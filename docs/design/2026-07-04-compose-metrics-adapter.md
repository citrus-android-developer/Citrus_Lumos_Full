# compose-metrics-adapter 設計(pitfalls 偏科層:重組效能)

> 計劃節點:[[Projects/pitfalls-lint-integration_計劃]](偏科層新支線)。地基認知:[[Systems/pitfalls-lint-adapter]](SARIF adapter)蓋不到重組效能——這是 pitfalls 原始痛點(Android/Compose 重組隱患)。

## 目標(一句)

機械偵測 Compose 重組效能退步——比對 Compose Compiler Metrics 的 baseline 與現況,skippable 比率退步 / 新增不可跳過 composable / unstable 增加 → 產候選信號 → 放行紀律(bump baseline),**只搬「重組效能退步了」的信號到人眼前,不驗「該怎麼修」**。

## 動機 / 定位

Compose 的重組效能(某 composable 每次父層重組都跟著重組 = 卡頓/掉幀)是 **SARIF linter 蓋不到的偏科坑**——detekt/lint 抓 code smell,但「這個 composable 不可跳過、因為某參數 unstable」是 **Compose 編譯器**才知道的資訊,輸出在 Compose Compiler Metrics(非 SARIF、非逐行診斷)。這正是 pitfalls 一開始想解、但 pivot 到「吃社群 linter」後留白的那塊。本 adapter 補這個洞——**吃 Compose 編譯器自己的 metrics(composition over invention 同哲學:不自建重組分析、吃編譯器產物)**。

## 核心認知:metrics 是整模組快照 → 必須 baseline+delta

真機坐實(KDS,AGP 8.2.2/Kotlin 1.9.20/compose-compiler 1.5.4):
- 專案 build 時給 Compose 編譯器旗標(`metricsDestination`/`reportsDestination`,**專案 build config 的事、非 lumos**)→ 產 `<module>-module.json`(聚合計數)+ `<module>-composables.csv`(逐 composable 旗標)+ `<module>-composables.txt`(人可讀,含哪個參數 unstable)。
- **是整模組快照、無 file:line、無 severity**。KDS 現況 21 個 non-skippable restartable composable——**直接報就是每次洗 21 條**。所以唯一可行機制是 **baseline + delta**:存一份已接受的 baseline,只報「相對 baseline 退步的」。
- 對照 [[Systems/lint-version-watch]]:baseline ≙ `current` 鎖定版、現況 metrics ≙ registry latest、delta ≙ behind、放行 ≙ bump baseline。**同形狀、換資料源**。

## 架構

兩層(沿既有分工):
1. **機械核心**:`scripts/lumos` 新增 `compose-metrics` 子命令(vault-free、可測、rc 語意,同 `lint-watch`)。讀 `.lumos/compose-metrics.json`(metrics 目錄宣告)+ `.lumos/compose-baseline.json`(baseline)→ 解析現況 metrics → 對比 baseline → 輸出 delta manifest(`--json`);`--update-baseline` = 放行(寫現況為新 baseline)。
2. **治理排程層**:**governance/compose-metrics-check.sh**(可選,掛 daily wrapper)——需專案先 build 出 metrics(非每日、按需);偵測到退步 → 信號(pending + LINE),沿 lint-watch 的 seen/pending/LINE 形狀。**v1 先做機械核心 + 手動跑;治理排程列 v2**(因需先跑 gradle build 產 metrics,節奏與 lint-watch 純 HTTP 不同)。

## 為什麼是新命令、不塞進 lint-watch / pitfalls --diff

- 不是 `lint-watch`:那是查外部 registry 版本;這是比對本地 build 產物的 baseline。資料源、baseline 語意都不同。
- 不是 `pitfalls --diff`:那是 SARIF/regex 逐行 claim 過濾到 diff;metrics 無 file:line、是整模組快照,套不上 diff-line 過濾(已於偏科層認知確立)。

## 資料契約

### 宣告檔 `.lumos/compose-metrics.json`(專案根,缺 = 無 compose-metrics)

```json
{
  "modules": [
    {"name": "app", "metrics_dir": "app/build/compose-metrics", "reports_dir": "app/build/compose-reports"}
  ]
}
```
- `name`:模組識別(對應 metrics 檔前綴,如 `app_release-module.json` 的 `app_release`——見下 file_prefix)。
- `metrics_dir`:含 `<prefix>-module.json`。`reports_dir`:含 `<prefix>-composables.csv`(+ `.txt`)。**目錄相對 repo 根**。
- `file_prefix`(選填):metrics 檔前綴(如 `app_release`);缺則自動偵測目錄內唯一 `*-module.json` 的前綴(多個 → 需明確宣告,否則該模組 failed)。

### baseline `.lumos/compose-baseline.json`(放行寫入;缺 = 首次、全現況視為 baseline 不報退步)

```json
{
  "app": {
    "aggregate": {"skippableComposables": 96, "restartableComposables": 229, "totalComposables": 233,
                  "knownUnstableArguments": 100, "inferredUnstableClasses": 29},
    "non_skippable": ["com.citrus.citruskds.ui.presentation.KdsScreen", "..."]
  }
}
```
- per 模組:`aggregate`(從 module.json 抽的關鍵計數子集)+ `non_skippable`(現況不可跳過 restartable composable 的 fully-qualified 名清單,**寫入時 `sorted()`**)。
- **`restartableComposables` 僅存供觀測、不參與退步判定**(m-3 認):restartable 本身非壞,只有「restartable 且 non-skippable」才是重組風險,已由 `new_non_skippable` 覆蓋;存它是為 baseline 完整快照/未來觀測。
- **缺 baseline**:global `baseline_missing:true` **只在整份 `.lumos/compose-baseline.json` 檔不存在時**(首次跑)——`regressions` 空、`checked_modules:0`、`new_modules:[]`、**`failed` 仍列解析失敗模組**(m-5 修)、提示 `--update-baseline` 立基準。
- **新模組(檔在、但該 module 鍵不在 baseline)**(M-1 修,消「或」歧義):該模組**不比對、不報退步**,列進 manifest `new_modules:[<module>]`;**不計入 `checked_modules`**;現況於下次 `--update-baseline` 納入。global `baseline_missing` 保持 false(檔存在)。

### delta manifest(`compose-metrics --json` stdout)

```json
{
  "regressions": [
    {"module": "app", "kind": "new_non_skippable",
     "name": "com.citrus.citruskds.ui.presentation.NewScreen",
     "unstable_params": ["viewModel: CentralViewModel"]},
    {"module": "app", "kind": "aggregate",
     "metric": "skippable_ratio", "baseline": 0.412, "current": 0.380},
    {"module": "app", "kind": "aggregate",
     "metric": "knownUnstableArguments", "baseline": 100, "current": 108}
  ],
  "checked_modules": 1,
  "new_modules": [],
  "failed": [{"module": "x", "reason": "module.json not found"}],
  "baseline_missing": false
}
```
- `regressions` 兩類,**entry 形狀**(M-2 修):
  - `new_non_skippable`:`{module, kind:"new_non_skippable", name:<FQN>, unstable_params:[...]}`。
  - `aggregate`:`{module, kind:"aggregate", metric:<名>, baseline:<值>, current:<值>}`。`metric` 為 `"skippable_ratio"`(baseline/current 為 float、判定用 EPS)或 module.json 鍵名逐字 `"knownUnstableArguments"`/`"inferredUnstableClasses"`(baseline/current 為 int、任何上升 `current>baseline` 即報、無 EPS)。
- `checked_modules`:成功解析**且對到既有 baseline 條目並比對**的模組數(new_modules 不算、failed 不算)。`new_modules`:檔在但該模組無 baseline 的模組名清單。`failed`:metrics 檔缺/壞、前綴歧義的模組 `{module, reason}`(fail-open、不升 rc、不報退步)。
- **移除的 composable(baseline 有、現況無)不報**(可能是刪除/改名——改善或重構,非退步)。

## 機械核心細節(**scripts/lumos** 的 compose-metrics 子命令)

### CLI 接線(沿 lint-watch 慣例)
- `sub.add_parser("compose-metrics")`;`--repo`(dest=`compose_metrics_repo`,預設 `.`);`--json`(store_true, dest=`as_json`);`--update-baseline`(store_true)。
- dispatch:`if args.cmd == "compose-metrics": ...`,**置於 `vault = find_vault(...)` 之前**(vault-free,同 lint-watch)。
- **非 `--json` 輸出**(M-3 修,沿 lint-watch 有人可讀摘要):印標題 `<N> regressions(modules: <checked>)`,每 regression 一行——`[new-non-skippable] <module>/<FQN>` 或 `[aggregate] <module> <metric> <baseline>→<current>`;`baseline_missing`/`new_modules` 各印一行提示(如 `baseline missing — run --update-baseline`)。`--json` 時印上述 manifest。
- `--update-baseline`:解析現況全模組 → **只寫成功解析的模組(module.json+csv 皆 OK);failed 模組跳過不寫入**(M-1 修:免 failed 模組以 `null` aggregate 毒化 baseline)→ 寫 `.lumos/compose-baseline.json`(aggregate 子集 + `sorted(non_skippable_set)` 排序寫入,m-4 修:免 set→list 非決定性 git diff 雜訊)→ 印「baseline updated(N modules, M skipped)」、rc 0(**不輸出 regressions**,放行動作)。`.lumos/compose-metrics.json` 缺時 `--update-baseline` → 無模組可寫、印提示、rc 0。

### 解析
- `_compose_read_module(metrics_dir, prefix) -> dict|None`:`json.load(<prefix>-module.json)`;缺/壞 → None。
- `_compose_read_composables(reports_dir, prefix) -> (non_skippable_set, unstable_reason_map)`:讀 `<prefix>-composables.csv`(`csv.DictReader`);`row["skippable"]=="0" and row["restartable"]=="1"` 的收 `row["package"]`(fully-qualified 名,即 `non_skippable_set`)。
  - 同時建 `{FQN: 裸name}` dict(csv 有 `package`+`name` 兩欄,平行收;m-2 修:FQN→裸name lookup 不靠切 `.`,避開 inner-class `$`)。
  - **txt↔csv join(B-2 修 + r2 硬化)**:`unstable_reason_map` 以**裸 `name` 為鍵**。解析 `<prefix>-composables.txt` 分區塊:
    - **區塊起始 = 行首含 ` fun <Name>(` 的行**(M-2 修:不限 `restartable`/`skippable` 前綴——真機有裸 `fun calculateYOffset(` / `fun asString(` 無關鍵字前綴;且關鍵字與 `fun` 間可能夾 `scheme("[...]")`,故偵測條件用「含 `fun <Name>(`」而非前綴)。名字 = `fun ` 後到 `(` 前、**再剝泛型 `<...>` 尾**(m-6 修:`fun Foo<T>(` → `Foo`)。
    - **空行不終止區塊**(m-4 修:真機多行 default value 參數段含空行,如 `AutoAcceptRadio`);區塊只由下一個「含 ` fun <Name>(` 的行」結束。
    - 收區塊內所有 `unstable <param>: <Type>` 行 → `{裸name: [「<param>: <Type>」...]}`。
  - 產 `unstable_params`:對每 non_skippable 條目,用 `{FQN:裸name}` 取裸名 → 查 map;命中附清單、未命中→空 list **不阻斷**。
  - **天花板(m-1 認)**:txt 只有裸名、無 package;**跨 package 同裸名**(如多個 feature 的 `Loading`)map 後寫者覆蓋 → 該情形 `unstable_params` 可能錯置/空。屬「為什麼」輔助資訊、非退步判定本體(退步判定用 FQN 集合差,不受影響),列天花板不硬追。txt 缺檔 → map 空、全部空 list。
- `file_prefix` 自動偵測:`metrics_dir` 內 `glob("*-module.json")`,唯一 → 取前綴;0 或 >1 → 該模組 failed(reason 明確)。

### 退步判定
- **new_non_skippable**:`current_non_skippable − baseline_non_skippable`(集合差)。每條附 `unstable_params`(from txt map)。
- **aggregate**:`skippable_ratio = skippableComposables / max(totalComposables,1)`;`current_ratio < baseline_ratio − EPS`(`COMPOSE_RATIO_EPS = 0.01`,防浮點/微幅抖動誤報)→ 報。`knownUnstableArguments` 或 `inferredUnstableClasses` `current > baseline` → 各報一條。
- **新模組(檔在、module 鍵缺)**:不報退步、進 manifest `new_modules`、不計 checked_modules、現況於下次 `--update-baseline` 納入(見〈baseline〉M-1 修;不與 global `baseline_missing` 混用)。

### rc 語意
- 解析+比對完成(含 regressions、含部分 failed)= **0**(信號模型,不阻斷;同 lint-watch fail-open 哲學)。
- `.lumos/compose-metrics.json` 缺 = 0(無 compose-metrics,空輸出)。
- 宣告檔格式壞(非 dict / 無 modules / 條目缺 name/metrics_dir/reports_dir)= 2。
- **注意**:v1 不設 `--strict`(退步→rc1 給 CI 擋)——列 v2;v1 純信號。

### stdlib only
`json`/`csv`/`glob`/`os`,函數內 lazy import。**不 build 專案、不跑 gradle**——metrics 由專案 build 產出(lumos 只讀)。

## 治理排程層(v1 手動 / v2 排程)
- v1:人按需 `lumos compose-metrics --repo <root> --json`(專案先 build 出 metrics),看 regressions,決定修或 `--update-baseline` 放行。
- v2(列未來):**governance/compose-metrics-check.sh** 掛 daily——但需先觸發專案 build 產 metrics(gradle,慢),節奏異於純 HTTP 的 lint-watch;信號沿 lint-watch 的 pending/seen/LINE 形狀。**v1 不做排程**,避免把「跑 gradle build」塞進每日喚醒窗。

## 實務隱患
- **併發**:單次 CLI、baseline 單寫者(`--update-baseline`),無並發。
- **冪等**:同一 metrics + 同 baseline → 同 manifest;`--update-baseline` 覆寫,冪等。
- **資源**:讀幾個檔(module.json ~1KB、csv ~數 KB),無熱路徑。
- **外部依賴**:metrics 格式依 Compose 編譯器版本;格式改(欄名/檔名)會失準 → 記 valid_under。

## 測試策略
機械核心(`scripts/test_lumos.py`,fixture 檔、不跑 gradle):
1. `_compose_read_module`/`_compose_read_composables`:餵真實形狀 fixture(module.json 計數 + composables.csv 標頭 `package,name,composable,skippable,restartable,...`)→ 正確抽 aggregate + non_skippable 集合;csv 缺/壞 → None/空 + failed。
2. 退步判定:baseline vs 現況——① 新增 non_skippable(集合差正確、附 unstable_params,且驗 txt 裸name↔csv FQN join)② skippable_ratio 下降超 EPS 報 / 微幅(<EPS)不報 ③ knownUnstableArguments 上升報 ④ **inferredUnstableClasses 上升報**(m-1 修:補此 aggregate 分支測試)⑤ 移除的 composable 不報 ⑥ 整份 baseline 缺 → baseline_missing、不報退步 ⑦ **新模組(檔在、module 鍵缺)→ 進 new_modules、不計 checked_modules、不報退步**。
3. `compose-metrics --json` 端到端(subprocess + 臨時 repo:`.lumos/compose-metrics.json` + 假 metrics 目錄 + baseline)→ regressions/checked_modules/new_modules/failed/baseline_missing 正確;`--update-baseline` 寫出正確 baseline(**含「一好一 failed 模組 → baseline 只含好的、failed 不寫入」**,M-1)且不輸出 regressions。
3b. txt 解析硬化(m 系列):裸 `fun Foo(` 無前綴也成區塊起始(M-2)、`scheme("[...]")` 夾在中間仍抽對名、泛型 `fun Foo<T>(`→`Foo`(m-6)、區塊內空行不斷區塊(m-4)。
4. file_prefix 自動偵測:唯一 `*-module.json` → 取前綴;0/多個 → 該模組 failed。
5. rc:缺宣告→0 空;壞宣告→2;metrics 檔缺→該模組 failed、rc 0。

真機驗證(KDS,實作階段):以 `/tmp/kds-compose-*`(已存的真 metrics)當 fixture 或直接指向 KDS build 產物,跑一次確認 non_skippable 集合 = 21、baseline 建立 → 改一個 composable 加 unstable 參數 → 重 build → delta 抓到新增那條。

## 知識同步影響
| 受影響文件 | 需同步什麼 |
|---|---|
| `skills/lumos-project-notes/SKILL.md` | 指令表補 `compose-metrics`(vault-free、baseline+delta、需專案先 build metrics) |
| `docs/methodology/架構圖即合約.md` | pitfalls 列補「Compose 重組效能(compose-metrics)——吃編譯器 metrics baseline+delta、補 SARIF 蓋不到的偏科坑」 |
| `Projects/pitfalls-lint-integration_計劃` | 偏科層新支線紀錄 + verified_by 回指 |

## 天花板 / 誠實邊界
1. **只報「退步了」,不報「怎麼修」**——unstable 參數怎麼變 stable(`@Immutable`/`@Stable`/wrapper)是人的事。
2. **需專案自己 build 出 metrics**(給 Compose 編譯器旗標);lumos 不 build、不管 build config。metrics 沒產 → 無資料可比。
3. **name-based、無 file:line**:composable 改名 = baseline 集合的 remove+add(改名那條會被當「新增 non_skippable」報一次,可接受——人一看就知道是改名)。
4. **baseline 靠人維護**(`--update-baseline` 放行);baseline 漂移(該放行沒放)會累積雜訊。
5. **metrics 語意依賴 Compose 編譯器版本**;跨大版本(如 compose-compiler 2.x strong skipping)skippable 語意會變,baseline 需重立。

## 審計修正紀錄(design-loop)

### R1(2026-07-04,canary type a=壞章節交叉引用(不存在的並行解析模型節),sonnet,**CAUGHT**,severity=blocker,存活 findings=8)

canary 被點出(懸空節指標,且與 實務隱患「無並發」矛盾——依規不折)。auditor 挖出真缺口(皆設計 absence/歧義、非經驗代碼宣稱,直接折):
- **B-2 blocker(折)**:`unstable_params` 的 txt↔csv join 鍵未定 → 明定以 csv 裸 `name` 為鍵、txt 區塊以行首 `restartable`/`skippable`... `fun <Name>(` 為界、命中附清單未命中空 list。
- **M-1 major(折)**:per-module baseline_missing「併入全域或 per-module」歧義 → 消「或」:global baseline_missing 僅整檔缺;新模組進 `new_modules`、不計 checked_modules、不報退步。
- **M-2 major(折)**:aggregate manifest entry 只示 skippable_ratio → 明定 count 型(knownUnstableArguments/inferredUnstableClasses)entry 形狀(metric=鍵名、int baseline/current、無 EPS)。
- **M-3 major(折)**:非 `--json` 輸出未定義 → 補人可讀摘要格式(沿 lint-watch)。
- **m-1(折)**:測試漏 inferredUnstableClasses 分支 → 補。
- **m-2(折)**:checked_modules 對 baseline-missing 模組兩義 → 明定不計、進 new_modules。
- **m-3(折)**:restartableComposables 存而不用 → 註明僅觀測、不判退步(重組風險只看 non-skippable)。
- **m-4(折)**:non_skippable set→list 寫入非決定性 → `sorted()` 寫入。
存活 8 條全折入(canary B-1 不折)。

### R2(2026-07-04,canary type b=未定義旗標 `--ratio-threshold`,sonnet,**CAUGHT**,severity=major,存活 findings=7)

canary 被點出(旗標無 dest/default/測試/驗證——依規不折)。r1 修後 auditor 判核心乾淨,存活多為 composables.txt 解析邊角(真機 KDS txt 坐實):
- **M-1 major(折)**:`--update-baseline` 未言明跳過 failed 模組 → 可能以 `null` aggregate 毒化 baseline → 明定只寫成功解析模組 + 測試。
- **M-2 major(折)**:txt 區塊界定漏「裸 `fun Name(` 無關鍵字前綴」塊(真機 `calculateYOffset`/`asString`)、且 `scheme(...)` 夾在關鍵字與 fun 間 → 改偵測「含 ` fun <Name>(`」、名字剝泛型。
- **m-1(折)**:跨 package 同裸名 map 覆蓋 → 列天花板(輔助資訊非退步本體,退步用 FQN 集合差不受影響)。
- **m-2(折)**:FQN→裸name lookup 隱含 → 明定 csv 平行建 `{FQN:裸name}` dict(避 inner-class `$` 切錯)。
- **m-4(折)**:區塊內空行(多行 default value)未定 → 明定空行不斷區塊。
- **m-5(折)**:baseline_missing=true 時 checked/new/failed 值未定 → 明定 0/[]/仍列 failed。
- **m-6(折)**:泛型 composable `fun Foo<T>(` → 剝 `<...>`。
存活 7 條全折入(canary m-3 不折)。
