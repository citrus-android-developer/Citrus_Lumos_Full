---
type: project
status: done
created: 2026-08-10
updated: 2026-08-11
tags:
  - type/project
  - status/done
  - scope/governance
related:
  - "[[code側刪除傳播守衛_計劃]]"
summary: |-
  FLOW:Task1 LINK_KEYS 常數→Task2 diff 解析抽 token→Task3 staged-index 信心分檔→Task4 vault 掃描+輸出→Task5 S2 純連結判定→Task6 delguard 子命令組裝(deadline/fail-open)→Task7 pre-commit Gate DG 掛載→Task8 S3 問句進 skill+架構圖收尾
  KEY:spec 單源=[[code側刪除傳播守衛_計劃]](design-loop 已收斂,golden@governance/golden/code側刪除傳播守衛/);本節點只管「怎麼落地」,行為合約以 spec 為準
  KEY:★執行模式=subagent-driven★(每 task 派乾淨 subagent,task 間主對話審查);TDD 硬性:每 task 先紅再綠再 commit
  KEY:★每個 commit 都動 scripts/lumos(code)→pre-commit Gate 3 要求同 commit 帶架構圖 .md=勾本節點該 task checkbox★
  KEY:先驗值(replay 校準後以數據取代)=token cap 40/輸出 top-10/deadline 2.0s(env LUMOS_DELGUARD_DEADLINE 可覆寫,測試靠它注入超時)
  TEST:python3 scripts/test_lumos.py 全跑;新增 t_delguard()+_mk_delguard_repo() fixture,斷言風格沿 check(name,cond,detail)
verified_by:
  - "[[Verification/2026-08-11_delguard落地]]"
---
# code側刪除傳播守衛_實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL — `superpowers:subagent-driven-development`（已裁定）。Steps 用 checkbox 追蹤；**每個 task 的 commit 必須同時勾本節點對應 checkbox（pre-commit Gate 3 硬擋 code 無架構圖 commit）**。

**Goal:** 把已收斂的 [[code側刪除傳播守衛_計劃]] v1（S1 被刪符號偵測＋S2 純連結判定＋S3 問句）落成 `lumos delguard` 子命令＋pre-commit Gate DG（advisory），TDD 全綠。

**Architecture:** 全部進 `scripts/lumos` 單檔 CLI（本 repo 慣例，比照 cochange：`cmd_delguard_check` ＋ 四個純函式）；pre-commit 只加一行 Gate DG 呼叫（`|| true` 隔離）；測試進 `scripts/test_lumos.py`。

**Tech Stack:** python3 stdlib only（零依賴家規）、bash hook、git plumbing（`diff --cached` / `grep --cached`）。

## Global Constraints（每個 task 隱含遵守；值全部抄自 spec，不得偏離）

- **advisory 契約**：`delguard` 恆 rc0（含內部錯誤與超時）；警告走 **stdout**（stderr 只放診斷，會被 hook 的 `2>/dev/null` 吞）。
- **所有 git 呼叫帶 `-c core.quotePath=off`**（CJK 路徑坑，pre-commit:36-39 前例）。
- **快照契約＝staged index**：判定一律 `--cached`，嚴禁 grep working tree 或 HEAD。
- **regex 三件套**：`re.compile(r"\b(?:" + "|".join(map(re.escape, tokens)) + r")\b", re.ASCII)`——`re.escape`＋`\b`＋`re.ASCII` 缺一不可。
- **單掃紀律**：vault 掃＝單條 alternation 一次過；staged-index 掃＝**單次** `git grep --cached` 多 `-e`，嚴禁每 token 一個子行程。
- 先驗值：`DELGUARD_TOKEN_CAP=40`、`DELGUARD_TOP_N=10`、deadline `2.0s`（`LUMOS_DELGUARD_DEADLINE` 覆寫）。
- 型別只排序不壓低：全五型別（Systems/Projects/Verification/Issues/MOC）都報，Systems 排前；信心檔位＝符號維度（全域消失=高／僅呼叫點消失=低）。
- 測試跑法：`python3 scripts/test_lumos.py`（全量，尾行 summary 判綠）。

## 檔案結構

- Modify `scripts/lumos`：
  - `LINK_KEYS` 常數（緊鄰 `LIST_KEYS`，:6224 附近）
  - `DELGUARD_*` 常數群＋`_delguard_parse_diff` / `_delguard_confidence` / `_delguard_vault_scan` / `_delguard_purelink` / `cmd_delguard_check`（放 `cmd_cochange_check` 之後，同區塊）
  - argparse：`sub.add_parser("delguard", ...)`（放 cochange 註冊附近）
- Modify `scripts/hooks/pre-commit`：Gate CC 之後加 Gate DG 區塊
- Modify `scripts/test_lumos.py`：`_mk_delguard_repo()`＋`t_delguard()`
- Modify `skills/lumos-project-notes/SKILL.md`：退場段加 S3 問句（Task 8）

---

### Task 1：LINK_KEYS 常數＋子集守衛斷言

**Files:** Modify `scripts/lumos`（`LIST_KEYS` 定義行正下方）；Test `scripts/test_lumos.py`
**Interfaces / Produces:** `LINK_KEYS = ("verified_by", "plan_refs", "related", "core_refs")`（tuple，後續 Task 5 直接引用）

- [x] Step 1 寫失敗測試（加進 test_lumos.py，新函式 `t_delguard()` 起手；並把 `t_delguard` 註冊進檔尾的測試清單——先 grep `t_cochange` 在清單裡怎麼掛、照抄）：

```python
def t_delguard():
    import re as _re
    src = Path(GRAPHCTL).read_text(encoding="utf-8")
    m = _re.search(r"^LINK_KEYS\s*=\s*\(([^)]*)\)", src, _re.M)
    check("delguard LINK_KEYS 常數存在", m is not None, "LINK_KEYS not found")
    keys = set(_re.findall(r'"(\w+)"', m.group(1))) if m else set()
    check("delguard LINK_KEYS 值正確", keys == {"verified_by", "plan_refs", "related", "core_refs"}, str(keys))
    lm = _re.search(r"^LIST_KEYS\s*=\s*\{([^}]*)\}", src, _re.M)
    listk = set(_re.findall(r'"(\w+)"', lm.group(1))) if lm else set()
    check("delguard 子集守衛 LINK_KEYS ⊆ LIST_KEYS∪{core_refs}", keys <= (listk | {"core_refs"}), f"{keys} vs {listk}")
```

- [x] Step 2 跑 `python3 scripts/test_lumos.py` 確認 t_delguard 三條紅（LINK_KEYS not found）
- [x] Step 3 在 `scripts/lumos` 的 `LIST_KEYS` 行正下方加：

```python
LINK_KEYS = ("verified_by", "plan_refs", "related", "core_refs")  # S2「純連結欄位」子集(≠LIST_KEYS:那是 append 白名單,pitfall_when=content-trigger 不算連結);spec=Projects/code側刪除傳播守衛_計劃
```

- [x] Step 4 跑測試確認綠
- [x] Step 5 commit（staged：scripts/lumos＋test_lumos.py＋本節點勾 Task1）`feat(delguard): LINK_KEYS 純連結子集+守衛斷言`

### Task 2：`_delguard_parse_diff` — 從 staged diff 抽被刪識別字＋vault 檔 diff

**Files:** Modify `scripts/lumos`；Test `scripts/test_lumos.py`
**Interfaces / Produces:**
```python
def _delguard_parse_diff(diff_text: str, graph_root: str) -> dict:
    """回 {"tokens": [str...]  # 依出現序去重,cap 前不截
         ,"vault_diffs": {path: [line...]}}  # graph_root 下 .md 的 +/- 行(含鍵頭),供 S2"""
```
規則（全抄 spec）：只吃 `-` 行（跳過 `---` 檔頭、`+++`、hunk 頭、binary 檔段）；token regex `[A-Za-z_][A-Za-z0-9_]{2,}`；**出現在同一份 diff 任何 `+` 行的 token 剔除**（檔內改名/搬行＝舊名即刻回收，降誤報）；stopword 表剔除（`if else for while return import class def val var fun void public private static final new this true false null let const function`）；vault（`graph_root` 前綴）與排除路徑（`node_modules/ bin/ obj/ dist/ build/ __pycache__/ .git/`）的檔案不抽 token，vault .md 的 diff 行另收進 `vault_diffs`。

- [x] Step 1 失敗測試（t_delguard 內續加；直接餵手工 diff 字串，不必 git）：

```python
    from importlib import machinery, util as _u
    # 以 exec 載入 scripts/lumos 取函式(本檔既有慣例:直接 subprocess 打 CLI 或 exec 模組;此處走 exec)
    spec_ = machinery.SourceFileLoader("lumos_mod", GRAPHCTL)
    mod = _u.module_from_spec(_u.spec_from_loader("lumos_mod", spec_))
    spec_.exec_module(mod)
    DIFF = """diff --git a/app/Login.kt b/app/Login.kt
--- a/app/Login.kt
+++ b/app/Login.kt
@@ -10,3 +9,2 @@
-        refreshPaywayCredentials()
-        val keep = renamedHelper(x)
+        val keep = renamedHelperV2(x)
diff --git a/docs/lumos-toolchain-knowledge/Systems/pay.md b/docs/lumos-toolchain-knowledge/Systems/pay.md
--- a/docs/lumos-toolchain-knowledge/Systems/pay.md
+++ b/docs/lumos-toolchain-knowledge/Systems/pay.md
@@ -3,1 +3,2 @@
 verified_by:
+  - "[[Verification/x]]"
"""
    out = mod._delguard_parse_diff(DIFF, "docs/lumos-toolchain-knowledge")
    check("delguard 抽到被刪 token", "refreshPaywayCredentials" in out["tokens"], str(out["tokens"]))
    check("delguard +行回收 token 不誤報改名", "renamedHelper" not in out["tokens"] or "renamedHelperV2" in out["tokens"], str(out["tokens"]))
    check("delguard stopword 剔除", "val" not in out["tokens"], str(out["tokens"]))
    check("delguard vault diff 不進 tokens 且收進 vault_diffs", "verified_by" not in out["tokens"] and any(p.endswith("pay.md") for p in out["vault_diffs"]), str(out))
```

（注意：`renamedHelper` 案例——`-` 行有 `renamedHelper`、`+` 行是 `renamedHelperV2`，token 字面不同不會被回收，這是**已知低信心誤報源**（spec 明文 v1 不解）；測試斷言放寬為「或 V2 在」以免釘死尚未承諾的行為。真正要釘的回收案例＝同 token 在 `+` 行原樣出現。若要加嚴，補一組 `-foo()`/`+foo()` 的搬行 diff 斷言 `"foo" not in tokens`。）

**實作偏差記錄（Task 2 執行時發現並修正）**：上段「或 V2 在」放寬斷言經實測**結構性恆假**——`tokens` 依 spec 只收 `-` 行，`renamedHelperV2` 只出現在 `+` 行，永遠不可能進 `tokens`；而 spec 又明文只回收「字面相同」的 token，`renamedHelper`≠`renamedHelperV2` 字面不同不得回收。兩者相加，該斷言對任何合規實作都恆假（非本實作特有 bug）。已將 `scripts/test_lumos.py` 內對應斷言改測兩個真正該釘的行為：①同字面（`keep` 同時原樣出現在 `-`/`+` 行）→ 回收剔除；②不同字面改名（`renamedHelper`→`renamedHelperV2`）→ 已知低信心誤報源，仍留在 `tokens`。實作（`_delguard_parse_diff` 本體、`_DELGUARD_STOP`、`_DELGUARD_EXCLUDE_DIRS`）維持逐字照抄，未動。詳見 task-2-report.md。

- [x] Step 2 跑紅（AttributeError: no `_delguard_parse_diff`）
- [x] Step 3 實作（`cmd_cochange_check` 後方）：

```python
_DELGUARD_STOP = frozenset("if else for while return import class def val var fun void public private static final new this true false null let const function".split())
_DELGUARD_EXCLUDE_DIRS = ("node_modules/", "bin/", "obj/", "dist/", "build/", "__pycache__/", ".git/")

def _delguard_parse_diff(diff_text, graph_root):
    import re
    tok_re = re.compile(r"[A-Za-z_][A-Za-z0-9_]{2,}")
    tokens, seen, added = [], set(), set()
    vault_diffs, cur, is_vault, is_excl, in_binary = {}, None, False, False, False
    lines = diff_text.splitlines()
    for ln in lines:  # 先收全 diff 的 + 行 token(回收表)
        if ln.startswith("+") and not ln.startswith("+++"):
            added.update(tok_re.findall(ln))
    for ln in lines:
        if ln.startswith("diff --git"):
            m = re.search(r" b/(.+)$", ln)
            cur = m.group(1) if m else None
            is_vault = bool(cur) and cur.startswith(graph_root) and cur.endswith(".md")
            is_excl = bool(cur) and any(seg in cur for seg in _DELGUARD_EXCLUDE_DIRS)
            in_binary = False
            continue
        if ln.startswith("Binary files"):
            in_binary = True
            continue
        if in_binary or cur is None:
            continue
        if is_vault and (ln.startswith("+") or ln.startswith("-")) and not ln.startswith(("+++", "---")):
            vault_diffs.setdefault(cur, []).append(ln)
            continue
        if is_vault or is_excl:
            continue
        if ln.startswith("-") and not ln.startswith("---"):
            for t in tok_re.findall(ln):
                if t in _DELGUARD_STOP or t in added or t in seen:
                    continue
                seen.add(t); tokens.append(t)
    return {"tokens": tokens, "vault_diffs": vault_diffs}
```

- [x] Step 4 跑綠
- [x] Step 5 commit＋勾 Task2 `feat(delguard): staged diff 解析——被刪 token 抽取+vault diff 分流`

### Task 3：`_delguard_confidence` — staged-index 兩檔信心（單次 git grep）

**Files:** Modify `scripts/lumos`；Test `scripts/test_lumos.py`（新 fixture `_mk_delguard_repo`）
**Interfaces / Produces:**
```python
def _delguard_confidence(tokens: list, repo_root: str, graph_root: str) -> dict:
    """回 {token: "high"|"low"}。high=staged index 全域消失(排除 vault/排除域後零命中)。
       單次 git -c core.quotePath=off grep --cached -n -I -w -F -e t1 -e t2 ... --
       . ':(exclude)<graph_root>' ':(exclude)node_modules' ...;rc>1 視為失敗丟 RuntimeError(上層 fail-open)。"""
```
命中歸屬在 python 端做：對 grep 輸出每行，用 Task 4 同款三件套 regex 判哪些 token 出現（`-w` 是 git 側粗篩，py 側再精配）。

- [x] Step 1 fixture＋失敗測試：

```python
def _mk_delguard_repo():
    import subprocess as sp
    root = Path(tempfile.mkdtemp(prefix="gctl-delg-"))
    sp.run(["git", "-C", str(root), "init", "-q"], capture_output=True)
    sp.run(["git", "-C", str(root), "config", "user.email", "t@t.t"], capture_output=True)
    sp.run(["git", "-C", str(root), "config", "user.name", "t"], capture_output=True)
    gr = root / "docs" / "kg-knowledge"
    for sub in ("Systems", "Projects", "Verification", "Issues", "MOC"):
        (gr / sub).mkdir(parents=True)
    (root / "app").mkdir()
    (root / "app" / "Login.kt").write_text(
        "fun login() {\n    refreshPaywayCredentials()\n    helperStillUsed()\n}\n", encoding="utf-8")
    (root / "app" / "Other.kt").write_text(
        "fun other() { helperStillUsed() }\n", encoding="utf-8")
    (gr / "Systems" / "憑證.md").write_text(
        "---\ntype: system\n---\n# 憑證\n登入時 refreshPaywayCredentials 撈一次憑證。\n還在講helperStillUsed欄位。\n", encoding="utf-8")
    (gr / "Projects" / "計劃.md").write_text(
        "---\ntype: project\n---\n# 計劃\n預定用 refreshPaywayCredentials 重構。\n", encoding="utf-8")
    sp.run(["git", "-C", str(root), "add", "-A"], capture_output=True)
    sp.run(["git", "-C", str(root), "commit", "-qm", "init"], capture_output=True)
    # staged 刪除:Login.kt 拿掉兩個呼叫(refreshPaywayCredentials 全域消失;helperStillUsed 在 Other.kt 仍活)
    (root / "app" / "Login.kt").write_text("fun login() {\n}\n", encoding="utf-8")
    sp.run(["git", "-C", str(root), "add", "app/Login.kt"], capture_output=True)
    return root, "docs/kg-knowledge"

# t_delguard 內續加:
    root, gr = _mk_delguard_repo()
    conf = mod._delguard_confidence(["refreshPaywayCredentials", "helperStillUsed"], str(root), gr)
    check("delguard 全域消失=high", conf.get("refreshPaywayCredentials") == "high", str(conf))
    check("delguard 仍有呼叫點=low", conf.get("helperStillUsed") == "low", str(conf))
    # 快照契約:worktree 加回不影響(index 為準)
    (root / "app" / "Login.kt").write_text("fun login() { refreshPaywayCredentials() }\n", encoding="utf-8")
    conf2 = mod._delguard_confidence(["refreshPaywayCredentials"], str(root), gr)
    check("delguard 快照=index 不被 worktree 救回", conf2.get("refreshPaywayCredentials") == "high", str(conf2))
```

- [x] Step 2 跑紅
- [x] Step 3 實作：

```python
def _delguard_confidence(tokens, repo_root, graph_root):
    import re, subprocess
    if not tokens:
        return {}
    cmd = ["git", "-c", "core.quotePath=off", "grep", "--cached", "-n", "-I", "-w", "-F"]
    for t in tokens:
        cmd += ["-e", t]
    cmd += ["--", ".", f":(exclude){graph_root}"]
    for d in _DELGUARD_EXCLUDE_DIRS:
        cmd += [f":(exclude){d.rstrip('/')}"]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=repo_root)
    if r.returncode > 1:
        raise RuntimeError(f"git grep rc={r.returncode}: {r.stderr.strip()[:200]}")
    alive = set()
    pats = {t: re.compile(r"\b" + re.escape(t) + r"\b", re.ASCII) for t in tokens}
    for line in r.stdout.splitlines():
        for t, p in pats.items():
            if t not in alive and p.search(line):
                alive.add(t)
    return {t: ("low" if t in alive else "high") for t in tokens}
```

- [x] Step 4 跑綠
- [x] Step 5 commit＋勾 Task3 `feat(delguard): staged-index 兩檔信心(單次 git grep 多 -e)`

### Task 4：`_delguard_vault_scan` — 三件套 alternation 掃 vault＋型別排序

**Files:** Modify `scripts/lumos`；Test `scripts/test_lumos.py`
**Interfaces / Produces:**
```python
def _delguard_vault_scan(tokens: list, conf: dict, graph_root_abs: str) -> list:
    """回 [{"node": "Systems/憑證.md", "folder": "Systems", "line_no": int,
            "line": str(strip,截 160 字), "tokens": [..], "conf": "high"|"low"}...]
       排序: (conf!=high, folder!="Systems", node, line_no)——高信心先、Systems 先。"""
```

- [x] Step 1 失敗測試（沿用 Task 3 fixture；先 `git -C root add -A` 前的 vault 檔已就位）：

```python
    hits = mod._delguard_vault_scan(["refreshPaywayCredentials", "helperStillUsed"], conf,
                                    str(root / gr))
    check("delguard vault 命中 Systems 原句", any(h["node"] == "Systems/憑證.md" and "撈一次" in h["line"] for h in hits), str(hits))
    check("delguard CJK 緊貼命中(re.ASCII)", any("還在講" in h["line"] and "helperStillUsed" in h["tokens"] for h in hits), str(hits))
    check("delguard Projects 也報(型別只排序不壓低)", any(h["folder"] == "Projects" for h in hits), str(hits))
    sys_idx = min(i for i, h in enumerate(hits) if h["folder"] == "Systems")
    proj_idx = min(i for i, h in enumerate(hits) if h["folder"] == "Projects")
    check("delguard Systems 排前", sys_idx < proj_idx, str([(h["folder"], h["conf"]) for h in hits]))
    # 詞界:蓋 refreshPaywayCredentialsV2 不誤配
    (root / gr / "Systems" / "V2.md").write_text("---\ntype: system\n---\n用 refreshPaywayCredentialsV2 取代。\n", encoding="utf-8")
    hits2 = mod._delguard_vault_scan(["refreshPaywayCredentials"], conf, str(root / gr))
    check("delguard \\b 詞界不誤配 V2", not any(h["node"] == "Systems/V2.md" for h in hits2), str(hits2))
```

- [x] Step 2 跑紅
- [x] Step 3 實作：

```python
def _delguard_vault_scan(tokens, conf, graph_root_abs):
    import re, os
    if not tokens:
        return []
    rx = re.compile(r"\b(?:" + "|".join(map(re.escape, tokens)) + r")\b", re.ASCII)
    per = {t: re.compile(r"\b" + re.escape(t) + r"\b", re.ASCII) for t in tokens}
    hits = []
    for dirpath, _dirs, files in os.walk(graph_root_abs):
        for fn in files:
            if not fn.endswith(".md"):
                continue
            fp = os.path.join(dirpath, fn)
            rel = os.path.relpath(fp, graph_root_abs)
            folder = rel.split(os.sep, 1)[0]
            try:
                text = open(fp, encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            for i, line in enumerate(text.splitlines(), 1):
                if not rx.search(line):
                    continue
                ts = [t for t, p in per.items() if p.search(line)]
                hits.append({"node": rel.replace(os.sep, "/"), "folder": folder, "line_no": i,
                             "line": line.strip()[:160], "tokens": ts,
                             "conf": "high" if any(conf.get(t) == "high" for t in ts) else "low"})
    hits.sort(key=lambda h: (h["conf"] != "high", h["folder"] != "Systems", h["node"], h["line_no"]))
    return hits
```

- [x] Step 4 跑綠
- [x] Step 5 commit＋勾 Task4 `feat(delguard): vault 三件套掃描+型別排序`

### Task 5：`_delguard_purelink` — S2 純連結 diff 判定（保守朝不報）

**Files:** Modify `scripts/lumos`；Test `scripts/test_lumos.py`
**Interfaces / Produces:**
```python
def _delguard_purelink(diff_lines: list) -> bool:
    """True=本檔 diff 只有「連結欄位鍵頭/連結列表項」的變更。
       合格行(±開頭,剝符號後): `- "[[..]]"` 列表項,或 `<LINK_KEYS 之一>:` 鍵頭。
       其他任何 ± 行(含 pitfall_when:/tags: 鍵頭、body 文字、YAML 重排)→ False。"""
```

- [x] Step 1 失敗測試：

```python
    pl = mod._delguard_purelink(['+  - "[[Verification/2026-08-03_x]]"'])
    check("delguard S2 純掛連結=True", pl is True, str(pl))
    check("delguard S2 動 body=False", mod._delguard_purelink(['+  - "[[V/x]]"', "+登入不再撈憑證"]) is False, "")
    check("delguard S2 pitfall_when 不算連結", mod._delguard_purelink(["+pitfall_when:", '+  - "撈憑證"']) is False, "")
    check("delguard S2 鍵頭+列表項=True", mod._delguard_purelink(["+verified_by:", '+  - "[[V/x]]"']) is True, "")
    check("delguard S2 空 diff=False(無變更不算純連結)", mod._delguard_purelink([]) is False, "")
```

- [x] Step 2 跑紅
- [x] Step 3 實作：

```python
def _delguard_purelink(diff_lines):
    import re
    item_re = re.compile(r'^\s*-\s*"?\[\[[^\]]+\]\]"?\s*$')
    key_re = re.compile(r"^(%s):\s*$" % "|".join(LINK_KEYS))
    changed = [ln[1:] for ln in diff_lines
               if ln[:1] in "+-" and not ln.startswith(("+++", "---"))]
    if not changed:
        return False
    return all(item_re.match(c) or key_re.match(c) for c in changed)
```

- [x] Step 4 跑綠
- [x] Step 5 commit＋勾 Task5 `feat(delguard): S2 純連結 diff 判定(LINK_KEYS,保守朝不報)`

### Task 6：`cmd_delguard_check` 組裝＋子命令註冊＋deadline/fail-open＋輸出

**Files:** Modify `scripts/lumos`（cmd 函式＋argparse 註冊＋dispatch 分支——dispatch 寫法照 cochange 的分支抄）；Test `scripts/test_lumos.py`
**Interfaces / Produces:** CLI `lumos delguard --staged [--json] [--repo R]`；恆 rc0（argparse 錯誤除外）。輸出（stdout）：
```
⚠ delguard: code 側刪除傳播——N 個被刪符號在架構圖仍被提及(高信心 H/低信心 L)
  [high] Systems/憑證.md:5 「登入時 refreshPaywayCredentials 撈一次憑證。」 ← refreshPaywayCredentials
  ...(top-10 逐條;其餘一行統計「另有 K 處命中(低信心/超額),--json 看全量」)
  ⚠ 假同步嫌疑: Systems/憑證.md 本次只掛連結(純連結編輯)但內文仍講被刪符號
  退場前自問: 1) 這次拿掉/反轉了什麼? 2) 上列原句逐句判:改動後還成立嗎?
  3) 還成立→一句話為什麼;不成立→現在改掉或標作廢。新增 verified_by/related 連結不算同步。
```
JSON：`{"tokens": N, "hits": [...全量...], "fake_sync": [node...], "degraded": bool}`。

- [x] Step 1 失敗測試（整合，走 CLI）：

```python
    def dg(*a, cwd=None, env=None):
        import os as _os
        e = dict(_os.environ); e.update(env or {})
        return sp.run([sys.executable, GRAPHCTL, "delguard", *a],
                      capture_output=True, text=True, cwd=cwd or str(root), env=e)
    r = dg("--staged", "--json")
    check("delguard CLI rc0", r.returncode == 0, r.stderr)
    data = json.loads(r.stdout.strip().splitlines()[-1])
    check("delguard 抓到 aff2329 形狀(高信心命中)", any(h["conf"] == "high" for h in data["hits"]), str(data)[:400])
    r = dg("--staged")
    check("delguard 警告走 stdout+S3 問句", "退場前自問" in r.stdout and r.returncode == 0, r.stdout[:400])
    # 假同步嫌疑:vault 節點只掛連結+S1 命中
    p = root / gr / "Systems" / "憑證.md"
    p.write_text(p.read_text(encoding="utf-8").replace("---\n# 憑證",
        '---\n# 憑證').replace("type: system\n", 'type: system\nverified_by:\n  - "[[Verification/x]]"\n'), encoding="utf-8")
    sp.run(["git", "-C", str(root), "add", "-A"], capture_output=True)
    r = dg("--staged", "--json")
    fs = json.loads(r.stdout.strip().splitlines()[-1])["fake_sync"]
    check("delguard S2 假同步嫌疑(純連結∧S1命中)", "Systems/憑證.md" in fs, str(fs))
    # 超時降級:env 注 0 → rc0+降級訊息在 stdout
    r = dg("--staged", env={"LUMOS_DELGUARD_DEADLINE": "0"})
    check("delguard 超時 fail-open rc0", r.returncode == 0, str(r.returncode))
    check("delguard 降級訊息在 stdout", "超時降級" in r.stdout, f"out={r.stdout!r} err={r.stderr!r}")
    # 內部錯誤 fail-open:env 注入測試鉤子
    r = dg("--staged", env={"LUMOS_DELGUARD_RAISE": "1"})
    check("delguard 內部錯誤 fail-open rc0+訊息", r.returncode == 0 and "內部錯誤" in r.stdout, r.stdout[:200])
    # 效能 benchmark:<1s(254 檔級 vault 用本 repo 真 vault 跑,40 token)
    import time as _t
    toks = [f"zzNoSuchTok{i}" for i in range(40)]
    t0 = _t.monotonic()
    mod._delguard_vault_scan(toks, {}, str(Path(GRAPHCTL).parent.parent / "docs" / "lumos-toolchain-knowledge"))
    check("delguard benchmark vault 掃 <1s", _t.monotonic() - t0 < 1.0, f"{_t.monotonic()-t0:.2f}s")
```

- [x] Step 2 跑紅（unknown command delguard）
- [x] Step 3 實作 `cmd_delguard_check`：

```python
def cmd_delguard_check(repo=None, as_json=False):
    import json, os, subprocess, time
    t0 = time.monotonic()
    deadline = float(os.environ.get("LUMOS_DELGUARD_DEADLINE", "2.0"))
    def _over():
        return time.monotonic() - t0 > deadline
    try:
        if os.environ.get("LUMOS_DELGUARD_RAISE"):
            raise RuntimeError("test hook")
        root = repo or _git_root() or os.getcwd()   # _git_root:repo 既有 helper,沒有就地寫 rev-parse
        gr = _find_graph_root(root)                 # 既有 vault 偵測 helper;找不到→靜默 rc0(vault-free repo 不掃)
        if not gr:
            return 0
        r = subprocess.run(["git", "-c", "core.quotePath=off", "diff", "--cached", "-M", "--no-color"],
                           capture_output=True, text=True, cwd=root)
        parsed = _delguard_parse_diff(r.stdout, os.path.relpath(gr, root).replace(os.sep, "/"))
        tokens = parsed["tokens"][:40]  # DELGUARD_TOKEN_CAP
        dropped = len(parsed["tokens"]) - len(tokens)
        if _over():
            print(f"delguard: 超時降級({deadline}s),放行;本輪掃描不完整"); return 0
        conf = _delguard_confidence(tokens, root, os.path.relpath(gr, root).replace(os.sep, "/"))
        if _over():
            print(f"delguard: 超時降級({deadline}s),放行;本輪掃描不完整"); return 0
        hits = _delguard_vault_scan(tokens, conf, gr)
        fake = []
        for path, dl in parsed["vault_diffs"].items():
            rel = os.path.relpath(os.path.join(root, path), gr).replace(os.sep, "/")
            if _delguard_purelink(dl) and any(h["node"] == rel for h in hits):
                fake.append(rel)
        if as_json:
            print(json.dumps({"tokens": len(tokens), "dropped": dropped, "hits": hits,
                              "fake_sync": fake, "degraded": False}, ensure_ascii=False))
            return 0
        if not hits:
            return 0
        hi = sum(1 for h in hits if h["conf"] == "high")
        print(f"⚠ delguard: code 側刪除傳播——{len(tokens)} 個被刪符號在架構圖仍被提及(高信心 {hi}/低信心 {len(hits)-hi})")
        for h in hits[:10]:  # DELGUARD_TOP_N
            print(f"  [{h['conf']}] {h['node']}:{h['line_no']} 「{h['line']}」 ← {','.join(h['tokens'])}")
        rest = len(hits) - min(len(hits), 10)
        if rest or dropped:
            print(f"  …另有 {rest} 處命中/{dropped} 個符號超 cap 未展開(--json 看全量)")
        for n in fake:
            print(f"  ⚠ 假同步嫌疑: {n} 本次只掛連結(純連結編輯)但內文仍講被刪符號")
        print("  退場前自問: 1) 這次拿掉/反轉了什麼? 2) 上列原句逐句判:改動後還成立嗎?")
        print("  3) 還成立→一句話為什麼;不成立→現在改掉或標作廢。新增 verified_by/related 連結不算同步。")
        return 0
    except Exception as e:
        print(f"delguard: 內部錯誤({e.__class__.__name__}),放行")
        return 0
```

argparse 註冊（cochange 註冊區旁；dispatch 分支照 cochange 樣式）：

```python
    dg = sub.add_parser("delguard", help="code 側刪除傳播守衛(advisory):staged 被刪符號→grep vault 指名過期原句;spec=Projects/code側刪除傳播守衛_計劃")
    dg.add_argument("--staged", action="store_true", help="掃 staged diff(目前唯一模式,旗標留語意)")
    dg.add_argument("--json", action="store_true")
    dg.add_argument("--repo")
```

（`_git_root`/`_find_graph_root` 若無同名既有 helper：grep `find_vault`/`rev-parse` 找現成的用，**不新造**；真沒有才就地寫兩個 10 行內的私有函式。）

- [x] Step 4 跑綠（全量 test_lumos.py，不許紅其他測試）
- [x] Step 5 commit＋勾 Task6 `feat(delguard): 子命令組裝——deadline fail-open+top-10 輸出+S3 問句`

> fix r1：--json 降級契約補齊（超時/內部錯誤兩條路徑皆輸出合法單行 JSON
> `{"tokens","hits":[],"fake_sync":[],"degraded":true,"reason":"timeout"|"error"}`，rc0；成功路徑
> `degraded` 已可觀察為 False，符合 Global Constraints「--json 含 tokens/hits/fake_sync/degraded」）、
> 標頭計數改為實際命中的 distinct 符號數（`len({t for h in hits for t in h["tokens"]})`，不再是被
> 刪符號原始總數）、`_git_root()` 刪除改用既有 `_cochange_repo_root(repo) or os.getcwd()`。

### Task 7：pre-commit Gate DG 掛載＋排除域對齊斷言

**Files:** Modify `scripts/hooks/pre-commit`（Gate CC 區塊之後、Gate 1 之前）；Test `scripts/test_lumos.py`
**Interfaces / Consumes:** Task 6 的 CLI；hook 既有變數 `CC_PY`、`REPO_ROOT`。

- [x] Step 1 失敗測試：

```python
    hook = Path(GRAPHCTL).parent / "hooks" / "pre-commit"
    ht = hook.read_text(encoding="utf-8")
    check("delguard Gate DG 已掛 pre-commit", "delguard --staged" in ht and "|| true" in ht.split("delguard --staged")[1][:40], ht[:0] or "gate missing")
    # 排除域對齊:python 排除清單每一項都出現在 should_exclude 的 case 行裡
    case_line = [l for l in ht.splitlines() if "node_modules" in l and "case" not in l][0]
    for d in mod._DELGUARD_EXCLUDE_DIRS:
        check(f"delguard 排除域對齊 pre-commit({d})", d.rstrip("/") in case_line, case_line)
```

- [x] Step 2 跑紅
- [x] Step 3 pre-commit 加區塊（Gate CC 的 `fi` 之後）：

```bash
# Gate DG: code 側刪除傳播守衛 (advisory;spec=Projects/code側刪除傳播守衛_計劃)
# 警告走 stdout(2>/dev/null 只吞診斷);|| true 只兜 crash,hang 由 lumos 內部 deadline 兜(fail-open)
if [[ -n "${CC_PY:-}" ]]; then
  "$CC_PY" "$REPO_ROOT/scripts/lumos" delguard --staged 2>/dev/null || true
fi
```

- [x] Step 4 跑綠＋手動煙霧：在 `_mk_delguard_repo` 產的 repo 裝 hook 實跑一次 commit，肉眼確認警告出現且 commit 成功（結果貼 PR/commit message）
- [x] Step 5 commit＋勾 Task7 `feat(delguard): pre-commit Gate DG(advisory)+排除域對齊斷言`

### Task 8：S3 問句進 skill 退場段＋架構圖收尾

**Files:** Modify `skills/lumos-project-notes/SKILL.md`（「常見工作流」節後加退場段）；Modify spec 節點＋本節點（架構圖收尾）
**Interfaces / Consumes:** 無 code。此 task 兌現 decision「advisory 版必須配 S3」的跨專案那一半（機械吐問句已由 Task 6 做掉）。

- [x] Step 1 在 `skills/lumos-project-notes/SKILL.md` 的「常見工作流」節之後加：

```markdown
## 退場自問（code 有「拿掉/反轉」的改動時，收工前跑一遍）

1. 這次改動**拿掉或反轉**了什麼？（函式/呼叫點/欄位/條件/預設值——過期幾乎都來自拿掉，不是新增）
2. 把那些名字逐個丟 `lumos search <名> --code`（--code 必帶：search 預設排除 code block；另注意預設排除 superseded）。哪些節點內文在講它們？貼原句。
3. 逐句判：改動後這句還成立嗎？成立→一句話為什麼；不成立→**現在改掉或標作廢**。
⚠ 新增一條 verified_by/related 連結**不算同步**。有裝 delguard（pre-commit Gate DG）的 repo，S1 命中時會機械吐這三問；沒裝的 repo 靠這段自律。
```

- [x] Step 2 架構圖收尾（同一 commit）：spec 節點 `lumos set Projects/code側刪除傳播守衛_計劃 status doing` 改 `done` 前先確認：待辦剩餘項（誤報帳格式、存量另案、v2 死碼判定）搬清楚＝留待辦不擋 done？——**不改 done**，改 `lumos set ... updated <日期>`＋body 待辦勾 S3 落點項、註「已裁定 skill 退場段（2026-08-10 Enzo）」；本實作計畫節點 `status` → `done`；建 `Verification/<日期>_delguard落地`（`plan_refs` 回指 spec＋本節點，記 t_delguard 全綠證據），`lumos append` 進兩節點 `verified_by`。
- [x] Step 3 `lumos lint` 兩節點＋`lumos doctor` 全綠
- [x] Step 4 commit＋勾 Task8 `feat(delguard): S3 問句入 skill 退場段+架構圖收尾`

---

## 終審提醒（執行完別跳）

全部 task 完成後：`lumos pitfalls --diff <merge-base>..HEAD`——**動了守衛面，大概率 tier: high** → 依家規走 `lumos-code-loop` 對抗代碼審，收斂 `lumos code-loop pass --note` 留痕才能 push（pre-push 硬擋）。

## Self-Review 紀錄（writing-plans 自查，2026-08-10）

- Spec 覆蓋：S1（Task 2/3/4/6）、S2（Task 1/5/6）、S3（Task 6 輸出＋Task 8 skill）、落點 d1（Task 7）、fail-open/deadline/stdout（Task 6/7）、測試策略表 17 列→分佈於各 task 測試（符號改名列＝Task 2 註記的放寬斷言；歷史段落列已由 spec 撤案改型別排序＝Task 4）；存量掃描＝spec 已劃另案，本計畫不含 ✓
- Placeholder 掃：無 TBD/「適當處理」;唯二留白＝`_git_root`/`_find_graph_root` 指示「先找既有 helper 不新造」，屬指令非佔位 ✓
- 型別一致：`LINK_KEYS` tuple（Task 1 定義、Task 5 引用）；`_delguard_parse_diff` 回 dict 鍵 tokens/vault_diffs（Task 2 定義、Task 6 消費）；`conf` dict（Task 3→4/6）✓
