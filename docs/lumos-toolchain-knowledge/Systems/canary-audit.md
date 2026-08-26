---
type: system
status: deferred
created: 2026-06-26
updated: 2026-08-14
self_audit: sonnet/2026-07-24
tags:
  - type/system
  - status/deferred
  - risk/守衛面
verified_by:
  - "[[Verification/2026-06-19_canary-audit]]"
  - "[[Verification/2026-07-10_審計loop研究硬化]]"
  - "[[Verification/2026-07-16_replay校準baseline_v0]]"
  - "[[Verification/2026-08-04_design-loop重設計落地T1-T7]]"
  - "[[Verification/2026-08-04_design-loop處置閘終審硬化]]"
  - "[[Verification/2026-08-06_驗證層自證三件S1S3落地]]"
  - "[[Verification/2026-08-08_canary型別描述報表]]"
  - "[[Verification/2026-08-08_驗證層去模型化落地]]"
  - "[[Verification/2026-08-14_canary協議停用none制落地]]"
summary: |-
  KEY:★協議已停用(2026-08-14,Enzo 裁,d5)★植入/判定/抽樣分權/漏抓懲罰全停——caught/missed 譯不出「認真」且無下游消費=空轉;煙霧偵測角色被 quote-check 引句錨定機械蓋掉;record 加 kind=none 當純處置帳載體(五處閘謂詞納 none,t_loop_panel_none_kind 釘住);工具封存不拆、歷史帳唯讀;重啟條件=能分「真醒/演醒」的探針出現;D 案(型別輪替攢 15 筆)隨停用作廢(其前提跨期統計已被 d4 否決)
  KEY:[2026-08-05 D 前置,Enzo 裁]record 加 --canary-type/--probe 選配欄(不給不寫鍵)+canary-stats 型別×探針×caught 表——植入型別與探針結果★結構化★取代散文 note(散文帳不可重算,攢十輪也是考古材料);★D 案(型別輪替表數據驅動)開工條件=帶型別記錄攢滿 15 筆★(帳面可數,同 A 案防浮動條款款式);skill 派工/記帳模板同步帶兩欄 [test:t_canary_type_probe_fields]
  KEY:[2026-08-06 效度自檢落地,plan:[[Projects/驗證層自證三件_計劃]]]①型別派工當下★隨機抽★取代固定輪替(loop next;固定輪替=可猜=答案印考卷背面,同輪 slot 仍不重複)[test:t_s2_loop_next_random_type_draw] ②canary-stats 型別來源如實分層 attr/note/unknown+覆蓋率即時計算(D 案 15 筆條件只認 attr)[test:t_s2_canary_stats_type_coverage] ③前瞻層 SNR=governance/eval/canary_snr.py(跨席分辨力÷同席重跑雜訊;重跑<3/分母=0→不裁決非高訊號;swap-candidate 恆人裁)[test:t_s2_snr_synthetic]——★canary-log 非 SNR 合法輸入(無同題重跑配對鍵,母體錯置)★,真 SNR 接 calibration 固定題矩陣
  KEY:★INVARIANT★ canary record/second 回報成功 ⟺ 該行已落盤且可讀回(readback 驗不到即 rc2 且不印 ✓ 行;出身=2026-07-28 回報成功未落盤事故) [test:t_canary_record_persist] [audit:sonnet/2026-07-29]
  KEY:[2026-08-04 d4,design-loop 限定]canary 在 design-loop ★降級為觀測★(不再一票否決:missed 不作廢該席 findings、不擋收斂;disposal 閘不消費 caught/missed)——判定強制留痕(--report/--snapshot,定錨後 rc2 強制)、進跨輪累積帳;離線校準歸 governance/eval/canary_calibration.py(fault seeding 文獻本職)。★code-loop 排除已於 2026-08-08 撤銷(Enzo 具名推翻防浮動條款,見 decisions[] 末條+[[Projects/驗證層去模型化_計劃]])★。脈絡=[[Projects/design-loop重設計]]+[[Projects/canary注意力檢查失效]]
  KEY:★INVARIANT★ second(第二判者)紀錄純 telemetry,永不影響 loop status 的 gate 輸出與 rc [test:t_canary_second] [audit:sonnet/2026-07-29]
  KEY:[2026-07-10]折入錨點污染型事故:編排者用工作副本(含canary)的字串當折入anchor→對真檔靜默落空(replace無assert)——防範:anchor一律取真檔原文+assert;fold-check未來方向補「紀錄宣稱vs正文存在」核對
  KEY:[2026-07-10]生成硬化三條進 skill——載重錨定/haiku 難度探針(FLAWS)/事故反轉(IBIR);missed-rate 升一級指標(lumos gov 分帳);見[[Projects/canary生成硬化_計劃]]
  FLOW:對抗審計一份 spec → 在工作副本偷植 1 個純加性 canary(指向不存在章節/引用未定義詞)→ 不告訴審計員、正常跑審 → 判定:審計員清楚描述該瑕疵=抓到(只信同類同段 findings)/沒描述=放水(判決作廢、換 canary 重跑)→ `lumos canary record caught|missed` 記一筆 → `lumos gov` 第 4 源彙整成審計員可靠度史
  KEY:[2026-07-30]★caught≠覆蓋★外部實證入帳:植錯誤考審查系統實測**最強單席僅 71.6%、六模型並集才 83.3%**(arXiv 2606.19749,經 07-30 治理日報引入)——canary caught 只證該席**醒著**、不證審得夠廣;廣度只能靠多席×多鏡頭×跨家族買,買不到就把收斂宣稱講小
  KEY:[2026-07-30]跨家族席改**能力宣告制**:有外家→該席也帶 canary(舊「不帶canary只否決」作廢,理由=否決席無注意力檢查等於編排者自判);無外家→loop 照跑但 note 留「單家族」、收斂措辭降級為「單家族視角下未發現」。**刻意不採日報的「升主力席」**(連動佔W/capture帳/fail-closed,且與可攜性衝突:skill 要發給別人用,硬要求第二家 CLI=零依賴工具鏈加外部依賴)
  KEY:[2026-08-04 終審實測]生成硬化的兩條校準觀察——★資源類植入對 haiku 探針天生顯眼★(同輪兩席 recraft×2 仍被探中,該席 caught 記弱證據;探針記法=probe:pass/recraft×N 進 record note);★植入 hunk 行數頭要程式自算★(手寫算錯=機械破綻,審計員靠 git 比對溯源抓到=caught 灌水來源)
  KEY:[2026-08-14 prior-art 掃描]同題 repo LoopX(huangruiteng/loopx,4.7k星,loop-engineering 狀態核心)的「canary」=發布工程金絲雀(promotion-readiness/premerge-gate/smoke 冒煙閘,全機械可重算),與本節點的注意力探針純撞名、無可借;掃描結論=世界對 loop 信任的解全押機械可重算閘、無人做 oracle 注意力層——佐證 08-04 重設計方向(canary 降觀測、閘只留可重算)本身就是業界同向解;僅讀 README+code 檔名層級,未深讀實作
  KEY:test-the-tester——這套方法論把判斷外包乾淨審計員,canary 是「注意力下限」探針,擋掉『審計員根本沒讀/只吐通用回應』失敗模式
  KEY:協議是主體(skill 規則),lumos 只做極小 helper:record 留痕 + gov 唯讀彙整;lumos 不 spawn agent、植入/判定留在對話/skill 層
  KEY:提交的文件永遠不含 canary;token(CANARY-<hex>)只是定位記號,非「抓到」的機械證明——唯一算數的是審計員正確描述了那個瑕疵
  KEY:誠實天花板新增(2026-07-07)——eval-awareness 有實證:Anthropic 工作空間論文讀到被評估時的 fake/fictional 內部表徵;canary 隱含前提「審計員沒察覺被測」是實在失效模式,行為層 caught/missed 分不出「真醒」vs「知道被測所以演醒」;詳見身體〈天花板〉〈外部佐證〉
  KEY:auto-mint token 用 secrets.token_hex(非時間戳:秒解析度同秒會撞被 dedup 誤折);每筆 token 唯一供 gov dedup 第 5 鑑別子
  KEY:gov dedup key 第 5 子用 r.get("token","")(不可 r["token"]——舊三源無此鍵會 KeyError 弄爆 gov);只 canary mapper 輸出 token 鍵
  DEP:scripts/lumos cmd_canary｜cmd_gov(.canary-log.jsonl 第 4 源)｜env.vault.parent 定位寫入｜skills/lumos-project-notes(canary 協議)
  TEST:t_canary｜t_canary_loop_fields(258 passed)
  VERIFY:[[Verification/2026-06-19_canary-audit]]
decisions:
  - content: token 不是「抓到」的機械證明,只當定位記號;唯一算數的是審計員清楚且正確地描述了那個植入瑕疵
    id: d1
    context: design-loop r1 canary 審計揪出的真 blocker(R1-F2):若以 token 字串出現在輸出裡當「抓到」,審計員可能只順手提到 token 卻沒真懂瑕疵,假乾淨
    why_chosen: 整套機制的價值是探測「審計員有沒有醒著讀」;機械字串比對能被表面提及騙過,只有正確描述才證明真的讀懂了那段
    decided: 2026-06-19
    valid: true
  - content: v1 canary 只收純加性(additive)瑕疵——指向不存在章節的交叉引用、或約束引用未定義詞;禁「與另一節矛盾的需求」這類非局部型
    id: d2
    context: design-loop r1(R1-F3):非局部 canary 會牽動被矛盾的那節、污染審計員對該節的真實 findings,移除 canary 也救不回
    why_chosen: canary 要能乾淨植入再移除、不汙染真實 findings;純加性瑕疵只動自己那一處,移除後其餘審計結果仍可信
    decided: 2026-06-19
    valid: true
  - content: gov dedup 第 5 鑑別子用 r.get("token","") 而非 r["token"];既有三源 mapper 不加 token 鍵,只 canary mapper 輸出 token
    id: d3
    context: design-loop r3 唯一 must-fix(R3-Issue1):既有三條 mapper 的舊事件 row 沒有 token 鍵,r["token"] 會對所有舊事件 KeyError 弄爆 lumos gov;且 canary 每筆 token 唯一,不加鑑別子會被 dedup 折成單列(R1-F4)
    why_chosen: .get 對舊事件回 "" 行為不變、crash-free;canary token 唯一當第 5 鑑別子才不會把多筆 missed 折成一列丟失可靠度史
    decided: 2026-06-19
    valid: true
  KEY:★2026-08-02 外部實測入帳:規模是主導混淆變數★——[Bigger Isn't Always Better](arXiv 2606.15689) 跨合成變異與真實 PR 的基準,兩條結論:①**抓得到合成缺陷不可靠地預測抓得到真實缺陷** ②**diff 大小是主導混淆變數**(越大越抓不到,跨模型架構一致);它給實務的第一條建議就是「設計合成基準時要控制 diff 大小」。★對本機制的影響★:lumos 的宣稱本來就是窄的(caught=該席醒著,不證覆蓋),故★未被推翻★;但**帳本完全沒記被審材料的規模**——2026-08-02 當天十輪 code-loop 的 diff 從 332 到 2770 行,在帳上長得一模一樣。處置=`canary record --scope-lines N`(純 telemetry、不進任何 gate、不改任何判定),並接進 `loop next` 的記帳模板與兩支 skill,避免重蹈 cluster 三態帳「有機制沒人用」(316:1)的覆轍。★不能回溯★:既有 461 筆(本 repo 316 + Landmark 145)沒有這個數字,時鐘從落地日起走。★預期三種結果都有用★:有關係→大 diff 要切開審或加席;沒關係→這個擔心在本情境不成立、寫下來別再擔心(同實驗⑨長期腐化的結局);反過來→查。[test:t_canary_scope_lines_records_review_size](翻紅釘:突變A 收下但不寫進帳本→「給了就要真的寫進帳本」與「負數擋下」翻紅;突變B 從 loop next 模板拿掉→「模板必須帶上它」翻紅)★誠實揭露★:搜尋摘要提到的「92% F1 degradation」具體數字,我在 PDF 原文裡未能可靠抽出(字型嵌入導致擷取不完整),故只採方向性結論、不引用該數字
  KEY:★軟上限 1800 行(≈30K token)+ scope_oversize 標記(2026-08-02 落地)★——派工前先 `wc -l`,超過就拆(切多輪或拆多席各審一段);`loop next` 在 plant-canary 階段印 `scope_cap` 量尺(★預防端必須在派工之前★,記帳時才喊已經來不及),`canary record --scope-lines N` 超標則在帳上標 `scope_oversize` 並當場喊。★不擋★(輪已跑完擋也來不及),但該輪 caught 視為★弱證據★:審查員可能是「看不完」而不是「沒問題」,收斂宣稱要講小。門檻 1800 是借用已發表的 32K 退化起點取略保守整數,★不是本專案量出來的★ [test:t_canary_scope_lines_records_review_size](翻紅釘三向:上限拉到 999999→超標兩條翻紅;改成無條件標記→反誤傷兩條翻紅;從 loop next 印出鍵移除→預防端那條翻紅)
  KEY:★2026-08-02 對既有紀錄的重讀(不翻案,但不得繼續當證據用)★——`code-slim-python` r1/r2 各 ≈45K token(2778 行)、存活 findings ★0/0★,而 r3-r6 各 ≈9-11K(415-529 行)共 5 條;★已被★三次★對照實驗降級(2026-08-02×2、2026-08-03×1)★——實驗三(Landmark 真事故當針、預先登記判準、獨立編碼者、S 4.3K vs L 41K token)★六席全滅 0/6 偵測到★,主要指標「偽陰性斷言」方向與預測相反(S 3/3、L 1/3),且該指標被發現與「每項作答長度」糾纏;★按預先寫死的規則判為假說不成立 + 地板效應無效★,見 [[Projects/規模影響判斷力假說]]。★三次難度都沒校準好(實驗二天花板 7/7、實驗三地板 0/6)——再測之前要先有能力把針調到 30-70% 命中率,否則是燒錢;裁定=停止在這條線上投資、收斂閘不動★。實驗二(Landmark 真缺陷、同針不同草堆、repo 只有一個 commit 無未來可翻)S 組 3/3、L 組 3/3,★命中率完全沒有隨規模下降★,見 [[Projects/審查規模對照實驗二_Landmark真缺陷]];實驗一詳情::見 [[Projects/審查規模對照實驗]]——同材料、拆三段 vs 各看完整、三席對三席,★預先登記的主要指標(去重相異缺陷總數)B(4) < C(5),假說未獲支持★;唯一獨立找到的 major 出自最小段(610 行)且是活在已交付碼裡的合約違反,但那是事後觀察、不在預先登記內、n 極小。故下述觀察★不得再當作支持證據★,只保留為歷史記錄。原文::r1/r2 審 bash→Python 移植(1769 行新增)、r3-r6 審後來才加的 manifest 步驟——**兩批是不同的碼**,缺陷密度本就可能不同;兩批都是全新未審過的碼、大的那批零收穫,但不能只憑這個下結論。該 loop 最終是「達 cap 未收斂、人裁放行」,放行理由之一是 findings 序列 [0,0,1,1,2,1]——★若前兩個 0 是「看不完」而非「沒問題」,那個序列的意義要重讀★。**不翻案**(六輪修法各綁翻紅釘、全套測試綠、交付包端到端真跑過),但★那兩個 0 不得再被引用為「乾淨輪」證據★。混淆誠實揭露:token 為 bytes/3.5 粗估;小 diff 是剛改過的地方、缺陷密度本就較高。
  - content: canary 定位收縮=當輪煙霧偵測器(同輪席間對照抓管線斷線);d4 的 code-loop 排除撤銷(降觀測擴及 code-loop);否決跨期統計/席位信譽/型別抽樣權重;SNR 前瞻層(固定題×同席重跑受控矩陣)明文豁免。替代案:維持分流=用已被動搖的閘/廢除 canary=盲飛失去管線斷線訊號;取捨:立「條款可被業主具名論證推翻」先例、code-loop 失 K-streak 行為門檻換判準不隨模型漂
    id: d4
    context: Enzo 非平穩性論證:caught≠認真/missed≠不認真;模型升→miss 趨零→計分飽和;模型換代/spec 各異/植針人拿捏=跨期統計站流沙。防浮動條款經 Enzo 具名推翻(signoff 於 驗證層去模型化_計劃)
    why_chosen: 煙霧偵測器不怕飽和(miss 越稀有訊號越大)、不需跨期統計(當輪對照即成立);閘體重全移可重算證據(處置帳/引句錨定/翻紅釘/變異測試)
    decided: 2026-08-08
    valid: true
  - content: canary 協議全面停用(植入/判定/抽樣分權/漏抓懲罰全停);record 加 kind=none 當純處置帳載體,panel/light/循序/verify-progress/settle 五處閘謂詞納 none;工具封存不拆、歷史 caught/missed 帳唯讀可回放
    id: d5
    context: Enzo 論證:抓到不代表認真、沒抓到不代表不認真(d4 已承認非平穩性),此訊號翻譯不出任何結論、無下游消費=空轉;僅存的煙霧偵測角色(審計員沒讀/管線斷線)已被 quote-check 引句錨定機械蓋掉;prior-art 掃描(LoopX 等同題 repo)確認業界對 loop 信任全押機械可重算閘、無人做注意力探針層;同日 Landmark code-crossclaim 11 輪實跑亦暴露「輪有效 caught<2」規則絆人白跑一輪
    why_chosen: 依家規「機制價值看對自動 loop 有沒有用」:無消費者的 telemetry 是死重;引句錨定用可重算方式蓋掉其僅存價值;停用(非拆除)可逆——日後若有能區分「真醒/演醒」的探針技術可重啟
    decided: 2026-08-14
    valid: true
related:
  - "[[Projects/規模影響判斷力假說]]"
  - "[[Projects/canary注意力檢查失效]]"
aliases:
  - test-the-tester
---
# canary-audit

> ## ⛔ 協議已停用（2026-08-14，Enzo 裁；見 decisions d5）— 植入/判定/抽樣分權/漏抓懲罰全停
>
> 理由三腳：①caught/missed 翻譯不出「認真與否」（d4 已承認非平穩性），無下游消費＝空轉；②僅存的煙霧偵測角色被 **quote-check 引句錨定**機械蓋掉；③prior-art 掃描確認業界同題全押機械可重算閘、無人做注意力探針層。
> **落地實證**：`record` 加 `kind=none`（無植入輪的純處置帳載體），panel／light／循序／verify-progress／settle 五處閘謂詞納 none，新測試 `t_loop_panel_none_kind` 三向釘（none 輪有效／嚴重度合取不盲 none 列／單席仍無效）＋既有 loop 系 215 測全綠。工具封存不拆；歷史 caught/missed 帳唯讀可回放。
> **重啟條件**：出現能區分「真醒／演醒」的探針技術（eval-awareness 天花板見下）再議。
>
> ★以下正文是停用前的機制紀錄與歷史帳判讀依據，不是現行協議。★

`lumos canary` + gov 第 4 源 + skill 協議 —— 給「對抗設計/spec 審計 loop」的 **test-the-tester**:每輪偷植一個已知瑕疵(canary)驗審計員有沒有在認真抓,放水的審計員判決作廢重跑。

源起:日報 2026-06-18 Gap 1「內迴圈派 Sonnet 當審計員,卻從沒檢查它這一輪到底有沒有在認真抓」+ Codex `/goal` 共識「你判斷『做完沒』的那套檢查必須比迴圈本身更可靠」。

## 解決什麼
這套方法論把判斷外包給乾淨審計員(spec/設計的對抗審計 loop)。一個放水審計員回報的「沒問題/看起來不錯」是最危險的假乾淨——自主迴圈只會更快更自信地犯錯。canary 把「審計員審得好不好」這個難自查的問題,換成「植入者判得準不準」這個較難自欺的問題。

## 範圍(v1)
- **只做對抗設計/spec 審計**:被審的是你控制的文件,能乾淨地植入瑕疵再移除。
- **不做架構圖自足性審計**(§795/§831):審計員讀真實架構圖,植 canary 會污染架構圖 → 延後。
- 形式 = skill 協議規則(主體)+ 極小 lumos helper(只記 log + 餵 gov);**lumos 不 spawn agent**,植入/判定留在對話/skill 層。

## 協議(寫進 skill 的規則,5 步)
1. 在工作副本植 1 個**純加性** canary,給唯一 token。**提交的文件永遠不含 canary。**
2. 正常跑審計,**不告訴審計員有 canary**(告訴就作弊)。
3. 判定:審計員**清楚且正確描述**該瑕疵=抓到(這輪是醒的,只信同類同段真實 findings)/ 沒描述=放水(判決作廢、換不同 canary 重跑,`record missed`)。
4. 連 2 次 missed 升級:換更強模型 / 把文件切小;升級前先 `lumos gov --since 7` 看 missed 史。
5. panel 變體:N 個審計員各給自己的 canary,漏抓自己的那個從投票剔除。

**校準鐵則**:canary 要「認真審計員一定抓得到、但不一眼看穿」,對齊你真正在意的瑕疵類型。

## 天花板(誠實合約)
抓到 canary 只證明審計員**醒到足以抓那一個、那一類、那一段**的植入瑕疵,**不證明抓到所有真實瑕疵**。canary 抓得到的失敗模式 = 「審計員根本沒讀 / 只吐通用回應」;**抓不到**的 = 「讀了、但對複雜權衡判斷錯」——後者 canary 無能為力,別在密集 spec 上因 canary pass 就過度信任。迴歸沒閉合:判定者=植入者本人,無外部檢查,canary 是**降低放水機率的摩擦**,非閉合驗證迴路。

**eval-awareness(2026-07-07 補,有實證了)**:canary 還有一個隱含前提——**審計員沒察覺自己被測**。Anthropic 工作空間論文(見下〈外部佐證〉)用 J-lens 直接在模型內部讀到被評估時的「fake / fictional」表徵,證明 **eval-awareness 是實在的失效模式,非杞人憂天**:審計員可能「察覺了但配合演出」,行為層的 caught/missed 完全無法區分「真醒著」與「知道被測所以表現醒著」。現行 canary 是行為代理,關不掉這格;未來 interpretability 探針若進到 API 層,「驗審計員醒著」可望從行為代理升級為**直接讀取工作空間**。

## 外部佐證(2026-07-07)
- **Anthropic〈Verbalizable representations and a global workspace in LLMs〉**(transformer-circuits.pub/2026/workspace):J-lens 找到模型中間層的全局工作空間(~20-25 個活躍概念、<10% 激活量),**言述與內部推理共用同一批表徵**(反事實反思訓練:訓練「說出」倫理原則 → 未提示情境行為自己變好;消融即回退)。對本系統三個含義:① 對齊審計讀到 "fake/secretly/trick" = 「刻意繞+不誠實」那格的白箱路徑;② eval-awareness 實證(上節);③ 「退場必寫/decisions 必寫 why」的言述紀律可能不只留紀錄、是在塑形後續推理——方法論的機理層支持。工作空間極小也解釋 impact 推播與 summary 符號行(一行一 KEY)為何適配 AI 讀者。

## Helper(`scripts/lumos`)
- `lumos canary record caught|missed [--auditor M] [--token T] [--note ...]` → append 一筆到 `<vault.parent>/.canary-log.jsonl`(`cmd_canary`,用 `env.vault.parent` 定位、不額外載圖)。
- argparse:`canary`(頂層)→ `dest="ccmd"` → `record` 子 parser → `kind` positional `choices=("caught","missed")`(非法值 argparse 自動 rc2)。
- `--token` 沒給則自動鑄 `CANARY-<secrets.token_hex(4)>`(隨機、非時間戳;見 decisions)。schema:`{ts,kind,auditor,token,note}`。
- `lumos gov` 把 `.canary-log.jsonl` 當**第 4 源**讀,明確 mapper(`gate:"canary"`),dedup key 加第 5 鑑別子 `r.get("token","")`(見 decisions)。canary 寫自己的 log,不碰 doctor 的 `.governance-log.jsonl`。

## 後續延伸(非本設計稿)
程式現況含 `--loop` / `--severity` 欄位與 `lumos loop status`(收斂留痕,2026-06-19 另一設計、commit `7858ce7`):把每輪記成帶 loop 的 canary,`lumos loop status <slug> --need 2` 算「連 K 輪 caught 且 severity∈{clean,minor}」→ exit 0 綠燈進實作。本節點聚焦 canary-audit 本體;收斂留痕細節見其專屬節點/設計稿。

## v1 明確不做
架構圖自足性 canary｜自動注入/判定工具｜`lumos canary` 擋任何東西(record-only)｜`lumos canary new`(已砍,record 自動補 token)｜非局部 canary 類型。

## 相關
- 設計稿:`docs/design/2026-06-19-canary-audit.md`(4 輪 Sonnet 對抗審計收斂)。
- 實作落點:`scripts/lumos` `cmd_canary` + `cmd_gov` 第 4 源 mapper;`skills/lumos-project-notes/SKILL.md` canary 協議段。
- 實作 commit:`58ae539`(canary record + gov 第 4 源)。

## caught ≠ 覆蓋（2026-07-30 外部實證入帳）

**來源**：arXiv 2606.19749（Dang Nguyen 等，2026-06-18，植入已知錯誤考各種 AI 審查系統）——
經 2026-07-30 治理日報（`governance/reports/governance-2026-07-30.json`）引入。

**數字**：**最強單一配置抓到 71.6%；六個模型的並集才 83.3%**，關鍵在不同模型抓到的是**不同種類**的錯。
同研究另指出真實部署的使用者抱怨以**誤報與無關痛癢的小意見**為大宗。

**對本機制的意義（兩條，已寫進 `lumos-design-loop` skill 誠實天花板）**：
1. **canary caught 只證該席「醒著」，不證它審得夠廣。** 單席 caught 的輪次不得被當成「這一輪審夠了」；
   廣度只能靠多席 × 多鏡頭 × 跨家族買，買不到就如實把收斂宣稱講小。
2. 誤報大宗的發現與既有抑噪紀律同向，維持不動。

## 跨家族席補注意力檢查（2026-07-30 修訂）

**改動**：design-loop 的跨家族席由「不帶 canary、只作否決」改為**有可用外家時該席也帶 canary**。

**理由**：否決席過去沒有注意力檢查，等於「它講得有沒有道理」全由編排者自己讀了算——**maker 自判**，
正是本機制要消滅的東西。2026-07-30 現場實例：外家席交出打掉整份 spec 前提的最重發現
（見 [[Projects/版本發布流程_計劃]] r1），但帳上沒有任何機械證據證明它醒著。

**刻意只採一半**：2026-07-30 日報建議「跨家族席升為主力席」，本次**不採**——升主力席會連動佔 W、
capture-recapture 帳與 fail-closed 分級，且與**可攜性**直接衝突：skill 是要發給別人用的，
硬性要求第二家廠商 CLI ＝ 給零依賴工具鏈加外部依賴、讓沒有的人開箱即壞。
故採**能力宣告制**：沒有外家 → loop 照跑、note 留「單家族」、收斂措辭降級為
「單家族視角下未發現」。★沒有跨家族不是「不准收斂」，而是「收斂的宣稱要更小」★。
