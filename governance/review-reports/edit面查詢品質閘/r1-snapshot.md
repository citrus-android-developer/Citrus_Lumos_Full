---
type: project
status: doing
created: 2026-08-18
updated: 2026-08-18
tags:
  - type/project
  - status/doing
summary: |-
  KEY:落地 [[Projects/檢索edit面真紅_計劃]] EXP1(離線 held 0.6842→0.7092 零倒退/train 零觸發)——impact ranked 的 query 品質閘:delta 文本為垃圾(首非空字元 `#!` 或去空白後 <20 字)→ 視同空查詢(L 臂靜默),沿用既有空查詢語意(direct=基分/hop1 靠 G/hop≥2 無詞彙背書自動退場),★不新增排序公式★
  KEY:落點=scripts/lumos impact ranked 融合塊(`query = (_payload.get("query") or "")` 之後、lex 計算之前)加 `_impact_query_junk(query)` 判準;--diff 聚合路徑(query=hunk 文字)同一落點自然生效;JSON 輸出加 `query_gated: true` 觀測欄(僅觸發時)
  KEY:旋鈕=LUMOS_IMPACT_QGATE_MINLEN(預設 20;★0=整閘停用含 shebang 分支★)——沿 _impact_knob 家族,評測消融可覆寫;shebang 判準無獨立旋鈕(隨整閘開關)
  KEY:驗收(雙場紀律沿 v1.2)——①考卷:held hook P@8 ≥0.70 且 train 不倒退(離線預估 0.7092,實跑數字可能有偏差,以實跑為準);②Landmark 真機:對其 repo 實跑 impact 抽查(輸出健全/條數/延遲),完整考卷待消費端 update 後跑;凍結=兩場同好
  KEY:刻意不做——hub direct 降權(H2 離線未定,另案帶真公式重驗)/固定席連坐收窄(H4 另軌)/融合權重調整(三臂對照已證天花板)/對 query 做語意清洗(只做機械判準,LLM 不進排序路徑)
  TEST:t_impact_query_gate——①junk 判準單測(shebang/短文/正常文/邊界 19-20 字/MINLEN=0 含 shebang 恆 False)②e2e stdin 路徑:fixture 餵 shebang query,斷言 hop2 免詞彙背書者退場+direct 得基分+query_gated 欄在+stderr 品質閘註記在;正常 query 斷言行為與現行逐位元一致(零回歸)③e2e --diff 路徑:shebang hunk 同斷言(兩路共用塊不靠推論靠實測)④旋鈕 0=閘停用(shebang query 也不被閘)
related:
  - "[[Projects/檢索edit面真紅_計劃]]"
  - "[[Systems/retrieval-ranking]]"
---
# edit面查詢品質閘_計劃

> 白話:改檔案時系統拿「這次改了什麼文字」去比對筆記找相關的。但有些改動的文字只是 `#!/usr/bin/env python3` 這種檔頭,拿去比對等於拿雜訊當線索——比出來的「文字很像」全是假訊號。修法一句話:**偵測到線索是雜訊,就當作沒有線索**——系統本來就有「沒線索」的正確行為(靠架構圖關聯排、遠端的沒背書就不推),借用即可,不發明新公式。

## 緣起

[[Projects/檢索edit面真紅_計劃]] 驗屍+EXP1:垃圾查詢毒化文字臂(E05 native-windows-support L=1.0 排第一/E14 正主 L=0 墊底);離線重排 held 0.6842→0.7092(過 0.70 線)零案倒退,train 六案零觸發零誤傷。判準自由度極小(`#!` 前綴/長度<20),非對考卷擬合。

## 規格

### S1 判準函式
`_impact_query_junk(query: str) -> bool`:★MINLEN=0 → 直接 return False(整閘停用,含 shebang 分支——逃生門恆真)★;否則 `q = query.strip()`,`q.startswith("#!")` 或 `len(q) < MINLEN(預設 20)` → True。空字串本就走空查詢路徑,判 True 無害(冪等)。

### S2 落點與行為
impact ranked 融合塊,`query` 取得後:`if _impact_query_junk(query): query = ""; gated=True`。之後一切沿既有空查詢語意——lex 不算(全 0)、direct=`_dbase`、hop1 indirect=0.4G、hop≥2 因 LMIN_HOP2 退場、動態閾照算。★不動任何公式/閾值/名額★。`--diff` 聚合(query=hunk)與 hook 路徑(stdin payload)經同一塊,自然生效。

### S3 觀測欄
觸發時 JSON 頂層加 `"query_gated": true`(未觸發不加欄,舊消費端零影響——史上 schema 均以 .get() 讀)。人讀輸出加一行 stderr 註記 `(query 品質閘:文本為檔頭雜訊/過短,L 臂靜默)`。

### S4 驗收(雙場)
- 考卷:重跑 held(釘 9fcb761)hook P@8 ≥0.70、train 不倒退;實跑數與離線預估(0.7092)的偏差如實記(候選集在空查詢下與離線重排不完全同構——hop≥2 退場/閾值連動)。
- Landmark 真機:對其 repo 抽查 impact 呼叫(健全/條數/延遲一句話);完整消費端考卷待 update 後。

## 刻意不做(記帳防回鍋)
- hub direct 降權(H2)——另案。
- 固定席連坐收窄(H4)——另軌。
- 融合權重/閾值調整——三臂對照已證天花板 0.6842。
- query 語意清洗/LLM 參與——排序路徑恆決定論。

## 實務隱患
- **誤傷面**:正常短 delta(<20 字的真實變更敘述)會被閘——考卷 train/held 16 案實測僅 shebang 型觸發;若未來出現真實短敘述誤傷,MINLEN 旋鈕可調可關,觀測欄讓誤傷可見。
- **消費端相容**:query_gated 為新增選填欄,.get() 讀法零影響;stderr 註記不進 stdout JSON。
- **[self-governance]**:不擋人,純排序行為;閘自身可由旋鈕停用=可逆。
- **[prod-irreversible]**:不適用(無狀態變更)。

## 合約候選清單(收斂提名,候選≠已標)
- MINLEN=0 必須完全等價於閘不存在(逃生門恆真)。
- 正常 query 路徑行為與閘前逐位元一致(零回歸)。

## 審計修正紀錄

- **pre-flight(2026-08-18,機械排乾,不算 loop findings)**:①MINLEN=0 逃生門自相矛盾(shebang 分支不受旋鈕管)→ 定案 0=整閘停用含 shebang;②S3 stderr 註記無測試著落→TEST ②補斷言;③--diff 路徑「自然生效」僅推論→TEST 補 ③顯式 e2e。地基驗證:空查詢語意(lex 全 0/direct 基分/hop≥2 退場)經逐行核對對現行碼為真;兩路徑共用融合塊屬實。

