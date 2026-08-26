---
type: project
status: done
created: 2026-07-05
updated: 2026-07-06
tags:
  - type/project
  - status/done
related:
  - "[[CLAUDE注入re-sync與版本標籤_計劃]]"
plan_refs:
  - "[[CLAUDE注入re-sync與版本標籤_計劃]]"
summary: |-
  FLAG:DECISION
  KEY:「CLAUDE 注入 re-sync + 版本標籤」TDD 實作計畫(設計權威=[[CLAUDE注入re-sync與版本標籤_計劃]],已過 design-loop 3 輪、架構折穩、glue 細節交 TDD);6 task
  KEY:T1 marker常數+_extract_claude_block_span 三態→ T2 _reinject_claude_block(5-status+diff+半壞+BOM)→ T3 解耦_scaffold+接線_vendor_toolchain/cmd_init→ T4 doctor Check D 漂移守衛→ T5 LUMOS_VERSION+版本戳+nudge→ T6 架構圖回填+回歸+anchor
  DECISION:subagent-driven TDD;基線=先跑 test_lumos.py 取
  DEP:[[CLAUDE注入re-sync與版本標籤_計劃]]
  TEST:T1 DONE — 16 checks green(t_extract_span_found/absent/broken);全量 752 passed(基線 736)|T2 DONE — 37 checks green(t_reinject_updates_existing/idempotent/creates_when_absent/appends_when_no_sentinel/preserves_outside/sentinel_broken/bom_crlf_normalized/no_template);全量 789 passed|T3 DONE — 9 checks green(t_scaffold_no_longer_injects/t_update_resyncs_claude/t_init_existing_resyncs);全量 798 passed|T3-review DONE — I-1既有vault非force只reinject不pull+I-2移除重複_install_hooks_py;新增t_init_existing_no_pull(4 checks);全量 802 passed|T4 DONE — Check D(字母D)+_expected_claude_body helper;4 tests 11 checks;全量 813 passed;本repo doctor 0 issues|T5 DONE — LUMOS_VERSION=v1.0+_START_TEMPLATE版本插值+_parse_sentinel_version+_version_nudge(dev-machine advisory)+Check N soft;5 tests 13 checks;826 passed;本repo doctor 0 issues Check D 0漂移;修復_make_check_d_block/_make_block停止內聯START常數
---
# CLAUDE 注入 re-sync + 版本標籤 Implementation Plan

> **REQUIRED SUB-SKILL:** superpowers:subagent-driven-development。**設計權威**:[[CLAUDE注入re-sync與版本標籤_計劃]](三交付物 + design-loop r1-r3 定案 + 誠實天花板)。

**Goal:** 讓 `lumos update`/`init` 真正刷新既有專案 CLAUDE.md 紀律區塊(覆蓋 sentinel 之間 + diff)+ 內容比對漂移守衛 + 版本標籤/nudge。

**Architecture:** 解耦「注入 CLAUDE.md」與「scaffold 架構圖資料」;`_extract_claude_block_span`(三態單一源)+ `_reinject_claude_block`(ReInjectResult 5-status)+ doctor Check D + `LUMOS_VERSION` 標籤。

**Tech Stack:** python3 stdlib(collections.namedtuple、difflib);既有 `_deinit_strip_claude`(marker 尋找)、`_vendor_toolchain`/`cmd_init`/`_scaffold_project`/`_lumos_src`/`_write_lf`。

## Global Constraints
- 零第三方依賴。
- **版本格式** `vMAJOR.MINOR`;**find 穩定前綴** `"<!-- LUMOS:GRAPH-DISCIPLINE:START"`(版本戳在其後)。
- 版本=標籤(advisory nudge)**非正確性守衛**;內容比對(Check D)才是守衛。
- **★INVARIANT★**:re-inject 保留 sentinel 之外內容 byte-equal(T6 綁 `[test:t_reinject_preserves_outside]`)。
- 測試進 `scripts/test_lumos.py` 用 `check()`;基線先跑 `python3 scripts/test_lumos.py` 取。
- 非 oracle:守得掉「範本改了沒傳到/repo 內漂移」,守不掉「--no-verify/手改不看 diff」。

---

### Task 1: marker 常數 + `_extract_claude_block_span`(三態)

**Files:** Modify `scripts/lumos`;Test。

**Interfaces:** `_CLAUDE_START_PREFIX = "<!-- LUMOS:GRAPH-DISCIPLINE:START"`、`_CLAUDE_END = "<!-- LUMOS:GRAPH-DISCIPLINE:END -->"`;`BlockSpan = namedtuple("BlockSpan","body body_start body_end")`;`_extract_claude_block_span(text) -> (state, span)`,state ∈ `"found"|"absent"|"broken"`,found 帶 BlockSpan、其餘 None。

- [x] **Step 1 失敗測試**:`t_extract_span_found`(完整 START..END→body/位移正確、含版本戳的 START 行仍 found)、`t_extract_span_absent`(無 sentinel→("absent",None))、`t_extract_span_broken`(只START/只END/END在START前→("broken",None))。
- [x] **Step 2 FAIL**:`python3 scripts/test_lumos.py -k extract_span`
- [x] **Step 3 實作**:prefix-based find START(用 `_CLAUDE_START_PREFIX`,對版本後綴穩健)+ 找該行 `\n`;find END;三態判斷;body=兩 sentinel 行之間、strip 首尾空白行;body_start/body_end=位移。
- [x] **Step 4 PASS**:16 checks green,全量 752 passed(基線 736)。
- [x] **Step 5 Commit** `feat(reinject): _extract_claude_block_span 三態 + marker 常數`

---

### Task 2: `_reinject_claude_block`(ReInjectResult 5-status)

**Files:** Modify `scripts/lumos`(用 T1);Test。

**Interfaces:** `ReInjectResult = namedtuple("ReInjectResult","status diff")`,status ∈ `created|updated|unchanged|appended|sentinel_broken|no_template`;`_reinject_claude_block(root, slug) -> ReInjectResult`。

- [x] **Step 1 失敗測試**:`t_reinject_updates_existing`(updated+diff)、`_idempotent`(unchanged 無寫)、`_creates_when_absent`(created)、`_appends_when_no_sentinel`(appended)、`_preserves_outside`(sentinel 外 byte-equal)、`_sentinel_broken`(半壞→sentinel_broken 原檔不動)、`_bom_crlf_normalized`、`_no_template`(範本缺→no_template)。
- [x] **Step 2 FAIL**:8 functions EXCEPTION (no attribute).
- [x] **Step 3 實作**:讀 vendored 範本(缺→no_template);`{{KG}}`→`docs/<slug>-knowledge/`;strip;包 sentinel(START 前綴固定字串,T5 插版本);讀 CLAUDE.md(strip BOM + CRLF→LF);`_extract_claude_block_span` 三態 → found:splice body_start/body_end + difflib(有變 updated 寫、無變 unchanged);absent 有檔:appended;無檔:created;broken:no-op 回 sentinel_broken;一律 `_write_lf`。
- [x] **Step 4 PASS**:37 checks green,全量 789 passed.
- [x] **Step 5 Commit** `feat(reinject): _reinject_claude_block 覆蓋+diff+5-status`

---

### Task 3: 解耦 `_scaffold_project` + 接線 `_vendor_toolchain`/`cmd_init`

**Files:** Modify `scripts/lumos`;Test(整合)。

- [x] **Step 1 失敗測試**:`t_update_resyncs_claude`(整合:臨時源+臨時消費專案、`_lumos_src` monkeypatch/env 指臨時源、既有舊 block→`update`→區塊刷新)、`t_scaffold_no_longer_injects`(scaffold 不再碰 CLAUDE.md)、`t_init_existing_resyncs`(既有 vault init 也刷新、免 --force)。
- [x] **Step 2 FAIL**。
- [x] **Step 3 實作**:`_scaffold_project` 移除注入段;`_vendor_toolchain` 在 copy2 迴圈**後**呼叫 `_reinject_claude_block` 印 status;`cmd_init` 序列改 vendor→reinject→existing/force return;no_hooks 路徑補 reinject 呼叫(讀本機 vendored 範本)。
- [x] **Step 4 PASS**:798 passed, 0 failed。
- [x] **Step 5 Commit** `feat(reinject): 解耦 scaffold + 接線 update/init(修順序)`
- [x] **T3 review fix** I-1:既有 vault 非 force → 只 `_reinject_claude_block`(不 pull、不重裝 hooks);I-2:移除 `cmd_init` 重複呼叫 `_install_hooks_py`。新增 `t_init_existing_no_pull`(4 checks)。802 passed。

---

### Task 4: doctor Check D(內容比對漂移守衛)

**Files:** Modify `scripts/lumos`(doctor);Test。

**Interfaces:** doctor 新 Check(字母 D 或順移):範本存在 且 CLAUDE.md 有 sentinel → `_extract_claude_block_span(CLAUDE).body == resolve(template).body`,否則報漂移;broken→報;`--ci` 擋。

- [x] **Step 1 失敗測試**:`t_claude_block_matches_template`(本 repo 同步→淨)、`t_doctor_reports_drift`(人為改 CLAUDE block→報)、`t_doctor_skip_no_template`(無範本→不 check 不誤報)、`t_doctor_broken_reports`(半壞→報、不 crash)。
- [x] **Step 2 FAIL**:t_doctor_reports_drift + t_doctor_broken_reports 失敗(Check D 未實作)。
- [x] **Step 3 實作**:`_expected_claude_body(root,slug)` helper(T2 共用單一源);Check D 加入 run_doctor 在 K 之後 V 之前;guard:無範本→skip/absent→skip/broken→issue/found+不等→issue;broken 不取 .body 避 crash;計入 issues;--ci 非零。
- [x] **Step 4 PASS** + `python3 scripts/lumos doctor` 本 repo 淨(0 issues,Check D:同步)。
- [x] **Step 5 Commit** `feat(doctor): Check D 紀律區塊漂移守衛(內容比對)`

---

### Task 5: `LUMOS_VERSION` + 版本戳 + nudge

**Files:** Modify `scripts/lumos`(新常數 + reinject 插值 + nudge);Test。

**Interfaces:** `LUMOS_VERSION = "vX.Y"`(頂部新建);reinject 包 START sentinel 時 `.format(version=LUMOS_VERSION)`;nudge:比對 CLAUDE sentinel 版本 vs `_lumos_src()` 的 LUMOS_VERSION,源不可達→靜默 skip。

- [x] **Step 1 失敗測試**:`t_version_stamped_in_sentinel`(reinject 後 START 行含 vX.Y)、`t_version_parse_tolerant`(START 無版本→未知不 crash)、`t_version_bump_not_trigger_guard`(版本改、body 不變→Check D 淨)、`t_version_nudge_when_behind`(源可達+落後→提示)、`t_nudge_skip_when_no_source`(`_lumos_src` 無→靜默不 crash)。
- [x] **Step 2 FAIL**。
- [x] **Step 3 實作**:`LUMOS_VERSION` 常數;START sentinel 帶 `{version}` 佔位、reinject format 插值;版本 parse(START 行空格切分取 vX.Y、容錯);nudge 讀 `_lumos_src()`/LUMOS_VERSION、源缺 skip。
- [x] **Step 4 PASS** + doctor 淨(版本戳不觸發 Check D)。826 passed, 0 failed;本 repo doctor --ci 0 issues / Check D 0 漂移。
- [x] **Step 5 Commit** `feat(version): LUMOS_VERSION 標籤 + 版本戳 + dev-machine nudge`

---

### Task 6: 架構圖回填 + 回歸 + anchor

**Files:** `Verification/2026-..._CLAUDE注入re-sync`;`Systems/lumos-cli-lifecycle`(KEY 更新 + ★INVARIANT★);anchor。

- [ ] **Step 1 回歸**:全量 `python3 scripts/test_lumos.py` 0 failed。
- [ ] **Step 2 確認**。
- [ ] **Step 3 回填**:Verification `plan_refs` 回指設計節點;`lumos-cli-lifecycle` 改 KEY「要重跑 init/update 才刷新→現已成真+解耦」、新增 `KEY:★INVARIANT★ re-inject 保留 sentinel 外內容 byte-equal [test:t_reinject_preserves_outside]`(`lumos guard bind` + `guard audit`)、`KEY:★DEBT★ 版本戳=標籤非守衛`。
- [ ] **Step 4 PASS** + doctor 0 + anchor approve(test_lumos.py 動了)。
- [ ] **Step 5 Commit** `docs(graph): CLAUDE re-sync 落地回填 + ★INVARIANT★ 綁定`

---

## 落地回填(controller)
Verification plan_refs 回指設計節點;設計 TEST/status→done;merge main + anchor approve(test 檔動)+ push。**本分支自身 tier 檢查**:多為既有檔改動,若 pitfalls 判 tier=high → code-loop 終審 + `code-loop pass` 閉環。
