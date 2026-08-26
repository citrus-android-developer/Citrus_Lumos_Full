---
type: issue
status: resolved
created: 2026-08-02
updated: 2026-08-02
related:
  - "[[Systems/lumos-cli-lifecycle]]"
  - "[[Systems/測試假綠形態]]"
  - "[[Systems/診斷迴圈先行]]"
pitfall_when:
  - "content:_VENDORED_TOOLKIT"
tags:
  - type/issue
  - status/resolved
summary: |-
  FLAG:TECHNICAL
  DECISION:不停止 vendoring 測試套件(消費端仍需要「更新後 CLI 有沒有壞」這個能力),改讓★來源 repo 專用★的測試在消費端乾淨 skip;判定★狀態驅動★(`_need_src()` 只看那個產物是不是真的不在),來源端零行為改變
  KEY:★實測數字(Landmark clone)★:`lumos update` 前 8 紅 → 更新後 ★91 紅★(本次精簡版工作讓它變 10 倍);修法後 ★0 紅 / 61 skip★,而來源 repo 仍是 2071 passed / 0 failed / ★0 skip★(守衛在來源端完全不生效)
  KEY:★目前沒有實害但一定會有★——pre-push 的測試閘要求 `skills/lumos-project-notes/` 存在,消費端沒有故整個閘跳過,那 91 紅是死的;但★一個會給假紅的套件,下一次就會被人用「反正它本來就紅」帶過★,那正是本專案這兩天一直在修的同一個病(閘給假紅 → 被 waive → 等於閘不存在)
  KEY:★覆蓋機制用「單一處的自動規則」不用逐支簿記★:`t_slim_*` 整族在 runner 一處以前綴涵蓋(新增的自動繼承),其餘 8 支個別加 `_need_src()`;往 40 個函式各插一行才是會漏的分支簿記
  KEY:★元守衛(這才是重點)★=`t_need_src_guards_cannot_silently_disable_coverage`:守衛的失敗模式是「放行」,所以它自己壞掉時必須大聲——掃本檔所有獨立成行的 `_need_src("...")` 實際參數,逐一斷言該路徑在來源 repo 真的存在。★自我維護★:新增守衛自動被涵蓋,不需維護第二份清單
  DEP:scripts/test_lumos.py(`_SrcOnly`/`_need_src`/runner 前綴規則/元守衛)｜scripts/lumos `_VENDORED_TOOLKIT`｜scripts/hooks/pre-push(測試閘的 `skills/lumos-project-notes` 條件)
---
# vendored 測試套件在消費端假紅

## 怎麼發現的

使用者問「有辦法在 Landmark 試試看嗎」。在 **Landmark 的 clone** 上排練 `lumos update`（本尊全程未動，已逐項核對），更新後跑 vendored 測試套件：**1684 passed / 91 failed**。

★我原本要說「那是既有現象」——跑了差異迴圈才發現是錯的★：

| | passed | failed |
|---|---|---|
| 更新前 | 1416 | **8** |
| 更新後 | 1684 | **91** |

（[[Systems/診斷迴圈先行]] 那條「不准在拿到訊號前建立理論」，第一個擋下的是我自己。）

## 真因

vendored 進消費端的 `test_lumos.py` 裡，有一大批測試驗的是**來源 repo 自己的產物**：`slim/` 交付包、`get.sh`、`docs/` 文件列舉、`governance/` 語料、來源 repo 自己的架構圖（`docs/lumos-toolchain-knowledge`）。消費端沒有這些東西，**必定紅**。

那 8 條舊的是同一類——**病本來就有，是本次精簡版工作讓它變成 10 倍**。

## 為什麼要修（目前沒有實害）

`pre-push` 的測試閘條件是 `skills/lumos-project-notes/` 存在，消費端沒有 → **整個閘跳過**，那 91 條是死的。

但：**一個會給假紅的套件，下一次就會被人用「反正它本來就紅」帶過。** 那正是本專案這兩天一直在修的同一個病——閘給假紅 → 被 `--no-verify` waive → 等於閘不存在。而它現在會被 `lumos update` 帶到每一個消費端專案。

## 修法

**不停止 vendoring**：消費端仍需要「更新後 CLI 有沒有壞」這個能力，那些測 CLI 行為的測試在消費端是有意義的。

- `_SrcOnly` 例外 ＋ `_need_src(*rels)`：★只看那個產物是不是真的不在★（狀態驅動，不是名單驅動）。來源 repo 一切照跑、零行為改變。
- runner 接住 `_SrcOnly` → 記成 **skip**，summary 印 `N skipped(來源 repo 專用)`。★不靜默★。
- 覆蓋用**單一處的自動規則**：`t_slim_*` 整族在 runner 一處以前綴涵蓋（新增的自動繼承）；其餘 8 支個別加 `_need_src()`。往 40 個函式各插一行才是會漏的分支簿記（2026-08-01 剛因同型簿記漏一條被代碼審抓到）。

## ★元守衛（這才是重點）★

`_need_src` 的失敗模式是**放行**——如果來源 repo 哪天少了 `slim/`，那些測試會在**來源端也靜默 skip**，覆蓋率無聲蒸發，而 skip 不會讓任何閘翻紅。

`t_need_src_guards_cannot_silently_disable_coverage`：掃本檔所有**獨立成行**的 `_need_src("...")` 實際參數，逐一斷言那個路徑在來源 repo 真的存在。**自我維護**——新增守衛自動被涵蓋，不需要第二份清單。

翻紅釘：`mv slim /tmp/slim-hidden` → 元守衛翻紅並印出 `缺: ['slim']`；還原後轉綠。

（第一版的正則把 docstring 裡提到的 `` `_need_src(...)` `` 也掃進來，掃出一個叫 `...` 的假路徑——改成只認獨立成行的呼叫。）

## 收斂數字

| | 消費端（Landmark clone） | 來源 repo |
|---|---|---|
| 修法前 | 1684 passed / **91 failed** | 2069 / 0 |
| 修法後 | 1675 passed / **0 failed** / 61 skipped | **2071 / 0 / ★0 skipped★** |

來源端 skip = 0 是關鍵：**守衛在來源端完全不生效，沒有遮掉任何一行覆蓋**。

## 誠實天花板

- 61 條 skip 在消費端是**真的沒被驗**——這不是把問題修好，是把「驗不了」從假紅改成誠實標示。消費端要驗那些東西，得在來源 repo 驗。
- `t_slim_*` 前綴規則是**約定**：如果有人寫了一支測交付包卻不叫 `t_slim_*`，它在消費端仍會假紅。元守衛抓不到這種（它只驗「被守門的產物存在」，不驗「該守門的都守了」）。★假設有第 N+1 種★。
