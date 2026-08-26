---
name: csharp-idioms
description: 寫或審 C#/.NET（ASP.NET Core Web API）代碼前必讀——通用不變量層的慣例規則：Task.WhenAll 並行、CancellationToken 全鏈、背景工作陷阱、DI 生命週期、資源釋放。每條附壞例→好例與分析器對照。框架選擇（EF Core/Dapper、DI 容器等）不在此裁——查該專案架構圖。
---

# C#/.NET 慣例（通用不變量層）

**這份文件治的病**：AI 寫出「正確但笨」的 C#——串聯了本該 `Task.WhenAll` 的查詢、CancellationToken 半路斷鏈、`Task.Run` 捕獲請求物件、singleton 偷抱 scoped 依賴。這些不炸在測試上，炸在負載、關機、和使用者按下取消的那一刻。

**分層原則**：只寫不隨框架選擇改變的原則。EF Core 還是 Dapper、哪家 DI 容器——查該專案的知識架構圖與 CLAUDE.md。

**機檢欄縮寫**：CA＝Roslyn 內建、AF＝AsyncFixer、VSTHRD＝VS Threading Analyzers、MA＝Meziantou、CS＝編譯器警告。⚠ 多數關鍵規則**預設不開或僅 suggestion**——見文末接線表，不升級嚴重度等於沒裝。

---

## 一、並行與 async 紀律

> **審查時機管道**:本文標「⚠ 不可機檢」的效能/適用性條目,其載重問已由 lumos 效能檢核機制在三時機自動推送(動手前 impact hook 注入/push 前 pitfalls advisory/終審 code-loop 鏡頭;內容源=lumos-toolchain 架構圖 Systems/效能檢核目錄,雙向同步義務)——可機檢條目歸 linter/analyzer,勿靠人記。

### R1. 互不依賴的等待必須並行 ⚠ 不可機檢，頭號條款
```csharp
// ✗ 笨（延遲相加）
var user   = await GetUserAsync(id);
var orders = await GetOrdersAsync(id);

// ✓ 先全部啟動,再一起等
var tUser   = GetUserAsync(id);
var tOrders = GetOrdersAsync(id);
await Task.WhenAll(tUser, tOrders);
```
**並行前提（重要反例）**：各工作必須各自持有連線／資源。共用同一條 DB connection 或 transaction 的批次**不准平行化**——多數 ADO 連線不支援並發查詢，平行了反而炸。判斷順序：先確認無資料依賴，再確認無共享資源，才並行。
- 依據：[MS Learn async scenarios](https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/async-scenarios)、[ASP.NET Core best practices](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/best-practices)

### R2. async 全鏈到底 ⚠ 架構性，不可機檢
入口（controller／endpoint／handler）回 `Task`，中途任何一層不得同步化再包回。局部症狀交機檢：禁 `.Result`/`.Wait()`/`GetAwaiter().GetResult()`（VSTHRD002、CA1849、AF02——死鎖與執行緒池飢餓）；禁 `async void`（AF03、VSTHRD100——未捕捉例外直接砸掉 process，唯一例外是事件處理器）；有 async 版 API 就用 async 版（CA1849、VSTHRD103）。
- 依據：[David Fowler AsyncGuidance](https://github.com/davidfowl/AspNetCoreDiagnosticScenarios/blob/master/AsyncGuidance.md)——「Asynchrony is viral」

### R3. 不忽略 Task；fire-and-forget 要走正門
```csharp
// ✗ 例外無聲蒸發,且捕獲了請求物件
_ = Task.Run(() => NotifyAsync(HttpContext.User));

// ✓ 交給 hosted service / 背景佇列;先複製純資料再入列
_queue.Enqueue(new NotifyJob(userId));
```
- 機檢：CS4014、VSTHRD110、MA0134 抓「忘了 await」；「捕獲 HttpContext」見 R7
- 不用 `Task.Run` 把同步 API 假裝成 async（`需自訂`）

### R4. ValueTask 只能消費一次且直接 await；Task 方法禁回 null
- 機檢：CA2012（升 warning）、VSTHRD114、MA0022

## 二、取消與資源

### R5. CancellationToken 全鏈傳遞 ⚠ 機檢只蓋一半，第二重要
endpoint 簽名收 token（框架自動綁定請求中斷）→ service → repository → DB/HTTP/IO，一路傳到底。斷鏈的代價：使用者早就關頁面，DB 還在跑大查詢；關機時 hosted service 等 SQL 自己跑完。
```csharp
// ✗ 半路斷鏈
public async Task<T> Get(CancellationToken ct) => await _repo.QueryAsync();

// ✓ 收了就轉發
public async Task<T> Get(CancellationToken ct) => await _repo.QueryAsync(ct);
```
- 機檢：CA2016／MA0040 抓「方法內有 token 沒轉發」；**「簽名根本沒收 token」抓不到**——靠本條＋審查。`await foreach` 配 `.WithCancellation(ct)`（MA0079/80）。自建 CTS（timeout/linked）必 `using`。

### R6. 資源釋放紀律
有 async 釋放能力的（交易、連線、writer）用 `await using`；Stream 類 Dispose 前先 `FlushAsync`（否則 Dispose 內同步阻塞）；**不疊 using**（同 block 頭兩個 using，第二個建構拋例外時第一個不會釋放——逐個宣告）；請求路徑不 new/dispose `HttpClient`（socket 耗盡，用注入的工廠／共享 client 能力）。
- 依據：[implementing DisposeAsync](https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/implementing-disposeasync)

## 三、DI 與背景工作

### R7. 背景工作不得捕獲請求範圍的東西 ⚠ 不可機檢，病發即 crash
`HttpContext`、controller 注入的 scoped 服務，請求結束就失效。背景工作要嘛先複製需要的**純資料**，要嘛用 `IServiceScopeFactory` 自己開新 scope 解析。
- 依據：[best practices](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/best-practices)——「Do not capture the HttpContext in background threads」

### R8. 禁 captive dependency，並把驗證開起來 ⚠ 靜態機檢缺席
singleton 建構子不得持有 scoped/transient 依賴（scoped 被抓住＝變相 singleton，資料錯亂）。**同時要求**：`ValidateScopes` 與 `ValidateOnBuild` 在所有環境開啟——讓這病在啟動時就炸，不是上線後。
- 依據：[DI guidelines](https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/guidelines)

### R9. 建構子與 DI factory 保持同步快速；singleton 自己負責 thread-safe
建構子不做 async 工作不阻塞（async factory＋`.Result`＝死鎖）；需要 async 初始化用 factory method 或啟動時初始化。容器只保證解析安全，不保證你的服務狀態安全。

## 四、LINQ 與資料

### R10. `IEnumerable<T>` 是延遲執行
會消費兩次以上就先 `ToList()/ToArray()` 物化（來源是 DB 查詢時重複列舉＝重跑查詢）；用 LINQ 產生 Task 集合**立刻物化再 WhenAll**（否則 task 根本沒啟動）。
- 機檢：CA1851（**預設關，要開**）

### R11. 大結果集分頁；過濾聚合下推到資料層
不回傳同步列舉的大 `IEnumerable` 給 serializer（OOM／執行緒池飢餓級）；只取當次需要的欄位與列；避免抓全量進記憶體再 LINQ、避免 N+1。
- 機檢：`不可機檢`

### R12. `ConfigureAwait` 裁定（防 AI 兩邊亂撒）
可重用類庫碼加 `ConfigureAwait(false)`；ASP.NET Core 應用碼無 SynchronizationContext、不強制。一句話：library 加、app 隨意但一致。

---

## 機檢接線（不設等於沒裝）

```xml
<!-- csproj:三包分析器合起來才蓋滿 async smell(Cezary Piątek 跨工具對照結論) -->
<PackageReference Include="AsyncFixer" Version="*" PrivateAssets="all" />
<PackageReference Include="Meziantou.Analyzer" Version="*" PrivateAssets="all" />
<PackageReference Include="Microsoft.VisualStudio.Threading.Analyzers" Version="*" PrivateAssets="all" />
```
```ini
# .editorconfig 嚴重度升級(預設 suggestion/關閉 = 名存實亡)
dotnet_diagnostic.VSTHRD002.severity = error   # 同步阻塞
dotnet_diagnostic.VSTHRD100.severity = error   # async void
dotnet_diagnostic.AsyncFixer02.severity = error
dotnet_diagnostic.AsyncFixer03.severity = error
dotnet_diagnostic.CA1849.severity  = warning   # 有 async 版就用
dotnet_diagnostic.CA1851.severity  = warning   # 重複列舉
dotnet_diagnostic.CA2016.severity  = warning   # token 轉發
dotnet_diagnostic.CA2012.severity  = warning   # ValueTask
```
Roslyn 吐 SARIF（`dotnet build -p:ErrorLog=...`）宣告進 `.lumos/lint.json`，`lumos pitfalls --diff` 自動吃進審查 manifest。

## 審查鏡頭（code-loop 用）

「對照 csharp-idioms R1–R12 逐條掃 diff；finding 必須引用條號（如『違反 R1：`GetActivitiesAsync` 三個各自建連線的查詢串聯等待』），並確認 R1 的共享資源前提；引用不出條號的風格意見不要標。」

## 誠實邊界

1. 病最重的四條（R1 並行、R2 全鏈、R5 token、R7 背景捕獲）機檢缺席或只蓋一半——本文件＋審查鏡頭是主防線。
2. R1 有真實反例教訓：看似無依賴的批次若共用 conn/tx，平行化是把 bug 換 bug——並行前先過「資源共享」檢查。
3. 本文件不裁框架；與專案當地慣例衝突時當地贏，衝突記進該專案架構圖。
4. 飛輪：每次人工糾正 AI 一個醜寫法，回填一條或一例。
