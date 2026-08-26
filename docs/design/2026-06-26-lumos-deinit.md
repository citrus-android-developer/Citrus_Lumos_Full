---
title: lumos deinit — 專案層反安裝指令
date: 2026-06-26
status: design-approved
---

# lumos deinit — 專案層反安裝

## 1. 定位與語義

與 `lumos init`(專案層裝)對稱的**專案層卸載**。完全逆轉 `init` 在「本 repo」與「本專案架構圖」留下的東西;**不碰機器共用項**(`~/.claude/hooks/`、`~/.claude/settings.json` 註冊),那些留給機器層的 `lumos uninstall` 處理。

分工:
- `lumos uninstall` = 機器層(全域 `~/.local/bin/lumos`、user-scope skills)— 已存在。
- `lumos deinit` = 專案層(本 repo 的 hooks/工具組/CLAUDE.md 注入/架構圖)— 本 spec 新增。

### 安裝 / 反安裝對照表

| `init` 裝的(來源函式) | `deinit` 處置 |
|---|---|
| `git config core.hooksPath scripts/hooks`(`_install_hooks_py`) | ✅ `git config --unset core.hooksPath` |
| vendored 工具組:`scripts/lumos`、`scripts/test_lumos.py`、`scripts/merge-claude-settings.py`、`scripts/graph-rename.sh`、`scripts/fetch-notesmd.sh`、`scripts/hooks/`、`scripts/templates/`(`_vendor_toolchain` 的 toolkit 清單)| ✅ 逐檔/逐夾移除(白名單;只動 lumos-owned) |
| `CLAUDE.md` 的 `LUMOS:GRAPH-DISCIPLINE:START/END` 區塊(`_scaffold_project`)| ✅ 只剝這段,其餘內容原封不動 |
| `docs/<slug>-knowledge/` 架構圖(`_scaffold_project`)| ✅ **預設刪**(走 §4 安全網);`--keep-graph` 可保留 |
| `~/.claude/hooks/check-graph-sync.py`、`verification-rot-check.py`(`_install_hooks_py`)| ❌ 不動(跨專案共用) |
| `~/.claude/settings.json` hook 註冊(`merge-claude-settings.py`)| ❌ 不動(跨專案共用) |

## 2. 指令介面

```
lumos deinit [--keep-graph] [--dry-run] [-y/--yes] [--source <path>]
```

| Flag | 作用 |
|---|---|
| (無) | 完整逆轉:拆閘 + 移 vendored 工具組 + 剝 CLAUDE.md 區塊 + **刪架構圖**;互動確認 |
| `--keep-graph` | 保留架構圖 vault,其餘照拆 |
| `--dry-run` | 只印「會動到什麼」,不實際改動(預演)。**唯讀,完全不觸發確認機制**(§4 第 1 條的互動確認與非互動中止皆豁免);CI 非 tty 下無需 `--yes` 即可預演 |
| `-y` / `--yes` | 跳過互動確認(CI / 非互動環境用) |
| `--source <path>` | 指定 Lumos 來源(預設 `_lumos_src()`),**僅供 §4 第 3 條 `root == _lumos_src()` 自我保護比對用**;vendored 白名單是 hardcoded 常數(見 §5),不隨 source 變動 |

行為細節:
- **冪等**:找不到 vault **且**無專案層安裝痕跡 → 印 `✓ 未安裝(此 repo 無 Lumos 專案層)` 並 `return 0`(措辭仿 `cmd_uninstall:3030` 的空狀態**語氣**,非逐字)。「有無安裝」的偵測 heuristic = **`git -C root config core.hooksPath` 有設值** 或 **`root/scripts/hooks/` 目錄存在**(偵測對象是 **target repo `root`**,不是 deinit 執行檔自身;故不論用全域 `lumos` 或 `python3 scripts/lumos` 跑都一致——`scripts/lumos` 自身存不存在與「該 repo 是否裝過」無關)。
- **root 與 vault 偵測**:`root` 走 `git rev-parse --show-toplevel`(獨立輸入);**與 `cmd_init:3255-3260` 不同的是 deinit 在非 git 目錄(rev-parse 失敗)時不 fallback 到 `cwd` 而是中止 return 非 0**——deinit 會刪檔,沒有可靠 root 寧可不動。取得 root 後再用 `_vault_in(root)` 找實際 vault 路徑(輸出),**直接用回傳路徑刪/印,不假設名稱、不靠 slug 重組**——`_vault_in` 三型(`docs/<slug>-knowledge`、`docs/knowledge`、standalone vault=root 自身,`scripts/lumos:3293-3306`)都回傳完整 Path,凡正文寫 `docs/<slug>-knowledge/` 僅為示例,實際以回傳值為準(dry-run 印的也是回傳路徑)。**不從 vault 反推 root**(勿學 `cmd_update:3097` 的 `vault.parent.parent`,該寫法在 standalone vault 會推錯)。找不到 vault 時 `--keep-graph` 為 no-op。
- **heuristic 與 git config 一律帶 `-C root`**:所有 `git config`/`git status` 呼叫用 `git -C <root> …`(不依賴 cwd),確保從子目錄執行也對同一 repo 生效。
- **不自動 commit**:只改 working tree + git config,留可審閱工作區給使用者(`git diff` 可看)。**已 tracked 的刪檔可 `git restore` 救回;untracked 檔(未 commit 的新筆記)刪了救不回**——正是 §4 第 1 條印清單要警示的對象。

## 3. 執行順序(設計保證:不被 pre-commit 擋)

**先過 pre-flight 守衛**:§4 第 3 條(`root==_lumos_src()`→`return 2`)與第 4 條(`vault==root`→強制 keep-graph)在 **step 1 之前求值**,命中即按該條處置(abort 或跳過刪 vault),**絕不會在已動 config/檔案後才攔截**。

pre-commit 閘由 `core.hooksPath → scripts/hooks/` 驅動,而這兩者正是 deinit 要移除的東西。固定順序保證後續 commit 不被擋:

1. **先拆閘** — `git config --unset core.hooksPath`(立即生效)+ 稍後移除 `scripts/hooks/`(雙保險:就算 config 未拆淨,hook 腳本不在 = git 找不到 = 不執行)。`--unset` 採 **best-effort**:rc 5(不存在的 key = 本來就沒設 = 拆閘目標已達成)與 rc 0 都視為成功;**其他非 0 rc(如 git 環境異常 rc 128)印 warning 後繼續**,不中止(真正的保險是「缺 hook 檔 git 直接放行不報錯」這條 git 語義——實機驗證:`core.hooksPath` 指向已刪目錄時 commit 仍 rc 0,故 step 4 移除 `scripts/hooks/` 後即便 config 殘留也無害)。
2. 移除 `CLAUDE.md` 的 graph-discipline 區塊。
3. 移除架構圖 vault(走 §4 安全網)。**`--keep-graph`、或 §4 第 4 條的 `vault == root` 鐵閘命中時,整個 step 3 跳過**(連 §4 第 1 條三道關卡都不進)。
4. **最後**移除其餘 vendored 工具組(含 `scripts/hooks/`、`scripts/templates/`、`scripts/lumos` 自己)。

> 把 vendored 檔移除放最後,是為了「`python3 scripts/lumos deinit` 刪到自己」的穩妥性:POSIX 上已載入記憶體的腳本被刪不影響執行,但流程其餘步驟此時都已完成。用全域 `lumos`(symlink 到來源)執行則無此顧慮。

事後 `git add -A && git commit` 時閘已不存在 → 刪光架構圖的 commit 暢通。手動路徑(自行 `git config --unset core.hooksPath` 再刪)亦同理成立;deinit 只是把它連同清理一次做好。

## 4. 安全網(防誤刪架構圖)

1. **刪架構圖前三道關卡:**
   - **印清單**:列 vault 路徑 + 檔案數,以及「其中 N 個未 commit(刪了 git 救不回)」,用 `git status --porcelain <vault>` 偵測未追蹤/已修改檔。
   - **互動確認**:預設需打 `y`;`--yes` 跳過。若偵測到未 commit 檔且非 `--yes`,確認語句特別警示。
   - **非互動防呆**:stdin 非 tty(管線/CI)又沒 `-y` → 中止並提示加 `--yes`,絕不默默刪。
2. **只動 Lumos 自己的東西:**
   - vendored 移除走**白名單**:① `_vendor_toolchain` 的固定 5 檔(`scripts/lumos`、`scripts/test_lumos.py`、`scripts/merge-claude-settings.py`、`scripts/graph-rename.sh`、`scripts/fetch-notesmd.sh`,全帶 `scripts/` 前綴,與 `scripts/lumos:3064-3065` 一致);② `scripts/hooks/`、`scripts/templates/` **整夾遞迴刪**(這兩夾整個是 Lumos-owned,直接刪目錄即可,**不需依賴 src 列舉**——故 `--source` 不可用時 deinit 照樣移得乾淨)。`scripts/` 底下使用者自有檔一律不碰;`scripts/` 空了才 `rmdir`,否則保留。
   - `CLAUDE.md` 只依 `LUMOS:GRAPH-DISCIPLINE:START/END` 標記剝該段;其餘內容、甚至整個檔(若還有別的內容)都留。若剝完僅剩 `# CLAUDE.md` 樣板殼,仍保留檔案(不臆測使用者意圖)。**找不到 START 標記(含 CLAUDE.md 不存在,例如 `init --no-hooks` 或模板缺致 `_scaffold_project:3167` 的 `if tpl.exists()` 未注入)→ 該步 no-op,不報錯**(注入端 `scripts/lumos:3175` 即以 `"…START" not in` 做存在性 gating,剝端對稱)。
3. **來源 repo 自我保護**:若 `root == _lumos_src()`(站在 Lumos 來源本身),**拒絕執行 + 印 stderr + `return 2`**,否則會把 Lumos 工具組自己刪了。對齊的是 **`cmd_update` 的 root==src 模式**(`scripts/lumos:3099-3101`:`print("ERROR…", file=sys.stderr); return 2`),**不是 `cmd_init`** —— cmd_init 的 root==src 只跳過 vendor/hooks、仍繼續 scaffold 且 rc 0(`scripts/lumos:3273-3274`),語義相反,deinit 套它會變成「在來源 repo 只跳部分動作、仍刪別的」,正好違反本條安全網。
4. **`vault == root` 鐵閘(防 rmtree 整個 repo)**:`_vault_in(root)` 對 **standalone vault**(根目錄有 `MOC/` + `Verification/` 或 `Systems/`,`scripts/lumos:3303-3305`)回傳 **`root` 本身**——不只 Lumos 源,**使用者自建純知識庫 repo、跨專案 core-knowledge repo 都符合**。此時 `vault.resolve() == root.resolve()`,若照預設刪 vault 就是 `rmtree(整個 repo)`。**故刪 vault 前必過此閘**:偵測到 `vault.resolve() == root.resolve()` →**絕不刪 vault**(強制等同 `--keep-graph`)、印明顯警示說明「偵測到 standalone vault,架構圖=repo 根,已保留;如確要清空請自行手動處理」,deinit 其餘專案層動作(拆閘/剝 CLAUDE.md/移 vendored)仍照常。此閘獨立於 §4 第 3 條的 `_lumos_src()` 比對(那條只擋 Lumos 源這一個 standalone repo,擋不住其他)。
5. **拆閘優先**:見 §3 step 1。

## 5. 實作落點

- 新增 `cmd_deinit(keep_graph=False, dry_run=False, yes=False, source=None)`,置於 `cmd_uninstall`(`scripts/lumos:3005`)附近。
- 抽出共用白名單:目前 `_vendor_toolchain` 把清單**內聯**在函式體(`scripts/lumos:3064-3069`:固定 5 檔 + `scripts/hooks/`、`scripts/templates/` 兩夾的 rglob 動態展開)。需**小幅重構 `_vendor_toolchain` 內部**,把那「固定 5 檔」清單抽成模組級常數(**示意命名** `_VENDORED_TOOLKIT`,實作時新建,型態同 `_SKILLS:3107` 的 `tuple[str]` 範式),供 `_vendor_toolchain` 與 `cmd_deinit` 共用避免漂移;兩夾在 deinit 端走「整夾遞迴刪」(§4 第 2 條),不需納入該常數。重構只動內部、不改 `_vendor_toolchain` 對外行為。
- argparse:`sub.add_parser("deinit", ...)` + 上述 flags;`main()` 在 vault-free 早處理區(同 `install/uninstall/update/bootstrap`,`scripts/lumos:3481` 一帶)分派,deinit 不需 vault Env。

## 6. 測試(TDD)

沿用 `scripts/test_lumos.py` 的 hermetic 模式(`t_install_hooks_py`,`scripts/test_lumos.py:110` 為模板):temp root + `git init` + temp HOME。

需覆蓋的案例:
1. **完整 deinit**:init 一個 repo → `deinit --yes` → 斷言 `core.hooksPath` 已 unset、vendored 工具組消失、`CLAUDE.md` 區塊被剝、vault 不存在。
2. **`--keep-graph`**:vault 仍在,其餘皆拆。
3. **拆閘有效**(規範斷言,非二選一):deinit 後斷言 `core.hooksPath` 為空 **且** `scripts/hooks/` 不存在 **且** 一個「改 code 不動架構圖」的 commit 能成功(rc 0,不被擋)——三者全驗,涵蓋 config 與檔案兩層。
4. **冪等**:對沒裝過的 repo 跑 `deinit` → return 0、印「未安裝」、無副作用。
5. **白名單**:`scripts/` 內預先放一個使用者自有檔 → deinit 後該檔仍在。
6. **CLAUDE.md 保留**:CLAUDE.md 內含使用者自有段落 + 注入區塊 → deinit 後自有段落完整、區塊消失。
7. **來源自我保護**:於 `_lumos_src()` 路徑跑 → 拒絕、return 非 0、無副作用。
8. **`--dry-run`**:印清單但檔案/config 全無改動。
9. **非互動防呆**:非 tty 無 `--yes` → 中止、return 非 0、無副作用。
10. **`vault == root` 鐵閘**(§4 第 4 條):造一個 standalone vault repo(根目錄 `MOC/` + `Systems/`,**非 `_lumos_src()` 路徑**),**並預先塞 `core.hooksPath` + 一段 CLAUDE.md 注入區塊**(讓「其餘動作」有東西可驗)→ `deinit --yes` → 斷言 **repo 根目錄與架構圖全數仍在**(絕無 rmtree)、印警示、**且 `core.hooksPath` 已 unset、CLAUDE.md 區塊已剝**(證其餘專案層動作確實執行)。這是防「刪整個 repo」的回歸測試。
11. **CLAUDE.md 退化 no-op**:CLAUDE.md 不存在、或存在但無 `LUMOS:GRAPH-DISCIPLINE` 標記 → `deinit --yes` 該步 no-op、不報錯、其餘步驟照常。

## 7. 文件

- `README.md` / `README.en.md`:第 「卸載」相關段補 `lumos deinit`(專案層)與 `lumos uninstall`(機器層)的分工。
- `ONBOARDING.md`:如有卸載/退場段落,補對照。
- 對齊 [[knowledge-sync-scatter-needs-mechanical-guard]] 的提醒:同步時掃散落的列舉表/清單,別只改最相關段。

## 8. 審計修正紀錄(design-loop)

> 註:本紀錄提到的 §N 是當輪審計時的編號;canary 為刻意植入後已移除,真檔不含。引用 §4 第 N 條一律指 §4 編號清單的第 N 項(本 spec 無 `### 4.N` 子標題)。

- **r1**(canary type a:植入 §9 壞引用,caught):存活真 finding 與折入:
  - **F2 [major]**:§4 第 3 條原寫「對齊 `cmd_init` 的 root==src skip」誤導——cmd_init root==src 仍 scaffold 且 rc 0(語義相反),已改為對齊 `cmd_update:3099-3101` 的拒絕+`return 2`。
  - **F4→minor**(辯方降:root 走 git toplevel 非 vault 反推):§2 補明 root 來源 + 勿學 `cmd_update:3097` 的 `vault.parent.parent`。
  - **F5→minor**(辯方降:git 缺 hook 檔放行、unset rc5 無害):§3 step 1 補 best-effort 說明。
  - **F3→minor**(辯方降:`_VENDORED_TOOLKIT` 是示意命名、有 `_SKILLS` 先例):§5 標明示意命名。
  - **F6/F7/F8 [minor]**:§2 dry-run 豁免非互動中止、冪等措辭標「語氣非逐字」、§6 測試行號修正。
- **r2**(canary type b:植入未定義旗標 `--keep-claude`,caught):存活全 minor,已折入:
  - **F2→minor**(辯方降 major→minor:`§N.M` 在編號清單無歧義):§2 的 `§4.1` 等改寫為「§4 第 N 條」。
  - **F4→clean**(辯方駁回 major):成立部分 = deinit 直接用 `_vault_in` 回傳路徑刪、不需 slug;白名單與 vault 型別/slug 解耦。⚠ **但辯方「standalone 案例已被 §4 第 3 條 `root==src` 守衛攔截」的論據在 r3 被推翻**(見下),屬誤閉案。
  - **F5 [minor]**:§2 `--source` 改述為「僅供自我保護比對」,白名單為 hardcoded 常數。
  - **F6 [minor]**:§2 `--dry-run` 明定完全不觸發確認機制。
  - **F7 [minor]**:§3 step 3 補「`--keep-graph` 時整步跳過」。
  - **F8 [minor]**:§2 `git restore` 改述為「tracked 可救、untracked 不可救」。
- **r3**(canary type c:植入未定義常數 `_PROTECTED_PATHS`,caught):
  - **F5/F10 [BLOCKER,辯方維持]**:standalone vault(根目錄 `MOC/`+`Systems/`)使 `_vault_in(root)` 回傳 `root` 本身 → `vault==root`,deinit 預設刪 vault = **rmtree 整個 repo**。`root==_lumos_src()` 守衛只擋 Lumos 源這一個 standalone repo,擋不住使用者自建知識庫 / core-knowledge repo。辯方查證後維持 blocker 並**推翻 r2 F4 的「已被守衛攔截」論據**。**修正**:§4 新增第 4 條 `vault==root` 鐵閘(偵測到即絕不刪 vault、強制 keep-graph + 警示),§3 step 3、§6 案例 10 連動。
  - **F3 [minor]**:§2 冪等的「有無安裝」heuristic 明定(core.hooksPath 有值 或 scripts/hooks/ 存在,不靠 scripts/lumos 自身)。
  - **F4 [minor]**:§3 step 1 補「rc 非 0 非 5 印 warning 續跑」。
  - **F7 [minor]**:§4 第 2 條明定 hooks/templates 整夾遞迴刪、不依賴 src 列舉。
  - **F9 [minor]**:§6 案例 3 由「OR 二選一」改為三斷言全驗。
  - (canary F2/F6 = `_PROTECTED_PATHS`,植入後移除,真檔不含。)
- **r4**(canary type d:植入未定義產物 `.deinit-manifest.json`+假 doctor 核對,caught):存活全 minor,已折入:
  - **F3→minor**(辯方降 major:「依標記剝」已隱含無標記=no-op、非破壞性):§4 第 2 條補「無標記/CLAUDE.md 不存在→no-op 不報錯」,§6 加案例 11。
  - **F4 [minor]**:§2 改述 vault 偵測直接用 `_vault_in` 回傳路徑,`docs/<slug>-knowledge/` 僅示例(涵蓋 `docs/knowledge`)。
  - **F5 [minor]**:§4 第 2 條註明 CLAUDE.md 注入為條件式(`_scaffold_project:3166`),deinit 對應 no-op。
  - **F6 [minor]**:§5 明述 `_vendor_toolchain` 清單 = 固定 5 檔 + hooks/templates rglob 動態展開。
  - **F7 [minor]**:§2 明定 git config/status 一律 `git -C root`。
  - **F9 [minor]**:§5 改述 `_VENDORED_TOOLKIT` 需「小幅重構 `_vendor_toolchain` 內部」而非僅「新建」。
  - (F8 §8 溯源:r2 F4 的誤論據原文已在 r2 紀錄保留+⚠ 標注,可追溯,不另動。canary F1/F2 = `.deinit-manifest.json`,植入後移除,真檔不含。)
- **r5**(canary type a:植入「§3 step 6 補償流程」壞引用,caught):**收斂輪**,存活全 minor,已折入:
  - **scripts/ 前綴 [minor]**(辯方降 major:同段 `scripts/` 脈絡簡寫,§1/§5/code 權威):§4 第 2 條 5 檔補齊 `scripts/` 前綴。
  - **pre-flight 順序 [minor]**(辯方降 major:`return 2`+對齊 cmd_update 本質即 pre-flight,最壞一行可復原 config):§3 開頭明述 §4 第 3/4 條在 step 1 前求值。
  - **rev-parse fallback [minor]**:§2 明定非 git 目錄中止(不 fallback cwd,因 deinit 會刪檔)。
  - **行號 [minor]**:`_scaffold_project` 的 `if tpl.exists()` 引用 3166→3167。
  - **heuristic 措辭 [minor]**:§2 改述偵測對象是 target repo root、與執行檔自身無關(全域/python3 跑皆一致)。
  - **案例 10 [minor]**:§6 案例 10 改為預裝 hooks+CLAUDE 區塊,才能斷言「其餘動作確實執行」。

---

### 收斂結語(design-loop,r4+r5 連 2 輪 caught 且無 blocker/major → CONVERGED)

5 輪 canary 全 caught(type a/b/c/d/a),抓出並修掉 1 個真 blocker(`vault==root` rmtree 整 repo)、1 個真 major(root==src 引用錯函式),其餘降/折為 minor。**誠實天花板**:① 收斂只證「連 2 輪醒著的審計員沒找到 blocker/major」,不證沒有更深問題;② canary-caught / severity / 誤判三者皆由植入者自判、無外部閉合,loop 是「可觀測+摩擦+地板」非 oracle。進實作後仍需 TDD 紅燈先行驗證 §6 各案例(尤其案例 10 的 `vault==root` 鐵閘)。
