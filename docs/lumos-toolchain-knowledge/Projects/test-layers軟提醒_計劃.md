---
type: project
status: done
created: 2026-07-17
updated: 2026-07-17
tags:
  - type/project
  - status/done
related:
  - "[[Systems/pitfalls-lint-adapter]]"
  - "[[Systems/pitfalls-code-loop]]"
  - "[[test-layers軟提醒_實作計畫]]"
  - "[[Android側UI測試綁架構圖工作流_計劃]]"
summary: |-
  KEY:問題=消費專案的測試套件 lumos 明文不越俎(pre-push 測試閘僅源 repo),E2E/Playwright/maestro 等慢測試層該硬在 CI 合併點——但「push 前忘了跑/忘了補」這個最便宜的破口目前零提醒
  KEY:方案=宣告+復用偵測+advisory 三件套——①專案 opt-in 宣告 .lumos/test-layers.json(棧 key→{layer,cmd,when},無檔靜默跳過)②棧偵測復用 pitfalls --diff 既有「副檔名→棧 key」對應(零新偵測碼)③pre-push 印 tier 後追加軟提醒段(恆 rc0,樣板同 co-change/Check H 的 advisory 型)④tier=high 時該宣告餵 code-loop 審查員當一個鏡頭(「此改動需不需要補/跑宣告的測試層?」)
  KEY:軟閘定位=關「忘了」不關「刻意不跑」——E2E 慢+flaky,本機硬擋逼出 --no-verify 文化反噬其他硬閘;真硬閘留 CI 合併點;同 code-loop 必用守衛/impact 的誠實天花板譜系
  KEY:v1 邊界=只提醒,不驗「有沒有真的跑」;v2 候選=查測試報告產物時間戳/接 CI 狀態(假陽性風險高,先不碰)
  DECISION:[2026-07-17]源起=使用者問「E2E 是軟閘嗎」延伸「能否按專案棧提醒對應測試環節」;裁定 v1 純 advisory、opt-in、恆不影響 rc(valid)
verified_by:
  - "[[Verification/2026-07-17_test-layers軟提醒]]"
---
# test-layers軟提醒_計劃

> 源起：2026-07-17 對話——E2E/Playwright 的閘位討論（快慢決定掛哪、承載合約才不可軟）延伸出「lumos 能不能按掛載專案的棧，軟提醒對應測試環節」。

PRIOR-ART: ① 最小解層級——復用 pitfalls --diff 既有棧偵測 + pre-push 既有 advisory 樣板（co-change/Check H 同型），新增=一個 opt-in 宣告檔 + 一段列印，無新機制。② 世界解過——Danger dangerfile（「改了 src 沒改 tests」PR 提醒）、Codecov patch coverage 評論，皆為「宣告＋diff 比對＋advisory」三件套。③ 裁定=borrow-design（借型原生實作，零依賴家規不引 Danger）。

## 設計

### 宣告檔（opt-in，無檔靜默）
```json
// .lumos/test-layers.json
{
  "vue":  { "layer": "E2E",     "cmd": "npx playwright test",  "when": "UI 元件/路由有動" },
  "kt":   { "layer": "UI 流程", "cmd": "maestro test flows/",  "when": "畫面或互動有動" },
  "cs":   { "layer": "整合",    "cmd": "dotnet test --filter Category=Integration", "when": "API/DB 有動" }
}
```
棧 key 語意與 `.lumos/lint.json` 一致（去點副檔名），偵測復用 pitfalls --diff 的既有對應，零新偵測碼。

### 觸發點
1. **pre-push**（主場）：印完 pitfalls tier 後，diff 命中宣告棧 → 追加軟提醒段，**恆 rc 0**：
   ```
   💡 test-layers 軟提醒(不擋):
      本次 diff 碰到 vue(8 檔) → 專案宣告的 E2E 層:npx playwright test
      跑了嗎?沒跑的話這是 push 前最後一次便宜的提醒點。
   ```
2. **code-loop 鏡頭**（加乘）：tier=high 時宣告內容併入審查員 prompt——「diff 碰了 X 層、專案宣告 Y 測試,判斷此改動需不需要補/跑」。

### 實作注意
- pre-push 是 **anchor 保護檔**——改動需 `lumos anchor approve --note` 走正門。
- advisory 段必須 `|| true` 隔離＋恆 rc 0（同 co-change 前例：警告走 stdout、診斷吞 stderr、版本偏斜不弄爆 hook）。
- 宣告檔解析失敗 → 靜默跳過＋一行 stderr 診斷，不得影響 push（fail-open，同 lint-adapter 慣例）。

## 誠實天花板
- 關「忘了跑」，關不掉「刻意不跑＋不誠實」——同守衛譜系，靠留痕事後可查。
- v1 不驗證「有沒有真的跑」：查產物時間戳/接 CI 假陽性風險高，留 v2 且需先想清楚判定來源。
- 提醒疲勞風險：若每次 push 都刷同樣提醒會被無視——`when` 欄位是給人讀的判斷提示，不是機械條件；v1 接受此限制。

## 進實作前（紀律）
宣告檔＋列印＋prompt 併入，無深演算法——貼 standard：走 writing-plans＋TDD（宣告解析/棧命中/rc 恆 0 三組測試），可跳 design-loop 並註明（glue 層，實作真測 > 設計散文，同 code-loop必用守衛前例）。落地 Verification 以 `plan_refs` 回指本節點。

## 下一步
- [x] writing-plans 出實作計畫 → [[test-layers軟提醒_實作計畫]]（2026-07-17，4 task TDD）
- [x] 實作後 anchor approve（pre-push 檔有動）
- [ ] 消費專案真機驗證一輪（建議 LandmarkMember 或前端專案，ship 後行動，不在本計畫範圍）
- [ ] 存量類級收口候選（code-loop r2/r3 產出）：檔名含字面雙引號/反斜線時 git 仍強制轉義加引號（quotePath 關不掉），全家族 `--name-only`/`+++ b/` 解析點需統一 unquote helper 才能根治——觸發面極窄，accepted minor 留痕於 code-loop pass note
