---
type: verification
status: pass
feature: decision-add 補齊 ADR 四欄位(--alternatives / --trade-offs)
date: 2026-08-26
valid_under: |-
  scripts/lumos 現行 surgical line-based decisions 手術(要求 2-space entry 縮排);_fmt_decision_value 的引號規則(僅「冒號+空白」或行首特殊字元才引號化);parse_decisions 對巢狀清單的解析;lint decisions 結構守衛已容忍巢狀清單(2026-08-05 假陽性修正後)。測試套件 2851 條全綠為基線。
revalidate_when: |-
  ①decisions 縮排契約變更(item_indent/sub 或改用 ruamel round-trip) ②_fmt_decision_value 引號規則變更 ③parse_decisions 對巢狀 list 的行為變更 ④lint decisions 結構守衛再動(巢狀清單假陽性可能復發) ⑤ADR 欄位規範本身增減欄位
plan_refs:
  - "[[Projects/授權與著作權宣告_計劃]]"
related:
  - "[[Systems/lumos-cli-write]]"
tags:
  - type/verification
  - status/pass
summary: |-
  TEST:新增 4 支測試 19 條斷言全綠;全套回歸 2851→2855 條。紅→綠→還原翻紅釘三段皆實測
  VERIFY:★缺口來自實戰★——[[Projects/授權與著作權宣告_計劃]] 寫兩條 ADR 時撞到:規範要求四欄位,CLI 只支援 context/why_chosen,而鐵則又禁止手改 frontmatter,兩條規矩對撞、無路可走
  KEY:★兩條 block 組裝路徑抽成單一源 `_decision_block`★——不是「改兩個地方」而是消除分支簿記這個缺陷類別;新增欄位天生對兩條路徑同時成立,不靠人記得改兩處
  KEY:★寫後自驗升級是本次最有價值的一段★——只驗 id+content 時,巢狀清單縮排寫錯會 YAML 解成別的東西卻回 rc=0(同 remove「不命中回成功」那類假成功)。實測植入 sub+2→sub 壞法:自驗擋下、rc=2、原檔零變動
  KEY:★過度引號化也是錯★——YAML 的 plain scalar 允許冒號不接空白;初版測試斷言「含冒號必引號」是我寫錯,實作維持既有規則正確(僅「冒號+空白」才引號化),否則徒增 diff 噪音
---
# 2026-08-26 decision-add 四欄位 ADR

## 一句話

**規範要求 ADR 四欄位、鐵則禁止手改 frontmatter、但 CLI 只寫得出其中兩欄——三者對撞導致重大決策的「為什麼不選 B」永遠進不了 frontmatter。本次補上缺的兩欄。**

## 缺口怎麼被發現的

不是憑空盤點出來的,是寫 [[Projects/授權與著作權宣告_計劃]] 那兩條 ADR 時實際撞上:

- `lumos-project-notes` reference 規定重大決策須填 ADR 四欄位:`context` / `alternatives_considered` / `why_chosen` / `trade_offs`,並明言「**為什麼選 / 為什麼不選才是真正的決策智慧,選了什麼只是結果**」。
- `lumos decision-add` 只有 `--context` / `--why`。
- skill 鐵則:「decisions 一律走 `decision-add`,別手改 frontmatter」。

三條規矩交集 = 四欄位裡有兩欄**結構性地寫不進去**。當時的折衷是把 alternatives 與 trade-offs 寫進本文,並在節點記下這個限制。

## 改了什麼

| 項目 | 內容 |
|---|---|
| CLI | `--alternatives`(`action="append"`,可重複)→ `alternatives_considered` 巢狀清單;`--trade-offs` → `trade_offs` 純量 |
| 欄位順序 | content / id / context / alternatives_considered / why_chosen / trade_offs / decided / valid(對齊 reference ADR 完整版範例) |
| 縮排 | entry `-` 在 item_indent(2)、子鍵 sub(4)、巢狀清單項 sub+2(6) |
| 結構 | 抽出 `_decision_block()` 單一組裝源,取代兩條路徑各自組裝 |
| 自驗 | `_check` 從「id+content」升級為四欄位皆驗(含 alternatives 解析回 list、逐項比對) |

## 測試

新增 4 支,19 條斷言:

| 測試 | 釘什麼 |
|---|---|
| `t_decision_add_four_field_adr` | 四欄位寫入 + 欄位順序 + 冒號不接空白保持 plain |
| `t_decision_add_alternatives_parse_back` | ★寫得出來 ≠ 讀得回來★:`parse_decisions` 必須把 `alternatives_considered` 解析為 **list**、內容逐項相符 |
| `t_decision_add_four_field_no_existing_decisions` | ★分支簿記守衛★:無 decisions 那條路徑同樣寫得出四欄位 |
| `t_decision_add_four_field_lint_clean` | 四欄位寫入後 `lint` rc=0;含「冒號+空白」的值必被引號化(鐵則3) |

## 三段實測(紅→綠→還原翻紅)

1. **紅**:實作前跑新測試 → `unrecognized arguments: --alternatives --trade-offs`,失敗原因正是缺參數。
2. **綠**:實作後 19 passed / 0 failed。
3. **還原翻紅釘**:植入壞法「巢狀清單縮排 sub+2 → sub」→ 8 failed,且**由寫後自驗攔下**(`ERROR: 自驗失敗:decisions 寫入後值不符預期`, rc=2, 原檔零變動),非事後才被 lint 發現。還原後 checksum 比對一致(`97c16f66…`)、回綠。

## 過程中自己踩到的三個測試錯誤(誠實記下)

初版測試 3 條紅燈**全部是測試寫錯,不是實作有問題**:

1. **順序斷言抓錯目標**——fixture `_vault_with_decisions()` 既有決策本身就含 `alternatives_considered`,對全文 `txt.index()` 抓到的是別條的欄位。改成只在新決策自己的 block 內比對,並在測試留註記防後人重蹈。
2. **過度引號化的斷言**——斷言「含冒號必引號」是錯的。YAML plain scalar 允許冒號不接空白,`_fmt_decision_value` 僅在「冒號+空白」或行首特殊字元才引號化,行為本來就對。改測真正需要引號的值,並補一條反向斷言釘住「不該多加引號」。
3. **lint fixture 缺 summary**——原 fixture 的 `Systems/X.md` 無 summary block,lint 本就會擋,與本次改動無關。改用自建的合規 fixture。

> ★教訓★:測試翻紅時先問「紅的是實作還是測試」。這三條若當成實作缺陷去「修」,會把正確的行為改壞——正是 CLAUDE.md 那條「架構圖與行為事實衝突時不自動判架構圖為真」的同型情境,只是換成「測試與實作衝突時不自動判測試為真」。

## 未涵蓋

- **既有節點不回溯**。本次只讓新寫入寫得出四欄位;架構圖裡既有的決策仍是兩欄或更少,未批次回填。
- **`decision-supersede` 未動**。翻案路徑不涉及新增欄位。
- **無 `--alternatives` 的既有呼叫完全不受影響**(參數皆 optional,`None` 時不產生對應行);既有 `t_decision_add` / `t_decision_add_no_existing` 未改仍綠,即為相容性實證。
