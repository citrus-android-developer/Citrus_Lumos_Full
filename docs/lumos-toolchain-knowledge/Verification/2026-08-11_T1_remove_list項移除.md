---
type: verification
status: pass
date: 2026-08-11
valid_under:
  - "LIST_KEYS 白名單制不變(remove 與 append 共用同一白名單與 link_target 比對語意)"
  - "frontmatter 為 2-space 縮排的標準 YAML list(同 T1 既有假設)"
  - "巢狀 dict 型 list(如 core-knowledge facet 的 implements)不在支援範圍"
revalidate_when:
  - "LIST_KEYS 增減成員"
  - "link_target() 比對語意變更(例:改回 basename-only 或加入模糊匹配)"
  - "有人要求 remove 支援巢狀 dict 型 list 項(需 T3 手術層,非本次範圍)"
tags:
  - type/verification
  - status/pass
  - scope/cli-write
summary: |-
  TEST:7 條牙齒測試全綠;全套 2543 passed / 0 failed
  VERIFY:實戰驗收——LandmarkMember 清掉 14 條死背書(doctor E1 14→0)+ 拆 core_refs 指針(doctor C 轉「無指針」),兩者皆為本命令上線前無路可走的操作
  KEY:★不命中一律 rc=2★是本命令最重要的設計——靜默 no-op 回成功會讓呼叫端以為清乾淨了,比報錯危險得多
---

# 驗證：T1 新增 `remove`（list 項移除）

## 缺口從哪來（實戰觸發，非憑空設計）

2026-08-11 在 LandmarkMember 跑五大節點交叉審計時，撞到兩件都做不了的事：

1. **死背書**：14 條 `verified_by` 指向已 `superseded`/`stale` 的 Verification（`doctor [E1]` 報「死背書給假安心感，是關係層頭號腐爛之一」），要清就得移除 list 項
2. **降格拆指針**：`custtransfer-semantics` 自核心架構圖降格回專案層後，專案節點的 `core_refs:` 指針該拆

而當時 T1 寫入層：`set` 只收 `SCALAR_KEYS`、`append` 只能加。唯一合法退路是 obsidian CLI 的 `processFrontMatter`，但那要 Obsidian 執行中——**實務上等於無路可走**。

## 實作要點

| 決策 | 理由 |
|---|---|
| 比對沿用 `link_target()` | 與 `append` 的 dedup 同語意：精確 target、保留路徑，不做前綴或 basename-only 匹配 → `[[A]]` 不會誤刪 `[[Projects/A_v2]]`（鏡像 append 的 BUG-1） |
| **不命中一律 rc=2** | ★最重要★。打錯字卻回成功＝呼叫端以為清乾淨了（死背書照舊掛著），比報錯危險得多。錯誤訊息附現有項清單供對照 |
| 命中多筆一次清乾淨 | dedup 理論上不該有重複，但若歷史遺留有重複項，清乾淨才是對的 |
| 清空後連 key 行一併移除 | 留 `verified_by:` 裸鍵會被 YAML 解成 null，對 doctor/lint 的判讀比「沒有這個鍵」更糟 |
| `core_refs` 納入 `LIST_KEYS` | 升格加指針／降格拆指針兩向都該走 T1；值是純路徑非 wikilink（core-knowledge skill 明令禁跨 vault wikilink），`link_target()` 對純路徑同樣適用 |

## 測試（7 條，全綠）

| 測試 | 守什麼 |
|---|---|
| `t_remove_basic` | 移除命中項、保留其他項 |
| `t_remove_not_found_rc2_file_untouched` | ★牙齒★ 不命中 rc=2 **且原檔零改動**（嚴禁靜默 no-op 回成功） |
| `t_remove_last_item_drops_key` | 清空最後一項連 key 行移除，其他欄位不受損 |
| `t_remove_exact_target_not_prefix` | `[[A]]` 不誤刪 `[[Projects/A_v2]]` |
| `t_remove_alias_and_path_forms_match` | `[[Folder/X\|別名]]` 被 `[[Folder/X]]` 命中 |
| `t_remove_rejects_non_whitelist_key` | 純量 key（`status`）被拒 rc=2，原檔不動 |
| `t_remove_core_refs_roundtrip` | `core_refs` append→remove 往返（降格拆指針的實戰路徑） |

`python3 scripts/test_lumos.py` → **2543 passed / 0 failed**。

> 過程中「文件命令數 vs argparse」守衛翻紅 5 條（文件寫 58、實際 59），改完 4 份 README/AGENTS/ARCHITECTURE + skill reference 才綠——**守衛正確地擋下了「加了指令沒更新文件」**。

## 實戰驗收（在 LandmarkMember）

| 操作 | 結果 |
|---|---|
| 清 14 條死背書 | `doctor [E1]` **14 → 0**，且未製造任何 Verification orphan |
| 拆 `core_refs` 指針 | `doctor [C]` 轉為「無 core_refs 指針」，降格收尾完成 |

其中一條（`2026-05-29_即時降等治本_會期窗換禮`）移除後會變孤兒——先在來源 Issue 內文建「沿革索引」段保留追溯路徑再移除，示範了**「移除死背書」不等於「刪掉歷史」**。

## 已知限制（誠實記錄）

**不支援巢狀 dict 型 list 項。** core-knowledge facet 的 `implements`（`- rule: ... / params: ... / references: [...]`）需要 `decision-supersede` 那種 T3 手術層級：不是刪一行，是刪一整個帶子欄位的項目。
LandmarkMember 降格後，核心 repo facet 的那條 `implements` 因此**清不掉**，只能先在 facet 內文標明失效。若要補，是獨立的一項工作。

## 相關

- [[Systems/lumos-cli-write]]
