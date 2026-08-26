# 設計:pitfalls lint 整合(pitfalls-lint-adapter)— `--diff` 從 regex 提示器升級為 lint 整合器

- 日期:2026-07-04
- 狀態:design-approved(2026-07-04)— design-loop 9 輪 GATE PASS(r7/r8/r9 連 3 caught+minor、K-streak∧G1∧G2 findings[2,2,1]枯竭)+ KDS 真機 tracer 坐實六大承重點 + qwen 跨家族 endorsed-after-refute(其 ≥major 全為 canary 誤讀/已折 finding 當 open,機械反證不成立)。原:純文字 design-loop 到頂 → KDS tracer 定稿(r1/r2/r3 連三 major、17 findings 折入,主結構穩;但真機整合細節[SARIF uri 形態/git range rev-parse/detekt SARIF 旗標]每文字化一層又生新縫,真值在真機非文字)→ **轉真機 tracer(KDS 專案)定稿**,同 rot-eval「先 prototype」哲學。
- 動機來源:`Projects/pitfalls-lint-integration_計劃` 第 ① 塊(地基)。brainstorm(2026-07-04)收斂:pitfalls 不是規則庫、是提問+整合+接線;通則(ruff S113/SIM115)與偏科(compose-rules/detekt/eslint)社群 linter 已有且 AST 級更準,兩者都該讓給 linter(composition over invention);整合共通格式=SARIF。
- loop_id:pitfalls-lint-adapter
- 計劃回指:docs/lumos-toolchain-knowledge/Projects 的 pitfalls-lint-integration_計劃 節點。

## 目標(一句話)

`pitfalls --diff` 新增 lint 整合:偵測 diff 涉及的技術棧 → 跑專案宣告的一組 lint 指令(各輸出 SARIF)→ lumos 解析合併 SARIF、過濾到 diff 觸及行 → 併進既有 manifest 餵 reviewer/code-loop;無宣告則退回現有 regex-only(向後相容)。lumos 只解析 SARIF 一種格式、不內建任何棧的規則。

## 前提與既驗事實(2026-07-04)

- **pitfalls --diff 現況**:`scripts/lumos` 的 `_pitfall_diff_mode(diff_range, repo_root, as_json)` 掃 `git diff -U3 <range>` 新增行、跑 `_PITFALL_DIFF_PATTERNS`(6 條 regex)、`@@` 行號推導、過濾繼承 Check H(skip .md/.txt/.rst+測試檔+註解行)、輸出 manifest `{file,line,class,pattern,question}`+尾行 `tier: high|standard`、rc 恆 0。本塊在此函數內擴充,不改既有 regex 骨架。
- **SARIF 是 OASIS 標準**(2020,v2.1.0):JSON 格式;`runs[].results[]` 每筆有 `ruleId`、`message.text`、`locations[].physicalLocation.artifactLocation.uri`(檔)與 `region.startLine`(行)、`level`(error/warning/note)。ESLint/detekt/Roslyn/Sonar 皆可輸出。lumos 以 stdlib `json` 解析,零依賴。
- **一棧多 linter 並存**:C#(Roslyn+StyleCop+Sonar+Roslynator)、Vue(ESLint+plugins)、Android(Lint+detekt+ktlint)——故指令是「一棧一組(list)」。
- **lumos 語言無關原則**:`_VENDORED_TOOLKIT` 不含任何棧規則;guard 範本亦專案自備(`.lumos/guard-templates/`)——lint 指令同理由專案宣告(`.lumos/lint.json`),lumos 不猜、不內建。
- **repo 解析**:`_anchor_repo_root(repo)` 既有(refcheck/anchor/pitfalls 共用)。
- **KDS 真機 tracer(2026-07-04,detekt on Citrus_KDS)坐實三大不確定性**:① SARIF uri=絕對 `file:///…`(無 uriBaseId)→ 正規化剝 scheme+relpath 為必須(R3-F2);② tool.driver.name='detekt'、region.startLine 有整數值(映射對,R1-F5);③ `git rev-parse '<base>..HEAD'` 回兩行(正端+`^`負端)→ 座標系判定須 split `..` 取右端 ref 單獨 rev-parse(R3-F4);④ detekt 333 issues 時 exit 非零仍產 SARIF(R2-F3② rc 語意)。三個 major 方向全經真機證實,非推測。

## 方案評比與選擇

| 方案 | 內容 | 判定 |
|---|---|---|
| **A(選)** | 專案宣告 `.lumos/lint.json`(副檔名→一組 lint 指令,各需輸出 SARIF);pitfalls 跑之、解析合併 | **選**:一次配、明確、跨棧統一;lumos 只讀宣告跑指令、只解 SARIF;無宣告退回 regex(向後相容);對齊 guard-templates 專案自備先例 |
| B(否決) | 自動偵測(看到 detekt.yml/.eslintrc 就推指令) | 否決:指令與參數(尤其 SARIF 輸出旗標)猜不準、脆;不同專案同工具配置差異大 |
| C(否決) | 只印「建議手動跑 detekt」不自己跑 | 否決:沒真接上,lint 結果進不了 manifest/code-loop,價值近零 |

## 範圍(組件)

### ① `.lumos/lint.json`(專案宣告檔,repo 側、非 vendored)
```json
{
  "kt":  ["<detekt 指令,輸出 SARIF 到 stdout 或指定檔>"],
  "vue": ["<eslint -f @microsoft/sarif ...>"],
  "cs":  ["<dotnet build -p:ErrorLog=<file>.sarif ...>"]
}
```
- key = 副檔名(不含點,如 `kt`/`vue`/`cs`/`py`);value = 該棧的一組指令(list,支援多 linter 並存)。
- 每個指令**必須含 `{LINT_SARIF_OUT}` 佔位符**(pitfalls 注入臨時檔路徑、指令寫 SARIF 到該路徑;單一寫檔契約,見組件 ③;r1-F6 砍 stdout 模式)。三棧範例皆寫檔式。
- lumos 不驗指令內容、不猜參數——宣告是專案責任(同 guard 範本專案自備)。

### ② 技術棧偵測(哪些 lint 指令要跑)
- 從 diff 新增行涉及的檔案副檔名集合 → 對照 `.lumos/lint.json` 的 key → 命中的棧的指令集合即待跑。**去點正規化(r2-F1,承重)**:既有 `_pitfall_diff_mode` 取副檔名用 `Path(cur_file).suffix`(帶點,如 `.kt`),而 key 定義不含點(`kt`)——偵測時必須 `suffix.lstrip('.')` 再對 key,否則帶點永對不上、技術棧偵測恆空、lint 永不觸發(python 實測 `Path('Foo.kt').suffix == '.kt'`)。
- diff 無觸及任何宣告棧的檔 → 不跑 lint(只 regex)。

### ③ lint runner + SARIF 解析(runner 契約)
- **單一寫檔契約(r1-F6:砍 stdout 模式)**:每個指令字串**必須含 `{LINT_SARIF_OUT}` 佔位符**,pitfalls **為每個指令各生成獨立臨時檔**(r6-F2,承重:一棧多 linter 並存時共用一路徑會讓 detekt/ktlint 互相覆寫、一半 findings 靜默歸零)注入、指令用它當 SARIF 輸出路徑,pitfalls 跑完逐一讀。無佔位符的指令 → 視為配置錯、跳過記 lint_skipped(不猜工具預設落點、不吃 stdout——主流 SARIF 產出器多不支援乾淨 stdout,三棧範例皆寫檔式)。
- **執行(r1-F3①)**:`subprocess.run(指令, shell=True, cwd=repo_root, timeout=LINT_CMD_TIMEOUT)`——指令是字串故 `shell=True`(有別於既有 `_pitfall_diff_mode` 的 list argv,本塊刻意用 shell 跑專案宣告的指令字串);**`{LINT_SARIF_OUT}` 注入用 `str.replace('{LINT_SARIF_OUT}', shlex.quote(臨時檔路徑))`**(r2-F6:shell=True 下路徑須 `shlex.quote` 防空白/元字元拆詞,否則 SARIF 寫錯位、pitfalls 讀不到全落 lint_skipped);`LINT_CMD_TIMEOUT` 常數(預設 180 秒)防 detekt/dotnet build 這類重量級跑掛住 pitfalls 的輕量提示器語意(r8-F3:shell=True 逾時只殺 shell、JVM 孫進程會孤兒續跑 → 用 `start_new_session=True` + 逾時時 `os.killpg` 殺整個 process group);**臨時檔生命週期(r9-F2)**:用 `tempfile.mkstemp` 生成、跑完 `os.unlink` 清理(lumos 現無 tempfile 先例,明定免洩漏累積)(r1 canary 掩蓋的真 gap:既有 subprocess 無 timeout、git 快無妨,外部 linter 慢必須設限)。
- 解析 SARIF:`json.load` → **對每個 `run` 配對其 driver 與 results**(r1-F5:`tool.driver.name` 是 per-run,須按 run index 配對、非扁平取):`for run in runs: tool = run.tool.driver.name; for r in (run.get('results') or []): ...`(r8-F2:`results` 是 SARIF optional,零 finding 的 driver-only run 缺 `results` → `run.get('results') or []` 免 KeyError 誤落 coarse skip) → 每筆映射 claim `{file, line, source, rule, message}`。**單筆容錯(r4-F1,承重)**:`result.locations` 在 SARIF 2.1.0 是 optional(project/compiler-level 診斷可零 location——ESLint/Roslyn/Sonar 會吐,detekt tracer 恆帶故打不到此路徑);每筆 result 的 location 存取包 `try/except`,`locations` 空或無 `physicalLocation` → **跳過該筆 finding**(或記 file-less claim 不參與 diff 行過濾),**絕不連坐丟整個 run**——容錯粒度是「該 finding」非「整指令」(否則一筆 location-less 讓該 run 其餘合法 findings 全靜默歸零):
  - `file` = `r.locations[0].physicalLocation.artifactLocation.uri` **正規化為 repo 相對正斜線路徑(r3-F2,承重 join key;KDS tracer 2026-07-04 真機坐實)**:剝 `file://` scheme、`urllib.parse.unquote` 解 `%20`、絕對路徑轉 `os.path.relpath(路徑, repo_root)`、反斜線轉正斜線——與 `added` 集合的 key(`+++ b/<path>` repo 相對正斜線)同形才比得中。**tracer 實測(detekt on Citrus_KDS)**:uri=`file:///Users/enzo/Citrus_KDS/app/.../X.kt`(絕對 file://)、`originalUriBaseIds={}`、`uriBaseId=null`——若不剝 scheme+relpath,絕對路徑永不匹配 diff 的 `app/...` repo 相對 key、lint 靜默歸零(坐實此段承重)。**uriBaseId 兼容(其他工具)**:detekt 無 uriBaseId,但 ESLint/Roslyn 可能吐相對 uri + `uriBaseId` → 有 uriBaseId 時以 `run.originalUriBaseIds[uriBaseId].uri` 為 base(r4-F3:originalUriBaseIds 是 run 屬性、須在 `for run in runs` scope 內取)拼接再 relpath(正規化須兩式兼容)
  - `line` = `r.locations[0].physicalLocation.region.startLine`(缺則 0)
  - `source` = `"lint:" + tool`(該 result 所屬 run 的工具名)
  - `rule` = `r.ruleId`;`message` = `r.message.text`(截 120 字)
- 指令失敗(rc≠0 **且無 SARIF 產出**——rc≠0 是 linter 有 finding 的正常訊號,有 SARIF 就不算失敗,r1-F3② 澄清;**KDS tracer 坐實:detekt 333 issues 時 exit 非零但正常產 SARIF**)/逾時/SARIF 解析失敗 → 印警示、跳過該指令記 lint_skipped、續跑其餘(容錯,**lint 失敗不改 pitfalls rc**)。**rc 語意精確化(r2-F3)**:diff 模式 rc = 掃描成功 0 / git 無或 range 解析失敗 2(既有 `_pitfall_diff_mode` 行為,lint 整合不動它);「rc 恆 0」僅指 lint 失敗不升 rc,非「任何情況都 0」。

### ④ 過濾到 diff 觸及行
- **建行集合(r1-F1:非「復用現成集合」)**:在既有 `_pitfall_diff_mode` 的掃描迴圈內**加一行 accumulator**——確認 `+` 新增行時同步 `added.setdefault(cur_file, set()).add(new_ln)`;regex 骨架(`_PITFALL_DIFF_PATTERNS`、`@@`/context/`+`/`-` 推導、skip 過濾)一字不動,只加集合累積(加法擴充、非改骨架)。
- SARIF finding 只保留 `(file, line)` 落在 `added` 集合內者(對齊「只提示本次改動風險」,不倒入專案舊 lint 債)。
- **座標系前提(r1-F2,承重)**:lint 指令對**工作區檔案**跑(SARIF startLine=工作區行號),而 `added` 是 `git diff <range>` 的 **range HEAD 端行號**——**兩者僅在「工作區 == range 的 HEAD 端」時對齊**。本塊的合法使用前提=**range 形如 `<base>..HEAD` 且工作區乾淨**(code-loop 終審調用即此:`merge-base..HEAD`、終審時工作區=HEAD)。**非對齊情形**(dirty tree、歷史區間如 `HEAD~3..HEAD~1`)→ pitfalls 對齊判定用**語意解析非字面比對**(r2-F5,承重):**右端抽取明定(r3-F4)**:右端 ref 抽取:**先判 `...` → `rsplit('...',1)[-1]`;否則 `..` → `rsplit('..',1)[-1]`**(r5 auditor git 實測修:`split('..',1)` 把 `a...b` 切成右端 `.b` 殘留前導點、`git rev-parse .b` fatal;故用 rsplit 且先 `...` 後 `..`);右端空(`a..`)→ HEAD;無 `..`(單 ref,`git diff` 語意=比工作區)→ 右端視為工作區、恆對齊。取得右端 ref 後 `git rev-parse <右端 ref>`(**單一 ref 非整條 range,整條 range rev-parse 會回兩行**;cwd=repo_root) == `git rev-parse HEAD` 且 `git status --porcelain` 空 → 對齊。**判定用 rev-parse/status 本身失敗(壞 ref rc≠0/非 git)→ 視為非對齊、降級全收不升 pitfalls rc**(r6-F3)。**事實校正(r3-F3)**:code-loop 實傳 `<merge-base-sha>..HEAD`(HEAD 保持字面 ref、非展開成 sha),故右端解析為 HEAD、正確判對齊(r2-F5 原稱「展開成 <sha>..<sha>」為事實錯誤,結論仍成立)。非對齊 → **印警示「座標系可能不對齊、lint 行過濾略過、改為全收 lint findings(不過濾 diff 行)」**——寧可多收不誤刪(偏嚴,掃描成功仍 rc 0)。

### ⑤ 合併 + tier + 輸出
- lint claims 與既有 regex claims **合併**進同一 manifest;每筆帶 `source`(`lint:<tool>` 或 `pitfalls-builtin`)區分。**lint claim 無 `question` 欄——reviewer 鏡頭對 lint claim 讀 `message`(linter 自帶的問題描述)取代 regex claim 的 `question`**(r1-F4:code-loop reviewer prompt 的「逐條判真隱患/誤報」對 lint claim 以 message 為據,不套「必答對應提問」——lint 沒有 pitfalls 式提問)。
- manifest schema 擴充為 `{file, line, source, ...}`——regex claim 補 `source: "pitfalls-builtin"`、保留原 `class/pattern/question`;lint claim 用 `source/rule/message`(無 class/question——lint 自帶訊息)。**向後相容**:既有欄位不刪。
- tier:regex 或 lint 任一有 claim → high;皆無 → standard。rc = 掃描成功 0 / git 無或 range 解析失敗 2(r3-F5:同 §③ 精確語意,此處原裸「rc 恆 0」散落漏改已對齊——lint 失敗不升 rc、非任何情況都 0)。
- `--json`:`{claims:[...], tier, lint_ran: [<跑過的指令摘要>], lint_skipped: [<失敗跳過的>]}`(新增 lint_ran/lint_skipped 供人看有沒有真跑到)。

### ⑥ 無宣告 / 無 lint 的 fallback
- `.lumos/lint.json` 不存在 → 完全走現有 regex-only 路徑,行為與本塊前分毫不變(回歸釘)。
- 有宣告但 diff 未觸及宣告棧 → 只 regex。

## canary 相容性(不可違反)
- 本塊只擴充 `--diff`(代碼層提示),不碰 spec 模式/`--check`/canary 保留地。
- lint 跑真 diff 涉及的真檔,與 code-loop 的 bug canary(工作副本層)不相交。

## 邊界 / 非目標(YAGNI)
- ❌ 不自動偵測 lint 指令(方案 B);不內建任何棧規則。
- ❌ 不做 SARIF 全欄支援:只取 file/line/ruleId/message/tool.name(**不取 level**,r2-F4:天花板 2 已定「不依賴 level 分級」,claim schema 無 level 欄,三處統一),其餘(level/codeFlows/fixes/relatedLocations)忽略。startLine 缺失的 finding → line=0、不落 added 集合(靜默漏,r2-F4:低發生率、記此)。
- ❌ 不縮/退役既有 regex pattern 表(留計劃後續;本塊只「共存合併」,pattern 表縮是獨立小改)。
- ❌ 不做 lint 結果快取(每次真跑;效能問題留 v2)。
- ❌ 不裝/不管理 linter(專案自己裝;沒裝→容錯跳過)。
- ❌ 不改 spec 模式、`--check`、gate、code-loop skill。

## 誠實天花板
1. **只收 diff 觸及行**:漏「本次改動害他處 lint 壞」(如改了共用函數簽名、他處 call site lint 紅但不在 diff)。換得「不倒入舊債」的聚焦,低風險可接受。
2. **SARIF level 語意各工具不完全一致**:error/warning/note 的界線工具間有差;本塊不依賴 level 分級(命中即進 manifest、tier 只看有無),迴避此不一致;若未來用 level 排序需另議。
3. **要專案先配 `.lumos/lint.json`**:一次性,但 Android/Vue/C# 專案本就該有 lint 配置;未配則本塊等於沒開(退回 regex)——漸進採用,不強迫。
4. **runner 執行 shell 指令**:`.lumos/lint.json` 的指令由專案作者寫、lumos 照跑——等於信任專案宣告檔(同 guard 範本、hooks)。非對抗場景(自己的 repo),威脅模型是配錯非惡意注入。
5. **行號比對容差**:SARIF 報的行 vs diff 新增行,若 linter 報的是「區塊起始行」而該行不在 diff 但區塊跨進 diff,可能漏;本塊只做精確行比對,粗放匹配留 v2。**offset-only region(r7-F3)**:SARIF region 允許純 `charOffset`/`byteOffset` 無 `startLine`(低階工具),此時 line=0→不落 added→靜默漏(同 startLine 缺失處理,detekt tracer 恆帶 startLine 打不到);v1 接受,offset→line 換算留 v2。
6. **座標系對齊是前提非保證(r1-F2)**:lint 跑工作區、過濾用 range HEAD 端行號,僅 `..HEAD`+乾淨工作區對齊;非對齊自動降級為「全收不過濾」(偏嚴)。**量級認知(r7-F2)**:成熟 repo 的全 repo lint 債可達數百條(KDS tracer 一次 333),dirty-tree 降級會把全部灌進 manifest——故降級時 manifest 明標「未過濾全收(座標系不對齊)」+ `lint_ran` 摘要顯示未過濾,讓 reviewer 知這是全 repo 債非本次改動、自行判斷;不硬設截斷閾值(避免又一裸常數,量級由標記透明化而非機械砍)。code-loop 主用例(`merge-base..HEAD`+乾淨)走對齊路徑不觸此分支。
7. **linter 執行成本(r1 timeout gap)**:detekt/dotnet build 可能數十秒到數分鐘,`LINT_CMD_TIMEOUT`(180s)防掛住但也意味 high 風險分支終審會明顯變慢;pitfalls「輕量提示器」語意在有 lint 配置時已非輕量——這是 code-loop 高風險分支的既有成本(risk-tiered 分級控總量),誠實記明。

## 測試策略
沿 `scripts/test_lumos.py` CLI subprocess 風格,git fixture:
1. **無 .lumos/lint.json → regex-only**:現有 t_pitfalls_diff 行為分毫不變(回歸)。
2. **宣告檔解析**:造 `.lumos/lint.json`,副檔名→指令集合正確讀取。
3. **SARIF 解析→claim 映射**:餵一個假 SARIF(含 2 findings)給 runner(用 `echo` 或 `cat` 假指令輸出到 `{LINT_SARIF_OUT}`),驗 claim 的 file/line/source/rule/message 映射正確。
4. **diff 行過濾**:SARIF finding 有的行在 diff 新增行內、有的不在 → 只保留在內的。
5. **lint+regex 合併**:同 diff 既命中 regex 又有 lint finding → manifest 兩者都在、source 欄區分。
6. **技術棧偵測**:diff 只碰 .py、宣告只有 kt → 不跑 lint(lint_ran 空)。
7. **指令失敗容錯**:假指令 rc≠0/無 SARIF → lint_skipped 記錄、rc 仍 0、regex claims 仍在。
8. **去點正規化 witness(r2-F1/r3 測試缺口)**:diff 碰 .kt、宣告 key `kt`、SARIF 有 finding → **lint_ran 非空且 claim 出現**(證 `.kt`→`kt` 對得上;miss 路徑的案 6 接不住此 bug,需正向 witness)。
9. **uri 正規化(r3-F2)**:SARIF finding 的 uri 為絕對 `file:///…/app.kt`(帶 %20 目錄)→ 正規化後 file key == diff 的 `app.kt`、能落 added 集合被保留。
10. **座標系降級(r2-F5/r3-F4)**:dirty tree(git status 非空)或 range 右端≠HEAD → 印警示、lint 全收不過濾(claim 含不在 diff 行的 finding);乾淨 ..HEAD → 正常過濾。
11. **回歸**:兩套件全綠。

## 知識同步影響
| 受影響文件 | 需同步什麼 |
|---|---|
| `skills/lumos-project-notes/SKILL.md` | pitfalls 指令表補「--diff 支援 .lumos/lint.json lint 整合(SARIF)」 |
| `skills/lumos-code-loop/SKILL.md` | pitfalls --diff manifest 現含 lint 來源(source 欄);reviewer 鏡頭對 lint claim 讀 `message`(非 question)、regex claim 仍讀 question(r1-F4) |
| `scripts/templates/graph-discipline.md` | 終審前 pitfalls --diff 段補一句「專案配 .lumos/lint.json 則自動吃 linter」 |
| `docs/methodology/架構圖即合約.md` | pitfalls 列補「lint 整合器(SARIF)——吃社群 linter 非自建規則」 |
| `Projects/pitfalls-lint-integration_計劃` | 第 ① 塊 status 更新 done + verified_by 回指本 spec 落地 Verification |

## 審計修正紀錄(design-loop)

### R1(2026-07-04,canary type a=壞§ref「§runner 逾時與併發」,opus,**CAUGHT**,辯方裁決後 severity=major,存活 findings=7)

canary 被正確識別(F7 明指全文標題清單無此節、為壞引用,並戳出它掩蓋的真 gap:runner 無 timeout)。此輪 auditor 紮實,judge 評 F1/F2/F3 三 major;辯方裁決:
- **F2 維持 major**(座標系錯配:lint 跑工作區 vs diff range HEAD 端行號,精確比對系統性錯位;§誠實天花板漏列)→ 組件④ 補座標系前提(`..HEAD`+乾淨工作區才對齊、非對齊降級全收)+ 天花板 6。
- **F1 降 minor**(new_ln 是區域變數為真,但「加一行 accumulator 進既有迴圈」是加法擴充非改骨架;spec「復用」指 @@ 推導邏輯非現成集合)→ 組件④ 措辭精確化。
- **F3 降 minor**(僅 ①shell=True 未明定為真;②誤讀「且無 SARIF」已處理、③已被容錯接住)→ 組件③ 明定 shell=True。
- **F4/F5/F6 + timeout(canary 掩蓋的真 gap)全折**:lint claim 走 message 非 question(F4)、source per-run 配對(F5)、砍 stdout 單一寫檔契約(F6)、runner 加 LINT_CMD_TIMEOUT(timeout gap)。
存活 7 條全折入(F2 major + F1/F3①/F4/F5/F6/timeout)。

### R2(2026-07-04,canary type b=未定義旗標 `--no-lint`,opus,**CAUGHT**,辯方裁決後 severity=major,存活 findings=5)

canary 性質被點出(R2-F2:`--no-lint` 無 CLI/簽名出處、無接線)——依規不折。此輪挖出 R1 折入後**新生**的可執行性缺口(非重複):
- **R2-F1 major(折)**:副檔名 key 錯配——`Path.suffix` 帶點(`.kt`)vs key 不含點(`kt`),偵測恆空 → 組件② 補去點正規化(承重,實測坐實)。
- **R2-F5 major(折)**:座標系降級的「range 非 `..HEAD`」字面比對會誤判 `merge-base` 展開的 SHA 主用例 → 改 `git rev-parse` 右端==HEAD 語意解析(承重)。
- R2-F3 minor(折):「rc 恆 0」過度宣稱(現況 git/range 錯 rc 2)→ rc 語意精確化。
- R2-F4 minor(折):level 三處矛盾(邊界取/映射無/天花板不用)→ 統一不取 level。
- R2-F6 minor(折):shell=True 下 `{LINT_SARIF_OUT}` 注入未定義引號 → shlex.quote。
存活 5 條全折入(R2-F1/F5 major + F3/F4/F6 minor)。

### R3(2026-07-04,canary type c=未定義常數 `LINT_MAX_PER_FILE`,opus,**CAUGHT**,severity=major,存活 findings=4)

canary 被識別(F1:全文僅一處、無賦值、無測試——裸常數)。此輪挖出折入自引的新縫:
- **R3-F2 major(折)**:SARIF `uri`→repo 相對路徑「正規化」只六字無演算法,是 §④ 過濾承重 join key;ESLint 吐絕對 `file://` 會全不匹配 → lint 靜默歸零(r2-F1 副檔名 bug 的路徑層翻版)→ 明定正規化演算法(剝 scheme/unquote/relpath/正斜線)。
- **R3-F4 minor(折)**:r2-F5 折入的「rev-parse 右端」未定義如何抽右端、整條 range rev-parse 回兩行 → 明定 split `..` 取末段、單 ref 特判。
- **R3-F3 minor(校正,折)**:r2-F5 的 justification「merge-base 展開成 <sha>..<sha>」事實錯誤(code-loop 傳 `<sha>..HEAD`、HEAD 字面保留)→ 結論仍成立、校正敘述。
- **R3-F5 minor(折)**:「rc 恆 0」在 §⑤ 殘留未隨 r2-F3 同步(散落漏改,同 memory「知識同步散落會漏」)→ 對齊。
- 測試缺口(佐證):去點正規化/uri/座標系降級皆無專屬測試 → 補案 8/9/10(正向 witness,miss 路徑接不住 bug)。
存活 4 條全折(F2 major + F3/F4/F5 minor + 測試補)。

### R4(2026-07-04,canary type d=憑空產物 `lint-raw-dump.json`,opus,**CAUGHT**,severity=major,存活 findings=2)

canary 被識別(F2:全文僅一處、無生產規格[路徑/覆寫或累積未定]、無消費端、無測試——write-only 懸空產物)。tracer 後主結構已紮實,此輪揭「tracer 只跑 detekt happy path、跨工具邊界未被真機打到」的縫:
- **R4-F1 major(折)**:SARIF `result.locations` 是 optional(ESLint/Roslyn/Sonar 吐零 location 的 project/compiler-level 診斷,detekt tracer 恆帶 location 故打不到);無條件 `r.locations[0]` 會炸,且容錯粒度「跳整指令」→ 一筆 location-less 連坐丟該 run 全部合法 findings 靜默歸零 → 改單筆 try/except 跳該 finding、絕不連坐。
- **R4-F3 minor(措辭,折)**:`originalUriBaseIds` 是 run 屬性 → 明定 `run.originalUriBaseIds`(在 for run scope 內取)。
存活 2 條全折(F1 major + F3 minor;canary F2 不折)。

### R5(2026-07-04,canary type a=壞§ref「§偵測與快取策略」,opus,**MISSED**,判決不採信)

auditor 漏抓植入的壞 §ref(逐節讀但未點出「§偵測與快取策略」全文不存在)→ 該輪判決作廢、不折。其挖到的 `...` symmetric range `split('..',1)` bug(git 實測 `.HEAD~1` fatal)雖真,依規本輪不折——留醒著輪次;r6 framing 加碼逐一核 § 引用。

### R6(2026-07-04,canary type b=未定義旗標 `--lint-only`,opus,**CAUGHT**,severity=major,存活 findings=3)

canary 被識別(Finding 1:`--lint-only` live 孤兒旗標、無 argparse/簽名/接線,結構同 R2 已退役的 `--no-lint`)。存活真洞:
- **R6-F2 major(折)**:多 linter 並存時 per-command 臨時檔分配未定義——共用一路徑則 detekt/ktlint 互相覆寫、一半 findings 靜默歸零 → 組件③ 明定「每指令各配獨立臨時檔」(招牌前提「多 linter 並存」的縫)。
- **R6-F3 minor(折)**:座標系判定的 rev-parse/status 本身失敗未定義 → 降級全收不升 rc + cwd=repo_root。
- **r5-F1 補折(minor,真洞經 git 實測確證)**:`...` symmetric range `split('..',1)` 殘留 `.HEAD~1` → 改 rsplit 且先 `...` 後 `..`(r5 missed 該輪作廢、但實測確證真洞不放進實作)。
存活 3 條全折(R6-F2 major + R6-F3/r5-F1 minor;canary --lint-only 不折)。

### R7(2026-07-04,canary type c=未定義常數 `LINT_TIER_CEILING`,opus,**CAUGHT**,severity=minor,存活 findings=2)→ 首個乾淨輪

canary 被識別(F1:全文僅一處、無賦值、無測試,且所在子句「超過閾值仍 high」是邏輯空操作——同 R3 `LINT_MAX_PER_FILE` 裸常數缺陷類)。auditor 機械核對(§引用/旗標/ALL_CAPS/產物)+ 語意查證後判「六大承重點全經真機/git 實測坐實、無 blocker/major 結構洞」。存活 2 minor 全折:
- **R7-F2 minor(折)**:座標系降級全收無量級認知(成熟 repo 數百條 lint 債會灌爆 manifest)→ 天花板 6 補量級 + 降級 manifest 標「未過濾全收」透明化(不設截斷閾值免又一裸常數)。
- **R7-F3 minor(折)**:region offset-only(無 startLine)未記 → 天花板 5 補(同 startLine 缺失、tracer 打不到、v2 換算)。
存活 2 條全折(皆 minor;canary LINT_TIER_CEILING 不折)。

### R8(2026-07-04,canary type d=憑空產物 `stack-detect-report.json`,opus,**CAUGHT**,severity=minor,存活 findings=2)→ 第 2 乾淨輪

canary 被識別(F1:植入級孤兒產物、無生產規格/消費端/schema/測試、與 lint_ran 冗餘——auditor 明指「結構同 R4 canary lint-raw-dump.json」)。排掉 canary 後全 minor:
- **R8-F2 minor(折)**:`run.results` 假設存在,SARIF `results` 是 optional、零 finding 的 driver-only run 會 KeyError 落 coarse skip(誤標成功指令為 skipped)→ `run.get('results') or []`。
- **R8-F3 minor(折)**:shell=True 逾時只殺 shell、JVM 孫進程孤兒續跑 → `start_new_session=True` + `os.killpg` 殺整個 process group。
存活 2 條全折(皆 minor;canary stack-detect-report.json 不折)。

### R9(2026-07-04,canary type b=未定義旗標 `--json-compact`,opus,**CAUGHT**,severity=minor,存活 findings=1)→ 第 3 乾淨輪(連 r7/r8/r9)

canary 被識別(Finding 1:`--json-compact` live 孤兒旗標、無 argparse/簽名/壓縮分支,結構同 R2 `--no-lint`/R6 `--lint-only`)。除 canary 外 auditor 判「與八輪+tracer 打磨版逐位元組相同、六大承重點坐實、無 blocker/major 結構洞」。存活 1 minor 折:
- **R9-F2 minor(折)**:臨時檔生命週期(所在目錄/用後清理)未定義 → `tempfile.mkstemp` + 跑完 `os.unlink`(lumos 現無 tempfile 先例,明定免洩漏)。
存活 1 條折(minor;canary --json-compact 不折)。

## 收斂

**GATE PASS**(2026-07-04):design-loop 9 輪(r1-r4 major、r5 missed 作廢、r6 major、**r7/r8/r9 連 3 輪 caught+minor**)+ KDS 真機 tracer 坐實六大承重點;K-streak 連 3 ∧ G1 引用座標 ∧ G2 findings [2,2,1] 枯竭(單調不增、末輪 1、末步 2→1 降)全過。此塊整合外部工具的邊界複雜度高(location-less/per-command temp/git 失敗/range split/uri 正規化每輪一個真洞),9 輪+tracer 系統性磨平。

**跨家族複核**:qwen worst=major 但逐條機械反證——① §壞引用實為 R1/R5 canary(真檔 refcheck 6 座標全 ok、正文無)② 座標系錯配已折(§④ 降級 + tracer 坐實)③ 其餘 qwen 自標 minor+「已修正/caught」——0 條 ≥major 成立 → endorsed-after-refute 放行(convergence-evidence-gate 計票第三次擋同型 qwen 誤報;佐證 backlog『cross_audit 對長 R 紀錄段易誤讀 canary』gap)。
