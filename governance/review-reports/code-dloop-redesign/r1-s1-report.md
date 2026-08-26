# Code Review — design-loop 重設計 T1-T7（r1-s1）

審查對象：`code-dloop-redesign-r1-s1.patch`（AGENTS.md/README* 計數同步、`docs/lumos-toolchain-knowledge/*` 架構圖節點、`governance/eval/canary_calibration.py`〔新檔〕、`scripts/lumos`、`scripts/test_lumos.py`、`skills/lumos-{code,design}-loop/*`）。逐 hunk 讀完，聚焦新邏輯（T1 record 六選配欄、T2 quote-check、T3 反循環快照、T4 `--disposal` 四合取、T6 留痕強制、T7 離線校準）。

---

## Finding 1 — `_loop_status_disposal` 用「先出現的 round-id」分組，round-id 非連續重現時會判到錯輪（已用真 CLI 重現）

- **severity: major**
- **file:line**: `scripts/lumos:8106`（`groups.setdefault(...)`）、`scripts/lumos:8110`（`rid, latest = next(reversed(groups.items()))`）；函式 `_loop_status_disposal` 起於 `scripts/lumos:8097`
- **引句**：「`groups.setdefault(r.get("round") or f"__seq{len(groups)}", []).append(r)`」
- **引句**：「`rid, latest = next(reversed(groups.items()))`」

**失敗場景（已用 `python3 scripts/lumos` 實跑重現，非臆測）**：

`OrderedDict` 的 key 順序是「該 key 第一次出現」的順序，不是「最後一次被寫入」的順序。若同一 loop 的 `--round` 值非嚴格遞增出現（例如：`r1`→`r2`→又補了一筆 `r1`，如遲交/更正的席次記錄），`groups` 會是 `{r1:[...], r2:[...]}`，`reversed(groups.items())` 拿到的仍是 `r2`（因為 `r2` 是第二個被插入的 key，即使 `r1` 之後又被追加了新紀錄）。於是 gate 讀到的「判定輪」不是帳面上真正最後寫入的那筆，而是次序上「先出現的較晚 key」。

實測（`repro2`）：
1. `--round r1`：一筆無處置欄的普通 caught
2. `--round r2`：一筆有 `--findings-set` 但**沒有** `--report/--snapshot` 的記錄
3. `--round r1`（真正時序上最後一筆）：**完整合法**的處置紀錄（`--findings-set/--folded-set/--report/--snapshot/--spec/--reviewed` 全帶齊）

跑 `lumos loop status repro-loop2 --disposal --spec ... --repo ...`，輸出：
```
[disposal] G3 hash: ✗ — 判定輪未綁 hash(...)
[disposal] 留痕: ✗ — 判定輪未帶 report/snapshot(留痕缺席)
⛔ DISPOSAL GATE FAIL (repro-loop2 輪 r2: G3/留痕缺席)
```
Gate 判的是「輪 r2」，完全略過了時序上最後、且真正合法的第二筆 `r1` 記錄——本應收斂（rc0）的帳被錯判為 FAIL（rc1）。反向情境（r2 恰好合法、真正最後一筆 r1 記錄其實有問題）則會造成**假 PASS**，比假 FAIL 更嚴重（gate 的整個賣點就是「四條合取★全讀側可重算★」，這裡的「讀側」本身選錯了要重算的對象）。

**對照**：同檔案既有的姊妹函式 `_loop_status_panel`（`scripts/lumos:3005` 起）在分組時明確擋掉這個情境——`scripts/lumos:3016-3020`：`if rid_ in groups and next(reversed(groups)) != rid_: print("ERROR: round-id ... 非連續重現(被其他輪隔開;append-only 帳次序損壞)"); return 2`。這是本 repo 對「round-id 被隔開後重現」這個確切邊界情境的既有防禦模式；新的 `_loop_status_disposal` 完全沒有複用或重做這道檢查，是新舊實作間的不一致，而非刻意設計（無任何註解說明為何 disposal 路徑可以豁免這個檢查）。

**測試覆蓋缺口**：`t_loop_status_disposal_gate`（`scripts/test_lumos.py:11990` 起讀到之新測試）全程只用單一 round-id（`r1`）跑多席，從未測「round-id 重現」情境，所以這個洞沒有被既有測試蓋到。

---

## Finding 2 — `_quote_rows` 的引句抽取正則遇巢狀全形引號（『』 內嵌於「」）會在第一個『』處截斷，可讓引句偽造繞過 quote-check 的錨定驗證（已用真 CLI 重現）

- **severity: major**
- **file:line**: `scripts/lumos:8090`
- **引句**：「`quotes = re.findall(r"引句[：:]\s*[「『]([^」』]+)[」』]", rtext)`」

**失敗場景（已用 `_quote_rows` 實跑重現）**：

字元類 `[^」』]+` 同時排除 `」` 與 `』`，所以只要引句本文中含有一個 `『...』` 巢狀引號，正則會在第一個 `』` 就把整條引句截斷，後面的文字完全不會進入抽取結果、也就完全不會被 quote-check 驗證。

實測：報告寫「引句：「規則『甲』其實根本不存在,是編出來的」」（審查員聲稱規則『甲』不存在，並附了說法），快照裡只有「只有這句提到規則『甲』,沒有其他敘述。」——`_quote_rows` 抽到的引句只有「規則『甲」（被截斷），而這個截斷片段剛好是快照裡「規則『甲』」的前綴，於是判定 `ok: True`。也就是說，審查員在引句欄位裡寫的整句「其實根本不存在,是編出來的」這段**從未被驗證**過就被判為「錨定成功」——quote-check 的存在目的（`skills/lumos-design-loop/templates.md` 新增段：「編不出引句的疑慮不要交」「錨不到＝該條不採信」，以及 T3 反循環合約要擋的正是「編造但看似合理」的引句）在這個巢狀引號邊界上被繞過。

考量本 repo 全篇文件（含 CLAUDE.md、本次 diff 的多處 KEY 行）大量使用「「」外層／『』內層」的巢狀引號慣例，審查員在複製「原文逐字引句」時完整保留巢狀引號是很自然會發生的情況，不是刁鑽構造。

**測試覆蓋缺口**：`t_quote_check_normalization_and_verdict`（`scripts/test_lumos.py:1175` 起）只測了粗體/反引號/跨行三種正規化情境與「快照裡完全沒有」的編造引句，沒有測巢狀引號截斷這個抽取邊界。

---

## Manifest 判定

- **項目**：`governance/eval/canary_calibration.py:81`——「檔案 handle 有沒有 with/確定 close?」
- **判定：誤報（false positive）**
- 實際程式碼（`governance/eval/canary_calibration.py:81-82`）：
  ```python
  with log.open("a", encoding="utf-8") as f:
      f.write(json.dumps(entry, ensure_ascii=False) + "\n")
  ```
  已用 `with` context manager 開檔，正常結束或例外都會保證 `f` 被關閉，沒有 handle 洩漏疑慮。此為 manifest 誤判，不成立。

---

## 總結

findings 2 條（Finding 1、Finding 2），皆 severity = **major**；manifest 命中 1 條判**誤報**。

**max severity: major**
