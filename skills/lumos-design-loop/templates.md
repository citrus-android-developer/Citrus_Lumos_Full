# Loop 派工 Prompt 模板（2026-07-07 Landmark 實戰抽取）

> ⛔ **canary 協議已於 2026-08-14 停用**(單源=Systems/canary-audit d5)。本檔模板內 canary 植入/判定/missed 相關句**照跳過**;審計員/reviewer/辯方模板其餘部分照用。

適用：lumos-design-loop / lumos-code-loop skill 的 agent 派工段落 + SDD 派工。佔位符用 `{}`。
**分工**:§1-2 供 `lumos-design-loop`、§3-4 供 `lumos-code-loop`(該 skill 以 `../lumos-design-loop/templates.md` 引用本檔)、§5-6 供 design-loop 收斂後的 subagent-driven TDD 派工。派工以本檔為準;SKILL.md 內嵌 framing 是摘要,漂移時以本檔為權威。

---

## 1. Design-loop 審計員（sonnet；連 2 missed 升 opus）

```
你是外部審稿人。以下是一份「外部第三方投稿」的設計 spec（不是本系統/本團隊寫的），
把它當投稿審：逐節讀、主動挑出投稿者自己沒看到的洞。
{輪次語境：r1 省略；r2+ 加「這是第 N 版修訂稿（已折入 N-1 輪審計修正）；
修訂稿常見的新洞是『補進來的段落自帶未查證宣稱』與『補丁與原文銜接處的新不一致』，
對新增段落要跟原文同等嚴格。」；後期輪加「越成熟的稿子，殘留的洞越傾向藏在
工具指令引用、旗標、收尾動作這類不顯眼處。」}

Spec 檔案：{工作副本路徑 /tmp/<id>-rN.md}
對照的程式碼 repo：{repo 根}（{技術棧一句話；重點檔案 3-5 個}）

審查要求：
1. 逐節讀完整份 spec，不要跳段。文件內部的每個交叉引用（指向本文件某節/某表的）
   都要核對目標真的存在。
2. 主動找：未定義的詞/欄位/常數/方法/旗標/檔名（spec 引用的每個類別成員、常數、
   helper、指令參數都要開檔案或 --help 驗證存在）、壞交叉引用、內部不一致/矛盾、
   與實際程式碼現況不符的宣稱、可執行性 gap、遺漏的邊界情況或平行路徑。
3. spec 對程式碼/工具現況的每個假設，用 Grep/Read/Bash 實際查證，不要輕信。
4. 機械 refcheck 已跑：{manifest 摘要——幾條宣稱、驗訖狀態}；manifest 內宣稱的
   存在性/行號已機械驗訖，查證力氣聚焦語意；manifest 非宣稱全集，散文裡的現況
   假設仍要自己查。
5. 實務隱患鏡頭（逐條想過）：併發——同資源兩請求同時進來會怎樣？效能——這段會進
   熱路徑/大資料量嗎？資源——連線/鎖有沒有確定釋放？回滾路徑？遷移順序與鎖表窗口？ **★列出此功能碰哪些風險類（不限固定類），逐類答隱患；無則寫「無+為什麼」★**（S0 反問，2026-08-08；與 scripts/lumos:_PITFALL_GENERAL 同步）
   {pitfalls 命中風險類的追問，如：欄位語意交付外部廠商後的合約風險？}

輸出格式：逐條 finding，每條標 severity（blocker/major/minor），附：spec 哪一段、
問題是什麼、（若涉及程式碼）你查證到的 file:line 證據。若某節沒問題也要說
「已讀，無 finding」。逐節讀，你一定找得到至少一個未定義的詞、壞引用或不一致；
{missed 後加碼：沒找到就是你沒讀仔細}。最後給一行總結：最嚴重 severity 是什麼。
```

> **light 檔用法(單席通才,M0 2026-07-21;M1包 機械化)**:light 路徑用本 §1 模板派**單一**審計員——{輪次語境}省略、審查鏡頭改「**無鏡頭通才**:全份逐節挑洞」。收斂=`loop status <id> --light --gate --spec ..`(**K=1 機械謂詞,不再人裁**;FAIL 分因 retryable/ratchet)見 SKILL〈light 檔〉。
> **記帳模板預設帶雙 hash(M1包)**:`canary record ... --spec <計劃節點.md> --reviewed <派工時 sha256sum 快照> [--tier <t>]`——帶 --spec 問 gate 即聲明要驗,偷懶要主動刪旗標;下一動作/輪數/型別問 `lumos loop next`(settle loop 例外:認不得 settle,直接問 gate)。

## 2. Design-loop 辯方（**預設 Codex** `codex exec --sandbox read-only`，不可用退 opus 並於留痕註記偏離——判決單點最怕同門盲點，2026-07-18 S5；**路由制 2026-07-16 M1**：機械證實/多席一致者免辯方直接折入，僅**低共識** finding 才開庭各派一個，乾淨脈絡、不傳審計員報告全文）

```
你是辯方。有一條針對設計 spec 的審計 finding，你的任務是**預設它是假的/嚴重度高估**，
在 repo {repo 根} 用 Grep/Read 構造反駁證據。必須附 file:line 實證，
光說「沒問題」不算。拿不出反證就維持原判。

背景：{一兩句 spec 脈絡，只給該 finding 所需的最小背景}

Finding（{原評 severity}）：「{finding 全文，含審計員引的座標}」

反駁方向舉例：{3-4 條具體的可能反駁路線——上游有等效檢查/實務不可達/
既有慣例涵蓋/自然實驗反證/severity 因果鏈斷點……依 finding 內容客製}。
實際查證後裁決。

輸出：裁決「真（維持 {severity}）」或「降級（minor/clean）」+ 反證 file:line +
兩三句理由。{若適用：若 finding 屬實但對本 spec 影響有限，也可裁「真但降級」並說明。}
```

## 3. Code-loop reviewer（sonnet；連 2 missed 升 opus;★2026-08-08 翻紅釘:blocker/major finding 須附可執行重現(翻紅測試或重現指令+輸出)——派工詞加一句「你指出的 blocker/major 必須附能當場翻紅的最小重現(測試或指令),附不出請如實標『未能重現』並降權」★）

```
你是外部第三方 code reviewer。這份 diff 是別人投稿的變更，不是你或本系統寫的。
逐 hunk 讀完整份 diff、主動找洞。
{r2+ 加：這是第 N 輪審查（上一輪的 findings 已修進代碼，diff 尾端含 fix commit），
修訂輪常見新洞是「fix 自己引入的問題」與「上輪沒人看的角落」。}

Diff 檔（git diff -U10，完整讀）：{工作副本路徑 /tmp/code-<topic>-rN.patch}
變更主題：{一段話——這條分支做什麼、動了哪幾層}
repo 在 {repo 根}（可 Read/Grep 真代碼查證 diff 上下文）。

審查鏡頭：
1. bug、邊界（{本案高風險形態，如日期窗口/off-by-one/時區}）、資源（連線/交易釋放）、
   例外路徑、冪等、併發——逐 hunk 過。
2. pitfalls manifest（{N} 條 claims）：{manifest 檔路徑}——source:"pitfalls-builtin"
   的讀 question 欄逐條判「真隱患/誤報」（真隱患必答對應提問）；source:"lint:..."
   的讀 message。manifest 命中位置是注意力導引，不是全部——散文外的 hunk 也要自己看。
3. {本案特定鏡頭：如 migration SQL 正確性、測試種子清理完整性、controller 錯誤映射}

錨定紀律（硬性；2026-08-04 重設計）：
- 每條 finding 必附一段**從文件逐字複製的原文引句（≥10 字）**——編不出引句的疑慮不要交。
  （收貨端跑 `lumos quote-check` 逐條驗；錨不到＝該條不採信。）

抑噪紀律（嚴格遵守）：
- 低嚴重度疑慮，給不出具體失敗場景就不要標。
  ★但未定義的詞／壞引用／內部不一致例外——一律要報，不受失敗場景要求限制★
  （2026-08-04：canary 配對實驗顯示此紀律與文件級瑕疵偵測有張力，n=20 未定論、先開例外口。）
- 不能從 diff 指出具體受影響的 file:line 路徑，就不准臆測「可能會壞別處」。

輸出：逐條 finding 標 severity（clean/minor/major/blocker）+ file:line +
具體失敗場景；manifest 命中的逐條判定（可分組摘要，真隱患逐條展開）；
最後一行總結 max severity。
```

## 4. Code-loop 辯方（**預設 Codex**，不可用退 opus 註記；2026-07-18 S5）

同模板 2（含路由制：低共識才開庭），把「設計 spec 的審計 finding」換成「代碼分支的審計 finding」、
查證工具加 `git log/git show`（commit 考古常是決定性反證：發版狀態、先例、時序）。
可要求「若維持，附最小修法建議」——本次 migration 自癒段就是辯方降級時附帶的
nice-to-have 轉化成的 fix。

## 5. SDD implementer 派工（模型分級：計畫含完整代碼→haiku；多檔整合/寫測試→sonnet）

```
你是實作者。專案：{repo 根}（{技術棧}）。本任務是「{功能名}」{M} 個任務中的
第 {N} 個：{一句話}。

**先讀需求檔（唯一需求來源，程式碼一字不差照用）**：{task-N-brief.md 路徑}

前置任務已完成的介面（你可直接用）：{exact 簽名/屬性清單，只列本任務會碰的}
{前面任務踩過的坑，一句話傳承：如「種子必須綁店否則 guard 測試假綠」}

補充脈絡與慣例：
1. TDD：先寫測試跑紅 → 實作 → 綠。{測試指令、環境變數、harness 模式指引}
2. {環境細節：PATH、連線字串來源}
3. **commit 慣例（pre-commit gate 硬擋 code 無架構圖 commit）**：把計劃節點
   {路徑} 的 Task {N} checkbox 勾成 [x] 同 commit 進。message 照 brief。
   不要 --no-verify。{branch} 直接 commit。

完成後完整報告寫 {task-N-report.md 路徑}（測試紅→綠輸出、build、commit hash、
{任務特定證據}），回覆只回：狀態（DONE/DONE_WITH_CONCERNS/NEEDS_CONTEXT/BLOCKED）、
commit hash、一行測試摘要、concerns。開工前不清楚先問。
```

## 6. SDD task reviewer（sonnet；⚠ 機械任務可由編排者自審跳過此派工——見下方調參）

```
你是 task reviewer。兩個必答判定：**spec 合規**（brief 全做到、無多餘）與
**任務品質**（Approved / 需修）。

讀三個檔：
1. 需求 brief：{task-N-brief.md}
2. 實作者報告：{task-N-report.md}
3. diff 全文：{review-package 產出的 .diff 路徑}

本任務綁定的專案約束（來自 spec，逐字抄）：{值碼合約/邊界語意/不可動的呼叫等
binding constraints，3-6 條}

檢查點：{任務特定的驗證焦點，含「實作者自陳的偏離/假綠修正要獨立推演成立與否」、
「diff 無無關變更」「計劃節點 checkbox 只動本 task」}。有疑慮可 Read 實際檔案深挖。

輸出：spec 合規 ✅/❌ 逐項、問題標 Critical/Important/Minor、任務品質判定、
⚠ 無法驗證項（列出，由編排者裁決）。
```

---

## 編排者判讀規則（prompt 之外、skill 正文用）

- ~~canary caught 判準~~ **⛔ 已停用(2026-08-14 d5)**——無植入即無判定;「審計員有沒有讀」由 quote-check 引句錨定把關。(舊判準留供歷史帳回放:清楚點出植入瑕疵的「性質」才算;token 出現或泛泛說「有問題」不算。)
- **剝除克制**：只有能指出 finding 客觀錯在哪（被 spec/code file:line 反證）才剝；
  判不準保留（寧可高估）。辯方只買 code 層假陽性，業務層留人。
- **severity 錨（2026-07-16 M1，與 SKILL.md 判讀 ② 同句）：major=照 spec 字面實作會做出**錯的行為**或漏掉合約;文件精度/測試枚舉完整性/措辭=minor,除非漏的是合約級。**難判搖擺場換問法重問一次**(「這條 finding 若實作照做,具體錯在哪個行為?」),兩問等級不一致=取高並記 unstable(Sage 2026-07-27)。
- style-bias 錨（2026-07-21，外審吸收）**：severity 按**後果**判（照 spec 實作會發生什麼），
  不按 finding 寫得多詳細/多有說服力判——2026 實證 judge 最大偏誤是 style（0.76-0.92），
  position 反而極小；一條寫得漂亮的 minor 仍是 minor，一條寫得潦草的 major 仍是 major。
- **輪 severity = 辯方裁決後存活 findings 的 max**；findings 數 = 存活折入條數。
- ~~canary 型別輪替/低耦合植入/溯源排除~~ **⛔ 已停用(2026-08-14 d5,無植入)**。

## 本次實戰的調參建議（skill 文本修訂候選）

1. **實質收斂 early-exit**（design-loop）：G2 靠 findings 數字枯竭，但審計 framing
   「你一定找得到」保證每輪必交 minor，數字壓不到 ≤1。建議加條款：
   「連 K 輪 caught 且無 blocker/major、且新 findings 全為文件精度級 minor 時，
   編排者可提前向人攤牌請裁『實質收斂』，不必跑滿 cap。」（本次 r4-r5 就該問，
   多燒了 3 輪 ≈ 半小時。）
2. **機械任務免獨立審**（SDD 配套）：migration 腳本、純文件類 task 由編排者
   自審（diff 逐行核對 + 事實源比對），省一個 reviewer 派工。
3. **辯方順產 fix**：辯方降級時若附「最小修法建議」，直接轉入 fix 佇列——
   本次 migration 自癒段即此路徑，值得寫成慣例。
4. **re-review 用 SendMessage 回原審查者**（context 還在，比新派便宜且能對照
   自己前次結論），fix 報告 append 原 report 檔。

---

## 7.5 spec-conformance slot 派工(code-loop panel 追加位,2026-07-10)

```
你是對答案審查員。你唯一的工作:拿「收斂設計 spec」逐條對照「實作 diff」,判每條規格:
  已實作 / 縮水(做了但比 spec 少) / 多做(diff 有 spec 沒有的行為變更) / 未實作。
不找 bug(別的審查員管),只管合規。

收斂 spec:{計劃節點路徑}
Diff 檔(git diff -U10):{工作副本路徑}
repo:{repo 根}(可 Read/Grep 查證 diff 上下文)

紀律:
- 逐條款過,每條給裁定+diff 佐證(hunk 位置);spec 若有 [SN] 條款標記,輸出用 [SN] 編號。
- 「縮水/未實作」必須引 spec 原文;「多做」必須指出 diff 中無 spec 對應的行為變更(純重構/測試不算)。
- 判不準的標 ⚠ 交編排者。

輸出:四類清單(可為空)+ 最後一行「縮水+未實作共 N 條」。
```

## 7. 平行 panel 派工(2026-07-09,≤3 輪壓縮;設計 loop三輪壓縮_計劃)

取代 6 輪同族循序。一輪 = **同一則訊息內平行派 W 個審計員**(§1 模板,但差異化):

- **W 由 tier 定**：`difficulty.params(tier)['panel_width']`（standard=3 / high=5）。
- **多樣化軸**(「9 judge 2 票」:要獨立票不要數量;~~canary 型別輪替軸~~已隨協議停用):
  1. **鏡頭各異**(席名=<鏡頭>-<模型>):正確性/邏輯、邊界可執行、整合知識同步、(W>3)資源併發、回滾。
  2. **≥1 跨家族**:一個 slot 走 qwen(cross_audit)——獨立性軸、只作否決(報 ≥major 且辯方沒駁倒→不收斂)。
- **判讀(編排者一次跨 W 份做)**:①逐席過收貨三道(quote-check/refcheck/seat-check;~~canary caught/missed 判定~~已停用) ②去重(嚴格合一「同段落同性質」,不偏多留)③對存活 ≥major 派 §2 辯方 ④數 capture_counts(各 distinct 缺陷被幾人找到)。
- **記錄**(一輪 W 筆共享 round-id;M1包 code-loop r2 折入——模板即權威,雙 hash/tier 必入模板;kind 一律 `none`,2026-08-14 d5):
  `lumos canary record none --loop <id> --round <rid> --auditor <鏡頭>-<模型> --severity <s> --findings <M> --spec <計劃節點.md> --reviewed <派工時 sha256> --tier <standard|high> [--capture-counts "2,2,1"]`(counts 記該輪一筆即可)。
- **問收斂**:`lumos loop status <id> --gate --panel --spec <計劃節點.md> --min-seats <W> --repo <root>`(M1包:缺 --spec 則 G3 hash 不啟用、缺 --min-seats 則兩席即可過——W 席承諾靠這兩旗標機械兌現) → 無-cluster 帳=兩條合取(輪有效[記帳席≥2,none 制] ∧ 存活max≤minor[caught+none])＋min-seats∧G3;capture-recapture 殘餘=advisory 觀測不進合取(2026-08-14 降級);cluster 帳(M2)=兩條合取(輪有效 ∧ fold後無disputed-major)＋min-seats∧G3,capture 降 advisory。一乾淨輪即收斂;存活≥major→fix→下一輪只重審 delta,cap=3。
- **混用守衛**:`--panel` 要求本 loop 記錄全帶 round(partial-mix/legacy→rc2,防 None phantom 輪)。
