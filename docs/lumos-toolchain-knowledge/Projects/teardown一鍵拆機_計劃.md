---
type: project
status: doing
created: 2026-07-24
updated: 2026-07-24
tags:
  - type/project
  - status/doing
related:
  - "[[Systems/lumos-cli-lifecycle]]"
  - "[[Systems/lumos-deinit]]"
  - "[[Issues/hook卸載殘留註冊]]"
  - "[[Projects/install全域hook同步_計劃]]"
summary: |-
  FLAG:DECISION
  KEY:問題=拆一台裝了 lumos 的機器要跑 2~3 個指令(deinit 拆專案層+uninstall 拆機器層),且全域 ~/.claude/settings.json hook 註冊+~/.claude/hooks/*.py 沒有任何指令會清(Issues/hook卸載殘留註冊 的殘尾)。使用者要一鍵拆但保留架構圖文件
  KEY:範圍(std Codex F11 校準)=teardown 拆「當前 repo 的專案層 + 機器全域(CLI/skills/hooks)」,非整台機器所有 repo(deinit 只吃當前 git toplevel;別 repo 的注入/hooks 與 bootstrap 來源 clone 都留)。文件與 CLI help 誠實標明,別宣稱「拆一台機器」
  KEY:方案=lumos teardown 一鍵三步,順序修正(std F5):①_teardown_global_claude()先清全域 hook(要用 merge-claude-settings.py,必須在 deinit 刪掉它之前跑)②cmd_deinit(keep_graph=True)拆專案層③cmd_uninstall()拆機器 CLI/skills
  KEY:_teardown_global_claude()=_sync_global_claude 的移除半邊,失敗語意修正(std F6):先驗 ~/.claude/settings.json 可解析可寫→不可則跳過該步+warn(不半做);可則 rm ~/.claude/hooks/{_GLOBAL+_RETIRED}.py → 跑 _prune_dangling 剪懸空我方註冊。重用既有已測 _prune_dangling,不新手改 JSON 結構;使用者 hook 指向仍存在故不剪
  KEY:便宜守衛(std,走 B 方案 b)=①core.hooksPath 只在它指向本 repo 的 scripts/hooks 時才 unset(std F8:否則誤殺使用者自設 githooks)②uninstall 的 ~/.local/bin/lumos 只在 symlink(或 resolve 到本工具)時移,不刪同名一般檔(std F10)。兩守衛改在共用函式=deinit/uninstall 直接呼叫也一併變安全
  KEY:繼承的激進行為記為已知殘留(std,不在本刀修,另開 deinit 票):F4 剝 CLAUDE.md 會正規化 sentinel 外空白/CRLF(byte-equal 只保證注入端非移除端)、F9 scripts/hooks+scripts/templates 整夾 rmtree(使用者放那的自有檔會被刪)、F12 uninstall 移除全部 skills 非只 lumos-*(csharp/kotlin/vue-idioms 一起刪)。teardown help/文件明列這些破壞性
  KEY:確認/冪等=單次確認(destructive-but-recoverable:bootstrap/install 復原);--yes 略過、非互動無 --yes 拒絕且拒絕前零 mutation(std F13);冪等:二次跑「未安裝」不報錯。部分失敗:全域 settings 步採「不半做」(見上),其餘層盡力續拆並尾端彙報各層 rc
  KEY:風險面=machine-global settings.json 寫入(2026-07-07 事故前例)——緩解=只 rm 我方 hook+跑既有 _prune_dangling+先驗可寫、不新增寫邏輯;TDD 重壓(std F13):架構圖留/使用者 hook 不誤剪(含同 event 同陣列/子目錄)/core.hooksPath 使用者值保留/CLAUDE.md sentinel 外/settings 其他欄位(mcpServers/permissions)保留/壞 JSON 跳過/冪等/vendored 入口跑/拒絕前零 mutation,全走假 HOME
  DECISION:teardown=全域hook清理→deinit(keep_graph)→uninstall;範圍=當前 repo+機器全域(非全機所有 repo,std F11);永遠保留架構圖(使用者 2026-07-24);B 走(b):修 A 類 bug+2 便宜守衛,F4/F9/F12 記殘留另票(使用者 2026-07-24「照建議」)
  DEP:scripts/lumos cmd_deinit/cmd_uninstall/_deinit_unbar_gate/_sync_global_claude/merge-claude-settings.py(_prune_dangling)/_GLOBAL_CLAUDE_HOOKS/_RETIRED_CLAUDE_HOOKS/_VENDORED_TOOLKIT
  PRIOR-ART:①最小解=組合既有 cmd_deinit+cmd_uninstall,新增 _teardown_global_claude(_sync_global_claude 鏡像)+2 守衛;主體復用 ②世界解=無需外求 ③裁定=borrow-design(復用 _prune_dangling/deinit/uninstall)
verified_by:
  - "[[Verification/2026-07-24_teardown一鍵拆機]]"
---
# teardown一鍵拆機_計劃

> **狀態**：設計中（std Codex 跨家族審已折入），待 TDD。緣起：使用者要「一個指令拆機器層＋專案層但不刪架構圖」＋補全域 hook 殘留坑（[[Issues/hook卸載殘留註冊]]）。**Codex 跨家族審把「簡單組合」的假象戳破**——deinit/uninstall 各自單用 OK，湊成「一鍵安全拆機」露出順序 bug、失敗不一致、與一堆繼承的激進行為。

## 白話問題

拆一台裝了 lumos 的機器要跑好幾個指令，且**全域 `~/.claude` 的 hook 註冊/檔沒有任何指令會清**。使用者要一鍵拆、架構圖留著。

## 範圍（誠實標明，std F11 校準）

teardown 拆的是「**當前 repo 的專案層 ＋ 機器全域（CLI/skills/hooks）**」——**不是**整台機器所有 repo（`deinit` 只吃當前 git toplevel）。別的 repo 的注入/hooks、bootstrap 建的來源 clone **都留著**。CLI help 與文件如實講，別宣稱「拆一台機器」。

## 方案：`lumos teardown` 一鍵三步（順序已修）

1. **`_teardown_global_claude()`（先，std F5 順序修正）** — 補全域 hook 坑。**必須在 deinit 刪掉 `merge-claude-settings.py` 之前跑**（它要用那支）。
   - **失敗語意（std F6）**：先驗 `~/.claude/settings.json` 可解析、可寫 → 不可則**跳過此步＋warn，不半做**（避免「.py 已刪、註冊沒剪」的懸空殘留）。
   - 可則：`rm ~/.claude/hooks/{_GLOBAL_CLAUDE_HOOKS ＋ _RETIRED_CLAUDE_HOOKS}.py` → 跑 `_prune_dangling` 剪掉我方 hook 的懸空註冊（`_sync_global_claude` 的移除半邊；使用者 hook 指向的檔仍在 → 不剪）。
2. **`cmd_deinit(keep_graph=True)`** — 拆專案層：拆閘、剝 CLAUDE.md 注入、移 vendored 工具。**架構圖強制保留**。
3. **`cmd_uninstall()`** — 拆機器層：移全域 `~/.local/bin/lumos` symlink ＋ skills。

## 便宜守衛（走 B 方案 (b)，改在共用函式 → deinit/uninstall 直接呼叫也變安全）
- **core.hooksPath（std F8）**：只在它指向**本 repo 的 `scripts/hooks`** 時才 `--unset`；指向使用者自設（如 `.githooks`）則不動＋warn。
- **`~/.local/bin/lumos`（std F10）**：只在它是 symlink（或 resolve 到本工具）時移；同名的一般檔不刪。

## 明確不做（範圍刀 ＋ 繼承殘留另票）
- **永不刪架構圖文件**（使用者 2026-07-24）——keep_graph 強制、standalone-guard 兜底。
- **繼承的 deinit/uninstall 激進行為（本刀不修，另開 deinit 票，teardown help 明列破壞性）**：
  - **F4**：剝 CLAUDE.md 會正規化 sentinel 外空白/CRLF（那條硬合約只保證「注入」端 byte-equal，非「移除」端）。
  - **F9**：`scripts/hooks`、`scripts/templates` 兩夾整夾 `rmtree`——使用者放那的自有檔會被刪（reinstall 救不回）。
  - **F12**：`uninstall` 移除**全部 skills**（csharp/kotlin/vue-idioms 都刪），非只 `lumos-*`。

## 確認 / 冪等 / 部分失敗
- **單次確認**（可 `bootstrap`/`install` 復原）；`--yes` 略過、非互動無 `--yes` 拒絕，且**拒絕前零 mutation**（std F13）。
- **冪等**：二次跑「未安裝」不報錯。
- **部分失敗**：全域 settings 步「不半做」（先驗可寫）；其餘層盡力續拆、尾端彙報各層 rc。

## 風險面
- **machine-global settings.json 寫入**（2026-07-07 事故前例）。緩解＝只 rm 我方 hook ＋ 跑既有 `_prune_dangling` ＋ 先驗可寫、不新增寫邏輯、TDD 重測、假 HOME 隔離。

## 測試策略（TDD，std F13 擴充）
1. `t_teardown_removes_all_layers`：假 HOME＋repo → 架構圖留、CLAUDE.md 注入剝、vendored 移、全域 CLI symlink 移、skills 移、全域 hook .py 移＋settings 註冊剪。
2. `t_teardown_keeps_graph`：架構圖 vault 檔數不變。
3. `t_teardown_preserves_user_hooks`：使用者自訂全域 hook（含與我方 hook 同 event 陣列）→ 保留；settings 其他欄位（mcpServers/permissions）保留、輸出仍 `json.loads` 得。
4. `t_teardown_preserves_user_hookspath`：`core.hooksPath` 指使用者值 → 不 unset。
5. `t_teardown_preserves_regular_bin`：`~/.local/bin/lumos` 為一般檔（非 symlink）→ 不刪。
6. `t_teardown_bad_settings_skips`：settings.json 壞 JSON → 全域步跳過＋warn、**hook .py 不先刪**（不製造懸空）。
7. `t_teardown_refuse_zero_mutation`：非互動無 `--yes` → rc 非 0 且**什麼都沒動**。
8. `t_teardown_idempotent`：二次跑同結果、不報錯。
9. `t_teardown_standalone_guard`：vault==root → 架構圖強制保留。
10. `t_teardown_ordering`：全域清理在 deinit 移除 `merge-claude-settings.py` 之前完成（否則 prune 拿不到腳本）。

## 審計修正紀錄
- **std（2026-07-24，單席 Codex 跨家族，使用者授權精簡 standard）**：Codex 回 blocker＋多 major（附 file:line），orchestrator 抽驗 F4/F5/F8 屬實：
  - **F5**（deinit 先跑會刪掉 step2 需要的 merge 腳本）→ 順序改「全域清理先、deinit 後」。
  - **F6**（半途失敗留懸空）→ 全域步「先驗可寫、不半做」。
  - **F8/F10**（core.hooksPath 無條件 unset／uninstall 刪一般檔）→ 加兩便宜守衛（改共用函式）。
  - **F11**（「拆一台機器」名不副實，只拆當前 repo）→ 範圍誠實標「當前 repo＋機器全域」。
  - **F4/F9/F12**（CLAUDE.md 正規化／整夾 rmtree／移全部 skills）→ 繼承殘留，記入明確不做、另開 deinit 票。
  - **F13**（6 案不足）→ 測試擴至 10 案。
  - 處置：使用者 2026-07-24「照建議」裁定——範圍取當前 repo＋全域、B 走 (b)、F4/F9/F12 另票；折入後進 TDD。
