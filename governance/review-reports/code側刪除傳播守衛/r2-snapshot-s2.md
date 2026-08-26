---
type: project
status: todo
created: 2026-08-10
updated: 2026-08-10
related:
  - "[[關係層傳播守衛_計劃]]"
  - "[[cochange守衛_計劃]]"
  - "[[Systems/cochange-guard]]"
tags:
  - type/project
  - status/todo
  - scope/governance
summary: |-
  FLOW:code diff 的 `-` 行抽出被刪識別字→grep 架構圖內文→列出「還在講它」的節點與原句→逐句問「這句還成立嗎」→改掉或標作廢
  KEY:★這是兩個既有守衛之間的接縫,不是新問題面★—[[關係層傳播守衛_計劃]] 自己寫明「pre-commit 只保證 code↔架構圖同次有動(檔案級存在性),保證不了決策翻案→下游校正(跨節點語意傳播)——不同顆粒度、不重疊」,把 code↔節點 這個方向劃給 pre-commit;而 pre-commit Gate 3 實際只判「有沒有任何一個架構圖 .md 進 staged」。兩邊各自以為對方管了
  KEY:★真實失守實錄(mOrangePos commit aff2329,2026-08-03)★—該 commit 移除登入自動撈 2C2P 憑證。它**有**帶架構圖更新、五個檔,Gate 3 放行;但其中三個 Systems 節點各自只改 1 行,而那一行是 `+  - "[[Verification/2026-08-03_...]]"`。★只掛連結,被推翻的敘述一個字沒改★。七天後(2026-08-10)排查時才發現六個節點+四處 code 註解仍在講「登入時 GetPaywayCredential 撈一次」,其中一個節點還拿這個不存在的前提當設計理由
  KEY:★失守形狀=「新增紀錄很容易,修正舊敘述容易被跳過」,而閘門只認得前者★—掛連結的人主觀上真的認為自己同步過了,所以泛問「有沒有漏更新?」永遠得到「沒有」。要破必須讓問句自己帶查法(見下方 S3)
  KEY:偵測面=從 diff 的 `-` 行抽識別字(函式/欄位/常數/端點路徑)→在 vault 內文 grep→命中即候選。★這次的案例會被抓到★:被刪的是 refreshPaywayCredentials 呼叫,六個節點內文有 refreshPaywayCredentials/GetPaywayCredential 字面。★「這行被刪」≠「符號從 repo 消失」★—call site 移除但函式還活著時,架構圖講它未必過期;只認全域消失又會漏本次這型(拿掉的是「登入時呼叫」這個行為,符號未必全滅)→ 抽取分兩檔信心:全域消失=高信心報、僅呼叫點消失=低信心報。★「全域消失」判定快照=staged index(git grep --cached;worktree 會被未 staged 內容救回、HEAD 看不到已 staged 新增,r1 折入)★;alternation 逐 token re.escape;S1 只認被刪行實際存在的 token、不做 call graph
  KEY:第二道=★純連結編輯不算同步★—判該節點本次 diff 是否只動 frontmatter 的 list 型欄位(★欄位清單不手列,讀 lumos LIST_KEYS 常數為單一真源+core_refs;r1 三席一致:手列三欄漏 plan_refs=假同步逃逸★);若是,且它同時被 S1 grep 命中(內文還在講本次被刪的符號)→ 標出來。YAML 重排/正規化 diff 一律判「有動內容」(保守朝不報)。直接對準本次失守形狀。★觸發鍵刻意取 S1 命中而非 impact 必看名單★—掛 impact top-8 會繼承它的漏抓
  KEY:★天花板(誠實講)★—只抓「符號消失」這一型。行為反轉但名字沒少(例:`isStock = if(isSend=="Y") prefs.isStock else false` 改成 `isStock = prefs.isStock`)完全不會響;純語意矛盾更不會。S2 也有逃逸形狀:body 隨手補一行新敘述、被推翻的舊句照樣不改,diff 就不是「純連結」,S2 靜默(=「只改最相關段、漏散落列舉表」的已知失敗型)。這是提高地板,不是全覆蓋——語意那半仍歸 AI 交叉審與 [[關係層傳播守衛_計劃]]
  KEY:誤報來源逐項處置(r1 折入)=檔案搬移(git diff -M 治得了)｜符號改名(檔內改名 -M ★治不了★,v1 明文不解、歸低信心+誤報帳)｜註解提及/同名符號(v1 不判,advisory 吸收,明文取捨)｜歷史記載節點(★字樣標記判定撤案★—substring 誤抑制「尚未作廢」;改節點型別過濾:Systems 高信心、Projects/Verification 壓最低,接實測②)。★刷屏也是失敗模式★—advisory 刷屏=訓練人無視它;識別字 cap 先驗 40、超 cap 保留高信心 top-10+一行統計(證據不清零);★超時契約:偵測器主體 python3 內建 deadline,|| true 只兜 crash 不兜 hang★;--no-verify 繞過留痕沿用既有 post-commit bypass 帳(r1 訂正:原稱「無留痕」有誤)
  PRIOR-ART:①最小解在既有層—pre-commit Gate 3 與 `impact --sync-check` 兩支都已存在,只需加一個判斷(被刪符號→grep vault)與一個 diff 分類(純連結 vs 有動內容),不造新機制、不新增治理層 ②世界解過—**Swimm** 做的正是 code-coupled docs:文件綁到具體 code 片段,被引用的 code 一改就把該文件標為過期,且分三級(up-to-date / out-of-sync 可自動修 / outdated 需人判),攔截點在 IDE 與 PR 合併前;另有 doc-drift CI 的作法(合併後掃,補本地 hook 漏的) ③裁定=**borrow-design**(借 Swimm 的三級分類與「攔在合併前」的時機,原生實作;零依賴家規排除 adopt)
  KEY:★與 Swimm 的刻意偏離★—Swimm 要求文件明確嵌入 code 錨點(Smart Tokens)才能耦合,精度高但有撰寫成本;本設計改用**識別字字面 grep**,精度低於錨點但★對 mOrangePos 既有 150 篇筆記零改造成本★。取捨已知:換來誤報,故先做 advisory 不硬擋
  KEY:★2026-08-10 mOrangePos 實跑帶回的四筆實測(詳見內文)★—①誤報率有真數字:1697 候選→183 找不到→**逐個判定真 drift 僅 6**(精確率約 3%,無過濾版地板;雜訊類別可枚舉:測試單號/外部 API 欄位/DB 欄位/後端 C# 符號/gradle task/架構圖 frontmatter 欄位/Android SDK 概念/lint 規則 ID/姊妹專案類別) ②★最強過濾訊號是節點型別不是字串規則★—6 筆真 drift **全落在 Systems/**;Projects 提到不存在的名字多半是「還沒實作的預定名稱」、Verification 多半是「正在記載該符號被移除」→建議 Systems 高信心報、Projects/Verification 壓最低 ③★存量掃描抓到 diff 版永遠抓不到的一型★—ArithUtil.kt/CartSummaryCalculator.kt 檔案都在但裡面沒同名物件(是 top-level 函式),架構圖把檔名當物件名寫成 `ArithUtil.round(v,scale)`,照著寫編不過;**從沒有 diff 刪過任何東西** → S1 永不觸發。故存量掃描(一次性,不進閘)與增量掃描(S1,進閘)抓的是不同東西,兩個都要 ④識別字掃勝過關鍵字掃的實例—`Systems/售完狀態雲端同步` 還在講付款設定頁的 etPnqrKey,前一輪用「憑證」關鍵字掃漏掉(節點名與主題對不上,人不會想去翻);★人會按主題找,而 drift 不按主題分布,這正是機械檢查存在的理由★ ⑤順帶產出真實驗收案例—同次把死碼真刪掉後,架構圖四個節點措辭要從「死碼」改成「已刪除」=★刪除本身又製造一批 drift,而這批正是 S1 的正字標記★,可重放
  DECISION:[2026-08-10]先軟提醒不硬擋,跑一段時間收誤報率再決定要不要升級成擋(對齊 sync-check 的 advisory 級別)
  DECISION:[2026-08-10]落點裁定=pre-commit Gate CC 旁,不放 impact --sync-check(輸入不等價:S1 契約=staged index,sync-check 是 branch-range 模式;r1 Codex 席升級自「傾向」)(valid)
decisions:
  - content: |-
      先做 advisory 軟提醒（不擋 commit），不直接升級成 pre-commit 硬擋
    context: |-
      識別字字面 grep 的誤報來源明確存在（改名、註解提及、同名符號、架構圖刻意保留的歷史段落），
      誤報率未知；而 pre-commit 硬擋一旦誤報就是擋住正常工作，反彈會導致整條規則被 --no-verify 繞過
    alternatives_considered: |-
      ①直接硬擋 ②advisory 軟提醒 ③只在 code-loop 終審跑（頻率低但漏日常 commit）
    why_chosen: |-
      對齊既有 `impact --sync-check` 的級別（advisory、人判）。先讓它跑、累積誤報樣本，
      有數字再談要不要升級——這與 cochange-guard 當初的路徑一致（Gate CC 至今仍是 `|| true` 隔離的軟提醒）
    trade_offs: |-
      軟提醒可以被無視，本次失守正是「被推播了仍只掛連結」。故 advisory 版必須配 S3 的問句紀律
      （帶查法、要求貼原句），否則會複製同一個失敗。
    decided: 2026-08-10
    valid: true
  - content: 落點裁定:掛 pre-commit 的 Gate CC 旁(advisory、|| true 隔離、與 cochange 同級),不放 impact --sync-check
    id: d1
    context: r1 Codex 席指出兩候選入口輸入不等價:Gate CC 直接讀 staged index;impact --sync-check 是 branch-range 模式(scripts/lumos:13253-13254 配 --diff)。放後者則 pre-commit 時 range 未定義(initial commit/detached HEAD/amend/部分 staged 全懸空),混用兩套快照會錯判
    alternatives_considered: |-
      ①Gate CC 旁(staged index,與 S1 的 --cached diff 同快照) ②impact --sync-check 內(需另造 pre-commit 時的 range 語意)
      ③兩邊都掛(重複告警、兩套快照並存)
    why_chosen: S1 的輸入契約=staged snapshot,只有 pre-commit 天然持有;快照一致性是本守衛正確性的前提,不是實作偏好
    trade_offs: |-
      impact hook 在編輯當下的即時推播不帶本守衛訊號;接受——刪除在編輯當下未必成形,commit 時點才是刪除的定案點。
      日常 commit 頻率高於 code-loop 終審,advisory 曝光面反而更大
    decided: 2026-08-10
    valid: true
---
# code 側刪除傳播守衛_計劃

**Goal:** 讓「code 拿掉了某個東西、架構圖還在講它」這一型過期，在 commit 當下就被指名到**具體哪一句**，而不是七天後排查時才撞見。

> **狀態：待評估與拍板。** 由 mOrangePos 那邊排查 2C2P 付款問題時撞到本問題、就地寫回。
> 進實作前依家規需過 `lumos-design-loop`。

---

## 一句話

**架構圖的閘只檢查「有沒有寫」，不檢查「舊的寫錯了沒」。**

新增一條連結、寫一篇新的 Verification，都算「有更新」；而把被推翻的那句話改掉，沒有任何機制在要求。於是新東西一直長，舊東西一直爛。

## 失守實錄（這不是假想案例）

mOrangePos `aff2329`（2026-08-03）把「登入時自動撈 2C2P 憑證」移除，改成設定頁手填。

那個 commit **有**帶架構圖更新，動了五個檔，pre-commit Gate 3 放行。但攤開來看：

```diff
# 三個 Systems 節點，各自的完整 diff 就是這一行
+  - "[[Verification/2026-08-03_MID與SecretKey改設定頁手動輸入]]"
```

**只掛了連結。** 被推翻的那段「登入 setEmpFlag 時 GetPaywayCredential 對 51/52 各撈一次」原封不動躺在新連結旁邊。

七天後（2026-08-10）排查時掃出來的後果：

| | |
|---|---|
| 節點仍在講已移除的機制 | **6 個** |
| 程式碼註解同病 | **4 處** |
| 其中把不存在的前提**當成設計理由**的 | 1 個（`QrPayNo.kt` 用「登入時不需為 55–58 各撈一次」解釋為何共用憑證——而登入根本不撈；★結論對、理由是假的★） |
| 整個計劃節點的前提被架空的 | 1 個（mOrangePos vault 的 `2C2P轉正式fail-safe_計劃`，其「正式值由後端下發」前提；非本 repo 節點） |

## 為什麼它落在守衛之間

`[[關係層傳播守衛_計劃]]` 的 summary 自己寫著：

> pre-commit 只保證 code↔架構圖同次有動（檔案級存在性），保證不了決策翻案→下游校正（跨節點語意傳播）——不同顆粒度、不重疊

它把 **code↔節點** 這個方向劃給 pre-commit，自己專心處理 **節點↔節點**。而 pre-commit 的 Gate 3 實際上是：

```bash
# Gate 3: 有架構圖 .md staged → 放行
if echo "$STAGED" | grep -qE "^${GRAPH_ROOT}/.*\.md$"; then
  exit 0
fi
```

任何一個架構圖檔，改任何內容，都放行。**兩邊各自以為對方管了。**

---

## S1 · 被刪符號偵測（機械，主力）

從 `git diff --cached` 的 `-` 行抽出被刪掉的識別字（函式名、欄位、常數、端點路徑），拿去 grep vault 內文。命中的節點＋原句列出來。**合成 alternation 時每個 token 必須 `re.escape`**（端點路徑含 `.`/`{}` 等 metachar，裸拼會誤配或炸 regex；沿 `scripts/lumos` 既有慣例 `"|".join(map(re.escape, ...))`，見 :7189/:10951）。

本次案例會被抓到：被刪行含 `refreshPaywayCredentials()` 呼叫，vault 六個節點有該字面。**精確講**：S1 只認被刪行實際存在的 token，不做 call graph——只寫 callee 名 `GetPaywayCredential` 的節點，要等到該方法宣告行本身被刪（後續死碼清理那次）才命中。

**誤報來源（設計時先想好，不是事後補）**，逐項處置：
- **檔案搬移**：`git diff -M` 偵測 rename，整檔搬移不產生刪除行——這條 `-M` 治得了。
- **符號改名**（檔案路徑不變、函式在檔內改名）：`-M` **治不了**——舊名照樣出現在 `-` 行。已知誤報源，v1 不解，歸低信心檔＋advisory 吸收＋誤報帳記錄；不寫「改名不誤報」的假測試。
- **註解裡提及／不相干的同名符號**：v1 不判，advisory 吸收＋誤報帳記錄（明文取捨，非遺漏）。
- **歷史記載節點**：不用字樣標記判斷（「已作廢」substring 會誤抑制「尚未作廢」，且標記形式無機械定義）——改用下方 mOrangePos 實測 ② 的**節點型別過濾**：`Systems/` 才高信心報，`Projects/`／`Verification/` 本來就會講預定名稱與歷史，預設壓到最低。

**兩檔信心——「這行被刪」≠「這個符號從 repo 消失」**：call site 被移除但函式還活著、還被別處用，這時架構圖講它未必過期；反過來只認「repo 全域消失的符號」精度高，但會漏掉本次這型（拿掉的是「登入時呼叫」這個行為，符號未必全滅）。抽取規則分兩檔：**全域消失＝高信心報、僅呼叫點消失＝低信心報**。**「全域消失」的判定快照＝staged index**（`git grep --cached`，與 pre-commit 契約對象一致；grep working tree 會被未 staged 內容「救回」、grep HEAD 看不到已 staged 新增——兩者都判錯），排除域重用 pre-commit 既有 `should_exclude`（vault／build／vendor）。此掃描成本入效能預算（見實務隱患），識別字 cap 同時限制它的次數。

**刷屏也是失敗模式**：大型 refactor 會噴出海量 `-` 行，advisory 一旦刷屏就是在訓練人無視它（trade_offs 已承認「軟提醒可以被無視」，別再自己加速）。`git diff -M` 吃掉檔案搬移；識別字 cap 先驗暫用 **40**（replay 校準後以數據取代）；**超 cap 不是全丟**——保留高信心（全域消失）命中 top-N（先驗 N=10）逐條列，其餘壓成一行統計，證據不清零。

## S2 · 純連結編輯不算同步（機械，補刀）

判斷一個節點本次的 diff 是否**只動了 frontmatter 的 list 型欄位**。欄位清單**不自行枚舉**——以 `scripts/lumos` 的 `LIST_KEYS` 常數為單一真源（現值 `verified_by`/`plan_refs`/`related`/`tags`/`aliases`/`pitfall_when`，`scripts/lumos:6224`），另加 `core_refs`（同款純連結語意）；實作直接讀該常數，常數演進自動跟上（r1 三席一致抓到：手列三個欄位漏掉 `plan_refs`，只 append plan_refs 的假同步正好逃逸）。若是純連結編輯，而它**同時被 S1 的 grep 命中**（內文還在講本次被刪的符號）→ 標出來。

**diff 邊界判定（保守朝不報）**：「只動 list 欄位」以行級 diff 判——每個變更行都落在 frontmatter 的 list 欄位區塊內才算。YAML 重排／縮排變化／scalar↔list 正規化造成的整段 diff 一律判「有動內容」（S2 不報）——寧可漏報這種罕見形狀，不把格式化誤標成假同步。

直接對準本次的失守形狀。S1 抓「該改而沒改」，S2 抓「假裝改了」。

**觸發鍵刻意取「S1 命中」而不是「impact 必看名單」**：「內文還在講被刪的符號＋這次只給它掛了條連結」正是本次事故的精確形狀；掛在 impact top-8 名單上反而繼承它的漏抓（六個中招節點未必都進得了 top-8）。

## S3 · 問句帶查法（人判那一半）

機械只能指出「哪一句提到了你刪掉的東西」，**「那句話還對不對」是判斷，機器做不了**。

但泛問會失效——本次那六個節點大概率都被 `impact` hook 推播過，結果仍是掛連結了事。**問題不在有沒有問，在問得夠不夠具體**：泛問可以在腦內三秒答完，指著某一行問「這句還對嗎」很難含糊。

問句本體（S1 命中時吐出，或無 S1 時當退場紀律用）：

```
退場前自問（逐條寫下答案，不可略過；「沒有」也要具名）：

1. 這次改動「拿掉」或「反轉」了什麼？
   （函式、呼叫點、欄位、條件、預設值、流程的某一段——
     不是問你新增了什麼，過期幾乎都來自拿掉）

2. 把那些名字逐個丟進 lumos search --code。
   （--code 必帶：search 預設排除 code block，而過期範例常躲在 code fence 裡；
     另注意 search 預設排除 superseded 節點——與 S1 的字面 grep 不是同一搜尋域）
   哪幾個節點的內文在描述它們？把原句連節點名貼出來。

3. 逐句判：這句話，在你這次改動之後還成立嗎？
   · 還成立 → 一句話說明為什麼
   · 不成立 → 現在就改掉，或標作廢並註明何時被推翻

⚠ 新增一條 verified_by / related 連結不算同步。
   同步 = 被推翻的那句話被改掉或標作廢。
```

**第 2 步是重心。** 少了它，第 3 步沒有東西可以逐句判，整段會塌回泛問。有 S1 的話這一步由機器代跑，精度更高；沒有 S1 時它至少把查找變成一個有輸出的動作，而不是憑印象。

---

## 天花板（誠實講，不要之後被當成全覆蓋）

**只抓「符號消失」這一型。** 行為反轉但名字沒少的，完全不會響——例如同一批排查裡的另一個案例：

```kotlin
isStock = if (isSend == "Y") prefs.isStock else false   // 改成 ↓
isStock = prefs.isStock
```

`isStock` 一個字都沒少，S1 不會有反應。純語意矛盾（兩篇內容打架）更不會。

**S2 也有自己的逃逸形狀**：在 body 隨手補一行新機制的敘述、被推翻的舊句照樣不改，diff 就不是「純連結編輯」，S2 靜默放行——這正是已知的失敗型「機制同步只改最相關段、漏散落的列舉表」。S2 只當便宜絆線用，別把它當「假同步」的全覆蓋。

**這是提高地板，不是天花板。** 語意那半分兩個承接者：typed-edge 傳播歸 `[[關係層傳播守衛_計劃]]`（它只掃 frontmatter 可判的關係），**純語意矛盾只歸 AI 交叉審**——兩者別併寫成一個。本守衛的定位是**機械前濾網**，讓貴的那關少看一點東西。

## 世界怎麼解的（PRIOR-ART ②）

**Swimm** 做的正是這件事：文件綁到具體 code 片段（Smart Tokens），被引用的 code 一改就把該文件標為過期。值得借的三點：

1. **分三級不是二值** — up-to-date ／ out-of-sync（改名、位移這類可自動修）／ outdated（實質變動，需人判）。S1＋S2 是**概念上**對應後兩級（同樣把「過期」分粗細），不是輸出契約對應——S1/S2 都只出 advisory、不自動修，別把類比讀成同構。
2. **攔在合併前**，不是事後掃。
3. **耦合的是「文件引用了哪段 code」**，不是「文件多久沒改」。時間不是新鮮度的指標。

**刻意偏離**：Swimm 要求文件明確嵌入錨點才能耦合——精度高，但有撰寫成本，且對既有筆記要回頭補。本設計改用**識別字字面 grep**，精度較低但**對 mOrangePos 現有 150 篇筆記零改造成本**（本 repo 254 篇同樣受益，機制是通用的）。取捨已知：換來誤報，所以第一版走 advisory。

出處：[Swimm — code-coupled docs](https://swimm.io/blog/swimm-native-integrations)、[Doc Drift Detection in CI](https://understandingdata.com/posts/doc-drift-detection-ci/)

---

## 實務隱患

**此功能碰到的風險類**：self-governance（守衛面）、效能（pre-commit 熱路徑）、輸入健壯性／可攜性（r1 補）。逐類答：

- **self-governance／誤擋的逃生口**：v1 是 advisory、恆 rc0，不存在誤擋。實作上必須比照 Gate CC 用 `|| true` 隔離——偵測器自己出 bug 也不准擋 commit（fail-open）。若日後憑誤報數據升硬擋，逃生口＝`--no-verify`（沿用 Gate 1 既有慣例，錯誤訊息裡印出來）；**繞過留痕已有現成機制**——`scripts/hooks/post-commit` 整支就是 bypass 偵測（`--no-verify` 跳不過 post-commit，事件落 `docs/.bypass-log.jsonl`，實存有真實資料），v1 直接沿用，不新造（r1 訂正：原稿誤寫「目前無留痕」）。
- **效能（熱路徑）**：pre-commit 每次 commit 都跑。前例教訓：Env vault 掃描曾低估到 4.7 秒被判 blocker。上限設計：①識別字抽取只吃 `--cached` diff 的 `-` 行（量小）②grep vault 不做 N 個符號 N 次掃，合成單條 alternation regex（逐 token `re.escape`）一次掃 254 檔③識別字 cap 先驗 40，超 cap 保留高信心 top-10、其餘壓一行統計④**兩檔信心的 staged-index 掃描（`git grep --cached`，最多 cap 次）一併入預算**⑤總預算目標 <1 秒。
- **超時的實作契約（`|| true` 兜不住 hang）**：`|| true` 只吞非零 rc，偵測器卡死時 commit 會無限等待。故偵測器主體＝**python3 內建 deadline**（`time.monotonic` 檢查點＋`subprocess.run(timeout=)` 包外部命令），到點自行輸出降級訊息、rc0 退出；不依賴 GNU `timeout`（macOS 無、零依賴家規）。bash 端 `|| true` 只兜 crash，不兜 hang——hang 由 python 內部 deadline 兜。
- **輸入健壯性／可攜性**：所有 git diff 呼叫帶 `-c core.quotePath=off`（CJK vault 檔名不加會被 git 引號包裹、路徑比對失敗——`scripts/hooks/pre-commit:36-39` 踩過的坑）；偵測邏輯全在 python3（不用 shell grep，避 BSD/GNU 方言）；binary diff 跳過；`-`/`---` diff 標頭行不得當內容抽取。
- **併發**：無——hook 每次 commit 單進程、對 vault 只讀不寫，無共享資源競態。**前提＝誤報帳不屬 v1 runtime**（見下），偵測器全程零寫入。
- **資源**：無——純檔案讀取，無連線／鎖／長駐進程。
- **誤報帳的狀態**：**明文不進 v1 偵測器 runtime**——v1 誤報樣本由人（或 AI 會話）事後手動記錄，落地格式歸待辦（傾向 append-only jsonl，與 governance-log 同款慣例），不引入新資料庫。何時自動化＝升硬擋議題的一部分，憑數據再談。

**已排除**：金流／對外送出／PII／認證／快取／遷移——本機制只讀 git diff 與 vault 文字，不碰任何業務資料面。

---

## 測試策略（已知行為，TDD）

機械層（S1/S2）行為可枚舉，走 TDD；S3 是人的紀律，無機械 oracle，誠實不寫湊數測試。

| 對象 | 測試（fixture diff → 預期輸出） |
|---|---|
| S1 命中 | 刪含 `refreshPaywayCredentials()` 呼叫的行、vault fixture 含該字面 → 報「節點＋原句」 |
| S1 兩檔信心 | 符號自 **staged index** 全域消失 → 高信心；僅呼叫點消失、定義仍在 → 低信心 |
| S1 快照契約 | staged 刪除＋working tree 未 staged 同名新定義 → 仍判高信心（以 index 為準，不被 worktree 救回）；partial hunk stage → 只認 staged 部分 |
| S1 邊界輸入 | initial commit（無 HEAD）不炸；binary diff 跳過；CJK 路徑（quotePath）正常；`---`/`+++` 標頭行不被當內容抽取 |
| S1 檔案搬移不誤報 | 純檔案 rename（`git diff -M` 偵測）→ 不報 |
| S1 符號改名 | 檔內改名 → **會報（已知誤報，v1 明文取捨）**——測試只釘「落在低信心檔」，不假稱不報 |
| S1 escaping | 被刪 token 含 `.`/`{}`/`\|` metachar → regex 不炸、不誤配 |
| S1 刷屏降級 | 識別字超 cap(40) → 保留高信心 top-10 逐條＋其餘一行統計（證據不清零） |
| S1 節點型別過濾 | 同一命中出現在 `Systems/` 與 `Projects/` fixture → 前者報高信心、後者壓低（取代字樣判「歷史段落」） |
| S2 純連結判定 | 節點 diff 只動 `LIST_KEYS`∪`core_refs` 欄位 → 判「純連結」；多改任一行 body → 判「有動內容」 |
| S2 觸發合取 | 純連結 ∧ S1 命中 → 報；純連結 ∧ 無 S1 命中 → 不報 |
| S2 邊界 | YAML 重排／縮排／scalar↔list 正規化 → 判「有動內容」（保守不報） |
| 效能 benchmark | 254 檔 vault、40 識別字 → 總時 <1s（正常量級，寬鬆時限） |
| timeout fail-open | 注入可控 hang（或極短 deadline）→ deadline 後偵測器自行終止、rc0、輸出降級訊息（與 benchmark 分開測，小 fixture 觸發不了真 timeout） |
| fail-open | 偵測器自身拋錯 → commit 不被擋（`\|\| true` 隔離） |

回歸錨：**vendored 合成 fixture**——把 aff2329 的失守形狀重建成最小合成 diff＋合成筆記（六節點型：三個只掛連結、內文留舊敘述），進本 repo 測試目錄；**不依賴外部 repo 的 SHA**（mOrangePos 是商業碼，原 diff 不可入庫；去敏後只留形狀）。

## 審計修正紀錄

- **pre-flight（2026-08-10，機械排乾，不計 loop findings）**：①補「測試策略」節（原 spec 無驗證方式描述）②失守實錄表格中 `2C2P轉正式fail-safe_計劃` 標明為 mOrangePos vault 節點（原文易誤讀為本 repo 節點，refcheck 型歧義）。同批：實務隱患節係 pitfalls --check rc1 後補（風險類反問 S0）。
- **r1（2026-08-10，panel 3 席：sonnet 通才／sonnet 正確性／Codex 邊界整合；三席 canary 全 caught；報告與快照存 `governance/review-reports/code側刪除傳播守衛/`）**：跨席去重後折入 13 條——①S2 欄位白名單改讀 `LIST_KEYS` 常數＋`core_refs`（三席一致）②alternation 逐 token `re.escape`（兩席）③「--no-verify 無留痕」訂正為沿用既有 post-commit bypass 留痕④rename 拆兩型：檔案搬移 `-M` 治、符號改名明文 v1 不解⑤「全域消失」快照定為 staged index（`git grep --cached`）＋成本入預算⑥CJK quotePath／python3 主體／binary diff 等輸入健壯性入風險類⑦timeout 契約：python 內建 deadline，`\|\| true` 不兜 hang⑧cap 先驗 40／超限保留高信心 top-10⑨歷史段落字樣判定撤案，改節點型別過濾（接 mOrangePos 實測 ②）⑩S3 問句改 `search --code` 並註明搜尋域差異⑪S1 案例句識別字精度訂正（不做 call graph）⑫測試策略補 staged 快照契約／timeout 拆測／vendored 去敏 fixture⑬落點裁定 Gate CC 旁（ADR）。另兩條措辭級：天花板承接者分寫、Swimm 對應降為概念級。**流程事件**：真檔在 r1 進行中被補入 mOrangePos 實測節（1697→183→6 等），被審快照未含——該節由 r2 delta 補審。誤報 183 筆已逐類折進「測試策略」節的誤報對照測試列，每類一列。

---

## 2026-08-10 · mOrangePos 實跑一次全圖版，帶回四筆實測

把 S1 反過來當**存量掃描**跑了一次（不是從 diff 抽被刪符號，而是從架構圖內文抽識別字 → 比對現行原始碼）。這是設計時沒想到的用法，結果比預期有用。

### ① 誤報率有真數字了：1697 → 183 → 6

| | |
|---|---|
| 架構圖內文抽出的候選識別字 | 1697 |
| 原始碼中找不到的 | 183 |
| 逐個判定後**真 drift** | **6** |

精確率約 **3%**。這是「無過濾版」的地板數字——183 筆裡的雜訊**類別是可枚舉的**，濾掉之後會好很多：

- 測試資料（訂單號 `M042026...`、商品碼 `GFF29K102F2`、交易號 `ccpp_15332051`）
- 外部 API 欄位（2C2P 的 `agentCode`/`clientID`/`processBy`/`return_url`）
- DB 欄位與後端 C# 符號（`PK_OrdersPayway`、`WriteAppEventLog`、`FrasersLiveDB`）
- gradle task（`assembleDevDebug`）、架構圖自己的 frontmatter 欄位（`plan_refs`）
- Android SDK 概念（`LaunchedEffect`、`onBackPressed`）、lint 規則 ID
- **姊妹專案的類別**（節點自己寫明「姊妹專案 CompassKiosk 的 `UsbEscPosPrinter`」）

### ② ★最強的過濾訊號是節點型別，不是字串規則★

真 drift **6 筆全部落在 `Systems/` 節點**。而 `Projects/` 與 `Verification/` 提到不存在的符號**多半是正確的**——

- 計劃節點寫的是**還沒實作的預定名稱**（`tvCashIn`、`packagingQtyFor`），提到不存在的東西天經地義
- 驗證節點記的是**歷史**（`btnRefreshCredential` 是它正在記載被移除的那個按鈕）
- 甚至有節點正文就寫著「`isDateFilterActive` 旗標**已移除**」——報它等於報自己

**建議**：`Systems/` 高信心報、`Projects`/`Verification` 預設不報或壓到最低。這一條比任何 token 正則都省事。

### ③ 存量掃描抓到 diff 版**永遠抓不到**的一型

```kotlin
// 架構圖寫的
ArithUtil.round(v, scale)

// 實際上 ArithUtil.kt 裡沒有 ArithUtil 這個物件，是 top-level 函式
import com.citrus.morangepos.util.round
round(v, scale)
```

`ArithUtil.kt` / `CartSummaryCalculator.kt` 兩個**檔案都在**，但裡面沒有同名物件。**從來沒有任何 diff 刪掉過什麼**——架構圖是一開始就把檔名當成了物件名。S1（diff 觸發）永遠不會響。

→ **存量掃描與增量掃描抓的是不同東西，兩個都要有。** 增量防新增的 drift，存量清歷史欠帳。存量版跑一次就好，不必進閘。

### ④ 識別字掃勝過關鍵字掃的實例

同一批 drift 裡有一筆是 `Systems/售完狀態雲端同步` 還在講付款設定頁的 `etPnqrKey` 欄位（該欄位隨憑證改手填一起移除）。

前一輪用**關鍵字**（「憑證」「GetPaywayCredential」）掃時**漏掉它**——因為節點名叫「售完狀態雲端同步」，主題對不上，人不會想到去翻。識別字掃不看主題，直接命中。

**這正是機械檢查存在的理由**：人（和 AI）會按主題找，而 drift 不按主題分布。

### ⑤ 順帶驗證了「刪除」這個動作本身

同一次把死碼真的刪掉（`refreshPaywayCredentials` 整條路徑，含 API 方法、VO 檔、常數、prefs 欄位）。刪完後**架構圖有四個節點的措辭要從「死碼」改成「已刪除」**——也就是說**刪除本身又製造一批 drift**，而這批正是 S1 的正字標記（符號從 repo 消失、架構圖還在講）。

如果 S1 當時在線上，這四處會被當場點名。這是一個**真實可重放的驗收案例**，比造一個測試 fixture 有說服力。

---

## 待辦

- [x] ~~決定放哪一層~~ → **已裁定：`pre-commit` 的 Gate CC 旁**（advisory，與 cochange 同級；ADR 見 decisions）。r1 Codex 席把這題從「傾向」升到裁定：兩入口**輸入不等價**——Gate CC 直接讀 staged index，`impact --sync-check` 是 branch-range 模式（`scripts/lumos:13253-13254` 配 `--diff`），放後者則 pre-commit 時 range 未定義（initial commit／detached HEAD／amend 全懸空）
- [ ] S1 的識別字抽取規則細化（哪些 token 值得抽、怎麼避開字串與註解；cap=40/top-10 為先驗值，replay 校準後以數據取代）
- [ ] S2 的「純 list 欄位 diff」判定實作（讀 `LIST_KEYS` 常數，行級 diff 邊界照 S2 節定義）
- [ ] 誤報樣本蒐集方式（v1 人工記錄；格式傾向 append-only jsonl；有數字再談升級硬擋）
- [ ] S3 問句放 `lumos-project-notes` skill 的退場段（user-scope，跨專案生效）還是各專案 CLAUDE.md——**此項是 v1 交付的一部分，不是可延後項**：decision 明言「advisory 版必須配 S3 否則複製同一個失敗」，S1/S2 落地而 S3 懸空＝decision 未兌現
- [ ] 存量掃描一次性跑法收尾（mOrangePos 實測 ③：增量防新 drift、存量清歷史欠帳；存量跑一次即可，不進閘）
