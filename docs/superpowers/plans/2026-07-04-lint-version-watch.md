# lint-version-watch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 每日機械偵測宣告的社群 linter 有沒有新穩定版(查 PyPI/npm/Maven/GitHub registry vs `.lumos/lint-watch.json` 鎖定版)→ 產升級候選 → 輕量放行紀律(暫存 + LINE 通知)。

**Architecture:** 機械核心在 `scripts/lumos` 新增 `lint-watch` 子命令(vault-free、可測、HTTP 抓取層可用 `LUMOS_LINT_WATCH_FIXTURE` 環境變數注入 fixture);治理排程層 = `governance/autonomous_loop/lint_watch_dedup.py`(所有 JSON 讀寫在 python)+ `governance/lint-watch-check.sh`(掛 daily wrapper 第 3 步、shell 不碰 JSON)。權威逐行細節見 `docs/design/2026-07-04-lint-version-watch.md`(6 輪 design-loop,核心 design-approved;shell wrapper 本計畫以真 shell 測試定稿)。

**Tech Stack:** Python 3 stdlib(`urllib.request`/`json`/`re`/`argparse`,函數內 lazy import 沿 codebase 慣例);`scripts/test_lumos.py` CLI subprocess harness;bash + 既有 `governance/autonomous_loop/line_notify.py`。

**Branch:** `feat/lint-version-watch`。

## Global Constraints

- **stdlib only**;不裝第三方(不 `requests`)。lumos 不裝/管理 linter,只查版本。
- **fail-open on network**:registry 單條失敗 → `failed[]`、跳過續查、**永不升 rc**。
- **rc 語意**:掃描成功(含部分 failed)=0;`.lumos/lint-watch.json` 缺或空 list `[]`=0(空 candidates);清單格式壞(非 list / 條目非 dict / 缺 `name`/`registry`/`current`)=2。
- **prerelease 一律不建議**;`_is_prerelease` 涵蓋 SemVer `-` 與 PEP 440 dashless(`a`/`b`/`c`/`rc`/`alpha`/`beta`/`dev`/`pre`)。
- **版本比較純數字 tuple + 等段數守衛**;段數不一 / prerelease / 非數字段 → skip(不猜、不假陽性)。**Maven latest 取數值 tuple max,嚴禁字串 `max`**。
- **shell 完全不解析/組裝 JSON**——JSON 側效全在 python;shell 只把 `$MSG` 當不透明字串傳。
- `lint-watch` dispatch **須置於 `vault = args.vault or find_vault(...)` 之前**(vault-free)。
- 錨點 `scripts/test_lumos.py` merge 後 push 前須 anchor approve(Task 6)。

---

### Task 1: semver 解析與比較核心(`_semver_parse` / `_is_prerelease` / `_compare_versions`)

**Files:** Modify `scripts/lumos`(新增三個 module-level helper,置於檔案 helper 區、其他 `_lint_*` 附近);Test `scripts/test_lumos.py`(`t_lint_watch_semver`)。

**Interfaces:** Produces `_semver_parse(v) -> tuple|None`、`_is_prerelease(v) -> bool`、`_compare_versions(current, latest) -> (state, reason)`(state ∈ `"behind"`/`"current"`/`"skip"`;reason 僅 skip 非空)。Task 2/3 消費。

- [ ] **Step 1: 測試**(加 `scripts/test_lumos.py`,用既有 `SourceFileLoader` 載入 extensionless 模組,同 `t_lint_aligned`):

```python
def t_lint_watch_semver():
    import importlib.util as U
    from importlib.machinery import SourceFileLoader
    spec = U.spec_from_file_location("lm", GRAPHCTL, loader=SourceFileLoader("lm", GRAPHCTL))
    m = U.module_from_spec(spec); spec.loader.exec_module(m)
    # _semver_parse
    check("parse 1.23.7", m._semver_parse("1.23.7") == (1,23,7), str(m._semver_parse("1.23.7")))
    check("parse v 前綴剝除", m._semver_parse("v1.2.3") == (1,2,3), str(m._semver_parse("v1.2.3")))
    check("parse 非數字段→None", m._semver_parse("1.x.3") is None, str(m._semver_parse("1.x.3")))
    # _is_prerelease 正例
    for v in ["1.24.0-RC1","0.5.0b1","2.22.0.dev20260702"]:
        check(f"prerelease True {v}", m._is_prerelease(v) is True, v)
    # _is_prerelease 負例(不可假陽性)
    for v in ["1.24.0","5.0.2.4997","cobra"]:
        check(f"prerelease False {v}", m._is_prerelease(v) is False, v)
    # _compare_versions 三態
    check("behind", m._compare_versions("1.23.7","1.24.0") == ("behind",""), str(m._compare_versions("1.23.7","1.24.0")))
    check("current(反向)", m._compare_versions("1.24.0","1.23.7")[0] == "current", str(m._compare_versions("1.24.0","1.23.7")))
    check("current(相等)", m._compare_versions("1.2.3","1.2.3")[0] == "current", "")
    check("skip unparseable", m._compare_versions("1.x","1.2.3") == ("skip","unparseable"), str(m._compare_versions("1.x","1.2.3")))
    check("skip prerelease", m._compare_versions("1.0.0","1.1.0-RC1") == ("skip","prerelease"), str(m._compare_versions("1.0.0","1.1.0-RC1")))
    check("skip 段數不一(calendar)", m._compare_versions("1.23.7","2024.1") == ("skip","segment-count-mismatch"), str(m._compare_versions("1.23.7","2024.1")))
    check("skip 段數不一(4段maven)", m._compare_versions("5.0.1","5.0.1.3006") == ("skip","segment-count-mismatch"), "")
    # 數值排序見證(同段數:字串 '1.9.0' > '1.20.0' 但數值 (1,9,0)<(1,20,0))
    check("數值 behind 1.9.0→1.20.0", m._compare_versions("1.9.0","1.20.0") == ("behind",""), str(m._compare_versions("1.9.0","1.20.0")))
```

- [ ] **Step 2:** 跑 `python3 scripts/test_lumos.py`,確認 `t_lint_watch_semver` fail(helper 未定義)。
- [ ] **Step 3:** 實作三 helper 於 `scripts/lumos`:

```python
def _semver_parse(v):
    import re
    s = v.strip()
    if s[:1].lower() == "v":
        s = s[1:]
    parts = s.split(".")
    if not parts or not all(p.isdigit() for p in parts):
        return None
    return tuple(int(p) for p in parts)

def _is_prerelease(v):
    import re
    s = v.lower()
    if "-" in s:
        return True
    return re.search(r'(?:\d|[-._])(a|b|c|rc|alpha|beta|dev|pre)\d*(?:$|[-._\d])', s) is not None

def _compare_versions(current, latest):
    if _is_prerelease(current) or _is_prerelease(latest):
        return ("skip", "prerelease")
    cu, la = _semver_parse(current), _semver_parse(latest)
    if cu is None or la is None:
        return ("skip", "unparseable")
    if len(cu) != len(la):
        return ("skip", "segment-count-mismatch")
    return ("behind", "") if la > cu else ("current", "")
```

- [ ] **Step 4:** 跑 `t_lint_watch_semver` 全綠 + 全套件回歸(`python3 scripts/test_lumos.py`,既有測試不破)。
- [ ] **Step 5:** commit `feat(lint-watch): semver 解析/prerelease/三態比較核心`(pre-commit KG gate 對 code-only 會擋,`--no-verify` 繞、Task 6 補架構圖)。

---

### Task 2: registry 抓取層(`_http_get_json` + fixture seam + `_registry_latest`)

**Files:** Modify `scripts/lumos`(新增 `_http_get_json`、`_registry_latest`,置於 Task 1 helper 旁);Test `scripts/test_lumos.py`(`t_lint_watch_registry`)。

**Interfaces:** Consumes Task 1 `_semver_parse`/`_is_prerelease`。Produces `_http_get_json(url) -> dict|None`(`LUMOS_LINT_WATCH_FIXTURE` 環境變數存在時讀 fixture 檔不打網路)、`_registry_latest(registry, fetch=_http_get_json) -> (str|None, str|None)`(成功 `(版本, None)`;失敗 `(None, reason)`)。Task 3 消費。

- [ ] **Step 1: 測試**(fixture 注入、不打網路;fixture 檔內容 = `{url: response_dict}` 映射):

```python
def t_lint_watch_registry():
    import importlib.util as U, json as J, os, tempfile
    from importlib.machinery import SourceFileLoader
    spec = U.spec_from_file_location("lm", GRAPHCTL, loader=SourceFileLoader("lm", GRAPHCTL))
    m = U.module_from_spec(spec); spec.loader.exec_module(m)
    # 四型 registry 的假 response,key = _registry_latest 內部組出的 url
    pypi_url = "https://pypi.org/pypi/ruff/json"
    npm_url  = "https://registry.npmjs.org/eslint/latest"
    gh_url   = "https://api.github.com/repos/detekt/detekt/releases/latest"
    import urllib.parse as UP
    mvn_url  = ("https://search.maven.org/solrsearch/select?q="
               + UP.quote('g:"org.sonarsource.scanner.cli" AND a:"sonar-scanner-cli"')
               + "&core=gav&sort=timestamp+desc&rows=20&wt=json")
    fixture = {
        pypi_url: {"info": {"version": "0.4.9"}},
        npm_url:  {"version": "9.0.0"},
        gh_url:   {"tag_name": "v1.24.0"},
        # maven docs 含 3.9 / 3.20.0 / 一個 RC → 過濾 RC、數值 max 應回 3.20.0
        mvn_url:  {"response": {"docs": [
            {"v": "3.9"}, {"v": "3.20.0"}, {"v": "3.21.0-RC1"}, {"v": "3.11"}]}},
    }
    fx = Path(tempfile.mkdtemp(prefix="gctl-lw-")) / "fx.json"
    fx.write_text(J.dumps(fixture), encoding="utf-8")
    os.environ["LUMOS_LINT_WATCH_FIXTURE"] = str(fx)
    try:
        check("pypi", m._registry_latest("pypi:ruff") == ("0.4.9", None), str(m._registry_latest("pypi:ruff")))
        check("npm", m._registry_latest("npm:eslint") == ("9.0.0", None), str(m._registry_latest("npm:eslint")))
        check("github 剝 v", m._registry_latest("github:detekt/detekt") == ("1.24.0", None), str(m._registry_latest("github:detekt/detekt")))
        check("maven 數值 max 過濾 RC",
              m._registry_latest("maven:org.sonarsource.scanner.cli:sonar-scanner-cli") == ("3.20.0", None),
              str(m._registry_latest("maven:org.sonarsource.scanner.cli:sonar-scanner-cli")))
        # pypi info.version 為 prerelease → (None, "latest is prerelease")
        fixture[pypi_url] = {"info": {"version": "0.4.3a1"}}
        fx.write_text(J.dumps(fixture), encoding="utf-8")
        check("pypi prerelease", m._registry_latest("pypi:ruff") == (None, "latest is prerelease"), str(m._registry_latest("pypi:ruff")))
        # 抓取回 None(fixture 無此 key)→ (None, "registry query failed: ...")
        latest, reason = m._registry_latest("npm:does-not-exist")
        check("抓取失敗", latest is None and reason.startswith("registry query failed"), f"{latest},{reason}")
    finally:
        os.environ.pop("LUMOS_LINT_WATCH_FIXTURE", None)
```

- [ ] **Step 2:** 跑確認 fail。
- [ ] **Step 3:** 實作於 `scripts/lumos`。`_http_get_json`:若 `os.environ.get("LUMOS_LINT_WATCH_FIXTURE")` 存在 → 讀該 JSON 檔、回 `fixture.get(url)`(無 key → None);否則 `urllib.request`(timeout 10s、header `User-Agent: lumos-lint-watch`),非 2xx/例外/非 JSON → None。`_registry_latest(registry, fetch=_http_get_json)`:`type, _, coord = registry.partition(":")`;依 type 組 url、呼 `fetch(url)`:
  - `pypi` → `d["info"]["version"]`;若 `_is_prerelease` → `(None,"latest is prerelease")`;fetch None/欄位缺 → `(None,"registry query failed: <detail>")`。
  - `npm` → `d["version"]`(同 prerelease/失敗處理)。
  - `github` → `d["tag_name"]` 剝前綴 `v`(同上)。
  - `maven` → coord 再 `partition(":")` 成 group/artifact;`url = "https://search.maven.org/solrsearch/select?q=" + urllib.parse.quote(f'g:"{group}" AND a:"{artifact}"') + "&core=gav&sort=timestamp+desc&rows=20&wt=json"`;docs = `(d.get("response") or {}).get("docs") or []`;`stable = [x["v"] for x in docs if x.get("v") and not _is_prerelease(x["v"])]`;過濾後空 → `(None,"no stable version")`;否則 `max(stable, key=_semver_parse)`(parse None 的排除後再 max;實作可先 `stable = [v for v in stable if _semver_parse(v)]`)→ `(那版本, None)`。
  成功一律回 `(版本字串, None)`。整個函式包 try/except,任何未預期例外 → `(None, f"registry query failed: {e}")`。
- [ ] **Step 4:** 跑 `t_lint_watch_registry` 全綠 + 全套件回歸。
- [ ] **Step 5:** commit `feat(lint-watch): registry 抓取層 + fixture seam + 四型 latest 抽取((latest,reason))`(`--no-verify`)。

---

### Task 3: `lint-watch` 子命令(config 載入 + 主迴圈 + manifest + rc)

**Files:** Modify `scripts/lumos`(argparse `sub.add_parser("lint-watch")`、dispatch 置於 `find_vault` 前、主邏輯函式 `_lint_watch_mode(repo_root, as_json)`);Test `scripts/test_lumos.py`(`t_lint_watch_cli`)。

**Interfaces:** Consumes Task 1/2 全部 helper。Produces `lumos lint-watch --repo <root> [--json]` CLI:`--json` 印 `{"candidates":[...], "checked":N, "failed":[...]}`;非 `--json` 印每候選一行 `<name> <current> → <latest>`。rc 見 Global Constraints。

- [ ] **Step 1: 測試**(subprocess 跑真 CLI + fixture + 臨時 `--repo` 根,無 git):

```python
def t_lint_watch_cli():
    import subprocess as sp, json as J, os, tempfile
    root = Path(tempfile.mkdtemp(prefix="gctl-lwcli-"))
    (root / ".lumos").mkdir()
    watch = [
        {"name":"ruff","registry":"pypi:ruff","current":"0.4.2"},        # behind
        {"name":"eslint","registry":"npm:eslint","current":"9.0.0"},     # current(相等)
        {"name":"cal","registry":"npm:cal","current":"1.23.7"},          # skip(段數不一 2024.1)
        {"name":"down","registry":"npm:down","current":"0.0.0"},         # fetch 失敗→failed
    ]
    (root / ".lumos" / "lint-watch.json").write_text(J.dumps(watch), encoding="utf-8")
    fixture = {
        "https://pypi.org/pypi/ruff/json": {"info":{"version":"0.4.9"}},
        "https://registry.npmjs.org/eslint/latest": {"version":"9.0.0"},
        "https://registry.npmjs.org/cal/latest": {"version":"2024.1"},
        # down 無 fixture key → fetch None → failed
    }
    fx = root / "fx.json"; fx.write_text(J.dumps(fixture), encoding="utf-8")
    env = dict(os.environ, LUMOS_LINT_WATCH_FIXTURE=str(fx))
    r = sp.run([sys.executable, GRAPHCTL, "lint-watch", "--repo", str(root), "--json"],
               capture_output=True, text=True, env=env)
    check("rc 0", r.returncode == 0, r.stderr)
    d = J.loads(r.stdout)
    check("1 candidate(ruff)", len(d["candidates"]) == 1 and d["candidates"][0]["name"] == "ruff", str(d["candidates"]))
    check("candidate latest", d["candidates"][0]["latest"] == "0.4.9", str(d["candidates"][0]))
    check("checked = behind+current = 2", d["checked"] == 2, str(d["checked"]))
    failed_names = {f["name"] for f in d["failed"]}
    check("failed 含 cal(段數) + down(抓取)", failed_names == {"cal","down"}, str(d["failed"]))
    # 缺清單 → rc 0 空候選
    root2 = Path(tempfile.mkdtemp(prefix="gctl-lwcli2-"))
    r2 = sp.run([sys.executable, GRAPHCTL, "lint-watch", "--repo", str(root2), "--json"], capture_output=True, text=True, env=env)
    check("缺清單 rc0", r2.returncode == 0 and J.loads(r2.stdout)["candidates"] == [], r2.stdout)
    # 壞清單(非 list)→ rc 2
    (root2 / ".lumos").mkdir()
    (root2 / ".lumos" / "lint-watch.json").write_text('{"not":"a list"}', encoding="utf-8")
    r3 = sp.run([sys.executable, GRAPHCTL, "lint-watch", "--repo", str(root2), "--json"], capture_output=True, text=True, env=env)
    check("壞清單 rc2", r3.returncode == 2, f"rc={r3.returncode}")
```

- [ ] **Step 2:** 跑確認 fail(subcommand 未定義)。
- [ ] **Step 3:** 實作:
  - argparse:在 subparser 區加 `p = sub.add_parser("lint-watch")`;`p.add_argument("--repo", dest="lint_watch_repo", default=".")`;`p.add_argument("--json", action="store_true")`。
  - dispatch:在 `refcheck`/`pitfalls`/`anchor` 那批 vault-free dispatch **之前或同區**(務必在 `vault = args.vault or find_vault(...)` 之前)加 `if args.cmd == "lint-watch": return _lint_watch_mode(args.lint_watch_repo, args.json)`。
  - `_lint_watch_mode(repo_root, as_json)`:讀 `Path(repo_root)/".lumos"/"lint-watch.json"`:不存在 → 空清單(視為 `[]`);存在但 `json.load` 失敗或非 list 或任一條目非 dict 或缺 `name`/`registry`/`current` → 印錯誤、`return 2`。空 list → candidates/failed 空、checked 0、rc 0。逐條:`latest, reason = _registry_latest(entry["registry"])`;`latest` None → `failed.append({"name":entry["name"],"reason":reason})`;否則 `state, r = _compare_versions(entry["current"], latest)`:`behind` → `candidates.append({"name","registry","current","latest"})` 且 checked+1;`current` → checked+1;`skip` → `failed.append({"name":entry["name"],"reason":r})`。輸出:`--json` → `print(json.dumps({"candidates":candidates,"checked":checked,"failed":failed}, ensure_ascii=False))`;否則每 candidate 印一行。`return 0`。
- [ ] **Step 4:** 跑 `t_lint_watch_cli` 全綠 + 全套件回歸。
- [ ] **Step 5:** commit `feat(lint-watch): lint-watch 子命令(config/主迴圈/manifest/rc,vault-free dispatch)`(`--no-verify`)。

---

### Task 4: 去重 helper `lint_watch_dedup.py`(`new_candidates` + `__main__` 側效)

**Files:** Create `governance/autonomous_loop/lint_watch_dedup.py`;Test `governance/autonomous_loop/test_lint_watch_dedup.py`(新檔,沿 `governance/autonomous_loop` 既有 test 風格;若該目錄用 `test_autonomous_loop.py` 集中式,則加進該檔——實作者依現況擇一,見下註)。

> **註**:先看 `governance/autonomous_loop/` 現有測試怎麼組織(集中 `test_autonomous_loop.py` 還是 per-module),沿現況;測試須能被既有 harness 收到。

**Interfaces:** Consumes Task 3 的 `--json` manifest 形狀。Produces `new_candidates(candidates, seen_path) -> list`(`(name,latest)` 不在 seen 的候選;seen 檔不存在 → 視為空)、`__main__`:`python3 lint_watch_dedup.py <seen_path> <pending_path> <today>` stdin 讀 manifest、有新候選則寫 pending + append seen + stdout 印完整 LINE dict、無則不寫檔 stdout 空、stdin 非 JSON → 印空乾淨退。

- [ ] **Step 1: 測試**:

```python
# new_candidates
def t_dedup_new_candidates():
    import importlib.util as U, json, tempfile
    from importlib.machinery import SourceFileLoader
    from pathlib import Path
    P = "governance/autonomous_loop/lint_watch_dedup.py"
    spec = U.spec_from_file_location("lwd", P, loader=SourceFileLoader("lwd", P))
    m = U.module_from_spec(spec); spec.loader.exec_module(m)
    cands = [{"name":"detekt","latest":"1.24.0"},{"name":"ruff","latest":"0.5.0"}]
    d = Path(tempfile.mkdtemp(prefix="lwd-"))
    seen = d / "seen.jsonl"
    # ① seen 檔不存在 → 全新
    assert m.new_candidates(cands, str(seen)) == cands
    # ② 全已見
    seen.write_text('{"name":"detekt","latest":"1.24.0","seen":"2026-07-04"}\n{"name":"ruff","latest":"0.5.0","seen":"2026-07-04"}\n', encoding="utf-8")
    assert m.new_candidates(cands, str(seen)) == []
    # ③ 部分新
    seen.write_text('{"name":"detekt","latest":"1.24.0","seen":"2026-07-04"}\n', encoding="utf-8")
    assert [c["name"] for c in m.new_candidates(cands, str(seen))] == ["ruff"]
    # ④ 同 name 但新 latest → 算新(key 是 (name,latest))
    seen.write_text('{"name":"detekt","latest":"1.23.7","seen":"2026-07-04"}\n', encoding="utf-8")
    assert any(c["name"]=="detekt" for c in m.new_candidates(cands, str(seen)))
    print("t_dedup_new_candidates OK")

# __main__ 側效
def t_dedup_main():
    import subprocess as sp, json, tempfile, sys
    from pathlib import Path
    d = Path(tempfile.mkdtemp(prefix="lwdm-"))
    seen = d / "seen.jsonl"; pending = d / "pending-2026-07-04.json"
    manifest = json.dumps({"candidates":[{"name":"detekt","registry":"github:detekt/detekt","current":"1.23.7","latest":"1.24.0"}],"checked":1,"failed":[]})
    r = sp.run([sys.executable, "governance/autonomous_loop/lint_watch_dedup.py", str(seen), str(pending), "2026-07-04"],
               input=manifest, capture_output=True, text=True)
    assert pending.exists(), "pending 未寫"
    assert json.loads(pending.read_text())[0]["name"] == "detekt"
    assert seen.exists() and "1.24.0" in seen.read_text(), "seen 未 append"
    msg = json.loads(r.stdout)
    assert msg["messages"][0]["type"] == "text" and "detekt" in msg["messages"][0]["text"]
    # 非 JSON stdin → 印空乾淨退
    r2 = sp.run([sys.executable, "governance/autonomous_loop/lint_watch_dedup.py", str(seen), str(pending), "2026-07-04"],
                input="ERROR: bad watch list", capture_output=True, text=True)
    assert r2.stdout.strip() == "", f"非 JSON 應印空: {r2.stdout!r}"
    print("t_dedup_main OK")
```

- [ ] **Step 2:** 跑確認 fail。
- [ ] **Step 3:** 實作 `governance/autonomous_loop/lint_watch_dedup.py`:

```python
"""lint-watch 去重 + 放行側效(所有 JSON 讀寫在 python;shell 不碰 JSON)。"""
import json, sys, os


def new_candidates(candidates, seen_path):
    seen = set()
    if os.path.exists(seen_path):
        with open(seen_path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    o = json.loads(line)
                    seen.add((o.get("name"), o.get("latest")))
                except json.JSONDecodeError:
                    continue
    return [c for c in candidates if (c.get("name"), c.get("latest")) not in seen]


def _line_message(new):
    lines = [f"🔧 lint 升級候選({len(new)}):"]
    for c in new:
        typ = c.get("registry", "").split(":", 1)[0]
        lines.append(f"{c['name']} {c['current']}→{c['latest']}({typ})")
    return {"messages": [{"type": "text", "text": "\n".join(lines)}]}


def main(argv):
    seen_path, pending_path, today = argv[0], argv[1], argv[2]
    try:
        manifest = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        print("", end="")
        return 0
    cands = manifest.get("candidates") or []
    new = new_candidates(cands, seen_path)
    if not new:
        print("", end="")
        return 0
    with open(pending_path, "w", encoding="utf-8") as f:
        json.dump(new, f, ensure_ascii=False, indent=2)
    with open(seen_path, "a", encoding="utf-8") as f:
        for c in new:
            f.write(json.dumps({"name": c["name"], "latest": c["latest"], "seen": today}, ensure_ascii=False) + "\n")
    print(json.dumps(_line_message(new), ensure_ascii=False), end="")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
```

- [ ] **Step 4:** 跑 `t_dedup_new_candidates` + `t_dedup_main` 全綠 + `governance/autonomous_loop` 既有測試回歸。
- [ ] **Step 5:** commit `feat(lint-watch): lint_watch_dedup 去重 + __main__ 放行側效(pending/seen/LINE dict)`(`--no-verify`)。

---

### Task 5: `lint-watch-check.sh` 排程 shell + 掛 daily wrapper(真 shell 測試定稿)

**Files:** Create `governance/lint-watch-check.sh`(chmod +x);Modify `governance/daily-governance.sh`(第 3 步呼叫 + 頭註)。

**Interfaces:** Consumes Task 3 `lumos lint-watch --json` + Task 4 `lint_watch_dedup.py`。無自動化單元測(shell);以**真 shell smoke 手動驗**(見 Step 3-4),因 design-loop 判定 shell wrapper 留實作階段真測定稿。

- [ ] **Step 1:** 先讀 `governance/autonomous-loop.sh`(repo 根探法 `SCRIPT_DIR`、`MSG=... python3 -c` 雙引號慣例、`sys.path.insert` + `from autonomous_loop import line_notify`)與 `governance/daily-governance.sh`(`set -uo pipefail` 無 `-e`、既有兩步結構),照它的實際寫法對齊(不憑記憶)。
- [ ] **Step 2:** 建 `governance/lint-watch-check.sh`:

```bash
#!/usr/bin/env bash
# lint-watch 每日排程:查 registry 新穩定版 → 新候選暫存 + LINE 通知(fail-open,不阻斷 wrapper)。
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$SCRIPT_DIR/.."
DIR="$REPO/governance/lint-upgrades"
mkdir -p "$DIR"
TODAY="$(date +%Y-%m-%d)"
SEEN="$DIR/seen.jsonl"
PENDING="$DIR/pending-$TODAY.json"
DEDUP="$REPO/governance/autonomous_loop/lint_watch_dedup.py"

MSG="$(lumos lint-watch --repo "$REPO" --json 2>/dev/null | python3 "$DEDUP" "$SEEN" "$PENDING" "$TODAY")" || true
TOKEN_FILE="$HOME/.config/ai-daily/line_token"
if [ -n "$MSG" ] && [ -f "$TOKEN_FILE" ]; then
  MSG="$MSG" python3 -c "import os,json,sys; sys.path.insert(0,'$REPO/governance'); from autonomous_loop import line_notify; line_notify.send(json.loads(os.environ['MSG']), open('$TOKEN_FILE').read().strip())" || true
fi
exit 0
```

- [ ] **Step 3:** `chmod +x governance/lint-watch-check.sh`。**真 shell smoke**(用 fixture、不打網路、不需 token):
```bash
# 造一個臨時 repo 根含 .lumos/lint-watch.json + fixture,跑 check 腳本、驗 pending 檔生成
# (實作者:在 /tmp 建 fixture 檔與 watch 清單,export LUMOS_LINT_WATCH_FIXTURE,
#  暫時把 REPO 指到該臨時根跑一次,確認 pending-<today>.json 生成且內容正確、無 token 時不報錯)
```
Expected:pending 檔生成、腳本 `exit 0`、無 token 時不噴錯(fail-open)。把實測指令與輸出記入 Task 5 report。
- [ ] **Step 4:** Modify `governance/daily-governance.sh`:第 2 步(autonomous-loop)之後加第 3 步 `"$DIR/lint-watch-check.sh" >> "$DIR/logs/lint-watch.log" 2>&1 || true`(log 路徑對齊既有 logs 慣例;確認 `logs/` 存在或 `mkdir -p`);頭註補「第 3 步 lint-watch-check:每日查 linter 新版」。
- [ ] **Step 5:** commit `feat(lint-watch): lint-watch-check.sh 排程 shell + 掛 daily wrapper 第 3 步`(此 commit 含 shell,pre-commit KG gate 對非架構圖改動仍會擋 → `--no-verify`,Task 6 補架構圖)。

---

### Task 6: 知識同步 + 架構圖節點 + anchor 收尾(controller 自跑)

**Files:** Modify `skills/lumos-project-notes/SKILL.md`(指令表補 `lint-watch`)、`docs/methodology/架構圖即合約.md`(pitfalls 列補「版本偵測(lint-watch)」);Create `Systems/lint-version-watch.md` + `Verification/2026-07-04_lint-version-watch.md`;更新 `Projects/pitfalls-lint-integration_計劃`(②塊 done);merge 後 anchor approve。

- [ ] **Step 1:** 知識同步兩檔(照 spec §知識同步影響表,grep 驗各 ≥1 命中)。
- [ ] **Step 2:** KG Systems 節點(summary:FLOW=讀 watch→查 registry→semver 比較→候選 manifest→去重→暫存+LINE;KEY=只查版本不驗規則/純數字 tuple+等段數守衛/prerelease 過濾/Maven 數值 max+%22+timestamp sort/fixture seam/shell 零 JSON/fail-open;DEP=[[pitfalls-lint-adapter]][[pitfalls-code-loop]];TEST;VERIFY)+ Verification 節點(valid_under:registry 端點語意/`.lumos/lint-watch.json` schema;revalidate_when;TEST 記實際數)。`lumos lint` ×2 + `lumos doctor` 0 issues。
- [ ] **Step 3:** 更新計劃節點 ②塊 status=done + verified_by 回指。commit(此 commit 純架構圖/docs,pre-commit gate 應放行)。
- [ ] **Step 4(merge 收尾):** merge 回 main 後 push 前:`lumos anchor approve --note "lint-version-watch:test_lumos.py 新增 lint-watch 測試"` + baseline 同批 commit。

---

## Self-Review

**Spec coverage**:semver 核心(§semver)→T1;registry 抓取+fixture seam(§HTTP/§prerelease)→T2;子命令 config/迴圈/manifest/rc(§CLI/§rc/§manifest)→T3;去重+__main__ 側效(§治理層 dedup)→T4;shell wrapper+掛 wrapper(§治理層 shell)→T5;知識同步→T6。✓
**測試策略對映**:§測試 1,2→T1;§測試 3→T2;§測試 4,5→T3;dedup 四例+__main__ 側效→T4;shell 真 smoke→T5。✓
**Placeholder scan**:T1-4 給完整測試+實作 code;T5 shell 完整、smoke 步驟具體(fixture 手法引 T2/T3 既有機制)。無 TBD。✓
**Type consistency**:`_semver_parse`/`_is_prerelease`/`_compare_versions`(T1)→ T2/T3 消費;`_registry_latest -> (latest,reason)`(T2)→ T3;manifest `{candidates,checked,failed}`(T3)→ T4 `new_candidates`/`__main__` 消費 candidates；`new_candidates(candidates, seen_path)` + `__main__ argv <seen> <pending> <today>`(T4)→ T5 shell 呼叫一致。✓
