---
type: project
status: todo
created: 2026-08-10
updated: 2026-08-12
self_audit: sonnet/2026-08-10
related:
  - "[[關係層傳播守衛_計劃]]"
  - "[[cochange守衛_計劃]]"
  - "[[Systems/cochange-guard]]"
  - "[[Systems/delguard]]"
  - "[[Systems/check-y-symbol-existence]]"
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
  KEY:第二道=★純連結編輯不算同步★—判該節點本次 diff 是否只動「純連結欄位」=★明確子集 LINK_KEYS={verified_by,plan_refs,related,core_refs},不整包吃 LIST_KEYS★(r2 改判:LIST_KEYS 語意=append 寫入白名單非連結語意,pitfall_when 是 content-trigger、tags/aliases 非指標,整包吃會誤判實質內容工作為假同步;子集掛斷言測試釘 ⊆ 防漂移——r1 手列漏 plan_refs 的教訓靠守衛接,不回手列裸奔);若是,且它同時被 S1 grep 命中(內文還在講本次被刪的符號)→ 標出來。YAML 重排/正規化 diff 一律判「有動內容」(保守朝不報)。★觸發鍵刻意取 S1 命中而非 impact 必看名單★—掛 impact top-8 會繼承它的漏抓
  KEY:★天花板(誠實講)★—只抓「符號消失」這一型。行為反轉但名字沒少(例:`isStock = if(isSend=="Y") prefs.isStock else false` 改成 `isStock = prefs.isStock`)完全不會響;純語意矛盾更不會。S2 也有逃逸形狀:body 隨手補一行新敘述、被推翻的舊句照樣不改,diff 就不是「純連結」,S2 靜默(=「只改最相關段、漏散落列舉表」的已知失敗型)。★死碼盲區★—符號還在但已無呼叫點(死碼)時,架構圖講它=講不會執行的機制,S1 存在性比對照樣放行(2026-08-10 實測釐清:關鍵字掃的 6 個當時全是死碼型,識別字掃恆盲;能力邊界表見天花板節;v2 候選=呼叫點判定)。這是提高地板,不是全覆蓋——語意那半分兩承接:typed-edge 傳播歸 [[關係層傳播守衛_計劃]],純語意矛盾只歸 AI 交叉審(r2 補鏡像:body 已分寫,此處跟上)
  KEY:誤報來源逐項處置(r1 折入)=檔案搬移(git diff -M 治得了)｜符號改名(檔內改名 -M ★治不了★,v1 明文不解、歸低信心+誤報帳)｜註解提及/同名符號(v1 不判,advisory 吸收,明文取捨)｜歷史記載節點(★字樣標記判定撤案★—substring 誤抑制「尚未作廢」;r2 再改判:★型別在 S1 只排序不壓低★—實測②證據屬存量方向,增量方向 Projects 講被刪符號恰是真 drift,全五型別都報)。★刷屏也是失敗模式★—advisory 刷屏=訓練人無視它;識別字 cap 先驗 40、超 cap 保留高信心 top-10+一行統計(證據不清零);★超時契約:偵測器主體 python3 內建 deadline,|| true 只兜 crash 不兜 hang★;--no-verify 繞過留痕沿用既有 post-commit bypass 帳(r1 訂正:原稱「無留痕」有誤)
  PRIOR-ART:①最小解在既有層—pre-commit Gate 3 與 `impact --sync-check` 兩支都已存在,只需加一個判斷(被刪符號→grep vault)與一個 diff 分類(純連結 vs 有動內容),不造新機制、不新增治理層 ②世界解過—**Swimm** 做的正是 code-coupled docs:文件綁到具體 code 片段,被引用的 code 一改就把該文件標為過期,且分三級(up-to-date / out-of-sync 可自動修 / outdated 需人判),攔截點在 IDE 與 PR 合併前;另有 doc-drift CI 的作法(合併後掃,補本地 hook 漏的) ③裁定=**borrow-design**(借 Swimm 的三級分類與「攔在合併前」的時機,原生實作;零依賴家規排除 adopt)
  KEY:★與 Swimm 的刻意偏離★—Swimm 要求文件明確嵌入 code 錨點(Smart Tokens)才能耦合,精度高但有撰寫成本;本設計改用**識別字字面 grep**,精度低於錨點但★對 mOrangePos 既有 150 篇筆記零改造成本★。取捨已知:換來誤報,故先做 advisory 不硬擋
  KEY:★2026-08-10 mOrangePos 實跑帶回的四筆實測(詳見內文)★—①★存量方向★誤報率有真數字:1697 候選→183 找不到→**逐個判定真 drift 僅 6**(精確率約 3%,無過濾版地板;與失守實錄的 6 個零重疊、同數巧合—a55030e 修完才跑 4ce602d 全圖掃;雜訊類別可枚舉:測試單號/外部 API 欄位/DB 欄位/後端 C# 符號/gradle task/架構圖 frontmatter 欄位/Android SDK 概念/lint 規則 ID/姊妹專案類別) ②★最強過濾訊號是節點型別不是字串規則★—6 筆真 drift **全落在 Systems/**;Projects 提到不存在的名字多半是「還沒實作的預定名稱」、Verification 多半是「正在記載該符號被移除」→建議 Systems 高信心報、Projects/Verification 壓最低(★r2 限定:此建議只適用存量方向;S1 增量不套、型別只排序,n=6 無分母屬觀察非定案★) ③★存量掃描抓到 diff 版永遠抓不到的一型★—ArithUtil.kt/CartSummaryCalculator.kt 檔案都在但裡面沒同名物件(是 top-level 函式),架構圖把檔名當物件名寫成 `ArithUtil.round(v,scale)`,照著寫編不過;**從沒有 diff 刪過任何東西** → S1 永不觸發。故存量掃描(一次性,不進閘)與增量掃描(S1,進閘)抓的是不同東西,兩個都要 ④識別字掃勝過關鍵字掃的實例—`Systems/售完狀態雲端同步` 還在講付款設定頁的 etPnqrKey,前一輪用「憑證」關鍵字掃漏掉(節點名與主題對不上,人不會想去翻);★人會按主題找,而 drift 不按主題分布,這正是機械檢查存在的理由★ ⑤順帶產出真實驗收案例—同次把死碼真刪掉後,架構圖四個節點措辭要從「死碼」改成「已刪除」=★刪除本身又製造一批 drift,而這批正是 S1 的正字標記★,可重放
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
  - content: 落點裁定(僅及 S1/S2;S3 落點另裁見待辦):掛 pre-commit 的 Gate CC 旁(advisory、|| true 隔離、與 cochange 同級),不放 impact --sync-check
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
verified_by:
  - "[[Verification/2026-08-11_delguard落地]]"
---
# code 側刪除傳播守衛_計劃

**Goal:** 讓「code 拿掉了某個東西、架構圖還在講它」這一型過期，在 commit 當下就被指名到**具體哪一句**，而不是七天後排查時才撞見。

> **狀態：design-loop 已收斂(r1/r2 雙 PASS,golden 已凍結),v1 實作完成於 feat/delguard。**

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

從 `git diff --cached` 的 `-` 行抽出被刪掉的識別字（函式名、欄位、常數、端點路徑），拿去 grep vault 內文。命中的節點＋原句列出來。**合成 alternation＝完整借 `scripts/lumos:7189` 的寫法**：`re.compile(r"\b(?:" + "|".join(map(re.escape, tokens)) + r")\b", re.ASCII)`——三件缺一不可（r2 折入，原稿只借了一半）：`re.escape`（端點路徑含 `.`/`{}` metachar，裸拼誤配或炸 regex）、**`\b` 詞界**（防 `refreshPaywayCredentialsV2` 這類子字串誤配）、**`re.ASCII`**（vault 是中文內文，CJK 緊貼識別字時 Python 預設把 CJK 當 `\w`、`\b` 不成立→整片漏抓——:7187-7188 註解的存在理由正是這個）。（:10951 為 generator 寫法，慣例同源。）

本次案例會被抓到：被刪行含 `refreshPaywayCredentials()` 呼叫，vault 六個節點有該字面。**精確講**：S1 只認被刪行實際存在的 token，不做 call graph——只寫 callee 名 `GetPaywayCredential` 的節點，要等到該方法宣告行本身被刪（後續死碼清理那次）才命中。

**誤報來源（設計時先想好，不是事後補）**，逐項處置：
- **檔案搬移**：`git diff -M` 偵測 rename，整檔搬移不產生刪除行——這條 `-M` 治得了。
- **符號改名**（檔案路徑不變、函式在檔內改名）：`-M` **治不了**——舊名照樣出現在 `-` 行。已知誤報源，v1 不解，歸低信心檔＋advisory 吸收＋誤報帳記錄；不寫「改名不誤報」的假測試。
- **註解裡提及／不相干的同名符號**：v1 不判，advisory 吸收＋誤報帳記錄（明文取捨，非遺漏）。
- **歷史記載節點**：不用字樣標記判斷（「已作廢」substring 會誤抑制「尚未作廢」，且標記形式無機械定義）。實測 ② 的節點型別訊號在 **S1 只作排序、不作壓低**（r2 折入）：該證據來自**存量方向**——「Projects 提到不存在的名字＝還沒實作的預定名稱」這個免責理由只在存量方向成立；S1 是增量方向，Projects 節點講「**本次被刪**」的符號不可能是預定名稱，恰恰是真 drift（失守實錄的最壞案例正是 Projects 計劃節點前提被架空）。故 **S1 對全部五種型別（含 `Issues/`、`MOC/`）都報**，型別只影響排序（Systems 排前）；型別當主濾網留給存量工具（證據所在的方向）。

**信心合成裁定（r2）**：報告信心＝**符號檔位單一維度**（全域消失＝高、僅呼叫點＝低）；節點型別不改變檔位、只改排序。不存在「型別 × 符號」二維矩陣要實作者自己猜；措辭統一為「排序壓後」，**沒有任何型別是「不報」**。

**兩檔信心——「這行被刪」≠「這個符號從 repo 消失」**：call site 被移除但函式還活著、還被別處用，這時架構圖講它未必過期；反過來只認「repo 全域消失的符號」精度高，但會漏掉本次這型（拿掉的是「登入時呼叫」這個行為，符號未必全滅）。抽取規則分兩檔：**全域消失＝高信心報、僅呼叫點消失＝低信心報**。**「全域消失」的判定快照＝staged index**（`git grep --cached`，與 pre-commit 契約對象一致；grep working tree 會被未 staged 內容「救回」、grep HEAD 看不到已 staged 新增——兩者都判錯），排除域**與 pre-commit `should_exclude` 對齊但不字面重用**（r2 折入：那是 bash 函式 `pre-commit:81-96`，偵測器主體是 python，跨語言只能同規則再實作）——python 內建同規則清單，並把這第三份消費者**擴進既有漂移守衛 `t_precommit_whitelist_drift_guard`**（`scripts/test_lumos.py:1615` 現釘 pre-commit/post-commit 兩份同源，加釘本清單）；vendored 白名單的源 repo 反轉語意照抄（pre-commit:91-93：源 repo 不豁免自家工具檔）。承重註記：**不排 vault 則 vault 自身提及使每個符號恆「還活著」→高信心檔恆空、advisory 靜默失效**。此掃描成本入效能預算（見實務隱患）。

**刷屏也是失敗模式**：大型 refactor 會噴出海量 `-` 行，advisory 一旦刷屏就是在訓練人無視它（trade_offs 已承認「軟提醒可以被無視」，別再自己加速）。`git diff -M` 吃掉檔案搬移；識別字 cap 先驗暫用 **40**（replay 校準後以數據取代）；**超 cap 不是全丟**——保留高信心（全域消失）命中 top-N（先驗 N=10）逐條列，其餘壓成一行統計，證據不清零。

## S2 · 純連結編輯不算同步（機械，補刀）

判斷一個節點本次的 diff 是否**只動了「純連結欄位」**＝明確子集 **`{verified_by, plan_refs, related, core_refs}`**（連結語意），**不整包吃 `LIST_KEYS`**（r2 折入，改掉 r1 的整包方案）：`LIST_KEYS` 的語意是 `lumos append` 的**寫入白名單**（`scripts/lumos:6496`），不是連結語意——`pitfall_when` 是 content-trigger（:6224 行內註解、:10728/:12165 當命中觸發內容用），tags/aliases 是標籤別名非指標，改它們是實質內容工作，整包吃會把它們誤判假同步；「常數演進自動跟上」同理是風險非優點（LIST_KEYS 的擴充理由＝能不能 append，與 S2 的判準＝是不是純指標，不同源）。此子集另立常數 `LINK_KEYS`（**實作時新增**於 `scripts/lumos`、緊鄰 LIST_KEYS 定義處，現不存在），實作掛斷言測試釘 `LINK_KEYS ⊆ LIST_KEYS ∪ {core_refs}` 防漂移——r1 教訓（手列三欄漏 plan_refs）保留：子集要有守衛，不是回到手列裸奔。若是純連結編輯，而它**同時被 S1 的 grep 命中**（內文還在講本次被刪的符號）→ 標出來。

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

**死碼盲區（2026-08-10 實測釐清時補）**：「符號存在」≠「機制還活著」。符號還在 code 裡但已無人呼叫（死碼）時，架構圖講它＝講一個不會執行的機制＝很可能已過期，但 S1 的存在性比對會放行。兩型掃描的能力邊界：

| 失守形狀 | 關鍵字／語意掃 | 識別字掃（S1／存量） |
|---|---|---|
| 符號還在、機制已停用（死碼） | ✅ 抓得到 | ❌ 盲 |
| 符號消失、架構圖還在講 | 看主題猜，會漏 | ✅ 抓得到 |
| 檔名被當成物件名 | ❌ | ✅ |
| 節點名與主題對不上（etPnqrKey 型） | ❌ 漏 | ✅ |

若之後要補死碼盲區：加一道「該符號有沒有呼叫點」判斷（宣告處以外零引用＝死碼＝架構圖講它很可能過期）——比純存在性強一階、成本不高。**明文 v2 候選，不在 v1**（歸待辦）。

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
- **效能（熱路徑）**：pre-commit 每次 commit 都跑。前例教訓：Env vault 掃描曾低估到 4.7 秒被判 blocker。上限設計：①識別字抽取只吃 `--cached` diff 的 `-` 行（量小）②grep vault 不做 N 個符號 N 次掃，合成單條 alternation regex（逐 token `re.escape`）一次掃 254 檔③識別字 cap 先驗 40，超 cap 保留高信心 top-10、其餘壓一行統計④兩檔信心的 staged-index 掃描＝**單次 `git grep --cached` 帶多 `-e` pattern（fixed-string），嚴禁 cap 次子行程**（r2 折入：40 個子行程各自展開整個 index，Android 級 repo 必超預算——「Env vault 4.7s」同型低估；與②的單掃紀律同一條原則）⑤總預算目標 <1 秒。
- **超時的實作契約（`|| true` 兜不住 hang）**：`|| true` 只吞非零 rc，偵測器卡死時 commit 會無限等待。故偵測器主體＝**python3 內建 deadline**（`time.monotonic` 檢查點＋`subprocess.run(timeout=)` 包外部命令），到點自行輸出降級訊息、rc0 退出；不依賴 GNU `timeout`（macOS 無、零依賴家規）。bash 端 `|| true` 只兜 crash，不兜 hang——hang 由 python 內部 deadline 兜。**降級訊息走 stdout**（r2 折入：Gate CC 的呼叫是 `... 2>/dev/null || true`、其 :45 註解明寫「警告走 stdout」——照抄呼叫慣例時若降級訊息走 stderr 會被吞成靜默，advisory 靜默失效正是本守衛最不該有的失敗型）。
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
| S1 詞界 | 刪 `refreshPaywayCredentials`、vault 含 `refreshPaywayCredentialsV2` → 不誤配（`\b`） |
| S1 CJK 緊貼 | vault 內文「還在講`etPnqrKey`欄位」（中文緊貼識別字）→ 命中（`re.ASCII`；無它則 `\b` 對 CJK 失效漏抓） |
| S1 刷屏降級 | 識別字超 cap(40) → 保留高信心 top-10 逐條＋其餘一行統計（證據不清零） |
| S1 節點型別排序 | 同一命中出現在 `Systems/` 與 `Projects/` fixture → 兩者**都報**、信心檔位相同（由符號檔位決定）、Systems 排前（r2 裁定：型別只排序不壓低；Issues/MOC 同樣報） |
| S2 純連結判定 | 節點 diff 只動 `LINK_KEYS` 欄位 → 判「純連結」；多改任一行 body（含只動 `pitfall_when`/`tags`/`aliases`）→ 判「有動內容」 |
| S2 子集守衛 | 斷言 `LINK_KEYS ⊆ LIST_KEYS ∪ {core_refs}`（防子集漂移） |
| S2 觸發合取 | 純連結 ∧ S1 命中 → 報；純連結 ∧ 無 S1 命中 → 不報 |
| S2 邊界 | YAML 重排／縮排／scalar↔list 正規化 → 判「有動內容」（保守不報） |
| 效能 benchmark | 254 檔 vault、40 識別字 → 總時 <1s（正常量級，寬鬆時限；**含單次 `git grep --cached` 多 `-e` 的 staged-index 掃描一併計時**，不得只測 vault 掃） |
| timeout fail-open | 注入可控 hang（或極短 deadline）→ deadline 後偵測器自行終止、rc0、降級訊息出現在 **stdout**（斷言輸出流；與 benchmark 分開測，小 fixture 觸發不了真 timeout） |
| fail-open | 偵測器自身拋錯 → commit 不被擋（`\|\| true` 隔離） |

回歸錨：**vendored 合成 fixture**——把 aff2329 的失守形狀重建成最小合成 diff＋合成筆記（六節點型：三個只掛連結、內文留舊敘述），進本 repo 測試目錄；**不依賴外部 repo 的 SHA**（mOrangePos 是商業碼，原 diff 不可入庫；去敏後只留形狀）。

## 審計修正紀錄

- **pre-flight（2026-08-10，機械排乾，不計 loop findings）**：①補「測試策略」節（原 spec 無驗證方式描述）②失守實錄表格中 `2C2P轉正式fail-safe_計劃` 標明為 mOrangePos vault 節點（原文易誤讀為本 repo 節點，refcheck 型歧義）。同批：實務隱患節係 pitfalls --check rc1 後補（風險類反問 S0）。
- **r1（2026-08-10，panel 3 席：sonnet 通才／sonnet 正確性／Codex 邊界整合；三席 canary 全 caught；報告與快照存 `governance/review-reports/code側刪除傳播守衛/`）**：跨席去重後折入 13 條——①S2 欄位白名單改讀 `LIST_KEYS` 常數＋`core_refs`（三席一致）②alternation 逐 token `re.escape`（兩席）③「--no-verify 無留痕」訂正為沿用既有 post-commit bypass 留痕④rename 拆兩型：檔案搬移 `-M` 治、符號改名明文 v1 不解⑤「全域消失」快照定為 staged index（`git grep --cached`）＋成本入預算⑥CJK quotePath／python3 主體／binary diff 等輸入健壯性入風險類⑦timeout 契約：python 內建 deadline，`\|\| true` 不兜 hang⑧cap 先驗 40／超限保留高信心 top-10⑨歷史段落字樣判定撤案，改節點型別過濾（接 mOrangePos 實測 ②）⑩S3 問句改 `search --code` 並註明搜尋域差異⑪S1 案例句識別字精度訂正（不做 call graph）⑫測試策略補 staged 快照契約／timeout 拆測／vendored 去敏 fixture⑬落點裁定 Gate CC 旁（ADR）。另兩條措辭級：天花板承接者分寫、Swimm 對應降為概念級。**流程事件**：真檔在 r1 進行中被補入 mOrangePos 實測節（1697→183→6 等），被審快照未含——該節由 r2 delta 補審。
- **r2（2026-08-10，delta 輪 3 席：sonnet 新證據正確性／sonnet 折入一致性／opus 邊界整合〔Codex auth 401 缺席退位，偏離記 r2-dispatch-s3.json〕；三席 canary 全 caught；主審＝實測節＋r1 折入 diff）**：跨席去重折入 11 條——①型別過濾改判「S1 只排序不壓低」（證據屬存量方向、增量方向 Projects 講被刪符號恰是真 drift；Issues/MOC 一併入列）②信心合成裁定：檔位＝符號單一維度，無二維矩陣③S2 改明確子集 `LINK_KEYS`＝{verified_by,plan_refs,related,core_refs}＋斷言守衛，撤 LIST_KEYS 整包方案（pitfall_when 是 content-trigger）④排除域改「對齊不重用」＋擴 `t_precommit_whitelist_drift_guard` 釘第三份清單＋源 repo 反轉語意照抄⑤alternation 補全 `\b`＋`re.ASCII`（CJK 緊貼漏抓）⑥staged-index 掃描改單次 git grep 多 `-e`，禁 cap 次子行程⑦存量掃描劃出 v1、另案交付（判定強度＞字面 grep）⑧3% 加存量方向限定、不可挪用為增量誤報率⑨timeout 降級訊息明定走 stdout⑩d1 範圍限定僅及 S1/S2⑪summary 天花板句殘留併寫修正（r1 折入漏的鏡像，r2 s2 席抓回）。**已結**（2026-08-10 Enzo 補時序）：兩個「6」零重疊、同數巧合（a55030e 修完 → 4ce602d 掃）；併帶出結構性事實「死碼讓 S1 失明」→ 天花板節能力邊界表＋v2 候選（呼叫點判定），標記已撤。
- **實作偏離（2026-08-11，終審裁定）**：v1 排除域＝7 目錄＋lock 三檔名（對齊 should_exclude 子集）；vendored 白名單與源 repo 反轉語意留 v2（advisory 下漏排僅多噪音不誤擋）。漂移守衛已擴 t_precommit_whitelist_drift_guard 釘第三份清單。
- **code-loop r1（2026-08-11，panel 5+1 席，單家族豁免留痕）**：折入 15 條（A–O）——排除域路徑段比對／confidence 內容域歸屬／回收表 per-file／diff 前綴固定／standalone vault 靜默／env float 防炸／非 UTF-8 replace／巨檔 deadline 粒度／top-10 鑑別力＋前置斷言／benchmark 真 repo 現場／漂移斷言去套套邏輯／Gate DG -f／S2 重排判有動內容／**fixture 洩漏 rmtree 收尾（I）**／縮水測試補 7 項＋**SQL 註解型 `--` 檔頭誤判之真碼修正（O②，`_delguard_is_diff_header`：舊判定把被刪的 SQL/Lua `--` 註解行 `--- x` 誤當 diff 檔頭整行吃掉）**；Verification 宣稱改機制式（數字快照兩度過期的病根治）。

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

> **r2 方向限定**：3% 是**存量掃描**的數字（母體＝全圖 1697 識別字），不是 S1 增量方向的誤報率（母體＝單次 commit 被刪行，cap 40）。DECISION 要收的「誤報率再談升硬擋」須由增量方向自己累積，3% 不可挪用。
>
> **兩個「6」的關係（已釐清，2026-08-10 Enzo）**：完全不相交，同數是巧合。時序＝關鍵字掃的 6 個先修完（mOrangePos `a55030e`）→ 全圖識別字掃（`4ce602d`）在**已修好的架構圖**上跑 → 兩批零重疊。兩個「4」同理非同一集合（前者＝排查時發現的 code 註解，後者＝`a022f4c` 刪除後要改措辭的架構圖節點，不同物件不同時點）。
>
> **比時序更重要的結構性事實——死碼會讓 S1 失明**：就算那 6 個沒先修，全圖識別字掃也抓不到它們——當時 `refreshPaywayCredentials` 等符號**還存在於 code 裡（死碼）**，識別字比對會通過。架構圖描述的是「已經不會執行的機制」，但符號還在，機械檢查看不出來。（那 6 個是 `a022f4c` 真刪掉之後才變成 S1 抓得到的形狀——即實測 ⑤：刪除本身製造出 S1 的正字標記。）

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

> **r2 裁定（方向限定）**：此建議適用於**存量方向**（本節證據的母體）。增量 S1 **不套**——被刪符號不可能是「還沒實作的預定名稱」，Projects 節點講它恰是真 drift（本計劃的最壞案例 `2C2P轉正式fail-safe_計劃` 正是 Projects 節點）；且此處 n=6、單向、無分母分佈（183 筆候選的型別分佈未報告），是觀察不是定案規則。S1 全型別都報、型別只作排序，見 S1 節「信心合成裁定」。

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

## 合約候選清單（design-loop 收斂鏡頭提名；★候選 ≠ 已標★，蓋章仍走 guard scaffold→bind→audit 與「不確定不標」鐵則）

- S1 詞界＋CJK：alternation 必為 `\b(?:…)\b`＋`re.ASCII`＋逐 token `re.escape`——改掉任一項＝漏抓或誤配（候選理由：CJK 漏抓是靜默失效）
- S2 判定子集＝`LINK_KEYS`，且斷言 `⊆ LIST_KEYS ∪ {core_refs}`——整包吃回 LIST_KEYS＝誤判實質內容為假同步
- fail-open：偵測器 crash／timeout 皆不得擋 commit（advisory 契約）；降級訊息走 stdout
- 「全域消失」判定快照＝staged index——改 grep worktree／HEAD＝判錯信心檔
- 排除域必排 vault——不排則高信心檔恆空、整條守衛靜默失效

## 待辦

- [x] ~~決定放哪一層~~ → **已裁定：`pre-commit` 的 Gate CC 旁**（advisory，與 cochange 同級；ADR 見 decisions）。r1 Codex 席把這題從「傾向」升到裁定：兩入口**輸入不等價**——Gate CC 直接讀 staged index，`impact --sync-check` 是 branch-range 模式（`scripts/lumos:13253-13254` 配 `--diff`），放後者則 pre-commit 時 range 未定義（initial commit／detached HEAD／amend 全懸空）
- [ ] S1 的識別字抽取規則細化（哪些 token 值得抽、怎麼避開字串與註解；cap=40/top-10 為先驗值，replay 校準後以數據取代）
- [ ] S2 的「純 list 欄位 diff」判定實作（讀 `LIST_KEYS` 常數，行級 diff 邊界照 S2 節定義）
- [ ] 誤報樣本蒐集方式（v1 人工記錄；格式傾向 append-only jsonl；有數字再談升級硬擋）
- [x] S3 問句落點——**已裁定（2026-08-10 Enzo）：`lumos-project-notes` skill 退場段**（user-scope 跨專案生效、symlink 分發下 pull 即吃到；CLAUDE.md 方案落選＝覆蓋面只到有裝專案且要逐專案重跑安裝）。落地歸 [[code側刪除傳播守衛_實作計畫]] Task 8；此項仍是 v1 交付的一部分
- [ ] **v2 候選：死碼判定**（「宣告處以外零引用＝死碼＝架構圖講它很可能過期」，補 S1 的死碼盲區——見天花板節能力邊界表；比存在性強一階，v1 不做）
- [x] ~~存量掃描另案交付~~ → ★**已由 [[Systems/check-y-symbol-existence]] 實現（另一條線 2026-08-12 獨立做出，合併時才發現）**★：doctor 掃 Systems 正文的 inline-code → 篩「方法/類別形狀」→ 比對 code haystack → 查無則軟提醒。它的節點自己寫明分工：**delguard 驗「被刪的符號架構圖還在講」（diff-based、commit 時）／Y 驗「架構圖提到的符號 repo 有沒有」（全量、隨時）**，且明講「守成因 D『寫的時候就錯』——code 從沒變過也會發生，★diff-based 守衛結構上抓不到★」。這正是本節點實測 ③「存量與增量抓的是不同東西，兩個都要有」的另一半。★別再另立計劃重造★；本節點 v2 候選（死碼判定＝呼叫點為零）仍未被覆蓋，那是第三型。
