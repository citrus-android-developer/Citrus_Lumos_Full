---
type: project
status: doing
created: 2026-07-18
updated: 2026-07-18
tags:
  - type/project
  - status/doing
related:
  - "[[Systems/pitfalls-code-loop]]"
  - "[[Systems/design-loop]]"
summary: |-
  KEY:code 階段三腿補強(呼應 design-loop d4 定位裁定:正確性歸下游,下游要配得上)——正確性/品質兩腿尚可,性能腿近空(pitfalls 只有 regex 提示,從未真量);2026 業界共識=審查從「用讀的」轉「用跑的」(agentic testing/execution-based verification)
  KEY:[S1]真跑優先(紀律層規則,r1 折入後誠實降級)——(a)diff 經 `lumos impact --diff` 命中綁 [test:] 的星標合約節點時,放行前**只跑該綁定測試**(非全套)且須綠;此為紀律層規則非機械閘(家規同款);[test:]名→指令解析紀律=架構圖記載→棧慣例組指令→歧義退檔/模組/全套並留痕,不得靜默跳過;機械化=動 gate code 記 v2 另立計劃 (b)確定性驗證器(真跑測試/type checker/mutation)**不佔 canary 席不進輪有效**;參與方式=findings 依機械證實路由折入+以異質 finder 進 capture-recapture 帳(既有 `loop capture-counts` 原語);跑真碼樹沿 mutation 隔離 worktree 模式
  KEY:[S2]查詢數斷言(消費端樣式)——「操作 X 最多 N 條查詢」寫成整合測試斷言,N+1 即紅;**落點=LandmarkMember 自己的架構圖節點**(框架特定歸專案架構圖,csharp-idioms 明文不裁框架、不落 Dapper 代碼;r1 blocker 折入),框架無關原則於落地時記入 pitfalls-code-loop summary(不進 linter精選目錄,r4 折入)
  KEY:[S3]性質測試席(選配,r1/r2 修)——開席=兩機械錨(tier=high ∧ impact 命中星標合約節點)+人工核純函式+具推導源(docstring/型別/架構圖合約;缺源不開席防自證 oracle),預設關+開席理由留痕;產出:反例可重現性免爭,**性質合法性必過辯方**(辯方專問「這條性質真是該函式的業務合約嗎」,對文件/架構圖合約/呼叫端查證;高分=進辯方資格非免審,低分丟);金流級另掛 signoff 既有慣例
  KEY:[S4]持續基準測試=不做(non-goal)——拒收理由立足工程成本(穩定硬體壓噪音);誠實缺口:CPU-bound/記憶體退化在 code 階段零覆蓋,S2 只接查詢數這一種訊號(第一根拐杖非補齊);線上分桶告警=消費端建議待辦**非既存安全網**(r1 折入:原文誤植為已存在)
  KEY:[S5]跨家族比重提升(使用者指示,r2 大修)——①辯方預設 Codex(兩 loop,成本中性替換=d4 合規)②雙 Codex 角色**僅 code-loop tier=high**(帶餌 finder 佔 W+無餌否決席外掛不佔 W;否決席 findings 同池進辯方/存活 max/重疊帳,防紙上角色);design-loop 一席不加(d4 前置加重一律拒)③≥3-run 至少 1 run Codex+家族否決保護(外家 blocker 不得僅被同門多數推翻,須執行反證或第二外家)④fail 分級(r3 嚴格版):standard fail-open/high fail-closed=外家軸缺席一律不得收斂攤人裁(人可明示豁免留痕),不分金流⑤真加軸=第三家族輪替,記方向
  KEY:範圍刀——S1 改兩份 skill 文字(紀律層);S2 樣式歸消費端架構圖;S3/S5 是編排規格;零新 lumos 原語;全部加在 code/驗證階段,spec 階段零加重(d4 合規)
  DEP:[[Systems/pitfalls-code-loop]]
  DECISION:[2026-07-18]S4 拒收記理由防重提;S3 觸發改開席四要件(兩機械錨+一人工核+推導源查核,r1-r3 逐輪收窄);S3 免辯方路由撤除(r1 三方共指:自評分=自報級信號不得做免辯方級動作)
---
# code階段強化_計劃——正確性/品質/性能三腿補強(鏡頭在 code 階段)

> **緣起**:design-loop d4 裁定「正確性歸下游」後,使用者要求鏡頭轉向 code 階段:搜業界更全面提升正確性/品質/消除 bad performance 的做法。2026-07-18 搜證(來源見文末)。r1 對抗審計(3 帶餌席+Codex 否決席)折入七組修正,見〈審計修正紀錄〉。

PRIOR-ART: ① 最小解層級——S1 改既有 skill 文字(紀律層)、S2 是消費端架構圖樣式文檔、S3/S5 是既有 panel 的編排規格;零新 lumos 原語。② 世界解過——S1=agentic testing 2026 共識;S2=Rails bullet/prosopite 查詢數斷言路線;S3=Anthropic property-based testing 配方(2026-07,984 報告實測 56%→86%);S5=異質 ensemble 文獻既有方向的比重調整;S4=Bencher 持續基準(拒收)。③ 裁定=S1/S2/S3/S5 皆 borrow-design;S4=評估後拒收(三分類外的 non-goal,非採納)。

## [S1] 真跑優先(正確性;紀律層規則,改 skill 文字)

**現況**:code-loop 收斂由 LLM 判官數 finding 決定;真跑測試只是實作階段習慣,終審層面無明文地位。

**改動**(兩份 skill 文字;**紀律層規則,非機械閘**——同「硬閘是紀律非技術鎖」家規,誠實聲明):
1. `skills/lumos-code-loop/SKILL.md` 收斂節加規則:**「觸碰合約」的判定依據=`lumos impact --diff` 命中綁 `[test:]` 的 ★INVARIANT★ 節點**(沿用既有 min_score 門檻機制,非檔案級粗判——單檔如 scripts/lumos 綁 6+ 合約,檔案級會誤傷 docstring 小改)。命中時,放行前**只跑該綁定測試**(非全套,成本=單測試一跑)且須綠;跑過與結果**記入 `code-loop pass --note`**(留痕可稽核)。**解析紀律(r2 折入)**:`[test:]` 存的是測試方法名非可執行命令——解析順序=①該合約節點/專案架構圖有無記完整測試指令 ②以測試名對該棧慣例組指令(如 `dotnet test --filter`/`python3 scripts/test_lumos.py -k`)③同名多筆或查無 → **不得靜默跳過**:退跑該測試檔/模組級,再不行跑全套,留痕記「解析歧義」;「解析不了所以沒跑」不構成放行理由(fail-closed on skip)。LLM 判官意見不能替代這一跑(信任階梯:真跑 > 機械查 > LLM 判官 > 自報)。**機械化**(code-loop check 讀綁定並驗執行結果)=動 gate code,記 v2 另立計劃,本計劃不做。
2. panel 節明文確定性驗證器的參與方式:**不佔 canary 席、不進「輪有效」判定**(它們跑真碼樹,看不到文字 diff 副本裡的誘餌,記席必然 missed;canary 票只驗 LLM 席注意力)。參與三通道:(a) 其 findings 依辯方路由「機械證實」直接折入 (b) 以**異質 finder** 進 capture-recapture 重疊帳(既有 `lumos loop capture-counts --finder/--from-pitfalls` 原語,零新機制) (c) 需跑真碼的(測試套件/type checker)沿 mutation 冒煙既有的**隔離 worktree** 模式。**待改的實際措辭(r2 折入,r3 校正指位)**:精確字串「一等 panel 成員」在 reference.md:179;SKILL.md 檔尾「參考」節有「一等成員」(:162)與「各算獨立票」;「升格為一個確定性 panel 成員」**兩份重複**(SKILL.md:164 與 reference.md:188,都要改,漏一份=語感殘留)——改寫為三通道語意,勿新造「同權重投票」等不存在字串去搜。**兩套帳差異(r2 折入)**:無-cluster 舊帳=三條合取,capture-recapture **進合取**(通道 b 有真裁決權);M2 cluster 帳(2026-07-16 上線)=capture-recapture **advisory 不進合取**——該模式下確定性驗證器的裁決權由**通道 (a) 承載**(其機械證實 findings 進 cluster 三態帳),通道 (b) 降為輔助訊號。skill 文字須分別敘明,不得混稱「數學不變」。

**測試策略**:純 prompt/紀律層無單元測;以下次真實 code-loop 跑一遍驗流程可執行(同 finding-refute 前例)。

## [S2] 查詢數斷言(性能;消費端樣式)

**現況**:性能腿近空——pitfalls 對 N+1 只有單行 regex 提示,從未有機制真的量過查詢行為。

**改動**(r1 blocker 折入:落點改歸消費端):
1. **樣式主體落 LandmarkMember 自己的架構圖**(Systems 節點):「會數查詢的連線包裝」——測試組件裡包 `IDbConnection` 攔 `Execute*/Query*` 計數 + 斷言範例:`載入 50 筆訂單清單 → 查詢數 ≤ 3`。N+1 出現時 3→51 直接紅。查詢數上限以**該專案實測值+緩衝**訂,硬編碼於各測試(顯式可審),不引入新宣告檔。
2. 本架構圖的框架無關原則(「操作級性能可翻譯成確定性測試斷言,優先於監控與基準」)於 S2 落地時記入 [[Systems/pitfalls-code-loop]] summary(確定性性能斷言=異質 finder 家族一員)——**不進 linter精選目錄**(該節點定位=linter 選型菜單,塞測試哲學句不搭;r3 折入)。
3. **csharp-idioms 不動**——該 skill 三處明文「框架選擇不在此裁,歸專案架構圖」,Dapper 專屬樣式進去會被其審查鏡頭套到所有 C# 專案(含 EF Core 者)產生誤導 finding(r1 s3-blocker)。
4. LandmarkMember 首用掛該專案待辦,非本計劃交付。

**為什麼是斷言不是監控**:把性能翻譯成**確定性測試**=信任階梯最高階;免基準環境、免統計、CI 直接跑。

**測試策略**:首用時以「故意引入 N+1 → 斷言翻紅」負向驗證(同 lint-check 驗收慣例)。

## [S3] 性質測試席(正確性;code-loop 選配席,r1 大修)

**現況與舊帳**:07-15 架構圖判「自動生成 property 測試 oracle 不可靠」(agent 自己發明錯誤期望→誤報)。Anthropic 2026-07 配方:推導性質(從文件/型別)→寫 PBT→真跑→自我篩選→評分過濾→**高分交人審**,實測 56%→86%。**r1 三方共指**(Codex+s1+s3):反例只證「代碼≠生成的性質」,哪邊錯正是 oracle 問題;自評分=自報級信號(S1 階梯最低級),不得做「免辯方」這個最高信任動作。

**改動**(code-loop 選配席編排規格):
- **觸發(開席四要件=兩機械錨+一人工核+一推導源查核,r1 收窄、r2 增訂、r3 正名)**:①tier=high **且** ②`lumos impact --diff` 命中綁 ★INVARIANT★ 合約節點 **且** ③該 diff 觸及的函式為純函式(無 IO;人工核,候選集已被②機械收窄)**且** ④該函式**具可推導源**(docstring/型別註解/架構圖合約其一;存在性=機械可查,內容品質人判)——缺推導源不開席並留痕「文件缺失」(r2 折入:無文件硬推=退化成 07-15 判定不可靠的自證 oracle;缺文件是先補文件的訊號)。**預設關**;開席須在收斂留痕記開席理由。防濫開:tier=high 門檻低,故②是主閘。
- **流程**:席位 agent 讀 diff 涉及的純邏輯函式+文件/型別註解 → 推導 2-3 條性質(從文件推導,禁憑空)→ 該棧 PBT 框架寫測試(C#=CsCheck/Kotlin=kotest-property/JS=fast-check/Py=Hypothesis)→ 真跑數百案例(固定 seed,反例可重現)→ 自我篩選(排除測試自己寫錯)→ 自評分(性質來源可靠度/可重現/影響面)。
- **產出(r1 撤免辯方)**:反例的**可重現性**免爭(那是機械事實);性質的**合法性必過辯方**——辯方(依 S5 預設 Codex)專問:「這條性質真是該函式的業務合約嗎?」對文件、架構圖 ★INVARIANT★、呼叫端行為查證。**高分=取得進辯方資格,非免審**;低分直接丟(防噪音)。辯方維持→折入;辯方駁倒→丟棄並記「性質推導誤」。金流級 finding 折入後另掛 `lumos signoff` 既有慣例(對業務的人確認)。
- **成本上限**:單席、跑一次、cap 數百案例;不收斂不重跑(加菜非主菜)。

**測試策略**:編排規格無單元測;首用挑真實高風險 diff 驗端到端,結果記 Verification。

## [S4] 持續基準測試——不做(non-goal,拒收記理由)

拒收理由立足工程成本:需穩定硬體環境壓噪音(change-point 偵測才有意義),重;lumos 自身是 CLI 無熱路徑。**誠實缺口(r1 折入,不得誇大覆蓋)**:S2 只接「查詢數」這一種性能訊號——CPU-bound 演算法退化、記憶體洩漏、快取失效在 code 階段**零覆蓋**;線上響應分桶告警是**消費端建議待辦,目前並不存在**(原文誤植為既存安全網,已更正)。故性能腿定位=「補上第一根拐杖」非「補齊」;S2 用起來後仍有缺口再議 S4(屆時評 Bencher 類自架)。記此防日報/自主 loop 重提。

## [S5] 跨家族比重提升(使用者指示 2026-07-18;r2 大修)

**動機**:r1/r2 實證——Codex 席連兩輪貢獻真 major(同權票落點/紙上硬閘/免辯方/[test:]解析/否決語意…),外家視角價值已證。但**兩個 Codex 彼此同門**,純加席邊際遞減;正確加碼=讓外家出現在更多**關鍵角色**,非堆同款席。

**d4 合規聲明(r2 blocker 折入)**:帶餌 finder 席**只加在 code-loop**(tier=high)——design-loop(spec 階段)**一席不加**,維持既有「≥1 跨家族無餌否決」現況;對 design-loop 的唯二變化是**成本中性替換**(辯方由 opus 換 Codex=同一席換供應商;≥3-run 多數決 run 次數不變),不新增任何審計動作——「前置加重一律拒」(d4) 因此不被觸犯。**誠實註記(r3)**:席數不變≠實效嚴格度必然不變——辯方換更強供應商,方向不定(更強反證→更多假陽性被降級=加速收斂;更準維持→防錯誤降級);列入 [[Projects/loop數據收集_計劃]] 觀察項(design-loop 收斂輪數/辯方降級率),若換手後輪數顯著上升,回頭檢討此聲明。

**改動**:
1. **辯方預設 Codex(兩 loop 適用,成本中性)**:低共識 findings 開庭時辯方由 Codex 擔任(乾淨脈絡、不傳審計結論;`codex exec --sandbox read-only`)——判決單點最怕同門盲點,外家反證價值最高。
2. **雙 Codex 角色(僅 code-loop tier=high)**:1 席**帶餌正式 finder,佔 W 配額之一**(替換一個同門席,總席數不變;與 LLM 席同規則受注意力檢查,findings 計入重疊帳)+1 席**無餌否決席,不佔 W**(沿 spec-conformance 外掛慣例;高 tier 淨增成本=此一外掛席)。**否決席裁決語意(r2 折入,r3 補落閘路徑)**:其 findings 與帶餌席 findings **同池**進辯方路由;存活 ≥major 的**落閘路徑依當前帳模式而異**——M2 cluster 帳(該 loop 錨定 cluster 模式時;code-loop 至今尚未實跑過 cluster 帳,r4 s2 查證 main.json 零筆——首個 cluster 模式 code-loop 落地時適用):必須記為該輪 cluster 記錄 `<名>=disputed-major`(這才進合取條2,severity 欄在該模式僅顯示不裁決;r3 s1 讀碼實證);無-cluster 舊帳:計入該輪存活 max severity。兩者皆非「只寫 note」——照此落法,否決席喊 blocker 而閘綠燈的組合才真的不可能發生。與 spec-conformance slot 並存,兩者皆外掛。**與既有 qwen 否決位的關係(r3 折入)**:code-loop 的跨家族否決位由 Codex 出任(**取代**既有「qwen 只否決」敘述,非並存;qwen 轉列第三家族替補與 finder 輪替候選)——SKILL 落地時刪舊 qwen 否決文字,防兩套否決條文疊床架屋。standard tier=1 席無餌否決(現況)。
3. **關鍵單點判決 ≥3-run 多數決,至少 1 run Codex+家族否決保護(r2 折入)**:任一家族 run 提出 blocker 時,**不得僅以他家族的同門多數推翻**——降級須具備可執行反證(真跑)或第二外家族確認;拿不出則 blocker 維持(fail toward safety)。防 opus+opus 2:1 壓掉唯一外家正確意見=重現同門盲點。
4. **fail 策略分級(r2 折入,r3 改嚴格版)**:standard=fail-open(Codex 不可用退同門+留痕註記)。**tier=high=fail-closed**:順位=第三家族(qwen/gemini)替補 → 等待/延期 → 皆不可 → **一律不得收斂,攤給人裁**(人可明示豁免並留痕「外家軸缺席,人裁放行」)——不分金流與否;r3 Codex 指出原「僅金流例外」讓資安/隱私/資料毀損級 diff 可被同門靜默放行,外家軸無聲失效。
5. **真加軸=第三家族**:以**實際驗證可用者為限**——qwen 有自主 loop 既有整合(cross_audit);gemini 於本 repo 無任何整合紀錄,列候選非承諾(r3 折入)。可用時輪替進 finder 席;記方向不急做。

**測試策略**:編排規格無單元測;本計劃 r2/r3 復審即實戰樣本(辯方開庭即用 Codex)。

## 實務隱患

- **效能**:S2 計數包裝只存在測試組件,不進 prod 路徑。S3 席跑數百案例有時間成本→雙機械錨+預設關+單席 cap。S5 Codex 席增加外部 CLI 呼叫次數(分鐘級/席),tier=high 才雙席。
- **併發**:無——S1/S3/S5 為編排文字;S2 計數包裝單測試進程內,無共享狀態。
- **冪等**:S3 固定 seed 記反例(可重現最小案例為產出物),避免 flaky 反例進判讀。
- **資源**:S3 席一次性 agent 無常駐;PBT 框架屬消費專案 dev 依賴,不進 lumos(零依賴家規不破)。Codex 呼叫受本機 quota 限制;fail 策略依 S5.4 分級(standard fail-open 退同門;high fail-closed 攤人),非無條件 fail-open。

## 誠實天花板

- S1 是**紀律層非機械閘**:審計員漏判合約關聯或直接留 pass,pre-push 仍放行——關「忘了」不關「刻意繞」;機械化留 v2。
- S1 觸碰判定依賴 impact --diff 的 min_score 門檻——門檻漏判=該跑沒跑,屬已知漏網面(逃逸帳接)。
- S2 查詢數上限人訂:太鬆抓不到退化、太緊變 flaky;首用實測值+緩衝,調整靠回歸經驗。性能覆蓋僅查詢數一維(見 S4 誠實缺口)。
- S3 即使性質過辯方,辯方對「文件本身過時」也可能雙雙誤判——低分丟棄的假陰性+辯方誤放的假陽性都歸逃逸帳;定位是加菜非兜底。
- S5 兩個 Codex 席彼此同門,邊際遞減誠實聲明;真獨立軸要等第三家族。
- 全計劃不含線上/prod 層性能網(監控告警歸消費端 ops,且目前不存在,見 S4)。

## 審計修正紀錄

- **r1(2026-07-18,3 帶餌席+Codex 否決席;3/3 caught 0 missed,存活 max=blocker)**:
  1. [Codex+s3] S1(b)「同權重投票」無機械落點(確定性驗證器看不到文字 diff 誘餌,記席必 missed;gate 數學無投票語意)→ 改三通道參與(機械證實折入/capture-recapture 異質 finder/隔離 worktree),刪同權重措辭。
  2. [Codex+s2] S1(a)「真跑綠才放行」原文=紙上硬閘+觸碰粒度未定義 → 誠實降級紀律層+指名 impact --diff 為判定依據+只跑綁定測試+留痕;機械化記 v2。
  3. [Codex+s1+s3 三方共指] S3 高分反例免辯方=自報級信號做免辯方級動作,Anthropic 配方「高分交人審」被偷換 → 撤免辯方:性質合法性必過辯方(預設 Codex),金流級另掛 signoff。
  4. [s2] S3 觸發「編排者判純邏輯」防濫開太弱(tier=high 門檻低)→ 雙機械錨(impact 命中合約節點為主閘)+預設關+開席理由留痕。
  5. [s3, blocker] S2 落點撞 csharp-idioms 明文邊界(不裁框架/審查鏡頭會套到所有 C# 專案)→ 樣式主體改歸 LandmarkMember 專案架構圖,idioms 不動,本架構圖只留框架無關原則一句。
  6. [s2] S4 拒收理由引用不存在的「線上分桶告警」+「性能腿補齊」誇大 → 更正為消費端建議待辦+「第一根拐杖」定位+CPU/記憶體缺口誠實記載。
  7. [使用者指示] 新增 S5 跨家族比重提升(辯方預設 Codex/雙 Codex 角色/≥3-run 含 Codex/第三家族方向)。

- **r2(2026-07-18,2 帶餌 delta 席+Codex 回鍋複審;2/2 caught 0 missed,存活 max=blocker)**:
  1. [s2, blocker] S5「改兩份 loop skill」把帶餌席也加進 design-loop=撞同日 d4「前置加重一律拒」,而範圍刀自稱 d4 合規 → 帶餌席只加 code-loop;design-loop 僅成本中性替換(辯方換供應商/多數決 run 數不變);補 d4 合規聲明。
  2. [Codex] S1 [test:] 只存方法名非可執行命令(同名多筆/需 runner 參數時照文跑不出)→ 補解析紀律三順位+歧義不得靜默跳過(fail-closed on skip)。
  3. [Codex] S5 無餌否決席無裁決語意(gate 只吃 canary/severity/capture,否決喊 blocker 閘照綠)→ 否決席 findings 同池進辯方/存活 max/重疊帳。
  4. [Codex] ≥3-run 多數決 opus+opus 可 2:1 壓掉唯一外家 blocker → 家族否決保護(降級須執行反證或第二外家確認)。
  5. [Codex] fail-open 與 high 保底衝突(Codex 掛掉全退同門照綠)→ fail 分級:standard open/high closed 傾向+金流級外家缺席不得收斂。
  6. [s1] S1(b)宣稱刪「同權重投票」但該字串不存在(實際待改=「一等 panel 成員/各算獨立票/升格為確定性成員」)→ 指名真實措辭與位置。
  7. [s1] M2 cluster 帳(07-16 上線)capture-recapture=advisory 不進合取,通道(b)在該模式紙上 → 兩套帳差異化敘明,cluster 模式裁決權由通道(a)承載。
  8. [s1] 「雙機械錨」實為兩機械+一人工 → 正名;[s1]「四方共指」→三方。
  9. [s2] PRIOR-ART「borrow-design 全線」與 S4 拒收矛盾 → S4 排除於三分類外。
  10. [s2] S3 缺「無文件純函式」擋板(硬推=自證 oracle 復辟)→ 開席第四要件:具推導源,缺源不開席留痕。

- **r3(2026-07-18,終輪;2/2 caught 0 missed,存活 max=blocker→cap 到頂攤人)**:
  1. [Codex+s2 雙指] S5 fail 分級未修徹(僅金流例外→資安/隱私級可被同門放行)+實務隱患殘句鏡像漂移 → 改嚴格版:high 外家軸缺席一律不得收斂攤人裁;殘句同步。Codex 另驗收:解析/否決語意/多數決保護三條修徹、d4 聲明成立。
  2. [s1, blocker] 否決席落閘在 M2 cluster 帳仍紙上(該模式只吃 caught 計數+disputed-major cluster 記錄,severity 僅顯示)→ 明文分帳落閘路徑:M2=記 disputed-major cluster 記錄/舊帳=計存活 max。
  3. [s1] d4 聲明「席數不變=不加重」有嚴格度縫隙 → 誠實註記(方向不定)+列 loop 數據觀察項。
  4. [s1] S3 標題計數未跟上第四要件 → 正名開席四要件;④存在性機械查/品質人判。
  5. [s1] 新 Codex 否決席與既有 qwen 否決位關係未交代 → 明文取代非並存,落地刪舊文;gemini 無整合紀錄=候選非承諾。
  6. [s2] frontmatter DECISION 指針行漏同步(雙機械錨/四方殘留)→ 同步(r2#8 鏡像失誤補課)。
  7. [s2] S1(b) 指位有誤(「一等 panel 成員」實在 reference.md:179;「升格為確定性成員」兩份重複漏列一份)→ 校正。
  8. [s2] 性能原則句塞 linter精選目錄不搭其定位 → 改於落地時記入 pitfalls-code-loop summary。

## 落地順序

S1(改文字)→ S5(改文字,與 S1 同波)→ S2 樣式(歸 LandmarkMember 架構圖,該專案下次動手時)→ S3 規格(寫進 SKILL,首用等真實高風險 diff)→ S4 不做。落地 Verification 以 `plan_refs` 回指本節點。

## 來源(2026-07-18 搜證)

- Anthropic《Finding bugs with Claude and property-based testing》(2026-07)——S3 配方與 56%→86% 實測
- Rails bullet/prosopite 查詢數斷言路線——S2 樣式原型
- Bencher 持續基準測試——S4 評估後拒收
- Tricentis/12thWonder 2026 agentic testing 盤點——S1「用跑的取代用讀的」共識
