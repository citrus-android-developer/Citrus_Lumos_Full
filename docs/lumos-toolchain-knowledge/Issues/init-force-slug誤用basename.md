---
type: issue
status: done
created: 2026-07-06
updated: 2026-07-06
related:
  - "[[lumos-cli-lifecycle]]"
pitfall_when:
  - "content:_slugify_vault"
  - "content:def cmd_init"
tags:
  - type/issue
  - status/done
summary: |-
  FLAG:ORIGIN
  KEY:現場事故——`lumos init --force` 在既有 vault 上,slug 誤用 repo basename 而非既有 vault 的 slug。repo basename=landmarkmember、實際 vault=landmark-knowledge → --force 建了空的 docs/landmarkmember-knowledge/ scaffold + 把 CLAUDE.md {{KG}} 架構圖路徑寫錯成 landmarkmember-knowledge(drift)
  KEY:root cause=cmd_init slug 行 `slug = _slugify_vault(name) if name else _slugify_vault(root.name)` 從不看已算出的 existing vault;--force 走完整 vendor+scaffold,用錯 slug 波及 reinject 路徑寫入 + scaffold 建錯 vault
  KEY:觸發脈絡=doctor 建議「用 lumos init --force 刷新 CLAUDE.md」,使用者照做卻踩到 slug bug(修 A 引出 B)
  DECISION:修=slug 決定順序改 ①--name ②既有 vault 資料夾名 ③repo basename(②先於③);綁 [test:t_init_force_uses_existing_vault_slug];見 [[lumos-cli-lifecycle]] KEY
  KEY:使用者現場已手動解:刪空 scaffold + CLAUDE.md 路徑改回 landmark-knowledge、drift 解除 doctor 0;本次修的是 root cause
---
# init --force slug 誤用 repo basename(現場事故)

## 現象
`lumos init --force`(doctor 建議用它刷新 CLAUDE.md 紀律區塊)在既有 vault 專案上:
- repo 資料夾 basename = `landmarkmember`,實際 vault = docs/landmark-knowledge/(它站專案,非本 repo;slug `landmark`)。
- `--force` 用 basename 當 slug → **建了一個空的 docs/landmarkmember-knowledge/ scaffold**,且 **把 CLAUDE.md 的 `{{KG}}` 架構圖路徑寫錯成 docs/landmarkmember-knowledge/**(內容 drift)。

## Root cause
`cmd_init` 的 slug 行 `slug = _slugify_vault(name) if name else _slugify_vault(root.name)` **從不參考已算出的 `existing = _vault_in(root)`**。`--force` 走完整 `_vendor_toolchain`(reinject 用該 slug 寫 CLAUDE.md 路徑)+ `_scaffold_project`(用該 slug 建 vault,錯 slug → 建錯的空 vault)。

## 修法
slug 決定順序改為 ①`--name` 顯式 ②既有 vault 資料夾名去 `-knowledge`(權威 slug,不重新 slugify)③repo basename;**②必須先於③**。綁回歸測試 `t_init_force_uses_existing_vault_slug`(repro:basename≠vault slug → --force 不建錯 vault、slug 取既有)。落點 `scripts/lumos` `cmd_init`;合約見 [[lumos-cli-lifecycle]] 的 slug 順序 KEY。

## 現場處置(使用者已做)
刪空 scaffold + CLAUDE.md 路徑改回 `landmark-knowledge` → drift 解除、doctor 0 issues。本次 lumos-toolchain 修的是 root cause,防復發。

## 教訓
- **修 A 引出 B**:doctor 建議的補救指令(init --force)本身有 slug bug——工具建議的動作也要對。
- **既有 vault 的資料夾名 = 權威 slug**,任何路徑不該用 repo basename 覆蓋它(basename 與 slug 常不同)。
