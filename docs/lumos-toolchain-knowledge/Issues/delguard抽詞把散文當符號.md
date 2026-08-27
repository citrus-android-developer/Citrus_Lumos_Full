---
type: issue
status: open
created: 2026-08-27
updated: 2026-08-27
aliases:
  - delguard 報一堆 and
  - 刪除傳播全是低信心命中
tags:
  - type/issue
  - status/open
  - priority/P2
  - scope/governance
related:
  - "[[Systems/delguard]]"
  - "[[code側刪除傳播守衛_計劃]]"
summary: |-
  FLAG:TECHNICAL
  KEY:★S1 抽詞只擋程式關鍵字,不擋散文英文字★——`_DELGUARD_STOP` 收的是 if/else/fun/val/class 這類 keyword,`and`/`items`/`Exception` 一律放行。刪掉一段 **docstring 或註解**(裡面是中英文散文)時,散文詞會被當成「被刪符號」拿去 grep 全 repo
  KEY:實測(2026-08-27,本次逐 token grep 改法自己的 commit):5 個 token 打出 **90 筆命中,高信心 0**,逐條列的前十筆全部由 `and` 一個字帶出,命中的是「global workspace in LLMs」「skippable=="0" and restartable」這類與刪除毫無關係的句子
  KEY:★這是舊缺陷、不是新退化★——一直都在,只是先前 `_delguard_confidence` 必定超時 fail-open,閘根本沒跑完,所以沒人看到輸出。2026-08-27 成本修好、閘真的跑起來後才浮出
  KEY:危害=與 2026-08-26 簿記檔那條同型:假陽性訓練人忽略這道閘。差別在簿記檔那次是「內容是紀錄不是宣告」,這次是「內容是散文不是宣告」
  KEY:候選解(未評估、未實作):①擴 stopword 到常見英文散文詞 ②只從**看起來像宣告的行**抽詞(def/fun/class/val/const 等左側),不從註解與 docstring 抽 ③per-token 長度/大小寫啟發式(全小寫短詞降權) ④低信心且命中數爆量時整批不報。★選哪條要先看誤報帳,不是憑直覺挑★
  DECISION:[2026-08-27] 本輪只結清成本 DEBT,不順手改抽詞——抽詞規則是 S1 的判準核心,改它會動到既有 85 條測試釘住的行為面,且候選解有四條、無數據不足以裁;先立本 Issue 攤給人
---
# delguard 抽詞把散文當符號

## 症狀

`lumos delguard --staged` 對一個只改了 docstring 與註解的 commit，報出：

```
⚠ delguard: code 側刪除傳播——5 個被刪符號在架構圖仍被提及(高信心 0/低信心 90)
  [low] Systems/canary-audit.md:121 「…Verbalizable representations and a global workspace in LLMs…」 ← and
  [low] Systems/compose-metrics-adapter.md:21 「…skippable=="0" and restartable=="1"…」 ← and
  [low] Systems/convergence-evidence-gate.md:19 「…all(good(r) for r in rounds[-need:])…」 ← items
```

沒有任何一筆是真的「code 拿掉了某個東西、架構圖還在講它」。

## 根因

`_DELGUARD_STOP`（`scripts/lumos`）是一份**程式關鍵字**清單：

```
if else for while return import class def val var fun void
public private static final new this true false null let const function
```

S1 從 staged diff 的 `-` 行抽識別字時只拿這份清單過濾。被刪的若是 docstring／註解，裡面的散文英文字（`and`、`items`、`Exception`…）全數通過，變成待查符號。

`and` 這種字在任何 repo 的架構圖裡都必然大量出現 → 必然命中 → 必然低信心（code 側也還在，判 `low`）。

## 為什麼現在才看到

`_delguard_confidence` 先前是單次多 pattern git grep，實測 10 個常見 token 要 39 秒，遠超預設 2.0s deadline，**每次都超時 fail-open**，輸出只有一行降級訊息。2026-08-27 改成逐 token grep（0.25s）後閘第一次真的跑完，缺陷才顯形。

★這條值得記在方法論層★：一道長期 fail-open 的閘，修好效能等於第一次啟用它——要預期看到一批從沒被看過的輸出，其中會有舊缺陷。

## 處置

見 summary 的候選解四條與 DECISION。選型前應先累積誤報帳（[[Systems/delguard]] 已知殘項節提到誤報帳目前是人工記錄）。
