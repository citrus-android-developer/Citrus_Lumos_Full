# Code Review — payload-L-mid.patch (11 commits, Landmark 會員系統)

審查方式：讀完整 11 個 commit 的 diff（`-U10`），對照落地後的完整 repo 快照逐檔追蹤呼叫現場（DI 註冊、
schema migration、既有慣例、前端 `api()` helper、CSS 選擇器特異性），並實際 `dotnet build` 兩個受影響專案
（`LandmarkMember.Server`、`LandmarkMember.Pos`）驗證編譯結果（皆 0 error）。

## 第一部分：逐檔裁決

| 檔案 | 判定 | 一句話理由 |
|---|---|---|
| `LandmarkMember.Pos/Repositories/Implementations/ReconciliationRepository.cs` | clean | 對帳排除補登單的邏輯經兩次迭代收斂到「查 `InvoiceOrders.InvFlag='SUPPLEMENT'` 權威紀錄」而非僅憑 `UserID`，比對 `InvoiceSupplementRepository.InsertInvoiceOrderAsync` 的實際寫入路徑完全吻合，且 prod 驗證過（69→68）。 |
| `LandmarkMember.Server/Repositories/Implementations/EventLogRepository.cs` | clean | `SpecifyKind(Utc)` 修正精確對應 `ReconciliationLog.CreatedAt DATETIME2 DEFAULT GETUTCDATE()` 的 schema 定義，改動範圍收斂在單一方法，不誤傷其他欄位。 |
| `LandmarkMember.Server/Repositories/Implementations/CustomerRepository.cs`（`UpdateLineBindingAsync` 部分） | clean | `ISNULL(NULLIF(@RegisterSource,''),RegisterSource)` 正確處理 null 與空字串兩種情況（`NULLIF(NULL,'')` 仍為 NULL），有 prod 193 筆事故佐證且已回填。 |
| `LandmarkMember.Server/Repositories/Implementations/CustomerRepository.cs`（`GetDailyNewMemberCountsAsync`/`GetTotalMemberCountAsync` 部分） | minor | 見 finding F1：總數/每日新增未過濾 `CardStatus`/`IsBlacklist`，與同檔案其他查詢方法的既有慣例不一致。 |
| `LandmarkMember.Server/Repositories/Interfaces/ICustomerRepository.cs` | clean | 介面新增方法簽章與實作一致，型別完整限定路徑在此 namespace 巢狀結構下可正確編譯（已用 `dotnet build` 驗證）。 |
| `LandmarkMember.Server/Configuration/SmsSettings.cs` | clean | `ExpiryMinutes`/文案兩次改動（5→15→5）首尾一致，最終落地值與 revert commit 完全對齊四處同步。 |
| `LandmarkMember.Server/Controllers/Admin/AdminSmsLookupController.cs` | clean | 稽核留痕、IP 正規化（`::ffff:` 前綴轉 IPv4 避免 15 字元截斷）、狀態機優先序合理；風險（管理金鑰洩漏即可窺視任意手機 OTP）在同檔案 XML doc 已明確自陳，且與既有 `/api/admin/*` 統一金鑰風險模型一致，非本次新增風險類別。 |
| `LandmarkMember.Server/Models/DTOs/Admin/SmsLookupDto.cs` | clean | 純資料容器，欄位命名與 Controller 對應正確。 |
| `LandmarkMember.Server/Repositories/Implementations/SmsLogRepository.cs` | clean | `GetLatestByPhoneAsync` 與既有 `GetLatestUnverifiedAsync` 同 pattern。 |
| `LandmarkMember.Server/Repositories/Interfaces/ISmsLogRepository.cs` | clean | 介面新增方法與實作一致。 |
| `LandmarkMember.Server/appsettings.Production.json` | clean | 與 `SmsSettings.cs`/`appsettings.json` 最終值一致（5 分鐘，revert 後）。 |
| `LandmarkMember.Server/appsettings.json` | clean | 同上。 |
| `LandmarkMember.Server/wwwroot/admin/logs/index.html`（SMS 查詢 / 會員統計 / RWD 基礎架構） | clean | tab 切換、URL 還原（`switchTab`/`restoreUrl`/onMounted 刷新分支）三處都同步加了新 tab 的 loader，沒有漏掛；`.fit` class 用 CSS specificity（`table.fit` > `table`）正確覆蓋 mobile `display:block`。 |
| `LandmarkMember.Server/wwwroot/admin/logs/index.html`（table.fit 覆蓋範圍） | minor | 見 finding F2：同一支檔案裡結構相同（窄欄位）的既有表格未一併套用 `.fit`，RWD 覆蓋不完整。 |
| `docs/landmark-knowledge/Systems/維運儀表板.md`（各次更新） | clean | 每個 commit 的架構圖同步內容與程式碼實際改動一致，無落後或臆測。 |
| `docs/landmark-knowledge/Systems/認證與註冊.md` | clean | RegisterSource 修正的脈絡記錄完整，含事故規模與回填方式。 |
| `docs/landmark-knowledge/Systems/SMS簡訊.md` | clean | 5→15→5 兩次改動都同步記錄，最終文件與最終程式碼值一致。 |
| `LandmarkMember.Pos/appsettings.json`（ReconSelfHeal 排程） | clean | 純 config 時間调整（22:30→23:00），有 prod 實測依據；`appsettings.Production.json` 未覆蓋此 key，故繼承 base 值，行為符合預期（非本次引入的分層問題）。 |
| `LandmarkMember.Server/Repositories/Implementations/SchedulerHeartbeatRepository.cs` | clean | 純註解字串同步排程時間，無邏輯改動。 |
| `docs/landmark-knowledge/Projects/對帳假差異自癒_計劃.md` | clean | 排程時間變更同步準確。 |
| `docs/landmark-knowledge/Verification/2026-07-16_對帳假差異自癒_lab_E2E.md` | clean | 只更新排程時間敘述，驗證內容本身未受影響（純 config 改動不需重驗）。 |
| `LandmarkMember.Server/Controllers/Admin/AdminMemberStatsController.cs` | clean | Route 與既有 `/api/admin/*` 控制器無衝突，`days` 有 `Math.Clamp(1,365)` 防呆。 |
| `LandmarkMember.Server/Models/DTOs/Admin/MemberStatsDto.cs` | clean | 純資料容器。 |
| `LandmarkMember.Server/wwwroot/admin/logs/index.html`（POS 請求日期預設當天） | clean | `dayjs()` 在 `createApp` setup 執行時已可用（app script 前已載入），純體驗改善、無副作用（reactive 不重置，session 內使用者改過不會被覆蓋）。 |

## 第二部分：Findings

### F1 — 會員統計「總數」/「每日新增」未排除註銷/黑名單會員（minor）

- **位置**：`LandmarkMember.Server/Repositories/Implementations/CustomerRepository.cs:187-208`（`GetDailyNewMemberCountsAsync` 的 `WHERE CreateDate >= ...`、`GetTotalMemberCountAsync` 的 `SELECT COUNT(*) FROM Customer`）
- **severity**：minor
- **具體場景**：同一檔案裡所有面向會員身份判定的既有查詢（`GetByCustNoAsync`/`GetByLineUserIdAsync`/`GetByPhoneAsync`，見 `CustomerRepository.cs:47-84`）都一致地過濾 `CardStatus = 'Y' AND ISNULL(IsBlacklist,'N') = 'N'`，代表這個系統對「有效會員」有明確定義。但這次新增的 `GetTotalMemberCountAsync`／`GetDailyNewMemberCountsAsync` 不套用同樣過濾，直接 `COUNT(*)`。結果：若客服人員在維運儀表板「會員統計」分頁看到「會員總數 X」、「今天新增 Y」，這兩個數字實際上**包含已註銷（`CardStatus<>'Y'`）與黑名單會員**，與系統其餘所有地方對「會員」一詞的定義不一致。不會造成程式錯誤或資料損毀，但若有人拿這個數字對帳/對客戶報告「目前有效會員數」會偏高。

### F2 — RWD `.fit` 覆蓋不完整，既有窄表格仍會出現同一個視覺缺陷（minor）

- **位置**：`LandmarkMember.Server/wwwroot/admin/logs/index.html:329`（「總覽」分頁「錯誤次數排行 Top 10」表格，3 欄：功能ID/次數/最後發生）
- **severity**：minor
- **具體場景**：commit `65e1acd`（"手機版窄表格填滿寬度 RWD .fit"）的動機記錄得很清楚——`table{display:block}`（由 commit `68fda8e` 引入的 mobile 斷點規則，`index.html:186`）會讓內容欄位少的表格在區塊化後縮成「內容寬度」置左、右側留白，用 playwright 390px 實機驗出並針對「會員統計每日表」「SMS 查詢結果表」兩支表格加了 `class="fit"` 修正。但同一支檔案裡結構相同（欄位少、內容窄）的「總覽」頁「錯誤次數排行 Top 10」表格（`index.html:329`，只有 功能ID/次數/最後發生 三欄）並未套用 `.fit`——這支表格是既有表格（此次 patch 之前就存在），但它是被同一個 `table{display:block}` mobile 規則新影響到的對象，同樣具備會觸發該視覺缺陷的結構特徵，卻沒被同一輪 RWD 收斂掃到。使用者在手機（≤768px）打開「總覽」分頁時，該表格很可能出現同樣的「表格縮成內容寬、右側大片留白」現象。純視覺瑕疵，不影響資料正確性或功能可用性。

## 補充觀察（未達標記門檻，僅供參考，不計入 findings）

- Reconciliation 的 `NOT EXISTS (SELECT 1 FROM InvoiceOrders WHERE OrderNO=...)` 子查詢目前沒有看到 `InvoiceOrders.OrderNO` 上有索引佐證（repo 內找不到該表的 CREATE TABLE/索引腳本，應是既有 ERP 表非本 repo 管轄）。對帳查詢是每店每日跑一次、資料量不大，實務上不太可能構成效能問題，且找不到具體會失敗的輸入/情境，故不列入 findings。
- `ReconciliationRepository`/`CustomerRepository.UpdateLineBindingAsync` 這兩個本次改動的核心修正都沒有對應的自動化回歸測試（repo 裡沒有任何測試檔案引用 `SVC_DESK`/`GetOrdersByDateAndBoothAsync`/`RegisterSource`），完全依賴 commit message 裡的 prod 手動驗證數字。兩者都有具體的事故背景與驗證數字支撐，且不是本次審查能獨立證偽的東西，故不升級為 finding，僅記錄以供追蹤。

## 建置驗證

```
dotnet build LandmarkMember.Server/LandmarkMember.Server.csproj -c Debug --nologo -v quiet
→ 0 個錯誤（37 個既有 VSTHRD103 warning，與本次改動無關）

dotnet build LandmarkMember.Pos/LandmarkMember.Pos.csproj -c Debug --nologo -v quiet
→ 0 個警告，0 個錯誤
```
