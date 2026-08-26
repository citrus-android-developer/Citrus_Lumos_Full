---
type: project
status: done
created: 2026-07-11
updated: 2026-07-11
tags:
  - type/project
  - status/done
related:
  - "[[Systems/retrieval-ranking]]"
  - "[[Systems/pitfalls-code-loop]]"
  - "[[Projects/檢索優化_計劃]]"
---
# impact-diff橋接_計劃

檢索排序轉正後的第一個消費場景橋接（使用者提案）：code-loop 終審時，用已量測過的 ranked impact 給審計員一顆「**受影響功能面**」鏡頭——更精確評估相關功能是否被這段 diff 波及。

PRIOR-ART: 沿用 [[Projects/檢索優化_計劃]] §3（hook 降噪機件,已 goldset 評測）與 code-loop 既有「manifest 餵鏡頭」模式（pitfalls manifest 同型），無新機制——兩端的世界輪子調研已在各自計劃做過；本計劃=純聚合 glue。

**跳 design-loop 註明**：glue/編排層（聚合既有 cmd_impact 逐檔結果），無新演算法、無新合約；依 [[Systems/design-loop]] 已實證教訓（對 glue 散文空轉、機械核心才收斂）改以實作真測收口（t_impact_diff 9 斷言）。

## 設計裁定

- **入口**：`lumos impact --diff <base>..HEAD [--json] [--top N]`（與 `--file` 二擇一;都缺 rc2）。
- **聚合語意**：diff 內每支改動 code 檔各跑一次 ranked impact（共用一次載入的架構圖環境——r1 panel N+1 修正），query=該檔 hunk 文字（`+/-` 行內容,cap 4000 字元）；跨檔合併=同節點取最高分整項重建（防 hop/L 幽靈欄位殘留）、pinned 任一檔 pinned 即 pinned、記來源檔清單。**種子過濾（r1 panel 修正）**：排除 `docs/`、`governance/golden/`、`*.jsonl`、`*.md`、governance 資料 `*.json`（goldset/裁決檔內嵌歷史 code 片段會偽觸發事故 pin——實證）；**已刪檔保留**（反查靠節點 body 引用路徑,刪除/改名正是合約節點最該被看到的時刻）。--file 與 --diff 同給 rc2。
- **輸出**：固定席（合約/事故）全保、非固定 top-N;人讀標「審計鏡頭,人判」;--json 帶 per-file meta。
- **定位（關鍵裁定）**：**advisory 審計鏡頭,不是自動閘**——機械保證只涵蓋合約/事故類固定席,其餘經排序無保底;code-loop 有 reviewer 在場,保底與噪音都由人兜。（時代註:裁定當下 hook 面 P@8≈.5 未過線;2026-07-11 深夜三病因修畢過 §6 後**單檔版已接 hook**,見 [[Verification/2026-07-11_hook面v1.1轉正]]——本 --diff 聚合版維持鏡頭定位不變。）
- **prospective 不需要**：diff 模式下 HEAD/工作樹已是改後內容,事故 content trigger 讀磁碟即為「套 delta 後」語意。
- **消費點**：`lumos-code-loop` skill 步驟 3——派 reviewer 前跑,manifest 附給 reviewer:「逐條判此 diff 會不會破壞該節點宣稱的行為/合約;固定席必答」。

## 驗證

- t_impact_diff 14 斷言：rc/manifest 結構/seed 過濾（code 檔進、架構圖節點與 governance 資料檔不進、**已刪檔保留**、CJK 檔名 quotePath）/已刪檔合約節點固定席/事故磁碟觸發/非固定帶來源檔/人讀標頭/參數守衛 rc2。
- 真機（本 repo HEAD~3..HEAD,15 檔）：固定席 3（2 事故+1 合約）浮頂,自由席前三=該批 commit 實際動到的功能節點（檢索優化_計劃/retrieval-ranking/goldset 驗證）——語意正確。

## 落成位置閉環（使用者提案 → 2026-07-11 已實作）

design-loop 收斂→code-loop 過審之後,「退場必寫」目前只有 pre-commit 粗閘（有沒有帶架構圖改動）與人判;精確版=**`impact --diff` 的預期受影響集 ∩ 分支實際動過的架構圖節點**——受影響但未同步的節點列 advisory 清單（code-loop finishing 步驟或 pre-push 軟提醒）,回答「你改了這功能,但它的節點沒動,是漏了還是不用?」。誠實界定:固定席（合約/事故）可信度高、自由席人判——所以是提醒不是硬閘。

**實作（2026-07-11）**：`lumos impact --diff <range> --sync-check`——同一段 diff 內「預期受影響節點(固定席+top-N)」對比「實際動過的架構圖節點」,列**未同步清單**(pinned 標⚠必看);--json 帶 sync 段(touched_nodes/missing)。消費點=code-loop 收斂後、`code-loop pass` 之前(skill 已入列)。advisory 不擋:「漏了還是不用」由人/編排者逐條判。t_impact_diff +6 斷言;真機自檢:本 repo 近三筆 commit 落成全同步。

## 相關模組

- [[Systems/retrieval-ranking]]
- [[Systems/pitfalls-code-loop]]
