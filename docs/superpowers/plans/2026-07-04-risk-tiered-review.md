# risk-tiered-review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 風險分級審查強度——新模組 difficulty.py(四類關鍵詞、二值分級、零參數)+ wrapper 分級注入與收檔機械重驗(不信自報 converged)+ orchestrator-prompt ratchet 與 high 級關 fail-open + confidence report 呈現 tier。

**Architecture:** ① `governance/autonomous_loop/difficulty.py`(純函數:RISK_CLASSES/assess/assess_spec/params);② `autonomous-loop.sh` 選 gap 後 assess 注入 `__NEED__`/`__TIER__`/MAXR_EFF,收檔前以**自算 tier** 重跑 `loop status --gate` + high 級 cross_verdict 字串核對;③ orchestrator-prompt §1 ratchet(逐輪重跑 assess_spec、只升不降)+ §2.5c high 條文(degraded/endorsed-after-refute 不放行);④ confidence_report 簽名擴充呈現 tier/hits/自報對照紅標。

**Tech Stack:** Python 3 stdlib(re);bash;`scripts/test_autonomous_loop.py`(unittest)+ `scripts/test_lumos.py`(CLI harness)。

**Branch:** 在 `feat/risk-tiered-review` 分支上實作。

## Global Constraints

- stdlib only;difficulty.py 純函數零依賴、**二值確定性**(無權重/計分/閾值/隨機/時間依賴)。
- **RISK_CLASSES 四類詞面(spec 逐字)**:payment(金流/payment/stripe/billing/退款/refund/扣款)、external-send(寄送/送出/send/webhook/notify/LINE 推送/mail/簡訊/對外)、prod-irreversible(prod/production/遷移/migration/不可逆/DROP TABLE/DELETE FROM/上架)、self-governance(錨點/anchor verify/收斂判準/canary/審計閘/pre-push hook)。
- **assess_spec 操作定義(spec 定死)**:以 `##` 標題切分 → 黑名單剝除(標題子字串命中「方案評比/canary 相容性/誠實天花板/審計修正紀錄」)→ 防呆(剝除後節數<2 或字元<200 → 回退全文 assess 偏嚴+印告警)→ 剝反引號 inline-code token 與檔名路徑引用 → assess。「前提與既驗事實」節不入黑名單。
- **params 對映**:high→`{"need":3,"maxr":8}`、standard→`{"need":2,"maxr":6}`;high 的 maxr 由 wrapper 取 `max(維運 MAXR, 8)`(params 函數本身回常數)。
- **收檔守衛雙級都上**:standard 也重驗 `--need 2 --gate`;`$NEED_FINAL`=wrapper 對最終 spec 自算 assess_spec 與注入 NEED 取大者;rc≠0 → requeue+LINE 歸因「tier 守衛擋下」+exit 0(**errexit-safe**:`set -euo pipefail` 下用 `if ! …` 形)。
- **high 級 cross_verdict 核對**:自算 tier=high 且 result JSON `cross_verdict != "endorsed"`(含 degraded/endorsed-after-refute/空值)→ 不放行;standard 不核。
- **ratchet 只升不降**;escalate 投遞的是 K 與 §2.5c 條文,**cap 不可投遞**(維持已注入值,誠實收窄——spec r4-F4)。
- **不做**(spec YAGNI):不動 canary 類型/judge/辯方;分級無統計模型;不新增 CLI 旗標;不動 `loop status` 代碼(消費既有 `--need`/`--gate`)。
- **錨點注意**:`scripts/test_lumos.py`/`scripts/test_autonomous_loop.py` 皆 anchor——merge 回 main 後 push 前 `lumos anchor approve --note` 同批 commit(Task 6 收尾)。
- result JSON 增 4 純量鍵:`tier`/`tier_escalated`/`need`/`maxr`;**hits 不進 result JSON**(wrapper 本地重算,單一來源)。

---

### Task 1: difficulty.py 分級器 + 單元測試

**Files:**
- Create: `governance/autonomous_loop/difficulty.py`
- Test: `scripts/test_autonomous_loop.py`(新增 `TestDifficulty`)

**Interfaces:**
- Produces:`RISK_CLASSES: dict[str, list[str]]`;`assess(text) -> {"tier": "high"|"standard", "hits": [{"class","pattern","excerpt"}]}`;`assess_spec(md_text) -> 同 assess`;`params(tier) -> {"need": int, "maxr": int}`。Task 2/3/4 消費。

- [ ] **Step 1: Write the failing tests**

加到 `scripts/test_autonomous_loop.py`(檔尾 `unittest.main()` 前):

```python
class TestDifficulty(unittest.TestCase):
    def setUp(self):
        from autonomous_loop import difficulty
        self.d = difficulty

    def test_assess_hits_high(self):
        for kw, cls in (("接 stripe 收款", "payment"), ("金流對帳", "payment"),
                        ("執行 DROP TABLE 清理", "prod-irreversible"),
                        ("完成後寄送通知", "external-send")):
            r = self.d.assess(kw)
            self.assertEqual(r["tier"], "high", kw)
            self.assertIn(cls, [h["class"] for h in r["hits"]], kw)

    def test_assess_standard(self):
        r = self.d.assess("重構內部快取層,拆函數與改名,無外部行為變更")
        self.assertEqual(r["tier"], "standard")
        self.assertEqual(r["hits"], [])

    def test_assess_deterministic(self):
        t = "金流與寄送並存的文本"
        self.assertEqual(self.d.assess(t), self.d.assess(t))

    def test_assess_self_governance(self):
        r = self.d.assess("本改動調整 anchor verify 與收斂判準")
        self.assertEqual(r["tier"], "high")
        self.assertIn("self-governance", [h["class"] for h in r["hits"]])

    def test_params_mapping(self):
        self.assertEqual(self.d.params("high"), {"need": 3, "maxr": 8})
        self.assertEqual(self.d.params("standard"), {"need": 2, "maxr": 6})

    def test_assess_spec_blacklist_strip(self):
        md = ("# t\n- 狀態:草稿\n"
              "## 目標\n改內部排序邏輯。\n"
              "## 組件\n重構 sort 模組,純內部。\n"
              "## 誠實天花板\ncanary 與收斂判準的既有守衛不受影響。\n"
              "## 審計修正紀錄(design-loop)\nr1 canary caught。\n")
        self.assertEqual(self.d.assess_spec(md)["tier"], "standard")

    def test_assess_spec_title_variant(self):
        md = ("# t\n## 目標\n改內部排序。\n## 組件\n純內部重構。\n"
              "## 誠實天花板(v2 補)\ncanary 收斂判準。\n## 附:審計修正紀錄與備註\ncanary。\n")
        self.assertEqual(self.d.assess_spec(md)["tier"], "standard")

    def test_assess_spec_substantive_high(self):
        md = ("# t\n## 目標\n強化 anchor verify 與 pre-push hook 的接線。\n"
              "## 組件\n改守衛腳本。\n## 誠實天花板\n無。\n")
        self.assertEqual(self.d.assess_spec(md)["tier"], "high")

    def test_assess_spec_fallback_near_empty(self):
        md = "# t\n## 誠實天花板\n" + "金流" * 200 + "\n"
        self.assertEqual(self.d.assess_spec(md)["tier"], "high")  # 回退全文,偏嚴

    def test_assess_spec_strips_inline_code_and_filenames(self):
        md = ("# t\n## 目標\n更新 `架構圖即合約-對外論述.md` 的段落說明,內容為文檔措辭。\n"
              "## 組件\n見 架構圖即合約-對外論述.md 檔。\n## 其他\n無風險詞的內部整理。\n")
        self.assertEqual(self.d.assess_spec(md)["tier"], "standard")  # 檔名「對外」不得誤觸
```

- [ ] **Step 2: Run tests to verify fail**

Run: `python3 scripts/test_autonomous_loop.py 2>&1 | tail -3`
Expected: FAIL——`ImportError`/`ModuleNotFoundError: difficulty`。

- [ ] **Step 3: Implement difficulty.py**

Create `governance/autonomous_loop/difficulty.py`:

```python
"""風險分級器(risk-tiered-review):關鍵詞 → tier(high/standard)。
零依賴、純函數、二值確定性(無權重/計分/閾值)。量的是「表面類別」非難度——
分級是 proxy,漏網靠 canary/cross-family/人工 review 兜底(設計 doc 天花板 1)。
設計:docs/design/2026-07-03-risk-tiered-review.md。"""
import re

RISK_CLASSES = {
    "payment": ["金流", "payment", "stripe", "billing", "退款", "refund", "扣款"],
    "external-send": ["寄送", "送出", r"\bsend\b", "webhook", "notify",
                      "LINE 推送", r"\bmail\b", "簡訊", "對外"],
    "prod-irreversible": [r"\bprod\b", "production", "遷移", "migration",
                          "不可逆", "DROP TABLE", "DELETE FROM", "上架"],
    "self-governance": ["錨點", "anchor verify", "收斂判準", "canary",
                        "審計閘", "pre-push hook"],
}
_COMPILED = {cls: [re.compile(p, re.IGNORECASE) for p in pats]
             for cls, pats in RISK_CLASSES.items()}

_BLACKLIST = ("方案評比", "canary 相容性", "誠實天花板", "審計修正紀錄")
_INLINE_CODE = re.compile(r"`[^`\n]*`")
_FILENAME = re.compile(r"[\w\-./]+\.(?:md|py|sh|json|yml|yaml|txt)\b")


def assess(text):
    """任一類命中 → high;每類記首個命中(class/pattern/excerpt)。"""
    hits = []
    for cls, pats in _COMPILED.items():
        for pat in pats:
            m = pat.search(text)
            if m:
                s = max(0, m.start() - 20)
                hits.append({"class": cls, "pattern": pat.pattern,
                             "excerpt": text[s:m.end() + 20].replace("\n", " ")})
                break
    return {"tier": "high" if hits else "standard", "hits": hits}


def assess_spec(md_text):
    """spec 文本入口:## 切分 → 黑名單剝除樣板節(其餘含前提節一律保留)→
    防呆回退 → 剝 inline-code 與檔名 → assess。剝除方向=偏嚴(over-fire)。"""
    parts = re.split(r"(?m)^(## .*)$", md_text)
    kept = [parts[0]] if parts and parts[0].strip() else []
    n_sections = 0
    i = 1
    while i + 1 < len(parts) + 1 and i + 1 <= len(parts):
        if i + 1 >= len(parts):
            break
        title, body = parts[i], parts[i + 1]
        if not any(b in title for b in _BLACKLIST):
            kept.append(title + body)
            n_sections += 1
        i += 2
    corpus = "\n".join(kept)
    if n_sections < 2 or len(corpus) < 200:
        print("⚠ assess_spec: 剝除後餘文近空(節數<2 或字元<200),回退全文 assess(偏嚴)")
        corpus = md_text
    corpus = _INLINE_CODE.sub(" ", corpus)
    corpus = _FILENAME.sub(" ", corpus)
    return assess(corpus)


def params(tier):
    """high 的 maxr 語意=下限 8(max(維運 MAXR, 8) 由 wrapper 端整數比較實現)。"""
    return {"need": 3, "maxr": 8} if tier == "high" else {"need": 2, "maxr": 6}
```

- [ ] **Step 4: Run tests to verify pass + 回歸**

Run: `python3 scripts/test_autonomous_loop.py 2>&1 | tail -3`
Expected: OK(TestDifficulty 10 tests + 既有全綠)。
Run: `python3 scripts/test_lumos.py 2>&1 | tail -1`
Expected: `352 passed, 0 failed`(不受影響)。

- [ ] **Step 5: Commit**

```bash
git add governance/autonomous_loop/difficulty.py scripts/test_autonomous_loop.py
git commit -m "feat(loop): difficulty.py 風險分級器(四類關鍵詞/二值/assess_spec 黑名單剝除)"
```

---

### Task 2: wrapper 接線——分級注入 + 收檔機械重驗(`governance/autonomous-loop.sh`)

**Files:**
- Modify: `governance/autonomous-loop.sh`(三處:PROMPT_FILE 前插分級塊+sed 增佔位符;gets 行加 tier;dry-run 分支前插收檔守衛)
- Test: `scripts/test_lumos.py`(新增 `t_loop_gate_need3`,補 K=3 off-by-one 案)

**Interfaces:**
- Consumes:Task 1 的 `difficulty.assess/assess_spec/params`;既有 `$GAP_JSON`/`$MAXR`/`get()`/`log()`/requeue 膠水/line_notify 慣例;`lumos loop status --need N --gate --spec --repo`(既有 CLI)。
- Produces:shell 變數 `TIER`/`NEED`/`MAXR_EFF`/`TIER_RESULT`(Task 4 caller 用 `$TIER_RESULT`;佔位符 `__NEED__`/`__TIER__` 由 Task 3 落進 prompt)。

- [ ] **Step 1: Write the failing test(K=3 gate off-by-one)**

加到 `scripts/test_lumos.py`(`t_loop_gate` 之後):

```python
def t_loop_gate_need3():
    vault, repo, spec_ok, _ = _mk_gate_fixture()
    for sev, f in (("minor", 2), ("clean", 0)):
        run(vault, "canary", "record", "caught", "--loop", "k3",
            "--severity", sev, "--findings", str(f), expect_rc=0)
    r = run(vault, "loop", "status", "k3", "--need", "3",
            "--gate", "--spec", str(spec_ok), "--repo", str(repo))
    check("gate K=3: 僅 2 筆合格輪 rc=1(斷在 K-streak)",
          r.returncode == 1 and "K-streak" in r.stdout, r.stdout)
```

Run: `python3 scripts/test_lumos.py 2>&1 | grep "K=3"` → 先確認**通過**(此為既有 gate 行為的防回歸釘,非新功能;若 fail 即 gate 有 off-by-one bug,停下回報)。

- [ ] **Step 2: 分級注入塊(PROMPT_FILE 前)**

Edit `governance/autonomous-loop.sh`:

old:
```bash
PROMPT_FILE="$(mktemp)"
sed -e "s#__SCRATCH__#$SCRATCH#g" -e "s#__DATE__#$TODAY#g" -e "s#__MAXR__#$MAXR#g" \
    "$SCRIPT_DIR/autonomous_loop/orchestrator-prompt.md" > "$PROMPT_FILE"
```
new:
```bash
# ── tier 分級(risk-tiered-review):gap 文本 assess → 注入 NEED/TIER/MAXR_EFF ──
read -r TIER NEED < <(echo "$GAP_JSON" | python3 -c "
import sys, json; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import difficulty
g=json.load(sys.stdin)
a=difficulty.assess((g.get('weakness','') or '')+'\n'+(g.get('suggestion','') or ''))
p=difficulty.params(a['tier'])
print(a['tier'], p['need'])")
MAXR_EFF="$MAXR"
[ "$TIER" = "high" ] && MAXR_EFF="$(( MAXR > 8 ? MAXR : 8 ))"
log "tier 分級:$TIER(need=$NEED, maxr=$MAXR_EFF)"

PROMPT_FILE="$(mktemp)"
sed -e "s#__SCRATCH__#$SCRATCH#g" -e "s#__DATE__#$TODAY#g" -e "s#__MAXR__#$MAXR_EFF#g" \
    -e "s#__NEED__#$NEED#g" -e "s#__TIER__#$TIER#g" \
    "$SCRIPT_DIR/autonomous_loop/orchestrator-prompt.md" > "$PROMPT_FILE"
```

- [ ] **Step 3: gets 行加 tier 自報值**

old:
```bash
CROSS_VERDICT="$(get cross_verdict)"; CROSS_WORST="$(get cross_worst)"; CROSS_SUMMARY="$(get cross_summary)"
```
new:
```bash
CROSS_VERDICT="$(get cross_verdict)"; CROSS_WORST="$(get cross_worst)"; CROSS_SUMMARY="$(get cross_summary)"
TIER_RESULT="$(get tier)"
```

- [ ] **Step 4: 收檔守衛(機械脊椎,converged 路徑)**

old:
```bash
[ -n "$CROSS_VERDICT" ] && log "跨家族複核:$CROSS_VERDICT($CROSS_WORST)— $CROSS_SUMMARY"
if [ "$MODE" = "--dry-run" ]; then
```
new:
```bash
[ -n "$CROSS_VERDICT" ] && log "跨家族複核:$CROSS_VERDICT($CROSS_WORST)— $CROSS_SUMMARY"

# ── tier 收檔守衛:不信自報 converged——wrapper 自算 tier、以其 need 重驗 gate ──
TIER_FINAL="$(cd "$REPO" && python3 -c "
import sys; sys.path.insert(0,'governance')
from autonomous_loop import difficulty
print(difficulty.assess_spec(open('$SPEC').read())['tier'])")"
NEED_FINAL="$NEED"
if [ "$TIER_FINAL" = "high" ] && [ "$NEED_FINAL" -lt 3 ]; then NEED_FINAL=3; fi
if ! (cd "$REPO" && python3 scripts/lumos --vault "$SCRATCH/kg" loop status "$TOPIC" --need "$NEED_FINAL" --gate --spec "$SPEC" --repo "$REPO"); then
  log "tier 守衛擋下:自報收斂但 gate 重驗不過(自算 tier=$TIER_FINAL, need=$NEED_FINAL)"
  MSG="⚠ tier 守衛擋下:自報收斂但 gate 重驗不過(tier=$TIER_FINAL)" python3 -c "
import sys, os; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import line_notify
t='$(cat "$HOME/.config/ai-daily/line_token" 2>/dev/null)'
print('LINE', line_notify.send(line_notify.build_message('$TOPIC',os.environ['MSG'],None),t) if t else 'no-token')" || true
  RQ="$(echo "$GAP_JSON" | python3 -c "
import sys, json; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import gap_select
g=json.load(sys.stdin)
print(gap_select.requeue_unconverged('$SCRIPT_DIR/backlog.jsonl', g, '$SCRIPT_DIR/covered.jsonl'))
" 2>/dev/null || echo '?')"
  log "未收斂 gap 處置:$RQ(tier 守衛)"
  exit 0
fi
if [ "$TIER_FINAL" = "high" ] && [ "$CROSS_VERDICT" != "endorsed" ]; then
  log "tier 守衛擋下:high 級 cross_verdict=$CROSS_VERDICT 非乾淨 endorsed,不放行"
  MSG="⚠ tier 守衛擋下:high 級複核非乾淨 endorsed(=$CROSS_VERDICT)" python3 -c "
import sys, os; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import line_notify
t='$(cat "$HOME/.config/ai-daily/line_token" 2>/dev/null)'
print('LINE', line_notify.send(line_notify.build_message('$TOPIC',os.environ['MSG'],None),t) if t else 'no-token')" || true
  RQ="$(echo "$GAP_JSON" | python3 -c "
import sys, json; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import gap_select
g=json.load(sys.stdin)
print(gap_select.requeue_unconverged('$SCRIPT_DIR/backlog.jsonl', g, '$SCRIPT_DIR/covered.jsonl'))
" 2>/dev/null || echo '?')"
  log "未收斂 gap 處置:$RQ(tier 守衛/cross)"
  exit 0
fi

if [ "$MODE" = "--dry-run" ]; then
```

- [ ] **Step 5: 驗證 + Commit**

Run: `bash -n governance/autonomous-loop.sh`
Expected: 語法過。
Run: `grep -c "__NEED__\|__TIER__\|TIER_FINAL\|tier 守衛" governance/autonomous-loop.sh`
Expected: ≥6。
Run: `python3 scripts/test_lumos.py 2>&1 | tail -1`
Expected: `353 passed, 0 failed`(+1 K=3 案)。

```bash
git add governance/autonomous-loop.sh scripts/test_lumos.py
git commit -m "feat(loop): wrapper tier 分級注入 + 收檔機械重驗(不信自報 converged;high 級 cross_verdict 核對)"
```

---

### Task 3: orchestrator-prompt 條文(ratchet + high 條文 + 佔位符 + 輸出 4 鍵)+ 佔位符測試

**Files:**
- Modify: `governance/autonomous_loop/orchestrator-prompt.md`(五處)
- Test: `scripts/test_autonomous_loop.py`(新增 `TestPromptPlaceholders`)

**Interfaces:**
- Consumes:Task 2 注入的 `__NEED__`/`__TIER__` 佔位符語意;Task 1 的 assess_spec 呼叫形。
- Produces:prompt 散文契約。

- [ ] **Step 1: Write the failing test**

加到 `scripts/test_autonomous_loop.py`:

```python
class TestPromptPlaceholders(unittest.TestCase):
    def test_need_tier_placeholders(self):
        p = Path(__file__).resolve().parent.parent / "governance/autonomous_loop/orchestrator-prompt.md"
        t = p.read_text(encoding="utf-8")
        self.assertIn("__NEED__", t)
        self.assertIn("__TIER__", t)
        self.assertNotIn("--need 2 --gate", t)   # 防硬編回歸
        self.assertIn("tier_escalated", t)        # 輸出契約含 escalate 欄
```

Run: `python3 scripts/test_autonomous_loop.py 2>&1 | tail -3` → Expected: FAIL(`__NEED__` 不存在)。

- [ ] **Step 2: §2 開頭 tier 行**

old:
```
### 2. Design-loop(最多 __MAXR__ 輪,canary 限 a/b/c、禁 d)
```
new:
```
### 2. Design-loop(最多 __MAXR__ 輪,canary 限 a/b/c、禁 d)
本輪風險級:__TIER__(§1 尾 ratchet 可就地升級、只升不降;high 級:收斂 K 用注入的 __NEED__、§2.5c 走 high 條文)。
```

- [ ] **Step 3: 步驟 8 `--need 2` 改佔位符**

old(:43 行內):
```
loop status <topic> --need 2 --gate --spec
```
new:
```
loop status <topic> --need __NEED__ --gate --spec
```

- [ ] **Step 4: §1 尾補 ratchet 段**

old(§1 的知識同步影響 blockquote 之後、`### 2.` 之前——在該空行處插入):
```
> **知識同步影響(必填,防實作 drift)**
```
(此為定位子字串;在該整行 blockquote 段落**之後**插入新段:)
```
> **spec 層 ratchet(risk-tiered-review)**:草稿寫完後、以及**每輪折入後(步驟 7 尾)**重跑:`python3 -c "import sys;sys.path.insert(0,'<REPO>/governance');from autonomous_loop import difficulty;print(difficulty.assess_spec(open('__SCRATCH__/spec/__DATE__-<topic>.md').read())['tier'])"`(<REPO>=實際 repo 絕對路徑)。回 high 而本輪注入 tier=standard → **就地升級**:其後輪次收斂 K=3、§2.5c 走 high 條文;cap 維持已注入值(升級不可投遞 cap,誠實收窄——損失=escalate 輪少 2 輪預算,收檔守衛仍以 wrapper 自算 tier 重驗)。**只升不降**(注入 high、文本 assess 出 standard → 維持 high)。result JSON 記 `"tier":"high","tier_escalated":true`。
```

- [ ] **Step 5: §2.5c 補 high 級條文**

old(§2.5c 計票規則最後一個子彈 `parse_fallback==true` 該行之後、§2.5d 之前插入):
```
   - **high 級條文(risk-tiered-review;以 §2 開頭注入/ratchet 升級後的最終 tier 為準)**:`status==degraded` → **不放行**(`cross_verdict=degraded` 且 `converged:false`——高風險級不接受「複核缺席視同通過」,走 requeue 隔天再審);「全數被機械反證」→ **不構成綠燈**:視同一次 reject 回步驟 1 續審(cap 內)/撞 cap 停(`endorsed-after-refute` 在 high 級不放行);自動放行只剩乾淨 `endorsed` 一條路。standard 級:上列計票規則照舊、行為分毫不變。
```

- [ ] **Step 6: §3 輸出 JSON 增 4 鍵**

old(§3 輸出行內):
```
"cross_summary":"<單行摘要,無換行>","notes":
```
new:
```
"cross_summary":"<單行摘要,無換行>","tier":"high|standard","tier_escalated":true|false,"need":<生效 K>,"maxr":<生效 cap>,"notes":
```

- [ ] **Step 7: 驗證 + Commit**

Run: `python3 scripts/test_autonomous_loop.py 2>&1 | tail -3` → OK(TestPromptPlaceholders 過)。
Run: `grep -c "__NEED__\|__TIER__\|high 級條文\|ratchet" governance/autonomous_loop/orchestrator-prompt.md` → ≥5。

```bash
git add governance/autonomous_loop/orchestrator-prompt.md scripts/test_autonomous_loop.py
git commit -m "feat(loop): orchestrator ratchet + high 級關 fail-open + __NEED__/__TIER__ 佔位符 + 輸出 tier 四鍵"
```

---

### Task 4: confidence_report 呈現 tier/hits + wrapper caller

**Files:**
- Modify: `governance/autonomous_loop/confidence_report.py`(簽名擴充)
- Modify: `governance/autonomous-loop.sh`(REPORT_MD 呼叫點)
- Test: `scripts/test_autonomous_loop.py`(新增 `TestConfidenceReportTier`)

**Interfaces:**
- Consumes:Task 1 `difficulty.assess_spec`;Task 2 的 `$TIER_RESULT`/`$SPEC`。
- Produces:`build_report(canary_log, loop_id, residual_risks, tier=None, hits=None, reported_tier=None)`——**向後相容**(不傳 tier 輸出照舊)。

- [ ] **Step 1: Write the failing test**

```python
class TestConfidenceReportTier(unittest.TestCase):
    def test_tier_rendered_and_mismatch_flag(self):
        from autonomous_loop import confidence_report
        d = Path(tempfile.mkdtemp()); log = d / "c.jsonl"
        log.write_text('{"loop":"x","kind":"caught","severity":"clean","note":"r1"}\n',
                       encoding="utf-8")
        r = confidence_report.build_report(str(log), "x", ["天花板"], tier="high",
                                           hits=[{"class": "payment", "excerpt": "接 stripe 收款"}],
                                           reported_tier="standard")
        self.assertIn("tier=`high`", r)
        self.assertIn("payment", r)
        self.assertIn("紅標", r)
        r2 = confidence_report.build_report(str(log), "x", ["天花板"], tier="high",
                                            hits=[], reported_tier="high")
        self.assertNotIn("紅標", r2)
        r3 = confidence_report.build_report(str(log), "x", ["天花板"])
        self.assertNotIn("tier=", r3)   # 向後相容:不傳 tier 照舊
```

Run 確認 fail(TypeError: unexpected keyword)。

- [ ] **Step 2: 改 build_report**

old(函數簽名與 header 組裝):
```python
def build_report(canary_log, loop_id, residual_risks):
```
與
```python
    lines = [f"## 收斂可信度報告(loop={loop_id})", "", f"**共 {len(rows)} 輪:**", ""]
```
new:
```python
def build_report(canary_log, loop_id, residual_risks, tier=None, hits=None, reported_tier=None):
```
與
```python
    lines = [f"## 收斂可信度報告(loop={loop_id})", ""]
    if tier:
        mismatch = (f"(⚠ result JSON 自報 `{reported_tier}` ≠ 自算——紅標,查參數謊報)"
                    if reported_tier not in (None, "", tier) else "")
        lines.append(f"**風險級 tier=`{tier}`(wrapper 對最終 spec 自算)**{mismatch}")
        for h in (hits or []):
            lines.append(f"- hit `{h.get('class')}`:…{h.get('excerpt', '')}…")
        lines.append("")
    lines += [f"**共 {len(rows)} 輪:**", ""]
```

- [ ] **Step 3: wrapper caller 傳 tier**

Edit `governance/autonomous-loop.sh`。old:
```bash
REPORT_MD="$(cd "$REPO" && python3 -c "
import sys, json; sys.path.insert(0,'governance')
from autonomous_loop import confidence_report
print(confidence_report.build_report('$SCRATCH/.canary-log.jsonl','$TOPIC', json.loads('''$RESIDUAL''')))
")"
```
new:
```bash
REPORT_MD="$(cd "$REPO" && python3 -c "
import sys, json; sys.path.insert(0,'governance')
from autonomous_loop import confidence_report, difficulty
a=difficulty.assess_spec(open('$SPEC').read())
print(confidence_report.build_report('$SCRATCH/.canary-log.jsonl','$TOPIC', json.loads('''$RESIDUAL'''),
      tier=a['tier'], hits=a['hits'], reported_tier='$TIER_RESULT'))
")"
```

- [ ] **Step 4: 驗證 + Commit**

Run: `python3 scripts/test_autonomous_loop.py 2>&1 | tail -3` → OK。
Run: `bash -n governance/autonomous-loop.sh` → 過。

```bash
git add governance/autonomous_loop/confidence_report.py governance/autonomous-loop.sh scripts/test_autonomous_loop.py
git commit -m "feat(loop): confidence report 呈現 tier/hits + 自報 tier 對照紅標"
```

---

### Task 5: 知識同步 — methodology ×2 + design-loop SKILL 軟建議

**Files:**
- Modify: `docs/methodology/架構圖即合約.md`(自主迭代 loop 節的屬性表加一列)
- Modify: `docs/methodology/架構圖即合約-對外論述.md`(「機器點收」段後插白話段)
- Modify: `skills/lumos-design-loop/SKILL.md`(硬閘行後補軟建議一句)

- [ ] **Step 1: 架構圖即合約.md 自主 loop 表加列**

old(自主迭代 loop 節屬性表內):
```
| 防 drift | spec 必填「知識同步影響」(列此改動影響哪些論述/skills),人放行時一併更新知識——架構圖即合約(知識跟實作走)套在 loop 自己身上 |
```
new:
```
| 風險分級審查(2026-07-04) | 審查強度跟風險面走:difficulty.py 四類關鍵詞(金流/對外寄送/prod 不可逆/守衛面)零參數二值分級——high 級 K=3/cap≥8/關 fail-open(複核缺席不放行、endorsed-after-refute 不算綠燈);**收檔由 wrapper 自算 tier 機械重驗 gate,不信 orchestrator 自報 converged**。分級是 proxy 非難度量測,假陽性偏嚴方向;RHB 病灶(難題放水)只買到更多次揮棒,縱深非解藥 |
| 防 drift | spec 必填「知識同步影響」(列此改動影響哪些論述/skills),人放行時一併更新知識——架構圖即合約(知識跟實作走)套在 loop 自己身上 |
```

- [ ] **Step 2: 對外論述插白話段**

old(「機器點收」段尾):
```
一句話:**說「審乾淨了」,得拿機器點收過的證據,不是拿「大家都同意」。**
```
new:
```
一句話:**說「審乾淨了」,得拿機器點收過的證據,不是拿「大家都同意」。**

審查的力氣也不再齊頭式平分。研究實測過一個陰險的現象:題目越難、越錯不起,AI 反而越容易對自己放水抄捷徑——等於在最容易出事的地方派最少的警衛。所以現在進門先分級:碰錢的、對外發東西的、動到守衛系統本身的,機器自動多審一輪、關掉所有寬容通道(複核缺席不算過、辯解成功也不算過,只有乾乾淨淨的通過才放行);無關痛癢的照走快速通道。而且收工時外層腳本會**自己重新分級、自己重驗一次**——AI 謊報「這題很簡單」也拉不低它要過的門檻。
```

- [ ] **Step 3: design-loop SKILL 軟建議**

old(:12 硬閘行尾):
```
lumos 擋不住「不跑就實作」——靠你記得調用 + 誠實。
```
new:
```
lumos 擋不住「不跑就實作」——靠你記得調用 + 誠實。**高風險 spec(金流/對外寄送/prod 不可逆/守衛面)建議 `--need 3`**(對齊自動 loop 的 risk-tiered-review 分級;手動 loop 無機械分級,靠你自判)。
```

- [ ] **Step 4: 驗證 + Commit**

Run: `grep -c "風險分級\|分級" docs/methodology/架構圖即合約.md docs/methodology/架構圖即合約-對外論述.md skills/lumos-design-loop/SKILL.md` → 三檔各 ≥1。

```bash
git add docs/methodology/架構圖即合約.md docs/methodology/架構圖即合約-對外論述.md skills/lumos-design-loop/SKILL.md
git commit -m "docs(sync): risk-tiered-review 知識同步——loop 表分級列 + 對外白話 + SKILL 軟建議"
```

---

### Task 6: 架構圖節點 + 收尾(controller 自跑)

**Files:**
- Create: `docs/lumos-toolchain-knowledge/Systems/risk-tiered-review.md`
- Create: `docs/lumos-toolchain-knowledge/Verification/2026-07-04_risk-tiered-review.md`
- Modify(收尾): `governance/anchor-baseline.json`(merge 後 approve——本分支動了兩個測試檔錨點)

> 鐵則:只建這兩個節點;lint ×2 + doctor 0 issues;merge 後 push 前 `lumos anchor approve --note` 同批 commit。

- [ ] **Step 1: Systems 節點**(FLOW=gap assess→注入→ratchet 逐輪→收檔自算重驗→high 級 cross 核對;KEY=零參數二值/黑名單剝除+防呆回退/只升不降/cap 不可投遞/不信自報 converged;誠實天花板 6 條全收;decisions=方案 A vs RHB 硬化、黑名單 vs 白名單、留痕錨——引用 spec 對應節)
- [ ] **Step 2: Verification 節點**(valid_under=RISK_CLASSES 詞表+params 對映+wrapper 接線形+prompt 佔位符;revalidate_when=改詞表/改黑名單/改 params/改收檔守衛;TEST 行記實際測試數)
- [ ] **Step 3: lint ×2 + doctor 0 issues + commit;merge 回 main 後:`lumos anchor approve --note "risk-tiered-review:測試 runner 更新"` + baseline 同批 commit + push**

---

## Self-Review

**Spec coverage**:組件 ①(RISK_CLASSES/assess/assess_spec 含黑名單+前提節保留+防呆+inline-code/檔名剝除/params)→ Task 1;組件 ②(注入+MAXR_EFF 下限 8+收檔重驗+NEED_FINAL 取大+cross_verdict 字串核對+errexit-safe+LINE 歸因)→ Task 2;組件 ③(ratchet 逐輪+只升不降+cap 不可投遞)→ Task 3 Step 4;組件 ④(high 級 degraded/endorsed-after-refute 不放行、standard 分毫不變)→ Task 3 Step 5;組件 ⑤(result JSON 4 純量鍵、hits 不進 JSON、report tier/hits/紅標)→ Task 3 Step 6 + Task 4;測試策略 8 案 → 案1-5(TestDifficulty)、案6(TestPromptPlaceholders)、案7(t_loop_gate_need3)、案8(兩套件回歸);知識同步 7 列 → Task 3(prompt)、Task 2(wrapper)、Task 5(methodology×2+SKILL)、Task 4(report)、Task 6(KG);memory 由 controller 收尾。✓

**Placeholder scan**:Task 6 為 controller 內容要點清單(既例模式);其餘完整 old/new 與代碼。✓

**Type consistency**:`assess`/`assess_spec` 回傳 shape 與測試斷言一致;`params` dict 鍵 need/maxr ↔ wrapper `p['need']`;`build_report` 新簽名 ↔ caller kwargs ↔ 測試;佔位符 `__NEED__`/`__TIER__` Task 2 sed ↔ Task 3 prompt ↔ TestPromptPlaceholders。✓
