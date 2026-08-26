---
type: project
status: done
created: 2026-07-05
updated: 2026-07-05
tags:
  - type/project
  - status/done
related:
  - "[[pitfalls-lint-integration_計劃]]"
  - "[[主動影響幅度偵測_計劃]]"
plan_refs:
  - "[[pitfalls-lint-integration_計劃]]"
summary: |-
  FLAG:DECISION
  KEY:pitfalls-lint-integration ④ 事故語料進架構圖——專案自己踩過的具體坑(linter 沒有、多為既有 Issues)加機械 pattern-trigger → lumos impact 多算 incidents 段 → 既有 impact PreToolUse hook 一併進場自動餵(像 refcheck manifest)。原 pitfalls-code-loop v2
  KEY:與 impact 分工=impact 撈「引用該檔的結構節點」(file-specific);④ 補「跨檔按主題觸發」(pattern-trigger)impact 撈不到的
  KEY:trigger 表示=事故節點 frontmatter `pitfall_when` list,兩型前綴:`glob:**/*Repository*.cs`(比被碰檔路徑)、`content:SELECT\s.*FROM`(grep 被碰檔內容 regex);新建 Write 無內容→只 glob
  FLOW:被碰 code 檔 → impact hook → lumos impact(算 direct/indirect + _match_incident_triggers 掃全圖 pitfall_when 節點比 glob/content)→ --json 加頂層 incidents 段 → hook 併注入
  KEY:去重=某節點既 impact 結構命中又 trigger 命中→只列 incidents(更具體、標 matched_by);誠實=trigger 人寫 GIGO、content-regex 假陽假陰、量少邊角
  DECISION:有真演算法(trigger 比對)+動剛 merged impact/hook→非純散文,走(輕量 design-loop 或)writing-plans+TDD(impact TDD 抓過 3 真 bug)
  DEP:[[主動影響幅度偵測_計劃]]
  TEST:已實作(branch feat/pitfall-incidents,671 passed;TDD 4 task+opus 終審);VERIFY:[[2026-07-05_pitfalls事故觸發]]
verified_by:
  - "[[2026-07-05_pitfalls事故觸發]]"
---
# pitfalls 事故觸發_計劃(block ④)

> 解 [[pitfalls-lint-integration_計劃]] 的 ④ 事故語料進架構圖。原 pitfalls-code-loop v2。**與 ③/impact 分工釐清**:③=網搜通則坑(skill);impact=撈「引用該檔的結構節點」(file-specific);**④=補「跨檔按主題 pattern-trigger」impact 撈不到的**(如「凡碰 raw SQL 都看 N+1 事故」)。

## §1 架構

> 落點(2026-08-08 補鏈,link-candidates 人裁採納):incidents 段的注入通道=`scripts/hooks/claude/impact-hook.py`(FLOW 所述 hook 併注入即此檔)。
事故節點加機械 trigger → `lumos impact` 多算 `incidents` 段 → **復用既有 impact PreToolUse hook** 一併注入(不新增 hook)。三部分:frontmatter 慣例 + lumos 比對原語 + hook 復用。

## §2 trigger 表示
事故節點(多為既有 Issues,也可任何節點)frontmatter 加 **`pitfall_when`** list,每項前綴兩型:
- **`glob:<pattern>`**(如 `glob:**/*Repository*.cs`)→ 比**被碰檔路徑**(fnmatch/pathlib)。
- **`content:<regex>`**(如 `content:SELECT\s.*FROM`)→ **grep 被碰檔內容**(re.search)。
- 走 `lumos set`/`append`?——`pitfall_when` 非白名單 list 欄位,v1 手寫 frontmatter(list 一項一行,同鐵則1);或 skill/指令輔助(YAGNI 先手寫)。
- **寫 trigger 的兩個 caveat**(最終 review 實測):
  - **`content:` regex 避免嵌套量詞**(如 `(a+)+$`)——python `re` 無 timeout,對大檔會 catastrophic backtracking 卡住整個 impact/hook(GIGO,§5.2)。用簡單 pattern。
  - **`glob:**/x` 不match 根層檔**:`glob:**/*Repository*.py` 命中 `app/UserRepository.py` 但**不**命中根層 `UserRepository.py`(`PurePath.match`/`fnmatch` 皆然)。要蓋根層用 `glob:*Repository*.py`,或兩條都寫。

## §3 比對演算法
新函式 `_match_incident_triggers(file_rel, file_content, env) -> list[dict]`:
1. 掃全圖有 `pitfall_when` 欄位的節點(`n.fields.get("pitfall_when")`,`as_list`)。
2. 對被碰檔:每項 trigger——`glob:` 用 `fnmatch`/`PurePath.match` 比 `file_rel`;`content:` 用 `re.search` 比 `file_content`。
3. 任一項命中 → 該事故相關,回 `{node, matched_by:"glob:.."/"content:..", contract, combo}`(contract/combo 復用 `_impact_contract`)。
4. **新建檔(Write 無 content)**→ content-regex 全 miss、只 glob 生效(合理:新檔還沒內容)。

## §4 輸出 / 去重 / hook
- `lumos impact --json` 加**頂層 `"incidents": [{node, matched_by, contract, combo}]`**;人讀輸出加「── 相關事故 ──」節。
- **去重**:某節點既 impact 結構命中(direct/indirect)又 trigger 命中 → **只列 incidents**(更具體、標 matched_by),不在 direct/indirect 重複。
- **hook**:既有 impact PreToolUse hook 讀 impact --json 時,把 `incidents` 併進 additionalContext 注入(改 hook 的 build/inject 納入 incidents;空 incidents 不洗版)。
- **檔內容來源**:impact 已收 `--file`;content-regex 需讀被碰檔內容(hook 傳的絕對路徑讀盤;讀不到→只 glob)。

## §5 誠實天花板
1. **trigger 人寫**(GIGO,同 refcheck/pitfall):沒寫 `pitfall_when` 的事故不會被觸發;寫錯 glob/regex 不準。
2. **content-regex 假陽/假陰**:正則近似非語意(`SELECT.*FROM` 可能誤中註解/字串)。
3. **量少邊角**:專案事故本就少;這是把既有事故 Issues「該看時自動浮出」,非產生事故。
4. 無機械 oracle 於「這事故此刻真相關嗎」——trigger 命中是「可能相關」,Claude 動手前判。

## §6 測試(TDD)
- `_match_incident_triggers` 單元:glob 命中/content-regex 命中/都不命中/新建檔只 glob/多節點;`as_list` str-list。
- `lumos impact --json` incidents 段 schema + 去重(節點既結構又 trigger 命中只列 incidents)。
- hook 注入含 incidents 段、空 incidents 不注入該段。
- 回歸:現有無 `pitfall_when` 的架構圖跑 impact → incidents 空、不誤傷(基線測試全綠)。

## 落地後回指
實作 Verification `plan_refs` 回指;本節點 TEST 更新;`pitfalls-lint-integration_計劃` ④ 標 done → roadmap ①②③④ 全 done。
