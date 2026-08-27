---
type: verification
status: pass
created: 2026-08-27
updated: 2026-08-27
aliases: []
tags:
  - type/verification
  - status/pass
  - scope/governance
related:
  - "[[Systems/delguard]]"
  - "[[Verification/2026-08-26_delguard簿記檔排除與成本根因定位]]"
  - "[[Issues/delguard抽詞把散文當符號]]"
plan_refs:
  - "[[Projects/code側刪除傳播守衛_計劃]]"
valid_under: |-
  _delguard_confidence 現行實作(逐 token 各跑一次 git grep --cached -n -I -w -F -e <單一 token>)
  量測環境:本 repo 2026-08-27 快照(304 篇 vault),macOS Darwin 25.6.0,git 系統版本,單機無併發負載
  常見 token 組 = node/path/line/check/root/text/name/type/value/token(打本 repo staged index)
  死 token 組 = zzNoSuchTok0..39(40 個 = DELGUARD_TOKEN_CAP 上限)
  LUMOS_DELGUARD_DEADLINE 預設仍為 2.0s(本次未調整)
revalidate_when: |-
  改動 _delguard_confidence 的 grep 形狀(合併回多 -e / 引入 thread pool 併發 / 換 -l 等旗標)
  DELGUARD_TOKEN_CAP 調整(40 是本次量測的最壞情況基準)
  git 大版本升級(多 pattern 退化是 git grep 本身的性質,上游修掉的話取捨前提就變了)
  vault 規模量級變化(vault_scan 那 0.21s 會跟著動,影響 2s benchmark 的餘裕)
summary: |-
  TEST:t_delguard 新增 7 條(逐 token 呼叫次數/每次單一 -e/每 token 各查一次、總預算耗盡拋 TimeoutExpired、中途逾時不回部分結果、10 個常見 token <5s、常見 token 仍判 low);t_delguard 96→103 條;全量 2884 passed / 0 failed(基線 2877)
  VERIFY:先紅後綠已補證——同一批新測試打在修前版 scripts/lumos 上 5 條紅(呼叫次數得 1 次、argv 得 3 個 -e、10 常見 token 得 39.14s、中途逾時回出 {'aTok':'high','bTok':'high','cTok':'high'} 的假警報 dict),修後全綠
  KEY:核心數字 10 個常見 token **39.00s → 0.25s(156×)**;代價 40 個死 token 0.02s → 0.62s;現場端到端 `lumos delguard --staged` 預設 2.0s deadline 下 0.23s 完成、未降級
  KEY:★閘修好=第一次啟用★——成本修完後閘第一次真的跑完,立刻露出既有的抽詞散文汙染缺陷([[Issues/delguard抽詞把散文當符號]]),本篇不處理
---
# 2026-08-27_delguard 逐 token grep

結清 [[Verification/2026-08-26_delguard簿記檔排除與成本根因定位]] 明寫「已定位、未修」的那一半：把 `_delguard_confidence` 從「單次多 `-e` 合併 grep」改成「逐 token 各跑一次」。

## 修法

`_delguard_confidence` 對每個 token 各跑一次 `git grep --cached -n -I -w -F -e <token>`，py 側仍只對內容域（`path:lineno:content` 的第三段）精配，維持 2026-08-11 code-loop r1 B 釘住的「檔名撞名不誤降級」。

順帶：`returncode == 1`（零命中）直接跳過，連 regex 都不用編。

## 量測

先紅後綠，兩邊都是實跑輸出，非估算。

| 情境 | 修前（單次合併） | 修後（逐 token） |
|---|---|---|
| 1 個常見 token | 0.04s | 0.03s |
| **10 個常見 token** | **39.00s** | **0.25s**（156×） |
| 40 個死 token（cap 上限） | 0.02s | 0.62s |
| 端到端 `delguard --staged`（預設 2.0s） | 超時降級 | **0.23s，未降級** |

2026-08-26 對另一組 token 量到 10 個 83.71s；39.00s 與之同量級同現象，★不應解讀兩個絕對值的差距★（token 組不同、機器負載不同）。

死 token 那 0.62s 拆開來看：純 subprocess 生成 0.22s（40 次 `git --version` 實測），其餘 0.4s 是 git grep 讀 index。三次重跑 0.624 / 0.617 / 0.615s，變異極小。

## 取捨

零命中那一格由 0.02s 變 0.62s，是明知的取捨：

- 那格本來就不是瓶頸——瓶頸一直是常見 token 那格，而現場 commit 幾乎必然混有常見 token。
- 最壞情況 0.62（confidence）+ 0.21（vault_scan）≈ 0.83s，仍在預設 2.0s deadline 內。
- benchmark 測試門檻同步由 `<1s` 放寬到 `<2s`——0.83s 壓在 1s 上會在忙碌機器上假紅。★這是放寬,不是移除★：同時新增「10 個常見 token <5s」那條，它離修後值有 20 倍餘裕、離修前值有 8 倍差距，兩邊都不會假紅假綠，是這次真正的鑑別力來源。

未做的下一步候選：thread pool 併發 N 個 grep（估 ~0.15s）。不做的理由是不想為了 0.5s 在 pre-commit 路徑上引入併發，且現況已在 deadline 內。

## timeout 語意變更

`timeout=` 從「單次 subprocess 的上限」變成「全部 N 次 grep 的總預算」，每次以剩餘預算轉傳。

★不得回傳部分結果★：預算耗盡一律拋 `subprocess.TimeoutExpired`，讓 `cmd_delguard_check` 既有的專屬 except 降級成 `reason=timeout` / 「本輪未實際守衛」。理由是沒掃到的 token 預設會被判 `high`（＝全域消失），那是**假警報**，比漏報更毒——翻紅釘實測修前版在同一情境回出 `{'aTok': 'high', 'bTok': 'high', 'cTok': 'high'}`。

## 驗證

1. **先紅後綠**：新增的 7 條打在修前版 `scripts/lumos` 上 5 條紅（另 2 條是契約測試，兩版皆綠，非鑑別力來源，已在測試註解標明）。
2. **機械 oracle 不只量時間**：spy 掉 `subprocess.run` 直接釘「3 個 token 跑 3 次、每次 argv 只帶一個 `-e`、每個 token 各被查一次」。只量時間會被機器快慢牽著走，合併版在快機器上也可能矇混過門檻。
3. **快不是靠少掃**：同一批常見 token 的判定結果全為 `low`，與修前一致——排除「靠漏掃換速度」這條假綠路徑。
4. **全量回歸**：2884 passed / 0 failed（基線 2877 + 7）。
5. **端到端**：對本次改動自己的 staged diff 跑 `lumos delguard --staged`，預設 deadline 下 0.23s 完成、`degraded: false`。

## 殘項

端到端那次跑出 5 個 token / 90 筆低信心命中、高信心 0，全部由 `and`、`items`、`Exception` 這類散文詞帶出——既有的抽詞缺陷，先前被必定超時遮住。立為 [[Issues/delguard抽詞把散文當符號]]，本輪不改（抽詞規則是 S1 判準核心，候選解四條且無誤報帳可裁）。
