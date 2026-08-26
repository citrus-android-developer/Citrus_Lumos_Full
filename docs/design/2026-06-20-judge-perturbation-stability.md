# judge-perturbation-stability — 讓 design-loop 的 judge 判斷抗得住輕微擾動(設計)

> 狀態:**評估後放棄(2026-06-20),理由存檔** — design-loop 2 輪揭示「用同一 judge 審兩次測它自己穩定性,逃不出『誰控制擾動』的自證悖論」(R2-F2);改用輕方案(可信度報告列『未檢查維度』,已實作)。詳見下方〈放棄決定〉。｜日期:2026-06-20
> 觸發 gap(日報 2026-06-20 gap[2]):design-loop 每輪只靠單一 judge,但 RAND 實測(arXiv 2603.05399)『沒有單一 AI 評審穩定可靠』——同一份答案換排版判斷就翻盤。judge-severity-gate 把 severity 交給 judge 後,judge 單一不可靠成了新最弱環。
> loop_id: judge-perturbation-stability

## 目標(一句話)

design-loop **關鍵輪**(要判 clean/minor 的收斂輪),把同一份 spec 換個說法再讓 judge 審一次;severity 判斷翻盤 = 該 judge 這輪不穩 → 該輪不採信、不算收斂。把 judge 從「一次說了算」升到「至少抗得住輕微擾動」。

## 邊界 / 非目標(YAGNI + 誠實約束)

- **不換模型家族(做不到,雙重約束 R1-F2)**:① `claude -p` 本身只路由 Anthropic Claude——換 GPT/Gemini **不是「換把鑰匙」,是換掉整條 CLI/SDK 工具鏈**;② OAuth 訂閱再把 Claude 自家可用面砍到只剩 opus/sonnet(fable-5 亦禁,實證 `ai-governance-research.sh`)。所以「換家族避免同門偏心」(RAND 核心)在當前工具鏈下**根本沒有實現路徑**,硬寫=假設做得到的破口。本 spec 只做「同家族內」抗擾動。
- **不做真多數決**(每輪多個 opus judge 投票成本翻倍,autonomous loop 已夠燒)。
- **只補關鍵輪**(要判 clean/minor 的那輪),不是每輪——成本。前面 blocker/major 輪本來就不收斂,不需擾動測試。

## 方案評比與選擇

### 方案 A(選此)— 關鍵輪擾動穩定度測試
要判 clean/minor 時,把 spec **換個說法/換段落順序**(語意不變),讓**同一個 judge** 再審一次。兩次 severity 跨越收斂門檻(clean/minor ↔ major/blocker)= 不穩 → 該輪記 missed-equivalent、不採信、不算收斂。
**選的原因**:直接對應 RAND「換排版就翻盤」實測;不需換模型、只多一次審(成本可控);只在關鍵輪觸發。

### 方案 B(否決)— judge 改 sonnet、與 opus auditor 隔離
讓 judge 用 sonnet(跟 opus auditor 不同 tier),弱版「評審與被評隔離」。**否決**:sonnet 評 severity 比 opus 糙、可能更不準;且 sonnet/opus 同家族,「隔離」是假的(同門);換來的隔離度 < 失去的判準度。不如把 judge 留 opus + 加擾動測試。

### 方案 C(否決)— 真多數決(N 個 judge 投票)
成本翻倍,且同家族 N 個 opus 投票仍同門偏心(RAND 的問題沒解、只是平均)。ROI 低。

## 組件

### C1 — 關鍵輪擾動測試(改 orchestrator-prompt.md design-loop sub-step)
- 觸發條件:judge 回報的 severity ∈ {clean, minor} 時做(=這輪可能讓收斂窗前進);major/blocker 輪跳過(本來就不收斂)。**觸發不對稱(R1-F1)見誠實天花板 1。**
- 動作:把 judge 的輸入做**機械擾動**(見 C2),用**同一個 judge prompt** 對「原序」+「擾動序」各審一次,只問 severity。
- 判定:兩次 severity 是否**同在收斂側**(都 ∈{clean,minor})。跨越門檻 = judge 這輪不穩 → 取較嚴格者、不採信、不算進收斂窗;note 記「擾動翻盤」。

### C2 — 擾動用「機械 reorder」、不用 agent 產(R1-F3 解,堵自證悖論)
**擾動不是 agent 改寫,是程序機械打亂呈現順序**:把 judge 輸入裡 auditor findings 報告的**條目順序**(+ spec 內同級 bullet 順序)用確定性程序打亂、**一個字不改內容**。兩個理由:
- **直接對症**:RAND 測的本就是「換**排版/順序**」(格式擾動)、不是改寫——機械 reorder 正中靶心,原方案的「換句話說」反而想多了。
- **無自證(F3 的核心)**:原方案讓 orchestrator(被審者)產擾動版、自己寫 note 說「等價」——正是 judge-severity-gate 才斷開的「**被審者自填**」反模式在新位置復發。機械 reorder 是**確定性、可驗證等價**(同一組 findings 只換序、內容逐字相同),沒有 agent 能塞「幾乎沒動的假擾動」或「故意更難讀」——作弊面歸零(連帶消掉原 F6 測試盲區)。

### C3 — 收斂語義不變、只多一道閘
`good(r) = caught AND severity∈{clean,minor}` 定義不動;C1 只是在「judge 回報 severity」與「record」之間插一道「擾動複審」,讓據實評的 severity 多一層抗擾動驗證。

## 誠實天花板

1. **只解「隨機不穩」子集、且只測收斂側(R1-F1)**:本 spec 把 gap「單一 judge 不可靠」窄化成「單一 judge **隨機**不穩」——擾動(同一 judge 換序審兩次)只抓「換排版就翻盤」的隨機不穩;**穩定的系統性偏見**(對某類 spec 一貫低估)兩次都偏、抓不到(換家族才解,$0 OAuth 做不到)。**且觸發不對稱**:只在第一次審 clean/minor 時測,防「假收斂」(clean 翻 major);第一次偏嚴(major)的「假不收斂」不測——接受偏嚴時多花幾輪、不增成本。只補一半,誠實標明。
2. **擾動等價性已從「靠自律」升為「機械可驗證」(R1-F3 解)**:改機械 reorder 後,擾動是確定性程序(只換 findings/bullet 順序、內容逐字相同),等價性可機械驗證(diff 只有順序差)、無 agent 自證——原「orchestrator 自產自證」反模式已消除。
3. **成本(R1-F5 量化)**:reorder 本身零成本(程序);多的是 judge 對亂序再審一次,只在 severity∈{clean,minor} 輪觸發。對齊 autonomous-loop「單日 ≤14 agent 調用」基線,收斂前至少 2 個 clean/minor 輪 → **最少 +2 judge 審/loop**。
4. **judge 集中化因本改動加深(R1-F4)**:judge 同輪被呼兩次(原序+亂序),權重更集中於單一 judge——架構圖即合約 §自主迭代 loop 已命名的「judge 集中化」風險,本改動是「以抗隨機不穩換更深集中化」。
5. **自指**:本 spec 是用「現在這個單一 judge 的 design-loop」審的——用不可靠的單一評審,審「修單一評審不可靠」的方案。不可避免,放行的人是最後兜底。

## 測試策略

- 合成:同一 findings 報告,原序 vs 機械亂序,judge 給跨門檻 severity(一 clean 一 major)→ 驗 C1 判「不穩、不採信」。
- 原序 vs 亂序 severity 一致 → 驗 C1 判「穩、採信」。
- major 輪 → 驗跳過(不觸發)。
- **機械 reorder 等價性**:驗亂序版與原版 findings **內容逐字相同、只順序差**(diff 可機械確認)——取代原「人工抽查假擾動」(機械 reorder 無假擾動可言,R1-F3/F6 一併消解)。

## 知識同步影響(dogfood 2026-06-20 新機制)

此改動若實作,需同步:
- **`governance/autonomous_loop/orchestrator-prompt.md`**(主改):design-loop sub-step 加「關鍵輪擾動複審」。
- **`docs/design/2026-06-20-autonomous-iteration-loop.md`** §組件3:judge 那條補「關鍵輪還要過擾動穩定度測試」。
- **`docs/methodology/架構圖即合約.md`** §四「自主迭代 loop」節:judge 機制補「關鍵輪過機械 reorder 擾動測試」;「judge 集中化」註「已加抗隨機不穩,但同輪雙呼**加深**集中化、系統性偏未解(換家族才解、$0 OAuth 做不到)」。
- **`docs/methodology/架構圖即合約-對外論述.md`**:白話段「派 AI 審設計」可補一句「同一份東西換個說法再審一次,判斷翻盤就代表這個 AI 沒看穩」。
- skills:**無**(judge/擾動是 autonomous-loop 獨有;`lumos-design-loop` 手動 loop 人在場、不受影響)。

## 審計修正紀錄

### R1(2026-06-20,canary 類型 a=壞§ref,opus,caught)
canary(〈C4 成本模型〉死§ref+token)抓到。worst real = major,全折:
- **major F1**:觸發不對稱——只在第一次審 clean/minor 時測,防「假收斂」、漏「假不收斂(major 其實該 clean)」→ 誠實天花板 1 明列、接受偏嚴多花幾輪。
- **major F3**(最深):原 C2「orchestrator 自產擾動版+自寫 note 說等價」=**被審者自填反模式復發**(judge-severity-gate 才斷開的)→ **改機械 reorder**(程序打亂 findings/bullet 順序、逐字不改內容):確定性、可驗證等價、無 agent 自證,作弊面歸零,**連帶消掉 F6 測試盲區**。且更對症(RAND 測的本就是換排版/順序)。
- **minor**:F2 邊界理由準確化(claude -p 根本不支援非 Claude、非「換鑰匙」);F4 天花板補 gap 窄化橋接 + judge 集中化因同輪雙呼加深;F5 成本量化(最少 +2 judge/loop)。
> 本輪最有價值:自以為想好的方案(agent 產擾動)一審就暴露重蹈「被審者自填」覆轍,戳穿同時逼出更乾淨的機械 reorder。

### R2(2026-06-20,canary 類型 b=未定義旗標,opus,caught)— 揭示方案根本兩難,折修方向待人決
canary(`--shuffle-seed` 懸空)抓到。3 個 major 都指向同一裂縫——**機械 reorder 沒真堵自證,只換了藏身處**:
- **F2(最深)**:spec 通篇沒說 reorder 由誰執行、種子誰選。若是 orchestrator(被審者)→ 它能挑「對自己有利的順序」=自證悖論原樣復活。**且立論自相矛盾**:前提「順序會讓 judge 翻盤」(否則測試廢)vs 防作弊「只換順序故無作弊面」——順序無關則廢、有關則可作弊,二者不能並存。
- **F1**:擾動標的失真——RAND 測「換被評對象(spec)排版」,C2 打亂的卻是「auditor findings 報告順序」(評審材料、有序論證體),打亂=破壞論證結構=noise,judge 翻盤未必證不穩。
- **F3**:「機械可驗證」≠「已被機械驗證」,驗證者未定義、loop 無此閘。
> **待人決的方向**:(a)折修重做——reorder 改**確定性程序** + 種子=findings **hash**(去人為、堵 F2 選順序)+ **自動 diff 等價閘**(F3)+ 擾動標的改 **spec 本身**(F1);代價:從「多審一次」變成要建一套真功能,且加深 judge 集中化。(b)放棄此方案,改用更輕的 inspiration「可信度報告硬列『迴圈沒檢查到的維度(含 judge 單一不可靠)』」,把人眼導到破口、不建 reorder 機制。**ROI 上 (b) 可能更划算。**

### 放棄決定(2026-06-20,人選 b)
評估後**放棄**此方案。理由:① 機制堵不住自證(R1→R2 每次折修只把自證換個藏身處);② 只解「隨機不穩」一半,系統性偏要換家族、$0 OAuth 做不到;③ 反而**加深** judge 集中化(修一弱環、加深另一,負和);④ ROI 低(為半個解建一套確定性 reorder+hash+diff 閘的真功能)。
**改用輕方案(已實作)**:`confidence_report.py` 的可信度報告把「殘留風險」升級成「**這個迴圈沒檢查到的維度(品質最可能爛在這、放行請特別盯)**」,judge 單一不可靠列首位;autonomous-loop.sh 的 RESIDUAL 同步補全。把放行的人的眼睛導到破口——機制堵不住的,**誠實標給人、別假裝堵得住**。
> loop engineering 洞察:不是每個弱環都該用更多機制堵;有些在當前約束下機制化只會越重越撞自證,最誠實是承認局限、攤給最後兜底的人。這也是 design-loop 的價值——它沒讓我把一個 ROI 存疑的方案硬做到收斂,而是逼出「不該做」的判斷。
