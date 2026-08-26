# 設計:腐蝕趨勢尺(corrosion-gauge)— loop 自我修改面的 code 退化跨輪入帳,單調上升標人核

- 日期:2026-07-14
- 狀態:draft(design-loop 審計中)
- 動機來源:2026-06-27 治理日報 gap「自主 loop 假設跨多輪自我修改可控,但實測長程迭代 agent 會累積架構腐蝕、早期決策滾雪球。19 模型基準顯示沒有模型能兼顧高解題率與低腐蝕。lumos 收斂判準只看『審計有沒有挑出問題』,不偵測 code 正在變膨脹冗餘」;建議加「腐蝕體檢」(死碼、冗餘結構、檔案膨脹),跨輪單調上升就標「卡住待人核」。
- loop_id:corrosion-gauge

PRIOR-ART: ① 最小解=無既有層可解——`.lumos/lint.json` 社群 linter 是單點 findings、code-loop 是單 diff 審,**累積型退化兩者構造上都看不見**(每個 diff 各自看起來都好,腐蝕只在時間序列上顯形);最小新件=1 個零依賴模組+1 支 lint-watch-check 同形 shell+daily-governance 一段接線,不造新閘(non-blocking 尺)。② 世界解過沒=真搜 GitHub API(2026-07-14;WebSearch 權限被擋、arXiv 沙盒不可達,誠實記明搜索面受限):vulture 4,685★(Python 死碼偵測,教訓=動態語言假陽性不可免→靠白名單/信心分)、jscpd 5,873★(token 視窗 copy-paste 偵測,223 格式)、radon 1,996★(Python 度量:LOC/複雜度)、repowise 3,566★(code health scores + git analytics,健康度=趨勢帳不是單點閾值)。③ 裁定=borrow-design:vulture/radon/jscpd 皆 pip/npm 包,零依賴家規排除 adopt;借三個設計教訓原生實作——(a) 死碼偵測在動態語言必有假陽性→**只當趨勢計數、不當 findings 清單**;(b) 重複偵測用正規化行視窗 hash(CPD 家族設計);(c) 健康度看**趨勢/差分**不看絕對閾值(repowise/CodeScene 精神)。

## 目標(一句話)

給自主 loop 的自我修改面(scripts/ + governance/ 的 code)一把零依賴的**腐蝕趨勢尺**:每日 snapshot 死碼計數/重複視窗比/TODO 計數/體積指標入帳(ledger JSONL,按 HEAD 去重=「輪」為 code 變更步),密度型指標連 K 個變更步嚴格單調上升 → LINE 通知+寫 pending 留人核——非閘、不擋任何流程,先量出真實趨勢再談收緊(rot-eval 先例:這是一把尺,不是新的閘)。

## 方案評比與選擇(brainstorm,2026-07-14)

| 方案 | 內容 | 判定 |
|---|---|---|
| **A(選)** | 零依賴趨勢尺:corrosion 模組(snapshot+trend 純函數)→ ledger JSONL(HEAD 去重)→ 每日 daily-governance 第 4 段跑檢查 → 單調上升 flag → LINE+pending 留人核;non-blocking | **選**:直擊 gap 的「跨輪」語意(累積型退化只在時間序列顯形,per-diff 審構造上看不見);全件複用既有形狀(lint-watch-check 同形 shell、difficulty.py 同款零依賴純函數模組、pending 收件匣、line_notify);無基線資料前不設閘,方向與 rot-eval「先量再說」一致 |
| B(否決) | 接社群 linter(vulture/jscpd)進 `.lumos/lint.json` SARIF 管道 | 否決:①pip/npm 依賴違零依賴家規(vendor 整包 vulture 不成比例);②lint.json 管道語意是 code-loop 的 per-diff findings 面——單點掃描量不到「跨輪單調上升」,趨勢帳還是得另建;③vulture 假陽性當 findings 會塞爆人審(它自己都要白名單) |
| C(否決) | 掛 pre-push/loop 入口硬閘:腐蝕指標上升即擋 | 否決:無基線資料前定閾值=拍腦袋(rot-eval 同型教訓:CONFIDENCE_THRESHOLD 是猜的就先量);假陽性直接擋開發/擋 loop,代價不對稱;gap 要的是「標卡住待人核」——標記+人核,不是自動封鎖 |

## 前提與既驗事實(逐字查證,2026-07-14)

- **全 repo 現無任何 code 趨勢量測**:`grep -rn "corrosion\|dead_defs\|dup_ratio" governance/ scripts/` 0 命中;`lumos doctor` 各 Check 全部對架構圖(Check P 抓「架構圖指向死碼檔案」,不量 code 本身);rot-eval(docs/design/2026-06-19-rot-eval.md)量的是**架構圖 Verification 知識腐化**,與 code 腐蝕不同物。
- **腐蝕主面是單檔 monolith**:`wc -l scripts/lumos` = 8,493 行單檔 python;governance/autonomous_loop/*.py 合計 ~400 行——loop 每天的實作改動集中在這兩面。
- **每日排程掛點現成**:`governance/daily-governance.sh` 三段結構(治理日報→自主 loop→lint-watch),各段 fail-open(`set -uo pipefail` 無 `-e`)、各寫自己 log——第 4 段同形掛接零風險。
- **同形先例**:`governance/lint-watch-check.sh`(20 行:跑檢查→dedup→LINE→`exit 0` fail-open)是「每日檢查+通知」的已收斂形狀;`governance/autonomous_loop/difficulty.py`(65 行零依賴純函數+模組頂 docstring 指回設計 doc)是模組形狀先例。
- **人核收件匣現成**:governance/pending 目錄(`governance/autonomous-loop.sh:10` mkdir)是人每天 review 的既有動線;dry-run 收斂 spec 也寫這裡(`governance/autonomous-loop.sh:195-196`)。
- **LINE 通知介面(r1-F2′ 精確化)**:`governance/autonomous_loop/line_notify.py:3-6` 的 `build_message(title, confidence_summary, pr_link)` **綁死**「自主迭代 loop:今天備好 1 個待放行 spec」banner 文案(自主-loop 專用、非通用格式器);`send(message, token)`(`governance/autonomous_loop/line_notify.py:8`)吃任意 message dict。**corrosion-check 走 lint-watch-check.sh:18 的 send()+自建 dict 路徑,不用 build_message**——訊息全文自組(topic+單行摘要)。token 在 `$HOME/.config/ai-daily/line_token`。
- **測試掛點現成**:`scripts/test_autonomous_loop.py` 既有 53 個 test(unittest、直接 import 模組函數、零網路)。
- **scripts/lumos 可被 ast.parse**:它是無副檔名的 python3 檔(shebang `#!/usr/bin/env python3`)——`ast.parse(open('scripts/lumos').read())` 直接可用,死碼/函數計數不需 regex 湊。
- **gap 引的「19 模型基準」論文未能定位**(WebSearch 權限被擋、arXiv 沙盒不可達):其結論(高解題率與低腐蝕不可兼得)僅轉述 2026-06-27 日報,本設計不依賴其具體數字——只取「腐蝕需獨立量測、審計挑錯抓不到」這一結構論點,該論點由本 repo 自身可驗事實(收斂判準只看 findings,見上)獨立成立。

## 範圍(四組件)

### ① 新模組 corrosion.py(落點 governance/autonomous_loop/ 目錄;零依賴純函數)

> 路徑以散文書寫:新檔提案、非現況指涉(refcheck 慣例,同 risk-tiered-review r1 留痕)。

- `SCOPE`:量測面 glob 清單,第一刀=scripts/lumos、scripts/*.py(**排除 scripts/test_*.py,r1-F3**)、scripts/hooks/*(**非遞迴、僅檔案**——os.path.isfile 過濾,目錄項不 open,r3-F1′;無副檔名檔以 shebang 首行分類:含 python → ast 面+文字面;否則只文字面——現況頂層三檔全 bash、python 分支為未來檔案預留(fixture 測試涵蓋);誤分類不炸、只虛拉 parse_errors,r2-F6)。**scripts/hooks/claude/ 子目錄的 *.py(Claude Code 整合 hooks:impact/check-graph-sync/verification-rot-check)v1 不納**——是否屬 loop 高頻自修改面待量,先誠實記取捨(r3-F1′),納入=之後改 SCOPE 一行、governance/*.sh、governance/*.py、governance/autonomous_loop/*.py。**量 scripts/+governance/ 的治理 code 面**(loop 自我修改的主面;glob 亦吃進非 loop 動線的治理工具如 governance_flex_builder.py/ai-governance-research.sh——同屬會腐蝕的治理 code,一併入帳、rationale 據實不縮寫,r3-F4),不量 docs/、不量架構圖、不量測試檔——unittest 的 setUp/fixture 天然高重複會灌噪 dup_ratio,且測試檔膨脹通常是覆蓋變好不是腐蝕;測試面的債(死 helper 等)v1 不量、誠實不宣稱蓋(見天花板 7)。
- `snapshot(repo_root) -> dict`:確定性度量(同 repo 狀態恆同輸出、零網路零時間依賴):
  - **體積指標(只入帳、不觸發)**:`total_loc`(非空非註解行)、`max_file_loc` + `max_file`(monolith 監視)、`file_count`。理由:活躍開發的 repo LOC 本來就隨功能長,拿體積當腐蝕訊號=恆假警報;體積入帳供人眼看斜率。
  - **密度指標(趨勢觸發用)**:
    - `dead_defs`(判準定義,r1-F5):python 檔以 `ast.walk` 收**全部** FunctionDef/AsyncFunctionDef(含方法,非只頂層;scripts/lumos 頂層 190/含方法 220,兩者都在改動面上);「引用」=詞邊界 regex(\b名\b)掃全 SCOPE 原文(含 .sh,shell 常以 python3 -c 引用函數名),**排除該 def 語句行自身**,零命中者計 dead。排除 dunder 與 test_ 前綴。**短名互撞方向=漏報**(死的 run 與活的 run 同名 → 判為有引用、不計 dead);**遞迴自引用/互引死函數同為結構性漏報**(體內自呼、兩死函數互呼=互證存活,r2-F5)——皆偏低假警報方向,漏報率穩定時趨勢仍有效(同天花板 1 邏輯)。**只出計數進 ledger;名單寫 detail 檔供人查,絕不當 findings 餵任何自動流程**(vulture 教訓:動態 dispatch 假陽性不可免)。**detail 檔釘定(r6-F3)**:落點 governance/ 目錄 corrosion-detail.json(散文書寫,新檔),**每次 snapshot 覆寫**(非追加;歷史靠 git diff),內容=dead_defs 名單+各指標覆蓋面;pending 檔的名單摘要取自它。
    - `dup_ratio`(定義釘死,r2-F2):正規化行(strip、去空行去純註解行)後,每檔取連續 6 行視窗 hash,跨檔統計;**重複視窗數=各 hash 組的超額份數 Σ(count−1)**(N 份相同算 N−1 份冗餘,不是 N)/ 總視窗數(CPD 視窗設計);**總視窗數=0 → dup_ratio 釘 0**(除零守衛,r5-F3)。兩種數法差在絕對值、直接左右 0.3pt 地板是否被跨,故釘死並由測試鎖精確值。
    - `todo_count`:TODO/FIXME/XXX 計數。
- `trend(rows, k=4) -> {"flagged": bool, "signals": [...]}`:rows=ledger 尾端;任一密度指標在**最近 k 個變更步**嚴格單調上升 → flagged,signals 列命中指標與數列。噪音地板**只對連續型 dup_ratio 設**(窗內總升幅 ≥0.3 個百分點);整數指標(dead_defs/todo_count)嚴格單調 k=4 本身已含 ≥+3 升幅,再設 ≥2 地板恆不 binding=空條款,不設(r2-F3)。k=4 與 0.3pt 是**第一刀約定非量測**(見天花板 4)。**k 語意釘死(r5-F5)**:k=4 指窗含 **4 列**(=3 個遞增比較;整數指標故含 ≥+3 升幅),測試以此鎖死。**SCOPE 邊界(r5-F1′)**:改 SCOPE=改 corrosion.py=scope_hash 斷裂列,該邊界步的跨定義比較不可比——單一邊界只污染窗內末一比較、無法獨力偽造 k=4 單調(需先有 3 步真趨勢),v1 靠人核歸因(改 SCOPE 的人=看 pending 的同一人,ledger 斷裂+階躍一眼可辨);v2 於 scope_hash 斷裂處 reset/標注。

### ② ledger:corrosion-ledger.jsonl(落點 governance/ 目錄;散文書寫,新檔)

- 一行一 snapshot:`{"date", "head_sha", ...metrics}`。
- **內容指紋去重=「輪」的操作定義(r1-F4 修正,原 HEAD 去重)**:snapshot 讀的是工作樹,`head_sha` 判不到未提交改動(髒工作樹下度量變了卻被丟)——去重鍵改為 `scope_hash`(SCOPE 全檔內容的 sha256;**檔案清單按路徑排序後再 hash**——glob 迭代序不保證穩定,不排序會把序抖動誤判成變更步,r6-F4;snapshot 順手算);與上一行相同 → 不 append。`head_sha` 仍入帳但只當人查脈絡用、不當鍵。ledger 的相鄰行=實際 code 變更步,「跨輪單調上升」量的是變更步序列、不是日曆日——沒改 code 的日子不稀釋也不偽造趨勢。
- 追加式、不改寫歷史;git 追蹤(與 .canary-log.jsonl 同款治理帳)。**commit 動線據實記明(r5-F4)**:cron 只 append 不 commit(與 .canary-log.jsonl 現行同款——工作樹累積、人隨手 commit);持久化依賴人,checkout/clean 可能丟未提交列——同構既有治理帳的已接受屬性,不另造自動 commit。**append 以 fcntl.flock 護(r1-F6;臨界區範圍 r2-F4)**:鎖住「讀尾行比 scope_hash → append」**整段**(只鎖 append 的話,重疊執行會各自讀到舊尾行、寫出兩列等值重覆行——不誤報 flag 但破壞「相鄰行=變更步」語意);stdlib 零依賴。

### ③ 檢查腳本 + 接線(corrosion-check.sh,落點 governance/ 目錄,散文書寫新檔;+ `governance/daily-governance.sh` 第 4 段)

- lint-watch-check.sh 同形(~20 行):python3 -c 調 corrosion 模組跑 snapshot→append ledger(scope_hash 去重,r1-F4)→trend→flagged 時 LINE 通知 + 寫 pending 檔(governance/pending 下,corrosion-flag-日期.md:signals 數列 + dead_defs 名單摘要,人核材料一頁式)→ `exit 0` fail-open。
- `governance/daily-governance.sh` 加第 4 段(同形三行:跑腳本、log 導向、echo rc)。
- **不進 autonomous-loop.sh、不進 orchestrator-prompt**:腐蝕是 repo 級時間序列,不是單次 loop 輪內的事;掛 loop 內反而把「輪」錯綁到 spec 審計輪。

### ④ flag 的人核動線

- LINE 訊息:topic=corrosion-gauge,單行摘要(哪個指標、連幾步、數列)。
- pending 檔即人核材料;人的處置=開清債 issue/接受現狀/調 SCOPE,**不設自動後續**——「卡住待人核」的實義=把訊號送到人已在看的收件匣,決策留人(與 loop 產出 100% 人工放行同構)。

## 邊界 / 非目標(YAGNI)

- ❌ **不設閘**:不擋 pre-push、不擋 loop、不擋 PR——v1 是尺(rot-eval 先例);量出一季真實趨勢與假警報率後再議收緊。
- ❌ **不量 spec 文本膨脹**:design-loop 折入=設計上單調增長,量它恆真警報;gap 明說「盯 code 退化、不是 finding 數」。
- ❌ **不做自動清債**:死碼名單只供人查,不自動刪(假陽性刪錯=真事故)。
- ❌ **不接社群 linter**(方案 B 否決理由)。
- ❌ **不做複雜度度量(cyclomatic)**:radon 語意需真 CC 計算器,v1 三個密度指標先跑;CC 留量出數據後評估。
- ❌ **不做跨 repo**:只量 lumos-toolchain 自身(loop 唯一的自我修改面);其他專案的腐蝕屬各專案 code review。
- ❌ **不動 canary/judge/收斂判準**:本設計量 repo code,與 design-loop 審計機制正交。

## canary 相容性(不可違反)

- corrosion 模組不讀 spec、不進 design-loop 輪內——canary a/b/c 保留地(spec 內部一致性)完全不受侵犯。
- ledger 與 .canary-log.jsonl 互不相干:一個記 code 趨勢、一個記審計紀律。

## 誠實天花板

1. **dead_defs 是啟發式,假陽性結構性存在**:getattr/字串 dispatch/argparse set_defaults(func=...) 這類動態引用 ast 名稱掃描看不見——所以它只當**趨勢計數**(假陽性率大致穩定時,計數的「變化」仍是訊號),名單絕不餵自動流程。假陽性率本身漂移(如大量改用 dispatch 風格,**或 SCOPE 編輯本身=一次覆蓋面漂移,r5-F1′**)會偽造趨勢,靠人核那眼識別(SCOPE 案有 ledger scope_hash 斷裂可佐)。
2. **量的是 proxy,不是「架構」**:重複/死碼/TODO 密度抓得到機械型腐蝕;模組邊界糊掉、抽象錯位、責任散落這類真·架構腐蝕,regex/ast 構造上量不到——那半靠 code-loop 對抗審與人審兜底,本尺不宣稱覆蓋。
3. **單調判準對震盪型退化盲**:升-平-升不觸發嚴格單調;分段上升靠人看 ledger 斜率(體積指標同理只給人眼)。第一刀選嚴格單調=偏低假警報方向,漏報靠人眼補——方向與「無人看顧場景假警報會訓練人忽略通知」的代價權衡一致。
4. **k=4 與噪音地板是拍的**:同 rot-eval CONFIDENCE_THRESHOLD 教訓,跑一季拿真 ledger 重校;v1 不假裝有實證支撐。
5. **flag 非閘**:人不處理 pending 沒有機械後果;這是設計選擇(方案 C 否決理由)不是缺陷,但誠實記明——若一季後發現 flag 恆被忽略,升級議題另開。
6. **自我指涉**:corrosion.py 自己也在 SCOPE 內——本設計落地即推高 total_loc(體積帳如實入帳,工具也是債);其 dead_defs/dup 密度同樣被自己量。
7. **測試面的債不量(r1-F3)**:SCOPE 排除 test 檔後,測試 helper 的死碼/重複不在帳上——v1 範圍取捨,誠實記明。
8. **prior-art 搜索面受限**:WebSearch 權限被擋、arXiv 沙盒不可達,②問證據限 GitHub API 真搜;「19 模型基準」原論文未定位,其量化結論不進本設計依賴鏈。

## 測試策略

沿 `scripts/test_autonomous_loop.py` 既有風格(unittest、直接 import、零網路、fixture 用 tempfile):

1. **snapshot 確定性**:同 fixture 目錄跑兩次 → dict 完全相等。
2. **dead_defs 正反例**:fixture 模組含「定義未引用」「定義且被 .sh 內 python3 -c 引用」「dunder」「test_ 前綴」四型 → 只第一型計入。
3. **dup_ratio**:fixture 兩檔含相同 6+ 行正規化區塊 → **鎖精確值**(已知視窗數下驗 Σ(count−1) 數法,r2-F2);全異內容 → ratio==0;不足 6 行的檔不產視窗;**全檔皆 <6 行(0 視窗)→ ratio==0 不拋**(r5-F3)。
4. **體積指標不觸發**:rows 中僅 total_loc 單調上升、密度全平 → flagged=False。
5. **trend 正例**:dup_ratio 窗 4 列全遞增(3 比較)且過地板 → flagged=True,signals 含指標名與數列(k=4 列語意鎖死,r5-F5)。
6. **trend 震盪/未達地板反例**:升-平-升 → False;連 4 步升但總升幅低於地板 → False。
7. **指紋去重**:append 邏輯對相同 scope_hash 不新增行;工作樹改一檔(未 commit)→ scope_hash 變、照 append(r1-F4 邊界案)。
8. **shebang 分類**:fixture 無副檔名檔 python shebang → 入 ast 面;bash shebang → 只文字面(r2-F6)。
9. **回歸**:`python3 scripts/test_autonomous_loop.py` 全綠 + `python3 scripts/lumos doctor` 不新增 issue。

> 覆蓋誠實聲明:corrosion-check.sh(bash 膠水)與 daily-governance 接線無機械測試(與 lint-watch-check 現況一致);LINE 送達與 pending 寫檔靠首跑人工驗一次留痕。

## 知識同步影響

| 受影響文件 | 需同步什麼 |
|---|---|
| `docs/methodology/架構圖即合約.md` | 自主 loop / 治理節補一句:「腐蝕趨勢尺——loop 自我修改面的 code 健康(死碼/重複/TODO 密度)按變更步入帳,連 K 步單調上升標人核;尺非閘,先量再收」;無對應段則於治理帳(canary-log/governance-log)列舉處併列 corrosion-ledger |
| `docs/methodology/架構圖即合約-對外論述.md` | 若有「自主 loop 安全邊界」段,補「code 退化趨勢獨立於審計 findings 另立帳」一句;無則略 |
| `lumos-*` skills | **無影響**——不動 design-loop/code-loop/project-notes 的任何流程(③ 明確不進 loop 輪內) |
| `governance/autonomous_loop/orchestrator-prompt.md` | **無影響**(同上) |

## 實務隱患

- **cron 環境 PATH/python 版本**:daily-governance 走 launchd,corrosion-check.sh 須同 lint-watch-check 用 `python3` 絕對可解析路徑寫法,不裸調 lumos。
- **ast.parse 的 SyntaxWarning 噪音(r2)**:scripts/lumos 現有 3 條 invalid escape sequence SyntaxWarning,ast.parse 會噴 stderr、每日 cron 灌 log——snapshot 內以 warnings.catch_warnings 靜音(只靜 SyntaxWarning,error 照拋)。
- **ast.parse 對語法錯誤檔的行為**:SCOPE 內若有暫時語法壞的檔(開發中),snapshot 不可整支炸掉——單檔 try/except、計入 `parse_errors` 欄位入帳——**歸體積類:只入帳供人眼、不入 trend 觸發**(r6-F2;它反映的是解析健康不是腐蝕密度)。**計量歸屬(r1-F7 尾)**:parse 失敗檔的文字型指標(total_loc/dup_ratio/todo_count)照文字計,ast 型(dead_defs)跳過該檔——各指標覆蓋面在 detail 檔記明。
- **ledger 首步冷啟動**:rows<k 時 trend 一律 False(不足以判趨勢),不得例外拋錯。
- **.sh 檔的行正規化**:shell 的 heredoc/多行字串會產生偽重複視窗——第一刀接受(假陽性穩定即不偽造趨勢),名單檔標注來源檔供人辨。
- **pending 檔累積**:flag 連續多日觸發會每日寫一檔——同日去重(檔名帶日期天然去重),跨日重複觸發是特性不是 bug(人沒處理就該一直響)。

## 審計修正紀錄

### R1(2026-07-14,opus auditor + opus judge + opus 辯方;canary a=壞§ref:caught)

- canary(型 a,壞§ref:引用不存在的例外矩陣章節)被正確指認性質——caught(token 留 canary-log,不進原稿)。
- **F2(major→辯方駁倒降 minor)**:auditor 指「spec 誤描述 build_message 為通用格式器、混淆兩套 LINE 路徑」。辯方反證:`governance/autonomous_loop/line_notify.py:3-6` banner 寫死屬實,但 spec 原文將 lint-watch-check.sh 引為 shell 骨架先例、build_message 歸 wrapper 呼叫形,兩先例分屬兩面向、無混淆;banner 錯配是 wrapper 現行 6 個呼叫點(autonomous-loop.sh:42/117/138/167/183/202)已容忍的既有共用 helper 屬性,非本 spec 引入。殘餘 minor 折入:前提行精確化=build_message 綁 banner、corrosion 明走 send()+自建 dict(lint-watch-check.sh:18)。
- **F3(minor,折)**:SCOPE 的 scripts/*.py 會吃進兩個 test 檔灌噪 dup_ratio → 排除 scripts/test_*.py,天花板 8 認領測試面不量。
- **F4(minor,折)**:「HEAD 相同=repo 沒變」假等價(髒工作樹漏帳)→ 去重鍵改 scope_hash(SCOPE 內容 sha256),head_sha 降為脈絡欄位。
- **F5(minor,折)**:dead_defs 引用判準未定 → 定死:ast.walk 全 FunctionDef(含方法)、詞邊界 regex 掃全 SCOPE 原文排除 def 行自身;短名互撞=漏報方向,誠實記明。
- **F6(minor,折)**:ledger append 無鎖 → fcntl.flock 臨界區。
- **F7 尾(折)**:parse 失敗檔的計量歸屬明定(文字型照計、ast 型跳過)。

### R2(2026-07-14,opus auditor + opus judge;canary b=未定義旗標:caught;無 major 免辯方)

- canary(型 b,未定義旗標+與 snapshot 簽名矛盾)被正確指認性質——caught(token 留 canary-log)。
- **F2(minor,折)**:dup_ratio「重複視窗數」N vs N−1 歧義左右絕對地板 → 釘死 Σ(count−1),測試鎖精確值。
- **F3(minor,折)**:整數指標地板被嚴格單調 k=4(≥+3)支配恆不 binding → 刪空條款,地板只留 dup_ratio。
- **F4(minor,折)**:flock 臨界區擴到「讀尾行比對+append」整段。
- **F5(minor,折)**:遞迴自引/互引死函數=另一類結構性漏報,補進判準段與天花板邏輯。
- **F6(minor,折)**:scripts/hooks 無副檔名檔以 shebang 分類,誤分類方向=虛拉 parse_errors、不炸。
- **F7(minor,折)**:誠實天花板編號重排 1–8,內文交叉引用同步(天花板 8→7)。
- **查證紀錄 ⚠(折)**:ast.parse 對 scripts/lumos 噴 3 條 SyntaxWarning → snapshot 內靜音,免灌 cron log。
- 地面查證:auditor 對 line_notify 雙路徑/lint-watch-check.sh:18/三段 fail-open/8493 行+190/220 函數計數/53 test 逐條驗證全相符。

### R3(2026-07-14,opus auditor + opus judge + opus 辯方;canary c=未定義常數:caught)

- canary(型 c,植入句同時帶未定義常數與「輪替裁舊 vs 不改寫歷史」矛盾)兩瑕疵面皆被指認——caught(token 留 canary-log)。
- **F1(major→辯方駁倒降 minor)**:auditor 指 SCOPE 的 shebang 分類「與 repo 不符:頂層全 bash=死條款;遞迴則踩目錄/.pyc」。辯方反證:spec 原文「下檔案」=非遞迴僅檔案語意,IsADirectoryError/.pyc 鏈全繫於審計員自造的遞迴前提;現況三檔全 bash 被分類**正確路由**進文字面(單臂無輸入≠死條款,是全函數預留);「前提與 repo 不符」證假(hooks 頂層確有無副檔名檔且分類對其全對)。殘餘 minor 折入:SCOPE 明寫「非遞迴、僅檔案」+ scripts/hooks/claude/*.py 取捨明示。
- **F4(minor,折)**:「只量 loop 的自我修改面」過宣稱(governance_flex_builder.py 等非 loop 動線也被 glob 吃)→ rationale 據實改寫。
- auditor 本輪地面查證:find scripts/hooks -type f、head -1 逐檔、grep 全圖無 JSONL 輪替、ls governance——實測型審計,r1/r2 未覆蓋的面。

### R4(2026-07-14;canary a=壞§ref:**missed**——判決不採信、findings 不折)

- auditor 交 7 條 minor 但全數繞開植入的壞 §ref(引用不存在的通知規範章節)——judge 判 missed,依規該輪 findings 一律不折(其中 SCOPE 漂移/除零/ledger commit 等留待後輪獨立重發現驗證)。

### R5(2026-07-14,opus auditor + opus judge + opus 辯方;canary b=未定義旗標:caught)

- canary(型 b,無定義無接線的旗標)被指認:auditor grep 證 daily-governance.sh 零參數解析、launchd 無參觸發,「名義逃生口不可用=等於沒有」——caught。
- **F1(major→辯方駁倒降 minor)**:「SCOPE 改版靜默污染趨勢」——辯方推演:單一邊界只影響窗內末一比較(前 3 比較全在舊 SCOPE 內),無法無中生有偽造 k=4 單調;dup_ratio 是比值方向不定、體積指標不觸發,可靠被推升的只剩 dead_defs;天花板 1 的基線漂移原理已涵蓋、缺具名實例屬文案級;非閘+暫態自癒+同一人歸因。殘餘折入:trend bullet 補邊界段、天花板 1 具名 SCOPE 實例、v2 reset 方向。
- **F3(minor,折)**:dup_ratio 0 視窗除零 → 釘 ratio=0,測試補案。
- **F4(minor,折)**:ledger「git 追蹤」的 commit 動線據實記明(cron 只寫、人 commit,同 .canary-log 現行)。
- **F5(minor,折)**:k=4 語意釘死=窗 4 列(3 遞增比較),§① 與測試 #5 措辭統一。
- r4 missed 輪的 SCOPE 漂移/除零/ledger commit 三條在本輪被獨立重發現——missed 不折紀律沒有漏掉真 finding,靠重發現收回。

### R6(2026-07-14,opus auditor + opus judge;canary c=未定義常數:caught;無 major 免辯方)

- canary(型 c,未定義常數)被精準指認(grep 全文僅一處、無值無定義、對照 k=4/0.3pt/6 行皆釘值)——caught。
- **F2(minor,折)**:parse_errors 不在任何指標類、trend 永不因它 flag → 歸體積類(供人眼、不觸發),措辭去「也是訊號」的過宣稱。
- **F3(minor,折)**:detail 檔(dead_defs 名單+覆蓋面)全文未定位 → 釘 governance/corrosion-detail.json、每次 snapshot 覆寫、歷史靠 git diff。
- **F4(minor,折)**:scope_hash 未定檔案迭代序 → 檔清單按路徑排序後 hash,堵 glob 序抖動誤判變更步。
- 機制主體經六輪已收斂:auditor 明言「未見新的實質機制洞」,殘餘皆折入時漏補的小定義。
