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
  - drift-history
  - 歷史重放
  - 規律自證
related:
  - "[[Systems/check-y-symbol-existence]]"
summary: |-
  FLOW:沿 git 歷史取樣→每點用 git grep 對當時 code 比對當時架構圖提到的符號→輸出幽靈符號時間序列→判「偶發 vs 穩態」
  KEY:★存在理由=讓每份架構圖自己量規律,而不是相信別人在別份架構圖上的結論★(Enzo 2026-08-12 質疑:「你只對這份架構圖適用嗎?」)。U/Y 兩道守衛靠形狀與詞表啟發式,換架構圖/語言棧可能靜默失效——與其宣稱通用,不如給一把尺
  KEY:★判讀★=曲線一直 0 → 沒這型 drift(或 profile 沒對上,先看候選數是不是 0);長期非 0 且同批符號反覆 → 規律成立值得開檢查
  KEY:★踩過的設計缺陷(被自己的測試打出來)★=首版只取「動過架構圖的 commit」,但 drift 的誕生機制正是「只改 code 沒改架構圖」——取樣點與要量的問題同形狀,系統性錯過出生那刻。改掃全部 commit
  KEY:★踩過的方法論陷阱★=首版腳本因 git 對非 ASCII 檔名加引號跳脫,`.md` 尾綴比對濾掉 25/30 節點,結論從「2% 持續三個月」變成「0% 沒問題」;故固定帶 core.quotePath=off
  DEP:[[Systems/check-y-symbol-existence]]
  TEST:3 條牙齒測試(改名後幽靈可見、--json 結構、無 docs 佈局 rc=2)
verified_by:
  - "[[Verification/2026-08-12_通用性修正_profile化與歷史重放]]"
---

# drift-history — 讓每份架構圖自己量規律

## 為什麼需要它

Enzo 2026-08-12 的質疑：

> 「我們做的盤點機制，到底是針對現成架構圖語義的規範，還是同樣對之後產出架構圖起作用？
> 我擔心的是你只對這份架構圖適用，那新的架構圖如果用別的闡述方式，會不會就抓不到？」

**這個質疑是對的。** Check U 靠中文詞表、Check Y 靠命名慣例——**換一份架構圖可能靜默失效**。

所以正解不是宣稱通用，而是**給每個專案一把尺自己量**。

## 判讀

| 曲線 | 意思 |
|---|---|
| 一直 0，**候選數也 0** | ★`symbol_profile` 沒對上你的語言棧★——先修 profile，別當成沒問題 |
| 一直 0，候選數正常 | 這個專案沒有這型 drift，不用開檢查 |
| 有出現但斷續 | 有人在修，但**沒有機制擋它再發生** |
| **橫跨全部取樣點都在** | ★**規律成立：不是偶發，是穩態**★ → 值得開機械檢查 |

## LandmarkMember 首跑（2026-08-12）

`GetOrdersForRedeemAsync` / `ListAvailableAsync` **橫跨全部取樣點**，
從 2026-05-26 到 2026-07-15 期間架構圖從 23 篇長到 27 篇、候選符號從 108 長到 149，
**這兩條一次都沒被修掉**——同期 10 個 agent 的兩階段交叉審計也沒抓到。

## ★兩個踩過的坑（都值得後人知道）★

### ① 取樣點與要量的問題同形狀

首版只取「動過架構圖的 commit」。但 **drift 的誕生機制正是「只改 code、沒改架構圖」**——
在架構圖 commit 取樣，就系統性錯過 drift 出生的那一刻。
**是測試翻紅才發現的**（造了「code 改名、架構圖沒動」的假 repo，工具看不見）。已改成掃全部 commit。

### ② 表面形狀的假設會錯得無聲無息

首版腳本用 `.endswith(".md")` 過濾 `git ls-tree` 輸出——
但 git 對非 ASCII 檔名會**加引號跳脫**，於是 25/30 個中文檔名節點被濾掉，
★結論從「2%、持續三個月」變成「0%、完全沒問題」★。

> 這正是本工具要防的失敗型態，而**我在寫它的時候自己犯了一次**。
> 故實作固定帶 `-c core.quotePath=off`。

## 用法

```bash
lumos drift-history                 # 預設每 60 個 commit 取樣一次
lumos drift-history --every 200     # 稀疏取樣(快)
lumos drift-history --limit 10      # 只看最近 10 個取樣點
lumos drift-history --json          # 給其他工具消費
```

## 相關

- [[Systems/check-y-symbol-existence]] — 這把尺量的就是 Check Y 那型 drift
