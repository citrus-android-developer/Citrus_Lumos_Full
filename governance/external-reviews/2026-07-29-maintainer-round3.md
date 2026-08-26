# 維護方 round3 簡報：v2 評審之後做了什麼，請你重審

> 給外部評審（Codex gpt-5.6）。你在 2026-07-29 出過 v2 收斂版評審（總分 6.4/10，基準 HEAD `33ea425`）。
> 本文是**維護方自報的 delta**。**不要採信本文任何一句話**——每一條都可在本機 repo 驗證（唯讀），請自行查證後再評。
> 若我自報的與你實查不符，請直接點名「維護方自報不實」，這比客氣更有價值。

## 核對基準

- 你的基準：`33ea425`
- 本次基準：`b75266c`（已 push，CI 綠）
- 期間 commit：21 筆（`git log --oneline 33ea425..b75266c`）

## 我針對你的路線圖做了什麼（自報，待你查證）

### P1-1「升級 oracle 品質——最高投資優先序」：我聲稱**已全數落地**

你列的六條，我對應的實作：

| 你的條目 | 我聲稱的實作 | 自查點 |
|---|---|---|
| `canary record` 印出絕對落盤路徑 | `_jsonl_append_verified()` 印絕對路徑 | `scripts/lumos` 搜 `_jsonl_append_verified` |
| append 後讀回 token；驗不到即非零退出 | 同函式：append→重開檔→逐行找 key→找不到 rc2 | 同上 |
| cwd 漂移、錯 vault、不可寫路徑回歸測試 | `t_canary_record_persist` | `scripts/test_lumos.py` |
| 每批 canary 抽樣交第二判定者覆核 | `lumos canary second` 子命令，且**拒絕同一判者**（分權） | 搜 `cmd_canary_second` |
| guard-kill 輸出實際失敗測試、assertion 與行為歸因 | `_kill_attribute()`：5 行窗口、名稱字串遮罩、鄰接他測名截斷 | 搜 `_kill_attribute` |
| timeout 降為弱證據；「還原舊 bug → 指定測試翻紅」標配 | verdict 由 6 態改 **7 態**：`timed_out_weak` **不再計為 killed**；`killed_unattributed` 另立。還原翻紅釘寫進 code-loop skill 紀律 | 搜 `timed_out_weak`；`skills/lumos-code-loop/SKILL.md` |

過程留痕：`Verification/2026-07-29_oracle品質包落地.md`。
**這一包經過 code-loop 對抗終審**，被打回 6 條（含我自己提的兩條合約候選被獨立審計員以 mutation 反證推翻、重做）。

### 額外做了一件你**沒有**列進路線圖的事：CI 回流閉環 v1

你 v2 說「接下來不應再補更多治理名詞」。我還是加了一個新機制，理由與範圍如下，**請你判這是否違反你的建議**：

- **動機**：你逼出的 CI 信任根落地後，出現一個閉環缺口——CI 在雲端跑，本機 agent 不知道紅了；自動開發到 push 就斷線。
- **實作**：`lumos ci-wait`（push 後同輪輪詢 `gh run list --commit <sha>`，紅則 rc1 並吐失敗步驟＋log 尾段）、`lumos ci-status`（唯讀查帳）、`docs/.ci-log.jsonl` 帳、gov 第 7 源、SessionStart hook 後備網。
- **範圍手術**：原設計含 PR flow / auto-merge / `ship`，因對抗審有一半以上 major 集中在那塊、且使用者拒絕侵入性設定，**砍到 v1 只做 direct flow**。
- **零侵入的定義**：總開關＝專案 `.lumos/config.json` 有沒有 `ci` 區塊。未宣告 → 不等、不提醒、gov 不載、hook 靜默；config 壞損也退全關（fail-safe）。
- 留痕：`Verification/2026-07-29_CI回流閉環v1落地.md`、`Projects/CI回流閉環_計劃`。

**請你直球回答**：這是「又一層治理名詞」，還是「補上你指出的強制面斷點」？

### 你點名的「手寫儀表數字仍不可靠」：我把守衛面推廣了

你抓到 1585／1587／1588 三個版本。當時只有一條 `t_docs_command_count` 守指令數。
今天使用者又抓到三處文件漂移（kill verdict 值域、ARCHITECTURE 管線圖、兩支 skill 的紀律），
根因是「同一事實散在多處、只有一處有機械守衛」。

新增 `t_docs_enumeration_drift`，把「禁止手寫數字／列舉」擴到三類機械可推導事實：
1. 治理帳來源數（文件宣稱 vs `cmd_gov` 實際 `load()` 次數）
2. kill verdict 值域（`cmd_guard_kill` 寫得出的 verdict 是否都列在 `skills/lumos-project-notes/reference.md`）
3. hook 生命週期對稱（`merge-claude-settings.py` 的 `HOOK_ENTRIES` ⟺ `scripts/lumos` 的 `_GLOBAL_CLAUDE_HOOKS` ⟺ 檔案存在）

已做 mutation 驗證（從文件拿掉一個 verdict → 翻紅；還原 → 綠）。**請你判它是否只是稻草人守衛。**

## 我**沒有**做的（誠實列出，請照樣扣分）

- **P1-0 部署最後一哩，四條全未做**：
  - CI 設為 `main` required check（GitHub 網頁設定，使用者本人才能點；已列 backlog ⑥）
  - Actions pin full SHA（現況仍 `actions/checkout@v4`、`actions/setup-python@v5`）
  - `get.sh` pin commit、notesmd checksum（現況 `git clone` 無 pin）
  - `doctor --ci` 納入全庫 decisions schema 檢查（現況守衛仍只在 `cmd_lint`，你的原批評未解）
- **P1-2 砍 capture-recapture 儀式**：未做。第一個有效輪不帶 cluster 時，舊模式 `<1` hard veto 仍在（`skills/lumos-design-loop/SKILL.md`）。
- **P1-3 合約普查／hermetic 測試／Windows 無條件 pass／resolver fail-closed**：全未做。
  - 但註記：toolchain 自身 INVARIANT 由 2 條 → **6 條**（oracle 包蓋章 4 條，均綁真測試且經獨立審計）。這是被動增加，不是普查。
- **認識論修正未落地**：你指出的「架構圖與 code 衝突以架構圖為準」仍原文寫在 `CLAUDE.md:17`、`README.md:31`、`skills/lumos-project-notes/SKILL.md:10`。**我接受你的分層理論但沒改字**，請照扣。
- **P2 結構債**：dry-run 寫權隔離、單檔拆分、砍低使用率命令，全未動。單檔已從 11,479 行漲到 **11,968 行**（新增機制的代價）。

## 我要你回答的四個問題

1. **P1-1 是否真的閉合了「證據帳完整性」風險？** 特別是：`_jsonl_append_verified` 的 readback 真的能擋住當初那個「回報成功、實未落盤」事故嗎？請找它擋不住的殘餘窗口（例如：並發、部分寫入、檔案被外部截斷、key 碰撞）。
2. **guard-kill 歸因是否真的從「知道紅」進到「知道為何紅」？** 請攻擊 `_kill_attribute` 的歸因啟發法：什麼情況下它會歸錯測試、或把 killed 誤降成 unattributed。
3. **第二判定者是否解決了「caught/missed 由植入者自判」？** 它是選配、由同一個編排者發動——這算不算換湯不換藥？
4. **CI 回流閉環 v1 是加分還是減分？** 以及：在 required check 尚未開啟的前提下，`ci-wait` 拉回紅燈讓 agent 當輪修，究竟是把強制面補上了，還是製造了「反正 agent 會修」的道德風險？

## 重新評分請求

請就五面向重新評分（問題定位／架構與代碼品質／治理機制設計／可用性／安全性），並明說：
- 哪一項因為本輪 delta 該升，升多少，證據是什麼；
- 哪一項**不該升**，即使我做了事；
- 你上次說「不再上調超過 6.4」的理由是「證據鏈可能斷在寫入層」——這個理由現在還成立嗎？如果成立，說明為什麼 readback 不夠。

同樣的紀律：不要因為維護方態度誠實就給同情分。
