# lumos refcheck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增 vault-free 指令 `lumos refcheck <md檔> [--repo <root>] [--json]`:確定性抽取 spec 的 inline-code 檔路徑+行號宣稱,機械核對存在性/行號範圍,輸出證據 manifest;並接進三個消費端(orchestrator-prompt、design-loop SKILL、方法論文檔)。

**Architecture:** `cmd_refcheck` 複用 Check P 已收斂的抽取規則(`scripts/lumos:749-786` 的 step 1-2 抽取與過濾),但去重粒度改為 `(token, line)` tuple(Check P 是 token 級——同檔多行號會塌成一條,refcheck 的 manifest 粒度掛在行號上,這是刻意分歧)。核對層(missing / line_out_of_range / ok + excerpt)是新增。CLI 走 install/bootstrap 同款 pre-Env 分流(不需 vault)。消費端整合全是散文 prompt/文檔編輯,不動任何 python 判定代碼。

**Tech Stack:** Python 3 stdlib(re、json 函數內 import——本 codebase 慣例、pathlib);測試沿用 `scripts/test_lumos.py` 自製 harness(`run()`/`check()`/`t_` 前綴自動收集)。

**Branch:** 在 `feat/spec-refcheck` 分支上實作(不直接動 main)。

## Global Constraints

- stdlib only,零第三方依賴;Python ≥3.8。
- **rc 語意(spec §範圍)**:全 ok → 0;有 missing 或 out_of_range → 1;參數/repo 解析失敗 → 2。
- **去重粒度 = `(token, line)` tuple**(spec 抽取規則 step 3;**不沿用** Check P 的 token 級去重)。
- **canary 相容性(不可違反)**:refcheck 只驗 spec→repo 指涉,**不驗 spec 內部一致性**(§ref 存不存在、`--旗標` 有無定義、ALL_CAPS 有無值)——那是 canary 的保留地。不得加任何內部一致性檢查。
- **不動** `governance/autonomous_loop/cross_audit.py`(run_cross_audit 簽名與實作零改動)、不動 canary/judge/辯方判定代碼、refcheck rc 不進 `lumos loop status` 判準。
- **不動 doctor Check P 行為**(refcheck 是獨立函數,只複製抽取邏輯、不抽共用 helper——兩者去重粒度不同,硬共用反而引入耦合;spec 明示共用方式留實作決定,本計畫選「複製」)。
- manifest JSON schema:`{"claims":[{token,line,status,excerpt[,dir]}...],"missing":N,"out_of_range":N,"ok":N}`;`line` 為字串(單行 `"39"`、範圍原字面 `"2-4"`、無行號 `""`)。
- 消費端編輯是**散文規範**:orchestrator-prompt.md 的 §2 步驟編號體系(1-8)不重排,新步驟用 `2.8.`;SKILL.md 同理用 `2.5.`。

---

### Task 1: `cmd_refcheck` 核心 + CLI 註冊 + 測試

**Files:**
- Modify: `scripts/lumos`(三處:`def main():` 前加 `cmd_refcheck` 函數;deinit subparser 塊後加 refcheck subparser;pre-Env dispatch 加 refcheck 分支)
- Test: `scripts/test_lumos.py`(新增 `t_refcheck`)

**Interfaces:**
- Consumes(皆既有,`scripts/lumos` module-level):`FENCE_RE`(:39)、`INLINE_CODE_RE`(:40)、`re`、`sys`、`Path`。
- Produces:`cmd_refcheck(md_path, repo=None, as_json=False) -> int`;CLI `lumos refcheck <md> [--repo <root>] [--json]`。Task 2/3 引用的指令字面即此。

- [ ] **Step 1: Write the failing test**

加到 `scripts/test_lumos.py`(任意 `def t_` 函數群之後,模組層):

```python
def _mk_refcheck_repo():
    """temp repo:scripts/real.py(5行) + 頂層 scripts/ 目錄;refcheck 用 --repo 顯式指定,免 git。"""
    root = Path(tempfile.mkdtemp(prefix="gctl-refcheck-"))
    (root / "scripts").mkdir()
    (root / "scripts" / "real.py").write_text(
        "L1 = 1\nL2 = 2\nL3 = 3\nL4 = 4\nL5 = 5\n", encoding="utf-8")
    return root


def t_refcheck():
    import json as _json
    root = _mk_refcheck_repo()

    # ---- 案例 1/3/4/5/7 + 目錄型:綜合 spec ----
    md_all = root / "spec-all.md"
    md_all.write_text(
        "# t\n"
        "缺:`scripts/ghost.py` 實作。\n"
        "在:`scripts/real.py:3` 與超界 `scripts/real.py:99` 與裸 `scripts/real.py`。\n"
        "範圍:`scripts/real.py:2-4`。\n"
        "目錄:`scripts/`。\n"
        "跳過:`https://x/y`、`and/or`、`cmd_context`、`governance/pending/*.md`。\n"
        "```\nfenced 內 `scripts/fenced.py` 不抓\n```\n",
        encoding="utf-8")
    r = run(root, "refcheck", str(md_all), "--repo", str(root), "--json")
    check("refcheck: 綜合 spec rc=1(有 missing+out_of_range)", r.returncode == 1,
          f"rc={r.returncode}\n{r.stdout}\n{r.stderr}")
    data = _json.loads(r.stdout)
    by_key = {(c["token"], c["line"]): c for c in data["claims"]}

    check("refcheck: ghost 報 missing",
          by_key.get(("scripts/ghost.py", ""), {}).get("status") == "missing", r.stdout)
    check("refcheck: real.py:3 ok 且 excerpt=第3行實際內容",
          by_key.get(("scripts/real.py", "3"), {}).get("status") == "ok"
          and by_key.get(("scripts/real.py", "3"), {}).get("excerpt") == "L3 = 3", r.stdout)
    check("refcheck: real.py:99 報 line_out_of_range",
          by_key.get(("scripts/real.py", "99"), {}).get("status") == "line_out_of_range", r.stdout)
    check("refcheck: 裸 real.py ok 且 excerpt 空",
          by_key.get(("scripts/real.py", ""), {}).get("status") == "ok"
          and by_key.get(("scripts/real.py", ""), {}).get("excerpt") == "", r.stdout)
    ex24 = by_key.get(("scripts/real.py", "2-4"), {}).get("excerpt", "")
    check("refcheck: 範圍 2-4 ok 且 excerpt 含首尾行",
          by_key.get(("scripts/real.py", "2-4"), {}).get("status") == "ok"
          and "L2 = 2" in ex24 and "L4 = 4" in ex24, r.stdout)
    check("refcheck: 同檔多行號不塌成一條(r3-F1,:3/:99/裸/2-4 各自成 claim)",
          len([c for c in data["claims"] if c["token"] == "scripts/real.py"]) == 4, r.stdout)
    check("refcheck: 目錄型 token ok+dir 註記、excerpt 空",
          by_key.get(("scripts/", ""), {}).get("status") == "ok"
          and by_key.get(("scripts/", ""), {}).get("dir") is True, r.stdout)
    skipped = {"https://x/y", "and/or", "cmd_context", "governance/pending/*.md",
               "scripts/fenced.py"}
    check("refcheck: url/非頂層/無斜線/glob/fenced 皆不入 claims",
          not any(c["token"] in skipped for c in data["claims"]), r.stdout)
    check("refcheck: 統計欄位正確(ok4/missing1/oor1)",
          data["ok"] == 4 and data["missing"] == 1 and data["out_of_range"] == 1, r.stdout)

    # ---- 案例 2:全 ok → rc 0 ----
    md_ok = root / "spec-ok.md"
    md_ok.write_text("# t\n只有 `scripts/real.py:3`。\n", encoding="utf-8")
    r = run(root, "refcheck", str(md_ok), "--repo", str(root), "--json")
    check("refcheck: 全 ok rc=0", r.returncode == 0, f"rc={r.returncode}\n{r.stdout}")

    # ---- 案例 6:--repo 解析失敗 → rc 2 ----
    r = run(root, "refcheck", str(md_ok), "--repo", str(root / "nope"))
    check("refcheck: --repo 不存在 rc=2", r.returncode == 2, f"rc={r.returncode}")

    # ---- md 檔不存在 → rc 2 ----
    r = run(root, "refcheck", str(root / "ghost.md"), "--repo", str(root))
    check("refcheck: md 不存在 rc=2", r.returncode == 2, f"rc={r.returncode}")

    # ---- 人讀版(無 --json)可跑、rc 語意一致 ----
    r = run(root, "refcheck", str(md_all), "--repo", str(root))
    check("refcheck: 人讀版 rc=1 且含統計行", r.returncode == 1 and "missing" in r.stdout,
          f"rc={r.returncode}\n{r.stdout}")
```

> 註:`run(root, ...)` 會帶 `--vault <root>`——refcheck 在 main() 的 pre-Env 分流處理,`--vault` 被無視,無妨。

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test_lumos.py 2>&1 | grep -A2 "refcheck"`
Expected: FAIL——argparse 報 `invalid choice: 'refcheck'`(subcommand 未註冊),`run()` 內 `expect_rc` 未用故不 raise,各 `check` 全 ✗。

- [ ] **Step 3: Implement `cmd_refcheck`**

Edit `scripts/lumos`,在 `def main():`(約 :3549)**正上方**插入:

```python
def cmd_refcheck(md_path, repo=None, as_json=False):
    """spec 指涉宣稱確定性核對(vault-free):inline-code 檔路徑/行號 → 存在性 manifest。
    抽取規則同 doctor Check P step 1-2(刻意複製、不共用——去重粒度不同:
    Check P 是 token 級,這裡是 (token, line);同檔多行號各自成 claim)。
    只驗 spec→repo 指涉,不驗 spec 內部一致性(canary 保留地)。"""
    import json
    md = Path(md_path)
    if not md.is_file():
        print(f"ERROR: 找不到檔案: {md_path}", file=sys.stderr)
        return 2
    if repo is not None:
        repo_root = Path(repo)
        if not repo_root.is_dir():
            print(f"ERROR: --repo 不是目錄: {repo}", file=sys.stderr)
            return 2
    else:
        repo_root = None
        for cand in (Path.cwd(), *Path.cwd().parents):
            if (cand / ".git").exists():
                repo_root = cand
                break
        if repo_root is None:
            print("ERROR: cwd 逐層向上找不到 .git repo,請用 --repo 指定", file=sys.stderr)
            return 2
    try:
        text = md.read_text(encoding="utf-8-sig")
    except OSError as e:
        print(f"ERROR: 讀不到 {md_path}: {e}", file=sys.stderr)
        return 2

    top_dirs = {p.name for p in repo_root.iterdir() if p.is_dir() and not p.name.startswith(".")}
    _suffix_re = re.compile(r":([^/]+)$")
    spans = [s.strip("`") for s in INLINE_CODE_RE.findall(FENCE_RE.sub("", text))]
    seen = set()
    claims = []
    for raw in spans:
        if "://" in raw or any(c in raw for c in "*<>?"):
            continue
        m = _suffix_re.search(raw)
        if m:
            token, sfx = raw[:m.start()], m.group(1)
            line = sfx if re.fullmatch(r"\d+(?:-\d+)?", sfx) else ""
        else:
            token, line = raw, ""
        if "/" not in token or (token, line) in seen:
            continue
        if token.split("/")[0] not in top_dirs:
            continue
        seen.add((token, line))
        target = repo_root / token
        if not target.exists():
            claims.append({"token": token, "line": line, "status": "missing", "excerpt": ""})
            continue
        if target.is_dir():
            claims.append({"token": token, "line": line, "status": "ok", "excerpt": "", "dir": True})
            continue
        if not line:
            claims.append({"token": token, "line": line, "status": "ok", "excerpt": ""})
            continue
        if "-" in line:
            lo, hi = (int(x) for x in line.split("-", 1))
        else:
            lo = hi = int(line)
        try:
            file_lines = target.read_text(encoding="utf-8-sig", errors="replace").splitlines()
        except OSError:
            file_lines = None
        if file_lines is None or lo < 1 or hi > len(file_lines):
            claims.append({"token": token, "line": line, "status": "line_out_of_range", "excerpt": ""})
            continue
        if lo == hi:
            excerpt = file_lines[lo - 1]
        else:
            excerpt = file_lines[lo - 1] + "\n…\n" + file_lines[hi - 1]
        claims.append({"token": token, "line": line, "status": "ok", "excerpt": excerpt})

    n_missing = sum(1 for c in claims if c["status"] == "missing")
    n_oor = sum(1 for c in claims if c["status"] == "line_out_of_range")
    n_ok = sum(1 for c in claims if c["status"] == "ok")
    if as_json:
        print(json.dumps({"claims": claims, "missing": n_missing,
                          "out_of_range": n_oor, "ok": n_ok}, ensure_ascii=False))
    else:
        print(f"refcheck {md} (repo={repo_root})")
        for c in claims:
            loc = f"{c['token']}:{c['line']}" if c["line"] else c["token"]
            mark = "✓" if c["status"] == "ok" else "✗"
            tail = f" | {c['excerpt']}" if c["excerpt"] and "\n" not in c["excerpt"] else ""
            print(f"  {mark} {c['status']:<17} {loc}{tail}")
        print(f"統計: ok {n_ok} / missing {n_missing} / out_of_range {n_oor}")
    return 1 if (n_missing or n_oor) else 0
```

- [ ] **Step 4: Register CLI + pre-Env dispatch**

(4a) Edit `scripts/lumos` subparser 區——在 deinit 塊之後、`args = ap.parse_args()` 之前:

old:
```python
    p.add_argument("--source", help="Lumos 來源 repo 路徑(僅供自我保護比對)")

    args = ap.parse_args()
```
new:
```python
    p.add_argument("--source", help="Lumos 來源 repo 路徑(僅供自我保護比對)")

    p = sub.add_parser("refcheck", help="spec 指涉宣稱確定性核對(vault-free):inline-code 路徑/行號 → 存在性 manifest")
    p.add_argument("md", help="要核對的 markdown 檔")
    p.add_argument("--repo", dest="refcheck_repo", help="repo root(預設 cwd 逐層向上找 .git)")
    p.add_argument("--json", dest="as_json", action="store_true", help="輸出 JSON manifest")

    args = ap.parse_args()
```

(4b) Edit pre-Env dispatch——deinit 分支之後、`vault = args.vault or find_vault(Path.cwd())` 之前:

old:
```python
    if args.cmd == "deinit":
        return cmd_deinit(keep_graph=args.keep_graph, dry_run=args.dry_run,
                          yes=args.yes, source=args.source)

    vault = args.vault or find_vault(Path.cwd())
```
new:
```python
    if args.cmd == "deinit":
        return cmd_deinit(keep_graph=args.keep_graph, dry_run=args.dry_run,
                          yes=args.yes, source=args.source)
    if args.cmd == "refcheck":
        return cmd_refcheck(args.md, repo=args.refcheck_repo, as_json=args.as_json)

    vault = args.vault or find_vault(Path.cwd())
```

> `--repo` 用 `dest="refcheck_repo"`:update subparser 已有 `--source`,而 `refcheck` 若用 dest=`repo` 與任何既有屬性撞名的風險為零(各 subparser namespace 獨立),但顯式 dest 讓 dispatch 讀值不含糊。

- [ ] **Step 5: Run tests to verify pass**

Run: `python3 scripts/test_lumos.py 2>&1 | grep -E "refcheck"`
Expected: `t_refcheck` 全部 ✓(13 個 check)。

Run: `python3 scripts/test_lumos.py 2>&1 | tail -3`
Expected: `N passed, 0 failed`(N ≥ 293:既有 280 + 新 13),既有測試零回歸(含 doctor Check P 的 `t_doctor_check_p*`)。

- [ ] **Step 6: Smoke on real spec**

Run: `./scripts/lumos refcheck docs/design/2026-07-02-spec-refcheck.md --repo . 2>&1 | tail -5`
Expected: 統計行印出;spec 引用的 `scripts/lumos:749-786` 等座標 ok(有 excerpt)。rc 可能為 1(spec 引用了尚未存在的路徑則屬正常),不擋。

- [ ] **Step 7: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): refcheck 指令——spec 指涉宣稱確定性核對 + 證據 manifest(vault-free)"
```

---

### Task 2: 消費端 ①② — orchestrator-prompt.md(步驟 2.8 + auditor/judge 措辭 + §2.5a 取材)

**Files:**
- Modify: `governance/autonomous_loop/orchestrator-prompt.md`(§2 步驟區 :34-42、§2.5a :45)

**Interfaces:**
- Consumes: Task 1 的 CLI 字面 `python3 <REPO>/scripts/lumos refcheck <md> --repo <REPO> --json`。
- Produces: prompt 散文規範,無代碼接口。

- [ ] **Step 1: 插入步驟 2.8(植 canary 後、spawn auditor 前)**

Edit `governance/autonomous_loop/orchestrator-prompt.md`:

old(:35 行,步驟 2 全行結尾處起到步驟 3 開頭):
```
2. 在**工作副本**(只工作副本)植 1 個 canary,類型=[a,b,c][(N-1)%3]:a=壞§ref(引用不存在章節);b=未定義旗標(--xxx 它處無定義);c=未定義常數(ALL_CAPS 無值)。行尾加唯一 token <!-- CANARY-AUTO-N -->。
3. **用 Agent 工具 spawn 一個 opus auditor**
```
new:
```
2. 在**工作副本**(只工作副本)植 1 個 canary,類型=[a,b,c][(N-1)%3]:a=壞§ref(引用不存在章節);b=未定義旗標(--xxx 它處無定義);c=未定義常數(ALL_CAPS 無值)。行尾加唯一 token <!-- CANARY-AUTO-N -->。
2.8. **機械核對(refcheck,對工作副本)**:`python3 <REPO>/scripts/lumos refcheck __SCRATCH__/<topic>-rN.md --repo <REPO> --json`。missing/line_out_of_range 宣稱=**機械 finding**:直接修正**原稿 spec**(修正記入審計修正紀錄、標「機械 refcheck」留痕;修正會被後續輪 auditor 重審,收斂輪的修正由 §2.5 cross_audit 讀最終原稿覆蓋)。manifest(ok 宣稱+excerpts)留存,步驟 3/4 附進 prompt。refcheck 只驗 spec→repo 指涉、**不驗 spec 內部一致性**(§ref/旗標/常數)——那是 canary 保留地、審計員責任田。
3. **用 Agent 工具 spawn 一個 opus auditor**
```

- [ ] **Step 2: auditor prompt 補 manifest 措辭(步驟 3)**

old(:36 行尾):
```
實際 grep/Read 驗 scripts/lumos 等真實 code,報告列查證指令與結果),逐條標 severity。
```
new:
```
實際 grep/Read 驗 scripts/lumos 等真實 code,報告列查證指令與結果),逐條標 severity。**附上步驟 2.8 的 refcheck manifest**:manifest 內宣稱的存在性/行號已機械驗訖,不必花查證力氣在「在不在」;地面查證聚焦**語意**——spec 對這些位置的描述、欄位/函數行為的宣稱對不對。**manifest 非宣稱全集**:散文裡(沒 backtick)的現況假設仍要自己 grep/Read 查。
```

- [ ] **Step 3: judge prompt 補 manifest + 語意查證行措辭(步驟 4)**

old(:37 行內):
```
唯有「對最嚴重 finding 無任一 grep/Read 查證行」才至少 major(客觀二值,不評足不足)。
```
new:
```
唯有「對最嚴重 finding 無任一 grep/Read 查證行」才至少 major(客觀二值,不評足不足;**同附 refcheck manifest+rc:存在性由機械 refcheck 保證,「查證行」閘只計語意查證行**)。
```

- [ ] **Step 4: §2.5a 取材改「機械底座 + 補充」**

old(:45 行):
```
a. **取材**:把本 spec 引用到的真實檔案/符號 grep/Read 出來(步驟 3 強制查證時已查過),整理成 ground-truth 片段。
```
new:
```
a. **取材**:對最終原稿 spec 重跑一次 refcheck(`--json`),其 manifest 為 ground-truth **必含底座、不得刪減**;再補語意片段(函數體/欄位定義,步驟 3 查證時已讀過)。誠實邊界:manifest 只保證「引用座標經機械核對」(無行號宣稱僅存在性、有行號僅孤立單行),語意份量仍靠補充段;「不得刪減」是散文規範無機械強制,漏貼可與 auditor 收到的 manifest 對照發現(機械拼接留 v2)。
```

- [ ] **Step 5: 驗證編輯完整性**

Run: `grep -n "2.8\.\|refcheck" governance/autonomous_loop/orchestrator-prompt.md`
Expected: 步驟 2.8 一處、步驟 3/4/§2.5a 各含 refcheck 措辭,共 ≥4 處命中;`grep -c "manifest" governance/autonomous_loop/orchestrator-prompt.md` ≥ 4。

- [ ] **Step 6: Commit**

```bash
git add governance/autonomous_loop/orchestrator-prompt.md
git commit -m "feat(loop): orchestrator 接 refcheck——步驟 2.8 機械核對 + auditor/judge manifest 措辭 + ground_truth 機械底座"
```

---

### Task 3: 消費端 ③ — lumos-design-loop SKILL.md(步驟 2.5 + canary (d) 校準規則)

**Files:**
- Modify: `skills/lumos-design-loop/SKILL.md`(「每一輪(照做)」步驟 2-3 區,:19-25)

**Interfaces:**
- Consumes: Task 1 的 CLI 字面 `lumos refcheck /tmp/<id>-rN.md --repo <repo根> --json`。
- Produces: 散文規範,無代碼接口。

- [ ] **Step 1: canary (d) 型補裸檔名校準規則**

old(:23):
```
   - (d) 未定義產物/檔名(憑空的 `xxx.json`,不在 schema/它處)
```
new:
```
   - (d) 未定義產物/檔名(憑空的 `xxx.json`,不在 schema/它處)。**(d) 型保持裸檔名(勿帶 repo 路徑如 `configs/foo.json`)——裸檔名無 `/`,天然在 refcheck 抽取域外,canary 防線不受影響;帶路徑會被步驟 2.5 機械吃掉、canary 作廢**
```

- [ ] **Step 2: 插入步驟 2.5(植 canary 後、派審計員前)**

old(:24-25,校準鐵則行到步驟 3 開頭):
```
   嵌唯一 token 定位。**canary 要「認真審就抓得到、但不一眼看穿」**——太細=不公平、太明顯=訊號弱(校準鐵則)。
3. **派乾淨審計員**
```
new:
```
   嵌唯一 token 定位。**canary 要「認真審就抓得到、但不一眼看穿」**——太細=不公平、太明顯=訊號弱(校準鐵則)。
2.5. **機械核對(refcheck,對工作副本)**:`lumos refcheck /tmp/<id>-rN.md --repo <repo根> --json`。missing/line_out_of_range=機械 finding,直接修**真檔 spec**(記入審計修正紀錄、標「機械 refcheck」);manifest(ok 宣稱+excerpts)留存、步驟 3 餵審計員。refcheck 只驗 spec→repo 指涉、不驗 spec 內部一致性——內部一致性是 canary 保留地、審計員責任田。
3. **派乾淨審計員**
```

- [ ] **Step 3: 步驟 3 審計員 prompt 補 manifest 餵入**

old(:25 行內):
```
要它逐節讀、主動找洞(未定義詞/壞引用/不一致/矛盾/可執行性 gap),逐條標 severity。
```
new:
```
要它逐節讀、主動找洞(未定義詞/壞引用/不一致/矛盾/可執行性 gap),逐條標 severity;**附步驟 2.5 的 refcheck manifest**——manifest 內宣稱的存在性/行號已機械驗訖,查證力氣聚焦語意;manifest 非宣稱全集,散文裡的現況假設仍要自己查。
```

- [ ] **Step 4: 驗證 + Commit**

Run: `grep -c "refcheck" skills/lumos-design-loop/SKILL.md`
Expected: ≥ 3。

```bash
git add skills/lumos-design-loop/SKILL.md
git commit -m "feat(skill): lumos-design-loop 接 refcheck——步驟 2.5 機械核對 + (d) 型裸檔名校準規則"
```

---

### Task 4: 知識同步 — methodology ×2 + lumos-project-notes 指令表

**Files:**
- Modify: `docs/methodology/架構圖即合約.md`(§四「設計前審計 loop」表格)
- Modify: `docs/methodology/架構圖即合約-對外論述.md`(:152「跨家族」段後)
- Modify: `skills/lumos-project-notes/SKILL.md`(讀取/巡檢表 + 子命令全覽行)

**Interfaces:**
- Consumes: Task 1 的指令語意(存在性機械化、LLM 只判語意)。
- Produces: 純文檔,無接口。

- [ ] **Step 1: 架構圖即合約.md — 設計前審計 loop 表格加一列**

old(「### 設計前審計 loop」表格內):
```
| 收斂留痕(A) | `lumos canary record --loop/--severity` 記每輪 + `lumos loop status <id> --need 2` **機械算收斂**（連 2 輪 caught 且無 blocker/major）；exit 0=綠燈進實作 |
```
new:
```
| 機械 refcheck(2026-07-02) | **確定性 > AI 判斷的落地例**:審計最吃重的「地面事實查證」恰是 LLM 最弱的能力(<55%)——`lumos refcheck` 把「檔在不在、行號在不在範圍」這片機械化(manifest+excerpt 餵 auditor/judge/cross_audit),LLM 只判 grep 查不到的語意。只驗 spec→repo 指涉、不驗 spec 內部一致性(canary 保留地)。放行時 qwen disputed 被 python/sed 秒級反證的現場,即此 gap 的實證 |
| 收斂留痕(A) | `lumos canary record --loop/--severity` 記每輪 + `lumos loop status <id> --need 2` **機械算收斂**（連 2 輪 caught 且無 blocker/major）；exit 0=綠燈進實作 |
```

- [ ] **Step 2: 對外論述 — :152「跨家族」段後插白話段**

old(:152 段尾到 :154 段頭):
```
它一樣不是萬靈丹——換家族只是降低「大家一起瞎」的機率,不是保證沒問題;最後按下放行的,仍然是人。
```
new:
```
它一樣不是萬靈丹——換家族只是降低「大家一起瞎」的機率,不是保證沒問題;最後按下放行的,仍然是人。

還有一種錯,連換家族都防不了:審計員聲稱「我查過了,這個檔案在、第幾行是什麼」——結果它根本查錯。研究實測 AI 做這種「地面事實查證」的正確率不到 55%,我自己也當場見過:另一家族的複核模型連續兩輪言之鑿鑿指出「重大缺陷」,用程式一跑、幾秒就證明全是它看錯。所以我把這件事**從 AI 手裡拿走**:審查開始前,系統先用一個小工具把文件裡提到的每個檔案、每個行號機械查一遍,附上原文摘錄給審查員——「在不在」機器說了算,審查員只判機器查不了的「描述得對不對」。查勤的事交給機器,動腦的事才留給 AI。
```

- [ ] **Step 3: lumos-project-notes SKILL.md — 讀取/巡檢表加 refcheck 列 + 全覽行更新**

(3a) old(讀取/巡檢表內):
```
| **全文搜尋** | `python3 scripts/lumos search <詞> [--path Systems] [--regex] [--files-only]` — frontmatter+body,大小寫不敏感 substring |
```
new:
```
| **全文搜尋** | `python3 scripts/lumos search <詞> [--path Systems] [--regex] [--files-only]` — frontmatter+body,大小寫不敏感 substring |
| **spec 指涉宣稱機械核對(vault-free)** | `lumos refcheck <md檔> [--repo <root>] [--json]` — 抽 inline-code 檔路徑/行號、核對存在性/行號範圍、輸出證據 manifest(含行內容摘錄);design-loop 審計前先跑,存在性查證不靠 LLM。rc:全 ok=0/有 missing 或超界=1/參數錯=2 |
```

(3b) old:
```
> **23 個子命令全覽**：讀取/巡檢 12（`doctor` `context` `contracts` `search` `links` `backlinks` `map` `export` `decisions` `stale` `recent` `stats`）+ 寫入 7（`set` `append` `new` `archive` `decision-add` `decision-supersede` `self-audit`）+ 安裝/生命週期 4（`install` `uninstall` `update` `bootstrap`）。`lumos --help` 為現行權威。
```
new:
```
> **子命令全覽**：讀取/巡檢 13（`doctor` `context` `contracts` `search` `refcheck` `links` `backlinks` `map` `export` `decisions` `stale` `recent` `stats`）+ 寫入 7（`set` `append` `new` `archive` `decision-add` `decision-supersede` `self-audit`）+ 安裝/生命週期 4（`install` `uninstall` `update` `bootstrap`）+ 其餘（`lint` `gov` `canary` `loop` `guard` `sync-verified-by` `init` `deinit` 等）。`lumos --help` 為現行權威。
```

- [ ] **Step 4: 驗證 + Commit**

Run: `grep -c "refcheck" docs/methodology/架構圖即合約.md docs/methodology/架構圖即合約-對外論述.md skills/lumos-project-notes/SKILL.md`
Expected: 三檔各 ≥1。

```bash
git add docs/methodology/架構圖即合約.md docs/methodology/架構圖即合約-對外論述.md skills/lumos-project-notes/SKILL.md
git commit -m "docs(sync): refcheck 知識同步——methodology 確定性軸 + 對外白話段 + project-notes 指令表"
```

---

### Task 5: 架構圖節點 — Systems/lumos-refcheck + Verification(收尾,controller 可自跑)

**Files:**
- Create: `docs/lumos-toolchain-knowledge/Systems/lumos-refcheck.md`
- Create: `docs/lumos-toolchain-knowledge/Verification/2026-07-02_lumos-refcheck.md`

**Interfaces:**
- Consumes: Task 1-4 的落地事實(測試數、消費端接線)。
- Produces: KG 節點;`verified_by` 互指。

> **鐵則**:只建這兩個節點,**不得**建任何其他節點(前例:實作 subagent 自建 out-of-scope 節點兩度弄壞 doctor)。寫完跑 `lumos lint` + `lumos doctor` 必須 0 issues。

- [ ] **Step 1: 建 Systems 節點**

`docs/lumos-toolchain-knowledge/Systems/lumos-refcheck.md`:

```markdown
---
type: system
status: done
created: 2026-07-02
updated: 2026-07-02
tags:
  - type/system
  - status/done
verified_by:
  - "[[Verification/2026-07-02_lumos-refcheck]]"
summary: |-
  FLOW:refcheck <md> --repo <root>→FENCE剝/INLINE抽/剝反引號→跳://與*<>?→剝:suffix(純數字才當行號)→須含/且首段=頂層目錄→(token,line)去重→exists/is_dir/行號範圍核對→manifest{token,line,status,excerpt}+統計→rc 0/1/2
  KEY:vault-free(pre-Env 分流,同 install/bootstrap);--repo 省略時 cwd 逐層向上找 .git,無則 rc2
  KEY:去重粒度=(token,line) tuple,刻意不沿用 doctor Check P 的 token 級(同檔多行號不塌;manifest 粒度掛行號)——抽取 step1-2 同款、複製非共用
  KEY:只驗 spec→repo 指涉、不驗 spec 內部一致性(§ref/旗標/常數)——canary 保留地,refcheck 抓走=test-the-tester 防線報廢;(d)型 canary 靠裸檔名(無/)天然在抽取域外(散文規範非機械強制)
  KEY:誠實天花板——存在≠語意正確;行號漂移半盲(內容換掉仍 ok,excerpt 供目視);只收 inline-code 宣稱(散文路徑/fenced/頂層檔案/top-dir typo 皆域外);manifest 錨定效應要 prompt 明示「非宣稱全集」
  DEP:[[canary-audit]]｜doctor Check P(抽取規則同源)
  TEST:t_refcheck 13 checks(missing/ok+excerpt/out_of_range/範圍行號/同檔多行號不塌/目錄型/跳過規則/rc語意)
  VERIFY:[[2026-07-02_lumos-refcheck]]
decisions:
  - content: 抽取邏輯從 Check P 複製而非抽共用 helper;去重粒度 (token,line) 與 Check P 的 token 級刻意分歧
    context: spec r3-F1:Check P token 級去重會把同檔多行號引用塌成一條,refcheck 的 line_out_of_range/excerpt 都掛行號上;spec 明示共用方式留實作決定
    why_chosen: 兩者粒度不同,硬共用要帶 mode 參數反而耦合;複製段小(~30 行)且各自有測試鎖行為
    decided: 2026-07-02
    valid: true
  - content: refcheck 刻意不驗 spec 內部一致性,rc 不進 loop status 收斂判準
    context: canary a/b/c 全是 spec 內部瑕疵,refcheck 機械抓掉=auditor 看 manifest 就能「抓到」canary,test-the-tester 失效;它是 pre-audit 修正器不是第五道 gate
    why_chosen: canary 相容性是 spec 標明「不可違反」的設計約束
    decided: 2026-07-02
    valid: true
---
# lumos-refcheck

`scripts/lumos` 的 `refcheck` 子指令——spec 指涉宣稱的**確定性核對 + 證據 manifest**(vault-free)。

## 動機
design-loop/跨家族複核最吃重的「地面事實查證」恰是 LLM 最不可靠的能力(<55%);放行本 spec 時 qwen disputed 的 5 條 ≥major 指控被 python/sed 秒級全反證,即現場實證。refcheck 把「檔在不在、行號在不在範圍」機械化,LLM 只判 grep 查不到的語意。

## 三個消費端
- 自動 loop:`governance/autonomous_loop/orchestrator-prompt.md` §2 步驟 2.8(植 canary 後、spawn auditor 前對工作副本跑;missing/超界=機械 finding 修原稿留痕)+ auditor/judge prompt 附 manifest + §2.5a ground_truth 機械底座(不得刪減,散文規範)。
- 手動 loop:`skills/lumos-design-loop/SKILL.md` 步驟 2.5 同款 + (d) 型 canary 裸檔名校準規則。
- 方法論:`docs/methodology/架構圖即合約.md` 設計前審計 loop 表「機械 refcheck」列。

## 相關
- 設計稿:`docs/design/2026-07-02-spec-refcheck.md`(design-loop 3 輪收斂;qwen disputed 經人裁機械反證後放行)。
- 實作計畫:`docs/superpowers/plans/2026-07-02-spec-refcheck.md`。
```

- [ ] **Step 2: 建 Verification 節點**

`docs/lumos-toolchain-knowledge/Verification/2026-07-02_lumos-refcheck.md`:

```markdown
---
type: verification
status: pass
created: 2026-07-02
updated: 2026-07-02
tags:
  - type/verification
  - status/pass
related:
  - "[[Systems/lumos-refcheck]]"
valid_under: scripts/lumos cmd_refcheck(FENCE_RE/INLINE_CODE_RE 抽取 + (token,line) 去重 + rc 0/1/2);消費端=orchestrator-prompt §2.8/§2.5a + design-loop SKILL 步驟 2.5
revalidate_when: 改 cmd_refcheck 抽取/核對/rc 邏輯;改 Check P 抽取規則(同源複製,需比對分歧是否仍刻意);改 orchestrator-prompt §2 步驟結構
summary: |-
  TEST:t_refcheck 13 checks 全綠(missing/ok+excerpt 精確比對/line_out_of_range/範圍 2-4 首尾行/同檔多行號 4 claims 不塌/目錄型 dir 註記/url·非頂層·無斜線·glob·fenced 全跳/統計欄位/rc 0·1·2/人讀版);全套件 0 failed 無回歸(doctor Check P 行為不變)
  VERIFY:真 spec smoke——refcheck docs/design/2026-07-02-spec-refcheck.md 座標核對可跑
---
# 2026-07-02 lumos-refcheck 驗證

`python3 scripts/test_lumos.py`:t_refcheck 13 checks 全綠,全套件 0 failed(既有測試無回歸)。
真 spec smoke:`./scripts/lumos refcheck docs/design/2026-07-02-spec-refcheck.md --repo .` 正常輸出 manifest 與統計。
消費端接線以 grep 驗證:orchestrator-prompt.md ≥4 處 refcheck 措辭、SKILL.md ≥3 處、methodology/project-notes 各 ≥1。
```

- [ ] **Step 3: lint + doctor + Commit**

Run: `./scripts/lumos lint Systems/lumos-refcheck && ./scripts/lumos lint Verification/2026-07-02_lumos-refcheck`
Expected: 兩檔皆過(無裸合約/格式錯)。

Run: `./scripts/lumos doctor 2>&1 | tail -3`
Expected: `✓ 架構圖健康 — 0 issues`。

```bash
git add docs/lumos-toolchain-knowledge/
git commit -m "kg(refcheck): Systems/lumos-refcheck + Verification 節點"
```

---

## Self-Review

**Spec coverage**(對照 `docs/design/2026-07-02-spec-refcheck.md`):
- §CLI(vault-free、--repo 向上找 .git、rc 2)→ Task 1 Step 3(repo 解析)+ Step 4(pre-Env 分流)。✓
- §抽取規則 step 1-3(Check P 同款 + (token,line) 去重)→ Task 1 Step 3 迴圈,測試案例 7 防塌。✓
- §核對與 manifest(missing/out_of_range/ok、excerpt 單行與範圍首尾、目錄型 dir、line 字串格式、--json、rc)→ Task 1 Step 3 + 測試逐項。✓
- §消費端 ①(步驟 2.8+auditor/judge 措辭)→ Task 2。✓
- §消費端 ②(ground_truth 機械底座+誠實邊界)→ Task 2 Step 4。✓
- §消費端 ③(SKILL 步驟 2.5+(d) 裸檔名)→ Task 3。✓
- §canary 相容性(不驗內部一致性)→ Global Constraints + Task 2/3 措辭明寫 + Systems 節點 KEY。✓
- §邊界(不重執行查證指令/不掃 vault/不當收斂閘/不動 cross_audit.py)→ Global Constraints;計畫無任何對應實作=正確不做。✓
- §測試策略 8 案(missing/ok+excerpt/oor/跳過/範圍/repo 失敗/多行號/回歸)→ t_refcheck 13 checks + 全套件回歸。✓
- §知識同步 6 列 → Task 2(orchestrator)、3(SKILL)、4(methodology×2+project-notes)、5(KG);memory `autonomous-iteration-loop` 由 controller 收尾時更新(非 repo 檔,不入 task)。✓

**Placeholder scan:** 無 TBD/TODO;所有編輯步驟有完整 old/new;測試與實作代碼完整。✓

**Type consistency:** `cmd_refcheck(md_path, repo=None, as_json=False)` ↔ dispatch `cmd_refcheck(args.md, repo=args.refcheck_repo, as_json=args.as_json)` ↔ subparser dest 一致;manifest schema 測試斷言(`token`/`line`/`status`/`excerpt`/`dir`/`missing`/`out_of_range`/`ok`)與實作 dict 鍵一致;Task 2/3 引用的 CLI 字面與 Task 1 註冊一致。✓
