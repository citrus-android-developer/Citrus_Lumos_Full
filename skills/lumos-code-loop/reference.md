---
name: lumos-code-loop
description: 分支終審前執行代碼對抗審計 loop——pitfalls --diff 命中 tier high 時觸發、派乾淨 reviewer 驗醒著、辯方殺假陽性、證據閘收斂才放行 finishing。對齊「收斂=終審綠燈」。觸發詞:分支終審、code review 對抗、pitfalls diff 命中 tier high、代碼審計 loop、終審前對抗審。
---

# lumos-code-loop:代碼對抗審計 loop 參考層(分支終審前的硬閘)

> ⛔ **canary 協議已於 2026-08-14 停用**(Enzo 裁;單源=Systems/canary-audit d5 與 SKILL.md 頁頂告示)。本檔 canary 相關段(植入/判定/missed 懲罰)**僅供回放歷史帳判讀**;每輪記帳改 `canary record none`。

**Claude 編排,lumos 出原語。** 你(主對話)用 Agent tool 派 reviewer、判讀、修代碼;lumos 出 `canary record none`/`loop status` 記錄與算收斂。lumos 不 spawn agent。

design-loop 的對抗紀律(canary 驗醒著 / 辯方殺假陽性 / 證據閘收斂)1:1 搬到代碼終審,差異只在:① canary 是 bug hunk 非散文瑕疵、② G1 對代碼無意義故 skip、③ mutation 冒煙為可選機械錨補充。

---

## 何時用 / 何時跳

- **觸發**:分支終審前跑 `lumos pitfalls --diff <merge-base>..HEAD`。
  - `tier: standard`(manifest 無命中)→ 現行單 reviewer 終審,**不走本 skill**。
  - `tier: high`(manifest 命中任一 pattern)→ 本 skill。★K 看模式:循序=2、平行 panel=1(tier=high 實務走 panel)。原本這裡只寫 K=2,對走 panel 的人是錯的——2026-08-03 修★
- **trivial 可跳**:改 typo / 純文檔 / 一行無邏輯 diff → 跳 loop,**但寫一句為什麼跳**(commit message)。
- **loop id** = `code-<topic>`(例:`code-payment-retry`、`code-worker-refactor`)。

---

## 每一輪 N(照做,步驟 1-7)

### 步驟 1 — 產 diff 文字檔並複製為工作副本

`review-package BASE HEAD` **或等價 `git diff -U10 BASE..HEAD` 重導向單檔**(僅需原生 git;review-package 是 superpowers 外掛的 git 薄殼,消費專案無外掛時走等價命令):

```bash
git diff -U10 <merge-base>..HEAD > /tmp/code-<topic>-diff.patch
cp /tmp/code-<topic>-diff.patch /tmp/code-<topic>-rN.patch   # 工作副本
```

**副本對象 = diff 文字檔**(非 checkout 原始碼樹)。植入、審查、判讀全在此副本上操作;真代碼樹不動。

---

### 步驟 2 — 植 bug canary hunk(只進工作副本)

在 `/tmp/code-<topic>-rN.patch` 的 Diff 段插入一段帶合法 `@@` 標頭的偽 hunk + 唯一 token 註解。

**類型輪替 `[(N−1) mod 4]`**:

| N 值 | (N−1) mod 4 | 類型 | 典型形態 |
|------|------------|------|----------|
| N=1 | 0 (a) | 邊界 / off-by-one | `< N` 改 `<= N`、索引越界一格 |
| N=2 | 1 (b) | 資源未釋放 / 鎖漏 | `lock.acquire()` 無對應 `release`、`open()` 無 `with` |
| N=3 | 2 (c) | None / 例外路徑未接 | 呼叫回傳值未判 None、例外吃掉不上報 |
| N=4 | 3 (d) | 冪等 / 併發破壞 | `SELECT` 後 `INSERT` 無交易包裹、TOCTOU |

canary 要「認真審就抓得到、但不一眼看穿」——太細=不公平、太明顯=訊號弱(校準鐵則,同 design-loop)。
**生成硬化三條(載重錨定/haiku 難度探針/事故反轉)與 reviewer 結構紀律(禁互辯/meta-judge/≥3 run 多數決)同 design-loop SKILL——單源在該檔對應節,code-loop 適配:載重錨定=bug canary 植在 diff 主題的核心邏輯型別、事故反轉查 pitfall_when 命中被改檔。不在此雙寫(防散落漂移)。

---

### 步驟 2.5 — 三道防污染(不可違反)

**① 真代碼永不含**
canary 只存在於 package 工作副本(`/tmp/…-rN.patch`)。折入真 finding 時每個 fix commit 必須錨到**真 diff 的 file:line**(canary hunk 的位置不在真 diff,想折也對不上座標)。

**② 低耦合植入**
canary hunk 的 file:line 必須落在**真改動集之外**(合成新 hunk 於未被真 diff 觸及的檔/函數),且與真改動弱耦合,縮小衍生推理波及面。
載體明定:reviewer 讀的是 diff 文字檔(`git diff -U10` 產)的工作副本;植入 = 在其 Diff 段插入帶合法 `@@` 標頭的偽 hunk + token 註解。
座標權威 = package 的 `-U10` 檔(pitfalls `--diff` 預設 `-U3`,兩者 `@@` 位移不同;pillar 判定為檔級,行級引用以 package 檔為準)。

**③ 溯源排除**
判讀時,任何 finding 的推理鏈引用 canary hunk 的 file:line、或依賴其語意(含間接聯想幻影:未顯式引用 canary file:line、僅因鄰接 canary 而聯想到真碼風險者)→ **連同 canary 一併排除、不折、不計 findings**。排本體也排影子。
排除方向偏「多排」(寧可少折不污染);殘餘=真 finding 被誤排的假陰性,由下一輪重挖兜底。折入端另有機械錨兜底:fix 必錨真 diff 座標 + 辯方 file:line 反證。

---

### 步驟 3 — 派乾淨 reviewer

Agent tool、`model: sonnet`(連 2 次 missed 後升 opus)、**不告知有 canary**、指向工作副本 `/tmp/code-<topic>-rN.patch`。

**framing(refute framing)**:
「你是外部第三方,這份 diff 是別人投稿的變更,不是你或本系統寫的。逐 hunk 讀、主動找洞:bug、邊界、資源、例外、冪等、併發——逐條標 severity(clean/minor/major/blocker)。附 pitfalls `--diff` manifest 當鏡頭:命中位置逐條判真隱患/誤報,真隱患必答對應提問。」

**抑噪紀律(borrow:PR-Agent 原始碼實證,兩句逐字進 reviewer prompt)**:
- 「低嚴重度疑慮,**給不出具體失敗場景就不要標**。」
- 「**不能從 diff 指出具體受影響的 file:line 路徑,就不准臆測『可能會壞別處』**。」
- ⚠ 刻意**不借** PR-Agent 的 findings 硬上限(num_max_findings=3)——上限會把真 findings 藏到下一輪,污染 G2 發現枯竭的收斂信號;抑噪靠上面兩句紀律,不靠砍量。

**受影響功能面鏡頭(2026-07-11 橋接,檢索排序轉正後啟用)**:派 reviewer 前跑
`lumos impact --diff <merge-base>..HEAD --json` ——聚合整段 diff 各檔的 ranked impact(query=各檔 hunk 文字)成一份 manifest:固定席(★INVARIANT★ 合約+pitfall_when 事故)全保、非固定取跨檔最高分 top-8。附給 reviewer 當第二鏡頭:「逐條判此 diff 會不會破壞該節點宣稱的行為/合約;固定席(合約/事故)必答」。**定位=advisory 人判**(機械保證只涵蓋合約/事故類固定席,其餘經排序無保底——保底與噪音都靠 reviewer 兜,故當鏡頭不當自動閘)。註:單檔版 ranked 已於 2026-07-11 過 §6 轉正接上 PreToolUse hook;--diff 聚合版仍維持審計鏡頭定位。

> manifest 現含兩種來源的 claim(`source` 欄區分):regex claim(`source:"pitfalls-builtin"`,讀 `question` 對應提問)與 lint claim(`source:"lint:<driver>"`,來自專案 `.lumos/lint.json` 宣告的社群 linter SARIF,讀 `message`——linter 已是具體診斷、無 question 欄)。reviewer 鏡頭對 lint claim 讀 `message`、對 regex claim 仍讀 `question`。

第一次 missed 起加碼 framing:「逐 hunk 讀,你一定找得到至少一個植入的 bug;沒找到就是你沒讀仔細。」

---

### 步驟 4 — 判讀 + 辯方

**① canary 判讀**
caught = reviewer 清楚且正確點出那個植入 bug 的「性質」(如「邊界 off-by-one」「鎖未釋放」);光 token 出現、或泛泛說「這段有問題」不算。

**② 真 finding 取 max severity**
排掉 canary 及其溯源影子後,剩餘 findings 的 max severity(`clean` / `minor` / `major` / `blocker`)。
剝「審計員誤判」要克制:只有能指出該 finding 客觀錯在哪(被真 diff 的 file:line 反證)才剝;判不準就保留(寧可高估),剝除理由記入審計紀錄。

**③ 辯方 refute(對 ② 標為 ≥major 的每條 finding)**
派 1 個獨立 opus 辯方(乾淨脈絡、不傳 reviewer 報告結論),framing:「預設這條 finding 假/嚴重度高估,構造反駁證據。必須附 file:line(grep/Read 真代碼),光說『沒問題』不算;拿不出反證則維持原 severity。」辯方回「真(維持)」或「假(降到 minor/clean)+file:line」。被駁倒(假)→ 降級、不折、審計紀錄標「辯方反證:<file:line>」。
- **辯方工具加 `git log`/`git show`**——commit 考古常是決定性反證(發版狀態、先例、時序)。完整派工模板見 `../lumos-design-loop/templates.md` §3-4(2026-07-07 Landmark 實戰)。
- **辯方順產 fix(實戰調參)**:辯方降級時若附「最小修法建議」,直接轉入 fix 佇列(nice-to-have 轉修,不折 finding、不佔 severity)——別浪費辯方查證時看到的低垂果實。

**④ 該輪 severity = 辯方裁決後存活 findings 的最高**

**⑤ 存活真 finding 修進真代碼**
fix commit(含必要的新測試)。測試收口分兩級:
- 隱患屬業務合約級 → 另寫架構圖 ★INVARIANT★ 並 `[test:]` 綁定(Check T 掃架構圖合約綁定才接住)。
- 非合約級的實作測試進套件靠回歸守,不經 Check T、不硬掛架構圖。

---

### 步驟 5 — 記錄

```bash
lumos canary record caught|missed \
  --loop code-<topic> \
  --severity <辯方裁決後存活 max> \
  --findings <存活折入數> \
  --auditor <模型>
```

- `--severity` = ④ 辯方重算後的存活 max(非 reviewer 原評)。
- `--findings` = ④ 辯方裁決後存活並折入的真 finding 條數(canary 不計;missed 輪不折記 0)。
- **missed → 該輪判決不採信、findings 全不折**,直接下一輪(N+1、自動換 canary 類型、framing 加碼)。
- **連 2 missed → 升 opus**(canary-log 最近 2 筆都 missed;中間一筆 caught 即重置)。

---

### 步驟 6 — 問收斂

```bash
lumos loop status code-<topic> --need 2 --gate --repo <repo根>
```

無 `--spec`(code-loop 無 spec 對象,G1 引用座標對代碼無意義):
- G1 印 `[gate] G1 refcheck: skipped(無 spec 對象)`、**不計 fail**。
- K-streak(★**循序模式**:連 2 輪 caught 且無 blocker/major;★**panel 模式只看最後一輪(K=1)**★) ∧ G2 發現枯竭 → exit 0(GATE PASS)→ 進 finishing。
- exit 1 → 逐錨明細指出斷在哪 → 回步驟 1。

---

### 步驟 7 — mutation 冒煙(可選機械錨,高風險分支建議)

在隔離 worktree 對 diff 涉及模組機械植少量變異(運算子翻轉 / 邊界 ±1,3-5 個)→ 跑該模組測試 → **活下來的變異 = 測試沒接住的洞**,列為 finding 回步驟 4。
零污染:不經 reviewer、不碰真樹。

**算子速查(borrow:Offutt E-selective / PItest / Kurtz FSE 2016)**:
- 預設植 **ROR(關係算子 `<`↔`<=`↔`==`)+ LCR(邏輯連接子 `and`↔`or`)**——最防禦得住的兩類;計算密集 diff 加 AOR(算術)。**無普適最優集,跟著 diff 的代碼形態選**。
- 同一個比較式(如 `i < 42`)**非冗餘變異只有 3 個:`i <= 42`、恆 `true`、恆 `false`**——植這 3 個以外是浪費名額(PItest subsumption)。

**結果判讀(borrow:Stryker 語意)**:
- **timeout → 記 `skipped(timeout)`,不算 finding 也不算存活**(無限迴圈=CI 事實上會接住;兩派工具語意殊途同歸)。
- 活變異**分兩桶,處置不同**:**Survived**(測試跑到該行但全綠)= 斷言缺口,補斷言;**NoCoverage**(該行根本沒被執行)= 測試整個缺,**更強的 finding、優先補**。判別零成本:變異行改成 `raise` 試跑一次即知有無被執行。

誠實邊界:3-5 個手植變異是抽樣不是覆蓋;活變異=測試缺口的存在證明,死光≠測試充分;flaky 測試會汙染訊號(跑前先確認套件綠)。

---

## 平行 panel 模式(≤3 輪壓縮,2026-07-09;取代 6 輪循序,機械核心與 design-loop 共用)
機械原語 loop-agnostic,**code-loop 直接可用**(同 `lumos loop status`/`canary record`);差別只在 panel 跑的是 **diff 文字檔**、canary 是 **bug hunk**、**無 G1**(code-loop 本就 skip 引用座標)。設計見 [[loop三輪壓縮_計劃]]。

- **一輪 = 平行派 W 個多樣 reviewer**(W=`difficulty.params(tier)['panel_width']`,standard=3/high=5),各讀一份 diff 工作副本:
  - **bug canary 型別跨 slot 輪替** `[(slot) mod 4]`=邊界off-by-one / 資源未釋放 / None例外路徑 / 冪等併發(code-loop 的四型,非 design-loop 的 a/b/c/d);canary hunk 仍落**真改動集之外**、走三道防污染(步驟 2.5)。
  - **鏡頭各異**:bug/邊界 / 資源與例外 / 冪等併發 /(W>3)migration 正確性、測試種子清理。
  - **跨家族(2026-07-18 S5,取代舊「qwen 只否決」)**:tier=high 雙 Codex 角色——1 席帶餌正式 finder 佔 W(受注意力檢查,計入重疊帳)+1 席無餌否決席不佔 W(外掛;findings 與帶餌席同池進辯方,存活 ≥major 依帳模式落閘:M2=記 disputed-major cluster 記錄/舊帳=計存活 max);standard=1 席無餌否決。fail 分級:standard fail-open 退同門+註記/high fail-closed(第三家族替補→延期→外家缺席不得收斂攤人)。qwen 轉列第三家族替補。
- **spec-conformance slot(2026-07-10,調研裁定③)**:tier=high 且該分支有收斂 spec(計劃節點)→ panel **追加**一個對答案審查員(不帶 canary、不佔 W 配額,地位同 Codex 無餌否決位):輸入=收斂 spec+diff,鏡頭=**逐條款對照**「說好的做了嗎/縮水/多做/未實作」四類;縮水與未實作視同 finding 進辯方流程。無 spec 的分支跳過並記一句。派工模板見 templates.md §7.5。
- **判讀/記錄/收斂**:同 design-loop panel(步驟 4 辯方 + 步驟 5 記錄)——一輪 W 筆共享 round-id:
  `lumos canary record caught|missed --loop code-<topic> --round <rid> --auditor <鏡頭>-<模型> --severity <s> [--capture-counts "2,2,1"]`。
- **問收斂**:`lumos loop status code-<topic> --gate --panel --repo <root>` → 兩條合取(輪有效[記帳席≥2,none 制] ∧ 存活max≤minor[caught+none];capture-recapture 殘餘=advisory 不進合取,2026-08-14 降級);**G1 本就對代碼 skip**,panel 模式不影響。一乾淨輪即收斂;存活≥major→fix→下一輪只重審 delta hunk,cap=3。
- **混用守衛**:`--panel` 要求本 loop 記錄全帶 round(partial-mix→rc2)。

### ⚠ code-loop 與 design-loop 的關鍵差異(2026-07-09 交叉查文獻;別全盤沿用)
程式碼有散文沒有的東西——**可執行 + 可靜態分析**。文獻(見 [[loop三輪壓縮_計劃]] 的 code-loop 差異節)證 code review 最佳解是**異質 ensemble**,非「多個多樣 LLM」:
1. **panel 應異質,不只多樣 LLM**(borrow:AutoSafeCoder / Multi-Agent Code Verification via Information Theory,arxiv 2511.16708——submodularity 證異質分析器各加獨立資訊)。**確定性驗證器的參與方式=三通道,不佔 canary 席、不進「輪有效」判定**(它們跑真碼樹,看不到文字 diff 副本裡的誘餌,記席必然 missed;canary 票只驗 LLM 席注意力;2026-07-18 codestage 收斂裁定):
   - (a) 其 findings 憑執行證據依辯方路由「機械證實」直接折入;
   - (b) 以**異質 finder** 進 capture-recapture 重疊帳(`loop capture-counts --finder/--from-pitfalls`);⚠ 兩套帳差異(2026-08-14 起已無):兩套帳的 capture-recapture 均 **advisory 不進合取**(無-cluster 帳 2026-08-14 降級對齊 cluster 帳);裁決權由通道 (a) 承載(機械證實 findings 進 cluster 三態帳);
   - (c) 需跑真碼的(測試套件/type checker)沿 mutation 冒煙的**隔離 worktree** 模式。
   - 具體 finder:專案 `.lumos/lint.json` 宣告的社群 linter(SARIF)/測試套件/type checker/mutation 冒煙(步驟 7)。
   - **為何**:linter/測試/type 的錯誤剖面**與 LLM 正交**(真獨立資訊),直擊「9 judge 2 票」——純 LLM panel(即使多樣)仍相關,摻確定性工具才買到真獨立訊號。
2. **辯方可執行 falsification**(borrow:Greptile TREX / CodeRabbit sandbox「grep 沒東西≠證明有 bug,先跑再信」):design-loop 辯方用 grep/Read 論證;**code-loop 辯方應能跑測試/repro/mutation 確認-或-殺一條 finding**——可執行反證 > 論證反證。lumos 已有種子:mutation 冒煙 + pre-push 測試 gate。
3. **capture-recapture 跨異質 finder**:LLM findings ∪ linter findings ∪ 測試失敗的**重疊**——LLM 與工具都指同一洞 = 更強收斂信號(且 capture-recapture 本就生於軟體檢驗,回娘家)。
4. **canary 型別、defect 分類本就不同**(已做:bug 四型 vs a/b/c/d)——文獻(PBR/defect-type mapping)證 reading technique 該隨 artifact 調;但實證 PBR 增益不穩,**重點在異質驗證器 mix 而非 LLM 鏡頭數**。
> 一句話:code-loop **繼承 panel 機制 + capture-recapture 收斂**(後者本是代碼檢驗的),但**panel 成員換成 LLM + 確定性工具的異質組合、辯方改可執行反證**——不是「design-loop 換 canary 名字」。

- **mutation 冒煙(步驟 7)**在 panel 下升格為**一個確定性 finder**(不只可選旁支;不佔 canary 席,參與方式見上三通道):活變異 = 一條 finding 進 capture-recapture 池。

### 異質 finder → capture_counts 的機械算法(別手數重疊)
一輪跑完,把每個 finder 找到的 finding-key(正規化成 `file:line` 或 `section:nature`)收齊,機械算重疊:
```
lumos loop capture-counts \
  --finder "app.py:12,svc.py:40"   # LLM reviewer A
  --finder "app.py:12,util.py:9"   # LLM reviewer B
  --finder "app.py:12"             # SARIF linter(pitfalls --diff 命中)
  --finder "svc.py:40"             # 測試失敗 / mutation 存活
# → capture_counts=… + 殘餘估計 + 可直接貼的 `canary record … --capture-counts <串>`
```
- 重疊計數(同洞被幾個 finder 中)是 capture-recapture 核心輸入,**人手數易錯 → 該機械化**。
- **linter 免手貼:`--from-pitfalls <range>` 一鍵收割**——`loop capture-counts --finder "<LLM A>" --finder "<LLM B>" --from-pitfalls main..HEAD --repo <root>` 會自己跑 `pitfalls --diff`、按 source 分組(每個 linter driver / pitfalls 內建各一個確定性 finder)、把命中的 `file:line` 併進來一起算重疊。手動 `--finder` 留給 LLM reviewer,確定性 finder 自動來。
- 拿到 `--capture-counts` 串 → `canary record caught --loop code-<topic> --round rN --capture-counts <串> …`;`loop status code-<topic> --gate --panel` 把它印成殘餘 advisory 觀測(不進合取);canary-stats 重疊分布段也吃它。

### 端到端一輪(照抄改參數)
```bash
# 0. 定 topic / tier / diff range
TOPIC=code-fix-billing; RANGE=main..HEAD; RID=r1
# 1. 平行派 W 個乾淨 LLM reviewer(Agent tool,W=panel_width;各讀 diff 工作副本、含輪替 bug canary)
#    → 收各 reviewer 的 findings,正規化成 file:line
# 2. 算重疊(LLM 手動 --finder + linter/regex 自動 --from-pitfalls)
lumos loop capture-counts \
  --finder "billing.py:88,billing.py:120" \  # reviewer A
  --finder "billing.py:88,tax.py:12" \       # reviewer B(billing.py:88 與 A 重疊)
  --from-pitfalls "$RANGE" --repo .          # linter/regex 確定性 finder 自動收割
#    → 印 capture_counts=… 與可貼的 `--capture-counts <串>`
# 3. 記這一輪(W 筆共享同一 --round;此處示意 caught 輪)
lumos canary record caught --loop "code-$TOPIC" --round "$RID" \
  --auditor bug-sonnet --severity minor --capture-counts "2,1,1"
# 4. 問收斂
lumos loop status "code-$TOPIC" --gate --panel --repo .   # rc0=PASS → 進 finishing;rc1→修 delta 再下一輪(cap=3)
# 5. 收斂後記留痕才能 push
lumos code-loop pass --note "panel 收斂:輪有效∧無存活 major(殘餘 obs X.XX advisory)"
```

## 護欄

- **連 2 次漏抓**(canary-log 最近 2 筆都 missed;中間一筆 caught 即重置)→ 升 opus。
- **max cap = 6 筆 record(循序模式);panel 模式 cap=3 輪**。到頂仍未收斂 → 停、把現況攤給人、記一句「達 cap 未收斂」。別無限燒。

---

## 誠實天花板(收斂後務必向人提醒)

1. **pattern 掃描是提示器不是偵測器**:N+1/race 多數形態 regex 抓不到;買到的是「reviewer 注意力被導到高風險位置」,漏網靠 reviewer 本身 + canary 紀律 + 測試。單行掃描能力邊界:「迴圈體內/交易語境/續行 timeout」等跨行語境單行不可判,實作以單行 + 小行窗啟發為限;做不到的形態誠實不掃、不硬湊。
2. **bug canary 的校準與污染殘餘**:「認真審抓得到、不一眼看穿」靠植入者自律(同 design-loop 校準鐵則);溯源排除規則由編排者人工判,判錯方向偏「多排」,殘餘=真 finding 被誤排的假陰性,下一輪重挖兜底。
3. **mutation 冒煙的誠實邊界**:3-5 個手植變異是抽樣不是覆蓋;活變異=測試缺口的存在證明,死光≠測試充分;flaky 測試會汙染訊號。
4. **code-loop 收斂少一道 G1**:gate 對代碼只剩 K-streak ∧ G2,「引用座標」類機械錨無對應物;衍生的機械錨(如 mutation 全滅)留 v2 評估是否進 gate。

---

## 收斂後

`lumos loop status` exit 0 → 向人回報收斂 + 上述天花板 → **必須先記 code-loop pass 留痕** → 再交 **finishing-a-development-branch** 進合併流程。

**強制步驟（不可跳）：**
```bash
lumos impact --diff <merge-base>..HEAD --sync-check   # 落成核對:受影響功能的節點動了沒?未同步清單逐條判(漏了就補,不用就心裡有數)
lumos code-loop pass --note "<收斂理由 / loop-id，例:code-<topic> 收斂 N 輪 caught 無 blocker>"
```

> **為什麼**：pre-push hook 已升級為 **blocking**——tier=high 分支若無有效的 `pass`（或 `skip`）留痕，`git push` 會被硬擋（rc1）。`loop status` exit 0 只代表審計收斂，留痕要另外寫一次才閉環。`skip` 是假陽性逃生閥（繞行也留痕），正常收斂後用 `pass`。

> 設計全文見 `docs/design/2026-07-04-pitfalls-code-loop.md` ### ③ `lumos-code-loop`。
