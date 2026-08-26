---
type: system
status: done
created: 2026-07-31
updated: 2026-08-03
tags:
  - type/system
  - status/done
  - risk/不可逆
summary: |-
  FLOW:`curl -fsSL <raw-url>/get.sh | bash` → 檢查 `git` 存在(找不到→清楚錯誤訊息+rc2,不留 traceback) → `~/.lumos-slim` 已是合法 git repo(有 `.git`)→ `git pull --ff-only`(冪等更新)｜已存在但非 git repo→拒絕、rc2、印訊息｜不存在→`git clone` 首次安裝 → 檢查 `install.sh` 存在 → 執行 `~/.lumos-slim/install.sh "$@"`(額外參數如 `--force` 原樣轉發)
  KEY:★INVARIANT★ 三支 `.ps1` 必須是 ★ASCII-only 且不加 BOM★(2026-08-03 Windows 真機★回歸★測試推翻了前一版的「必須加 BOM」)——★BOM 是兩難不是解法★:無 BOM → 磁碟執行時 PowerShell 5.1 用系統 ANSI codepage 讀,DBCS 前導位元組吃掉下一個位元組、撞壞引號配對(CJK 語系 parse error、什麼都沒裝);有 BOM → `irm | iex` 收到的是★普通字串★,PowerShell 不會替它剝 BOM,`U+FEFF` 成了第 1 行內容、那行註解被當成指令執行。v1.4 只是把問題從前者搬到後者,而★後者正是 README 唯一教的入口★。正解=消滅問題:ASCII-only 之後兩條路徑都不需要 BOM。中文設計說明搬 `slim/WINDOWS-NOTES.md`。★這條紀律組織內部早就有★——LandmarkMember 的 CLAUDE.md〈Deploy 腳本踩雷規則〉第 1 條「ASCII-only 規則」,理由一字不差,且是踩了三輪 prod deploy 失敗才立的;★我設計這幾支檔案時沒去查過,那正是 CLAUDE.md 第一條「架構圖先行」要防的★ [test:t_slim_ps1_ascii_only_no_bom,t_slim_ps1_real_parser_accepts_both_execution_paths](★獨立審計首輪判「不 legal」——不是道理不對,是★決定當時還沒進 git、而 HEAD 上的 code 正好相反★;另指出 .gitattributes 仍寫著舊的「必須加 BOM」、WINDOWS-NOTES.md 有斷鏈引用、verified_by 仍指向記錄舊設計的節點。四條殘留全部處理後才留痕★) [audit:sonnet/2026-08-03]
  KEY:★INVARIANT★ 三支 `.ps1` 的 `param()` ★不得使用保留名 `$Args`★(2026-08-03 Windows 真機回歸測試抓到,★非 v1.4 引入、是前一版包函式時就在的★)——`$Args` 是 PowerShell ★自動變數★(該函式自己「未綁定的參數」),會蓋掉呼叫端傳進來的值,於是 `@Args` splatting 展開成★空★,`--force`／`--here`／`-y` ★全部靜默失效★(實測:加了 --force 仍印「已存在,加 --force 覆寫」)。改用 `$ScriptArgs` 之類的非保留名。★前一份真機回報沒抓到,是因為當時沒傳過任何參數——「沒人用過的路徑不會有人回報」是真的盲區★ [test:t_slim_ps1_args_param_not_shadowed_by_automatic_variable,t_ps1_args_shadowing_is_real_language_behavior](★審計員自行 `brew install powershell` 實測重現:`param($Args)` count=0、`$ScriptArgs` count=2;本專案長期掛的「沒有 PowerShell 驗不了」對這條★是錯的★★) [audit:sonnet/2026-08-03]
  KEY:★`&` 呼叫外部程式必須接 `| Out-Host`★——PowerShell 函式的 `return` 會帶出函式內所有未被消費的輸出,`&` 的 stdout 沒被指派就進了輸出流,`return $LASTEXITCODE` 再追加一個數字 → 呼叫端收到 ★Object[]★ 不是數字,實測 `SetShouldExit` 直接爆。★`$code = $LASTEXITCODE; return $code` 解決不了★(問題在 `&` 的 stdout 進了輸出流,不是 return 的寫法) [test:t_slim_ps1_subprocess_output_does_not_pollute_return]
  KEY:★`get.ps1` 的 `git clone` 漏檢 `$LASTEXITCODE`(2026-08-02 對照實驗抓到,已修)★——同一個 `Invoke-Get` 函式裡,`git pull` 那一支有檢 `$LASTEXITCODE`、`git clone` 那一支沒有,純粹是漏寫的不對稱。★不能靠 `$ErrorActionPreference = "Stop"` 兜底★:它只管 PowerShell cmdlet,原生執行檔(git.exe)回非零 exit code **不會**觸發終止(PS 7.3 起的 `$PSNativeCommandUseErrorActionPreference` 才改這行為,而本包要支援 Windows PowerShell 5.1)。漏掉的後果不是「靜默失敗」而是★把使用者帶去錯的方向★:clone 失敗(沒網路/私有 repo 沒權限/磁碟滿)後照樣往下走,下一段 `Test-Path $InstallScript` 判假,使用者看到的是「交付包內容可能不完整」——網路/權限問題被誤導成「這個包壞掉了」。修法=clone 後補 `$LASTEXITCODE -ne 0` → 講網路與存取權限的訊息 + return 2。★守的是對稱性不是行為★:綁定測試 `t_slim_get_ps1_every_git_call_checks_lastexitcode` 掃「每個行首 git 呼叫後幾行內要有 `$LASTEXITCODE`」,屬 [[Systems/測試假綠形態]] 第③型(驗寫法不驗行為)且★刻意如此★——開發機是 macOS 沒有 PowerShell,一行 ps1 都跑不了;它買到的是「新增 git 呼叫時不會忘了配一道檢查」,★不得因為它綠了就宣稱 get.ps1 在 Windows 上正確★(已知限制:管線中段的 git 抓不到)
  KEY:★固定落點理由★——舊版 [[Systems/slim-install-安裝器]] 用 `$(dirname "$0")` 定位自身;透過 `curl | bash` 執行時 `$0` 是 bash 本身/`/dev/stdin`,沒有穩定檔案位置可定位。固定 `~/.lumos-slim` 給包一個穩定的家,也讓 [[Systems/slim-uninstall-一行卸載]] 有東西可以拿來做 sha256 內容比對(見該節點的硬合約)
  KEY:★冪等的精確定義★——「不炸」指的是不出現 `git clone` 對非空目錄的爆炸式錯誤(`already exists and is not an empty directory`)。第二次執行呼叫到的 `install.sh` 仍有自己既有的碰撞保護(未帶 `--force` 時偵測到 `~/.local/bin/lumos` 已存在會拒絕、rc2)——這是 install.sh 既有的、刻意的安全行為,不是 get.sh 冪等性的破口;`get.sh` 本身把 `--force` 原樣轉發即可讓使用者一次到位重跑
  KEY:與本 repo 根目錄既有的 `get.sh`/`get.ps1`(完整版 Lumos 遠端一鍵裝,clone `citrus-android-developer/Citrus_Lumos_Full` 後委派 `bootstrap`,見 [[Systems/lumos-cli-lifecycle]])是**兩支獨立腳本、不同交付對象**——本節點記的是 `slim/get.sh`,目標 repo 是精簡版交付庫 `citrus-android-developer/Citrus_Lumos`,只做「clone/更新+執行 install.sh」兩件事,不含 bootstrap 的專案層四分流/`_confirm_tty`/hooks 接線等機器層以外的邏輯——★這是刻意的功能子集,不是殘缺★
  KEY:`REPO_URL` 可用環境變數 `LUMOS_SLIM_REPO_URL` 覆蓋(測試用,指向本地 git repo 路徑避免打真網路);生產預設寫死 GitHub URL,不吃命令列參數覆蓋(降低被誤導向惡意 repo 的攻擊面)
  KEY:★2026-08-01 補追加 Task 13——新增 Windows 對應腳本 slim/get.ps1,slim/get.sh 本身邏輯不變★:`slim/get.sh` 呼叫的 `install.sh` 從「承載全部邏輯」改成「薄殼轉發給 `install.py`」(見 [[Systems/slim-install-安裝器]]),但 `get.sh` 自己的 clone/pull/檢查/呼叫邏輯完全沒動——它本來就只負責「把套件放到固定落點+呼叫 install.sh」,install.sh 內部怎麼實作跟它無關。新增 `slim/get.ps1` 逐步對照翻譯同一套邏輯(clone/pull 到 `$HOME\.lumos-slim` → 呼叫 `install.ps1`),先例正是本節點 KEY 行(上)提到的本 repo 根目錄完整版 `get.ps1`(12 行,直接把工作丟給 python)——★這台機器沒有 Windows/PowerShell,`get.ps1` 沒有真機驗證過★,只是逐行對照 `get.sh` 翻譯,見 [[Verification/2026-08-01_slim-python移植]] 的誠實標記。
  KEY:(★2026-08-01 Task 14 修復③,保險性修法,★這段語意本身未在真機驗證★,與 [[Systems/slim-install-安裝器]] 的 `install.ps1` 同批同款理由)`get.ps1` 收尾原本是裸的 `exit $LASTEXITCODE`——`get.ps1` 正是 README 一行版 `irm ... | iex` 直接執行的那支腳本,`exit` 在這種呼叫方式下最容易把使用者當下開著的 PowerShell 視窗整個關掉,改成 `$global:LASTEXITCODE = $LASTEXITCODE`,不再呼叫 `exit`。這台機器沒有 PowerShell/git-for-Windows,只做了靜態結構檢查 [test:t_slim_ps1_scripts_avoid_session_killing_trailing_exit](非真機驗證)。詳見 [[Verification/2026-08-01_slim-windows兩缺陷修復]]
  KEY:(★2026-08-01 Task 15,補殘留風險,★這段語意本身仍未在真機驗證★,與 [[Systems/slim-install-安裝器]] 同批同款理由)`get.ps1` 早期 4 處錯誤分支的裸 `exit 2`(找不到 git、`git pull` 失敗、目的地已存在但非本包 clone、`install.ps1` 缺失——Task 14 收尾修復時刻意收窄未動,這支腳本正是 `irm ... | iex` 一行版直接執行的那支,踩到機率最高)全部改成邏輯包進 `Invoke-Get` 函式、印完 `Write-Error` 後各自 `return 2`,腳本最下方把函式回傳值收進 `$rc` 再寫回 `$global:LASTEXITCODE`。反向斷言 [test:t_slim_ps1_error_branches_still_halt_via_return](驗「每處錯誤訊息後緊接 return,不是被拆成不擋往下繼續跑」,`get.ps1` 4 個分支逐一驗)。詳見 [[Verification/2026-08-01_slim-ps1早期分支exit修復]],報告 `.superpowers/sdd/公開精簡版_實作計畫/task-15-report.md`
  KEY:(★2026-08-01 Task 16 修復①③,分支終審抓到,兩條都是本檔案的真缺陷,不是只做一致性處理★)①BLOCKER,同批同款理由見 [[Systems/slim-install-安裝器]]:`get.ps1` 頂部 `$ErrorActionPreference = "Stop"` 讓 4 處 `Write-Error` 全部變終止型例外,`return 2` 執行不到、`Invoke-Get` 被例外炸穿、`$global:LASTEXITCODE` 永遠寫不進去——`get.ps1` 正是 `irm ... | iex` 一行版直接執行的那支,踩到機率最高。修法:4 處 `Write-Error` 都加 `-ErrorAction Continue` 明確覆寫。②③MINOR,★這條是本檔案獨有的真缺陷,不是跟 install.ps1/uninstall.ps1 一樣的一致性處理★:`$ErrorActionPreference = "Stop"` 原本寫在頂層(函式外)——README 教的一行安裝 `irm ... | iex` 中,`iex` 在**呼叫端當下的 scope** 執行(不像 `& "path.ps1"` 會建新 script scope),這行會直接改到使用者互動 shell 的設定且裝完不還原,同一視窗裡任何原本靠非終止型錯誤運作的後續指令都會被意外中止、使用者不知道原因是「剛剛裝了個東西」。修法:把賦值搬進 `Invoke-Get` 函式內部第一行——PowerShell 函式預設有自己的子 scope,函式內賦值(無 `$global:`/`$script:` 前綴)只落在函式自己的 local scope,不外溢回呼叫端;`Invoke-Get` 已涵蓋本檔案所有用到非終止型錯誤語意的邏輯,搬進去不影響行為。[test:t_slim_ps1_write_error_noterminating_under_stop_preference](靜態結構檢查,驗得到「Write-Error 本行有無 -ErrorAction Continue」這種寫法,驗不到 PowerShell 真實執行語意,見該測試 docstring 誠實邊界)。★這兩段語意本身仍未在真機驗證——尤其③的 scope 隔離語意,這台機器沒有 PowerShell,無法實際驗證 `iex` 執行下函式內賦值真的不會外溢回呼叫端 session★。詳見 [[Verification/2026-08-01_slim-終審三缺陷修復]],報告 `.superpowers/sdd/公開精簡版_實作計畫/task-16-report.md`
  DEP:slim/get.sh｜slim/get.ps1(新增,Windows 對應)｜slim/install.sh(被呼叫執行)｜slim/install.ps1(新增)｜scripts/test_lumos.py t_slim_get_idempotent｜t_slim_get_no_git
  TEST:t_slim_get_idempotent 7 checks 全綠——首次執行 rc0(git clone 到位)、第二次執行不出現 clone 式爆炸訊息且 stderr 無 traceback、`.git` 目錄未被破壞、帶 `--force` 轉發給 install.sh 可完整跑完 rc0;t_slim_get_no_git 3 checks 全綠——限縮 `PATH` 模擬 git 缺失,斷言 rc2+清楚錯誤訊息(非 traceback)+`~/.lumos-slim` 未被建立(`python3 scripts/test_lumos.py -k slim_get`)
related:
  - "[[Systems/slim-install-安裝器]]"
  - "[[Systems/slim-uninstall-一行卸載]]"
verified_by:
  - "[[Verification/2026-07-31_公開精簡版一行安裝卸載與代碼審修復]]"
  - "[[Verification/2026-08-01_slim-python移植]]"
  - "[[Verification/2026-08-01_slim-windows兩缺陷修復]]"
  - "[[Verification/2026-08-01_slim-ps1早期分支exit修復]]"
  - "[[Verification/2026-08-01_slim-終審三缺陷修復]]"
  - "[[Verification/2026-08-02_slim三缺陷修復_實驗產出]]"
  - "[[Verification/2026-08-03_Windows回歸測試三缺陷]]"
  - "[[Verification/2026-08-03_Windows真機三輪驗證通過]]"
---
# slim-get-一行安裝

公開精簡版的一行安裝入口(`slim/get.sh`)。解決 [[Systems/slim-install-安裝器]] 原本「必須先手動拿到交付包才能跑 `install.sh`」的問題:`curl -fsSL <raw-url>/get.sh | bash` 把交付包 clone 到固定落點 `~/.lumos-slim`,再自動執行包內的 `install.sh`。已存在時走 `git pull` 冪等更新,不會對非空目錄硬 `git clone` 炸掉;`git` 指令本身不存在時給清楚錯誤訊息而非 Python/bash traceback。詳見 [[Projects/公開精簡版_實作計畫]] Task 6(一行安裝／卸載)。

固定落點 `~/.lumos-slim` 同時是 [[Systems/slim-uninstall-一行卸載]] 判斷「`~/.local/bin/lumos` 是不是我們裝的那份」的比對基準——兩支腳本靠這個路徑耦合,改動路徑常數要兩邊同步。
