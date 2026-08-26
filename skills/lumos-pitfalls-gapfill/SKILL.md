---
name: lumos-pitfalls-gapfill
description: linter 未收錄的新坑用網搜補漏——WebSearch 找某 stack 的新 gotcha/pitfall(linter 沒抓的)→ 反證預篩(派 refuter 駁倒即丟)→ 駁不倒進候選(非定論)→ 人輕量放行 → 進架構圖 linter-gap 實務隱患節點(節點自去重)。邊角、量少、無機械 oracle 人閘省不掉。觸發詞:網搜補漏、linter 沒收錄的坑、pitfalls 網搜、新 gotcha 補漏、偏科層補殘餘。
---

# lumos-pitfalls-gapfill:linter 未收錄新坑的網搜補漏(block ③)

**Claude 編排,人放行,架構圖存放。** pitfalls 偏科層靠 linter 吃大宗;這個 skill 只補**linter 還沒收錄的殘餘新坑**。無 lumos 新指令——只用既有 `lumos new issue`/`append`/`context`/`search` 讀寫節點。

> ⚠ **邊角、量少、別過度跑**:linter(`.lumos/lint.json`)已覆蓋大宗,這只補殘餘。**不是每次 code-loop 都掃**;在「寫某 stack 的 spec / 進某 stack 的 code-loop、感覺 linter 可能沒蓋到某類新坑」時才調用。

## 何時用 / 何時跳
- **用**:針對某 stack(Kotlin/C#/Vue…),懷疑有 linter 未收錄的**新**慣用坑(新版框架 API 陷阱、社群近期熱議的 footgun),想補進專案 pitfalls。
- **跳**:linter(detekt/eslint/VSTHRD…)已能抓的 → 走 lint-adapter,不在這裡重找;專案自己踩過的具體事故 → 走 ④ 事故語料(寫架構圖節點),不是網搜。

## 前置(架構圖先行)
每專案一個 `Issues/linter-gap實務隱患.md`(type issue)。**先讀它**(去重基準):
```
lumos context linter-gap實務隱患        # 無 → lumos new issue "linter-gap實務隱患"
```
節點兩段:**〈已採納〉**(放行的坑)、**〈已評估駁回〉**(駁回的坑+反證)。step 2 搜到的凡已在這兩段 → 跳過,不重找重駁。

## workflow(照做)

1. **確認已覆蓋範圍**:讀該專案 `.lumos/lint.json` 宣告的 linter(得知哪些坑已被 lint-adapter 蓋)。網搜目標 = **linter 沒蓋的**。
2. **WebSearch**:搜「<stack> <版本> gotcha / pitfall / footgun / common mistake linter doesn't catch」等。收成候選坑清單(每條:一句描述 + 來源 URL + 觸發條件)。**濾掉**:① linter 已蓋的 ② 已在節點兩段的 ③ 專案沒用到的 API/情境。
3. **反證預篩**(借鏡 `lumos-design-loop` 的辯方 / [[finding-refute]]):對**每條**候選,用 Agent tool 派**乾淨 refuter**(獨立脈絡),framing:
   > 「預設這條坑是**假的 / 不適用本專案**。構造反駁證據:它是否過時(框架已修)、是否 linter 其實有規則、是否本專案根本不會踩(用 grep/Read 實際代碼查)。**必須附來源或 `file:line`,光說『沒問題』不算**;拿不出反證才算駁不倒。」
   - refuter 回「駁倒(附證據)」→ **丟掉**(可選記進〈已評估駁回〉附反證,避免下次重找)。
   - refuter 回「駁不倒」→ 進候選。
4. **候選 = 非定論**:駁不倒的坑,連**來源 + 反證嘗試結果**,攤給人。
5. **人輕量放行**(oracle 省不掉):人判這坑對本專案業務/技術現實是否真值得記。
   - 放行 → `Issues/linter-gap實務隱患` 的**〈已採納〉**段:坑描述 + 觸發條件 + 來源 URL(body 表格用 Edit;純量/list 走 lumos)。
   - 駁回 → **〈已評估駁回〉**段:坑 + 為何駁(下次 step 1 跳過)。
6. **收尾**:節點 `lumos lint` 自驗 → `lumos doctor`。放行的坑之後可被 pitfalls 進場當隱患鏡頭餵(像 refcheck manifest,同 ④ 事故語料)。

## 誠實天花板(務必向人複述,別讓「駁不倒」被當「真」)
1. **無機械 oracle**:「舉不了反證 ≠ 真」——這是**缺席證明謬誤**,加上**反證者能力上限**(refuter 沒駁倒可能只是它不夠強,同 canary/`[audit:]`/refcheck 天花板:驗形式不驗真值)。候選是「醒著的反證者沒駁倒」,不是「已證為真」。
2. **人閘省不掉**:最終真偽 + 是否值得記,靠人對業務/技術現實判。skill 只做**篩選 + 推到眼前**,不做定論。
3. **量少邊角**:linter 覆蓋大宗;這只補殘餘新坑。跑太勤 = 噪音。

> 設計見 `Projects/pitfalls網搜補漏_計劃`(解 `pitfalls-lint-integration_計劃` ③)。跳 design-loop(純散文 skill,design-loop 對散文空轉),驗收走 dogfood 真 stack。

## 高危 pattern → known-pitfall 節點(已知坑策展庫 v2,2026-08-09)
網搜坑放行後,若屬**高危設計 pattern**(認證/token/並發/快取/遷移…世界通用,非本 repo 專屬):除進 linter-gap 表,**另建 known-pitfall 節點**(快取式,第一次碰該 pattern 才建):
`lumos new system known-pitfall-<pattern>` → `lumos append <node> pitfall_when "content:<寬 regex>"` → `lumos set <node> pitfall_ask "<一句隱患提問>"` → `lumos set <node> pitfall_source "<世界來源 URL>"`。
之後任何 spec 文本命中該 regex,pitfalls 自動 advisory 攤出此坑(design-time,跨 session 記憶——不賭下顆 LLM 剛好熟)。★人放行才建,不自動(maker bias 鐵則);pitfall_when 走 append 存 block-list,勿手打 flow-list★。
