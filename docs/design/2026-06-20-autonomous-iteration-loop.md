# autonomous-iteration-loop — 自主迭代 loop:每天自動備好一份已自審的 lumos 改進 spec(設計)

> 狀態:**CONVERGED**(canary-護 design-loop 5 輪、K=2,2026-06-20;**自指閉環達成**——用 lumos 迭代 lumos 的第一個產物=迭代器自己,走完它自己描述的那套 loop 並收斂)。待 writing-plans;**實作第一步=dry-run 實證 headless orchestrator(R1-B1),非直接全自動上線**｜日期:2026-06-20
> 觸發:user 願景「建立永遠在迭代的 lumos」——日報產出後自動接產出、走 loop、產出改進 spec。
> 定調(由本 session 實證):**不是「無人迭代」,是「自動備料 + 自審 + 停在放行閘等人」**。放行的人是最後也是唯一真兜底(對齊「AI 全工人只驗證撐不起」「人變稀缺、只在最高槓桿放行點」)。

## 目標(一句話)

每天日報產出後,自動:抽當日最高價值 gap → brainstorm 成 spec → 跑 design-loop 審到收斂 → 把「收斂 spec + 收斂可信度報告」開成 PR、停,等人放行。**人從「每天發起這條鏈」變成「每天 review 一個 PR」。**

> **放行閘補:放行前跨家族複核(cross-family-audit,2026-06-22)**。收斂後、開 PR / 備 pending 前,多一道 **qwen3-max 跨家族複核**補 opus 同門盲點:opus 取材餵 ground-truth、qwen 跨家族判;`endorsed`/`degraded` 放行、`disputed`(major+ 異議)退回 opus 驗證續審、達 2 次升級給人;API 不可用 → degrade 回 opus 放行並於 log/LINE 標註(fail-open)。這是 backlog gap[4]「judge 抗自偏漏了換家族解法」的解——前提「換家族 $0 OAuth 做不到」已被 qwen API 破。詳 `docs/design/2026-06-22-cross-family-audit.md`。

## 邊界 / 非目標(YAGNI)

- **不自動實作、不自動 merge**:放行(merge PR)永遠人手動。自動只到「備好待放行的 spec」。
- **不取代人的判斷**:放大放行帶寬,不消滅放行。
- **N=1 的精確語義**:同時只有 1 個待放行 spec——上一個 PR 沒 merge/close 前,新 gap 只進 backlog、不展開。PR 永不堆。
- **第一版先 dry-run**(不開 PR、不發 LINE,只產到本地供人看),觀察幾天品質達標再放手到真 PR。
- **canary 限 type a/b/c**(壞§ref/未定義旗標/未定義常數),禁 type d(本 session 證明對 self-contained 新功能不公平)。

## 技術可行性(已實證,2026-06-20)

`claude -p` headless + **$0 OAuth token**(非 API key)成功 spawn 子 agent(`is_error:false, num_turns:2, 子 agent 回傳 SUBAGENT_OK`)。故 spawn 子 agent **不需上 API key**。配置:`--allowedTools "Read,Edit,Bash,Grep,Glob,Agent,WebSearch,WebFetch" --permission-mode dontAsk --agents '<json>' --output-format json`。注意:避開 OAuth 被禁的 model(如 fable-5),auditor/judge 用 opus、brainstorm 用 opus/sonnet。

> ⚠ **只證了「spawn 1 個子 agent」,沒證「orchestrate 整套 design-loop」(R1-B1)。** design-loop 需要 orchestrator 角色做:多輪、跨輪保持狀態、**巢狀** spawn 審計子 agent、自判 caught/missed、record、問收斂、折 findings。而 `lumos-design-loop` skill 明寫「**Claude 主對話編排,lumos 不 spawn**」——把這個編排角色換成一個 headless `claude -p`、且讓它自己再 spawn 子審計員,**這個巢狀 + 多輪 + 狀態保持 + 自判,§19 的單次 spawn 實證完全沒涵蓋**。**dry-run 第一關的成功判準就綁這條**:先實證 headless orchestrator 能跨輪跑完一個 design-loop,再談全鏈(尤其 judge 是 orchestrator **再** spawn 的孫層 agent——「子 agent spawn 子 agent」這層深度也在未證之列,R2-F5)。

## 架構:5 組件 + 數據流

```
日報 json(9:30) ──┐
                  ▼
[1 Gap 抽取]──(當日 gaps + backlog,去重排序,選 top-1;已有待放行 PR→只進 backlog 不展開)
                  ▼ 選中 gap
[2 自動 Brainstorm]──(派 agent 替你做方案決策,產 spec 草稿 docs/design/)
                  ▼ spec 草稿
[3 自動 Design-loop]──(opus auditor + canary a/b/c + 獨立 judge(判canary+評severity) + 強制地面事實查證 → CONVERGED)
                  ▼ 收斂 spec + 審計軌跡
[4 放行閘]──(branch + PR + 收斂可信度報告 + LINE 提醒)
                  ▼ 停
            你 review PR:merge=放行→實作 / 評論=要改 / close=否決→gap 回 backlog 或 dead
未選中的 gaps ──▶ [5 backlog](候選池 + 衰減淘汰)
```

執行形態:新 script `governance/autonomous-loop.sh`,內部一個(或數個)`claude -p` orchestrator 調用;cron `0 10 * * *`(日報 9:30 之後)。**起手先驗當日 `governance/reports/governance-<date>.json`(R2-F1:真實路徑含 `reports/` 層,裸寫會每天判不存在→loop 永不啟動)存在且 date 相符,否則跳過**(R1-m4:日報延遲/失敗時不抽到舊日報或空)。**報告缺日(週末/失敗)→ 該日跳過、不視為錯誤;連續 N 日無報告觸發 → 走 LINE 提醒(R3-F-R3-3 loop 餓死偵測,對齊 HEARTBEAT「沒人時不會有警報」)。**

## 組件逐一

### 1 — Gap 抽取(選 top-1,對齊放行帶寬)
- **輸入**:當日 `governance/reports/governance-<date>.json`(R2-F1:含 `reports/` 層)的 `gaps[]`(真 schema `{weakness, suggestion}`,R1-B2)+ `backlog.jsonl` 累積候選。
- **前置 gate(N=1 同時只 1 個待放行,R1-M4 補兩態)**:① **真 PR 模式**:`gh pr list` 查有無 open 的 `auto/spec-*` PR(部署前先 `gh auth status` 驗登入);② **dry-run 模式**:查 `governance/pending/` 有無未處理的 spec。任一有 → 今天的 gaps **全進 backlog、不展開**。
- **選法**:派 agent 讀全部候選,按判準排序選 top-1 並給理由——判準:① 有外部證據支持 ② 打在 loop engineering 主軸(尤其驗證層可靠度)③ 可落地(非「等 X 變多再做」那類擱置型)④ backlog 衰減分。
- 選中的移出 backlog 進流程;未選中的當日 gaps 寫入 backlog。

### 2 — 自動 Brainstorm(替你做方案決策)
- 派 agent 跑 brainstorm 流程,但**去掉互動**:原本要問人的澄清/方案選擇,由 agent **自己權衡 2-3 方案、選最滿足 gap 的**,並把「為什麼選這個、否決了什麼」寫進 spec。
- 產出 spec 草稿(寫 scratch、收斂後才入庫)。同既有 spec 格式,含目標/邊界/組件/誠實天花板/測試/**知識同步影響**/審計修正紀錄區。
- **知識同步影響(必填,防 drift)**:每份 spec 須列「此改動若實作,影響哪些方法論論述(`docs/methodology` 兩篇)/ skills(`lumos-*`),各該怎麼同步」。理由:loop 每天改實作,若不宣告碰了哪些知識,論述/skills 會落後於實作;此節讓人放行 PR 時一併更新知識,把 drift 堵在放行那一刻——架構圖即合約(知識跟實作走)套在 loop 自己身上。

### 3 — 自動 Design-loop(全自動判收斂 + 四條補償)
**覆寫** `lumos-design-loop` skill 的若干預設行為(R1-M1/M2 修正:不是「沿用既有機制」——以下幾條都跟 skill 預設相反,故須**參數化** skill 或 autonomous-loop 自帶覆寫;且要評估對手動 loop 使用者的影響):
- **opus auditor 起手**(**覆寫** skill 預設「sonnet 起手、連 2 missed 才升 opus」——本 session 證明 opus 一上來就抓到 sonnet 漏的)。
- **canary 限 type a/b/c**,禁 d(**覆寫** skill 的 `清單[(N-1)mod4]` a/b/c/d 固定輪換——改 a/b/c 三類輪換;本 session 證明 type d 對 self-contained 新功能不公平)。每輪 token 定位。
- **獨立 judge agent:判「canary 抓到沒」+ 回報 severity(2026-06-20 judge-severity-gate 落地後擴充)**:orchestrator 植 canary,judge 判「auditor 有沒有點出植入瑕疵的性質」**並回報排掉 canary 後最嚴重真 finding 的 severity**(據實評、finding 層級客觀二值)——**severity 改由 judge 回報、不再 orchestrator 自填**(斷開收斂自填閘,詳 `judge-severity-gate` spec)。**但 judge 仍不檢查選的 gap / brainstorm 方向對不對**——它把「canary + severity」兩維推離被審者,但不是全鏈的外部錨點。全鏈 AI 自選 gap、自 brainstorm 的回歸缺口,唯一外部錨點仍是末端人 review PR(見誠實天花板)。
- **強制地面事實查證(最重要,cib 教訓)**:auditor prompt 硬性要求——spec 裡每個「現況假設」(欄位存在、函數簽名、檔案在不在、常數值)**必須實際 `grep`/`Read` 驗過**,報告裡列「查了哪些假設、各自結果」。逻辑審不算數;cib「守空集合」正是只逻辑審會漏、手動 grep 才接住。
- 跑到 `lumos canary record` + `lumos loop status --need 2` CONVERGED。

### 4 — 放行閘(PR + 可信度報告 + LINE)
- 收斂後:commit 到 `auto/spec-<topic>-<date>` branch,`gh pr create`。
- **PR body = 收斂可信度報告**:canary 用了哪些類型 / auditor 是誰、幾輪收斂、各輪 severity / judge 對每輪 canary 的判定 / **地面事實查證清單(查了哪幾個假設、grep 結果)** / 殘留風險清單(自動模式已知未兜底的點)。
- 發 LINE:「今天備好 1 個待放行 spec:〈title〉,可信度〈摘要〉,PR:〈link〉」。
- 人的放行動作=review PR:**merge=放行**(進實作,人手動或下階段)/ **評論=要改** / **close=否決**(gap 回 backlog 或標 dead)。

### 5 — backlog + 防堆積
- `backlog.jsonl`:每條由日報 gap 映射——日報 `gaps[]` **真實 schema = `{weakness, suggestion}`**(R1-B2 查證,**無** value_score/source_date),故 backlog 條目 = `{weakness, suggestion, source_date(寫入時補), value_score(見下), last_seen}`。
- **value_score 來源(誠實標明,R1-B2)**:由 AI 評分 agent 按組件 1 判準給分——**這是未經外部驗證的自評**,進誠實天花板(AI 替自己的待辦排序、有自我強化偏誤)。
- **衰減**:value_score 每天 ×0.95;低於閾值淘汰(防僵尸 gap 永占位)。
- backlog 本身=「lumos 待改進方向」可排序視圖(對齊 governance 可觀測)。
- **崩潰安全預設(R1-m1,取代懸空的「災難恢復」)**:claude -p 超時 / 子 agent 死 / 中途崩 → **事務性:要嘛完整產出 PR,要嘛什麼都不留**(不留半成品 PR / 半截 branch / 不污染 backlog)。無人看顧下「無聲寫壞狀態」是已知風險(對齊日報 HEARTBEAT 警告)。
- **發 LINE(R1-m3 + R2-F2 修正,誠實降級)**:復用 `curl broadcast` + `$HOME/.config/ai-daily/line_token` 的**傳輸層**;但 `governance_flex_builder.py` 是**日報專用**(硬讀 `overview/articles/inspirations/gaps` schema、無 PR/title/可信度欄位,R2-F2 查證),**不可復用**——PR 待放行訊息**另寫一個小 builder**。即:復用傳輸層,訊息 body 另寫,不是「完全不另造」。待放行 PR 超過 N 天沒動 → LINE 提醒一次。

## 誠實天花板(必寫進 PR 可信度報告 + 系統文件)

1. **放行的人是最後也是唯一真兜底**:全自動判收斂仍是**沒閉合的迴歸**——獨立 judge 只把「canary 抓到沒」的自評**推遠一層**(judge 也是 AI、也會錯),未消滅;**且 `lumos canary record` 的 severity 原由 orchestrator 自填=全自動判收斂最弱環,已被 `judge-severity-gate` 修(2026-06-20):severity 改由獨立 judge 據實回報、不再被審者自填,斷開『收斂了沒由被審者自填』那道閘**。**但這把最弱環推進一層、未消滅**(R3-F-R3-1 的後續):judge 同時掌 canary-caught + severity(集中化風險)、只讀 auditor 文字不自己 grep(地面錨弱)、且是「規範非機制強制」(orchestrator 仍可違規轉錄 judge 值)。dry-run 仍須人工抽查 judge severity_rationale vs 實際 findings。CONVERGED 是「連 2 輪 opus **canary 被抓到、且**沒挑出 blocker/major」(R2-F3:收斂同時要求 canary caught,漏抓該輪不採信——別把收斂說成只剩『沒挑出問題』那一半),仍不證沒有更深問題。**本輪 R1 本身就是活證:這份 spec 用『強制地面事實查證』審自己,抓到自己 4 個沒查地面事實的假設(B1/B2/M1/M2)——證明這條補償必要,但也證明『沒人 grep 就會放過』,而自動模式裡那個 grep 的人不在。**
2. **自動 brainstorm 沒人回澄清** → spec 品質天花板低於有人在場的 brainstorm;「替你決策」是 AI 自選方案,**選錯方向的風險比有人時高**(cib 那種前提錯,自動模式更容易放過——這正是強制地面事實查證要擋的,但擋不保證全擋)。
3. **AI 判「哪個 gap 值得做」= AI 決定改自己的方向**,有自我強化偏誤風險(可能偏好它「擅長」或「上次做過」的方向)。放行的人要警覺方向是否被 AI 帶偏。
4. **這是放大放行帶寬,不是無人迭代**:它把「發起 + 篩選 + 自審備料」自動化,把「判斷收斂可不可信 + 放行」留人。

## 測試策略

- **第一版 dry-run**(關鍵):`--dry-run` 不開 PR、不發 LINE,只把收斂 spec + 可信度報告寫到 `governance/pending/` 供人看。**先跑幾天**,人觀察:自動選的 gap 合不合理?自動 brainstorm 的 spec 能不能看?自動 design-loop 的收斂可不可信(尤其地面事實查證有沒有真查、judge 判 canary 準不準)?達標再開真 PR + LINE。
- 單元測試:gap 抽取的排序/去重/前置 gate(有 open PR 則不展開);backlog 衰減淘汰;可信度報告生成。
- 用合成 governance json + 假 backlog 驗流程,不每次真燒 claude -p。

## 成本與失控保護(R4 補)

- **單日粗估**:brainstorm(1 opus)+ design-loop(≤6 輪 ×[1 opus auditor + 1 opus judge])+ gap 評分(1)≈ **單日 ≤14 個 agent 調用**。走 $0 OAuth 訂閱(無 API key 費),但受訂閱額度 / rate limit 約束。
- **失控保護三道硬界**:① design-loop `max cap = 6 輪`(既有,不收斂即停);② `N=1` 同時只 1 個待放行(既有,不並發多 spec);③ 連續撞 cap(不收斂)→ 停 + LINE 告警「今日 spec 未收斂、未開 PR」,別無限燒。
- **dry-run 先觀察實際單日 token / 時長**再放手到真 PR。不設精細 token 預算(YAGNI,訂閱內 $0)。

## 審計修正紀錄

### R1(2026-06-20,canary 類型 a=壞§ref,**opus**,caught)
canary(引用不存在的〈組件 6 — 災難恢復〉)被抓到(m1,並識破 token)。**最漂亮的自指**:opus 用本 spec 自己倡導的「強制地面事實查證」,抓到本 spec 自己 4 個沒查地面事實的假設(B1/B2/M1/M2)。worst real = blocker,全折:
- **blocker**:**B1** 只實證 spawn 1 個 agent、沒證 orchestrate 整套(巢狀+多輪+跨輪狀態+自判 caught/missed)→ 技術可行性加「dry-run 第一關綁實證 headless orchestrator」;**B2** 日報 `gaps[]` 真 schema=`{weakness,suggestion}`,原 backlog `{gap,source_date,value_score,last_seen}` 凭空 → 明定映射 + value_score=AI 自評進天花板。
- **major**:**M1/M2**「禁 type d / opus 起手」其實是**覆寫** `lumos-design-loop` skill 預設(skill 是 a/b/c/d 固定輪換 + sonnet 起手),非「沿用既有機制」→ 改寫為明確覆寫 + 評估手動 loop 影響;**M3** 獨立 judge 作用域僅「canary 抓沒抓到」、不檢查真 findings / 方向 → 標明非全鏈錨點、殘留缺口列回誠實天花板。
- **minor**:m1 組件 6 懸空(=canary,改補崩潰安全預設);m2 record severity 仍自評(天花板補);m3 LINE 復用既有 broadcast;m4 cron 起手驗當日日報存在。

### R2(2026-06-20,canary 類型 b=未定義旗標,opus,**MISSED**)
canary(`--force-expand` 未定義旗標)**漏抓**——opus 在 F4 點到它、但合理化成「autonomous-loop.sh 自家旗標、待實作介面、不算缺陷」,未點「spec 它處無任何 script 旗標介面定義=憑空」的性質 → 判 missed(該輪判決不採信)。**誠實記:此 canary 偏不公平**(「待實作 script 的旗標」本就可以是合理待定義介面);且 opus 極醒著,找到 2 個真 major——又是「spec 倡導 grep 卻自己沒 grep」的同病:
- **major**:**F1** 日報路徑裸寫漏 `reports/` 層(cron stat 每天判不存在→loop 永不啟動)→ 全篇補 `governance/reports/`;**F2** `governance_flex_builder.py` 是日報專用 schema、無 PR/title 欄位、不可復用 → m3 誠實降級為「復用傳輸層、訊息 body 另寫」。
- **minor**:**F3** 收斂語義漏「canary caught 那半」(天花板補全);**F5** judge 孫層 spawn 亦未證(§技術可行性補)。
> 再次實證「canary 可信度因 spec 而異、真 findings 比 canary caught 更可靠」(見 memory)。最自指:本 spec=自動 design-loop,它正被自己描述的那套 design-loop 用「真 findings 兜底、而非靠 canary」驗證並修實。

### R3(2026-06-20,canary 類型 c=未定義常數,opus,caught)
canary(`DECAY_RATE`/`BACKLOG_FLOOR` 未定義常數)被抓到(識別符清查表標憑空、識破 token;type c 比 R2 type b 公平,opus 一抓即中)。排掉 canary 後 1 真 major + 1 minor:
- **major**:**F-R3-1** R2-F3 只補了收斂的「文字定義」,沒補自動模式「**severity 自報 = 收斂門檻自填**」的執行面缺口——severity∈{clean,minor} 直接決定 loop status 收斂、judge 不覆蓋 severity → 收斂了沒由被審者自填,全自動判收斂最弱環。折入天花板 + dry-run 抽查每輪 severity vs 實際 findings。
- **minor**:**F-R3-3** 報告缺日→loop 靜默不跑無告警 → 補 loop 餓死偵測。
其餘各節評 sound(技術可行性誠實、F1/F2 修乾淨、天花板整體到位)。

### R4(2026-06-20,canary 類型 a=壞§ref,opus,caught)
canary(〈§成本模型〉死§ref)抓到(識別符清查對照 17 個 header 確認無此節、識破 token)。排掉 canary 後 **0 blocker / 0 major / 1 minor**(本輪乾淨):
- **minor**:成本模型實質缺席(排掉 canary 身分仍真)——spec 提要算成本卻通篇無上界/預算/估算 → 補「成本與失控保護」節(單日 ≤14 agent、三道硬界、dry-run 觀察)。
其餘各節 sound:**地面事實 7/7 全符真實 code/檔案**,R3 兩條修法乾淨且與 `scripts/lumos:1214` 收斂邏輯精確對齊,天花板無漏列、R1-R3 canary 未洩漏進真檔。

### R5(2026-06-20,canary 類型 c=未定義常數,opus,caught)→ **CONVERGED**
canary(`AGENT_MAX_TURNS` 未定義常數 + 洩漏 token)抓到(識別符清查表)。排掉 canary 後 **0 blocker / 0 major / 0 minor = clean**:本體地面事實全符、R1-R4 修法扎實、天花板精確對齊 `scripts/lumos:1213` `good(r)` 邏輯。**收斂達成**(tail = R4 minor + R5 clean,連 2 輪 caught+乾淨)。
> 諷刺註:opus 點出 R5 canary「植在修正者最鬆懈、最容易宣告勝利的那節」(R4 剛宣告 0 major 的成本節)——又一次自指印證:連 design-loop 自己都會在「剛宣告乾淨」處鬆懈,放行的人是最後兜底。
