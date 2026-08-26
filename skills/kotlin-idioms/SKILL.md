---
name: kotlin-idioms
description: 寫或審 Kotlin（Coroutines/Flow/Compose）代碼前必讀——通用不變量層的慣例規則：並行等待、Flow 合成、協程紀律、Compose 重組。每條附壞例→好例與機檢對照。框架選擇（Hilt/Koin、Retrofit/Ktor 等）不在此裁——那是各專案自己的事，查該專案架構圖。
---

# Kotlin 慣例（通用不變量層）

**這份文件治的病**：AI 寫出「正確但笨」的 Kotlin——能跑、測試會過，但串聯了本該並行的等待、巢狀了本該 combine 的流、吞了不該吞的取消例外。這些 bug 不炸在功能上，炸在效能、電量、和上線三個月後的詭異取消行為上。

**分層原則（重要）**：本文件只寫「不隨框架選擇改變的原則」。用 Hilt 還是 Koin、Retrofit 還是 Ktor、MVI 還是 MVVM——那是各專案的當地選擇，**去讀該專案的知識架構圖和 CLAUDE.md**（`lumos search <關鍵字>` 起手）。本文件的規則以「可注入」「可替換」等能力措辭，不點名框架。

**機檢欄說明**：`detekt:規則名`＝有現成規則；`自訂`＝可寫 detekt/Semgrep 自訂規則；`不可機檢`＝只有本文件與審查鏡頭能守——這類規則排最前面，因為文件是唯一防線。

---

## 一、並行與 Flow（本文件存在的理由）

> **審查時機管道**:本文標「⚠ 不可機檢」的效能/適用性條目,其載重問已由 lumos 效能檢核機制在三時機自動推送(動手前 impact hook 注入/push 前 pitfalls advisory/終審 code-loop 鏡頭;內容源=lumos-toolchain 架構圖 Systems/效能檢核目錄,雙向同步義務)——可機檢條目歸 linter/analyzer,勿靠人記。

### R1. 互不依賴的等待必須並行 ⚠ 不可機檢，本文件頭號條款
兩個以上 suspend 呼叫，彼此的輸入不依賴對方的輸出 → 必須 `coroutineScope { async }` 並行；串聯 await 只允許在真有資料依賴時。

```kotlin
// ✗ 笨（兩秒）：b 根本不需要 a 的結果
val a = fetchProfile()
val b = fetchOrders()

// ✓ 並行（一秒）
val (a, b) = coroutineScope {
    val pa = async { fetchProfile() }
    val pb = async { fetchOrders() }
    pa.await() to pb.await()
}
```
- 語意選擇：一個失敗要取消整批 → `coroutineScope`；個別失敗不連坐（如掃描一批 IP）→ `supervisorScope`。
- 多筆同型：`items.map { async { fetch(it) } }.awaitAll()`——用 `awaitAll()` 不用 `map { it.await() }`（後者逐一等、首個例外的傳播較差）。
- 依據：[Kotlin 官方 composing-suspending-functions](https://kotlinlang.org/docs/composing-suspending-functions.html)

### R2. 多資料流合成畫面狀態用 `combine`，禁止巢狀 collect ⚠ 不可機檢
```kotlin
// ✗ 巢狀 collect（外層每發一次就重訂閱內層,行為錯亂）
flowA.collect { a -> flowB.collect { b -> render(a, b) } }

// ✓ 任一來源更新就重算
combine(flowA, flowB) { a, b -> UiState(a, b) }
```
- `combine`＝任一更新就重算最新組合（UI state 幾乎都要這個）；`zip`＝嚴格一對一配對（少用，配對語意才用）；`merge`＝多源同型事件匯流。
- 依據：[Android 官方 state production](https://developer.android.com/topic/architecture/ui-layer/state-production)

### R3. ViewModel 曝光 state 的標準形狀
私有 `MutableStateFlow` ＋ 公開 `StateFlow`；串流上游用 `.stateIn(scope, SharingStarted.WhileSubscribed(5_000), initial)`——5 秒是為了撐過螢幕旋轉不重啟上游。`Eagerly` 需一行書面理由。
- 機檢：`自訂`（掃公開 MutableStateFlow / Eagerly）
- 依據：[sharein-statein 官方文章](https://medium.com/androiddevelopers/things-to-know-about-flows-sharein-and-statein-operators-20e6ccb2bc74)

### R4. state 更新一律原子 `update { it.copy(...) }`，禁 `.value =` 做讀改寫
`_state.value = _state.value.copy(...)` 在併發下丟更新——AI 高頻犯，且測試測不出來。
- 機檢：`自訂`

### R5. `shareIn`/`stateIn` 禁止放在函式回傳裡
每呼叫一次就生一條新熱流佔著記憶體。共享流一律建成類別屬性、只建一次。
- 機檢：`自訂`

### R6. 回傳 `Flow` 的函式不標 `suspend`；`flow {}` 內不 `withContext`
冷流本身就是延遲執行；builder 內換 context 違反 context preservation，runtime 直接炸——換上游執行緒用 `.flowOn(dispatcher)`。
- 機檢：`detekt:SuspendFunWithFlowReturnType`（預設開）；withContext 需`自訂`

### R7. 高頻流接慢消費者，backpressure 策略要明示
只要最新值 → `conflate()` 或 `collectLatest`；不能丟 → `buffer()`。什麼都不寫＝默默堆積。另外：可被新值作廢的查詢用 `collectLatest`，必須逐筆完成的命令用 `collect`——選錯方向是語意 bug。
- 機檢：`不可機檢`

## 二、協程紀律

### R8. suspend 函式必須 main-safe ⚠ 不可機檢，第二重要
做阻塞／耗時工作的**那個類別自己**負責 `withContext(io)`；呼叫端永遠可以在主執行緒直接呼叫，不准要求呼叫端補 withContext。AI 常反著寫（在呼叫端亂包），一句話記住：**誰阻塞，誰負責**。
- 依據：[Google coroutines best practices](https://developer.android.com/kotlin/coroutines/coroutines-best-practices)

### R9. Dispatcher 不准硬編碼，必須可注入可替換
建構子參數、DI 模組、預設參數皆可——重點是測試時換得成 TestDispatcher。`Dispatchers.IO` 直接寫死在方法裡＝不可測。
- 機檢：`detekt:InjectDispatcher`（預設開）

### R10. 永不吞 `CancellationException`
```kotlin
// ✗ 取消訊號被吃掉,協程殺不死(runCatching 包 suspend 同罪)
try { work() } catch (e: Exception) { log(e) }

// ✓ 取消先放行,再接業務例外
try { work() }
catch (e: CancellationException) { throw e }
catch (e: IOException) { log(e) }
```
這 bug 只在取消時發作、最難排查。
- 機檢：`detekt:SuspendFunSwallowedCancellation`（預設關，要開）

### R11. 禁 `GlobalScope`；活過畫面的工作用注入的應用級 scope
- 機檢：`detekt:GlobalCoroutineUsage`（預設關，要開）

### R12. 其餘一鍵機檢組（寫進 detekt 設定就好，不佔篇幅）
`SleepInsteadOfDelay`（協程內用 delay 不用 Thread.sleep，預設開）、`RedundantSuspendModifier`（沒暫停點就拿掉 suspend，預設開）、`ForbiddenMethodCall` 配置 `runBlocking`（suspend 內禁用）、`CoroutineLaunchedInTestWithoutRunTest`（測試協程要包 runTest，預設關）。
另兩條靠審查：CPU 密集迴圈內定期 `ensureActive()`（取消是合作式的）；`Job()/SupervisorJob()` 不當參數傳進 launch（要 supervisor 語意用 `supervisorScope {}`）。

## 三、Compose

### R13. 收流一律 `collectAsStateWithLifecycle()`
`collectAsState()` 在 App 退到背景時照樣收集，浪費電和網路——且要跟 R3 的 `WhileSubscribed` 成對才生效。AI 訓練語料舊，極常寫錯這條。
- 機檢：`detekt:ForbiddenMethodCall` 配置 `collectAsState`

### R14. Lazy 清單必給穩定 key
`items(list, key = { it.id })`——AI 幾乎必漏；症狀是捲動閃跳與整列白白重組，使用者看得到。
- 機檢：`自訂`

### R15. 重組效能三件套 ⚠ 不可機檢
昂貴計算包 `remember(keys) {}`；高頻 state 的派生判斷用 `derivedStateOf`（如 `firstVisibleItemIndex > 0`，否則每滾一像素重組一次）；動畫／捲動值延遲到 `Modifier.offset { }`／`drawBehind {}` 再讀。另禁 backwards write（composition 中讀完又寫同一 state → 無限重組）。
- 依據：[Compose 官方效能指南](https://developer.android.com/develop/ui/compose/performance/bestpractices)

### R16. Composable 參數紀律（現成規則整組開）
不傳 ViewModel／MutableState／可變集合往下——傳 immutable data ＋ `onXxx` 事件 lambda 往上；ViewModel 只在 screen 頂層取一次。public composable 必有 `modifier: Modifier = Modifier` 且只施加在 root 一次。
- 機檢：[mrmans0n/compose-rules](https://mrmans0n.github.io/compose-rules/rules/)（detekt/ktlint 雙棲，32 條）＋ [Slack compose-lints](https://slackhq.github.io/compose-lints/rules/)（Android Lint 層，互補）

## 四、結構

### R17. 分層 API 形狀固定
data/domain 層：一次性操作＝`suspend fun(): Result`、串流＝非 suspend 的 `fun(): Flow`；ViewModel 收斂成 StateFlow；UI 只收集。一個邊界只保留一套結果型別，不要 Result／Either／throw 三種混用。
- 機檢：`不可機檢`

### R18. 越層 import 當 build error 治
AI 一個世代就能打穿分層（UI 直接 import DAO）。自訂 detekt `ForbiddenImport`／層白名單規則，讓越層直接紅。
- 機檢：`自訂`（[完整範例](https://dev.to/wakita181009/an-llm-broke-my-architecture-in-one-generation-i-made-that-a-build-error-1ae0)）

---

## 機檢接線（一次設好，CI 自動把關）

detekt 設定要點（`--build-upon-default-config` 之上）：
```yaml
coroutines:
  GlobalCoroutineUsage: { active: true }
  SuspendFunSwallowedCancellation: { active: true }
  CoroutineLaunchedInTestWithoutRunTest: { active: true }
style:
  ForbiddenMethodCall:
    active: true
    methods:
      - "kotlinx.coroutines.runBlocking"
      - "androidx.compose.runtime.collectAsState"
```
加掛 compose-rules（detekt plugin jar）補 R16 整組。專案把 detekt 指令宣告進 `.lumos/lint.json`，`lumos pitfalls --diff` 就會自動吃 SARIF、命中行進審查 manifest——lumos 這頭不用再做任何事。

## 審查鏡頭（code-loop 用）

給審查員的一句 framing：「對照 kotlin-idioms 的 R1–R18 逐條掃這份 diff；**finding 必須引用條號**（如『違反 R1：`loadA()`/`loadB()` 無資料依賴卻串聯』），引用不出條號的風格意見不要標。」——執法不立法，品味之爭擋在門外。

## 誠實邊界

1. 最重要的三條（R1 並行、R2 combine、R8 main-safe）恰好都不可機檢——「無依賴」「該不該合成」是語意判斷，這份文件＋審查鏡頭是唯一防線，這正是它存在的理由。
2. 機檢規則抓形狀不抓意圖：過了 detekt 不代表寫得好。
3. 本文件不裁框架。發現某條規則與專案當地慣例衝突時：當地慣例贏，但把衝突記進該專案架構圖（可能是當地的技術債，也可能是本文件該修）。
4. 飛輪：每次人工糾正 AI 一個醜寫法，回來加一條或補一個例——這份文件跟事故語料一樣，是越用越厚的。
