---
type: project
status: doing
created: 2026-07-12
updated: 2026-07-12
tags:
  - type/project
  - status/doing
summary: |-
  FLOW:M層(C1a-lint演進/C1b-框架版本 cron偵測)→pending候選→A層(refuter/drain草案/C3旁註/C2網搜,Claude在場跑)→screened→staged→人閘三力度→改idioms文件
  KEY:治病=idioms三份(kotlin/vue/csharp)會過時(版本變)或缺漏(新實踐沒收),既有「飛輪」靠人記得回填=實質不會發生;把「該回來複查」變機械觸發
  KEY:方案C''(round-2修正版:拆兩層)——機械層M(純lumos stdlib零LLM,cron可無人跑:版本偵測/池/去重/staging) + agent層A(Claude在場才跑:refuter/草案生成/C3旁註/C2網搜);交棒點=候選池status
  KEY:演進史=C(只借)→round-1 Codex否決(借用假設半數與現契約不符)→C'(各造薄新原語)→round-2 Codex否決(LLM判斷鏈接不上零依賴cron)→C''(拆層)
  KEY:候選池=idioms-candidates.json(6態:pending/screened/rejected/deferred/staged/adopted;os.replace atomic;O_CREAT|O_EXCL portable鎖非fcntl;結構化target_rule+tool_or_framework+evidence_version)
  KEY:C3=結構化附出契約(封閉區塊<<<IDIOMS-ANNOTATION>>>,canary排除+辯方後才抽,抽取失敗不影響verdict);refuter框架特定判準=可替換庫選擇→駁/核心框架慣例→收
  KEY:誠實代價=A層需Claude在場(自主loop tick或skill),非真7×24無人;「自動」限M層偵測+staging
  DEP:[[pitfalls網搜補漏_計劃]][[lint-version-watch]][[自主loop加法偏食]][[linter-gap實務隱患]]
  DECISION:[2026-07-12]C→C'→C''三代演進,現行C''拆兩層(valid)
  DECISION:[2026-07-12]C3結構化附出不動verdict(valid)｜refuter/drain屬A層Claude編排不硬造model-runner(valid)｜portable鎖非fcntl(valid)
related:
  - "[[pitfalls網搜補漏_計劃]]"
  - "[[Systems/lint-version-watch]]"
  - "[[Issues/自主loop加法偏食]]"
  - "[[Issues/linter-gap實務隱患]]"
decisions:
  - content: 走方案C：薄 collector + 共用候選池為新造，refuter 借 gapfill、drain 借自主 loop、落點仿 linter-gap
    context: 三份 idioms 文件會過時/缺漏，既有『飛輪』靠人記得回填=實質不會發生；需把『該複查』機械觸發。三源(lint-watch/網搜/code-loop棄稿)產出需匯流
    why_chosen: 唯一同時滿足『共用 sink』又不重造 gapfill/loop 的方案；A 全新子系統重造已 dogfood 的 refuter/drain/落點(違零依賴家規)，B 全走既有軌會讓候選散在 lint-watch staging 與 linter-gap 兩處(破壞共用池、人要看兩地)
    alternatives_considered:
      - "A 全新 lumos idioms-watch 子系統：概念最乾淨、邊界清楚，但重造 gapfill refuter/自主 loop drain/linter-gap 落點——零依賴家規下的重造輪子"
      - "B 全走既有軌、不造新東西：新代碼幾乎為零且全部已驗證，但候選散在 lint-watch staging 與 linter-gap 節點兩處，破壞『共用 sink』、人要看兩地"
      - "C 薄 collector + 共用池新造，refuter/drain 借既有：選此"
    trade_offs: "需明確定義三個 collector 與既有 refuter/loop 的介面(新增邊界的維護成本)；換得共用池不散落 + screening/draining 不重造已 dogfood 的機制"
    decided: 2026-07-12
    valid: true
  - content: round-1 修正:方案C→C'——borrow-design(gapfill反證哲學+lint-watch的staging形態)但refuter留痕/drain/框架監測各造薄新原語,不硬借canary-record(收斂專用)/自主loop(N=1單工)
    context: round-1 design-loop 跨家族Codex否決席揭露:C3兩桶會讓無R真bug逃code-loop收斂閘(blocker)、canary-record無候選語意、自主loop N=1單工不容drain插槽、gapfill反證綁單專案與idioms跨專案通用相斥、lint-watch輸出已被治理層消費
    why_chosen: 保住三源完整迴路又修正blocker:C3改加法旁註(不動verdict/pre-push)、refuter/drain各造薄專用原語(仿形態不硬借)、C1b加回框架watcher補框架rot分類洞、明定框架特定判準(可替換庫選擇→駁/核心框架慣例→收)
    decided: 2026-07-12
    valid: true
  - content: round-2 修正:C'→C''拆兩層——機械層M(純lumos stdlib零LLM,cron可無人跑:版本偵測/池/去重/staging) + agent層A(Claude在場才跑:refuter/草案/C3旁註/C2網搜);交棒點=候選池status
    context: round-2 design-loop 跨家族Codex否決席揭露infra-fit blocker:LLM判斷鏈(refuter/草案生成/C3旁註抽取)接不上零依賴stdlib的cron(lumos不spawn agent、code-loop reviewer無結構化parser、governance daily只是shell);另fcntl與工具鏈原生Windows支援衝突、lint-upgrades每日覆寫會漏、C1b監測對象(kotlin-stdlib≠Compose)不成立
    why_chosen: 拆層對齊lumos既有哲學(機械原語+Claude編排):M層可無人cron跑偵測,A層判斷鏈跟Claude session節奏(自主loop tick或skill);誠實承認A層非7×24無人=拆層換infra-fit的代價。並修:portable鎖(O_CREAT|O_EXCL非fcntl)、C1a游標讀seen.jsonl、C3結構化封閉區塊附出、6態狀態機(補deferred/staged)、gap採納回填R號、自引用斷路可執行偵測(IDIOMS_SELF_REVIEW旗標)
    decided: 2026-07-12
    valid: true
  - content: 3輪design-loop後暫停實作:架構(M/A拆層)收斂但整合接縫未收斂,人裁定收成設計資產。phase-1 MVP=M層+人手動skill(不碰C3 hook/自主loop整合,那些整合點不存在)
    context: 3輪panel全GATE FAIL,跨家族Codex否決席3輪皆決定性:r1借用假設不符→C',r2 LLM鏈接不上cron→C''拆層,r3兩sonnet認證架構站住但Codex揭露A層3整合點(runner/skill、C3 code-loop hook、跨session旗標)在repo不存在。loop誠實揭露:全包=大整合工程非幾個薄原語
    why_chosen: 架構已穩、續推邊際遞減且接縫需真build(非spec patch);凍成golden保住三輪findings語料+架構決策,實作另議。phase-1只做真做得出的M層+人跑skill,C3/全自動列phase-2
    decided: 2026-07-12
    valid: true
---
# idioms自維護迴路_計劃

**PRIOR-ART:** round-1 揭露「只借不造」半數與現契約不符→C'（各造薄新原語）。round-2 再揭露更深的 infra-fit：LLM-判斷鏈（refuter/草案生成/C3 旁註抽取）接不上零依賴 stdlib 的 cron（`lumos` 不 spawn agent、code-loop reviewer 無結構化 parser）。修正為**方案 C''：拆兩層**——**機械層 M**（純 lumos stdlib、零 LLM、可無人 cron 跑）只做版本偵測/池/去重/staging；**agent 層 A**（Claude 在場才跑，掛自主 loop tick 或專用 skill）做所有 LLM 判斷。對齊 lumos 既有哲學（機械原語 + Claude 編排）。裁定 = **borrow-design（gapfill 反證哲學 + lint-watch 形態）+ build（機械層薄原語）+ orchestrate（agent 層沿用 Claude 編排，不硬造 model-runner）**。

## 一、問題

三份 idioms 慣例文件（kotlin R1-R18 / vue R1-R13 / csharp R1-R12）會以兩種方式腐爛：

- **過時（stale）**：① 某條 `自訂`/`不可機檢` 現在 linter 原生支援了（**linter 演進**）；② 綁框架 API 版本的條款（Vue 3.5 `useTemplateRef`…）隨升版失準（**框架 API 演進**）。
- **缺漏（gap）**：該有的最佳實踐從沒進 R 清單。

文件自宣告的「飛輪」**沒有驅動力**（全靠人記得）。本計劃把「該回來複查」從「被記得」變成「被機械觸發」。

## 二、架構（方案 C''：機械層 M + agent 層 A）

**分層鐵則**：一步驟需 LLM 判斷 → 屬 A 層（Claude 在場才跑），**絕不放進無人 cron**；純版本/檔案/字串比對 → 屬 M 層（cron 可無人跑）。交棒點 = 候選池的 `status`。

```
【M 層 · 機械 cron · 純 lumos stdlib · 零 LLM】
  C1a 版本偵測(消費 lint-upgrades 事件) ─┐
  C1b 框架 watcher(監測正確對象)        ┼→ pending 候選(帶 target_rule) → 候選池(lock+去重)
  staging(drain 機械半:冪等產 stub)     ┘        │ status=pending 等 A 層
【A 層 · agent-session · Claude 在場(自主 loop tick 或 lumos-idioms-maintain skill)】
  refuter 判斷: pending → screened / rejected / deferred
  drain 草案生成: screened → 照房規 diff → staged(冪等,不重產)
  C3 code-loop 旁註(結構化附出) / C2 網搜(每週) → pending 候選
【人閘】 staged → 人放行(三力度) → adopted(僅文件真改+驗證後)
```

**元件邊界（標層）**

| 元件 | 層 | 職責 | 新造 |
|---|---|---|---|
| 候選池 | M | 可變狀態儲存 + 6 態狀態機 + portable lock + 去重 | ✅ 核心 |
| C1a/C1b | M | 版本偵測→pending 候選（純機械） | ✅ 薄 |
| staging | M | drain 機械半：冪等產 proposal stub、LINE | ✅ 薄 |
| refuter | A | 判斷候選（試駁）→ screened/rejected/deferred | ⭕ Claude 編排 |
| drain 草案 | A | screened→照房規 diff→staged | ⭕ Claude 編排 |
| C3 旁註 / C2 網搜 | A | code-loop 附出 / 每週網搜 → pending | ⭕ Claude 編排 |

核心原則：**collector 只丟訊號、不判對錯；判對錯交 refuter（A 層機器初篩）+ 人（終判）**。

## 三、元件規格

### 候選池（M 層）
- `[S1]` 候選儲存 `idioms-candidates.json`（待建，`governance/` 下），**可變狀態儲存**：狀態轉移以 **tmp（同目錄）→ 自驗 → `os.replace` atomic rename** 就地更新；崩潰恢復＝啟動清理殘留 `*.tmp`。
- `[S2]` schema：`{id, source: lint-linter|framework|websearch|code-loop, doc: kotlin|vue|csharp, kind: stale|gap, target_rule, tool_or_framework, claim, evidence, evidence_version, refuter_verdict, status: pending|screened|rejected|deferred|staged|adopted, retry_after, provenance_gen, notified, ts}`。**狀態機**：pending→(refuter)→screened|rejected|deferred；deferred→(重試)→pending；screened→(drain)→staged；staged→(人放行)→adopted。`deferred`/`staged` 為獨立狀態（修 round-2：enum 補齊，不與 pending 混用）。
- `[S3]` **portable 鎖**：`os.open(lock, O_CREAT|O_EXCL)` 建鎖檔（跨平台 stdlib，**非 `fcntl`**——修 round-2：工具鏈承諾原生 Windows，`fcntl` 非 Windows stdlib；死鎖檔以 mtime 逾時判 stale）。單寫入者持鎖全程 check-then-act。去重身分：**stale = `(doc, target_rule, tool_or_framework, from→to)`**（`tool_or_framework` 為 schema 欄位，消歧同 doc 多監測對象）；**gap = `(doc, 正規化 claim, evidence_version)`**（含 evidence 版本→依據更新可重驗，修 round-2「永久封死重驗」）。正規化＝NFC+trim+lowercase，**只機械近似**（跨源語意重複靠人眼）。
- `[S3b]` **刪 R 編號策略**：刪 R **保留號洞、不順移重編**（避免既有候選 `target_rule` 指標錯位）；被刪 R 於文件標 `(retired)`，指標永久穩定。

### C1a linter 演進收集器（M 層）
- `[S4]` **消費 lint-upgrades 穩定事件**：**不掃每日覆寫的 `pending-YYYY-MM-DD.json`**（round-2：`"w"` 覆寫漏當日第二批），改讀 append-only `seen.jsonl` + 自持游標（記已消費 offset），不漏不重。映射用**權威表**（`name/registry`→doc + analyzer 類別）：`detekt(maven)→kotlin`、`eslint(npm)→vue`、指定 NuGet analyzer 套件 id 清單→csharp；未知項→log 待人補表，不臆測。
- `[S5]` 候選＝「複查指針」非可反駁 claim——refuter（A 層）翻 changelog 找具體 idioms 相關規則變動，**找不到→deferred（重試）非 rejected**。

### C1b 框架版本 watcher（M 層，新薄原語）
- `[S6]` 讀 `.lumos/idioms-framework-watch.json`（`[{doc, framework, name, registry, current, source_of_current}]`，**含 `name`**——修 round-2：既有 registry 契約需 `name`，缺則 rc=2）。**監測對象逐一明宣**（修 round-2：kotlin-stdlib≠Compose≠AGP、NuGet≠.NET SDK）：每個框架元件各一筆（如 `{doc:kotlin, framework:compose, name:androidx.compose.runtime:runtime, registry:google-maven}`）。`current` 盡量從 lockfile/pin 讀（`source_of_current` 標來源），避免採納後忘推進而永久重報。落後→吐 `kind=stale`。fail-open。

### C2 缺漏收集器（A 層，獨立網搜）
- `[S7]` A 層每週一次 WebSearch 找「某棧新最佳實踐、linter 沒收**且不在 R1-Rn**」→ pending `kind=gap`。**不復用 gapfill 的「本專案不會踩→反證」**（綁單 repo，idioms 跨專案）。**與 `linter-gap實務隱患` 分池**（通用 idioms vs 專案 gotcha），**共用一次網搜、結果分流**兩池（省重複燒）。`doc` 歸類：按棧發起搜尋→天然帶 doc；不屬三棧者丟棄。

### C3 code-loop reviewer 加法旁註（A 層，修 round-1+round-2）
- `[S8]` **reviewer verdict 完全不動**：所有真 bug（含無 R 條號者）照舊計入 verdict/severity、pre-push 一字不動（修 round-1 blocker）。
- `[S9]` **結構化附出契約**（修 round-2：reviewer 無 parser、旁註混入自然語言會被誤讀為 finding）：旁註走**獨立封閉區塊** `<<<IDIOMS-ANNOTATION>>>…<<<END>>>` + JSON，由編排者在 **canary 排除、辯方裁決之後**才抽取「存活真 finding 中反映通用樣式者」寫入池（`source=code-loop, kind=gap, provenance_gen`）；**抽取器失敗→略過旁註、絕不影響 verdict**；區塊內含 `major/blocker` 等字樣也不進 severity 計算（物理隔離）。
- `[S10]` 旁註門檻 framing（可辯護通用實踐、非品味）；不 gate，誤標由 refuter+人閘接住。

### refuter 預篩（A 層，自造留痕）
- `[S11]` Claude 在場對 pending 派乾淨 refuter，**試駁不試證**。stale：翻 changelog→找到 screened／找不到 deferred。gap：①已涵蓋 ②純品味 ③**框架特定** 任一→駁倒。**「框架特定」判準**：可替換第三方庫選擇（Hilt/Koin…）→駁、進專案架構圖；核心語言/官方框架通用慣例（Coroutines/Flow/Compose…）→收（對齊三份文件「不裁框架庫」原則）。
- `[S12]` 駁不倒→screened；駁倒→rejected+理由（留池去重記憶）。**留痕自造**（候選 json `refuter_verdict`），**不借 canary-record**（收斂專用、會污染 `.canary-log`）。逾時/失敗→deferred+`retry_after`（指數退避、上限 N 次後 log 告警人工介入，不無限循環）。

### drain（M 機械半 + A 草案半）
- `[S13]` **A 半（草案）**：Claude 在場對 screened 用「已載入三份 idioms 房規」固定範本產**完整 diff 草案**：stale→改機檢欄/條文或標 `(retired)`；gap→一條新 R【壞例→好例+機檢欄+依據】。產完→候選轉 `staged` + 記 proposal-id。
- `[S14]` **M 半（staging，冪等）**：cron 把 staged 且 `notified=false` 者寫 `idioms-proposals（governance/ 下待建）`、發 LINE、置 `notified=true`；**同候選不逐日重產/重發**（修 round-2）。N=0 靜默。
- `[S15]` **步序**：A 層（**C2/C3** collector→refuter→drain 草案）在 Claude session tick 一起跑（修 round-3：原誤寫 C1a/C1b，那兩個是 M 層機械偵測；A 層 collector 是 C2 網搜與 C3 旁註）；M 層（C1a/C1b 偵測 + staging）掛 governance daily。

### 人閘與落地
- `[S16]` **機械命令 + 狀態一致**（修 round-2）：`lumos idioms approve <id>` / `reject <id>` / `revive <id>`；approve **僅在 idioms 文件真改成功 + 驗證通過後**才轉 `adopted`（避免半完成）。三力度：①微調 trivial 直改；②新 R 走 design-loop canary；③刪 R（標 retired）輕量確認。
- `[S17]` **gap 採納回填**：新 R 落地後把分配到的 R 號寫回候選 `target_rule`（修 round-2：否則 adopted gap 永遠 null、日後只能弱文字去重）。
- `[S18]` **自引用斷路**（修 round-2：可執行偵測）：design-loop 審 idioms 提案時編排者設 `IDIOMS_SELF_REVIEW=1`；C3 抽取器見旗標即**跳過**。候選 `provenance_gen` 記世代，禁「入池→採納成 R→同 finding 再生候選」回授環。
- `[S19]` `adopted`/`rejected` 候選**留池標記、不搬離**（搬離→去重讀不到→重入池）；恆保留身分鍵。改 idioms 是否觸發既有 pre-commit gate＝**實作期 hook 實測確認項**。

## 四、資料流

```
【M cron】 C1a(游標讀 seen.jsonl) / C1b(框架 registry) → pending 候選(帶 target_rule/tool_or_framework)
【A tick】 collector(C2 每週/C3 旁註) + refuter: pending → screened / rejected(留池) / deferred(重試)
【A tick】 drain 草案: screened → 房規範本 diff → staged(+proposal-id)
【M cron】 staging(冪等): staged 且 notified=false → idioms-proposals（governance/ 下待建） + LINE
【人閘】 lumos idioms approve/reject/revive → 文件真改+驗證 → adopted(gap 回填 R 號)
        新 R 走 design-loop(IDIOMS_SELF_REVIEW=1 關 C3 旁註)
```

## 五、錯誤處理與天花板

**錯誤處理**：refuter 誤駁→rejected 留池、`lumos idioms list --rejected`+`revive <id>`（附新 evidence 才重 pending）；併發→`O_CREAT|O_EXCL` 鎖檔 + 持鎖 check-then-act、殘留 tmp 啟動清理、死鎖檔 mtime 逾時判 stale；C1a 不漏＝游標讀 append-only seen.jsonl；stale 檢索失敗→deferred 非駁；gap 身分含 evidence_version→可重驗；drain 冪等（notified）不重發、staged 未放行不重產；N=0 靜默；當地慣例衝突→當地贏、記專案架構圖。

**天花板（誠實邊界）**：
1. refuter 抓「版本沒變/已涵蓋/框架庫選擇」，抓不到「讀了但深層判錯」——降雜訊地板，非 oracle。
2. 「還算不算最佳實踐」無機器 oracle，終究人/乾淨模型判。
3. **去重只機械近似**：gap 跨源語意等價無法純機械判，殘餘靠人眼。
4. 飛輪需人糧：C3 要 code-loop 真在跑、真有人審。
5. **A 層需 Claude 在場**：refuter/草案/網搜/旁註都非無人 cron——「自動」限 M 層偵測+staging；判斷鏈跟 Claude session（自主 loop tick 或人跑 skill）節奏，**非真 7×24 無人**。這是拆層換 infra-fit 的**誠實代價**。

## 實務隱患

- **A 層觸發頻率**：refuter/drain 綁 Claude session，長期無 session → pending/screened 堆積；需定義「多久沒 tick 就 LINE 提醒積壓」。
- **C1a 游標契約**：依賴 `lint_watch_dedup` 的 seen.jsonl 格式穩定；格式變則游標要跟改（跨元件耦合點）。
- **C1b current 生命週期**：`source_of_current` 指 lockfile 則自動；人手填則採納後需推進，否則版本標記失真。
- **C3 結構化附出**：需真測「旁註區塊含 blocker 字樣不影響 verdict severity」「抽取器失敗 verdict 照常」。
- **portable 鎖邊界**：`O_CREAT|O_EXCL` 崩潰留死鎖檔→需 stale-lock 逾時（mtime+PID）。

## 六、測試策略

| 單元 | 層 | 測什麼 | 型 |
|---|---|---|---|
| 候選池狀態機 | M | 6 態轉移合法性；deferred/staged 獨立；atomic rewrite；殘留 tmp 清理 | 純函式 |
| portable 鎖 | M | `O_CREAT\|O_EXCL` 併發互斥、無重複/半寫；stale-lock 逾時 | 併發 |
| 去重身分 | M | stale 含版本、gap 含 evidence_version、刪 R 保號洞 | 純函式 |
| C1a 游標 | M | 讀 seen.jsonl 不漏當日第二批、不重消費 | 行為 |
| C1b 映射 | M | 每框架元件各自 registry；`name` 缺→rc=2；fail-open | 純函式 |
| C3 結構化附出 | A | verdict/severity 不受旁註影響（含旁註帶 blocker 字樣）；抽取失敗 verdict 照常 | 行為 |
| refuter | A | 駁倒→rejected+理由；stale 檢索失敗→deferred；框架庫選擇→駁；退避上限告警 | 行為 |
| drain 冪等 | M+A | staged 不逐日重產/重發；proposal-id 唯一；N=0 靜默 | 行為 |
| 人閘一致 | M | approve 僅文件改+驗證後 adopted；gap 回填 R 號 | 行為 |
| 自引用斷路 | A | `IDIOMS_SELF_REVIEW=1` 時 C3 不產候選 | 行為 |
| 端到端 dogfood | — | 種真 stale(detekt 已原生)+真框架 rot(Vue 3.5)+真 gap → staged | E2E |

## 七、落地順序（建議）

1. **M 層地基**：候選池 CLI + 6 態狀態機 + portable 鎖 + 去重（`[S1][S2][S3][S3b]`）。
2. **M 層偵測**：C1a 游標讀 seen.jsonl（`[S4][S5]`）+ C1b 框架 watcher（`[S6]`）→ 純機械、可先無人 cron 產 pending。
3. **A 層 C3 旁註結構化附出**（`[S8][S9][S10]`）——不動 verdict/pre-push，風險低。
4. **A 層 refuter**（`[S11][S12]`）——借哲學不借 canary-record。
5. **drain**（A 草案 `[S13]` + M staging 冪等 `[S14][S15]`）+ 人閘機械命令 + 回填 + 斷路（`[S16][S17][S18][S19]`）。
6. **A 層 C2 網搜**（`[S7]`）——與 linter-gap 共用搜尋分流。

## 八、design-loop 狀態與 Round-3 待解接縫（2026-07-12 暫停實作）

**loop 收斂狀態**：3 輪 panel 全 GATE FAIL（跨家族 Codex 否決席 3 輪皆決定性）。r1 揭露「借用假設半數不符現契約」→ C'；r2 揭露「LLM 判斷鏈接不上零依賴 cron」→ C''（拆層）；r3 兩 sonnet 認證**架構（M/A 拆層）已站住**，但 Codex 揭露「A 層整合點在 repo 裡不存在」。**架構收斂、接縫未收斂**；經人裁定**收成設計資產、暫停實作**（非 gate-clean）。

**phase-1 MVP 建議（真做得出來的最小集）**：只做 **M 層**（C1a/C1b 版本偵測→候選池→staging，純 lumos stdlib 可無人 cron）+ **一個人手動跑的 `lumos-idioms-maintain` skill**（做 refuter/drain）。**不碰** C3 code-loop hook、**不碰**自主 loop 整合——那兩個整合點還不存在。C3 旁註 + 全自動列 phase-2。

**實作前必解接縫（round-3 findings，依嚴重度）**：
- 🔴 **A 層觸發入口不存在**：`autonomous-loop.sh` 是 N=1 gap→spec 專用、無 idioms tick；`lumos-idioms-maintain` skill 未建。M→A 交棒需真造入口（phase-1 = 人手動跑 skill）。
- 🔴 **C3 抽取編排點不存在**：`lumos code-loop` 只管 pass/skip 留痕，無認 `<<<IDIOMS-ANNOTATION>>>` 的 parser/hook（phase-2 才碰）。
- 🔴 **`IDIOMS_SELF_REVIEW` 無跨 session 控制面**：shell env 傳不到別 session 起的 reviewer（隨 C3 一起 phase-2）。
- 🟠 **`seen.jsonl` 扛不起 stale 身分**：實際每行僅 `{name, latest, seen}`，無 `registry`/`current`/`from`——C1a 得不到 `from→to`。需改讀更完整事件源或擴 lint-watch 輸出。
- 🟠 **並發缺 lease/CAS**：六態無 `processing`/owner/lease，兩 session 會重複判斷/覆寫。schema 需加 owner+version CAS。
- 🟠 **schema 補欄位**：`from→to`（非單一 evidence_version 可表）、`retry_count`（撐 N 次上限）、`rejected 理由`（refuter_verdict 若是 enum 裝不下）、`proposal-id`（S13/14 用到未入 schema）。
- 🟠 **跨儲存原子性**：候選池 `os.replace` 涵蓋不了「文件改+驗證+adopted」跨資源交易；approve 需 proposal/文件 hash + 可重入 reconciliation。
- 🟠 **portable stale-lock**：mtime+PID 可能誤刪有效鎖，需 owner token + 存活策略。
- 🟠 **target_rule 誰填**：M 層零 LLM 產不出「具體 R 號」（語意匹配屬 A 層 refuter）；[S3]/§四 宣稱 M 產候選帶 target_rule 與分層鐵則矛盾，需改為 A 層填。
- 🟠 **自引用只蓋力度②**：①trivial/③刪 R 不走 design-loop 但仍過 pre-push code-loop，C3 旁註照跑、回授環未斷。
- 🟡 **C1b 應復用 `_registry_latest`**（已支援 google-maven/nuget）而非另造 watcher（避免重造輪子）。
- 🟡 diagram：§二 ASCII 把 staging 誤畫成 pending 產出源（應為 staged 消費者）。
