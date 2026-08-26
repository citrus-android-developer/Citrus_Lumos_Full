---
type: project
status: doing
created: 2026-08-07
updated: 2026-08-07
tags:
  - type/project
  - status/doing
summary: |
  KEY:hook 紅燈殘餘 6 筆收尾——pre-flight 勘誤:僅 3 筆真斷鏈(B 群,D2 家族訊號全覆蓋)、3 筆=已 direct 被閾砍且保底未觸發(A 群);關鍵推論=光補鏈救不動(補進來照樣被砍),綁定約束=保底觸發過保守 → 兩件並進:S1 候選生成+人裁補鏈(零 LLM,D1 實證標的=train E20)、S2 觸發放寬至「free 內 direct<N 即補至水位」(考卷 A/B 裁決)
  KEY:`lumos link-candidates <file>` 唯讀恆 rc0,不寫檔;人裁後補標準引用=正常架構圖編輯,反查自然吃到;考卷誠實界線=通用規則全庫生成+實質關係人裁,labels 不動,補鏈後數字變動如實記
  KEY:刻意不做——LLM 候選(v2+反證預篩)/Drift 符號錨(另立)/自動寫入(人閘省不掉,pbt-oracle 教訓)
  FLAG:DECISION
---
# 連結缺失補全_計劃

> 緣起:[[Projects/hook必看召回修復_計劃]] 收斂後殘餘——held 必看 miss 6 筆全屬死法③(節點無機械可抓的 code 引用),週閘 hook P@8 0.6944 距 0.70 差 0.0056,多救一筆即翻綠。第三帖藥:候選生成+人裁補連結。

PRIOR-ART: ① 最小解層級——新增**唯讀候選生成子命令**(觀測,不動任何排序/閘),補的連結=正常架構圖編輯(引用寫進節點 body,反查自然吃到,零新消費端);姿勢 borrow 自家 [[Projects/pitfalls網搜補漏_計劃]](候選→人放行→進架構圖,人閘省不掉)。② 世界解:TLR(LLM 連結恢復,arXiv 2509.05585/2508.12232)——LLM 在迴圈=不可重算,僅離線候選+人裁姿勢合法;v1 甚至不用 LLM,兩個決定論偵測器夠用(見實驗)。Drift 符號錨(路徑#符號@sha)=另一題(錨定格式升級),本計劃不做。③ Growth test 三問:事故=週閘紅燈+驗屍 6 筆死法③(機械留痕);非風格偏好;既有機制(quote-check/refcheck/seat-check/reverse-lookup)全是消費端無一做候選挖掘——蓋不住,新讀取面成立。④ 裁定=borrow-design。

## 前置實驗(2026-08-07;★pre-flight 勘誤後以 live impact 反查為準,原表 3 筆誤判已更正★)
殘餘 6 筆 miss 經 `lumos impact --json` direct 清單重放,實況分兩群:
| 群 | 節點 | 實況 |
|----|------|------|
| A(已 direct 被閾砍,3 筆) | Systems/retrieval-ranking、Projects/主動影響幅度偵測_實作計畫、Verification/2026-07-05_主動影響幅度偵測 | 帶反引號引用早存在(原實驗腳本只掃正向訊號、沒查「是否已 direct」——歸因錯誤由 pre-flight 以現碼重放抓回);同題另有 direct 存活 → 零 direct 觸發條件不成立,保底未出手 |
| B(真斷鏈,3 筆) | Verification/2026-07-10_檢索排序v1、Projects/主動影響幅度偵測_計劃、Projects/pitfalls事故觸發_計劃 | 零機械可抓引用;皆有 D2 家族訊號(鄰居引同檔/標題共詞幹) |

另 train 卷 E20(convergence-evidence-gate ← cross_audit.py)=純文字提及無反引號,D1 可抓。
→ **關鍵推論(改寫本計劃範圍)**:B 群補鏈後變成「direct 但 L≈0」——照現行閾值照樣被砍,且同題有 direct 存活時保底不觸發 → **光補鏈救不動 held 數字**。綁定約束=保底觸發條件過保守(hook必看召回修復 刻意保守的已知代價,當時如實記錄)。故本計劃兩件並進:S1 補鏈工具(架構圖衛生+D1/E20 型)+S2 觸發條件放寬(考卷 A/B 裁決)。

## 規格

### S2 保底觸發放寬(治 A 群+補鏈後的 B 群;考卷 A/B 裁決)
- 現行:僅「最終 free 集零 direct」觸發。放寬案=**「存在被閾砍/截的 direct 且 free 集 direct 數 < 保底水位」即觸發**,水位=N(沿用 LUMOS_IMPACT_RESCUE_N;即 free 內 direct 不足 N 席時補到 N,仍取分數最高被砍者、rescued 標記/第三桶語意全不變)。零 direct 舊行為=此案的特例,語意向下相容。
- 風險如實:單體檔洪水場景(多 direct 過閾)不觸發(direct ≥N 已滿足);「1 direct 存活+多 direct 被砍」場景會多補 N-1 席可能引噪——**考卷 A/B 同款 harness 裁決**(gate 同 hook必看召回修復:held P@8 護欄 ±0.02+Σmust 整數對帳 ≥+1;輸=回退觸發條件刪碼)。
- touchpoint:cmd_impact rescue 段觸發謂詞一行級;測試補「1 direct 存活+被砍 direct 存在→補至水位」「direct ≥N 不觸發」兩案。

### S1 `lumos link-candidates <code-file> [--json]`(唯讀,恆 rc0;輸入壞損 rc2)
- **D1 純文字提及**:剝 inline-code 與 fenced block 後,節點可見文字含目標檔完整路徑/檔名/去副檔名詞幹(詞幹須 ≥6 字元且非常用詞,防 `lumos`/`eval` 這類短詞洪水)→ 候選,標 `signal: plain-text`+證據行摘錄(實證標的:train 卷 E20 型)。
- **D2 鄰居家族**:目標檔的 direct 引用節點集 D 的 wikilink 一階鄰居(related/body wikilink 雙向),且滿足任一:(a) 與某 d∈D 標題共享 ≥4 字元 CJK 詞幹 (b) plan_refs/verified_by 鏈相連 → 候選,標 `signal: neighbor-family`+經由哪個 d。
- 已是 direct(有 inline-code 引用)的節點不出候選(去重);兩訊號同中標 both。
- 輸出:逐候選 `{node, signal, via/evidence}`;無候選印「無」。**不寫任何檔**——補引用=人裁後的正常架構圖編輯。
- `--all-goldset`:對 goldset edit 卷全部 file 掃一輪出彙總(驗收用)。

### 人裁協定(省不掉的閘)
- 候選清單交人逐筆判「這節點真的管這支檔嗎」;確認的由人(或人授權的編輯)把標準引用(`路徑` inline-code)寫進節點 body 適當段落。
- **考卷誠實界線**:候選由通用規則對全庫生成、逐筆按實質關係人裁——非為過卷定向補;goldset labels 不動;補完重跑考卷的數字變動=真實改善的量測,如實記(含「此輪補鏈後題集語料已變,與舊分比較需註明」)。

## 審計修正紀錄
- **pre-flight(2026-08-07,機械排乾)**:①前置實驗表 3/6 筆歸因錯——原腳本只掃正向訊號沒查「已否 direct」,live impact 反查揭穿(A 群早有反引號引用);連帶推翻「補鏈即救」假設,S2 觸發放寬入範圍 ②驗收「6 筆全出現」與去重規則自相矛盾→改 B 群 3+E20 ③「54+1」底數誤,現為 55 子命令 ④`link-candidates` 與既有 `links` 字面近,消歧:links=節點連出邊,link-candidates=code→節點補鏈候選。

## 刻意不做(記帳防回鍋)
- LLM 語意候選(v2 再議,須 pitfalls-gapfill 式反證預篩)。
- Drift 符號錨/`@sha` 過期偵測(另一題,錨定格式升級另立計劃)。
- 自動寫入節點(人閘省不掉——pbt-oracle 教訓:自動生成+自動採納=maker bias 閉環)。
- 排序/閾值一概不動(hook必看召回修復 剛收斂,天平不重調)。

## 實務隱患
- **併發/效能**:唯讀單進程掃 vault(~240 節點×regex),一次性;無熱路徑。
- **資源**:純檔案讀+stdout;無連線/鎖。
- **[self-governance]**:純觀測工具,無擋人面;誤報候選=人裁時多看一眼即棄,成本=人時,D1 詞幹下限+D2 家族條件即為抑噪。
- **[prod-irreversible]**:不適用(不寫檔)。

## 驗收線
- S1 測試:`t_link_candidates`(D1 命中/inline-code 已引不出候選/短詞幹不洪水/D2 家族命中/雙訊號 both/rc 合約);對 B 群 3 筆+E20 跑掃描:4 筆全在候選清單(通用規則召回已證訊號,已 direct 的 A 群依去重規則不出現——與規格一致)。
- S2 測試:`t_impact_direct_rescue` 補兩案(1 direct 存活+被砍存在→補至水位/direct ≥N 不觸發);考卷 A/B(harness 沿 hook必看召回修復:top8/dump-rows/env knob):gate=held P@8 不劣 ±0.02 ∧ Σmust ≥+1,輸=觸發條件回退。
- 端到端:S2 轉正+B 群人裁補鏈後重跑 held,數字如實記 history(不設「必須翻綠」為通過條件);補鏈後語料已變,與舊分比較需註明。
