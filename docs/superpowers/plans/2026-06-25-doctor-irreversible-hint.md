# Check H 漏標可逆性提醒 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** doctor 新增 Check H section——`--ci` 模式掃 git diff 裡碰 prod/外部 API/寄送/破壞性 DB 的 `+` 行,用 `warn_soft` 提示「這裡是不是漏標 `★IRREVERSIBLE★`?」,把「全靠人想到」改成「機器提醒人」。

**Architecture:** 純加法。`scripts/lumos` 加 1 個常數(`IRREVERSIBLE_HINT_PATTERNS`)+ 1 個 helper(`_scan_diff_for_irreversible_hints(cwd)`,放可逆性軸函數群、helper 內 lazy `import subprocess`)+ 1 個 Check H section(插在 `run_doctor` Check S 之後、僅 `ci=True` 執行)。不改任何既有 Check、不計 issues、不影響 rc。

**Tech Stack:** Python(`scripts/lumos` 單檔)、自訂測試 runner `scripts/test_lumos.py`(`t_` 前綴函式 + `check(name,cond,detail)`/`run(vault,*args)`/`mkvault()`,**非 pytest**;跑全部:`python3 scripts/test_lumos.py`)。測試需 git repo fixture(temp `git init` + vault 子目錄 + staged 文件)。

## Global Constraints

- **絕不 hard block**:Check H 只 `warn_soft`,**不計 issues、不影響 rc**(同 Check S/K)。
- **只在 `ci=True` 執行**:互動 `lumos doctor`(無 `--ci`)印「(僅 --ci 模式掃 diff;互動模式略過)」、不掃。
- **只掃 diff 的 `+` 行**:`git diff --staged` 優先,空則 fallback `git diff HEAD~1..HEAD`;非 git/無 diff/初始 commit 無 parent → 靜默回 `[]`(安全失敗)。
- **helper 內必須 `import subprocess`**(lazy import,module-level 無 subprocess,否則 NameError)。
- **cwd=`str(env.vault)` 即可**:git diff 無 pathspec 時範圍為全 repo,vault 子目錄不縮小範圍(spec r2-F1 辯方坐實)。
- **過濾**:跳過 `.md/.txt/.rst` 副檔名、測試檔(`test_`/`_test.`/`.spec.`/`/tests?/`)、純注解行(`# // -- /* *` 開頭);`hits[:8]` 截斷。
- **常數 + helper 放可逆性軸群**(`GUARD_REF_RE` @L995 之後、reversibility helper 群),不放 module 頂或 run_doctor 內(spec r2-F2 辯方坐實:前向引用在呼叫時解析,符合本檔慣例)。
- **不改**:Check R 邏輯、`warn()`、`run_doctor` 簽名、`extract_reversibility`/`_rollback_resolved`/`_guard_resolved`、gov_events(Check H **刻意不寫**——無具體 Systems nodes、empty-nodes 在 `cmd_gov` 零可見性增益)。

---

### Task 1: Check H 實作 + 測試(scripts/lumos + test_lumos.py)

**Files:**
- Modify: `scripts/lumos`(常數 + helper 接在 `reversibility_guard_ref` @L1005 後;Check H section 插在 Check S `print()` @L685 後、Check K 註解 @L687 前)
- Test: `scripts/test_lumos.py`(加 `_mk_git_vault` helper + `t_check_h_irreversible_hint`)

**Interfaces:**
- Consumes(既有,已坐實):`run_doctor(env, strict, color, suggest=False, ci=False)` @L357、`section(idx,title)` @L366、`warn_soft(lines,head,advice)` @L381、`ok(msg)`、`env.vault`、module-level `import re`(L29)、`Path`(L34)。
- Produces:`IRREVERSIBLE_HINT_PATTERNS`(list[re.Pattern])、`_scan_diff_for_irreversible_hints(cwd:str)→list[str]`、doctor 輸出多一段 `[H]`。

- [ ] **Step 1: 寫 git fixture helper + 失敗測試**

在 `scripts/test_lumos.py` 加模組級 helper(放在 `mkvault` 定義之後;`_` 前綴不被 runner 收集):

```python
def _mk_git_vault():
    """temp git repo + docs/kg vault(子目錄)+ 一個初始 commit。回 (root, vault)。"""
    import subprocess
    root = Path(tempfile.mkdtemp(prefix="gctl-h-"))
    for cmd in (["git", "init", "-q"], ["git", "config", "user.email", "t@t.t"],
                ["git", "config", "user.name", "t"]):
        subprocess.run(cmd, cwd=root, capture_output=True)
    vault = root / "docs" / "kg"
    (vault / "MOC").mkdir(parents=True)
    (vault / "MOC" / "i.md").write_text("---\ntype: moc\n---\n# i\n", encoding="utf-8")
    subprocess.run(["git", "add", "-A"], cwd=root, capture_output=True)
    subprocess.run(["git", "commit", "-qm", "init"], cwd=root, capture_output=True)
    return root, vault
```

加測試函式(覆蓋 spec 測試策略 7 條):

```python
def t_check_h_irreversible_hint():
    import subprocess
    HEAD = "疑似碰外部不可逆"  # warn_soft head 的特徵詞

    # 1. smoke:staged 含 prod requests.post → 提示
    root, vault = _mk_git_vault()
    (root / "charge.py").write_text('requests.post("https://prod.api.com/charge")\n', encoding="utf-8")
    subprocess.run(["git", "add", "charge.py"], cwd=root, capture_output=True)
    r = run(vault, "doctor", "--ci")
    check("Check H smoke: staged prod requests.post → 提示", HEAD in r.stdout, r.stdout)

    # 2. filter-test-file:test_ 檔含 sendmail → 不報
    root, vault = _mk_git_vault()
    (root / "test_email.py").write_text('sendmail("to@prod")\n', encoding="utf-8")
    subprocess.run(["git", "add", "test_email.py"], cwd=root, capture_output=True)
    r = run(vault, "doctor", "--ci")
    check("Check H filter test-file: test_ 檔不報", HEAD not in r.stdout, r.stdout)

    # 3. filter-comment:純注解行 → 不報
    root, vault = _mk_git_vault()
    (root / "x.py").write_text('# sendgrid.send(...)\n', encoding="utf-8")
    subprocess.run(["git", "add", "x.py"], cwd=root, capture_output=True)
    r = run(vault, "doctor", "--ci")
    check("Check H filter comment: 純注解不報", HEAD not in r.stdout, r.stdout)

    # 4. config-file:.yaml 含 prod.stripe → 報(SKIP_EXT 不排 .yaml)
    root, vault = _mk_git_vault()
    (root / "config.yaml").write_text('endpoint: https://prod.stripe.com\n', encoding="utf-8")
    subprocess.run(["git", "add", "config.yaml"], cwd=root, capture_output=True)
    r = run(vault, "doctor", "--ci")
    check("Check H config: .yaml prod → 報", HEAD in r.stdout, r.stdout)

    # 5. no-ci:--strict(無 --ci)→ 印互動略過語、不掃
    root, vault = _mk_git_vault()
    (root / "charge.py").write_text('requests.post("https://prod.api.com")\n', encoding="utf-8")
    subprocess.run(["git", "add", "charge.py"], cwd=root, capture_output=True)
    r = run(vault, "doctor", "--strict")
    check("Check H no-ci: 互動模式略過", "互動模式略過" in r.stdout, r.stdout)

    # 6. non-git:普通 vault(非 git repo)→ 靜默無疑似、不崩
    v = mkvault()
    r = run(v, "doctor", "--ci")
    check("Check H non-git: 不崩 + 無疑似", HEAD not in r.stdout, r.stdout)

    # 7. initial-commit:只有初始 commit、無新 staged → HEAD~1 rc≠0 → 無疑似
    root, vault = _mk_git_vault()
    r = run(vault, "doctor", "--ci")
    check("Check H initial-commit: 無 parent diff → 無疑似", HEAD not in r.stdout, r.stdout)
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `python3 scripts/test_lumos.py 2>&1 | grep -iE "Check H|✗|FAIL" | head`
Expected: 7 個 Check H case 失敗(section 還沒實作,stdout 無相關輸出)。

- [ ] **Step 3: 實作常數 + helper(可逆性軸群)**

在 `scripts/lumos` 的 `reversibility_guard_ref`(@L1003-1005)定義**之後**插入:

```python
IRREVERSIBLE_HINT_PATTERNS = [
    re.compile(r"\bprod[._\-/]|production\b", re.I),
    re.compile(r"smtplib|sendmail|send_mail\b|\.send_message\b", re.I),
    re.compile(r"requests\.post\b|httpx\.post\b", re.I),
    re.compile(r"boto3\.(client|resource)\s*\(", re.I),
    re.compile(r"\bstripe\.\b|\btwilio\.\b|\bsendgrid\.\b", re.I),
    re.compile(r"\bDROP\s+TABLE\b|\bDELETE\s+FROM\b", re.I),
    re.compile(r"external_api\b|ext_api\b", re.I),
]


def _scan_diff_for_irreversible_hints(cwd):
    """掃 git diff --staged(優先)或 HEAD~1..HEAD,回傳疑似不可逆 +行摘要列表。
    非 git repo 或無 diff → 回傳 []。跳過測試檔與純注解行。
    cwd=str(env.vault) 即可:git diff 無 pathspec 時範圍為全 repo,cwd 子目錄不縮小範圍。"""
    import subprocess  # lazy import,與 L339/L2298 等先例一致
    _SKIP_EXT = {".md", ".txt", ".rst"}
    _TEST_PAT = re.compile(r"(test_|_test\.|\.spec\.|/tests?/)", re.I)

    for cmd in (["git", "diff", "--staged"], ["git", "diff", "HEAD~1..HEAD"]):
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
        except FileNotFoundError:
            return []
        if r.returncode != 0 or not r.stdout.strip():
            continue
        diff_text = r.stdout
        break
    else:
        return []

    cur_file = ""
    hits = []
    for line in diff_text.splitlines():
        if line.startswith("+++ b/"):
            cur_file = line[6:]
        if line.startswith("+++") or line.startswith("---"):
            continue
        if not line.startswith("+"):
            continue
        ext = Path(cur_file).suffix if cur_file else ""
        if ext in _SKIP_EXT:
            continue
        if cur_file and _TEST_PAT.search(cur_file):
            continue
        code_line = line[1:].strip()
        if code_line.startswith(("#", "//", "--", "/*", "*")):
            continue
        for pat in IRREVERSIBLE_HINT_PATTERNS:
            if pat.search(code_line):
                hits.append(f"{Path(cur_file).name}: {code_line[:80]}")
                break
    return hits[:8]
```

- [ ] **Step 4: 實作 Check H section(run_doctor 內)**

在 `scripts/lumos` 的 `run_doctor`,Check S 尾 `print()`(@L685)之後、Check K 註解(@L687)之前插入:

```python
    # Check H: 漏標可逆性提醒(軟,不擋,不計 issues)——僅 --ci 掃 diff,提示疑似漏標 ★IRREVERSIBLE★
    section("H", "漏標可逆性提醒 (diff 碰 prod/外部 API/寄送 → 是否漏標 ★IRREVERSIBLE★?)")
    if not ci:
        print("  (僅 --ci 模式掃 diff;互動模式略過)")
    else:
        hint_hits = _scan_diff_for_irreversible_hints(str(env.vault))
        if not hint_hits:
            ok("diff 無疑似不可逆操作行(或無 staged/HEAD diff)")
        else:
            warn_soft(
                hint_hits,
                f"diff 發現 {len(hint_hits)} 行疑似碰外部不可逆操作:",
                "確認相關 Systems 節點已標 ★IRREVERSIBLE★ [rollback:decisions] 或 [guard:decisions];若確認可逆可忽略",
            )
    print()
```

- [ ] **Step 5: 跑測試確認通過 + 全回歸**

Run: `python3 scripts/test_lumos.py 2>&1 | tail -3`
Expected: 全綠(含 7 個 Check H case + 既有回歸)。若 case 5「互動模式略過」沒命中,確認 `doctor --strict` 走到 ci=False 分支;若 case 1 沒命中,確認 helper cwd 是 vault、git diff --staged 掃到 root 的 staged 檔。

- [ ] **Step 6: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(doctor): Check H — 掃 diff 提示漏標 ★IRREVERSIBLE★(軟,僅 --ci)

掃 git diff 碰 prod/外部 API/寄送/破壞性 DB 的 +行,warn_soft 提示可能漏標不可逆;
維持人手標、只加機器提醒(不把判可逆性自動化交 LLM)。與 Check R(標了要合規)互補。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: 知識同步(方法論 Check 體系 + skills + 速查)

**Files:**
- Modify: `docs/methodology/架構圖即合約.md`(Check 體系表 L126-128 加 Check H 行;Check T/R 詳解段補 Check H 互補句)
- Modify: `docs/methodology/架構圖即合約-對外論述.md`(可逆性白話段 L160 補「doctor 還會掃 diff 提醒漏標」)
- Modify: `skills/lumos-project-notes/SKILL.md`(doctor check 說明補 `[H]`)
- Modify: `scripts/templates/graph-discipline.md`(可逆性段補 Check H 提醒)

**吸取昨天教訓**:新 Check 要回填**所有列舉 Check 的地方**,別只補一段(check-r 漏 L282、辯方漏 3 處列舉表的覆轍)。

- [ ] **Step 1: 架構圖即合約.md Check 體系表加 Check H 行**

先定位:`grep -n "Check K ★COMBO★\|Check R 可逆性" docs/methodology/架構圖即合約.md`

在 Check R 那一行(`| Check R 可逆性...`)**之後**插入一行:

```markdown
| Check H 漏標可逆性提醒（2026-06-25，doctor `--ci`） | doctor `--ci` | 軟提醒（不擋） | 「diff 碰 prod/外部 API/寄送/破壞性 DB 卻可能沒標 ★IRREVERSIBLE★」——把漏標從「全靠人想到」變「機器提醒人」；與 Check R 互補（R 守「有標要合規」、H 提醒「沒標但可能需要」）。維持人手標、不把判可逆性自動化交 LLM |
```

- [ ] **Step 2: 架構圖即合約.md Check 詳解段補 Check H**

先定位:`grep -n "^### 合約即測試 / 獨立審計 / 可逆性\|^| Check R |" docs/methodology/架構圖即合約.md`

在該詳解表 `| Check R | ...` 行**之後**插入:

```markdown
| Check H（2026-06-25） | doctor `--ci` 掃 git diff 的 `+` 行（staged 優先、fallback `HEAD~1..HEAD`），碰 prod/外部 API/寄送/破壞性 DB pattern → `warn_soft` 提示「是否漏標 ★IRREVERSIBLE★」。純加法、不擋、不計 issues；pattern 是 syntactic（有 false positive，軟提示成本近零）。與 Check R 互補：R 守「標了要合規」、H 提醒「沒標但可能需要」 |
```

- [ ] **Step 3: 對外論述補白話**

先定位:`grep -n "先把「萬一錯了怎麼收回來」" docs/methodology/架構圖即合約-對外論述.md`

在該可逆性段落(L160 那段,結尾「本身就有價值。」)**之後**補一句(同段或新句):

```markdown
而且工具還會幫你「想到要標」:每次檢查時掃一遍這次的改動,只要碰到像「寄信、打正式環境、刪資料庫」這種收不回的操作,就軟提醒一句「這裡是不是該標成不可逆?」——把「漏標」從全靠人記得,變成機器幫你想。它只提醒、不替你決定（判一個動作到底可不可逆,還是人說了算）。
```

- [ ] **Step 4: project-notes SKILL + graph-discipline 補 Check H**

先定位:`grep -n "Check S\|Check K\|Check R\|doctor" skills/lumos-project-notes/SKILL.md scripts/templates/graph-discipline.md`

- `skills/lumos-project-notes/SKILL.md`:找 doctor 各 check 說明處(列了 Check R/S/K 的地方),補一條:
  ```markdown
  `[H]` 漏標可逆性提醒（`doctor --ci` 才跑）:掃 diff 碰 prod/外部 API/寄送 → 軟提醒「是否漏標 ★IRREVERSIBLE★」。只提醒、不擋。
  ```
- `scripts/templates/graph-discipline.md`:可逆性段(提 ★IRREVERSIBLE★/`[rollback:]`/`[guard:]` 的地方)補一行:
  ```markdown
  - `doctor --ci` 的 Check H 會掃 diff、碰 prod/外部 API/寄送時軟提醒「是否漏標 ★IRREVERSIBLE★」(只提醒、不擋)。
  ```

- [ ] **Step 5: 確認沒破測試 + Commit**

Run: `python3 scripts/test_lumos.py 2>&1 | tail -1`
Expected: 全綠(文件改不影響測試;但 `t_marker_doc_sync` 若涵蓋新內容須確認——它守的是 marker 字串非 Check 名,Check H 不涉新 marker,應不受影響)。

```bash
git add docs/methodology/架構圖即合約.md docs/methodology/架構圖即合約-對外論述.md skills/lumos-project-notes/SKILL.md scripts/templates/graph-discipline.md
git commit -m "docs(doctor): Check H 知識同步——方法論 Check 體系/詳解 + skills + 速查

回填所有列舉 Check 的地方(Check 體系表 + 詳解表 + project-notes + graph-discipline)+ 對外白話。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## 驗證(計畫完成後)

- **單元測試**:`python3 scripts/test_lumos.py` 全綠(7 個 Check H case + 回歸)。
- **手動煙霧**:在 repo `git add` 一個含 `requests.post("https://prod...")` 的 .py,跑 `lumos doctor --ci`,Check H 應軟提醒;`git reset` 後重跑應無。
- **誠實天花板**(向人提醒):Check H 是 syntactic pattern、有 false positive;只提醒不擋、不解析對應哪個 Systems 節點;多 commit PR 只看最後一個 commit。

## Spec 覆蓋自檢

- 組件 1(IRREVERSIBLE_HINT_PATTERNS)→ T1 Step 3;2(_scan_diff_for_irreversible_hints)→ T1 Step 3;3(Check H section)→ T1 Step 4。
- 測試策略 1-7 → T1 Step 1(smoke/filter-test/filter-comment/config/no-ci/non-git/initial-commit 各一 case)。
- 知識同步影響(方法論/對外論述/project-notes/graph-discipline)→ T2 Step 1-4;**額外回填** Check 體系表 + 詳解表(spec 只說「補句」,吸取昨天教訓擴到所有列舉處)。
- 不改清單(Check R/warn/簽名/gov_events)→ Global Constraints 約束。
