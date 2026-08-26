# rel-layer-guard · design-loop findings 語料（3 輪，2026-07-14）

> 狀態：**架構收斂、實作合約未釘**；人裁定收成設計資產、暫停實作（**非** panel gate-clean）。
> spec 快照見同目錄 `spec.md`（＝計劃節點 `Projects/關係層傳播守衛_計劃` 的 v3）。
> 跨家族 Codex（gpt-5.6-sol）讀 repo 兩輪修正地基——doc-only 的同家族 sonnet 結構上抓不到。

## 輪次帳（canary log）

| 輪 | canary（型別） | 抓到? | Codex 決定性發現 | 轉向 |
|---|---|---|---|---|
| r1 | [S12]bad-ref / EDGE_STALE_DAYS(a/c) | 皆抓 | PRIOR-ART 誤指 `_reco_scores`（推薦排序器非傳播引擎）；decision-supersede 是 Bash CLI、PreToolUse 撞不到；Stop hook 誤當 pre-commit | → 修引擎/觸發 |
| r2 | [P4]bad-ref / .edge-provenance(a/d) | 皆抓 | 更深：`_impact_bfs`/`_impact_via` 也不行——**架構圖建圖層 `Env.edges` 以 target 去重、丟掉邊型**；ledger 粒度不足；判斷閘寫回介面全空白 | → 翻 build P0 typed-edge index |
| r3 | INDEX_REBUILD_SEC / [S13]bad-ref(c/a) | 皆抓 | **確認 P0 從 frontmatter 具名欄位建得出**（block scalar 已排除、寫側白名單有）；總評「方向可行、P1 與 CLI 架構能局部落地」；剩全是合約細節 | → 收斂、暫停 |

## 三輪逐層的地基修正（Codex 讀 repo，附 `scripts/lumos` 行號）

- **r1**：`impact` 的引擎不是 `_reco_scores`（那是無向推薦排序器）。
- **r2**：也不是 `_impact_bfs`+`_impact_via`——lumos 架構圖在**走圖層無型別**（`Env.edges` 去重丟來源欄位、`_impact_via` 事後單值猜型、`related` 遮 `verified_by`）。**但邊型存在 frontmatter 具名欄位**（`verified_by`/`plan_refs`/`related` 各自 list）→ 補網直接讀可行、主網需**新建 typed-edge index**。
- **r3**：P0 typed-edge index 從 frontmatter 建**可行**（具名欄位確實解析成 list）。剩：rel-cascade 需 `--cascade-id`、supersede 需回傳 decision-id、P0 ghost/scalar/同名政策、ledger 並行鎖/CAS、P1 單次 atomic、E2 首判粒度、菱形依賴、crash 恢復、path 安全。

## phase-1 MVP（現成可建）

**補網 `[S6]` E1 失效背書**：只讀 `verified_by`+V.status（stale/fail 即標）、**不需任何前置**、獨立可驗——立刻把「$30 AI 交叉審才掃得出的頭號腐爛」變**免費週期檢查**。接著 `[P0]`→E2/E4。主網（typed hop-1 + cascade ledger + `rel-cascade` CLI）較大工程、後上。

待釘合約完整清單見 spec.md §八。

## 方法論收穫（meta）

- **跨家族 Codex 讀 repo = 這一小時兩份設計（idioms + 本案）的 MVP**：它兩次揪出「設計假設了 codebase 沒有的東西」（idioms：gapfill/自主 loop/canary-record 契約；本案：impact 引擎、架構圖無型別）——**同家族 doc-only 審計結構上抓不到**（它們只驗文件內部一致性）。佐證 reviewer 跨家族 slot + 「否決席常駐」的設計。
- **design-loop 對「觸及大量既有 repo 契約的整合型 spec」特別有價值**：把「這假設了不存在的機制」逐層逼出，避免帶錯假設進實作。三輪收斂的訊號＝**不再翻地基、只剩合約細節**。
