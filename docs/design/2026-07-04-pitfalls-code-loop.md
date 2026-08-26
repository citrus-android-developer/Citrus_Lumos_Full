# 設計:實務隱患意識 + 代碼審計對齊(pitfalls-code-loop)— `lumos pitfalls` 三模式 + code-loop 對抗代碼審

- 日期:2026-07-04
- 狀態:design-approved(2026-07-04 收斂放行)
- 收斂紀錄:design-loop 8 輪(K=3 high 級;canary 6/8 caught,r2/r5 missed 依規作廢重挖);GATE PASS(K-streak R6+R7+R8 ∧ G1 11 座標全真 ∧ G2 findings [2,1,0] 枯竭)。辯方 r1 降 4 major、r4 維持 1 major(同步表漏 gate 契約,折入)、r3 降 1 major;qwen 跨家族 1 條 major 經機械反證(把前提節現況陳述誤讀為契約矛盾)→ endorsed-after-refute 放行。
- 動機來源:使用者觀察——AI 開發仰賴模型自決實作方式、只需通過最終驗證,但實作選型的實務隱患(效能/冪等/併發/資源)沒人逼它回答;且**審計火力頭重腳輕**:spec 有 canary/辯方/跨家族/證據閘一整套對抗機器,代碼只有 task reviewer + 終審兩道普通眼睛——最該被層層審的東西審得最薄。
- loop_id:pitfalls-code-loop

## 目標(一句話)

補齊兩層:**提問層**——新 vault-free 指令 `lumos pitfalls`(spec 模式逼答設計決策級隱患、diff 模式把代碼級風險位置攤給審查者);**對抗層**——新 user-scope skill `lumos-code-loop` 把 design-loop 的對抗紀律(canary 驗醒著、辯方殺假陽性、證據閘收斂)1:1 搬到分支終審,風險分級觸發(pitfalls --diff 命中才升級,日常零命中分支不變慢)。

## 核心判斷(brainstorm 收斂,2026-07-04)

- **缺的不是知識是機制**:效能/冪等/併發的通用坑模型都知道,不會主動應用——mechanical not motivational,要機械關卡逼答,不是整理最佳實踐文檔(模型已知、整理即過時)。真正值得收集的是自家事故史與平台硬約束(**留 v2**:事故語料進架構圖+進場自動餵,需事故回填習慣先養起來)。
- **隱患分兩層、錨點不同**:設計決策級(冪等鍵/重試策略/一致性模型——等寫 code 才想就晚了)錨在 spec;代碼級(N+1/race/資源洩漏)只在真 diff 上看得見,錨在終審。
- **代碼側需要醒著訊號**:code-loop 收斂=「連 K 輪沒挖到新東西」,無醒著驗證則蓋章 reviewer 連說兩次 LGTM 即收斂——r9(2026-07-04)連 opus 都漏抓 canary 的實證在前。
- **代碼 canary 的污染風險比 spec 嚴重**(使用者質疑,成立):spec canary 是加法散文,代碼假 hunk 改變程式語意,reviewer 可能從它推導出衍生 findings(幻影)。→ 三道防污染(見組件 ③),外加 mutation 冒煙為零污染的測試層補充錨。

## 方案評比與選擇

| 軸 | 選定 | 否決與理由 |
|---|---|---|
| 適用範圍 | 共用層(手動 pipeline + 自主 loop 都吃) | 只蓋單邊:效能/併發主戰場在業務專案,治理面在 loop,擇一都缺半 |
| checklist 結構 | **通用 3 問恆印 + 命中類專屬追問** | 只做類專屬:漏掉效能/併發主場景(不綁四風險類);大而全問卷:寫「無」疲勞使其淪為儀式 |
| ② 載體 | **lumos 新指令**(vendored 到各專案即用) | 純 prompt 層:違反 mechanical-not-motivational;擴充 difficulty.py:手動端拿不到(governance/ 不 vendor) |
| ① 強制力 | **`--check` 機械擋**(缺節 rc 1) | 純紀律:漏寫無機械訊號;硬進 doctor/lint:design 檔不在 vault、寫作中途被擋擾人 |
| code-loop 觸發 | **風險分級**(--diff 命中→終審升級,零命中→現行單 reviewer) | 全分支都跑:日常小功能多燒 2-3 輪 opus;人手動指定:靠人記得,漏的恰是最危險的 |
| 醒著訊號 | **reviewer bug-canary(帶三道防污染)+ mutation 冒煙(可選機械錨)** | 只 mutation:審查層敷衍抓不到(mutation 驗測試層非審查層);無訊號:loop 空轉收斂 |

## 前提與既驗事實(2026-07-04)

- **風險類已有機械載體**:`governance/autonomous_loop/difficulty.py` 的 `RISK_CLASSES` 四類(payment/external-send/prod-irreversible/self-governance)+ `assess`/`assess_spec`(黑名單剝除/防呆回退)。但它**不在 vendored 工具組**(`_VENDORED_TOOLKIT` 只含 scripts/ 五檔+hooks/templates),他專案拿不到——pitfalls 的詞表須自帶於 `scripts/lumos`,與 difficulty 的一致性靠漂移守衛測試(兩表類名集合不等即紅)。
- **diff 掃描有先例**:doctor Check H 的 `IRREVERSIBLE_HINT_PATTERNS`(`scripts/lumos` 內,7 條 regex 掃 staged diff `+` 行、skip `.md`)——pitfalls `--diff` 同型放大,但獨立函數、不動 Check H。
- **spec 抽取/剝除機械已收斂**:`_refcheck_scan`(refcheck/G1 共用)與 `FENCE_RE`/`INLINE_CODE_RE`(`scripts/lumos:39-40`);pitfalls spec 模式的剝除規則對齊 assess_spec 慣例(黑名單樣板節/inline-code/檔名)但**自帶實作**(同 refcheck 對 Check P 的「同款不共用」先例——消費粒度不同)。
- **收斂原語可直接複用**:`canary record --loop/--severity/--findings` 與 `loop status --need K --gate --spec --repo`(K-streak∧G1∧G2)。**現況 `--gate` 必須給 `--spec`**(缺則 rc 2)——code-loop 沒有 spec 對象,G1(引用座標)對代碼無意義,需小改(組件 ②)。
- **終審有 package 慣例**:subagent-driven 的 `review-package BASE HEAD` 產單一 diff 檔給 reviewer——code-loop 的 canary 植入對象就是此檔的工作副本。
- **spec 節名慣例**:orchestrator-prompt 步驟 1 的節名清單(目標/邊界/組件/誠實天花板/測試策略/知識同步影響/審計修正紀錄)是 **prompt 散文慣例、無機械強制**(r4-F5:pitfalls --check 將是第一個機械強制某節名的機制);手動端同構(docs/design/ 慣例)。
- **風險分級已上線**:risk-tiered-review(設計 2026-07-03、2026-07-04 merge)——spec 層已有 tier;本設計把同一哲學延伸到終審(diff 層 tier)。

## 範圍(四組件)

### ① `lumos pitfalls`(新 vault-free 指令,`scripts/lumos` 內)

CLI:`lumos pitfalls <md檔> [--repo <root>] [--check] [--json]` 或 `lumos pitfalls --diff <base>..<head> [--repo <root>] [--json]`。repo 解析沿 refcheck 慣例(顯式優先、cwd 向上找 .git、失敗 rc 2)。

**詞表(自帶,PITFALL_CLASSES)**:類名與 difficulty.RISK_CLASSES 四類**同名**(漂移守衛釘);每類附**提問清單**:
- 通用(恆印,不綁類):併發——同資源兩請求同時進來會怎樣?效能——這段會進熱路徑/大資料量嗎?資源——連線/檔案/鎖有沒有確定釋放?
- payment:冪等鍵怎麼設計?重複扣款如何防?部分失敗怎麼補償/對帳?
- external-send:重試會不會風暴?收端如何去重?超時與速率上限?
- prod-irreversible:回滾路徑?遷移順序與鎖表窗口?
- self-governance:誤擋的逃生口?繞過有沒有留痕?

**spec 模式**(`<md檔>`):剝除(黑名單樣板節標題子字串「方案評比/canary 相容性/誠實天花板/審計修正紀錄」→ 剝 inline-code/檔名)→ 詞面掃描 → 印「通用 3 問 + 命中類追問」。`--check`:**命中任一類 且 全文無 `## 實務隱患` 標題(子字串比對,`##` 級)→ rc 1**;有節或零命中 → rc 0。只驗「有沒有寫」,不驗內容(內容=審計員/人的地盤)。

**diff 模式**(`--diff <range>`):`git diff <range>` 取新增行(`+` 開頭、排除 `+++`;**過濾繼承 Check H 全套**,r4-F3:skip `.md/.txt/.rst`、測試檔(_TEST_PAT 同款)、純註解行——測試 fixture 內合法樣板不觸發無謂升級),掃**代碼級 pattern 表**(獨立於詞表;初版:迴圈體內 query/HTTP 呼叫、`requests.`/`httpx.` 無 `timeout=`、`INSERT/UPDATE/DELETE` 無交易語境詞、`open(` 無 `with`、`threading`/共享可變狀態無鎖詞、`time.sleep` 在迴圈)→ 輸出 manifest:`{file, line, class, pattern, question}` 逐條 + 尾行 `tier: high|standard`(命中任一=high)。manifest `line` 由 unified diff `@@` 標頭 + hunk 內行計數推導(標準記帳 ~10 行狀態機,r4-F2;精度僅供 reviewer 導引——pillar-1 的不相交判定是檔/hunk 級集合關係,不依賴行號精度)。**diff 模式的 `class` 用代碼形態類軸(併發/效能/資源,即通用 3 問的軸)、不用四業務類**(r3-F1:每條 pattern 綁定其形態類——迴圈內 query/sleep→效能、無 timeout/open 無 with→資源、無鎖/無交易→併發;與 spec 模式詞表是兩個類集合)。**rc 恆 0(提示器非閘)**;`--json` 給結構化輸出供接線。

### ② gate 小改:`loop status --gate` 的 `--spec` 改可選

- 缺 `--spec` 時 G1 印 `[gate] G1 refcheck: skipped(無 spec 對象)`、**不計 fail**;K-streak 與 G2 照常。有 `--spec` 行為分毫不變(回歸測試釘)。
- 理由:code-loop 沒有 spec 可核座標,但**必須吃 G2 發現枯竭**——否則代碼側收斂退回純輪次計數,違反 convergence-evidence-gate 才立的判準。

### ③ `lumos-code-loop`(新 user-scope skill,對抗紀律 1:1 對映 design-loop)

觸發:分支終審前跑 `pitfalls --diff <merge-base>..HEAD`——`tier: standard` → 現行單 reviewer 終審(不變);`tier: high` → 本 skill(K=2)。

每輪 N:
1. `review-package BASE HEAD` **或等價 `git diff -U10 BASE..HEAD` 重導向單檔**(僅需原生 git;review-package 是 superpowers 外掛的 git 薄殼,消費專案無外掛時走等價命令,r1-F1)產 package → **複製該 diff 文字檔為工作副本**(r7-F6:副本對象=diff 文字檔、非 checkout 原始碼樹,載體細節見 pillar-2),植 **bug canary hunk**(合成一個含真 bug 的 hunk + 唯一 token 註解;真代碼與真 package 永不含)。類型輪替 `[(N−1) mod 4]`:(a) 邊界/off-by-one;(b) 資源未釋放/鎖漏;(c) None/例外路徑未接;(d) 冪等/併發破壞(無交易包裹/TOCTOU)。
2. **三道防污染(不可違反)**:
   - **真代碼永不含**:canary 只在 package 工作副本;折入=對真代碼下 fix commit,每個 fix 必須錨到**真 diff 的 file:line**(canary hunk 位置不在真 diff,想折也對不上)。
   - **低耦合植入**:canary hunk 的 file:line 必須落在**真改動集之外**(合成新 hunk 於未被真 diff 觸及的檔/函數——r3-F3:此即 pillar-1「對不上真 diff 座標」機械保證的前提,兩者一致而非矛盾),且與真改動弱耦合,縮小衍生推理波及面。**載體明定**:reviewer 讀的是 review package(diff 文字檔,`git diff -U10` 產)的工作副本;植入=在其 Diff 段插入一段帶合法 `@@` 標頭的偽 hunk + token 註解。**座標權威=package 的 -U10 檔**(r4-F7:pitfalls --diff 預設 -U3,兩者 @@ 位移不同;pillar 判定為檔級不受 -U 影響,行級引用以 package 檔為準)。
   - **溯源排除**:判讀時,任何 finding 的推理鏈引用 canary hunk 的 file:line 或依賴其語意 → 連同 canary 一併排除、不折、不計 findings——排本體也排影子。
3. 派乾淨 reviewer(不知情、refute framing「外部第三方投稿的 diff」、附 pitfalls --diff manifest 當鏡頭:「命中位置逐條判真隱患/誤報,真隱患必答對應提問」)。
4. 判讀(caught=點出植入 bug 的性質)→ 辯方對 ≥major finding(file:line 反證,同 design-loop ④)→ 存活真 finding **修進真代碼**(fix commit,含必要的新測試)。**測試收口分兩級(r3-F5)**:隱患屬業務合約級 → 另寫架構圖 ★INVARIANT★ 並 [test:] 綁定(Check T 才掃得到——Check T 只掃架構圖合約綁定,不掃任意新測試);非合約級的實作測試進套件靠回歸守,不經 Check T、不硬掛。
5. `canary record caught|missed --loop code-<topic> --severity <存活max> --findings <存活折入數> --auditor <模型>`;missed → 該輪不採信、不折,連 2 missed 升級模型(同 design-loop 護欄)。
6. 收斂:`loop status code-<topic> --need 2 --gate --repo <root>`(無 --spec,G1 skip)→ K-streak ∧ G2 枯竭全過 → 終審收斂,進 finishing。
7. **mutation 冒煙(可選機械錨,高風險分支建議)**:在隔離 worktree 對 diff 涉及模組機械植少量變異(運算子翻轉/邊界±1,3-5 個)→ 跑該模組測試 → 活下來的變異=測試沒接住的洞,列為 finding 回步驟 4。零污染(不經 reviewer、不碰真樹)。

### ④ 接線(共用層落點)

- `CLAUDE.md` 主動調用表 + `scripts/templates/graph-discipline.md`(vendored 到各專案):加規則「分支終審前跑 `lumos pitfalls --diff`;tier high → 調用 `lumos-code-loop`」。
- `governance/autonomous_loop/orchestrator-prompt.md`:步驟 1 節名清單(散文慣例)加「實務隱患」;步驟 2.8(refcheck)旁加 `pitfalls --check`(rc 1 → 補節再審)+ 提問清單附給 auditor 當鏡頭之一。
- `skills/lumos-design-loop/SKILL.md`:同構——審前 `pitfalls --check`,缺節先補;清單附審計員。
- 自主 loop 的實作端即本 repo 的 subagent-driven 流程,吃 CLAUDE.md/skill 慣例,無另行接線。

## canary 相容性(不可違反)

- `pitfalls --check` 只驗 `## 實務隱患` **節標題存在性**,不驗 §ref/旗標/常數/內文——spec-loop 的 canary 保留地(內部一致性)不受侵犯。
- code-loop 的 bug canary 是**新開的保留地**(package 副本層),與 spec canary 互不干涉;pitfalls --diff 的 pattern 掃描跑在**真 diff** 上,canary hunk 不在真 diff → 天然不相交。

## 邊界 / 非目標(YAGNI)

- ❌ **事故語料進架構圖+進場自動餵**(v2):需事故回填習慣先養起來;通用坑不收集(模型已知)。
- ❌ **不做通用 mutation testing 基建**(mutmut/依賴):冒煙用 3-5 個手植變異+既有測試,零第三方依賴;全量 mutation 留給有 CI 之後。
- ❌ **不動 difficulty.py / Check H / refcheck 既有代碼**:pitfalls 自帶詞表與 pattern 表;漂移守衛只釘**類名集合**(pattern 表是代碼形態 regex、difficulty 無對應物,不受守衛,r1-F5)。
- ❌ **pattern 表不追全**:提示器定位,初版 6-8 條;誤報靠 reviewer 判、漏網靠 canary 紀律+測試。
- ❌ **--check 不驗內容品質**:「寫無也要寫+為什麼無」是紀律要求,機械只驗節存在。
- ❌ **不改 task review(逐任務)流程**:code-loop 只掛終審;逐任務審維持現行(成本)。

## 誠實天花板

1. **pattern 掃描是提示器不是偵測器**:N+1/race 多數形態 regex 抓不到;買到的是「reviewer 注意力被導到高風險位置」,漏網靠 reviewer 本身 + canary 紀律 + 測試。**單行掃描的能力邊界(r3-F4)**:所引 Check H 先例是逐 `+` 行單行 regex——「迴圈體內/交易語境/續行 timeout」等跨行語境單行不可判,實作以**單行 + 小行窗啟發**為限(如 ± 數行窗內同現 for/while 與 query 才記命中),做不到的形態誠實不掃、不硬湊;「同型放大」指掃描骨架,非宣稱能力等同。
2. **「實務隱患」節可敷衍填**:--check 只驗存在;內容品質靠 design-loop 審計員(拿提問清單當鏡頭)與人。
3. **bug canary 的校準與污染殘餘**:「認真審抓得到、不一眼看穿」靠植入者自律(同 design-loop 校準鐵則);**溯源排除規則由編排者人工判**(finding 是否為 canary 影子),無機械強制——判錯方向偏「多排」(寧可少折不污染),殘餘=真 finding 被誤排的假陰性,由下一輪重挖兜底;**間接聯想幻影(未顯式引用 canary file:line、僅因鄰接 canary 而聯想到真碼風險者)同樣走多排**(r1-F4),折入端另有機械錨兜底(fix 必錨真 diff 座標+辯方 file:line 反證)。
4. **mutation 冒煙的誠實邊界**:3-5 個手植變異是抽樣不是覆蓋;活變異=測試缺口的存在證明,死光≠測試充分;flaky 測試會汙染訊號(跑前先確認套件綠)。
5. **code-loop 收斂少一道 G1**:gate 對代碼只剩 K-streak∧G2,「引用座標」類機械錨無對應物;衍生的機械錨(如 mutation 全滅)留 v2 評估是否進 gate。
6. **通用 3 問對純文檔類 spec 也會印**:答「無」即可,3 問疲勞成本可接受;若實測淪為儀式,v2 再收窄觸發條件。
7. **成本**:高風險分支終審 +2 輪起跳(reviewer+judge+辯方),風險分級控總量;標準分支零增量。

## 測試策略

CLI subprocess 風格(`scripts/test_lumos.py`,`run`/`check`/t_ 前綴);fixture 用 temp repo + `--repo` 顯式。

1. **spec 模式命中**:含「stripe/寄送」的 md → 印 payment/external-send 追問 + 通用 3 問。
2. **spec 模式零命中**:純內部重構 md → 只印通用 3 問;`--check` rc 0。
3. **--check 缺節擋**:命中類且無 `## 實務隱患` → rc 1;補節後 → rc 0;零命中無節 → rc 0。
4. **--check 剝除規則**:風險詞只在「審計修正紀錄」樣板節 → 不觸發(黑名單剝除起作用)。
5. **--diff 命中**:fixture repo 兩 commit,新增行含 `requests.post(` 無 timeout、迴圈內 `SELECT` → manifest 各命中 + `tier: high`;rc 0。
6. **--diff 零命中**:純註解/文檔 diff → 空 manifest + `tier: standard`。
7. **--diff 過濾全套**:`.md/.txt/.rst`、測試檔(_TEST_PAT 同款)、純註解行的新增行皆不掃(參數化案逐一斷言,r6-F3——R4-F3 的防誤升級保證須有回歸釘,不只 .md)。
8. **漂移守衛**:pitfalls 類名集合 ≡ difficulty.RISK_CLASSES 集合(import 比對,不一致即紅)。**落點=`scripts/test_autonomous_loop.py`(已 import difficulty、非 vendored)——toolchain-only 守衛,不隨工具組發貨**(r1-F3;消費端詞表就地改由 lumos update 的 filecmp 覆補自癒兜底);**守衛同時釘黑名單集合**(pitfalls 剝除黑名單 ≡ difficulty._BLACKLIST,r4-F6——黑名單是第二個複製面,不能只釘類名)。
9. **gate --spec 可選**:無 --spec → G1 印 skipped 不計 fail,K-streak∧G2 決定 rc(**既有 t_loop_gate 案 14 的「缺 --spec → rc 2」斷言隨之改寫為新契約**,r1-F2);**有 --spec 行為分毫不變**(既有 gate 測試全綠回歸)。
10. **回歸**:兩套件全綠。

> 覆蓋誠實聲明:組件 ③(skill 散文)與 ④(prompt/模板接線)無機械測試——靠知識同步表點名 + 漂移守衛慣例(marker 出現於 SKILL.md 與 graph-discipline.md 的既有測試模式可加一條)。

## 知識同步影響

| 受影響文件 | 需同步什麼 |
|---|---|
| `CLAUDE.md` + `scripts/templates/graph-discipline.md` | 主動調用表加「終審前 pitfalls --diff;tier high → lumos-code-loop」 |
| `governance/autonomous_loop/orchestrator-prompt.md` | 步驟 1 節名清單加「實務隱患」;步驟 2.8 旁加 pitfalls --check + 清單餵 auditor |
| `skills/lumos-design-loop/SKILL.md` | 審前 pitfalls --check 步 + 清單附審計員;**gate 措辭同步**(r6-F2:12/35 行現記 `--gate --spec` 必帶——組件 ② 後補註 code-loop 情境 `--spec` 可省、G1 skip) |
| skills/lumos-code-loop/SKILL.md(新檔提案,散文書寫免 refcheck 誤報) | skill 本體(組件 ③) |
| `skills/lumos-project-notes/SKILL.md` | 指令表加 `lumos pitfalls` 三模式;**gate 契約段同步**(r4-F4:收斂留痕段 ~899 行與指令表 ~92 行現記 `--gate --spec` 必帶、「引用壞座標不收斂」——組件 ② 上線後改記 `--spec` 可選、code-loop 走 G1 skip) |
| `docs/methodology/架構圖即合約.md` | 強制力層表加「pitfalls 提問閘 + code-loop 終審對抗」;審計火力對齊敘事;**設計前審計 loop 節的 gate 描述同步 --spec 可選**(r4-F4) |
| `docs/methodology/架構圖即合約-對外論述.md` | 白話:AI 寫代碼前被逼答「這樣做上線會出什麼事」,寫完的代碼跟設計稿一樣被「考官+辯方」輪番審 |
| memory `autonomous-iteration-loop` | 補:代碼側對抗紀律上線 |

## 審計修正紀錄(design-loop)

### R1(2026-07-04,canary type a=壞§ref「§輸出契約與降級矩陣」,opus,**CAUGHT**,辯方裁決後 severity=minor,存活 findings=6)

canary 被正確識別(F6 明指全文標題清單無此節、為壞引用,並點出 token)。judge 原評 F1-F4 四條 major,獨立辯方逐條以 file:line 反證降級:
- **F1 major→minor**(反證:review-package 本體=git log/diff 薄殼;spec 組件 ① 已用原生 `git diff`)→ 步驟 1 補等價命令。
- **F2 major→minor**(反證:#9 原文明切「無/有 --spec」兩半,案 14 屬前者=主動要改的對象)→ #9 點名案 14 隨改。
- **F3 major→minor**(反證:test_autonomous_loop.py 已 import difficulty 且非 vendored=天然落點)→ #8 指定落點 toolchain-only。
- **F4 major→minor**(反證:天花板 3/核心判斷已認領;fix 錨真 diff 座標+辯方 file:line+mutation 為既有機械錨,非純自律)→ 天花板 3 補間接聯想子形態。
- F5(詞表 vs pattern 表守衛範圍混淆)、F7(merge 日期精確化)minor 直折;F8/F9 為肯定性查證(clean)。

### R2(2026-07-04,canary type b=未定義旗標 `--strip-profile`,opus,**MISSED**,判決不採信)

auditor 產出三條看似有價值的 finding(package 載體語意/迴圈 pattern 可行性/skill 分發)但未點出植入的未定義旗標——依規該輪不採信、全部不折(真洞留待醒著的輪次重挖,r3 果然重挖到 F3/F4 同族)。r3 起 framing 加碼。

### R3(2026-07-04,canary type c=未定義常數 `MUTATION_SMOKE_BUDGET`,opus,**CAUGHT**,辯方裁決後 severity=minor,存活 findings=4)

canary 被正確識別(明指無賦值、僅一處出現、skill 散文無常數載體——雙重瑕疵)。judge 原評 F1=major(diff manifest class 無來源),辯方反駁成功降 minor:spec 從未把 diff 的 class 綁四業務類(該綁定是 finding 自己補的前提);§47 通用 3 問(併發/效能/資源)即代碼層類軸、§94 明言 pattern 與 difficulty 刻意脫鉤——殘餘=映射未寫白。存活 4 minor 全折:
- **F1 殘餘(折入)**:diff manifest `class` 明綁形態類軸(併發/效能/資源),逐 pattern 綁定,與 spec 模式詞表分立。
- **F3(折入)**:pillar-2 明定 canary 座標必須在真改動集之外(與 pillar-1 一致而非矛盾)+ 載體明定(diff 文字檔工作副本、合法 @@ 偽 hunk)。
- **F4(折入)**:天花板 1 補單行掃描能力邊界(跨行語境以小行窗啟發為限、做不到誠實不掃)。
- **F5(折入)**:Check T 接線措辭修正(合約級才進架構圖綁定,實作測試靠套件回歸)。

### R4(2026-07-04,canary type d=憑空產物 pitfalls-scan-cache.json,opus,**CAUGHT**,辯方裁決後 severity=major,存活 findings=6)

canary 被正確識別(明指無路徑定義、無消費者機制、單一無限定檔名並發互踩——三重瑕疵)。judge 評 F2/F3/F4 三 major;辯方裁決:F2 假→minor(@@ 行號=標準 diff 記帳非新機制;pillar-1 為檔級集合關係不依賴行號)、F3 假→minor(tier 是提示器、誤升級偏嚴合設計姿態;真缺口=過濾未繼承先例)、**F4 真→維持 major**(gate 契約變更但知識同步表漏列 project-notes ~899/~92 與 methodology 的 gate 文檔同步——組件改了東西表沒列,違反自家同步紀律)。存活 6 條全折:F4(同步表補兩處)、F2 殘(line 推導+檔級判定)、F3 殘(過濾繼承 Check H 全套)、F5(「硬性」下修為散文慣例)、F6(漂移守衛同時釘黑名單集合)、F7(座標權威=-U10 package 檔)。

### R5(2026-07-04,canary type a=壞§ref「§分級升級細則」,opus,**MISSED**,判決不採信)

auditor 未點出植入壞 ref——不採信、不折(其 F1「§81 硬性殘留」經編排者 grep 自查屬實,r6 後以筆誤更正透明處理)。cap 依 risk-tiered high 級精神自判上調 8(手動 loop 舊 cap 6 預於分級機制,誠實留痕)。

### R6(2026-07-04,canary type b=未定義旗標 `--section-title`,opus,**CAUGHT**,severity=minor,存活 findings=2)

canary 被正確識別性質(缺 CLI 語法行出處、無測試、與 §87/§37/§81 固定節名合約三重矛盾——auditor 誤標「真旗標」但性質點好點滿,依判準①算 caught;其跨節矛盾觀察=canary 影子,一併排除不折)。存活 2 minor 折入:
- **F2(折入)**:知識同步表 design-loop 行補 gate 措辭同步(第三個契約記錄面,R4-F4 族傳播補全)。
- **F3(折入)**:測試 #7 擴充為過濾全套參數化案(.txt/.rst/_TEST_PAT/註解行,R4-F3 保證的回歸釘)。
- **編排者筆誤更正(非折入)**:§81「硬性節名清單」→「節名清單(散文慣例)」——r4-F5 折入時漏改此處,grep 機械可證的措辭同步(同 risk-tiered r1「順手改正」前例)。

### R7(2026-07-04,canary type c=未定義常數 `CODE_LOOP_MIN_DIFF_LINES`,opus,**CAUGHT**,severity=minor,存活 findings=1)

canary 被正確識別(明指無值/單一無定義處/承重閘值三重瑕疵,並點名同 R3 型)。F2-F5 為肯定性查證(CLI 旗標/詞表黑名單/gate 契約四記錄面傳播全對)。存活 1 minor 折入:
- **F6(折入)**:步驟 1「複製工作副本」用語精度——明定副本對象=diff 文字檔(非 checkout 樹),與 pillar-2 載體澄清前後呼應。

### R8(2026-07-04,canary type d=憑空產物 code-loop-ledger.md,opus,**CAUGHT**,severity=clean,存活 findings=0)

canary 被正確識別(明指生產機制不存在且與 cmd_canary 實作矛盾/無位置與生命週期規格/漏列同步表——三重瑕疵,並準確歸類為 R4-F4 同款「組件引入產物表沒列」型)。四項機械步驟(產物/ALL_CAPS/旗標/§ 引用)全 clean,歷輪 canary 殘留確認只在紀錄段。**零真 finding → 連 3 輪 caught(R6+R7+R8)、findings [2,1,0] 枯竭,GATE PASS 收斂**(K=3,risk-tiered high 級)。
