# Lumos

**繁體中文** · [English](README.en.md)

> **Lumos —— 揭開全 AI 開發的黑箱,照亮通往正確需求的路。**
>
> (路摸思:點亮咒。一邊照「程式碼」——把藏起來的為什麼、決策、硬合約照出來;一邊照「需求」——用繞不過的對話逼出理解,讓人走對路。Lumos 不替你把需求變對,它把路照亮、讓你自己走對。)

「**圖譜即合約**」方法論的**完整工具組唯一源**。把每一次全 AI 迭代織進「已理解的布」:知識圖譜是專案的唯一真相來源(為什麼這樣設計 / 邊界 / 不可改的合約),用 **commit-time 強制力與可執行合約測試**確保它不腐爛。

> **本治理建立在 [Claude Code](https://claude.com/claude-code) 之上。** 整套規範以 Claude Code 為執行的 AI agent 來設計:`skills/` 是 user-scope 的 Claude Code skills(symlink 到 `~/.claude/skills/`)、紀律注入專案的 `CLAUDE.md`、L1/L3 在 Claude Code session start 載入、`[audit:]` 獨立合法性審計用**乾淨的 Claude agent**(maker ≠ checker)。`scripts/lumos` CLI 本身是純 python、哪裡都能跑;但「先讀後動 / 退場寫回 / 獨立審計」這條完整迴圈假設 agent 就是 Claude Code。

---

## 1. Lumos 解決什麼

當 AI 寫了大部分的 code,瓶頸就從「生不生得出 code」變成「**我們還懂不懂這系統、看不看得出某個改動是錯的**」。Code 只告訴你「現在長這樣」,它說不出:

- **為什麼**這樣設計(決策、被否決的方案)。
- **邊界**在哪。
- 哪些行為是**合約**(改了 = breaking)、哪些是**偶然**(可隨意重構)。
- 有沒有**驗證過**、在什麼前提下成立。
- 這個動作**可不可逆**、搞砸了怎麼收回。

Lumos 把這些知識存成一張 Markdown 筆記圖譜(Obsidian 相容,但**核心不需要 Obsidian app**;僅兩支選配 Claude hook 的部分功能在無 Obsidian 時自動降級),用零依賴的 python CLI + git hooks 讓「**不更新圖譜**」比「更新圖譜」更難。

---

## 2. 核心理念:圖譜即合約

- **圖譜是意圖與合約的真相。** 圖譜與其他文件 / 記憶 / 臆測衝突 → 以圖譜為準。**但行為事實不是**——「現在實際跑成什麼樣」的權威是測試 / 執行結果 / 生產觀測；兩者衝突時不自動判圖譜為真，那代表有東西壞了，查清哪邊錯並立事故節點（2026-07-29 外部評審吸收：本專案自己出過「圖譜寫舊態、程式已更新」的活例，照舊規則會把正確的碼判成錯）。
- **先讀再動。** 動既有系統前,第一個動作是 `lumos`,不是 `grep` / `Read` / 查 DB。圖譜先給你合約與邊界,code/DB 只拿來印證細節。
- **退場寫回。** 做完把決策 / 驗證 / 合約寫回圖譜。
- **commit-time 強制。** pre-commit 硬擋「改 code 沒更新圖譜」;`lumos doctor` 證明圖譜內部一致、且每條載重宣稱都綁了可執行測試。

---

## 3. 工具組內容

| 類別 | 檔案 / 命令 | 作用 |
|---|---|---|
| **CLI** | `scripts/lumos`、`scripts/test_lumos.py` | 純 python3 標準庫、零依賴、61 個頂層命令。讀 / 寫(寫後自驗)/ 巡檢(`doctor`)/ 歸檔。 |
| **合約守衛 scaffold** | `lumos guard list/scaffold/bind/audit/trace/kill` | 對談驅動:列未綁的 `★INVARIANT★`、套範本產**預設紅燈**測試 stub、綁 `[test:]`、蓋獨立 `[audit:]`;`kill` 沙盒真弄壞驗殺傷力。 |
| **檢索與推薦** | `lumos search`(預設相關性排序)、`impact --ranked`(已接 hook)、`context --recommend`(dormant) | BM25F+圖分融合;search 與 hook 面均經人工 goldset 評測轉正(§6 門檻;評測釘語料快照可重現)。評測器 `governance/eval/retrieval_eval.py`。 |
| **對抗審計 loop** | `lumos pitfalls`、`code-loop`、`canary`、`loop`、`fold-check`、`refcheck` | `pitfalls --diff` 分 tier;tier=high 走 canary 護的 `code-loop`(對抗代碼審);`design-loop` 在進實作前審 spec;`fold-check` 抓設計折入漂移。 |
| **影響 / 完整性** | `lumos impact`、`anchor verify/approve`、`lumos testmap` | `impact` 由改動的檔反查受影響關聯節點(直接/間接)+ 命中事故(`pitfall_when`);`anchor` 守測試/閘檔不被**無聲**竄改(改動偵測:防意外/無痕漂移;同 repo 內自簽,非防蓄意攻擊的信任根);`testmap` 建檔案↔測試依賴地圖(naming/content/cochange 三路訊號),`affected` 依 diff 推薦該跑測試(advisory,Landmark 真庫金標雙層 recall 1.0 轉正)。 |
| **git hooks** | `scripts/hooks/` | pre-commit 硬擋「改 code 沒帶圖譜」;post-commit 留繞過痕跡;pre-push 跑 `doctor --ci` **+ anchor verify + tier=high 未過 code-loop 硬擋**。 |
| **Claude hooks** | `scripts/hooks/claude/` | PreToolUse:改 code 前注入 impact 影響半徑;PostToolUse:自足性 / verification-rot 後驗。(2026-07-06 ADR:撤除 Stop 每回合 code-loop nag——太擾民,code-loop 由 pre-push 單點把關) |
| **安裝器** | `get.sh`、`get.ps1`、`install.sh`、`scripts/merge-claude-settings.py`(底層 `install-hooks.sh` / `install-graph-toolchain.sh`) | `get.sh` 一鍵到底(機器層+專案層 auto-init,2026-07-25);`get.ps1`(Win)仍兩步(機器層+手動 `lumos init`)。設 hooks / 合併 Claude settings。 |
| **紀律範本** | `scripts/templates/graph-discipline.md` | 「圖譜先行」紀律,注入各專案 `CLAUDE.md`。 |
| **skills** | `lumos-project-notes`、`core-knowledge`、`design-loop`、`code-loop`、`pitfalls-gapfill` | 寫給 **AI** 的圖譜讀寫規範與對抗審計 loop 編排(user-scope 共用)。 |

---

## 4. 快速上手

### 4a. 已導入 Lumos 的專案
clone 後在裡面跑一個指令——**連 Lumos 都自動幫你 clone**:

```bash
git clone <你的專案> && cd <你的專案>
python3 scripts/lumos bootstrap     # 自動:clone Lumos(若缺)+ user-scope skills + 全域 lumos + repo hooks
```

然後**重啟 Claude Code session**(L1/L3 hooks 在 session start 載入)。

> `bootstrap` 預設**不**拉更新。日後更新:`git -C ~/harness/lumos-toolchain pull`(全 symlink),或 `lumos bootstrap --pull`。

### 4b. 全新專案導入(一條指令)

**站在你的專案裡跑**(連 Lumos 都自動 clone;2026-07-25 起 get.sh 委派 bootstrap,一鍵到底):

```bash
cd <你的專案>
curl -fsSL https://raw.githubusercontent.com/citrus-android-developer/Citrus_Lumos_Full/main/get.sh | bash
# 會問「要把 <路徑> 建成 lumos 專案嗎? [y/N]」→ 按 y 即建圖譜+工具+hooks;然後重啟 Claude Code session
```

- 機器層(clone Lumos+skills+全域 `lumos`)＋專案層(確認後 auto-init)一次完成;**問句預設 N**,站在不想導入的 repo(如 dotfiles)按 Enter 就跳過。
- 非互動/CI:`… | bash -s -- --init` 免確認直接建;`--pull` 拉最新。可先 `curl -fsSL <url> -o get.sh` 審閱再跑。
- 站在**非 git 目錄**跑 → 只裝機器層(同舊行為)。

**顆粒操作(進階)**:只建專案層用 `lumos init`(slug 預設取資料夾名,`--name` 自訂;既有 vault **絕不覆寫**,`--no-hooks` 輕量版);只裝機器層用 `lumos install`。安裝↔卸載對稱:`bootstrap/get.sh ↔ teardown`(一鍵)、`install ↔ uninstall`(機器層)、`init ↔ deinit`(專案層)。

<details><summary>進階/離線:手動 install-graph-toolchain</summary>

```bash
git clone https://github.com/citrus-android-developer/Citrus_Lumos_Full ~/harness/lumos-toolchain
cd ~/harness/lumos-toolchain && ./install.sh        # user-scope skills(symlink)
python3 scripts/lumos install                       # (選用)全域 `lumos` 上 PATH
scripts/install-graph-toolchain.sh --target <專案路徑> --slug <名稱>
```
</details>

### 4c. Windows(原生 PowerShell)
前置:Git for Windows(自帶 bash 跑 git hooks)、python on PATH、Claude Code。

```powershell
irm https://raw.githubusercontent.com/citrus-android-developer/Citrus_Lumos_Full/main/get.ps1 | iex
# 重啟 Claude Code session(L1/L3 在 session start 載入)
# 若 lumos 找不到:把 %USERPROFILE%\.local\bin 加進 PATH
cd <你的專案>; lumos init
```

`get.ps1` 裝「機器層」:clone Lumos(若缺)+ 呼叫 `lumos install` —— 全域 `lumos` 用 `%USERPROFILE%\.local\bin\lumos.cmd` shim、user-scope skills 用目錄 **junction**(`mklink /J`,失敗才退回複製),皆零權限免 admin;個別 Claude hook 的 `.py` 一律**複製**到 `~/.claude/hooks/`。接著 `lumos init` 同 Unix 建專案層(圖譜骨架 + vendor 工具 + git/Claude hooks)。

### 為什麼分兩層裝?
CI 只 checkout 專案 repo、git hook 是 per-repo,所以**工具組必須 vendor 進各專案**;而 **skills 是 user-scope**(一份共用、symlink 到 `~/.claude/skills/`)。對 Lumos clone `git pull` 會即時更新 skills + 全域 CLI;專案裡 vendored 的工具組用 `lumos update` 刷新。

---

## 5. 心智模型:節點與標籤

### 節點型別(frontmatter 的 `type:`)
`system`(模組:流程、合約、依賴)· `verification`(測試/審計紀錄)· `issue`(發現)· `project`(計劃)· `moc`(索引)。

### `summary` 符號行(Systems / Issues)
`summary:` block scalar,每行一個前綴,讓你掃一眼就掌握模組:

| 前綴 | 意義 | 前綴 | 意義 |
|---|---|---|---|
| `FLOW:` | 核心流程 `a→b→c` | `VERIFY:` | 驗證連結 `[[..]]` |
| `KEY:` | 關鍵概念/欄位 | `DECISION:` | 決策指針(簡版) |
| `DEP:` | 依賴模組 `[[..]]` | `FLAG:` | 語意標記(`TECHNICAL`/`ORIGIN`…) |
| `TEST:` | 測試狀態 | `AUTH:` | 認證方式 |

### 三條強制的「鏈」(Lumos 的差異化)

**合約鏈** —— *這是不是規則、有沒有被證明?*
```
KEY:★INVARIANT★ <業務合約;改 = breaking> [test:方法名] [audit:模型/日期]
                 └ 宣稱          └ 可執行證據    └ 無脈絡獨立 agent 的合法性判決
KEY:★DEBT★ <已知偶然行為;可改、不算 breaking>
```
- `★INVARIANT★` **必須**綁 `[test:]`(一個真的存在於 code 的測試方法)——否則 `doctor` 報「裸合約」並擋。
- 然後**必須**帶 `[audit:]` —— 由**無對話脈絡的 agent** 判決「這真的是合約、測試不是套套邏輯」(maker ≠ checker)。缺 = 「未審」,`--ci` 下擋。
- *不確定是不是合約就不標。* 嚴禁從 code 反推「應該是合約吧」。

**可逆性鏈** —— *能不能 undo、怎麼 undo?*(僅 Systems)
```
KEY:★IRREVERSIBLE★ <收不回:prod 遷移 / 上架> [rollback:decisions]
KEY:★CHECKPOINT★   <改了難救:部署測試機>
未標 = 可逆(git/測試級,放手)
```
- `★IRREVERSIBLE★` **必須**帶 `[rollback:decisions]`,且節點 `decisions[]` 要有一條非空 `rollback` 欄位(實際回退 SQL / 補償步驟)——否則 `doctor` 的 **Check R** 擋。
- `★CHECKPOINT★` *建議*帶(缺 = warning,不擋)。
- **天花板**:`[rollback:]` 證明*你寫下了 undo 路徑*,**不**證明它跑得動、或還符合現行 schema——同 `[test:]`/`[audit:]` 的誠實。別把「有回退」當「安全」。

### frontmatter 欄位
`status`(`doing`/`pass`/`open`/`done`/`stale`/`superseded`…)· `verified_by` / `plan_refs` / `related` / `tags`(list)· `decisions[]`(ADR:`content`/`context`/`alternatives_considered`/`why_chosen`/`trade_offs`/`decided`/`valid`/`superseded_by`/`rollback`)· `valid_under` / `revalidate_when`(重驗條件)· `core_refs`(指向跨專案核心圖譜)。

> ⚠ 多個 wikilink 必須是 YAML **list**、一項一行(`- "[[A]]"`)。單字串 `"[[A]], [[B]]"` 會長出 ghost 節點。純量/list/decisions 一律走 `lumos set`/`append`/`decision-add`(安全格式 + 寫後自驗),別手改。

---

## 6. 日常工作流

```
進場 ── lumos search <關鍵字> → lumos context <節點> → lumos contracts <節點>   (動 grep/DB 前先讀圖譜)
設計 ── spec 進實作前:design-loop(canary 護的對抗審計)到 lumos loop status 收斂;設計寫成計劃節點(Projects/X_計劃)
動工 ── 改動;改 code 前 impact hook 自動注入受影響關聯節點 + 命中事故;新增 INVARIANT 時 guard scaffold → bind → audit
寫回 ── lumos set/append/decision-add 記決策、驗證、合約
自驗 ── lumos lint <節點>        (快、單檔——寫完一個節點馬上跑)
       ── lumos doctor           (全圖健康)
終審 ── lumos testmap affected --diff <base>..HEAD 拿建議測試清單(advisory);lumos pitfalls --diff 分 tier;tier=high → code-loop(canary 護對抗代碼審)→ code-loop pass 記留痕
提交 ── pre-commit 擋 code-without-graph;pre-push 跑 doctor --ci + anchor verify + code-loop 硬擋
```

強制力,由快到硬:

| 層 | 指令 | 範圍 |
|---|---|---|
| **impact** | `lumos impact --file <檔>`(+ PreToolUse hook) | 改 code 前推播受影響關聯節點(直/間接)+ 命中事故;推播不擋 |
| **lint** | `lumos lint <節點>` | 單檔、不掃 repo——預判 pre-push 會不會擋 |
| **doctor** | `lumos doctor [--ci]` | 全圖:orphan、斷連、`verified_by` 同步、**Check T**(合約→test→audit)、**Check R**(可逆性)、frontmatter lint |
| **code-loop** | `lumos code-loop check` | tier=high 分支未過對抗代碼審 → pre-push 單點硬擋 |
| **pre-push** | `doctor --ci` + `anchor verify` + `code-loop check` | push 前三合一硬擋 |

---

## 7. 指令參考

**讀**
```bash
lumos context <節點> [--brief]    # 節點 + 鄰居壓縮索引(合約突顯在頂部)
lumos contracts [<節點>]          # 合約登記簿:★INVARIANT★(含綁定測試)/ ★DEBT★
lumos search <關鍵字> [--path P] [--top N]  # 全文搜尋;預設 BM25F 相關性排序(正主頂位;--legacy 舊字母序,--regex 走舊路)
lumos context <節點> --recommend [--top 8]  # 相關節點推薦(圖分×詞彙融合;dormant 旗標)
lumos links / backlinks <節點>    # 連出 / 連入
lumos map <節點> [--depth N]      # 鄰域樹
lumos decisions [<節點>] [--superseded]   # ADR 決策 / 掃被推翻的
lumos stale [--match S] [--candidate]     # stale 驗證 / 「改 X 時該重驗哪幾篇」(預設樞紐度×日齡風險排序;--legacy 字母序)
lumos recent [N] · lumos stats · lumos export --format mermaid|dot|html
```

**寫**(都寫後自驗)
```bash
lumos new system|issue|project|verification <名稱>   # scaffold 節點(印出怎麼填標籤)
lumos set <節點> <欄位> <值>                          # 純量欄位(status/updated/...)
lumos append <節點> verified_by|plan_refs|related|tags "[[X]]"
lumos decision-add <節點> "<內容>" --decided 日期 [--context ..] [--why ..]
lumos decision-supersede <節點> "<子字串>" --by "..." [--ended 日期]
```

**合約與驗證**
```bash
lumos guard list [--unbound]                         # ★INVARIANT★ 綁定狀態(real/dangling/fake/naked)+ 審計狀態
lumos guard scaffold --node S --invariant "<子字串>" --method M --type pure|behavioral|state --claim "..." [--platform P]
lumos guard bind  <節點> "<子字串>" <方法> [--platform P]   # 把 [test:方法] 寫回 KEY 行(多平台:[test:P:方法])
lumos guard audit <節點> "<子字串>" [--model sonnet] [--date 日期]   # 獨立審計後蓋 [audit:]
lumos guard trace [<節點>]                           # 合約 → 守衛測試 → Verification 證據鏈
lumos guard kill-add <節點> "<子字串>" --recipe '<JSON>'   # 宣告「業務上怎麼弄壞」配方
lumos guard kill <節點> [--platform P]               # 殺傷力驗證:worktree 沙盒真弄壞→綁定測試必翻紅(survived=稻草人)
lumos sync-verified-by [--apply]                     # 補漏寫的 verified_by(doctor Check 3)
```

**對抗審計 loop / 影響 / 完整性**
```bash
lumos pitfalls --diff <base>..HEAD [--no-lint]       # 掃 diff 隱患、分 tier(standard/high);high → 走 code-loop
lumos code-loop check [--json]                        # tier=high 未過對抗代碼審 → rc1(pre-push 單點硬擋)
lumos code-loop pass|skip --note "<理由>"            # pass/skip 都記進 code-loop 留痕(綁 HEAD sha;skip=假陽性逃生閥,繞行也留痕)
lumos canary record caught|missed --loop <id> ...    # design-loop/code-loop 的 canary 醒著紀錄
lumos loop status <id> --need 2 --gate                # 收斂閘(legacy 序列:K-streak∧G1∧G2∧G3)
lumos loop status <id> --gate --panel [--min-seats W] # panel 閘(不吃 --need;輪有效∧存活max≤minor∧capture-recapture殘餘/cluster 帳)
lumos loop status <id> --gate --spec <spec.md> --settle <清單.json>   # 結清模式(opt-in:清單全結清∧G1∧G3;--spec 必填)
lumos loop compress <筆記檔> / lumos loop verify-progress <id>   # [S2] 白名單壓縮 / [S3] 結構帳覆核原語
lumos loop capture-counts --finder ... [--from-pitfalls <range>]  # 異質 finder(LLM+linter+測試)算重疊→capture_counts(--from-pitfalls 自動收割 linter,免手貼)
lumos fold-check <spec>                               # 抓設計「折入漂移」(鏡像段/值漂移/反向遺漏)
lumos refcheck <spec> --repo . [--json]              # spec→repo 指涉的機械核對(missing/行號越界)
lumos impact --file <檔> [--depth N] [--json]        # 反查受影響關聯節點(直/間接)+ 命中事故(pitfall_when)
lumos impact --file <檔> --ranked [--stdin-payload]  # 融合排序+固定席降噪(已接 PreToolUse hook:窗外 top-8/窗內 incidents-only 快速路)
lumos impact --diff <base>..HEAD [--json]            # 受影響功能面 manifest(code-loop 審計鏡頭:合約/事故固定席+top-8,advisory 人判)
lumos cochange rules|check [--json]                  # git 史挖共改規則;pre-commit Gate CC 警告漏改夥伴(advisory)
lumos testmap build [--repo R] [--json]              # 檔案↔測試依賴地圖:三路訊號(naming/content/cochange)挖邊存 .lumos/testmap.json
lumos testmap affected --diff <range> [--json]       # 依 diff 推薦該跑測試+「無已知測試」裸檔+map 陳舊三訊號提醒(advisory 恆 rc0)
lumos anchor verify | approve --note "<理由>"        # 測試/閘檔完整性:驗指紋 / 刻意改後核可基線
lumos ci-wait [--timeout 600] [--json]               # push 後同輪等 GitHub Actions 結論(綠 rc0/紅 rc1+失敗步驟+log 尾段/非成功非失敗=undetermined rc0 要人判);觀測非強制,擋不了 push·merge;需 .lumos/config.json 宣告 ci 區塊才啟用
lumos ci-status [--json]                             # 唯讀查最後一次 CI 結果(不打網路,供離線與 SessionStart hook)
```

**治理與巡檢**
```bash
lumos lint <節點>                # 單檔快檢(標籤/格式/合約/可逆性)
lumos doctor [--ci] [--suggest]  # 全圖健康;--ci = strict + 無色(會擋)
lumos gov [<節點>] [--since N]    # 唯讀治理事件帳:某節點被哪幾道閘攔過、硬擋 vs 軟
lumos spec-trace <計劃節點>       # 計劃條款 [S1].. 認領掃描(未被 Verification 認領→rc1;opt-in)
lumos signoff <節點> --note ".."  # 業務簽核留痕(validation 那半;寫 signoff-log+frontmatter)
```

**安裝 / 生命週期**
```bash
lumos install [--force] · lumos uninstall          # 全域 lumos symlink 到 ~/.local/bin
lumos update [--source PATH] [--no-pull]           # 從 Lumos 唯一源刷新本專案 vendored 工具組
lumos bootstrap [--pull] [--init]                  # 一鍵全套(安裝;--init 免確認建新專案)
lumos teardown [-y]                                # 一鍵拆機(當前 repo + 機器全域,保留圖譜)
lumos archive [--days N] [--apply]                 # 滾動歸檔老的 pass Verification(活守衛受保護)
```

### 卸載

安裝側有 `bootstrap`(一鍵)＋ `install`/`init`(顆粒);卸載側對稱——`teardown`(一鍵)＋ `uninstall`/`deinit`(顆粒)。**分層速記**:整台機器一次拆 → `teardown`;只拆一個 repo → `deinit`;只移全域 CLI → `uninstall`。

**① 一鍵拆機(首選)** — 拆「當前 repo 專案層 ＋ 機器全域(CLI/skills/全域 hooks)」,**永遠保留圖譜文件**:
```bash
lumos teardown           # 全域 hook 清理 → deinit(--keep-graph) → uninstall,一次拆乾淨(互動確認)
lumos teardown -y        # 跳過互動確認(非互動環境用)
```
- **範圍 = 當前 repo ＋ 機器全域**:別的 repo 的裝設、bootstrap 來源 clone **都不動**(要拆別的 repo 到那個 repo 再跑一次)。
- 補了「全域 `~/.claude` hook 殘留」的清理(`uninstall` 單獨跑不清這塊)。
- 確認訊息會列出仍在的破壞性:剝 CLAUDE.md 注入會正規化 sentinel 外的空白/換行(F4)、`uninstall` 會移除**全部 lumos 家族 skills**(含 csharp/kotlin/vue-idioms,不只 `lumos-*`;你自己名字不同的 skill 不碰)。

**② 顆粒操作**(teardown 就是建在這兩個之上):

- **專案層 `deinit`**(只拆這一個 repo,全域＋其他 repo 不動)——用途:多個 repo 用 lumos,只想清掉其中一個:
  ```bash
  lumos deinit              # 完整逆轉 init:拆閘 + 移工具組 + 剝 CLAUDE.md 區塊 + 刪圖譜(互動確認)
  lumos deinit --keep-graph     # 保留圖譜,只拆其餘
  lumos deinit --dry-run        # 只預演,不改動
  lumos deinit -y               # 跳過互動確認(CI/非互動環境用)
  lumos deinit --source <path>  # 指定 Lumos 來源(自我保護比對用)
  ```
  deinit 不自動 commit、不碰機器共用項;standalone vault(圖譜=repo 根)自動保留防誤刪整個 repo。`scripts/hooks`/`scripts/templates` 只刪 lumos 的檔、**你放在裡面的自有檔會保留**(F9 修 2026-07-24)。
- **機器層 `uninstall`**(只移全域 `~/.local/bin/lumos` + user-scope skills,各 repo 裝設不動)。

> 手動完整版(不用 teardown 時):每個專案 `lumos deinit` → `lumos uninstall` → 視需要 `rm -rf ~/harness/lumos-toolchain`。

權威清單以 `lumos --help` 為準。

---

## 8. 治理事件帳(`lumos gov`)

治理訊號以前散在各 hook。`lumos gov` 是**唯讀彙整器**,讀七個本機 JSONL(bypass/rot-queue/governance/canary/kill/signoff/ci):

- `docs/.bypass-log.jsonl` —— L2 pre-commit 繞過(post-commit 寫)
- `docs/.rot-queue.jsonl` —— L3 verification-rot 發現
- `docs/.governance-log.jsonl` —— `doctor --ci` 發現(Check T / Check R),單一寫者

```bash
lumos gov                # 全部 gate 事件的時間軸
lumos gov OrderService   # 這節點被哪幾道閘攔過、硬擋 vs 軟、附日期
```

> 這是**本機開發可見性**工具(三檔皆 gitignore),不是合規物。L2 繞過事件無 node、L3 以 Verification 路徑為鍵,故對 Systems 節點的 per-node 視圖是部分的——輸出會標明。

---

## 9. 更新方式

- **skills + 全域 CLI**(symlink):`git -C ~/harness/lumos-toolchain pull`——即時,免重裝。
- **某專案的 vendored 工具組 + `CLAUDE.md` 紀律區塊**:在該專案跑 `lumos update`(拉 Lumos 源、重 vendor、重注入)。圖譜資料受保護。

---

## 10. 設計原則

- **DRY / YAGNI / TDD**、頻繁提交;CLI 純標準庫、可在 CI 跑。
- **別治理過頭。** 只標載重的;軟的維持軟;不疊沒有對等價值的 ceremony。
- **誠實的天花板。** 工具證的是*形式*(測試存在、回退有寫、乾淨 agent 審過),不是*validation*(規則符不符合今天的業務、回退跑不跑得動)——那留給人。
- **maker ≠ checker。** 沒有標準答案的判斷(這是不是真合約?測試是不是套套邏輯?)交給無脈絡的獨立 agent,不是作者本人。

---

## 邊界與延伸閱讀

Lumos 只放**通用的圖譜工具組**。各專案**自己的東西不進這裡**:業務圖譜內容、app 的發版/部署腳本(如 `release.sh`)、技術棧 skill(vue/csharp 等 project-scope skill)。

- 上手細節:[ONBOARDING.md](ONBOARDING.md)
- 架構全景:[ARCHITECTURE.md](ARCHITECTURE.md)(唯一源→兩種 scope→消費端、生命週期指令、子命令、強制力管線)
- 與 SDD 的差異:[SDD-vs-Lumos.md](SDD-vs-Lumos.md)
