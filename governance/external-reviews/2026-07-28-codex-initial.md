# 第三方評審結論

Lumos 不是純概念玩具；它確實把 ADR、知識架構圖、git gate、測試綁定與 AI 審計組成了一套能運作的個人工程系統。但它目前更像「高度投入的單人治理實驗室」，還不是可放心交給團隊、宣稱具組織級強制力的成熟平台。

核心問題不是機制太少，而是機制數量與術語膨脹得比獨立可信根、語意驗證、CI 強制及維護能力更快。最危險的失敗模式是：儀表板很綠、儀式都做了，但架構圖與程式仍可能不一致。

| 面向 | 評分 |
|---|---:|
| 問題定位與方法論 | 7/10 |
| 架構與代碼品質 | 5/10 |
| 治理機制設計 | 6/10 |
| 可用性與採用門檻 | 4/10 |
| 安全性 | 4/10 |
| **總分** | **5.2/10** |

審查限制：我以唯讀方式檢查完整 repo，實跑 `lumos doctor --strict` 成功，但完整測試因環境禁止建立暫存目錄，無法獨立重跑到結束。因此測試評價來自靜態檢查、測試 runner 結構與部分命令實跑，不把 repo 自報的全綠直接當第三方證據。

---

## 1. 問題定位與方法論：7/10

### 站得住的部分

問題判斷是對的：AI 大量產碼後，瓶頸從「寫不寫得出來」轉為「意圖、限制與驗證是否仍可追溯」。README 對此描述清楚，而且沒有把 code 本身當成能完整表達設計原因的媒介：[README.md:15](/Users/enzo/harness/lumos-toolchain/README.md:15)。

真正有價值的差異化不是「知識架構圖」或「ADR」本身，而是這個組合：

- 決策、合約、驗證與回退關係進同一張版控圖。
- `★INVARIANT★ → [test:] → [audit:]` 建立從宣稱到可執行證據的鏈：[README.md:127](/Users/enzo/harness/lumos-toolchain/README.md:127)。
- commit/push 時對文件腐壞施加摩擦。
- 把「測試本身可能是稻草人」納入 guard-kill。
- 文件本身對多數機制的天花板相當誠實，例如 rollback 只證明有寫、不是證明跑得動：[README.md:145](/Users/enzo/harness/lumos-toolchain/README.md:145)。

與 ADR 相比，ADR 本質是記錄單一重要決策、理由、取捨與後果的 decision log；Lumos 的 decisions 是 ADR 的超集，額外加入關聯圖、有效條件、驗證證據與機械 gate。[ADR 官方定義](https://adr.github.io/)

所以這不是單純重新發明 ADR。比較準確的說法是：**把既有零件整合成 AI-first、post-change governance pipeline**。repo 自己也承認各零件都已有先例，罕見的是整合方式：[架構圖即合約-對外論述.md:212](/Users/enzo/harness/lumos-toolchain/docs/methodology/架構圖即合約-對外論述.md:212)。這個定位可信。

### 站不住或說太滿的部分

最大的認識論問題是「架構圖與 code 衝突，以架構圖為準」。這適用於規範性意圖，不適用於事實性現況。如果架構圖寫錯、過期或根本沒覆蓋，宣稱它是唯一真相不會讓它變真。比較嚴謹的分層應是：

- 架構圖：意圖與宣告合約的權威來源。
- 可執行系統／測試／production observation：行為事實來源。
- 衝突：進入 incident，而不是自動判架構圖勝出。

現在的 commit gate 也沒有驗證語意同步。它只判斷「有 code 時，是否任意 staged 一個架構圖 `.md`」：[pre-commit:109](/Users/enzo/harness/lumos-toolchain/scripts/hooks/pre-commit:109)。改一行無關節點甚至空泛補記就能過。因此它是 **graph-presence gate**，不是 graph-code consistency gate。README 說 `doctor` 能證明架構圖內部一致，尚可；若解讀成證明架構圖與 code 一致，就過度宣稱了：[README.md:31](/Users/enzo/harness/lumos-toolchain/README.md:31)。

實際跑 `lumos contracts`，172 篇架構圖筆記只有 2 條 `★INVARIANT★`、5 條 debt。這代表合約鏈設計很完整，但目前真正接受此治理的核心合約密度極低。系統的大部分「載重宣稱」仍只是 `KEY:` 散文，不受最強 gate 約束。

與 SDD 的公開比較也需要收斂。root 的比較頁把 SDD 畫成一次性、向前、容易腐壞，後段才承認可互補：[SDD-vs-Lumos.md:9](/Users/enzo/harness/lumos-toolchain/SDD-vs-Lumos.md:9)。但 GitHub Spec Kit 官方方法明確把 spec 定義為持續精煉、雙向接受 production reality 的來源，並非一次性瀑布流程；OpenSpec 也明確主打 iterative、brownfield 與可回頭修改。[Spec Kit 官方方法](https://github.com/github/spec-kit/blob/main/spec-driven.md)、[OpenSpec 官方 README](https://github.com/Fission-AI/openspec)

因此公平的差異是：

- SDD／Spec Kit：較強的 pre-change intent、spec→plan→task→implementation 鏈。
- Lumos：較強的 post-change upkeep、驗證紀錄、條件式有效期與 git-side 腐壞偵測。
- ADR：較輕、易採用、專注決策理由。
- Coverage gate：測量的是實際執行覆蓋，可由 `--fail-under` 在 CI 確定性阻擋；但不證明需求正確。[coverage.py 官方文件](https://coverage.readthedocs.io/en/7.13.4/commands/cmd_reporting.html)
- Lumos：試圖驗語意與意圖，野心更高，但信號遠不如 coverage 確定。

結論：**差異化是真的，但主要是整合與治理生命週期，不是基礎方法論發明。**

---

## 2. 架構與代碼品質：5/10

### 優點

零 runtime dependency 對 vendored CLI、離線環境與消費 repo 很有價值。核心模型簡單，`Note`、`Env`、wikilink resolver 讓工具可以不靠 Obsidian：[scripts/lumos:181](/Users/enzo/harness/lumos-toolchain/scripts/lumos:181)。

不少錯誤案例有明顯的事故驅動硬化痕跡：

- 中文路徑與 `core.quotePath`。
- `-k` 選中零案例會紅，不會假綠：[test_lumos.py:11321](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:11321)。
- repo 路徑防 traversal／絕對路徑：[scripts/lumos:7501](/Users/enzo/harness/lumos-toolchain/scripts/lumos:7501)。
- pre-push 先消耗 stdin，再跑 subprocess，處理了真實 git hook 陷阱：[pre-push:20](/Users/enzo/harness/lumos-toolchain/scripts/hooks/pre-push:20)。

這不是隨便拼的 shellware；作者確實有持續打磨邊界。

### 單檔 11k 行已超過合理取捨

`scripts/lumos` 11,453 行、約 252 個函式／類別；`main()` 從 10,747 行開始集中建立所有 argparse 與 dispatch：[scripts/lumos:10747](/Users/enzo/harness/lumos-toolchain/scripts/lumos:10747)。`run_doctor()` 本身約 700 行：[scripts/lumos:440](/Users/enzo/harness/lumos-toolchain/scripts/lumos:440)。

早期單檔便於 vendor 是合理的；到 49 個頂層命令後，單檔已成為 god module：

- 每個功能都碰全域 parser／dispatcher。
- 命令、資料模型、IO、git、圖演算法、安裝器、治理統計與安全邏輯共存。
- 版本仍是人工維護的 `v1.0` 字串：[scripts/lumos:39](/Users/enzo/harness/lumos-toolchain/scripts/lumos:39)。
- `json`、`subprocess` 等 import 到檔案九千行後才出現，顯示功能是在單檔中持續沉積，而非維持清楚分層。

零依賴不等於零模組。完全可以保留 stdlib-only，同時拆成 `lumos_core/graph.py`、`doctor.py`、`git.py`、`governance.py`、`cli.py`，最後仍打包成單檔發佈。

### parser 與錯誤處理

自製 frontmatter parser 只支援刻意縮小的 YAML 子集：[scripts/lumos:106](/Users/enzo/harness/lumos-toolchain/scripts/lumos:106)。這可以接受，但它現在已承載 decisions、巢狀欄位與治理合約，超出「極簡 scalar/list parser」的安全舒適區。

實際架構圖已有它漏掉的格式錯誤：`heterogeneous-finder-ensemble.md` 的 `id: d1` 被縮排進 `content: |-` block，而不是 decision sibling：[heterogeneous-finder-ensemble.md:27](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/heterogeneous-finder-ensemble.md:27)。`doctor --strict` 仍回報零 issue。這正是「綠燈不代表 schema 真正有效」的實例。

resolver 在同名筆記時警告後直接取第一個：[scripts/lumos:287](/Users/enzo/harness/lumos-toolchain/scripts/lumos:287)。對查詢工具或許可接受，對「架構圖即合約」則不夠嚴；載重操作應 fail-closed。

大量 broad exception/fail-open 也讓治理訊號容易靜默消失。例如 vault 讀取直接捕捉所有 `Exception`：[scripts/lumos:193](/Users/enzo/harness/lumos-toolchain/scripts/lumos:193)。pre-push 的 pitfalls 失敗也被 `|| true` 吞掉：[pre-push:98](/Users/enzo/harness/lumos-toolchain/scripts/hooks/pre-push:98)。

目前 Python 3.14 每次啟動還會在約 9517、9584、9632 行輸出 invalid escape `SyntaxWarning`。對一個治理 CLI 而言，工具自己在正常命令輸出警告，是基本衛生問題。

### 「1500+ 檢查」的真實品質

靜態計數約有：

- 277 個 `t_*` 測試函式。
- 約 1,546 次自製 `check()` 呼叫。
- 11,342 行測試碼。

這是實質測試投入，不是灌水到可以完全否定。許多是 subprocess E2E，能抓 CLI exit code、檔案與 git 行為。

但「1500+ checks」不是 1500 個獨立測試，更不是 coverage：

- 自製 runner 只累積全域 PASS/FAIL：[test_lumos.py:11316](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:11316)。
- 沒有 line/branch coverage、mutation score、property tests 或正式測試報告格式。
- 部分測試直接操作真實 `~/.claude/skills` 與 `~/.local/bin`：[test_lumos.py:226](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:226)。這是不 hermetic，甚至可能改寫開發者環境。
- Windows 分支存在無條件 `check(..., True)` 的「留手動驗」：[test_lumos.py:227](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:227)。
- repo 沒有 `.github/workflows`；所以這些測試目前不是受保護分支上的可重現 gate。

結論：**測試量很大、回歸意識很強，但度量與隔離程度低於成熟工具鏈。**

---

## 3. 治理機制設計：6/10

### Canary：概念 7/10，落地可信度 5/10

Canary 是合理的 test-the-tester：能排除「審計員根本沒讀，只吐泛泛回應」。文件對適用邊界寫得很好，明白說只證明審計員抓到那一類、那一段，且判定者仍是植入者本人：[canary-audit.md:70](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/canary-audit.md:70)。

問題是 helper 只記錄自報結果，不注入、不判定、不阻擋：[canary-audit.md:78](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/canary-audit.md:78)。當流程進一步加入：

- 載重錨定
- haiku 難度探針
- 事故反轉
- 多席 panel
- 辯方
- 跨家族否決
- fold-check
- capture-recapture

它很容易從「注意力探針」變成讓操作者誤以為已建立統計可信度的儀式。這部分已有自嗨成分。

### Anchor：方向合理，但不是信任根

anchor 只保護兩個 runner 與三個 git hooks：[scripts/lumos:7392](/Users/enzo/harness/lumos-toolchain/scripts/lumos:7392)。它不保護：

- `scripts/lumos` 本身
- Claude hooks
- settings merger
- autonomous loop
- baseline 自己

baseline 缺失還會 rc 0：[scripts/lumos:7417](/Users/enzo/harness/lumos-toolchain/scripts/lumos:7417)。而 approve 在同一 repo、由同一工具重算 hash：[scripts/lumos:7457](/Users/enzo/harness/lumos-toolchain/scripts/lumos:7457)。它能防意外修改與無痕漂移，不能抵抗有意污染者。文件自己也承認 same-repo guard paradox：[anchor-integrity.md:13](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/anchor-integrity.md:13)。

所以 anchor 應稱為 **change detector**，不該暗示是 integrity trust anchor。

### Guard-kill：有工程價值，但訊號偏寬

guard-kill 在隔離 worktree 故意破壞行為，再驗證綁定測試是否翻紅，這比「測試函式存在」強很多：[guard-kill.md:27](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/guard-kill.md:27)。

但 timeout 和任何非零退出都可能算 killed；可能只是 compile error、fixture crash 或環境失敗，不代表斷言真的守到業務合約。文件已誠實承認「殺得掉不等於殺得準」：[guard-kill.md:15](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/guard-kill.md:15)。在加入 assertion attribution 前，它應是強 advisory evidence，不宜成為唯一合約證據。

### Capture-recapture：過度工程最明顯的一塊

把 Chao1／capture-recapture 用在 reviewer findings，前提很差：

- reviewer 並不獨立，同模型家族高度相關。
- 每輪修 spec/code 後，待捕捉缺陷母體已改變，不是 closed population。
- findings 正規化與同一缺陷判定仍是人工。
- 樣本很小，估計值會極端。

文件也承認小樣本只應當信號：[heterogeneous-finder-ensemble.md:70](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/heterogeneous-finder-ensemble.md:70)。既然如此，就不該把「殘餘 < 1」包裝成精確收斂判準。它比「連續兩輪無 major」看似科學，但未必更真。

**直說：capture-recapture 作為 dashboard 指標有趣；作為 gate，是統計儀式化。**

---

## 4. 可用性與採用門檻：4/10

### 做得好的地方

README、架構圖、命令分類與誠實天花板普遍寫得清楚。Unix、Windows、vendoring、install/update/uninstall/deinit 的生命週期都被考慮到：[ARCHITECTURE.md:9](/Users/enzo/harness/lumos-toolchain/ARCHITECTURE.md:9)。

CLI stdlib-only、架構圖是 Markdown、git hooks 不依賴雲端，這些都是可移植的好基礎。

### 真實上手成本遠高於文件估計

方法論文件估算新人約一小時上手：[架構圖即合約.md:403](/Users/enzo/harness/lumos-toolchain/docs/methodology/架構圖即合約.md:403)。我認為不可信。一小時頂多會跑命令，不可能理解：

- frontmatter 四條鐵則
- Systems／Projects／Verification／Issues 分工
- invariant/test/audit
- valid_under/revalidate_when
- canary、辯方、panel、fold、refcheck
- light/standard/high tier
- capture counts、cluster、golden replay
- guard kill、anchor approve
- 哪些是硬 gate、哪些只是 honor system

design-loop 與 code-loop skill 本身已接近操作手冊而不是輕量 skill；code-loop 一輪七步、panel 又有 W=3/5、跨家族 finder/否決席及 capture-recapture：[lumos-code-loop/SKILL.md:12](/Users/enzo/harness/lumos-toolchain/skills/lumos-code-loop/SKILL.md:12)。

這對作者本人可能是外部記憶；對團隊是巨大認知稅。

### 文件與實作已有可見漂移

- README 說全新專案一條 `get.sh` 完成：[README.md:69](/Users/enzo/harness/lumos-toolchain/README.md:69)。
- ONBOARDING 還說要 `get.sh` 再 `lumos init` 兩步：[ONBOARDING.md:23](/Users/enzo/harness/lumos-toolchain/ONBOARDING.md:23)。
- README 說 49 個頂層命令：[README.md:42](/Users/enzo/harness/lumos-toolchain/README.md:42)；ARCHITECTURE 還列 44 個。
- README 說不需要 Obsidian：[README.md:25](/Users/enzo/harness/lumos-toolchain/README.md:25)，但 verification-rot 的候選查找直接呼叫 `obsidian`，不可用就整段返回空結果：[verification-rot-check.py:123](/Users/enzo/harness/lumos-toolchain/scripts/hooks/claude/verification-rot-check.py:123)。
- Claude Stop hook 只認 Obsidian mutate command，不認規範建議的 `lumos set/append` 寫入：[check-graph-sync.py:189](/Users/enzo/harness/lumos-toolchain/scripts/hooks/claude/check-graph-sync.py:189)。

一個主張「防漂移」的工具，自身權威文件與機制已有這種漂移，會嚴重傷害採用信任。

### 非 Claude 可移植性不足

README 自己承認完整治理假設 Claude Code：[README.md:11](/Users/enzo/harness/lumos-toolchain/README.md:11)。skills 進 `~/.claude/skills`，hooks 進 Claude settings，reviewer hardcode Agent、Sonnet、Opus、Codex、Qwen。

CLI 與 git hooks 可移植；**完整 Lumos 方法論不可移植**。

這方面業界基準已拉開：Spec Kit 官方宣稱支援 35 種 agent integration；OpenSpec 也主打跨 25+／30+ AI 工具。[Spec Kit 官方文件](https://github.github.com/spec-kit/index.html)、[OpenSpec 官方 README](https://github.com/Fission-AI/openspec)

---

## 5. 安全性：4/10

這不是網路服務，攻擊面比 daemon／web platform 小；零依賴也降低一般 Python supply-chain 面積。repo 內還有一些不錯的路徑 containment 和 destructive-operation guard。

但治理工具本身是高權限供應鏈元件，目前幾個問題不可忽視。

### 供應鏈沒有內容驗證

官方安裝方式是對 `main/get.sh` 執行 curl pipe bash：[README.md:73](/Users/enzo/harness/lumos-toolchain/README.md:73)。`get.sh` 再 clone 未 pin commit 的 repo：[get.sh:21](/Users/enzo/harness/lumos-toolchain/get.sh:21)。

`fetch-notesmd.sh` 雖 pin 版本，但下載 tarball 後直接解壓執行，沒有 SHA-256 或簽章驗證：[fetch-notesmd.sh:32](/Users/enzo/harness/lumos-toolchain/scripts/fetch-notesmd.sh:32)。

對一個會安裝全域 skills、Claude hooks、git hooks、CLI 的工具，這是不及格的 trust bootstrap。

### Autonomous loop 已知 confused-deputy 漏洞尚未修

autonomous loop 給 orchestrator：

```text
Read, Edit, Bash, Grep, Glob, Agent
```

並使用 `acceptEdits`：[autonomous-loop.sh:63](/Users/enzo/harness/lumos-toolchain/governance/autonomous-loop.sh:63)。

架構圖自己記載子 agent 繼承全權、可能受 poisoned spec 誘導去 Edit/Bash/開 PR，而且狀態仍是 planned：[nested-agent-permission-scope.md:46](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/nested-agent-permission-scope.md:46)。這代表系統已經知道漏洞，但仍保留可執行入口。安全上應直接停用非 dry-run 模式，直到 read-only child isolation 落地。

### 本機 hooks 不是組織級安全控制

pre-push 多處 fail-open：

- 缺 Python／lumos 放行：[pre-push:29](/Users/enzo/harness/lumos-toolchain/scripts/hooks/pre-push:29)。
- pitfalls 出錯吞掉。
- code-loop 異常 rc 不阻擋。
- `git push --no-verify` 全部繞過。

更關鍵的是 repo 沒有 `.github/workflows`，但 hook 訊息多次聲稱「CI 仍會抓」：[pre-push:7](/Users/enzo/harness/lumos-toolchain/scripts/hooks/pre-push:7)。現在沒有那個後盾。

成熟組織控制應把檢查放進伺服器端 required status checks；GitHub 的 protected branch 能要求狀態檢查成功後才允許 merge。[GitHub protected branches 官方文件](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)

### 其他問題

- 測試輸出使用固定 `/tmp/lumos-prepush-tests.log`，有 collision／symlink／資訊殘留風險：[pre-push:52](/Users/enzo/harness/lumos-toolchain/scripts/hooks/pre-push:52)。
- autonomous loop 使用可預測 `/tmp/auto-loop-日期`，不是 `mktemp -d`。
- 治理／bypass logs 全是 gitignored 本機資料，能被刪除，也不適合作稽核證據：[README.md:289](/Users/enzo/harness/lumos-toolchain/README.md:289)。

---

## 最大的三個風險／弱點

### 1. 假確信：presence 與算術被誤當成語意正確

一篇任意 graph `.md` 就能通過 code-with-graph gate；canary、capture counts、anchor hash、test name existence 也主要驗「形式存在」。機制越多，越容易讓人錯把形式合規當成需求正確。

這是產品最大的風險，比單一 bug 嚴重。

### 2. 治理熵超過維護能力

11k CLI、11k tests、49 commands、多代 loop gate、skills/reference/golden/graph/methodology 多份真相同時存在。已出現：

- 44/49 命令漂移。
- 一步／兩步 onboarding 漂移。
- Obsidian optional 宣稱與實作矛盾。
- 架構圖 malformed YAML 未被 doctor 抓。
- 7 個 Systems self-audit stale，而 `doctor --strict` 仍綠。

「架構圖防腐」目前沒有成功防止 Lumos 自身腐壞。

### 3. 強制力停留在本機與同一信任域

hooks 可跳、logs 可刪、anchor 可由同 repo 重簽、autonomous agents 有完整權限、沒有 CI workflow／required check。對單人 dogfood 是摩擦；對團隊治理或安全宣稱不夠。

---

## 最值得做的三件改進

### P0：建立真正獨立的 CI 信任根

具體做法：

1. 新增 GitHub Actions，至少跑：
   - `python -m compileall`
   - 完整 test suite
   - `lumos doctor --ci`
   - anchor verify，且 baseline 缺失必紅
   - frontmatter schema validator
2. 把 checks 設為 branch protection required checks。
3. CI 由 checkout SHA 自算 runner/hook hash，輸出 attestation；不要信工作樹內自報。
4. 不再於本機 hook 聲稱不存在的「CI 仍會抓」。
5. autonomous non-dry-run 在 read-only child sandbox 完成前直接禁用。

這一項會把 Lumos 從「個人紀律」提升成真正工程控制。

### P1：先停止加命令，拆 CLI 與測試基礎

保持零依賴，但拆成 stdlib modules：

- `graph_model`
- `frontmatter_schema`
- `doctor_checks`
- `git_gates`
- `contract_guard`
- `review_evidence`
- `install`
- `cli`

再由 build script 產單檔 vendored artifact。source 可維護，consumer 仍拿單檔。

同步完成：

- 所有 tests 使用 temporary HOME／XDG 目錄。
- 禁止無條件 pass。
- 加 line/branch coverage gate。
- 對 parser、resolver、gate predicates 加 property/fuzz tests。
- Python 3.14 warnings 歸零。
- doctor 對 malformed decisions、未知巢狀欄位與同名載重節點 fail-closed。

### P2：砍掉統計儀式，收斂成少數可信原語

建議治理核心只保留五件：

1. 架構圖 schema／引用一致性。
2. code↔受影響節點的可解釋 mapping。
3. invariant↔test↔independent audit。
4. 真實 test/mutation/guard-kill 執行證據。
5. CI required gate。

調整：

- Canary 保留為 reviewer attention probe，不當正確性證明。
- Capture-recapture 降為實驗性 dashboard，不進 hard gate。
- light/standard/high 收斂成兩檔。
- maker/checker 權限隔離由 harness 機械實作，不靠 prompt 自律。
- 自動產生 README/ARCHITECTURE command table，禁止手寫數字。
- 每個「硬 gate」都必須列出 fail-open 條件、server-side 對應與可測 bypass。

---

## 總評

Lumos 最強的地方是：作者真的理解 AI 開發治理的核心矛盾，也願意把機制天花板寫出來；guard-kill、驗證紀錄、條件式有效期與 commit-side upkeep 都有實際價值。

最弱的地方則是：**它正在用更多治理機制解決治理機制自己產生的複雜度。** Canary 用來驗 reviewer、anchor 用來驗 verifier、capture-recapture 用來驗 panel、fold-check 用來驗折入、架構圖再記錄這些驗證；每加一層，都再產生一份需要被驗的真相。這已開始呈現自我指涉的治理螺旋。

目前定位應誠實寫成：

> 一套對 AI-heavy、長生命週期專案很有啟發性，且已充分 dogfood 的「個人／小團隊治理實驗工具組」；核心原語有產品價值，但尚未證明能作為團隊級、跨 agent、具獨立信任根的治理平台。

**總分：5.2/10。**  
若補上獨立 CI、語意 co-change、模組化與權限隔離，並砍掉約三分之一儀式型機制，可合理升到 7–8 分；如果繼續增加 loop、評分器與治理術語，卻不處理信任根和自身漂移，會變成一套精緻但不可採用的自我治理藝術品。