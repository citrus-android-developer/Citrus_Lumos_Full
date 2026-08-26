# design-loop 辯方 refute 階段 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** design-loop 兩個落點(手動 SKILL.md + 自動 orchestrator-prompt)各加「步驟 4.5 辯方 refute」——對每條 major+ finding 派獨立辯方試圖反駁(要 file:line 證據)、殺 code 層假陽性,severity 取存活 findings max。

**Architecture:** 純 prompt 紀律改,無代碼、無單元測試。辯方插在「judge/判讀評 severity 後、record 前」;被駁倒的 finding 降級不折;該輪 severity 由編排者機械取存活最高。兩落點 step 號各異(SKILL step5=record/step7=折;orch step5=讀/決定、step6=record、step7=折),但動作對稱。

**Tech Stack:** Markdown prompt 檔(`skills/lumos-design-loop/SKILL.md`、`governance/autonomous_loop/orchestrator-prompt.md`)+ 方法論文件。

## Global Constraints

- **純 prompt 紀律改**:無代碼、無單元測試;驗證靠 grep 確認插入 + design-loop 實戰觀察。
- **辯方共用 framing**(兩落點一致):獨立 opus、乾淨脈絡、不傳 auditor/judge 結論、「預設這條 finding 假/高估,構造反駁、**必須附 file:line**(grep/Read 實際代碼),光說『沒問題』不算;**若 finding 真的無任何查證行(judge 因此鎖 major),辯方也得拿反證 file:line 才能降,拿不出則維持**」。回「真(維持)/假(降到 minor|clean)+file:line」。
- **只對 severity≥major 派辯方**(minor/clean 不影響收斂、不派)。
- **1 個辯方 + 強制證據**(不 N 個多數決、不重派 judge)。
- **severity = 存活 findings 機械取 max**(編排者不評判、同 judge-severity-gate)。
- **不碰** canary 流程、judge、cross-family(§2.5)、lumos 原語、loop status。
- **兩落點 step 號各異**:SKILL step5=記錄、step7=折;orchestrator step5=讀/決定、step6=record、step7=折。勿照「對稱」字面套錯 step 號。

---

### Task 1: SKILL.md 手動版加辯方階段

**Files:**
- Modify: `skills/lumos-design-loop/SKILL.md`(步驟 4② 後插步驟 4.5;步驟 7 改;步驟 5 record 用重算 severity)

- [ ] **Step 1: 在步驟 4② 後插入步驟 4.5「辯方 refute」**

找到步驟 4「判讀」的 ②(「剝『審計員誤判』要克制…剝除理由記進 note。」)結尾,在其後、步驟 5「記錄」之前插入:

```markdown
   - ③ **辯方 refute(對 ②標為 ≥major 的每條 finding)**:用 Agent tool 派 1 個獨立 opus 辯方(乾淨脈絡、**不傳 auditor 報告結論**),framing=「預設這條 finding 假/嚴重度高估,構造反駁證據。必須附 file:line(grep/Read 實際代碼),光說『沒問題』不算;若該 finding 真無任何查證行(因此鎖 major),你也得拿反證 file:line 才能降,拿不出則維持」。辯方回「真(維持原 severity)」或「假(降到 minor/clean)+file:line」。被駁倒(假)→ 該 finding 降級、**不折**、在審計紀錄標「辯方反證:<file:line>」。
   - ④ **該輪 severity = 辯方裁決後存活 findings 的最高**(編排者機械取 max,取代「②編排者自剝」;辯方帶證據裁、同 judge-severity-gate 精神)。
```

- [ ] **Step 2: 改步驟 7「折真 findings」為只折存活**

步驟 7「抓到 → 折真 findings 進 `docs/design/<id>.md`」改為:「抓到 → **只折辯方存活的真 finding** 進 `docs/design/<id>.md`(被辯方駁倒的不折、已在審計紀錄標『辯方反證:<file:line>』)」。

- [ ] **Step 3: 確認步驟 5 record severity 用重算後值**

步驟 5「記錄:`lumos canary record … --severity <worst>`」的 `<worst>` 改註明:「= ④ 辯方重算後的存活 max,非 ② 原評」。

- [ ] **Step 4: 驗證插入 + 其餘步驟未動**

Run: `grep -nE "辯方 refute|辯方反證|存活 findings" skills/lumos-design-loop/SKILL.md`
Expected: 步驟 4③/4④/7 三處命中。
Run: `grep -cE "^1\. \*\*複製|^2\. \*\*植|^3\. \*\*派乾淨|loop status" skills/lumos-design-loop/SKILL.md`
Expected: 既有步驟 1/2/3/8 文字未被動到(回歸)。

- [ ] **Step 5: Commit**

```bash
git add skills/lumos-design-loop/SKILL.md
git commit -m "feat(design-loop): SKILL.md 手動版加步驟 4.5 辯方 refute(防假陽性)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: orchestrator-prompt §2 自動版加辯方階段

**Files:**
- Modify: `governance/autonomous_loop/orchestrator-prompt.md`(§2 步驟 4 後插步驟 4.5;步驟 6 record 用重算;步驟 7 折只存活)

**Interfaces:**
- Consumes: §2 步驟 4(judge 回 caught + severity)的輸出

- [ ] **Step 1: 步驟 4(judge)後插入步驟 4.5「辯方 refute」**

找到 §2 步驟 4(judge…severity)結尾,在其後、步驟 5(讀 judge severity + 決定折哪些)之前插入:

```markdown
4.5. **辯方 refute(對 judge 評為 severity≥major 的每條 finding)**:用 Agent 工具派 1 個獨立 opus 辯方(乾淨脈絡、**不傳 auditor/judge 結論**),framing=「預設這條 finding 假/嚴重度高估,構造反駁證據。必須附 file:line(grep/Read 實際代碼),光說『沒問題』不算;若該 finding 真無任何查證行(judge 因此鎖 major),你也得拿反證 file:line 才能降,拿不出則維持」。辯方回「真(維持)」或「假(降到 minor/clean)+file:line」。被駁倒→ 該 finding 降級、不折、審計紀錄標「辯方反證:<file:line>」。**該輪 severity = 辯方裁決後存活 findings 的最高**(你機械取 max,非自評——同 judge-severity-gate)。
```

- [ ] **Step 2: 步驟 5/6/7 對齊重算 severity + 只折存活**

- 步驟 5(讀 judge severity)註明:嚴重度以「步驟 4.5 辯方重算後」為準。
- 步驟 6 record 的 `--severity` 用重算後值(原本就取自步驟 4/4.5)。
- 步驟 7「caught → 折真 findings」改:「caught → **只折辯方存活的真 finding**(被駁倒的不折、已標反證)」。

- [ ] **Step 3: 驗證插入 + §2.5 cross-family / 其餘未動**

Run: `grep -nE "4\.5|辯方 refute|辯方反證" governance/autonomous_loop/orchestrator-prompt.md`
Expected: 步驟 4.5 + 步驟 7 命中。
Run: `grep -cE "§2\.5 跨家族複核|步驟 8|cross_audit" governance/autonomous_loop/orchestrator-prompt.md`
Expected: §2.5 / 步驟 8 / cross_audit 文字未動(回歸)。

- [ ] **Step 4: Commit**

```bash
git add governance/autonomous_loop/orchestrator-prompt.md
git commit -m "feat(design-loop): orchestrator-prompt §2 步驟 4.5 辯方 refute(自動版)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: 知識同步(方法論 + 對外論述 + memory)

**Files:**
- Modify: `docs/methodology/架構圖即合約.md`(設計前審計 loop 段補辯方=canary 對稱)
- Modify: `docs/methodology/架構圖即合約-對外論述.md`(白話檢察官/辯護律師)
- Modify: memory `canary-loop-reliability-varies-by-spec`(補辯方防假陽性)

- [ ] **Step 1: 方法論(技術)補辯方**

`docs/methodology/架構圖即合約.md` 設計前審計 loop 段補:辯方階段(對每條 major+ finding 派獨立辯方、要 file:line 證據、防假陽性)= canary(防假陰性、漏抓)的**對稱補位**;檢察官(對設計 refute→findings)/辯方(對 finding refute→殺假陽性)雙向對抗。天花板:只買 code 層、業務層留人。

- [ ] **Step 2: 對外論述補白話**

`docs/methodology/架構圖即合約-對外論述.md` 補白話:審查除了「檢察官挑毛病」,還配「辯護律師」——每條重罪指控派一個律師專門反駁、且逼他拿代碼證據(指出第幾行),冤枉的當庭推翻。金絲雀防檢察官偷懶漏放,辯護律師防檢察官認真但冤枉人。

- [ ] **Step 3: 更新 memory**

更新 `~/.claude/projects/-Users-enzo-harness-lumos-toolchain/memory/canary-loop-reliability-varies-by-spec.md`:補「canary 只防假陰性(放水/漏抓),辯方階段(2026-06-24 finding-refute)防假陽性(認真但判錯);要 file:line 證據;6/23 qwen 誤判 nested-agent 是觸發案例」。MEMORY.md 索引 hook 同步。

- [ ] **Step 4: Commit**

```bash
git add docs/methodology/
git commit -m "docs(finding-refute): 知識同步——辯方階段(防假陽性)= canary(防假陰性)對稱

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## 驗證(無單元測,prompt 紀律)

- **grep 確認**:兩落點各有步驟 4.5 辯方 + 步驟 7 只折存活(Task 1/2 Step 4/3)。
- **回歸**:canary/judge/§2.5/loop status 文字未被動到。
- **實戰**:下一個 design-loop(手動或自動)觀察——若 auditor 出假 major,辯方有沒有當輪帶證據駁倒、severity 降。(本 spec 自己 design-loop 時全程無假陽性、未驗到此路徑。)
