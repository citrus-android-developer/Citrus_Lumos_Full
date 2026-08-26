---
type: project
status: done
created: 2026-07-05
updated: 2026-07-07
tags:
  - type/project
  - status/done
related:
  - "[[pitfalls事故觸發_計劃]]"
plan_refs:
  - "[[pitfalls事故觸發_計劃]]"
summary: |-
  FLAG:DECISION
  KEY:「pitfalls 事故觸發」TDD 實作計畫(設計見 [[pitfalls事故觸發_計劃]]);4 task=T1 _match_incident_triggers(glob/content-regex)→ T2 lumos impact incidents 段+去重+讀被碰檔內容 → T3 impact hook 注入 incidents → T4 e2e/回歸+架構圖回填
  KEY:動既有 impact(cmd_impact/scripts/lumos)+ impact-hook.py(剛 merged);算法權威在設計 §2-§4
  DECISION:subagent-driven TDD;merge 前全 test_lumos.py + 真機無 pitfall_when 架構圖 incidents 空不誤傷
  DEP:[[pitfalls事故觸發_計劃]]
  TEST:未開工
---
# pitfalls 事故觸發 Implementation Plan(block ④)

> **REQUIRED SUB-SKILL:** superpowers:subagent-driven-development。**設計權威**:[[pitfalls事故觸發_計劃]](§2 trigger/§3 比對/§4 輸出去重/§5 天花板/§6 測試)。

**Goal:** 事故節點 `pitfall_when`(glob/content-regex)→ `lumos impact` 加 `incidents` 段 → 復用 impact PreToolUse hook 進場自動餵。

**Architecture:** `_match_incident_triggers(file_rel, file_content, env)` 掃全圖 `pitfall_when` 節點比 glob(路徑)/content-regex(被碰檔內容)→ `cmd_impact` 加頂層 `incidents`(去重 vs direct/indirect,重疊只列 incidents)→ impact-hook.py 注入納入 incidents。

**Tech Stack:** python3 stdlib(fnmatch/PurePath.match/re);既有 `_impact_contract`/`as_list`/`cmd_impact`/`impact-hook.py`。

## Global Constraints
- 零第三方依賴。
- 只做 ④(事故 trigger),不重造 impact 既有(T1-T12 已完成)。
- 去重:節點既 impact 結構命中又 trigger 命中 → 只列 incidents。
- 新建檔(無 content)→ content-regex 全 miss、只 glob。
- 測試進 `scripts/test_lumos.py` 用 `check()`;基線=main 現值(先 `python3 scripts/test_lumos.py` 取)。
- 真機無 `pitfall_when` 架構圖跑 impact → incidents 空、不回歸。

---

### Task 1: `_match_incident_triggers`(glob + content-regex)

**Files:** Modify `scripts/lumos`(新 `_match_incident_triggers`);Test `scripts/test_lumos.py`

**Interfaces:** Produces: `_match_incident_triggers(file_rel, file_content, env) -> list[dict]`(每筆 `{node, matched_by}`)。

- [ ] **Step 1: 失敗測試**
```python
def t_match_incident_triggers():
    env, _ = make_fixture_vault({
        "Issues/N1.md": "---\npitfall_when:\n  - \"glob:**/*Repository*.py\"\n---\nN+1 事故",
        "Issues/SQL.md": "---\npitfall_when:\n  - \"content:SELECT\\\\s.*FROM\"\n---\nraw SQL 事故",
        "Issues/None.md": "---\n---\n無 trigger",
    })
    # glob 命中路徑
    r = _match_incident_triggers("app/UserRepository.py", "code", env)
    assert any(x["node"]=="Issues/N1.md" for x in r)
    # content-regex 命中內容
    r2 = _match_incident_triggers("x.py", "q = 'SELECT a FROM t'", env)
    assert any(x["node"]=="Issues/SQL.md" for x in r2)
    # 都不命中
    assert _match_incident_triggers("x.py", "nothing", env) == []
    # 新建檔無 content → 只 glob
    r3 = _match_incident_triggers("app/UserRepository.py", "", env)
    assert any(x["node"]=="Issues/N1.md" for x in r3)
    assert not any(x["node"]=="Issues/SQL.md" for x in r3)
```
- [ ] **Step 2: FAIL**。Run: `python3 scripts/test_lumos.py -k match_incident`
- [ ] **Step 3: 實作** — 見設計 §3:掃 `env.notes` 有 `n.fields.get("pitfall_when")` 的(`as_list`);每項 `glob:` 用 `PurePath(file_rel).match` 或 `fnmatch`、`content:` 用 `re.search(pat, file_content)`;任一命中 → `{node, matched_by}`。前綴分派;`content:` 空內容→跳。
- [ ] **Step 4: PASS**。
- [ ] **Step 5: Commit** `feat(impact): _match_incident_triggers(pitfall_when glob/content-regex)`

---

### Task 2: `lumos impact` 加 incidents 段 + 去重 + 讀被碰檔內容

**Files:** Modify `scripts/lumos`(`cmd_impact`);Test。

**Interfaces:** `lumos impact --json` 加頂層 `incidents:[{node,matched_by,contract,combo}]`;人讀加「相關事故」節。

- [ ] **Step 1: 失敗測試** — impact --json 有 `incidents` key;pitfall_when 命中的節點進 incidents;**去重**:某節點既被 body-inline-code 直接命中又 trigger 命中 → 只在 incidents 不在 direct;無 pitfall_when 架構圖 → incidents 空。
```python
def t_impact_incidents_section():
    # fixture:一節點 body 引用 code X(→ 本來 direct)且 pitfall_when glob 命中 X → 只列 incidents
    out = run_lumos_capture(["impact","--file","app/UserRepository.py","--repo",FIX,"--json"])
    d = json.loads(out)
    assert "incidents" in d
    inc_nodes = {x["node"] for x in d["incidents"]}
    direct_nodes = {x["node"] for x in d["direct"]}
    assert inc_nodes.isdisjoint(direct_nodes)   # 去重:不重複
```
- [ ] **Step 2: FAIL**。
- [ ] **Step 3: 實作** — 見設計 §4:`cmd_impact` 讀被碰檔內容(`--file` 絕對路徑讀盤;讀不到→空內容只 glob)→ `_match_incident_triggers` → `incidents` 段(contract/combo 復用 `_impact_contract`);**去重**:從 direct/indirect 移除已在 incidents 的 node。`--json` 加 key;人讀加「── 相關事故 ──」。
- [ ] **Step 4: PASS** + 真機 `lumos impact --file scripts/lumos --repo . --json` incidents 空(本圖無 pitfall_when)不回歸。
- [ ] **Step 5: Commit** `feat(impact): --json incidents 段 + trigger 去重 + 讀被碰檔內容`

---

### Task 3: impact hook 注入 incidents

**Files:** Modify `scripts/hooks/claude/impact-hook.py`;Test。

**Interfaces:** hook `build_additional_context` 納入 incidents 段;空 incidents 不加該段。

- [ ] **Step 1: 失敗測試** — impact_data 含非空 incidents → 注入的 additionalContext 有「相關事故」段;空 incidents → 無該段;全空(direct/indirect/incidents 皆空)→ 不注入。
```python
def t_impact_hook_incidents_inject():
    out = hook_run_with_impact({"direct":[],"indirect":[],"incidents":[{"node":"Issues/N1","matched_by":"glob:**/*Repo*","contract":None,"combo":False}]})
    j = json.loads(out)
    assert "相關事故" in j["hookSpecificOutput"]["additionalContext"] or "incident" in j["hookSpecificOutput"]["additionalContext"].lower()
    assert hook_run_with_impact({"direct":[],"indirect":[],"incidents":[]}) == ""  # 全空不注入
```
- [ ] **Step 2: FAIL**。
- [ ] **Step 3: 實作** — 見設計 §4:`build_additional_context` 加 incidents 段(節點 + matched_by + 合約標);`inject` 的「空集合不注入」判定納入 incidents(direct+indirect+incidents 皆空才不注入);指令文字沿用(動手前判)。
- [ ] **Step 4: PASS**。
- [ ] **Step 5: Commit** `feat(impact-hook): 注入 incidents 段(空則不加)`

---

### Task 4: e2e/回歸 + 架構圖回填

**Files:** Test `scripts/test_lumos.py`;架構圖(controller 回填)。

- [ ] **Step 1: 回歸測試** — 對現有無 `pitfall_when` 的真架構圖跑 `lumos impact --file scripts/lumos --repo . --json` → incidents 空、rc 不變、direct/indirect 不受影響。
```python
def t_impact_incidents_regression():
    d = json.loads(run_lumos_capture(["impact","--file","scripts/lumos","--repo",".","--json"]))
    assert d["incidents"] == []   # 本圖無 pitfall_when
```
- [ ] **Step 2: 確認行為**。
- [ ] **Step 3:** 全量 `python3 scripts/test_lumos.py` 0 failed;真機 smoke(暫造一個 pitfall_when 事故節點→impact 撈到→清理)。
- [ ] **Step 4: PASS**。
- [ ] **Step 5: Commit** `test(impact): incidents 回歸(無 pitfall_when 架構圖不誤傷)`

---

## 落地回填(controller)
寫 `Verification/2026-..._pitfalls事故觸發` plan_refs 回指;設計節點 TEST/status;`pitfalls-lint-integration_計劃` ④ 標 done → roadmap ①②③④ 全 done。文件 `lumos-project-notes`/CLAUDE.md 補 `pitfall_when` 欄位慣例(list、glob:/content: 前綴)。
