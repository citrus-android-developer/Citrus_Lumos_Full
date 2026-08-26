# 設計:valid_under 進場主動提示 + 過期引用率指標(valid-under-active-prompt)

- 日期:2026-06-29
- 狀態:DRAFT
- 動機來源:2026-06-23 治理日報 gap「valid_under 只在寫入時標記,AI 重讀時不理它;FAMA 實測連專門記憶系統也救不多」
- loop_id:valid-under-active-prompt

## 目標(一句話)

讓 `lumos context` 在傳回節點內容**之前**搶先顯示 `valid_under` 條件警示(含日齡啟發式紅標),並在 `lumos doctor` 新增 Check V(軟)量出「全圖有多少比例的節點 valid_under 可能已過期」——讓「有寫失效條件」確實影響 AI 進場行為,而不只是寫入時的自我安慰。

## 前提與既驗事實

- **`cmd_context` 不輸出 `valid_under`**(`scripts/lumos:1785`):valid_under 存在 frontmatter、`lumos stale --match` 可篩,但 `cmd_context` 顯示的欄位(meta/contracts/summary/verified_by/plan_refs/core_refs/edges)完全不包含 valid_under/revalidate_when。AI 用 `lumos context` 讀節點時**看不到失效條件**,遑論遵守。
- **`lumos stale` 是事後列表,不是進場警示**(`scripts/lumos:1921`):列所有 status=stale 的驗證節點;但 AI 是先 `context` 取節點再工作,`stale` 命令要 AI 主動去查才有效——FAMA 指出 AI 不會主動去查。
- **`valid_under` 解析已有**(`scripts/lumos:1912` def,`scripts/lumos:1957` 呼叫點):_conds() 把 valid_under block scalar / YAML list 拆成條件列表(via as_list + split("\n"));現只用於 `stale --match`;可直接重用於 context 顯示。
- **`extract_contracts` 範例**(`scripts/lumos:863` def,`scripts/lumos:1795` cmd_context 呼叫點):合約在 context 最頂以 `⚠ 合約(動前必讀):` 突顯——相同位置模式可套用 valid_under 警示;差異在合約是「改前必讀」,valid_under 是「用前核實」。
- **日齡啟發式——欄位差異**:valid_under 目前只存在於 **Verification 節點**(全圖 14/14 皆然,`grep -rln "valid_under:" docs/lumos-toolchain-knowledge/` 坐實)。Verification 節點用 `date:` 欄位記錄日期(`scripts/lumos:2777` 模板),Systems 節點用 `updated:`。`date:` 屬 DATE_KEYS(L2416)並由 fmt_scalar(L2453)驗 YYYY-MM-DD 格式,`lumos new` 寫入時以 `datetime.date.today().isoformat()` 保證 ISO。日齡計算讀 `n.fields.get("date") or n.fields.get("updated") or ""`(date 優先適 Verification,updated 作 System 保險 fallback)。>90 天加紅標 `[⚠ 節點已 N 天未更新,前提條件可能失效]`(90 天拍估,非精確 TTL)。空字串直接跳過不計算日齡(guard:`if date_str:` 再呼叫 `datetime.date.fromisoformat`;加 try/except ValueError 作容錯,同 L2643 既有範例)。
- **doctor soft-check 範例**(`scripts/lumos:647` Check S 區塊):只 warn_soft(定義 L384)、不計 issues、不影響 rc;Check V 照此模板。warn_soft 與 _soft_list(L671)均為 run_doctor 閉包,Check V 亦在 run_doctor 內故可直接呼叫。`section()` 是 run_doctor 內函式(L369),呼叫方式 `section("V", "title")`。現有 Check 段尾順序 T(L564)→R(L622)→S(L651)→H(L691)→K(L708),Check V 接在 K 後。
- **FAMA 實測上限**:就算顯示了 valid_under,AI 取用率估計仍有限;這是「無→有」的改善,不是「有→必遵守」的保證。

## 解法比較與選擇

| 方案 | 描述 | 優 | 劣 |
|------|------|----|----|
| A(選)| context 頂部插 valid_under 警示 + 日齡紅標 + doctor Check V 計率 | 不改 workflow;AI 進場就看到;可量化 | 日齡是 proxy;AI 仍可能忽略 |
| B | `lumos guard` 進場強制確認(阻斷) | 更強制 | 嚴重打斷合法查詢;YAGNI |
| C | 只加 doctor 指標、不改 context | 可量化 | 沒解進場看不到的核心問題 |

否決 B:阻斷式太重,valid_under 多數情況仍有效,阻斷比例會高、破壞日常使用。否決 C:治標不治本。選 A:最小侵入、確實把資訊推到 AI 眼前。

## 邊界 / 非目標(YAGNI)

- ❌ **不語義評估** valid_under 條件現在是否成立(那需要 LLM + 系統知識;本 spec 只靜態顯示)。
- ❌ **不自動 `set status stale`**:人/AI 讀了警示後自行判斷要不要標 stale。
- ❌ **不改 `revalidate_when` 顯示邏輯**:只加 valid_under 的 context 警示;revalidate_when 不加入 context 輸出(已由 `lumos stale --candidate` 覆蓋)。
- ❌ **不追蹤每次 `lumos context` 呼叫日誌**:rate 從 doctor 靜態掃,不靠 invocation log。
- ❌ **不擋 doctor rc**:Check V 用 warn_soft,不影響 CI。
- ❌ **不改 `lumos stale` 現有行為**:保留現有語義,pure add。

## 組件(改動)

### 改:`scripts/lumos` — `cmd_context`(L1785)

在輸出 meta 行、**contracts 之前**,新增 valid_under 警示:

位置:`print(f"# {rel}")` 之後(L1792)、`extract_contracts(n)` 呼叫(L1795)之前。

邏輯:
1. 取 `n.fields.get("valid_under")`
2. 呼叫 `_conds()`(L1912)拆成條件列表;若列表為空跳過(m5 修正:避免空 valid_under 印出零條件 header)
3. **計算日齡**:讀 `n.fields.get("date") or n.fields.get("updated") or ""`(Verification 節點只有 `date:`,System 節點只有 `updated:`)。用 `import datetime`(function-local,與既有慣例一致)然後 `if date_str: try: delta = (datetime.date.today() - datetime.date.fromisoformat(date_str)).days; except ValueError: delta = None`(B1/m3 修正:空字串跳過、fromisoformat 加 try/except 容錯,同 L2643 既有範例)。`delta>90` 則加 `[⚠ 節點已 {delta} 天未更新,前提條件可能失效]`。
4. 印出 `⚠ 使用前驗證(valid_under<hint>):` + 逐條條件

### 改:`scripts/lumos` — `run_doctor`(Check V,軟)

在既有 **Check K 之後**新增 Check V(段尾 T→R→S→H→K→V):

- 掃全圖所有有 valid_under 欄位的節點;_conds() 返回非空者才計入(m5 修正)
- **計算日齡**:讀 `n.fields.get("date") or n.fields.get("updated") or ""`(同 cmd_context);加 try/except ValueError 跳過格式異常
- 日齡 >90 天者計入 vu_stale
- 報告:`f"{len(vu_stale)}/{len(vu_total)} ({rate:.0%})"` 例 `2/3 (67%)`(格式已定義)
- 用 `_soft_list` + `warn_soft`(均為 run_doctor 閉包),不計入 issues,不改 rc;`section("V", "...")`
- 全數 ≤90 天或無 vu_total → 印 ok 行

### 不改

lumos stale、lumos search、lumos contracts、canary/judge/doctor rc 邏輯,revalidate_when 顯示。

## 誠實天花板

1. **日齡是 proxy,不是真實性判斷**:date/updated >90 不等於「前提條件已失效」——可能 90 天前提仍成立,也可能 10 天就失效(前提條件本身變了)。只是粗篩啟發。
2. **age ≠ content-drift**(m6/M2 修正):日齡只量「節點多久沒更新」,無法偵測「valid_under 條件文字 / 系統本身已改但節點仍新」的內容漂移。語義評估需人 / LLM 介入(非目標)。初期(新節點全<90天)Check V 的過期率恆為 0%——指標要到建圖後 90 天才開始有意義。rate 的價值在長期趨勢管理,不在精確點位。
3. **rate 指標是管理視角**:90 天門檻、date/updated 準確性都影響數字。
4. **`date:` 欄位無 `lumos set` 更新路徑**:Verification 節點的 `date:` 不在 `SCALAR_KEYS`(L2414),無法用 `lumos set` 刷新;消除提示方式:手動更新 frontmatter 或建新 Verification 節點。
5. **不改 Check Doctor rc**:warn_soft 確保不意外破 CI。

## 測試策略

所有測試以 **CLI subprocess 方式**(`run(vault, "context", node)` 斷言 stdout,與 test_lumos.py 既有 `search`/`decisions`/`doctor` 測試同風格)：

- **context 基本警示**:fixture Verification 節點含 `valid_under: [cond1]` + `date: 2020-01-01`(>90 天);驗 stdout 含「⚠ 使用前驗證(valid_under」且含「⚠ 節點已」。
- **無過期節點**:fixture `date:` 為今天;驗 stdout 含「⚠ 使用前驗證」但不含「⚠ 節點已」。
- **無 valid_under 節點**:驗 stdout 不輸出「⚠ 使用前驗證」。
- **空 valid_under 節點**(m5 修正新增):fixture `valid_under: []`(empty list);驗 stdout 不輸出「⚠ 使用前驗證」header。
- **Check V 指標**:fixture 含 3 個有 valid_under 節點(2 個 `date: 2020-01-01` > 90 天,1 個今天);驗 doctor stdout 含「2/3 (67%)」。
- **Check V 全新**:fixture 全 ≤90 天;驗 doctor stdout 含「ok」。
- 名稱範例:`t_context_valid_under_warning`、`t_doctor_check_v`(接在既有 `t_check_k` 後;注:test 以字母序執行,m4 修正:source 位置為習慣不是強制)。

## 知識同步影響

改動若實作,需同步以下知識:

1. **`docs/methodology/架構圖即合約.md`**:若有「lumos context 輸出格式說明」章節 → 補「valid_under 警示現在在 contracts 之前出現」;若無 → 在「節點讀取規範」相關段落補注。
2. **`docs/methodology/架構圖即合約-對外論述.md`**:若有「staleness 如何處理」相關段落 → 更新描述從「passive 標記」改為「進場主動提示」;否則補一段說明設計哲學(valid_under 不只是寫入標記,也是進場守衛)。
3. **`lumos-project-notes` skill**:若有「valid_under 用法說明」→ 補「context 時會自動警示」;若無此欄 → 可在 CLAUDE.md 標籤規範表下方加備注。
4. **`Verification/2026-06-23_check-t-sentinel.md`**:實作後更新此節點的 `valid_under` 中 "T→R→S→K" → "T→R→S→H→K→V"(字串已過時,Check H 早於本節點 authoring;需重驗跑 `t_check_k`)。

預計改動幅度:小(補幾行說明 + 更新 sentinel valid_under 字串);可在 PR review 時人工同步,不須另開工單。

## 審計修正紀錄

### R1(2026-06-29) — canary CAUGHT,severity=blocker → 以下真 finding 折入:
- **F8(blocker,辯方維持)**:日齡欄位錯 → 改用 `n.fields.get("date") or n.fields.get("updated") or ""`。
- **F10(minor,辯方降格)**:插入點「Check S 後」→ 改 K 後。
- **F11(minor,辯方降格)**:測試策略改為 CLI subprocess。
- **F13(minor)**:非目標 revalidate_when 矛盾 → 刪組件 step 5。
- **F9(辯方駁倒,不折)**:datetime import 假陽性。

### R2(2026-06-29) — canary CAUGHT,severity=minor → 以下真 finding 折入:
- **B1(minor,辯方降格)**:sentinel 知識同步補注(知識同步影響第 4 項)。
- **M2(minor,辯方降格,含 B1)**:sentinel 過時順序字串,同上。
- **M3(minor,辯方降格)**:誠實天花板第 4 項補注 `date:` 無 `lumos set` 路徑。
- **m5,m7,anchor(minor)**:率格式定義、block scalar 措辭、測試名修正。
- **M4(辯方駁倒,不折)**:formula strawman。

### R3(2026-06-29) — canary CAUGHT,severity=minor → 以下真 finding 折入:
- **B1/m3(minor)**:前提區塊補注 `if date_str:` guard + try/except ValueError 容錯(同 L2643 既有範例);90 天閾值定義在組件描述中一處即可。
- **m5(minor)**:新增空 valid_under header 防衛(`_conds()` 返回空列表不印 header);測試補空 valid_under case。
- **m6/M2(minor)**:誠實天花板第 2 項補 "age ≠ content-drift" 與初期指標死區。
- **m4(minor)**:測試章節補注 "test 以字母序執行"。
- **M1(辯方駁倒,不折)**:`date` 在 DATE_KEYS(L2416);`cmd_archive` 用 string-compare;実測不 crash。
- **M2(辯方駁倒,不折)**:timeline 逆転;protected invariant=K 不改名非 K 最後。
