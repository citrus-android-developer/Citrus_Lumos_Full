# 收斂版外部評審 v2

## 定位一句話

Lumos 已經越過「單人概念實驗」門檻，成為一套有真實 CI、消費端合約與對抗審實績的 AI-heavy 個人／小團隊治理工具鏈；但它尚未越過「可當組織級強制控制與稽核系統」的門檻。

## 更新評分

| 面向 | 初審 | 今日 | 變動主因 |
|---|---:|---:|---|
| 問題定位與方法論 | 7.0 | **7.5** | 負結果處決、真實消費端考卷與對抗審戰果獲證；仍扣「架構圖必勝」認識論未落地修正 |
| 架構與代碼品質 | 5.0 | **6.0** | CI、SyntaxWarning 閘、schema lint、文件漂移守衛已落地；仍有 11.5k 行 god module、非 hermetic 測試與 doctor 覆蓋缺口 |
| 治理機制設計 | 6.0 | **7.5** | canary 鑑別力與 code-loop 真戰果成立；仍扣自判帳、未落盤事故、舊 capture-recapture veto |
| 可用性與採用門檻 | 4.0 | **5.5** | 文件與常駐上下文已明顯改善；仍有 49 命令、厚重操作規約與 Claude 鎖定成本 |
| 安全性 | 4.0 | **5.5** | 有伺服器端 CI、非 dry-run autonomous loop 已停用；仍缺 required check、供應鏈 pin 與 dry-run 寫權隔離 |
| **總分** | **5.2** | **6.4/10** | 五項等權平均 |

我不再上調超過 6.4：新增 CI 是重大進步，但 canary 記錄「回報成功、實未落盤」證明最核心的證據鏈仍可能斷在寫入層。事故處置誠實，卻不能抵銷控制尚未硬化的事實。

核對基準為本地 HEAD `33ea425`，以及三筆公開 CI。最新事故 commit 已讀 diff，但本稿不臆測未提供的 HEAD CI 狀態。

## 逐面向精評

### 1. 問題定位與方法論：7.5/10

**我被說服的部分：**

Lumos 不是只加機制、不殺機制。PPR／共改邊權經預註冊考卷得出負結果後整包刪除，足以證明它有真正的 falsification 文化。testmap 最終也不是靠散文 loop 宣稱成功，而是靠金標考卷、測試矩陣與「還原 bug 必翻紅」轉正。這比任何自報成熟度都更有說服力。

合約密度批評也必須收窄。本輪維護方實跑結果為：

- LandmarkMember：21 條 INVARIANT、4 條 DEBT，INVARIANT 均綁真測試。
- Citrus_KDS：2＋1。
- mOrangePos：4＋19。
- lumos-toolchain 自身：2 條 INVARIANT。

所以「整個生態最強鏈幾乎空載」不成立；較準確的結論是：**Landmark 已實質使用合約鏈，toolchain 自身與兩個 Android 消費庫仍屬低密度或債務偏高。**

**我維持異議的部分：**

「架構圖與 code 衝突，以架構圖為準」仍寫在 [CLAUDE.md](/Users/enzo/harness/lumos-toolchain/CLAUDE.md:17) 與 [README.md](/Users/enzo/harness/lumos-toolchain/README.md:31)。維護方已接受理論修正，但尚未落地，因此不能計完成分。

正確分層仍應是：

- 架構圖是規範性意圖與宣告合約的權威。
- 測試、執行系統與 production observation 是行為事實。
- 兩者衝突時立 incident，不自動宣判架構圖為真。

### 2. 架構與代碼品質：6.0/10

CI 不是紙上 P0。公開紀錄顯示：

- [run#1](https://github.com/EnzoHsieh-Android/Lumos/actions/runs/30414260226) 的完整測試步驟失敗，確實暴露硬編維護者路徑。
- [run#2](https://github.com/EnzoHsieh-Android/Lumos/actions/runs/30414838455) 與 [run#3](https://github.com/EnzoHsieh-Android/Lumos/actions/runs/30415560700) 的 compile、SyntaxWarning、測試、doctor、anchor 全數成功。

這證明 CI 已是活的異機執行面，不是裝飾 workflow。

但精確數字需要訂正：成功 run 的原始 log 是 **1587 passed**，不是答辯所稱 1588；[workflow](/Users/enzo/harness/lumos-toolchain/.github/workflows/ci.yml:22) 的步驟標題仍寫 1585。這只是小型敘述漂移，不推翻 CI 價值，但正好說明手寫儀表數字仍不可靠。

**我改口：**不再主張現在立刻拆單檔。CI 先行的排序正確；以「第二維護者加入／月度回歸率上升／單 PR 經常橫跨 parser、doctor、git、graph 四區」作拆分觸發條件，比先做大爆拆合理。

**我維持異議：**技術債客觀存在。`scripts/lumos` 現為 11,479 行，測試檔 11,395 行。decisions 結構守衛目前落在 `cmd_lint()`，[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2068)，尚未進 `doctor --ci` 全庫掃描；同型錯誤仍可能繞過單檔 lint。

### 3. 治理機制設計：7.5/10

**Canary：撤回「本身是自嗨」的過寬判詞。**

raw log 具有真實鑑別力：

- Sonnet 前兩輪六席只有兩席 caught、四席 missed：[canary log](/Users/enzo/harness/lumos-toolchain/docs/.canary-log.jsonl:228)。
- 升 Opus 後連續十二席 caught：[canary log](/Users/enzo/harness/lumos-toolchain/docs/.canary-log.jsonl:234)。

它確實淘汰低可信審查輪並驅動模型升級。Canary 應保留為 reviewer attention/calibration probe。

**但 Q3 抓到的是本次對話最重要的真事故。**

code-testmap 帳中只有八筆原生紀錄：r1 五筆、r3 三筆，其中七 caught、一 missed，[canary log](/Users/enzo/harness/lumos-toolchain/docs/.canary-log.jsonl:246)。r2 三筆是在翌日人工補登，[canary log](/Users/enzo/harness/lumos-toolchain/docs/.canary-log.jsonl:254)。

因此正確敘述只能是：

> 11 席合計 10 caught，但證據品質為「8 筆原生＋3 筆事後補記」，不是 11 筆同級原生稽核紀錄。

維護方沒有掩飾：已立 [事故節點](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Issues/canary-record未落盤事件.md:15)，補記也明標來源，這值得肯定。但事故仍是 open；絕對落盤路徑、append 後 readback、自驗失敗 rc 非零都尚未實作。在硬化完成前，canary 帳只能稱「本機治理證據」，不能稱可靠稽核帳。

此外，caught/missed 仍由植入者判定，沒有系統性第二判定者資料。這部分原批評完全成立。

**Capture-recapture：維持異議，維護方已接受。**

cluster 模式已把它降成 advisory，但第一個有效輪不帶 cluster 時，舊模式仍把殘餘 `<1` 當 hard veto，[design-loop skill](/Users/enzo/harness/lumos-toolchain/skills/lumos-design-loop/SKILL.md:66)。在非封閉缺陷母體、小樣本、相關 reviewer 下，它沒有否決資格。

第一刀仍應是：cluster 預設化 → capture-recapture 全路徑 advisory → 遷移後刪除 `<1` veto。

**Guard-kill：方向正確，oracle 還不夠準。**

現況已誠實承認「殺得掉不等於殺得準」：[guard-kill](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/guard-kill.md:15)。任何非零退出或 timeout 仍可能被計為 killed。下一階段不該再加 reviewer 層，而應做 assertion attribution、timeout 降級及還原 bug 翻紅釘。

### 4. 可用性與採用門檻：5.5/10

文件漂移批次修正、命令數守衛、常駐上下文縮減，都是真改善。

我也撤回「未支援 35 種 agent 就是缺陷」的比較。完整 loop 以 Claude Code 為產品邊界，是合法選擇，不是未兌現承諾。

但它仍影響採用成本：

- 49 個頂層命令。
- 多層 loop、panel、辯方、canary、cluster 與 ledger 術語。
- 完整治理依賴 Claude Code 執行模型。
- 本輪仍出現 1585／1587／1588 三個測試數字版本。

因此它適合願意付治理成本的長生命週期專案，不是輕量即插即用工具。

### 5. 安全性：5.5/10

非 dry-run autonomous loop 已在入口硬拒絕，[autonomous-loop.sh](/Users/enzo/harness/lumos-toolchain/governance/autonomous-loop.sh:11)，這是正確處置。

但 dry-run 仍以 `Edit,Bash,Agent + acceptEdits` 在 repo 根執行，[autonomous-loop.sh](/Users/enzo/harness/lumos-toolchain/governance/autonomous-loop.sh:74)。它雖不開 PR，仍保有 confused-deputy 所需的寫入能力；scratch-only OS 級限制尚未完成。

CI 也尚未設為 branch required check。沒有 required status check，workflow 能偵測失敗，卻不保證失敗提交不能合併；這是 GitHub 明確區分的控制面。[GitHub protected branches 文件](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)

Actions 仍用可移動 tag，`get.sh` clone 與 notesmd 下載也尚未完成 commit/checksum pin。故安全分只能到 5.5。

## 更新後風險序

1. **Oracle 與證據帳完整性。**  
   目前最大的風險已不是單純「形式存在」，而是工具能回報成功卻未留下證據、caught 判定無第二人、guard-kill 只知紅而不知為何紅。

2. **強制面尚未閉合。**  
   CI 已存在，但 branch required check、供應鏈 pin、dry-run 寫權隔離未完成。

3. **治理熵與合約載重不均。**  
   Landmark 已證明模型可工作，但 toolchain 與 Android 消費庫尚未同等載重；舊 capture gate、多代機制與單檔規模仍提高維護成本。

## 重排後路線圖

P0 的工程實作面已清：CI、警告閘、壞節點守衛、主要文件修正及 autonomous 非 dry-run 停用均已落地。接下來不應再補更多治理名詞。

### P1-0：完成部署面的最後一哩

- 將 CI 設為 `main` required check。
- Actions pin full SHA。
- `get.sh` pin commit；notesmd 加 checksum。
- `doctor --ci` 納入全庫 decisions schema 檢查。

### P1-1：升級 oracle 品質——最高投資優先序

- `canary record` 印出絕對落盤路徑。
- append 後讀回 token；驗不到即非零退出。
- 增加 cwd 漂移、錯 vault、不可寫路徑回歸測試。
- 每批 canary 抽樣交第二判定者覆核。
- guard-kill 輸出實際失敗測試、assertion 與行為歸因。
- timeout 降為弱證據；修 bug 標配「還原舊 bug → 指定測試翻紅」。

### P1-2：砍掉第一個統計儀式

- cluster ledger 設為預設。
- capture-recapture 全路徑只保留 telemetry。
- 遷移舊帳後刪除 `<1.0` hard veto。

### P1-3：合約普查與測試可信度

- 普查 toolchain、Citrus_KDS、mOrangePos，不從 code 反推假合約。
- 測試全面使用 temporary HOME／XDG。
- 清除 Windows 無條件 pass。
- 載重 resolver 遇同名節點 fail-closed。

### P2：在觸發條件命中時處理結構債

- dry-run 改 scratch-only 寫權，審計子 agent 唯讀。
- 依既定三項觸發器啟動 source module 拆分，仍可生成單檔 vendored artifact。
- 刪除低使用率命令與重複 loop 路徑，而不是只做文件壓縮。

## 給潛在採用者的誠實建議

若你是 AI-heavy、長生命週期、單人或小團隊專案，且願意維護合約與驗證紀錄，Lumos 已值得試用；優先採用架構圖、INVARIANT→test→audit、CI 與反事實測試這幾個核心，不要第一天全開所有 loop。

若你需要的是受監管稽核、多人組織強制或惡意行為者下的安全控制，現在還不該把 Lumos 當合規平台。至少先自行補上 required checks、不可竄改外部紀錄、供應鏈 pin、權限隔離與本專案的合約密度基線。

**最終評分：6.4/10。** 它已是有實證價值的工程工具鏈；下一個成長點不在增加治理層，而在讓每一盞綠燈都能回答兩個問題：證據真的落盤了嗎？紅燈真的是那條規則咬住的嗎？