---
type: verification
status: pass
date: 2026-08-01
valid_under: "分支 main;slim/install.ps1、slim/uninstall.ps1、slim/get.ps1 現行版本——早期錯誤分支(找不到 python3/python、找不到 git、git pull/clone 失敗、交付包不完整,共 6 處)的邏輯已包進 Invoke-Install/Invoke-Uninstall/Invoke-Get 函式,錯誤時 return <int> 而非 exit,呼叫端把函式回傳值收進 $global:LASTEXITCODE。★這台機器沒有 PowerShell,PowerShell 真實執行語意完全沒有真機驗證★,見下方〈仍未在真機驗證 / 已知殘留風險〉"
revalidate_when: "改動三支 .ps1 的函式結構/return 分支、或未來真的拿到 Windows 機器做真機驗證後(屆時要把本節點、[[Verification/2026-08-01_slim-windows兩缺陷修復]]、slim/README.md 的『未驗證』標記一併更新,不能讓已驗證的部分繼續掛著誠實標記)"
tags:
  - type/verification
  - status/pass
plan_refs:
  - "[[Projects/公開精簡版_實作計畫]]"
summary: |-
  TEST:擴充 `t_slim_ps1_scripts_avoid_session_killing_trailing_exit`(斷言範圍從只看結尾 `exit $LASTEXITCODE` 擴大成三支 `.ps1` 程式碼行完全不含裸 `exit`)+ 新增 `t_slim_ps1_error_branches_still_halt_via_return`(反向斷言:每處 Write-Error 後緊接 return <int>、邏輯確實包進 function、回傳值確實被外層變數接住並寫回 $global:LASTEXITCODE)。`python3 scripts/test_lumos.py -k slim` 290 checks 全綠(`-k slim_ps1` 單看這兩支測試 27 checks 全綠)。紅→綠實測:改測試後、動 .ps1 前先跑過一次(`-k slim_ps1`),24 checks 中 15 個翻紅(擴大後的裸 exit 斷言+反向斷言因函式/return 都不存在而紅),改完三支 .ps1 後轉綠(總數變 27,因為函式回傳值真的被接住那 3 條子斷言此時才會被跑到);另外用 mutant(刻意把某個 return 2 拿掉、讓錯誤分支印完訊息後直接落到下一行的 `}`)重跑反向斷言測試,確認會抓到「守衛被拆成不擋」這個失敗模式(mutant 立即還原,未進 commit)。
  VERIFY:[[Systems/slim-install-安裝器]]、[[Systems/slim-uninstall-一行卸載]]、[[Systems/slim-get-一行安裝]] 補完 [[Verification/2026-08-01_slim-windows兩缺陷修復]] ③ 刻意收窄留下的殘留缺陷——三支 `.ps1` 早期錯誤分支的裸 `exit 2`(共 6 處:install.ps1 1 處/uninstall.ps1 1 處/get.ps1 4 處)全部改成函式內 `return <int>`,呼叫端統一收進 `$global:LASTEXITCODE`。詳見報告 `.superpowers/sdd/公開精簡版_實作計畫/task-15-report.md`。
---
# 2026-08-01_slim-ps1早期分支exit修復

## 背景

[[Verification/2026-08-01_slim-windows兩缺陷修復]] ③修了三支 `.ps1`(`install.ps1`/`uninstall.ps1`/`get.ps1`)**結尾**的裸 `exit $LASTEXITCODE`,但當時明確「範圍刻意收窄」,留下一句「三支 `.ps1` 內仍有幾處早期分支的 `exit 2`……本次未觸碰,列為已知殘留風險」。這批殘留正是**早期錯誤分支**的 `exit 2`——找不到 python(`install.ps1:34`/`uninstall.ps1:20`)、找不到 git/clone 失敗/交付包不完整(`get.ps1:36,44,48,57`)。這些反而比結尾那個更該修:它們全在錯誤路徑上,使用者最需要看到錯誤訊息的時候,`exit` 若真的終止呼叫端 session,視窗直接被關掉,連錯在哪都來不及讀——README 教的兩種呼叫方式(`irm ... | iex`、`& "$HOME\.lumos-slim\install.ps1"`)都會踩到。

## 修法

三支檔案的邏輯都包進一個函式(`Invoke-Install`/`Invoke-Uninstall`/`Invoke-Get`):
- 每個原本 `exit 2` 的錯誤分支,改成印完 `Write-Error` 後 `return 2`——PowerShell 裡函式本體內的 `return` 直接結束整個函式(不是只結束當下的 if/elseif 區塊),不會像 `exit` 那樣終止呼叫端 session,同時保證該分支之後真正的安裝/卸載/clone 動作不會被跑到。
- 正常路徑結尾同樣 `return $LASTEXITCODE`(子行程的 rc),延續 Task 14 選定的慣例。
- 腳本最下方呼叫函式、把回傳值收進 `$rc`,再寫回 `$global:LASTEXITCODE`(供呼叫端在同一 session 內讀取)。

三支檔案 6 個 `exit 2` 全部改法一致:
- `install.ps1`:找不到 python3/python → `return 2`
- `uninstall.ps1`:找不到 python3/python → `return 2`
- `get.ps1`:找不到 git / `git pull` 失敗 / 目的地已存在但不是本包 clone / `install.ps1` 缺失(交付包不完整)→ 各自 `return 2`

## 測試

**★誠實限制★**:這台機器沒有 PowerShell,只能做靜態結構驗證,不能驗真實執行語意。

1. 擴充 `t_slim_ps1_scripts_avoid_session_killing_trailing_exit`——斷言範圍從「只看結尾那個 `exit $LASTEXITCODE`」擴大成「三支 `.ps1` 的程式碼行(排除註解行)完全不含任何裸 `exit`」,涵蓋這 6 處早期分支。
2. 新增反向斷言 `t_slim_ps1_error_branches_still_halt_via_return`——驗的是「拔掉 exit 之後,守衛有沒有被順手拆成不擋」:每一處 `Write-Error`(程式碼行)緊接著的下一行程式碼必須是 `return <整數>`;另外檢查邏輯確實包進 `function`、函式回傳值確實被外層變數接住並寫回 `$global:LASTEXITCODE`。3 支檔案共驗到 6 個 `Write-Error`→`return` 配對(install.ps1 1、uninstall.ps1 1、get.ps1 4),數量寫死斷言,避免漏改或多算。
   - **驗得到**:原始碼結構上「錯誤訊息後面緊接著就是 `return`,不是繼續往下的其他陳述式」。
   - **驗不到**:PowerShell 真實執行語意——這個 `return` 實際執行時是否真的結束整個函式(而非某個巢狀 scriptblock/迴圈——本次改法的函式本身沒有這種巢狀,但這條測試不是靠追蹤大括號配對驗證這件事,是靠人工確認結構後寫死的正則)、函式呼叫鏈與 `$LASTEXITCODE`/`$global:LASTEXITCODE` 在 PowerShell 各種呼叫路徑(`&`/`iex`/dot-source)下是否真的對呼叫端可見,都需要真機驗證。
3. 紅→綠實測:先擴充測試(code 尚未改),跑 `python3 scripts/test_lumos.py -k slim_ps1` 確認 24 checks 中 15 個翻紅(擴大後的裸 exit 斷言、以及反向斷言因函式/return 都不存在而紅;此時反向斷言測試因為找不到 `$var = Invoke-...` 這個模式,少算了 3 條「接住的變數有寫回 $global:LASTEXITCODE」子斷言,故此時總數是 24,不是修完後的 27);改完三支 `.ps1` 後重跑,27 checks 全綠(多出的 3 條正是函式回傳值真的被接住那 3 個子斷言)。
4. 反向斷言的殺傷力驗證(mutant,未進 commit):在 `install.ps1` 把找不到 python 那個分支的 `return 2` 拿掉(讓 `Write-Error` 印完直接落到下一行的 `}`,函式繼續往下跑),重跑 `t_slim_ps1_error_branches_still_halt_via_return`——`install.ps1 第1處 Write-Error 後緊接著 return <int>` 這條斷言確實翻紅(抓到「下一行程式碼是 `}`」),證明這條反向斷言真的能抓到「守衛被拆成不擋」這種失敗模式;驗完立刻還原,`git status --porcelain slim/install.ps1` 確認乾淨。

## 怎麼驗證的

- `python3 scripts/test_lumos.py -k slim`:290 checks 全綠。
- `scripts/slim-gen.py` 重新生成 `dist/`,確認 10 個入口檔全在,且生成後的三支 `.ps1` 同樣不含裸 `exit`。
- 架構圖同步:[[Systems/slim-install-安裝器]]、[[Systems/slim-uninstall-一行卸載]]、[[Systems/slim-get-一行安裝]] 補上對應 KEY 行,關閉 Task 14 留下的「早期分支 exit 2 未觸碰」殘留風險標記;`slim/README.md`〈支援平台〉未驗清單同步更新。

## 仍未在真機驗證 / 已知殘留風險

- 這整段修法(結尾與早期分支的 `exit`→`return`/`$global:LASTEXITCODE`)在真實 PowerShell 各種呼叫路徑下是否確實不終止 session、rc 是否確實對呼叫端可見——完全沒有真機驗證,與 [[Verification/2026-08-01_slim-windows兩缺陷修復]] 同款誠實限制,範圍擴大到涵蓋這 6 處。
- `shutil.which()` 對真實 Windows PATH 解析行為、`.cmd` shim 在真實 `cmd.exe`/PowerShell 下能不能被正確找到並執行——與既有未驗清單相同,未擴大也未縮小。
