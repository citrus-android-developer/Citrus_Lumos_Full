---
type: moc
status: doing
---
# lumos-toolchain 知識架構圖總索引

Lumos 工具鏈(`scripts/lumos` + skills + governance 自動化)自身的知識架構圖。節點現況以 code 為準,完整設計史/收斂史指回 `docs/design/`。狀態標記:無標=已實作;`[planned]`=設計收斂未落地;`[deferred]`=擱置;`[rejected]`=評估後不做(輕方案落地)。

> **慣例**:節點內嵌的 `scripts/lumos:行號`(或 `@行號`、`:行號`)是**近似導航參考**,code 重構後可能漂移——以 code 現況與函式名為準,行號僅供快速定位。

## 設計審計 loop(進實作前的把關)
- [[Systems/design-loop]] — canary-護的設計審計 loop;Claude 編排、lumos 出原語,連 2 輪 caught 才放行實作。
- [[Systems/canary-audit]] — test-the-tester:每輪偷植已知假錯驗審計員有沒有認真抓(防假陰性/放水)。
- [[Systems/loop-convergence-recording]] — `canary record --loop/--severity` + `loop status --need` 算收斂、可機械終止多輪。
- [[Systems/finding-refute]] — 辯方 refute:對 ≥major finding 派獨立 opus 強制 file:line 反證才降(防假陽性,對稱 canary)。
- [[Systems/judge-severity-gate]] — 讓 judge 覆蓋 severity 維度,堵「收斂門檻沒覆蓋處偷工」。
- [[Systems/cross-family-audit]] — 換模型家族複核(qwen3-max),解 opus 審 opus 的自我偏好偏心。
- [[Systems/judge-perturbation-stability]] `[rejected]` — 評審擾動穩定性;評估後改走輕量 confidence_report.py。

## doctor 合約 / 可逆性檢查
- [[Systems/check-t-sentinel]] — Check T:★INVARIANT★ 合約綁可執行測試 `[test:]`(+ stub 紅燈哨兵)。
- [[Systems/check-r-guard]] — Check R:不可逆動作(★IRREVERSIBLE★)動手前要有實質 `[rollback:]`/`[guard:]`。
- [[Systems/reversibility-governance-ledger]] — 可逆性綁定 + gov 治理事件帳(某節點被哪幾道閘攔過)。
- [[Systems/doctor-irreversible-hint]] — `[H]` 軟提醒:掃 diff 碰 prod/外部 API → 是否漏標 ★IRREVERSIBLE★。
- [[Systems/check-j-regen-guard]] — Check J:from-scratch 重建節點 provenance 分級(regen 蓋章+[src:]/[git:]/推測:/佚失: 標身分;拒發明無證據合約、假指針機械擋)。
- [[Systems/core-invariant-baseline]] `[deferred]` — 核心節點已知良好快照 + 可回退(pivot 為 content-baseline,擱置)。

## 自主治理 / loop engineering
- [[Systems/autonomous-iteration-loop]] — 日報 gap→brainstorm→design-loop→收斂備 pending 的無人看顧自主迭代。
- [[Systems/verification-rot-eval]] `[planned]` — 從架構圖史抽衝突測試集定期回測 L3 腐化偵測(設計收斂未落地)。

## 安全與權限
- [[Systems/nested-agent-permission-scope]] — 子 agent 權限收窄(maker≠checker 的審計員不繼承主對話權限)。

## 平台支援
- [[Systems/native-windows-support]] — 原生 Windows(get.ps1 / mklink / junction / hook 路徑正斜線化)。
- [[Systems/lumos-deinit]] — 專案層反安裝指令(對稱 `lumos init`);四重閘保護不可逆的 vault rmtree。

## 完整性 / 影響 / 漂移守衛
- [[Systems/guard-kill]] — 殺傷力驗證:宣告壞法→worktree 隔離→綁定測試必翻紅;survived=稻草人證據(合約鏈最後一哩)。
- [[Systems/cochange-guard]] — co-change 漏改守衛:git 歷史挖共改規則(ROSE 非對稱 confidence),pre-commit Gate CC 警告漏改夥伴(advisory)。

## 檢索與推薦
- [[Systems/retrieval-ranking]] — BM25F 排序+圖分融合推薦+impact 降噪(search 與 hook 面均已轉正——§6 七盞全綠;recommend 面 dormant)。

## CLI 核心原語
- [[Systems/lumos-cli-read]] — 讀/巡檢:doctor/context/contracts/search/links/backlinks/map/export/decisions/stale/recent/stats。
- [[Systems/lumos-cli-write]] — 寫:set/append/new/archive/decision-add/decision-supersede/self-audit;T1 寫後自驗 atomic。
- [[Systems/lumos-cli-lifecycle]] — install/uninstall/update/bootstrap/init/deinit;機器層 vs 專案層分工。

## 外部對照 / PRIOR-ART
- [[Systems/外部對照-code衍生wiki]] — langchain-ai/openwiki(11.6k★ code 衍生 wiki)反例世界解:站在 lumos 導覽層、賭注相反(code 衍生+可丟 vs 架構圖手寫+機械守);核心論點=重生保新鮮≠正確、無輸出 oracle(maker-only),反證 lumos「架構圖即真相/合約驗證層」的必要。

## 外部設計 / 計畫文件(架構圖外,但屬本工具鏈)
- `docs/design/` — 各功能設計稿(含 design-loop 收斂紀錄,18 份)。
- `docs/superpowers/plans/` — 實作計畫(TDD 任務分解)。
- `docs/methodology/` — 「架構圖即合約」方法論。
- `governance/reports/` — AI 治理日報(研究 → gap → 觸發上述功能的 provenance,各 Verification/Systems 節點內有溯源)。
