---
name: vue-idioms
description: 寫或審 Vue 3（Composition API/<script setup>）代碼前必讀——通用不變量層的慣例規則：並行等待、computed vs watch、響應性陷阱、組件邊界。每條附壞例→好例與機檢對照。框架選擇（Pinia/Vuex、Axios/fetch 等）不在此裁——查該專案架構圖。
---

# Vue 3 慣例（通用不變量層）

**這份文件治的病**：AI 寫出「正確但笨」的 Vue——串聯了本該並行的請求、用 watch 手動同步本該 computed 的衍生值、解構弄丟響應性、async watch 的舊回應蓋掉新資料。

**分層原則**：只寫不隨框架選擇改變的原則。Pinia 還是 Vuex、Axios 還是 fetch——查該專案的知識架構圖與 CLAUDE.md（`lumos search` 起手）。

**機檢欄**：`eslint:規則名`＝現成；`自訂`＝可寫自訂規則；`不可機檢`＝只有本文件與審查鏡頭能守（排最前）。

---

## 一、並行與非同步

> **審查時機管道**:本文標「⚠ 不可機檢」的效能/適用性條目,其載重問已由 lumos 效能檢核機制在三時機自動推送(動手前 impact hook 注入/push 前 pitfalls advisory/終審 code-loop 鏡頭;內容源=lumos-toolchain 架構圖 Systems/效能檢核目錄,雙向同步義務)——可機檢條目歸 linter/analyzer,勿靠人記。

### R1. 互不依賴的等待必須並行 ⚠ 不可機檢，頭號條款
```js
// ✗ 笨（延遲相加）
const user = await fetchUser()
const prices = await fetchPrices()

// ✓ 並行
const [user, prices] = await Promise.all([fetchUser(), fetchPrices()])
```
- 要每個結果不論成敗 → `Promise.allSettled`；要一敗即停 → `Promise.all`。
- 迴圈內串聯有現成規則：`eslint:no-await-in-loop`；直線碼的無依賴串聯只有本條能治。
- 依據：[MDN Promise.all](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all)

### R2. 衍生值一律 `computed`，禁止用 watch 手動同步 ⚠ 不可機檢，第二重要
```js
// ✗ 用 watch 養第二份 state(會漂、會漏初始化)
watch(items, v => { count.value = v.length })

// ✓ 宣告式衍生,自帶快取
const count = computed(() => items.value.length)
```
官方分工：computed 管衍生值、watch 只管副作用。computed getter 必須純——不改 state、不發請求（`eslint:vue/no-side-effects-in-computed-properties`、`vue/no-async-in-computed-properties` 兜底）。
- 依據：[Vue watchers](https://vuejs.org/guide/essentials/watchers.html)、[computed](https://vuejs.org/guide/essentials/computed.html)

### R3. async watch 必須處理競態 ⚠ 不可機檢，最隱蔽的 bug
快速切換時舊回應晚到、蓋掉新資料。標準解：
```js
watch(id, (newId, _, onCleanup) => {
  const c = new AbortController()
  fetch(url(newId), { signal: c.signal }).then(render)
  onCleanup(() => c.abort())   // 下一輪觸發前取消上一輪
})
```
- 注意：`onWatcherCleanup`（3.5+）不能在 `await` 之後呼叫。
- 依據：[Vue watchers](https://vuejs.org/guide/essentials/watchers.html)

### R4. Promise 不得懸空（機檢為主，一句帶過）
await／return／`.catch`／顯式 `void` 四選一。`if (isValid())` 這種把 async 函式當同步用的恆真 bug 也在此列。
- 機檢：`@typescript-eslint/no-floating-promises`、`no-misused-promises`（需 type-aware lint，**必開**）

### R5. `await` 之後禁止再註冊 watch／生命週期鉤子；composable 必須在 setup 內同步呼叫
async 回呼裡建的 watcher 綁不到組件、要手動停，不停就洩漏。
- 機檢：`eslint:vue/no-watch-after-await`、`vue/no-lifecycle-after-await`（essential preset）

## 二、響應性紀律

### R6. 解構丟響應 ⚠ 對應規則預設不開
```js
// ✗ 解構出來的是死值
let { count } = state; count++

// ✓ 保住連結
const { count } = toRefs(state)
```
props 同理：要當初始值 → `ref(props.x)`（有意斷開）；要跟著變 → `computed(() => props.x)`；**禁止 watch 同步本地拷貝**。
- 機檢：`eslint:vue/no-setup-props-reactivity-loss`、`vue/no-ref-object-reactivity-loss`——**uncategorized，要手動開**

### R7. `ref()` 是宣告狀態的主 API
`reactive()` 只給「就地突變、永不整體重賦值」的聚合物件——`state = reactive({...})` 重賦值即斷連。watch reactive 的單一屬性要傳 getter：`watch(() => state.count, cb)`。忘 `.value` 由 `eslint:vue/no-ref-as-operand` 兜。
- 依據：[reactivity fundamentals](https://vuejs.org/guide/essentials/reactivity-fundamentals.html)

### R8. watch 成本意識 ⚠ 不可機檢
`deep: true` 對大結構昂貴，必要才用（3.5+ 可給數字限深）；「初始跑一次」用 `immediate: true`，不准 onMounted＋watch 寫兩份同邏輯；`watchEffect` 的 async 回呼**只追蹤第一個 await 之前**讀到的依賴——async 邏輯優先用顯式 `watch`。

### R9. composable 慣例
`use` 前綴；回傳「refs 的 plain object」（解構不丟響應）；輸入用 `toValue()` 收 ref／getter／裸值皆可；DOM 副作用 onMounted 掛、onUnmounted 清。
- 依據：[composables](https://vuejs.org/guide/reusability/composables.html)

## 三、模板與效能

### R10. essential preset 一行帶過（機檢全包）
`v-for` 必帶穩定 `:key`（不用 index）；`v-if` 不與 `v-for` 同元素（過濾收進 computed）；模板內不內聯過濾排序邏輯。
- 機檢：`eslint-plugin-vue` 的 `flat/recommended` 全開即可

### R11. 效能三件套 ⚠ 不可機檢
v-for 子項的 prop 預先算成 per-item 值（`:active="item.id === activeId"`，別把全域值塞給每個子項）；千項級列表虛擬化；`v-once`/`v-memo` 是量測後的手術刀不是預設撒的。
- 依據：[performance](https://vuejs.org/guide/best-practices/performance.html)

## 四、組件邊界

### R12. props down / events up
props 唯讀，要改就 emit（含巢狀物件——runtime 不擋但官方明勸阻）。雙向綁定用 `defineModel()`（3.4+），不手刻 modelValue、更不准 watch 雙向同步。emit 必顯式宣告。
- 機檢：`eslint:vue/no-mutating-props`、`vue/require-explicit-emits`

### R13. provide/inject 與 template ref 紀律
突變留在 provider、對外給更新函數、值用 `readonly()` 包、大型 app 用 Symbol key。組件通訊優先 props/emit；template ref 只留給命令式動作（`useTemplateRef()`，3.5+）。

---

## 機檢接線（一次設好）

```js
// eslint.config.js 要點
// 1. eslint-plugin-vue: flat/recommended 之上,手動加開 uncategorized 三條:
//    vue/no-setup-props-reactivity-loss, vue/no-ref-object-reactivity-loss, vue/prefer-use-template-ref
// 2. typescript-eslint: type-aware 必開 no-floating-promises, no-misused-promises
```
專案把 ESLint 指令（`@microsoft/eslint-formatter-sarif`）宣告進 `.lumos/lint.json`，`lumos pitfalls --diff` 自動吃 SARIF 進審查 manifest。

## 審查鏡頭（code-loop 用）

「對照 vue-idioms R1–R13 逐條掃 diff；finding 必須引用條號（如『違反 R2：`totalPrice` 用 watch 同步，該用 computed』），引用不出條號的風格意見不要標。」

## 誠實邊界

1. 最重要的三條（R1 並行、R2 computed、R3 競態）全部不可機檢——本文件＋審查鏡頭是唯一防線。
2. 持續比對源：Vue 官方有專為 AI 維護的最佳實踐 repo（[vuejs-ai/skills](https://github.com/vuejs-ai/skills)）——本文件更新時先跟它對一輪。
3. 本文件不裁框架；與專案當地慣例衝突時當地贏，衝突記進該專案架構圖。
4. 飛輪：每次人工糾正 AI 一個醜寫法，回填一條或一例。
