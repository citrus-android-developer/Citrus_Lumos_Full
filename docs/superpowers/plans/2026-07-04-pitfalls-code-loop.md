# pitfalls-code-loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 實務隱患意識 + 代碼審計對齊——`lumos pitfalls` 三模式(spec 提問 / --check 缺節擋 / --diff 代碼風險 manifest+tier)、gate `--spec` 改可選(讓 code-loop 吃 G2 枯竭錨)、新 `lumos-code-loop` skill(bug canary+三道防污染+辯方+證據閘)、四處接線。

**Architecture:** ① `scripts/lumos` 內新增 `cmd_pitfalls`(自帶 PITFALL_CLASSES 詞表+代碼 pattern 表,spec 模式剝除對齊 difficulty.assess_spec 但獨立實作,vault-free pre-Env 分流);② `cmd_loop_status` 的 `--spec` 由必填改可選(G1 skip);③ 新 user-scope skill `lumos-code-loop`(散文);④ 接線 orchestrator-prompt / graph-discipline 模板 / design-loop skill / project-notes。漂移守衛落 `test_autonomous_loop.py`(toolchain-only)。

**Tech Stack:** Python 3 stdlib(re/subprocess lazy import);`scripts/test_lumos.py`(CLI harness)+ `scripts/test_autonomous_loop.py`(unittest,已 import difficulty)。

**Branch:** `feat/pitfalls-code-loop`。

## Global Constraints

- stdlib only;pitfalls 詞表/pattern 表**自帶於 scripts/lumos**(difficulty.py 不 vendored,他專案拿不到)。
- **PITFALL_CLASSES 四類名 ≡ difficulty.RISK_CLASSES**(payment/external-send/prod-irreversible/self-governance);**剝除黑名單 ≡ difficulty._BLACKLIST**(方案評比/canary 相容性/誠實天花板/審計修正紀錄)——兩者由漂移守衛測試釘(Task 1),測試落 `test_autonomous_loop.py`(toolchain-only、不隨 vendor)。
- **spec 模式剝除對齊 assess_spec**:`##` 切分 → 黑名單剝除(前提節保留)→ **防呆回退(節數<2 或字元<200 → 回退全文,偏嚴+印告警)** → 剝 inline-code/檔名 → 掃描。獨立實作(同 refcheck 對 Check P 「同款不共用」先例)。
- **通用 3 問恆印**(併發/效能/資源)+ 命中類專屬追問。
- **--check**:命中任一類 且 全文無 `## 實務隱患` 標題 → rc 1;有節或零命中 → rc 0。只驗節存在、不驗內容。
- **--diff**:掃新增行(`+` 開頭、排除 `+++`);**過濾繼承 Check H 全套**(skip `.md/.txt/.rst`、測試檔 `_TEST_PAT`、純註解行);manifest `{file,line,class,pattern,question}` + 尾行 `tier: high|standard`;`class` 用**代碼形態類軸(併發/效能/資源)**、非四業務類;`line` 由 `@@` 標頭+hunk 內行計數推導;**rc 恆 0**(提示器非閘)。
- **vault-free**:pitfalls CLI 不吃 `--vault`,pre-Env 分流(同 refcheck/anchor);repo 解析 `_anchor_repo_root` 慣例。
- **gate --spec 改可選**:缺 `--spec` → G1 印 `skipped(無 spec 對象)` 不計 fail;**有 --spec 行為分毫不變**(回歸釘);既有 `t_loop_gate` 案 14「缺 --spec → rc 2」斷言隨改為新契約。
- 不動 canary/judge/辯方機制、不動 difficulty.py/Check H/refcheck 既有代碼、不改 task review 逐任務流程。
- **錨點注意**:`test_lumos.py`/`test_autonomous_loop.py` 皆 anchor——merge 後 push 前 `lumos anchor approve --note` 同批 commit(Task 6)。

---

### Task 1: `cmd_pitfalls` spec 模式 + CLI 三模式 argparse + --check + 漂移守衛

**Files:**
- Modify: `scripts/lumos`(`cmd_refcheck` 上方加 `cmd_pitfalls` + 詞表/pattern 常數;refcheck subparser 後加 pitfalls subparser;refcheck dispatch 後加 pitfalls 分支)
- Test: `scripts/test_lumos.py`(新增 `t_pitfalls_spec`)、`scripts/test_autonomous_loop.py`(新增 `TestPitfallsDrift`)

**Interfaces:**
- Consumes(既有):`FENCE_RE`/`INLINE_CODE_RE`(`scripts/lumos:39-40`)、`_anchor_repo_root`、`re`、`sys`、`Path`。
- Produces:`PITFALL_CLASSES`(dict)、`_PITFALL_QUESTIONS`(dict)、`_PITFALL_GENERAL`(list)、`_PITFALL_BLACKLIST`(tuple)、`cmd_pitfalls(md=None, diff=None, repo=None, check=False, as_json=False, section_title="實務隱患") -> int`;CLI `lumos pitfalls <md> [--repo] [--check] [--json]` / `lumos pitfalls --diff <range> [--repo] [--json]`。Task 2 加 diff 分支、Task 5/接線引用此 CLI。

- [ ] **Step 1: Write the failing tests**

`scripts/test_lumos.py` 加(模組層):

```python
def t_pitfalls_spec():
    root = Path(tempfile.mkdtemp(prefix="gctl-pf-"))
    (root / ".git").mkdir()
    # 命中 payment + external-send
    md_hit = root / "hit.md"
    md_hit.write_text("# s\n## 目標\n接 stripe 收款後寄送通知。\n## 組件\n扣款流程。\n", encoding="utf-8")
    r = run_bare("pitfalls", str(md_hit), "--repo", str(root))
    check("pitfalls spec: 印通用 3 問", "併發" in r.stdout and "效能" in r.stdout and "資源" in r.stdout, r.stdout)
    check("pitfalls spec: 命中 payment 追問", "冪等" in r.stdout, r.stdout)
    check("pitfalls spec: 命中 external-send 追問", "去重" in r.stdout or "重試" in r.stdout, r.stdout)
    # --check 命中且無節 → rc 1
    r = run_bare("pitfalls", str(md_hit), "--repo", str(root), "--check")
    check("pitfalls --check: 命中無節 rc 1", r.returncode == 1, f"rc={r.returncode}\n{r.stdout}")
    # 補節 → rc 0
    md_ok = root / "ok.md"
    md_ok.write_text("# s\n## 目標\n接 stripe 收款。\n## 實務隱患\n冪等鍵用訂單號。\n", encoding="utf-8")
    r = run_bare("pitfalls", str(md_ok), "--repo", str(root), "--check")
    check("pitfalls --check: 有節 rc 0", r.returncode == 0, f"rc={r.returncode}\n{r.stdout}")
    # 零命中 → rc 0(無節也不擋)
    md_clean = root / "clean.md"
    md_clean.write_text("# s\n## 目標\n重構內部排序,無外部行為。\n## 組件\n拆函數。\n", encoding="utf-8")
    r = run_bare("pitfalls", str(md_clean), "--repo", str(root), "--check")
    check("pitfalls --check: 零命中無節 rc 0", r.returncode == 0, f"rc={r.returncode}\n{r.stdout}")
    check("pitfalls spec: 零命中只印通用問", "冪等" not in r.stdout, r.stdout)
    # 剝除:風險詞只在黑名單樣板節 → 不觸發
    md_tmpl = root / "tmpl.md"
    md_tmpl.write_text("# s\n## 目標\n" + "純內部整理。" * 20 +
                       "\n## 組件\n" + "改函數命名。" * 20 +
                       "\n## 審計修正紀錄\nr1 canary 抓到金流 stripe 扣款壞 ref。\n", encoding="utf-8")
    r = run_bare("pitfalls", str(md_tmpl), "--repo", str(root), "--check")
    check("pitfalls 剝除: 風險詞只在審計紀錄節 → --check rc 0", r.returncode == 0, f"rc={r.returncode}\n{r.stdout}")
    # md 不存在 → rc 2
    r = run_bare("pitfalls", str(root / "ghost.md"), "--repo", str(root))
    check("pitfalls: md 不存在 rc 2", r.returncode == 2, f"rc={r.returncode}")
```

> `run_bare` 是既有 helper 嗎?——若無,用既有 `run(vault, ...)` 會強制帶 `--vault`;pitfalls vault-free,`--vault` 被 pre-Env 分流忽略無妨,故**直接用既有 `run(root, "pitfalls", ...)`**(root 當 vault 位置傳入、實際被忽略)。將測試中 `run_bare(...)` 全部改為 `run(root, ...)`。

`scripts/test_autonomous_loop.py` 加(檔尾 `unittest.main()` 前):

```python
class TestPitfallsDrift(unittest.TestCase):
    def test_pitfall_classes_match_risk_classes(self):
        import subprocess, json as _json
        from autonomous_loop import difficulty
        lumos = str(Path(__file__).resolve().parent / "lumos")
        # 從 lumos 匯出 PITFALL_CLASSES 類名集合(exec 載入模組層常數)
        src = Path(lumos).read_text(encoding="utf-8")
        ns = {}
        import re as _re
        m = _re.search(r"^PITFALL_CLASSES = \{.*?^\}", src, _re.S | _re.M)
        self.assertIsNotNone(m, "PITFALL_CLASSES 未找到")
        exec("import re\n" + m.group(0), ns)
        self.assertEqual(set(ns["PITFALL_CLASSES"].keys()), set(difficulty.RISK_CLASSES.keys()),
                         "pitfalls 類名集合 != difficulty.RISK_CLASSES(漂移)")

    def test_pitfall_blacklist_match(self):
        from autonomous_loop import difficulty
        lumos = str(Path(__file__).resolve().parent / "lumos")
        src = Path(lumos).read_text(encoding="utf-8")
        import re as _re
        m = _re.search(r"^_PITFALL_BLACKLIST = \((.*?)\)", src, _re.S | _re.M)
        self.assertIsNotNone(m)
        ns = {}
        exec("_PITFALL_BLACKLIST = (" + m.group(1) + ")", ns)
        self.assertEqual(set(ns["_PITFALL_BLACKLIST"]), set(difficulty._BLACKLIST),
                         "pitfalls 黑名單 != difficulty._BLACKLIST(漂移)")
```

- [ ] **Step 2: Run tests to verify fail**

Run: `python3 scripts/test_lumos.py 2>&1 | grep pitfalls` → FAIL(argparse invalid choice)。
Run: `python3 scripts/test_autonomous_loop.py 2>&1 | grep -i drift` → FAIL(常數未定義)。

- [ ] **Step 3: 實作 `cmd_pitfalls` spec 模式 + 常數**

Edit `scripts/lumos`,在 `def cmd_refcheck(` **正上方**插入:

```python
PITFALL_CLASSES = {
    "payment": [r"金流", r"payment", r"stripe", r"billing", r"退款", r"refund", r"扣款"],
    "external-send": [r"寄送", r"送出", r"\bsend\b", r"webhook", r"notify", r"LINE 推送", r"\bmail\b", r"簡訊", r"對外"],
    "prod-irreversible": [r"\bprod\b", r"production", r"遷移", r"migration", r"不可逆", r"DROP TABLE", r"DELETE FROM", r"上架"],
    "self-governance": [r"錨點", r"anchor verify", r"收斂判準", r"canary", r"審計閘", r"pre-push hook"],
}
_PITFALL_COMPILED = {c: [re.compile(p, re.I) for p in pats] for c, pats in PITFALL_CLASSES.items()}
_PITFALL_GENERAL = [
    "併發——同資源兩請求同時進來會怎樣?",
    "效能——這段會進熱路徑/大資料量嗎?",
    "資源——連線/檔案/鎖有沒有確定釋放?",
]
_PITFALL_QUESTIONS = {
    "payment": "冪等鍵怎麼設計?重複扣款如何防?部分失敗怎麼補償/對帳?",
    "external-send": "重試會不會風暴?收端如何去重?超時與速率上限?",
    "prod-irreversible": "回滾路徑?遷移順序與鎖表窗口?",
    "self-governance": "誤擋的逃生口?繞過有沒有留痕?",
}
_PITFALL_BLACKLIST = ("方案評比", "canary 相容性", "誠實天花板", "審計修正紀錄")
# diff 模式:代碼形態 pattern → 形態類軸(併發/效能/資源);Task 2 填 _PITFALL_DIFF_PATTERNS


def _pitfall_strip_spec(md_text):
    """spec 模式剝除:## 切分→黑名單剝樣板節(前提節保留)→防呆回退→剝 inline-code/檔名。
    對齊 difficulty.assess_spec 慣例、獨立實作(同 refcheck 對 Check P 不共用)。"""
    parts = re.split(r"(?m)^(## .*)$", md_text)
    kept = [parts[0]] if parts and parts[0].strip() else []
    n_sections = 0
    i = 1
    while i + 1 <= len(parts):
        title, body = parts[i], parts[i + 1]
        if not any(b in title for b in _PITFALL_BLACKLIST):
            kept.append(title + body)
            n_sections += 1
        i += 2
    corpus = "\n".join(kept)
    if n_sections < 2 or len(corpus) < 200:
        print("⚠ pitfalls: 剝除後餘文近空(節數<2 或字元<200),回退全文掃描(偏嚴)")
        corpus = md_text
    corpus = INLINE_CODE_RE.sub(" ", corpus)
    corpus = re.sub(r"[\w\-./]+\.(?:md|py|sh|json|yml|yaml|txt)\b", " ", corpus)
    return corpus


def _pitfall_scan_classes(text):
    """回命中類名 list(每類記首個命中即可)。"""
    hits = []
    for cls, pats in _PITFALL_COMPILED.items():
        if any(p.search(text) for p in pats):
            hits.append(cls)
    return hits


def cmd_pitfalls(md=None, diff=None, repo=None, check=False, as_json=False, section_title="實務隱患"):
    """實務隱患提問(vault-free):spec 模式逼答設計決策級隱患;--diff 模式攤代碼級風險位置(Task 2)。
    spec 模式印通用 3 問 + 命中類追問;--check:命中類且無「## <section_title>」節 → rc 1(只驗節存在)。"""
    import json
    repo_root = _anchor_repo_root(repo)
    if repo_root is None:
        return 2
    if diff is not None:
        return _pitfall_diff_mode(diff, repo_root, as_json)   # Task 2
    if md is None:
        print("ERROR: pitfalls 需 <md檔> 或 --diff <range>", file=sys.stderr)
        return 2
    mp = Path(md)
    if not mp.is_file():
        print(f"ERROR: 找不到檔案: {md}", file=sys.stderr)
        return 2
    text = mp.read_text(encoding="utf-8-sig")
    corpus = _pitfall_strip_spec(text)
    hits = _pitfall_scan_classes(corpus)
    if check:
        has_section = re.search(r"(?m)^##\s+.*" + re.escape(section_title), text) is not None
        if hits and not has_section:
            print(f"✗ pitfalls --check: 命中風險類 {hits} 但無「## {section_title}」節 → 補節(寫『無』也要寫+為什麼無)")
            return 1
        print(f"✓ pitfalls --check: {'有節' if has_section else '零命中'}(命中類={hits})")
        return 0
    if as_json:
        print(json.dumps({"hits": hits, "general": _PITFALL_GENERAL,
                          "class_questions": {c: _PITFALL_QUESTIONS[c] for c in hits}}, ensure_ascii=False))
        return 0
    print("實務隱患提問(通用,恆答):")
    for q in _PITFALL_GENERAL:
        print(f"  - {q}")
    if hits:
        print(f"命中風險類追問({', '.join(hits)}):")
        for c in hits:
            print(f"  - [{c}] {_PITFALL_QUESTIONS[c]}")
    return 0
```

- [ ] **Step 4: CLI argparse + pre-Env dispatch**

(4a) subparser——refcheck subparser 塊之後、anchor subparser 之前(或任一相鄰處)。Edit `scripts/lumos`:

```python
    p = sub.add_parser("pitfalls", help="實務隱患提問(vault-free):spec 逼答隱患 / --diff 攤代碼風險位置")
    p.add_argument("md", nargs="?", help="spec md 檔(spec 模式)")
    p.add_argument("--diff", dest="pf_diff", help="diff range(如 main..HEAD;diff 模式)")
    p.add_argument("--repo", dest="pf_repo", help="repo root(預設 cwd 向上找 .git)")
    p.add_argument("--check", action="store_true", help="命中風險類且無「## 實務隱患」節 → rc 1")
    p.add_argument("--json", dest="pf_json", action="store_true", help="JSON 輸出")
```

(4b) dispatch——refcheck 分支之後、`vault = args.vault or find_vault(...)` 之前:

```python
    if args.cmd == "pitfalls":
        return cmd_pitfalls(md=args.md, diff=args.pf_diff, repo=args.pf_repo,
                            check=args.check, as_json=args.pf_json)
```

> Task 1 先不實作 `_pitfall_diff_mode`——若 `--diff` 傳入會 NameError。**Task 1 的 cmd_pitfalls 暫時把 diff 分支改為**:`if diff is not None: print("diff 模式見 Task 2"); return 0`(佔位,Task 2 換掉)。測試不覆蓋 diff 模式,不受影響。

- [ ] **Step 5: Run tests to verify pass + 回歸**

Run: `python3 scripts/test_lumos.py 2>&1 | grep pitfalls` → `t_pitfalls_spec` 全 ✓。
Run: `python3 scripts/test_autonomous_loop.py 2>&1 | tail -3` → TestPitfallsDrift 2 tests 過 + 既有全綠。
Run: `python3 scripts/test_lumos.py 2>&1 | tail -1` → `354 passed`(353 + 1 新 t_)。

- [ ] **Step 6: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py scripts/test_autonomous_loop.py
git commit -m "feat(lumos): pitfalls spec 模式 + CLI 三模式 argparse + --check + 漂移守衛(類名/黑名單 ≡ difficulty)"
```

---

### Task 2: `cmd_pitfalls` --diff 模式(Check H 骨架 + pattern 表 + line 推導 + 過濾繼承)

**Files:**
- Modify: `scripts/lumos`(加 `_PITFALL_DIFF_PATTERNS` 常數 + `_pitfall_diff_mode` 函數;cmd_pitfalls 的 diff 佔位換成真呼叫)
- Test: `scripts/test_lumos.py`(新增 `t_pitfalls_diff`)

**Interfaces:**
- Consumes:Task 1 的 `cmd_pitfalls` diff 分支呼叫點、`re`/`subprocess`。
- Produces:`_pitfall_diff_mode(diff_range, repo_root, as_json) -> int`(rc 恆 0);manifest schema `{file,line,class,pattern,question}` + 尾行 `tier:`。

- [ ] **Step 1: Write the failing test**

`scripts/test_lumos.py` 加:

```python
def t_pitfalls_diff():
    import json as _json, subprocess as sp
    root = Path(tempfile.mkdtemp(prefix="gctl-pfd-"))
    def git(*a): sp.run(["git", *a], cwd=root, capture_output=True)
    git("init"); git("config", "user.email", "t@t"); git("config", "user.name", "t")
    (root / "app.py").write_text("x = 1\n", encoding="utf-8")
    git("add", "-A"); git("-c", "user.email=t@t", "-c", "user.name=t", "commit", "-m", "init")
    # 新增:無 timeout 的 requests.post(資源類)+ 迴圈內 query(效能類)
    (root / "app.py").write_text(
        "import requests\n"
        "def f(ids):\n"
        "    requests.post('http://x')\n"
        "    for i in ids:\n"
        "        db.execute('SELECT 1')\n", encoding="utf-8")
    git("add", "-A"); git("-c", "user.email=t@t", "-c", "user.name=t", "commit", "-m", "c2")
    r = run(root, "pitfalls", "--diff", "HEAD~1..HEAD", "--repo", str(root), "--json")
    check("pitfalls --diff: rc 0(提示器)", r.returncode == 0, f"rc={r.returncode}\n{r.stderr}")
    data = _json.loads([l for l in r.stdout.splitlines() if l.strip().startswith("{")][0])
    tokens = " ".join(f"{c['pattern']}|{c['class']}" for c in data["claims"])
    check("pitfalls --diff: 命中無 timeout requests(資源)", "資源" in tokens, r.stdout)
    check("pitfalls --diff: 命中迴圈內 query(效能)", "效能" in tokens, r.stdout)
    check("pitfalls --diff: tier high", data["tier"] == "high", r.stdout)
    check("pitfalls --diff: class 用形態軸非四業務類",
          all(c["class"] in ("併發", "效能", "資源") for c in data["claims"]), r.stdout)
    check("pitfalls --diff: 每條有 line", all(isinstance(c["line"], int) for c in data["claims"]), r.stdout)
    # 純文檔 diff → tier standard
    (root / "readme.md").write_text("hello\n", encoding="utf-8")
    git("add", "-A"); git("-c", "user.email=t@t", "-c", "user.name=t", "commit", "-m", "doc")
    r = run(root, "pitfalls", "--diff", "HEAD~1..HEAD", "--repo", str(root), "--json")
    data = _json.loads([l for l in r.stdout.splitlines() if l.strip().startswith("{")][0])
    check("pitfalls --diff: .md skip → tier standard", data["tier"] == "standard", r.stdout)
    # 測試檔內的 requests.post 不觸發(過濾繼承 _TEST_PAT)
    (root / "test_app.py").write_text("import requests\nrequests.post('http://y')\n", encoding="utf-8")
    git("add", "-A"); git("-c", "user.email=t@t", "-c", "user.name=t", "commit", "-m", "t")
    r = run(root, "pitfalls", "--diff", "HEAD~1..HEAD", "--repo", str(root), "--json")
    data = _json.loads([l for l in r.stdout.splitlines() if l.strip().startswith("{")][0])
    check("pitfalls --diff: 測試檔 skip → tier standard", data["tier"] == "standard", r.stdout)
```

- [ ] **Step 2: Run test to verify fail** — `grep "pitfalls --diff"` → FAIL(佔位回 diff 模式見 Task 2)。

- [ ] **Step 3: 實作 `_PITFALL_DIFF_PATTERNS` + `_pitfall_diff_mode`**

Edit `scripts/lumos`,`_PITFALL_BLACKLIST` 之後加常數:

```python
# diff 模式代碼形態 pattern:(regex, 形態類軸, 提問)——類軸限 併發/效能/資源(非四業務類)
_PITFALL_DIFF_PATTERNS = [
    (re.compile(r"requests\.\w+\(|httpx\.\w+\(", re.I), "資源", "HTTP 呼叫有沒有 timeout?"),
    (re.compile(r"\bopen\s*\(", re.I), "資源", "檔案 handle 有沒有 with/確定 close?"),
    (re.compile(r"\b(SELECT|INSERT|UPDATE|DELETE)\b", re.I), "效能", "是否在迴圈內、造成 N+1?"),
    (re.compile(r"\btime\.sleep\s*\(", re.I), "效能", "sleep 在迴圈裡會不會累積延遲?"),
    (re.compile(r"\bthreading\.|\bLock\s*\(|global\s+\w+", re.I), "併發", "共享狀態有沒有鎖保護?"),
    (re.compile(r"\bINSERT\b|\bUPDATE\b|\bDELETE\b", re.I), "併發", "寫入有沒有交易包裹?"),
]
_PITFALL_DIFF_SKIP_EXT = {".md", ".txt", ".rst"}
_PITFALL_DIFF_TEST_PAT = re.compile(r"(test_|_test\.|\.spec\.|/tests?/)", re.I)


def _pitfall_diff_mode(diff_range, repo_root, as_json):
    """掃 git diff <range> 新增行找代碼形態風險位置。過濾繼承 Check H 全套;line 由 @@ 標頭推導。
    rc 恆 0(提示器非閘)。class 用形態類軸(併發/效能/資源)。"""
    import json
    import subprocess
    try:
        r = subprocess.run(["git", "diff", "-U3", diff_range],
                           capture_output=True, text=True, cwd=str(repo_root))
    except FileNotFoundError:
        print("ERROR: 無 git", file=sys.stderr)
        return 2
    if r.returncode != 0:
        print(f"ERROR: git diff {diff_range} 失敗: {r.stderr.strip()}", file=sys.stderr)
        return 2
    claims = []
    cur_file, new_ln = "", 0
    for line in r.stdout.splitlines():
        if line.startswith("+++ b/"):
            cur_file = line[6:]
            continue
        m = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)", line)
        if m:
            new_ln = int(m.group(1))
            continue
        if line.startswith("+++") or line.startswith("---"):
            continue
        if line.startswith("-"):
            continue                          # 刪除行不推進新檔行號
        if not line.startswith("+"):
            new_ln += 1                       # context 行推進
            continue
        # 這是新增行(+ 開頭)
        ext = Path(cur_file).suffix if cur_file else ""
        code = line[1:]
        if (ext not in _PITFALL_DIFF_SKIP_EXT and cur_file
                and not _PITFALL_DIFF_TEST_PAT.search(cur_file)
                and not code.strip().startswith(("#", "//", "--", "/*", "*"))):
            for pat, axis, q in _PITFALL_DIFF_PATTERNS:
                if pat.search(code):
                    claims.append({"file": cur_file, "line": new_ln, "class": axis,
                                   "pattern": pat.pattern, "question": q})
                    break
        new_ln += 1                           # 新增行推進新檔行號
    tier = "high" if claims else "standard"
    if as_json:
        print(json.dumps({"claims": claims, "tier": tier}, ensure_ascii=False))
    else:
        for c in claims:
            print(f"  {c['file']}:{c['line']} [{c['class']}] {c['question']}")
        print(f"tier: {tier}")
    return 0
```

並把 Task 1 的 cmd_pitfalls 佔位行 `if diff is not None: print("diff 模式見 Task 2"); return 0` 換回 `if diff is not None: return _pitfall_diff_mode(diff, repo_root, as_json)`(Task 1 Step 3 原代碼已是此形，若 Step 4 註記改過則改回)。

- [ ] **Step 4: Run test + 回歸**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "pitfalls --diff"` → 8 checks 全 ✓。
Run: `python3 scripts/test_lumos.py 2>&1 | tail -1` → `355 passed`。

- [ ] **Step 5: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): pitfalls --diff 模式(Check H 骨架+代碼形態 pattern+@@ 行號推導+形態類軸+過濾繼承)"
```

---

### Task 3: gate `--spec` 改可選(cmd_loop_status G1 skip)

**Files:**
- Modify: `scripts/lumos`(`cmd_loop_status` 的 `if spec is None: return 2` 段)
- Test: `scripts/test_lumos.py`(改 `t_loop_gate` 案 14 + 新增 `t_loop_gate_no_spec`)

**Interfaces:**
- Consumes:既有 `cmd_loop_status` gate 段、`_refcheck_scan`。
- Produces:`--gate` 無 `--spec` 時 G1 印 `skipped`、不計 fail;K-streak∧G2 決定 rc。

- [ ] **Step 1: 改測試(案 14 翻契約 + 新增 no-spec 案)**

`scripts/test_lumos.py` 的 `t_loop_gate` 內,把案 14 原斷言：
```python
    r = run(vault, "loop", "status", "g3", "--gate", "--repo", str(repo))
    check("gate 案14: --gate 缺 --spec rc=2", r.returncode == 2, f"rc={r.returncode}")
```
改為(新契約:缺 --spec → G1 skip,rc 由 K-streak∧G2 決定;g3 已 findings [2,0] 枯竭+2 caught)：
```python
    r = run(vault, "loop", "status", "g3", "--need", "2", "--gate", "--repo", str(repo))
    check("gate 案14(新契約): 缺 --spec → G1 skip,g3 收斂 rc 0",
          r.returncode == 0 and "skipped" in r.stdout, f"rc={r.returncode}\n{r.stdout}")
```

新增 `t_loop_gate_no_spec`(獨立驗 G1 skip 不影響 G2 擋)：
```python
def t_loop_gate_no_spec():
    vault, repo, _spec_ok, _spec_bad = _mk_gate_fixture()
    def rec(loop, sev, f):
        run(vault, "canary", "record", "caught", "--loop", loop, "--severity", sev,
            "--findings", str(f), expect_rc=0)
    # 未枯竭 [2,3]:即使 G1 skip,G2 仍擋
    rec("ns1", "minor", 2); rec("ns1", "minor", 3)
    r = run(vault, "loop", "status", "ns1", "--need", "2", "--gate", "--repo", str(repo))
    check("gate no-spec: G1 skip 但 G2 未枯竭 → rc 1",
          r.returncode == 1 and "skipped" in r.stdout and "G2" in r.stdout, r.stdout)
```

- [ ] **Step 2: Run to verify fail** — 案 14 新斷言 fail(現碼 `spec is None → rc 2`)。

- [ ] **Step 3: 實作 G1 skip**

Edit `scripts/lumos` `cmd_loop_status` gate 段。old:
```python
    # ── 證據閘(--gate):K-streak(必要)∧ G1 refcheck ∧ G2 發現枯竭 ──
    if spec is None:
        print("ERROR: --gate 需同時給 --spec <md檔>", file=sys.stderr)
        return 2
    repo_root = _anchor_repo_root(repo)
    if repo_root is None:
        return 2
    try:
        text = Path(spec).read_text(encoding="utf-8-sig")
    except OSError as e:
        print(f"ERROR: 讀不到 --spec {spec}: {e}", file=sys.stderr)
        return 2
    fails = []
    if converged:
        print(f"[gate] K-streak(--need {need}): ✓")
    else:
        print(f"[gate] K-streak(--need {need}): ✗ — 還需 {need - streak} 輪 caught+乾淨(已 {len(rounds)} 輪)")
        fails.append("K-streak")
    claims, n_missing, n_oor, _n_ok = _refcheck_scan(text, repo_root)
    bad = [c for c in claims if c["status"] in ("missing", "line_out_of_range")]
    if bad:
        print(f"[gate] G1 refcheck(引用座標): ✗ — {len(bad)} 條壞宣稱")
        for c in bad:
            loc = f"{c['token']}:{c['line']}" if c["line"] else c["token"]
            print(f"    {loc}({c['status']})")
        fails.append("G1")
    else:
        print(f"[gate] G1 refcheck(引用座標): ✓ — {len(claims)} 條宣稱全 ok")
```
new:
```python
    # ── 證據閘(--gate):K-streak(必要)∧ G1 refcheck(--spec 可選)∧ G2 發現枯竭 ──
    repo_root = _anchor_repo_root(repo)
    if repo_root is None:
        return 2
    fails = []
    if converged:
        print(f"[gate] K-streak(--need {need}): ✓")
    else:
        print(f"[gate] K-streak(--need {need}): ✗ — 還需 {need - streak} 輪 caught+乾淨(已 {len(rounds)} 輪)")
        fails.append("K-streak")
    if spec is None:
        print("[gate] G1 refcheck(引用座標): skipped(無 spec 對象,code-loop 情境)")
    else:
        try:
            text = Path(spec).read_text(encoding="utf-8-sig")
        except OSError as e:
            print(f"ERROR: 讀不到 --spec {spec}: {e}", file=sys.stderr)
            return 2
        claims, n_missing, n_oor, _n_ok = _refcheck_scan(text, repo_root)
        bad = [c for c in claims if c["status"] in ("missing", "line_out_of_range")]
        if bad:
            print(f"[gate] G1 refcheck(引用座標): ✗ — {len(bad)} 條壞宣稱")
            for c in bad:
                loc = f"{c['token']}:{c['line']}" if c["line"] else c["token"]
                print(f"    {loc}({c['status']})")
            fails.append("G1")
        else:
            print(f"[gate] G1 refcheck(引用座標): ✓ — {len(claims)} 條宣稱全 ok")
```

> G2 段(`tail = rounds[-need:]` 起)與收尾不動。

- [ ] **Step 4: Run tests + 回歸**

Run: `python3 scripts/test_lumos.py 2>&1 | grep -E "gate 案14|no-spec|gate K=3"` → 全 ✓(案 14 新契約、no-spec、既有 K=3 皆過)。
Run: `python3 scripts/test_lumos.py 2>&1 | tail -1` → `356 passed`。

- [ ] **Step 5: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): loop status --gate 的 --spec 改可選(缺則 G1 skip,供 code-loop 吃 G2 枯竭錨)"
```

---

### Task 4: `lumos-code-loop` skill(新 user-scope skill)

**Files:**
- Create: `skills/lumos-code-loop/SKILL.md`

**Interfaces:**
- Consumes:Task 1/2 的 `pitfalls --diff`、既有 `canary record`/`loop status --gate --repo`(無 --spec)、review-package 或 `git diff -U10`。
- Produces:skill 散文(無機械測試,靠接線與知識同步守)。

- [ ] **Step 1: 寫 SKILL.md**(對抗紀律 1:1 對映 design-loop,含 frontmatter + 三道防污染 + mutation 冒煙)

frontmatter(對齊既有 lumos-* skill 格式):`name: lumos-code-loop`;`description:` 含觸發詞(分支終審、code review 對抗、pitfalls diff 命中、代碼審計 loop)。本體逐節寫入 spec 組件 ③ 的全部內容:
- 觸發:`pitfalls --diff <merge-base>..HEAD` → tier standard 走現行單 reviewer、tier high 走本 skill(K=2)。
- 每輪 N 步驟 1-7(spec §組件 ③ 逐字):review-package **或等價 `git diff -U10 BASE..HEAD`** 產 diff 文字檔 → 複製**該 diff 文字檔**為工作副本 → 植 bug canary hunk(四型輪替 `[(N−1) mod 4]`:邊界/資源未釋放/例外路徑/冪等併發破壞,插入帶合法 `@@` 標頭的偽 hunk + token)。
- **三道防污染(不可違反,逐字)**:① 真代碼永不含(fix 錨真 diff file:line、canary hunk 不在真 diff);② 低耦合植入(canary file:line 落真改動集之外、弱耦合);③ 溯源排除(finding 推理鏈引用 canary file:line 或依賴其語意、含間接聯想幻影 → 連同 canary 排除、不折、不計)。
- 派 reviewer(refute framing、附 pitfalls --diff manifest 鏡頭)→ 判讀(caught=點出植入 bug 性質)→ 辯方對 ≥major(file:line 反證)→ 存活真 finding 修進真代碼(fix commit,合約級隱患另寫架構圖 ★INVARIANT★ + [test:]、非合約級進套件回歸)。
- `canary record caught|missed --loop code-<topic> --severity <max> --findings <存活數> --auditor <模型>`;missed 該輪不採信、連 2 missed 升模型。
- 收斂:`loop status code-<topic> --need 2 --gate --repo <root>`(無 --spec → G1 skip,K-streak∧G2 決定)→ GATE PASS 進 finishing。
- mutation 冒煙(可選機械錨、高風險建議):隔離 worktree 植 3-5 個變異跑該模組測試,活變異=測試缺口 → finding;零污染。
- 誠實天花板:pattern 提示器非偵測器、canary 校準+溯源排除靠自律(偏多排)、mutation 抽樣非覆蓋、少一道 G1。

- [ ] **Step 2: 驗證 + Commit**

Run: `grep -c "三道防污染\|溯源排除\|canary\|loop status" skills/lumos-code-loop/SKILL.md` → ≥4。
Run: `ls skills/lumos-code-loop/SKILL.md` → 存在。

```bash
git add skills/lumos-code-loop/SKILL.md
git commit -m "feat(skill): lumos-code-loop——代碼對抗審計(bug canary+三道防污染+辯方+證據閘+mutation 冒煙)"
```

---

### Task 5: 接線(orchestrator-prompt + graph-discipline + design-loop skill + project-notes)

**Files:**
- Modify: `governance/autonomous_loop/orchestrator-prompt.md`(步驟 1 節名清單加「實務隱患」;步驟 2.8 旁加 pitfalls --check)
- Modify: `scripts/templates/graph-discipline.md`(調用規則加「終審前 pitfalls --diff;tier high → lumos-code-loop」)
- Modify: `skills/lumos-design-loop/SKILL.md`(審前 pitfalls --check + 清單附審計員)
- Modify: `skills/lumos-project-notes/SKILL.md`(指令表加 pitfalls 三模式;gate 契約段 ~92/~899 補 `--spec` 可選)

**Interfaces:**
- Consumes:Task 1/2 CLI 字面、Task 4 skill 名。
- Produces:散文接線。

- [ ] **Step 1: orchestrator-prompt 步驟 1 + 2.8**

步驟 1 節名清單加「實務隱患」(散文列舉,`grep` 定位「知識同步影響/審計修正紀錄」那行的節名列表,加入「實務隱患」);步驟 2.8(refcheck)區塊旁補一行:`python3 <REPO>/scripts/lumos pitfalls __SCRATCH__/spec/__DATE__-<topic>.md --repo <REPO> --check`(rc 1 → 補「## 實務隱患」節再審)+ 提問清單(`pitfalls` 無 --check 的輸出)附給 auditor 當鏡頭之一。

- [ ] **Step 2: graph-discipline 模板調用規則**

`scripts/templates/graph-discipline.md` 的規則段(找主動調用/skill 相關段)加:「**分支終審前**跑 `lumos pitfalls --diff <merge-base>..HEAD`;`tier: high` → 調用 `lumos-code-loop` skill 做對抗代碼審(user-scope skill,每機裝一次;未裝則退回單 reviewer 並提示裝)」。

- [ ] **Step 3: design-loop skill 審前 pitfalls**

`skills/lumos-design-loop/SKILL.md` 每輪步驟(派審計員前)補:審前跑 `lumos pitfalls <工作副本> --check`,缺「## 實務隱患」節先補;`pitfalls` 提問清單附給審計員當鏡頭。

- [ ] **Step 4: project-notes 指令表 + gate 契約段**

(4a) 讀取/巡檢指令表加 `lumos pitfalls` 列(三模式:spec 提問 / --check 缺節 rc1 / --diff 代碼風險 manifest+tier)。
(4b) gate 契約段(~92 行指令表 + ~899 行收斂留痕段)補註:「code-loop 情境 `--gate` 可省 `--spec`(G1 skip);design/spec loop 仍帶 --spec」。

- [ ] **Step 5: 驗證 + Commit**

Run: `grep -c "pitfalls\|code-loop\|實務隱患" governance/autonomous_loop/orchestrator-prompt.md scripts/templates/graph-discipline.md skills/lumos-design-loop/SKILL.md skills/lumos-project-notes/SKILL.md` → 四檔各 ≥1。

```bash
git add governance/autonomous_loop/orchestrator-prompt.md scripts/templates/graph-discipline.md skills/lumos-design-loop/SKILL.md skills/lumos-project-notes/SKILL.md
git commit -m "feat(wiring): pitfalls/code-loop 接線——orchestrator 步驟1+2.8 / graph-discipline / design-loop / project-notes"
```

---

### Task 6: methodology ×2 + 架構圖節點 + anchor 收尾(controller 自跑)

**Files:**
- Modify: `docs/methodology/架構圖即合約.md`(強制力層表加 pitfalls/code-loop 列 + 審計火力對齊敘事)
- Modify: `docs/methodology/架構圖即合約-對外論述.md`(白話段:AI 寫代碼前被逼答隱患、寫完的代碼跟設計稿一樣被考官+辯方輪審)
- Create: `docs/lumos-toolchain-knowledge/Systems/pitfalls-code-loop.md`、`Verification/2026-07-04_pitfalls-code-loop.md`
- Modify(收尾): `governance/anchor-baseline.json`

> 鐵則:只建這兩個 KG 節點;lint ×2 + doctor 0 issues;merge 後 push 前 `lumos anchor approve --note` 同批 commit(本分支動了 test_lumos.py+test_autonomous_loop.py 兩錨點)。

- [ ] **Step 1: methodology ×2**(強制力層表新列:pitfalls 提問閘[--check 缺節擋]+ code-loop 終審對抗[bug canary+辯方+G2 收斂,風險分級觸發];天花板:提示器非偵測器/canary 溯源排除靠自律。對外論述白話段:碰錢/對外/動守衛的代碼,寫前逼答上線隱患、寫完跟設計稿一樣被考官+辯方輪審。)

- [ ] **Step 2: Systems + Verification 節點**(Systems summary:FLOW=pitfalls 三模式→tier→code-loop 對抗審→收斂;KEY=三道防污染/class 形態軸/gate --spec 可選/漂移守衛釘類名+黑名單/誠實天花板 7 條;decisions=共用層/黑名單非白名單/reviewer canary+mutation 雙錨/事故語料留 v2;DEP=[[risk-tiered-review]]/[[convergence-evidence-gate]]/[[lumos-refcheck]]。Verification:valid_under=PITFALL_CLASSES 詞表+pattern 表+gate --spec 可選+skill 步驟;TEST 行記實際測試數。)

- [ ] **Step 3: lint + doctor + commit + merge 收尾**

```bash
./scripts/lumos lint Systems/pitfalls-code-loop && ./scripts/lumos lint Verification/2026-07-04_pitfalls-code-loop
./scripts/lumos doctor   # 0 issues
git add docs/ && git commit -m "kg+docs(pitfalls-code-loop): methodology×2 + Systems/Verification 節點"
# merge 回 main 後、push 前:
# lumos anchor approve --note "pitfalls-code-loop:測試 runner 更新(t_pitfalls_*/gate no-spec/漂移守衛)" && git add governance/anchor-baseline.json && git commit && git push
```

---

## Self-Review

**Spec coverage**:
- 組件 ①(pitfalls 三模式:詞表/通用3問/類追問/剝除對齊 assess_spec 含防呆/--check rc/diff pattern+line 推導+class 形態軸+過濾繼承)→ Task 1(spec+check)+ Task 2(diff)。✓
- 組件 ②(gate --spec 可選、G1 skip、有 spec 分毫不變)→ Task 3。✓
- 組件 ③(code-loop skill:四型 canary+三道防污染+辯方+[test:]收口+G2 收斂+mutation)→ Task 4。✓
- 組件 ④(接線 orchestrator/graph-discipline/design-loop/project-notes)→ Task 5。✓
- 漂移守衛(類名 ≡ RISK_CLASSES + 黑名單 ≡ _BLACKLIST,toolchain-only)→ Task 1 Step 1 TestPitfallsDrift。✓
- 測試策略 10 案 → t_pitfalls_spec(1-4,含剝除)+ t_pitfalls_diff(5-7 命中/skip/測試檔)+ TestPitfallsDrift(8)+ t_loop_gate 案14改+t_loop_gate_no_spec(9)+ 全套件回歸(10)。✓
- 知識同步表 → Task 5(orchestrator/design-loop/project-notes/graph-discipline)+ Task 6(methodology×2/KG);memory `autonomous-iteration-loop` controller 收尾。✓
- 誠實天花板 7 條 → Task 4 skill + Task 6 節點 KEY。✓

**Placeholder scan**:Task 4/6 為散文/節點內容要點清單(既例模式,controller 現場寫全文);Task 1-3/5 完整 old/new 與代碼。✓

**Type consistency**:`cmd_pitfalls(md, diff, repo, check, as_json, section_title)` ↔ dispatch kwargs ↔ argparse dest(`md`/`pf_diff`/`pf_repo`/`check`/`pf_json`);`_pitfall_diff_mode(diff_range, repo_root, as_json)` Task 1 呼叫 ↔ Task 2 定義;manifest schema `{file,line,class,pattern,question}`+`tier` 測試斷言一致;`PITFALL_CLASSES`/`_PITFALL_BLACKLIST` 常數名 Task 1 定義 ↔ TestPitfallsDrift 正則抓取一致;gate G1 skip 訊息「skipped」測試斷言一致。✓

> **Task 1↔2 銜接注意**:Task 1 Step 3 的 `cmd_pitfalls` 已寫 `if diff is not None: return _pitfall_diff_mode(...)`,但 `_pitfall_diff_mode` Task 2 才定義——Task 1 Step 4 註記把該行**暫時**改佔位(print+return 0)使 Task 1 可獨立跑綠;Task 2 Step 3 改回真呼叫。實作者須遵此順序,否則 Task 1 測試跑到 diff 分支會 NameError(但 Task 1 測試不觸發 diff 模式,實務上僅需確保佔位/真呼叫二選一存在)。
