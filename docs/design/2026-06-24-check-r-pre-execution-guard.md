# 設計:Check R 擴展 [guard:decisions] 前置防護路徑

- 日期:2026-06-24
- 狀態:CONVERGED(2026-06-24 design-loop 3 輪、canary 3/3 全中、r2+r3 連 2 good 自動收斂;跨家族複核 2 輪 endorsed)
- 動機來源:2026-06-22 AI 治理日報 gap:Check R 驗「回退有沒有寫」,但外部不可逆動作(寄信/prod 遷移已被下游消費)根本沒有逆操作,寫回退=空頭支票。
- loop_id:check-r-pre-execution-guard

## 目標(一句話)

對 `★IRREVERSIBLE★` 動作新增 `[guard:decisions]` 作為 `[rollback:decisions]` 的同等合規路徑——外部不可逆類動作改用「執行前冪等鍵/核可閘」取代事後補償,Check R 兩軌皆放行。

## 前提與既驗事實

- **`IRREVERSIBLE_RE`**(`scripts/lumos:993`):解析 `★IRREVERSIBLE★` KEY 行。
- **`ROLLBACK_REF_RE`**(`scripts/lumos:994`):正則 `\[rollback:\s*([^\]]+)\]`。
- **`reversibility_rollback_ref(text)`**(`scripts/lumos:997`):從行文字抽 rollback ref。
- **`extract_reversibility(note)`**(`scripts/lumos:1002`):回傳 `(marker, clean, rollback_ref)` 三元組列表;`clean` 已 sub 掉 `[rollback:]`。全 repo 呼叫點僅 2 處:`scripts/lumos:622`(doctor)與 `scripts/lumos:1142`(lint)——已 grep 確認,改 4-tuple 需同步更新這兩處解包(無第三方斷裂風險)。
- **`_rollback_resolved(note, ref)`**(`scripts/lumos:1018`):驗 `ref=="decisions"` 且 `decisions[].rollback` 有 ≥1 非空條目。
- **Check R(doctor)**(`scripts/lumos:619-642`):外層 `if t_ != "system":` 型別守衛(`scripts/lumos:624`)先驗型別。之後 `elif not _rollback_resolved(nnote, ref): if marker==IRREVERSIBLE / else CHECKPOINT`。型別守衛**保持不動**;本 spec 僅改 inner `elif not _rollback_resolved` 分支結構。
- **Check R(lint)**(`scripts/lumos:1141-1149`):同邏輯,單檔版。
- **`parse_decisions`**(`scripts/lumos:1740`):以 `m_kv`(`[\w-]+` 正則)通用解析任何 decisions sub-key;`guard` 符合 `[\w-]+`,block scalar(`guard: |`) 也被正確解析。
- **既有 NEW_HINT["system"]**(`scripts/lumos:2697`):只提 `[rollback:decisions]`,未提 `[guard:]`。
- **`t_marker_doc_sync`**(`scripts/test_lumos.py:1073`):迴圈 `for m in ("★CHECKPOINT★", "★IRREVERSIBLE★", "[rollback:")` — **不含 `[guard:`**。需新增 `"[guard:"` 到 tuple 才能有漂移保護。
- **`[guard:]` 命名無衝突**(辯方反證 `scripts/lumos:865`:`AUDIT_REF_RE` 已是 `[audit:]` pointer 與 `lumos guard audit` CLI 指令在同 codebase 共存的先例):CLI 指令在 argparse namespace、pointer 在 KEY 行 regex namespace,兩層從不相交。`{X}_REF_RE` / `_{X}_resolved` / `[{X}:decisions]` 是可逆性軸既有命名範式(`rollback`/`audit` 已採用)。

## 邊界 / 非目標(YAGNI)

- ❌ **不新增 `★EXTERNAL-IRREVERSIBLE★` tag**:外部/內部邊界在標記時常難判定,新 tag 增學習負擔——否決。
- ❌ **不驗 guard 已在 code 中實作**:code 層靠 `[test:]` + CI;本機制驗「decisions 有沒有記錄守衛機制」,同 `[rollback:]` 誠實上界。
- ❌ **`[guard:]` 不影響 `★CHECKPOINT★` 行為**:guard 僅對 `★IRREVERSIBLE★` 生效;CHECKPOINT 分支獨立判讀 `_rollback_resolved`(不讀 `_guard_resolved`)。CHECKPOINT 有 `[guard:]` → 靜默忽略,**CHECKPOINT 軟提醒行為等同現狀**(無 rollback 仍出 warning)。
- ❌ **不廢棄 `[rollback:]`**:DB 遷移有補償交易場景仍多;兩軌並存。
- ❌ **v1 不支援 `[guard:non-decisions-ref]`**:只支援 `decisions` 字面,其他→error;留 v2。

## 架構:新增 `[guard:decisions]` 並行合規路徑

**方案選擇**:

| 方案 | 描述 | 結論 |
|---|---|---|
| A) 新 Tag `★EXTERNAL-IRREVERSIBLE★` | 需遷移、增學習負擔 | **否決** |
| **B) `★IRREVERSIBLE★` 加 `[guard:]` 指針** | 最小語法增量、向後兼容、同架構 | **採用** |
| C) `kind:external` 子分類 | 解析複雜 | **否決** |

```
Check R 擴展後:
  ★IRREVERSIBLE★ → [rollback:decisions] + 非空 rollback  ← 補償路徑(事後)
                 OR [guard:decisions]   + 非空 guard      ← 預防路徑(事前)
                 (任一合規即放行;兩者兼具也行)
                 兩者皆無 → error(提示兩個選項)

  ★CHECKPOINT★ → 行為不變:有 rollback → 不提醒;無 rollback → 軟提醒
                (guard 對 CHECKPOINT 靜默忽略)
```

**分支真值表(doctor inner 區塊)**:

| marker | rollback resolved | guard resolved | 結果 |
|---|---|---|---|
| IRREVERSIBLE | True | any | 無誤 → pass |
| IRREVERSIBLE | False | True | 無誤 → pass |
| IRREVERSIBLE | False | False | rev_err → error |
| CHECKPOINT | True | any | 無誤 → pass |
| CHECKPOINT | False | any | rev_soft → warning(guard 忽略) |

**`decisions[].guard` 語義範例**:
```yaml
decisions:
  - content: 補登 API 呼叫
    decided: 2026-06-22
    guard: |
      冪等鍵:X-Idempotency-Key = sha256(invoice_id+retry_seq);
      後端 Redis 60s 去重視窗;重試相同鍵 → 204 Not Modified,不重送。
```

## 組件(改動)

### 改:`scripts/lumos`

1. **`GUARD_REF_RE`**(新,接在 `ROLLBACK_REF_RE:994` 之後;屬**可逆性軸**,與合約軸 guard 指令正交):
   ```python
   GUARD_REF_RE = re.compile(r"\[guard:\s*([^\]]+)\]")  # 可逆性軸,平行於 ROLLBACK_REF_RE
   ```

2. **`reversibility_guard_ref(text) → str|None`**(新,接在 `reversibility_rollback_ref:997` 之後):
   ```python
   def reversibility_guard_ref(text):
       m = GUARD_REF_RE.search(text)
       return m.group(1).strip() if m else None
   ```

3. **`_guard_resolved(note, ref) → bool`**(新,接在 `_rollback_resolved:1018` 之後):
   ```python
   def _guard_resolved(note, ref):
       """[guard:decisions] 視為已解析 ⟺ 本節點 decisions[] 有 ≥1 條非空 guard。"""
       if not ref or ref.strip().lower() != "decisions":
           return False
       return any(str(d.get("guard", "")).strip() for d in parse_decisions(note.fm_lines))
   ```

4. **`extract_reversibility`**(改,`scripts/lumos:1002`):
   - 回傳改為 **4-tuple** `(marker, clean, rollback_ref, guard_ref)`;`clean` 同時 sub 掉 `[rollback:]` 和 `[guard:]`。
   - **同步更新解包點**:`scripts/lumos:622`(doctor)與 `scripts/lumos:1142`(lint)須改為 4-元素解包。
   ```python
   clean_body = ROLLBACK_REF_RE.sub("", GUARD_REF_RE.sub("", body)).strip()
   out.append((marker, clean_body, reversibility_rollback_ref(body), reversibility_guard_ref(body)))
   ```

5. **Check R(doctor)** inner 分支重構(`scripts/lumos:627-632`;外層 `if t_ != "system":` 守衛在 `lumos:624`,**保持不動**):
   - 解包改為 4-tuple
   - 按分支真值表,改 inner `elif not _rollback_resolved` 區塊為:
   ```python
   # 以下替換 lumos:627-632;外層 if t_ != "system": 不動
   elif marker == "★IRREVERSIBLE★":
       if not (_rollback_resolved(nnote, rollback_ref) or _guard_resolved(nnote, guard_ref)):
           rev_err.append(f"... 加 [rollback:decisions] 或 [guard:decisions] ...")
   elif not _rollback_resolved(nnote, rollback_ref):  # ★CHECKPOINT★;guard_ref 不讀
       rev_soft.append(...)
   # IRREVERSIBLE 已 resolved 或 CHECKPOINT 已有 rollback → fall-through,無誤
   ```

6. **Check R(lint)**(`scripts/lumos:1142-1149`):同 doctor,分開 IRREVERSIBLE/CHECKPOINT 分支;解包加 `guard_ref`。

7. **`NEW_HINT["system"]`**(`scripts/lumos:2697`):加 `;外部不可逆(信已送/下游已消費)改用 [guard:decisions] 記冪等鍵/核可閘([guard:] 僅對 ★IRREVERSIBLE★ 生效;屬可逆性軸,與 lumos guard bind 的合約軸正交)`

8. **`scripts/templates/graph-discipline.md`**:可逆性那行加 `[guard:decisions]` 說明(外部不可逆用;僅 ★IRREVERSIBLE★)。

9. **`skills/lumos-project-notes/SKILL.md`**:若有 `[rollback:]` 寫入規則段落,同步加 `[guard:decisions]` 路徑說明。

10. **`scripts/test_lumos.py` 的 `t_marker_doc_sync`**(`scripts/test_lumos.py:1073`):tuple 加 `"[guard:"`:
    ```python
    for m in ("★CHECKPOINT★", "★IRREVERSIBLE★", "[rollback:", "[guard:"):
    ```
    **⚠ 組件 8、9、10 須同一 commit 提交**——否則 t_marker_doc_sync 立即紅燈。

### 不改

`parse_decisions`、`IRREVERSIBLE_RE`、`CHECKPOINT_RE`、`ROLLBACK_REF_RE`、`extract_contracts`/invariant 家族、`_rollback_resolved`、型別守衛(`scripts/lumos:624`)、既有測試邏輯(除 `t_marker_doc_sync` tuple 擴充)。

## 誠實天花板

`[guard:decisions]` 證明「你在 decisions 記錄了前置守衛機制」,**不證明「守衛已在 code 裡實作且在運行時生效」**——code 層靠 `[test:]` 綁定;和 `[rollback:decisions]` 誠實上界相同。

語義層面守衛 > 回退(預防 > 補償),但文件層聲明等級相同。

## 測試策略

對齊 `scripts/test_lumos.py` 既有風格(subprocess)：

1. `★IRREVERSIBLE★` + `[guard:decisions]` + 非空 `guard` 條目 → `doctor --ci` rc0
2. `★IRREVERSIBLE★` + `[guard:decisions]` + 空 `guard` → error(懸空)
3. `★IRREVERSIBLE★` 既無 `[rollback:]` 也無 `[guard:]` → error(訊息含兩選項)
4. `★IRREVERSIBLE★` + 有效 `[rollback:decisions]`(現有) → rc0(回歸)
5. `★IRREVERSIBLE★` + 兩者皆有 → rc0
6. `★CHECKPOINT★` + `[guard:decisions]` + 非空 `guard` → **guard 靜默忽略**;無 rollback 時仍出 `rev_soft` warning(測試須斷言 warning 訊息存在)
7. lint 單檔版同 1-3
8. 既有 `_rollback_resolved` 測試全綠(回歸)
9. **漂移測試回歸**:`t_marker_doc_sync` tuple 擴充後,`[guard:` 必須同時出現在 `scripts/templates/graph-discipline.md` 及 `skills/lumos-project-notes/SKILL.md`(組件 8+9+10 同 commit)

## 知識同步影響

| 文件 | 影響 | 同步方式 | 是否 PR 必改 |
|---|---|---|---|
| `scripts/templates/graph-discipline.md` | 速查表只提 `[rollback:]` | 加 `[guard:decisions]` 說明 | **必改(組件 8,同 commit)** |
| `skills/lumos-project-notes/SKILL.md` | 若有 `[rollback:]` 寫入規則 | 加 `[guard:decisions]` 路徑說明 | **必改(組件 9,同 commit)** |
| `docs/methodology/架構圖即合約.md` | 若有 Check R 提及 | 補 guard path 說明 | 視段落決定 |
| `docs/methodology/架構圖即合約-對外論述.md` | 若提到 rollback 必填 | 補 guard 替代路徑 | 視段落決定 |

## 審計修正紀錄

### r1(2026-06-24,opus auditor + judge + 辯方 refute)
**F-DRIFT(major → 折)**:元件 8 原宣稱「才能通過既有漂移測試」——不成立。`t_marker_doc_sync` 迴圈不含 `[guard:`。修正:新增元件 10 擴充 tuple;知識同步兩檔改為 PR 必改。
**F-CHECKPOINT(minor → 折)**:元件 5 若共用條件對所有 marker,CHECKPOINT+guard 會消掉軟提醒。修正:分開 IRREVERSIBLE/CHECKPOINT 分支;邊界明文「guard 不影響 CHECKPOINT」。

### r2(2026-06-24,opus auditor + judge + 辯方 refute)
**D2(minor,辯方反證 `scripts/lumos:624` → 降 minor → 折)**:spec 組件 5 片段是 inner-delta;外層型別守衛 lumos:624 保持不動。修正:前提節明示「型別守衛不動,僅改 inner elif 結構」;組件 5 加 fall-through 分支真值表。
**D6(minor → 折)**:組件 8+9+10 須同 commit。修正:加 ⚠ 警語。
**D1(minor → 折)**:路徑補 `scripts/test_lumos.py`。

### r3(2026-06-24,opus auditor + judge + 辯方 refute)
**F1(minor,辯方反證 `scripts/lumos:865` AUDIT_REF_RE 先例 → 降 minor → 折)**:`[guard:]` vs `lumos guard` CLI 指令命名無衝突——`[audit:]` pointer 與 `lumos guard audit` 指令同 codebase 共存即先例(CLI argv namespace vs KEY 行 regex namespace,從不相交)。修正:在 `GUARD_REF_RE` 注釋標明「可逆性軸,與合約軸 guard 指令正交」;前提節補充辯方反證說明;NEW_HINT 加「屬可逆性軸,與 lumos guard bind 正交」。
**F5(minor → 折)**:SKILL.md 提升為正式組件 9(原 9→10);補同 commit 要求。
**F3(minor → 折)**:測試案例 6 補「須斷言 rev_soft warning 仍存在」。
**F2(minor → 折)**:組件 5 加完整分支真值表說明 fall-through 情境。

### §2.5 跨家族複核 round 1(cross_reject_count=1)

**cross_audit 回傳 status=ok, worst_severity=major**:

**Finding H(major → 辯方反證 → 假陽性)**:qwen 宣稱「組件 5 未防禦非 IRREVERSIBLE/CHECKPOINT marker,可能 fall into CHECKPOINT 分支誤判」。辯方反證:`scripts/lumos:1002-1016` `extract_reversibility` 迴圈寫死 `("★CHECKPOINT★", CHECKPOINT_RE), ("★IRREVERSIBLE★", IRREVERSIBLE_RE)` 兩種 regex,函式只能產出這兩個 marker 值,集合完全封閉。「未來新增 marker」是架構層改動、v1 範圍外——在當前 spec 邊界內 H 不成立。**不折、審計紀錄標反證**。

**Finding A(minor → 接受)**:前提節混用 present/future(「改 4-tuple 需同步更新」混入既驗事實段落)。此為措辭提醒,設計意圖不影響正確性,接受並留記錄。
