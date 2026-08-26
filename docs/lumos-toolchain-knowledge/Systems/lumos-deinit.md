---
type: system
status: done
created: 2026-06-26
updated: 2026-06-26
self_audit: sonnet/2026-06-26
tags:
  - type/system
  - status/done
  - risk/不可逆
verified_by:
  - "[[Verification/2026-06-26_lumos-deinit_跨平台]]"
summary: |-
  FLOW:pre-flight守衛(非git→rc2｜root==_lumos_src→rc2｜vault==root→強制keep-graph)→[--dry-run僅印即返]→[刪架構圖安全網:非tty無--yes→rc2｜印清單+未commit數→互動y確認]→拆閘→剝CLAUDE區塊→刪vault→移vendored(最後,可能含自己)
  KEY:對稱 lumos init 的「專案層」反安裝(對比 uninstall=機器層);只動本 repo,不碰 ~/.claude
  KEY:不可逆的 rmtree(vault) 被四重閘擋——dry-run/keep-graph/vault==root/非互動無--yes 任一即不刪(防誤刪整個 repo)[test:t_deinit_graph]
  KEY:vault==root 鐵閘獨立於 root==_lumos_src 守衛——保護任何 standalone-vault repo(非只 Lumos 源)免被 rmtree 整個 repo
  KEY:不自動 commit;留可審閱工作區(tracked 刪檔可 git restore、untracked 救不回)
  KEY:_VENDORED_TOOLKIT 常數安裝端(_vendor_toolchain)與移除端(cmd_deinit)共用,避免白名單漂移
  DEP:scripts/lumos cmd_init(對稱)｜cmd_uninstall(機器層)｜_vault_in/_lumos_src
  TEST:258 passed(macOS);Windows 真機驗過(EOFError 硬化)
  VERIFY:[[Verification/2026-06-26_lumos-deinit_跨平台]]
decisions:
  - content: vault==root 鐵閘:偵測到 vault.resolve()==root.resolve() 時強制 keep-graph、絕不 rmtree,獨立於 root==_lumos_src 守衛
    id: d1
    context: design-loop r3 canary 審計揪出的真 blocker:_vault_in 對 standalone vault(根目錄 MOC/+Systems)回傳 root 本身,deinit 預設刪 vault 會 rmtree 整個 repo;原 root==_lumos_src 守衛只擋 Lumos 源這一個 standalone repo,擋不住使用者自建知識庫
    why_chosen: 對主打防誤刪的指令,刪掉整個 repo 是不可逆災難;鐵閘獨立於來源守衛才能涵蓋任何 standalone-vault repo
    decided: 2026-06-26
    valid: true
  - content: 預設刪架構圖但置於三道安全網後(印清單+未commit警示、互動y確認、非tty無--yes則rc2拒刪)
    id: d2
    context: 使用者要 deinit 完整逆轉 init(含架構圖);但架構圖是不可逆資料
    why_chosen: 預設完整逆轉符合對稱語義,安全網把不可逆風險收斂到明確確認;--keep-graph 為逃生口
    decided: 2026-06-26
    valid: true
  - content: 互動確認的 input() 包 try/except EOFError,讀不到確認時拒刪 return 2
    id: d3
    context: Windows 真機驗證發現:某些終端 isatty() 回 True 但 stdin 實為 EOF,input() 會丟 EOFError
    why_chosen: 破壞性操作的安全預設是拒絕,對齊非互動中止;讀不到確認絕不刪
    decided: 2026-06-26
    valid: true
---
# lumos-deinit

`scripts/lumos` 的 `deinit` 子指令 —— 與 `lumos init` 對稱的**專案層反安裝**。

## 定位
- `lumos deinit` = 專案層:拆本 repo 的 pre-commit 閘(`core.hooksPath`)、vendored 工具組、`CLAUDE.md` 的 `LUMOS:GRAPH-DISCIPLINE` 注入區塊、(預設)知識架構圖 vault。
- `lumos uninstall` = 機器層(既有):全域 `~/.local/bin/lumos`、user-scope skills。
- deinit **不碰機器共用項**(`~/.claude/hooks/*.py`、`~/.claude/settings.json`)。

## 指令介面
`lumos deinit [--keep-graph] [--dry-run] [-y/--yes] [--source <path>]`
- `--keep-graph`:保留架構圖,其餘照拆。
- `--dry-run`:唯讀預演,完全不觸發確認機制,不動任何檔/config。
- `-y/--yes`:跳過互動確認(CI/非互動用)。
- `--source`:僅供 `root==_lumos_src()` 自我保護比對;白名單是 hardcoded 常數,不隨 source 變。

## 四重閘保護(不可逆的 `shutil.rmtree(vault)`)
`rmtree` 只在 `will_delete_vault` 為真時可達,而以下任一都讓它為假或提早 return,因此 rmtree 永遠到不了:
1. `--dry-run` → 印完即 `return 0`。
2. `--keep-graph` → `will_delete_vault=False`。
3. `vault==root` 鐵閘 → 強制 `keep_graph=True`(standalone vault:架構圖=repo 根,刪了=刪整個 repo)。**獨立於** `root==_lumos_src()` 守衛,保護任何 standalone-vault repo。
4. 非互動(stdin 非 tty)且無 `--yes` → `return 2`。
互動確認的 `input()` 另包 `try/except EOFError` —— 某些終端 `isatty()` 回 True 但 stdin 實為 EOF(Windows 真機),讀不到確認時**安全預設:拒刪 return 2**;使用者打非 `y` 主動取消 → `return 1`。

> `vault==root` 怎麼發生:`_vault_in(root)` 對 **standalone vault**(`MOC/` + `Systems/` 或 `Verification/` 直接在 repo 根)回傳 root 本身;一般專案則回傳 `docs/<slug>-knowledge/` 或(舊慣例)docs/knowledge/(不等於 root)。
> `root==_lumos_src()` 守衛:對齊 `cmd_update` 的 root==src 模式,印 stderr 並 `return 2`(拒絕整個 deinit),與 `vault==root` 鐵閘(只擋 rmtree、其餘照拆)效果不同。
> 對應回歸測試:`t_deinit_graph`(案例 10 = vault==root 鐵閘,並斷言印出「standalone vault」警示)。

## 固定執行順序(pre-flight 守衛全在第一個 mutation 之前)
1. 拆閘 `git -C root config --unset core.hooksPath`(best-effort:rc 0/5 皆成功,其他印 warning 續行)。
2. 剝 `CLAUDE.md` 的 graph-discipline 區塊(無標記/無檔 → no-op)。
3. 刪 vault(僅 `will_delete_vault` 時)。
4. **最後**移 vendored 工具組:`_VENDORED_TOOLKIT` 5 檔(`scripts/lumos`、`scripts/test_lumos.py`、`scripts/merge-claude-settings.py`、`scripts/graph-rename.sh`、`scripts/fetch-notesmd.sh`)+ `scripts/hooks/`、`scripts/templates/` **逐檔白名單刪(F9 修 2026-07-24,原整夾 rmtree 會連坐使用者自有檔)**——`_deinit_remove_vendored(root, src)` 從 `src` 兩夾 rglob 列舉 lumos 檔(對稱 `_vendor_toolchain` 安裝)、只刪這些;夾內尚有使用者檔則留夾+warn、空了才移;src 缺(None/來源夾不存在)→保守留夾+warn 不刪(never delete unknown)。見 [[Issues/deinit整夾刪使用者檔]]。`scripts/` 底下使用者自有檔不碰、空了才 `rmdir`。放最後因 POSIX 上刪到執行中的 `scripts/lumos` 自己無妨;Windows 用全域 `lumos`(指向來源 copy)亦無事。

## 已知平台差異
- **Git Bash(MinTTY)**:`isatty()` 不可靠,互動確認可能讀不到 → 設計上落回「拒刪、要 `--yes`」的安全側。
- **Windows 自刪**:用專案自帶 `python scripts\lumos deinit` 跑時,最後刪自己可能 `PermissionError`(Windows 不准刪執行中檔);用全域 `lumos`(指向來源)無此問題。

## 相關
- 設計稿:`docs/design/2026-06-26-lumos-deinit.md`(design-loop 收斂,5 輪)。
- 實作計畫:`docs/superpowers/plans/2026-06-26-lumos-deinit.md`(8 任務 TDD)。
- 實作落點:`scripts/lumos` `cmd_deinit` + 五個 `_deinit_*` helper + `_VENDORED_TOOLKIT` 常數。
