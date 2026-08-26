# pitfalls-lint-adapter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `pitfalls --diff` 從 regex 提示器升級為 lint 整合器——偵測 diff 涉及的棧 → 跑專案 `.lumos/lint.json` 宣告的 lint 指令(各輸出 SARIF)→ 解析合併、過濾到 diff 觸及行 → 併進既有 manifest;無宣告退回 regex-only。

**Architecture:** 全在 `scripts/lumos` 的 `_pitfall_diff_mode` 擴充 + 幾個 module-level helper(`_lint_load_config`/`_lint_run_and_parse`/`_diff_added_lines`/`_lint_aligned`)。lumos 只解 SARIF(stdlib json)、不內建棧規則。權威逐行細節見 `docs/design/2026-07-04-pitfalls-lint-adapter.md`(9 輪 design-loop + KDS tracer 定稿),本計畫每 task 引其組件編號。

**Tech Stack:** Python 3 stdlib(json/subprocess/tempfile/shlex/urllib.parse/os,函數內 lazy import 沿 codebase 慣例);`scripts/test_lumos.py` CLI subprocess harness + git fixture。

**Branch:** `feat/pitfalls-lint-adapter`。

## Global Constraints

- stdlib only;lumos 不內建任何棧規則、不裝/管理 linter;無宣告 `.lumos/lint.json` → regex-only 分毫不變(向後相容,回歸釘)。
- **spec 為逐行權威**:每 task 照 `docs/design/2026-07-04-pitfalls-lint-adapter.md` 對應組件實作,以下承重點不可漏(全經 KDS tracer/git 實測坐實):
  - 副檔名去點:`Path(f).suffix.lstrip('.')` 對 `.lumos/lint.json` key(組件②,R2-F1)
  - uri 正規化:剝 `file://` scheme + `urllib.parse.unquote` + `os.path.relpath(路徑, repo_root)` + 反斜線轉正斜線;有 `uriBaseId` 則以 `run.originalUriBaseIds[uriBaseId].uri` 為 base(組件③,R3-F2/R4-F3,KDS tracer:detekt 吐絕對 `file:///`)
  - SARIF 迭代:`for run in runs: for r in (run.get('results') or []):`(results optional,R8-F2);per-run `tool.driver.name`(R1-F5);單筆 location 存取包 try/except、`locations` 空跳該 finding **不連坐整 run**(R4-F1)
  - runner:每指令**各配獨立臨時檔** `tempfile.mkstemp`(R6-F2)、`{LINT_SARIF_OUT}` 用 `shlex.quote` 注入(R2-F6)、`subprocess.run(shell=True, timeout=LINT_CMD_TIMEOUT=180, start_new_session=True)` 逾時 `os.killpg`(R8-F3)、跑完 `os.unlink`(R9-F2);rc≠0 **且無 SARIF 內容**才算失敗記 `lint_skipped`(R2-F3②,KDS tracer:detekt 333 issues exit 非零仍產 SARIF)
  - 座標系對齊:`added` 行集合僅由 diff `+` 行構成(組件④,R4-F1 加 accumulator 不動 regex 骨架);對齊判定 = 右端 ref rev-parse == HEAD 且 `git status --porcelain` 空(cwd=repo_root);右端抽取先 `rsplit('...',1)` 後 `rsplit('..',1)`(R5/R6,`split('..',1)` 對 `a...b` 壞成 `.b`);非對齊或判定失敗 → 降級全收不過濾、manifest 標「未過濾全收」、不升 rc(R6-F3/R7-F2)
  - manifest:lint claim `{file,line,source,rule,message}`(無 class/question);regex claim 補 `source:"pitfalls-builtin"` 保留 class/pattern/question(R1-F4/向後相容不刪欄);`--json` 增 `lint_ran`/`lint_skipped`
  - rc:掃描成功 0 / git 缺或 range 解析失敗 2;lint 失敗不升 rc(R2-F3/R3-F5)
- 只驗「lint 有沒有真跑到」不驗規則對錯;錨點 `scripts/test_lumos.py` merge 後 push 前須 anchor approve(Task 5)。

---

### Task 1: `added` 行集合 accumulator + 座標系對齊 helper

**Files:** Modify `scripts/lumos`(`_pitfall_diff_mode` 掃描迴圈加 accumulator;新增 `_diff_added_lines`、`_lint_aligned` module-level helper);Test `scripts/test_lumos.py`(`t_lint_aligned`)。

**Interfaces:** Produces `_diff_added_lines(diff_text) -> dict[str, set[int]]`(檔→新增行號集合)、`_lint_aligned(diff_range, repo_root) -> bool`(座標系對齊)。Task 4 消費。

- [ ] **Step 1: 測試**(加 `scripts/test_lumos.py`):
```python
def t_lint_aligned():
    import subprocess as sp
    root = Path(tempfile.mkdtemp(prefix="gctl-la-"))
    def git(*a): sp.run(["git",*a],cwd=root,capture_output=True)
    git("init"); git("config","user.email","t@t"); git("config","user.name","t")
    (root/"a.kt").write_text("l1\n",encoding="utf-8")
    git("add","-A"); git("-c","user.email=t@t","-c","user.name=t","commit","-m","c1")
    (root/"a.kt").write_text("l1\nl2\n",encoding="utf-8")
    git("add","-A"); git("-c","user.email=t@t","-c","user.name=t","commit","-m","c2")
    import importlib.util as U
    spec=U.spec_from_file_location("lm","scripts/lumos"); m=U.module_from_spec(spec); spec.loader.exec_module(m)
    # added 集合:c2 的 +l2 在第 2 行
    diff=sp.run(["git","diff","-U3","HEAD~1..HEAD"],cwd=root,capture_output=True,text=True).stdout
    added=m._diff_added_lines(diff)
    check("added: a.kt 第2行", added.get("a.kt")=={2}, str(added))
    # 對齊:乾淨 ..HEAD → True
    check("aligned: 乾淨 ..HEAD True", m._lint_aligned("HEAD~1..HEAD", root) is True, "")
    # 對齊:... symmetric split 不炸(右端 rsplit)
    check("aligned: ...HEAD 不炸", isinstance(m._lint_aligned("HEAD~1...HEAD", root), bool), "")
    # dirty tree → False
    (root/"a.kt").write_text("l1\nl2\nDIRTY\n",encoding="utf-8")
    check("aligned: dirty False", m._lint_aligned("HEAD~1..HEAD", root) is False, "")
```
- [ ] **Step 2:** 跑確認 fail(helper 未定義)。
- [ ] **Step 3:** 實作——照 spec 組件④:`_diff_added_lines` 復用 `@@` 推導邏輯建 `{file: set(new_ln)}`;`_lint_aligned` = 右端 ref(先 `rsplit('...',1)` 後 `rsplit('..',1)`,空→HEAD,無`..`→工作區恆對齊)`git rev-parse` == `rev-parse HEAD` 且 `git status --porcelain` 空(皆 cwd=repo_root、失敗→False)。`_pitfall_diff_mode` 掃描迴圈在確認 `+` 行處加 `added.setdefault(cur_file,set()).add(new_ln)`(不動 regex 骨架)。
- [ ] **Step 4:** 跑 `t_lint_aligned` 全綠 + 全套件回歸(t_pitfalls_diff 不破)。
- [ ] **Step 5:** commit `feat(pitfalls): diff added 行集合 + 座標系對齊 helper(組件④)`。

---

### Task 2: `.lumos/lint.json` 讀取 + 技術棧偵測(去點)

**Files:** Modify `scripts/lumos`(新增 `_lint_load_config(repo_root)`、`_lint_stacks_for_diff(added, config)`);Test `t_lint_config`。

**Interfaces:** Produces `_lint_load_config(repo_root) -> dict|None`(無檔→None)、`_lint_stacks_for_diff(added, config) -> list[str]`(待跑指令展平)。Task 4 消費。

- [ ] **Step 1: 測試**:`.lumos/lint.json = {"kt":["cmd1"],"py":["cmd2"]}`;added 只碰 `a.kt` → `_lint_stacks_for_diff` 回 `["cmd1"]`(去點 `.kt`→`kt` 命中);added 碰 `a.vue`(無宣告)→ `[]`;無 `.lumos/lint.json` → `_lint_load_config` 回 None。
- [ ] **Step 2:** fail。
- [ ] **Step 3:** 實作照組件①②:`_lint_load_config` 讀 `repo_root/.lumos/lint.json`(json.load,不存在/壞→None);`_lint_stacks_for_diff` 對 added 每檔 `Path(f).suffix.lstrip('.')` 對 config key、命中則收該 key 的指令 list(去重)。
- [ ] **Step 4:** 綠 + 回歸。
- [ ] **Step 5:** commit `feat(pitfalls): .lumos/lint.json 讀取 + 技術棧偵測(去點,組件①②)`。

---

### Task 3: lint runner + SARIF 解析(核心)

**Files:** Modify `scripts/lumos`(新增 `LINT_CMD_TIMEOUT=180`、`_lint_run_and_parse(cmd, repo_root) -> (claims, ok)`);Test `t_lint_sarif`。

**Interfaces:** Produces `_lint_run_and_parse(cmd, repo_root) -> (list[claim], bool)`——claim `{file,line,source,rule,message}`(file 已正規化 repo 相對);ok=指令成功產出可解析 SARIF。Task 4 消費。

- [ ] **Step 1: 測試**(假 linter:用 `printf` 把預存假 SARIF 寫到 `{LINT_SARIF_OUT}`):
```python
def t_lint_sarif():
    import importlib.util as U, json as J
    spec=U.spec_from_file_location("lm","scripts/lumos"); m=U.module_from_spec(spec); spec.loader.exec_module(m)
    root=Path(tempfile.mkdtemp(prefix="gctl-ls-"))
    # 假 SARIF:絕對 file:// uri + per-run driver + 一筆 location-less
    sarif={"runs":[{"tool":{"driver":{"name":"detekt"}},"results":[
        {"ruleId":"R1","message":{"text":"m1"},"locations":[{"physicalLocation":{
            "artifactLocation":{"uri":f"file://{root}/app/X.kt"},"region":{"startLine":5}}}]},
        {"ruleId":"R2","message":{"text":"no-loc"}}  # location-less → 跳該筆不連坐
    ]}]}
    sf=root/"fake.sarif"; sf.write_text(J.dumps(sarif),encoding="utf-8")
    cmd=f"cp {sf} {{LINT_SARIF_OUT}}"   # 假 linter=把預存 SARIF 複製到注入路徑
    claims, ok = m._lint_run_and_parse(cmd, root)
    check("sarif ok", ok is True, "")
    check("sarif: 1 claim(location-less 跳)", len(claims)==1, str(claims))
    c=claims[0]
    check("sarif: uri 正規化 repo 相對", c["file"]=="app/X.kt", c["file"])
    check("sarif: source per-run", c["source"]=="lint:detekt", c["source"])
    check("sarif: line/rule/message", c["line"]==5 and c["rule"]=="R1" and c["message"]=="m1", str(c))
    # 指令失敗無 SARIF → ok False
    claims2, ok2 = m._lint_run_and_parse("false", root)
    check("sarif: 失敗 ok False", ok2 is False and claims2==[], "")
```
- [ ] **Step 2:** fail。
- [ ] **Step 3:** 實作照組件③全部承重點:`tempfile.mkstemp` 生獨立臨時檔 → `cmd.replace('{LINT_SARIF_OUT}', shlex.quote(path))` → `subprocess.run(shell=True, cwd=repo_root, timeout=LINT_CMD_TIMEOUT, start_new_session=True)`(TimeoutExpired→`os.killpg(os.getpgid(...),SIGKILL)`、回 ([],False))→ 讀臨時檔:空/parse 失敗→([],False);`for run in runs: tool=run['tool']['driver']['name']; base=run.get('originalUriBaseIds',{}); for r in (run.get('results') or []): try: loc=r['locations'][0]['physicalLocation']; uri 正規化(剝 file:// + unquote + relpath(repo_root) + 正斜線;有 uriBaseId 拼 base); startLine or 0; claims.append({file,line,source:f"lint:{tool}",rule:ruleId,message:text[:120]}) except (KeyError,IndexError): continue`(跳該筆不連坐)→ `finally: os.unlink(臨時檔)`。回 (claims, True)。
- [ ] **Step 4:** `t_lint_sarif` 全綠 + 回歸。
- [ ] **Step 5:** commit `feat(pitfalls): lint runner + SARIF 解析(per-command temp/shell/timeout/location-less/uri 正規化,組件③)`。

---

### Task 4: 整合——合併/過濾/tier/輸出 + fallback 回歸

**Files:** Modify `scripts/lumos`(`_pitfall_diff_mode` 尾段:接 Task1-3);Test `t_pitfalls_lint_integration`。

**Interfaces:** Consumes Task1-3 全部 helper。Produces `--diff` 完整 lint 整合行為。

- [ ] **Step 1: 測試**:git fixture + `.lumos/lint.json`(假 linter cmd)+ diff 新增 `.kt` 檔;驗:① lint claim 與 regex claim 合併、`source` 欄區分;② lint finding 在 diff 行→保留、不在→過濾掉(對齊時);③ dirty tree→降級全收 + manifest 標「未過濾全收」;④ 無 `.lumos/lint.json`→regex-only(`t_pitfalls_diff` 級行為、`lint_ran` 空);⑤ 指令失敗→`lint_skipped` 記錄、rc 0、regex claims 仍在;⑥ diff 未碰宣告棧→lint_ran 空。(6-8 個 check,`--json` 讀 `claims`/`tier`/`lint_ran`/`lint_skipped`。)
- [ ] **Step 2:** fail。
- [ ] **Step 3:** 實作照組件④⑤⑥:`_pitfall_diff_mode` 尾段——`config=_lint_load_config(repo_root)`;`config` None→維持現有 regex-only 輸出(fallback,不加 lint_ran)。否則:`added=_diff_added_lines(diff)`、`cmds=_lint_stacks_for_diff(added,config)`、`aligned=_lint_aligned(diff_range,repo_root)`;對每 cmd `_lint_run_and_parse`→ ok 記 lint_ran、否則 lint_skipped;lint claims 若 aligned 則過濾 `(file,line) in added` 否則全收+標記;regex claims 補 `source:"pitfalls-builtin"`;合併、`tier=high if any claim`;`--json` 輸出 `{claims,tier,lint_ran,lint_skipped}`(+非對齊時 `filtered:false` 標記)。
- [ ] **Step 4:** 全綠 + `t_pitfalls_diff`/`t_pitfalls_spec` 回歸 + 全套件。
- [ ] **Step 5:** commit `feat(pitfalls): --diff lint 整合(合併/過濾/tier/lint_ran/fallback,組件④⑤⑥)`。

---

### Task 5: 知識同步 + 架構圖節點 + anchor 收尾(controller 自跑)

**Files:** Modify `skills/lumos-project-notes/SKILL.md`(pitfalls 指令表補 `--diff` lint 整合)、`skills/lumos-code-loop/SKILL.md`(reviewer 鏡頭對 lint claim 讀 `message` 非 question,R1-F4)、`scripts/templates/graph-discipline.md`(終審前 pitfalls --diff 補「配 .lumos/lint.json 則吃 linter」)、`docs/methodology/架構圖即合約.md`(pitfalls 列補「lint 整合器 SARIF」);Create `Systems/pitfalls-lint-adapter.md` + `Verification/2026-07-04_pitfalls-lint-adapter.md`;更新 `Projects/pitfalls-lint-integration_計劃`(①塊 done);merge 後 anchor approve。

- [ ] **Step 1:** 知識同步四檔(照 spec §知識同步影響表,grep 驗各 ≥1 命中)。
- [ ] **Step 2:** KG Systems 節點(summary:FLOW=偵測棧→跑 lint→SARIF 解析→過濾/合併→manifest;KEY=只解 SARIF 不內建規則/uri 正規化 KDS tracer 坐實/per-command temp/location-less 不連坐/座標系對齊降級/向後相容;DEP=[[lumos-refcheck]][[pitfalls-code-loop]];TEST;VERIFY)+ Verification 節點(valid_under/revalidate_when/TEST 記實際數)。lint ×2 + doctor 0 issues。
- [ ] **Step 3:** 更新計劃節點 ①塊 status=done+verified_by 回指。commit。
- [ ] **Step 4(merge 收尾):** merge 回 main 後 push 前:`lumos anchor approve --note "pitfalls-lint-adapter:測試 runner 更新"` + baseline 同批 commit。

---

## Self-Review

**Spec coverage**:組件①(lint.json)→T2;②(偵測去點)→T2;③(runner/SARIF/uri/location-less/temp/timeout)→T3;④(added/座標系/過濾/降級)→T1+T4;⑤(合併/source/tier/lint_ran)→T4;⑥(fallback)→T4;知識同步→T5。✓
**測試策略 11 案**:去點(T2)/uri 正規化+location-less(T3)/added 過濾+座標系降級(T1+T4)/lint+regex 合併(T4)/指令失敗容錯(T3+T4)/無宣告回歸(T4)/全套件(各 task)。✓
**Placeholder scan**:T3 實作步驟給完整承重點清單引 spec 組件③逐行權威;測試完整 code。無 TBD。✓
**Type consistency**:`_diff_added_lines`/`_lint_aligned`/`_lint_load_config`/`_lint_stacks_for_diff`/`_lint_run_and_parse` 簽名 T1-3 定義、T4 消費一致;claim schema `{file,line,source,rule,message}` T3 產、T4 合併一致。✓
