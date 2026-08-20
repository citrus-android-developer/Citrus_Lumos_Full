---
type: project
status: done
created: 2026-07-25
updated: 2026-08-20
tags:
  - type/project
  - status/done
related:
  - "[[Systems/lumos-cli-lifecycle]]"
  - "[[Projects/teardown一鍵拆機_計劃]]"
summary: |-
  FLAG:DECISION
  KEY:問題=拆側已有一鍵 teardown,裝側 bootstrap 卻不對稱——它只「接上已是 lumos 的專案」(step3 找不到 vendored 工具就跳過),不會把新 repo 建成 lumos 專案(那要另跑 init);get.sh(curl 一鍵)也只做機器層、尾行叫人手動 init。使用者要「一鍵建立↔一鍵解除,冪等都處理好」
  KEY:方案=bootstrap step3 升級成「專案層自動接線」四分流:①有 vault+有 vendored(已是專案)→照舊 _install_hooks_py(hooks 是 git config=每機器要重接)②有 vault 無 vendored(中間態,stdF5:_vault_in 只看名稱可能假陽性)→不自動動、印提示跑 init 補齊③無 vault(git repo)→★問一句(印完整路徑+預設N)才 auto-init★(cmd_init 完整路徑)④非 git→跳過只做機器層。get.sh 尾端改委派 bootstrap(clone 後全交它,消 install --force 雙寫)。cmd_init 呼叫契約(stdF6/F7):force=False+no_pull=True 必傳(pull 政策歸 step1)、呼叫前設 LUMOS_HOME env 傳導 --lumos-home 自訂 home(_lumos_src 既有通道)。失敗傳播(stdF8):各步查 returncode、尾端彙報、失敗最終 rc 非 0,不吞錯
  KEY:★樞紐坑:curl|bash 下 stdin=管線★——input() 綁死讀 sys.stdin,光 open('/dev/tty') 再 input() 是裝反(r1F1)。_confirm_tty 三階 v2(stdF1/F2/F3):①stdin.isatty→input(),EOFError 落入②非當 False(isatty 撒謊時別誤判拒絕)②os.open('/dev/tty',O_RDWR) 低階 fd(★r+ 開法 Darwin/Py3.14 實測炸 not seekable★)+os.write prompt+select 30s timeout+os.read(有控制終端≠有人回答,timeout 防永久掛)③皆不可→None=跳過+提示(除非 --init)。答案只認 y/yes 精確比對+預設 N(緩解 PTY 餵腳本殘文,F2-B 無完美解誠實記)。原生 Windows 靠①,console wrapper isatty=false 時用 --init 逃生
  KEY:誤建守衛=auto-init 絕不默默做——站在 dotfiles 等個人 repo 跑安裝不能被偷偷變成 lumos 專案:確認 y 才建(prompt 印完整 repo 路徑+預設 N)/--init 顯式(CI)/非互動→跳過(r1F5 誠實:get.sh 委派後職責邊界真實擴大,靠確認把關非純增益)。slug 沿 cmd_init 預設(repo basename;既有 vault slug 權威優先,init 已處理)
  KEY:冪等=①clone:已在則沿用(--pull 才拉)②install --force 本冪等③auto-init 只在無 vault 時觸發,已有 vault 走接 hooks 分支不進 cmd_init 完整路徑;--init 永不映射 force=True(r1F7:force 重跑 vendor+git pull 違背冪等),只是免確認、cmd_init 一律 force=False
  KEY:測試接縫(r1F2+stdF11/F12)=確認邏輯抽 _confirm_tty 純函式:單元層直測全三階含★第2階成功路徑★(monkeypatch os.open 假 fd 餵 y+斷言 sys.stdin 全程未被讀+select timeout→None);整合層 subprocess 用 stdin=DEVNULL+★start_new_session=True(setsid 脫離控制終端機)★——沒 setsid 則開發機上 /dev/tty 照樣開得起來掛死測試。get.sh 測試真跑 bash+假 lumos shim 斷言 argv 轉發與 exit code(grep 驗不到參數展開,stdF12)
  KEY:已知殘留(std 照出既有病,本刀不修)=F4 半成品 vault 無自癒(init 見 vault 即輕路徑不補缺)/F9 docs/knowledge與standalone 佈局 slug 反推錯致 reinject 寫錯 {{KG}} 路徑/F10 Windows get.ps1 仍兩步(本案範圍明縮 POSIX)
  KEY:範圍刀=不動 cmd_init 本體(slug/scaffold/注入邏輯全復用);不加 bootstrap --name(要自訂 slug 的用戶自己跑 init --name);get.sh 旗標解析改迴圈(現碼只比對 $1,並帶兩旗標會無聲吃掉第二個)只認 --pull/--init、未知 warn 忽略,尾端提示拿掉手動 init 教學(r1F6)
  DECISION:裝側對稱=bootstrap 升級為真一鍵(機器層+專案層 auto-init 含確認),get.sh 委派 bootstrap;顆粒指令(install/init)降級進階保留(使用者 2026-07-25「好」)
  DEP:scripts/lumos cmd_bootstrap/cmd_init/_install_hooks_py/_vault_in｜get.sh
  PRIOR-ART:①最小解=組合既有 cmd_init,bootstrap 只加分流+確認,get.sh 改委派消雙寫 ②世界解=curl|bash 裝置器問確認走 /dev/tty 是 homebrew/rustup 等的成熟慣例(borrow) ③裁定=borrow-design
verified_by:
  - "[[Verification/2026-07-25_bootstrap一鍵對稱]]"
---
# bootstrap一鍵對稱_計劃

> **狀態**：done（r1 light＋std Codex 兩審折入 → TDD 落地，見 [[Verification/2026-07-25_bootstrap一鍵對稱]]）。緣起：拆側有一鍵 `teardown`，裝側 `bootstrap` 不對稱（不建新專案、get.sh 尾行叫人手動 init）。使用者要「一鍵建立↔一鍵解除、冪等」。
> 實作與 spec 的已記偏離：測試案 2-5 合併為 `t_bootstrap_autoinit`（同覆蓋）；`_confirm_tty` 第 2 階測試接縫用 `LUMOS_TTY`/`LUMOS_TTY_TIMEOUT` env＋真 pty（非 monkeypatch os.open，等價達意）。

## 白話問題

拆機器有 `teardown` 一條指令；裝機器卻要「curl 裝機器層 → cd 專案 → 再跑 init」兩三步。bootstrap 名為一鍵，碰到還不是 lumos 專案的 repo 就兩手一攤跳過。

## 方案

### bootstrap step3 升級：專案層自動接線
| 站在哪 | 行為 |
|---|---|
| 有 vault ＋ 有 vendored 工具（已是 lumos 專案） | 照舊接 hooks（`core.hooksPath` 是 git config＝每台機器要重接） |
| 有 vault ＋ **無** vendored 工具（中間態，std F5 補列） | **不自動動**，印提示「跑 `lumos init` 補齊工具」——`_vault_in` 只看資料夾名，可能是同名非 lumos 目錄，別在誤判上疊自動動作 |
| 無 vault（git repo） | **問一句「要把 <完整路徑> 建成 lumos 專案嗎？[y/N]」→ y 才跑 `cmd_init`**（建圖譜＋vendor＋hooks＋CLAUDE 注入） |
| 非 git repo（如家目錄） | 跳過專案層，只做機器層（同現況） |

**cmd_init 呼叫契約**（std F6/F7 釘死）：
- `cmd_init(force=False, no_pull=True)`——**`no_pull=True` 必傳**（F7：bootstrap step1 已管 pull 政策，init 內再 `git pull` 一次＝重複網路依賴＋非預期來源變動）；`force=False`（r1 F7）。
- **`--lumos-home` 傳導**（F6）：bootstrap 呼叫 `cmd_init` 前 `os.environ["LUMOS_HOME"] = str(home)`——`cmd_init` 內部 `_lumos_src()` 讀該 env var，這是不動 cmd_init 本體下的既有傳導通道；否則自訂 home 時 init 會抓錯來源（預設路徑不存在→只建 vault 不 vendor、卻印成功）。

**失敗傳播**（std F8）：bootstrap 各步 subprocess/函式回傳碼**必須檢查**——install 失敗、hooks 失敗 → 印 warn、**最終 rc 非 0**（尾端彙報各步結果，同 teardown 模式）；不得吞錯照印成功（現碼 step2 subprocess.run 沒看 returncode，是既有病，本刀一併修）。

### get.sh 委派
clone 完成後整段交給 `bootstrap`（消掉 get.sh 自己跑 `install --force` 的雙寫）。**旗標解析改迴圈**（現碼 `get.sh:9` 只比對 `$1`，`--pull --init` 並帶時第二個會被無聲吃掉）：`for a in "$@"` 認 `--pull`／`--init`、未知旗標 warn 忽略；原樣轉發 bootstrap。**尾端提示同步改**（F6）：拿掉「請自己 cd 專案 && lumos init」教學（bootstrap 已代辦或已當場提示），只留「重啟 Claude Code session」。

### ★樞紐坑：`curl | bash` 的 stdin 是管線 ＋ 確認機制三階（r1 F1/F4 折入）
bash 從 stdin 讀腳本 → python 繼承同一條管線 → 直接 `input()` 會把**腳本殘文當使用者回答**（或 EOF）。**且注意（F1）：`input()` 綁死讀 `sys.stdin`——光 `open('/dev/tty')` 再呼叫 `input()` 是裝反的（白開，照樣讀管線）**；要走 tty 必須**對 tty 檔案物件自己 write(prompt)＋readline()**，不經 `input()`。

確認函式 `_confirm_tty(prompt) -> True/False/None` **三階判定 v2**（std Codex F1/F2/F3 折入）：
1. `sys.stdin.isatty()` → 走 `input()`；**`EOFError` 不當 False、改落入第 2 階**（std F2-A：isatty 撒謊但 /dev/tty 其實可用時，別把「讀不到」誤判成「拒絕」）。
2. 嘗試 **`os.open('/dev/tty', os.O_RDWR)` 低階 fd**——★不可用 `open('/dev/tty','r+')`★（std F1 實測：Darwin/Py3.14 對 tty 開 r+ 炸 `io.UnsupportedOperation: not seekable`）。`os.write(fd, prompt)`（os.write 無緩衝，免 flush 坑）＋ **`select.select([fd],[],[],30)` 帶 30s timeout 再 os.read**（std F3：排程器/`ssh -t`/容器 `-t` 有控制終端機但無人回答，readline 會永久掛死——timeout 到 → 視同 None 跳過＋提示）。開不了/timeout/讀失敗 → 下一階。
3. 皆不可 → 回 `None`＝非互動：**跳過 auto-init＋印提示**（除非帶 `--init` 顯式旗標）。
- **答案判定**：只認 `y`/`yes`（strip+lower 後精確比對）、**預設 N**——同時是 std F2-B（PTY 餵腳本時 isatty=true、input() 可能吃到腳本殘文）的緩解：殘文恰好是裸 "y" 的機率極低。誠實：F2-B 無完美解，靠嚴格答案＋預設 N 壓風險。
- 原生 Windows：無 /dev/tty，第 1 階涵蓋正常互動；console wrapper 令 isatty=false 時會被當非互動（用 `--init` 逃生），文件明示。

### 誤建守衛
站在隨便一個 git repo（dotfiles）跑安裝，不能被偷偷變成 lumos 專案：確認 y 才建（**prompt 印出完整 repo 路徑、預設 N**）／`--init` 顯式（CI）／非互動 → 跳過。（F5 誠實版：get.sh 委派後，習慣站在 dotfiles 等個人 repo 跑安裝指令的人**會被多問一句**——這是職責邊界的真實擴大，靠「顯示路徑＋預設 N」的確認把關，非零成本、非純增益。）

## 冪等
- clone：已在沿用（`--pull` 才拉）。
- `install --force`：本就冪等。
- auto-init：**只在「無 vault」時觸發**；已有 vault 走「已是專案」分支（接 hooks），不進 `cmd_init` 完整路徑。**`--init` 永不映射成 `cmd_init(force=True)`**（F7：force 會重跑 vendor＋`git pull`，違背冪等承諾）——`--init` 只是「免確認」，`cmd_init` 一律 `force=False`。重跑同結果。

## 明確不做（範圍刀）
- 不動 `cmd_init` 本體（slug 決定、scaffold、注入全復用；slug 預設 repo basename、既有 vault slug 權威優先——init 已處理）。
- 不加 `bootstrap --name`（要自訂 slug 的自己跑 `init --name`）。
- get.sh 只認 `--pull`／`--init`，不做整套參數轉發。

## 測試策略（TDD，r1 F2 重寫——tty 路徑可測性）

**可測性接縫**：確認邏輯抽成 `_confirm_tty(prompt)` 純函式，測試分兩層——
- **單元層（直測 _confirm_tty 三階）**：monkeypatch `sys.stdin`／`os.open`／`select`，不必真開終端機——**tty 被回答的路徑（含第 2 階成功）在單元層測到**（r1 F2＋std F11 主訴）；EOFError 語意＝落入第 2 階（std F2-A，詳見下方案例 1）。
- **整合層（subprocess 跑 bootstrap）**：`stdin=DEVNULL` **＋ `start_new_session=True`（setsid 真正脫離控制終端機）** → `/dev/tty` 開不了 → 走跳過分支——**沒有 setsid 的話開發機/互動 CI 上 `/dev/tty` 照樣開得起來、readline 會掛死整個測試**（F2 掛起風險，此參數是防掛的關鍵）。

案例（std F11/F12 擴充）：
1. `t_confirm_tty_unit`：單元測全三階——①假 tty stdin 餵 y/n；②**isatty=True 但 input() 拋 EOFError → 落入第 2 階（非 False）**；③monkeypatch `os.open` 假 /dev/tty fd 成功、餵 "y" → **第 2 階成功路徑**（std F11 主訴：curl|bash 唯一互動路徑必須被測到）＋斷言**過程中 sys.stdin 從未被讀**（假 stdin 物件 read 即 raise）；④os.open 失敗→None；⑤select timeout→None（monkeypatch select 回空）。
2. `t_bootstrap_autoinit_flag`：假 repo（git、無 vault）＋ `--init` → vault 建成＋hooks 接上＋CLAUDE 注入（subprocess＋假 HOME＋`LUMOS_HOME` 指真來源）。
3. `t_bootstrap_autoinit_skip_noninteractive`：無 `--init`、`stdin=DEVNULL`＋`start_new_session=True` → **不建 vault**、印提示（誤建守衛；限 POSIX，Windows skip 此案）。
4. `t_bootstrap_existing_project`：有 vault＋vendored 的 repo → 不重建 vault、hooks 接上、無提問；**中間態**（有 vault 無 vendored）→ 不動＋提示。
5. `t_bootstrap_idempotent`：`--init` 跑兩次 → 同結果不報錯、第二次不觸發 vendor/pull（驗 force=False＋no_pull=True 映射）。
6. `t_getsh_forwards_args`（std F12：grep 不夠）：**真跑 bash**——假 `LUMOS_HOME` 植入假 `scripts/lumos`（shim：把 argv 寫進檔案）→ `bash get.sh --pull --init` → 斷言 shim 收到兩旗標、未知旗標印 warn、shim 非零時 get.sh exit 非零。
（機器層 clone 需網路的部分：測試以已存在來源跳過 step1。）

## 實務隱患
- **/dev/tty 在測試環境**：互動開發機/CI runner 即使 `stdin=DEVNULL`，`/dev/tty` 仍開得起來（fd 0 重導 ≠ 脫離控制終端機）→ 整合測試必配 `start_new_session=True`，否則 readline 掛死（r1 F2）。
- **get.sh 委派後的相容**：`curl | bash` 行為改變——站在任何 git repo（含 dotfiles）跑會多一句確認（顯示路徑＋預設 N 把關）；站非 git 位置行為同舊。是職責邊界的真實擴大，非純增益（r1 F5）。
- **bootstrap 在 Lumos 來源 repo 內跑**：來源自己有 vault → 走「已是專案」路徑接 hooks，無誤建之虞。
- **原生 Windows**：無 `/dev/tty`，但第一階 `isatty→input()` 已涵蓋正常互動；`curl|bash` 情境在原生 Windows 本不存在（r1 F4）。

## 審計修正紀錄
- **r1（light，2026-07-25，canary CAUGHT）**：審計員抓到植入的「不存在章節引用」canary（判決可採信；該 finding 依溯源排除剔除，其順帶點到的 get.sh 單參數解析實情獨立成立、已折入範圍刀）。存活 2 blocker＋3 major＋1 minor 全折：
  - **F1**（blocker：`input()` 綁死 stdin，光開 /dev/tty 是裝反）→ 樞紐坑段加「必須對 tty 檔案物件 write＋readline、不經 input()」。
  - **F2**（blocker：測試沒蓋 tty 被回答路徑＋skip 測試會因 /dev/tty 仍可開而掛死）→ 測試策略重寫：抽 `_confirm_tty` 接縫、單元層測三階、整合層配 `start_new_session=True`。
  - **F4**（major：原生 Windows 無 /dev/tty；deinit 有更穩前例）→ 確認機制改三階（isatty→input+EOFError ／ /dev/tty ／ None）。
  - **F5**（major：get.sh 委派後職責邊界擴大被輕描淡寫）→ 誠實版寫回誤建守衛＋實務隱患。
  - **F6**（minor：get.sh 尾端提示過期）→ 委派段補「拿掉手動 init 教學」。
  - **F7**（major：`--init`→force 映射沒定義，force=True 會重跑 vendor+pull 破冪等）→ 冪等段釘死「`--init` 只是免確認，`cmd_init` 一律 force=False」。
  - 處置：light 挖到存活 major → **依 ratchet 升 standard**；沿本案既定模式（真遺忘/teardown 前例）走精簡 standard＝單席 Codex 跨家族複核折入後 spec。
- **std（2026-07-25，單席 Codex 跨家族）**：12 條（1 blocker＋多 major，多附 file:line；**F1 附真機實驗**——PTY 下 `open('/dev/tty','r+')` 在 Darwin/Py3.14 實測炸 `not seekable`，可執行反證>論證）。機制類全折：
  - **F1**（blocker：r+ 開 tty 目標平台不可用）→ 改 `os.open(O_RDWR)` 低階 fd＋os.write/os.read。
  - **F2**（isatty 撒謊雙向）→ EOFError 落入第 2 階非當 False；嚴格答案 y/yes＋預設 N 緩解 PTY 殘文（F2-B 無完美解，誠實記）。
  - **F3**（有控制終端≠有人回答，readline 永久掛）→ select 30s timeout → 視同 None 跳過。
  - **F6**（--lumos-home 沒傳進 cmd_init）→ 呼叫前設 `LUMOS_HOME` env（_lumos_src 既有通道）。
  - **F7**（bootstrap 不帶 --pull 但 init 內仍 pull）→ `cmd_init(no_pull=True)` 必傳。
  - **F8**（委派後吞錯：step2 沒看 returncode 照印成功）→ 各步查 rc、尾端彙報、最終 rc 非 0。
  - **F5**（_vault_in 只看名稱、假陽性上疊自動動作）→ 分流表補「中間態：有 vault 無 vendored → 不動＋提示」。
  - **F11/F12**（第 2 階成功路徑沒測／get.sh 只 grep 驗不到 argv）→ 測試案 1 擴 5 子案（含斷言 stdin 未被讀）、案 6 改真跑 bash＋argv shim。
  - **既有病記殘留（本刀不修，另見殘留節）**：F4 半成品 vault 無自癒、F9 `docs/knowledge`/standalone 佈局 slug 反推錯、F10 Windows get.ps1 仍兩步。
  - 處置：折畢進 TDD（d4：一輪 panel 抓完便宜的就走，正確性歸測試）。

## 已知殘留（std 照出的既有病，本刀不修）
- **F4**：`cmd_init` 對「vault 建到一半」（如 KeyboardInterrupt 後）無自癒——有 vault 就 early-return 輕路徑，不補缺的子目錄/gitignore。既有行為，修要動 init 本體（範圍刀外）。
- **F9**：`docs/knowledge`／standalone vault 佈局下 `cmd_init` 反推不出 slug、reinject 會把 `{{KG}}` 寫成 `docs/<repo>-knowledge/`（錯路徑）。既有行為；bootstrap 分流靠 `_vault_in` 不受此影響，但 init 輕路徑在這類佈局有此病。
- **F10**：Windows 官方入口 `get.ps1` 只做機器層＋手動 init——本案範圍明縮 **POSIX（get.sh）**，Windows 一鍵化另立。

## 結案後迭代

- **2026-08-20 鏡像安裝入口去上游耦合**([[Verification/2026-08-20_鏡像安裝入口去上游耦合]]):本計劃讓 `get.sh` 委派 `bootstrap`,但 `get.sh` 自己的 `LUMOS_URL` 仍寫死上游——對**鏡像交付庫**而言,一鍵安裝那條路等於繞過 2026-08-19 的鏡像自足(`_self_repo_origin` 只在「已有 clone」時生效)。本次把安裝入口的活路徑(get.sh/get.ps1/README/ONBOARDING/ARCHITECTURE/解析鏈第四段)一律改指本 repo。★殘留:上游單向同步會洗掉,無機械守衛,見驗證節點★。
