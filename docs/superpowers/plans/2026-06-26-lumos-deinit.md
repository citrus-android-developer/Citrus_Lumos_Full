# lumos deinit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `lumos deinit` subcommand that reverses everything `lumos init` installed at the **project layer** (this repo's git hooks gate, vendored toolkit, CLAUDE.md injection block, and knowledge-graph vault), while never touching machine-shared items.

**Architecture:** New `cmd_deinit()` plus small single-purpose helpers in the existing zero-dependency `scripts/lumos` CLI, dispatched from `main()`'s vault-free early block (same place as `install/uninstall/update/bootstrap`). Helpers are unit-tested directly via the `SourceFileLoader` trick already used by `t_install_hooks_py`; the assembled command is tested end-to-end through hermetic temp-repo subprocess runs. Pre-flight safety guards (source-repo self-protection, `vault == root` iron gate) are evaluated before any mutation; the destructive graph deletion sits behind a three-gate safety net.

**Tech Stack:** Python 3 standard library only (subprocess, pathlib, shutil) — same as the rest of `scripts/lumos`. Tests use the repo's homemade `check()`-based harness in `scripts/test_lumos.py` (not pytest).

## Global Constraints

- **stdlib only, zero third-party deps** — `scripts/lumos` is pure python3 stdlib; do not add imports beyond stdlib.
- **Python ≥ 3.8** — no 3.10+ features (e.g. no `write_text(newline=)`); use `_write_lf` for file writes (`scripts/lumos:2584`).
- **Writes go through `_write_lf(path, text)`** for UTF-8 / LF / no-BOM consistency.
- **All git calls target the repo with `git -C <root>`** — never rely on cwd for `git config` / `git status`.
- **deinit never auto-commits** — it only mutates the working tree + git config.
- **deinit never touches machine-shared items** — `~/.claude/hooks/*.py`, `~/.claude/settings.json` are out of scope.
- **Test runner:** `python3 scripts/test_lumos.py` (exit 0 = all pass). Test functions are auto-discovered by the `t_` name prefix; assert with `check(name, cond, detail)`.
- **No-network tests:** build the "installed" fixture state by hand (git init + config + touch files); do **not** invoke `lumos init`/`update` in tests (they pull from the Lumos source).

---

### Task 1: Extract `_VENDORED_TOOLKIT` constant + refactor `_vendor_toolchain` (no behavior change)

**Files:**
- Modify: `scripts/lumos:3064-3065` (inline toolkit list) and add a module-level constant near `scripts/lumos:3107` (`_SKILLS`)
- Test: `scripts/test_lumos.py` (add `t_deinit_vendored_toolkit_constant`)

**Interfaces:**
- Produces: `_VENDORED_TOOLKIT: tuple[str, ...]` — the 5 fixed `scripts/`-prefixed vendored file paths, shared by `_vendor_toolchain` and (later) `cmd_deinit`.

- [ ] **Step 1: Write the failing test**

Add to `scripts/test_lumos.py` (anywhere among the `t_` functions). It loads `scripts/lumos` as a module via the established `SourceFileLoader` pattern and asserts the constant:

```python
def t_deinit_vendored_toolkit_constant():
    import importlib.util
    from importlib.machinery import SourceFileLoader
    spec = importlib.util.spec_from_file_location(
        "m", GRAPHCTL, loader=SourceFileLoader("m", GRAPHCTL))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)  # __main__ guard → import 不跑 main
    expected = ("scripts/lumos", "scripts/test_lumos.py",
                "scripts/merge-claude-settings.py", "scripts/graph-rename.sh",
                "scripts/fetch-notesmd.sh")
    check("deinit: _VENDORED_TOOLKIT 5 檔且帶 scripts/ 前綴",
          tuple(m._VENDORED_TOOLKIT) == expected, f"got {getattr(m,'_VENDORED_TOOLKIT',None)!r}")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test_lumos.py 2>&1 | grep deinit`
Expected: FAIL — `✗ deinit: _VENDORED_TOOLKIT 5 檔且帶 scripts/ 前綴  got None` (constant not defined yet).

- [ ] **Step 3: Add the constant**

In `scripts/lumos`, immediately **above** `_vendor_toolchain` (i.e. just before line 3041), add:

```python
# vendored 工具組白名單(固定 5 檔,scripts/ 前綴;hooks/templates 兩夾另走整夾刪)。
# _vendor_toolchain 安裝端與 cmd_deinit 移除端共用,避免漂移。
_VENDORED_TOOLKIT = ("scripts/lumos", "scripts/test_lumos.py",
                     "scripts/merge-claude-settings.py", "scripts/graph-rename.sh",
                     "scripts/fetch-notesmd.sh")
```

- [ ] **Step 4: Refactor `_vendor_toolchain` to use it (no behavior change)**

Replace `scripts/lumos:3064-3065`:

```python
    toolkit = ["scripts/lumos", "scripts/test_lumos.py", "scripts/merge-claude-settings.py",
               "scripts/graph-rename.sh", "scripts/fetch-notesmd.sh"]
```

with:

```python
    toolkit = list(_VENDORED_TOOLKIT)
```

(The two `for sub in ("scripts/hooks", "scripts/templates")` rglob lines below stay exactly as-is.)

- [ ] **Step 5: Run tests to verify pass + no regression**

Run: `python3 scripts/test_lumos.py`
Expected: all pass (the new deinit constant test passes; every pre-existing test still passes — the refactor is behavior-preserving).

- [ ] **Step 6: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "refactor(lumos): 抽 _VENDORED_TOOLKIT 常數供 deinit 共用(無行為變更)"
```

---

### Task 2: `_deinit_unbar_gate(root)` — best-effort unset of `core.hooksPath`

**Files:**
- Modify: `scripts/lumos` (add helper near `cmd_uninstall`, ~line 3032)
- Test: `scripts/test_lumos.py` (add `t_deinit_unbar_gate`)

**Interfaces:**
- Produces: `_deinit_unbar_gate(root: Path) -> int` — runs `git -C root config --unset core.hooksPath`; returns the git returncode. rc 0 (unset) and rc 5 (key absent) are success; other rc prints a warning and is still tolerated (caller does not abort).

- [ ] **Step 1: Write the failing test**

```python
def _load_lumos():
    import importlib.util
    from importlib.machinery import SourceFileLoader
    spec = importlib.util.spec_from_file_location(
        "m", GRAPHCTL, loader=SourceFileLoader("m", GRAPHCTL))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m

def t_deinit_unbar_gate():
    import subprocess
    from pathlib import Path
    m = _load_lumos()
    root = Path(tempfile.mkdtemp(prefix="gctl-deinit-unbar-"))
    subprocess.run(["git", "-C", str(root), "init"], capture_output=True, text=True)
    subprocess.run(["git", "-C", str(root), "config", "core.hooksPath", "scripts/hooks"],
                   capture_output=True, text=True)
    rc1 = m._deinit_unbar_gate(root)
    hp = subprocess.run(["git", "-C", str(root), "config", "core.hooksPath"],
                        capture_output=True, text=True)
    check("deinit unbar: core.hooksPath 已 unset", hp.stdout.strip() == "", f"got {hp.stdout!r}")
    check("deinit unbar: rc 0 視為成功", rc1 == 0, f"rc={rc1}")
    rc2 = m._deinit_unbar_gate(root)   # 再 unset 一次 → key 已不存在
    check("deinit unbar: 重複 unset rc5 不崩潰", rc2 in (0, 5), f"rc={rc2}")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit unbar"`
Expected: FAIL / EXCEPTION — `_deinit_unbar_gate` not defined.

- [ ] **Step 3: Implement the helper**

Add to `scripts/lumos` just after `cmd_uninstall` (after line 3031):

```python
def _deinit_unbar_gate(root: Path) -> int:
    """拆 pre-commit 閘:git -C root config --unset core.hooksPath。
    rc 0(已 unset)/ rc 5(key 本不存在)皆成功;其他 rc 印 warning 但不中止
    (真正保險是 step 4 會把 scripts/hooks/ 整夾刪掉,缺 hook 檔 git 自會放行)。"""
    import subprocess
    r = subprocess.run(["git", "-C", str(root), "config", "--unset", "core.hooksPath"],
                       capture_output=True, text=True)
    if r.returncode not in (0, 5):
        print(f"  ⚠ git config --unset core.hooksPath rc={r.returncode}(續行)", file=sys.stderr)
    return r.returncode
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit unbar"`
Expected: 3 lines, all `✓`.

- [ ] **Step 5: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): _deinit_unbar_gate 拆 pre-commit 閘(best-effort unset)"
```

---

### Task 3: `_deinit_strip_claude(root)` — strip the CLAUDE.md injection block

**Files:**
- Modify: `scripts/lumos` (add helper near `_deinit_unbar_gate`)
- Test: `scripts/test_lumos.py` (add `t_deinit_strip_claude`)

**Interfaces:**
- Consumes: `_write_lf(path, text)` (`scripts/lumos:2584`).
- Produces: `_deinit_strip_claude(root: Path) -> bool` — removes the text between `<!-- LUMOS:GRAPH-DISCIPLINE:START …` and `… LUMOS:GRAPH-DISCIPLINE:END -->` (inclusive) from `root/CLAUDE.md`, preserving all other content and keeping the file. Returns True if a block was stripped; False (no-op) when CLAUDE.md is absent or has no START marker.

- [ ] **Step 1: Write the failing test (3 cases)**

```python
def t_deinit_strip_claude():
    from pathlib import Path
    m = _load_lumos()
    START = ("<!-- LUMOS:GRAPH-DISCIPLINE:START — 自動注入/更新,勿手改本區塊;"
             "改範本 scripts/templates/graph-discipline.md -->")
    END = "<!-- LUMOS:GRAPH-DISCIPLINE:END -->"

    # case A: 有自有段落 + 注入區塊 → 剝區塊、留自有段落、留檔
    root = Path(tempfile.mkdtemp(prefix="gctl-deinit-cm-a-"))
    (root / "CLAUDE.md").write_bytes(
        ("# CLAUDE.md\n\n我的專案規則。\n\n" + START + "\n架構圖紀律內文\n" + END + "\n").encode("utf-8"))
    stripped = m._deinit_strip_claude(root)
    txt = (root / "CLAUDE.md").read_text(encoding="utf-8")
    check("deinit claude A: 回 True", stripped is True, f"got {stripped}")
    check("deinit claude A: 自有段落保留", "我的專案規則。" in txt, txt)
    check("deinit claude A: 區塊已消失", "GRAPH-DISCIPLINE" not in txt, txt)
    check("deinit claude A: 檔仍在", (root / "CLAUDE.md").exists(), "")

    # case B: 無 START 標記 → no-op、回 False、內容不變
    root = Path(tempfile.mkdtemp(prefix="gctl-deinit-cm-b-"))
    (root / "CLAUDE.md").write_bytes("# CLAUDE.md\n\n只有我的內容\n".encode("utf-8"))
    before = (root / "CLAUDE.md").read_text(encoding="utf-8")
    res = m._deinit_strip_claude(root)
    check("deinit claude B: no-op 回 False", res is False, f"got {res}")
    check("deinit claude B: 內容不變", (root / "CLAUDE.md").read_text(encoding="utf-8") == before, "")

    # case C: CLAUDE.md 不存在 → no-op、回 False、不報錯
    root = Path(tempfile.mkdtemp(prefix="gctl-deinit-cm-c-"))
    res = m._deinit_strip_claude(root)
    check("deinit claude C: 無檔 no-op 回 False", res is False, f"got {res}")
    check("deinit claude C: 仍無 CLAUDE.md", not (root / "CLAUDE.md").exists(), "")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit claude"`
Expected: FAIL / EXCEPTION — `_deinit_strip_claude` not defined.

- [ ] **Step 3: Implement the helper**

Add to `scripts/lumos` after `_deinit_unbar_gate`:

```python
def _deinit_strip_claude(root: Path) -> bool:
    """剝 CLAUDE.md 的 LUMOS:GRAPH-DISCIPLINE 區塊;其餘內容/整個檔都留。
    無檔或無 START 標記 → no-op 回 False(對稱注入端 scripts/lumos:3175 的存在性 gating)。"""
    cm = root / "CLAUDE.md"
    if not cm.exists():
        return False
    text = cm.read_text(encoding="utf-8")
    start_marker = "<!-- LUMOS:GRAPH-DISCIPLINE:START"
    end_marker = "LUMOS:GRAPH-DISCIPLINE:END -->"
    si = text.find(start_marker)
    ei = text.find(end_marker)
    if si == -1 or ei == -1:
        return False
    ei += len(end_marker)
    new = (text[:si].rstrip() + "\n" + text[ei:].lstrip()).strip()
    _write_lf(cm, (new + "\n") if new else "")
    return True
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit claude"`
Expected: all `✓`.

- [ ] **Step 5: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): _deinit_strip_claude 剝 CLAUDE.md 注入區塊(無標記/無檔 no-op)"
```

---

### Task 4: `_deinit_remove_vendored(root)` — whitelist removal of the vendored toolkit

**Files:**
- Modify: `scripts/lumos` (add helper near the other `_deinit_*`)
- Test: `scripts/test_lumos.py` (add `t_deinit_remove_vendored`)

**Interfaces:**
- Consumes: `_VENDORED_TOOLKIT` (Task 1).
- Produces: `_deinit_remove_vendored(root: Path) -> list[str]` — removes each existing `_VENDORED_TOOLKIT` file, then `scripts/hooks/` and `scripts/templates/` as whole directories (recursive), then `rmdir`s `scripts/` only if empty. Never touches non-Lumos files under `scripts/`. Returns the list of removed relative paths.

- [ ] **Step 1: Write the failing test**

```python
def t_deinit_remove_vendored():
    from pathlib import Path
    m = _load_lumos()
    root = Path(tempfile.mkdtemp(prefix="gctl-deinit-rm-"))
    sc = root / "scripts"
    (sc / "hooks").mkdir(parents=True)
    (sc / "templates").mkdir(parents=True)
    (sc / "hooks" / "pre-commit").write_text("#!/bin/sh\n")
    (sc / "templates" / "graph-discipline.md").write_text("tpl\n")
    for rel in ("scripts/lumos", "scripts/test_lumos.py", "scripts/merge-claude-settings.py",
                "scripts/graph-rename.sh", "scripts/fetch-notesmd.sh"):
        (root / rel).write_text("x\n")
    (sc / "my_own_helper.py").write_text("mine\n")   # 使用者自有檔

    removed = m._deinit_remove_vendored(root)

    check("deinit rm: scripts/lumos 已移", not (sc / "lumos").exists(), "")
    check("deinit rm: scripts/hooks/ 整夾移除", not (sc / "hooks").exists(), "")
    check("deinit rm: scripts/templates/ 整夾移除", not (sc / "templates").exists(), "")
    check("deinit rm: 使用者自有檔保留", (sc / "my_own_helper.py").exists(), "")
    check("deinit rm: scripts/ 非空故保留", sc.is_dir(), "")
    check("deinit rm: 回傳列表含 scripts/lumos", "scripts/lumos" in removed, f"{removed}")

    # 第二個 repo:scripts/ 只剩 Lumos-owned → 清空後應 rmdir
    root2 = Path(tempfile.mkdtemp(prefix="gctl-deinit-rm2-"))
    (root2 / "scripts").mkdir()
    (root2 / "scripts" / "lumos").write_text("x\n")
    m._deinit_remove_vendored(root2)
    check("deinit rm: scripts/ 清空後 rmdir", not (root2 / "scripts").exists(), "")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit rm"`
Expected: FAIL / EXCEPTION — `_deinit_remove_vendored` not defined.

- [ ] **Step 3: Implement the helper**

Add to `scripts/lumos` after `_deinit_strip_claude`:

```python
def _deinit_remove_vendored(root: Path) -> list:
    """白名單移除 vendored 工具組:① _VENDORED_TOOLKIT 固定 5 檔;
    ② scripts/hooks/、scripts/templates/ 整夾遞迴刪(Lumos-owned,不靠 src 列舉)。
    scripts/ 底下使用者自有檔不碰;scripts/ 空了才 rmdir。回傳已移除相對路徑列表。"""
    import shutil
    removed = []
    for rel in _VENDORED_TOOLKIT:
        p = root / rel
        if p.exists():
            p.unlink(); removed.append(rel)
    for d in ("scripts/hooks", "scripts/templates"):
        p = root / d
        if p.is_dir():
            shutil.rmtree(p); removed.append(d + "/")
    sc = root / "scripts"
    if sc.is_dir() and not any(sc.iterdir()):
        sc.rmdir(); removed.append("scripts/")
    return removed
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit rm"`
Expected: all `✓`.

- [ ] **Step 5: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): _deinit_remove_vendored 白名單移除(保留使用者自有檔)"
```

---

### Task 5: `_deinit_detect_installed(root)` + `_claude_block_present(root)` — install-state heuristic

**Files:**
- Modify: `scripts/lumos` (add helpers near the other `_deinit_*`)
- Test: `scripts/test_lumos.py` (add `t_deinit_detect_installed`)

**Interfaces:**
- Produces:
  - `_deinit_detect_installed(root: Path) -> bool` — True iff `git -C root config core.hooksPath` has a value, OR `root/scripts/hooks/` exists. (Does not depend on `scripts/lumos` existing — the executing binary is irrelevant to whether *this repo* was installed.)
  - `_claude_block_present(root: Path) -> bool` — True iff `root/CLAUDE.md` exists and contains `LUMOS:GRAPH-DISCIPLINE:START`.

- [ ] **Step 1: Write the failing test**

```python
def t_deinit_detect_installed():
    import subprocess
    from pathlib import Path
    m = _load_lumos()

    # 無安裝痕跡 → False
    bare = Path(tempfile.mkdtemp(prefix="gctl-deinit-det0-"))
    subprocess.run(["git", "-C", str(bare), "init"], capture_output=True, text=True)
    check("deinit detect: 空 repo False", m._deinit_detect_installed(bare) is False, "")

    # core.hooksPath 有值 → True
    h = Path(tempfile.mkdtemp(prefix="gctl-deinit-det1-"))
    subprocess.run(["git", "-C", str(h), "init"], capture_output=True, text=True)
    subprocess.run(["git", "-C", str(h), "config", "core.hooksPath", "scripts/hooks"],
                   capture_output=True, text=True)
    check("deinit detect: hooksPath 有值 True", m._deinit_detect_installed(h) is True, "")

    # scripts/hooks/ 存在 → True
    s = Path(tempfile.mkdtemp(prefix="gctl-deinit-det2-"))
    subprocess.run(["git", "-C", str(s), "init"], capture_output=True, text=True)
    (s / "scripts" / "hooks").mkdir(parents=True)
    check("deinit detect: scripts/hooks 存在 True", m._deinit_detect_installed(s) is True, "")

    # _claude_block_present
    c = Path(tempfile.mkdtemp(prefix="gctl-deinit-det3-"))
    (c / "CLAUDE.md").write_text("# CLAUDE.md\n<!-- LUMOS:GRAPH-DISCIPLINE:START x -->\n", encoding="utf-8")
    check("deinit detect: claude 區塊在 True", m._claude_block_present(c) is True, "")
    check("deinit detect: 無 claude False",
          m._claude_block_present(Path(tempfile.mkdtemp(prefix="gctl-deinit-det4-"))) is False, "")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit detect"`
Expected: FAIL / EXCEPTION — helpers not defined.

- [ ] **Step 3: Implement the helpers**

Add to `scripts/lumos` after `_deinit_remove_vendored`:

```python
def _deinit_detect_installed(root: Path) -> bool:
    """target repo root 是否有專案層安裝痕跡:core.hooksPath 有值 或 scripts/hooks/ 存在。
    不靠 scripts/lumos 自身存在(執行檔與'此 repo 是否裝過'無關)。"""
    import subprocess
    hp = subprocess.run(["git", "-C", str(root), "config", "core.hooksPath"],
                        capture_output=True, text=True)
    if hp.returncode == 0 and hp.stdout.strip():
        return True
    return (root / "scripts" / "hooks").is_dir()


def _claude_block_present(root: Path) -> bool:
    cm = root / "CLAUDE.md"
    return cm.exists() and "LUMOS:GRAPH-DISCIPLINE:START" in cm.read_text(encoding="utf-8")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit detect"`
Expected: all `✓`.

- [ ] **Step 5: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): _deinit_detect_installed/_claude_block_present 安裝痕跡偵測"
```

---

### Task 6: `cmd_deinit` (non-graph) + argparse + dispatch — pre-flight guards & non-destructive actions

This task assembles the command for everything **except graph deletion** (graph is always kept here; deletion is added in Task 7). It wires the `deinit` subparser + dispatch, the non-git/source-repo pre-flight guards, idempotent short-circuit, and the unbar→strip→remove-vendored sequence.

**Files:**
- Modify: `scripts/lumos` — add `cmd_deinit` (near `cmd_uninstall`); add `deinit` subparser near `scripts/lumos:3473`; add dispatch near `scripts/lumos:3490`
- Test: `scripts/test_lumos.py` (add `t_deinit_cmd_basic`)

**Interfaces:**
- Consumes: `_lumos_src` (`scripts/lumos:3034`), `_vault_in` (`scripts/lumos:3293`), `_deinit_unbar_gate`, `_deinit_strip_claude`, `_deinit_remove_vendored`, `_deinit_detect_installed`, `_claude_block_present`.
- Produces: `cmd_deinit(keep_graph=False, dry_run=False, yes=False, source=None) -> int` — return 0 on success/idempotent-empty, 2 on a pre-flight refusal. In THIS task graph deletion is stubbed off (`will_delete_vault = False`).

- [ ] **Step 1: Write the failing tests**

Add a shared fixture builder + the test. The builder hand-creates an "installed" project (no network):

```python
def _mk_installed_project(prefix="gctl-deinit-proj-", with_vault=True, slug="demo"):
    """造一個已裝 Lumos 專案層的 hermetic repo(不跑 init/update,純手工)。回傳 root。"""
    import subprocess
    from pathlib import Path
    root = Path(tempfile.mkdtemp(prefix=prefix))
    subprocess.run(["git", "-C", str(root), "init"], capture_output=True, text=True)
    subprocess.run(["git", "-C", str(root), "config", "core.hooksPath", "scripts/hooks"],
                   capture_output=True, text=True)
    sc = root / "scripts"
    (sc / "hooks").mkdir(parents=True)
    (sc / "templates").mkdir(parents=True)
    (sc / "hooks" / "pre-commit").write_text("#!/bin/sh\nexit 0\n")
    (sc / "templates" / "graph-discipline.md").write_text("tpl\n")
    for rel in ("scripts/lumos", "scripts/test_lumos.py", "scripts/merge-claude-settings.py",
                "scripts/graph-rename.sh", "scripts/fetch-notesmd.sh"):
        (root / rel).write_text("x\n")
    START = ("<!-- LUMOS:GRAPH-DISCIPLINE:START — 自動注入/更新,勿手改本區塊;"
             "改範本 scripts/templates/graph-discipline.md -->")
    END = "<!-- LUMOS:GRAPH-DISCIPLINE:END -->"
    (root / "CLAUDE.md").write_bytes(
        ("# CLAUDE.md\n\n我的規則\n\n" + START + "\n紀律\n" + END + "\n").encode("utf-8"))
    if with_vault:
        kg = root / "docs" / f"{slug}-knowledge"
        (kg / "MOC").mkdir(parents=True)
        (kg / "Systems").mkdir(parents=True)
        (kg / "MOC" / "index.md").write_text("# idx\n")
        (kg / "Systems" / "S.md").write_text("# S\n")
    return root

def _deinit_run(root, *args, stdin_data=None):
    """從 root 跑 lumos deinit(cwd=root,git toplevel 即 root)。"""
    import subprocess, os
    fake = tempfile.mkdtemp(prefix="gctl-deinit-home-")
    return subprocess.run([sys.executable, GRAPHCTL, "deinit", *args],
                          cwd=str(root), input=stdin_data,
                          env=dict(os.environ, HOME=fake, USERPROFILE=fake),
                          capture_output=True, text=True)

def t_deinit_cmd_basic():
    from pathlib import Path
    # 整體(graph 在 Task 7 才刪;此處 --keep-graph 行為驗非破壞動作)
    root = _mk_installed_project()
    r = _deinit_run(root, "--keep-graph", "--yes")
    check("deinit cmd: rc 0", r.returncode == 0, f"{r.returncode} {r.stderr}")
    import subprocess
    hp = subprocess.run(["git", "-C", str(root), "config", "core.hooksPath"],
                        capture_output=True, text=True)
    check("deinit cmd: core.hooksPath 已 unset", hp.stdout.strip() == "", f"{hp.stdout!r}")
    check("deinit cmd: scripts/hooks/ 已移", not (root / "scripts" / "hooks").exists(), "")
    check("deinit cmd: scripts/lumos 已移", not (root / "scripts" / "lumos").exists(), "")
    cm = (root / "CLAUDE.md").read_text(encoding="utf-8")
    check("deinit cmd: claude 自有段落留", "我的規則" in cm, cm)
    check("deinit cmd: claude 區塊剝", "GRAPH-DISCIPLINE" not in cm, cm)

    # case 5 白名單:使用者自有檔保留
    root = _mk_installed_project(prefix="gctl-deinit-white-")
    (root / "scripts" / "mine.py").write_text("mine\n")
    _deinit_run(root, "--keep-graph", "--yes")
    check("deinit cmd: 使用者自有 scripts/mine.py 保留", (root / "scripts" / "mine.py").exists(), "")

    # case 7 來源自我保護:--source 指到 root 本身 → 拒絕 + rc2 + 無副作用
    root = _mk_installed_project(prefix="gctl-deinit-src-")
    r = _deinit_run(root, "--keep-graph", "--yes", "--source", str(root))
    check("deinit cmd: 來源自我保護 rc2", r.returncode == 2, f"{r.returncode} {r.stdout} {r.stderr}")
    check("deinit cmd: 自我保護下 scripts/lumos 未動", (root / "scripts" / "lumos").exists(), "")

    # case 4 冪等:乾淨 repo → rc0 + 印未安裝
    bare = Path(tempfile.mkdtemp(prefix="gctl-deinit-bare-"))
    subprocess.run(["git", "-C", str(bare), "init"], capture_output=True, text=True)
    r = _deinit_run(bare, "--yes")
    check("deinit cmd: 冪等 rc0", r.returncode == 0, f"{r.returncode} {r.stderr}")
    check("deinit cmd: 冪等印未安裝", "未安裝" in r.stdout, r.stdout)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit cmd"`
Expected: FAIL — `deinit` is not a recognized subcommand (argparse error) / `cmd_deinit` undefined.

- [ ] **Step 3: Implement `cmd_deinit` (graph deletion stubbed off)**

Add to `scripts/lumos` immediately after `cmd_uninstall` (after line 3031). Note `will_delete_vault = False` with an explicit "Task 7 替換" comment:

```python
def cmd_deinit(keep_graph=False, dry_run=False, yes=False, source=None):
    """專案層反安裝(對稱 cmd_init):拆本 repo 的 pre-commit 閘 / vendored 工具組 /
    CLAUDE.md 注入區塊 /(預設)架構圖 vault。不碰機器共用項(~/.claude)。不自動 commit。"""
    import subprocess
    # root 走 git toplevel;非 git 目錄中止(不 fallback cwd——deinit 會刪檔)
    try:
        root = Path(subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"], text=True,
            stderr=subprocess.DEVNULL).strip())
    except Exception:
        print("ERROR: 非 git 目錄,deinit 需可靠 repo root(不 fallback cwd)", file=sys.stderr)
        return 2
    # pre-flight 守衛①:來源 repo 自我保護(對齊 cmd_update 的 root==src → return 2)
    src = _lumos_src(source)
    if root.resolve() == src.resolve():
        print("ERROR: 當前就是 Lumos 來源本身,deinit 拒絕執行", file=sys.stderr)
        return 2
    vault = _vault_in(root)
    will_delete_vault = False   # Task 7 替換為:vault is not None and not keep_graph(含 vault==root 鐵閘)
    installed = _deinit_detect_installed(root)
    has_claude = _claude_block_present(root)
    if not installed and not will_delete_vault and not has_claude:
        print("✓ 未安裝(此 repo 無 Lumos 專案層)")
        return 0
    # ── 固定順序執行(pre-flight 已過)──
    _deinit_unbar_gate(root)                 # step 1 先拆閘
    _deinit_strip_claude(root)               # step 2 剝 CLAUDE.md 區塊
    # step 3 刪架構圖 vault:Task 7 加入(此處暫不刪)
    _deinit_remove_vendored(root)            # step 4 最後移 vendored(可能含自己)
    print("✓ deinit 完成(專案層已移除)。檢視 `git diff` 後自行 commit。")
    return 0
```

- [ ] **Step 4: Add the `deinit` subparser**

In `main()`, after the `init` subparser block (after `scripts/lumos:3477`), add:

```python
    p = sub.add_parser("deinit", help="專案層反安裝(對稱 init):拆本 repo 的 hooks/工具組/CLAUDE.md 注入/架構圖")
    p.add_argument("--keep-graph", action="store_true", help="保留架構圖 vault,其餘照拆")
    p.add_argument("--dry-run", action="store_true", help="只印會動到什麼,不實際改動")
    p.add_argument("-y", "--yes", action="store_true", help="跳過互動確認(CI/非互動用)")
    p.add_argument("--source", help="Lumos 來源 repo 路徑(僅供自我保護比對)")
```

- [ ] **Step 5: Add the dispatch**

In `main()`, in the vault-free early block after the `init` dispatch (after `scripts/lumos:3492`), add:

```python
    if args.cmd == "deinit":
        return cmd_deinit(keep_graph=args.keep_graph, dry_run=args.dry_run,
                          yes=args.yes, source=args.source)
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit cmd"`
Expected: all `✓`.

- [ ] **Step 7: Run the full suite (no regression)**

Run: `python3 scripts/test_lumos.py`
Expected: `N passed, 0 failed`.

- [ ] **Step 8: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): cmd_deinit 骨架 + 分派(pre-flight 守衛 + 非破壞動作,架構圖待 Task7)"
```

---

### Task 7: Graph deletion + three-gate safety net + `vault == root` iron gate + `--dry-run`

This task makes graph deletion the default, behind the safety net, and adds the `vault == root` iron gate and dry-run preview.

**Files:**
- Modify: `scripts/lumos` — `cmd_deinit` (the `will_delete_vault` line + insert safety net, vault==root gate, dry-run block, and the step-3 rmtree)
- Test: `scripts/test_lumos.py` (add `t_deinit_graph`)

**Interfaces:**
- Consumes: everything from Task 6 plus `shutil.rmtree`.
- Produces: final `cmd_deinit` behavior — default deletes the vault behind confirmation; `--keep-graph` preserves; `vault == root` forces keep-graph + warns; `--dry-run` changes nothing; non-tty without `--yes` aborts with rc 2.

- [ ] **Step 1: Write the failing tests**

```python
def t_deinit_graph():
    import subprocess, os
    from pathlib import Path

    # case 1 完整 deinit:default(--yes)→ vault 不存在 + 其餘皆拆
    root = _mk_installed_project(prefix="gctl-deinit-g1-")
    r = _deinit_run(root, "--yes")
    check("deinit graph1: rc0", r.returncode == 0, f"{r.returncode} {r.stderr}")
    check("deinit graph1: vault 已刪", not (root / "docs" / "demo-knowledge").exists(), "")
    check("deinit graph1: scripts/lumos 已移", not (root / "scripts" / "lumos").exists(), "")

    # case 2 --keep-graph:vault 仍在
    root = _mk_installed_project(prefix="gctl-deinit-g2-")
    _deinit_run(root, "--keep-graph", "--yes")
    check("deinit graph2: --keep-graph 保留 vault", (root / "docs" / "demo-knowledge").is_dir(), "")

    # case 8 --dry-run:vault + config + 檔案全不動
    root = _mk_installed_project(prefix="gctl-deinit-g8-")
    r = _deinit_run(root, "--dry-run")
    check("deinit graph8: dry-run rc0", r.returncode == 0, f"{r.returncode}")
    check("deinit graph8: dry-run vault 仍在", (root / "docs" / "demo-knowledge").is_dir(), "")
    check("deinit graph8: dry-run scripts/lumos 仍在", (root / "scripts" / "lumos").exists(), "")
    hp = subprocess.run(["git", "-C", str(root), "config", "core.hooksPath"],
                        capture_output=True, text=True)
    check("deinit graph8: dry-run hooksPath 未動", hp.stdout.strip() == "scripts/hooks", f"{hp.stdout!r}")

    # case 9 非互動防呆:預設(無 --yes)+ 非 tty → 拒絕刪 + rc2 + vault 仍在
    root = _mk_installed_project(prefix="gctl-deinit-g9-")
    r = _deinit_run(root)   # subprocess capture → stdin 非 tty
    check("deinit graph9: 非互動無 --yes rc2", r.returncode == 2, f"{r.returncode} {r.stdout} {r.stderr}")
    check("deinit graph9: vault 未刪", (root / "docs" / "demo-knowledge").is_dir(), "")

    # case 10 vault==root 鐵閘:standalone vault repo(非 _lumos_src)→ 絕不 rmtree
    root = Path(tempfile.mkdtemp(prefix="gctl-deinit-g10-"))
    subprocess.run(["git", "-C", str(root), "init"], capture_output=True, text=True)
    subprocess.run(["git", "-C", str(root), "config", "core.hooksPath", "scripts/hooks"],
                   capture_output=True, text=True)
    (root / "MOC").mkdir(); (root / "Systems").mkdir()
    (root / "MOC" / "index.md").write_text("# idx\n")
    (root / "important_note.md").write_text("不可刪\n")
    START = ("<!-- LUMOS:GRAPH-DISCIPLINE:START — 自動注入/更新,勿手改本區塊;"
             "改範本 scripts/templates/graph-discipline.md -->")
    END = "<!-- LUMOS:GRAPH-DISCIPLINE:END -->"
    (root / "CLAUDE.md").write_bytes(("# CLAUDE.md\n\n" + START + "\nx\n" + END + "\n").encode("utf-8"))
    r = _deinit_run(root, "--yes")
    check("deinit graph10: 鐵閘 rc0", r.returncode == 0, f"{r.returncode} {r.stderr}")
    check("deinit graph10: repo 根仍在(絕無 rmtree)", (root / "important_note.md").exists(), "")
    check("deinit graph10: MOC/ 架構圖仍在", (root / "MOC" / "index.md").exists(), "")
    hp = subprocess.run(["git", "-C", str(root), "config", "core.hooksPath"],
                        capture_output=True, text=True)
    check("deinit graph10: 其餘動作仍執行(hooksPath unset)", hp.stdout.strip() == "", f"{hp.stdout!r}")
    cm = (root / "CLAUDE.md").read_text(encoding="utf-8")
    check("deinit graph10: 其餘動作仍執行(claude 區塊剝)", "GRAPH-DISCIPLINE" not in cm, cm)

    # case 3 拆閘有效:deinit 後 commit「改 code 不動架構圖」不被擋
    root = _mk_installed_project(prefix="gctl-deinit-g3-")
    _deinit_run(root, "--keep-graph", "--yes")
    hp = subprocess.run(["git", "-C", str(root), "config", "core.hooksPath"],
                        capture_output=True, text=True)
    check("deinit graph3: core.hooksPath 空", hp.stdout.strip() == "", f"{hp.stdout!r}")
    check("deinit graph3: scripts/hooks/ 不存在", not (root / "scripts" / "hooks").exists(), "")
    (root / "code.py").write_text("print(1)\n")
    subprocess.run(["git", "-C", str(root), "add", "-A"], capture_output=True, text=True)
    cr = subprocess.run(["git", "-C", str(root), "-c", "user.email=t@t", "-c", "user.name=t",
                         "commit", "-m", "change code only"], capture_output=True, text=True)
    check("deinit graph3: commit 不被擋(rc0)", cr.returncode == 0, f"{cr.returncode} {cr.stdout} {cr.stderr}")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit graph"`
Expected: FAIL — e.g. `deinit graph1: vault 已刪` fails (Task 6 keeps the vault); `deinit graph9` returns 0 instead of 2; `deinit graph8` dry-run mutates.

- [ ] **Step 3: Replace the `will_delete_vault` stub + insert the gate, safety net, and dry-run**

In `cmd_deinit`, replace this line:

```python
    will_delete_vault = False   # Task 7 替換為:vault is not None and not keep_graph(含 vault==root 鐵閘)
```

with the gate + computed flag:

```python
    # pre-flight 守衛②:vault == root 鐵閘(防 rmtree 整個 repo)
    if vault is not None and vault.resolve() == root.resolve() and not keep_graph:
        keep_graph = True
        print("⚠ 偵測到 standalone vault(架構圖=repo 根):強制保留架構圖,只拆其餘專案層。",
              file=sys.stderr)
    will_delete_vault = (vault is not None) and (not keep_graph)
```

Then, **after** the idempotent short-circuit block and **before** the `_deinit_unbar_gate(root)` line, insert the dry-run preview and the safety net:

```python
    if dry_run:
        print("lumos deinit --dry-run(僅預演,不改動):")
        print(f"  root: {root}")
        print("  拆閘: git config --unset core.hooksPath" if installed
              else "  拆閘: (core.hooksPath 未設,略)")
        if has_claude:
            print("  剝 CLAUDE.md graph-discipline 區塊")
        if will_delete_vault:
            n = len([f for f in vault.rglob("*") if f.is_file()])
            print(f"  刪架構圖 vault: {vault}({n} 檔)")
        elif vault is not None:
            print(f"  保留架構圖 vault: {vault}")
        print("  移除 vendored 工具組(白名單:5 檔 + hooks/templates 兩夾)")
        return 0
    if will_delete_vault and not yes:
        if not sys.stdin.isatty():
            print("ERROR: 非互動環境(stdin 非 tty)且未加 --yes,拒絕刪架構圖。加 --yes 確認。",
                  file=sys.stderr)
            return 2
        files = [f for f in vault.rglob("*") if f.is_file()]
        dirty = subprocess.run(["git", "-C", str(root), "status", "--porcelain", str(vault)],
                               capture_output=True, text=True).stdout
        n_dirty = len([ln for ln in dirty.splitlines() if ln.strip()])
        print(f"將刪除架構圖 vault: {vault}({len(files)} 檔)")
        if n_dirty:
            print(f"  ⚠ 其中 {n_dirty} 個未 commit — 刪了 git 救不回!")
        if input("確定刪除?輸入 y 繼續、其他取消: ").strip().lower() != "y":
            print("已取消。")
            return 1
```

Finally, replace the step-3 placeholder comment:

```python
    # step 3 刪架構圖 vault:Task 7 加入(此處暫不刪)
```

with:

```python
    if will_delete_vault:                    # step 3 刪架構圖(pre-flight + 安全網已過)
        import shutil
        shutil.rmtree(vault)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "deinit graph"`
Expected: all `✓`.

- [ ] **Step 5: Run the full suite (no regression)**

Run: `python3 scripts/test_lumos.py`
Expected: `N passed, 0 failed`.

- [ ] **Step 6: Manual smoke test of the interactive confirm path**

Run (in a throwaway repo) to confirm the interactive `y` prompt works — the automated tests only cover `--yes`/non-tty:
```bash
tmp=$(mktemp -d); git -C "$tmp" init -q
git -C "$tmp" config core.hooksPath scripts/hooks
mkdir -p "$tmp/docs/demo-knowledge/MOC" "$tmp/scripts/hooks"; echo x > "$tmp/docs/demo-knowledge/MOC/i.md"
( cd "$tmp" && printf 'n\n' | python3 /Users/enzo/harness/lumos-toolchain/scripts/lumos deinit )
```
Expected: prints the manifest, reads `n`, prints `已取消。`, vault still present.

- [ ] **Step 7: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): deinit 架構圖刪除 + 三道安全網 + vault==root 鐵閘 + --dry-run"
```

---

### Task 8: Documentation — README / README.en / ONBOARDING

**Files:**
- Modify: `README.md` (the uninstall-related section)
- Modify: `README.en.md` (the parallel section)
- Modify: `ONBOARDING.md` (if it has an uninstall/exit section)

**Interfaces:** none (docs only).

- [ ] **Step 1: Locate the uninstall mentions**

Run: `grep -n "uninstall\|卸載\|解除\|deinit" README.md README.en.md ONBOARDING.md`
Expected: shows the existing machine-layer `lumos uninstall` references (and any list/table enumerating commands — update all of them, per [[knowledge-sync-scatter-needs-mechanical-guard]], not just the most obvious one).

- [ ] **Step 2: Add the project-layer / machine-layer split to `README.md`**

In the section that currently documents `lumos uninstall`, add the two-layer distinction. Use this content (adapt heading level to the surrounding doc):

```markdown
### 卸載

Lumos 是兩層安裝,對應兩個指令:

- **專案層**(本 repo 的 hooks/工具組/CLAUDE.md 注入/架構圖):在專案內跑
  ```bash
  lumos deinit            # 完整逆轉 init:拆閘 + 移工具組 + 剝 CLAUDE.md 區塊 + 刪架構圖(互動確認)
  lumos deinit --keep-graph   # 保留架構圖,只拆其餘
  lumos deinit --dry-run      # 只預演,不改動
  ```
  deinit 不自動 commit、不碰機器共用項;偵測到 standalone vault(架構圖=repo 根)會自動保留架構圖以防誤刪整個 repo。
- **機器層**(全域 `~/.local/bin/lumos`、user-scope skills):`lumos uninstall`。

> 完整卸載 = 在每個專案跑 `lumos deinit`,最後 `lumos uninstall` + 視需要 `rm -rf ~/harness/lumos-toolchain`。
```

- [ ] **Step 3: Mirror the content into `README.en.md`**

Add the equivalent English section next to its `lumos uninstall` mention:

```markdown
### Uninstalling

Lumos installs in two layers, with one command each:

- **Project layer** (this repo's hooks / vendored toolkit / CLAUDE.md injection / graph), run inside the project:
  ```bash
  lumos deinit              # full reverse of init: unbar gate + remove toolkit + strip CLAUDE.md block + delete graph (interactive confirm)
  lumos deinit --keep-graph # keep the graph, remove everything else
  lumos deinit --dry-run    # preview only, change nothing
  ```
  deinit never auto-commits and never touches machine-shared items; if it detects a standalone vault (graph == repo root) it force-keeps the graph to avoid deleting the whole repo.
- **Machine layer** (global `~/.local/bin/lumos`, user-scope skills): `lumos uninstall`.

> Full removal = run `lumos deinit` in each project, then `lumos uninstall` + optionally `rm -rf ~/harness/lumos-toolchain`.
```

- [ ] **Step 4: Update `ONBOARDING.md` if applicable**

If `grep` in Step 1 found an uninstall/exit section in `ONBOARDING.md`, add a one-line pointer: `專案層卸載用 lumos deinit、機器層用 lumos uninstall(見 README「卸載」段)`. If no such section exists, skip (note it in the commit message).

- [ ] **Step 5: Verify the docs render and reference correct flags**

Run: `grep -n "deinit" README.md README.en.md ONBOARDING.md`
Expected: the new sections appear with the four flags (`--keep-graph`, `--dry-run`, `-y/--yes`, `--source`) consistent with the `deinit` subparser from Task 6.

- [ ] **Step 6: Commit**

```bash
git add README.md README.en.md ONBOARDING.md
git commit -m "docs: 補 lumos deinit(專案層)與 uninstall(機器層)的卸載分工"
```

---

## Self-Review

**Spec coverage** (§ = design spec sections):
- §1 install/uninstall table → Task 6 (unbar, vendored, claude) + Task 7 (graph) + Task 8 (docs split). Machine-shared items never touched (no task removes `~/.claude/*`). ✓
- §2 flags (`--keep-graph`/`--dry-run`/`-y`/`--source`) → Task 6 subparser; behavior in Task 6 (source) + Task 7 (keep-graph/dry-run/yes). ✓
- §2 idempotent + heuristic + `-C root` + non-git abort → Task 5 (heuristic) + Task 6 (idempotent, non-git abort). ✓
- §3 fixed order (unbar→strip→graph→vendored) + pre-flight first → Task 6 order; Task 7 inserts graph at step 3 and the pre-flight gates before any mutation. ✓
- §4 three gates → Task 7; whitelist + CLAUDE strip → Tasks 3/4; source self-protection → Task 6; `vault==root` iron gate → Task 7. ✓
- §5 implementation anchors (`_VENDORED_TOOLKIT`, `cmd_deinit` near `cmd_uninstall`, vault-free dispatch) → Tasks 1, 6. ✓
- §6 test cases 1–11 → case 1/4/5/6/7 (Tasks 6–7), 2/3/8/9/10 (Task 7), 11 (Task 3 `_deinit_strip_claude` no-op + exercised end-to-end). ✓
- §7 docs → Task 8. ✓

**Placeholder scan:** No "TBD"/"add error handling"/"similar to". The Task 6 `will_delete_vault = False` stub is intentional and explicitly replaced in Task 7 Step 3 with the exact replacement line shown. ✓

**Type consistency:** `_VENDORED_TOOLKIT` (tuple of str) defined in Task 1, consumed in Task 4. Helper signatures (`_deinit_unbar_gate`/`_deinit_strip_claude`/`_deinit_remove_vendored`/`_deinit_detect_installed`/`_claude_block_present`) defined in Tasks 2–5, consumed in Task 6's `cmd_deinit`. `cmd_deinit(keep_graph, dry_run, yes, source)` signature matches the dispatch call and subparser args in Task 6. Test helpers `_load_lumos`/`_mk_installed_project`/`_deinit_run` defined once (Tasks 2/6) and reused. ✓
