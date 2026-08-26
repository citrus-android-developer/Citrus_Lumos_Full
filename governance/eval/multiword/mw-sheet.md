# 檢索相關性標註表(多詞查詢,M01-M10)

知識庫在:`/private/tmp/claude-501/-Users-enzo-harness-lumos-toolchain/e74434fc-8040-402f-a23c-9df2bc617bfc/scratchpad/snap285/docs/lumos-toolchain-knowledge`(共 102 篇,這是 2026-07-10 的凍結快照)。可自由 Read/grep。

## 怎麼標

對每個候選節點,判斷它對該查詢的相關性:

- `2` = **必看**——要回答這個查詢,一定得看它
- `1` = **有用**——相關,但不是非看不可
- `0` = **噪音**——只是碰巧含到查詢裡的某個詞,對回答這查詢沒幫助

★重要★:候選是機器撈的,**裡面本來就會有噪音**。大方給 0,不要因為它被撈出來就覺得該給分。
★重要★:判斷「對這個查詢有沒有用」,不是「這篇好不好」。一篇很重要的節點對不相干的查詢一樣是 0。

## 輸出

只輸出一段 JSON:`{"M01": {"路徑": 2, "路徑": 0, ...}, "M02": {...}, ...}`
每個候選都要給值,不可省略。

---

## M01｜查詢:「合約 綁定 測試」
- Systems/lumos-cli-read.md
- Projects/主動影響幅度偵測_實作計畫.md
- Projects/guard殺傷力驗證_計劃.md
- Verification/2026-07-02_multiplatform-test-binding.md
- Systems/core-invariant-baseline.md
- Projects/多平台合約測試綁定_計劃.md
- Systems/test-profile-multiplatform.md
- Projects/主動影響幅度偵測_計劃.md
- Systems/guard-kill.md
- Verification/2026-07-10_guard殺傷力驗證.md
- Systems/convergence-evidence-gate.md
- Verification/2026-07-10_合約鏈補強234.md
- Projects/檢索優化_計劃.md

## M02｜查詢:「canary 收斂 判定」
- Projects/loop三輪壓縮_計劃.md
- Projects/guard殺傷力驗證_計劃.md
- Projects/收斂閘caught-rate修正_計劃.md
- Projects/code-loop必用守衛_計劃.md
- Projects/spec合規slot_計劃.md
- Systems/loop-convergence-recording.md
- Systems/heterogeneous-finder-ensemble.md
- Systems/cross-family-audit.md
- Projects/社群演算法補強_調研.md
- Systems/canary-audit.md
- Systems/design-loop.md
- Systems/autonomous-iteration-loop.md
- Projects/pitfalls-lint-integration_計劃.md

## M03｜查詢:「事故 語料 反轉」
- Projects/canary生成硬化_計劃.md
- Systems/canary-audit.md
- Systems/guard-kill.md
- Projects/主動影響幅度偵測_計劃.md
- Projects/pitfalls-lint-integration_計劃.md
- Projects/pitfalls事故觸發_計劃.md
- Projects/先問世界_存量掃描裁定.md
- Projects/pitfalls事故觸發_實作計畫.md
- Verification/2026-07-05_pitfalls事故觸發.md
- Projects/pitfalls網搜補漏_計劃.md
- Verification/2026-07-10_審計loop研究硬化.md
- Systems/pitfalls-code-loop.md
- Projects/社群演算法補強_調研.md

## M04｜查詢:「可逆性 回退 綁定」
- Systems/check-r-guard.md
- Verification/2026-07-04_risk-tiered-review.md
- Systems/lumos-cli-read.md
- Verification/2026-07-02_multiplatform-test-binding.md
- Systems/core-invariant-baseline.md
- Verification/2026-06-19_reversibility-governance-ledger.md
- MOC/index.md
- Systems/reversibility-governance-ledger.md
- Systems/doctor-irreversible-hint.md
- Projects/guard殺傷力驗證_計劃.md
- Verification/2026-07-10_合約鏈補強234.md
- Projects/多平台合約測試綁定_計劃.md

## M05｜查詢:「治理 帳 留痕」
- Projects/檢索優化_計劃.md
- Systems/anchor-integrity.md
- Projects/code-loop必用守衛_計劃.md
- Systems/loop-convergence-recording.md
- Systems/core-invariant-baseline.md
- Systems/design-loop.md
- Projects/收斂閘caught-rate修正_計劃.md
- Projects/code-loop必用守衛_實作計畫.md
- Verification/2026-07-10_審計loop研究硬化.md
- Issues/自主loop加法偏食.md
- Projects/cochange守衛_計劃.md
- Verification/2026-07-05_code-loop必用守衛.md
- Projects/先問世界_存量掃描裁定.md
- Projects/檢索優化_調研.md
- Systems/lint-version-watch.md
- Systems/reversibility-governance-ledger.md

## M06｜查詢:「架構圖 同步 閘」
- Systems/lumos-deinit.md
- Projects/社群演算法補強_調研.md
- Projects/cochange守衛_計劃.md
- Systems/autonomous-iteration-loop.md
- Projects/多平台合約測試綁定_計劃.md
- Systems/core-invariant-baseline.md
- Projects/CLAUDE注入re-sync與版本標籤_實作計畫.md
- Verification/2026-07-10_cochange守衛.md
- Projects/CLAUDE注入re-sync與版本標籤_計劃.md
- Projects/pitfalls事故觸發_實作計畫.md
- Projects/guard殺傷力驗證_計劃.md
- Issues/design-loop折入漂移_機械守衛.md
- Projects/design-loop折入守衛_計劃.md
- Projects/主動影響幅度偵測_計劃.md
- Systems/lumos-cli-lifecycle.md

## M07｜查詢:「掃描器 形態 漏網」
- Systems/pitfalls-code-loop.md
- Projects/先問世界_存量掃描裁定.md
- Verification/2026-06-24_finding-refute.md
- Projects/pitfalls網搜補漏_計劃.md
- Verification/2026-07-04_lint-version-watch.md
- Issues/自主loop加法偏食.md
- Verification/2026-07-04_pitfalls-code-loop.md

## M08｜查詢:「節點 引用 座標」
- Projects/檢索優化_調研.md
- Systems/pitfalls-code-loop.md
- Projects/先問世界_存量掃描裁定.md
- Projects/檢索優化_計劃.md
- Projects/pitfalls事故觸發_計劃.md
- Projects/主動影響幅度偵測_計劃.md
- Verification/2026-07-04_pitfalls-lint-adapter.md
- Verification/2026-07-05_pitfalls事故觸發.md
- Projects/pitfalls事故觸發_實作計畫.md
- Projects/主動影響幅度偵測_實作計畫.md
- Verification/2026-07-02_lumos-refcheck.md
- Systems/convergence-evidence-gate.md
- Systems/pitfalls-lint-adapter.md

## M09｜查詢:「對抗 審計 辯方」
- Systems/canary-audit.md
- Systems/finding-refute.md
- Verification/2026-06-19_design-loop.md
- Systems/convergence-evidence-gate.md
- Verification/2026-07-09_loop三輪壓縮.md
- Projects/loop三輪壓縮_計劃.md
- Systems/design-loop.md
- Systems/pitfalls-code-loop.md
- Projects/多平台合約測試綁定_計劃.md
- Issues/自主loop加法偏食.md

## M10｜查詢:「突變 測試 存活」
- Projects/guard殺傷力驗證_計劃.md
- Projects/loop三輪壓縮_實作計畫.md
- Projects/loop三輪壓縮_計劃.md
- Systems/convergence-evidence-gate.md
- Projects/多平台合約測試綁定_計劃.md
- Verification/2026-07-02_multiplatform-test-binding.md
- Verification/2026-07-09_loop三輪壓縮.md
- Projects/主動影響幅度偵測_計劃.md
- Systems/design-loop.md
- Systems/finding-refute.md
- Projects/主動影響幅度偵測_實作計畫.md
- Systems/heterogeneous-finder-ensemble.md
- Projects/先問世界_存量掃描裁定.md
