# Cross-Family Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** autonomous loop 收斂放行前,多一道 qwen3-max 跨家族複核補 opus 同門盲點;API 不可用則 degrade 回 opus 放行並標註。

**Architecture:** 新建純函數模組 `cross_audit.py`(urllib 調 DashScope 國際 endpoint,回 status 三態),由 orchestrator-prompt 新增的「步驟 9」在收斂時調用、把結果寫成 §3 result JSON 三個扁平欄位;autonomous-loop.sh 用既有 `get()` 取三欄,走收斂/未收斂兩分支的 log + LINE。confidence_report / build_report 完全不碰。

**Tech Stack:** Python 3(僅標準庫 urllib,無第三方依賴)、bash、unittest(`scripts/test_autonomous_loop.py`)。

## Global Constraints

- **$0 OAuth 不破例外**:本機制是唯一的付費 API 例外,key 存 `~/.config/ai-daily/qwen_api_key`(單行、不入 repo、人手放置);讀不到 → degraded/no_key。
- **調用方式**:`python3 -c "import sys;sys.path.insert(0,'$REPO/governance');from autonomous_loop import cross_audit;..."`(絕對路徑版)。**禁用 `python3 -m`**(governance/ 頂層無 `__init__.py`、非 package)。
- **無第三方依賴**:只用標準庫 urllib(與既有模組一致)。
- **endpoint/model**:`https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions`、`qwen3-max`、`temperature=0.2`。
- **不改**:`confidence_report.py` / `build_report` / `scripts/lumos` 原語 / judge-severity-gate / canary 流程。
- **測試驗收**:`python3 scripts/test_autonomous_loop.py` 全綠且總數 ≥ 原 16。
- **放行=人 merge,絕不自動**;degrade 為 fail-open(API 掛不卡死 loop)。

---

### Task 1: `cross_audit.py` 模組 + 單元測試(TDD 核心)

**Files:**
- Create: `governance/autonomous_loop/cross_audit.py`
- Test: `scripts/test_autonomous_loop.py`(在既有檔末加 `TestCrossAudit` class)

**Interfaces:**
- Produces: `run_cross_audit(spec_text, canary_log_path, loop_id, ground_truth, key_path="~/.config/ai-daily/qwen_api_key", model="qwen3-max", timeout=120, temperature=0.2) -> dict`
  - 回傳三態:
    - `{"status":"ok","worst_severity":"<clean|minor|major|blocker>","findings":str,"usage":dict}`
    - `{"status":"degraded","worst_severity":None,"reason":"no_key"}`
    - `{"status":"degraded","worst_severity":None,"reason":"http_<code>"|"timeout"|"error:..."}`
- Produces(模組私有,供測試):`_parse_worst(text) -> str`(正則抓「最嚴重 severity = X」,抓不到掃內文最高 severity,全無 → "clean")

- [ ] **Step 1: 寫失敗測試 — no_key 路徑**

在 `scripts/test_autonomous_loop.py` 末尾新增(沿用檔頭既有 `import sys; sys.path.insert(0,'governance')`):

```python
class TestCrossAudit(unittest.TestCase):
    def setUp(self):
        self.d = Path(tempfile.mkdtemp())
        self.canary = self.d / ".canary-log.jsonl"
        self.canary.write_text(
            '{"loop":"x","kind":"caught","severity":"clean","note":"r1"}\n', encoding="utf-8")

    def test_no_key_returns_degraded(self):
        from autonomous_loop import cross_audit
        r = cross_audit.run_cross_audit("spec", str(self.canary), "x", "gt",
                                        key_path=str(self.d / "nonexistent_key"))
        self.assertEqual(r["status"], "degraded")
        self.assertEqual(r["reason"], "no_key")
        self.assertIsNone(r["worst_severity"])
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd /Users/enzo/harness/lumos-toolchain && python3 scripts/test_autonomous_loop.py -k TestCrossAudit 2>&1 | tail -5`
Expected: FAIL — `ModuleNotFoundError: No module named 'autonomous_loop.cross_audit'`

- [ ] **Step 3: 寫 cross_audit.py(完整實作)**

```python
import json, os, re, urllib.request, urllib.error
from pathlib import Path

ENDPOINT = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions"
_SEV_ORDER = {"clean": 0, "minor": 1, "major": 2, "blocker": 3}


def _parse_worst(text):
    m = re.search(r"最嚴重\s*severity\s*=\s*(clean|minor|major|blocker)", text)
    if m:
        return m.group(1)
    found = [s for s in _SEV_ORDER if s in text]
    return max(found, key=lambda s: _SEV_ORDER[s]) if found else "clean"


def _read_evidence(canary_log_path, loop_id):
    p = Path(canary_log_path)
    if not p.exists():
        return ""
    out = []
    for line in p.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        r = json.loads(line)
        if r.get("loop") == loop_id:
            out.append(f"{r.get('kind')}/{r.get('severity')}: {r.get('note', '')}")
    return "\n".join(out)


def run_cross_audit(spec_text, canary_log_path, loop_id, ground_truth,
                    key_path="~/.config/ai-daily/qwen_api_key",
                    model="qwen3-max", timeout=120, temperature=0.2):
    kp = Path(os.path.expanduser(key_path))
    if not kp.exists():
        return {"status": "degraded", "worst_severity": None, "reason": "no_key"}
    key = kp.read_text(encoding="utf-8").strip()
    evidence = _read_evidence(canary_log_path, loop_id)
    prompt = (
        "你是獨立設計審計員。基於提供的真實代碼審以下 spec,逐節找洞"
        "(未定義詞/壞引用/不一致/矛盾/可執行性 gap),每條標 severity。\n"
        f"=== 收斂證據(逐輪)===\n{evidence}\n"
        f"=== ground-truth 真實代碼片段 ===\n{ground_truth}\n"
        f"=== 待審 SPEC ===\n{spec_text}\n"
        "最後一行輸出「最嚴重 severity = <clean|minor|major|blocker>」。")
    payload = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": temperature,
    }).encode("utf-8")
    req = urllib.request.Request(
        ENDPOINT, data=payload,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.load(resp)
    except urllib.error.HTTPError as e:
        return {"status": "degraded", "worst_severity": None, "reason": f"http_{e.code}"}
    except Exception as e:
        reason = "timeout" if "timed out" in str(e).lower() else f"error:{e}"
        return {"status": "degraded", "worst_severity": None, "reason": reason}
    findings = data["choices"][0]["message"]["content"]
    return {"status": "ok", "worst_severity": _parse_worst(findings),
            "findings": findings, "usage": data.get("usage", {})}
```

- [ ] **Step 4: 跑 no_key 測試確認通過**

Run: `python3 scripts/test_autonomous_loop.py -k TestCrossAudit 2>&1 | tail -3`
Expected: OK(1 test)

- [ ] **Step 5: 加 ok / 防呆 / degraded 測試(mock urllib,不真打 API)**

在 `TestCrossAudit` 內加(用 `unittest.mock.patch`;檔頭若無 `from unittest import mock` 則補):

```python
    def _mock_resp(self, content):
        body = json.dumps({"choices": [{"message": {"content": content}}],
                           "usage": {"total_tokens": 1}}).encode()
        cm = mock.MagicMock()
        cm.__enter__.return_value.read.return_value = body
        cm.__enter__.return_value = io.BytesIO(body)
        return cm

    def _run_with_key(self, urlopen_side):
        kf = self.d / "key"; kf.write_text("sk-test", encoding="utf-8")
        from autonomous_loop import cross_audit
        with mock.patch.object(cross_audit.urllib.request, "urlopen", side_effect=urlopen_side):
            return cross_audit.run_cross_audit("spec", str(self.canary), "x", "gt", key_path=str(kf))

    def test_ok_parses_declared_severity(self):
        body = json.dumps({"choices":[{"message":{"content":"逐節...\n最嚴重 severity = minor"}}],
                           "usage":{}}).encode()
        r = self._run_with_key(lambda *a, **k: io.BytesIO(body))
        self.assertEqual(r["status"], "ok")
        self.assertEqual(r["worst_severity"], "minor")

    def test_ok_blocker(self):
        body = json.dumps({"choices":[{"message":{"content":"最嚴重 severity = blocker"}}],"usage":{}}).encode()
        r = self._run_with_key(lambda *a, **k: io.BytesIO(body))
        self.assertEqual(r["worst_severity"], "blocker")

    def test_ok_no_format_scans_highest(self):
        body = json.dumps({"choices":[{"message":{"content":"有個 minor,也有個 major 問題"}}],"usage":{}}).encode()
        r = self._run_with_key(lambda *a, **k: io.BytesIO(body))
        self.assertEqual(r["worst_severity"], "major")  # 無宣告行 → 掃內文最高

    def test_http_error_degraded(self):
        def boom(*a, **k):
            raise urllib.error.HTTPError("u", 403, "forbidden", {}, None)
        r = self._run_with_key(boom)
        self.assertEqual(r["status"], "degraded")
        self.assertEqual(r["reason"], "http_403")
        self.assertIsNone(r["worst_severity"])

    def test_timeout_degraded(self):
        def boom(*a, **k):
            raise urllib.error.URLError("timed out")
        r = self._run_with_key(boom)
        self.assertEqual(r["status"], "degraded")
        self.assertEqual(r["reason"], "timeout")
```

檔頭 import 區補(若缺):`import io`、`import urllib.error`、`from unittest import mock`。

- [ ] **Step 6: 跑全部 cross_audit 測試確認通過**

Run: `python3 scripts/test_autonomous_loop.py -k TestCrossAudit 2>&1 | tail -3`
Expected: OK(6 tests)

- [ ] **Step 7: 跑完整回歸確認 ≥ 原 16 全綠**

Run: `python3 scripts/test_autonomous_loop.py 2>&1 | tail -3`
Expected: `Ran 22 tests ... OK`(原 16 + 新 6)

- [ ] **Step 8: Commit**

```bash
git add governance/autonomous_loop/cross_audit.py scripts/test_autonomous_loop.py
git commit -m "feat(cross-audit): cross_audit.py qwen3-max 跨家族複核模組 + 6 單元測試

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: orchestrator-prompt.md 新增步驟 9 + §3 三扁平欄位

**Files:**
- Modify: `governance/autonomous_loop/orchestrator-prompt.md`(§2 步驟 8 後加步驟 9;§3 輸出 JSON 加三欄)

**Interfaces:**
- Consumes: Task 1 的 `run_cross_audit`(經 `python3 -c sys.path.insert` 絕對路徑版調用)
- Produces: orchestrator §3 result JSON 多出 `cross_verdict` / `cross_worst` / `cross_summary` 三頂層欄位(供 Task 3 的 `get()` 讀)

- [ ] **Step 1: 在 §2 步驟 8 後新增步驟 9(覆寫步驟 8 終止語意)**

在 `### 2. Design-loop` 的步驟 8 後、`### 3. 輸出` 前插入:

```markdown
9. **跨家族複核(放行前,只在步驟 8 判定收斂時做一次;覆寫步驟 8 的「則停」)**:
   a. 取材:把本 spec 引用到的真實檔案/符號 grep/Read 出來(你步驟 3 查證時已查過),整理成 ground-truth 片段。
   b. 調 `python3 -c "import sys;sys.path.insert(0,'<REPO>/governance');from autonomous_loop import cross_audit,json;print(json.dumps(cross_audit.run_cross_audit(open('<spec>').read(), '__SCRATCH__/.canary-log.jsonl', '<topic>', '''<ground_truth>''')))"`(絕對路徑版;`<REPO>` 用實際 repo 路徑)。
   c. 讀回傳 status / worst_severity,判 cross_verdict:
      - `status==degraded` → `cross_verdict=degraded`、收斂放行(fail-open)。
      - `status==ok` 且 worst_severity ∈ {clean,minor} → `cross_verdict=endorsed`、收斂放行。
      - `status==ok` 且 worst_severity ∈ {major,blocker} → 把 qwen findings 當新一輪 audit:你自己 grep 驗證每條(真的折進 spec、誤報在審計紀錄標反證);`cross_reject_count += 1`,回步驟 1 續審。`cross_reject_count` 達 2 → 停、不放行、`cross_verdict=disputed`。
   d. cross_summary:一句話單行摘要(無換行),供 log/LINE。
```

- [ ] **Step 2: 在 §3 輸出 JSON schema 加三欄**

把 `### 3. 輸出` 的 JSON 範例改為(在既有欄位後加三欄,disputed 時 `converged` 填 false):

```json
{"topic":"<topic>","spec_path":"...","loop_id":"<topic>","converged":true|false,"skipped":false,"rounds":<N>,"cross_verdict":"endorsed|degraded|disputed","cross_worst":"<severity或空>","cross_summary":"<單行摘要>","notes":"..."}
```
並加一句:`disputed 必伴 converged:false(才走得進 wrapper 未收斂分支)`。

- [ ] **Step 3: 自洽性檢查(無單元測,人讀)**

Run: `grep -nE "步驟 9|cross_verdict|cross_worst|cross_summary" governance/autonomous_loop/orchestrator-prompt.md`
Expected: 步驟 9 存在、§3 三欄齊;確認步驟 9 的調用用絕對路徑版、未用 `python3 -m`。

- [ ] **Step 4: Commit**

```bash
git add governance/autonomous_loop/orchestrator-prompt.md
git commit -m "feat(cross-audit): orchestrator-prompt 步驟 9 跨家族複核 + §3 三扁平欄位

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: autonomous-loop.sh 取三欄位 + 兩分支 log/LINE

**Files:**
- Modify: `governance/autonomous-loop.sh`(L59 附近取三欄;L77-85 未收斂分支;L87 後收斂放行分支)

**Interfaces:**
- Consumes: Task 2 的 §3 三欄 `cross_verdict` / `cross_worst` / `cross_summary`(經既有 `get()` L58 讀)

- [ ] **Step 1: 取三欄 + strip 換行(在 L59 既有 `get` 區附近)**

在 `SPEC="$(get spec_path)"` 那組之後加:

```sh
CROSS_VERDICT="$(get cross_verdict)"
CROSS_WORST="$(get cross_worst)"
CROSS_SUMMARY="$(get cross_summary)"
CROSS_SUMMARY="${CROSS_SUMMARY//$'\n'/ }"   # F3 防破版:換行→空格
```

- [ ] **Step 2: 收斂放行分支加跨家族訊息(L87 後、build_report 之後)**

在收斂分支 `log "完成。"` 之前加:

```sh
[ -n "$CROSS_VERDICT" ] && log "跨家族:$CROSS_VERDICT($CROSS_WORST)— $CROSS_SUMMARY"
```
並把 `$CROSS_VERDICT/$CROSS_SUMMARY` 併進該分支既有 LINE notify 的 message 字串(endorsed/degraded)。

- [ ] **Step 3: 未收斂分支依 verdict 區分文案(L77-85)**

把 L77-85 未收斂分支的 notify message 改為依 `$CROSS_VERDICT` 區分:

```sh
if [ "$CROSS_VERDICT" = "disputed" ]; then
  MSG="⚠ 跨家族否決(qwen 持續異議):$CROSS_SUMMARY"
else
  MSG="⚠ 今日 spec 未收斂、未放行"
fi
```
用 `$MSG` 取代原硬編碼「撞 cap」字串傳給 line_notify。

- [ ] **Step 4: 語法檢查**

Run: `bash -n governance/autonomous-loop.sh && echo OK`
Expected: `OK`

- [ ] **Step 5: 人工驗 dry-run(無 key → degraded 路徑)**

Run: `./governance/autonomous-loop.sh --dry-run 1 2>&1 | grep -iE "跨家族|degraded" | head`
Expected: 因 `~/.config/ai-daily/qwen_api_key` 未放置,orchestrator 跑 cross_audit 得 degraded,log 出現「跨家族:degraded」(或該輪未到放行則無此行——確認不報錯即可)。

- [ ] **Step 6: Commit**

```bash
git add governance/autonomous-loop.sh
git commit -m "feat(cross-audit): autonomous-loop.sh 取三扁平欄位 + 收斂/未收斂兩分支 log+LINE

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: 知識同步(放行 PR 時一併,架構圖即合約)

**Files:**
- Modify: `docs/methodology/架構圖即合約.md`(自主 loop 段補跨家族複核)
- Modify: `docs/methodology/架構圖即合約-對外論述.md`(對外白話段補一句)
- Modify: `docs/design/2026-06-20-autonomous-iteration-loop.md`(§放行閘補步驟 9 + degrade)
- Modify: memory `autonomous-iteration-loop`(放行閘加跨家族複核)

- [ ] **Step 1: 方法論(技術)補一段**

在 `docs/methodology/架構圖即合約.md` 自主 loop 自節,補:「放行前跨家族複核(qwen3-max)= 對抗同門偏心的具體機制:opus 取材餵料、qwen 跨家族判,disputed 退回 opus 驗證,degrade fail-open。」

- [ ] **Step 2: 對外論述補白話一句**

在 `docs/methodology/架構圖即合約-對外論述.md` 對外段補:「loop 放行前,由『不同家族的 AI』再看一眼——降低同一家族的共同盲點。」

- [ ] **Step 3: autonomous-iteration-loop spec 放行閘補步驟 9**

在 `docs/design/2026-06-20-autonomous-iteration-loop.md` §放行閘,補「收斂後、放行前的 qwen 跨家族複核步驟(endorsed/degraded 放行、disputed 退回)+ degrade fail-open」。

- [ ] **Step 4: 更新 memory**

更新 `~/.claude/.../memory/autonomous-iteration-loop.md`:放行閘加跨家族複核(gap[4] 的解、前提『換家族做不到』已被 qwen API 破);連結 `[[canary-loop-reliability-varies-by-spec]]`。

- [ ] **Step 5: Commit**

```bash
git add docs/methodology/ docs/design/2026-06-20-autonomous-iteration-loop.md
git commit -m "docs(cross-audit): 知識同步——兩篇論述 + autonomous-loop spec 放行閘補跨家族複核

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## 啟用前置(人手,非實作步驟)

1. 放 key:`echo 'sk-...' > ~/.config/ai-daily/qwen_api_key`(不入 repo)。
2. 至 Model Studio console 確認帳號有付費額度(免費 tier 可能靜默耗盡 → degrade)。
3. 觀察數日 dry-run 的跨家族 log,品質達標再考慮接 `--pr`。
