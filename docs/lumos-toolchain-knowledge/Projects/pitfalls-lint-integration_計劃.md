---
type: project
status: done
created: 2026-07-04
updated: 2026-07-07
tags:
  - type/project
  - status/done
related:
  - "[[Systems/pitfalls-code-loop]]"
summary: |-
  FLOW:brainstorm 收斂(2026-07-04)→ 四塊有序落地(①lint adapter+SARIF → ②每日 linter 版本偵測 → ③網搜補漏 → ④事故語料進架構圖),各塊獨立 spec→design-loop→實作→merge
  KEY:核心認知重定位——pitfalls 不是規則庫,是「提問層 + lint 整合器 + loop 接線」。通則(requests timeout/open-with)ruff S113/SIM115 已有且 AST 級更準;偏科(LazyColumn key/主執行緒)compose-rules/detekt/eslint 已有;兩者都該讓給社群 linter(composition over invention)
  KEY:整合共通格式=SARIF(OASIS 標準,ESLint/detekt/Roslyn/Sonar 皆可輸出)——lumos 只解析 SARIF 一種格式(stdlib json)、跨棧跨工具收進單一 pitfalls manifest
  KEY:一棧多 linter 並存(C#:Roslyn+StyleCop+Sonar+Roslynator;Vue:ESLint+plugins;Android:Lint+detekt+ktlint)→ adapter 要「一棧一組指令」、各輸出 SARIF 再合併
  KEY:pitfalls --diff 通則 regex 層=過渡/次優(6 條有 2-3 條輕造輪子),未來被 SARIF 餵的 ruff 結果取代、pattern 表該縮到 linter 沒覆蓋的領域坑(N+1/無交易)並標低信賴;骨架(manifest schema/tier/code-loop 接線)有價值不回退
  KEY:偏科/網搜內容無機械 oracle(同 refcheck/[audit:] 天花板:驗形式不驗真值)——把關靠「反證預篩(駁倒即丟)+ 駁不倒進候選非定論 + 人輕量放行」;「舉不了反證≠真」(缺席證明謬誤+反證者能力上限,同 canary 天花板)
  DEP:[[pitfalls-code-loop]](本計劃是其偏科層的真正落地)｜[[convergence-evidence-gate]]｜risk-tiered-review(分級哲學)
  TEST:各塊落地時各自 spec 的測試策略;本節點為路線圖、無直接測試
decisions:
  - content: 四塊拆成獨立 spec 有序做,不吞一個大 spec;序=① adapter+SARIF(地基,②③④ 皆建其上/相關)→ ② 每日版本偵測 → ③ 網搜補漏 → ④ 事故語料
    id: d1
    context: 使用者要「全做完」;但四塊是獨立子系統,一個 spec 吞下 design-loop 審不動、實作 subagent 也吞不下
    why_chosen: 依賴序 + 各塊獨立可測;adapter 是其餘三塊的共同地基
    decided: 2026-07-04
    valid: true
  - content: 偏科/通則都走社群 linter(SARIF 整合),不自建規則庫;lumos 維持語言無關(不內建任何棧規則)
    id: d2
    context: 使用者三連問(偏科有 linter?其他平台?通則也有?)推導出——規則庫社群已維護且更新更快、更準(AST 級)、免腐化
    why_chosen: composition over invention(設計原則 6,同「不造輪子用 Obsidian」);解掉自建包的腐化/噪音/未驗證/人工放行四風險
    decided: 2026-07-04
    valid: true
verified_by:
  - "[[Verification/2026-07-04_pitfalls-lint-adapter]]"
  - "[[Verification/2026-07-04_lint-version-watch]]"
  - "[[Verification/2026-07-04_compose-metrics-adapter]]"
---
# pitfalls-lint-integration 計劃

pitfalls 偏科層的真正落地——**吃社群 linter(SARIF 整合),不自建規則庫**。2026-07-04 brainstorm 收斂,四塊有序做完。

## 四塊(依賴序)

### ① lint adapter + SARIF 整合(地基,最高價值,先做)—— ✅ DONE(2026-07-04)
> **狀態(2026-07-04)**:**已實作(subagent-driven 5 task)**。spec design-approved(KDS tracer 坐實六大承重點 + design-loop 9 輪 GATE PASS + qwen endorsed-after-refute)→ writing-plans 5 task → 每 task 乾淨 reviewer 雙判、Task3 核心 opus 複核 + fix、Task4 整合 opus 複核 → 全套件 412 passed。落地見 [[pitfalls-lint-adapter]] + [[Verification/2026-07-04_pitfalls-lint-adapter]]。
偵測技術棧 → 跑專案宣告的一組 lint 指令(各輸出 SARIF)→ lumos 解析合併 SARIF → 收進 pitfalls `--diff` manifest 餵 reviewer/code-loop。lumos 只解 SARIF 一種格式、不碰任何棧規則。接線細節待定(專案宣告 `.lumos/lint.json` 一棧一組指令,推薦)。順帶:通則 regex pattern 表縮到 linter 沒覆蓋的領域坑、標低信賴。

### ② 每日 linter 版本/新規則偵測 —— ✅ DONE(2026-07-04,已實作)
排程(吃治理日報骨架)盯已採用的 linter 套件有沒有新版/新規則(查 registry 最新版 vs 專案鎖定版)→ 產「該升級 X」候選 → 候選→放行紀律。
> **狀態(2026-07-04)**:spec `docs/design/2026-07-04-lint-version-watch.md`。design-loop 6 輪 canary **6/6 全 caught**(auditor 全程醒著),挖出並修真缺陷:Maven Solr `%22` 編碼 + 字串 max 病灶(→ 數值 tuple max + `sort=timestamp+desc`)、PEP440 dashless prerelease 漏抓、`_compare_versions` 三態(bool 承載不了 failed 分流)、等段數守衛擋 calendar/4段假陽性、fixture 測試 seam、shell↔python JSON 側效全收進 dedup `__main__`。**未 GATE PASS**:核心機械設計 r4-r6 連 3 輪判乾淨=已收斂,但治理 shell wrapper 散文持續招 finding(逐字寫 shell 每個不精確範例招一條),達 6 筆 cap。**建議**:核心 design-approved、shell wrapper 屬薄整合層留實作階段以真 shell 測試定稿。**進實作前待人放行本判定**(自主設計成果不自動 merge,同 loop 紀律)。

### 偏科層新支線:compose-metrics-adapter —— ✅ DONE(2026-07-05,已實作+KDS真機驗證)
Compose 重組效能(SARIF linter 蓋不到的偏科坑)——吃 Compose Compiler Metrics(baseline+delta,同 lint-watch 形狀:baseline≙鎖定版、現況 metrics≙latest、delta≙退步、放行≙bump baseline)。
> **狀態(2026-07-04)**:spec `docs/design/2026-07-04-compose-metrics-adapter.md`。**KDS 真機驅動**(實跑 compose compiler metrics:module.json 聚合 + composables.csv/txt,坐實 21 個 non-skippable、格式與 txt 邊角)。design-loop r1/r2 canary 2/2 caught、折 15 真 finding(txt↔csv join/baseline_missing 消歧/update-baseline skip failed/泛型/空行/aggregate entry 形狀等)。G1 refcheck ok、findings 8→7 churn 於 txt 解析邊角(同 block② cap 現象);核心判乾淨。**待人放行進 writing-plans/實作**。

### ③ 網搜補漏(邊角)✅ DONE(2026-07-05)
linter 還沒收錄的新坑,量少。反證預篩(駁倒即丟)+ 駁不倒進候選 + 人輕量放行。無機械 oracle,人的閘省不掉。
**落地**:`lumos-pitfalls-gapfill` skill(on-demand,無 lumos 新碼)+ `Issues/linter-gap實務隱患`(每專案,兩段自去重)。見 [[pitfalls網搜補漏_計劃]] / [[2026-07-05_pitfalls網搜補漏]]。

### ④ 事故語料進架構圖 ✅ DONE(2026-07-05)
專案自己踩過的具體坑(linter 沒有)→ 寫成架構圖節點 + 觸發條件 → 實作進場自動餵(像 refcheck manifest)。原 pitfalls-code-loop spec 的 v2。
**落地**:pattern-trigger 機制——事故節點 `pitfall_when`(glob/content-regex)→ lumos impact `incidents` 段 → 復用 impact hook 進場自動餵。補 impact「跨檔按主題觸發」缺口。見 [[pitfalls事故觸發_計劃]] / [[2026-07-05_pitfalls事故觸發]]。

## 相關
- 起點認知:`docs/design/2026-07-04-pitfalls-code-loop.md`(通則層已 merge;偏科層原設計「自建網搜迭代包」經本 brainstorm 推翻,改吃 linter)。
- 各塊落地 spec:`docs/design/`(逐塊建,plan_refs 回指本節點)。
