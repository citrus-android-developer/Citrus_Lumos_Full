---
type: project
status: done
created: 2026-07-17
updated: 2026-07-17
tags:
  - type/project
  - status/done
related:
  - "[[test-layers軟提醒_計劃]]"
plan_refs:
  - "[[test-layers軟提醒_計劃]]"
summary: |-
  KEY:test-layers 軟提醒 TDD 實作計畫(設計權威=[[test-layers軟提醒_計劃]]);4 task=T1 純函式(config 載入+棧命中)/T2 cmd_test_layers 子命令+argparse/T3 pre-push advisory 段+anchor approve/T4 code-loop skill 鏡頭併入+架構圖收尾
  KEY:鐵則——恆 rc 0(advisory 不得變硬:無宣告檔靜默/解析失敗 fail-open/git 失敗 stderr 診斷+rc0);pre-push 呼叫 `|| true` 雙保險;唯一 rc 2=缺 --diff 參數(用法錯誤)
  KEY:復用錨點——config 載入鏡像 _lint_load_config(scripts/lumos:6521)/棧命中鏡像 _lint_stacks_for_diff 的「副檔名 lstrip('.') 對 key」語意(:6534)/argparse 註冊區 :9203/dispatch :9287/測試 t_* 自動收集(test_lumos.py main :9040)
  KEY:pre-push 是 anchor 保護檔——T3 改完必 `lumos anchor approve --note`,否則自己擋自己
  DECISION:[2026-07-17]跳 design-loop 並註明:宣告檔解析+列印+prompt 併入純 glue 層,無深演算法——實作真測 > 設計散文(同 code-loop必用守衛 前例);終審按 pitfalls --diff 分流(valid)
---
# test-layers 軟提醒 Implementation Plan

> **REQUIRED SUB-SKILL:** superpowers:subagent-driven-development 或 executing-plans 逐 task 執行。**設計權威**:[[test-layers軟提醒_計劃]],規格衝突以該節點為準。

**Goal:** diff 命中專案宣告的棧 → push 前軟提醒「該跑的測試層」,恆不影響 rc。

**Architecture:** 新 `lumos test-layers` 子命令(vault-free,鏡像 pitfalls 的 config 載入/棧比對語意)+ pre-push 尾段 advisory 呼叫 + code-loop skill 一段鏡頭文字。零新依賴、opt-in、fail-open。

**Tech Stack:** python3 stdlib(scripts/lumos 單檔)、bash(scripts/hooks/pre-push)、markdown(SKILL.md)。

## Global Constraints
- 零外部依賴(python3 stdlib only);單檔 scripts/lumos,函式前綴 `_testlayers_`。
- **恆 rc 0**:無宣告檔/解析失敗/git 失敗 → 靜默或 stderr 診斷,絕不 rc≠0;唯一例外=缺 `--diff` 參數 rc 2。
- 宣告檔路徑固定 `.lumos/test-layers.json`;棧 key=副檔名 `lstrip('.')`(與 lint.json 同語意)。
- 測試進 `scripts/test_lumos.py`,函式名 `t_test_layers*`(runner 按 `t_` 前綴自動收集)。
- pre-push 修改後必跑 `lumos anchor approve --note`。

---

### Task 1: 純函式——config 載入 + 棧命中

**Files:**
- Modify: `scripts/lumos`(緊接 `_lint_stacks_for_diff` 之後,約 :6548)
- Test: `scripts/test_lumos.py`(檔尾新增)

**Interfaces:**
- Produces: `_testlayers_load_config(repo_root) -> dict|None`、`_testlayers_hits(files: list[str], config: dict) -> list[tuple[str, dict, int]]`(key, entry, 命中檔數;去重保序)

- [x] **Step 1: 寫失敗測試**(scripts/test_lumos.py 檔尾)

```python
def t_testlayers_units():
    """test-layers 純函式:config 載入 fail-open + 棧命中去重保序。"""
    import json as _json
    import tempfile
    from pathlib import Path as _P
    sys.path.insert(0, str(_P(__file__).parent))
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "lumos_mod", str(_P(__file__).parent / "lumos"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)

    with tempfile.TemporaryDirectory() as td:
        # 無檔 → None
        assert m._testlayers_load_config(td) is None, "無宣告檔應回 None"
        lp = _P(td) / ".lumos"
        lp.mkdir()
        # 壞 JSON → None(fail-open)
        (lp / "test-layers.json").write_text("{broken", encoding="utf-8")
        assert m._testlayers_load_config(td) is None, "壞 JSON 應 fail-open None"
        # 非 dict 頂層 → None
        (lp / "test-layers.json").write_text("[1,2]", encoding="utf-8")
        assert m._testlayers_load_config(td) is None, "非 dict 應回 None"
        # 正常
        cfg = {"vue": {"layer": "E2E", "cmd": "npx playwright test", "when": "UI 有動"},
               "kt": {"layer": "UI 流程", "cmd": "maestro test flows/"}}
        (lp / "test-layers.json").write_text(_json.dumps(cfg), encoding="utf-8")
        loaded = m._testlayers_load_config(td)
        assert loaded == cfg, "正常 config 應原樣載入"

    # 棧命中:去重保序 + 計數 + 未宣告棧忽略
    files = ["src/A.vue", "src/B.vue", "app/C.kt", "readme.md"]
    hits = m._testlayers_hits(files, cfg)
    assert [h[0] for h in hits] == ["vue", "kt"], f"去重保序錯: {hits}"
    assert hits[0][2] == 2 and hits[1][2] == 1, f"計數錯: {hits}"
    assert m._testlayers_hits(["x.md"], cfg) == [], "未命中應空列表"
    print("  ✓ t_testlayers_units")
```

- [x] **Step 2: 跑測試確認失敗**

Run: `python3 scripts/test_lumos.py 2>&1 | grep -A2 testlayers`
Expected: FAIL(`AttributeError: ... _testlayers_load_config`)

- [x] **Step 3: 最小實作**(scripts/lumos,`_lint_stacks_for_diff` 函式後)

```python
def _testlayers_load_config(repo_root):
    """讀取 repo_root/.lumos/test-layers.json → dict;不存在/解析失敗/非 dict → None(fail-open)。"""
    import json
    p = Path(repo_root) / ".lumos" / "test-layers.json"
    if not p.exists():
        return None
    try:
        with open(p, encoding="utf-8") as f:
            cfg = json.load(f)
        return cfg if isinstance(cfg, dict) else None
    except Exception:
        return None


def _testlayers_hits(files, config):
    """files 副檔名(lstrip '.')比對 config key(語意同 _lint_stacks_for_diff)。
    回傳 [(key, entry, 命中檔數)],key 依首見序去重。"""
    order = []
    counts = {}
    for f in files:
        ext = Path(f).suffix.lstrip(".")
        if ext in config:
            if ext not in counts:
                order.append(ext)
                counts[ext] = 0
            counts[ext] += 1
    return [(k, config[k], counts[k]) for k in order]
```

- [x] **Step 4: 跑測試確認通過**

Run: `python3 scripts/test_lumos.py 2>&1 | tail -3`
Expected: 全綠含 `✓ t_testlayers_units`

- [x] **Step 5: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): test-layers 純函式——宣告檔 fail-open 載入+棧命中去重保序"
```
(pre-commit 會要架構圖同步:本 task 屬計畫執行中,末 task 統一收架構圖——先 `git commit --no-verify` 或把本實作計畫節點 status 改動一併 add;**建議每 commit 都帶上本節點勾選進度,天然滿足 gate**)

---

### Task 2: `cmd_test_layers` 子命令 + argparse 接線

**Files:**
- Modify: `scripts/lumos`(`cmd_pitfalls` 後新增 cmd;argparse 註冊區 :9203 附近;dispatch 區 :9287 附近)
- Test: `scripts/test_lumos.py`

**Interfaces:**
- Consumes: Task 1 的 `_testlayers_load_config` / `_testlayers_hits`
- Produces: `cmd_test_layers(diff=None, repo=None, as_json=False) -> int`;CLI `lumos test-layers --diff <range> [--repo R] [--json]`;JSON shape `{"hits":[{"stack","files","layer","cmd","when"}]}`

- [x] **Step 1: 寫失敗測試**(e2e:臨時 git repo + subprocess 跑 CLI)

```python
def t_testlayers_cmd():
    """test-layers CLI:命中提醒/無宣告靜默/rc 恆 0/缺 --diff rc2。"""
    import json as _json
    import subprocess as _sp
    import tempfile
    from pathlib import Path as _P
    lumos_bin = str(_P(__file__).parent / "lumos")

    def run(args, cwd):
        return _sp.run([sys.executable, lumos_bin] + args,
                       cwd=cwd, capture_output=True, text=True, timeout=60)

    with tempfile.TemporaryDirectory() as td:
        _sp.run(["git", "init", "-q"], cwd=td, check=True)
        _sp.run(["git", "-c", "user.email=t@t", "-c", "user.name=t",
                 "commit", "-q", "--allow-empty", "-m", "base"], cwd=td, check=True)
        (_P(td) / "A.vue").write_text("<template/>", encoding="utf-8")
        (_P(td) / "b.py").write_text("x=1", encoding="utf-8")
        _sp.run(["git", "add", "-A"], cwd=td, check=True)
        _sp.run(["git", "-c", "user.email=t@t", "-c", "user.name=t",
                 "commit", "-q", "-m", "c1"], cwd=td, check=True)

        # 無宣告檔 → 靜默 rc 0
        r = run(["test-layers", "--diff", "HEAD~1..HEAD", "--repo", td], td)
        assert r.returncode == 0 and r.stdout.strip() == "", f"無宣告應靜默rc0: {r.returncode}/{r.stdout!r}"

        # 有宣告 → 命中 vue、忽略 py;rc 0
        lp = _P(td) / ".lumos"; lp.mkdir()
        (lp / "test-layers.json").write_text(_json.dumps(
            {"vue": {"layer": "E2E", "cmd": "npx playwright test", "when": "UI 有動"}}),
            encoding="utf-8")
        r = run(["test-layers", "--diff", "HEAD~1..HEAD", "--repo", td, "--json"], td)
        assert r.returncode == 0, f"rc 應 0: {r.returncode} {r.stderr}"
        hits = _json.loads(r.stdout)["hits"]
        assert len(hits) == 1 and hits[0]["stack"] == "vue" and hits[0]["files"] == 1, hits

        # 人讀輸出含提醒行
        r = run(["test-layers", "--diff", "HEAD~1..HEAD", "--repo", td], td)
        assert "test-layers 軟提醒" in r.stdout and "npx playwright test" in r.stdout, r.stdout

        # 壞 range → rc 0 + stderr 診斷(fail-open)
        r = run(["test-layers", "--diff", "nosuch..HEAD", "--repo", td], td)
        assert r.returncode == 0, f"git 失敗應 fail-open rc0: {r.returncode}"

        # 缺 --diff → rc 2
        r = run(["test-layers", "--repo", td], td)
        assert r.returncode == 2, f"缺 --diff 應 rc2: {r.returncode}"
    print("  ✓ t_testlayers_cmd")
```

- [x] **Step 2: 跑測試確認失敗**

Run: `python3 scripts/test_lumos.py 2>&1 | grep -B1 -A3 testlayers_cmd`
Expected: FAIL(argparse `invalid choice: 'test-layers'`)

- [x] **Step 3: 實作 cmd + 接線**

`cmd_pitfalls` 函式之後新增:

```python
def cmd_test_layers(diff=None, repo=None, as_json=False):
    """test-layers 軟提醒(vault-free,恆 rc 0):diff 命中 .lumos/test-layers.json 宣告棧
    → 印「該跑的測試層」提醒。無宣告檔靜默;git/解析失敗 fail-open(stderr 診斷+rc 0)。
    唯一 rc 2=缺 --diff(用法錯誤)。設計:[[test-layers軟提醒_計劃]]。"""
    import json
    import subprocess
    if not diff:
        print("ERROR: test-layers 需 --diff <range>", file=sys.stderr)
        return 2
    repo_root = _anchor_repo_root(repo)
    if repo_root is None:
        print("test-layers: 找不到 repo root,跳過提醒", file=sys.stderr)
        return 0
    cfg = _testlayers_load_config(repo_root)
    if cfg is None:
        if as_json:
            print(json.dumps({"hits": []}, ensure_ascii=False))
        return 0
    try:
        r = subprocess.run(["git", "diff", "--name-only", diff],
                           cwd=str(repo_root), capture_output=True, text=True, timeout=30)
        if r.returncode != 0:
            print(f"test-layers: git diff rc={r.returncode},跳過提醒", file=sys.stderr)
            if as_json:
                print(json.dumps({"hits": []}, ensure_ascii=False))
            return 0
        files = [ln.strip() for ln in r.stdout.splitlines() if ln.strip()]
    except Exception as e:
        print(f"test-layers: git diff 失敗({e}),跳過提醒", file=sys.stderr)
        return 0
    hits = _testlayers_hits(files, cfg)
    norm = []
    for k, e, n in hits:
        e = e if isinstance(e, dict) else {}
        norm.append({"stack": k, "files": n, "layer": e.get("layer", ""),
                     "cmd": e.get("cmd", ""), "when": e.get("when", "")})
    if as_json:
        print(json.dumps({"hits": norm}, ensure_ascii=False))
        return 0
    if not norm:
        return 0
    print("💡 test-layers 軟提醒(不擋):")
    for h in norm:
        line = f"   diff 碰到 {h['stack']}({h['files']} 檔) → 宣告的 {h['layer'] or '?'} 層"
        if h["cmd"]:
            line += f":{h['cmd']}"
        print(line)
        if h["when"]:
            print(f"     時機:{h['when']}")
    print("   跑了嗎?沒跑的話這是 push 前最後一次便宜的提醒點。")
    return 0
```

argparse 註冊(`sub.add_parser("pitfalls", ...)` 區塊後):

```python
    p = sub.add_parser("test-layers", help="測試層軟提醒(vault-free,恆 rc0):diff 命中 .lumos/test-layers.json 宣告棧 → 提醒該跑的測試層")
    p.add_argument("--diff", dest="tl_diff", help="diff range(如 main..HEAD)")
    p.add_argument("--repo", dest="tl_repo", help="repo root(預設 cwd 向上找 .git)")
    p.add_argument("--json", dest="tl_json", action="store_true", help="JSON 輸出")
```

dispatch(`if args.cmd == "pitfalls":` 之後):

```python
    if args.cmd == "test-layers":
        return cmd_test_layers(diff=args.tl_diff, repo=args.tl_repo, as_json=args.tl_json)
```

- [x] **Step 4: 跑測試確認通過**

Run: `python3 scripts/test_lumos.py 2>&1 | tail -3`
Expected: 全綠含 `✓ t_testlayers_cmd`

- [x] **Step 5: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py docs/lumos-toolchain-knowledge/Projects/test-layers軟提醒_實作計畫.md
git commit -m "feat(lumos): test-layers 子命令——diff 命中宣告棧軟提醒,恆 rc0 fail-open"
```

---

### Task 3: pre-push advisory 段 + anchor approve

**Files:**
- Modify: `scripts/hooks/pre-push`(mb 區塊尾,code-loop check 段之後、`fi` 之前)

**Interfaces:**
- Consumes: Task 2 的 CLI `lumos test-layers --diff <range> --repo <root>`

- [x] **Step 1: 修改 pre-push**——在 `# rc=0(已收斂/skip/tier≠high):放行;rc≠0/1(異常):fail-open 放行` 之後、mb 區塊收尾 `fi` 之前插入:

```bash
  # test-layers 軟提醒(advisory,恆不影響 rc;無 .lumos/test-layers.json 靜默)
  "$PY" "$GRAPHCTL" test-layers --diff "$mb..HEAD" --repo "$REPO_ROOT" 2>/dev/null || true
```

- [x] **Step 2: 語法檢查 + 冒煙**

Run: `bash -n scripts/hooks/pre-push && echo OK`
Expected: `OK`
Run(本 repo 無宣告檔,應無 test-layers 輸出且不影響流程): `python3 scripts/lumos test-layers --diff main~1..main --repo . ; echo "rc=$?"`
Expected: `rc=0`,無 stdout

- [x] **Step 3: anchor approve**(pre-push 是錨點檔,不 approve 會自己擋自己)

Run: `python3 scripts/lumos anchor approve --note "pre-push 加 test-layers 軟提醒段(advisory,|| true 隔離)"`
Expected: approve 成功訊息

- [x] **Step 4: Commit**

```bash
git add scripts/hooks/pre-push docs/.governance-log.jsonl
git commit -m "feat(hooks): pre-push 追加 test-layers 軟提醒段(恆 rc0,|| true 隔離)"
```
(anchor baseline 檔若有變動一併 add;確切檔名以 `git status` 為準)

---

### Task 4: code-loop skill 鏡頭併入 + 架構圖收尾

**Files:**
- Modify: `skills/lumos-code-loop/SKILL.md`(步驟 3「impact 鏡頭」段後)
- Create: `docs/lumos-toolchain-knowledge/Verification/2026-07-17_test-layers軟提醒.md`(lumos new verification;已建立)
- Modify: 本節點與 [[test-layers軟提醒_計劃]](status/勾選/verified_by)

- [x] **Step 1: SKILL.md 併入**——`**impact 鏡頭**:...` 段落之後加:

```markdown
**test-layers 鏡頭(有宣告才附)**:派前跑 `lumos test-layers --diff <range> --json`,`hits` 非空 → 附給 reviewer:「diff 碰到 <棧> 且專案宣告 <層> 測試(<cmd>)——判斷此改動需不需要補/跑該層;需要而缺 → 列 finding(severity 依風險自判)」。無宣告檔則略過此鏡頭。
```

- [x] **Step 2: 建 Verification 節點**

```bash
python3 scripts/lumos new verification $(date +%Y-%m-%d)_test-layers軟提醒
```
內文必填:`plan_refs` 指 `[[test-layers軟提醒_計劃]]` 與本實作計畫、`valid_under`(如「cmd_test_layers 簽名/宣告檔 schema 不變」)、`revalidate_when`(「test-layers.json schema 改動/pre-push 呼叫段改動」)、TEST 行記全量測試數;同步 `lumos append Projects/test-layers軟提醒_計劃 verified_by "[[Verification/<日期>_test-layers軟提醒]]"`。

- [x] **Step 3: 收尾**

```bash
python3 scripts/lumos set Projects/test-layers軟提醒_計劃 status done
python3 scripts/lumos set Projects/test-layers軟提醒_實作計畫 status done
python3 scripts/lumos lint Projects/test-layers軟提醒_計劃
python3 scripts/lumos doctor
```
Expected: lint 0 問題、doctor 0 issues

- [x] **Step 4: 終審 + Commit**

```bash
python3 scripts/lumos pitfalls --diff main..HEAD --no-lint   # 看尾行 tier
# tier=high → 跑 lumos-code-loop;standard → 單 reviewer 審過即可
git add -A && git commit -m "feat(skill): code-loop 併入 test-layers 鏡頭+架構圖收尾"
```

---

## Self-Review 紀錄
- 規格覆蓋:設計節點四件(宣告檔/棧偵測復用/pre-push advisory/code-loop 鏡頭)→ T1+T2/T2/T3/T4 各有著落;v1 不驗「有沒有真的跑」→ 無對應 task(正確,YAGNI)。
- 恆 rc 0 鐵則在 T2 測試逐條釘(無宣告/壞 range/正常皆 rc0,僅缺 --diff rc2)。
- 型別一致:`_testlayers_hits` 回 `(key, entry, count)`,cmd 內 normalize 為 dict 再印/JSON——T1/T2 簽名互相吻合。
- 真機驗證(消費專案,LandmarkMember 或前端)屬 ship 後行動,記在設計節點下一步,不在本計畫內。
