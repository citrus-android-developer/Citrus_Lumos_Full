---
type: verification
status: pass
feature: 關係層主網 M2——P0 typed-edge 反向索引(build_typed_index)+ doctor E2 內聯反查遷移共用
commit: 待填
date: 2026-07-15
valid_under:
  - "索引每次呼叫從 frontmatter 具名欄位(verified_by/plan_refs/related)現建現用——無持久化=無腐爛"
  - "只索引整值恰為一個 wikilink;block scalar 欄位排除(鐵則 2);path 式不 fallback 到 stem"
  - "同名歧義直接查 by_stem 候選數(不走 env.resolve——它靜默取第一篇)"
revalidate_when:
  - "load_vault 的 fm_targets 抽取規則或 block_keys 語意變更"
  - "M4 impact --node/cascade_surface 開始消費本索引(含 ambiguous 的 NEIGHBOR-AMBIG 浮出)"
plan_refs:
  - "[[關係層主網_實作計畫]]"
tags:
  - type/verification
  - status/pass
---
# 驗證：關係層主網 M2——typed-edge 反向索引

主網第二座（[[關係層主網_實作計畫]] M2/[P0]）。補架構圖「走圖層丟邊型」的洞（`Env.edges` 以 target 去重、不存來源欄位——r2 Codex 揭露的地基缺口）：`build_typed_index(env)` 從 frontmatter 具名欄位建正反向**帶型別**索引。

## 變更範圍（scripts/lumos）
- **`build_typed_index(env)`**（新，`TYPED_EDGE_FIELDS=(verified_by, plan_refs, related)`）：回 `{rev, fwd, ghosts, ambiguous, scalars}`。合約全釘：exact-wikilink only／scalar 進 warnings 不靜默納入／ghost 不靜默丟／同名歧義記候選清單嚴禁取首（by_stem 直查）／去重鍵 `(source, target字面, type)`／path 式 miss 即 ghost（不 fallback stem）。
- **doctor Check E2 遷移**：內聯反查改消費共用索引（只吃 resolved、過濾 verified_by/plan_refs；ghost/ambiguous 不做時序判定）。E2 既有測試全綠＝行為不變。

## 測試項目
7 合約斷言（`t_typed_index_contracts`）：反向去重、正反向對稱、ghost 標記、scalar 拒斥、同名歧義不取首（雙 Dup 實測）、**投影比較**（resolved typed edge ⊆ `Env.edges` 超集，不做集合等價）。全套 **1069 passed / 0 failed**；真圖 doctor 0 issues。

## 連動
- [[Verification/2026-07-14_relguard_E2建在被推翻決策上]] 的 `revalidate_when`「P0 若落地→E2 改用共用 index」**於本次觸發並通過**（E2 全部既有測試綠、真圖行為不變）。
- M4 將以本索引做 typed hop-1（`cascade_surface`/`impact --node`）；ambiguous 條目屆時走 NEIGHBOR-AMBIG 行浮出。

## 相關模組
- [[關係層主網_實作計畫]]（M2 ✅ → 次站 M3 cascade ledger）
- [[Systems/lumos-cli-read]]（doctor E2 消費面）
