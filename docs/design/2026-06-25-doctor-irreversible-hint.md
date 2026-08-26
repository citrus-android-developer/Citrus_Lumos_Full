# 設計:doctor Check H — 漏標可逆性提醒(diff 碰 prod/外部 API/寄送 → 主動提示)

- 日期:2026-06-25
- 狀態:草稿(design-loop 進行中)
- 動機來源:2026-06-22 AI 治理日報 gap:「判動作可不可逆」若全靠人想到,漏標一個不可逆動作=靜默放行危險操作。補 doctor 偵測疑似不可逆的 diff 行、提示「是否漏標 ★IRREVERSIBLE★」。
- loop_id:doctor-irreversible-hint

## 目標(一句話)

doctor 新增 **Check H** section:掃 git diff 裡碰 prod/外部 API/寄送/破壞性 DB 操作的 +lines,用 `warn_soft` 提示「這裡是不是漏標 ★IRREVERSIBLE★?」——把「全靠人想到」改成「機器提醒人想」。

## 前提與既驗事實

以下均已 grep/Read 確認(scripts/lumos 真實 code):

- **`run_doctor` 簽名**(`scripts/lumos:357`): `run_doctor(env, strict, color, suggest=False, ci=False)` — 函數直接讀 env(含 vault 路徑)。
- **`warn_soft(lines, head, advice=None)`**(`scripts/lumos:381`):印出但不動 `issues`、不影響 rc——本 Check 唯一合法 warn 函數。**巢狀在 `run_doctor` 內**,非 module-level。
- **`section(idx, title)`**(`scripts/lumos:366`):印 `[{idx}]` 格式。**巢狀在 `run_doctor` 內**。既有字母 G/L/C/T/R/S/K 已佔用(`scripts/lumos:491-689`)。**`H`** 空著 → Check H。
- **subprocess import 模式**(`scripts/lumos:339,2298,2939,2999`):全檔 `import subprocess` 都是**函數內 lazy import**。**module-level 無 subprocess**,只有 argparse/re/sys/time/unicodedata/defaultdict/Path(`L28-34`)。module-level helper 若不自帶 `import subprocess` → 立即 NameError。**[r1-F1]helper 內必須自己 `import subprocess`**。
- **git diff 範圍與 cwd**(`scripts/lumos:341`,辯方 r2-F1 查證):傳入 `cwd=str(env.vault)`(子目錄)時,`git diff HEAD~1..HEAD` / `git diff --staged` 仍掃全 repo——git diff 無 pathspec 時範圍永遠是整個 repo,cwd 僅影響 relative pathspec 解析。**[r2-F1 辯方反證]cwd=str(env.vault) 是正確且確定性行為,不是「湊巧」**。
- **可逆性軸函數群聚**(`scripts/lumos:991-1036`):L992 `CHECKPOINT_RE`/L993 `IRREVERSIBLE_RE`/L994 `ROLLBACK_REF_RE`/L995 `GUARD_REF_RE` 接著 L998-L1032 各 reversibility_* helper。**[r2-F2 辯方反證:正確放置=新常數+新 helper 都放 L993 可逆性軸群,與現有 run_doctor (L357) 在呼叫時解析、前向引用符合本檔既有慣例]**。
- **Check R 目前只驗「有沒有標」**(`scripts/lumos:619-642`):不偵測漏標;Check H 是互補——R 守「有標要合規」,H 提醒「沒標但可能需要」。
- **插入點**:Check S 的 `print()` @L685;L686 空行;L687-688 是 Check K doc 註解;`section("K")` @L689。Check H 插在 L685(print())之後、L687 之前。

## 邊界 / 非目標(YAGNI)

- NOPE **絕不 hard block**(不計 `issues`、只 `warn_soft`):Check H 是「摩擦地板」提醒,不是合規守衛。
- NOPE **不解析 graph 判斷哪個 Systems 節點對應**:pattern match 字面比對,跨 code→graph 映射在 v1 成本>效益。
- NOPE **不掃整個 repo,只掃 diff 的 + 行**:減低噪音。
- NOPE **不在純互動 `lumos doctor`(無 `--ci`)時跑**:只在 `ci=True` 執行。
- NOPE **不偵測刪除行(`-` lines)**:刪 prod 呼叫通常是減少不可逆。
- NOPE **不維護 pattern 設定檔**:v1 hardcode;可設定留 v2。

## 方案選擇(自行決策)

| 方案 | 描述 | 結論 |
|---|---|---|
| A) regex on raw diff `+` 行 | 字面 pattern,soft warn,整合進 doctor | **採用** |
| B) A + 跨 graph 節點比對 | 找 `[test:]` link 到被改檔 Systems 節點 | **否決**(大量 Systems 無 `[test:]`→靜默漏提) |
| C) LLM 判斷每條 diff 行 | LLM 語義判可逆性 | **否決**(gap 的 weakness——LLM 判斷無形式保證) |

**採用 A**:soft reminder 的價值在「觸發思考」,不在「精確鎖定節點」;維持「方法論工具靠確定性機制、不靠 LLM 自判」原則。

## 架構:新增 Check H section

### 放置位置(r2-F2 修正)

**IRREVERSIBLE_HINT_PATTERNS 常數**與 **`_scan_diff_for_irreversible_hints(cwd)` helper** 都放在 **L993 可逆性軸群** (`IRREVERSIBLE_RE` 附近),不放 `run_doctor` 之前。理由:現有可逆性軸已有 CHECKPOINT_RE/IRREVERSIBLE_RE/ROLLBACK_REF_RE/GUARD_REF_RE(L992-995)及 helper(L998-1032);run_doctor 在 L357 呼叫定義在 L1008+ 的 helper 是本檔既有穩定慣例(前向引用在模組載入後呼叫時解析)。

### IRREVERSIBLE_HINT_PATTERNS(新常數,L993 可逆性軸群)

```python
IRREVERSIBLE_HINT_PATTERNS = [
    re.compile(r"\bprod[._\-/]|production\b", re.I),
    re.compile(r"smtplib|sendmail|send_mail\b|\.send_message\b", re.I),
    re.compile(r"requests\.post\b|httpx\.post\b", re.I),
    re.compile(r"boto3\.(client|resource)\s*\(", re.I),
    re.compile(r"\bstripe\.\b|\btwilio\.\b|\bsendgrid\.\b", re.I),
    re.compile(r"\bDROP\s+TABLE\b|\bDELETE\s+FROM\b", re.I),
    re.compile(r"external_api\b|ext_api\b", re.I),
]
```

**注意**:`re` 是 module-level import(`L29`)。`.delete()` 已移除(r1-F7:噪音過高)。`DROP TABLE/DELETE FROM` 保留(SQL 層不可逆,特指性強)。

### `_scan_diff_for_irreversible_hints(cwd)`(新 helper,L993 可逆性軸群)

```python
def _scan_diff_for_irreversible_hints(cwd):
    """掃 git diff --staged(優先)或 HEAD~1..HEAD,回傳疑似不可逆 +行摘要列表。
    非 git repo 或無 diff → 回傳 []。跳過測試檔與純注解行。
    cwd=str(env.vault) 即可:git diff 無 pathspec 時範圍為全 repo,cwd 子目錄不縮小範圍。"""
    import subprocess  # lazy import,與 L339/L2298 等先例一致
    _SKIP_EXT = {".md", ".txt", ".rst"}   # 只排文字文件;config 保留(r1-F5)
    _TEST_PAT = re.compile(r"(test_|_test\.|\.spec\.|/tests?/)", re.I)

    for cmd in (
        ["git", "diff", "--staged"],
        ["git", "diff", "HEAD~1..HEAD"],
    ):
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
        except FileNotFoundError:
            return []
        if r.returncode != 0 or not r.stdout.strip():
            continue
        diff_text = r.stdout
        break
    else:
        return []

    cur_file = ""
    hits = []
    for line in diff_text.splitlines():
        if line.startswith("+++ b/"):   # 只更新到真實檔;/dev/null 不更新(r1-F4)
            cur_file = line[6:]
        if line.startswith("+++") or line.startswith("---"):
            continue
        if not line.startswith("+"):
            continue
        ext = Path(cur_file).suffix if cur_file else ""
        if ext in _SKIP_EXT:
            continue
        if cur_file and _TEST_PAT.search(cur_file):
            continue
        code_line = line[1:].strip()
        if code_line.startswith(("#", "//", "--", "/*", "*")):
            continue
        for pat in IRREVERSIBLE_HINT_PATTERNS:
            if pat.search(code_line):
                label = f"{Path(cur_file).name}: {code_line[:80]}"
                hits.append(label)
                break
    return hits[:8]
```

### Check H section 在 `run_doctor` 插入點

插在 Check S 的 `print()` @L685 之後、L686 空行處、L687(Check K doc 註解)之前。**只在 `ci=True` 執行**。

```python
section("H", "漏標可逆性提醒 (diff 碰 prod/外部 API/寄送 → 是否漏標 ★IRREVERSIBLE★?)")
if not ci:
    print("  (僅 --ci 模式掃 diff;互動模式略過)")
else:
    hint_hits = _scan_diff_for_irreversible_hints(str(env.vault))
    if not hint_hits:
        ok("diff 無疑似不可逆操作行(或無 staged/HEAD diff)")
    else:
        warn_soft(
            hint_hits,
            f"diff 發現 {len(hint_hits)} 行疑似碰外部不可逆操作:",
            "確認相關 Systems 節點已標 ★IRREVERSIBLE★ [rollback:decisions] 或 [guard:decisions];若確認可逆可忽略",
        )
print()
```

## 組件(改動總覽)

### 改:`scripts/lumos`

1. **新常數 `IRREVERSIBLE_HINT_PATTERNS`**(L993 可逆性軸群,緊接 `GUARD_REF_RE @L995` 之後)
2. **新 helper `_scan_diff_for_irreversible_hints(cwd)`**(L993 可逆性軸群,緊接常數後,`import subprocess` 在函數內)
3. **Check H section**:插在 `run_doctor` L685(print())之後、L686 空行處、L687(Check K doc 註解)之前

### 不改

- Check R 邏輯(`scripts/lumos:619-642`)
- `warn()` 呼叫(Check H 從不計 issues)
- `run_doctor` 簽名
- `extract_reversibility`, `_rollback_resolved`, `_guard_resolved`
- gov_events:Check H **刻意不寫**——Check H 無具體 Systems nodes 可記錄(diff-scan 不解析架構圖),empty-nodes gov_event 在 `cmd_gov` L1228-1235(`q in r["nodes"]`)查不到任何節點,對 `lumos gov <node>` 消費端零可見性增益(r5-F1 辯方反證:scripts/lumos:L660/666/699/1228-1230)

## 誠實天花板

1. **Pattern 是 syntactic,不是 semantic**:`requests.post` 可能打 localhost mock;`DELETE FROM` 可能在 migration test。False positive 有,但軟提示成本接近零。
2. **CI 環境:staged 幾乎永遠空,主路徑是 `HEAD~1..HEAD`**:本地若有 staged 變更則優先掃 staged;CI 中 staged 空 → 自動 fallback 到 `HEAD~1..HEAD`。多 commit PR 只看最後一個 commit。
3. **`+++ b/` 前綴假設**:`diff.noprefix=true` 或 `mnemonicPrefix=true` 時 cur_file 解析失敗 → SKIP_EXT/TEST_PAT 過濾全失效(雜訊爆增而非安全降級)。v1 假設 git 標準前綴。
5. **初始 commit 無 parent**:`git diff HEAD~1..HEAD` rc≠0 → 靜默回 `[]`(安全失敗)。
4. **不知道對應哪個 Systems 節點**:提示通用,人仍要自查。
5. **Check H 與 Check R 有重疊**:已有 `★IRREVERSIBLE★` 的行仍可能被 Check H 報;人確認已標後略過。
6. **hits[:8] 截斷**:prod endpoint config 改動量多可能擠掉其他 hit。v1 接受,優先列先出現的 diff 行。

## 知識同步影響

| 文件 | 影響 | 同步動作 |
|---|---|---|
| `docs/methodology/架構圖即合約.md` | 說明 Check R 可逆性機制 | 補句「doctor --ci 另有 Check H:掃 diff 偵測疑似不可逆操作、提示漏標」 |
| `docs/methodology/架構圖即合約-對外論述.md` | 有可逆性段落(L160,確認含不可逆動作說明) | 同上補句 |
| `skills/lumos-project-notes/SKILL.md` | doctor 各 check section 說明 | 補「[H] 漏標可逆性提醒(--ci 才跑)」 |
| `scripts/templates/graph-discipline.md` | ★IRREVERSIBLE★ 說明 | 可逆性段落補「doctor --ci 的 Check H 掃 diff 提醒漏標」 |
| `skills/lumos-design-loop/SKILL.md` | 不直接影響 | 無 |
| `governance/autonomous_loop/orchestrator-prompt.md` | 不直接影響 | 無 |

## 測試策略

1. **smoke**:temp git repo,staged 含 `requests.post("https://prod.api.com/charge")` → doctor --ci → Check H 輸出「疑似碰外部不可逆操作」。
2. **filter-test-file**:staged 只改 `test_email.py` 含 `sendmail(...)` → Check H 輸出「無疑似不可逆操作行」。
3. **filter-comment**:staged 含 `# sendgrid.send(...)` 純注解行 → 不報。
4. **config-file-detected**:staged 改 `config.yaml` 含 `endpoint: https://prod.stripe.com` → Check H 報(SKIP_EXT 不排 .yaml)。
5. **no-ci**:doctor --strict(不含 --ci) → Check H 印「(僅 --ci 模式掃 diff;互動模式略過)」。
6. **non-git**:CWD 非 git repo → 靜默回 `[]`,Check H 報「無疑似」。
7. **initial-commit**(r2-F6):無 parent 的初始 commit → `HEAD~1..HEAD` rc≠0 → 靜默回 `[]`。

## 審計修正紀錄

- **r1 caught** (r1 canary 壞章節引用);severity=blocker(辯方維持);折修:
  - F1 BLOCKER:helper 內補 `import subprocess` lazy import
  - F2+F3 MAJOR:helper 改 `_scan_diff_for_irreversible_hints(cwd)`,由 run_doctor 傳 `str(env.vault)`;所有 subprocess.run 帶 cwd
  - F5 MAJOR:SKIP_EXT 縮減到 {".md",".txt",".rst"},config 檔保留掃描
  - F4/F7 MINOR:cur_file 只在 `+++ b/` 更新;移除 `.delete()` 高噪音 pattern
  - F8 MINOR:知識同步確認 對外論述.md L160 有內容,移除條件「若」
- **r2 caught** (r2 canary 未定義旗標);severity=minor(辯方降兩個 MAJOR);折修:
  - F1 MAJOR→minor(辯方反證):補 cwd 說明——git diff 無 pathspec 時範圍全 repo,子目錄 cwd 不縮小範圍
  - F2 MAJOR→minor(辯方反證):常數+helper 改放 L993 可逆性軸群(遵慣例而非違反)
  - F6 MINOR:誠實天花板補「初始 commit 無 parent → 靜默回 []」;測試策略補 test 7
- **r3 caught** (r3 canary 未定義常數);severity=major(辯方維持 F2);折修:
  - F2 MAJOR(辯方維持):插入點修正——Check S print() 在 L685 非 L687;L687-688 是 Check K doc 註解;Check H 正確插在 L685 之後、L687 之前(L686 空行處)
  - F1 MINOR:subprocess 行號說明——L2939/L2999 實為 `import os, subprocess` 合併式(非裸 `import subprocess`);核心前提不變
  - F4 MINOR:誠實天花板補——假設 git 標準前綴 `+++ b/`;若 diff.noprefix=true 則 cur_file 無法解析(靜默降級)
  - F6 MINOR:多 commit PR 僅看最後 commit 是已知缺口;已列誠實天花板
- **r4 caught** (r4 canary 壞章節引用);severity=minor(辯方降 F1);折修:
  - F1 MAJOR→minor(辯方反證):Check H **刻意不寫** gov_events——gov schema 定義為「blocked/warned 級 gate findings」(`docs/design/2026-06-19-reversibility-and-governance-ledger.md:65`),Check H 是摩擦地板提醒(warn_soft 不計 issues)非 gate finding;governance-log 自主 loop 收斂吃 canary-log 不吃 governance-log(`scripts/lumos:1267+`)。**在組件/不改節補一條明示:「不寫 gov_events(gov schema 為 gate-finding 級,Check H 是 hint 非 gate)」**
  - F3 MINOR:補誠實天花板說明——`diff.noprefix=true` 時 cur_file 解析失敗 → SKIP_EXT/TEST_PAT 過濾全失效(非安全降級,是雜訊爆增)
- **r5 caught** (r5 canary 未定義旗標 --hint-threshold);severity=minor(辯方降 F1);折修:
  - F1 MAJOR→minor(辯方反證 `scripts/lumos:L660/666/699/1228-1230`):gov_events 不寫的精確理由——Check H 無具體 Systems 節點(`nodes=[]`),empty-nodes gov_event 在 `cmd_gov`(L1228:`q in r["nodes"]`)查不到任何節點,對消費端零可見性增益。spec 改精確措辭:「Check H 無具體 nodes 可記錄,且 node-less gov_events 在 `cmd_gov` L1228-1235 為查不到的 partial-view,故刻意不寫」
  - F2 MINOR:修正誠實天花板編號重複「4.」
  - F3 MINOR:誠實天花板補 CI fetch-depth=1 場景(HEAD~1..HEAD rc≠0 → Check H 靜默失效,比初始 commit 更常見)
- **cross-audit 第 1 輪 (qwen)**:worst_severity=major;cross_reject_count=1;自 grep 驗證逐條:
  - qwen-M1(section 非 nested→major):FALSE POSITIVE — `grep -n "def section" scripts/lumos` 顯示 L366 縮排 4 格,確認 nested in run_doctor;spec 正確
  - qwen-M3(ok 未定義→major):FALSE POSITIVE — L369 nested 在 run_doctor,與 section/warn_soft 同層;spec 已文件化 nested 性質,ok 行為顯而易見
  - qwen-M2+M4(組件節 L687-L689 殘留→major):TRUE — L144 仍寫舊行號 → 已折修為「L685 print() 之後、L686 空行處、L687 之前」
