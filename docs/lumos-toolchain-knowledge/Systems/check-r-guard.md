---
type: system
status: done
created: 2026-06-26
updated: 2026-06-26
self_audit: sonnet/2026-06-26
tags:
  - type/system
  - status/done
  - risk/守衛面
verified_by:
  - "[[Verification/2026-06-24_check-r-guard]]"
summary: |-
  FLOW:Check R(doctor+lint)解析 ★IRREVERSIBLE★ KEY 行 → 抽 (marker, clean, rollback_ref, guard_ref) 4-tuple → IRREVERSIBLE 走「_rollback_resolved OR _guard_resolved」任一合規即放行 → 兩軌皆無 → error(訊息含兩選項)
  KEY:對 ★IRREVERSIBLE★ 新增 [guard:decisions] 作為 [rollback:decisions] 的同等合規路徑——外部不可逆(信已送/下游已消費)用「執行前冪等鍵/核可閘」取代事後補償 [test:t_reversibility_guard_doctor]
  KEY:[guard:] 僅對 ★IRREVERSIBLE★ 生效;★CHECKPOINT★ 仍只判 _rollback_resolved(有 guard 靜默忽略、無 rollback 仍出軟提醒)——CHECKPOINT 行為等同現狀 [test:t_reversibility_lint]
  KEY:[guard:] 屬可逆性軸(KEY 行 regex namespace),與 lumos guard bind 的合約軸 CLI 指令(argparse namespace)正交、從不相交
  KEY:誠實天花板=證明「decisions 記錄了前置守衛」,不證明「守衛在 code 運行時生效」(code 層靠 [test:]);與 [rollback:] 上界相同
  DEP:extract_reversibility(4-tuple)｜_guard_resolved/GUARD_REF_RE/reversibility_guard_ref｜parse_decisions｜doctor Check R/lint Check R
  TEST:t_reversibility_guard_doctor｜t_reversibility_lint([guard:] 案例)｜t_marker_doc_sync([guard: 漂移守衛)
  VERIFY:[[Verification/2026-06-24_check-r-guard]]
decisions:
  - content: 採方案 B(★IRREVERSIBLE★ 加 [guard:] 指針)而非新增 ★EXTERNAL-IRREVERSIBLE★ tag 或 kind:external 子分類
    id: d1
    context: 2026-06-22 日報 gap:Check R 驗「回退有沒有寫」,但外部不可逆動作(寄信/prod 遷移已被下游消費)根本沒有逆操作,寫回退=空頭支票;需要事前預防路徑
    why_chosen: 最小語法增量、向後兼容、同架構;外部/內部邊界在標記時常難判定,新 tag 增學習負擔;{X}_REF_RE/_{X}_resolved/[{X}:decisions] 是可逆性軸既有命名範式(rollback/audit 已採用)。完整 alternatives 見設計稿方案表
    decided: 2026-06-24
    valid: true
  - content: guard 僅影響 ★IRREVERSIBLE★ 分支;CHECKPOINT 分支獨立判 _rollback_resolved(不讀 _guard_resolved)、有 guard 靜默忽略
    id: d2
    context: design-loop r1 canary 揪出 F-CHECKPOINT(minor):若共用條件對所有 marker,CHECKPOINT+guard 會誤消掉軟提醒
    why_chosen: CHECKPOINT 是「改了難救」非「不可逆」,語義上不該被事前守衛免除軟提醒;分開 IRREVERSIBLE/CHECKPOINT 兩分支讓行為精確且 CHECKPOINT 等同現狀
    decided: 2026-06-24
    valid: true
  - content: 組件 8(graph-discipline.md)+9(SKILL.md)+10(t_marker_doc_sync tuple 加 "[guard:")須同一 commit 提交
    id: d3
    context: design-loop r1 F-DRIFT(major):原宣稱「才能通過既有漂移測試」不成立——t_marker_doc_sync 迴圈原不含 [guard:,無漂移保護;不同 commit 拆開會立即紅燈
    why_chosen: 漂移守衛測試斷言 [guard: 須同時出現在模板與 skill,tuple 擴充與兩檔同步必須原子化否則測試紅燈
    decided: 2026-06-24
    valid: true
---
# check-r-guard

Check R(可逆性閘)擴展:對 `★IRREVERSIBLE★` 動作新增 `[guard:decisions]` 作為 `[rollback:decisions]` 的**同等合規並行路徑**。

源起:日報 2026-06-22 gap——Check R 驗「事後回退有沒有寫」,但外部不可逆動作(寄出的信、下游已消費的 prod 遷移)根本沒有逆操作,「把回退寫下來」≠「跑得動」;強槓桿在執行前用冪等鍵/核可閘從源頭防 commit,不在事後補償。lumos 6/14 的發票補登冪等守衛即雛形,本機制把它升格為不可逆動作的標準前置防線。

## 解決什麼
- `[rollback:decisions]` 是**事後補償**路徑(DB 遷移有 revert.sql)。
- `[guard:decisions]` 是**事前預防**路徑(冪等鍵 / 核可閘):外部已送出就收不回的動作,寫事後回退是空頭支票,改記「執行前如何避免重複/不可逆 commit」。
- Check R 兩軌任一合規即放行,兩者兼具也行。

## 關鍵機制(現況,`scripts/lumos`)
- `GUARD_REF_RE`(`scripts/lumos:1014`):`re.compile(r"\[guard:\s*([^\]]+)\]")`,平行於 `ROLLBACK_REF_RE`。
- `reversibility_guard_ref(text)`(`:1022`):抽 guard ref。
- `_guard_resolved(note, ref)`(`:1106`):`ref=="decisions"` 且 `decisions[]` 有 ≥1 條非空 `guard` 才為真。
- `extract_reversibility`(`:1082`):回傳 **4-tuple** `(marker, clean, rollback_ref, guard_ref)`,`clean` 同時 sub 掉 `[rollback:]` 與 `[guard:]`。
- **doctor Check R**(`:625`):4-tuple 解包;`if marker=="★IRREVERSIBLE★": if not (_rollback_resolved OR _guard_resolved) → rev_err`;`elif not _rollback_resolved`(CHECKPOINT,`guard_ref` 不讀)→ `rev_soft`。
- **lint Check R**(`:1230`):同邏輯單檔版。

## 分支真值表(doctor inner)
| marker | rollback resolved | guard resolved | 結果 |
|---|---|---|---|
| IRREVERSIBLE | True | any | pass |
| IRREVERSIBLE | False | True | pass |
| IRREVERSIBLE | False | False | error(訊息含 `[rollback:decisions]` 與 `[guard:decisions]` 兩選項) |
| CHECKPOINT | True | any | pass |
| CHECKPOINT | False | any | warning(軟提醒;guard 忽略) |

`extract_reversibility` 迴圈寫死兩種 regex,marker 值集合封閉(只 `★CHECKPOINT★`/`★IRREVERSIBLE★`),不存在 fall-through 到錯誤分支(跨家族複核 Finding H 經辯方反證為假陽性)。

## 兩軸正交
- **可逆性軸**:`[guard:]` 是 KEY 行 regex namespace 的 pointer,標「事前守衛機制有沒有記在 decisions」。
- **合約軸**:`lumos guard bind/scaffold/audit` 是 argparse CLI 指令,綁 `[test:]` 守衛測試。
- 兩層從不相交;先例:`[audit:]` pointer 與 `lumos guard audit` 指令已在同 codebase 共存。

## 已知限制 / 非目標
- 誠實天花板:`[guard:decisions]` 證明「decisions 記了前置守衛」,**不證明守衛在 code 運行時生效**(那靠 `[test:]` + CI)。語義上守衛 > 回退(預防 > 補償),但文件層聲明等級相同。
- v1 只支援 `[guard:decisions]` 字面;其他 ref → error(留 v2,目前為 deferred/backlog,無主動追蹤計畫)。
- 不廢棄 `[rollback:]`(DB 補償交易場景仍多);不新增 external tag;不驗 guard 已在 code 實作。

## 知識同步(與本機制同 commit)
`scripts/templates/graph-discipline.md`、`skills/lumos-project-notes/SKILL.md`、`docs/methodology/架構圖即合約.md` 已補 `[guard:decisions]` 說明;`t_marker_doc_sync` tuple 含 `"[guard:"` 作漂移守衛(`scripts/test_lumos.py:1204`)。

## 相關
- 設計稿:`docs/design/2026-06-24-check-r-pre-execution-guard.md`(design-loop 收斂 3 輪,canary 3/3 全中,跨家族複核 2 輪 endorsed)。
- 實作計畫:`docs/superpowers/plans/2026-06-24-check-r-guard.md`(2 任務 TDD)。
- 實作落點:`scripts/lumos` `GUARD_REF_RE`/`reversibility_guard_ref`/`_guard_resolved` + `extract_reversibility` 4-tuple + doctor/lint Check R inner 分支。
- 特性 commit:`eb73b22`(feat)、`047b1ee`/`3e73fe7`/`7cd68ee`/`7f66f44`(同步)。
