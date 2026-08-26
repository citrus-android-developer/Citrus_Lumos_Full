---
type: project
status: doing
created: 2026-08-08
updated: 2026-08-08
tags:
  - type/project
  - status/doing
summary: |
  KEY:世界已知坑不等本專案爆才進帳——分兩層:★v1=S0 反問風險類(廣度,skill 文本+提問行,零 vault 破壞:直接反問在場 LLM「碰哪些風險類」取代 regex 猜,解「4 類太少」)★｜v2=S1 策展庫(深度,注入類別內世界已知具體坑,pre-flight 證要破 vault-free+新欄位,延後獨立輪)
  KEY:v2 深度層:庫=快取非百科(第一次碰高危 pattern 才 gapfill 填,沒用淘汰,大小由建過幾類 pattern 決定);寬只寬在同類內;機械只召回、判斷歸在場 LLM;種子=refresh-token→single-flight
  KEY:位置=design loop 入口 pitfalls --check(panel 之前,排除有 panel 即時稽核);次位置 impact hook 已在跑不動
  KEY:刻意不做——預收全世界(噪音死)/LLM 進機械觸發器(不可重算)/機械做適用判定/自動採納坑
  FLAG:DECISION
---
# 已知坑機械前置_計劃

> 緣起(2026-08-08,Enzo 一連串追問推導出的設計):事故記帳只接「已爆的坑」(先踩才有);世界已知坑(如 refresh-token→single-flight)不該等本專案上線爆才進帳,也不該賭「當下這顆 LLM 剛好熟」。核心洞見(Enzo)=**問題不是機器認不得語意(語意有在場 LLM 認),是判斷力不跨 session、有盲區**——庫的價值是給每顆會來的 LLM「一份不會忘的共同記憶」。分工:**機械寬召回(不漏)+ 在場 LLM 帶設計脈絡裁定(不濫)+ 裁定留痕(panel 兜底)**。
> ★2026-08-08 Enzo 二次洞見(重切範圍)★:現有 pitfalls 只認寫死 4 風險類=太少;而「這功能碰哪些風險類」本身就是**語意分類**,不該 regex 猜——**直接反問在場 LLM**即可。分兩層:**廣度=反問 LLM 自我分類(catch 所有類別,便宜零碼)｜深度=策展庫注入類別內的世界已知具體坑(catch 這顆 LLM 不知道的,需碼)**。缺廣度=盲類、缺深度=盲坑。v1 只做廣度(S0),深度(S1 庫)延後——pre-flight 證庫要破 vault-free 邊界+新欄位,非「一根線」,值單獨一輪。

PRIOR-ART: ① 最小解——★缺的只一根線★:`pitfall_when` 觸發機制(glob/content regex)已存在,但只 impact hook(改碼時)消費;`pitfalls --check`(design 時)只認寫死的 4 風險類(scripts/lumos:9282 PITFALL_CLASSES),不看架構圖坑節點。本案=把 pitfalls --check 接上 content-trigger 的坑節點(design 時彈)。② 世界解:已知坑=走既有 gapfill(網搜→refuter 駁→人放行)按需填,非預收全世界(噪音必死)。③ Growth test:事故=事故記帳的時間差窗(Enzo 追問實證);非風格;既有機制(pitfall_when/pitfalls/gapfill)接線即可,無新輪子。④ 裁定=borrow-design。

## 設計哲學(定調,防未來走偏)
- **不蒐羅世界**——會死於噪音(蓋好沒人用)。庫=**快取**:第一次碰某高危 pattern 才 gapfill 填,之後免費彈,沒用的淘汰;大小由「本專案建過幾類 pattern」而非「世界有幾坑」決定。
- **寬只寬在「同類之內寧濫勿缺」**,非跨類撒網。
- **機械只負責召回,判斷歸在場 LLM**:content regex 故意寬(token/session/auth 沾邊就彈),誤報成本=多讀一句按掉。★機械不做適用性判定★——那是在場 LLM 帶脈絡的事。
- **裁定留痕**:LLM 判「不適用」須寫理由進 spec 實務隱患節;panel 審該排除(即時稽核),漏判再掉逃逸帳。

## 位置(Enzo 裁:早於 panel,非 design loop 之後)
- **主位置**:design loop 入口的 `pitfalls --check`(現 step 2.6)——坑在寫實務隱患當下彈→答/排除進 spec→**panel 隨後審排除是否成立**(裁定的即時背手;放 design loop 之後=設計已凍結重開貴+排除無人審)。
- **次位置**:改碼時 impact hook(現已消費 pitfall_when)——補「沒走完整設計週期的改動」,不動。

## 規格

### S0 反問風險類(v1 主打;skill 文本為主+提問路徑小改)
- **廣度靠在場 LLM 自我分類**:pitfalls spec 模式的通用提問,除現有固定 3 問(併發/效能/資源),加一問:「★列出此功能碰到的風險類(不限既有 4 類:認證/並發/快取/遷移/PII/限流/狀態同步…),逐類答隱患;無則寫『無+為什麼』★」。
- 現有 4 類 regex **保留當機械地板**(無 LLM 在場時仍彈,如純 CLI 場景);S0 的反問是**在其上加語意廣度**,不取代。
- 落點:主為 design-loop skill(派工/實務隱患紀律加此反問);`_PITFALL_GENERAL`(scripts/lumos:9289)加一行反問提示(讓 pitfalls 印出時就帶這問)。
- **裁定留痕沿用**:反問答出的類→逐類答進實務隱患;判「不碰某類」→寫理由;panel 審。

### S1(v2,深度層——延後,非本輪)pitfalls --check 接坑節點
> ★pre-flight 勘誤:非「一根線」★——cmd_pitfalls 刻意 vault-free(scripts/lumos:13223 help+t_pitfalls_spec fixture 只有 .git 無 vault),接坑節點=新開「找 vault→Env→掃 env.notes」路徑+破 vault-free 邊界;且既有 pitfall_when 節點**無「提問」結構化欄位**(全庫 grep 零命中,現況是 summary KEY 自由文字),要新造欄位慣例;比對須吃 `_pitfall_strip_spec` 後的 corpus(非原始 text,否則重蹈假陽性)。**本輪不做,獨立計劃過審。**
- `cmd_pitfalls` 的 spec 模式(--check 與提問路徑):除既有 PITFALL_CLASSES 4 類,**加掃架構圖中 `pitfall_when` 帶 `content:` trigger 的坑節點**,對 **spec 文本**(非 code 檔)比對——命中則把該坑的隱患提問攤進「命中類追問」。
  - 複用 `_match_incident_triggers` 的 content 比對分支(file_content=spec 文本;glob trigger 對 spec 不適用,只吃 content)。
  - 坑節點的提問文字:節點 summary 的隱患提問欄(欄名待 pre-flight 對齊既有事故節點慣例)。
- **--check 語意不變**:仍只驗「命中類且有實務隱患節」→ rc;新增的是「命中的坑清單」多一個來源。

### S2 known-pitfall 節點慣例(架構圖規範,skill 文本)
- 世界已知坑=Systems/Issues 節點,帶 `pitfall_when: [content:<寬 regex>]` + **必附 `source:` 世界來源 URL**(區別於本專案事故節點:後者記已發生、前者記世界已知)+ 一句隱患提問。
- 走既有 gapfill 填:第一次碰高危 pattern → 網搜→refuter 駁→人放行→建節點。**不自動生成採納**(maker bias 鐵則)。

### S3 裁定留痕紀律(design-loop skill 文本)
- pitfalls --check 彈出的坑,在場 LLM 帶脈絡判:相關→答進實務隱患;不相關→**寫「已排除:<理由>」進實務隱患節**(不是靜默按掉)。
- panel 審實務隱患時,排除理由納入審查範圍(排除判錯=panel 該抓)。

### 種子(v2 隨 S1;本輪不建)
- 建一個真坑節點:`auth/refresh-token → single-flight`(source=OWASP/公開文),content trigger 寬抓 refresh.?token/refreshToken/token.?rotat;隱患提問=「多分頁並發 refresh:token 一次性輪換?前端 single-flight?refresh 中的請求排隊或放行+失敗回滾?」

## 刻意不做
- 預收全世界坑庫(噪音必死;快取式按需填)。
- LLM 進機械觸發器(進閘/熱路徑=不可重算+熱路徑爆;語意判定歸在場 LLM,非外接)。
- 機械做適用性判定(只召回,判斷歸 LLM+panel)。
- 自動生成採納坑(gapfill 人閘不可拆)。
- 動 impact hook 的既有 pitfall_when 消費(已在跑,不碰)。
- 擴充寫死的 4 風險類 regex(治標且列不全;改用反問 LLM 自我分類=S0)。
- v1 碰 vault-free 邊界/新欄位(全留 v2 深度層)。

## 實務隱患
- **效能**:pitfalls --check 多掃一輪 pitfall_when content 節點(全圖 ~248,regex),design 時一次性、非熱路徑。
- **[self-governance]**:advisory 不擋人(--check 語意不變);寬召回誤報=人多讀一句;排除留痕可回審。
- **噪音防膨脹**:庫按需長+沒用淘汰(Growth test);content regex 過寬導致某坑到處彈=該坑降權/收緊 regex(逃逸帳反向)。
- **[prod-irreversible]**:不適用(唯讀+文本)。

## 驗收線(v1=S0)
- S0 測試:`t_pitfalls_ask_risk_classes`(pitfalls spec 模式輸出含「列出風險類」反問行/固定 3 問仍在/--check rc 語意不變/`--risk-classes` 旗標可關反問)。
- skill 文本 diff:design-loop 實務隱患紀律含反問+裁定留痕。
- 實跑:對一份 refresh-token spec 跑 pitfalls,反問行出現(在場 LLM 據此答 single-flight——廣度到位;具體坑的機械注入=v2)。
- v1 不碰 vault、不建種子、不設坑數門檻。
