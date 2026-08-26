# compose-metrics-adapter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `lumos compose-metrics` — 機械偵測 Compose 重組效能退步(比對 Compose Compiler Metrics 現況 vs baseline:新增 non-skippable composable / skippable 比率退步 / unstable 上升)→ delta manifest → `--update-baseline` 放行。

**Architecture:** 機械核心在 `scripts/lumos` 新增 `compose-metrics` 子命令(vault-free,同 `lint-watch`);解析 `<prefix>-module.json`(聚合)+ `<prefix>-composables.csv`(逐 composable,`csv.DictReader`)+ `<prefix>-composables.txt`(unstable 參數,human-readable);baseline+delta(metrics 是整模組快照、無 file:line,必須存 baseline 只報退步)。權威逐行細節見 `docs/design/2026-07-04-compose-metrics-adapter.md`(2 輪 design-loop + KDS 真機格式坐實)。

**Tech Stack:** Python 3 stdlib(`json`/`csv`/`glob`/`os`,函數內 lazy import);`scripts/test_lumos.py` CLI subprocess harness。真機參考格式已存 `/tmp/kds-compose-module.json` / `/tmp/kds-compose-composables.csv` / `/tmp/kds-compose-composables.txt`。

**Branch:** `feat/compose-metrics-adapter`。

## Global Constraints

- **stdlib only**;不 build 專案、不跑 gradle——metrics 由專案 build 產出,lumos 只讀。
- **baseline+delta**:metrics 整模組快照無 file:line → 存 baseline、只報相對 baseline 退步的(否則每次洗版)。
- **fail-open**:單模組解析失敗 → `failed[]`、不升 rc、不報退步。rc:成功(含 regressions/部分 failed)=0;`.lumos/compose-metrics.json` 缺=0(空輸出);宣告檔格式壞(非 dict/無 modules/條目缺 name/metrics_dir/reports_dir)=2。
- **退步兩類**:`new_non_skippable`(現況 non-skippable FQN 集合 − baseline 集合)+ `aggregate`(skippable_ratio 下降超 `COMPOSE_RATIO_EPS=0.01`;`knownUnstableArguments`/`inferredUnstableClasses` 任何上升 `current>baseline`、無 EPS)。**移除的 composable 不報**。
- **non-skippable 定義**:csv `row["skippable"]=="0" and row["restartable"]=="1"`,收 `row["package"]`(FQN)。
- **txt 解析**:區塊起始=行首含 ` fun <Name>(`(不限關鍵字前綴、`scheme(...)` 可夾中間);名字=`fun ` 後到 `(` 前、剝泛型 `<...>`;空行不終止區塊;收 `unstable <param>: <Type>` 行 → `{裸name:[...]}`;join 用 csv 平行建的 `{FQN:裸name}` dict。跨 package 同裸名=天花板(不阻斷)。
- **`--update-baseline` 只寫成功解析模組**(failed 跳過免毒化);`non_skippable` 寫入 `sorted()`。
- `compose-metrics` dispatch **置於 `vault = find_vault(...)` 之前**(vault-free)。
- 錨點 `scripts/test_lumos.py` merge 後 push 前 anchor approve(Task 4)。

---

### Task 1: metrics 解析(`_compose_read_module` + `_compose_read_composables`)

**Files:** Modify `scripts/lumos`(新增兩 helper,置於 lint-watch helper 附近);Test `scripts/test_lumos.py`(`t_compose_parse`)。

**Interfaces:** Produces `_compose_read_module(metrics_dir, prefix) -> dict|None`(module.json 解析,缺/壞→None)、`_compose_read_composables(reports_dir, prefix) -> (non_skippable_fqns:set, fqn_to_name:dict, unstable_map:dict)`。Task 2/3 消費。

- [ ] **Step 1: 測試**(fixture 用真機形狀,含 r2 硬化的 txt 邊角):

```python
def t_compose_parse():
    import importlib.util as U, json, tempfile
    from importlib.machinery import SourceFileLoader
    from pathlib import Path
    spec = U.spec_from_file_location("lm", GRAPHCTL, loader=SourceFileLoader("lm", GRAPHCTL))
    m = U.module_from_spec(spec); spec.loader.exec_module(m)
    d = Path(tempfile.mkdtemp(prefix="gctl-cm-"))
    md = d / "metrics"; rd = d / "reports"; md.mkdir(); rd.mkdir()
    (md / "app_release-module.json").write_text(json.dumps({
        "skippableComposables": 96, "restartableComposables": 229, "totalComposables": 233,
        "knownUnstableArguments": 100, "inferredUnstableClasses": 29}), encoding="utf-8")
    # csv: KdsScreen non-skippable(skippable=0,restartable=1); MainFeatureBtn skippable(1,1)
    (rd / "app_release-composables.csv").write_text(
        "package,name,composable,skippable,restartable,readonly,inline,isLambda,hasDefaults,defaultsGroup,groups,calls,\n"
        "com.citrus.KdsScreen,KdsScreen,1,0,1,0,0,0,0,0,2,15,\n"
        "com.citrus.MainFeatureBtn,MainFeatureBtn,1,1,1,0,0,0,0,0,1,1,\n"
        "com.citrus.GenScreen,GenScreen,1,0,1,0,0,0,0,0,1,1,\n", encoding="utf-8")
    # txt: KdsScreen 有 unstable viewModel;GenScreen 為泛型 fun GenScreen<T>(;含空行 default;裸 fun helper 無關鍵字
    (rd / "app_release-composables.txt").write_text(
        'restartable scheme("[androidx.compose.ui.UiComposable]") fun KdsScreen(\n'
        '  unstable viewModel: CentralViewModel\n'
        '  stable askUpdate: Function0<Unit>\n'
        ')\n'
        'restartable skippable fun MainFeatureBtn(\n'
        '  stable status: String = @static {\n'
        '\n'                                # 空行(多行 default)不該斷區塊
        '  }\n'
        ')\n'
        'restartable fun GenScreen<T>(\n'   # 泛型
        '  unstable data: T\n'
        ')\n'
        'fun calculateYOffset(\n'           # 裸 fun 無關鍵字前綴
        '  stable width: Int\n'
        '): Dp\n', encoding="utf-8")
    # module
    mod = m._compose_read_module(str(md), "app_release")
    check("module skippable", mod["skippableComposables"] == 96, str(mod))
    check("module missing→None", m._compose_read_module(str(md), "nope") is None, "")
    # composables
    non_sk, fqn2name, umap = m._compose_read_composables(str(rd), "app_release")
    check("non_skippable = KdsScreen+GenScreen(FQN)",
          non_sk == {"com.citrus.KdsScreen", "com.citrus.GenScreen"}, str(non_sk))
    check("fqn2name", fqn2name["com.citrus.KdsScreen"] == "KdsScreen", str(fqn2name))
    check("unstable KdsScreen", umap.get("KdsScreen") == ["viewModel: CentralViewModel"], str(umap.get("KdsScreen")))
    check("unstable GenScreen(泛型名剝<T>)", umap.get("GenScreen") == ["data: T"], str(umap.get("GenScreen")))
    check("MainFeatureBtn 空行不斷→無 unstable", umap.get("MainFeatureBtn", []) == [], str(umap.get("MainFeatureBtn")))
```

- [ ] **Step 2:** 跑確認 fail。
- [ ] **Step 3:** 實作於 `scripts/lumos`:
  - `_compose_read_module(metrics_dir, prefix)`:`p = os.path.join(metrics_dir, prefix + "-module.json")`;不存在→None;`try: json.load` 失敗→None;回 dict。
  - `_compose_read_composables(reports_dir, prefix)`:
    - csv:`csv.DictReader` 讀 `<prefix>-composables.csv`(缺→回 `(set(), {}, {})`);對每 row,`fqn=row["package"]`,`fqn_to_name[fqn]=row["name"]`;若 `row.get("skippable")=="0" and row.get("restartable")=="1"` → `non_skippable_fqns.add(fqn)`。
    - txt(缺→umap 空):逐行掃,**區塊起始 = `" fun " in line and "(" in line`(用 `line`,行首起算;偵測 ` fun <Name>(`)**;起始時 `name = line.split(" fun ",1)[1].split("(",1)[0]`,再剝泛型 `name = name.split("<",1)[0]`,設 `cur=name`、`umap[cur]=[]`;非起始行且 `cur` 有值且 `line.strip().startswith("unstable ")` → `umap[cur].append(line.strip()[len("unstable "):])`(即 `<param>: <Type>`)。空行不改 `cur`(自然不斷區塊)。
    - 回 `(non_skippable_fqns, fqn_to_name, umap)`。
- [ ] **Step 4:** 跑 `t_compose_parse` 全綠 + 全套件回歸。
- [ ] **Step 5:** commit `feat(compose-metrics): metrics 解析(module.json/composables.csv/txt,含泛型/裸fun/空行硬化)`(`--no-verify`)。

---

### Task 2: 退步判定(`_compose_diff`)

**Files:** Modify `scripts/lumos`(新增 `COMPOSE_RATIO_EPS=0.01`、`_compose_diff`);Test `t_compose_diff`。

**Interfaces:** Consumes Task 1 輸出形狀。Produces `_compose_diff(module, baseline_mod, cur_agg, cur_non_skippable, fqn_to_name, umap) -> list[dict]`——回該模組 regressions 清單(entry 形狀見 Global Constraints)。Task 3 消費。

- [ ] **Step 1: 測試**:

```python
def t_compose_diff():
    import importlib.util as U
    from importlib.machinery import SourceFileLoader
    spec = U.spec_from_file_location("lm", GRAPHCTL, loader=SourceFileLoader("lm", GRAPHCTL))
    m = U.module_from_spec(spec); spec.loader.exec_module(m)
    baseline = {"aggregate": {"skippableComposables": 96, "restartableComposables": 229,
                              "totalComposables": 233, "knownUnstableArguments": 100, "inferredUnstableClasses": 29},
                "non_skippable": ["com.citrus.KdsScreen"]}
    cur_agg = {"skippableComposables": 96, "restartableComposables": 230, "totalComposables": 234,
               "knownUnstableArguments": 108, "inferredUnstableClasses": 29}
    cur_non = {"com.citrus.KdsScreen", "com.citrus.NewScreen"}   # NewScreen 新增
    fqn2name = {"com.citrus.NewScreen": "NewScreen", "com.citrus.KdsScreen": "KdsScreen"}
    umap = {"NewScreen": ["vm: CentralViewModel"]}
    regs = m._compose_diff("app", baseline, cur_agg, cur_non, fqn2name, umap)
    kinds = [(r["kind"], r.get("name") or r.get("metric")) for r in regs]
    check("new_non_skippable NewScreen",
          ("new_non_skippable", "com.citrus.NewScreen") in kinds, str(kinds))
    nn = [r for r in regs if r["kind"]=="new_non_skippable"][0]
    check("unstable_params 附上", nn["unstable_params"] == ["vm: CentralViewModel"], str(nn))
    check("knownUnstableArguments 上升報", ("aggregate", "knownUnstableArguments") in kinds, str(kinds))
    check("inferredUnstableClasses 未升→不報",
          ("aggregate", "inferredUnstableClasses") not in kinds, str(kinds))
    # skippable_ratio: baseline 96/233=.412, current 96/234=.410 → 差 .002 < EPS(.01) → 不報
    check("ratio 微幅<EPS 不報", ("aggregate", "skippable_ratio") not in kinds, str(kinds))
    # ratio 大跌:current skippable=80/234=.342 vs .412 差 .07>EPS → 報
    regs2 = m._compose_diff("app", baseline, dict(cur_agg, skippableComposables=80), cur_non, fqn2name, umap)
    check("ratio 大跌>EPS 報", any(r["kind"]=="aggregate" and r.get("metric")=="skippable_ratio" for r in regs2), str(regs2))
    # 移除的 composable 不報:baseline 有 X 現況無 → 無 regression
    regs3 = m._compose_diff("app", {"aggregate": baseline["aggregate"], "non_skippable": ["com.citrus.KdsScreen","com.citrus.Gone"]},
                            cur_agg, {"com.citrus.KdsScreen"}, {}, {})
    check("移除不報", not any(r["kind"]=="new_non_skippable" for r in regs3), str(regs3))
```

- [ ] **Step 2:** fail。
- [ ] **Step 3:** 實作:`COMPOSE_RATIO_EPS = 0.01`。`_compose_diff(module, baseline_mod, cur_agg, cur_non_skippable, fqn_to_name, umap)`:
  - `regs = []`;`base_agg = baseline_mod.get("aggregate") or {}`;`base_non = set(baseline_mod.get("non_skippable") or [])`。
  - new_non_skippable:`for fqn in sorted(cur_non_skippable - base_non): name = fqn_to_name.get(fqn, ""); regs.append({"module": module, "kind": "new_non_skippable", "name": fqn, "unstable_params": umap.get(name, [])})`。
  - skippable_ratio:`br = base_agg.get("skippableComposables",0)/max(base_agg.get("totalComposables",0),1)`;`cr = cur_agg.get("skippableComposables",0)/max(cur_agg.get("totalComposables",0),1)`;`if cr < br - COMPOSE_RATIO_EPS: regs.append({"module":module,"kind":"aggregate","metric":"skippable_ratio","baseline":round(br,3),"current":round(cr,3)})`。
  - count 升:`for k in ("knownUnstableArguments","inferredUnstableClasses"): b=base_agg.get(k,0); c=cur_agg.get(k,0);` `if c > b: regs.append({"module":module,"kind":"aggregate","metric":k,"baseline":b,"current":c})`。
  - 回 `regs`。
- [ ] **Step 4:** 綠 + 回歸。
- [ ] **Step 5:** commit `feat(compose-metrics): 退步判定 _compose_diff(new_non_skippable + aggregate ratio/count)`(`--no-verify`)。

---

### Task 3: `compose-metrics` 子命令(config/loop/partition/baseline/output/rc)

**Files:** Modify `scripts/lumos`(argparse + dispatch + `_compose_metrics_mode`);Test `t_compose_metrics_cli`。

**Interfaces:** Consumes Task 1/2。Produces `lumos compose-metrics --repo <root> [--json] [--update-baseline]`。

- [ ] **Step 1: 測試**(subprocess + 臨時 repo;含 update-baseline skip-failed + baseline_missing):

```python
def t_compose_metrics_cli():
    import subprocess as sp, json, tempfile
    from pathlib import Path
    root = Path(tempfile.mkdtemp(prefix="gctl-cmcli-"))
    (root/".lumos").mkdir()
    md = root/"app"/"m"; rd = root/"app"/"r"; md.mkdir(parents=True); rd.mkdir(parents=True)
    (root/".lumos"/"compose-metrics.json").write_text(json.dumps(
        {"modules":[{"name":"app","metrics_dir":"app/m","reports_dir":"app/r"}]}), encoding="utf-8")
    def write_metrics(skippable, non_sk_rows):
        (md/"app_release-module.json").write_text(json.dumps(
            {"skippableComposables":skippable,"restartableComposables":10,"totalComposables":20,
             "knownUnstableArguments":5,"inferredUnstableClasses":2}), encoding="utf-8")
        rows = "package,name,composable,skippable,restartable,readonly,inline,isLambda,hasDefaults,defaultsGroup,groups,calls,\n"
        for fqn,name in non_sk_rows:
            rows += f"{fqn},{name},1,0,1,0,0,0,0,0,1,1,\n"
        (rd/"app_release-composables.csv").write_text(rows, encoding="utf-8")
        (rd/"app_release-composables.txt").write_text("", encoding="utf-8")
    write_metrics(10, [("com.a.Foo","Foo")])
    # baseline 缺 → baseline_missing、rc 0、無 regressions
    r0 = sp.run([sys.executable,GRAPHCTL,"compose-metrics","--repo",str(root),"--json"],capture_output=True,text=True)
    d0 = json.loads(r0.stdout)
    check("baseline_missing", r0.returncode==0 and d0["baseline_missing"] is True and d0["regressions"]==[], r0.stdout)
    # --update-baseline 立基準
    ru = sp.run([sys.executable,GRAPHCTL,"compose-metrics","--repo",str(root),"--update-baseline"],capture_output=True,text=True)
    check("update-baseline rc0", ru.returncode==0 and (root/".lumos"/"compose-baseline.json").exists(), ru.stderr)
    # 新增 non_skippable Bar → 報 new_non_skippable
    write_metrics(10, [("com.a.Foo","Foo"),("com.a.Bar","Bar")])
    r1 = sp.run([sys.executable,GRAPHCTL,"compose-metrics","--repo",str(root),"--json"],capture_output=True,text=True)
    d1 = json.loads(r1.stdout)
    names = [x.get("name") for x in d1["regressions"] if x["kind"]=="new_non_skippable"]
    check("new_non_skippable Bar", r1.returncode==0 and "com.a.Bar" in names, r1.stdout)
    check("checked_modules 1", d1["checked_modules"]==1, str(d1))
    # 壞宣告 → rc 2
    (root/".lumos"/"compose-metrics.json").write_text('[]', encoding="utf-8")
    r2 = sp.run([sys.executable,GRAPHCTL,"compose-metrics","--repo",str(root),"--json"],capture_output=True,text=True)
    check("壞宣告 rc2", r2.returncode==2, f"rc={r2.returncode}")
```

- [ ] **Step 2:** fail。
- [ ] **Step 3:** 實作:
  - argparse:`p=sub.add_parser("compose-metrics")`;`p.add_argument("--repo",dest="compose_metrics_repo",default=".")`;`p.add_argument("--json",action="store_true",dest="as_json")`;`p.add_argument("--update-baseline",action="store_true")`。
  - dispatch(**在 `vault=find_vault` 之前**,同 lint-watch 區):`if args.cmd=="compose-metrics": return _compose_metrics_mode(args.compose_metrics_repo, args.as_json, args.update_baseline)`。
  - `_compose_metrics_mode(repo, as_json, update_baseline)`:
    - 讀 `<repo>/.lumos/compose-metrics.json`:不存在 → `update_baseline` 印提示 rc0;否則空輸出 rc0。`json.load` 失敗/非 dict/無 `modules`/條目缺 `name`/`metrics_dir`/`reports_dir` → 印錯 rc2。
    - `prefix` 解析:條目 `file_prefix` 或 `glob(metrics_dir/*-module.json)` 唯一取前綴;0/多 → 該模組 failed。
    - 逐模組:`_compose_read_module` + `_compose_read_composables`;module None → failed(reason "module.json not found/parse")。
    - **update_baseline 分支**:收集成功解析模組的 `{aggregate 子集, sorted(non_skippable)}` → 寫 `.lumos/compose-baseline.json`(failed 跳過)→ 印 `baseline updated (N modules, M skipped)`、rc0(不輸出 regressions)。
    - **一般分支**:讀 baseline 檔(不存在 → baseline_missing=True);逐成功模組:baseline 無該 module 鍵 → `new_modules.append`;有 → `_compose_diff` 收 regressions、`checked_modules+=1`。輸出 manifest(`--json`)或人可讀摘要(非 json,見 spec);rc0。
    - aggregate 子集抽取 helper:`{k: mod.get(k,0) for k in ("skippableComposables","restartableComposables","totalComposables","knownUnstableArguments","inferredUnstableClasses")}`。
- [ ] **Step 4:** 綠 + `t_compose_parse`/`t_compose_diff` 回歸 + 全套件。
- [ ] **Step 5:** commit `feat(compose-metrics): 子命令(config/loop/partition/update-baseline skip-failed/manifest/rc,vault-free)`(`--no-verify`)。

---

### Task 4: 知識同步 + 架構圖節點 + anchor + KDS 真機驗證(controller 自跑)

**Files:** Modify `skills/lumos-project-notes/SKILL.md`(指令表補 `compose-metrics`)、`docs/methodology/架構圖即合約.md`(pitfalls 列補「Compose 重組效能」);Create `Systems/compose-metrics-adapter.md` + `Verification/2026-07-04_compose-metrics-adapter.md`;更新 `Projects/pitfalls-lint-integration_計劃`(偏科層支線 done);merge 後 anchor approve。

- [ ] **Step 1:** 知識同步兩檔(照 spec §知識同步影響,grep 驗各 ≥1 命中)。
- [ ] **Step 2:** KG Systems 節點(summary:FLOW=讀宣告→解析 module.json/csv/txt→比對 baseline→delta manifest→放行 bump;KEY=只報退步不報怎修/baseline+delta 因整模組快照無file:line/non-skippable=skippable0&restartable1/txt 裸fun+泛型+空行硬化/update-baseline skip failed/EPS 只在 ratio;DEP=[[lint-version-watch]][[pitfalls-lint-adapter]];TEST;VERIFY)+ Verification 節點。lint ×2 + doctor 0。
- [ ] **Step 3(KDS 真機驗證):** 在 KDS 寫 `.lumos/compose-metrics.json`(指向已存的 `/tmp/kds-compose-*` 或重 build 的 `app/build/compose-*`)→ `lumos compose-metrics --repo /Users/enzo/Citrus_KDS --json`:首跑 baseline_missing → `--update-baseline` → 確認 baseline 含 21 non_skippable → (可選)改一個 composable 加 unstable 參數重 build → delta 抓到新增那條。結果記入 Verification 節點。**KDS 的 build.gradle.kts 若為驗證加了 metrics flags,驗完還原。**
- [ ] **Step 4(merge 收尾):** 更新計劃節點偏科層支線 status=done + verified_by。merge 回 main 後 push 前 `lumos anchor approve --note "compose-metrics:test_lumos.py 新增測試"` + baseline commit。

---

## Self-Review

**Spec coverage**:解析(§解析)→T1;退步判定(§退步判定+manifest entry)→T2;子命令 config/partition/baseline/output/rc(§CLI/§rc/§baseline)→T3;知識同步+KDS 驗證→T4。✓
**測試對映**:txt 硬化(泛型/裸fun/空行)+csv non-skippable+module→T1;new_non_skippable+ratio EPS+count 升+移除不報→T2;端到端+update-baseline skip-failed+baseline_missing+rc2→T3。✓
**Placeholder scan**:T1-3 完整測試+實作 code(含 txt 掃描邏輯、_compose_diff 全分支、_compose_metrics_mode partition)。無 TBD。✓
**Type consistency**:`_compose_read_module -> dict|None`、`_compose_read_composables -> (set,dict,dict)`(T1)→ T2 `_compose_diff(module,baseline_mod,cur_agg,cur_non,fqn2name,umap)` 消費一致 → T3 `_compose_metrics_mode` 串接一致;baseline schema `{module:{aggregate,non_skippable}}`(T2/T3)一致;manifest `{regressions,checked_modules,new_modules,failed,baseline_missing}`(T3)= spec。✓
