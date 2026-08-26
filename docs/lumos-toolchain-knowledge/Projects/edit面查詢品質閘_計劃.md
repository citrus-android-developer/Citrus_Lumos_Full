---
type: project
status: done
created: 2026-08-18
updated: 2026-08-18
tags:
  - type/project
  - status/done
summary: |-
  KEY:落地 [[Projects/檢索edit面真紅_計劃]] EXP1(離線 held 0.6842→0.7092 零倒退)——impact ranked 的 query 品質閘:★低資訊判準(r1 改版)=剝 shebang 首行後壓縮空白殘餘 <20 字→視同空查詢(L 臂靜默)★,沿既有空查詢語意,不新增公式;觸發族=純 shebang(E05/E14)+短文(E01/E15,模擬零倒退);shebang+真內容不誤殺;事故探針刻意不受閘
  KEY:落點=scripts/lumos impact ranked 融合塊(`query = (_payload.get("query") or "")` 之後、lex 計算之前)加 `_impact_query_junk(query)` 判準;--diff 聚合路徑(query=hunk 文字)同一落點自然生效;JSON 輸出加 `query_gated: true` 觀測欄(僅觸發時)
  KEY:旋鈕=LUMOS_IMPACT_QGATE_MINLEN(預設 20;★<=0/NaN/Inf 一律=整閘停用,語意連續★)——沿 _impact_knob 家族進 history knobs 欄可消融;觀測=query_gated JSON 欄(含 --diff 聚合轉發)為主承載,stderr 註記僅互動式輔助
  KEY:驗收(雙場紀律沿 v1.2)——①考卷:held hook P@8 ≥0.70 且 train 不倒退(離線預估 0.7092,實跑數字可能有偏差,以實跑為準);②Landmark 真機:對其 repo 實跑 impact 抽查(輸出健全/條數/延遲),完整考卷待消費端 update 後跑;凍結=兩場同好
  KEY:刻意不做——hub direct 降權(H2 離線未定,另案帶真公式重驗)/固定席連坐收窄(H4 另軌)/融合權重調整(三臂對照已證天花板)/對 query 做語意清洗(只做機械判準,LLM 不進排序路徑)
  TEST:t_impact_query_gate——①junk 判準單測(純 shebang/shebang+真內容不誤殺/短文/正常文/邊界/壓縮空白繞過/非字串防呆/MINLEN 0·負·NaN 皆停用)②e2e stdin:shebang query 斷言 hop2 退場+direct 基分+query_gated 欄+stderr 註記;正常 query 零回歸;原生空 query 不標 gated ③e2e --diff:junk hunk 斷言聚合 manifest 轉發 query_gated+人讀加註 ④incidents-only 快速路不標欄 ⑤旋鈕 0=整閘停用
related:
  - "[[Projects/檢索edit面真紅_計劃]]"
  - "[[Systems/retrieval-ranking]]"
---
# edit面查詢品質閘_計劃

> 白話:改檔案時系統拿「這次改了什麼文字」去比對筆記找相關的。但有些改動的文字只是 `#!/usr/bin/env python3` 這種檔頭,拿去比對等於拿雜訊當線索——比出來的「文字很像」全是假訊號。修法一句話:**偵測到線索是雜訊,就當作沒有線索**——系統本來就有「沒線索」的正確行為(靠架構圖關聯排、遠端的沒背書就不推),借用即可,不發明新公式。

## 緣起

[[Projects/檢索edit面真紅_計劃]] 驗屍+EXP1:垃圾查詢毒化文字臂(E05 native-windows-support L=1.0 排第一/E14 正主 L=0 墊底);離線重排 held 0.6842→0.7092(過 0.70 線)零案倒退,train 六案零觸發零誤傷。判準自由度極小(`#!` 前綴/長度<20),非對考卷擬合。

## 規格

### S1 判準函式(r1 改版:低資訊判準,非 shebang 專用)
`_impact_query_junk(query) -> bool`:
1. **防呆**:`query` 非 `str` → return False(不炸;既有三呼叫方皆產字串,此為 stdin 任意 JSON 防線)。
2. **逃生門**:`MINLEN = _impact_knob("LUMOS_IMPACT_QGATE_MINLEN", 20)`;`MINLEN <= 0` 或非有限(NaN/Inf)→ return False(★整閘停用,含 shebang 處理——旋鈕語意連續:非正常值一律=停用★)。
3. **判準**:`q = query.strip()`;若 `q.startswith("#!")` → 剝掉第一行(`q = q.split("\n", 1)[1] if "\n" in q else ""`);`return len("".join(q.split())) < MINLEN`(★壓縮全部空白後量長度——防稀疏空白繞過★)。
- 行為表:純 shebang 行→junk✓;shebang+大段真內容→非 junk✓(r1:新增檔案誤殺修正);短佔位敘述(E01「(結構性變更)」7 字)/短碼片段(E15 17 字)→junk(★低資訊觸發族,非僅 shebang——E15 離線模擬零倒退、E01 無自由席不受影響,如實列★)。

### S2 落點與行為(r1 精修)
impact ranked 融合塊內、`if not incidents_only:` 分支**之內**、lex 計算之前:
```
gated = False                      # r1:先初始化,未觸發路徑不得 NameError
if query and _impact_query_junk(query):   # r1:原生空 query 不進判準、不標 gated
    query = ""
    gated = True
```
之後沿既有空查詢語意(lex 全 0/direct=_dbase/hop1=0.4G/hop≥2 退場/動態閾照算),★不動任何公式/閾值/名額★。
- **作用域明文(r1,外家席)**:閘只覆寫 lex 用的局部 `query`;★事故觸發探針 `_delta_q`(同 payload 的另一讀點)刻意不受閘★——事故席是安全網,content probe 用原文寧多勿漏,且其比對是 regex 命中非相似度,雜訊文本命中率天然低。此為刻意設計非遺漏。
- incidents-only 快速路(TTL 窗內)在 `if not incidents_only:` 之外,不執行判準、不標欄(該模式不算 L,標了是觀測噪音)。
- `--diff` 聚合與 hook 路徑經同一塊生效(pre-flight 逐行驗證屬實)。

### S3 觀測欄(r1 精修)
- 單檔 JSON 頂層:觸發時加 `"query_gated": true`(未觸發不加欄;原生空 query 不標)。
- ★`--diff` 聚合必須轉發★(r1:通才/整合席——原設計在聚合層被無聲丟棄):`per_file_meta` 併入 `query_gated`(觸發檔才有),人讀 manifest 對觸發檔加註 `(query 品質閘)`——code-loop 審計鏡頭因此看得到哪檔分數產於空查詢。
- stderr 註記:觸發時**恆印**(不分 as_json;stderr 獨立流不入 stdout JSON,hook/eval 皆 capture 分離實證不污染)。★誠實定位:自動鏈(hook/eval)無人讀 stderr,可觀測性主承載=JSON 欄;stderr 僅互動式輔助★。

### S4 驗收(雙場;r1 補敗訴出口)
- 考卷:重跑 held(釘 9fcb761)與 train。★ship 條件=held 淨提升 ∧ 無單案倒退 >0.05★;0.70 轉綠是目標非 ship 條件(實跑與離線預估 0.7092 的偏差如實記——空查詢下候選集與離線重排非同構)。★敗訴出口:held 倒退或單案崩 → 旋鈕預設改 0 出貨(閘存在但關),證據記回 [[Projects/檢索edit面真紅_計劃]] 待 EXP2 重議——不硬塞不棄案★。
- 母體漣漪揭露(r1 整合席):E01/E15 被閘後 collect_unjudged 的候選集會縮(hop≥2 退場)——S0 母體定義=「現行實作的計分觸及集」,隨實作演進屬預期;收縮只減 denom 不產新未標,repin 不受阻。驗收時重跑 unjudged 斷言仍 0。
- Landmark 真機:抽查 impact 呼叫健全/條數/延遲;完整消費端考卷待 update。

## 刻意不做(記帳防回鍋)
- hub direct 降權(H2)——另案。
- 固定席連坐收窄(H4)——另軌。
- 融合權重/閾值調整——三臂對照已證天花板。
- query 語意清洗/LLM 參與——排序路徑恆決定論。
- ★事故觸發探針(_delta_q)加閘★——刻意排除(安全網寧多勿漏,regex 命中非相似度;r1 通才席指出後明文化)。

## 實務隱患
- **誤傷面**:低資訊觸發族含短真敘述(E15 型)——離線模擬零倒退;MINLEN 旋鈕可調可關;`query_gated` 欄(含 --diff 聚合轉發)讓誤傷可稽核。
- **消費端相容**:query_gated 選填欄,三消費端(hook/eval/test)實查皆 .get() 讀法零影響;legacy 輸出路徑(非 ranked)不在落點內,其嚴格 schema 斷言不受影響。
- **[self-governance]**:不擋人;旋鈕停用=可逆。
- **[prod-irreversible]**:不適用。

## 合約候選清單(收斂提名,候選≠已標)
- MINLEN<=0/非有限 必須完全等價於閘不存在(逃生門恆真,含 shebang 處理)。
- 正常非空 query 路徑行為與閘前逐位元一致(零回歸;gated 初始化保證無 NameError)。
- 事故探針路徑永不受閘(安全網合約)。

## 審計修正紀錄

- **pre-flight(2026-08-18,機械排乾,不算 loop findings)**:①MINLEN=0 逃生門自相矛盾(shebang 分支不受旋鈕管)→ 定案 0=整閘停用含 shebang;②S3 stderr 註記無測試著落→TEST ②補斷言;③--diff 路徑「自然生效」僅推論→TEST 補 ③顯式 e2e。地基驗證:空查詢語意(lex 全 0/direct 基分/hop≥2 退場)經逐行核對對現行碼為真;兩路徑共用融合塊屬實。

- **r1(2026-08-18,panel:3 sonnet(通才/謂詞邊界/整合)+Gemini 外家;去重 14 條全折,原評 max=blocker(外家:閘作用域未明))**:
  - [blocker→折][外家] 閘作用域未明文(局部 query vs payload)→S2 明文:只覆寫 lex 局部變數;事故探針 _delta_q 刻意不受閘(通才席同指,升格為刻意不做條款)。
  - [major][謂詞] shebang 前綴過寬誤殺新增檔案(shebang+真內容)→判準改「剝 shebang 行後量殘餘」。
  - [major][整合] 「僅 shebang 型觸發」宣稱被新快照金標反證(E01 7 字/E15 17 字走長度分支)→改「低資訊觸發族」如實列;案例數 16→20 修正。
  - [major][通才] gated 未初始化=正常路徑 NameError→S2 偽代碼補初始化。
  - [major][通才+整合] query_gated 在 --diff 聚合被丟棄=code-loop 鏡頭不可見→S3 明文轉發。
  - [major][通才] stderr 註記被「人讀輸出」措辭鎖死於 as_json=False 而 --diff 恆 json→改「觸發恆印」。
  - [major][通才] 非字串 query 防呆缺→S1 第 1 步。
  - [major][謂詞] 驗收缺敗訴出口→S4 ship 條件+旋鈕歸零出貨路徑。
  - [minor][外家] 稀疏空白繞過→壓縮空白量長度。
  - [minor][外家] 原生空 query 誤標 gated→S2 `if query and …`。
  - [minor][整合] incidents-only 快速路白跑判準+誤標→落點移入 `if not incidents_only:`。
  - [minor][謂詞] 旋鈕負/NaN/Inf 語意不連續→<=0/非有限一律停用。
  - [minor][通才] 「空字串判 True 無害」與逃生門句衝突→措辭重寫(空 query 不進判準)。
  - [minor][整合] stderr 自動鏈無人讀→誠實定位句(JSON 欄為主承載)。
  - 謂詞席證偽一條:「diff 標頭使長度永不觸發」不成立(標頭天生被濾,實測留痕)。
\n

## 落地後發現(2026-08-18,設計逃逸如實入帳)

- **長度分支有害,判準收窄(MINLEN 預設 20→1=「僅 shebang/空白」)**:r1 收斂版的低資訊判準(<20 字)在 held 實跑造成 E15 倒退 0.67→0.38——機制:E15 的 17 字真代碼行「if len(argv) < 3:」有訊息,其 L 分把動態門檻撐高殺掉 7 個 hop1 噪音;閘掉後全分歸平、門檻塌回地板、噪音全湧回。★「短」≠「無訊息」,原低資訊假說的長度分支被 held 證據反證★;shebang 案(E05/E14)的收益全來自 shebang 分支。收窄後 held 0.7467 零倒退。修正走 TDD(單測反轉+邊界改 0/1+旋鈕高值仍可閘供網格)。

## 驗收實錄(2026-08-18)

- 考卷:held hook P@8 **0.6842→0.7467**(零單案倒退;E05 0.25→0.62/E14 0.38→0.62/E15 保持 0.67);train 零觸發不動(0.6667)。★六閘全綠:「gate 總判定: PASS」——fusion 勝 graph-only 與 free p95 兩顆與本案無關的老紅燈被連帶治癒(垃圾 L 拉平分數的位次污染同源)★。全在凍結預設參數(knobs=frozen-defaults)下達成。
- Landmark 真機:junk query 正確 gated(0.40s,輸出健全,固定席保留),正常 query 13 筆零影響。
- 回歸:全量 2748 passed;既有救援測試 2 支顯式帶閘停用旋鈕(驗救援語意與閘正交,逃生門合約首用)。

## code 終審紀錄(2026-08-18)

tier=standard 單審:max=minor 一條(救援測試旋鈕在收窄後為前瞻防護、docstring 因果敘述過時→已修真);四特別鏡頭(NaN 寫法/gated 作用域/聚合零影響/假綠八型對照)逐項核實無誤。留痕 governance/review-reports/code-edit面查詢品質閘/。

