---
type: project
status: doing
created: 2026-08-08
updated: 2026-08-08
tags:
  - type/project
  - status/doing
summary: |
  KEY:把驗證層判準從「依賴模型行為」換成「機器可重算」(Enzo 2026-08-08 非平穩性裁定入帳)——S1 canary 定位收縮=當輪煙霧偵測器(同輪席間對照抓管線斷線;跨期統計/席位信譽/型別權重全否決)|S2 code-loop 處置閘移植(K-streak 舊制→--disposal 四條可重算合取,canary 觀測化)|S3 翻紅釘證據制(blocker/major 折入必附先紅後綠測試,phantom-vuln 機械解)|S4 diff 變異測試 v1(lumos mutate:機器植針考測試非考人;三算子/testmap 選測/worktree 沙盒/恆 rc0 觀測)
  KEY:PRIOR-ART——處置閘本週三 loop 實戰含 rc0;guard kill 思想泛化;testmap 複用;mutation testing 業界成熟但零依賴自寫算子;8/1 日報可執行重現裁定
  KEY:刻意不做——canary 廢除(煙霧偵測器保留)/變異進閘(v1 觀測)/引套件/再動 design-loop 閘
  FLAG:DECISION
---
# 驗證層去模型化_計劃

> 緣起(2026-08-08,Enzo 裁定入帳):canary 的根本困境=「有抓到不代表認真,沒抓到不代表不認真;模型能力上升 → miss 率趨零 → 計分訊號飽和;整個機制在不停變動的系統(模型換代/spec 各異/植針難度人拿捏)裡找穩定規律——跨期統計站在流沙上」。系統 8/4 已把 design-loop 的 canary 踢出閘(d4 觀測化),本案推進兩步:①canary 定位正式收縮成「當輪煙霧偵測器」②code-loop 同步降級+以模型無關判準補位。

PRIOR-ART: ① 最小解層級——處置閘(design-loop 已驗證,本週三個 loop 實戰含 rc0 收斂)移植 code-loop;變異測試=既有 `guard kill`(合約點沙盒破壞)思想泛化到 diff 層,測試選擇複用既有 `testmap affected`(檔↔測試依賴圖);翻紅釘=TDD 紅綠既有慣例升收貨規則;其餘全 skill 文本/架構圖裁定。② 世界解:mutation testing=業界成熟(mutmut/cosmic-ray/PIT;diff-based mutation 有文獻與 CI 實務)——零依賴家規排除引套件,算子自寫(python ast,三種起步);「finding 須附可執行重現」=2026-08-01 治理日報吸收(十個唱反調審查員一致背書不存在漏洞,只有強制實跑才殺掉)。③ Growth test 三問:事故=Enzo 非平穩性論證+canary 天花板實證(canary-audit 已載「真醒vs演醒不可分」+Anthropic workspace 論文)+8/1 phantom-vuln 日報;非風格(閘的判準漂移=可量測的治理風險);既有機制小修蓋不住「考人」的結構問題,但補位件全是既有機制泛化。④ 裁定=borrow-design。

## 四件(S1-S2 純文字/架構圖,S3 收貨規則,S4 唯一新碼)

### S1 canary 定位收縮(design-loop 側,零代碼)
- 架構圖裁定入帳([[Systems/canary-audit]] KEY+decision):canary=**當輪煙霧偵測器**——只做同輪席間對照(多席抓到、一席沒抓到=當輪異常,查該席管線:context 截斷/檔沒給到/工具壞/降級路由),**不做跨期統計、不做席位信譽分、不做型別抽樣權重**(D 案的權重工程半正式否決,理由=非平穩性;型別帳降為描述性紀錄)。
- 判讀規則一句話入 skill:「漏送分題=強警報(連這都沒抓到);漏難題=弱訊號(不苛責);抓到送分題≈零證明;抓到難題=真醒著」——當輪判讀,非統計。
- 型別報表結清:canary-stats 現有輸出即第一份描述性報表(18 筆 attr;c 型 5/5 全抓=送分題實證),入 Verification 結清「攢滿 15 筆」驗收,**到此為止不再蓋樓**。

### S2 code-loop 處置閘移植(skill 文本為主;★本件=正式翻案,非移植★)
- **被翻對象明列(pre-flight 抓回,不得裝沒看見)**:①[[Systems/canary-audit]] d4 明文「code-loop 不跟進(刻意分流非漂移)」②code-loop SKILL 警語「沿用舊 panel 閘,不得因同步衝動改本檔」③[[Projects/panel收斂判準改革_計劃]](2026-08-05 done,K=2+收斂後抽查)。**翻案理由=裁定之後的新資訊**:Enzo 2026-08-08 非平穩性論證(本案緣起)——當時分流的前提是「canary 閘在 code-loop 仍可信」,該前提被推翻。程序=落地時對 canary-audit 走 `decision-supersede`+SKILL 警語旁註記被本計劃推翻+panel收斂判準改革 節點補「被 supersede」指針;**本 loop 收斂+Enzo 已裁=翻案的放行證據**。
- 取代對象精確化:現行=A 案(K=2 streak+G1/G2/G3+收斂後決定性抽查),非籠統「舊制」→ 改走 `loop status --disposal`(四條可重算合取);canary 降觀測(d4 適用範圍正式擴及 code-loop,經 supersede 非偷擴)。
- 收貨三道(quote-check/refcheck/seat-check)同步寫進 code-loop 收貨慣例(對象=diff/patch 凍結快照)。
- 舊帳不回溯;`code-loop pass/skip` 留痕與 pre-push 閘機制不動(實查:pre-push 只驗 pass/skip 留痕存在,不呼叫 gate,解耦成立)。
- 機械可行性(pre-flight 實查過):disposal gate 為 loop-id 泛型、T6 定錨與 code-loop 留痕慣例相容——零 lumos 改碼成立。

### S3 翻紅釘證據制(code-loop 收貨規則)
- blocker/major finding 折入的**採信條件**升級:必附「先紅後綠」證據——一條當下翻紅的測試(或可執行重現指令+輸出),修完轉綠才記 folded;處置帳 note 記測試名/重現指令。捏造的 bug 寫不出會紅的測試(8/1 日報 phantom-vuln 的機械解)。
- 豁免:文件精度/措辭級 minor 不強求;「真但無法在沙盒重現」(環境級)→ accepted 條目明文理由,不混 folded。
- 落點:code-loop skill 收貨段+templates.md reviewer/辯方派工詞(要求 finding 附重現)。

### S4 diff 變異測試 v1(唯一新碼;「植針考測試」取代「植針考人」)
- **與 code-loop 既有步驟 7 的關係(pre-flight 抓回)**:該 skill 已有「手動 ROR/LCR mutation 冒煙+Survived/NoCoverage 分桶」的人工步驟——S4=**把步驟 7 自動化**(取代手動植入,分桶語意沿用),非平行新機制。
- `lumos mutate --diff <range> [--json]`:對 diff 命中的 **python 檔** hunks 自動生成變異(v1 三算子:比較運算子反轉 `>=`↔`>`/`==`↔`!=`、布林反轉 `and`↔`or`、邊界常數 ±1),每個變異在**臨時 worktree** 套用 → 測試選擇=對**原始 diff range** 跑一次 `testmap affected` 取聯集(pre-flight 抓回:單一變異不另造 range,沿原 PR range 選測,變異只影響「跑哪些」的母集不重算)→ 記殺/活。
- 輸出:殺率+**活口清單**(分桶沿 testmap 既有 `verdict_bucket` 欄位語意)(哪個變異沒任何測試殺得死=測試網的洞,file:line+變異描述);恆 rc0 **觀測不進閘**(沿 canary 降級同款路徑:先量活口率,升閘另立計劃過審)。
- 邊界:v1 僅 .py(本 repo 主棧;多語言=v2);單變異單跑(不組合);變異上限 cap(防大 diff 爆炸,超限抽樣並如實標);testmap 無邊的檔=如實列「無測試可跑」(這本身就是發現)。
- 誠實射程:殺得死機械變異≠殺得死真缺陷(mutation score 是測試網密度的代理,非缺陷偵測);等價變異(改了但語意不變)會誤列活口——v1 接受,人裁活口清單時剔除。

## 審計修正紀錄
- **pre-flight(2026-08-08,機械排乾)**:①S2 與三份既有明文裁定衝突(code-loop SKILL 警語/canary-audit d4 排除/panel收斂判準改革 done)——「移植」改「正式翻案」,明列被翻對象+supersede 程序+翻案理由(裁定後新資訊) ②現況描述補精確(A 案 K=2+抽查,非籠統舊制) ③S4 與 code-loop 手動步驟 7 關係明文(=自動化取代) ④變異的 testmap range 定義補(沿原 diff range 取聯集) ⑤S4 commit 自我指涉排序明訂(走舊 panel 首航,新閘驗收指向其後 loop) ⑥d4 範圍擴大改走 supersede 非「對齊」措辭。

## 刻意不做(記帳防回鍋)
- canary 廢除——不廢:煙霧偵測器用途保留(管線斷線唯一行為訊號);廢除=盲飛。
- 型別抽樣權重/席位信譽分/跨期 caught 率基線(Enzo 非平穩性裁定,本案緣起)。
- 變異測試進閘(v1 觀測;升閘須另過 loop+Growth test)。
- 引 mutmut/cosmic-ray 等套件(零依賴家規)。
- design-loop 的閘再動(8/4 新制不碰)。

## 實務隱患
- **效能**:S4 變異×測試=乘法爆炸——cap+testmap 窄選+單檔 worktree;僅手動/終審時跑,不進 hook 熱路徑。
- **併發**:worktree 隔離(沿 eval 慣例 mkdtemp+cleanup);單進程序列跑。
- **資源**:worktree 用後即刪(atexit+finally 雙保險)。
- **[self-governance]**:S2 動的是守衛面規矩書——golden 語料在(本週三 loop),舊帳不回溯+新制已在 design-loop 實戰;S4 恆 rc0 無誤擋面;繞過留痕:pass/skip 機制原樣。
- **[prod-irreversible]**:不適用(全讀+臨時 worktree)。

## 驗收線
- S1:canary-audit 節點 KEY+decision 入帳;skill 判讀句 diff;型別描述報表入 Verification 結清。
- S2:code-loop skill 文本 diff+canary-audit decision-supersede 留痕;實戰驗收=**S4 落地之後**的下一個真實 code loop 以 --disposal 收斂(pre-flight 抓回的自我指涉排序:S4 改 scripts/lumos 那筆 commit 的 tier=high 過關**走舊 A 案 panel**——新閘不得以「驗收引入自己的 commit」首航;S2 skill 文本改動為 .md-only,pitfalls 恆 standard,無循環)。
- S3:templates.md/skill diff;下一個 code loop 的 folded 條目全數帶翻紅釘留痕。
- S4:`t_mutate_diff`(三算子生成/worktree 隔離/testmap 選測/殺與活判定/cap 抽樣/無測試檔如實列/rc 合約);對本週真實 diff(hook必看召回修復那批)實跑一輪,活口清單如實入 Verification——**不設「殺率須達 X」門檻**(觀測層,防預期寫成驗收)。
