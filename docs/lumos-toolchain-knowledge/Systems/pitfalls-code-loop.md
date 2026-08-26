---
type: system
status: done
created: 2026-07-04
updated: 2026-08-14
self_audit: sonnet/2026-07-24
tags:
  - type/system
  - status/done
  - risk/守衛面
verified_by:
  - "[[Verification/2026-07-04_pitfalls-code-loop]]"
  - "[[Verification/2026-07-05_code-loop必用守衛]]"
  - "[[Verification/2026-07-10_合約鏈補強234]]"
  - "[[Verification/2026-08-05_panel-K2與抽查落地]]"
  - "[[Verification/2026-08-14_canary協議停用none制落地]]"
  - "[[Verification/2026-08-26_全repo術語統一為架構圖]]"
summary: |-
  KEY:★[2026-08-14]canary 協議停用(單源=[[Systems/canary-audit]] d5)★——植入/三道防污染/判定/missed 懲罰全停;輪記帳改 `canary record none`;panel 輪有效=記帳席≥2(Landmark r5「單席 caught<2 白跑」型不再發生);repro triage 觸發改「可疑席(引句錨不到/通用回應)」;落地驗證=[[Verification/2026-08-14_canary協議停用none制落地]]
  KEY:[2026-08-05]UI 層驗收慣例(MCP 接驗證層,Enzo 靈感;立慣例不綁案)——test-layers 宣告 layer 含「UI 驗收」的棧被 diff 命中時,終審驗收=agent 以 Playwright MCP(乾淨瀏覽器)/claude-in-chrome(真登入態)真開頁執行驗收條款,截圖+console 證據存 governance/review-reports/<loop-id>/ui-evidence/ 由 Verification 引用(哲學同 quote-check:證據可重放非口頭);起不了環境=明記未驗+原因不得靜默跳;Landmark .lumos/test-layers.json 已宣告 vue/html/js→UI 驗收、cs→dotnet test;首用=下一個天然帶 UI 面的工作(RSNO 暫緩,人裁);★Android 通道(2026-08-11,[[Projects/Android側UI測試綁架構圖工作流_計劃]])★=maestro MCP list_devices→inspect_screen→run,與 Playwright/chrome 並列;★前置:只准對「已標可自動且測試門店已確認」的 flow 自動跑★(否則會在真裝置真後端開真單),未達條件的 flow 一律僅手動、終審走 lumos code-loop skip --note 留痕
  KEY:[2026-08-05]pitfalls --diff 排除 governance/review-reports/ 路徑——歸檔證物(席報告/canary 快照 .patch)★故意★含 bug,當代碼掃=push 被自己的留痕擋下(C 慣例落地首推實錄);排除不外溢(收緊釘:同內容在該路徑外照掃) [test:t_pitfalls_diff_skips_review_report_artifacts]
  KEY:[2026-08-11]同型第二例——簿記帳也排除(_BOOKKEEPING_FILES/_DIR:治理帳/usage-log/ci-log/anchor-baseline/code-loop 留痕)。★自我餵食迴圈★:治理帳裡記的 skip 理由本身在描述「命中 open(...)」→掃自己的紀錄再次命中→再 skip→再寫一行理由進治理帳,實測誤觸發 9 次(3978732、837bbff 等皆此形態)。白名單與 code-loop 留痕失效豁免★共用同一組常數★(原本 code-loop 端寫成區域變數,兩處會漂移) [test:t_pitfalls_diff_skips_bookkeeping_ledgers]
  KEY:[2026-08-05]missed 席 findings 改★機械 repro triage★(取代直接丟)——canary 硬閘不動(該席判決仍作廢),但 findings 逐條試真碼/真跑證實;證實走通道 a 折入(note 記「機械證實非席信用」)、repro 不出才丟。實證=T8 r1 missed 席兩條真 major 靠 repro 撈回,原「撈」是編排者裁量現為硬步驟(結構性誤殺的機制化補丁;與 design-loop d4 分流不變:代碼有真 oracle 故走 repro 不走「不作廢」)
  KEY:[2026-08-05]席報告留痕慣例+收貨 quote-check(advisory)——報告落 governance/review-reports/<loop-id>/(原躺 scratchpad 蒸發,帳上 note 指空;T8 實錄);record 帶 --report/--snapshot 讓 sha 落帳(不帶 findings_set 不觸 T6 定錨);逐席 quote-check 對工作副本驗引句(§3 錨定紀律的機械收貨端;不進 gate,panel 判準一字不動)
  KEY:[2026-08-04]pass/skip 留痕的簿記白名單豁免([[Issues/code-loop-pass自失效追尾]])——留痕 sha 之後的 commit 只動簿記檔(治理帳/usage-log/anchor-baseline/code-loop 留痕)且留痕 sha 為目標祖先 → 留痕仍有效;其他檔一動照樣失效、改寫史拒認。「HEAD 移動→作廢」原意=pass 不得蓋到新代碼,此為精化非放寬(原嚴格等值下 pass 自己 append 的治理帳行被 commit 即自失效→追尾) [test:t_codeloop_pass_survives_bookkeeping_commits]
  KEY:[2026-07-18]codestage S1/S5 落地(設計[[Projects/code階段強化_計劃]],4輪審計30條折入+實質收斂人裁)——S1 真跑優先(綁約合約 pass 前必真跑綁定測試,解析三順位不得靜默跳過;紀律層)+確定性驗證器三通道參與(不佔canary席;M2帳下capture advisory裁決歸機械證實通道)/S5 辯方預設Codex+tier-high雙Codex角色(帶餌finder佔W+無餌否決席外掛,落閘=M2記disputed-major)+家族否決保護+fail分級(high外家缺席不得收斂攤人)
  KEY:[2026-07-10]panel 追加 spec-conformance slot(tier=high 且有收斂 spec→對答案審查員,四類:已實作/縮水/多做/未實作;templates §7.5)
  FLOW:pitfalls spec 模式(剝除對齊 assess_spec+防呆→掃 PITFALL_CLASSES 四類→印通用3問+命中類追問)｜--check(命中類且無「## 實務隱患」節→rc1)｜--diff(掃新增行 Check H 骨架+代碼形態 pattern→manifest{file,line,class,pattern,question}+stack_questions(命中 kt/cs/vue/sql 附該棧效能問,源=[[效能檢核目錄]])+尾行 tier;line 由 @@ 推導;rc 恆0)→ 尾行 tier 分流:trivial 跳(commit 註明)/standard 走單 reviewer 終審/high 觸發 lumos-code-loop 終審對抗審(bug canary 四型+辯方+K-streak∧G2 收斂,loop status --gate 無 --spec G1 skip)
  KEY:兩層隱患兩錨點——設計決策級(冪等鍵/重試策略)錨 spec 層 pitfalls --check;代碼級(N+1/race/資源洩漏)錨終審 --diff+code-loop。補審計火力頭重腳輕(spec 有整套對抗機器、代碼原只兩道普通眼)
  KEY:三道防污染(不可違反)——真代碼永不含(fix 錨真 diff file:line、canary hunk 不在真 diff)｜低耦合植入(canary 座標在真改動集外=pillar-1 機械前提)｜溯源排除(含間接聯想幻影,未顯式引用亦排;偏多排)
  KEY:PITFALL_CLASSES 四類名 ≡ difficulty.RISK_CLASSES、_PITFALL_BLACKLIST ≡ difficulty._BLACKLIST——漂移守衛落 test_autonomous_loop.py(toolchain-only、非 vendored);詞表/pattern 表自帶 scripts/lumos(difficulty.py 不 vendored)
  KEY:diff class 用代碼形態類軸(併發/效能/資源)非四業務類;pattern 去重疊(SELECT→效能 N+1、INSERT/UPDATE/DELETE→併發交易);過濾繼承 Check H 全套(skip .md/.txt/.rst+測試檔+註解行)
  KEY:誠實天花板——pattern 提示器非偵測器(單行掃描,跨行語境小行窗啟發為限)｜canary 校準+溯源排除靠自律｜--check 只驗節存在不驗內容｜mutation 冒煙抽樣非覆蓋｜code-loop 少一道 G1(--spec 可選、G1 skip)｜事故語料進架構圖留 v2
  DEP:[[risk-tiered-review]](分級哲學延伸到 diff 層)｜[[convergence-evidence-gate]](gate --spec 改可選)｜[[lumos-refcheck]]｜doctor Check H(diff 掃描骨架)
  TEST:t_pitfalls_spec(9)+t_pitfalls_diff(11,含行號值+併發寫入)+TestPitfallsDrift(2,類名+黑名單)+t_loop_gate 案14翻契約+t_loop_gate_no_spec;374 passed
  VERIFY:[[2026-07-04_pitfalls-code-loop]]
decisions:
  - content: 共用層(手動 pipeline + 自主 loop 都吃);checklist=通用3問+類專屬追問;載體=lumos 新指令;--check 機械擋;code-loop 風險分級觸發;醒著訊號=reviewer bug-canary+mutation 冒煙
    id: d1
    context: 效能/併發主戰場在業務專案、治理面在 loop,擇一都缺半;純 prompt 違反 mechanical-not-motivational;全分支跑 code-loop 日常太貴
    why_chosen: 每軸都選機械可驗+分級控總量;bug canary 驗審查層醒著、mutation 驗測試層守著,兩者正交
    decided: 2026-07-04
    valid: true
  - content: 代碼 canary 用三道防污染(真代碼永不含+低耦合植入+溯源排除),不採純 mutation
    id: d2
    context: 使用者質疑代碼 canary 污染風險比 spec 嚴重(假 hunk 改變語意、reviewer 推導衍生幻影 findings)
    why_chosen: 需醒著訊號(無則蓋章 reviewer 連 2 LGTM 空轉收斂,r9 opus 都漏抓);mutation 只驗測試層抓不到審查層敷衍;三道防污染把污染封到「必留可見痕跡」
    decided: 2026-07-04
    valid: true
related:
  - "[[Projects/impact-diff橋接_計劃]]"
---
# pitfalls-code-loop

`lumos pitfalls` 三模式 + `lumos-code-loop` skill——**實務隱患意識 + 代碼審計對齊**。

## 動機
AI 開發仰賴模型自決實作方式、只需通過最終驗證,但實作選型的實務隱患(效能/冪等/併發/資源)沒人逼它回答;且審計火力頭重腳輕——spec 有 canary/辯方/跨家族/證據閘一整套對抗機器,代碼只有 task reviewer + 終審兩道普通眼睛。

## 組件
- `scripts/lumos` `cmd_pitfalls`:三模式(spec 提問 / --check 缺節擋 / --diff 代碼風險 manifest+tier),vault-free、詞表自帶。
- `cmd_loop_status --gate` 的 `--spec` 改可選(缺 → G1 skip;供 code-loop 吃 G2 枯竭錨)。
- `skills/lumos-code-loop/SKILL.md`:對抗代碼審(bug canary 四型+三道防污染+辯方+證據閘+mutation 冒煙),tier high 觸發。
- 接線:orchestrator-prompt(步驟1節名+2.8 pitfalls --check)/graph-discipline(終審前 --diff→code-loop)/design-loop skill(審前 --check)/project-notes(指令表+gate 契約)。

## 相關
- 設計稿:`docs/design/2026-07-04-pitfalls-code-loop.md`(design-loop 8 輪 K=3 收斂;qwen major 機械反證後 endorsed-after-refute)。
- 實作計畫:`docs/superpowers/plans/2026-07-04-pitfalls-code-loop.md`。
