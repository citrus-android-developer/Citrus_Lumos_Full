# Code Review: payload-S.patch（ReconSelfHeal 排程 22:30 → 23:00）

## 摘要（人話）

這份 changeset 只做一件事：把「對帳假差異自癒」背景服務的排程時間，從晚上 10:30 再往後挪 30 分到晚上 11:00。commit message 自稱「純 config,不碰自癒邏輯/合約」——我逐檔核對過，這句話是真的：實際的自癒判斷邏輯（`ReconciliationSelfHealService.cs`、`ReconciliationRepository.cs`）一行都沒動，只動了 config 數值、一則 SchedulerHeartbeat 顯示註解、跟兩篇知識架構圖文件。

JSON 改法本身是對的（我驗證過 `appsettings.json` 改完仍是合法 JSON，數值 `Hour:23/Minute:0` 正確落地），也沒有其他 `appsettings.*.json` 覆寫這個區塊去打架。23:00 這個時間點本身不會撞到午夜跨日或其他排程服務的邊界，风险很低。

唯一抓到的問題是「文件/註解沒跟著全部改到位」——這是那種「你看 code 註解會被誤導,但實際跑起來行為是對的」的落差,全部歸類 minor（跑起來不會壞，只是白紙黑字對不上）。

## 第一部分：逐檔裁決

| 檔案 | 判定 | 一句話理由 |
|---|---|---|
| `LandmarkMember.Pos/appsettings.json` | clean | Hour/Minute 數值正確改成 23/0，JSON 格式合法，無其他 appsettings 覆寫此區塊。 |
| `LandmarkMember.Server/Repositories/Implementations/SchedulerHeartbeatRepository.cs` | clean | 純顯示用註解字串同步更新為「23:00」，`IntervalSec=24*3600` 邏輯未變、無需變。 |
| `docs/landmark-knowledge/Projects/對帳假差異自癒_計劃.md` | minor | 本次改到的段落（summary、排程小節）已同步 23:00，但同一份文件另外兩處「config 全定義」列表（line 54、66）仍寫著舊值 `Hour(22)/Minute(0)`，同檔案內自相矛盾。 |
| `docs/landmark-knowledge/Verification/2026-07-16_對帳假差異自癒_lab_E2E.md` | clean | 描述文字同步更新為 23:00，與計劃文件一致。 |

## 第二部分：Findings

### F1（minor）—— 計劃文件內部前後矛盾，同檔案未改全

`docs/landmark-knowledge/Projects/對帳假差異自癒_計劃.md:54`：
```
- config:`ReconSelfHeal:Enabled`(true)/`Hour`(22)/`Minute`(0)/`LookbackDays`(2)。...
```
`docs/landmark-knowledge/Projects/對帳假差異自癒_計劃.md:66`：
```
- **config 全定義 + 驗證**:`ReconSelfHeal:Enabled`(true)/`Hour`(22)/`Minute`(0)/`LookbackDays`(2);...
```
這兩行仍寫 `Hour(22)/Minute(0)`，但同一份文件被這次 patch 改動的 line 22、41 已經改成「排程時間 22:00→23:00…Hour=23/Minute=0」。

**具體失敗場景**：維運或未來開發者只看「配套」或「關鍵決策」小節（文件中段/後段，line 54/66 所在區塊，不是開頭 summary）去核對 config 應有值時，會看到 `Hour(22)/Minute(0)`，誤以為目前排程仍是 22:00，可能因此在除錯「當晚翻不到」的情境時往錯誤方向查（以為排程沒生效，其實只是文件沒更新）。

### F2（minor）—— 服務原始碼裡的排程時間註解與 fallback 預設值未同步（此 changeset 未觸碰該檔）

`LandmarkMember.Pos/Services/ReconciliationSelfHealService.cs:9`：
```
/// 背景排程：每日 22:00 對帳假差異自癒。
```
`LandmarkMember.Pos/Services/ReconciliationSelfHealService.cs:12`：
```
/// 讀不到 → 誤報 missingOnServer → 假性 mismatched。閉店後（22:00）當日交易全結算，重跑比對即可把
```
`LandmarkMember.Pos/Services/ReconciliationSelfHealService.cs:50`：
```csharp
var hour = Clamp(_configuration.GetValue("ReconSelfHeal:Hour", 22), 0, 23, 22, "Hour");
```
以及 `LandmarkMember.Pos/Program.cs:104`：
```
// 對帳假差異自癒（每日 22:00 重跑純 missingOnServer 的 mismatched 列，假差異翻 matched）
```

這些檔案這次 changeset 完全沒動，字面值都還停在「22:00」（其實連上一輪 22:00→22:30 的改動都沒同步到，這次 22:30→23:00 也一樣沒同步，等於同一處註解已經連續兩輪排程調整都沒更新，跟實際值差到 1 小時）。

**具體失敗場景（兩層）**：
1. 文件層：日後工程師只讀程式碼（不查 `appsettings.json` 或架構圖文件）想確認自癒服務何時跑，會被 XML doc 註解誤導成「22:00」，實際上是 23:00，可能因此誤判「對帳晚於 22:00 完成的差異當晚翻不到」而去查一個已經在上一輪修過的假問題。
2. 行為層（低機率但真實）：`GetValue("ReconSelfHeal:Hour", 22)` 的第二參數 `22` 是「config 讀不到該鍵時」的 fallback。目前 `appsettings.json` 確實有設 `Hour:23`，所以正常部署不會走到這個 fallback。但若未來有任何環境（例如 IIS 上被覆寫的機碼、或部署腳本誤刪該區塊）造成 `ReconSelfHeal:Hour` 這個 key 在執行當下讀不到，服務會**靜默退回 22:00**（Clamp 邏輯不會報錯、只會寫一則 warning 心跳），等於這次「改到 23:00」的產品決策在該情境下被悄悄復原，而維運不容易從行為直接看出「用的是 fallback 值不是 config 值」。

以上兩項都判 minor：不是這次 patch 引入的邏輯錯誤（patch 承諾「不碰自癒邏輯」也確實沒碰），純粹是文件精度／註解未隨 config 變動同步更新，正常部署路徑下行為是對的。

## 未列入 finding 的項目（已查證排除）

- `docs/RELEASE_LOG.md:235` 仍寫「每日22:00」——這是帶日期的歷史發版紀錄（記錄當時上線時的排程），不是「現況描述」，不應該回填改寫，不算問題。
- 搜過全庫，沒有任何自動化測試（unit/E2E code）斷言排程時間字面值，驗證是 lab SQL 手動 E2E（文件形式），這次 patch 對應同步了 Verification 文件，沒有遺漏的測試斷言需要跟著改。
- `appsettings.Production.json`（Pos/Server 兩份都查過）沒有覆寫 `ReconSelfHeal` 區塊，不存在「base 改了、環境覆寫沒改」的風險。
- 23:00 本身不會撞到午夜跨日或其他背景服務排程邊界，`IntervalSec=86400` 的 stale-heartbeat 判斷邏輯與具體 Hour/Minute 無關，不受影響。
