---
type: verification
status: pass
created: 2026-07-06
updated: 2026-07-06
plan_refs:
  - "[[CLAUDE注入re-sync與版本標籤_計劃]]"
related:
  - "[[CLAUDE注入re-sync與版本標籤_計劃]]"
  - "[[CLAUDE注入re-sync與版本標籤_實作計畫]]"
  - "[[lumos-cli-lifecycle]]"
tags:
  - type/verification
  - status/pass
summary: |-
  TEST:CLAUDE 注入 re-sync + 版本標籤實作完成,826 passed 0 failed(branch feat/claude-reinject,TDD 6 task + opus whole-branch 終審 Ready to merge 無 Critical/Important);修「lumos update/init 從不刷新既有專案 CLAUDE.md 紀律區塊」破口
  VERIFY:_extract_claude_block_span 三態(found/absent/broken,text[start:end]==body 不變量)+ _reinject_claude_block 6-status(覆蓋 sentinel 之間 body + diff,sentinel 外 byte-equal 合約)+ 解耦注入 from _scaffold_project + 接線 _vendor_toolchain(copy2 後,修順序)/cmd_init(既有 vault 只 re-inject 不 pull/重裝 hooks)+ doctor Check D 內容比對漂移守衛(_expected_claude_body 單一源)+ LUMOS_VERSION 版本戳(body 外→不觸發 Check D)+ Check N nudge(soft advisory,來源不可達靜默 skip)
  KEY:版本=標籤/advisory 非正確性守衛,內容比對(Check D)才是守衛——code 落實無偷用版本當 oracle(終審實證);design-loop 3 輪(架構折穩、glue 天花板轉 TDD,見 [[CLAUDE注入re-sync與版本標籤_計劃]])
  KEY:誠實天花板=doctor --no-verify 繞得過;nudge 只在來源可達的開發機生效(CI skip);非 oracle
---
# 2026-07-06 CLAUDE 注入 re-sync + 版本標籤驗證

修「vendored 教學範本(`graph-discipline.md`)改了、`lumos update`/`init` 卻從不刷新既有專案已注入的 CLAUDE.md 紀律區塊」的破口(使用者點出「最重要的是教會 Claude 用本工具」)。落地 [[CLAUDE注入re-sync與版本標籤_計劃]](設計經 design-loop 3 輪、glue 天花板轉 TDD)。

## 測試結果
- **`scripts/test_lumos.py` 826 passed, 0 failed**(基線 736 → +90:extract_span 三態/reinject 6-status/preserves_outside ★INVARIANT★/解耦+接線整合/Check D 漂移守衛/版本戳不觸發守衛/nudge skip/broken no-crash)。
- TDD 6 task,每 task fresh subagent + sonnet review + fix loop;opus whole-branch 終審 **Ready to merge、無 Critical/Important**。本 repo `lumos doctor` 0 漂移。

## 交付(對應設計三交付物)
1. `_extract_claude_block_span`(三態 + body 位移,`text[body_start:body_end]==body` 有保證)+ `_reinject_claude_block`(6-status:created/updated/unchanged/appended/sentinel_broken/no_template;覆蓋 sentinel 之間 body、diff、BOM/CRLF 正規化)。
2. 解耦注入 from `_scaffold_project`(其 skip-if-exists 只保護架構圖資料);接 `_vendor_toolchain`(copy2 vendor 後 re-inject、修「讀舊範本」順序)+ `cmd_init`(既有 vault 非 force 只 `_reinject` 不 pull/不重裝 hooks);doctor **Check D** 內容比對漂移守衛(`_expected_claude_body` 單一源給 reinject 與 Check D 共用)。
3. `LUMOS_VERSION`(v1.0)版本戳蓋 START sentinel 行(body 外 → 版本 bump 不觸發 Check D)+ **Check N** nudge(soft advisory、語意版本 tuple 比較、來源 `_lumos_src()` 不可達靜默 skip)。

## opus 終審實證(逐點驗過)
- **★INVARIANT★ sentinel 外 byte-equal**:splice `text[:body_start]+新body+text[body_end:]`,`t_reinject_preserves_outside` 斷言前後綴 byte 相等。
- **單一源**:`_expected_claude_body` 被 reinject 與 Check D 同用,round-trip body==expected 實證(update 剛刷新 doctor 不自相矛盾)。
- **版本解耦**:`t_version_bump_not_trigger_guard`(START v0.9 + body==範本 → Check D 淨)。
- **nudge soft**:`warn_soft` 不計 issue、`--ci` 不受影響;`t_nudge_skip_when_no_source`。
- **接線副作用**:`t_init_existing_no_pull`(既有 vault 非 force init → `_vendor_toolchain` 未被呼叫、無 pull/無重裝 hooks)。

## 迭代修正(2026-07-07)
- **存量戶版本戳缺口(Landmark 真機發現)**:原 updated 路徑只換 body、START 行原樣保留 → 既有安裝戶永遠拿不到版本戳(標籤機制對主要客群虛設)。修:found 路徑同步刷新 START 行(在管理區塊內,★INVARIANT★ 只保護 sentinel 外,不違約);body 同+START 同才 unchanged(冪等保持)。[test:t_version_stamp_on_updated_path]

## 誠實天花板
- **版本 ≠ 守衛**:版本號只驅動 advisory nudge,正確性靠 Check D 內容比對(同「有寫下 undo ≠ 驗過能跑」)。
- **非 oracle**:doctor Check D `--no-verify` 繞得過;nudge 只在來源可達的開發機生效(CI/無源 skip)。守得掉「範本改了沒傳到/repo 內漂移」,守不掉「刻意繞 + 手改不看 diff」。
- **design-loop glue 天花板**:設計層 3 輪未過 gate(glue 密集、非架構未解),殘留實作細節由本次 TDD 紅綠釘死(見設計節點 TEST)。
