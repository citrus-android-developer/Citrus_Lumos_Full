# 設計:design-loop 辯方 refute 階段(finding-refute)

- 日期:2026-06-24
- 狀態:**CONVERGED**(2026-06-24 design-loop 3 輪、canary 3/3 全中、r2+r3 連 2 good 自動收斂、全程無假陽性。辯方機制尚未上,本 spec 仍由編排者手動當辯方但本輪無假陽性可駁)
- 動機來源:2026-06-23 cross-family 首次真審 nested-agent spec,qwen 認真但誤判 `__SCRATCH__`/cwd(假陽性);人 grep 駁回=辯方。design-loop 全是檢察官、缺辯方。
- loop_id:finding-refute

## 目標(一句話)

design-loop 每輪判讀 severity 後,對該輪 **severity≥major 的 finding** 各派一個獨立辯方「試圖反駁、預設它假、必須附 file:line 證據」,殺掉 code 層假陽性;該輪 severity = 辯方裁決後存活 findings 的最高(編排者機械取 max)。

## 前提與既驗事實

- **canary 防假陰性、不防假陽性**:`SKILL.md` 步驟 4① canary 驗「審計員有沒有認真讀」(漏抓=放水),抓不到「認真讀了但判錯」(誤抓)。今天 qwen 引了行號、講得頭頭是道,卻把已處理好的 `__SCRATCH__`(sed 替換 token)誤判成 major——canary 對這型無能為力,甚至因 qwen「醒著」而更信任它的誤判。
- **現有「剝誤判」是編排者自填、有風險**:`SKILL.md` 步驟 4②「剝審計員誤判要克制:只有能指出該 finding 客觀錯在哪(被 code 反證)才剝」——這是辯方雛形,但**由編排者自己判讀時剝**。編排者同時是「想收斂的人」,自剝有自填偏誤(剝真 finding 求收斂 / 不剝假 finding 怕擔責)。同 judge-severity-gate 當初要解的「severity 別由利害關係人自填」。
- **辯方升級它為獨立帶證據**:把「編排者克制剝誤判」升級成「派獨立辯方、預設 finding 假、逼 file:line 證據」——斷開編排者自填,同 judge-severity-gate 精神(severity 裁決交獨立評定者)。
- **兩個 design-loop 落點**:`skills/lumos-design-loop/SKILL.md`(手動版,主對話用 Agent tool 派)步驟 4-5 之間;`governance/autonomous_loop/orchestrator-prompt.md` §2(自動版,claude -p)步驟 4(judge)後、步驟 5(讀/決定)前(實檔 7 才是折)。
- **judge-severity-gate 現狀**(orchestrator-prompt §2 步驟 4):獨立 opus judge 評 caught + severity(排掉 canary 後最嚴重真 finding)。辯方接在 judge 後,對 judge 評為 major+ 的 finding 再複核。

## 邊界 / 非目標(YAGNI)

- ❌ **只對 severity≥major 派辯方**:minor/clean 不影響收斂(`good`=caught 且 severity∈{clean,minor}),不派、省算力。
- ❌ **不 N 個多數決**:1 個辯方 + 強制 file:line 證據即可——要證據=確定性查證(可被下輪 auditor/人複驗),比 N 個 AI 投票更貼「確定性 > AI 判斷」主軸,且省。
- ❌ **不重派 judge 算 severity**:辯方裁每條 finding 真/假 + 降幅(**帶 file:line 證據、獨立評定**,同 judge-severity-gate 精神);編排者只對各 finding 結果**機械取 max**(取 max 非評判)。注:辯方選「降 minor vs clean」雖是評定,但 good() 二值門檻({clean,minor} 皆 good)使其對收斂等價。
- ❌ **不碰 canary / judge / cross-family / lumos 原語**:辯方是新疊加階段,純加。
- ❌ **不擋業務層**:辯方只殺「code 層能反駁」的假陽性;業務層對錯留人(誠實天花板)。

## 架構:辯方階段插在 judge 後、record 前

```
auditor → findings                 (檢察官:對「設計」refute)
judge → caught/missed + severity   (現有:排掉 canary 後最嚴重真 finding)
【辯方 refute(新)】:
    對每條 judge 評為 severity≥major 的 finding:
      派 1 個獨立 opus 辯方(乾淨脈絡、不餵 auditor/judge 結論)
      prompt:「預設這條 finding 是假/嚴重度高估,構造反駁證據。
              必須附 file:line(實際 grep/Read 代碼);光說『沒問題』不算。
              **若該 finding 真的無任何查證行(judge 因此鎖 major),你也得拿出反證 file:line 才能降,拿不出則維持。**」
      回:「真(維持 judge 原 severity)」或「假(降到 <minor|clean>)+ file:line 證據」
    該輪 severity = 存活 findings 最高(編排者機械取 max)
【record / 折】用重算後 severity;只折存活真 finding,被駁倒的不折、標「辯方反證:<file:line>」

(物理步驟編號兩落點不同、見「組件」;共通順序:judge → 辯方 → record(用重算 severity)→ 折——record 早於折,兩落點皆然。)
```

**跟現有四機制的關係**(各防一個失敗模式,互補):

| 機制 | 防的失敗模式 | 方向 |
|---|---|---|
| canary | 審計員放水/沒讀(假陰性、漏抓) | 測審計員狀態 |
| judge-severity-gate | 編排者自填 severity | severity 交獨立評定者 |
| cross-family | 同門盲點(收斂輪、另一家族) | 另一個檢察官(qwen);`status==ok&major` 時**編排者每次 self-grep 複核** qwen findings(導向 disputed 的過程;達 2 次→disputed 終態)——**非獨立辯方,正是本 spec 要改進的 self-grep 自填偏誤** |
| **辯方(本 spec)** | auditor 認真但判錯(假陽性、誤抓) | 對每條 finding refute |

**收斂影響**:假 major 當輪被辯方降級 → severity 降 → 若降到 clean/minor 該輪轉 good → 直接解「假 major 害 loop 跑更久」(今天 cross-family/check-t 都撞 cap、major 輪多)。

## 組件(改動)

### 改:`skills/lumos-design-loop/SKILL.md`

步驟 4「判讀」②「最嚴重真 finding…剝誤判要克制」之後、步驟 5「記錄」之前,插入**步驟 4.5「辯方 refute」**:
- 對步驟 4② 標為 ≥major 的每條 finding,用 Agent tool 派 1 個獨立 opus 辯方(乾淨脈絡、不傳 auditor 報告結論、refute-the-finding framing:「預設這條 finding 假/高估,構造反駁、附 file:line」)。
- 辯方回「真/假(+降後 severity)+file:line」。被駁倒(假)→ 該 finding 降級、不折、在審計紀錄標「辯方反證:<file:line>」。
- 步驟 4② 末句改:該輪 severity = 辯方裁決後存活 findings 的 max(取代編排者自剝)。
- 步驟 5 record 的 severity 用重算後值。
- 步驟 7「折真 findings」改:只折辯方存活真 finding,被駁倒的不折、標「辯方反證:<file:line>」。**注(F2):兩落點是「動作對稱、step 號各異」**——SKILL step5=record/step7=折,orchestrator step6=record/step7=折;勿照「對稱」字面去 SKILL 找 step6(實為漏抓分支)。

### 改:`governance/autonomous_loop/orchestrator-prompt.md`(§2)

步驟 4(judge)後、步驟 5(讀 judge severity + 決定折哪些)前,新增**步驟 4.5「辯方 refute」**:對 judge 評為 ≥major 的每條 finding,用 Agent 工具派 1 個獨立 opus 辯方(同上 framing、要 file:line)。回真/假;假→降級。該輪 severity = 存活 findings max(編排者機械取,非自評)。**步驟 6 record 用重算 severity;步驟 7 折只折存活真 finding**(實檔:5=讀/決定、6=record、7=折)。

### 不改

canary 流程、judge(步驟 4)、cross-family(§2.5)、lumos 原語、record/loop status。

## 誠實天花板

1. **只買 code 層假陽性**:辯方靠 grep/Read 能反證的(qwen `__SCRATCH__` 看 sed 替換點就破、M2 看 `creditCardDone` 設值點就破)。「業務現實才知道對不對」的假陽性/假陰性,辯方一樣判不了——那層留人拍板。
   - **效力來源是「方向相反」、不是「code 證據」本身**:auditor 提 major 時也 grep 過(強制查證)。辯方不靠「更會看 code」,靠**任務方向相反**——auditor 找洞(看到可疑就提、無動力深挖反證),辯方被逼「構造推翻證據」(專去查 auditor 跳過的反方向)。qwen 誤判 `__SCRATCH__` **不是「看了 L35 sed 還判錯」,是「沒把 `__SCRATCH__` 追到 L35」**;辯方的反向任務逼它 grep 到 L35 才破。同樣 grep、目標命題相反(找支持 vs 找推翻)→ 挖的角落不同。這也是為何不靠「多派 auditor」(都找洞方向、只生更多起訴)。
   - **何時無效(精確邊界,回應「缺脈絡時辯方憑什麼對」)**:① 缺的脈絡在 **code 外**(業務現實/設計意圖,code 裡沒寫)→ 辯方一樣 grep 不到、給不出反證 → 一樣判錯,留人。② 辯方**自己也沒挖到**那塊 code 脈絡(跟 auditor 同樣缺)→ 拿不出反證 → 按規矩**維持** finding(假陽性沒殺,但「逼證據」讓它不空口誤殺真的——無功但無害)。故辯方只提高「脈絡在 code 裡、auditor 找洞時跳過」那類的糾正機率,**非保證**。
2. **辯方也是 AI**:逼 file:line 降低瞎判,但辯方可能查錯/引錯行。證據**可複驗**(下輪 auditor + 人看得到辯方 file:line)→ 降低、不消滅。
3. **辯方太強會駁倒真 finding**(假陽性換假陰性):強制 file:line(空口不算)+ 只碰 major+(不動已收斂的 minor)限制;但一個會伪造證據的辯方仍可能殺真 finding——同所有 AI 審計的天花板,摩擦地板非 oracle。
4. **canary 防漏抓、辯方防誤抓**:兩個相反方向、都是降低放水的摩擦,不是閉合驗證。最終業務確認留人(同 judge-severity-gate / cross-family 天花板)。

## 測試策略

- **無單元測試**:辯方階段是 prompt 紀律(SKILL.md + orchestrator-prompt),同 cross-family/judge-severity-gate 的 prompt 改,無代碼可單元測。
- **驗證靠 design-loop 實戰**:本 spec 自己走 design-loop 時辯方尚未上,仍 opus 單審 + 編排者手動當辯方(讀 spec、grep 駁回誤判);上線後下一個自動 loop / 手動 design-loop 觀察「假 major 有沒有被辯方當輪降級」。
- **回歸**:確認 SKILL.md / orchestrator-prompt 其餘步驟(canary/judge/record/loop status/cross-family)文字未被動到。

## 知識同步影響

| 受影響文件 | 需同步什麼 |
|---|---|
| `docs/methodology/架構圖即合約.md` | 設計前審計 loop 段補:辯方階段(防假陽性)= canary(防假陰性)的對稱補位;檢察官/辯方雙向對抗 |
| `docs/methodology/架構圖即合約-對外論述.md` | 白話:審查除了「檢察官挑毛病」,還配「辯護律師」反駁冤枉的指控(逼拿代碼證據) |
| `skills/lumos-design-loop/SKILL.md` | 見上:步驟 4.5 辯方 + 步驟 4②/5 severity 改重算 |
| `governance/autonomous_loop/orchestrator-prompt.md` | 見上:§2 步驟 4.5 辯方 |
| memory `autonomous-iteration-loop` / `canary-loop-reliability-varies-by-spec` | 補:辯方階段防假陽性(canary 只防假陰性) |

## 審計修正紀錄

### R1(2026-06-24,canary type a=壞§ref,opus,**CAUGHT**,severity=major)
canary(§調用時序圖 不存在)被識別。排掉 canary 後全是真 finding(**無假陽性,auditor 這次準,故未觸發手動辯方演練**),折入:
- **Major(F1)**:orchestrator §2 步驟編號錯——實檔 5=讀/決定、6=record、7=折(我誤寫「步驟 5=折」)。架構圖改邏輯流程(去物理步驟號)、組件精確標 record(6)早於折(7)。
- **Major(F2)**:cross-family disputed 是**編排者 self-grep** 複核 qwen findings、非「opus 半辯方」(我造詞 + 錯假設)。對照表改正——且這恰恰**強化本 spec**:cross-family 也是 self-grep 自填,本 spec 的獨立辯方更好。
- **Minor(F3)**:「raw severity」造詞→刪;judge「無查證行鎖 major」底線:辯方降級也須拿反證 file:line,拿不出則維持(已加進辯方 prompt)。
- **Minor(F4)**:「機械 max=非評判」論證——辯方選降幅是評定,但 good() 二值吸收;措辭修正。
- **Minor(F5)**:架構圖混用兩落點步驟號→改邏輯流程 + 組件分別精確。
- 其餘(good() 定義/SKILL 步驟 4②剝誤判)經 auditor 查證 clean。

### R2(2026-06-24,canary type b=未定義旗標,opus,**CAUGHT**,severity=minor)
canary(`--refuted-by` 未定義旗標)被識別。排掉 canary 後僅 minor(此輪 good):
- **Minor(F2)**:SKILL §組件遺漏「步驟 7 折只折存活真 finding」的對稱修改(orchestrator 組件有、SKILL 漏)→ 補上,兩落點對稱。
- 其餘(cross-family disputed self-grep 描述/good() 定義/judge 底線/步驟編號/辯方時序)經 auditor **全查證 clean**,R1 修正(F1 步驟號/F2 cross-family)站得住。

### R3(2026-06-24,canary type c=未定義常數,opus,**CAUGHT**,severity=minor)→ **CONVERGED(連 2 輪 R2+R3 caught+minor)**
canary(`REFUTE_TRIGGER` 未定義常數)被識別。排掉 canary 後僅 minor:
- **Minor(F2)**:「對稱」措辭掩蓋兩落點 step 號各異(SKILL step5=record、orch step5=讀/決定)→ 改述「動作對稱、step 號各異」。
- **Minor(F3)**:cross-family disputed 因果倒置——self-grep 是 `status==ok&major` 每次做的過程(導向 disputed)、disputed 是達 2 次終態(不再 self-grep)→ 改正。
- 其餘(good()/step5-7/judge 無查證行鎖 major 底線/誠實天花板)經 auditor 查證 clean。

> **3 輪收斂(2026-06-24)**:r1 major→r2 good→r3 good,連 2 輪 caught+minor。**全程無假陽性**(auditor 三輪皆準、未觸發手動辯方演練——諷刺但誠實:辯方機制要 auditor 真出假陽性才用得上,這次沒有)。核心地面事實全查證準確,R1 兩個硬傷(步驟號/cross-family 造詞)修掉後快速收斂。
