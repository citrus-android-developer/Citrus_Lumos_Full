# ★COMBO★ 組合覆蓋軟規範 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 給 lumos doctor 加一道軟 Check(Check K)——標了 `★COMBO★` 的最重 `★INVARIANT★` 鐵則只綁 1 個 `[test:]` 時,`warn_soft` 提醒補組合測試(不擋、不計 issues)。

**Architecture:** 在 `scripts/lumos` 的 `cmd_doctor` 函數內、Check S 之後、`if ci:` 留痕之前,新增 `section("K")`。照 Check S 結構:`for rel, n in sorted(notes.items())` 重掃 → `extract_contracts(n)` 取 invariants → 過濾 group(1) 含 `★COMBO★` → 數 `[test:]` 標記個數(`TEST_REF_RE.findall`)→ ==1 收進 `combo_thin` → `_soft_list` 印 + `gov_events check-k hard:False`。純加法,不改既有 Check/tag/解析。

**Tech Stack:** Python(`scripts/lumos` 單檔)、`scripts/test_lumos.py`(subprocess fixture 測試:`run`/`mkvault`/`write`/`check`)。

## Global Constraints

- **軟性、不擋**:用 `warn_soft`(經 `_soft_list`),**不計 issues、不影響 rc**(同 Check S)。
- **數 `[test:]` 標記個數,非展開名數**(F1):用 `TEST_REF_RE.findall(inv)`(`scripts/lumos:838`,只匹配 `[test:]` 不含 `[audit:]`);`[test:a,b]` 算 **1 個標記**,免單逗號繞過。spec 寫 `INV_TAG_RE` 不精確(含 audit),**以 `TEST_REF_RE` 為準**。
- **section 識別碼用 `"K"`**(`"C"` 已被 core_refs 占用,`scripts/lumos:514`)。
- **`★COMBO★` 必在 `★INVARIANT★` 之後**(否則 `INVARIANT_RE` 不匹配、整條 invariant 消失);Check K 在 `extract_contracts` 回的 group(1) 文字裡檢測 `★COMBO★`。
- **不改**:Check T、`[test:]` 解析、既有 4 tag、節點分類、`gov_events` schema。
- **插入點**:`cmd_doctor` 內 Check S 的尾 `print()`(`scripts/lumos:685`)之後、`if ci: _append_governance_log`(`scripts/lumos:687`)之前。

---

### Task 1: Check K(section("K"))實作 + fixture 測試

**Files:**
- Modify: `scripts/lumos`(`cmd_doctor`,插在 L685 `print()` 後、L687 `if ci:` 前)
- Test: `scripts/test_lumos.py`(加 3 個 Check K fixture 測試)

**Interfaces:**
- Consumes(既有,已 ground-truth 坐實):`section(idx, title)` L366、`extract_contracts(n)` L821 回 `(inv, debt)`、`TEST_REF_RE` L838、`_soft_list(items, head, advice)` L668、`ok(msg)` L369、`gov_events` list L364、`notes` dict、`n.stem`。
- Produces:doctor 輸出多一段 `[K] ★COMBO★ 組合覆蓋提醒`;`gov_events` 多 `{"gate":"check-k",...}`(僅 `--ci` 時寫入 `.governance-log.jsonl`)。

- [ ] **Step 1: 看既有 invariant 測試的 fixture 寫法**

Run: `grep -n "★INVARIANT★\|def test" scripts/test_lumos.py | head`
目的:確認 `mkvault()`/`write(v, rel, fm, body)` 怎麼讓 doctor 認到 invariant(KEY 行格式、節點 type),照同模式寫 Check K 測試。

- [ ] **Step 2: 寫失敗測試(3 個 Check K case)**

加到 `scripts/test_lumos.py`(照既有 `run`/`mkvault`/`write`/`check` 模式;invariant 寫在節點 body 的 `KEY:` 行,★COMBO★ 在 ★INVARIANT★ 之後):

```python
def test_check_k_thin_warns():
    v = mkvault()
    write(v, "money.md", "type: system\n",
          "KEY: ★INVARIANT★ 不可超賣 ★COMBO★ [test:OverbookHappy]\n")
    r = run(v, "doctor")
    check("Check K 提醒只綁 1 個 [test:]", "補組合" in r.stdout or "只綁 1" in r.stdout)

def test_check_k_two_tags_silent():
    v = mkvault()
    write(v, "money.md", "type: system\n",
          "KEY: ★INVARIANT★ 不可超賣 ★COMBO★ [test:Happy] [test:Combo]\n")
    r = run(v, "doctor")
    check("綁 2 個 [test:] 標記 → 不提醒", "補組合" not in r.stdout)

def test_check_k_no_combo_silent():
    v = mkvault()
    write(v, "money.md", "type: system\n",
          "KEY: ★INVARIANT★ 不可超賣 [test:Happy]\n")
    r = run(v, "doctor")
    check("無 ★COMBO★ → Check K 不提醒補組合", "補組合" not in r.stdout)
```

- [ ] **Step 3: 跑測試確認失敗**

Run: `python3 scripts/test_lumos.py 2>&1 | grep -i "check_k\|FAIL\|✗" | head`
Expected: 3 個 Check K case 失敗(Check K 還沒實作,doctor 輸出無「補組合」)。

- [ ] **Step 4: 實作 section("K")**

在 `scripts/lumos` 的 `cmd_doctor`,Check S 尾 `print()`(L685)之後、`if ci:`(L687)之前插入:

```python
    # Check K: ★COMBO★ 組合覆蓋提醒(軟,不擋,不計 issues)——標了 ★COMBO★ 的最重 ★INVARIANT★
    #   只綁 1 個 [test:] 標記 → 提醒補組合測試。數標記個數(TEST_REF_RE,非展開名數),免 [test:a,b] 逗號繞過。
    section("K", "★COMBO★ 組合覆蓋提醒 (最重鐵則只綁 1 個 [test:] → 補組合)")
    combo_thin, combo_any = [], False
    for rel, n in sorted(notes.items()):
        invs, _ = extract_contracts(n)
        for inv in invs:
            if "★COMBO★" not in inv:
                continue
            combo_any = True
            if len(TEST_REF_RE.findall(inv)) == 1:
                combo_thin.append(inv.replace("★COMBO★", "").strip())
                gov_events.append({"gate": "check-k", "kind": "warned",
                                   "hard": False, "nodes": [n.stem]})
    if not combo_any:
        ok("無 ★COMBO★ 標記 (無鐵則宣告需組合覆蓋)")
    elif combo_thin:
        _soft_list(combo_thin,
                   f"{len(combo_thin)} 條 ★COMBO★ 鐵則只綁 1 個 [test:] happy-path:",
                   "為這條最重鐵則補一條組合情境測試(多條件交叉),別只測 happy-path")
    else:
        ok("★COMBO★ 鐵則都綁了 ≥2 個 [test:] 標記")
    print()
```

- [ ] **Step 5: 跑測試確認通過**

Run: `python3 scripts/test_lumos.py 2>&1 | tail -3`
Expected: 全綠(含 3 個新 Check K case)。若 fixture 沒讓 doctor 認到 invariant(KEY 行 type 問題),照 Step 1 既有 invariant 測試的節點格式調 `write()` 的 fm/body。

- [ ] **Step 6: 手動驗 rc 不變(warn_soft 不計 issues)**

Run: `cd /tmp && python3 /Users/enzo/harness/lumos-toolchain/scripts/lumos --vault <一個含 ★COMBO★ 綁1標記的 vault> doctor; echo "rc=$?"`
Expected: 輸出含「補組合」提醒,但 `rc` 與沒有 Check K 時相同(Check K 只 warn_soft、不動 issues)。

- [ ] **Step 7: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): Check K — ★COMBO★ 組合覆蓋軟提醒(數 [test:] 標記、warn_soft 不擋)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: 知識同步(方法論 tag/Check 體系 + lumos tag 說明)

**Files:**
- Modify: `docs/methodology/架構圖即合約.md`(Tag 體系補 ★COMBO★、Check 體系補 Check K)
- Modify: `docs/methodology/架構圖即合約-對外論述.md`(白話補一句)
- Modify: `scripts/lumos`(若有 Tag 說明/help 文字,補 ★COMBO★)

- [ ] **Step 1: 方法論(技術)補 ★COMBO★ + Check K**

在 `docs/methodology/架構圖即合約.md` Tag 體系處補第 5 個 tag `★COMBO★`(★INVARIANT★ 子修飾、必寫其後);Check 體系補 Check K(軟、只數 [test:] 標記、提醒補組合)。點出「驗證正確性 > AI 審計」主軸:CI 跑測試是錨點,Check K 只軟提醒「最重鐵則別只綁 1 個 happy-path」。

- [ ] **Step 2: 對外論述補白話一句**

在 `docs/methodology/架構圖即合約-對外論述.md` 補:最重的鐵則別只測一個順風案例,該測「各種情況湊一起」——lumos 軟提醒、不強制、不擋。

- [ ] **Step 3: lumos tag 說明補 ★COMBO★(若有)**

Run: `grep -nE "★INVARIANT★|★IRREVERSIBLE★|★CHECKPOINT★" scripts/lumos | grep -iE "help|說明|tag" | head`
若有集中的 Tag 說明/help 文字,補一行 `★COMBO★`(標最重 ★INVARIANT★、必寫其後、軟提醒組合覆蓋);無則略過。

- [ ] **Step 4: Commit**

```bash
git add docs/methodology/ scripts/lumos
git commit -m "docs(check-t-sentinel): 知識同步——方法論 Tag 體系補 ★COMBO★ + Check K

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## 啟用後(人手,非實作步驟)

- 在最重的 money-path `★INVARIANT★` 鐵則行尾(★INVARIANT★ 之後)加 `★COMBO★`,doctor 會軟提醒補組合測試。
- 補的組合測試另綁一個 `[test:組合測試名]`(該 invariant 達 ≥2 個 [test:] 標記 → 提醒消失)。
- 真正的組合覆蓋有效性靠 CI 跑紅綠;Check K 只是提醒、不保證。
