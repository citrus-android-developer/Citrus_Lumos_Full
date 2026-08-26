我會依 repo 的架構圖與合約規矩做唯讀稽核：先重建 v2 的評分基線，再逐條拆解 round3 自報，最後以程式碼、測試、歷史與 CI 證據交叉驗證；不把「誠實揭露未做」計為成果。
基線已重建：v2 的 6.4 上限不是因為缺少功能，而是「證據寫入可假成功、oracle 只知紅不知因、強制面未閉合」。接下來我會先依架構圖入口查本輪新增合約，再拿 code 與 git 歷史反證；目前工作樹已有兩個 log 修改與 round3 未追蹤檔，我不會碰它們。
已找到第一個實質落差：`ci-wait` 的紅燈資料確實在 JSON payload 裡，但一般文字模式只印狀態／workflow／URL，沒有印自報與 skill 所稱的「失敗步驟＋log 尾段」。這不是措辭瑕疵，而是主使用路徑與文件合約不一致；我會在最終報告標成「維護方自報不實」。
CI 的 remote-tracking ref 確實指向 `b75266c`，本機 `.ci-log.jsonl` 也記了 run `30439628699` success；但該帳正是受評系統自己寫的，不算獨立信任根。我正在嘗試以 GitHub 端資料另驗，若連線不可用，最終會明確把「已 push」與「CI 綠」分成不同證據等級。
第二批反證更嚴重：新漂移守衛沒有守住它宣稱的「對稱」，而架構圖本身仍同時寫著舊六態、`timed_out` 算 killed、49 個命令，以及 CI 的 PR/tier/ship 測試矩陣；現碼則是七態、51 命令、direct-only。這正好擊中 Lumos 自己的核心承諾：不是文件小瑕疵，而是「架構圖是唯一真相」卻讓真相分裂。
查證已完成到可下結論：這輪確有實質修補，但維護方把「局部防線」多次寫成「閉環已成立」。我正把每條自報分成已證實、部分屬實與「自報不實」，並將程式、測試、架構圖與實際 CI 的互相矛盾逐項對齊。
# Lumos Round 3 外部第三方重審

## 一、結論先行

**重新評分：6.4/10，維持不變。**

這不是「完全沒有進步」：

- `canary record` 現在確實會在 append 後重開檔案、讀回 token，普通的「函式根本沒寫到所選檔案卻直接報成功」已被擋住。
- `timed_out` 已降為弱證據；全弱證據不再回傳成功。
- CI 回流提供了真實的當輪可觀測性；本次公開 CI 也確實在 `b75266c` 全綠、`1668 passed`。

但維護方把數個「局部機制已存在」誇張成「P1-1 全數落地」「分權成立」「知道為何紅」「CI 紅燈會吐完整證據」。其中有明確不實自報。

最嚴重的四點是：

1. `_jsonl_append_verified()` 只證明所選路徑上某個相同 key **當下可讀**，不證明本次 append 可持久化、不證明讀到的是本筆、不證明 vault 選對，也不防並發、碰撞、截斷或 inode 替換。
2. `canary second` 是不影響 gate 的選配 telemetry；repo 中沒有任何一筆第二判定者紀錄或抽樣報告。這不是已成立的分權。
3. `_kill_attribute()` 是文字鄰接啟發法，沒有 assertion 或行為歸因；預設文字輸出與治理帳甚至不保留歸因 excerpt。
4. `ci-wait` 不是強制面，且含有完成但非明列紅色就判綠的邏輯；`cancelled`、`action_required` 等可被誤報為 green。

因此，原先 6.4 的上限理由需要**收窄但不能撤銷**：普通的 fresh-token 即時讀回已修；廣義的證據帳完整性仍沒有成立，且本輪又增加了 CI 假綠與架構圖漂移。

---

## 二、查證基準與方法

我重新閱讀了 v2 評審。上次 6.4 的核心立場是：

- Lumos 已是有真 CI、對抗審與消費端合約的工程工具。
- 但尚不能當組織級強制控制或可靠稽核系統。
- 最大扣分是 canary「回報成功但沒有留下證據」，加上自判、guard-kill 歸因不足、required check 缺席與權限／供應鏈未硬化。[v2 評審](/Users/enzo/harness/lumos-toolchain/governance/external-reviews/2026-07-29-codex-final-v2.md:18)

獨立核對結果：

- `HEAD = b75266c`
- `33ea425..b75266c` 共 21 筆 commit
- `scripts/lumos`：11,968 行
- 頂層命令實際為 51 個
- 公開 CI run `30439628699` checkout 的確切 SHA 為 `b75266c`；compile、SyntaxWarning、完整測試、doctor、anchor 全綠，完整測試為 `1668 passed, 0 failed`：[GitHub Actions run](https://github.com/EnzoHsieh-Android/Lumos/actions/runs/30439628699)

查證時工作樹原已存在：

- `docs/.governance-log.jsonl` 修改
- `docs/.usage-log.jsonl` 修改
- round3 報告為 untracked

以下 code 判定以目前工作樹實況為主，commit 數與正式 CI 以 `b75266c` 為準。我沒有修改 repo。

---

# 三、逐條核對維護方自報

## 3.1 基準資訊

### `b75266c`、21 筆 commit、CI 綠：屬實

`git rev-list --count 33ea425..b75266c` 為 21；遠端 CI 也在該 SHA 全綠。

但「CI 綠」只能證明現有測試綠，不能替下述未測窗口背書。

---

## 3.2 P1-1「已全數落地」：不成立

維護方在 round3 明確聲稱「已全數落地」。[round3](/Users/enzo/harness/lumos-toolchain/governance/external-reviews/2026-07-29-maintainer-round3.md:15)

實查是六項中：

- 兩項基本成立。
- 兩項只完成局部機制。
- 兩項屬明確自報不實。

所以總括宣稱「全數落地」本身就是過度陳述。

### 1. 絕對路徑：使用者行為屬實，實作位置自報不實

維護方聲稱 `_jsonl_append_verified()` 本身印出絕對路徑。[round3](/Users/enzo/harness/lumos-toolchain/governance/external-reviews/2026-07-29-maintainer-round3.md:21)

實際上 helper 只回傳 rc；絕對路徑是外層 `cmd_canary_record()` 用 `path.resolve()` 組進成功訊息。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2537)

**判定：**

- 「成功訊息帶絕對路徑」屬實。
- **維護方自報不實：**不是 `_jsonl_append_verified()` 印的；是呼叫端印的。

這個差別不影響 CLI 當前行為，但說明自報沒有精確對照實作。

### 2. append 後讀回 token：屬實，但不是 durable write

helper 確實：

1. 以 append 模式寫一行。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2553)
2. 關閉後重開檔案。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2559)
3. 逐行找相同 key；找到即 rc0。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2567)
4. 找不到則 rc2。

但沒有 `flush()`、`fsync()`、檔案鎖、offset／record digest 驗證，也沒有驗證讀回的整筆內容等於剛才 append 的 payload。

**判定：局部屬實。**它是 visibility readback，不是 durability、uniqueness 或 ledger-integrity proof。

### 3. cwd 漂移、錯 vault、不可寫路徑回歸測試：維護方自報不實

維護方把三種測試都歸到 `t_canary_record_persist`。[round3](/Users/enzo/harness/lumos-toolchain/governance/external-reviews/2026-07-29-maintainer-round3.md:23)

實際測試只驗：

- 正常成功輸出與 token 落盤。[scripts/test_lumos.py](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:9330)
- 將 canary log symlink 到 `/dev/null` 後必須失敗。[scripts/test_lumos.py](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:9343)

沒有看到：

- 選錯但可寫、可讀的 vault 必須被攔截。
- 真實的 `EACCES`／唯讀目錄。
- 無 `--vault` 下由不同 cwd 導致解析到錯 vault。
- 讀到錯 vault 中既存相同 token 的碰撞情形。

`/dev/null` 只能測「寫後找不到 token」；不能代表一般的不可寫路徑，更不能代表 wrong-vault 偵測。

**判定：維護方自報不實。**

### 4. 每批交第二判定者覆核、拒絕同一判者形成分權：維護方自報不實

`lumos canary second` 的確存在，並拒絕第二筆 auditor label 與第一筆完全相同。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2615)

但實際機制明確是 telemetry-only，不影響 gate。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2577) CLI help 也照樣標明 telemetry-only。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:11280)

更致命的是：

- auditor 只是任意字串，沒有身份驗證。
- 只拒絕大小寫不敏感的完全相同 label；同一個編排者填另一個名字即可。
- 同一原始紀錄可以反覆增加 second 判定。
- 不要求抽樣報告或 evidence artifact。
- 不改變 caught/missed gate。
- `rg '"kind":"second"' docs/.canary-log.jsonl` 為零筆。
- `governance/canary-samples/` 只有 README，沒有任何 `CANARY-*.md` 覆核報告；而 README 明定抽樣報告應存於此。[canary sample README](/Users/enzo/harness/lumos-toolchain/governance/canary-samples/README.md:3)

skill 寫了「累積五輪抽一輪」的流程規範，[code-loop skill](/Users/enzo/harness/lumos-toolchain/skills/lumos-code-loop/SKILL.md:90)；但現有系統與帳本證據沒有證明它曾實際執行。

**判定：**

- 「有 second telemetry 子命令」屬實。
- 「每批已交第二判定者」沒有證據。
- 「拒絕同一判者＝分權成立」不成立。
- **維護方自報不實。**

### 5. guard-kill 輸出實際失敗測試、assertion 與行為歸因：維護方自報不實

`_kill_attribute()` 做的是：

- 搜尋 method 名稱的字串位置，且不是 token boundary match。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4079)
- 從命中行往後看最多四行。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4082)
- 遇到疑似其他測試名稱即停止。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4086)
- 看到任何 `FAIL`、`ERROR`、`AssertionError` 等 marker 即歸因。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4088)

這不是 assertion attribution，更不是 behavior attribution。它沒有解析測試框架結構、exception、assert expression、expected/actual 或 stack ownership。

另外：

- `attr_excerpt` 只放入內部 result／JSON。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4253)
- 寫入 kill ledger 時沒有保存 `attr_excerpt`。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4294)
- 預設文字輸出只印 verdict、invariant、test、detail，不印 excerpt。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4308)

所以連「輸出實際失敗 assertion」都不成立，更不用說「行為歸因」。

**判定：維護方自報不實。**

### 6. timeout 降級、7 態、全弱不成功、還原舊 bug 翻紅：屬實

這是本輪最扎實的 oracle 改善：

- `timed_out_weak` 不再算 killed。
- `killed_unattributed` 已拆出。
- 全部只有弱證據時回 rc1。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4316)
- code-loop 已把「還原舊 bug 後指定測試必須翻紅」寫成標準。[code-loop skill](/Users/enzo/harness/lumos-toolchain/skills/lumos-code-loop/SKILL.md:89)

**判定：屬實，應計實質進步。**

但架構圖仍保留舊的六態與 `timed_out` 視同 killed：

- [guard-kill system](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/guard-kill.md:13)
- [guard-kill system](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/guard-kill.md:37)
- 舊 Verification 仍為 `status: pass`，且重驗條件明列 state／rc 改變就應重驗。[舊 Verification](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Verification/2026-07-10_guard-kill整合測試.md:3)

因此 code 修了，架構圖合約面沒有乾淨收斂。

---

## 3.3 「code-loop 打回六條」：實作 delta 可證，程序獨立性不可證

Git 歷史確實存在 `5508aed oracle code-loop fixes 6`，也能看到對應程式與測試修改。

但「獨立審計員」是不是乾淨的第二權力中心、是否沒有共享上下文、是否真正由不同判定者執行，repo 無法獨立證明。Verification 的自述不能反過來證明 Verification 自己的程序獨立性。

**判定：**

- 六項程式修正存在：屬實。
- 審計程序的獨立性：無法由 repo 證成，不加分。

---

## 3.4 CI 回流閉環

### direct-flow 程式範圍：大致屬實

`ci-wait` 會以 SHA 查 GitHub Actions run、聚合 run/attempt，紅色時回 rc1；`ci-status` 讀本機 ledger。這些程式均存在。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9707)

缺少 `ci` config 或 config 壞掉時會停用。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9673)

但把 config 壞損退全關稱作「fail-safe」只在「不侵入使用者」這個狹義目標成立；對品質控制而言，它是 **fail-open**：配置壞了，agent 繼續工作且 rc0。

### 「紅則吐失敗步驟＋log 尾段」：維護方自報不實

紅色 result 物件會建立 `failed_step` 和 `log_tail`。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9834)

但預設文字 emitter 只印：

- status
- workflow
- sha
- URL
- verdict

沒有印 `failed_step` 或 `log_tail`。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9792)

測試的紅色路徑使用 `--json`，且只 assertion `failed_step`；沒有驗證人類可見文字輸出，也沒有驗證 `log_tail`。[scripts/test_lumos.py](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:11389)

ledger 同樣沒有保存完整 log tail。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9877)

**判定：維護方自報不實。**

README 與 skill 也跟著承諾了預設會印失敗步驟／log，但 code 沒做到：

- [README](/Users/enzo/harness/lumos-toolchain/README.md:237)
- [code-loop skill](/Users/enzo/harness/lumos-toolchain/skills/lumos-code-loop/SKILL.md:157)
- [project-notes skill](/Users/enzo/harness/lumos-toolchain/skills/lumos-project-notes/SKILL.md:14)

### CI 有假綠邏輯

程式只把 `failure`、`timed_out`、`startup_failure` 定義為紅色。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9668)

所有 run completed 且未命中上述紅色，過 grace period 後就直接判 green。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9847)

因此至少下列 GitHub conclusion 可能被誤報為 green：

- `cancelled`
- `action_required`
- 未知／未來新增的 completed conclusion

這也違反架構圖計劃自己列出的 conclusion 矩陣。[CI 計劃](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/CI回流閉環_計劃.md:53)

此外：

- `gh` 不可用時 rc0。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9830)
- 沒有 run 或等候 timeout 時 rc0。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9858)

對後備通知工具可以接受；對「強制閉環」絕對不能接受。

### 所謂「範圍手術」只在 code 成立，架構圖沒有真正動完

code 的確只做 direct SHA polling。

但 active project 仍是 `status: doing`，摘要與主體保留 PR flow、tier、ship、自動重試等設計。[CI 計劃](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/CI回流閉環_計劃.md:3)

其中還保留：

- 不需要 branch protection 的語意。[CI 計劃](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/CI回流閉環_計劃.md:35)
- PR／auto-merge／ship 測試規劃。[CI 計劃](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/CI回流閉環_計劃.md:129)
- 「紅燈文字輸出 failure step/log」的預期。[CI 計劃](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Projects/CI回流閉環_計劃.md:135)

**判定：程式 scope 收縮屬實；架構圖的 scope surgery 沒有收乾淨。**

---

## 3.5 `t_docs_enumeration_drift`

### 不是純稻草人，但被明顯過度宣傳

它確實有一個有價值的作用：若程式能 emit 的 verdict 從 reference 中被刪掉，測試會失敗。[scripts/test_lumos.py](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:11236)

治理來源數也有對程式與文件兩邊計數。[scripts/test_lumos.py](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:11226)

所以不能說完全是稻草人。

但維護方宣稱 hook 是三方 `⟺`。[round3](/Users/enzo/harness/lumos-toolchain/governance/external-reviews/2026-07-29-maintainer-round3.md:52)

實際 assertion 是：

```text
registered <= copied
```

不是 equality，也不是雙向等價。[scripts/test_lumos.py](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:11245)

因此：

- 多出「只 copy、未 register」的 phantom hook 可通過。
- verdict 測試只保證 code emitted values 被 reference 包含；reference 多列不存在的 verdict 仍可通過。
- 它沒有保護 `Systems/guard-kill.md` 與舊 Verification，所以 repo 現在仍同時存在六態與七態。
- `AGENTS.md` 仍宣稱 44 個頂層命令。[AGENTS.md](/Users/enzo/harness/lumos-toolchain/AGENTS.md:7)
- project-notes reference 仍宣稱 49 個命令。[reference.md](/Users/enzo/harness/lumos-toolchain/skills/lumos-project-notes/reference.md:85)
- 實際 `lumos --help` 是 51 個。

**判定：**

- 「不是純稻草人」成立。
- 「hook 三方等價」是**維護方自報不實**。
- 它只能拿到小額工程分，不能拿「文件漂移問題已閉合」的分。

---

## 3.6 維護方自報「未做事項」：均查證屬實，但零加分

誠實列出未做是最低要求，不是成果。

### required check：仍未做

CI workflow 存在，不等於 `main` branch required status check。`ci-wait` 更不會阻止未通過的提交進 main。

### Actions pin：仍未做

仍使用可移動 tag：

- `actions/checkout@v4`
- `actions/setup-python@v5`

見 [ci.yml](/Users/enzo/harness/lumos-toolchain/.github/workflows/ci.yml:14)。

### bootstrap 供應鏈 pin／checksum：仍未做

`get.sh` 仍直接 clone，沒有 commit pin。[get.sh](/Users/enzo/harness/lumos-toolchain/get.sh:26)

notesmd 下載仍是 curl 解壓，沒有 checksum 驗證。[fetch-notesmd.sh](/Users/enzo/harness/lumos-toolchain/scripts/fetch-notesmd.sh:32)

### `doctor --ci` decisions schema：仍未做

結構檢查仍在 `cmd_lint()` 路徑。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2068)

### capture-recapture hard veto：仍未做

不帶 cluster 的舊路徑仍保有 `<1` hard veto。[design-loop skill](/Users/enzo/harness/lumos-toolchain/skills/lumos-design-loop/SKILL.md:68)

### 認識論修正：仍未做

架構圖與 code 衝突仍被規定為架構圖必勝：

- [CLAUDE.md](/Users/enzo/harness/lumos-toolchain/CLAUDE.md:17)
- [README](/Users/enzo/harness/lumos-toolchain/README.md:31)
- [project-notes skill](/Users/enzo/harness/lumos-toolchain/skills/lumos-project-notes/SKILL.md:10)

本輪架構圖仍寫六態、code 寫七態，已再次示範為什麼這項認識論有害：若照「架構圖必勝」，新 code 反而會被宣判為錯。

### dry-run 寫權隔離：仍未做

非 dry-run 已禁用，這點維持肯定。[autonomous-loop.sh](/Users/enzo/harness/lumos-toolchain/governance/autonomous-loop.sh:11)

但所謂 dry-run 仍給 `Edit,Bash,Agent` 和 `acceptEdits`。[autonomous-loop.sh](/Users/enzo/harness/lumos-toolchain/governance/autonomous-loop.sh:74)

### Windows 無條件 pass：仍存在

Windows 分支仍有直接 `check(..., True)` 後 return 的測試。[scripts/test_lumos.py](/Users/enzo/harness/lumos-toolchain/scripts/test_lumos.py:227)

### 單檔結構債：屬實且惡化

`scripts/lumos` 從 11,479 行增至 11,968 行，新增 489 行；頂層命令從 v2 的 49 增至 51。

### INVARIANT 2 → 6：屬實

新增 canary 兩條、guard-kill 兩條 invariant：

- [canary-audit](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/canary-audit.md:15)
- [guard-kill](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/guard-kill.md:11)

但這只能證明合約數增加。它不能抵銷同一文件 body 還保留「judge 就是 injector、無外部檢查」的舊描述。[canary-audit](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Systems/canary-audit.md:73)

---

# 四、四個指定問題的攻擊性回答

## 4.1 `_jsonl_append_verified` 是否閉合證據帳完整性？

**沒有。它只關掉一個窄窗口：本次呼叫對所選 path append 後，完全找不到該 key。**

它擋得住的事故：

> fresh unique token、單一 writer、vault 選對、檔案沒有被替換，且失敗形式是「寫入根本不可見」。

這比 v2 時好，應承認。

它擋不住以下窗口。

### A. 沒有 durable write

沒有 `fsync()`。重開讀回通常仍可從 OS page cache 看到資料，但掉電或 kernel crash 後仍可能遺失。

所以它證明的是：

> 現在這個 process 能讀到。

不是：

> 證據已持久化到可稽核儲存層。

### B. key 碰撞／舊紀錄代答

helper 掃整個檔案，只要任何一行 `d[key_field] == key_value` 就成功。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2567)

token 又可由使用者指定。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:11288)

因此：

1. 檔案已有相同 token。
2. 本次 append 被截斷或沒有成功。
3. readback 找到舊紀錄。
4. rc0。

它沒有驗證：

- 新增檔案 offset。
- seq。
- 整筆 payload。
- hash。
- record count 增量。

### C. 並發 writers

沒有鎖，也沒有 single-writer protocol。

兩個 process 可以：

- 使用相同 key。
- 各自 append。
- 其中一筆只寫了一半。
- 另一筆完整。
- 兩者 readback 都因找到完整 key 而成功。

JSONL 小行通常有較高機會一次寫完，不代表 API 提供完整原子性保證，也不代表多個 writer 不會產生重複或局部損壞。

CI ledger 的 dedup 也使用「先掃描、再 append」，同樣沒有鎖。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:9763) 兩個 agent 同時執行可產生重複紀錄。

### D. wrong vault 仍可成功

helper 只驗證 resolver 選出的 `env.vault.parent`。如果選到另一個合法、可寫、可讀的 vault，它會在錯地方完整寫入並回成功。

顯示絕對路徑是給人看的線索，不是機械上的 vault identity proof。

### E. TOCTOU／inode 替換

append 與 readback 是兩次獨立 open。兩次之間路徑可以被：

- symlink 重指向。
- rename 替換。
- mount／inode 交換。

helper 沒有比對 device/inode，也沒持有同一 file descriptor。

### F. 讀回後遭截斷、刪除或竄改

readback 成功後，外部 process 仍可立即：

- truncate。
- delete。
- rewrite。
- 移除特定 record。

本機 JSONL 也沒有 hash chain、append-only filesystem control、簽章或遠端不可竄改副本。

### G. 部分損壞被靜默略過

掃描時無法解析的 JSON 行直接 `continue`。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:2563)

只要同一 key 在其他完整行出現，檔案中另有部分寫入、交錯或 corruption 並不會使操作失敗。

### H. 原事故根因仍未知

事故節點自己只把 cwd／路徑漂移列為懷疑，沒有證明根因。[事故節點](/Users/enzo/harness/lumos-toolchain/docs/lumos-toolchain-knowledge/Issues/canary-record未落盤事件.md:17)

因此不能聲稱「原事故已機械閉合」。精確說法只能是：

> 已阻止一類「所選 path 上找不到 key 仍報成功」的失敗。

---

## 4.2 `_kill_attribute` 是否從知道紅進到知道為何紅？

**沒有。它從「看到 process 紅」進步到「測試名稱後五行內看到失敗字樣」，仍不是因果歸因。**

### 假陽性：錯殺為 `killed`

#### 方法名是別人的前綴

合約綁的是 `test_pay`；輸出是：

```text
test_payment FAILED
```

`.find(method)` 仍會命中，因為沒有 token boundary。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4079)

#### 測試已通過，但摘要行含 FAIL

```text
TestLimitFive PASSED
0 FAILED, 1 passed
```

marker 包含寬鬆的 `"FAIL"`。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4065) 因此 `0 FAILED` 也能被判 killed。

#### 測試名稱出現在 log／stack，後面是別人的 AssertionError

只要後四行內未先出現另一個可辨識的測試名稱，就可能把無關 AssertionError 歸給目標測試。

#### whole-suite unrelated failure

若命令層沒有把單一 method 傳給 runner，整套測試因其他原因紅，結果仍可能得到強 verdict。程式只在 detail 加上「whole-suite 證據較弱」，沒有把 verdict 降級。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4263)

#### 測試本身失敗，不代表 invariant 行為被殺掉

即使失敗測試名稱完全正確，也可能是：

- fixture setup 壞掉。
- import error。
- teardown error。
- 資料庫／網路／時間不穩定。
- mutation 造成 crash，而非目標 assertion 翻紅。

baseline green 只能排除「修改前本來就紅」，不能證明修改後紅燈由目標行為導致。

### 假陰性：真 killed 卻被降為 `killed_unattributed`

#### failure marker 在測試名稱之前

部分 runner 先印 exception，再在尾端列 testcase。演算法只往後看，不往前看。

#### stack trace 超過四行

名稱與 `AssertionError` 相隔五行以上即看不到。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4082)

#### 中間文字被誤認為另一個 test

`_OTHER_TEST_RE` 很寬，`\w+Tests?` 可能把一般 log token、suite name 或 `LoadTest` 認成另一測試，提前 break。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4067)

#### runner 格式不在 regex 假設內

參數化顯示名、BDD 名稱、ANSI color、換行格式、non-Python framework 都可能漏掉。

#### log 中段被裁掉

輸出只保留 head/tail，總上限約 256 KiB。[scripts/lumos](/Users/enzo/harness/lumos-toolchain/scripts/lumos:4052) 真正的 testcase failure 若在中段可消失。

### 最終判定

7 態拆分與 timeout 降級值得加分；`_kill_attribute()` 不值得被稱為 assertion／behavior attribution。它只是 evidence proximity heuristic。

---

## 4.3 第二判定者是否真的形成分權？

**沒有。現在是「可另填一個 auditor label 的事後註解功能」，不是權力分立。**

真正的第二判定者至少要有：

1. 由系統而非原編排者選樣。
2. 第二人無法看到第一人的 verdict，避免 anchoring。
3. auditor identity 不可由呼叫者自由冒填。
4. 原始 injection、report、判定 rubric 均被固定。
5. disagreement 會進仲裁或影響 gate。
6. 有實際覆核帳與 artifact。

目前六項都沒有。

尤其：

- same-label rejection 防不了同一 actor 用別名。
- 第二判定不影響 gate。
- 可以對同一 ref 多次補寫相反答案。
- 沒有 second 紀錄。
- 沒有 sample report。

所以答案很直接：

> **是，現在仍是換湯不換藥。**

skill 中把流程寫出來是設計意圖；沒有實際 ledger 和 power effect，就不能叫控制已落地。最多只能說「提供未來分權的資料格式」。

---

## 4.4 CI 回流閉環是加分還是道德風險？

**對治理可觀測性小幅加分；對強制面與安全性不加分，目前實作甚至帶來額外假綠風險。**

### 它確實解決了一個真問題

push 後 agent 可以在同一輪看到遠端異機 CI 結果，縮短：

```text
push → 雲端紅 → 人稍後發現
```

到：

```text
push → 同輪查詢 → agent 當輪修
```

這是 MTTR／feedback latency 改善，不只是新名詞。它可以得到治理機制分。

### 但它不是 enforcement

`ci-wait` 不會：

- 阻止 push。
- 阻止 merge。
- 阻止 direct main。
- 建立 required status check。
- 建立不可繞過的伺服器端政策。

所以它沒有補上 v2 所稱的強制面斷點，只是把強制面之外的通知回路補上。

### 道德風險確實存在

若組織開始相信：

> 反正 agent push 後會等 CI、看到紅就會修。

就容易推遲：

- branch protection。
- required checks。
- PR review。
- 權限分離。
- release gate。

而現況的 `ci-wait` 恰好會在多種狀況 rc0：

- config 缺失或壞損。
- `gh` 不可用。
- 沒有 run。
- timeout。
- `cancelled`／`action_required` 等未明列紅色 conclusion。

這不是假設性風險；它已存在於控制流程。

### 最終歸類

- **是治理可觀測性與開發體驗功能：加小分。**
- **不是強制控制：安全不加分。**
- **若文件繼續稱它為「閉環」而不清楚標示 fail-open，就應扣誠信與設計分。**

「CI 回流觀測」會比「CI 回流閉環」更準確。

---

# 五、架構圖與實況的反證

這輪最諷刺的結果是：repo 仍宣稱「架構圖衝突時架構圖必勝」，但 round3 自己製造了更多架構圖／code 衝突。

| 事項 | Code／實況 | 架構圖／文件 |
|---|---|---|
| guard-kill state | 7 態，timeout weak | 仍寫六態、timeout killed |
| guard-kill rc | 全弱 rc1 | 舊 Verification 寫 timeout killed rc0 |
| canary second | telemetry-only、實際零紀錄 | summary 宣稱第二判定者 invariant |
| CI scope | direct SHA polling | active plan 仍含 PR、ship、tier |
| CI failure output | 預設不印 step/log | README、skills、計劃宣稱會印 |
| 命令數 | 51 | AGENTS 44、reference 49 |

這不是小型文案瑕疵；它直接推翻「架構圖必然代表真相」的認識論。

更嚴重的是 CI 的 `doctor` 仍回 0 issues，代表現有機械檢查看不見這些衝突。新增四條 invariant 的數量，不能抵銷 invariant 所在文件本身互相矛盾。

---

# 六、重新評分

五面向維持等權平均。

| 面向 | v2 | Round 3 | 變動 | 判定 |
|---|---:|---:|---:|---|
| 問題定位與方法論 | 7.5 | **7.5** | 0.0 | 不升 |
| 架構與代碼品質 | 6.0 | **5.9** | -0.1 | 小降 |
| 治理機制設計 | 7.5 | **7.7** | +0.2 | 唯一上升 |
| 可用性與採用門檻 | 5.5 | **5.5** | 0.0 | 不升 |
| 安全性 | 5.5 | **5.4** | -0.1 | 小降 |
| **總分** | **6.4** | **6.4/10** | **0.0** | 維持 |

## 6.1 問題定位與方法論：7.5，不升

加分面：

- 繼續把 oracle 品質當最高優先級是正確方向。
- timeout 降級與 restoration-red 都是正確的 falsification discipline。

不升原因：

- 「架構圖必勝」沒有修。[CLAUDE.md](/Users/enzo/harness/lumos-toolchain/CLAUDE.md:17)
- capture-recapture 舊 hard veto 沒有砍。[design-loop skill](/Users/enzo/harness/lumos-toolchain/skills/lumos-design-loop/SKILL.md:68)
- 本輪把 telemetry 稱為分權、文字鄰接稱為行為歸因、通知稱為閉環；概念精度反而不足。

做了很多事不等於方法論分應上升；要看是否正確描述控制能力。

## 6.2 架構與代碼品質：5.9，小降 0.1

正面：

- 有實質測試增加。
- CI 在公開異機環境全綠。
- `ci-wait`、dedup、ledger 的基本結構可用。

扣分：

- god module 再增 489 行至 11,968。
- CI conclusion 判定含假綠。
- human output、ledger、文件三者不一致。
- 新 drift test 被描述為三方等價，實際只是 subset。
- code 修成七態，架構圖與 Verification 還保留六態。
- command-count guard 沒抓到 44／49／51 三個版本。

因此不是「有新增測試就必須升」。新增程式也帶入新的 correctness debt。

## 6.3 治理機制設計：7.7，上升 0.2

這是唯一應上升的面向。

加分依據：

- canary 成功路徑加入 append 後 readback。
- timeout 不再被當強 kill。
- 全弱證據 rc1。
- restoration-red 納入 code-loop。
- 遠端 CI 結果能回流本地 agent。
- toolchain invariant 由 2 增至 6。

沒有升更多，因為：

- readback 不是 durable／unique proof。
- second judge 沒有 power separation，也沒有實績。
- kill attribution 不是 causal attribution。
- CI 是 fail-open observability。
- 架構圖仍有大量活動中矛盾。

## 6.4 可用性與採用門檻：5.5，不升

`ci-wait` 對實際開發流程有用，但被下列成本抵銷：

- 頂層命令由 49 增至 51。
- 預設紅燈輸出沒有維護方承諾的 step/log。
- 新增 CI ledger、second judge、更多 verdict 與 workflow 術語。
- 文件仍有 44／49／51 命令數漂移。
- 使用者仍需理解 config 是否存在、`gh` 狀態、no-run、timeout 與 ledger 語意。

功能增加不自動等於可用性提高。

## 6.5 安全性：5.4，小降 0.1

安全面沒有完成任何 v2 關鍵項：

- required check 未設。
- Actions 未 pin full SHA。
- bootstrap clone 未 pin。
- notesmd 無 checksum。
- dry-run 仍有 Edit/Bash/Agent 與 acceptEdits。
- doctor 全庫 decisions schema 未完成。

小降原因不是懲罰「誠實」，而是本輪新增了一個容易被誤認為 enforcement 的 fail-open CI 回路，且實際存在非紅 conclusion 被判綠的缺陷。這增加了控制誤讀風險。

---

# 七、「不再上調超過 6.4」的理由是否仍成立？

## 精確答案

**原句不能原封不動沿用，但修正版仍成立。**

不應再說：

> canary 沒有 append 後 readback，因此任何成功回報都可能完全沒有寫入。

這一點已經修了。對 fresh unique token、正確 vault、單 writer 的一般路徑，現在確實會讀回，這是實質改善。

應改成：

> Lumos 最核心的證據鏈仍只證明「所選本機路徑上，某個相同 key 在操作結束前可讀」；尚未證明這是本次 append、已持久化、位於正確 vault、未受並發／碰撞影響，且後續不可被截斷或竄改。

因此 6.4 上限仍成立，但理由已由：

```text
完全缺乏寫後驗證
```

收窄為：

```text
寫後可見性已補上；證據帳的持久性、唯一性、身份、並發與不可竄改性仍未成立
```

再加上本輪新發現的：

- second judge 無實權、零實績。
- kill attribution 非因果。
- CI conclusion 可假綠。
- required gate 仍不存在。
- graph/code 衝突持續增加。

在這些問題沒有處理前，把總分推到 6.5 以上會把「新增機制」錯當成「控制成立」。

---

# 八、最終評語

Round 3 是一輪**有真工程進步、但自報成熟度高於實際控制成熟度**的 delta。

最值得保留的是：

- append 後即時讀回。
- timeout weak。
- 全弱 rc1。
- restoration-red。
- 遠端 CI 當輪回流。

最需要撤回的宣稱是：

- 「P1-1 全數落地」。
- 「second judge 已形成分權」。
- 「guard-kill 已輸出 assertion 與行為歸因」。
- 「ci-wait 紅燈預設吐 step＋log tail」。
- 「hook 三方 ⟺ 已機械守衛」。
- 「CI 回流已補上強制閉環」。

**最終分數：6.4/10。**

這不是同情分，也不是因為維護方坦白未做事項而維持分數；是因為真改善足以抵銷本輪新增的架構、假綠與控制誤讀風險，但不足以跨過可靠稽核與組織級 enforcement 的門檻。