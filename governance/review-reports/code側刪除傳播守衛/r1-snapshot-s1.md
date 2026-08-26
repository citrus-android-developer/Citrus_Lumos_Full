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
  KEY:偵測面=從 diff 的 `-` 行抽識別字(函式/欄位/常數/端點路徑)→在 vault 內文 grep→命中即候選。★這次的案例會被抓到★:被刪的是 refreshPaywayCredentials 呼叫,六個節點內文有 refreshPaywayCredentials/GetPaywayCredential 字面。★「這行被刪」≠「符號從 repo 消失」★—call site 移除但函式還活著時,架構圖講它未必過期;只認全域消失又會漏本次這型(拿掉的是「登入時呼叫」這個行為,符號未必全滅)→ 抽取分兩檔信心:全域消失=高信心報、僅呼叫點消失=低信心報
  KEY:第二道=★純連結編輯不算同步★—判該節點本次 diff 是否只動 frontmatter 的 list 型欄位(verified_by/related/tags);若是,且它同時被 S1 grep 命中(內文還在講本次被刪的符號)→ 標出來。直接對準本次失守形狀。★觸發鍵刻意取 S1 命中而非 impact 必看名單★—掛 impact top-8 會繼承它的漏抓
  KEY:★天花板(誠實講)★—只抓「符號消失」這一型。行為反轉但名字沒少(例:`isStock = if(isSend=="Y") prefs.isStock else false` 改成 `isStock = prefs.isStock`)完全不會響;純語意矛盾更不會。S2 也有逃逸形狀:body 隨手補一行新敘述、被推翻的舊句照樣不改,diff 就不是「純連結」,S2 靜默(=「只改最相關段、漏散落列舉表」的已知失敗型)。這是提高地板,不是全覆蓋——語意那半仍歸 AI 交叉審與 [[關係層傳播守衛_計劃]]
  KEY:誤報來源(設計時要先想好)=改名(舊名消失只是換名)、註解裡提及、不相干的同名符號、以及架構圖刻意保留的歷史記載(標了「已作廢/歷史」的段落不該再報)。★刷屏也是失敗模式★—大型 refactor/檔案搬移噴海量 `-` 行,advisory 刷屏=訓練人無視它;至少 git diff -M 吃掉 rename、單次輸出設上限
  PRIOR-ART:①最小解在既有層—pre-commit Gate 3 與 `impact --sync-check` 兩支都已存在,只需加一個判斷(被刪符號→grep vault)與一個 diff 分類(純連結 vs 有動內容),不造新機制、不新增治理層 ②世界解過—**Swimm** 做的正是 code-coupled docs:文件綁到具體 code 片段,被引用的 code 一改就把該文件標為過期,且分三級(up-to-date / out-of-sync 可自動修 / outdated 需人判),攔截點在 IDE 與 PR 合併前;另有 doc-drift CI 的作法(合併後掃,補本地 hook 漏的) ③裁定=**borrow-design**(借 Swimm 的三級分類與「攔在合併前」的時機,原生實作;零依賴家規排除 adopt)
  KEY:★與 Swimm 的刻意偏離★—Swimm 要求文件明確嵌入 code 錨點(Smart Tokens)才能耦合,精度高但有撰寫成本;本設計改用**識別字字面 grep**,精度低於錨點但★對 mOrangePos 既有 150 篇筆記零改造成本★。取捨已知:換來誤報,故先做 advisory 不硬擋
  DECISION:[2026-08-10]先軟提醒不硬擋,跑一段時間收誤報率再決定要不要升級成擋(對齊 sync-check 的 advisory 級別)
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

從 `git diff --cached` 的 `-` 行抽出被刪掉的識別字（函式名、欄位、常數、端點路徑），拿去 grep vault 內文。命中的節點＋原句列出來。

本次案例會被抓到：被刪的是 `refreshPaywayCredentials()` 的呼叫，六個節點內文帶 `refreshPaywayCredentials` / `GetPaywayCredential` 字面。

**誤報來源（設計時先想好，不是事後補）**：改名（舊名消失只是換名）、註解裡提及、不相干的同名符號、架構圖**刻意保留**的歷史段落（已標「已作廢／歷史」的不該再報）。歷史段落的判定鍵直接用節點 frontmatter 既有的 `archived_at` 欄位，不需新增標記慣例。

**兩檔信心——「這行被刪」≠「這個符號從 repo 消失」**：call site 被移除但函式還活著、還被別處用，這時架構圖講它未必過期；反過來只認「repo 全域消失的符號」精度高，但會漏掉本次這型（拿掉的是「登入時呼叫」這個行為，符號未必全滅）。抽取規則分兩檔：**全域消失＝高信心報、僅呼叫點消失＝低信心報**。

**刷屏也是失敗模式**：大型 refactor／檔案搬移會噴出海量 `-` 行，advisory 一旦刷屏就是在訓練人無視它（trade_offs 已承認「軟提醒可以被無視」，別再自己加速）。至少 `git diff -M` 吃掉 rename，再對單次輸出量設上限。

## S2 · 純連結編輯不算同步（機械，補刀）

判斷一個節點本次的 diff 是否**只動了 frontmatter 的 list 型欄位**（`verified_by` / `related` / `tags`）。若是，而它**同時被 S1 的 grep 命中**（內文還在講本次被刪的符號）→ 標出來。

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

2. 把那些名字逐個丟進 lumos search。
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

**這是提高地板，不是天花板。** 語意那半仍歸 AI 交叉審與 `[[關係層傳播守衛_計劃]]`；本守衛的定位是**機械前濾網**，讓貴的那關少看一點東西。

## 世界怎麼解的（PRIOR-ART ②）

**Swimm** 做的正是這件事：文件綁到具體 code 片段（Smart Tokens），被引用的 code 一改就把該文件標為過期。值得借的三點：

1. **分三級不是二值** — up-to-date ／ out-of-sync（改名、位移這類可自動修）／ outdated（實質變動，需人判）。我們的 S1＋S2 天然對應後兩級。
2. **攔在合併前**，不是事後掃。
3. **耦合的是「文件引用了哪段 code」**，不是「文件多久沒改」。時間不是新鮮度的指標。

**刻意偏離**：Swimm 要求文件明確嵌入錨點才能耦合——精度高，但有撰寫成本，且對既有筆記要回頭補。本設計改用**識別字字面 grep**，精度較低但**對 mOrangePos 現有 150 篇筆記零改造成本**（本 repo 254 篇同樣受益，機制是通用的）。取捨已知：換來誤報，所以第一版走 advisory。

出處：[Swimm — code-coupled docs](https://swimm.io/blog/swimm-native-integrations)、[Doc Drift Detection in CI](https://understandingdata.com/posts/doc-drift-detection-ci/)

---

## 實務隱患

**此功能碰到的風險類**：self-governance（守衛面）、效能（pre-commit 熱路徑）。逐類答：

- **self-governance／誤擋的逃生口**：v1 是 advisory、恆 rc0，不存在誤擋。實作上必須比照 Gate CC 用 `|| true` 隔離——偵測器自己出 bug 也不准擋 commit（fail-open）。若日後憑誤報數據升硬擋，逃生口＝`--no-verify`（沿用 Gate 1 既有慣例，錯誤訊息裡印出來）；繞過留痕沿用既有現狀（`--no-verify` 目前無留痕，本計劃不新造留痕機制，誠實記著這個洞）。
- **效能（熱路徑）**：pre-commit 每次 commit 都跑。前例教訓：Env vault 掃描曾低估到 4.7 秒被判 blocker。上限設計：①識別字抽取只吃 `--cached` diff 的 `-` 行（量小）②grep vault 不做 N 個符號 N 次掃，合成單條 alternation regex 一次掃 254 檔③識別字數設 cap（超過視同 refactor 刷屏、直接降級成一行摘要提示）④總預算目標 <1 秒，超時 fail-open 放行。
- **併發**：無——hook 每次 commit 單進程、對 vault 只讀不寫，無共享資源競態。
- **資源**：無——純檔案讀取，無連線／鎖／長駐進程。
- **誤報帳的狀態**：誤報樣本落地方式歸待辦（傾向 append-only jsonl，與 governance-log 同款慣例），不引入新資料庫。

**已排除**：金流／對外送出／PII／認證／快取／遷移——本機制只讀 git diff 與 vault 文字，不碰任何業務資料面。

---

## 測試策略（已知行為，TDD）

機械層（S1/S2）行為可枚舉，走 TDD；S3 是人的紀律，無機械 oracle，誠實不寫湊數測試。

| 對象 | 測試（fixture diff → 預期輸出） |
|---|---|
| S1 命中 | 刪含 `refreshPaywayCredentials()` 呼叫的行、vault fixture 含該字面 → 報「節點＋原句」 |
| S1 兩檔信心 | 符號 repo 全域消失 → 高信心；僅呼叫點消失、定義仍在 → 低信心 |
| S1 改名不誤報 | `git diff -M` 可偵測的 rename → 不報 |
| S1 刷屏降級 | 被刪識別字數超 cap → 降級成一行摘要，不逐條列 |
| S1 歷史段落不報 | vault 命中行落在標「已作廢／歷史」的段落 → 不報 |
| S2 純連結判定 | 節點 diff 只動 verified_by/related/tags → 判「純連結」；多改任一行 body → 判「有動內容」 |
| S2 觸發合取 | 純連結 ∧ S1 命中 → 報；純連結 ∧ 無 S1 命中 → 不報 |
| 效能 | 254 檔 vault、20 識別字 → 單次 alternation grep，總時 <1s；超時 fail-open rc0 |
| fail-open | 偵測器自身拋錯 → commit 不被擋（`\|\| true` 隔離） |

回歸錨：mOrangePos aff2329 的 diff 作為 replay fixture（S1 必須命中六節點型的案例）。

## 審計修正紀錄

- **pre-flight（2026-08-10，機械排乾，不計 loop findings）**：①補「測試策略」節（原 spec 無驗證方式描述）②失守實錄表格中 `2C2P轉正式fail-safe_計劃` 標明為 mOrangePos vault 節點（原文易誤讀為本 repo 節點，refcheck 型歧義）。同批：實務隱患節係 pitfalls --check rc1 後補（風險類反問 S0）。

---

## 待辦

- [ ] 決定放哪一層：`pre-commit` 的 Gate CC 旁（advisory，與 cochange 同級）還是 `impact --sync-check` 裡——傾向 Gate CC 旁：S1 要吃 diff 的刪除行，pre-commit 天然有 `--cached` diff；impact 觸發在編輯當下，刪除未必已成形
- [ ] S1 的識別字抽取規則（哪些 token 值得抽、怎麼避開字串與註解）
- [ ] S2 的「純 list 欄位 diff」判定
- [ ] 誤報樣本蒐集方式（先跑一段時間、記下來，有數字再談升級硬擋）
- [ ] S3 問句放 `lumos-project-notes` skill 的退場段（user-scope，跨專案生效）還是各專案 CLAUDE.md
