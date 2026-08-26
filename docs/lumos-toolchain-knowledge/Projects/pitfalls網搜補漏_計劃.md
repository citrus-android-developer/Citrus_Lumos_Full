---
type: project
status: done
created: 2026-07-05
updated: 2026-07-05
tags:
  - type/project
  - status/done
related:
  - "[[pitfalls-lint-integration_計劃]]"
  - "[[finding-refute]]"
  - "[[linter-gap實務隱患]]"
plan_refs:
  - "[[pitfalls-lint-integration_計劃]]"
summary: |-
  FLAG:DECISION
  KEY:pitfalls-lint-integration ③ 網搜補漏(邊角)——linter 未收錄的新坑,Claude WebSearch 找→反證預篩(駁倒即丟)→駁不倒進候選(非定論)→人輕量放行→進架構圖
  KEY:形態=on-demand lumos-* skill(源 lumos-toolchain repo symlink,像 lumos-design-loop);Claude 編排(WebSearch+反證)、人放行、架構圖存放;**無 lumos 新碼**(只用既有 new issue/append/search)
  FLOW:調用 skill → 讀該專案 linter-gap Issue 兩段(已採納/已評估駁回)去重 → 對 stack(從 .lumos/lint.json 得已覆蓋範圍)WebSearch 新坑 → 反證預篩(default-refute 附來源/file:line,駁倒即丟)→ 駁不倒候選 → 人放行 → 進〈已採納〉/駁回進〈已評估駁回〉(節點自去重)
  KEY:放行落 Issues/linter-gap實務隱患.md(每專案一個,兩段;與 ④ 事故語料同居、可被 pitfalls 進場餵)
  KEY:誠實天花板(計劃明載,skill 複述)=無機械 oracle(舉不了反證≠真:缺席證明謬誤+反證者能力上限,同 canary/[audit:])、人閘省不掉、量少邊角別過度跑
  DECISION:跳 design-loop——純散文 skill 無演算法/code,design-loop 對散文空轉(見記憶 design-loop-completeness-ceiling);驗收改 dogfood 真 stack 走一次流程
  DEP:[[finding-refute]]
  TEST:已實作(skill skills/lumos-pitfalls-gapfill + dogfood 真 stack python 走通全流程);VERIFY:[[2026-07-05_pitfalls網搜補漏]]
verified_by:
  - "[[2026-07-05_pitfalls網搜補漏]]"
---
# pitfalls 網搜補漏_計劃(block ③)

> 解 [[pitfalls-lint-integration_計劃]] 的 ③ 網搜補漏(邊角)。**極輕**:一個 skill + 純架構圖,無 lumos 新碼。原「自建網搜迭代包」已於 pitfalls-lint brainstorm 推翻改吃 linter,③ 是殘留邊角。

## §1 形態與分工
一個 **on-demand lumos-* skill**(源在 lumos-toolchain repo `skills/`、symlink 進 `~/.claude/skills/`,同 lumos-design-loop)。
- **Claude 編排**:WebSearch 找新坑 + 反證預篩(派 refuter,借鏡 [[finding-refute]])。
- **人放行**:候選非定論,人輕量放行(無 oracle,省不掉)。
- **架構圖存放**:放行的坑進架構圖節點。
- **無 lumos 新碼**:skill 只用既有 `lumos new issue`/`append`/`search`/`context` 讀寫節點。

## §2 skill workflow(寫 spec / code-loop 遇某 stack 時主動調用)
1. **讀去重基準**:讀該專案 `Issues/linter-gap實務隱患`(無則 `lumos new issue` 建)的〈已採納〉+〈已評估駁回〉兩段。
2. **WebSearch**:對目標 stack(從 `.lumos/lint.json` 宣告的 linter 得知**已覆蓋範圍**,避免重複 linter 已抓的)搜「該 stack linter 未收錄的新 gotcha/pitfall」;濾掉已在兩段的。
3. **反證預篩**:每個新候選派**乾淨 refuter**(default-refute framing:「預設這坑假/不適用,構造反駁;必須附來源/`file:line`,光說沒問題不算」)——**駁倒即丟**。
4. **候選(非定論)**:駁不倒的,連來源 + 反證嘗試,呈**人輕量放行**。
5. **落地**:人放行 → 〈已採納〉段(附觸發條件/來源);人駁回 → 〈已評估駁回〉段(下次跳過)。節點自去重。

## §3 架構圖節點
`Issues/linter-gap實務隱患.md`(每專案一個,type issue),兩段:
- **〈已採納〉**:放行的 gotcha + 觸發條件 + 來源。可被 pitfalls 進場餵(像 refcheck manifest,同 ④)。
- **〈已評估駁回〉**:駁回的 gotcha + 反證,供 step 1 去重跳過。

## §4 誠實天花板(skill 須複述)
1. **無機械 oracle**:「舉不了反證 ≠ 真」——缺席證明謬誤 + 反證者能力上限(同 canary/`[audit:]`/refcheck 天花板:驗形式不驗真值)。
2. **人閘省不掉**:候選是非定論,最終真偽靠人對業務/技術現實判。
3. **量少邊角、別過度跑**:不是每次 code-loop 都掃;linter 已覆蓋大宗,這只補殘餘新坑。

## §5 驗收(跳 design-loop 的替代)
- **跳 design-loop 理由**:純散文 skill、無演算法/code,design-loop canary 對散文空轉(見記憶 design-loop-completeness-ceiling-shown「design-loop 對 shell/glue 散文空轉」)。
- **驗收 = dogfood 真 stack**:對一個真 stack(如本 repo python,或 KDS Android)實跑一次 skill 全流程(讀節點→WebSearch→反證預篩→候選→放行→進節點),證流程走得通、節點去重生效。dogfood 紀錄寫 Verification,plan_refs 回指本節點。

## 落地後回指
skill 落地 + dogfood → 寫 `Verification/2026-..._pitfalls網搜補漏` plan_refs 回指;本節點 TEST 更新;`pitfalls-lint-integration_計劃` 的 ③ 標 done。
