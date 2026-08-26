# Code Review — payload-S.patch（對帳自癒排程 22:30→23:00）

## 摘要（人話）

這份 changeset 名義上是「純改一個排程時間的數字」：把「對帳假差異自癒」這個背景服務的執行時間從 22:30 挪到 23:00，給店家閉店對帳留更寬的緩衝。commit message 說「純 config，不碰自癒邏輯/合約，架構圖同步」。

實際檢查後：**config 本身改對了、行為會如預期在 23:00 執行**（appsettings.json 是唯一被讀取的來源，Production 環境沒有覆寫這個區塊，所以不會被蓋掉）。問題出在「架構圖同步」這句話不完全屬實——投稿者只改了 4 個檔案裡「主要敘述句」提到的時間，但同一份計劃文件裡另外兩處仍寫著舊的 22（不是舊排程 22:30 的殘留，是更早、根本沒被上一輪 22:00→22:30 改動同步過的殘留），以及程式碼本身的預設值/降級值、和另一支檔案的中文註解都沒跟著動。這些都不會讓服務跑錯時間（因為 appsettings.json 一定會被讀到），但構成「講的跟做的不一致」的文件債，且其中一項（程式碼裡的 fallback 常數）在特定環境設定遺失時會是真正的行為分歧點。

## 第一部分：逐檔裁決

| 檔案 | 判定 | 一句話理由 |
|---|---|---|
| `LandmarkMember.Pos/appsettings.json` | clean | Hour 22→23、Minute 30→0，JSON 語法有效，值落在服務自己的 Clamp 合法範圍（0-23/0-59）內，這是唯一真正驅動執行時間的來源，改動本身正確。 |
| `LandmarkMember.Server/Repositories/Implementations/SchedulerHeartbeatRepository.cs` | clean | 只改了心跳表顯示用的中文註解字串（22:30→23:00），不影響任何邏輯或判斷分支。 |
| `docs/landmark-knowledge/Projects/對帳假差異自癒_計劃.md` | minor | patch 只同步了文件裡 4 處提到時間的段落中的 2 處；同一份文件第 54 行、第 66 行仍寫著舊的 `Hour`(22)，與第 19/22/40/41 行的新值 23 互相矛盾，違背 commit message 聲稱的「架構圖同步」。 |
| `docs/landmark-knowledge/Verification/2026-07-16_對帳假差異自癒_lab_E2E.md` | clean | 唯一一處時間敘述已正確同步為 23:00，且驗證內容本身（lab SQL 級 E2E 4 情境）不受排程時間點影響，不需重跑。 |

## 第二部分：Findings

### F1 — 計劃文件內部自相矛盾（同一份被改動的檔案裡新舊值並存）
- **file:line**: `docs/landmark-knowledge/Projects/對帳假差異自癒_計劃.md:54` 與 `:66`
- **severity**: minor
- **具體失敗場景**: 讀者（或下一個接手的工程師/AI）打開這份計劃文件，看到開頭 summary（第 19、22 行）與「排程」小節（第 40、41 行）說「23:00 / Hour=23」，但往下讀到「配套」小節第 54 行、第 66 行的「config 全定義」清單卻寫著 `Hour(22)`——兩處對「目前正確的預設值是多少」給出互相矛盾的答案，無法單靠讀文件判斷哪個是真的，必須回頭翻 appsettings.json 才能確認。這正是 CLAUDE.md 要求「架構圖是唯一真相來源」所依賴的前提（文件內部一致）被破壞的具體案例——commit message 聲稱「架構圖同步」，但這份文件本身沒有同步完整。

### F2 — 程式碼內的 fallback 預設值與 XML 文件註解沒有跟著改，形成潛在的環境相依行為分歧
- **file:line**: `LandmarkMember.Pos/Services/ReconciliationSelfHealService.cs:50`（`Clamp(_configuration.GetValue("ReconSelfHeal:Hour", 22), 0, 23, 22, "Hour")`）、`:9`、`:12`（XML 文件註解仍寫「每日 22:00」）；另 `LandmarkMember.Pos/Program.cs:104`（註冊處註解仍寫「每日 22:00」）
- **severity**: minor
- **具體失敗場景**: `GetValue` 的第二參數（22）是「當 config 完全讀不到 `ReconSelfHeal:Hour` 這個 key 時」的內建預設值；`Clamp` 的第 4 參數（22）是「當 config 裡的值超出 0-23 合法範圍時」的降級預設值。目前因為 `LandmarkMember.Pos/appsettings.json`（base 設定檔，一定會被載入）本身就帶著 `Hour: 23`，這兩個 22 在正常部署下**不會被觸發**，服務仍會在 23:00 執行——不影響目前這次上線的行為。但若日後有人（例如未來另一個 config 整理/重構的 commit）誤刪了 base appsettings.json 裡的 `ReconSelfHeal` 區塊、或維運人員在某個環境變數/命令列覆寫傳入一個非法值（例如 `Hour=24`），服務會**悄悄降級回 22:00** 而不是這次上線後應該的 23:00，且只會在日誌留一行 `LogWarning`，不會有其他告警——這與「晚於店家 ~22:04 閉店對帳」這個本次變更的核心目的直接衝突（22:00 又會回到「當晚翻不到、拖隔天」的舊 bug）。investors 特別是投稿者自己在 commit message 裡寫「不碰自癒邏輯」，但這幾個殘留的 22 本來就是「邏輯」的一部分（fallback/降級值），只是這次沒有觸發條件，所以外部行為看不出來。

## 補充：本次未發現的問題（供讀者判斷覆蓋範圍）

- appsettings.json 改動後 JSON 語法仍合法（已用 `python3 -m json.tool` 驗證）。
- `Hour=23/Minute=0` 落在服務自身 `Clamp` 的合法範圍（0-23 / 0-59）內，不會觸發降級。
- 檢查了其他 6 支背景服務（`NonceCleanupService`／`PointReservationCleanupService`／`SecurityAnomalyMonitorService`／`PosApiAccessLogWriterService`／`PosApiAccessLogCleanupService`／`MemberTokenCleanupService`）：全部是「服務啟動後固定間隔（24h/5min/60s）」排程，不是固定時鐘點，跟 23:00 這個新的固定時間點不會有搶跑/搶鎖之類的排程衝突。
- `LandmarkMember.Pos/appsettings.Production.json`、`LandmarkMember.Server/appsettings.Production.json` 均未定義 `ReconSelfHeal` 區塊，確認 Production 環境會 fallthrough 吃到 base appsettings.json 的 `Hour=23`，不會被覆寫回舊值。
- `docs/RELEASE_LOG.md:235` 仍寫著「對帳假差異自癒服務(每日22:00)」——但這是歷史發布紀錄的既有條目（記錄當時上線時的狀態），不是本次 changeset 該同步的對象，未列入 finding。
