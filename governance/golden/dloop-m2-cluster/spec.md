---
type: project
status: doing
created: 2026-07-16
updated: 2026-07-16
tags:
  - type/project
  - status/doing
related:
  - "[[Systems/design-loop]]"
  - "[[Systems/loop-convergence-recording]]"
  - "[[Systems/canary-audit]]"
  - "[[Systems/finding-refute]]"
summary: |-
  FLAG:DECISION
  KEY:問題=design-loop 常態跑滿 3 輪 cap 靠人裁,收斂慢。真因兩個結構病:①非定態目標——每輪折入改寫 spec,下輪審的是新文件,新 findings 一半在審上輪補丁,capture-recapture 的封閉族群/獨立捕獲前提偏弱(Codex 診斷);②「你一定找得到」framing 保證每輪必交 minor→G2 發現枯竭永不成立
  KEY:文獻定調——self-refinement 普遍 3 輪 plateau(SELF-REFINE/IMPROVE),cap=3 已是效率前緣;解不在加輪數/換停止規則,在「讓 r1 起點更高+後續輪只審 delta」
  KEY:藥方五條(划算排序):①R2/R3 嚴格 delta-scoped(物理只餵 diff+受影響合約+前輪爭議,留一席便宜全局哨兵)②gate 改 risk-cluster 三態帳(resolved/accepted-minor/disputed-major;停止=輪有效∧fold後無disputed-major 兩條合取,新生cluster與capture-recapture皆降advisory;雙finder覆蓋條件v1砍——r1/r2 loop 收斂後定案)③pre-flight cascade(機械checklist→小模型→panel)④辯方按共識路由(一致+有證據直折,低共識才開庭)⑤fold 迷你核對
  KEY:不做——SPRT(分布每輪變,不可用)/group sequential(收益極小)/Bayesian 停止(posterior 由 prior 主導,需先累 10+ loops 歷史回放校準,順序不可倒)
  DECISION:②動 loop status gate 語意=改守衛的守衛,高風險面——本計劃進實作前必過 design-loop(用舊 loop 審新 loop);①③④⑤純 skill 編排文字,trivial 級可先行
  DEP:[[Systems/design-loop]]｜[[Systems/loop-convergence-recording]]
---
# design-loop提效_計劃

> **狀態**：三路調研（web 文獻 ×3 + Codex 跨家族研究席）收斂的提效方案，尚未實作。緣起：使用者觀察「跑滿久才能收斂」（2026-07-16）。

## 問題（實測數據）

fromscratch-m1 三輪 9→6→3、T3 三輪 12→6→5——常態跑滿 cap 靠人裁實質收斂。拆 findings 性質：r1 大宗是清單型缺陷（未定義詞/矛盾/touchpoint 漏），r2/r3 一大半在審上一輪折入的補丁。

**兩個結構病**：
1. **非定態目標**（Codex 診斷，比「折入品質」更根本）：折入這個動作本身持續改寫受審對象——下輪的「新發現」可能只是新文字引入的；capture-recapture 的封閉族群＋獨立捕獲兩前提在此偏弱，殘餘估計不可當硬閘。
2. **minor 永續供應**：「你一定找得到」framing（防放水的必要之惡）保證每輪必交 minor → G2 發現枯竭結構上永不成立 → 人裁成為事實出口（T3/fromscratch 皆如此）。

## PRIOR-ART（2026-07-16 真搜：web×3 + Codex 席）

- **Self-refinement 文獻**（SELF-REFINE arXiv:2303.17651 / IMPROVE arXiv:2502.18530）：迭代精煉普遍 1-2 輪最大收益、3 輪 plateau——**cap=3 已是效率前緣**，實測 9→6→3 完全吻合。解在輸入品質與 delta 化，非輪數與停止規則。
- **軟體審查經典**（Wohlin/Runeson capture-recapture 十年總結 jss04；El Emam DPM）：估計器該用在「要不要開下一輪」的**事前決策**；experience-based 校正因子（誤差 10.5%→7%）＝歷史回放校準路線。DPM（發現速率曲線）需時間戳，選配。
- **LLM cascade/routing**（ICML 2025 dekoninck25a；ICLR 2024 uncertainty routing）：便宜先掃、不確定才升級是正統；成敗核心在 quality estimator 非層數；**路由用可觀測訊號**（席間重疊/severity 分歧/證據座標缺失/辯方翻案史），不用模型口頭 confidence。
- **Debate 負面證據**（EACL 2026 findings.268）：拉長互辯出現 problem drift/無進展——背書現行「禁互辯＋獨立席」設計，並主張更早截斷。
- **統計停止規則裁決**（Codex）：SPRT 不可用（資料生成分布每輪變）；group sequential 形式可做收益極小；Bayesian 最適配但小樣本下 posterior 由 prior 主導——**先累語料後校準，順序不可倒**。
- 裁定＝**borrow-design**：借 inspection 的事前決策思想 + cascade 架構 + cluster 化記帳，全部原生實作於 skill/loop status。

## 藥方（划算排序）

1. **R2/R3 嚴格 delta-scoped + 全局哨兵**（Codex「若只能改一件」）：物理上只餵「折入 diff + 被改 claim 的上下游合約 + 前輪爭議」，另留一席便宜模型全文掃防漏。一石三鳥：省 token/消措辭型重複發現/恢復輪間可比性。改 skill 派工規則。
2. **gate 改 risk-cluster 三態帳**：同根因碎片 findings 合併 cluster，狀態 resolved / accepted-minor / disputed-major。停止＝canary caught ∧ 無 disputed-major ∧ 高風險 claim ≥2 獨立 finder 覆蓋 ∧ 本輪無新 cluster。capture-recapture 降 advisory。**解 minor 永續供應**。動 `loop status --panel` gate 語意 + record 欄位。
3. **pre-flight cascade**：panel 前一道機械 checklist（未定義旗標/欄位/檔名、交叉引用、範圍自違、CLI touchpoint、測試策略對應）+ 小模型掃——清單型缺陷排乾，r1 從 v2 水準起跑，一輪收斂（K=1 本就允許）從理論變可能。
4. **辯方按共識路由 + 免辯方條件明文化**：機械證實（可執行證據+編排者自核）免辯方；席間一致+有獨立證據直折；只有低共識 ≥major 開庭。省每輪 opus pass。
5. **fold 迷你核對**：折完派便宜 agent 只看 delta 問「鏡像段跟了嗎/新舊句打架嗎/新詞有定義嗎」——殺 r3 型「補丁沒同步」findings。
6. **（後續,等語料）** 歷史 replay 校準 Bayesian expected-loss 門檻（golden 語料 10+ 份後）；severity 錨句進派工模板（major=照實作會做錯行為;文件精度/測試枚舉=minor 除非漏合約）。

## 里程碑

- **M1（skill 層,trivial 級可先行）**：①③④⑤ + severity 錨句——全是 SKILL.md/templates.md 文字改動,不動 code。✅ **已落地（2026-07-16,SKILL.md 五處:pre-flight 2.7/severity 錨/辯方路由制/fold 迷你核對/delta-scoped+全局哨兵;user-scope symlink 即時生效）**
- **M2（動 gate code,必過 design-loop）**：② risk-cluster 帳——`canary record` 加 cluster 欄位、`loop status --panel` 改停止條件。**改守衛的守衛,高風險面,進實作前本計劃過 design-loop（舊 loop 審新 loop）**。
- 驗收信號：下一個真實 spec 過 loop 的輪數/wall-clock/token 對照本計劃前的基線（fromscratch-m1 ≈3 輪/~2h）。

## M2 詳細規格（v4;r1-r3 折入）

**範圍**：只改「記錄欄位 + panel gate 停止條件」。不動 canary 判定、不動辯方、不動 legacy(非 panel)路徑。

### 記錄層（cmd_canary 的 record 子指令擴一個選配欄）

- `lumos canary record ... --clusters "名=狀態,名=狀態,..."`：該輪存活 findings 經編排者**按根因合併**後的 risk-cluster 清單。狀態白名單三態:`resolved`(已修並核)/`accepted-minor:理由`(小事,接受不改——**理由逐 cluster 內嵌於狀態值冒號後、必填**,解析缺理由 rc2;ledger 顯示理由。r3 Codex:整筆單一 note 對多個 accepted-minor 無法對應=模糊過帳)/`disputed-major`(大事,還在吵/未修)。名=kebab 短 slug(編排者命名,跨輪沿用同名=同 cluster)。
- **W-record 歸屬(r1 Codex+B 折入)**:cluster 合併是編排者一次性彙整,**每輪至多一筆記錄帶 `--clusters`**(建議掛該輪最後一筆);「該輪帶 cluster」=輪級判定(任一筆帶即算);**有效輪**同輪 >1 筆帶 → 讀側 rc2(防照抄 capture_counts「取第一筆非空」慣例靜默吞衝突);**無效輪多筆帶不 rc2、全列警告區**(r3 三方互證 Codex/opus/A:W 歸屬亦屬 cluster 語意,受統一單位裁定收口——否則無效首輪手滑雙掛=整條 status 硬掛,「完全豁免」為假)。
- **★統一單位裁定(r2 折入,一刀收四洞:Codex 謂詞/A caught-輪三讀法/B 首輪 missed 定錨+中段卡死/C ledger 蒸發)**:cluster 的一切語意(定錨/混用判定/fold/新生 advisory/ledger 正表)**只作用於「有效輪」**——謂詞=**caught≥2 ∧ missed=0 ∧ 全部 kind ∈ {caught,missed}**(r3 Codex+opus 互證補全:既有 2301-2309 謂詞對未知 kind 是盲的,`{caught,caught,kind=其他}` 會被放行——M2 須在其上加一道 kind 白名單守衛,gate/fold/定錨/ledger 四處共用同一 helper),**輪級判定、非記錄級**(嚴禁只看帶 clusters 那筆的 kind——否則「2 caught+1 missed」輪的 resolved 靜默採納,r1 C 洞換皮復發)。**無效輪(含 missed/孤席/未知 kind)完全豁免**:帶或不帶 clusters 皆不觸發混用 rc2、不定錨、其 clusters 不進 fold 與 ledger 正表——但 status **警告區逐輪列出**(格式「⚠ r<N>(無效輪) clusters 已忽略: 名=狀態,...」)(記帳不蒸發:資料本就在 `.canary-log.jsonl`,**警告區顯示即留痕**——status 是唯讀指令,不寫任何治理事件;r3 Codex 修正:前版「留痕走 governance-log」指稱錯誤且會擴範圍)。
- 不帶 `--clusters` = 無-cluster 舊帳(panel 既有三條合取 gate 不變;「legacy」一詞保留給非 panel 循序模式,兩者勿混)。**混用守衛(r1 A+B 折入;r2 改綁有效輪)**:判定在**讀側 `loop status`**(同 round 混用守衛前例 scripts/lumos:2418-2429;record 保持純 append 不讀回歷史——否則破「只改記錄欄位」範圍刀);**模式以該 loop 第一個有效輪定錨**(無效輪不定錨——B 席:首輪全 missed 的新 loop 不得被鎖死 legacy 模式):第一個有效輪無 cluster → 整個 loop 走無-cluster 舊 gate 到底,後續**有效輪**帶 clusters → 讀側 rc2,訊息分因指路(「本 loop 已定錨無-cluster 模式(定錨輪 rX);要用 cluster 帳請開新 loop id」——不得誤稱 M2 前舊帳);第一個有效輪有 → 後續**有效輪**皆須帶,有效輪半帶 rc2(無效輪豁免,見統一單位裁定)。**round-id 非連續重現(r2 Codex 必補)**:rounds 依 append 序分組;同 round-id 被其他 round 隔開後重現 → 讀側 rc2(帳本次序損壞信號,append-only 帳不容跳寫)。
- 解析驗證(r1 B 折入;r2 C 空態統一):**執行時機=寫側 `canary record`**(格式錯當場擋,不流進 append-only 帳——與讀側的混用/W 歸屬判定分工,本體明講 r2 B#4);狀態不在白名單 rc2;名含空白/逗號/等號 rc2;同輪同名重複 rc2;尾逗號空段靜默過濾;**帶了 `--clusters` 但過濾後空列表(含空字串/全逗號)→ 一律 rc2**(「帶旗標即須有效內容」,消 C 席第三空態——撤前版「空字串=未帶」特例,單一規則無歧義);段缺 `=` → rc2 明確訊息(嚴禁未捕捉例外崩潰)。**儲存結構(r3 A 折入)**:寫側解析後轉 **dict{名:狀態}** 存入 jsonl(同 capture_counts 寫側轉型慣例 scripts/lumos:2226);讀側預期結構=dict[str,str]。**讀側型別防禦(r2 Codex)**:status 讀到 clusters 欄非此結構(手改/損壞 JSONL)→ rc2 明確訊息,非 traceback。

### gate 層（loop status --panel 停止條件改造）

該 loop 定錨 cluster 模式(第一個有效輪帶 clusters)時,合取改為**兩條**(r1 折入:原條 3 降 advisory——A 席揭穿其字面版擋 accepted-minor 首現=隱性最少兩輪、自打「解 minor 永續供應」;放寬版(只擋新 disputed-major)又與條 2 冗餘。dryness 本質是人裁訊號,不硬閘):
1. **輪有效**(同有效輪謂詞:caught≥2 且 0 missed,scripts/lumos:2301-2309——r3 探針噪音自查:原「全數」措辭與現碼不符,統一為單一謂詞)——不變。
2. **cluster 帳無 disputed-major**:跨輪 fold(同名 cluster 取物理序最後一筆狀態,同 [[關係層主網_實作計畫]] M3 cascade 帳本 `_ledger_fold` 前例 scripts/lumos:4841,語意平行不共用函式)後,無任何 cluster 終態=disputed-major。**fold 只採有效輪的 clusters(r1 C 折入;r2 謂詞綁定)**——見統一單位裁定:非有效輪(任何 missed/孤席/未知 kind)整輪 clusters 忽略+警告區列帳(對齊「missed 者 findings 剔除」慣例 scripts/lumos:2311 的輪級嚴格化;否則睡著席或同輪殘 missed 的 resolved 可靜默清掉先前 disputed-major)。**取代「存活 max≤minor」**——blocker/major finding 必須屬於某個 disputed-major cluster(未修)或 resolved cluster(已修核);accepted-minor 只准裝 minor(編排者誠實紀律,GIGO 同 anchors)。
- (advisory,不進合取) **新生 cluster**:判定輪首次出現的 cluster **計數+名單**(格式「新生 N 個: name1,name2」,r2 C 數/名消歧;僅基於有效輪——無效輪不得提前『首次出現』扭曲判定)——根因級 dryness 訊號,供實質收斂人裁參考,不硬擋(硬擋要嘛冗餘要嘛復活 minor 卡門)。**實作同步義務(r2)**:capture-recapture 舊訊息(scripts/lumos:2320-2324「✗/必帶」)與 CLI help(8824-8825)須同步改 advisory 語氣——嚴禁「顯示 ✗ 但整體 PASS」;**`--panel` 下 cluster gate 恆生效,`--gate` 對 panel 為相容 no-op**(明訂,消歧義)。
- (advisory,不進合取) **capture-recapture 降 advisory**:照算照印(仍是有用訊號),**退出合取**——非定態目標下封閉族群/獨立捕獲前提偏弱(Codex 裁決),不再當硬閘;無 counts 不再 fail-closed(cluster 帳接手守門)。
- **accepted-minor 帳永久可查**:`loop status <id>` 輸出 cluster ledger 表(名/終態/首現輪/末更輪——**皆僅計有效輪,與新生 advisory 同源**,r3 opus:物理首見含無效輪會與 advisory 對不上帳)——接受不是消失,是記帳(防合法掃地毯,天花板條的機械兌現)。**邊界明句(r3 opus+A)**:loop 至今零有效輪=cluster 模式**未定錨**→沿用既有三條合取舊 gate(fail-closed,latest 無效輪即條 1 ✗);判定輪(latest)本身無效時,新生 advisory 整行改印「判定輪無效,新生統計不適用」——嚴禁沿用 latest 變數拿無效輪當首現基準。

### 明確不做（範圍刀）

- 不做 cluster 自動聚類(合併是編排者判斷,GIGO 誠實記);不做高風險 claim 雙 finder 覆蓋條件(需 claim 級標注,v1 砍——capture_counts advisory 已給重疊訊號);不動 legacy 循序模式 gate;不動 G1 refcheck 錨;不做跨 loop cluster 庫。

### 測試策略

record 解析(寫側):三態白名單過/壞狀態 rc2/名含非法字元 rc2/同輪重名 rc2/尾逗號空段靜默過濾/**帶旗標過濾後空列表(空字串/全逗號)rc2**/段缺 = → rc2 訊息非崩潰/不帶=無-cluster 舊帳不變;讀側型別防禦:損壞 clusters 欄 rc2 非 traceback;W 歸屬:同輪 >1 筆帶 → 讀側 rc2;**有效輪謂詞**(caught≥2∧missed=0∧kind 全白名單,四處共用 helper):2caught+1missed 輪的 clusters 不進 fold(掛 caught 記錄上也不進)/單 caught 孤席輪不進/**2caught+1 未知 kind 輪不進(謂詞盲區補測,r3)**;W 歸屬僅有效輪:無效輪多筆帶不 rc2 全列警告區(r3);accepted-minor 缺冒號理由 rc2+ledger 顯示理由(r3);clusters 存 dict{名:狀態}/讀側非此結構 rc2(r3);零有效輪=未定錨走舊 gate/latest 無效輪 advisory 印不適用(r3);定錨:首輪全 missed 不定錨、第一個有效輪才定錨/定錨後無效輪帶或不帶皆不觸發 rc2;混用(有效輪級):定錨無-cluster 後續有效輪帶 → rc2 訊息分因指路/定錨有 cluster 後續有效輪半帶 → rc2;round-id 非連續重現 → rc2;fold:同名跨有效輪最後狀態勝(disputed→resolved 放行、resolved→disputed 回鎖)/無效輪 clusters 忽略+警告區列帳(不蒸發);gate:fold 後有 disputed-major 擋/無 disputed-major 且輪有效(caught≥2∧0missed)放行(**含首個有效輪帶 accepted-minor 首現=可收斂**,K=1 真可行);advisory:新生 cluster 計數+名單(僅有效輪)/無 counts 不再 fail-closed/殘餘照印不進合取/舊 ✗ 訊息與 help 同步 advisory 語氣;ledger 表:accepted-minor 顯示+無效輪攜帶項列警告區;--gate 對 panel no-op 相容;無-cluster loop 走 panel 既有三條合取迴歸不變;非 panel 循序 gate(K-streak∧G1∧G2)不受影響。

## M2 審計修正紀錄

**pre-flight（2026-07-16,M1 新步驟 2.7 首戰）**:panel 前便宜 agent 排乾 4 條清單型——①cmd_canary_record 函式名不存在(實為 cmd_canary 的 record 子指令)②「四條合取」標題與「第4項退出合取」自相矛盾(實為三條)③「四條舊合取」與現碼不符(panel 舊 gate 為三條)④「legacy」一詞雙義(panel 無-cluster vs 非 panel 循序)已消歧。全數修真檔,未耗 panel 席。

**r1（2026-07-16,panel:3 sonnet 異鏡頭+Codex 否決席;M1 新規則首戰輪）**:canary a✗(advisory 高殘餘時回鍋硬條件的矛盾,A 席漏——其 F1/F2 帶行號自核採信)b✗(未定義 ledger 查詢旗標,B 席漏——其 F1/F2/F3 帶行號自核採信)c✓(憑空第四狀態自相矛盾+帳外孤兒,精準)。**caught 1/3=無效輪**;誠實記:兩 missed 席均挖出深層真洞卻漏表面植入——canary 或藏過頭,r2 校準難度+framing 加碼。Codex:核心可建、無結構性障礙,gate 改造點行號級列明。存活 6 條 distinct 全折 v2:
- **條 3 降 advisory(major,A 自核)**:字面版擋 accepted-minor 首現=隱性最少兩輪、自打核心賣點;放寬版與條 2 冗餘 → gate 收兩條合取,新生 cluster 數改 advisory 供人裁。
- **W-record 歸屬(major,Codex+B)**:每輪至多一筆帶/輪級判定/同輪多筆 rc2(防 capture_counts「取第一筆」慣例靜默吞衝突)。
- **混用守衛時機+升級裁定(major,A+B 合併)**:判定在讀側(record 純 append 不讀回,護範圍刀);首輪定錨模式;隱患節裁定折回本體消兩節矛盾。
- **missed 輪 fold 污染(major,C)**:fold 只採 caught 輪,missed 輪 clusters 忽略+警告——否則睡著席可靜默清 disputed-major。
- **解析邊界(major,B)**:尾逗號/空值/缺 = 三態補全,比照 capture_counts 防禦慣例,嚴禁未捕捉例外崩潰。
- **M3 引用消歧(minor,B)**:補 wikilink 與 `_ledger_fold` 行號。

**r2（2026-07-16,panel delta-scoped 首戰:3 sonnet+Codex;a/b 席 framing 加碼）**:canary a✓(孤兒治理帳檔——四路實證:grep 零命中/六帳封閉清單×2/`_codeloop_gov_log` 不另開檔慣例/範圍刀,精準)b✗(時間型容忍窗被當正當設計接受,連兩輪 missed → r3 該席升 opus;其 F1/F2 canary 無關核心自核採信)c✓(借名旗標——argparse 實證兩子指令皆無、僅 doctor 有且語意不相干,精準)。**caught 2/3 仍無效輪**。Codex 行使否決:「否決折入實作」兩必補+六副作用。存活 9 條 distinct 折 v3:
- **★統一單位裁定(major,Codex+A+B+C 四洞同根)**:cluster 一切語意只作用於「有效輪」(≥2 caught∧0 missed,輪級);無效輪完全豁免+警告區列帳不蒸發;留痕走既有 governance-log 不造新檔。
- **round-id 非連續重現 rc2(major,Codex)**。
- **定錨改「第一個有效輪」+rc2 訊息分因(major,B-F1 自核)**:首輪全 missed 的新 loop 不得鎖死 legacy;訊息不得誤稱 M2 前舊帳。
- **第三空態統一(major,C-F2)**:撤「空字串=未帶」特例,帶旗標過濾後空列表一律 rc2。
- **ledger 與 gate 同源+警告區列帳(major,C-F3)**:記帳不蒸發。
- **讀側型別防禦(major,Codex)**:損壞 JSONL → rc2 非 traceback。
- **summary KEY 行舊停止條件消歧(major,Codex:架構圖即真相)**。
- **檢查時機本體明講(minor,B-F4)**/**新生 cluster 數+名格式(minor,C-F4)**/**舊 ✗ 訊息與 help 同步義務+--gate no-op 明訂(minor,Codex+C-F5)**。

**r3（2026-07-16,panel delta-scoped,cap 末輪;B 席升 opus）**:canary a✓(不可執行慣例——note 前綴解析,邏輯反了 round 欄就在手上,完美)b✗(未定義快取檔,**opus 亦漏=該席三連 missed**——深鏡頭審計與表面植入偵測是兩軸的系統性觀察,三輪皆交最深 findings 皆漏 canary)c✓(無效輪防灌帳例外 vs 完全豁免互打,精準)。**caught 2/3 仍無效輪;三輪無一有效輪**。Codex 覆核:否決維持但殘餘收窄(六項判已解決)。存活 7 條 distinct 折 v4(全確定性修法):
- **unknown-kind 謂詞補全(major,Codex+opus 互證)**:caught≥2∧missed=0∧kind 全白名單,四處共用 helper。
- **W 歸屬收口有效輪(major,Codex+opus+A 三重互證)**:無效輪多筆帶不 rc2、全列警告區。
- **accepted-minor 逐 cluster 理由(major,Codex)**:`accepted-minor:理由` 內嵌必填,ledger 顯示。
- **留痕指稱修正(Codex)**:警告區顯示即留痕(資料本在 canary-log),status 唯讀不寫治理事件。
- **clusters 儲存結構(minor,A)**:dict{名:狀態},同 capture_counts 寫側轉型慣例。
- **ledger 僅計有效輪+零有效輪/latest 無效邊界明句(minor,opus+A)**。
- 版本標示 v4。
另:探針階段自查修真檔一條(gate 條 1「全數」措辭與現碼 2301 謂詞不符→統一);slot-c 獨立覆核確認該修正。

## 實務隱患（M2）

- **self-governance 循環（最重）**：M2 改的是「判定所有 spec 能否進實作」的閘——gate 邏輯錯了會系統性放行壞 spec 或永遠擋好 spec。緩解＝測試逐條對齊合約 + 本 spec 過 design-loop（舊閘審新閘）+ anchor 護測試。
- **編排者誠實依賴加深**：cluster 合併與三態標定全是編排者自報——把 major 標成 accepted-minor 即偽收斂。緩解＝accepted-minor 須帶理由 + ledger 永久可查 + canary 仍驗審計員(但不驗編排者,誠實記:比 capture-counts 的 GIGO 面更大)。
- **混用守衛的邊界**：升級裁定已折回規格本體(第一個**有效輪**定錨,r2 精化——首輪全 missed 不定錨)——此處僅留提醒:讀側 rc2 的錯誤訊息必須分因指路「開新 loop id」,否則使用者會誤以為要改舊紀錄。
- **fold 語意撞名**:cluster fold(最後狀態勝)與 M3 cascade 帳本 fold 同模式但**不同資料源**(canary-log vs rel-cascade jsonl)——實作勿共用函式硬湊,語意平行即可。
- **誤擋逃生口**:gate 兩條合取下唯一硬擋=fold 後 disputed-major(新生 cluster 數僅 advisory 不擋門,r1 已降);誤擋的出口仍是既有「實質收斂人裁」——不新增旗標。

## 天花板（誠實）

- delta-scoped 有漏看風險——全局哨兵是便宜緩解非保證；哨兵本身是弱檢查器。
- risk-cluster 的「同根因合併」是編排者判斷——cluster 切錯（兩個真問題併一個）會漏；GIGO 同 anchors。
- 這些提效都不改變誠實天花板：收斂仍只證「醒著的審計員沒再找到」，非「沒有更深的洞」。
- 提效後 minor 被 accepted 掉不再擋門——**accepted-minor 帳要留著可查**（不是消失,是記帳),否則變成合法掃地毯。
