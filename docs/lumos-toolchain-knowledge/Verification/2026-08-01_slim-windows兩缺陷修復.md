---
type: verification
status: pass
date: 2026-08-01
valid_under: "分支 main;slim/install.py 現行版本(_pick_windows_interpreter() 直譯器 fallback、碰撞偵測同時看 dst_shim);slim/install.ps1、slim/uninstall.ps1、slim/get.ps1 現行版本(收尾用 $global:LASTEXITCODE = $LASTEXITCODE,不呼叫裸 exit)。★Windows 分支僅靠 LUMOS_SLIM_SIMULATE_WINDOWS=1 環境變數注入驗過分支邏輯與靜態結構,shutil.which() 真實 Windows PATH 解析行為與 .ps1 的 exit 語意修法完全沒有真機驗證★,見下方〈測不到什麼〉"
revalidate_when: "改動 install.py 的 _pick_windows_interpreter()/_install_cli() 碰撞偵測、改動三支 .ps1 的收尾寫法、或未來真的拿到 Windows 機器做真機驗證後(屆時要把本節點與 slim/README.md 的『未驗證』標記一併更新,不能讓已驗證的部分繼續掛著誠實標記)"
tags:
  - type/verification
  - status/pass
plan_refs:
  - "[[Projects/公開精簡版_實作計畫]]"
summary: |-
  TEST:`python3 scripts/test_lumos.py -k slim` 272 checks 全綠(新增 4 支 t_slim_* 函式:`t_slim_install_windows_shim_does_not_hardcode_python_when_only_python3_available`、`t_slim_install_windows_collision_detects_orphan_cmd_shim`、`t_slim_ps1_scripts_avoid_session_killing_trailing_exit`;既有 268 checks 零鬆動)。前兩支均實測過「紅→綠」:`git stash` 只還原 `slim/install.py` 重跑,兩支測試各自對應斷言確實翻紅(shim 寫死 `python`/孤兒 `lumos.cmd` 被無聲覆寫),回補修復後轉綠,非稻草人。
  VERIFY:[[Systems/slim-install-安裝器]]、[[Systems/slim-uninstall-一行卸載]] 的 Windows 專屬缺陷修復——①`.cmd` shim 不再寫死呼叫字面 `python`,改成安裝當下偵測可用直譯器寫進 shim ②Windows 路徑碰撞偵測同時看 `lumos` 與 `lumos.cmd`,不再只看前者 ③三支 `.ps1` 薄殼收尾不再呼叫裸 `exit`(保險性修法,未真機驗證)。詳見報告 `.superpowers/sdd/公開精簡版_實作計畫/task-14-report.md`。
---
# 2026-08-01_slim-windows兩缺陷修復

## 背景

精簡版交付包一次性交給離職接手者,`.sh`/`.ps1` 都是薄殼,真正邏輯在 `slim/install.py`(Windows 支援見 [[Systems/slim-install-安裝器]])。這台開發機是 macOS,沒有 PowerShell,Windows 路徑無法真機驗證——本輪修法盡量靠「結構正確」而非「跑起來看看」,能寫紅→綠回歸測試的一定寫,不能真機驗證的地方誠實標記,不包裝成已解決。

## ①(major)`.cmd` shim 寫死 `python`,與安裝器自己的 fallback 不一致

`install.py` 舊版 `_install_cli()`:`shim_text = '@echo off\r\npython "%~dp0lumos" %*\r\n'`——寫死字面 `python`。但同專案 `install.ps1`(先試 `python3`,找不到才退 `python`)與 `install.sh`(`for cand in python3 python`)兩支薄殼都承認 `python` 可能不存在。

**失敗場景**:Windows 上只有 `python3.exe`(沒有 `python.exe`)的機器——`install.ps1` 用 `python3` 成功跑完安裝、印出「裝好了」,但產生的 shim 寫死呼叫 `python`,之後每次打 `lumos` 都得到 `'python' is not recognized`。裝完即壞,且要等使用者真的執行才會發現,不會在安裝當下就報錯。

**修法(選了「安裝當下偵測」,不是「shim 內 runtime fallback」)**:新增 `_pick_windows_interpreter()`,依序 `shutil.which("python3")`/`shutil.which("python")`,把偵測到的**命令名稱**(不是 `sys.executable` 的絕對路徑)寫進 shim。

**取捨(為什麼寫名稱不寫絕對路徑)**:`sys.executable` 在真機 Windows 上其實就是 `install.ps1` 用 `Get-Command` 解出的那支具體 exe 絕對路徑,直接烤進 shim 看似「當下已驗證存在」最穩;但 Windows 常見的 python 版本管理方式(pyenv-win、winget/choco 升級)經常是「换一支新 exe、搬動安裝目錄」而不是原地替換同一路徑,絕對路徑撐不過這類升級。命令名稱(`python3`/`python`)通常穩定掛在 PATH 上,版本管理工具本身的職責就是讓這兩個名字持續可用,而且與另外兩支薄殼的判斷邏輯語意一致(三處判斷不漂移)。

**為什麼不選「shim 內 runtime fallback」(如 `where python3 >nul 2>nul` 判斷)**:精簡版一貫的薄殼哲學是盡量單純(現行 shim 只有一行呼叫),安裝當下 Python 環境已經知道答案,沒必要把偵測邏輯複製一份進批次檔語法(較難讀、較難維護,牴觸〈公開精簡版計劃〉「接手者改得動」的核心價值主張),且 runtime fallback 每次呼叫 `lumos` 都要多一次 `where` 查詢開銷。

紅→綠測試:`t_slim_install_windows_shim_does_not_hardcode_python_when_only_python3_available`——用自製 `python3` stub(`exec` 真正的直譯器)組一個 PATH 上保證只有 `python3`、沒有 `python` 的環境(不依賴宿主機器巧合沒裝 `python`),模擬 Windows 安裝後精確比對(非子字串)shim 裡的直譯器詞恰好是 `python3`。修復前對此 fixture 跑會產生 `python "%~dp0lumos" %*`,斷言「不是寫死字面 python」翻紅;修復後轉綠。

## ②(minor,同一處)碰撞偵測只看 `lumos`、沒看 `lumos.cmd`

`_install_cli()` 舊版 `collided = dst_script.exists() or dst_script.is_symlink()`——若 `lumos.cmd` 單獨殘留(使用者手動刪了 `lumos` 忘了刪 `.cmd`),非 `--force` 重裝時 `collided` 判成假,直接跳過碰撞保護、**無聲覆寫**殘留的 `lumos.cmd`,繞過「碰撞需要 `--force`」這條保護的存在意義。

修法:Windows 路徑下 `collided` 同時看 `dst_script`(`lumos`)與 `dst_shim`(`lumos.cmd`),任一存在都算碰撞;unlink 時分別判斷各自是否存在再刪,不假設兩者同時在。警告訊息在 Windows 路徑下同時列出兩個檔名。

紅→綠測試:`t_slim_install_windows_collision_detects_orphan_cmd_shim`——只放殘留的 `lumos.cmd`(內容可辨識的假字串),不放 `lumos`,跑一次不帶 `--force` 的模擬 Windows 安裝。修復前:rc0、殘留內容被直接覆寫成新 shim 內容(親眼實測 `git stash` 只還原 `install.py` 重跑,三條斷言中兩條翻紅)。修復後:rc 非 0、殘留內容位元組級不變、且帶 `--force` 仍能正常覆寫成功(對稱驗證,防修過頭變成「Windows 上 --force 也救不了」)。

## ③(major,保險性修法)`.ps1` 結尾的 `exit $LASTEXITCODE`

`install.ps1:25`、`uninstall.ps1:19`、`get.ps1:55` 三處收尾都是裸的 `exit $LASTEXITCODE`。PowerShell 的 `exit` 在 `iex`/`&` 呼叫鏈中會終止整個呼叫端 session(不像 bash 子行程只結束自己),而 README 教的兩種呼叫方式都會踩到——一行版 `irm ... | iex`、兩行版 `& "$HOME\.lumos-slim\install.ps1"`。

**失敗場景**:使用者貼上 README 的指令,安裝其實成功了,但畫面印完「裝好了」之後整個 PowerShell 視窗突然關閉,會被誤以為是崩潰。

**修法**:三處收尾都改成 `$global:LASTEXITCODE = $LASTEXITCODE`(不再呼叫 `exit`)——`$LASTEXITCODE` 是 PowerShell 的特殊自動變數,寫入即對呼叫端可見,呼叫端仍可 `& install.ps1; if ($LASTEXITCODE -ne 0) {...}` 讀到正確值,同時不會主動終止 session。

**取捨(未在 README 教的呼叫方式下的已知限制)**:若改用 `powershell.exe -File install.ps1` 這種「當成獨立行程啟動」的方式呼叫(README 沒教這種呼叫法),因為腳本本身不再呼叫 `exit`,回給作業系統的行程 exit code 會固定是 0,不會反映失敗。README 教的兩種呼叫方式都是在同一個 session 內執行(不是啟動新行程),不受此取捨影響。

**★誠實限制,不包裝成已解決★**:這台機器沒有 PowerShell,無法驗證這段語意——推理上這個改法不會再主動關掉呼叫端視窗,但 `exit` 在 PowerShell 各種呼叫路徑(`&`/`iex`/dot-source/`-File`)下的精確行為差異、`$LASTEXITCODE` 在這些路徑下是否確實對呼叫端可見,都需要真機驗證才能下定論。三支 `.ps1` 檔案本身的註解與 `slim/README.md` 都同步標了這條未驗清單。

**範圍刻意收窄**:三支 `.ps1` 內仍有幾處**早期分支**的 `exit 2`(如「找不到 python3/python」「找不到 git」等錯誤守衛)未動——這些理論上有同款的 session 終止風險,但不在本次 task 明確列出的三個行號範圍內,故本輪未觸碰,列為已知殘留風險(見下方〈仍未在真機驗證 / 已知殘留風險〉)。

測試(靜態結構檢查,非真機驗證):`t_slim_ps1_scripts_avoid_session_killing_trailing_exit`——斷言三支檔案的**程式碼行**(排除註解行,避免被修復說明自己的文字誤觸發)不再含裸的 `exit $LASTEXITCODE` 收尾、仍把 rc 寫回 `$LASTEXITCODE`、且都留有「未在真機驗證」的誠實聲明字樣。

## 怎麼驗證的

- `python3 scripts/test_lumos.py -k slim`:272 checks 全綠。
- ①②兩條均實測「紅→綠」:`git stash push -- slim/install.py` 只還原該檔、重跑對應測試確認翻紅,`git stash pop` 拿回修復後版本確認轉綠。
- `scripts/slim-gen.py` 重新生成 `dist/`,確認 10 個入口檔(`install.{sh,py,ps1}`/`uninstall.{sh,py,ps1}`/`get.{sh,ps1}`/`README.md`/`claude-block.md`)全在、三支 `.sh` 保留可執行位元。
- 架構圖同步:[[Systems/slim-install-安裝器]]、[[Systems/slim-uninstall-一行卸載]] 補上對應 ★INVARIANT★/KEY 行與 verified_by。

## 仍未在真機驗證 / 已知殘留風險

- `shutil.which()` 對真實 Windows PATH(含 `PATHEXT`)的解析行為——邏輯層級已驗,PATH 真實生效方式未驗。
- 三支 `.ps1` 收尾改法(`$global:LASTEXITCODE`)在真實 PowerShell 各種呼叫路徑下是否確實不終止 session、rc 是否確實對呼叫端可見——完全沒有真機驗證。
- 三支 `.ps1` 內**早期分支**的 `exit 2`(python/git 找不到等錯誤守衛)理論上有同款 session 終止風險,本次未觸碰,留作已知殘留風險。
- `.cmd` shim 在真實 `cmd.exe`/PowerShell 下能不能被正確找到並執行——與既有的 Windows 未驗清單相同,未擴大也未縮小。
