---
type: system
status: done
created: 2026-06-26
updated: 2026-08-18
self_audit: sonnet/2026-07-24
tags:
  - type/system
  - status/done
  - risk/守衛面
verified_by:
  - "[[Verification/2026-06-20_autonomous-iteration-loop]]"
summary: |-
  FLOW:cron 10:10 → autonomous-loop.sh:驗當日日報存在(真模式無報即跳;dry-run fallback 最近一份)→ gap_select(日報 gaps + backlog 去重排序選 top-1;N=1 gate:有 pending/open PR 則只進 backlog)→ claude -p orchestrator(真執行:brainstorm spec → design-loop ≤6 輪[opus auditor + canary a/b/c + judge 判 caught 並回報 severity + 強制地面事實查證]→ loop status --need 2 收斂 → §2.5 qwen3-max 跨家族複核)→ 收斂+endorsed/degraded → 放行閘(dry-run 寫 governance/pending/;真模式 branch+PR+LINE)→ 停等人放行
  KEY:定調=自動備料+自審+停在放行閘等人,不是無人迭代;放行(merge PR)永遠人手動,人從「每天發起鏈」變「每天 review 1 個 PR」
  KEY:N=1 同時只 1 個待放行 spec——上一個未清(pending 條目/open auto/spec- PR)前,新 gap 只進 backlog 不展開,PR 永不堆
  KEY:全自動判收斂仍是沒閉合的迴歸——judge/cross-family 只把自評推遠一層未消滅,末端人 review PR 是最後也唯一真兜底(誠實天花板)
  KEY:dry-run≠模擬——orchestrator 必須真執行所有工具(canary record/cross_audit),收尾前自查 scratch spec+canary-log 必須存在,否則本輪無效重做(06-23 真機抓到「全程腦內模擬」幻覺後硬化)
  KEY:claude -p 走 $0 OAuth token(CLAUDE_CODE_OAUTH_TOKEN,非 API key);避開 OAuth 被禁 model
  KEY:tier 收檔守衛(2026-07-24 L4 審計補漏——本節點原漏這道會否決自報收斂的機械閘):orchestrator 自報 converged=True+cross_verdict=endorsed 後,wrapper(autonomous-loop.sh L130-190)仍①驗 spec_path 存在②用自算 difficulty.assess_spec() 的 tier 重跑 loop status --gate 機械重驗③tier=high 要求 cross_verdict 必須乾淨 endorsed——任一不過→requeue 不放行+LINE;機制本體見 [[Systems/risk-tiered-review]]
  KEY:★抽掉人之前必辦清單(觸發條件=迴圈能不經人放行寫架構圖/開 PR 那天,今天人在放行點故全部不建)★——①提案者≠寫入者結構分離(Mnemosyne arXiv 2607.00269,2026-07-24 裁定:語意合約唯一真獨立寫入閘=真跑測試或人,LLM judge=換皮提案者)②PoE 型防竄改帳+逐筆授權+可重播(arXiv 2607.05397,2026-07-25 裁定:價值不靠敵人成立——無人 loop 自己的遙測可不可信;現成便宜前例 2.7ms;07-26 再添 PROJECTMEM arXiv 2606.12329:本機零依賴 append-only 指紋鏈+寫入前驗內容實證可行,「要裝東西太重」藉口拿掉)③日報吸收管線升格為不可信輸入面(調研員每天真讀外部網頁,今天靠人眼把關,無人化後=夾帶指令/假結論的真通道)。框架修正(使用者 2026-07-25):「內部系統無敵意下毒」對——敵意攻擊框架(IssueTrojanBench 66.5%)不適用單人私有 repo;但無人化後「幻覺 agent 寫錯架構圖+改自己成績單」效果同下毒,主角不需是敵人。同日拒:審計加對抗步(design-loop d4 前置加重一律拒,可審≠審得出=07-23 已記天花板換新引用)/spec 夾帶掃描(spec 作者=自己人,威脅不成立)
  KEY:紀律抗壓縮(Governance Decay arXiv 2606.22528,2026-07-26 對帳)=長跑對話的摘要壓縮會悄悄刪安全規矩(違規率 0→65-95%)——lumos 架構已結構性counter:規矩不住對話記憶(CLAUDE.md 每輪重注入/架構圖在硬碟/impact hook 每次動手前重推合約/orchestrator 每日 fresh spawn),「每輪從硬碟重讀紀律」該篇藥方=本設計既有形狀。殘餘面(誠實):對話中途的口頭約定(未落架構圖者)確實隨壓縮衰減——正是「退場必寫」存在的理由,重要裁定必須離開對話住進硬碟
  DEP:governance/daily-governance.sh(真入口:launchd com.enzo.lumos.daily-governance 09:30 單次喚醒,腳本內串接呼叫——原「兩支獨立 cron 09:30/10:10」因 Mac 閉蓋睡眠中途醒不來已棄,見該檔頭註)｜governance/autonomous-loop.sh(被 daily-governance.sh:26 以 --dry-run 6 呼叫)｜autonomous_loop/{gap_select,backlog,cross_audit,confidence_report,line_notify,orchestrator_result}.py + orchestrator-prompt.md｜scripts/lumos canary record / loop status｜gh CLI｜LINE curl broadcast
  TEST:scripts/test_autonomous_loop.py 27 passed;dry-run 端到端真機跑通 06-20→06-26(cron 已上 10:10)
  VERIFY:[[Verification/2026-06-20_autonomous-iteration-loop]]
decisions:
  - content: 定調為「自動備料 + 自審 + 停在放行閘等人」,而非「無人迭代」;放行(merge PR)永遠人手動,自動只到「備好待放行 spec」,絕不自動實作 / 自動 merge
    id: d1
    context: user 願景是「永遠在迭代的 lumos」;但全自動判收斂仍是沒閉合的迴歸(judge/cross-family 也是 AI、也會錯),且自動 brainstorm 沒人回澄清、AI 自選 gap 有自我強化偏誤
    why_chosen: 放大放行帶寬不等於消滅放行;末端人 review PR 是全鏈唯一外部錨點、最後真兜底,對齊「AI 全工人只驗證撐不起、人只在最高槓桿放行點」
    decided: 2026-06-20
    valid: true
  - content: dry-run≠模擬——orchestrator-prompt 加「執行紀律」塊強制真執行所有工具,收尾前自查 scratch spec + .canary-log.jsonl 必須存在,否則本輪無效重做;dry-run 與 --pr 唯一差別在收尾(寫 pending vs 開 PR),過程完全相同
    id: d2
    context: 06-23 真機發現 orchestrator 把 dry-run 誤解成「腦內模擬、什麼都不真做」——report converged/endorsed 但 scratch spec 空、無 canary-log,canary/judge/cross-family 全是它自說自話的幻覺,架空整個 loop(很可能從 06-20 上線起一直如此)
    why_chosen: 防放水的 canary、judge severity、跨家族補盲若被「模擬」架空,收斂報告全失真;唯有強制可驗證證據(真檔案產出)收尾自查才接得住此類幻覺
    decided: 2026-06-23
    valid: true
  - content: severity 改由獨立 judge 據實回報、不再 orchestrator 自填(judge-severity-gate);收斂門檻 = 連 2 輪 canary caught 且 severity ∈ {clean,minor}
    id: d3
    context: design-loop R3 揪出「severity 自報 = 收斂門檻自填」是全自動判收斂最弱環——被審者自填收斂了沒;此缺口本身就是 loop 上線後自己選中、自己 brainstorm 出 judge-severity-gate spec 來修的(自指)
    why_chosen: 把「收斂了沒」從被審者手裡移到獨立 judge,斷開自填閘;但這只把最弱環推進一層未消滅(judge 集中掌 caught+severity、只讀 auditor 文字不自 grep),仍須人工抽查
    decided: 2026-06-20
    valid: true
  - content: 放行前加 qwen3-max 跨家族複核(§2.5):收斂後開 PR 前,opus 取材餵 ground-truth、qwen 跨家族判;endorsed/degraded 放行、disputed(major+ 異議)退回 opus 續審,達 2 次升給人;API 不可用 → degrade 回 opus 放行(fail-open)
    id: d4
    context: backlog gap「judge 抗自偏漏了換家族解法」;真機側證 opus 單家族 canary missed 2/6 ≈ 33%,正是同門盲點;前提「換家族 $0 OAuth 做不到」被 qwen API 破
    why_chosen: 補 opus 同門盲點是收斂可信度最實在的一道補強;fail-open 確保 qwen 不可用時 loop 不卡死(降級回 opus 並標註)
    decided: 2026-06-22
    valid: true
  - content: 暫停每日自主 loop(launchctl disable com.enzo.lumos.daily-governance;plist 保留)
    id: d5
    context: 使用者指示暫停接下來的日報 loop
    why_chosen: 恢復指令:launchctl enable gui/$UID/com.enzo.lumos.daily-governance && launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.enzo.lumos.daily-governance.plist
    decided: 2026-07-07
    valid: false
    superseded_by: 2026-07-11 使用者裁示重啟(launchctl enable+bootstrap 已執行,每日 09:30);重啟時點的安全網比暫停時厚:panel near-perfect 閘/跨家族否決席/guard kill/落成核對均已上線
    ended: 2026-07-11
  - content: 重啟每日自主 loop(dry-run 模式維持:收斂備 pending 等人放行,絕不自動 merge)
    id: d6
    context: 使用者明示「重啟」;7/7 暫停期間補齊 canary 生成硬化/near-perfect/panel/guard kill/落成核對
    why_chosen: 人放行閘=最高槓桿不動;恢復後首輪吃到全部新紀律
    decided: 2026-07-11
    valid: true
---
# autonomous-iteration-loop

每天日報產出後,**自動備好一份已自審的 lumos 改進 spec、停在放行閘等人**的閉環。

## 定位(一句話)
日報(9:30)→ 抽當日最高價值 gap → 自動 brainstorm 成 spec → 跑 design-loop 審到收斂 → 跨家族複核 → 把「收斂 spec + 可信度報告」備好(dry-run 寫本地 / 真模式開 PR + LINE),**停,等人放行**。人從「每天發起這條鏈」變成「每天 review 一個 PR」。

> **這是放大放行帶寬,不是無人迭代。** 自動化「發起 + 篩選 + 自審備料」;把「判斷收斂可不可信 + 放行」留人。放行 = 人手動 merge PR,系統絕不自動 merge / 自動實作。

> **源起:日報 2026-06-18 gap**——「整套把關預設『每次 commit 都有人在旁邊看 stderr』,但無人看顧的自主迴圈已成主流,這個前提正在崩。」對齊治理大方向 loop engineering(朝自主 / 無人看顧的自我檢查 loop)。

## 架構(5 組件 + cron 入口)
- `governance/autonomous-loop.sh` — **由 `daily-governance.sh` 串接呼叫**(launchd 09:30 單次喚醒同腳本內接續;舊「獨立 cron 10:10」已棄——閉蓋睡眠醒不來,2026-07-24 L4 審計修真)。驗當日 `governance/reports/governance-<date>.json` 存在(真模式無報即跳、不視為錯;dry-run fallback 最近一份)→ gap_select → 派 orchestrator → 解析回傳 → 收斂則放行閘。主流程包 `while`(skip → continue 選下一個,`SKIP_CAP=3` 防空燒)。
- `autonomous_loop/gap_select.py` — 讀日報 `gaps[]`(真 schema `{weakness, suggestion}`)+ `backlog.jsonl`,去重排序選 top-1;**N=1 gate**(`pending_exists`:dry-run 查 `governance/pending/*.md`、真模式 `gh pr list head:auto/spec-`);`covered.jsonl` 永久排除已被既有 spec 覆蓋的 gap。
- `autonomous_loop/backlog.py` — backlog 讀寫 / value_score 衰減 / 淘汰 / 排序。
- `autonomous_loop/cross_audit.py` — qwen3-max(DashScope 國際 endpoint)跨家族複核;回 `{status, worst_severity, ...}`,`status==degraded` 為 fail-open(no_key / http / timeout)。
- `autonomous_loop/orchestrator-prompt.md` — `claude -p` orchestrator 的 prompt 模板(brainstorm + design-loop + §2.5 跨家族 + 輸出單一 JSON)。
- `confidence_report.py` / `line_notify.py` / `orchestrator_result.py` — 可信度報告 body、LINE 傳輸層復用 + 待放行訊息 body、從 orchestrator result 文字提取最後一個合法 JSON(容錯敘述夾雜 `{clean,minor}` 干擾)。

## 收斂與放行門檻
- **CONVERGED** = `lumos loop status <topic> --need 2` exit 0 = **連 2 輪 canary caught 且 severity ∈ {clean,minor}**(漏抓那輪不採信收斂的一半)。失控保護:design-loop max cap = 6 輪、N=1、連續撞 cap → 停 + LINE 告警。
- 收斂後走 **§2.5 跨家族複核**:`endorsed`/`degraded` → 放行;`disputed`(major+ 異議)→ 退回 opus 續審,`cross_reject_count` 達 2 → 停、不放行、`cross_verdict=disputed`(必伴 `converged:false`)。
- 放行閘:dry-run 寫 `governance/pending/<date>-<topic>.md`(+ confidence);真模式(`--pr`)commit 到 `auto/spec-<topic>-<date>` branch、`gh pr create`、發 LINE。**⚠ 真 PR 模式(--pr)的 branch+PR+LINE 路徑尚未真機驗證**——Verification 節點的 pass 範圍僅涵蓋 dry-run;切換至 --pr 前須重驗放行閘全路徑(見 [[Verification/2026-06-20_autonomous-iteration-loop]] `revalidate_when`)。

## design-loop 對 skill 預設的覆寫(autonomous 版)
- **opus auditor 起手**(覆寫 skill「sonnet 起手、連 2 missed 才升 opus」)。
- **canary 限 type a/b/c、禁 type d**(覆寫 skill a/b/c/d 固定輪換;type d 對 self-contained 新功能不公平)。
- **獨立 judge**:判「canary 抓到沒」+ 據實回報排掉 canary 後最嚴重真 finding 的 severity(severity 不再 orchestrator 自填)。
- **強制地面事實查證**:auditor 對 spec 每個現況假設(欄位 / 簽名 / 檔案 / 常數)必須實際 grep/Read 驗過、列查證清單。

## 誠實天花板(必寫進 PR 可信度報告)
1. **末端人 review PR 是全鏈唯一外部錨點、最後真兜底**。全自動判收斂仍是沒閉合的迴歸:judge-severity-gate 把「收斂自填」推進一層未消滅(judge 集中掌 caught+severity、只讀文字不自 grep、規範非機制強制);cross-family 補同門盲點但 qwen 也是 AI。
2. 自動 brainstorm 沒人回澄清 → spec 品質天花板低於有人在場。
3. AI 判「哪個 gap 值得做」= AI 決定改自己的方向,有自我強化偏誤。

## 已知限制 / 真機教訓
- **orchestrator「模擬」幻覺**(06-23,已硬化):曾把 dry-run 誤解成腦內模擬、report converged 但 scratch 全空——已加執行紀律塊 + 收尾自查強制可驗證證據。屬「無人看顧下無聲寫壞狀態」的活例。
- **未收斂但有價值的 gap 處置**:撞 cap / cross disputed 的 gap 由 `requeue_unconverged` 降分(×0.7)+ 累計 `unconverged` 回 backlog,達上限 3 → covered(放棄自動、留人手動)。
- opus 單家族 canary missed ≈ 33%(06-22 真機)——跨家族複核的存在理由,但 canary 自評弱仍是已知。

## 相關
- 設計稿:`docs/design/2026-06-20-autonomous-iteration-loop.md`(canary-護 design-loop 5 輪、K=2 收斂;自指閉環)。
- 實作計畫:`docs/superpowers/plans/2026-06-20-autonomous-iteration-loop.md`。
- 下游產物(loop 自己選中、brainstorm 出來的):`docs/design/2026-06-20-judge-severity-gate.md`、`docs/design/2026-06-22-cross-family-audit.md`。
- 真機觀察日誌:`governance/autonomous_loop/DRYRUN-OBSERVE.md`、spike 結果 `SPIKE-RESULT.md`。

## 近期修正

- 2026-08-18 token 傳遞硬化(code-loop code-標註刷新 r1 另案收尾):七處 LINE 通知的 token 由 shell 內插(`t='$(cat …)'`,token 含引號會炸 python 且被 || true 吞)改為 `LINE_TOKEN` 環境變數傳遞+`os.environ.get`,行為不變、注入面拆除。
