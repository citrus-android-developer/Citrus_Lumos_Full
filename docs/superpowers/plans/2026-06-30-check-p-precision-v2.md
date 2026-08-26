# Check P v2 精度精煉 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 精煉 `lumos doctor` Check P 路徑抽取:跳 glob/模板 token(`* < > ?`)+ 一般化後綴剝除(剝任何 `:後綴`、僅數字當行號),把真 vault 的 15 條噪音降到 1 條真指針。

**Architecture:** 只改 `scripts/lumos` Check P 區段(`section("P")` 內,`for raw in spans:` 迴圈 + `_line_re` 定義);其餘 rule(剝 fenced/反引號、含`/`、頂層目錄錨定、存在檢查、去重、warn_soft、repo_root 重用、輸出格式)全不動。純降噪、可逆。

**Tech Stack:** Python 3 stdlib(re);repo 既有 `scripts/test_lumos.py` `check()` harness + `_mk_docs_vault` fixture(v1 已建)。

## Global Constraints

- stdlib only,Python ≥3.8;純加性/精煉:不改 doctor rc、不改其餘 rule、不碰其他 check。
- glob 字元集 = `*`、`<`、`>`、`?`(觀測 + glob `?`);不擴及 `[` `]`。
- 後綴剝除:`:([^/]+)$` 取尾端非斜線後綴做存在檢查;**僅當後綴 `re.fullmatch(r"\d+(?:-\d+)?")` 才當行號帶進輸出**,符號/中文錨剝掉不顯示行號。
- `://` 跳過仍在後綴處理之前。
- `scripts/rot-eval/` 仍會被報(不跳 [planned]、不特殊處理尾端 `/`)。
- 測試 CLI subprocess、`t_`-prefixed、`check()`;沿用 `_mk_docs_vault`。

---

### Task 1: Check P v2 抽取精煉 + 測試

**Files:**
- Modify: `scripts/lumos`(`section("P")` 區段:`_line_re` 定義行 + `for raw in spans:` 迴圈頭)
- Test: `scripts/test_lumos.py`(新增 `t_doctor_check_p_precision`)

**Interfaces:**
- Consumes(皆既有):Check P 區段的 `repo_root`/`top_dirs`/`spans`/`seen_paths`/`stale_claims`、`re`、`warn_soft`/`ok`。
- Produces:Check P 抽取行為精煉(對外描述不變)。

- [ ] **Step 1: Write the failing test**

加到 `scripts/test_lumos.py`(`_mk_docs_vault` v1 已存在):

```python
def t_doctor_check_p_precision():
    root, vault = _mk_docs_vault(prefix="gctl-checkp-v2-")
    (root / "scripts").mkdir()
    (root / "scripts" / "real.py").write_text("x\n")
    (root / "governance").mkdir()  # 讓 glob token 的頂層目錄錨定不先擋,確保是 glob 過濾起作用
    # 案例 A:glob/模板 token → 不報
    write(vault, "Systems/a.md", "type: system\nstatus: done",
          "# A\n見 `governance/pending/*.md` 與 `docs/<slug>-knowledge/` 慣例。\n")
    # 案例 B:符號/中文錨且檔存在 → 不報
    write(vault, "Systems/b.md", "type: system\nstatus: done",
          "# B\n見 `scripts/real.py:t_some_test` 與 `scripts/real.py:行號`。\n")
    # 案例 C:真死指針帶數字行號 → 報且顯示 :10
    write(vault, "Systems/c.md", "type: system\nstatus: done",
          "# C\n見 `scripts/ghost.py:10` 實作。\n")

    r = run(vault, "doctor")
    check("Check P v2: glob/模板不報", "governance/pending/*.md" not in r.stdout and "<slug>" not in r.stdout, r.stdout)
    check("Check P v2: 符號/中文錨且檔存在不報", "scripts/real.py" not in r.stdout, r.stdout)
    check("Check P v2: 真死指針報出", "scripts/ghost.py" in r.stdout, r.stdout)
    check("Check P v2: 數字行號顯示 :10", "Systems/c.md:10" in r.stdout, r.stdout)
    check("Check P v2: rc 不變", r.returncode == 0, f"rc={r.returncode}")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "Check P v2"`
Expected: FAIL — v1 會把 glob `governance/pending/*.md`(`governance` 頂層存在)與 `scripts/real.py:行號`(`:行號` 非數字、token 留 `scripts/real.py:行號` 不存在)誤報 → `不報` 斷言失敗。

- [ ] **Step 3: Apply the precision edits**

(3a) 把 `_line_re` 定義改為後綴 regex。Edit `scripts/lumos`:

old:
```python
        _line_re = re.compile(r":\d+(?:-\d+)?$")
```
new:
```python
        _suffix_re = re.compile(r":([^/]+)$")
```

(3b) 把 `for raw in spans:` 迴圈頭(`://` 跳過 + 行號剝除)整段替換。Edit `scripts/lumos`:

old:
```python
            for raw in spans:
                if "://" in raw:
                    continue
                m = _line_re.search(raw)
                line = m.group(0)[1:] if m else ""
                token = _line_re.sub("", raw)
                if "/" not in token or token in seen_paths:
                    continue
                if token.split("/")[0] not in top_dirs:
                    continue
```
new:
```python
            for raw in spans:
                if "://" in raw or any(c in raw for c in "*<>?"):
                    continue
                m = _suffix_re.search(raw)
                if m:
                    token, sfx = raw[:m.start()], m.group(1)
                    line = sfx if re.fullmatch(r"\d+(?:-\d+)?", sfx) else ""
                else:
                    token, line = raw, ""
                if "/" not in token or token in seen_paths:
                    continue
                if token.split("/")[0] not in top_dirs:
                    continue
```

> 其餘行(`seen_paths.add`、`(repo_root / token).exists()`、`loc = f"{rel}:{line}" if line else rel`、`stale_claims.append`、warn_soft/ok)不動。

- [ ] **Step 4: Run tests to verify pass + v1 regression**

Run: `python3 scripts/test_lumos.py 2>&1 | grep -E "Check P"`
Expected: `t_doctor_check_p_precision` 5 行全 `✓`;**v1 的 `t_doctor_check_p` 7 案例仍全 `✓`**(案例 1 `scripts/ghost.py` 仍報、案例 2 `scripts/real.py:10` 仍不報、fenced 仍不抓、無 docs 略過、rc0)。

Run: `python3 scripts/test_lumos.py`
Expected: `N passed, 0 failed`。

- [ ] **Step 5: Smoke on real vault(降噪驗證)**

Run: `./scripts/lumos doctor 2>&1 | sed -n '/\[P\]/,/^\[/p' | grep "→"`
Expected: 從 15 條降到 **1 條**(`Systems/verification-rot-eval.md → scripts/rot-eval/`);doctor 結尾仍 `✓ 架構圖健康 — 0 issues`(Check P 軟、不改 rc)。

- [ ] **Step 6: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): Check P v2 精度精煉(跳 glob/模板 + 一般化後綴剝除,真 vault 噪音 15→1)"
```

---

## Self-Review

**Spec coverage**(對照 `docs/design/2026-06-30-check-p-precision-v2.md`):
- §範圍 ① 跳 glob/模板(`*<>?`)→ Step 3b `any(c in raw for c in "*<>?")`。✓
- §範圍 ② 一般化後綴剝除(`:([^/]+)$`、僅數字當行號)→ Step 3a `_suffix_re` + Step 3b `re.fullmatch(r"\d+(?:-\d+)?", sfx)`。✓
- 其餘 rule 不動 → 只改 2 處(`_line_re` 定義 + 迴圈頭),其餘行原樣。✓
- §邊界(不跳 planned、不特殊處理尾端 `/`、`*<>?` 字元集)→ Global Constraints + rot-eval 仍報(Step 5 預期 1 條)。✓
- §測試策略(glob 不報、符號錨檔存在不報、真死指針帶 :10 報、v1 回歸)→ Step 1 + Step 4。✓
- §知識同步(對外描述不變、無需改 skill/方法論)→ 計畫無 doc 同步 task,符合。✓
- §誠實天花板 → 設計認知,不需 code。✓

**Placeholder scan:** 無 TBD;Step 3 完整 old/new、Step 1 完整測試。✓

**Type consistency:** `_suffix_re`(取代 `_line_re`)Step 3a 定義、3b 使用,一致;`token`/`line`/`sfx` 在 3b 內定義即用;測試斷言字串(`governance/pending/*.md`、`scripts/ghost.py`、`Systems/c.md:10`)與實作輸出格式一致。✓
