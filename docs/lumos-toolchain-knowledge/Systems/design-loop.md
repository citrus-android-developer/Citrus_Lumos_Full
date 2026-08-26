---
type: system
status: done
created: 2026-06-26
updated: 2026-08-14
self_audit: sonnet/2026-07-24
tags:
  - type/system
  - status/done
  - risk/守衛面
verified_by:
  - "[[Verification/2026-06-19_design-loop]]"
  - "[[Verification/2026-07-09_loop三輪壓縮]]"
  - "[[Verification/2026-07-10_審計loop研究硬化]]"
  - "[[Verification/2026-07-16_dloop提效M2_cluster帳]]"
  - "[[Verification/2026-07-16_replay校準baseline_v0]]"
  - "[[Verification/2026-08-04_design-loop重設計落地T1-T7]]"
  - "[[Verification/2026-08-06_驗證層自證三件S1S3落地]]"
  - "[[Verification/2026-08-08_風險類反問v1落地]]"
  - "[[Verification/2026-08-14_canary協議停用none制落地]]"
  - "[[Verification/2026-08-18_派工編制資料化落地]]"
  - "[[Verification/2026-08-18_循序tier錨定落地]]"
summary: |-
  KEY:★[2026-08-14]canary 協議停用(單源=[[Systems/canary-audit]] d5)★——植入/判定/抽樣分權/漏抓懲罰全停;輪記帳改 `canary record none`(純處置帳載體),panel 輪有效=記帳席≥2;skill 頁頂掛告示、植入步驟標停用;「審計員有沒有讀」由 quote-check 引句錨定把關;落地驗證=[[Verification/2026-08-14_canary協議停用none制落地]]
  KEY:[2026-08-04 重設計]★收斂改走處置閘★(--disposal;完整設計=[[Projects/design-loop重設計]],r1 panel 自審收斂+人裁放行)——定位修訂「閘便宜,審不淺」(前提層錯誤明列本層職責:TDD/E2E 對 spec 理解本身無 oracle);K-streak/capture-recapture/存活≤minor 硬閘退場(歷史實測 1/38 從未放行+capture-recapture 封閉母體前提不成立);canary 降級觀測(d4);錨定紀律=finding 必附逐字引句、quote-check 對凍結快照機械驗。舊 panel 閘保留給 code-loop——★2026-08-08 撤銷:code-loop 亦改走處置閘(Enzo 具名推翻防浮動條款,見[[Projects/驗證層去模型化_計劃]];A 案機制碼保留供舊帳重放)★
  KEY:[2026-08-06 收貨三道,plan:[[Projects/驗證層自證三件_計劃]]]收貨=quote-check(引句↔凍結快照)+refcheck(finding file:line↔repo 實在性)+★seat-check★(有講沒做對帳:dispatch manifest rN-dispatch.json 宣告 materials→unreported/out_of_scope,越界另記 out-of-scope.jsonl 不進收斂帳;lens 觀測不判定/空 materials vacuous 豁免/恆 rc0 觀測)[test:t_s1_seat_check];派工慣例同步=派工當下落 dispatch manifest;新機制準入三問(Growth test,borrow evidra)入 skill 護欄後段
  KEY:★定位★[2026-07-18 使用者裁定,見 decisions d4]——design-loop=抬 spec 質量,非保 spec 正確:一輪 panel 抓便宜的(矛盾/未定義詞/缺失敗路徑)就放行,正確性歸下游 code-loop+測試+驗證、漏網進逃逸帳;**前置加重一律拒**(日報 2026-07-18『保留題接閘』已拒收勿重提——保留題留離線 replay 校準,不進閘)
  KEY:[2026-07-18]S5 跨家族落地(見[[Projects/code階段強化_計劃]])——辯方預設 Codex(成本中性替換,d4 合規;不可用退 opus 註記)+≥3-run 多數決至少 1 run Codex+家族否決保護(外家 blocker 不得僅被同門多數推翻,須執行反證或第二外家);換手效應列 [[Projects/loop數據收集_計劃]] 觀察項(收斂輪數/辯方降級率)
  KEY:★經濟學★[2026-07-20 使用者裁定,見 decisions d5]——spec 品質目標=成本平衡非精確度漸近線:缺陷分層定價(清單型→pre-flight/撞自家現實型→架構圖接地/語意矛盾→一輪panel/深層錯→下游執行接地)+邊際遞減止損+反偏誤排序(執行接地>機械查>異家族>同家族多取樣,信號種類>家族)+標記不確定比消滅不確定便宜;逃逸帳=調價器。**精確度軍備競賽類提案(更強判官/更多輪/更細spec)一律先過此教義裁**
  KEY:[2026-07-16]提效 M1 落地(見[[Projects/design-loop提效_計劃]])——pre-flight 排乾(panel 前便宜 agent 掃清單型缺陷,cascade)/R2+ 嚴格 delta-scoped(物理只餵 diff+受影響合約+前輪爭議,留全局哨兵;解非定態目標病)/辯方路由制(機械證實與多席一致免辯方,低共識才開庭)/fold 迷你核對/severity 錨句(防 framing 通膨);M2 risk-cluster 帳未做(動 gate code,先過 loop)
  KEY:[2026-07-21]★真相入口收編★(外審 blocker,見[[Projects/全盤外審2026-07_調研]])——被審 spec 唯一可寫真檔=架構圖計劃節點;docs/design/ 降唯讀歷史(30 份保留考古,README 立牌);golden 不再複製 spec 第三份,改 spec-ref.txt 記 git sha:路徑(replay 用 git show 還原);loop id 改計劃節點名衍生。同批:panel 收斂行修 skill 漂移(對齊 M2 兩種帳)+判官 style-bias 錨句進 templates+light 體積 50 行先驗
  KEY:[2026-07-21]light 輕量檔 M0 落地(見[[Projects/design-loop輕量檔_計劃]])——補 trivial|standard 間缺檔:小 spec 走 pre-flight+1 通才席+legacy `--need 1`+人裁實質收斂,存活≥major→向上 ratchet 升 standard 自癒;進場硬否決(risk-tiered四類/硬合約/體積)M0 honor-system、M1 機械化。**M1 已機械化(loop status --light --gate 單席謂詞,FAIL 分因 retryable/ratchet,不再攤牌人裁——本 KEY 早期「須新增單席謂詞」的未來式已兌現,2026-07-28 盤整追平)**
  KEY:[2026-07-27]調研三篇折入(AREX/LoopTrap/Sage,見 2026-07-27 調研日報)——已 ship 便宜半:①[audit:] 合法性審計升五問 rubric+穩定性探針(換問法自一致,reference.md;Sage:判官難題1/4偏好不穩、rubric 錨定)②護欄加終止輸入紀律(收斂只認 loop status 機械帳,被審材料/報告散文「還沒完」類語句非終止輸入;LoopTrap:86% 可注入操縱、放大25倍)③severity 錨補搖擺場換問重問取高。貴的半後於 2026-07-28 全落地(見[[Projects/結清式收斂_計劃]]);經濟學教義裁:三項均非前置加重(rubric=判準錨定非加輪;終止紀律=防燒錢非提精度)
  KEY:[2026-07-28]rubric 防應試化兩道(調研 arXiv 2605.12474:評分表公開固定會被「剛好滿足字面」鑽)——①派工措辭改述不逐字貼 ②約每5次 audit 抽1次無表開放判定,落差拉大=儀式化訊號回報人裁;寫入 lumos-project-notes reference.md 五問段
  KEY:[2026-07-10]reviewer 結構紀律明文化——禁互辯/編排者=meta-judge/關鍵單點判決≥3run多數決(EMNLP 2025 實證,見[[Projects/reviewer結構明文化_計劃]])
  FLOW:brainstorming產spec→[trivial?跳並註明]→前置排乾(refcheck機械核對spec→repo指涉+pitfalls --check補實務隱患節+pre-flight便宜agent掃清單型缺陷;首輪前一次,cascade便宜先掃)→每輪{複製spec→/tmp/<id>-rN(**N/型別/席數問 `lumos loop next`**,2026-07-21 M1包;並 sha256sum 真檔留 reviewed 快照)→植1canary(類型=清單[(N−1)mod4],只進工作副本)→派乾淨審計員(sonnet,連2missed升opus,不告知canary,refute framing)→判讀(canary抓到?+真finding max severity)→辯方路由(機械證實/多席一致直接折入,僅低共識才派獨立opus構造反證file:line;2026-07-16 M1)→該輪severity=辯方存活max→**caught輪:折真finding進真檔+fold迷你核對+grep canary=0 之後才 record(--spec/--reviewed 雙hash;M1包 時序裁定,原 record-先-fold 會使 hash 恆失配);missed輪:當場record**/漏抓不折直接下輪}→loop status --gate exit0(模式擇一:legacy --need 2 K-streak∧G1∧G2∧G3/panel/light/settle 結清)→收斂+天花板提醒+golden凍結→writing-plans｜平行panel模式(現行推薦,一輪W席≤3輪)見下方KEY
  KEY:Claude編排,lumos只出原語——Claude用Agent tool派審計員/判讀/修spec;lumos出 canary record/loop status 記錄與算收斂,lumos不spawn agent
  KEY:canary=test-the-tester——每輪偷植已知假錯驗審計員有沒有在認真抓;漏抓(missed)=該輪審計失靈,判決不採信、不折findings(防假陰性/審計員放水)
  KEY:辯方refute=對稱防假陽性——對≥major finding 走路由制(2026-07-16 M1):機械證實/多席一致免辯方直接折入,低共識才派獨立opus(乾淨脈絡、不傳審計結論)強制拿file:line反證才能降;辯方只買code層假陽性,業務層留人
  KEY:硬閘是紀律非技術鎖——loop status未CONVERGED不得進實作,但lumos擋不住「不跑就實作」;靠Claude記得調用+誠實+cap/留痕兜底
  KEY:收斂判準K=2——連2輪 caught 且 severity∈{clean,minor};max cap=6筆record,到頂未收斂則停、攤給人
  KEY:實質收斂 early-exit(2026-07-07 Landmark 實戰調參)——連K輪 caught 無 blocker/major 且新 findings 全為文件精度級 minor → 編排者可提前攤牌請人裁「實質收斂」不跑滿 cap(「你一定找得到」framing 使 G2 數字枯竭壓不到底的誠實出口;僅手動 loop,自主 loop 走 unconverged requeue)
  KEY:派工模板權威=skills/lumos-design-loop/templates.md(6角色 dispatch prompt+編排者判讀規則,Landmark 實戰抽取;SKILL 內嵌 framing 是摘要,漂移以模板為準)
  KEY:平行 panel 模式(2026-07-09,≤3輪壓縮,見 [[loop三輪壓縮_計劃]])——買獨立廣度非相關深度:一輪平行 W 個多樣審計員(tier→panel_width);收斂判準改結構信號(無-cluster 兩條合取:輪有效∧存活max≤minor;capture-recapture 殘餘★2026-08-14 降 advisory 不進合取(鑑別力≈0:殘餘<1 組下輪 major+ 67% vs ≥1 對照組 79%,p≈0.25;f1≤1 公式退化;見[[Projects/收斂閘殘餘估計降級_計劃]])★;M2 cluster 帳=兩條合取,詳[[Systems/loop-convergence-recording]])取代 K-streak∧G2 序列;`loop status --gate --panel`;混用守衛防 None phantom 輪;legacy(無--panel)完全不變
  DEP:lumos canary record --loop/--severity｜lumos loop status --need(Component A 原語)｜skills/lumos-design-loop/SKILL.md
  TEST:Component A 原語有 test_lumos.py 覆蓋;B 是 skill 非 code,以 design-loop 自跑收斂為驗證
  VERIFY:[[Verification/2026-06-19_design-loop]]
decisions:
  - content: 收斂判準 K=2(連 2 輪 caught 且 severity∈{clean,minor}),寫進 spec 本體與 loop_status --need 預設;漏抓(missed)仍是一筆 record、仍算進 cap,判決不採信但不消失
    id: d1
    context: design-loop r2 canary 護審計揪出真 BLOCKER:K=2 未敘明於 spec 本體;MAJOR:「作廢」vs「算進 cap」矛盾——漏抓那輪到底算不算一輪定義不一致
    why_chosen: 「輪」「cap」「連續漏抓」全以 canary-log 記錄為準才定義一致,不存在「不記錄的 inline 重跑」;K=2 讓收斂=連 2 輪醒著的審計員沒找到 blocker/major,可觀測且有摩擦
    decided: 2026-06-19
    valid: true
  - content: canary 類型由輪序 N 決定 type=清單[(N−1) mod 4](a 壞§ref／b 未定義旗標／c 未定義欄位／d 未定義產物),無需 state 欄;missed 重跑時 N 已+1 故自動換新類型
    id: d2
    context: design-loop r2 MAJOR:rotation 無 state——若 type 要記憶/查 log 的 type 欄,植入者得自管狀態、易錯且不可審
    why_chosen: 由 N 機械推導 a→b→c→d→a 輪替,免狀態、可從 loop_status 輪歷史重現;canary 校準鐵則=「認真審抓得到但不一眼看穿」(太細不公平、太明顯訊號弱)
    decided: 2026-06-19
    valid: true
  - content: 加辯方 refute 階段(對 ≥major 每條 finding 派獨立 opus、不傳審計結論、強制 file:line 反證才能降),該輪 severity 取辯方裁決後存活 findings 的機械 max,取代編排者自剝誤判
    id: d3
    context: finding-refute 後續 spec(3 輪自動收斂):原 step4「編排者自剝審計員誤判」是沒閉合的迴歸、會放水;canary 防假陰性,但假陽性(審計員過度報警)無對稱守衛
    why_chosen: 辯方=canary 的對稱面(canary 防假陰性/防審計員放水,辯方防假陽性/防過度嚴重度);效力來源是「方向相反的對抗」+ 強制帶 code 證據,而非 code 證據本身;業務層假陽性留人裁
    decided: 2026-06-24
    valid: true
  - content: design-loop 定位裁定=抬 spec 質量,非保 spec 正確——一輪 panel 抓便宜的(矛盾/未定義詞/缺失敗路徑)就放行;正確性歸下游 code review+測試+驗證,漏網進逃逸帳。前置加重一律拒:日報 2026-07-18 提的『保留題接閘』(收斂前抽歷史考卷考審計員)拒收,理由=①信任階梯反面論證:spec 階段只有最弱驗證手段(純文字+LLM 判官),重壓在信號最弱處不划算 ②自家實證:自相矛盾測試 spec 撐過 6 輪散文審、實作真測一次現形;test-layers 跳 design-loop 走 TDD,真 bug 全在 code-loop 抓到零代價 ③導入成本:前端壓太重難導入,違反北極星(讓正常改動變快)。保留題想法降級留離線 replay 校準(不進閘不擋人);『收斂前真跑綁定測試』挪 code-loop/驗證側
    id: d4
    context: 使用者裁定:design-loop 本意是提高 spec 質量而非強求完全正確,正確性靠後續 code review 和驗證環節;琢磨太多 spec 問題會難導入(前端花太多時間)。適逢日報 2026-07-18 建議往 spec 收斂閘加保留題,需明確拒收防自主 loop 撿走重做
    why_chosen: 與既有方向同線(三輪壓縮/pre-flight 排乾/辯方路由全是在砍 spec 階段成本);逃逸帳架構本就承認 spec 不完美由下游接;錢花在驗證信號最強處(code 階段有真測試)
    decided: 2026-07-18
    valid: true
  - content: spec 品質經濟學(d4 續章)——目標=成本平衡的品質提升,非精確度漸近線。四原則:①缺陷分層定價:每類缺陷在最便宜層抓——清單型(未定義詞/斷引用)→pre-flight 機械預掃;撞自家現實型(與既有機制/決策衝突)→架構圖接地(impact/contracts);語意矛盾型→一輪廣度 panel(sonnet 夠);深層設計錯→下游執行接地(真測/code-loop,單位準度最高)。不在貴層重複買便宜層能抓的、不在抓不到的層硬砸(自證:自相矛盾 spec 撐 6 輪散文審真測一次現形;codestage 3 blocker 全是撞自家現實型) ②邊際遞減止損:首輪抓大宗(replay 實證:單席首輪廣度驚人,多輪價值在折入迴歸),預設一輪抓便宜就走 ③反偏誤多樣性排序:執行接地>機械查>異家族 LLM>同家族多取樣——信號種類多樣性>家族多樣性(AI 偏誤 universal,交叉審計買的是同門盲點保險非完美) ④精確本身有成本:寫作+審查+漂移面(本週九處漂移即證),「標記不確定(NEEDS CLARIFICATION/範圍刀/誠實天花板)」比「消滅不確定」便宜。逃逸帳=調價器:哪類缺陷漏到哪層的帳回饋抓取層調整,先攢帳後調參
    id: d5
    context: 使用者裁定:論文傾向 spec 精確度軍備競賽(判官更強/審更多輪);但 AI 偏誤 universal 非特定家族,交叉審計也不會有 100% 完美 spec——目標應放在高效、成本最平衡地提高 spec 品質。適逢 2026-07-20 日報判官可靠度專題,需明確此教義防日報/自主 loop 端出精確度最大化提案
    why_chosen: 三自家實證支撐(6輪漏抓/replay首輪廣度/codestage blocker 型態分佈);與 d4 抬質量定位、北極星(正常改動變快)、逃逸帳架構完全同線;分層定價讓每塊錢花在該類缺陷最便宜的抓取層
    decided: 2026-07-20
    valid: true
---
# design-loop

`skills/lumos-design-loop/SKILL.md` —— **canary-護的設計審計 loop**,進實作前的硬閘。對齊 lumos 治理的 loop-engineering 方向:讓「每個計畫都先進 loop 打磨、再進最終實作」成為標準路徑。

## 源起
日報 2026-06-18 gap:「內迴圈派 Sonnet 當審計員,卻從沒檢查它這一輪到底有沒有在認真抓。」suggestion 借 Codex『驗收要比迴圈本身可靠』:每輪審計先偷塞一個已知假錯(canary),看審計員抓不抓得到,抓不到代表這輪審計失靈、回報的「乾淨」作廢重跑。此 gap 直接催生 Component A(`canary record` 原語)與 Component B(本 skill,把 canary-護的對抗審計 loop 編排成標準路徑)。

## 定位:Component A / B 分工
- **Component A**(`docs/design/2026-06-19-convergence-recording.md`(唯讀歷史)):lumos 出**原語** —— `lumos canary record --loop/--severity`(寫 `.canary-log.jsonl`)+ `lumos loop status --need`(讀 log 算收斂)。有 `test_lumos.py` 覆蓋。
- **Component B**(本節點 = 本 skill):Claude 的**編排層** —— 用 Agent tool 派審計員、判讀、修 spec。**lumos 不 spawn agent**;Claude 照 SKILL.md 跑程序。

## 每一輪的程序(SKILL.md §「每一輪」)
1. 複製 `docs/design/<id>.md` → `/tmp/<id>-rN.md`;**N = `lumos loop status <id>` 已有輪數 + 1**(不靠記憶)。
2. 植 1 個 **canary**(additive、只進工作副本、**真檔永不含**):類型由 N 機械決定 `清單[(N−1) mod 4]`(a 壞§ref／b 未定義旗標／c 未定義欄位／d 未定義產物),嵌唯一 token 定位。
3. 派**乾淨審計員**(Agent tool、`model: sonnet`、不告知有 canary、refute framing 逐節找洞)。連 2 次 missed 後升 opus。
4. **判讀**:① canary 是否被清楚且正確點出性質(光 token 出現不算);② 排掉 canary 後最嚴重真 finding(clean/minor/major/blocker);③ **辯方路由**(2026-07-16 M1:機械證實/多席一致直接折入,僅低共識才派獨立 opus 構造 file:line 反證);④ 該輪 severity = 辯方裁決後存活 findings 的機械 max。
5. `lumos canary record caught|missed --loop <id> --severity <存活max> --auditor <model> --note "r<N> type=<a-d> …"`。
6. **漏抓** → 判決不採信、**不折** findings、直接下一輪(仍是一筆 missed record、仍算 cap、自動換 canary 類型 + framing 加碼)。
7. **抓到** → 只折辯方存活的真 finding 進 `docs/design/<id>.md`;**commit 前 `grep -c '<canary token>' docs/design/<id>.md` 必須為 0** 再 commit。
8. `lumos loop status <id> --need 2` → exit 0 出 loop;exit 1 → 回 step 1。

## 收斂演算法(Component A `cmd_loop_status`)
讀 `.canary-log.jsonl` 的 **append 序**(不 ts-sort:ts 只到秒、同秒並列),篩 `loop==id`。tail-K 滑動窗:`converged = len(rounds)≥need 且 last-K 筆皆 good`,`good = kind==caught 且 severity∈{clean,minor}`。missed/缺 severity 視同未收斂。exit 0=CONVERGED／1=未收斂(含無記錄)／2=真錯誤。

## 護欄與誠實天花板(SKILL.md)
- **連 2 次漏抓**(canary-log 最近 2 筆都 missed;中間一筆 caught 即重置)→ 升級:sonnet→opus +(soft、人工)切小 spec 各自開 loop。
- **max cap = 6 筆 record**:到頂未收斂 → 停、攤給人、記「達 cap 未收斂」,別無限燒。
- **硬閘是紀律非技術鎖**:lumos 擋不住「不跑就實作」(同 pre-commit `--no-verify` 後門),靠 Claude 記得調用 + 誠實 + cap/留痕事後可查。**trivial 改動**(typo/一行/純機械)可跳,但寫一句為什麼跳。
- **誠實天花板**(收斂後務必向人提醒):① 完整性 —— 收斂只證「連 2 輪醒著的審計員沒找到 blocker/major」,不證沒更深問題;② 整合性 —— canary-caught／severity／誤判判定皆由植入者自判、無外部檢查,是**沒閉合的迴歸**,loop 是可觀測+摩擦+地板,**不是 oracle**。

## 已知限制(v1 YAGNI)
- 不做:lumos spawn agent、架構圖自足性審計 loop(v1 只設計/spec)、自動 canary 生成、改 brainstorming/writing-plans skill 本體。
- 三重自判(canary 抓到沒／severity／誤判)根本上不 tamper-proof;辯方 refute 收窄了假陽性那一面、canary 收窄假陰性那一面,但都不是 oracle。

## 相關
- 設計稿(B):`docs/design/2026-06-19-design-loop-skill.md`(design-loop 收斂,5 輪、0 漏抓,severity 單調 blocker→blocker→major→minor→clean)。
- 設計稿(A 原語):`docs/design/2026-06-19-convergence-recording.md`(唯讀歷史)。
- 設計稿(辯方 refute 後續):`docs/design/` finding-refute(3 輪自動收斂)。
- 實作落點:`skills/lumos-design-loop/SKILL.md`(B);`scripts/lumos` `cmd_canary` + `cmd_loop_status`(A 原語)。
- 衍生:`docs/superpowers/plans/2026-06-20-autonomous-iteration-loop.md`(自主迭代 loop 跨輪 headless 跑 design-loop)。
