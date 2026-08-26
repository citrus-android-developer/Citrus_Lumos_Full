# doctor Check P 失效檔案認領 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `lumos doctor` 新增軟性 Check P:掃節點正文 inline-code 路徑引用,指向已不存在的 repo 檔即軟提醒(架構圖指向死碼),不計 issues、不改 rc。

**Architecture:** 在 `run_doctor`(`scripts/lumos`)Check V 之後、`if ci:` 之前插入一段 Check P;重用 Check C 已推導的 `repo_root` 區域變數;路徑抽取 = 剝 fenced block → inline-code findall → strip 反引號 → 剝行號 → 含`/` → 頂層目錄錨定 → 存在檢查。純讀 `os.path.exists`、無 subprocess。知識同步另一任務。

**Tech Stack:** Python 3 stdlib(re, pathlib);repo 既有 `scripts/test_lumos.py` 的 `check()` harness。

## Global Constraints

- stdlib only,Python ≥ 3.8;**純加性**:不改 doctor rc、不改既有 `[2/4] Unresolved wikilinks` 與其他 check、不改 `lumos stale`。
- Check P 用 `warn_soft`(`scripts/lumos:384`,不計 issues、不改 rc)。
- 插入點:Check V 區塊的 `print()`(`scripts/lumos:730` 一帶)之後、`if ci:`(`scripts/lumos:749`)之前 → 段尾 T→R→S→H→K→V→**P**。
- **repo_root 重用 Check C 的區域變數**(`scripts/lumos:518-522` 已 `repo_root = None; for p in env.vault.parents: if p.name=="docs": repo_root=p.parent`);**不**引入 `git rev-parse`。`repo_root is None` → Check P 印 ok 並跳過。
- 路徑抽取嚴格照 spec rule 1-5:**先 `FENCE_RE.sub("",text)` 剝 fenced、`INLINE_CODE_RE.findall` 後 `.strip("`")` 剝定界符**(INLINE_CODE_RE 無 capture group、含反引號);剝尾端 `:\d+(?:-\d+)?$` 行號(記住);跳 `://`;須含 `/`;**第一段 ∈ repo_root 非隱藏頂層目錄**;`(repo_root/token).exists()` 為否 → finding。
- 輸出格式:有行號 `「<rel>:<line> → <token>(已不存在)」`、無行號 `「<rel> → <token>(已不存在)」`(不印 `:None`)。
- 測試 CLI subprocess(`run(v,"doctor")`)、`t_`-prefixed、`check()`。fixture 須 `docs/<slug>-knowledge` 佈局 + sibling `scripts/`(不需 git)。

---

### Task 1: Check P 實作 + 測試

**Files:**
- Modify: `scripts/lumos`(`run_doctor` 內,Check V `print()` 之後插入 Check P)
- Test: `scripts/test_lumos.py`(新增 `_mk_docs_vault` helper + `t_doctor_check_p`)

**Interfaces:**
- Consumes(皆既有):run_doctor 區域 `repo_root`(Check C 設)、`notes`、`section`/`ok`/`warn_soft` 閉包、`FENCE_RE`(`:39`)、`INLINE_CODE_RE`(`:40`)、`as_list` 不需要;`re` 已 module import。
- Produces:doctor 輸出新增 `[P]` 段。

- [ ] **Step 1: Write the failing test**

加到 `scripts/test_lumos.py`:

```python
def _mk_docs_vault(prefix="gctl-checkp-"):
    """建 temp_root/docs/<slug>-knowledge vault(讓 Check C 的 repo_root 推導命中 docs/ 母目錄)。
    回傳 (root, vault)。"""
    root = Path(tempfile.mkdtemp(prefix=prefix))
    vault = root / "docs" / "demo-knowledge"
    for sub in ("Systems", "Verification", "Projects", "MOC"):
        (vault / sub).mkdir(parents=True)
    (vault / "MOC" / "idx.md").write_bytes("---\ntype: moc\n---\n# idx\n".encode("utf-8"))
    return root, vault


def t_doctor_check_p():
    # 案例 1+2+3+4+5:同一 vault 多節點
    root, vault = _mk_docs_vault()
    (root / "scripts").mkdir()                       # rule 3 錨定靠 scripts/ 存在
    (root / "scripts" / "real.py").write_text("x\n") # 案例 2 的真實檔
    # 案例 1:失效認領(scripts/ghost.py 不存在)
    write(vault, "Systems/a.md", "type: system\nstatus: done",
          "# A\n見 `scripts/ghost.py` 實作。\n")
    # 案例 2:存在路徑帶行號 → 不報
    write(vault, "Systems/b.md", "type: system\nstatus: done",
          "# B\n見 `scripts/real.py:10` 一帶。\n")
    # 案例 3:散文/非路徑 → 不報
    write(vault, "Systems/c.md", "type: system\nstatus: done",
          "# C\n反引號 `and/or`、散文 maker/checker、反引號 `cmd_context`(無斜線)。\n")
    # 案例 4:fenced block 內路徑 → 不報
    write(vault, "Systems/d.md", "type: system\nstatus: done",
          "# D\n```\n`scripts/ghost.py`\n```\n")
    # 案例 5:無路徑引用 → 不報
    write(vault, "Systems/e.md", "type: system\nstatus: done", "# E\n純文字無反引號路徑。\n")

    r = run(vault, "doctor")
    check("Check P: 段標題出現", "[P]" in r.stdout, r.stdout)
    check("Check P: 案例1 報出 ghost", ("Systems/a.md" in r.stdout and "scripts/ghost.py" in r.stdout), r.stdout)
    check("Check P: 案例2 存在路徑不報", "scripts/real.py" not in r.stdout, r.stdout)
    check("Check P: 案例3 散文/非路徑不報", "and/or" not in r.stdout and "cmd_context" not in r.stdout, r.stdout)
    check("Check P: 案例4 fenced 內不報", r.stdout.count("scripts/ghost.py") == 1, r.stdout)  # 只有案例1那次
    check("Check P: rc 不變(warn_soft 軟提醒)", r.returncode == 0, f"rc={r.returncode}")

    # 案例 6:無 docs/ 佈局(mkvault 的 vault 不在 docs/ 下)→ Check P 略過
    v2 = mkvault()
    r2 = run(v2, "doctor")
    check("Check P: 無 docs/ 佈局略過", "略過失效認領" in r2.stdout, r2.stdout)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "Check P"`
Expected: FAIL — doctor 尚無 `[P]` 段(`"[P]" in r.stdout` 等斷言全失敗)。

- [ ] **Step 3: Insert Check P into `run_doctor`**

在 `scripts/lumos` 的 Check V 區塊結尾 `print()`(`scripts/lumos:730` 一帶)之後、`if ci:`(`:749`)之前插入:

```python
    section("P", "失效檔案認領 (節點正文 inline-code 路徑指向已不存在的檔;軟提醒、不擋 CI)")
    if repo_root is None:
        ok("(無 docs/ 佈局,略過失效認領檢查)")
    else:
        top_dirs = {p.name for p in repo_root.iterdir() if p.is_dir() and not p.name.startswith(".")}
        _line_re = re.compile(r":\d+(?:-\d+)?$")
        stale_claims = []
        for rel, n in sorted(notes.items()):
            try:
                text = (env.vault / rel).read_text(encoding="utf-8-sig")
            except OSError:
                continue
            spans = [s.strip("`") for s in INLINE_CODE_RE.findall(FENCE_RE.sub("", text))]
            seen_paths = set()
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
                seen_paths.add(token)
                if not (repo_root / token).exists():
                    loc = f"{rel}:{line}" if line else rel
                    stale_claims.append(f"{loc} → {token}(已不存在)")
        if stale_claims:
            warn_soft(stale_claims,
                      f"{len(stale_claims)} 個節點引用指向已不存在的 repo 路徑(架構圖指向死碼?):",
                      "碼被刪/改名?更新節點正文的路徑引用,或補對應節點")
        else:
            ok("無失效檔案認領 (節點引用的 repo 路徑都存在)")
    print()
```

> 註:`repo_root` 沿用 Check C 在同一 `run_doctor` 內設的區域變數(`scripts/lumos:519-522`),Check P 直接用,不重算。`re`/`FENCE_RE`/`INLINE_CODE_RE` 皆 module 級既有。

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "Check P"`
Expected: 7 行 `✓`(段標題、案例1報出、案例2不報、案例3不報、案例4 fenced 不報、rc0、無docs略過)。

- [ ] **Step 5: Run full suite + smoke on real vault**

Run: `python3 scripts/test_lumos.py`
Expected: `N passed, 0 failed`。

Run: `./scripts/lumos doctor 2>&1 | grep -A3 "\[P\]"`
Expected: 出現 `[P] 失效檔案認領 …` 段;本 repo 架構圖節點引用的路徑都存在 → 印 `✓ 無失效檔案認領`(若報出某些,逐一查證是真死指針還是抽取偽陽性);doctor 結尾仍 `✓ 架構圖健康 — 0 issues`(Check P 軟、不改 rc)。

- [ ] **Step 6: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): doctor Check P — 失效檔案認領(節點 inline-code 路徑指死碼軟提醒,段尾 ...→V→P)"
```

---

### Task 2: 知識同步(方法論 + skill doctor 表 + KG)

**Files:**
- Modify: `docs/methodology/架構圖即合約.md`(若有 doctor 巡檢/commit-time 段)
- Modify: `skills/lumos-project-notes/SKILL.md`(doctor 巡檢說明)
- Modify: `docs/lumos-toolchain-knowledge/Systems/lumos-cli-read.md`(summary 補 Check P)

**Interfaces:** 無(文件/架構圖同步)。

- [ ] **Step 1: skill doctor 巡檢說明補 Check P**

`grep -n "doctor" skills/lumos-project-notes/SKILL.md | head` 定位 doctor 巡檢描述(「健康巡檢」「orphans / 破連結 / verified_by 同步…」那段)。用 Edit 在該段的 check 列舉處補一句:
```
；Check P 失效檔案認領(節點正文 inline-code 路徑指向已不存在的 repo 檔 → 軟提醒「架構圖指向死碼」)
```

- [ ] **Step 2: 方法論補一句(有對應段才補)**

`grep -n "commit-time\|doctor\|巡檢\|腐爛\|死碼" docs/methodology/架構圖即合約.md | head`。
- 有「doctor 巡檢 / commit-time 強制」相關段 → Edit 補一句:`doctor 亦抓「架構圖正文指向已不存在檔路徑」的失效認領(Check P,軟提醒)`。
- 無對應段 → 跳過,commit message 註明「方法論無對應段,略」。

- [ ] **Step 3: KG Systems/lumos-cli-read summary 補 Check P**

doctor 屬讀/巡檢原語,記在 `Systems/lumos-cli-read`。**不可用 Write/Edit 改 frontmatter 純量/list**,但 summary block 屬 rich 內文、且本任務只加描述句 → 用 Edit 在該節點 summary 的 doctor 相關 KEY 行末或內文補:`Check P 失效檔案認領(inline-code 路徑指死碼)`。**不動 `created`/`updated`/`self_audit` 三欄**(保 L4 戳記)。改完 `./scripts/lumos lint lumos-cli-read` 須 0 問題。

- [ ] **Step 4: 驗證架構圖健康**

```bash
cd /Users/enzo/harness/lumos-toolchain
./scripts/lumos doctor 2>&1 | tail -2          # 0 issues
./scripts/lumos lint lumos-cli-read 2>&1 | tail -1  # 0 問題
```
Expected: doctor 0 issues、lint 0 問題。

- [ ] **Step 5: Commit**

```bash
git add docs/methodology/架構圖即合約.md skills/lumos-project-notes/SKILL.md docs/lumos-toolchain-knowledge/Systems/lumos-cli-read.md
git commit -m "docs(sync): Check P 失效檔案認領落地——skill doctor 表 + 方法論 + KG cli-read 註記"
```
(方法論若無對應段未改,該檔不納入 git add。)

---

## Self-Review

**Spec coverage**(對照 `docs/design/2026-06-30-doctor-stale-file-claim.md`):
- §範圍 repo_root 重用 Check C + None 跳過 → Task 1 Step 3(`if repo_root is None: ok(...)`)。✓
- §範圍 rule 1(剝 fenced + findall + strip 反引號)→ Step 3 `[s.strip("`") for s in INLINE_CODE_RE.findall(FENCE_RE.sub("", text))]`。✓
- rule 2(剝行號 `:\d+(?:-\d+)?$`、跳 `://`、含 `/`)→ Step 3 `_line_re` + `"://"` + `"/" in token`。✓
- rule 3(第一段 ∈ 非隱藏頂層目錄)→ `not p.name.startswith(".")` + `token.split("/")[0] not in top_dirs`。✓
- rule 4(存在檢查)→ `(repo_root / token).exists()`。✓ rule 5(去重)→ `seen_paths`。✓
- §輸出格式(有/無行號)→ `loc = f"{rel}:{line}" if line else rel`。✓
- §測試策略 7 案例 → `t_doctor_check_p`(案例 1-6;案例 7 rc 不變併入案例 1 的 rc 斷言)。✓
- §邊界(warn_soft 不改 rc、不碰其他 check)→ Global Constraints + Step 3 用 warn_soft。✓
- §知識同步 3 項 → Task 2。✓
- §誠實天花板 → 設計認知,不需 code。✓

**Placeholder scan:** 無 TBD;Step 3 完整 code、Step 1 完整測試;Task 2 Step 2 方法論「有則補/無則略+commit 註明」明確分支。✓

**Type consistency:** `repo_root`(Check C 區域變數)Task 1 重用;`_line_re`/`top_dirs`/`stale_claims`/`seen_paths` 在 Step 3 內定義即用;測試 helper `_mk_docs_vault` 在 Task 1 定義即用;輸出字串 `[P]`、`略過失效認領`、`scripts/ghost.py` 與測試斷言一致。✓
