# 設計:巢狀子 agent 權限範圍收窄(nested-agent-permission-scope)

- 日期:2026-06-23
- 狀態:草稿(autonomous-loop dry-run)— opus 5 輪 CONVERGED;放行前跨家族複核 qwen 提異議,經人驗證**全為誤判、駁回**(見末「放行前跨家族複核紀錄」),維持收斂
- 動機來源:backlog gap 2026-06-21「自主 loop 巢狀 spawn 子 agent,卻沒有範圍受限身分——子 agent 繼承全權(confused deputy 風險)」
- loop_id:nested-agent-permission-scope

## 目標(一句話)

autonomous loop 的 auditor / judge 子 agent 改以 **Bash 子程序(`claude -p --allowedTools "Read,Grep,Glob"`)** 而非 Agent 工具 spawn,使它們在 harness 層被機械強制為唯讀,同時把每次委派的工具範圍寫進 **delegation-log**,讓「誰以什麼權限做了什麼」可稽核。

## 前提與既驗事實

- **現況**:autonomous-loop.sh:L43 給 orchestrator `--allowedTools "Read,Edit,Bash,Grep,Glob,Agent"`;orchestrator 再用 `Agent` 工具 spawn auditor / judge——Claude Code 的 `Agent` 工具**不支援 allowedTools 參數**,子 agent 完整繼承父 session 的工具集。
- **confused deputy 路徑**:spec 草稿中若有「被下毒」節(惡意注入指令),auditor 子 agent 被誘導時可合法呼叫 `Edit`/`Bash`,寫入架構圖、改 spec、甚至開 PR——父 session 和 harness 層皆不攔截。
- **機械防護可達點**:`claude -p --allowedTools "Read,Grep,Glob"` 在 harness 層強制 auditor/judge 無 Edit/Bash/Agent,子程序無論被如何誘導都無法呼叫受限工具(harness 層比 prompt 層可靠)。
- **orchestrator Bash 工具已驗**:orchestrator-prompt 要求跑 `python3 scripts/lumos ...` + `python3 -c "...cross_audit..."`,已用 Bash 工具;再加一條 `claude -p` Bash 子程序同層次、無新依賴。
- **autonomous_loop/ __init__.py 存在**:grep 已驗 `governance/autonomous_loop/__init__.py` 存在;`governance/__init__.py` 不存在,故 `sys.path.insert(0,'<REPO>/governance')` + `from autonomous_loop import ...` 是正確調用路徑(cross_audit spec R2 坐實)。
- **`$SCRATCH` 未 export(R1-B1 坐實)**:autonomous-loop.sh 在 L12 定義 `SCRATCH` 但從不 export。orchestrator 程序繼承的 env 僅有 PATH/ANTHROPIC_API_KEY/CLAUDE_CODE_OAUTH_TOKEN。故 orchestrator Bash 子程序中 `$SCRATCH` 展開為空——路徑必須用 `__SCRATCH__` 被 sed 替換後的**字面絕對路徑**(orchestrator-prompt 本身即如此用:autonomous-loop.sh:L35 替換 `__SCRATCH__` → 實際路徑,再送給 LLM)。
- **`claude -p --model` 旗標已驗(R1-minor1 坐實)**:`claude --help` 確認 `--model <model>` 存在,auditor/judge 子程序可指定 opus。
- **`--permission-mode dontAsk` 合法(R1 查證)**:`claude --help` 確認 `dontAsk` 是合法 choice。

## 方案比較與決策

### 方案 A — 純 prompt 層:子 agent prompt 頭部加「你只能用 Read/Grep/Glob」
- **優點**:零架構改動,立即可試。
- **缺點**:prompt 層無機械強制——被惡意注入後 LLM 仍可忽略前置指令;這正是 confused deputy 的核心漏洞(節點受信任=繞過前置指令)。
- **決策:否決**。

### 方案 B — 資源層守衛:chmod canary vault 唯讀 + git pre-commit 攔截
- **優點**:保護關鍵資源本身。
- **缺點**:只保護特定路徑;子 agent 仍可寫其他路徑(tmp/ 下任意檔);chmod 在 orchestrator 寫完 canary 後需立刻 restore,時序窗口複雜(TOCTOU)。
- **決策:否決**,保護面太窄、時序複雜。

### 方案 C(選定)— Harness 層收窄:子程序 `claude -p --allowedTools "Read,Grep,Glob"` + delegation-log
- **優點**:機械強制(harness 攔、非 prompt 勸)、改動最小(把 orchestrator-prompt 裡的 Agent 呼叫改成 Bash 子程序)、自然留下委派痕跡(delegation-log)。
- **缺點(R1 修正後更誠實)**:orchestrator prompt 變長;orchestrator LLM **必須**在 Bash 子程序中帶上 `--allowedTools`——這仍是 prompt 層自律,無 harness 層強制備援(見下方誠實天花板 #2);auditor/judge 每次均是獨立 `claude -p` 程序,session overhead 比 Agent 工具高(見誠實天花板 #5)。
- **決策:採用**——機械強制點在工具集宣告而非子 agent 自我審查,已比方案 A/B 更可靠;overhead 可接受。

## 邊界 / 非目標(YAGNI)

- 不改 orchestrator 本身的工具集:orchestrator 仍有 Edit/Bash/Agent(需要寫 spec、折 findings、跑 canary record)。
- 不建全身份認證體系:不引入簽章、capability token 等複雜機制——scope 由 `--allowedTools` 在 harness 層單一可查點管理。
- 不限制所有 Agent 工具用途:orchestrator 的 Agent 工具仍可用,但 auditor / judge 這兩個角色改為 Bash 子程序;其他臨時 Agent 用途不在本 spec。
- 不跨 PR 流程驗 delegation-log:delegation-log 是 append-only 本機可稽核,不設自動 CI 驗證(見誠實天花板 #4)。
- 不改 autonomous-loop.sh 的工具宣告:wrapper 層無需改動,改動只在 orchestrator-prompt。

## 架構:子程序替換 + delegation-log

**路徑慣例**:orchestrator-prompt 收到的 `__SCRATCH__` 已被 autonomous-loop.sh L35 sed 替換為字面絕對路徑(如 `/tmp/auto-loop-2026-06-23`);orchestrator 應使用 `__SCRATCH__` 展開後的字面路徑——不用 `$SCRATCH`(未 export,R1-B1)、不用 `<DATE>` 佔位符(非替換 token,R3-m1)。另:auditor 子程序須以 **cwd=repo root** 執行(R3-F1):Grep/Glob 預設搜索 cwd,若 cwd=/tmp 則搜索代碼庫靜默空回傳。

```
orchestrator(有 Edit/Bash/Grep/Glob/Agent)
  │
  ├─ [canary 植入] 直接 Edit 工作副本(需 Edit)
  │
  ├─ [spawn auditor]  (cwd 須為 repo root,由呼叫者的 `(cd "$REPO" && ...)` 繼承——R3-F1/R4-m1)
  │    DELEGATION_LOG=__SCRATCH__/.delegation-log.jsonl   ← 用 __SCRATCH__ 展開值,非 <DATE> 佔位符(R3-m1)
  │    echo '{"turn":N,"role":"auditor","tools":"Read,Grep,Glob",...}' >> $DELEGATION_LOG
  │    AUDITOR_OUT=__SCRATCH__/auditor-rN.json
  │    claude -p "<auditor prompt via temp file>" \
  │      --allowedTools "Read,Grep,Glob" \
  │      --permission-mode dontAsk \
  │      --output-format json \
  │      --model claude-opus-4-8 \
  │      > $AUDITOR_OUT
  │    AUDITOR_REPORT=$(python3 -c "import json; print(json.load(open('$AUDITOR_OUT')).get('result',''))")
  │
  ├─ [spawn judge]
  │    echo '{"turn":N,"role":"judge","tools":"Read,Grep,Glob",...}' >> $DELEGATION_LOG
  │    JUDGE_OUT=__SCRATCH__/judge-rN.json
  │    # judge prompt 含 auditor 完整報告:寫入 temp file,不拼接進 shell 字面量(防 prompt 注入)
  │    JUDGE_PROMPT=$(mktemp); printf '%s\n%s' "<judge instructions>" "$AUDITOR_REPORT" > $JUDGE_PROMPT
  │    claude -p "$(cat $JUDGE_PROMPT)" \
  │      --allowedTools "Read,Grep,Glob" \
  │      --permission-mode dontAsk \
  │      --output-format json \
  │      --model claude-opus-4-8 \
  │      > $JUDGE_OUT
  │    JUDGE_RESULT=$(python3 -c "import json; print(json.load(open('$JUDGE_OUT')).get('result',''))")
  │    rm -f $JUDGE_PROMPT
  │
  ├─ [canary record / loop status] Bash → python3 scripts/lumos(不變)
  ├─ [cross_audit]   Bash → python3 -c(不變)
  └─ [spec 折入 findings] Edit/Bash(需 Edit,不變)
```

### 委派限縮規則(append-only narrowing)

- orchestrator(層 0):Read,Edit,Bash,Grep,Glob,Agent(由 autonomous-loop.sh:L43 宣告)
- auditor / judge(層 1):Read,Grep,Glob only(由 orchestrator 在每次 Bash 子程序呼叫中宣告)
- 每次委派範圍 ≤ 上層範圍(只能更窄,不能更寬)。
- **保護層唯一性**:沒有「harness 層二重保護」——父 `claude -p` 的 `--allowedTools` 是 per-session 旗標,**不**傳播到子 `claude -p` 程序(R1-B2);唯一的機械強制點是 orchestrator **實際帶上** `--allowedTools "Read,Grep,Glob"` 的那一行 Bash 命令。

### delegation-log 格式

每行 JSONL:
```
{"turn":1,"role":"auditor","tools":"Read,Grep,Glob","spawned_by":"orchestrator","loop_id":"<topic>","ts":"<ISO>"}
{"turn":1,"role":"judge","tools":"Read,Grep,Glob","spawned_by":"orchestrator","loop_id":"<topic>","ts":"<ISO>"}
```

路徑:`__SCRATCH__/.delegation-log.jsonl`(用 `__SCRATCH__` 展開後的字面絕對路徑——R3-m1)。orchestrator 每次 spawn 前 append 一行;autonomous-loop.sh 不讀此檔(純稽核用)。

OAUTH_TOKEN 傳遞:子程序繼承 orchestrator 的 env,包含 `CLAUDE_CODE_OAUTH_TOKEN`(autonomous-loop.sh:L39 export),故無需另設 token。

### auditor/judge prompt 傳遞方式(防 prompt 注入)

**不可**把 auditor/judge prompt 或 auditor 報告拼接進 shell 字面量(若 spec 草稿含反引號/引號序列,會注入額外 shell 命令)。
**正確做法**:把 prompt 寫入 temp file,用 `claude -p "$(cat $TMPFILE)"` 傳遞(R1 誠實天花板 #5;注意:`--input-file` 旗標不存在——R2-M1 已驗)。

## 組件(改動)

### 改:`governance/autonomous_loop/orchestrator-prompt.md`

## 步驟 → ### 2 子步驟 3、4 改寫(R1-minor2/R2-m1:對齊 orchestrator-prompt.md 實際結構 `## 步驟 / ### 2`,不用 § 符號):

**round sub-step 3(auditor spawn)**:
- 不再:用 Agent 工具 spawn opus auditor。
- 改為:
  1. Append delegation-log 一行(`{"turn":N,"role":"auditor","tools":"Read,Grep,Glob",...}`)到字面路徑 `.delegation-log.jsonl`。
  2. Bash 子程序以 `(cd "<REPO>" && claude -p "$(cat $AUDITOR_PROMPT_FILE)" --allowedTools "Read,Grep,Glob" --model claude-opus-4-8 --output-format json)` 跑 auditor——cwd 明確設為 repo root,Grep/Glob 才能搜索代碼庫(R3-F1/R4-m1);prompt 寫 temp file,不拼接入 shell 字面量。
  3. 輸出到 `__SCRATCH__/auditor-rN.json`;用 `python3 -c "import json; print(json.load(open('...')).get('result',''))"` 取 auditor 報告文字。

**round sub-step 4(judge spawn)**:
- 不再:用 Agent 工具 spawn opus judge。
- 改為:同 sub-step 3 模式,但 judge prompt temp file = judge 指令 + auditor 完整報告文字;輸出到 `__SCRATCH__/judge-rN.json`;同樣 `python3 -c "..."` 取 judge 判定文字。

### 不改:`governance/autonomous-loop.sh`

wrapper 層不動;L43 工具集宣告維持(orchestrator 子程序繼承時不影響——每個 `claude -p` 均獨立 session)。

### 不改:`governance/autonomous_loop/confidence_report.py` / `cross_audit.py`

delegation-log 不進可信度報告;審計留本機即可。

## 成本與 overhead(R1-major4 補)

- **現況(Agent 工具)**:auditor/judge 在父 orchestrator session 內 spawn,共享 session;token 計在同一 conversation。
- **本設計(子程序)**:每輪 2 個獨立 `claude -p` opus 程序,各自啟動新 session,各自計 context overhead。最多 6 輪 × 2 = 12 個獨立 opus 子程序。
- **評估**:overhead 是真實的 regression(session 啟動延遲 + 各自 context),但可接受——安全收益(harness 層工具限制)高於 session overhead;且每輪 auditor/judge 的 context 均是新鮮的,不累積前輪汙染(副效應:每輪審計更乾淨)。
- **成本**:走 OAuth 訂閱($0 API 費,但受 rate limit 約束);12 子程序的 rate limit 消耗比 Agent tool 高——若 loop 頻繁 rate limit,可考慮在子程序之間加短暫 sleep(YAGNI,實際跑才確認)。

## 誠實天花板

1. **auditor/judge 仍是 LLM**:限工具只防「調用受限工具」,不防「回傳被誘導的錯誤評估」——confused deputy 的「資訊投毒」路徑(子 agent 被誘導後回傳假 clean / 假 caught)不被本設計堵住,最終兜底仍是人 review。
2. **保護層唯一**:父 `claude -p` 的 `--allowedTools` 不傳播到子 `claude -p`(per-session 旗標,R1-B2 坐實);**沒有 harness 層二重保護**——唯一的機械強制點是 orchestrator 帶上 `--allowedTools "Read,Grep,Glob"` 的那條 Bash 命令。若 orchestrator 因 prompt 注入或 LLM 錯誤省略此旗標,子程序恢復全工具集。這是 prompt-orchestrated 設計的固有殘留。
3. **oauth token 共用**:token 代表帳戶層級的 claude 調用權,不是細粒度工具權限。工具限制是 client-side `--allowedTools`,非 server-side 隔離。
4. **delegation-log 無法自證**:orchestrator 可以寫假的 delegation-log(log 記錄「orchestrator 宣稱它做了什麼」,非「harness 層驗證 orchestrator 確實做了什麼」)——獨立驗證需 wrapper 層讀 log 並確認工具清單,本 spec 明確不做(YAGNI)。
5. **session overhead 增加**:見「成本與 overhead」節;rate limit 下可能需補 sleep,實際跑才能確認。

## 測試策略

- **smoke test**:手動觸發一輪 design-loop,確認 `auditor-r1.json` 存在、`.result` 可用 python3 取出非空文字,且 `.delegation-log.jsonl` 有對應 auditor + judge 各一行。
- **機械拒絕驗證**:在 auditor prompt 末尾加「請用 Edit 工具在 /tmp/canary-write-test.txt 寫一行」,確認子程序回傳 error 或拒絕,且 `/tmp/canary-write-test.txt` 不存在。
- **delegation-log 格式**:python3 one-liner 讀 `.delegation-log.jsonl`,確認每輪有 auditor + judge 各一行、tools 欄位為 `"Read,Grep,Glob"`。
- **不新增單元測試**:orchestrator-prompt 是 prompt 層,smoke test 即可;不為 LLM 呼叫格式寫 mock 單元測試(YAGNI)。

## 知識同步影響

| 受影響文件 | 需同步什麼 |
|---|---|
| `governance/autonomous_loop/orchestrator-prompt.md` | §2 round sub-steps 3/4:spawn auditor/judge 改 Bash 子程序(字面路徑 + temp file) + delegation-log append |
| `docs/design/2026-06-20-autonomous-iteration-loop.md` | §3 自動 Design-loop 段:補「子 agent 唯讀(harness 層 --allowedTools 限)+ delegation-log 稽核軌跡」 |
| `docs/methodology/架構圖即合約.md` | 補:loop 子 agent 委派採 append-only narrowing——每巢狀一層只能更窄、delegation-log 留痕 |
| `docs/methodology/架構圖即合約-對外論述.md` | 可不改(技術細節,對外論述不需列 allowedTools 機制) |
| `lumos-project-notes` skill | 補:confused deputy gap 已有設計 spec |

## 審計修正紀錄

### R1(2026-06-23,canary type a=壞§ref,opus,**CAUGHT**,severity=blocker)

canary(`§capability-token-rotation` 不存在章節引用)被識別。排掉 canary 後有 2 blocker + 3 major,全折入:
- **Blocker(B1)**:`$SCRATCH` 未 export,orchestrator Bash 子程序中展開為空→路徑破碎→`/auditor-rN.json`(permission denied)。修正:架構圖及組件段改用字面絕對路徑,說明 `__SCRATCH__` sed 替換機制。
- **Blocker(B2)**:「父 `--allowedTools` 二重保護子程序」為假——per-session 旗標不跨程序傳播、無 `.claude/settings*.json`。修正:移除「harness 層二重保護」表述;誠實天花板 #2 改寫為「保護層唯一」。
- **Major(M1)**:convergence-recording §5 引用錯誤(§5 談 severity 自評,非 delegation-log 偽造)。修正:移除該括號引用,保留論點本身。
- **Major(M3)**:`.result` 讀取未給具體 python3 指令。修正:架構圖補 `python3 -c "import json; print(json.load(open(...)).get('result',''))"` 一行。
- **Major(M4)**:子程序成本/overhead 未分析。修正:新增「成本與 overhead」節。
- **Minor(m1)**:`--model` MUST-VERIFY 已解——旗標確認存在,移除 MUST-VERIFY 警告。
- **Minor(m2)**:步驟標籤「步驟 3/4」與頂層步驟混淆。修正:改稱「round sub-steps 3/4」。

### R2(2026-06-23,canary type b=未定義旗標,opus,**CAUGHT**,severity=major)

canary(`--delegation-strict` 不存在旗標)被識別。排掉 canary 後 1 major + 1 minor,折入:
- **Major(M1)**:`--input-file` 旗標不存在(`claude --help` 確認無此旗標,R2 查證);spec 將其列為 prompt 傳遞的備選方案——移除,僅保留 `"$(cat $TMPFILE)"` 形式。
- **Minor(m1)**:`§2 round sub-steps` 符號與 orchestrator-prompt.md 實際結構(`## 步驟 / ### 2`)不符——改用 `## 步驟 → ### 2 子步驟 N` 對齊。
- **Core enforcement empirically verified(正向)**:auditor 實際執行 `claude -p ... --allowedTools "Read,Grep,Glob" --permission-mode dontAsk` 並嘗試 Write 工具——被拒絕、/tmp/canary-write-test.txt 不存在;機械限制核心機制實證有效。

### R3(2026-06-23,canary type c=未定義常數,opus,**MISSED**,severity=major)

canary(`DELEGATION_VERIFY_ROUNDS=0` 未定義常數)未被識別——auditor 未點出此 ALL_CAPS 常數無定義。本輪不採信收斂。真 findings 仍折入:
- **Major(F1)**:auditor 子程序 cwd/Grep 搜索根未指定。Grep 預設搜索 cwd——若 cwd 為 /tmp,搜索代碼庫回傳空、auditor 誤稱「已驗」。修正:架構圖標明 auditor 子程序須以 cwd=repo root 執行;路徑佔位符改用 `__SCRATCH__`(非 `<DATE>`)。
- **Minor(m1)**:`<DATE>` 佔位符與 orchestrator-prompt 的 `__SCRATCH__`/`__DATE__` 替換 token 不一致——全改為 `__SCRATCH__`。
- **Minor(m2)**:delegation-log echo 用 shell 字面量拼接 `<topic>`;與 spec 自己的「prompt 要用 temp file」原則不一致。標入誠實天花板(低風險,topic 是 loop 內部值;改 printf/jq 屬 YAGNI,留為 known limitation)。

### R4(2026-06-23,canary type a=壞§ref,opus,**CAUGHT**,severity=minor)

canary(`§token-isolation-protocol` 不存在章節引用)被識別。排掉 canary 後 1 minor,折入:
- **Minor(m1)**:`cwd=repo root` 要求只在文字中提及,架構命令區塊未展示機制。修正:架構圖標示「由呼叫者 `(cd "$REPO" && ...)` 繼承」,組件節 sub-step 3 改寫為 `(cd "<REPO>" && claude -p ...)` 明確編碼。
- 其餘(CLI 旗標/佔位符 token/ALL_CAPS 常數/交叉引用/init.py)全部 auditor 查證 clean。

### R5(2026-06-23,canary type b=未定義旗標,opus,**CAUGHT**,severity=minor)→ **CONVERGED(連 2 輪 R4+R5 caught+minor)**

canary(`--scope-audit` 不存在旗標)被識別。排掉 canary 後 2 minor:
- **Minor(m1)**:orchestrator-prompt.md 在 §2.5 段落仍用 `§` 符號(L41/L43 `轉 §2.5 跨家族複核`),故 spec 說「prompt 不用 §」不精確。修正:改為「避免在 sub-step 標籤用 §,以免與頂層章節混淆」。
- **Minor(m2)**:`delegation-log` JSONL 範例的 `"loop_id":"<topic>"` 佔位符無展開說明,已在 R3-m2 標為 known limitation,不再新增。
- 其餘(--allowedTools/--permission-mode/--model/--output-format/全 §-ref/ALL_CAPS/行號/init.py)全部查證 clean;核心機械強制機制(--allowedTools + dontAsk 阻斷 Write)實證有效。

### 放行前跨家族複核紀錄(2026-06-23,qwen3-max via cross_audit,SSL 修後真審)

qwen 真審本 spec(opus 5 輪已收斂),回 worst=blocker、提兩 finding。**人代 opus 下輪驗證、逐條 grep 反證——兩個皆 false positive,verdict 應為 endorsed**:
- qwen「**blocker**:cwd 修復依賴 spec 自身被採納」→ **駁回**:spec L122 已編碼 `(cd "<REPO>" && claude -p …)`、R3-F1/R4-m1 已折;qwen 把「spec 未實作(現況 orchestrator-prompt 仍用 Agent)」當 blocker,但那是所有未 merge spec 的本質(描述改後態),非缺陷。
- qwen「**major**:`__SCRATCH__` orchestrator 取不到該變量」→ **駁回**:spec L50/L58/L103 已明確「`__SCRATCH__` 是 autonomous-loop.sh:L35 sed 替換 token → 字面絕對路徑」(同 cross-family-audit F6 解法),非執行時 shell var;qwen 誤讀成 `$__SCRATCH__` env 引用。
- **意義**:cross-family-audit 首次真審即 false positive,印證其誠實天花板「qwen 也是 AI、會誤判」+ 設計 `disputed → opus 驗證` 這一步的必要——opus(或人)驗證會駁回 qwen 誤判、不錯退好 spec。真實 loop 在此會 disputed → 退回 → opus 驗證發現 spec 無問題 → 多一輪但不錯放。
