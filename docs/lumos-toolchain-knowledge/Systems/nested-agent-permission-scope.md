---
type: system
status: planned
created: 2026-06-26
updated: 2026-06-26
self_audit: sonnet/2026-06-26
tags:
  - type/system
  - status/planned
  - risk/守衛面
verified_by:
  - "[[Verification/2026-06-23_nested-agent-permission-scope_design-loop收斂]]"
summary: |-
  FLOW:orchestrator(層0 全工具)→[canary 植入 Edit]→spawn auditor/judge 改 Bash 子程序 `claude -p --allowedTools "Read,Grep,Glob" --permission-mode dontAsk`(層1 唯讀,cwd=repo root)→每次 spawn 前 append delegation-log 一行→canary record/cross_audit(不變)
  KEY:autonomous-loop 的 auditor/judge 由「Agent 工具 spawn(繼承父全權)」改為「claude -p 子程序帶 --allowedTools 唯讀」——機械強制點在 harness 層工具集宣告,非 prompt 自律
  KEY:Claude Code 的 Agent 工具不支援 allowedTools,子 agent 完整繼承父 session 工具集——這是 confused deputy 漏洞根因(被下毒節點可誘導唯讀審計員去 Edit/Bash/開 PR)
  KEY:append-only 收窄——每巢狀一層權限只能更窄(層0 Read,Edit,Bash,Grep,Glob,Agent → 層1 Read,Grep,Glob);委派範圍寫 delegation-log JSONL 留痕(本機稽核,不進 CI/可信度報告)
  KEY:保護層唯一——父 `claude -p` 的 --allowedTools 是 per-session 旗標,不傳播到子程序;唯一機械強制點是 orchestrator 實際帶上 --allowedTools 的那條 Bash 命令(若被注入省略則退回全工具,prompt-orchestrated 固有殘留)
  KEY:auditor/judge prompt 與 auditor 報告寫 temp file 經 `claude -p "$(cat $TMP)"` 傳遞,不拼接進 shell 字面量(防 spec 草稿含引號序列注入 shell 命令);`--input-file` 旗標不存在
  DEP:governance/autonomous_loop/orchestrator-prompt.md(改:§2 round sub-steps 3/4)｜governance/autonomous-loop.sh(不改,L43 工具宣告維持、L35 __SCRATCH__ sed 替換)
  TEST:無單元測試(prompt 層,smoke test 即可);spec 經 design-loop 5 輪收斂(R2 實證 Write 被拒)
  VERIFY:[[Verification/2026-06-23_nested-agent-permission-scope_design-loop收斂]]
decisions:
  - content: 選方案 C(harness 層 claude -p 子程序 --allowedTools 收窄)否決方案 A(純 prompt 前置指令)與方案 B(chmod 唯讀 + pre-commit 攔)
    id: d1
    context: confused deputy 風險——autonomous loop 用 Agent 工具 spawn 的 auditor/judge 完整繼承父全權,被下毒 spec 誘導時可合法 Edit/Bash 寫架構圖改 spec
    why_chosen: 方案 A 是 prompt 層自律,被注入後 LLM 可忽略前置指令(正是漏洞核心);方案 B 只保護特定路徑且 chmod restore 有 TOCTOU 時序窗口;方案 C 機械強制點在 harness 工具集宣告、改動最小、自然留 delegation-log
    decided: 2026-06-23
    valid: true
  - content: 路徑用 __SCRATCH__ sed 替換後的字面絕對路徑,不用 $SCRATCH env;auditor 子程序須以 cwd=repo root 執行
    id: d2
    context: design-loop R1-B1 揪出 $SCRATCH 在 autonomous-loop.sh 從不 export(orchestrator 子程序中展開為空、路徑破碎);R3-F1 揪出 Grep/Glob 預設搜 cwd,cwd=/tmp 則搜代碼庫靜默空回傳、auditor 誤稱已驗
    why_chosen: __SCRATCH__ 是 autonomous-loop.sh:L35 的 sed 替換 token(展開為字面絕對路徑),非執行時 shell var;cwd=repo root 由呼叫者 `(cd "$REPO" && claude -p ...)` 繼承,保 Grep/Glob 搜得到代碼
    decided: 2026-06-23
    valid: true
  - content: 不建全身份認證體系(無簽章/capability token)、delegation-log 不設自動 CI 驗證(append-only 本機稽核)
    id: d3
    context: 6/12 日報曾提加密委派 token;YAGNI 取捨——delegation-log 記「orchestrator 宣稱做了什麼」非「harness 驗證確實做了什麼」,可被寫假
    why_chosen: scope 由單一可查點 --allowedTools 在 harness 層管理即夠;獨立驗證需 wrapper 讀 log 比對工具清單,本 spec 明確不做
    decided: 2026-06-23
    valid: true
  - content: 非 dry-run 模式停用:autonomous-loop.sh 對 --pr 直接 exit 2(硬閘進 script 開頭),排程路徑本就僅 dry-run。解禁條件=read-only child isolation 落地+過 code-loop 終審
    id: d4
    context: Codex 外審(2026-07-29)指出已知 confused-deputy 漏洞仍留可執行入口;使用者裁定停用
    why_chosen: 漏洞已知且修復 planned 未落地時,留著入口=可被 poisoned spec 誘導 Edit/Bash 的活風險;dry-run 產出 pending 等人放行的價值不受影響
    decided: 2026-07-29
    valid: true
aliases:
  - confused deputy
---
# nested-agent-permission-scope

autonomous-loop 的 design-loop 子 agent(auditor / judge)權限範圍收窄 —— 把它們從「**Agent 工具** spawn(繼承父全權)」改為「**`claude -p` Bash 子程序帶 `--allowedTools "Read,Grep,Glob"`**」,在 harness 層機械強制唯讀,並把每次委派的工具範圍寫進 **delegation-log** 供稽核。

> **狀態 = planned**:設計稿已收斂入庫(commit `19ced27`,2026-06-24),但 `orchestrator-prompt.md` **尚未實作**——現況仍用 Agent 工具 spawn(grep 確認 4 處「Agent 工具」、0 處 `claude -p`/`allowedTools`/`delegation-log`)。本節點描述設計目標態。

## 解決什麼(confused deputy)
- **現況漏洞**:`autonomous-loop.sh:L43` 給 orchestrator `--allowedTools "Read,Edit,Bash,Grep,Glob,Agent"`;orchestrator 用 **Agent 工具** spawn auditor/judge。Claude Code 的 Agent 工具**不支援 allowedTools**,子 agent 完整繼承父 session 工具集。
- **攻擊路徑**:spec 草稿若含被下毒節(惡意注入),受誘導的 auditor 子 agent 可合法呼叫 `Edit`/`Bash` 寫架構圖、改 spec、開 PR——父 session 與 harness 層皆不攔。
- **源起**:日報 2026-06-21 backlog gap「自主 loop 巢狀 spawn 子 agent,卻沒有範圍受限身分,子 agent 繼承全權(confused deputy 風險)」(同報 inspiration「append-only 收窄」、2026-06-12 多 agent confused deputy 三層防護研究亦為脈絡)。autonomous-loop 自選此 gap → 自動 brainstorm → 5 輪 design-loop 收斂 → 跨家族複審。

## 關鍵機制
1. **子程序替換**:auditor/judge 改為 `(cd "<REPO>" && claude -p "$(cat $TMP)" --allowedTools "Read,Grep,Glob" --permission-mode dontAsk --output-format json --model claude-opus-4-8 > $OUT)`;報告以 `python3 -c "import json; print(json.load(open('$OUT')).get('result',''))"` 取出。
2. **append-only 收窄**:層0 orchestrator(Read,Edit,Bash,Grep,Glob,Agent)→ 層1 auditor/judge(Read,Grep,Glob only)。每委派一層只能更窄。
3. **delegation-log**:`__SCRATCH__/.delegation-log.jsonl`,每 spawn 前 append 一行 `{"turn":N,"role":"auditor","tools":"Read,Grep,Glob","spawned_by":"orchestrator","loop_id":"<topic>","ts":"<ISO>"}`。`loop_id` 值取自 orchestrator 收到的 gap JSON 的 `topic` 欄位(由 `autonomous-loop.sh:L59` 萃取後隨 gap 內容一併塞入 orchestrator prompt,orchestrator 直接讀用)。純本機稽核,autonomous-loop.sh 不讀、不進可信度報告。
4. **防 prompt 注入**:prompt 與 auditor 報告寫 temp file 經 `"$(cat $TMP)"` 傳遞,不拼接 shell 字面量。

## 已知限制(誠實天花板)
- **保護層唯一**:父 `claude -p` 的 `--allowedTools` 是 per-session 旗標、不傳播到子程序;唯一機械強制點是 orchestrator 實際帶上 `--allowedTools` 的那條命令。若因注入/LLM 錯誤省略,子程序恢復全工具集——這是 prompt-orchestrated 設計的固有殘留。
- **只防調用、不防誘導**:限工具防「調用受限工具」,不防「回傳被誘導的假 clean/假 caught」(資訊投毒);最終兜底仍是人 review。
- **oauth token 共用**:token 是帳戶層調用權,工具限制是 client-side `--allowedTools`,非 server-side 隔離。
- **delegation-log 無法自證**:記「orchestrator 宣稱做了什麼」,可被寫假;獨立驗證(wrapper 讀 log 比對)明確不做(YAGNI)。
- **session overhead**:每輪 2 個獨立 `claude -p` opus 程序(最多 6 輪 × 2 = 12 個),session 啟動延遲 + 各自 context 是真實 regression,但安全收益高於 overhead;副效應是每輪審計 context 新鮮、不累積前輪汙染。

## 相關
- 設計稿:`docs/design/2026-06-23-nested-agent-permission-scope.md`(opus 5 輪 CONVERGED;R3 MISSED 一輪;跨家族 qwen 複審兩 finding 經人 grep 駁回為誤判)。
- 實作落點(待做):`governance/autonomous_loop/orchestrator-prompt.md` §2 round sub-steps 3/4。
- 計畫:無(commit `19ced27` 註「待 writing-plans 實作」,docs/superpowers/plans/ 未見對應份)。
- 實作後 smoke test(見 [[Verification/2026-06-23_nested-agent-permission-scope_design-loop收斂]]):`$SCRATCH/auditor-r1.json` 存在、`.result` 取出非空、`$SCRATCH/.delegation-log.jsonl` 每輪 auditor+judge 各一行且 `tools="Read,Grep,Glob"`。
