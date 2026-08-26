# 原生 Windows 支援 Implementation Plan(交 Windows 端執行)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓 lumos 在原生 Windows(PowerShell,不開 bash)能裝能用——安裝邏輯收進跨平台 python(單一源),Windows 經 `get.ps1` 進來,junction(skills 目錄)+ `.cmd` shim(全域 lumos)+ 個別 `.py` 用 copy。

**Architecture:** S2(邏輯進 python CLI)+ A(完全收斂、bash 安裝器瘦成薄殼)。設計全文與 3 輪 design-loop 審計紀錄見 `docs/design/2026-06-26-native-windows-support.md`。

**Tech Stack:** python(`scripts/lumos` 純標準庫)、PowerShell(`get.ps1`)、bash(hooks 維持)、自訂 runner `scripts/test_lumos.py`(`t_` 前綴 + `check()`,**非 pytest**)。

## ⚠ 給 Windows 執行端的前提(最重要)

1. **這份未經 Windows 驗證**:設計過 3 輪 design-loop(約 10 真 findings 已折),但 **Mac 端無法驗 junction/.cmd shim/settings 遷移/python3-vs-python**。**Task 7 的手動清單是真正的放行閘**——實作後務必在這台 Windows 跑完、回報哪步壞。
2. **這不是 Windows-only 加法,會改到 Unix/Mac 共用路徑**:`cmd_install` 語義變(連帶裝 skills)、`merge-claude-settings.py` 會遷移既有 `~/.claude/settings.json`、`lumos init` 從 5 夾變 6 夾。**每個 Task 都有 Unix 回歸測試**,別讓 Windows 改動弄壞 Mac。
3. **前置環境**:Git for Windows(自帶 bash 跑 hooks)、python on PATH(`python` 或 `python3`)、Claude Code、Python ≥ 3.8(`shutil.copytree(dirs_exist_ok=)`)。
4. **多 Task 改同一檔 `scripts/lumos`**:**用函式名/錨點定位,不靠絕對行號**(行號會隨前面 Task 位移)。

## Global Constraints

- **單一源**:安裝邏輯只在 python 一份;bash 安裝器瘦成薄殼或刪。
- **零權限 Windows**:skills 目錄用 junction(`mklink /J`)、全域 lumos 用 `.cmd` shim、個別 `.py` 檔用 copy(junction 不能連檔)、任一失敗 fallback `shutil.copytree(dirs_exist_ok=True)`/`copy2`。
- **junction 失敗才 fallback**(非跨碟判斷;junction 可跨碟)。
- **hooks 維持 bash**,只補 `python3 → python` fallback;Claude hooks 註冊用 resolved 直譯器。
- **既有坐實行號**(dispatch 當下,會位移):`cmd_install@2961`/PATH 檢查`@2982`、`_vendor_toolchain` def`@3013` bash call`@3031`、`_INIT_SUBDIRS@3122`、`cmd_bootstrap` bash`@3103`/`@3115`、`get.sh` install`@24`、`merge-claude HOOK_ENTRIES@14-32` `_equivalent@46-48`、`install-hooks.sh` claude 複製`@103-145`、`install.sh:28 SKILLS`。

---

### Task 0:Windows 行尾/編碼地基(前置——建立可用的綠底 oracle)

**⚠ 為何必須最先做**(真機發現,非紙上):真 Windows `python scripts/test_lumos.py` baseline = **147 過 / 29 敗(23 測試函式)**。根因:`scripts/lumos` 與 `test_lumos.py` 都用 `write_text(..., encoding="utf-8")`(無 `newline=`),Windows text mode 把 `\n`→`\r\n`,lumos **自己寫出 CRLF、`load_raw_for_edit@2564` 又拒絕 CRLF**(自相矛盾)。沒修這層,Task 1–6 的「測試紅→綠」沒有可信 oracle(會被 29 個 CRLF 紅淹沒)。**Mac 端已坐實所有觸點存在、`write_text(newline=)` 是 3.10+ 故用 `write_bytes`。**

**Files:**
- Modify: `scripts/lumos`(加 `_write_lf`;`atomic_write_verify`/`cmd_new`/`cmd_guard_scaffold`/`cmd_archive`/`cmd_init` 改走它)
- Modify: `scripts/test_lumos.py`(`write()` helper + 直寫 fixture 改 LF;`t_export_quote_escape` win32 skip;stdout 強制 UTF-8)
- Create: `.gitattributes`(repo root)

**Interfaces:**
- Produces:`_write_lf(path:Path, text:str)→None`(寫 UTF-8/LF/no-BOM,不受平台 text mode 影響)。
- 不變:`load_raw_for_edit` 的 CRLF 拒絕語義保留(vault 慣例 LF 刻意;修的是「寫」不是「讀」)。

- [ ] **Step 1:寫失敗測試(Windows 重現 CRLF 自相矛盾;Mac 恆綠)**

`scripts/test_lumos.py` 加:
```python
def t_write_lf_roundtrip():
    import subprocess
    proj = Path(tempfile.mkdtemp(prefix="gctl-lf-"))
    (proj / "Systems").mkdir(parents=True); (proj / "MOC").mkdir()
    (proj / "MOC" / "idx.md").write_bytes(b"---\ntype: moc\n---\n# idx\n")
    write(proj, "Systems/S.md", "type: system\nstatus: doing")     # 經 write() helper
    raw = (proj / "Systems" / "S.md").read_bytes()
    check("write helper 寫 LF(無 CRLF)", b"\r\n" not in raw, f"got {raw[:40]!r}")
    r = subprocess.run([sys.executable, GRAPHCTL, "set", str(proj / "Systems" / "S.md"),
                        "status", "done"], capture_output=True, text=True)
    raw2 = (proj / "Systems" / "S.md").read_bytes()
    check("atomic_write_verify 寫回 LF", b"\r\n" not in raw2, f"rc={r.returncode} {r.stderr}")
```

- [ ] **Step 2:跑測試確認失敗**

Run: `python scripts/test_lumos.py 2>&1 | grep -iE "LF|✗" | head`
Expected(Windows):LF 兩測 + 既有 append/decision/set/guard/sync 一片紅(同根因)。Mac:恆綠(write_bytes 在 Mac 也寫 LF)。

- [ ] **Step 3:`scripts/lumos` 加 `_write_lf` 並收斂所有內容寫入**

寫入工具區(`atomic_write_verify@2581` 定義前)加:
```python
def _write_lf(path: Path, text: str):
    """寫 UTF-8 / LF / no-BOM,平台無關(不靠 text mode)。vault 唯一寫入原語。
    用 write_bytes:write_text(newline=) 要 Python 3.10,違反本專案 ≥3.8。"""
    path.write_bytes(text.encode("utf-8"))
```
把下列 `X.write_text(<content>, encoding="utf-8")` 改 `_write_lf(X, <content>)`(**用函式名定位,行號會位移**):
- `atomic_write_verify`(`@2600` `tmp.write_text`)← **單一收斂點,修這個=修掉 set/append/decision/guard/sync 全部**
- `cmd_new`(`@2812` `path.write_text(f"---\n{fm}...")`)
- `cmd_guard_scaffold`(`@1557` `target.write_text`)
- `cmd_archive`(`@2938` rewrite `tmp.write_text`)
- `cmd_init`(`@3164` `gi.write_text(_INIT_GITIGNORE)`)
- (非 vault:`_fetch` cache `@2377`、export html `@2403` CRLF 無害;一致起見可一併改,非放行條件。)

- [ ] **Step 4:`test_lumos.py` fixture 改 LF + 修 Windows 不相容測試**

(a) `write()` helper(`@47`)`write_text`→`write_bytes`:
```python
def write(vault, rel, fm, body="# x\n"):
    p = vault / rel; p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(f"---\n{fm}\n---\n{body}".encode("utf-8"))
    return p
```
(b) 其餘直寫 fixture(`MOC/idx.md`、`.lumos/config.json`、`*.cs/*.kt/*.tmpl` 等)一律 `write_text(...)`→`write_bytes(<str>.encode("utf-8"))`。grep 定位:`grep -n "write_text" scripts/test_lumos.py`。
(c) `t_export_quote_escape`:NTFS 禁 `"`,開頭加 `if sys.platform == "win32": check("export quote: NTFS 禁 \" 字元,Windows skip", True); return`。

- [ ] **Step 5:runner 強制 UTF-8 stdout(cp950 主控台不 crash)**

`scripts/test_lumos.py` 頂(import 後)加:
```python
try:
    sys.stdout.reconfigure(encoding="utf-8")   # cp950 印 ✓/✗ 會 UnicodeEncodeError
except Exception:
    pass
```
(可選:`scripts/lumos` 入口同樣處理,免使用者要設 `PYTHONUTF8=1`。)

- [ ] **Step 6:加 `.gitattributes`(根治 clone 端 autocrlf)**

repo root 建 `.gitattributes`(`load_raw_for_edit` 錯誤訊息本就叫使用者這樣做,理應內建):
```
* text=auto eol=lf
*.md text eol=lf
scripts/lumos text eol=lf
*.py text eol=lf
*.sh text eol=lf
*.ps1 text eol=crlf
```

- [ ] **Step 7:跑測試 + 全平台回歸**

Run: `python scripts/test_lumos.py 2>&1 | tail -2`
Expected:全綠(Windows 與 Mac 皆無回歸)——這才是 Task 1–6 可信的紅綠 oracle。Mac:`write_bytes` 同寫 LF,行為不變。

- [ ] **Step 8:Commit**

```bash
git add scripts/lumos scripts/test_lumos.py .gitattributes
git commit -m "fix(win): 內容寫入強制 LF(_write_lf)+ runner UTF-8 stdout + .gitattributes

修 lumos 在 Windows 寫 CRLF 又拒絕自己;真 Windows baseline 147/29→全綠,為 Task 1-6 建可信 oracle。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

> **對後續 Task 的連動**:Task 0 完成後,Task 1 Step 2「Expected: scaffold 測失敗」等紅綠判讀才成立(否則被 CRLF 紅淹沒)。Task 7 真機閘第 4/6 步(`lumos init` 寫檔、pre-commit 擋)也依賴 lumos 不再寫 CRLF。

---

### Task 1:平台 helper + 安裝原語(跨平台、可測)

**Files:**
- Modify: `scripts/lumos`(module 頂加 `_IS_WIN`;`cmd_bootstrap` 附近加 `_install_skills`/`_scaffold_project`/`_install_hooks_py`)
- Test: `scripts/test_lumos.py`(加 `t_scaffold_project` / `t_install_hooks_py` / `t_install_skills_unix`)

**Interfaces:**
- Produces:`_IS_WIN`、`_install_skills()→None`、`_scaffold_project(root:Path, slug:str)→None`、`_install_hooks_py(root:Path)→None`。

- [ ] **Step 1:寫失敗測試**

`scripts/test_lumos.py` 加(用 `subprocess`/`tempfile`,跨平台):

```python
def t_scaffold_project():
    import subprocess, sys
    proj = Path(tempfile.mkdtemp(prefix="gctl-scaf-"))
    r = subprocess.run([sys.executable, GRAPHCTL, "init", "--name", "demo", "--no-hooks"],
                       cwd=str(proj), capture_output=True, text=True)
    kg = proj / "docs" / "demo-knowledge"
    for d in ("Systems", "Verification", "Projects", "Issues", "Sessions", "MOC"):
        check(f"scaffold: 建 {d} 夾", (kg / d).is_dir(), f"rc={r.returncode} {r.stderr}")
    check("scaffold: MOC/index.md", (kg / "MOC" / "index.md").exists(), "")
    check("scaffold: .gitignore", (kg / ".gitignore").exists(), "")

def t_install_skills_unix():
    if sys.platform == "win32":
        check("skills: Windows 分支留 Task 7 手動驗", True); return
    import subprocess
    r = subprocess.run([sys.executable, GRAPHCTL, "install", "--force"], capture_output=True, text=True)
    dst = Path.home() / ".claude" / "skills" / "lumos-project-notes"
    check("skills: ~/.claude/skills/lumos-project-notes 連結存在", dst.exists(), r.stderr)
```

(`t_install_hooks_py` 在 Task 3 settings 改完後補完整;此處先測 hooksPath。)

- [ ] **Step 2:跑測試確認失敗**

Run: `python3 scripts/test_lumos.py 2>&1 | grep -iE "scaffold|skills|✗"`
Expected: scaffold 測失敗(目前 `_INIT_SUBDIRS` 只 5 夾、缺 Sessions)。

- [ ] **Step 3:加 `_IS_WIN` + `_install_skills`**

`scripts/lumos` module 頂(`import` 區附近)加:
```python
_IS_WIN = os.name == "nt"
```

在 `cmd_bootstrap` 定義(`@3065` 附近)之前加:
```python
_SKILLS = ("lumos-project-notes", "lumos-core-knowledge", "lumos-design-loop")  # 同 install.sh:28

def _link_or_copy(src: Path, dst: Path):
    """src→dst:Unix symlink、Win 目錄 junction、失敗 fallback 複製。src 須為目錄。"""
    import shutil, subprocess
    if dst.is_symlink() or dst.exists():
        if dst.is_dir() and not dst.is_symlink():
            shutil.rmtree(dst, ignore_errors=True)
        else:
            dst.unlink()
    dst.parent.mkdir(parents=True, exist_ok=True)
    try:
        if _IS_WIN:
            r = subprocess.run(["cmd", "/c", "mklink", "/J", str(dst), str(src)],
                               capture_output=True, text=True)
            if r.returncode != 0:
                raise OSError(r.stderr)
        else:
            dst.symlink_to(src)
    except OSError:
        shutil.copytree(src, dst, dirs_exist_ok=True)  # Python ≥ 3.8
        print(f"  ⚠ 連結失敗,改複製(失去 git pull 即更新): {dst}")

def _install_skills():
    repo = Path(__file__).resolve().parent.parent
    dest = Path.home() / ".claude" / "skills"
    for s in _SKILLS:
        src = repo / "skills" / s
        if src.is_dir():
            _link_or_copy(src, dest / s)
            print(f"  ✓ skill {s}")
```

- [ ] **Step 4:加 `_scaffold_project`(6 夾含 Sessions)**

在 `_install_skills` 後加(取代 `install-graph-toolchain.sh` 的 scaffold/CLAUDE.md 主體):
```python
_INIT_SUBDIRS_FULL = ("Systems", "Verification", "Projects", "Issues", "Sessions", "MOC")

def _scaffold_project(root: Path, slug: str):
    kg = root / "docs" / f"{slug}-knowledge"
    if kg.exists():
        print(f"  ✓ vault 已存在,跳過 scaffold(保護資料): {kg}")
        return
    for d in _INIT_SUBDIRS_FULL:
        (kg / d).mkdir(parents=True, exist_ok=True)
    (kg / "MOC" / "index.md").write_text(
        f"---\ntype: moc\nstatus: doing\n---\n# {slug} 知識架構圖總索引\n", encoding="utf-8")
    (kg / ".gitignore").write_text(".bypass-log.jsonl\n.rot-queue.jsonl\n.governance-log.jsonl\n.canary-log.jsonl\n", encoding="utf-8")
    # CLAUDE.md 注入 graph-discipline 區塊(用既有範本,變數替換)
    tpl = root / "scripts" / "templates" / "graph-discipline.md"
    if tpl.exists():
        body = tpl.read_text(encoding="utf-8").replace("{{KG}}", f"docs/{slug}-knowledge/").strip()
        START = "<!-- LUMOS:GRAPH-DISCIPLINE:START — 自動注入/更新,勿手改本區塊;改範本 scripts/templates/graph-discipline.md -->"
        END = "<!-- LUMOS:GRAPH-DISCIPLINE:END -->"
        block = START + "\n" + body + "\n" + END
        cm = root / "CLAUDE.md"
        if not cm.exists():
            cm.write_text("# CLAUDE.md\n\n" + block + "\n", encoding="utf-8")
        elif "LUMOS:GRAPH-DISCIPLINE:START" not in cm.read_text(encoding="utf-8"):
            t = cm.read_text(encoding="utf-8")
            cm.write_text(t.rstrip() + "\n\n" + block + "\n", encoding="utf-8")
    print(f"  ✓ scaffold {kg}")
```

(注:`_INIT_SUBDIRS@3122` 舊的 5 夾 + Jenny `cmd_init` 的 scaffold 由 Task 5 改接 `_scaffold_project`;此處先建函式。)

- [ ] **Step 5:加 `_install_hooks_py`(hooksPath + 複製 claude .py 用 copy)**

```python
def _install_hooks_py(root: Path):
    import subprocess, shutil
    # ① git config core.hooksPath
    subprocess.run(["git", "-C", str(root), "config", "core.hooksPath", "scripts/hooks"])
    # ② 複製 Claude hooks 到 ~/.claude/hooks/(個別 .py 一律 copy,不用 junction:mklink /J 只連目錄)
    chooks = Path.home() / ".claude" / "hooks"
    chooks.mkdir(parents=True, exist_ok=True)
    src_dir = root / "scripts" / "hooks" / "claude"
    for f in ("check-graph-sync.py", "verification-rot-check.py"):
        s = src_dir / f
        if s.exists():
            shutil.copy2(s, chooks / f)
    # ③ settings.json 註冊(Task 3 改 merge-claude-settings.py 用 resolved python)
    merge = root / "scripts" / "merge-claude-settings.py"
    if merge.exists():
        subprocess.run([__import__("sys").executable, str(merge)])
    print("  ✓ hooks:core.hooksPath + Claude hooks 複製 + settings 註冊")
```

- [ ] **Step 6:改 `_INIT_SUBDIRS` 補 Sessions(修 Jenny 既有漏)**

`scripts/lumos@3122` `_INIT_SUBDIRS = ("Projects", "Systems", "Issues", "Verification", "MOC")` 改為含 Sessions:
```python
_INIT_SUBDIRS = ("Projects", "Systems", "Issues", "Verification", "Sessions", "MOC")
```
(若 Task 5 讓 Jenny `cmd_init` 改用 `_scaffold_project`,此常數可能變冗餘——Task 5 處理;此處先補齊一致。)

- [ ] **Step 7:跑測試 + 回歸**

Run: `python3 scripts/test_lumos.py 2>&1 | tail -3`
Expected: 全綠(scaffold 6 夾、skills unix 連結、既有測試無回歸)。

- [ ] **Step 8:Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(install): 平台 helper + python 安裝原語(_install_skills/_scaffold_project/_install_hooks_py)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2:`cmd_install` = 全域 lumos + skills(+ os.pathsep 修)

**Files:**
- Modify: `scripts/lumos`(`cmd_install@2961`)
- Test: `scripts/test_lumos.py`(`t_install_includes_skills`)

**Interfaces:**
- Consumes:`_install_skills`(Task 1)、`_IS_WIN`。
- Produces:`cmd_install` 後 `~/.local/bin/lumos`(Unix)或 `lumos.cmd`(Win)+ skills 都在。

- [ ] **Step 1:寫失敗測試(Unix 回歸——install 後 skills 也在)**

```python
def t_install_includes_skills():
    if sys.platform == "win32":
        check("install+skills: Windows 留 Task 7 手動驗", True); return
    import subprocess
    subprocess.run([sys.executable, GRAPHCTL, "install", "--force"], capture_output=True, text=True)
    g = Path.home() / ".local" / "bin" / "lumos"
    sk = Path.home() / ".claude" / "skills" / "lumos-design-loop"
    check("install: 全域 lumos 在", g.exists(), "")
    check("install: 連帶 skills 也在", sk.exists(), "")
```

- [ ] **Step 2:跑確認失敗**(現 `cmd_install` 不裝 skills)

Run: `python3 scripts/test_lumos.py 2>&1 | grep -iE "install.*skills|✗"`

- [ ] **Step 3:擴充 `cmd_install`**

`cmd_install@2961`:① 全域指令分平台 ② 結尾呼叫 `_install_skills()` ③ PATH 檢查改 `os.pathsep`。把整個函式換成:

```python
def cmd_install(force=False):
    """全域 lumos + user-scope skills(機器層一鍵)。Unix=symlink、Win=.cmd shim。"""
    import os
    src = Path(__file__).resolve()
    bindir = Path.home() / ".local" / "bin"
    bindir.mkdir(parents=True, exist_ok=True)
    if _IS_WIN:
        shim = bindir / "lumos.cmd"
        shim.write_text(f'@echo off\r\npython "{src}" %*\r\n', encoding="utf-8")
        print(f"✓ 安裝: {shim} → python {src}")
    else:
        dst = bindir / "lumos"
        if dst.is_symlink() and dst.resolve() == src:
            print(f"✓ 已安裝(symlink 正確): {dst} → {src}")
        elif dst.exists() or dst.is_symlink():
            if not force:
                cur = str(dst.resolve()) if dst.is_symlink() else "(一般檔案)"
                print(f"⚠ {dst} 已存在(→ {cur}),加 --force 覆寫", file=sys.stderr)
                return 2
            dst.unlink(); dst.symlink_to(src); print(f"✓ 覆寫安裝: {dst} → {src}")
        else:
            dst.symlink_to(src); print(f"✓ 安裝: {dst} → {src}")
    # 連帶裝 skills(r2-F1:機器層一鍵)
    print("裝 user-scope skills…")
    _install_skills()
    # PATH 檢查(r1-F7:用 os.pathsep,Windows 是 ;)
    if str(bindir) not in os.environ.get("PATH", "").split(os.pathsep):
        hint = (f'  Windows:把 {bindir} 加進使用者 PATH(系統環境變數)'
                if _IS_WIN else f'  export PATH="$HOME/.local/bin:$PATH"')
        print(f"⚠ {bindir} 不在當前 PATH —\n{hint}", file=sys.stderr)
    else:
        print(f"  {bindir} 已在 PATH — 任何專案打 `lumos doctor` 即可")
    return 0
```

- [ ] **Step 4:跑測試 + 回歸**(Mac 上應通過,且你自己的 skills 被重連——確認 `lumos doctor` 仍正常)

Run: `python3 scripts/test_lumos.py 2>&1 | tail -2 && python3 scripts/lumos doctor >/dev/null 2>&1 && echo "doctor OK"`

- [ ] **Step 5:Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(install): cmd_install = 全域 lumos + skills 一起(Win .cmd shim、os.pathsep 修)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3:`merge-claude-settings.py` resolved-python + 按路徑去重遷移

**Files:**
- Modify: `scripts/merge-claude-settings.py`
- Test: `scripts/test_lumos.py`(`t_merge_settings_dedupe`)

**Interfaces:**
- Produces:settings.json hook command = `<resolved-python> <path>`;同 hook 路徑只一筆(遷移取代舊格式)。

**⚠ 最高風險 Task**:會遷移你 Mac 的 live `~/.claude/settings.json`(現為舊裸路徑格式)。測試用 temp settings、不碰 live;但實跑 `lumos init`/`bootstrap` 會動到——先確認測試綠再跑。

- [ ] **Step 1:寫失敗測試(去重遷移:舊格式 + 新格式 = 同 hook 只一筆)**

```python
def t_merge_settings_dedupe():
    import subprocess, json, os
    tmp = Path(tempfile.mkdtemp(prefix="gctl-settings-"))
    fake_home = tmp
    settings = fake_home / ".claude" / "settings.json"
    settings.parent.mkdir(parents=True)
    # 既有:舊裸路徑格式
    settings.write_text(json.dumps({"hooks": {"Stop": [
        {"hooks": [{"type": "command", "command": "${HOME}/.claude/hooks/check-graph-sync.py", "timeout": 10}]}
    ]}}), encoding="utf-8")
    env = dict(os.environ, HOME=str(fake_home), USERPROFILE=str(fake_home))
    merge = str(Path(GRAPHCTL).resolve().parent / "merge-claude-settings.py")
    subprocess.run([sys.executable, merge], env=env, capture_output=True, text=True)
    data = json.loads(settings.read_text(encoding="utf-8"))
    stop = data["hooks"]["Stop"]
    cmds = [h["command"] for e in stop for h in e["hooks"] if "check-graph-sync" in h["command"]]
    check("merge: check-graph-sync 同 hook 只一筆(去重遷移)", len(cmds) == 1, f"got {len(cmds)}: {cmds}")
```

- [ ] **Step 2:跑確認失敗**(現會變兩筆——舊裸路徑 + 新格式並存)

Run: `python3 scripts/test_lumos.py 2>&1 | grep -iE "merge|✗"`

- [ ] **Step 3:改 `merge-claude-settings.py`**

(a) 頂部加 resolved python + 用它組 command:
```python
import shutil
_PY = shutil.which("python3") or shutil.which("python") or "python3"

def _hook_cmd(rel_path):  # rel_path = "verification-rot-check.py"
    return f'{_PY} "${{HOME}}/.claude/hooks/{rel_path}"'
```
把 `HOOK_ENTRIES` 的 `"command": "${HOME}/.claude/hooks/xxx.py"` 改成 `"command": _hook_cmd("xxx.py")`。

(b) `_equivalent`(`@46-48`)改成**按 hook 腳本檔名**比對(認出舊裸路徑 == 新 `python …/xxx.py` 為同一 hook):
```python
import re
def _hook_script(cmd: str):
    m = re.search(r"([\w.-]+\.py)", cmd or "")
    return m.group(1) if m else cmd

def _equivalent(a: dict, b: dict) -> bool:
    if a.get("matcher") != b.get("matcher"):
        return False
    a_s = sorted(_hook_script(h.get("command", "")) for h in a.get("hooks", []))
    b_s = sorted(_hook_script(h.get("command", "")) for h in b.get("hooks", []))
    return a_s == b_s
```

(c) main 迴圈:命中既有(同 hook 路徑)時**取代成新格式**而非 skip(遷移)。把 `if any(_equivalent(...)): print skip; continue` 改:
```python
            match_idx = next((i for i, e in enumerate(existing) if _equivalent(new_entry, e)), None)
            if match_idx is not None:
                if existing[match_idx] != new_entry:
                    existing[match_idx] = new_entry  # 遷移:取代成 resolved-python 格式
                    print(f"  [migrate] {event} hook → resolved-python"); changed = True
                else:
                    print(f"  [skip] {event} hook already current")
                continue
            existing.append(new_entry); print(f"  [add ] {event} hook"); changed = True
```

- [ ] **Step 4:跑測試 + Unix 回歸**(確認你 Mac 的 L1/L3 仍觸發)

Run: `python3 scripts/test_lumos.py 2>&1 | tail -2`
然後手動:`python3 scripts/merge-claude-settings.py`(會遷移你 live settings)→ 確認 `~/.claude/settings.json` 每個 hook 只一筆、格式為 `python3 ${HOME}/.claude/hooks/...`;重啟 Claude Code 動 code 確認 L1 仍提醒。

- [ ] **Step 5:Commit**

```bash
git add scripts/merge-claude-settings.py scripts/test_lumos.py
git commit -m "fix(hooks): claude hooks 註冊用 resolved-python + 按路徑去重遷移(Windows shebang 不認;防雙重註冊)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4:git hooks `python3 → python` fallback

**Files:**
- Modify: `scripts/hooks/post-commit`、`scripts/hooks/pre-push`
- Test: grep 斷言(`t_hooks_python_fallback`)

- [ ] **Step 1:寫測試(grep 斷言 hook 含 fallback 形)**

```python
def t_hooks_python_fallback():
    import pathlib
    repo = pathlib.Path(GRAPHCTL).resolve().parent.parent
    for h in ("post-commit", "pre-push"):
        t = (repo / "scripts" / "hooks" / h).read_text(encoding="utf-8")
        check(f"{h}: 有 python3||python fallback",
              "command -v python3 || command -v python" in t, "缺 fallback")
```

- [ ] **Step 2:跑確認失敗**

- [ ] **Step 3:改兩個 hook**

`scripts/hooks/pre-push`:把 `PY="$(command -v python3 || true)"` 改 `PY="$(command -v python3 || command -v python || true)"`。

`scripts/hooks/post-commit`:`python3 - "$BYPASS_LOG" <<'PYEOF'` 改成先解析 `PY="$(command -v python3 || command -v python)"` 再 `"$PY" - "$BYPASS_LOG" <<'PYEOF'`(若該 hook 無 PY 變數則在 python3 呼叫前加一行解析)。

- [ ] **Step 4:跑測試 + Mac 回歸**(Mac 有 python3,fallback 不觸發、行為不變)

Run: `python3 scripts/test_lumos.py 2>&1 | tail -2`

- [ ] **Step 5:Commit**

```bash
git add scripts/hooks/post-commit scripts/hooks/pre-push scripts/test_lumos.py
git commit -m "fix(hooks): post-commit/pre-push python3→python fallback(Windows 常只有 python)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5:接線收斂(get.ps1 新 + get.sh 瘦 + cmd_init/bootstrap 改 python + 薄殼)

**Files:**
- Create: `get.ps1`(repo root)
- Modify: `get.sh`、`scripts/lumos`(`_vendor_toolchain@3013`/`cmd_bootstrap@3103,3115`/Jenny `cmd_init`)、`install.sh`/`scripts/install-graph-toolchain.sh`/`scripts/install-hooks.sh`(瘦薄殼)

**Interfaces:**
- Consumes:`_scaffold_project`/`_install_hooks_py`/`cmd_install`(Task 1/2)。

- [ ] **Step 1:`_vendor_toolchain` 換純 python**

`_vendor_toolchain@3013` 內 `subprocess.run(["bash", str(installer), ...])`(`@3031`)那段,換成:
```python
    _scaffold_project(root, slug)
    _install_hooks_py(root)
    rc = 0
```
(保留前面的 git pull + 後面的「結尾自癒」toolkit 複製;只換中間 bash 呼叫。)

- [ ] **Step 2:`cmd_init`(Jenny)改用 `_scaffold_project`/`_install_hooks_py`**

Jenny `cmd_init` 內若直接 mkdir `_INIT_SUBDIRS` + `bash install-hooks.sh`,改呼叫 `_scaffold_project(root, slug)` + `_install_hooks_py(root)`,移除 `_INIT_SUBDIRS`/`_INIT_GITIGNORE` 重複(單一源)。grep 定位:`grep -n "_INIT_SUBDIRS\|install-hooks" scripts/lumos`。

- [ ] **Step 3:`cmd_bootstrap` 刪 bash install 行**

`cmd_bootstrap`:刪 `@3103` `subprocess.run(["bash", str(home / "install.sh")])`(skills 由 `cmd_install` 連帶裝)、`@3115` `bash install-hooks.sh` 改 `_install_hooks_py(root)`。`@3093` 的 `lumos install` 已含 skills。

- [ ] **Step 4:`get.sh` 瘦(刪 bash install.sh)**

`get.sh:21` 的 `bash "$LUMOS_HOME/install.sh"` 刪掉(`:24` `python3 lumos install --force` 已含 skills);結尾提示對齊。

- [ ] **Step 5:建 `get.ps1`(repo root)**

```powershell
# get.ps1 — 用法:  irm https://raw.githubusercontent.com/EnzoHsieh-Android/Lumos/main/get.ps1 | iex
$ErrorActionPreference = "Stop"
$homeDir = if ($env:LUMOS_HOME) { $env:LUMOS_HOME } else { "$HOME\harness\lumos-toolchain" }
$url = if ($env:LUMOS_URL) { $env:LUMOS_URL } else { "https://github.com/EnzoHsieh-Android/Lumos" }
if (-not (Test-Path "$homeDir\scripts\lumos")) {
  New-Item -ItemType Directory -Force -Path (Split-Path $homeDir) | Out-Null
  git clone $url $homeDir
}
python "$homeDir\scripts\lumos" install --force    # = 全域 lumos.cmd + skills
Write-Host "`n✓ 機器層裝好。下一步:"
Write-Host "  1. 重啟 Claude Code session(L1/L3 hooks 在 session start 載入)"
Write-Host "  2. 進你的專案:cd <專案>; lumos init"
```

- [ ] **Step 6:瘦 bash 安裝器成薄殼**

`install.sh` / `scripts/install-graph-toolchain.sh` / `scripts/install-hooks.sh` 內容換成薄殼(保留檔名給舊文檔/離線),例 `install.sh`:
```bash
#!/usr/bin/env bash
# 薄殼:邏輯已收進 python 單一源(scripts/lumos)。保留供舊文檔/離線。
exec python3 "$(cd "$(dirname "$0")" && pwd)/scripts/lumos" install --force
```
(install-graph-toolchain.sh 薄殼 `exec python3 .../lumos init --name "$SLUG"` 解析既有 `--target`/`--slug` 旗標轉成 init;install-hooks.sh 薄殼呼叫一個 `lumos install-hooks` 子命令——或若太繞,install-hooks.sh 直接刪、文檔改指 `lumos init`。**實作端視情況選薄殼 or 刪**,但 toolkit 自癒清單 `@3034` 移除這三支。)

- [ ] **Step 7:跑測試 + Mac 回歸**

Run: `python3 scripts/test_lumos.py 2>&1 | tail -2`
手動:在 temp 專案 `python3 scripts/lumos init --name demo --no-hooks` → 6 夾 + CLAUDE.md;`lumos doctor` OK。

- [ ] **Step 8:Commit**

```bash
git add get.ps1 get.sh scripts/lumos install.sh scripts/install-graph-toolchain.sh scripts/install-hooks.sh
git commit -m "feat(install): get.ps1 Windows 入口 + 收斂接線(_vendor/cmd_init/bootstrap 走 python、bash 安裝器瘦薄殼)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6:文檔(README + ONBOARDING 加 Windows 段)

**Files:** Modify `README.md`、`ONBOARDING.md`

- [ ] **Step 1:README 加 Windows 段**(4b 附近)

```markdown
### 4c. Windows(原生 PowerShell)
前置:Git for Windows(自帶 bash 跑 hooks)、python on PATH、Claude Code。
\`\`\`powershell
irm https://raw.githubusercontent.com/EnzoHsieh-Android/Lumos/main/get.ps1 | iex
# 重啟 Claude Code session;把 %USERPROFILE%\.local\bin 加進 PATH(若 lumos 找不到)
cd <你的專案>; lumos init
\`\`\`
junction(skills)+ .cmd shim(全域 lumos)零權限;個別 hook 檔用複製。
```

- [ ] **Step 2:ONBOARDING 同步一句指向 Windows**

- [ ] **Step 3:回歸測試 + Commit**

```bash
git add README.md ONBOARDING.md
git commit -m "docs(install): README/ONBOARDING 加原生 Windows(get.ps1)段

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7:**真 Windows 手動驗收(放行閘——這才是真正的測試)**

在一台**真 Windows**(PowerShell)跑;任一步失敗即不放行,記到 spec 審計紀錄。

- [ ] 1. `irm …/get.ps1 | iex` → 印 `✓ 機器層裝好`,無報錯;`~\harness\lumos-toolchain` 有 clone。
- [ ] 2. 新開 PowerShell 打 `lumos` → 找得到(`.cmd` shim + PATH);找不到=PATH 沒加,照提示加 `%USERPROFILE%\.local\bin`。
- [ ] 3. `dir %USERPROFILE%\.claude\skills\lumos-project-notes` → 顯示 `<JUNCTION>`、內容指對(`type` 看得到檔)。
- [ ] 4. `cd <新專案>; lumos init` → `docs\<slug>-knowledge\` **6 夾(含 Sessions)** + `MOC\index.md` + `.gitignore`;`git config core.hooksPath` == `scripts/hooks`;`%USERPROFILE%\.claude\hooks\check-graph-sync.py` 存在。
- [ ] 5. `type %USERPROFILE%\.claude\settings.json` → hook command 是 `python3 ...` 或 `python ...`(resolved 直譯器);**每個 hook 只一筆**(無雙重註冊)。
- [ ] 6. 改一個 .py 不更新架構圖 → `git commit` 被 **pre-commit 擋**(git-for-win 用自帶 bash 跑 hook)。若沒擋=hook 沒生效或 python 沒 on PATH。
- [ ] 7. 重啟 Claude Code session → 動 code,L1 軟提醒出現(claude hook resolved-python 真跑);`lumos doctor` 綠。

**回報**:哪幾步過、哪步壞(附錯誤訊息)。壞的折回 spec 改、重驗。

---

### Task 8:Task 7 真機 findings 折真(W2/W3/W4)

**來源**:Task 7 跑完,6/7 步過,揪出 3 個 Mac 紙審 3 輪 + 跨平台單元測都摸不到的真機缺陷(OS 物理 / shell 語義邊界)。設計全文見 `docs/design/2026-06-26-native-windows-support.md` 第二筆真機回報。

**Files:**
- Modify: `scripts/lumos`(`_link_or_copy`:W2 解碼 + W4 junction 安全清理)
- Modify: `scripts/merge-claude-settings.py`(`_hook_cmd`:W3 home 前綴)
- Test: `scripts/test_lumos.py`(`t_hook_cmd_home_resolved`、`t_link_or_copy_idempotent`)

- [ ] **W2 — mklink 解碼炸**:`_link_or_copy` 的 `subprocess.run(["cmd","/c","mklink","/J",...], capture_output=True, text=True)` 在繁中 Windows 對 cp950 的 mklink 輸出用 UTF-8 解碼 → reader thread `UnicodeDecodeError`。修:加 `encoding="utf-8", errors="replace"`。(難跨平台單元測;靠真機重跑 install 無 traceback 驗。)

- [ ] **W4 — `_link_or_copy` 不冪等 + junction 清理危險**(W2 修後揭露的 pre-existing):Windows junction 不被 `Path.is_symlink()` 認出 → 舊 `shutil.rmtree(dst)` 會跟進 junction **刪來源 target**;且重跑 junction 殘留 → mklink「已存在」→ fallback copytree 炸 → install 重跑就壞。修:`is_symlink→unlink`、`is_dir→os.rmdir(只移連結/空夾,不碰 target);非空夾才 rmtree`。測:`t_link_or_copy_idempotent`(連呼叫兩次不炸 + 來源 f.txt 還在 + dst 可達)。真機連跑兩次 install 驗冪等。

- [ ] **W3 — hook command `${HOME}` native Windows 不展開**:Task 3 只 resolve 直譯器,路徑前綴仍 `${HOME}`,cmd/PowerShell 不展開 → L1/L3 靜默不觸發。修:`merge-claude-settings.py` 加 `_HOME = str(Path.home()).replace("\\","/")`,`_hook_cmd` 在 `sys.platform=="win32"` 用 `_HOME`、否則 `${HOME}`(Unix 可攜不變)。測:`t_hook_cmd_home_resolved`(win32 斷言無 `${HOME}`、Unix 斷言有)。真機重跑 merge 遷移成絕對 home。

- [ ] **W6 — hook command 反斜線被 Git Bash 吃掉**(W3 修後、marker 探針揭露;claude-code-guide 確認):**Claude Code 在 Windows 用 Git Bash 跑 hook command**,W3 只正斜線化了 home、`_PY`(shutil.which 回 `C:\…\python.EXE`)仍是反斜線 → Git Bash 把 `C:\Users` 吃成 `C:Users` → python 找不到 → hook 靜默失敗(先前在 PowerShell 手動驗 W3「成功」是假象,Claude Code 不用 PowerShell)。修:`_hook_cmd` 在 win32 把 `_PY` 也 `.replace("\\","/")` + 引號。測:`t_hook_cmd_home_resolved` 改 monkeypatch `_PY="C:\\…"` 斷言輸出無反斜線(stale PATH 下 _PY 退化成 python3 測不到,故 monkeypatch)。真機重生 settings = `"C:/…/python.EXE" "C:/…/x.py"`。

- [x] **W5(已否證 — 假議題,真因是 W6)**:我一度懷疑「remote-control session 不觸發 hooks」,但那次失敗測試**同時混了兩個變數**(remote-control + W6 反斜線格式),沒隔離。使用者指出「Mac 的 remote-control 會跑 hook」→ remote-control 不該是兇手。隨後做**單變數隔離**(同一 session、hooks 已載入、只切 remote-control 開關、W6 已修):remote-control 模式下 marker **照樣出現** → **remote-control 不抑制 hook 執行,真因從頭到尾只有 W6**。教訓:歸因前先隔離變數,別一次改兩個。

- [x] **驗收(全通)**:`python scripts/test_lumos.py` 全綠(200);真機 `lumos install` 連跑兩次乾淨 + 來源完好;settings hook command = `"<正斜線絕對 python>" "<正斜線絕對 home>/.claude/hooks/…"`(無反斜線、無 `${HOME}`)。**Step 7 L1/L3 實際觸發已坐實**:marker 探針確認 PostToolUse(L3)+ Stop(L1)兩個 hook 在 native Windows **本地與 remote-control 模式都觸發**(W6 修後)。Task 7 七步全閉合。

- [ ] **Commit**:`git add scripts/lumos scripts/merge-claude-settings.py scripts/test_lumos.py docs/` + message:
```
fix(win): Task 7 真機 findings W2/W3/W4(mklink 解碼 + junction 冪等安全 + hook ${HOME} 解析)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
```

---

## 驗證總結

- **跨平台單元測**(任何 OS):`python3 scripts/test_lumos.py` 全綠(scaffold 6 夾、install+skills、merge 去重、hooks fallback、既有回歸)。
- **Mac 回歸**(實作者在 Mac 時):你的 live `~/.claude/settings.json` 被遷移後 L1/L3 仍觸發、`lumos doctor` 綠、`lumos init` 6 夾。
- **真 Windows 閘**(Task 7):7 步手動清單——**這才是這份的放行標準**,紙上測試/CI 都代替不了。

## Spec 覆蓋自檢

組件 1(_IS_WIN/_install_skills/_scaffold_project/_install_hooks_py)→ T1;cmd_install+skills+pathsep → T2;merge-claude resolved+去重 → T3;hooks fallback → T4;get.ps1+收斂接線+薄殼 → T5;文檔 → T6;手動 Windows 清單 → T7。Mac 回歸散在 T2/T3/T4/T7。
