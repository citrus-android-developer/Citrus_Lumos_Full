# 複審結論

我把總分由 **5.2 調高到 6.4/10**。

Lumos 已不只是「單人治理實驗室」：CI、真實消費端評測、負結果處決、canary 模型分流，以及 code-loop 抓出測試空轉，都提供了先前缺少的實證。但它仍不是完整的組織級治理平台：CI 尚未成為 required check，語意同步仍未閉合，部分治理帳只有自報，autonomous dry-run 仍握有完整寫入權限。

核對範圍：HEAD `3ffec02`、近 20 commits、當前程式與架構圖。我另實跑 SyntaxWarning 閘、`t_docs_command_count`（3/3）、`anchor verify`（5/5）。受唯讀環境限制，未重跑會建立暫存檔的全套測試；CI 紅→綠的 commit 時序可信，但我未取得 GitHub Actions 原始 run log，因此不把「3m15s／1588 全綠」當完全獨立第三方證據。

## 1. 逐條回應簡報 ②③④

### ② 誤讀或漏讀

1. **Capture-recapture：改口一半。**

我漏讀 cluster 帳已將它降成 advisory；這點維護方說得對。skill 明載 cluster 模式只有「輪有效＋無 disputed-major」兩條合取，[skills/lumos-design-loop/SKILL.md:66](/Users/enzo/harness/lumos-toolchain/skills/lumos-design-loop/SKILL.md:66)，程式亦確實只印估值、不拿來擋，[scripts/lumos:2722](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2722)。

但原判沒有完全失效：第一個有效輪若未帶 `clusters`，仍自動定錨舊帳，[scripts/lumos:2638](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2638)，並以殘餘 `<1.0` 作 hard gate，[scripts/lumos:2695](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2695)。所以修訂為：

> Capture-recapture 作為 telemetry 合理；在尚為預設的無-cluster 路徑作 veto，仍屬統計儀式化。

2. **Canary 定位：改口。**

我原先把「降為注意力探針」寫成改進建議，不準確；那本來就是明文定位。架構圖稱它為「注意力下限」，[Systems/canary-audit.md:17](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/canary-audit.md:17)，並清楚否認完整性與閉合驗證，[Systems/canary-audit.md:70](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/canary-audit.md:70)；skill 也明載「抬 spec 質量、非保正確」，[skills/lumos-design-loop/SKILL.md:8](/Users/enzo/harness/lumos-toolchain/skills/lumos-design-loop/SKILL.md:8)。

我撤回「canary 本身有自嗨成分」這個過寬判詞。較準確是：

> Canary 是有實際鑑別力的 reviewer attention/calibration probe；儀式化風險出在把 caught-rate 外推為 correctness 或 coverage。

3. **INVARIANT 密度：縮小批評範圍，但維持本 repo 原判。**

當前實跑結果是 **173 節點、2 條 INVARIANT**。我接受不能由本 meta-vault 外推整個 Lumos 生態「最強鏈幾乎空載」；消費 repo 才是業務合約主戰場。

但對 Lumos 自身仍是有效批評：治理工具的關鍵行為也值得正式合約化，而目前大量機制宣稱仍未進最強鏈。維護方自己也把它列 backlog 首位，[Projects/Codex外審吸收_計劃.md:16](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/Codex外審吸收_計劃.md:16)。

4. **「衝突以架構圖為準」：維持原判，尚未落地。**

維護方理論上已接受，但產品正文仍寫無條件「以架構圖為準」，[README.md:31](/Users/enzo/harness/lumos-toolchain/README.md:31)，吸收計劃也只說待修改，[Projects/Codex外審吸收_計劃.md:21](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/Codex外審吸收_計劃.md:21)。

因此我不先為「已接受」加完成分。應落成：

- 架構圖：規範性意圖權威。
- 執行／測試／production observation：行為事實。
- 衝突：進 incident，不自動宣判架構圖為真。

### ③ 內部實證

1. **Canary 鑑別力：被說服，明確改口。**

Raw log 可直接驗證：

- Sonnet 前兩輪 6 席只有 2 caught、4 missed，[docs/.canary-log.jsonl:228](/Users/enzo/harness/lumos-toolchain/docs/.canary-log.jsonl:228) 至 [docs/.canary-log.jsonl:233](/Users/enzo/harness/lumos-toolchain/docs/.canary-log.jsonl:233)。
- 升 Opus 後連續 12 席全 caught，[docs/.canary-log.jsonl:234](/Users/enzo/harness/lumos-toolchain/docs/.canary-log.jsonl:234) 至 [docs/.canary-log.jsonl:245](/Users/enzo/harness/lumos-toolchain/docs/.canary-log.jsonl:245)。

這已足以反駁「純儀式」：它真淘汰了低可信輪，並產生模型升級訊號。樣本仍小、只是一個 spec family，但證據方向很清楚。

2. **負結果處決文化：被說服，但限定推論。**

PPR 實驗有預註冊 train、兩臂逐權重同分、未碰 held、整包殺除，[Verification/2026-07-28_PPR邊權消融.md:27](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Verification/2026-07-28_PPR邊權消融.md:27)。我撤回任何「Lumos 只加不減」的籠統暗示。

但這證明的是「演算法／功能實驗能被殺」，尚未證明既有治理 scaffolding 也同樣容易退役。三代 loop gate 並存與大型 skills 的治理熵批評仍成立。

3. **Design-loop 天花板：完全接受。**

testmap 實錄確實顯示後期 major 大量來自前輪補丁互打，[Projects/檔案測試依賴地圖_計劃.md:180](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/檔案測試依賴地圖_計劃.md:180)，最後明文承認散文收斂邊際遞減，[同檔:187](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/檔案測試依賴地圖_計劃.md:187)。

這使我更確信：高保真金標、可執行反例與「還原 bug 必翻紅」比繼續磨散文更值得投資。

4. **Code-loop 戰果：結果被說服，11 席 10 中的帳仍有缺口。**

真 bug 與三條空轉測試都有 commit diff 支撐；驗證節點也精確記錄 rstrip 死碼及三種假測試，[Verification/2026-07-28_testmap落地與Landmark轉正.md:46](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Verification/2026-07-28_testmap落地與Landmark轉正.md:46)。

但 raw canary log 只見：

- r1：5/5 caught。
- r3：2 caught、1 missed。

也就是 8 筆；宣稱全中的 r2 三席只存在 Verification 散文與 passed ledger，未見三筆 raw canary record。11/10 數字寫在 [docs/.governance-log.jsonl:7750](/Users/enzo/harness/lumos-toolchain/docs/.governance-log.jsonl:7750)，但底層帳不完整。

所以我接受「code-loop 抓到真 bug／假測試」，暫不把精確的 11/10 當完整可稽核統計。

### ④ 維護方異議

1. **拆單檔優先序：我改口，不再堅持現在立刻拆。**

CI 先行是正確排序。P0 已先做，不存在「拆檔 vs CI」的當前二選一，我不主張現在發動大爆拆。

不過債仍客觀存在：`scripts/lumos` 目前 11,479 行，`run_doctor()` 仍從 [scripts/lumos:440](/Users/enzo/harness/lumos-toolchain/scripts/lumos:440) 起，集中 parser/dispatch 的 `main()` 在 [scripts/lumos:10773](/Users/enzo/harness/lumos-toolchain/scripts/lumos:10773)，lazy imports 仍沉到 [scripts/lumos:9069](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9069)。

我的新建議是設觸發條件，而非立即重構：

- 第二維護者加入；
- 單檔衝突或回歸率持續上升；
- 新功能已無法不跨 parser／doctor／git／graph 多區修改；
- CI 穩定累積足夠基線。

屆時拆 source modules、生成 vendored 單檔，保留零依賴交付形態。

2. **評分重複計價：同意需聯動，但不是只能加一次。**

同一 P0 可以改善多個面向，因為它解決的是不同後果：

- 架構：可重現回歸與警告閘。
- 安全：出現伺服器端執行面。
- 可用性：文件與真實行為開始被機械對帳。

我已聯動調高三項，但沒有把 workflow 的「存在」當三份完整成果：例如 security 沒有 required check，就只能拿部分分。

3. **可移植性：改口。**

拿 Spec Kit 的 35-agent 支援當最低合格線，確實混淆產品邊界與缺陷。README 已明確宣告完整 loop 以 Claude Code 為前提，[README.md:11](/Users/enzo/harness/lumos-toolchain/README.md:11)。我撤回「不支援多 agent＝實作缺陷」。

它仍會影響採用面評分，因為這代表較小的適用市場與較高的 Claude 鎖定成本；但那是產品取捨，不是未兌現承諾。

## 2. 更新評分

| 面向 | 昨日 | 更新 | 主要驅動 |
|---|---:|---:|---|
| 問題定位與方法論 | 7.0 | **7.5** | 負結果處決與實證文化獲證；仍扣「架構圖必勝」尚未修及本 repo 合約低密度 |
| 架構與代碼品質 | 5.0 | **6.0** | CI、SyntaxWarning 閘、decisions lint、命令數守衛；仍扣 god module、非 hermetic 測試與 lint 未進全庫 doctor |
| 治理機制設計 | 6.0 | **7.5** | canary 真有鑑別力、cluster 已 advisory、code-loop 抓真 bug／假測試；仍扣舊 capture gate、自報帳與語意同步未閉合 |
| 可用性與採用門檻 | 4.0 | **5.5** | 文件修整、常駐 context -58%、移植性基準修正；仍有 49 命令、厚重 skills 及文件殘留漂移 |
| 安全性 | 4.0 | **5.5** | CI、mktemp、`--pr` 拒跑；仍缺 required checks、供應鏈驗證及真正 child isolation |
| **總分** | **5.2** | **6.4/10** | 五項等權平均 |

### P0 尚未完全閉合的證據

- Workflow 已存在且涵蓋主要步驟，[.github/workflows/ci.yml:18](/Users/enzo/harness/lumos-toolchain/.github/workflows/ci.yml:18)。但 branch protection 仍在 backlog，[Projects/Codex外審吸收_計劃.md:16](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/Codex外審吸收_計劃.md:16)。沒有 required status check 時，CI 是伺服器端偵測面，還不是 merge 強制力；GitHub 也明定要設 required checks 才會阻止合併。[GitHub protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- `actions/checkout@v4` 與 `setup-python@v5` 仍以可移動 tag 引用，[.github/workflows/ci.yml:14](/Users/enzo/harness/lumos-toolchain/.github/workflows/ci.yml:14)；GitHub 的安全建議是 full SHA pin。[GitHub Actions secure use](https://docs.github.com/en/actions/reference/security/secure-use)
- decisions 結構守衛只在 `cmd_lint()`，[scripts/lumos:2042](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2042)；CI 跑 `doctor --ci`，沒有逐節點呼叫它。因此同型壞 YAML 若繞過手動 `lumos lint`，仍可進 CI。
- autonomous `--pr` 雖被擋，[governance/autonomous-loop.sh:11](/Users/enzo/harness/lumos-toolchain/governance/autonomous-loop.sh:11)，但 dry-run 仍用 `Read,Edit,Bash,Grep,Glob,Agent`＋`acceptEdits` 真跑，[同檔:74](/Users/enzo/harness/lumos-toolchain/governance/autonomous-loop.sh:74)，而 prompt 明說 dry-run 與 PR 過程完全相同，[orchestrator-prompt.md:12](/Users/enzo/harness/lumos-toolchain/governance/autonomous_loop/orchestrator-prompt.md:12)。所以 confused-deputy 的「寫 repo 能力」尚未真正移除，只是自動開 PR 被移除。
- 英文 README 仍寫兩步 onboarding，[README.en.md:68](/Users/enzo/harness/lumos-toolchain/README.en.md:68)；方法論仍宣稱一個 git 歷史中未出現的 `graph-doctor.yml`，[架構圖即合約.md:611](/Users/enzo/harness/lumos-toolchain/docs/methodology/架構圖即合約.md:611)。文件漂移已改善，但未清完。
- 安裝供應鏈仍未 pin clone，[get.sh:24](/Users/enzo/harness/lumos-toolchain/get.sh:24)，notesmd 仍下載後直接解壓執行、無 checksum，[fetch-notesmd.sh:32](/Users/enzo/harness/lumos-toolchain/scripts/fetch-notesmd.sh:32)。

## 3. 下一輪追問

1. 能否提供 CI run#1／run#2 的 URL 或原始 log artifact？
2. `main` 是否已有 branch ruleset／required `CI / test`？若沒有，預定何時設定？
3. code-testmap r2 的三筆 canary raw records 為何缺失？是未記、搬運遺失，還是協議允許只寫 Verification？
4. cluster 帳何時成為預設？無-cluster hard gate 預計保留多久？
5. Canary 是否有第二判定者抽查資料，能估植入者對 caught/missed 的誤判率？
6. 能否提供各消費 repo 的「節點數／INVARIANT／綁 test／有 audit／有 kill」分布，而非單一案例？
7. 為何 autonomous dry-run 仍需 `Edit/Bash/Agent + acceptEdits`？能否在 isolation 前連 dry-run 也改成 scratch-only OS 權限？
8. 是否會把 decisions schema 檢查提升進 `doctor --ci` 全庫掃描？
9. 是否願意把 GitHub Actions pin 到 full SHA，並同時處理 `get.sh`／notesmd checksum？
10. 模組化延後的客觀觸發器會採哪一個：第二維護者、衝突率、缺陷率，還是檔案／函式規模？

## 4. 第一個砍與第一個升級投資

**第一個砍：無-cluster panel 的 capture-recapture hard veto。**

不是刪掉估計器，而是先砍它的否決權：

1. cluster ledger 改預設；
2. capture-recapture 全路徑只作 advisory；
3. 舊帳遷移完後刪掉 `<1.0` hard gate。

testmap 已出現「殘餘 3.75 擋住，但真正出口仍是 cap＋人裁」的實例，[Projects/檔案測試依賴地圖_計劃.md:175](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/檔案測試依賴地圖_計劃.md:175)。它有觀察價值，沒有足夠校準資格當 veto。

**第一個升級投資：可執行反事實驗證，也就是把 guard-kill 升成「準殺」。**

目前任何非零 rc 或 timeout 都算 killed，[scripts/lumos:4089](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4089)，架構圖也已承認可能只是碰巧 crash，[Systems/guard-kill.md:15](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/guard-kill.md:15)。

升級目標應是：

- 必須確認預期測試實際執行；
- 失敗需歸因到指定 assertion／行為，而非任意 crash；
- timeout 降為弱證據，不與精準 assertion failure 同級；
- 已修 bug 必有「還原舊 bug → 指定測試翻紅」釘子；
- 輸出失敗測試 ID、assertion 摘要與 attribution。

這正是本輪最強實證共同指向的方向：PPR 靠考卷殺錯機制，testmap 靠還原 bug 與多案例斷言抓空轉。它比再加一層 reviewer、統計量或收斂術語，更接近真正可信的 oracle。