# Code Review — payload-S.patch（對帳自癒排程 22:30→23:00）

## 背景確認

這份 changeset 宣稱「純 config,不碰自癒邏輯/合約」。實際比對後：改動的 4 個檔案裡，
真正的執行邏輯（`ReconciliationSelfHealService.cs`、`ReconciliationRepository.cs`）
確實一行都沒碰，只動了 config 值、一行 dictionary 註解、和兩份架構圖文件。這個定性是準確的。

驗過幾條可能被時間值變動牽動的側路，結論都是安全：
- `appsettings.Production.json` / `appsettings.Local.json.template` 都沒有 `ReconSelfHeal` 區段，
  ASP.NET Core 的 config 疊加不會蓋掉 base `appsettings.json` 的新值 23:00 → prod 生效值正確。
- 儀表板 STALE 判定門檻是 `expected_interval × 2.5`（見 `LandmarkMember.Server/wwwroot/admin/logs/index.html:1566`
  與 `docs/landmark-knowledge/Systems/維運儀表板.md:132`），本服務 `IntervalSec=86400`（24h），
  門檻 60 小時。換檔當天最壞情況（前一天 22:30 跑、新設定隔天 23:00 才跑）只多出 30 分鐘的間隔，
  離門檻还差很遠，不會誤報 STALE。
- `GetHealableLogsAsync` 的窗口計算只吃 `BusinessDate`（日期），不吃時分，換到 23:00 執行不影響掃描窗口語意。

## 第一部分：逐檔裁決

| 檔案 | 判定 | 一句話理由 |
|---|---|---|
| `LandmarkMember.Pos/appsettings.json` | clean | Hour/Minute 值變更本身正確、在 Clamp 合法範圍內，且驗過不受 Production/Local override 影響。 |
| `LandmarkMember.Server/Repositories/Implementations/SchedulerHeartbeatRepository.cs` | minor | dictionary 註解值有同步更新，但沿用「由 22:00 改」的舊措辭掩蓋了中間 22:30 這一版，讀者會誤以為只改過一次。 |
| `docs/landmark-knowledge/Projects/對帳假差異自癒_計劃.md` | minor | 頂部 FLOW/KEY 摘要與「設計」段落已同步到 23:00，但下方「配套」「關鍵決策」兩段仍留著舊的 `Hour(22)/Minute(0)`，同一份文件內自相矛盾。 |
| `docs/landmark-knowledge/Verification/2026-07-16_對帳假差異自癒_lab_E2E.md` | clean | 純敘述性同步，準確反映新排程時間，未過度宣稱驗證過新時間點的行為（本就不需要，因為只是常數）。 |

## 第二部分：findings

### F1（minor）— 計劃文件內部数值不一致，changeset 沒有完整傳播新排程值
- **file:line**：`docs/landmark-knowledge/Projects/對帳假差異自癒_計劃.md:54` 與 `:66`
- 這兩行分別在「配套」與「關鍵決策」段落，寫著
  `config:ReconSelfHeal:Enabled(true)/Hour(22)/Minute(0)/LookbackDays(2)`，
  是本次 diff **沒有觸及**的既有文字。而同一份文件開頭 `summary` 的 FLOW/KEY 行（本次 diff 已改）
  已經寫成 23:00。
- **具體失敗場景**：日後任何人（人或 AI）只看這份計劃文件「配套」或「關鍵決策」段落找目前排程值
  （而不是往上翻到 summary），會得到「Hour=22」的錯誤資訊，與 `appsettings.json` 實際值 23 不符。
  commit message 宣稱「架構圖同步」，但同步做得不完整，留下一份自相矛盾的節點。

### F2（minor）— dictionary 註解的變更歷史敘述失真（沿用既有措辭，非本次新增）
- **file:line**：`LandmarkMember.Server/Repositories/Implementations/SchedulerHeartbeatRepository.cs:24`
- 註解寫「每日 23:00 一次(2026-07-17 由 22:00 改...)」，略過了中間 22:30 那一版（上一個 commit 才剛把
  22:00 改到 22:30）。這個「A→C」省略「A→B→C」的措辭風格是延續舊註解就有的寫法（上一版本身也寫
  「由 22:00 改」略過細節），非本次 patch 首次引入，但本次 patch 有機會一併修正卻沒有修正。
- **具體失敗場景**：維運人員之後想確認「這個排程到底調過幾次、每次調多少」時，只看這行註解會誤以為
  只調過一次（22:00→23:00 直接跳），漏看中間曾經在 22:30 跑過一段時間的事實，可能影響排查「為何某天
  22:30 左右有一筆自癒紀錄」之類的追溯工作。

### F3（minor）— C# 內建 fallback 預設值與新調校值不同步，config 缺失時會靜默退回舊時間
- **file:line**：`LandmarkMember.Pos/Services/ReconciliationSelfHealService.cs:50-51`（此檔本次 diff 未觸及）
  ```csharp
  var hour = Clamp(_configuration.GetValue("ReconSelfHeal:Hour", 22), 0, 23, 22, "Hour");
  var minute = Clamp(_configuration.GetValue("ReconSelfHeal:Minute", 0), 0, 59, 0, "Minute");
  ```
- **具體失敗場景**：目前 `appsettings.json` 明確帶了 `ReconSelfHeal:Hour=23`，正常路徑沒事。但如果未來
  有人重建/精簡 appsettings.json 時不小心把整個 `ReconSelfHeal` 區塊漏掉（例如手動改設定檔、或拿舊版
  appsettings.json 部分覆寫時漏了這段——註：此類事故在本專案並非空想，`appsettings.Production.json` 檔頭
  註解本身就在講「機密由 Local.json 覆寫」這種分層覆寫模式），`GetValue` 會靜默吃到 `22`（不是
  `Clamp` 的 out-of-range 分支，因為根本沒有值可比對，也就不會寫警告心跳）。服務會在 22:00 跑，
  **早於店家 ~22:04 的閉店對帳**——這正是這整個功能一開始要修的原始 bug 場景（22:00 那班翻不到當晚
  假差異、要靠隔天 LookbackDays 窗才補翻，延遲一天翻正）。也就是說，這個 fallback 值一旦被觸發，
  會無聲無息地讓服務退化回文件裡明確記載「已知有問題」的舊排程，而且不會有任何 clamp 警告心跳可供
  排查，因為 `GetValue` 在鍵缺失時直接用預設值，不會進到 `Clamp` 的告警分支。
- 由於本次 changeset 明確定位為「排程微調」而非邏輯改動，且觸發前提（config 整段缺失）並非本次
  patch 造成，評級為 minor；但既然本次 patch 就是在動這個時間值，理論上該一併把這個硬編碼 fallback
  更新到 23/0，否則「調校值」與「安全網退回值」永久脫鉤。

## 總結

這是一個範圍很小、風險很低的 config-only 變更，核心邏輯完全沒動，且對可能受影響的下游（IIS 分層
config、STALE 偵測門檻、掃描窗口 SQL）都驗證過沒有副作用。問題全部集中在「架構圖/文件/註解沒有徹底
跟著新值傳播」這一類，沒有發現會導致錯誤執行行為的 major/blocker 問題。
