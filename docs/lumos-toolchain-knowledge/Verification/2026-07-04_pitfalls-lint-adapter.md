---
type: verification
status: pass
date: 2026-07-04
valid_under: "scripts/lumos _pitfall_diff_mode lint 整合分支不變;.lumos/lint.json schema 為 {副檔名去點: [指令]};SARIF 2.1.0 runs[].results[] 結構"
revalidate_when: "SARIF schema 大改 / .lumos/lint.json 格式改 / _lint_run_and_parse subprocess 逾時或 killpg 機制改 / 座標系對齊判定改"
tags:
  - type/verification
  - status/pass
related:
  - "[[pitfalls-lint-adapter]]"
summary: |-
  TEST:全套件 412 passed(base 39ab438 起 378→384→390/397→412 逐 task 遞增);新增 6 測試函式覆蓋五 helper + 整合
  VERIFY:subagent-driven 五 task,每 task 派乾淨 reviewer(spec+quality 雙判)、Task3 核心走 opus 複核 + fix 複審、Task4 整合 opus 複核
---
# 2026-07-04_pitfalls-lint-adapter

pitfalls-lint-adapter(pitfalls-lint-integration 計劃第 ① 塊)實作驗證。spec 9 輪 design-loop + KDS tracer 坐實六大承重點 + qwen endorsed-after-refute → writing-plans 5 task → subagent-driven 實作。

## 測試覆蓋(scripts/test_lumos.py,全套件 412 passed)
- `t_lint_aligned`(Task1)——`_diff_added_lines` added 行集合 + `_lint_aligned` 乾淨/`...`不炸/dirty 三邊界。
- `t_lint_config`(Task2)——`.kt` 去點命中 / undeclared `.vue`→[] / 缺檔→None / 壞 JSON→None / 多檔同棧去重。
- `t_lint_sarif`(Task3)——絕對 file:// uri 正規化 repo 相對 / per-run driver source / location-less 跳不連坐 / 失敗 ok False。
- `t_lint_sarif_malformed_run` + `t_lint_sarif_relative_uri`(Task3 fix 硬化)——malformed run(缺 tool)跳不 crash / 相對 uri 不誤 relpath。
- `t_pitfalls_lint_integration`(Task4,15 checks)——lint+regex 合併 source 區分 / 對齊過濾(在 diff 行留、不在濾掉)/ dirty 降級全收+filtered:false / 無 config regex-only(無 lint_ran)/ cmd 失敗→lint_skipped+rc0+regex 仍在 / 未碰宣告棧→lint_ran 空。
- 回歸釘:`t_pitfalls_diff` / `t_pitfalls_spec` 全 task 保持綠(向後相容)。

## 逐 task review 結論
- T1/T2/T4:spec ✅ + quality Approved 0 Critical/Important。
- T3(核心,opus review):初版 1 Important(malformed run 缺 tool/driver/name 連坐整 helper crash)+ 1 真 silent-drop Minor(相對 uri 誤 relpath)→ fix 派修 + 新測試 + opus 複審 both resolved。
- Minor 留最終 review:lint 分支 text(非 --json)path 無斷言(人面向低風險);tier 運算式兩分支重複(刻意保向後相容)。

## 已知限制 / 天花板
- 只驗「lint 有無真跑到 + SARIF 有無正確解析合併」,不驗規則對錯(規則正確性是社群 linter 的事)。
- 座標系對齊靠 heuristic(右端 ref==HEAD + 乾淨工作區);非對齊降級全收=寧噪音不漏。
- implementer 多次 `--no-verify` 繞 KG pre-commit gate(code-only task,Task5 補架構圖);merge 後測試 runner=anchor 須 approve 重簽。
