---
type: system
status: done
created: 2026-08-12
updated: 2026-08-12
tags:
  - type/system
  - status/done
  - risk/守衛面
  - scope/cli-read
aliases:
  - Check Y
  - 被提及符號存在性
  - 幽靈符號守衛
related:
  - "[[Systems/check-n-recomputable]]"
  - "[[Systems/check-u-overgeneralization]]"
  - "[[Systems/drift-history]]"
summary: |-
  FLOW:doctor 掃 Systems 節點正文的 inline-code→篩「方法/類別形狀」→比對 code haystack→查無則軟提醒
  KEY:★守的是成因 D「寫的時候就錯」★——code 從沒變過也會發生,故 ★diff-based 守衛(delguard)結構上抓不到★。與 delguard 分工:delguard 驗「被刪的符號架構圖還在講」(diff-based、commit 時);Y 驗「架構圖提到的符號 repo 有沒有」(全量、隨時)
  KEY:★首發實績★=抓到活動報名寫 ActivityService.RegisterAsync(實為 SubmitRegistrationAsync)、滿額贈寫 ListAvailableAsync/GetOrdersForRedeemAsync(實為 GetActivitiesAsync/GetOrderSelectionAsync)——★這三條在同日 10 個 agent 的兩階段交叉審計中全被漏掉★(實證員驗了行為、沒挑方法名)
  KEY:★只掃 Systems★是語意決定不是調參——只有 Systems 宣稱「現在長怎樣」;Projects 提未來方法、Verification/Issues 記歷史狀態,對它們報「查無」是誤報。實測:全型別 37 命中 → 限 Systems 4 命中
  KEY:★否定語境豁免★=節點常「正確地記錄某符號已不存在」(「X 全庫零命中」「原記 X 無此方法」),對這種行報錯是把正確紀錄當錯誤;此為★唯一★誤報來源(2026-08-12 補足詞彙後真實架構圖誤報歸零),清單含 零命中/已移除/查無/無此/原記/舊名/改名/棄用/不使用/廢棄/停用 等
  DEP:[[Systems/lumos-cli-read]]
  TEST:5 條牙齒測試(含否定語境豁免、Projects 不掃、形狀過濾擋環境變數/範例ID/檔名)
verified_by:
  - "[[Verification/2026-08-12_CheckY_符號存在性]]"
  - "[[Verification/2026-08-12_通用性修正_profile化與歷史重放]]"
---

# Check Y — 被提及符號存在性（幽靈符號守衛）

## 守什麼：成因 D「寫的時候就錯」

★**code 從沒變過也會發生**★——所以任何 diff-based 機制（含 `delguard`）**結構上就抓不到**。

| | delguard | Check Y |
|---|---|---|
| 問題 | 「**被刪的**符號，架構圖還在講」 | 「架構圖**提到的**符號，repo 有沒有」 |
| 時機 | commit 時（staged diff） | 隨時（全量） |
| 抓得到「一開始就寫錯」嗎 | ❌ | ✅ |

## 首發實績

2026-08-12 上線當天抓到三條**真錯**：

| 節點 | 架構圖寫 | 實際 |
|---|---|---|
| 活動報名 | `ActivityService.RegisterAsync` | `SubmitRegistrationAsync` |
| 滿額贈 | `ListAvailableAsync` | `GetActivitiesAsync` |
| 滿額贈 | `GetOrdersForRedeemAsync` | `GetOrderSelectionAsync` |

★**這三條在同一天 10 個 agent 的兩階段交叉審計中全被漏掉**★——
實證員驗的是「行為對不對」，方法名寫錯了但行為描述正確，就滑過去了。

> **一個 30 行的機械檢查，補上了 10 個 agent 的盲區。** 不是 agent 不行，是**人和 agent 都會盯著語意而放過名字**，機器剛好相反。

## 兩個關鍵設計（都是量出來的）

### ① 只掃 Systems——語意決定，不是調參

只有 `Systems` 宣稱「**現在長怎樣**」。
`Projects` 提的是「打算做的方法」（還沒寫）、`Verification`/`Issues` 記的是歷史狀態（當時存在、現已移除）——對那些節點報「repo 查無」是**誤報而非發現**。

實測：全型別掃 **37 命中**（多為計劃中的未來方法／已移除的歷史方法）→ 限 Systems **4 命中**。

### ② 形狀過濾——擋掉不是符號的東西

寬鬆抽法（任何 PascalCase inline-code）在真實架構圖 **7% 未命中（74/930）**，抽樣多為：
環境變數（`ADMIN_LOG_VIEWER_KEY`）、DB 欄位（`TBmemberdisc.WelcomeCouponNo`）、
會員編號範例（`LM00001226`）、別 repo 頁面（`MemberDisc.aspx`）。

收緊成「方法/類別形狀」——**無底線、無數字、非全大寫、無副檔名**，且**以 `Async` 結尾**或**帶點**（`Class.Method`）——
→ **279 候選 / 1 未命中（0.4%）且為真陽性**。

### ③ 否定語境豁免——最大宗誤報

節點常常「**正確地記錄某符號已不存在**」：

> 「`RefundPointsAsync` 全庫**零命中**」「**原記** `RegisterAsync` **無此方法**」

對這種行報「repo 查無」是**把正確的紀錄當成錯誤**。清單：
`零命中 / 已移除 / 不存在 / 查無 / 已刪 / 從未 / 已退役 / 移除 / 無此 / 原記 / 舊名 / 改名 / removed / no longer / deleted / renamed`

> 諷刺的是：**2026-08-12 訂正架構圖時，我們自己寫的訂正句就觸發了這類誤報**——這正好證明了它必須豁免。

## 已知限制

- **只認 C#/前端命名慣例**（`Async` 後綴、PascalCase）；其他語言棧需擴充形狀規則
- 只驗「符號**存在**」，不驗「**用對地方**」——後者仍需交叉審計
- 否定詞清單是**列舉式**，新的說法（例如「已封存」「凍結」）會漏——★但這是可增補的字典問題，不是結構限制★

> 🔧 **2026-08-12 訂正一則自己的誤判**：本節點原寫「DB 欄位形狀與 `Class.Method` 難分（`TBmemberdisc.WelcomeCouponNo` 仍會誤報）」，
> 把它當成**無解的結構限制**。實際去看節點原文才發現——那行寫的是「**棄用，不使用**」，
> ★根本就是同一類否定語境，只是清單漏了「棄用/不使用」這組詞★。補進去之後誤報歸零。
>
> **教訓**：把「還沒解的」說成「解不了的」，會讓後人不去嘗試。**判定為結構限制之前，先看一眼實際案例。**

## 相關

- [[Systems/check-n-recomputable]] — Check N，守成因 F（寫死易漂的值）
- [[Systems/check-u-overgeneralization]] — Check U，守成因 G（過度概化）
