---
type: system
status: planned
created: 2026-06-26
updated: 2026-06-26
self_audit: sonnet/2026-06-26
tags:
  - type/system
  - status/planned
summary: |-
  FLOW:vault git 史 ─A.mine→ candidates.jsonl ─B.label(人)→ fixtures.jsonl(進git黃金集) ─C.run(複製L3 pre-LLM 成本閘→importlib 載 hook→build_prompt+call_claude_sonnet→正規化None/缺鍵)→ report(recall/precision/門檻敏感性表)
  KEY:量化 L3 腐化偵測(verification-rot-check.py)的真實 recall/precision，把 CONFIDENCE_THRESHOLD=0.7 從拍腦袋變成從門檻敏感性表挑——是一把尺、不是新閘(不改 hook、不接 CI 擋線、不改 doctor)
  KEY:零重寫保真——unit C 用 importlib.util.spec_from_file_location 載 hook(檔名帶連字號不能 import)，跑線上同一把 build_prompt+call_claude_sonnet 判斷；monkeypatch 打 hook_module.call_claude_sonnet 模組屬性
  KEY:報告數字是「LLM 判斷層 recall」非「整條 pipeline recall」——eval 直接把對的 Verification 餵進去、繞過 find_candidate_verifications 搜尋層；真實 pipeline 還要再乘搜尋層命中率、只會更低
  KEY:倖存者偏差——git 史只有「被發現並修掉」的失效，量出的 recall 是上限、真值更糟；當方向儀不當精密尺(N~15-30 吵雜)
  KEY:狀態=design-only prototype 規範(CONVERGED 5輪)，尚未實作；scripts/rot-eval/ 與 lumos 子命令皆未落地
  DEP:scripts/hooks/claude/verification-rot-check.py(L3,被量的對象,不改)｜build_prompt/call_claude_sonnet/MIN_DIFF_LINES/MAX_DIFF_LINES/CONFIDENCE_THRESHOLD
  TEST:設計級測試策略——mine 給合成 git fixture repo、run monkeypatch call_claude_sonnet 驗算分(不燒 token)、label 純人工不自動測；尚無實作測試(t_-prefixed 未建)
  VERIFY:無(design-only,無真機/測試數證據)
decisions:
  - content: diff_text 必須是「動了 code 的 commit 之完整 diff」(不過濾 code/md/yaml)，純架構圖 status→stale commit 不是 L3 場景；overturn_commit 自身有 code diff 則用它，否則時間窗回溯(30 天內或最近 10 個 code commit)找動到節點 valid_under 符號的 commit，皆無則 null+drop
    id: d1
    context: design-loop R2 兩個 blocker 推翻 R1 自己的修法——F1:L3 的 get_diff_text() 跑 git diff HEAD~1..HEAD 完全不過濾、餵 prompt 的是整個 commit 完整 diff，且因 hook 對無 code 變動 commit 早退(if not code_files: return 0)、L3 只在動 code 的 commit 上跑；F2:Verification 記符號的欄位是 valid_under，不是 Systems 才有的 verified_by(R1 用錯欄位=死碼)
    why_chosen: 餵進 LLM 的料必須跟線上一致才量得準；R1 的「code-only diff」框架與「verified_by 回溯」都偏離 hook 實際行為，會讓 recall 系統性失真
    decided: 2026-06-19
    valid: true
  - content: unit C 必須複製 L3 main() 的三道 pre-LLM 成本守衛(code_files 非空、MIN_DIFF_LINES(10)≤diff_lines≤MAX_DIFF_LINES(2000))；過不了的 positive 不餵 LLM、不計進 LLM 層分母，改記為「被守衛跳過的 pipeline miss」
    id: d2
    context: design-loop R3 BLOCKER-2——不複製這些守衛會把 L3 線上根本不會碰(早退跳過)的 diff 也算進去，recall 虛高;R4 FINDING-2 釐清另兩道(candidates 非空=搜尋層設計性繞過、diff_text 非空=B 已 drop)不另複製
    why_chosen: 守衛跳過是 pipeline 層的設計性 miss、不是 LLM 漏判，混進同一分母會汙染「LLM 判斷層 recall」這個唯一誠實能量的數字
    decided: 2026-06-19
    valid: true
  - content: old_node_text 存整篇節點全文(frontmatter+summary+內文)、交給 build_prompt 自截(verification 1500/diff 4000 字)，不只擷結論
    id: d3
    context: design-loop R1 §5(最關鍵 blocker)——build_prompt 的 verification_text 線上吃節點全文，valid_under/revalidate_when 正是 L3 判「被驗證符號/契約有沒有被動到」的核心料；只餵結論會讓 LLM 少看關鍵欄位、recall 系統性偏低
    why_chosen: fixture 要忠實重放線上 prompt 構造；截斷邏輯留給 build_prompt 自己做才與線上一致(R3 MINOR-2)
    decided: 2026-06-19
    valid: true
---
# verification-rot-eval

量化 L3 腐化偵測命中率的 **prototype 評測尺**。拿 LandmarkMember 架構圖自己的 git 史造一組**有標準答案**的「失效題」，重放 L3(`verification-rot-check.py`)現用的判斷，量出真實的 **recall / precision**，把 `CONFIDENCE_THRESHOLD = 0.7` 從「拍腦袋」變成「從門檻敏感性表挑」。

> 源起:日報 2026-06-19 gap 1 ——「第三道腐化偵測本質上會漏掉約一半的隱性失效，而信心門檻是猜的、沒被量過」。外部依據:STALE 評測(arXiv 2605.06527)指最強模型也只認得出約 55% 的「舊資訊已被新事實推翻」。

## 定位與邊界(YAGNI)
- **是一把尺，不是新的閘**:不改 L3 hook、不自動調門檻、不接 CI 擋線、不改 doctor。
- **先當 prototype 腳本**(設計擬放 scripts/rot-eval/,待建),升格條件:三單元跑通 + 對 ≥15 組真實 fixtures 能講出「L3 在 0.7 大概抓 X 成、漏的多是哪一類」(即門檻敏感性表可讀、量級結論明確)後,才升格成 `lumos rot-eval {mine,run}` 子命令 + 週彙整觸發。
- **不追大 N 統計顯著**——這是方向儀(「就算 0.5 門檻也只 60%」這種量級結論),不是精密尺。
- **現況:design-only**。spec 已 CONVERGED(canary-護審計 5 輪、K=2),但 scripts/rot-eval/(待建)、`lumos` 子命令、回歸測試**都尚未實作**。

## 三個獨立單元
- **A `mine`(挖候選,絕不貼標)**:掃 vault `git log` 抓三類最顯性 git 訊號當候選——① Verification frontmatter `status: pass→stale`(排除 `pass→done`=成功完成非腐化);② `superseded` / 進 `Verification/Archive/`(篩除批次歸檔:同 commit rename ≥5 檔且 status 不變→排除;≥10 檔不論 status 一律當批次+交人複核);③ `summary`/`KEY:` 行被實質改動。每筆輸出 `{node_path, overturn_commit, diff_text, code_commit, old_node_text}` 寫成 `rot-eval-candidates.jsonl`。
- **B `label`(人工確認,產黃金集)**:把候選攤成可讀清單,人逐筆判 `positive`(真失效)/`negative`(code 動了但沒失效,量誤報)/`drop`(雜訊或 `diff_text=null`)。存 `rot-eval-fixtures.jsonl`(**進 git**)。
- **C `run`(重放 + 算分)**:見下「保真關鍵」。每筆 fixture 的 `diff_text` 取法:先看 `overturn_commit` 自身有無 code diff → 有則直接用;否則時間窗回溯(30 天內 **或** 最近 10 個 code commit,取先到者)找動到該節點 `valid_under` 符號的 commit → 皆無則 `diff_text=null` 並在 B 階段 drop。輸出 `rot-eval-report.md`,含 recall@0.7 / precision@0.7、門檻敏感性表(0.5/0.6/0.7/0.8;positive 數 < `MIN_FIXTURES_FOR_SWEEP`=5 時整表跳過、只報單點)、每筆 fixture judge 對錯。

## 保真關鍵(unit C 與線上同一把判斷)
1. **import**:hook 檔名 `verification-rot-check.py` 帶連字號不能 `import`,用 `importlib.util.spec_from_file_location("hook", <path>)` + `exec_module()`;monkeypatch 打 `hook_module.call_claude_sonnet`(模組屬性)。
2. **型別**:`build_prompt(verification_path: Path, ...)` 首參是 `pathlib.Path`(hook 取 `.name`),呼叫須 `build_prompt(Path(node_path), ...)`。
3. **接回傳正規化**:`call_claude_sonnet` 回完整 dict 或 `None`、且不做 schema 驗證 → 算分前一律把 `None`、或缺 `invalidates`/`confidence` 鍵 → 視為 `invalidates=false, confidence=0`(計進分母,規則寫死避免 N 小偏移)。
4. **pre-LLM 成本閘**:複製 L3 三道成本守衛(見 decisions[1]),過不了記 pipeline miss、不進 LLM 層分母。

## 誠實天花板(必寫進 report 顯眼處)
- **倖存者偏差**:git 史只有「被發現並修掉」的失效;沒被注意的那半不在樣本 → recall 是**上限**,真值更糟。
- **只量 LLM 判斷層,不量搜尋層**:L3 兩段都會漏——① `find_candidate_verifications` 沒撈出對的 Verification;② LLM 撈到卻判錯。本 eval **直接餵對的 Verification、只量 ②**;標題/結論不得簡稱「L3 recall」,真實 pipeline 還要再乘搜尋層命中率、只會更低。
- **守衛跳過 ≠ LLM 漏**:被 `MIN/MAX_DIFF_LINES` 跳過的 positive 是 pipeline 層 miss,分開記。
- **N 小**:fixtures 預期 ~15-30 筆,百分比吵雜;門檻表是不連續階梯(N~7 時最小粒度 ≈14%),只判量級、不精挑門檻。
- **標註也是判斷**:hybrid 人工確認把「何謂真失效」收斂到人,沒消滅它。

## 已知限制
- **執行環境(spec §7)**:unit C 真跑 LLM 靠 `claude -p --model sonnet`(Max 訂閱 CLI、無 API key)→ **只能本機跑、不上 CI**;CI 只跑 monkeypatch 模式驗算分邏輯。升格接週彙整觸發時這條限制要正面寫明。
- **第四類訊號留升格**:每個 Verification 的 `revalidate_when`(非 git、結構化)可配 code diff 比對,prototype 不做;不宣稱「竭盡」。

## 相關
- 設計稿:`docs/design/2026-06-19-rot-eval.md`(CONVERGED,canary-護審計 loop 5 輪、K=2;審計修正紀錄見尾段 R1-R4)。
- 被量對象:`scripts/hooks/claude/verification-rot-check.py`(L3 腐化偵測 hook,不改)。
