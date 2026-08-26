# valid_under 進場主動提示 + Check V Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓 `lumos context` 在輸出節點內容前搶先顯示 `valid_under` 失效條件(含 >90 天日齡紅標),並在 `lumos doctor` 加一個軟性 Check V 量「全圖 valid_under 可能過期的比例」——把「有寫失效條件」從寫入時的自我安慰變成 AI 進場時真的看得到的提示。

**Architecture:** 純加性改 `scripts/lumos` 兩處(`cmd_context` 輸出區、`run_doctor` 段尾)+ 一個共用日齡 helper,避免兩處重複日齡邏輯。不改既有 `lumos stale`、不改 doctor 退出碼、不做語義評估(只靜態顯示 + 日齡 proxy)。

**Tech Stack:** Python 3 標準庫(datetime),零第三方依賴。測試用 repo 既有 `scripts/test_lumos.py` 的 `check()` harness + CLI subprocess(`run(vault, ...)`),非 pytest。

## Global Constraints

- stdlib only,零第三方依賴;Python ≥ 3.8。
- **純加性**:不改 `lumos stale`、`lumos search`、`lumos contracts`、canary/judge 邏輯、doctor 退出碼、`revalidate_when` 顯示。
- **Check V 用 `warn_soft`**(不計 issues、不改 rc;CI 不被擋)。
- valid_under 警示在 `cmd_context` 的 **meta 行之後、`extract_contracts` 之前**輸出。
- 日齡來源:`n.fields.get("date") or n.fields.get("updated") or ""`(Verification 用 `date:`、System 用 `updated:`);空字串或格式異常 → 不計日齡(視為 None,不紅標、不計入 stale)。
- 日齡 **>90 天**才紅標(90 天為粗估啟發,非精確 TTL)。
- 空 `valid_under`(`_conds()` 回空 list)→ 不印 header。
- 測試一律 CLI subprocess 風格(`run(v, "context"/"doctor", ...)`),`t_`-prefixed,`check(name, cond, detail)` 斷言。
- 寫入走既有慣例;`import datetime` 用 function-local(與 `scripts/lumos` 既有慣例一致)。

---

### Task 1: `cmd_context` valid_under 進場警示 + 日齡紅標(含共用 helper)

**Files:**
- Modify: `scripts/lumos` — 新增 `_node_age_days()`(置於 `cmd_context` 之前,約 L1784);改 `cmd_context`(`scripts/lumos:1785`,在 L1794 `print(meta)` 之後、L1795 `extract_contracts` 之前插入)
- Test: `scripts/test_lumos.py`(新增 `t_context_valid_under_*`)

**Interfaces:**
- Produces:
  - `_node_age_days(n) -> int | None` — 節點日齡(天):`date:`(Verification)優先、`updated:`(System)fallback;空/格式異常回 None。Task 2 共用。
  - `cmd_context` 輸出新增區塊:有 `valid_under` 條件時印 `⚠ 使用前驗證(valid_under)[紅標]:` + 逐條條件。
- Consumes: 既有 `_conds(val)`(`scripts/lumos:1912`,把 list/字串/block scalar 拆條件列表)。

- [ ] **Step 1: Write the failing tests(4 case)**

加到 `scripts/test_lumos.py`(`t_` 前綴自動發現;用既有 `mkvault`/`write`/`run`/`check`):

```python
def t_context_valid_under_warning():
    import datetime
    v = mkvault()
    # >90 天的 Verification 節點(date 2020 → 紅標)
    write(v, "Verification/old.md",
          'type: verification\nstatus: pass\ndate: 2020-01-01\nvalid_under:\n  - "DB schema v1 未變"')
    r = run(v, "context", "Verification/old")
    check("context: valid_under 警示 header", "⚠ 使用前驗證(valid_under" in r.stdout, r.stdout)
    check("context: >90 天紅標", "⚠ 節點已" in r.stdout, r.stdout)
    check("context: 條件內容印出", "DB schema v1 未變" in r.stdout, r.stdout)

    # 新節點(date=今天 → 有警示但無紅標)
    today = datetime.date.today().isoformat()
    write(v, "Verification/fresh.md",
          f'type: verification\nstatus: pass\ndate: {today}\nvalid_under:\n  - "並發 <= 1000 RPS"')
    r2 = run(v, "context", "Verification/fresh")
    check("context: 新節點有警示", "⚠ 使用前驗證(valid_under" in r2.stdout, r2.stdout)
    check("context: 新節點無紅標", "⚠ 節點已" not in r2.stdout, r2.stdout)

    # 無 valid_under → 不印警示
    write(v, "Systems/plain.md", 'type: system\nstatus: done\nupdated: 2020-01-01')
    r3 = run(v, "context", "Systems/plain")
    check("context: 無 valid_under 不印警示", "⚠ 使用前驗證(valid_under" not in r3.stdout, r3.stdout)

    # 空 valid_under(empty list)→ 不印 header
    write(v, "Verification/empty.md",
          'type: verification\nstatus: pass\ndate: 2020-01-01\nvalid_under: []')
    r4 = run(v, "context", "Verification/empty")
    check("context: 空 valid_under 不印 header", "⚠ 使用前驗證(valid_under" not in r4.stdout, r4.stdout)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "context:"`
Expected: FAIL — 警示尚未實作(stdout 不含「⚠ 使用前驗證」)。

- [ ] **Step 3: Add the `_node_age_days` helper**

在 `scripts/lumos` 的 `cmd_context`(L1785)**之前**插入:

```python
def _node_age_days(n):
    """節點日齡(天):Verification 用 date:、System 用 updated:。
    取不到或格式異常 → None(不參與日齡判斷)。90 天紅標的共用來源(cmd_context + doctor Check V)。"""
    import datetime
    date_str = n.fields.get("date") or n.fields.get("updated") or ""
    if not date_str:
        return None
    try:
        return (datetime.date.today() - datetime.date.fromisoformat(str(date_str))).days
    except ValueError:
        return None
```

- [ ] **Step 4: Insert the valid_under block into `cmd_context`**

在 `scripts/lumos:1794`(`print(meta)`)之後、`scripts/lumos:1795`(`inv, debt = extract_contracts(n)`)之前插入:

```python
    vu = _conds(n.fields.get("valid_under"))
    if vu:
        age = _node_age_days(n)
        flag = f"[⚠ 節點已 {age} 天未更新,前提條件可能失效]" if (age is not None and age > 90) else ""
        print(f"⚠ 使用前驗證(valid_under){flag}:")
        for c in vu:
            print(f"  {c}")
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "context:"`
Expected: 6 行全 `✓`(header 出現、>90 紅標、條件印出、新節點無紅標、無 valid_under 不印、空 valid_under 不印)。

- [ ] **Step 6: Run full suite (no regression)**

Run: `python3 scripts/test_lumos.py`
Expected: `N passed, 0 failed`。

- [ ] **Step 7: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): cmd_context 進場顯示 valid_under + >90天日齡紅標(+ _node_age_days helper)"
```

---

### Task 2: `lumos doctor` Check V — valid_under 過期率(軟)

**Files:**
- Modify: `scripts/lumos` — `run_doctor`(`scripts/lumos:360`),在 Check K 區塊結尾(`scripts/lumos:727` 的 `print()`)之後、`scripts/lumos:729`(`if ci:`)之前插入 Check V
- Test: `scripts/test_lumos.py`(新增 `t_doctor_check_v`)

**Interfaces:**
- Consumes: `_node_age_days`(Task 1)、`_conds`(L1912)、run_doctor 閉包內的 `notes`、`section`、`ok`、`warn_soft`(`scripts/lumos:369/372/384`)。
- Produces: doctor 輸出新增 `[V]` 段;軟提醒、不計 issues、不改 rc。

- [ ] **Step 1: Write the failing test**

```python
def t_doctor_check_v():
    import datetime
    v = mkvault()
    write(v, "Verification/a.md",
          'type: verification\nstatus: pass\ndate: 2020-01-01\nvalid_under:\n  - "c1"')
    write(v, "Verification/b.md",
          'type: verification\nstatus: pass\ndate: 2020-02-02\nvalid_under:\n  - "c2"')
    today = datetime.date.today().isoformat()
    write(v, "Verification/c.md",
          f'type: verification\nstatus: pass\ndate: {today}\nvalid_under:\n  - "c3"')
    r = run(v, "doctor")
    check("doctor Check V: 段標題出現", "[V]" in r.stdout, r.stdout)
    check("doctor Check V: 2/3 (67%)", "2/3 (67%)" in r.stdout, r.stdout)

    # 全新節點 → 0% / ok 行
    v2 = mkvault()
    write(v2, "Verification/fresh.md",
          f'type: verification\nstatus: pass\ndate: {today}\nvalid_under:\n  - "c1"')
    r2 = run(v2, "doctor")
    check("doctor Check V: 全新 → 0%/ok", ("0/1 (0%)" in r2.stdout) or ("≤90" in r2.stdout), r2.stdout)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "Check V"`
Expected: FAIL — doctor 尚無 `[V]` 段(stdout 不含 `2/3 (67%)`)。

- [ ] **Step 3: Insert Check V into `run_doctor`**

在 `scripts/lumos:727`(Check K 區塊尾的 `print()`)之後、`scripts/lumos:729`(`if ci:`)之前插入:

```python
    section("V", "valid_under 過期率 (進場提示覆蓋 + 日齡 proxy;軟提醒、不擋 CI)")
    vu_total, vu_stale = [], []
    for rel, n in sorted(notes.items()):
        if not _conds(n.fields.get("valid_under")):
            continue
        vu_total.append(rel)
        age = _node_age_days(n)
        if age is not None and age > 90:
            vu_stale.append(f"{rel}(已 {age} 天未更新)")
    if not vu_total:
        ok("無 valid_under 節點 (無進場提示需量)")
    elif vu_stale:
        rate = len(vu_stale) / len(vu_total)
        warn_soft(vu_stale,
                  f"{len(vu_stale)}/{len(vu_total)} ({rate:.0%}) 個 valid_under 節點 >90 天未更新(前提可能失效):",
                  "進場 lumos context 已會警示;>90 天者建議重核 valid_under、必要時標 stale 或建新 Verification")
    else:
        ok(f"0/{len(vu_total)} (0%) — 所有 valid_under 節點 ≤90 天")
    print()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 scripts/test_lumos.py 2>&1 | grep "Check V"`
Expected: 3 行 `✓`（段標題、`2/3 (67%)`、全新 0%/ok）。

- [ ] **Step 5: Run full suite + smoke on the real vault**

Run: `python3 scripts/test_lumos.py`
Expected: `N passed, 0 failed`。

Run: `./scripts/lumos doctor 2>&1 | grep -A2 "\[V\]"`
Expected: 出現 `[V] valid_under 過期率 …` 段(真實 vault 多數節點 ≤90 天 → 0% 或少量),且 doctor 結尾仍 `✓ 架構圖健康 — 0 issues`(Check V 是軟提醒,不改 rc)。

- [ ] **Step 6: Commit**

```bash
git add scripts/lumos scripts/test_lumos.py
git commit -m "feat(lumos): doctor 加 Check V — valid_under 過期率軟提醒(段尾 T→R→S→H→K→V)"
```

---

### Task 3: 知識同步(過時 check 順序字串 + 方法論/skill 註記)

實作改了 doctor 段尾順序與 context 行為 → 同步架構圖與方法論,把 drift 堵在放行這一刻(架構圖即合約套自己身上)。

**Files:**
- Modify: `docs/lumos-toolchain-knowledge/Verification/2026-06-23_check-t-sentinel.md`(valid_under 過時順序字串)
- Modify: `docs/lumos-toolchain-knowledge/Systems/check-t-sentinel.md`(FLOW 行 + decisions 內過時順序字串)
- Modify: `skills/lumos-project-notes/SKILL.md`(valid_under 用法處補「context 會自動警示」)

**Interfaces:** 無(純文件/架構圖字串同步)。

- [ ] **Step 1: 修過時的 doctor check 順序字串(3 處,`T→R→S→K` → `T→R→S→H→K→V`)**

這 3 處字串現為 `T→R→S→K`(已漏 H,加 V 後正解為 `T→R→S→H→K→V`):

```bash
cd /Users/enzo/harness/lumos-toolchain
grep -rn "T→R→S→K" docs/lumos-toolchain-knowledge/
```
逐處把 `T→R→S→K` 改為 `T→R→S→H→K→V`:
- `Verification/2026-06-23_check-t-sentinel.md:8`(valid_under 條件字串內)
- `Systems/check-t-sentinel.md`(FLOW 行 `Check 段尾(T→R→S→K)` + decisions content `段尾 T→R→S→K`)

用 Edit 逐處替換(字串唯一、直接換)。

- [ ] **Step 2: 驗證架構圖仍健康 + 字串已無殘留**

```bash
grep -rn "T→R→S→K" docs/lumos-toolchain-knowledge/   # 應 0 命中
./scripts/lumos doctor 2>&1 | tail -2                 # 應 0 issues
./scripts/lumos lint check-t-sentinel 2>&1 | tail -1  # 應 0 問題
```
Expected: `T→R→S→K` 0 命中;doctor 0 issues;lint 0 問題。

> 注意:改了這兩個 check-t-sentinel 節點的內容 → 其 `self_audit` 戳記會比 `updated` 舊(若有 bump updated)。本步**只改字串、不改 `updated`/`self_audit`**(屬 L4 審內範圍的同步修正),保持 Check S 綠。

- [ ] **Step 3: 方法論 + skill 註記(valid_under 進場行為)**

在 `skills/lumos-project-notes/SKILL.md` 找到 valid_under 相關說明處(grep 定位):
```bash
grep -n "valid_under" skills/lumos-project-notes/SKILL.md | head
```
在「valid_under 必填」或「Verification 健康檢查」相關段落,補一句(用 Edit 接在該段末):
```
> 進場提示(2026-06-29 起):`lumos context` 讀節點時會在最上方自動顯示 `valid_under` 條件(>90 天未更新加紅標),並由 `lumos doctor` Check V 量全圖過期率——失效條件從「寫入時標記」變「進場主動提示」,不需 AI 自己去 `lumos stale` 查。
```

`docs/methodology/架構圖即合約.md`:grep 是否有「staleness / valid_under / context 輸出」相關段:
```bash
grep -n "valid_under\|staleness\|context" docs/methodology/架構圖即合約.md | head
```
- 有相關段 → 在該段補一句:`valid_under 自 2026-06-29 起於 lumos context 進場主動提示(非僅寫入標記)`。
- 無相關段 → 跳過(不硬塞;此項在 spec §知識同步為「若有…否則」的選擇性同步),並在 commit message 註明「方法論無對應段,略」。

- [ ] **Step 4: Commit**

```bash
git add docs/lumos-toolchain-knowledge/ skills/lumos-project-notes/SKILL.md docs/methodology/架構圖即合約.md
git commit -m "docs(sync): valid_under 進場提示落地——更新 check 順序字串 T→R→S→H→K→V + skill/方法論註記"
```
(若方法論無對應段未改,該檔不納入 `git add`。)

---

## Self-Review

**Spec coverage**(對照 spec `docs/design/2026-06-29-valid-under-active-prompt.md`):
- §組件「改 cmd_context」(L1785,meta 後 contracts 前,_conds + 日齡 date||updated + try/except + >90 紅標 + 空跳過)→ Task 1 全覆蓋。✓
- §組件「run_doctor Check V」(K 後、warn_soft、_conds 非空才計、rate 格式 `2/3 (67%)`、≤90 印 ok)→ Task 2 全覆蓋。✓
- §邊界 YAGNI(不語義評估、不自動 set stale、不改 revalidate_when/stale、不擋 rc)→ Global Constraints + 各 Task 未觸碰,符合。✓
- §測試策略(CLI subprocess、含空 valid_under case、Check V 2/3 + 全新 ok)→ Task 1 Step 1(4 case 含空)+ Task 2 Step 1(2/3 + 全新)。✓
- §知識同步(check-t-sentinel sentinel 字串 + 方法論 + skill)→ Task 3。✓
- §誠實天花板(日齡是 proxy、age≠content-drift、新圖前 90 天恆 0%、date 無 lumos set 路徑)→ 屬設計認知,不需 code;Global Constraints 已反映「>90 為粗估」。✓

**Placeholder scan:** 無 TBD/「similar to」;每個 code step 有完整可貼程式碼;Task 3 Step 3 方法論項用「有則補/無則略 + commit 註明」明確分支,非 placeholder。✓

**Type consistency:** `_node_age_days(n) -> int|None` 定義於 Task 1、消費於 Task 2,簽名一致;`_conds`(既有)兩處同名同用;header 字面 `⚠ 使用前驗證(valid_under` 與紅標 `⚠ 節點已` 在 Task 1 程式碼與 Task 1/2 測試斷言一致;rate 格式 `{rate:.0%}` → `2/3 (67%)` 與 Task 2 測試斷言一致。✓
