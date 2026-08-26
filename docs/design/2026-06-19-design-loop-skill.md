# 設計:lumos-design-loop skill(Component B)— loop-pipeline 編排

- 日期:2026-06-19
- 狀態:✅ CONVERGED(經 5 輪 canary-護審計、用 A 的 K=2 判準收斂:tail-2=[r4 caught+minor, r5 caught+clean])
- 方向:lumos 治理朝 loop engineering(見 memory `lumos-governance-direction-loop-engineering`)
- 角色:**Component B**(Claude 編排層 skill),消費 **Component A**(`docs/design/2026-06-19-convergence-recording.md`:`lumos canary record --loop/--severity` + `lumos loop status`)。

## 0. 動機

把這個 session 一直手動在跑的「canary-護的對抗審計 loop」自動化:產出 spec 後、進實作前,自動派乾淨審計員一輪輪挑毛病、每輪植 canary 驗審計員有沒有放水、修到 `lumos loop status` 收斂,才進實作。讓「每個計畫都先進 loop 打磨、再進最終實作」成為標準路徑(loop-engineering 方向)。

## 1. 範圍 / 架構

- B = **一個 user-scope Claude skill**,目錄 `skills/lumos-design-loop/`(放 lumos-toolchain repo,跟其他 lumos skill 一起 symlink 進 `~/.claude/skills/`)。
- **Claude 編排,lumos 出原語**:Claude 用 Agent tool 派審計員、判讀、修 spec;lumos 出 `canary record`/`loop status` 記錄與算收斂。**lumos 不 spawn agent**。
- v1 對象 = **設計/spec 的對抗審計**(對齊 A + canary v1 範圍)。不含架構圖自足性審計。

## 2. 觸發 / 閘

- **觸發點**:brainstorming 產出 spec/設計 doc 後、進 writing-plans/實作**前**。
- **硬閘(紀律強制,非技術鎖,M-4 誠實)**:`lumos loop status <id>` 回 exit 0(CONVERGED)前,**不得進實作**。lumos **無法技術上擋住**「未跑 loop 就實作」——這靠 Claude 記得調用 + 誠實套用 trivial 判準(同 pre-commit 有 `--no-verify` 後門:是紀律不是鐵牢)。trivial-skip 也是自評、無第三方檢查;**所以 cap/天花板/留痕都要在**,讓繞過至少留痕、可事後查。
- **trivial 可跳**:改 typo / 一行 / 純機械(rename、補欄位、連結修復)→ 可跳 loop,但**寫一句為什麼跳**(留在對話/commit message)。
- **loop id** = spec 檔名去掉 `docs/design/` 前綴與 `.md`、再去掉日期前綴(如 `docs/design/2026-06-19-design-loop-skill.md` → `design-loop-skill`),傳給所有 `--loop`。

## 3. 每一輪(skill 的程序,Claude 照做)

1. **複製** spec 成工作副本:**來源 = `docs/design/<id>.md`**(brainstorming 的產出落點);工作副本 `/tmp/<id>-rN.md`。**N 推導 = 該 loop 在 canary-log 已有的記錄數 +1**(`lumos loop status <id>` 的輪歷史即可數;不靠記憶)。
2. **植一個 canary**:**additive only**(不牽動其他段落)。**canary 類型清單(輪流換,滿足 §8「清單具體」)**:
   - (a) 壞 §/章節交叉引用(指向不存在的 §N);
   - (b) 未定義的旗標 `--xxx`(引入卻不在任何指令/簽名);
   - (c) 未定義的欄位/常數(如憑空的 frontmatter 欄位或常數名);
   - (d) 未定義的產物/檔名(如憑空的 `xxx.json`,不在 schema/它處)。
   **類型由 N 決定(無需記憶/查 log 的 type 欄):type = 清單[(N−1) mod 4]**(N=本輪序,a=1,b=2…)→ 自動 a→b→c→d→a 輪替,missed 重跑時 N 已 +1 故換新類型。嵌唯一 token 定位;在 `--note` 記 `type=<x>`。**提交的 spec 永遠不含 canary。**
3. **派乾淨審計員**:Agent tool、`model: sonnet`(**升級後 opus,見 §4**)、**refute framing**(主動找洞,別確認)、**不告知有 canary**、指向工作副本。
4. **判讀**:① **canary 抓到 = 審計員清楚點出那個植入瑕疵的「性質」**(如「§N 不存在」「`--xxx` 未定義」)——光 token 字串出現、或泛泛說「有些引用怪怪的」不算;② **最嚴重真 finding**(`clean`=排掉 canary 後審計員無任何真 finding / `minor` / `major` / `blocker`)= 審計員標的 max。**剝除「審計員誤判」的約束(防自己放水,M-3)**:只有當你能**指出該 finding 客觀錯在哪**(被實際 spec/code 內容反證)才可剝;**判不準就保留**(寧可高估嚴重度)。誤判剝除要在 `--note` 記一句理由。
5. **記錄**:`lumos canary record caught|missed --loop <id> --severity <worst> --auditor sonnet --note "r<N> type=<a-d> <caught|missed> [誤判剝除理由]"`(`--loop`/`--severity`/`--auditor` 皆 **Component A 的 `canary record` 介面**所定義,見 A spec;`--note` 格式固定含 canary 類型供追溯)。
6. **漏抓 → 該輪判決不採信**(但**仍是一筆 `missed` record、仍算進 cap**,不是「不存在」):**不折 findings**(判決不可信),下一輪(N+1、自動換 canary 類型 + 更兇 framing,見 §4)。
7. **抓到 → 折真 findings 進 `docs/design/<id>.md`**;**commit 前 `grep -c '<canary token>' docs/design/<id>.md` 必須為 0**(MINOR-1:確認 canary 沒混進真檔)再 `git commit`(message 記該輪 canary+severity)。折時:剝審計員誤判(依 step4 約束)、套真 fix、把該輪寫進 spec 審計修正紀錄。
8. **問收斂**:`lumos loop status <id> --need 2`(**K=2**:連 2 輪 caught 且無 blocker/major)→ exit 0 出 loop;exit 1 → 回 step 1 下一輪。

## 4. 護欄

- **每次派審計員 = 一筆 record = 一輪**(含 missed,M-1):漏抓也 `lumos canary record missed` 留痕、**也算進 cap**;不存在「不記錄的 inline 重跑」。所以「輪」「cap」「連續漏抓」全以 **canary-log 的記錄**為準,定義一致。
- **更兇 framing(從第 1 次漏抓就用,不必等 2 次)**:把 refute prompt 從「找洞」升成「**逐節讀,你一定找得到至少一個未定義的詞/壞引用/不一致;沒找到就是你沒讀仔細**」。
- **連 2 次漏抓 → 升級**:定義 = **canary-log 最近 2 筆都 `missed`**(中間一筆 `caught` 即重置連續計數)。升級動作:① 審計模型 sonnet→**opus**;②(soft,人工判斷)把 spec 切小(獨立子段各自開 loop;v1 不自動化此步)。
- **max rounds cap = 6 筆 record**:到頂仍未收斂 → **停、把現況攤給人**、記一句「達 cap 未收斂」(別無限燒)。
- **三重自判都是沒閉合的迴歸(誠實,M-3)**:編排的 Claude 同時判 ① canary 抓到沒、② severity、③ 哪些 finding 是審計員誤判——三個都由「植入者本人」做、無外部檢查。已用約束收窄(step4:誤判要能反證、判不準就保留;severity 忠實轉錄 max),但**根本上不 tamper-proof**。
- **誠實天花板(沿用 A/canary,B 不得弱化)**:loop 是**可觀測 + 摩擦 + 地板**,不是 oracle。收斂只證「連 K 輪醒著的審計員沒找到 blocker/major」,不證完整正確。B 在收斂後**仍要向人提醒**這些天花板,別讓 CONVERGED 被當成「絕對沒問題」。

## 5. 收斂後

`lumos loop status` exit 0 → 向人**回報收斂 + 天花板提醒** → 交 **writing-plans** 出實作計畫 → 實作。

## 6. 整合 / 讓「每個計畫自動走」

- **B 的 skill description** 設成在「產出 spec/設計後、進實作前」觸發(讓 Claude 自己會調用)。
- **指針句(具體文字)**:在 `skills/lumos-project-notes/SKILL.md` 的**工具速查表**(`| … | python3 scripts/lumos … |` 那張)新增一列、與 `scripts/templates/graph-discipline.md` 的 **`### 其餘原則` 的「退場必寫」bullet 之後**,各加:
  > 「**設計 spec 完成 → 進實作前,先用 `lumos-design-loop` skill 把它過 canary-護的審計 loop 到 `lumos loop status` 收斂**(trivial 改動可跳並註明)。」
- B **不改** superpowers 的 brainstorming/writing-plans(那在 plugin cache、不在本 repo)——B 是獨立 skill,靠 description + 上述指針被接上。

## 7. 範圍 / YAGNI(v1 不做)

- ❌ lumos spawn agent(編排在 skill)。
- ❌ 架構圖自足性審計 loop(v1 只設計/spec)。
- ❌ 自動 canary 生成工具(Claude 從 skill 內的小型 canary 類型清單挑)。
- ❌ 改 brainstorming/writing-plans skill 本體。

## 8. 「完成」判準(這是 skill,不是 code)

- skill markdown **明確到 Claude 能照跑、無需再做設計決定**:每步有具體動作、canary 類型清單具體、收斂/升級/cap 條件具體、天花板明說、整合指針到位。
- 冒煙:對一份玩具 spec 跑一遍 B(植 canary → 派審計 → record → loop status),走得通。
- **本 doc 是 B 的設計 spec;實作 B = 依此 spec 寫出 `skills/lumos-design-loop/SKILL.md`**(把 §2-§6 變成 Claude 照跑的 skill 指令)。本 doc 收斂後,SKILL.md 由 writing-plans/實作產出。
- (無 `test_lumos.py` 單元測試——B 是 skill 非 lumos code;A 的原語已有測試。)

## 審計修正紀錄
### 第五輪(canary=壞 §ref→§9,**抓到**)— ✅ CONVERGED
- 審計員精準點名 §9 dead-ref,並明確驗證其餘全 CLEAN(terms/flags/artifacts/refs 皆定義、無 orphan、邏輯一致)。
- **R5 = caught+clean** → tail-2=[r4 caught+minor, r5 caught+clean] → **CONVERGED**(K=2 滿足)。
- 全程 severity:blocker→blocker→major→minor→clean(單調下降,loop 死不收斂直到真乾淨)。5 輪、0 漏抓。

### 第四輪(canary=未定義產物 `loop-summary.md`,**抓到**;無 blocker/major)
- MINOR-A:`--auditor` 等旗標未註明來自 A 介面 → §3 step5 註明。
- canary 校準教訓:`loop-summary.md` 偏像真實 deliverable,審計員當「缺路徑」flag(仍是 catch),不如 loop_manifest/round_budget 那種明顯 orphan;下輪用更明確的 orphan(壞 §ref)。
- **R4 = caught+minor → 計入收斂**;但 tail-2=[r3 major, r4 minor] 尚未收斂,需 r5。

### 第三輪(canary=未定義欄位 `round_budget`,**抓到**)
- 前兩輪 13 項修正**全部 hold**。
- MAJOR-2:連續漏抓 reset 規則 + 單次漏抓 framing 文字未 pin → §4 明訂(最近 2 筆 missed、caught 重置;framing 從第 1 次漏抓就加碼)。
- MINOR-4:`clean` severity 定義(無任何真 finding)→ §3 step4。
- NIT:§4 ②③ 重複「切小」編號修;loop id 推導寫明。
- canary 驗證:審計員精準點名 `round_budget`(undefined field)→ **醒著**;severity=major → 不計入收斂。

### 第二輪(canary=未定義旗標 `--escalate-once`,**抓到**)
- BLOCKER-2(真):K=2 未敘明於 spec 本體 → §3 step8 寫明 `--need 2`。
- MAJOR-1:`作廢` vs 算進 cap 矛盾 → §3 step6 改「判決不採信、仍是 missed record 算進 cap」。
- MAJOR-2:rotation 無 state → §3 step2 改「type=清單[(N−1)mod4]」由 N 決定。
- MINOR-1:commit 前 grep canary token=0 → §3 step7。
- MINOR-2:`--note` 固定格式含 type → §3 step5。
- MINOR-3:step3 補「升級後 opus」。
- MINOR-4:「切小」標 soft/人工、v1 不自動化 → §4。
- §6 指針 anchor 具體化(工具速查表列、退場必寫 bullet 後)。
- canary 驗證:審計員精準點名 `--escalate-once`(undefined flag)→ **醒著**;severity=blocker → 不計入收斂。

### 第一輪(canary-護;canary=未定義產物 `loop_manifest.json`,**抓到**)
- B-1(canary):ghost 產物,已剝(只在工作副本)。
- B-2:canary 類型清單缺(spec 未達自己 §8 判準)→ §3 step2 補具體 4 類清單。
- B-3:來源 spec 路徑 + rN 推導未定 → §3 step1 pin(來源 docs/design/<id>.md;N=canary-log 記錄數+1)。
- M-1:重跑/cap 計數歧義 → §4 明訂「每次派審計=一筆 record=一輪(含 missed),全以 canary-log 為準」。
- M-2:「更兇 framing」「更強 model」未定 → §4 給具體(opus、切小、加碼 framing 文字)。
- M-3(深):**第二整合性面**——編排者也判「哪些是審計員誤判」可放水 → §3 step4 約束(誤判要能反證、判不準保留)+ §4 明說三重自判都是沒閉合迴歸。
- M-4:硬閘/trivial-skip 是紀律非技術鎖、自評無第三方 → §2 誠實標明(靠 cap/留痕兜)。
- M-5:整合指針句未給文字 → §6 補具體句。
- m-1:本 doc 是 spec、實作 B=寫 SKILL.md → §8 釐清。
- canary 驗證:審計員精準點名 `loop_manifest.json`(且發現它與 committed doc 分歧)→ **醒著**;severity=blocker → 不計入收斂。
