---
type: project
status: done
created: 2026-07-09
updated: 2026-07-09
tags:
  - type/project
  - status/done
related:
  - "[[loop三輪壓縮_計劃]]"
plan_refs:
  - "[[loop三輪壓縮_計劃]]"
summary: |-
  FLAG:DECISION
  KEY:「loop 三輪壓縮」TDD 實作計畫(設計權威=[[loop三輪壓縮_計劃]],經 2 輪平行 panel dogfood + 3 線文獻交叉);策略=TDD 機械核心、prose(skills/orchestrator)當文檔接線(spec 自身天花板:glue 留實作真測不設計散文摳)
  KEY:6 task=T1 capture-recapture 殘餘估計(純函式 Chao1)→ T2 cmd_canary --round 留痕→ T3 cmd_loop_status --panel 謂詞(輪有效+ODC class-gating+falsification-survived+capture-recapture 殘餘<門檻+混用報錯)→ T4 difficulty panel_width→ T5 prose 接線(skills/templates/orchestrator/Systems)→ T6 架構圖回填+回歸+anchor
  DECISION:subagent-driven TDD;基線 828 passed;向後相容(無 --panel/--round=舊 K-streak∧G2 不變)
  DEP:[[loop三輪壓縮_計劃]]
  TEST:未開工
---
# loop 三輪壓縮 Implementation Plan

> **REQUIRED SUB-SKILL:** superpowers:subagent-driven-development。**設計權威**:[[loop三輪壓縮_計劃]](平行 panel 結構 / 收斂判準定案四條 / 散文收斂三機制 / R1-R2 dogfood 折入)。

**Goal:** 把 canary-護對抗審計 loop 從 6 輪同族循序壓成 ≤3 輪平行多樣 panel,收斂信號改建在結構(capture-recapture 重疊 + ODC class + AC coverage)上,不動 refute-framing。

**Architecture:** 機械核心進 `scripts/lumos`(capture-recapture 估計 + `--panel` gate 謂詞 + `--round` 留痕)+ `difficulty.py`(panel_width);prose(skills/templates/orchestrator)描述怎麼跑 panel + 用這些原語,當文檔接線不 design-loop。

## Global Constraints
- 零第三方依賴(capture-recapture 純 stdlib)。
- **向後相容**:無 `--panel`/無 `round` 欄 → 現行 K-streak∧G1∧G2 舊模式**分毫不變**;`--panel` 與 round-tagged log 混用 → **報錯拒讀**(不靜默把 W 筆當 W 輪,殺 R2-F1 footgun)。
- 測試進 `scripts/test_lumos.py` 用 `check()`;基線 828 passed。
- panel gate 四條合取:輪有效(≥2 canary caught)∧ ODC 只缺陷類 gate ∧ falsification 後零 ≥major 存活 ∧ capture-recapture 殘餘<門檻。

---

### Task 1: capture-recapture 殘餘缺陷估計(純函式)

**Files:** Modify `scripts/lumos`(新 `_estimate_remaining_defects`);Test。

**Interfaces:** `_estimate_remaining_defects(capture_counts: list[int]) -> float`——輸入=各 distinct 缺陷「被 W 個審計員中幾個找到」的次數列表;回殘餘估計。用 **Chao1 偏差修正**:`f1=(只1人找到數), f2=(恰2人), remaining = f1*(f1-1)/(2*(f2+1))`(f2=0 不炸)。

- [x] **Step 1 失敗測試**:`t_caprecap_estimate`——全高重疊(每缺陷都多人找到,f1=0)→ remaining≈0;高 f1 低 f2(各找各的)→ remaining 大;f2=0 不 div0;空輸入→0。
- [x] **Step 2 FAIL**:`python3 scripts/test_lumos.py -k caprecap`
- [x] **Step 3 實作** Chao1 偏差修正純函式。
- [x] **Step 4 PASS**。
- [x] **Step 5 Commit** `feat(loop): capture-recapture 殘餘估計(Chao1,平行 panel 收斂信號)`

---

### Task 2: `cmd_canary record --round` 留痕欄

**Files:** Modify `scripts/lumos`(cmd_canary + argparse);Test。

**Interfaces:** `canary record ... --round <id>` 選填;schema 加 `round` 欄(無則 None,向後相容)。

- [x] **Step 1 失敗測試**:`t_canary_round_field`——帶 --round 寫入含 round 欄;不帶則無此欄(舊記錄格式不變);讀回正確。
- [x] **Step 2 FAIL**。
- [x] **Step 3 實作** argparse `--round` + 函式參數 + schema。
- [x] **Step 4 PASS**。
- [x] **Step 5 Commit** `feat(loop): canary record --round 留痕欄(panel 一輪 W 筆共享)`

---

### Task 3: `cmd_loop_status --panel` 收斂謂詞

**Files:** Modify `scripts/lumos`(cmd_loop_status + argparse);Test。

**Interfaces:** `loop status <id> --gate --panel [--repo]`——按 round-id 分組;每組判四條合取。混用守衛:`--panel` 但 log 無 round 欄、或 無 --panel 但 log 有 round 欄 → rc2 + 明確錯訊(不靜默誤算)。缺陷計數/severity 由 record 欄提供(orchestrator 已 ODC 分類後寫入);capture-recapture 吃各組的 per-defect capture_counts(record 需帶或由 note 結構化——實作定最小 schema)。

- [x] **Step 1 失敗測試**:`t_loop_panel_converged`(一組 ≥2 caught + 存活 max≤minor + 殘餘<門檻 → rc0)、`t_loop_panel_invalid_round`(<2 caught → 不收斂)、`t_loop_panel_major_survives`(存活 major → 不收斂)、`t_loop_panel_mixed_log_errors`(--panel 讀到無 round 欄 / 舊模式讀到 round 欄 → rc2)、`t_loop_legacy_unchanged`(無 --panel 無 round → K-streak∧G2 行為與現況逐位元相同)。
- [x] **Step 2 FAIL**。
- [x] **Step 3 實作** 分組 + 四條合取 + 混用守衛;legacy 路徑完全不動(新分支包在 `if panel:`)。
- [x] **Step 4 PASS** + 本 repo `lumos doctor` 不受影響。
- [x] **Step 5 Commit** `feat(loop): loop status --panel 收斂謂詞(輪有效∧ODC∧falsification∧capture-recapture)`

---

### Task 4: `difficulty.params` 加 panel_width

**Files:** Modify `governance/autonomous_loop/difficulty.py`;Test。

**Interfaces:** `params(tier)` 回傳加 `panel_width`(standard=3、high=5);既有 {need,maxr} 消費端不受影響(多一鍵)。

- [x] **Step 1 失敗測試**:`t_difficulty_panel_width`——standard→3、high→5;既有 need/maxr 值不變。
- [x] **Step 2 FAIL**。
- [x] **Step 3 實作** + 確認 `test_autonomous_loop.py` 既有測試不退步。
- [x] **Step 4 PASS**。
- [x] **Step 5 Commit** `feat(loop): difficulty panel_width(tier 驅動並行寬度)`

---

### Task 5: prose 接線(skills / templates / orchestrator / Systems)

**Files:** `skills/lumos-design-loop/SKILL.md`(每輪→panel 結構+四條收斂)、`skills/lumos-design-loop/templates.md`(新增平行 panel 派工模板 + W-slot canary 分派 + 判讀:ODC 分類/capture_counts 記錄)、`skills/lumos-code-loop/SKILL.md`(panel 化的 diff 分派)、`governance/autonomous_loop/orchestrator-prompt.md`(步驟 3-8 改平行 + cross_audit 接 panel)、`Systems/design-loop.md`、`Systems/convergence-evidence-gate.md`(G2 序列→panel 結構信號)。

- [x] **Step 1** 改上述 prose,描述怎麼跑 panel + 用 T1-4 原語;明標「派工以 templates.md 為權威」。
- [x] **Step 2** 全量 `python3 scripts/test_lumos.py` 0 failed(prose 改動不該動測試,除非動到 doctor Check D 的範本比對——CLAUDE.md 經 reinject 同步)。
- [x] **Step 3 Commit** `docs(loop): panel 化 prose 接線(skills/orchestrator/Systems)`

---

### Task 6: 架構圖回填 + 回歸 + anchor

- [x] Verification `plan_refs` 回指設計節點;設計/實作 status→done;`Systems/design-loop` + `convergence-evidence-gate` KEY 更新(panel 收斂)。
- [x] 全量測試 0 failed;`lumos doctor` 0 issues。
- [x] anchor approve(test_lumos.py 動了)。
- [x] Commit `docs(graph): loop 三輪壓縮落地回填`

---

## 落地回填(controller)
Verification plan_refs 回指;merge main + anchor approve + push。**本分支自身終審**:可用**新的平行 panel** 跑(dogfood 上線版);tier=high 則需真收斂或人裁。
