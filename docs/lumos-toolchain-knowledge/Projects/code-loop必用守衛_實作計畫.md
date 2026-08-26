---
type: project
status: done
created: 2026-07-05
updated: 2026-07-05
tags:
  - type/project
  - status/done
related:
  - "[[code-loop必用守衛_計劃]]"
plan_refs:
  - "[[code-loop必用守衛_計劃]]"
summary: |-
  FLAG:DECISION
  KEY:「code-loop 必用守衛」TDD 實作計畫(設計見 [[code-loop必用守衛_計劃]]);5 task=T1 code-loop 留痕(pass/skip/check 綁 HEAD)→ T2 guard 判定式(tier-high∧無pass∧無skip)→ T3 Stop hook 注入 nag → T4 pre-push 升 blocking → T5 skill/doc+回歸+回填
  KEY:留痕 governance/code-loop/<branch>.json {head_sha,status:passed|skipped,note,ts};HEAD 移動→作廢(綁 diff 狀態)
  DECISION:subagent-driven TDD;基線=main 現值(先跑取)
  DEP:[[code-loop必用守衛_計劃]]
  TEST:未開工
---
# code-loop 必用守衛 Implementation Plan

> **REQUIRED SUB-SKILL:** superpowers:subagent-driven-development。**設計權威**:[[code-loop必用守衛_計劃]](§1 架構/§2 收斂綁HEAD/§3 skip/§4 天花板/§5 測試)。

**Goal:** 收 code-loop「靠記得調用」破口:Stop hook 注入 nag + pre-push 升 blocking + `code-loop` 留痕(pass/skip 綁 HEAD)。

**Architecture:** `lumos code-loop {check,pass,skip}` 讀寫 `governance/code-loop/<branch>.json`(綁 HEAD sha)→ guard 判定式 `tier-high(pitfalls --diff)∧無有效pass∧無有效skip` → Stop hook 注入 nag / pre-push rc1 擋。

**Tech Stack:** python3 stdlib;既有 `pitfalls --diff --no-lint --json`(取 tier)、git rev-parse(HEAD/branch)、impact-hook.py(Stop hook push 范式)、merge-claude-settings.py(註冊)。

## Global Constraints
- 零第三方依賴。
- 判定三處共用:tier=high AND 無有效 pass AND 無有效 skip。
- **綁 HEAD sha**:pass/skip 存當時 HEAD;當前 HEAD 不符→作廢。
- Stop hook **只注入不擋**(Stop 分不出做完/中途);pre-push 才硬擋。
- skip 留痕(治理帳);`--no-verify` git-native 繞得過(接受)。
- 測試進 `scripts/test_lumos.py` 用 `check()`;基線=先跑 `python3 scripts/test_lumos.py` 取。
- 非 oracle:守衛關「忘了/隨手漏」,關不掉「刻意繞」。

---

### Task 1: `lumos code-loop {pass,skip,check}` 留痕(綁 HEAD)

**Files:** Modify `scripts/lumos`(新 `cmd_code_loop` + argparse subparser);Test。

**Interfaces:** `governance/code-loop/<branch>.json` = `{head_sha, status:"passed"|"skipped", note, ts}`;`_codeloop_read(repo_root, branch)`/`_codeloop_write(...)`;`code-loop pass --note`/`code-loop skip --note`/`code-loop check`。

- [ ] **Step 1: 失敗測試** — `code-loop pass --note x` 寫留痕(head_sha=當前 HEAD、status=passed);`skip` 同(status=skipped);讀回正確;branch/head 從 git 取。
```python
def t_codeloop_ledger():
    with tempfile.TemporaryDirectory() as d:
        _git_init_commit(d)  # helper:git init + 一個 commit
        rc = run_lumos(["code-loop","pass","--note","done","--repo",d]); assert rc==0
        rec = _codeloop_read(d, _git_branch(d))
        assert rec["status"]=="passed" and rec["head_sha"]==_git_head(d) and rec["note"]=="done"
```
- [ ] **Step 2: FAIL**。Run: `python3 scripts/test_lumos.py -k codeloop_ledger`
- [ ] **Step 3: 實作** — argparse `code-loop {pass,skip,check}`;pass/skip 寫 `governance/code-loop/<branch>.json`(git 取 branch/HEAD;ts 用 payload/傳入或省略——**Date.now 禁,ts 由 git commit 時間或省略**,用 `git rev-parse HEAD` 的 committer date 或留空);note 進治理帳(gov-log)。`code-loop check` 見 T2。
- [ ] **Step 4: PASS**。
- [ ] **Step 5: Commit** `feat(code-loop): pass/skip 留痕(綁 HEAD sha)`

---

### Task 2: guard 判定式 + `code-loop check`

**Files:** Modify `scripts/lumos`(`_codeloop_guard_verdict` + `cmd_code_loop` 的 check);Test。

**Interfaces:** `_codeloop_guard_verdict(repo_root) -> dict{blocked:bool, reason, tier}`;`lumos code-loop check` rc(blocked=1/否則0)+ --json。

- [ ] **Step 1: 失敗測試** — tier=high∧無留痕→blocked;pass(HEAD 相符)→不 blocked;skip(HEAD 相符)→不 blocked;pass 但 HEAD 移動(再 commit)→作廢 blocked;tier≠high→不 blocked。
```python
def t_codeloop_guard_verdict():
    # mock/造 pitfalls tier=high 的 diff + 留痕狀態,斷言 blocked 各情境
    ...
```
- [ ] **Step 2: FAIL**。
- [x] **Step 3: 實作** — 見設計 §1+§2:跑 `pitfalls --diff <range> --no-lint --json` 取 tier;讀留痕,pass/skip 的 sha == 目標 才有效;`blocked = tier=="high" and not valid_pass and not valid_skip`。`code-loop check` 印 verdict、rc=blocked?1:0。**範圍取法(2026-07-22 prepush範圍修法落地)：pre-push 改讀 stdin 推送範圍逐 ref 判(取代 merge-base，堵 main-direct 盲區)；`code-loop check` 加 `--diff/--at-sha/--branch` 委派、留痕綁 remote_ref 目的地。見 [[Projects/prepush主幹範圍修法_計劃]]。**
- [ ] **Step 4: PASS**。
- [ ] **Step 5: Commit** `feat(code-loop): guard 判定式(tier-high∧無pass∧無skip,綁HEAD)+check`

---

### Task 3: Stop hook 注入 nag

> ⚠ **已撤除(2026-07-06 ADR)**:此 Stop nag 每回合太擾民,改由 pre-push 單點把關;腳本 scripts/hooks/claude/code-loop-guard.py 與 Stop 註冊已對稱移除(commit 14b41eb)。以下為當時計畫原文,保留歷史。

**Files:** Create scripts/hooks/claude/code-loop-guard.py(已撤除);Modify `scripts/merge-claude-settings.py`(Stop 註冊);Test。

**Interfaces:** Stop hook:verdict blocked → 印 `{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":...}}`(nag,不擋回合)。

- [ ] **Step 1: 失敗測試** — verdict blocked → 注入 additionalContext(含「跑 lumos-code-loop 或 lumos code-loop skip」);不 blocked → 無輸出;fail-open(lumos 缺席/非 git → 靜默)。
- [ ] **Step 2: FAIL**。
- [ ] **Step 3: 實作** — 見設計 §1:Stop hook 讀 payload cwd/`$CLAUDE_PROJECT_DIR` → subprocess `lumos code-loop check --json` → blocked 則注入 nag(**Stop event、只注入不 block**)。fail-open(同 impact-hook 范式:lumos 缺席/非架構圖/非 git 靜默)。**不擋回合**(Stop decision 不設 block)。
- [ ] **Step 4: PASS**。
- [ ] **Step 5: Commit** `feat(code-loop-guard): Stop hook 注入 nag(tier=high 未過 code-loop)`

---

### Task 4: pre-push 升 blocking

**Files:** Modify `scripts/hooks/pre-push`;Test(shell 行為或函式化)。

**Interfaces:** pre-push:verdict blocked → **rc1 擋 push**(從 advisory 升級);訊息含跑法/skip 法。

- [ ] **Step 1: 失敗測試** — 造 tier=high∧無留痕 → pre-push rc≠0(擋);有 pass(HEAD 符)→ rc0(放);skip→放;tier≠high→放。(pre-push 是 shell,測試可呼叫 `lumos code-loop check` 的 rc 對齊 + 端到端 smoke)
- [ ] **Step 2: FAIL/確認**。
- [ ] **Step 3: 實作** — 見設計 §1:pre-push 現有 tier=high advisory 段(`scripts/hooks/pre-push:43-55`)改為:跑 `lumos code-loop check` → blocked(rc1)則 **exit 1 擋 push** + 印(「跑 lumos-code-loop 或 lumos code-loop skip --note；或 --no-verify 繞(自負)」);否則放行。保留 anchor/graph-doctor 其他 pre-push 檢查。
- [ ] **Step 4: PASS** + 端到端 smoke(造 tier=high 分支 → push 被擋 → code-loop skip → 放)。
- [ ] **Step 5: Commit** `feat(pre-push): tier=high 未過 code-loop → 硬擋 push(升 blocking)`

---

### Task 5: skill/doc 接線 + 回歸 + 回填

**Files:** Modify `skills/lumos-code-loop/SKILL.md`(收斂後呼叫 `code-loop pass`)、`skills/lumos-project-notes/SKILL.md` + `CLAUDE.md` + `scripts/templates/graph-discipline.md`(使用指南補);Test 回歸;架構圖回填(controller)。

- [ ] **Step 1: 回歸測試** — tier≠high 分支:`code-loop check` 不 blocked、Stop 不 nag、pre-push 不擋(不誤傷)。全量 `python3 scripts/test_lumos.py` 0 failed。
- [ ] **Step 2: 確認**。
- [ ] **Step 3: 接線** — lumos-code-loop SKILL 收斂(loop status gate 過)後**強制 `lumos code-loop pass --note`** 記留痕(否則 pre-push 仍擋——閉環);使用指南三處補(Stop nag + pre-push code-loop 硬擋 + `code-loop pass/skip/check` 指令)。
- [ ] **Step 4: PASS** + doctor 0。
- [ ] **Step 5: Commit** `feat(code-loop-guard): skill/doc 接線 + 回歸`

---

## 落地回填(controller)
`Verification/2026-..._code-loop必用守衛` plan_refs 回指;設計 TEST/status;merge-claude-settings anchor 註冊 Stop hook(不進 ANCHOR_FILES,同 impact-hook)。
