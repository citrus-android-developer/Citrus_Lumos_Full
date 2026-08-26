---
type: system
status: done
created: 2026-07-03
updated: 2026-08-14
self_audit: sonnet/2026-07-24
tags:
  - type/system
  - status/done
  - risk/守衛面
verified_by:
  - "[[Verification/2026-07-03_convergence-evidence-gate]]"
  - "[[Verification/2026-07-09_loop三輪壓縮]]"
  - "[[Verification/2026-07-10_審計loop研究硬化]]"
  - "[[Verification/2026-08-05_panel-K2與抽查落地]]"
  - "[[Verification/2026-08-14_殘餘估計降級與重疊報表落地]]"
summary: |-
  KEY:✅[2026-08-05 A案落地]panel K=1→★K=2★(cutoff 2026-08-06 起新 loop;首筆 ts 定錨不回溯,env LUMOS_PANEL_K2_CUTOFF 覆寫供測試)——最後兩輪★各自★過三條合取(前一輪 quiet 評估印一行摘要;單一實作 _panel_round_conjuncts 兩處共用);cluster 路同窗(前一輪須為有效輪)。+(e') 收斂後決定性抽查判定:PASS 印 sha256(loop_id+rid+該輪 token 集)%2 應抽/免抽——輸入全來自 append-only 帳,人人可事後重算,不依賴編排者誠實;應抽→加開 probe-* 輪(材料全量/席可縮 3/不計 cap/上限 1 次),★撤銷自動化=probe 冒 major 時 K=2 窗滑入髒輪 gate 自然 FAIL,零新機制★。防浮動條款:判準凍結,唯一翻案通道=攢滿 20 筆抽查帳。證據與五候選裁決全程=[[Projects/panel收斂判準改革_計劃]](design-loop r1+r2 收斂) [test:t_panel_k2_and_probe]
  KEY:★收斂 K 值依模式而異,而 skill 曾在四處講錯或漏標(2026-08-03 修)★——★循序模式 K=2★(`--need 2`,code:`all(good(r) for r in rounds[-need:])`);★平行 panel 模式 K=1★(code:`_loop_status_panel` 只取 `next(reversed(groups.items()))`,只看最後一輪)。錯處:①code-loop SKILL 頭版只寫「連 2 輪」與同份文件 panel 節的「一乾淨輪即收斂」自相矛盾 ②code-loop SKILL/reference 把 `tier: high` 標成「(K=2)」——★講反了★,tier=high 實務走 panel 即 K=1 ③design-loop 誠實天花板寫「連 2 輪醒著的審計員」,對 panel 使用者不成立。★後果★:看頭版的人與照 code 跑的人得到不同結論,而★兩邊都覺得自己在照規矩走★——2026-08-03 使用者問「本來不就是乾淨兩輪才放行嗎」才暴露,當時我四輪都跑在 panel 下卻用 K=2 的心智模型講話。
  KEY:~~panel 判準最鬆(K=1)未經檢驗~~——✅2026-08-05 A案已解(上行);歷史脈絡保留:外部案例研究 arXiv 2605.12280 §3.5 明確建議「two consecutive clean passes」當複現判準,具名理由=「stopping rule is a known source of ★premature-termination risk on stochastic LLM auditors★」;但那是 N=1 case study,且 panel 的 K=1 當初是用「多席平行買廣度」換來的,該取捨可能仍成立。★本次刻意只修文件矛盾、不動判準★(動判準屬守衛面,要另走 design-loop)。★同篇論文另外兩條直接證據★:嚴重度評審間一致度 κ=0.46 vs 分類 κ=0.80(支持「嚴重度不該單獨當閘」);四家廠商 ×3 跑,★聯集才抓到全部 5 個種子缺陷★,而 Anthropic 那家嚴重度一致度最低(0.57)、誤報最高(1.33)——支持跨家族席,且★我們自己就是那一門★
  KEY:[2026-07-10]panel 輪有效升級 near-perfect——caught≥2 且 0 missed(中段分數弱訊號不背書收斂;borrow mutation score 文獻,見[[Projects/收斂閘caught-rate修正_計劃]])
  FLOW:每輪 canary record --findings N(辯方存活折入條數)→loop status --gate --spec <md> --repo <root>→K-streak(必要)∧G1(_refcheck_scan 引用座標 0 missing/0 超界)∧G2(findings 單調不增+末輪≤1+末步下降,K=1 退化末輪=0)∧G3(帶 --spec=聲明 hash 驗證:收斂窗雙 hash 鏈四驗,窗內無 hash=FAIL 非 advisory;不帶 --spec 舊用法不驗——[2026-07-21 M1包])→全過 GATE PASS rc0｜cross_audit:_build_prompt sentinel 定界+_parse_worst 末行優先回(sev,parse_fallback)→§2.5c 計票:≥major 經機械驗證存活才 +1 reject,全反證=endorsed-after-refute 放行
  KEY:收斂判準從「輪次算術」升級「證據錨」——「連 K 輪各挖 5 條 minor」與 [1,1] 穩態涓流不再算收斂;輪次紀律保留為必要條件非充分條件(退役的是充分性)
  KEY:向後相容三條——不帶 --gate 輸出與 rc 分毫不變;不給 --findings 鍵不寫;run_cross_audit 既有鍵不動只增 parse_fallback
  KEY:G2 fail-closed(tail-K 缺 findings 欄位即擋)+ 欄位互證(clean⇒0、minor⇒≥1,矛盾即擋);G1 用 _refcheck_scan 只驗 spec→repo 指涉、不驗內部一致性(canary 保留地)
  KEY:Confident Liar 條款(§2.5c)——unanchored(指控與 ground-truth 無字串交集)單獨不撐 reject;parse_fallback 遍不計票;disputed 門票從「qwen 喊 major」改「喊的 major 驗過還站著」
  KEY:誠實天花板——findings 數源頭仍是 LLM 裁決(gate 機械化算術非數字正確性);枯竭≠挖乾(同門盲點趨同);sentinel 擋混淆不擋對抗注入;§2.5c 是 prompt 層散文契約無機械回歸守衛;換 loop_id 洗紀錄仍可(hash 綁 loop 內容非 id);--spec 綁定向量已清償([2026-07-21 M1包]雙 hash 鏈落地,見[[Projects/loop機械脊椎M1包_計劃]]:record --spec/--reviewed 成對寫 reviewed/result 兩欄,gate 帶 --spec=聲明要驗——收斂窗 all-or-nothing+鏈續性+同輪雙欄一致+窗末=當前檔,G3 段;不帶 --spec 舊用法 advisory 不變;light 恆強制)
  KEY:平行 panel 收斂(2026-07-09,`--panel`,見 [[loop三輪壓縮_計劃]])——G2 序列枯竭是**循序深度**信號、配不上平行拓樸;panel 模式合取=輪有效(記帳席≥2且0missed,none 制)∧存活 max≤minor;capture-recapture 殘餘估計★2026-08-14 降 advisory 不進合取(鑑別力≈0:殘餘<1 組下輪 major+ 67% vs ≥1 對照組 79%,p≈0.25;f1≤1 公式退化;見[[Projects/收斂閘殘餘估計降級_計劃]])★——觀測行照印、無 counts 印缺席提示不 fail;legacy K-streak∧G1∧G2(無 --panel)完全不變
  DEP:[[lumos-refcheck]](G1 消費 _refcheck_scan)｜[[canary-audit]](記錄面)｜`governance/autonomous_loop/cross_audit.py`(2026-08-08 補鏈:原裸文字提及正名為標準引用)
  TEST:t_canary_findings 3 + t_loop_gate 16 checks(CLI)+ TestCrossAudit 新 4(unittest);352 passed 全綠
  VERIFY:[[2026-07-03_convergence-evidence-gate]]
decisions:
  - content: 方案 A(判準增強落在既有 loop status 的 --gate 旗標);否決 B 統計離散度模型與 C 只修 cross_audit 定界
    id: d1
    context: B 的權重/閾值全是拍腦袋參數,把「一致≠正確」換成「權重≠正確」,違反 mechanical-not-motivational;C 只治複核端不動判準本體
    why_chosen: 每道錨都是確定性核對(rc/字串比對/整數單調性),零權重參數;複用已落地 refcheck;向後相容
    decided: 2026-07-03
    valid: true
  - content: 「留痕完整」不設錨——它是 K-streak 的邏輯後果({streak 通過}⊆{留痕完整}恆真),另設=零判別力裝飾
    id: d2
    context: design-loop R1 辯方對此 major 反駁失敗、維持原判,導致當輪拆錨重構(gate 從三錨收斂為兩錨)
    why_chosen: 誠實拆除不湊門面;歸因回歸測試(缺 severity 斷在 K-streak)固定此結論、防未來重新發明空錨
    decided: 2026-07-03
    valid: true
  - content: cross_reject 計票改「≥major 經機械驗證存活才 +1」,全反證=endorsed-after-refute 放行
    id: d3
    context: qwen disputed 三連(refcheck/loop-stall×2/本 spec)的 ≥major 指控經機械驗證全數不成立,仍消耗放行預算逼人裁;本 spec 自己的放行路徑上 _parse_worst fallback 撿引文誤報 blocker 現場重演
    why_chosen: 自信但經不起機械驗證的否決不該有否決權;disputed 升級人核精神保留,只改門票條件
    decided: 2026-07-03
    valid: true
aliases:
  - Confident Liar
  - capture-recapture
---
# convergence-evidence-gate

design-loop 收斂判準升級:**輪次算術 → 機械證據錨 + 發現枯竭**。四組件:`canary record --findings`(記錄面)、`loop status --gate`(判準面)、cross_audit sentinel 定界+解析硬化(根因修)、§2.5c 計票語意(prompt 層)。

## 動機
「連 K 輪一致」量的是穩定不是正確——審計員可每輪自信地漏同一個洞,跨家族複核可連兩輪言之鑿鑿指控不存在的問題(7/2-7/3 日報 + qwen disputed 三連實證)。收斂的最後一判改錨在騙不過的東西上:機器核對的引用座標、機械可讀的發現枯竭序列、經得起實跑反證的否決。

## 消費端
- 自動 loop:`governance/autonomous_loop/orchestrator-prompt.md` 步驟 6(--findings)/8(--gate)+ §2.5c 計票。
- 手動 loop:`skills/lumos-design-loop/SKILL.md` 硬閘/步驟 5/步驟 8。
- 方法論:`docs/methodology/架構圖即合約.md` loop 表證據閘列 + 原則 5 計票句。

## 相關
- 設計稿:`docs/design/2026-07-03-convergence-evidence-gate.md`(design-loop 4 輪、canary 4/4、R1 辯方維持 major 拆錨重構;qwen disputed 經人裁機械反證後放行)。
- 實作計畫:`docs/superpowers/plans/2026-07-03-convergence-evidence-gate.md`。
