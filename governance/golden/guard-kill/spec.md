---
type: project
status: doing
created: 2026-07-10
updated: 2026-07-10
tags:
  - type/project
  - status/doing
decisions:
  - content: 壞法人宣告(kill 配方進 decisions)+config 宣告 run_cmd,不做自動變異生成
    context: 零依賴跨語言(C#/Kotlin/E2E/python)工具不內建語言知識;自動生成變異有等價變異不可判定問題(實務 4-39% 誤報)
    why_chosen: 人宣告的壞法保證語意有變(繞開等價變異,pytest-mutagen/ISO 26262 先例);run_cmd 沿 .lumos/lint.json 既有信任模型(專案自己宣告的指令);universalmutator ICSE 2018 實證文字層+外部指令 rc 跨語言可行
    decided: 2026-07-10
    valid: true
  - content: 四態判定(killed/survived/timeout/error)+baseline 前置,error 不得記 killed
    context: 紅燈≠殺傷:本來就紅的測試會假殺、編譯錯的紅是最常見假殺來源
    why_chosen: cargo-mutants baseline 流程+timeout=baseline×5下限20s 整套照搬;PIT/cosmic-ray 的獨立 timeout 類別;survived 才 rc1(稻草人)、環境問題 rc2 分開
    decided: 2026-07-10
    valid: false
    superseded_by: r1 審計折入:改六值 verdict(killed/timed_out歸killed類/survived/drifted/abort/error),timeout 歸 killed 對齊 PIT/cargo-mutants(變異致掛=被超時接住);原『獨立 timeout 類別』引用與 PIT 實際語意相反
    ended: 2026-07-10
  - content: 六值 verdict+timeout 歸 killed+baseline 前置;v1 砍 hydration 與 lockfile(否決位裁定:成本/風險大於收益)
    context: r1/r2 panel 折入
    why_chosen: PIT 把 TIMED_OUT 記 killed(變異致掛=被接住);hydration 為邊緣便利換一片 binary/untracked 新風險面;lockfile 唯一命名已防碰撞、stale 死鎖反成新風險
    decided: 2026-07-10
    valid: true
related:
  - "[[Projects/社群演算法補強_調研]]"
  - "[[Systems/check-t-sentinel]]"
  - "[[Systems/check-r-guard]]"
  - "[[Systems/test-profile-multiplatform]]"
---
# guard殺傷力驗證_計劃

## 目標

補 ★INVARIANT★→`[test:]` 合約鏈的最後一哩：Check T 只驗「綁的測試存在」、`[audit:]` 靠 agent 讀判「夠不夠格」——都沒有**真的打一拳**。新增 `lumos guard kill`：對綁定的測試，在隔離環境故意弄壞被守護的行為，測試必須翻紅；全綠＝綁定是稻草人（假證據），機械可證。

PRIOR-ART: ① 最小解層級：既有 guard 家族加子命令 + config 加欄位，無新物種。② 世界解過（2026-07-10 專項調查，來源見文末）：pytest-mutagen（人宣告壞法、逐 mutant 期望翻紅——概念完全對口但綁死 python/pytest）、ISO 26262 fault injection（安全領域制度化的「宣告故障+期望防護翻紅」）、StrykerJS command runner / cosmic-ray test-command / universalmutator（「config 宣告任意測試指令、rc 判紅綠、工具不內建語言知識」的跨語言介面，ICSE 2018 實證）、cargo-mutants（baseline 前置 + timeout=baseline×5 下限 20s）、PIT/Stryker（四態判定 killed/survived/timeout/error 與增量失效）。③ 裁定 = **borrow-design**：「宣告式 kill 配方 × command-runner × 架構圖綁定」組合世界無既成品，各構件皆有先例背書；零依賴 stdlib 原生實作。

## 設計裁定（r1/r2 兩輪折入後修訂版）

1. **壞法由人宣告，不自動生成；配方存節點級 `kill_recipes` frontmatter 欄位（r1 折入：不進 decisions——decisions 是節點級平面陣列、與個別 KEY 行無映射，「對應 decision」無資料模型可依）**。`kill_recipes` = block scalar 內 JSON array，每條配方自帶歸屬：`{"invariant":"<KEY子字串>","test":"<綁定測試名>","platform":"<平台名,單平台可省>","file":"<相對該平台root>","old":"...","new":"...","note":"業務上壞了什麼"}`。KEY 行尾標 `[kill:recipes]`（存在性標記；**lint 專責**驗 recipe.invariant 匹配到某 ★INVARIANT★ 行 + 反向孤兒標記——doctor v1 不加檢，與 CLI 面一致）。`old` 為 **literal 字面替換**（str.replace，非 regex；含換行走 JSON `\n`），唯一命中的權威判定時點=worktree 內套用時（count==1，否則 `drifted`）；kill-add 時對當下工作樹預檢並提示。**配方從業務行為推導、不從實作反轉**（DO-178C 教訓）；一條 INVARIANT 可綁多條配方（N=1 證據力弱）。
   - **同步改動明列（r2 修訂——r1 版歸因有誤）**：① `INV_TAG_RE` 擴為 `(test|audit|kill)`（否則 `[kill:recipes]` 漏進 strip_test_refs 乾淨合約文字，污染 Check T 顯示/scaffold stub/audit 比對——:1029/:1249/:2220/:2242（audit 第二處 match 同用）；**bind :2157 用 TEST_REF_RE、不受擴充影響也無需改**——業務子字串不會撞標記文字，r1 把它列進來是歸因錯誤）；② 新 `KILL_REF_RE` 解析 `[kill:recipes]` 存在性（仿 :1214/:1244 樣板）；③ **新 block-scalar-JSON frontmatter 寫入器**（kill_recipes 非純量/list/decisions 三類任一，set/append 白名單寫不了——kill-add 的 frontmatter 與 KEY 行標記**同檔一次 atomic_write_verify** 原子落地，無半寫狀態）；④ `load_platforms` 擴充保留 `run_cmd` 欄（現行只回 profile/root）；⑤ `classify_invariants`+`cmd_guard_list` 加 kill 欄；⑥ `cmd_gov` 第 5 支 load+mapper、scaffold .gitignore 樣板、cochange 預設排除各補 .kill-log；⑦ `scripts/templates/graph-discipline.md` 欄位速查補 kill_recipes/[kill:recipes] + `t_marker_doc_sync` 機械漂移守衛測試加 `[kill:` 標記（比照 rollback/guard 待遇）。⑤ 的 kill 欄顯示注意：clean 文字已被擴充後的 INV_TAG_RE 剝掉 kill 標——顯示判定要從原始 KEY 行或 kill_recipes 讀，不從 clean 文字。**JSON 形狀釘死：單行 compact array**（parse 器對 block 逐行 strip 且靠縮排判界，多行 pretty JSON 會被截斷）。
2. **跑測試靠 config 宣告指令**：多平台 → `platforms.<名>.run_cmd`；**legacy 單平台 → `test.run_cmd`**（r2 折入：收進既有 test.* 巢狀）。**並存優先序（r3 折入）**：config 有 `platforms` 鍵即整組走多平台、`test.run_cmd` 不生效並印告警（load_platforms 的二分慣例）；legacy 分支需專門讀 `test.run_cmd`（與 platforms.X.run_cmd 巢狀層級不同，實作注意）。`run_cmd` 含 `{method}` 佔位（多平台 ref 取**裸方法名**、剝平台前綴；legacy 裸 ref 含冒號時不切分、整串代入會被重驗擋下——記為已知邊界；代入前重驗：IDENT_RE **或** Kotlin 反引號名（去引號後限字母數字/空白/點的白名單）+ 一律 `shlex.quote`——`[test:]` 可被手改，不可信任；沿 `_lint_run_and_parse` 先例 `scripts/lumos:4642`，**注意先例是唯讀 linter、本功能會寫檔+跑有副作用的測試，信任邊界同為「專案自宣告指令」但爆炸半徑更大，見裁定 3 圍欄**）。無 `{method}` 的 run_cmd 允許但 verdict note 記 `whole-suite`（baseline 語意變成全套綠）。缺 run_cmd → rc 2 明確報。執行一律 `Popen(shell=True, start_new_session=True)` + timeout 到期 `os.killpg`（沿 :4666-4681，殺得掉 dotnet/vstest 孫進程）；cwd=**該配方平台的 worktree 根**。
3. **原始碼層隔離 + baseline 前置（r1 折入：正名——worktree 只隔離檔案，不隔離 DB/埠/外部狀態）**：對**配方 platform 的 repo root** 開 `git worktree add --detach`（跨 repo 時對 Landmark 那類外部 root 開，不是對 vault repo）；worktree 建在**系統 temp 目錄下**（tempfile.mkdtemp 產生、唯一命名——不放 repo 內，杜絕自遞迴/被掃描）+ **try/finally（先 proc.wait 確認測試進程死透）+ SIGINT 下 `git worktree remove --force`**（配方會弄髒樹，不 --force 刪不掉）+ remove 失敗補 `git worktree prune` 清行政記錄。**不設 lockfile**（r2 折入：唯一命名已防路徑碰撞，git 原生支援多 worktree；lockfile 的 stale 死鎖風險大於「併發 build cache 互撞」的收益——否決位裁定砍）。**以 HEAD 為基準（r2 折入：否決位建議砍掉「帶入未提交變更」——最貴、最邊緣、自帶 binary patch/untracked 邊界的整片新面；主要殺傷對象本就是已提交已綁定的測試）**：kill 只驗已提交內容；`git status --porcelain` 非空 → 大聲警告「未提交變更不會進沙盒——配方目標與綁定測試需先 commit」（**判定對象=配方 platform 的 repo**，即開 worktree 的那個 repo，非 vault repo——跨 repo 場景的關鍵消歧）。hydration 留 v2。**路徑圍欄**：配方 `file` 與 worktree 根**兩邊都 realpath 後**做前綴比對（macOS /tmp→/private/tmp 單邊比對會誤判；擋 `../` 與 symlink 逃逸——這是 lint 先例沒有的寫檔能力，必須新加的圍欄）。baseline = worktree 內先跑未變異 run_cmd，rc 0 才續（非綠 → `abort`）；timeout 基準 = 該次 baseline 牆鐘 ×5、下限 20s（含建置成本，對編譯語言偏鬆——誠實記不精確；**測試專用覆寫** env `LUMOS_KILL_TIMEOUT_FLOOR` 可調低下限，否則 timed_out 用例要等 20s——r3 折入）。**hermetic 前置警語**：run_cmd 若有外部副作用（真 DB 寫入），弄壞行為可能把髒資料寫進共用資源——僅建議對自我清理（交易回滾/finally 全刪）的測試跑 kill。
4. **判定與合併（r1 折入：timeout 歸 killed，對齊 PIT/cargo-mutants——變異致掛而測試靠超時抓到=接住）**。per-recipe verdict 六值：`killed`（紅）✓ / `timed_out`（歸 killed 類、註記）✓ / `survived`（綠——含「filter 零命中」情形：綁定測試沒執行到=守不住這條壞法，語意上同稻草人；留痕存 baseline 輸出尾 200 字供人查證）/ `drifted`（old 零命中或多重命中——配方漂移，原名 stale 更名避免與既有 `lumos stale` 語意相撞）/ `abort`（baseline 非綠）/ `error`（套用後 harness 失敗，**不得記 killed**）。**node-level rc**：任一 survived → 1；無 survived 但有 drifted/abort/error → 2（證據缺損非稻草人）；全 killed（含 timed_out）→ 0。留痕 append **docs/.kill-log.jsonl**（欄位含 `ts`/`node`——gov 的 cutoff 與 node 過濾需要——與 `commit`（對哪個版本跑的）/`note`/`flaky_risk`；abort/error 另存輸出尾 200 字供人查原因）。**「同層」不等於自動被撈（r2 折入）**：`cmd_gov` 是硬編四支 load——要 gov 看得到需加第 5 支 load+mapper；scaffold 的 .gitignore 樣板與 cochange 預設排除清單同為硬編四帳，都要補第五個——三處同步列入交付清單，`--json` 出 manifest。

## CLI 面

- `lumos guard kill-add <node> "<KEY子字串>" --file F --old X --new Y [--test 方法名] [--platform P] [--note "業務上壞了什麼"]` — 寫配方進 `kill_recipes`（T1=本專案「寫 tmp→自驗→atomic rename」寫入慣例；寫後自驗：重讀 parse 得回、invariant 匹配到 KEY 行）+ KEY 行尾補 `[kill:recipes]`（merge 不重複）。`--test` 缺省時取該 KEY 行唯一的 `[test:]` ref；多 ref 必須指明；**0 個 `[test:]`（naked 合約）→ 硬報 rc 2**（kill 的語意就是驗綁定，無綁定無物可驗）。節點零配方跑 `guard kill` 同樣 rc 2 明示。
- `lumos guard kill <node> ["<KEY子字串>"] [--platform P] [--json] [--keep-worktree]` — 跑該節點（或指定合約）的配方。rc 見裁定 4；`--keep-worktree` 保留現場（測試計畫的「無殘留」斷言在不帶此旗標時成立）。
- doctor 不加硬檢（v1）：kill 是主動體檢不是 gate；`guard list` 顯示各 INVARIANT 有無 `[kill:]`（改 classify_invariants + cmd_guard_list）。

## 交付同步清單

- `skills/lumos-project-notes/SKILL.md`：子命令全覽 guard 段 `list/scaffold/bind/audit/trace` → 補 `kill/kill-add`；`lumos guard` 指令區塊補用法。頂層命令計數 **42 不變**（guard 子命令非頂層）。
- guard subparser help 文字補 kill。
- 架構圖：`Systems/check-t-sentinel` 補 kill 機制段、Verification、本計劃 `plan_refs` 回指；related frontmatter 補齊與 body 相關模組一致（四節點）。
- guard-templates 無需動（kill 用配方非範本）。
- 裁定 1 改動明列 ⑥⑦ 的三處硬編同步（cmd_gov/scaffold gitignore/cochange 排除）與 graph-discipline 欄位速查+t_marker_doc_sync 守衛——即本清單的程式面條目（明列與清單雙處記載，防漏）。

## 邊界與誠實天花板

- **E2E（maestro/playwright）**：`{method}` 佔位對 maestro **不成立**（maestro 跑 flow 檔路徑、綁的是 name: 欄位，CLI 無法按 name filter）——E2E 平台 run_cmd 由專案自帶正確形狀（多半整檔跑），無裝置時 run_cmd 非綠 → 走 `abort` 路徑（baseline 前置的副作用，明列）。flaky 紅 ≠ 殺傷：E2E verdict 註記 `flaky_risk`（留痕有欄位），v1 不自動重跑。
- **worktree ≠ 環境隔離**：只隔離原始碼；DB/埠/外部資源共用（r1 否決位 M1）。hermetic 警語見裁定 3。
- **冷 build 成本**（r1 否決位 M2）：fresh worktree 無建置快取，C# 大 repo 每配方一次冷 build——比所引 cargo-mutants（重用 target）貴；v1 接受（偶發體檢非 per-commit 閘），build 產物重用留 v2。
- **submodule**：worktree 不自動 init submodule——依賴 submodule 的測試會假紅走 abort；v1 記載不處理。
- **配方等價風險**（dead code → 永遠 survived，人查）；**配方自身稻草人**（audit 順帶審）；kill 證「這個測試接得住這個壞法」，是存在證明不是覆蓋證明。

## 測試計畫（scripts/test_lumos.py，合成 repo + python run_cmd）

- 六態各一：killed / timed_out（sleep 配方 + `LUMOS_KILL_TIMEOUT_FLOOR` 調低,斷言歸 killed 類）/ survived / drifted（old 漂移與多重命中兩例）/ abort（baseline 紅）/ error（壞語法）；無 run_cmd rc2；legacy 頂層 run_cmd 生效。
- HEAD 基準：worktree **看不到**主樹未 commit 的新測試檔、kill 以已提交內容跑（r2 descope 的反向迴歸）。
- 路徑圍欄：`file` 含 `../` → 拒絕。
- 清理：**成功與失敗路徑（error/abort/中斷模擬）都無 worktree 殘留**（含 `git worktree list` 行政記錄——prune 迴歸）；`--keep-worktree` 有殘留（且測試自行清）。
- `[kill:recipes]` 標記：strip 後乾淨合約文字不含 kill 標（INV_TAG_RE 迴歸）；kill-add 寫後自驗；孤兒配方（invariant 對不到 KEY 行）與**反向孤兒標記**（KEY 有標、kill_recipes 無對應）lint 報。
- {method}：多平台 ref 剝前綴、非識別字拒絕、shlex.quote 進指令。
- rc 合併：混合 verdict 的 node-level rc 斷言 + 全 error 純態 rc2 + 零配方 rc2。
- gov 撈取：kill 一筆後 `lumos gov` 輸出含之（第 5 支 load 迴歸）；scaffold .gitignore 樣板含 .kill-log；cochange 預設排除含 .kill-log；t_marker_doc_sync 含 `[kill:` 標記（三處硬編同步各一迴歸）。
- dirty 工作樹警告：未提交變更時 kill 印警告且以 HEAD 內容跑。

## 驗收（真機）

- 本 repo（legacy config + python run_cmd）：對一條示範 INVARIANT 走完六態。
- **Landmark（C# xunit，跨 repo platform root）**：挑一條已綁 `[test:]` 且測試 hermetic（lab2 finally 全刪那批）的 ★INVARIANT★，platforms 條目宣告 `run_cmd`（`dotnet test --filter FullyQualifiedName~{method}`；注意 `~` 是子串匹配會命中超集，方法名前綴唯一時才精確——驗收時人工確認 filter 命中數），宣告一條業務壞法配方，真跑 kill 至 killed——跨 repo、跨語言、真守衛端到端閉環。**前置**：確認該測試自我清理（否決位 M1 的 hermetic 限縮）。

## 審計修正紀錄

- **r3（2026-07-10，panel W=3 delta：2 canaried opus + 1 否決位；canary 2/2 caught（s1=假裁定編號、s2=幽靈旗標）、0 missed → **首個輪有效回合**）**：三員同抓 hydration descope 殭屍測試句（r2 砍功能漏刪其迴歸——fold-drift 實證，編排者即時修）+ s2 三 medium 折入（dirty 判定對象=platform repo、platforms 存在則 test.run_cmd 不生效+告警、timed_out 測試 floor 覆寫 env）+ s1 四 minor（節標題 r1→r1/r2、T1 詞彙 gloss、:2242 補列、交付清單與明列雙處記載+三處硬編各一迴歸測試）。否決位裁定：「scrub 後可進實作，無設計級缺陷」。
- **r2（2026-07-10，panel W=5；canary s2 caught（attempt_seq/verdict_policy 幽靈機制+與 v1 不重跑矛盾，性質正確）、s1/s3/s4 **missed** → 輪無效 1/4；s3/s4 探針曾各重植一次（probe:recraft×1→pass）**：折入有效來源（s2/s5 + 剔除者經編排者機械覆核為真的部分）——**v1 descope×2（否決位裁定）**：砍 hydration（binary/untracked 整片風險面隨之消失）、砍 lockfile（唯一命名已足、stale 死鎖反成新風險）；gov「同層=撈得到」假宣稱修正+三處硬編碼同步（cmd_gov 第5 load/scaffold gitignore/cochange 排除）+graph-discipline 欄位速查與 t_marker_doc_sync 守衛（s4）；realpath 雙邊比對；worktree 移系統 temp+prune；ADR decisions[1] 四態 vs 正文六態矛盾 supersede 修正；bind :2157 歸因錯誤修正（用 TEST_REF_RE 不受擴充影響、無需改——s1/s3/s4 三員一致、編排者驗證）；kill_recipes 寫入器/load_platforms 擴充/KILL_REF_RE 列入改動明列；{method} Kotlin 反引號白名單；--test 0ref 與零配方 rc2；legacy run_cmd 收 test.*；孤兒檢查統一 lint 專責；abort/error 留痕輸出尾；dotnet ~ 子串提醒。**ghost 指控二度覆核為編造**（s1/s4-r1 同款幻覺；ls -f + lumos links resolve 雙重證據：兩 Systems 檔實存且解析正常——r2 的 s4 亦獨立證實無 ghost）。
- **r1（2026-07-10，panel W=5：4 canaried opus（新出題程序首跑：載重錨定+haiku 探針 4/4 probe:pass+事故庫無匹配走輪替）+1 否決位 opus；canary 3/4 caught、s4 missed → near-perfect 判準下輪無效、s4 findings 剔除〔其 ghost 連結 HIGH 經編排者覆核為編造——兩 Systems 檔實際存在〕）**：折入有效來源（s1/s2/s3/s5 + s4 與 s1 重合的 INV_TAG_RE 經覆核）——資料模型重設（配方改 kill_recipes frontmatter、自帶 invariant/test/platform 歸屬——原「對應 decision」無映射可依）、run_cmd legacy 棲身處、worktree 帶入未提交變更+跨 repo 開樹規則+路徑圍欄+finally --force 清理+唯一命名+lockfile、timeout 歸 killed（對齊 PIT）、survived 併 no-coverage 語意+baseline 輸出留痕、stale 更名 drifted、留痕改 docs/.kill-log.jsonl+commit/flaky_risk 欄、INV_TAG_RE 擴 kill+兩函式改動明列、{method} 剝前綴+IDENT_RE 重驗+shlex.quote+killpg、E2E maestro 佔位不成立明列、hermetic 警語+驗收限縮（否決位 M1）、冷 build 天花板（M2）、交付同步清單節新增、先例行號 :4613→:4642+唯讀 vs 副作用限定。

## 相關模組

- [[Projects/社群演算法補強_調研]]
- [[Systems/check-t-sentinel]]
- [[Systems/check-r-guard]]
- [[Systems/test-profile-multiplatform]]

## PRIOR-ART 來源

- pytest-mutagen：github.com/timpaquatte/pytest-mutagen（宣告式 mutant、期望翻紅）
- StrykerJS command runner：stryker-mutator.io/docs/stryker-js/configuration
- cosmic-ray：cosmic-ray.readthedocs.io（test-command+timeout→incompetent 三態）
- cargo-mutants：mutants.rs/baseline.html（baseline 前置、timeout 公式）
- universalmutator：github.com/agroce/universalmutator（ICSE 2018，文字層跨語言+外部指令 rc）
- PIT：pitest.org/faq（KILLED/SURVIVED/TIMED_OUT/NO_COVERAGE、targetTests、withHistory）
- ISO 26262 fault injection、DO-178C requirements-based coverage（需求推導壞法、人審把關）
