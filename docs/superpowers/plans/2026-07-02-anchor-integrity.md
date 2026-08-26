# anchor-integrity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增 vault-free 指令 `lumos anchor verify/approve`——對 5 個錨點檔(測試 runner ×2 + 把關 hooks ×3)維護 sha256 baseline,錨點被改而未 approve → verify rc=1;pre-push 與自主 loop 每輪入口接線,讓「測試綠/hook 放行」的前提(驗證器本身沒被動過)變成可機械核對、有留痕的宣稱。

**Architecture:** `cmd_anchor_verify/approve` 進 `scripts/lumos`(同 `cmd_refcheck` 的 pre-Env 分流掛法);baseline 落 `governance/anchor-baseline.json`(checked-in);approve 複用 `_append_governance_log` 留痕(連動改 docstring + gov mapper 讓 note 可見)。pre-push 在 vault 閘門**之前**插 verify(repo 層,無 vault 也要跑);autonomous-loop.sh 在**每輪派 orchestrator 前**插 verify(errexit-safe,missing baseline 對 loop 硬擋)。

**Tech Stack:** Python 3 stdlib(hashlib/json 函數內 import——codebase 慣例);bash(hook/loop 接線);測試沿用 `scripts/test_lumos.py` harness(`run()`/`check()`/`_mk_git_vault`)。

**Branch:** 在 `feat/anchor-integrity` 分支上實作。

## Global Constraints

- stdlib only;Python ≥3.8。
- **錨點集合 v1 固定列舉 5 檔**:`scripts/test_lumos.py`、`scripts/test_autonomous_loop.py`、`scripts/hooks/pre-commit`、`scripts/hooks/pre-push`、`scripts/hooks/post-commit`。**不含 `scripts/lumos` 本體**(spec YAGNI:天天迭代會盲簽疲勞;分層=baseline 守驗證器、測試守被驗物)。
- **rc 語意**:verify 全符 → 0;任一 mismatch/缺檔 → 1;**baseline 不存在 → 0 + 警示**(漸進採用);參數/repo 解析失敗 → 2。approve 成功 → 0;`--note` 缺/空 → 2。
- **vault-free 語意**:CLI 不吃 `--vault` 才算(全域 `--vault` flag 仍可用);approve 取 vault **優先 `args.vault`**、後備 `find_vault(Path.cwd())`;無 vault → baseline 照寫、gov-log 跳過並印警示(留痕降級要喊出來)。
- **governance-log 連動(spec 明列,不是靜默擴權)**:`_append_governance_log` docstring「doctor --ci 唯一寫者」→「寫者=doctor --ci + anchor approve」;gov mapper 的 `.governance-log.jsonl` `"detail": ""` → `d.get("note","")`(**向後相容**:doctor 事件無 note 鍵、顯示不變)。
- **pre-push 插點**:環境檢查(無 python3/lumos 降級放行)之後、vault 閘門(`have_vault` exit 0)**之前**——不得被 vault 存在性短路。
- **loop 入口比 pre-push 嚴**:missing baseline 視同失敗硬擋;接線必須 **errexit-safe**(`set -euo pipefail` 下用 `if ! …; then …; exit 1; fi`,LINE 通知沿檔內 `|| true` 慣例)。
- **不做**:簽名/密鑰、語意掃描、動 doctor、擋 `--no-verify`(spec YAGNI 全列)。
- **自指注意**:pre-push 自己是錨點——改 pre-push 接線與 `anchor approve` 產的 baseline **同一 commit** 進版,否則守衛自擋。

---

### Task 1: `cmd_anchor_verify/approve` + CLI + governance-log 連動 + 測試

**Files:**
- Modify: `scripts/lumos`(四處:`def cmd_refcheck` 前加常數+helper+兩個 cmd 函數;refcheck subparser 後加 anchor subparser;refcheck dispatch 後加 anchor dispatch;`_append_governance_log` docstring;gov mapper `detail`)
- Test: `scripts/test_lumos.py`(新增 `_mk_anchor_repo` + `t_anchor`)

**Interfaces:**
- Consumes(皆既有):`_append_governance_log(vault, events)`(`scripts/lumos:335`,events dict 任意鍵會被 merge 進 jsonl)、`find_vault`、`Path`/`sys`/`re`;測試側 `_mk_git_vault()`(`scripts/test_lumos.py:1331`,回 (root, vault),含 git init + initial commit)。
- Produces:`cmd_anchor_verify(repo=None, as_json=False) -> int`、`cmd_anchor_approve(repo=None, note=None, vault=None) -> int`、常數 `ANCHOR_FILES`(list)、helper `_anchor_repo_root(repo)`;CLI `lumos anchor verify [--repo] [--json]` / `lumos anchor approve [--repo] --note "<理由>"`。Task 2 的 hook/loop 接線引用的指令字面即此。

- [ ] **Step 1: Write the failing test**

加到 `scripts/test_lumos.py`(模組層,任意既有 `t_` 函數之後):

```python
def _mk_anchor_repo():
    """_mk_git_vault(git repo + docs/kg vault + initial commit)疊 5 個假錨點檔。"""
    root, vault = _mk_git_vault()
    (root / "scripts" / "hooks").mkdir(parents=True)
    for rel in ("scripts/test_lumos.py", "scripts/test_autonomous_loop.py",
                "scripts/hooks/pre-commit", "scripts/hooks/pre-push",
                "scripts/hooks/post-commit"):
        (root / rel).write_text(f"# fake {rel}\n", encoding="utf-8")
    return root, vault


def t_anchor():
    import json as _json
    root, vault = _mk_anchor_repo()
    bp = root / "governance" / "anchor-baseline.json"

    # baseline 不存在 → rc 0 + 警示(漸進採用)
    r = run(vault, "anchor", "verify", "--repo", str(root))
    check("anchor: 無 baseline rc=0 且警示未啟用", r.returncode == 0 and "未啟用" in r.stdout,
          f"rc={r.returncode}\n{r.stdout}")

    # approve 缺 --note → argparse rc=2
    r = run(vault, "anchor", "approve", "--repo", str(root))
    check("anchor: approve 缺 --note rc=2", r.returncode == 2, f"rc={r.returncode}\n{r.stderr}")

    # approve → baseline 建立(5 錨點 + note),verify rc=0
    r = run(vault, "anchor", "approve", "--repo", str(root), "--note", "初始")
    check("anchor: approve rc=0", r.returncode == 0, f"rc={r.returncode}\n{r.stdout}\n{r.stderr}")
    data = _json.loads(bp.read_text(encoding="utf-8"))
    check("anchor: baseline 5 錨點+note+version",
          len(data["anchors"]) == 5 and data["note"] == "初始" and data["version"] == 1,
          bp.read_text(encoding="utf-8"))
    r = run(vault, "anchor", "verify", "--repo", str(root))
    check("anchor: approve 後 verify rc=0", r.returncode == 0, f"rc={r.returncode}\n{r.stdout}")

    # governance-log 留痕(gate=anchor-approve,note 進 lumos gov 顯示)
    gl = root / "docs" / ".governance-log.jsonl"
    check("anchor: gov-log 有 anchor-approve 事件",
          gl.exists() and "anchor-approve" in gl.read_text(encoding="utf-8"),
          gl.read_text(encoding="utf-8") if gl.exists() else "無檔")
    r = run(vault, "gov")
    check("anchor: lumos gov 顯示 approve note", "初始" in r.stdout, r.stdout)

    # 改一檔 → verify rc=1 且列出該檔;--json mismatches 精確
    (root / "scripts" / "hooks" / "pre-push").write_text("# tampered\n", encoding="utf-8")
    r = run(vault, "anchor", "verify", "--repo", str(root))
    check("anchor: 改檔 verify rc=1 且列出", r.returncode == 1 and "scripts/hooks/pre-push" in r.stdout,
          f"rc={r.returncode}\n{r.stdout}")
    r = run(vault, "anchor", "verify", "--repo", str(root), "--json")
    d = _json.loads(r.stdout)
    check("anchor: --json ok=false 且 mismatch 指名",
          d["ok"] is False and any(m["file"] == "scripts/hooks/pre-push" for m in d["mismatches"]),
          r.stdout)

    # 缺檔 → rc=1
    (root / "scripts" / "hooks" / "pre-push").unlink()
    r = run(vault, "anchor", "verify", "--repo", str(root))
    check("anchor: 缺檔 verify rc=1", r.returncode == 1 and "缺檔" in r.stdout,
          f"rc={r.returncode}\n{r.stdout}")

    # 重 approve(容忍缺檔:警示 + 只寫存在的 4 個)→ verify 回 0
    r = run(vault, "anchor", "approve", "--repo", str(root), "--note", "重簽")
    check("anchor: 缺檔重 approve rc=0 帶警示", r.returncode == 0 and "缺失" in r.stdout,
          f"rc={r.returncode}\n{r.stdout}")
    data = _json.loads(bp.read_text(encoding="utf-8"))
    check("anchor: 重簽後 baseline 4 錨點", len(data["anchors"]) == 4, str(data["anchors"].keys()))
    r = run(vault, "anchor", "verify", "--repo", str(root))
    check("anchor: 重簽後 verify rc=0", r.returncode == 0, f"rc={r.returncode}\n{r.stdout}")

    # --repo 解析失敗 → rc=2
    r = run(vault, "anchor", "verify", "--repo", str(root / "nope"))
    check("anchor: --repo 不存在 rc=2", r.returncode == 2, f"rc={r.returncode}")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "anchor"`
Expected: FAIL——argparse `invalid choice: 'anchor'`,各 check ✗。

- [ ] **Step 3: Implement `cmd_anchor_*`**

Edit `scripts/lumos`,在 `def cmd_refcheck(md_path, repo=None, as_json=False):` **正上方**插入:

```python
ANCHOR_FILES = [
    "scripts/test_lumos.py",
    "scripts/test_autonomous_loop.py",
    "scripts/hooks/pre-commit",
    "scripts/hooks/pre-push",
    "scripts/hooks/post-commit",
]
_ANCHOR_BASELINE_REL = "governance/anchor-baseline.json"


def _anchor_repo_root(repo):
    """--repo 顯式優先;省略時 cwd 逐層向上找 .git(同 refcheck 慣例)。失敗印錯回 None。"""
    if repo is not None:
        p = Path(repo)
        if not p.is_dir():
            print(f"ERROR: --repo 不是目錄: {repo}", file=sys.stderr)
            return None
        return p
    for cand in (Path.cwd(), *Path.cwd().parents):
        if (cand / ".git").exists():
            return cand
    print("ERROR: cwd 逐層向上找不到 .git repo,請用 --repo 指定", file=sys.stderr)
    return None


def cmd_anchor_verify(repo=None, as_json=False):
    """錨點完整性核對:baseline 內每個錨點檔算 sha256 比對。
    全符 rc=0;mismatch/缺檔 rc=1;baseline 不存在 rc=0+警示(漸進採用);參數錯 rc=2。
    只證「驗證器檔案沒被動過」,不證測試本身寫得對(spec 誠實天花板)。"""
    import json
    import hashlib
    repo_root = _anchor_repo_root(repo)
    if repo_root is None:
        return 2
    bp = repo_root / _ANCHOR_BASELINE_REL
    if not bp.exists():
        print("anchor: baseline 不存在(未啟用)——`lumos anchor approve --note` 建立後生效")
        return 0
    try:
        data = json.loads(bp.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        print(f"ERROR: baseline 讀取失敗: {e}", file=sys.stderr)
        return 2
    mismatches = []
    for rel, expected in sorted(data.get("anchors", {}).items()):
        f = repo_root / rel
        if not f.is_file():
            mismatches.append({"file": rel, "expected": expected, "actual": "(缺檔)"})
            continue
        actual = hashlib.sha256(f.read_bytes()).hexdigest()
        if actual != expected:
            mismatches.append({"file": rel, "expected": expected, "actual": actual})
    if as_json:
        print(json.dumps({"ok": not mismatches, "mismatches": mismatches}, ensure_ascii=False))
    elif mismatches:
        print("✗ anchor verify 失敗——驗證器檔案與 baseline 不符:")
        for m in mismatches:
            act = m["actual"] if m["actual"] == "(缺檔)" else m["actual"][:16] + "…"
            print(f"  {m['file']}(期望 {m['expected'][:16]}… 實際 {act})")
        print("非刻意 → git checkout 還原;刻意改錨點 → lumos anchor approve --note \"理由\"")
    else:
        print(f"✓ anchor verify — {len(data.get('anchors', {}))} 個錨點全符")
    return 1 if mismatches else 0


def cmd_anchor_approve(repo=None, note=None, vault=None):
    """重算全部錨點 sha256 寫回 baseline + governance-log 留痕(anchor-approve 事件)。
    改錨點檔的唯一合法路徑;--note 必填(空理由=無資訊留痕)。"""
    import json
    import hashlib
    import datetime
    if not note or not note.strip():
        print("ERROR: --note 必填(留痕理由)", file=sys.stderr)
        return 2
    repo_root = _anchor_repo_root(repo)
    if repo_root is None:
        return 2
    anchors, absent = {}, []
    for rel in ANCHOR_FILES:
        f = repo_root / rel
        if f.is_file():
            anchors[rel] = hashlib.sha256(f.read_bytes()).hexdigest()
        else:
            absent.append(rel)
    if absent:
        print(f"⚠ 錨點檔缺失(不入 baseline): {', '.join(absent)}")
    bp = repo_root / _ANCHOR_BASELINE_REL
    prev = {}
    if bp.exists():
        try:
            prev = json.loads(bp.read_text(encoding="utf-8")).get("anchors", {})
        except (OSError, ValueError):
            prev = {}
    changed = sorted({k for k in anchors if anchors[k] != prev.get(k)} | (set(prev) - set(anchors)))
    bp.parent.mkdir(parents=True, exist_ok=True)
    payload = {"version": 1, "anchors": anchors,
               "approved_at": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
               "note": note}
    bp.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    v = vault or find_vault(Path.cwd())
    if v is None:
        print("⚠ 無 vault:baseline 已寫,governance-log 留痕跳過")
    else:
        _append_governance_log(v, [{"gate": "anchor-approve", "kind": "approved",
                                    "hard": False, "nodes": changed, "note": note}])
    print(f"✓ anchor approve — {len(anchors)} 個錨點寫入 baseline({len(changed)} 個變更)")
    return 0
```

- [ ] **Step 4: CLI 註冊 + pre-Env dispatch + governance-log 連動兩處**

(4a) subparser——refcheck 塊之後、`args = ap.parse_args()` 之前。Edit `scripts/lumos`:

old:
```python
    p.add_argument("--json", dest="as_json", action="store_true", help="輸出 JSON manifest")

    args = ap.parse_args()
```
new:
```python
    p.add_argument("--json", dest="as_json", action="store_true", help="輸出 JSON manifest")

    p = sub.add_parser("anchor", help="錨點完整性(vault-free):測試 runner/把關 hooks 的 sha256 baseline")
    asub = p.add_subparsers(dest="anchor_cmd", required=True)
    av = asub.add_parser("verify", help="比對錨點 sha256 vs baseline;不符 rc=1(baseline 不存在 rc=0+警示)")
    av.add_argument("--repo", dest="anchor_repo", help="repo root(預設 cwd 逐層向上找 .git)")
    av.add_argument("--json", dest="as_json", action="store_true", help="輸出 JSON")
    aa = asub.add_parser("approve", help="重算錨點 hash 寫回 baseline + governance-log 留痕(改錨點的合法路徑)")
    aa.add_argument("--repo", dest="anchor_repo", help="repo root(預設 cwd 逐層向上找 .git)")
    aa.add_argument("--note", required=True, help="一句話理由(必填,進留痕)")

    args = ap.parse_args()
```

(4b) dispatch——refcheck 分支之後、`vault = args.vault or find_vault(Path.cwd())` 之前。Edit `scripts/lumos`:

old:
```python
    if args.cmd == "refcheck":
        return cmd_refcheck(args.md, repo=args.refcheck_repo, as_json=args.as_json)

    vault = args.vault or find_vault(Path.cwd())
```
new:
```python
    if args.cmd == "refcheck":
        return cmd_refcheck(args.md, repo=args.refcheck_repo, as_json=args.as_json)
    if args.cmd == "anchor":
        if args.anchor_cmd == "verify":
            return cmd_anchor_verify(repo=args.anchor_repo, as_json=args.as_json)
        return cmd_anchor_approve(repo=args.anchor_repo, note=args.note, vault=args.vault)

    vault = args.vault or find_vault(Path.cwd())
```

(4c) `_append_governance_log` docstring(宣稱變更,spec 明列)。Edit `scripts/lumos`:

old:
```python
    """doctor --ci 唯一寫者:把本輪 gate findings append 到 docs/.governance-log.jsonl。
```
new:
```python
    """寫者=doctor --ci + anchor approve:把 gate findings append 到 docs/.governance-log.jsonl。
```

(4d) gov mapper note 可見性(向後相容:doctor 事件無 note 鍵 → "" 不變)。Edit `scripts/lumos`:

old:
```python
    load(".governance-log.jsonl", lambda d: {"ts": d.get("ts", ""), "commit": d.get("commit", ""),
         "gate": d.get("gate", "?"), "kind": d.get("kind", "?"), "hard": bool(d.get("hard")),
         "nodes": [stem(x) for x in d.get("nodes", [])], "detail": ""})
```
new:
```python
    load(".governance-log.jsonl", lambda d: {"ts": d.get("ts", ""), "commit": d.get("commit", ""),
         "gate": d.get("gate", "?"), "kind": d.get("kind", "?"), "hard": bool(d.get("hard")),
         "nodes": [stem(x) for x in d.get("nodes", [])], "detail": d.get("note", "")})
```

- [ ] **Step 5: Run tests to verify pass + 回歸**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "anchor"`
Expected: `t_anchor` 13 checks 全 ✓。

Run: `python3 scripts/test_lumos.py 2>&1 | tail -2`
Expected: `N passed, 0 failed`(N ≥ 307 = 294 + 13);既有 `t_governance_log_write`(gov-log 寫者)與 gov 顯示測試零回歸。

- [ ] **Step 6: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): anchor verify/approve——錨點完整性 sha256 baseline + 治理帳留痕"
```

---

### Task 2: pre-push + 自主 loop 入口接線 + 真 repo 初始 baseline

**Files:**
- Modify: `scripts/hooks/pre-push`(環境檢查後、vault 閘門前插 verify)
- Modify: `governance/autonomous-loop.sh`(while 迴圈內、每輪派 orchestrator 前插 verify)
- Create: `governance/anchor-baseline.json`(跑 `lumos anchor approve` 產生,進版)

**Interfaces:**
- Consumes: Task 1 的 CLI 字面 `lumos anchor verify` / `lumos anchor approve --note`;pre-push 既有變數 `$PY`/`$GRAPHCTL`;autonomous-loop.sh 既有 `$REPO`/`log()`/line_notify 呼叫慣例。
- Produces: 上線的兩道接線 + 首個 baseline(含改過的 pre-push 自身 hash——自指,同 commit 進版)。

- [ ] **Step 1: pre-push 插 verify(vault 閘門之前)**

Edit `scripts/hooks/pre-push`:

old:
```bash
# 只在 vault 存在時跑
have_vault=0
```
new:
```bash
# 錨點完整性:驗證器(runner/hooks)沒被動過,後面的「doctor 過/測試綠」才可信(repo 層,vault 無關)
if ! "$PY" "$GRAPHCTL" anchor verify; then
  {
    echo ""
    echo "🚫 pre-push: anchor verify 失敗——驗證器檔案與 baseline 不符,push 已擋下"
    echo ""
    echo "請選一條:"
    echo "  1. 非刻意改動 → git checkout 還原錨點檔後重 push"
    echo "  2. 刻意改錨點 → lumos anchor approve --note \"理由\" 後重 push"
    echo "  3. 確屬可接受 → git push --no-verify(留 PR diff 與缺 approve 事件的對帳痕)"
    echo ""
  } >&2
  exit 1
fi

# 只在 vault 存在時跑
have_vault=0
```

- [ ] **Step 2: autonomous-loop.sh 每輪派工前插 verify(errexit-safe + 硬擋 missing baseline)**

Edit `governance/autonomous-loop.sh`:

old:
```bash
log "選中 gap:$GAP_JSON"

PROMPT_FILE="$(mktemp)"
```
new:
```bash
log "選中 gap:$GAP_JSON"

# 錨點完整性:驗證器被污染時跑出的「收斂/綠」全是假訊號,寧停。
# loop 入口比 pre-push 嚴:missing baseline 亦硬擋(無人看顧場景無人眼兜底)。
if [ ! -f "$REPO/governance/anchor-baseline.json" ] || ! (cd "$REPO" && python3 scripts/lumos anchor verify); then
  log "錨點完整性失敗(anchor verify 不過或 baseline 缺失),loop 拒跑"
  MSG="⚠ 錨點完整性失敗,自主 loop 拒跑(anchor verify)" python3 -c "
import sys, os; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import line_notify
t='$(cat "$HOME/.config/ai-daily/line_token" 2>/dev/null)'
print('LINE', line_notify.send(line_notify.build_message('anchor-integrity', os.environ['MSG'], None), t) if t else 'no-token')" || true
  exit 1
fi

PROMPT_FILE="$(mktemp)"
```

- [ ] **Step 3: 真 repo 初始 baseline(實錨自測,上線即有效)**

Run:
```bash
./scripts/lumos anchor approve --note "初始 baseline(anchor-integrity 上線,含本次 pre-push 接線)"
./scripts/lumos anchor verify
```
Expected: approve 印 `✓ anchor approve — 5 個錨點寫入 baseline(5 個變更)`;verify rc=0 印 `✓ anchor verify — 5 個錨點全符`。
(approve 在 pre-push 編輯**之後**跑——baseline 記的是接線後的 hash,自指閉合。)

Run: `bash -n scripts/hooks/pre-push && bash -n governance/autonomous-loop.sh`
Expected: 兩檔語法皆過。

- [ ] **Step 4: 接線 smoke(hook 直呼)**

Run: `bash scripts/hooks/pre-push </dev/null; echo "rc=$?"`
Expected: anchor verify 過 → 續跑 doctor --ci → `rc=0`(當前架構圖健康)。

Run(暫時篡改→驗擋→還原):
```bash
echo "# tamper" >> scripts/hooks/post-commit
bash scripts/hooks/pre-push </dev/null; echo "rc=$?"
git checkout -- scripts/hooks/post-commit
```
Expected: 中段印 `✗ anchor verify 失敗` + `🚫 pre-push: anchor verify 失敗`、`rc=1`;還原後無殘留(`git status` 乾淨)。

- [ ] **Step 5: 全套件回歸 + Commit**

Run: `python3 scripts/test_lumos.py 2>&1 | tail -1`
Expected: `N passed, 0 failed`。

```bash
git add scripts/hooks/pre-push governance/autonomous-loop.sh governance/anchor-baseline.json
git commit -m "feat(anchor): pre-push + 自主 loop 入口接線 + 初始 baseline(自指同批進版)"
```
(注意:此 commit 動了 pre-push=錨點,但 baseline 同 commit 帶了新 hash——verify 在 push 時讀的是同批 baseline,不會自擋。commit 若被 pre-commit 架構圖閘擋,依既例 `--no-verify`,架構圖同步歸 Task 4。)

---

### Task 3: 知識同步 — methodology ×3 + lumos-project-notes 指令表

**Files:**
- Modify: `docs/methodology/架構圖即合約.md`(強制力層表加列 + :83 ★COMBO★ 行天花板補後綴)
- Modify: `docs/methodology/架構圖即合約-全景圖.md`(§真錨點補一句)
- Modify: `docs/methodology/架構圖即合約-對外論述.md`(refcheck 段後插白話段)
- Modify: `skills/lumos-project-notes/SKILL.md`(讀取/巡檢表加列 + 全覽行)

**Interfaces:**
- Consumes: Task 1/2 的指令語意(sha256 baseline、approve 留痕、pre-push/loop 入口擋)。
- Produces: 純文檔。

- [ ] **Step 1: 架構圖即合約.md 強制力層表加列**

old(表內既有行,原樣定位):
```
| 治理事件帳 `lumos gov`（2026-06-19） | 查詢時 | 只彙整 | 「四道閘的訊號散落各 hook，無法一次查某節點歷來被哪幾道攔過」——可觀測性 |
```
new:
```
| 錨點完整性 anchor verify（2026-07-02，vault-free） | pre-push / 自主 loop 每輪入口 | 擋 | 「驗證器本身（測試 runner／把關 hooks）被悄悄改成一律通過」——5 錨點 sha256 baseline 比對，改錨點須 `lumos anchor approve --note` 留痕（治理帳 anchor-approve 事件）；「測試綠」的前提（批改程式沒被動過）變成可機械核對的宣稱。天花板：同 repo 守衛悖論——買到的是無痕篡改被封死（必留 baseline diff／缺 approve 事件／bypass 軌跡其一），非不可繞 |
| 治理事件帳 `lumos gov`（2026-06-19） | 查詢時 | 只彙整 | 「四道閘的訊號散落各 hook，無法一次查某節點歷來被哪幾道攔過」——可觀測性 |
```

- [ ] **Step 2: 架構圖即合約.md :83 ★COMBO★ 行天花板補後綴**

old(行尾):
```
天花板:只數標記個數、`[test:a,b]` 算 1 個免逗號繞過、CI 跑才是錨點 |
```
new:
```
天花板:只數標記個數、`[test:a,b]` 算 1 個免逗號繞過、CI 跑才是錨點（錨點自身完整性由 anchor baseline 守,2026-07-02） |
```

- [ ] **Step 3: 全景圖 §真錨點補一句**

old:
```
2. **🎯 真錨點**:不管 AI 審了幾層,真正算數的只有兩件——**把測試真的跑綠**、**最後由人拍板**。
```
new:
```
2. **🎯 真錨點**:不管 AI 審了幾層,真正算數的只有兩件——**把測試真的跑綠**、**最後由人拍板**。而「測試真的跑綠」成立的前提=批改程式沒被動過——`lumos anchor verify`(2026-07-02)把這個前提從盲信變成可機械核對的宣稱(runner/hooks sha256 baseline,pre-push 與自主 loop 入口把關)。
```

- [ ] **Step 4: 對外論述插白話段(refcheck 段之後)**

old(refcheck 段尾到下一段之間):
```
查勤的事交給機器,動腦的事才留給 AI。
```
new:
```
查勤的事交給機器,動腦的事才留給 AI。

沿著同一條思路再往下挖一層:整套流程最底層的信任是「測試跑綠才算數」——但如果**批改考卷的程式本身**被改成一律給過呢?這不是杞人憂天:有人就用這招破了八大權威 AI 評測,在測試框架裡塞一個鉤子把每題都改寫成「通過」,評分器毫無察覺。我的對策是給批改程式拍指紋:把測試程式和把關腳本的雜湊值存成基準檔,推送程式碼前、自動迭代開跑前,先機械比對「批改程式動過沒」;真要改它,必須走一道會留下簽名和理由的核可指令。它防不了鐵了心連指紋一起改的人——但**無痕篡改**從此不存在:任何繞法都必然留下看得見的痕跡,審查的人有明確的紅旗可查。
```

- [ ] **Step 5: lumos-project-notes SKILL.md 表加列 + 全覽行**

(5a) old(讀取/巡檢表內,refcheck 列):
```
| **spec 指涉宣稱機械核對(vault-free)** | `lumos refcheck <md檔> [--repo <root>] [--json]` — 抽 inline-code 檔路徑/行號、核對存在性/行號範圍、輸出證據 manifest(含行內容摘錄);design-loop 審計前先跑,存在性查證不靠 LLM。rc:全 ok=0/有 missing 或超界=1/參數錯=2 |
```
new:
```
| **spec 指涉宣稱機械核對(vault-free)** | `lumos refcheck <md檔> [--repo <root>] [--json]` — 抽 inline-code 檔路徑/行號、核對存在性/行號範圍、輸出證據 manifest(含行內容摘錄);design-loop 審計前先跑,存在性查證不靠 LLM。rc:全 ok=0/有 missing 或超界=1/參數錯=2 |
| **錨點完整性(vault-free)** | `lumos anchor verify [--repo] [--json]`/`lumos anchor approve --note "<理由>"` — 測試 runner+把關 hooks 的 sha256 baseline(`governance/anchor-baseline.json`);verify 不符 rc=1(pre-push/自主 loop 入口擋)、approve=改錨點合法路徑(治理帳留痕)。改測試 runner/hooks 後記得 approve |
```

(5b) old:
```
> **子命令全覽**：讀取/巡檢 13（`doctor` `context` `contracts` `search` `refcheck` `links` `backlinks` `map` `export` `decisions` `stale` `recent` `stats`）+ 寫入 7（`set` `append` `new` `archive` `decision-add` `decision-supersede` `self-audit`）+ 安裝/生命週期 4（`install` `uninstall` `update` `bootstrap`）+ 其餘（`lint` `gov` `canary` `loop` `guard` `sync-verified-by` `init` `deinit` 等）。`lumos --help` 為現行權威。
```
new:
```
> **子命令全覽**：讀取/巡檢 13（`doctor` `context` `contracts` `search` `refcheck` `links` `backlinks` `map` `export` `decisions` `stale` `recent` `stats`）+ 寫入 7（`set` `append` `new` `archive` `decision-add` `decision-supersede` `self-audit`）+ 安裝/生命週期 4（`install` `uninstall` `update` `bootstrap`）+ 其餘（`anchor` `lint` `gov` `canary` `loop` `guard` `sync-verified-by` `init` `deinit` 等）。`lumos --help` 為現行權威。
```

- [ ] **Step 6: 驗證 + Commit**

Run: `grep -c "anchor" docs/methodology/架構圖即合約.md docs/methodology/架構圖即合約-全景圖.md docs/methodology/架構圖即合約-對外論述.md skills/lumos-project-notes/SKILL.md`
Expected: 前兩檔 ≥2、後兩檔 ≥1(對外論述用「基準檔/指紋」白話,grep "指紋" ≥1 亦可)。

```bash
git add docs/methodology/架構圖即合約.md docs/methodology/架構圖即合約-全景圖.md docs/methodology/架構圖即合約-對外論述.md skills/lumos-project-notes/SKILL.md
git commit -m "docs(sync): anchor-integrity 知識同步——強制力表 + 真錨點前提 + 對外白話 + 指令表"
```

---

### Task 4: 架構圖節點 — Systems/anchor-integrity + Verification(收尾,controller 可自跑)

**Files:**
- Create: `docs/lumos-toolchain-knowledge/Systems/anchor-integrity.md`
- Create: `docs/lumos-toolchain-knowledge/Verification/2026-07-02_anchor-integrity.md`

> **鐵則**:只建這兩個節點,不得建其他節點。寫完 `lumos lint` ×2 + `lumos doctor` 必須 0 issues。

- [ ] **Step 1: 建 Systems 節點**

`docs/lumos-toolchain-knowledge/Systems/anchor-integrity.md`:

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
  - "[[Verification/2026-07-02_anchor-integrity]]"
summary: |-
  FLOW:anchor approve --note→5錨點(runner×2+hooks×3) sha256→anchor-baseline.json(checked-in)+治理帳 anchor-approve 事件｜anchor verify→逐錨點比對→mismatch/缺檔 rc1(pre-push 擋、自主 loop 每輪入口硬擋含 missing baseline)
  KEY:守「驗證器本身被悄悄改成一律通過」——測試綠/hook 放行的前提(批改程式沒被動過)從盲信變成可機械核對宣稱;外部實證=八大評測被 conftest 鉤子破
  KEY:刻意不守 scripts/lumos 本體(天天迭代→盲簽疲勞);分層=baseline 守驗證器、測試守被驗物
  KEY:loop 入口比 pre-push 嚴——missing baseline 視同失敗(無人看顧無人眼兜底);pre-push 維持 rc0+警示(漸進採用)
  KEY:誠實天花板——同 repo 守衛悖論:決意繞過者可連守衛一起改;買到的是無痕篡改被封死(必留 baseline diff/缺 approve 事件/bypass 軌跡其一),非不可繞。baseline 自身無自我保護(手改 json 靠對帳抓,v1 人工);core.hooksPath 一行可指走整個 hooks 層(loop 入口 shell 直呼=第二條路,真解留 future CI)
  DEP:[[lumos-refcheck]](vault-free 同型)｜_append_governance_log(寫者宣稱已改:doctor --ci + anchor approve)
  TEST:t_anchor 13 checks(無 baseline 警示/approve 建檔+留痕/gov 顯示 note/改檔+缺檔 rc1/--json/重簽容缺/repo 解析 rc2)
  VERIFY:[[2026-07-02_anchor-integrity]]
decisions:
  - content: 方案 A baseline hash+顯式 approve;否決 RHB 環境硬化(方案 B)與純 diff 標記送審(方案 C)
    context: 本機單人工作流沒有 agent 摸不到的執行面,硬寫隔離=自欺;marker 對 agent 零成本自貼、無內容 hash 底線
    why_chosen: 機械、確定性、零依賴;無痕篡改被封死到只剩「連守衛一起改」,人 review 有明確紅旗;B 留 future 真 CI(baseline 屆時直接複用)
    decided: 2026-07-02
    valid: true
  - content: 錨點集合 v1 固定列舉 5 檔,不含 scripts/lumos 本體
    context: lumos 是自主 loop 天天迭代對象,收進 baseline=每天 approve→盲簽疲勞,守衛立刻形同虛設
    why_chosen: 分層——baseline 守驗證器(runner+hooks),測試守被驗物(lumos 行為);改壞 lumos 由 test_lumos.py 抓,前提「runner 沒被動」正是 baseline 守的
    decided: 2026-07-02
    valid: true
---
# anchor-integrity

`lumos anchor verify/approve`——**錨點完整性守衛**(vault-free):測試 runner 與把關 hooks 的 sha256 baseline + 顯式 approve 留痕。

## 動機
方法論最底層退路「CI 跑真測試、綠才算數」把測試結果當不可造假真值,但 runner/評分器本身可被悄悄改寫(外部實證:八大權威評測被 conftest 鉤子全破)。lumos 自主 loop 的 agent 摸得到整個 repo,同樣風險。

## 接線
- `scripts/hooks/pre-push`:環境檢查後、vault 閘門前(repo 層,無 vault 也跑);rc1 擋 push,訊息三選一(還原/approve/--no-verify 留痕)。
- `governance/autonomous-loop.sh`:每輪 gap 派 orchestrator 前(污染可能發生在當天中途);errexit-safe;missing baseline 硬擋。
- 改錨點的合法路徑=`lumos anchor approve --note`(重算寫回 + 治理帳 `anchor-approve` 事件,note 進 `lumos gov` 顯示)。

## 相關
- 設計稿:`docs/design/2026-07-02-anchor-integrity.md`(design-loop 3 輪、R1 missed 作廢、R2+R3 收斂;qwen endorsed;辯方 4 次全駁倒假 major)。
- 實作計畫:`docs/superpowers/plans/2026-07-02-anchor-integrity.md`。
```

- [ ] **Step 2: 建 Verification 節點**

`docs/lumos-toolchain-knowledge/Verification/2026-07-02_anchor-integrity.md`:

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
  - "[[Systems/anchor-integrity]]"
valid_under: scripts/lumos cmd_anchor_verify/approve(ANCHOR_FILES 5 檔列舉 + sha256 + rc 0/1/2);接線=pre-push vault 閘門前 + autonomous-loop.sh 每輪派工前;governance-log 寫者=doctor --ci + anchor approve
revalidate_when: 改 ANCHOR_FILES 列舉;改 cmd_anchor_* 邏輯;改 pre-push/autonomous-loop.sh 接線段;anchor-baseline.json schema 變更
summary: |-
  TEST:t_anchor 13 checks 全綠(無 baseline rc0 警示/缺 note rc2/approve 建檔 5 錨點+note/verify rc0/gov-log anchor-approve 事件/lumos gov 顯示 note/改檔 rc1 列名/--json 精確/缺檔 rc1/重簽容缺 4 錨點/repo 解析 rc2);全套件 0 failed 無回歸
  VERIFY:真 repo 實錨自測——初始 approve 5 錨點+verify rc0;pre-push 直呼 smoke(乾淨 rc0、篡改 post-commit rc1 擋下、還原乾淨)
---
# 2026-07-02 anchor-integrity 驗證

`python3 scripts/test_lumos.py`:t_anchor 13 checks 全綠,全套件 0 failed(含 t_governance_log_write 無回歸)。
真 repo:`lumos anchor approve --note "初始 baseline"` 寫入 5 錨點、`verify` rc=0;pre-push 直呼 smoke——乾淨 repo rc=0,篡改 `scripts/hooks/post-commit` 後 rc=1 正確擋下,還原後乾淨。
接線語法:`bash -n` 兩檔皆過;loop 入口 errexit-safe 寫法(if ! …)不觸發 set -e 早死。
```

- [ ] **Step 3: lint + doctor + Commit**

Run: `./scripts/lumos lint Systems/anchor-integrity && ./scripts/lumos lint Verification/2026-07-02_anchor-integrity && ./scripts/lumos doctor 2>&1 | tail -2`
Expected: lint ×2 過、doctor `✓ 架構圖健康 — 0 issues`。

```bash
git add docs/lumos-toolchain-knowledge/
git commit -m "kg(anchor-integrity): Systems + Verification 節點"
```

---

## Self-Review

**Spec coverage**(對照 `docs/design/2026-07-02-anchor-integrity.md`):
- §組件 1(baseline json schema:version/anchors/approved_at/note,5 錨點含 post-commit)→ Task 1 Step 3 payload + 測試斷言。✓
- §組件 2(verify/approve rc 語意、baseline 不存在 rc0+警示、--note 必填、vault 優先 --vault 後備 find_vault、無 vault 降級喊出、docstring 連動、gov mapper note 向後相容)→ Task 1 Steps 3-4(4c/4d)。✓
- §組件 3(pre-push 插點=vault 閘門前、訊息三選一、自指同批)→ Task 2 Steps 1/3/5。✓
- §組件 4(loop 每輪派工前、errexit-safe、missing baseline 硬擋、LINE 通知)→ Task 2 Step 2。✓
- §組件 5(測試:_mk_git_vault 慣例、verify 全符/改檔/缺檔、approve 後 verify+gov-log 事件、baseline 不存在)→ Task 1 Step 1 全覆蓋。✓
- §實錨自測(真 repo 首個 baseline+首筆 approve 事件同 PR 進版,無空窗)→ Task 2 Step 3(approve 事件寫本 repo docs/.governance-log.jsonl,gitignored——進版的是 baseline;事件本機可查,合 spec「留痕」語意)。✓
- §YAGNI 5 條(不守 lumos 本體/不簽名/不語意掃描/不動 doctor/不擋 --no-verify)→ Global Constraints,無對應實作=正確。✓
- §知識同步 6 列 → Task 3(methodology ×3 + project-notes);orchestrator-prompt 明列「無需改」✓;memory `lumos-governance-tag-rigor` 由 controller 收尾更新(非 repo 檔)。✓
- §誠實天花板 4 條 → Systems 節點 KEY 行 + 方法論表列天花板欄。✓

**Placeholder scan:** 無 TBD/TODO;所有 code/編輯步驟含完整內容。✓

**Type consistency:** `cmd_anchor_verify(repo, as_json)`/`cmd_anchor_approve(repo, note, vault)` ↔ dispatch 參數 ↔ subparser dest(`anchor_repo`/`as_json`/`note`)一致;測試斷言鍵(`anchors`/`note`/`version`/`ok`/`mismatches[].file`)與實作 payload 一致;Task 2 接線指令字面與 Task 1 CLI 一致;`_ANCHOR_BASELINE_REL` 與 Task 2/4 引用的 `governance/anchor-baseline.json` 一致。✓
