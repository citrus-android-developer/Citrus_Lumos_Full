---
type: project
status: doing
created: 2026-07-17
updated: 2026-07-17
tags:
  - type/project
  - status/doing
related:
  - "[[Systems/design-loop]]"
  - "[[Systems/pitfalls-code-loop]]"
  - "[[Projects/loop數據收集_計劃]]"
summary: |-
  KEY:來源=2026-07-17 使用者把簡化版生命週期圖餵 GPT 取得外部評審;七成建議已存在且多有實證版(L1-3分級=trivial/standard/high｜固定角色+跨家族=panel 鏡頭分工｜審查預算=cap 6/3｜影響表=impact/pitfalls manifest｜規則-測試ID=[test:]綁定+spec-trace｜保鮮=valid_under/stale/cochange｜證據格式=抑噪紀律)——外部盲測視角反向驗證設計方向
  KEY:吸收④——①同一變更同碰{業務碼,測試,hook/CI/審查規則}→tier 自動升 high(改考卷升險;待辦,動 gate code 須過 design-loop)②收斂時未修 findings 逐條「接受理由」(已落兩份 SKILL.md 收斂節,散文紀律 trivial 跳 loop)③TDD 例外明文化=已知行為測試先行/未知行為實驗先行(已落 CLAUDE.md)④「正常改動變快」立北極星指標(已落 [[Projects/loop數據收集_計劃]] KEY)
  KEY:拒收②——canary 改加權可信度評分(自報數字假精確,同 [[pbt-oracle]] 教訓:驗證層天花板=oracle 品質;missed-rate 已當指標+golden replay 校準已達「累積模型可靠度」同一目的,且錯殺 findings 由下輪重挖兜底)｜誘餌五類多樣化(四型輪替+事故反轉+載重錨定+haiku 難度探針已覆蓋)
  KEY:待盤點=pre-commit「code 無架構圖」gate 對 trivial 變更會不會逼出灌水節點——拿實際 commit 歷史數據看一次再裁,勿憑感覺加豁免
  DECISION:[2026-07-17]吸收走最小動作:散文紀律當場落(trivial 註明)、gate code 改動留 design-loop;拒收項記理由防重提(valid)
---
# GPT外部評審吸收_計劃

> 來源:2026-07-17 使用者將簡化版生命週期流程圖餵 GPT 所得外部評審全文(對話中)。GPT 只看得到白話圖、看不到架構圖與 skill 正文——等於一次「盲測外部審計」。裁定原則:已有的記對照(驗證方向)、真缺的吸收、想當然的記拒收理由防日後重提。

PRIOR-ART: ① 最小解層級——吸收①是 pitfalls --diff tier 判定加一條組合規則(既有機制小修,非新機制);②③④全是散文紀律/指標宣告,零新代碼。② 世界解過——①即審計界 separation of duties(不能自己改考卷自己閱卷)的機械化;GPT 意見本身即出處。③ 裁定=borrow-design。

## 逐條裁定

### 已存在(七成)——記對照,不動作
| GPT 建議 | Lumos 現況(更強/有實證) |
|---|---|
| 風險 L1/L2/L3 三級 | trivial/standard/high 三分流+panel_width 按級配(3/5) |
| 固定審查角色、防同質 panel | 鏡頭分工+canary 型別跨席輪替+跨家族否決席(Codex/qwen);「9 judge 2 票」教訓;r1 通才席(replay 實證) |
| 審查預算 | cap=6 筆(循序)/3 輪(panel),到頂攤人 |
| 變更影響表 | `lumos impact --diff`(合約固定席+top-8)+`pitfalls --diff` manifest |
| 規則↔測試 ID 追蹤 | ★INVARIANT★ [test:] 強綁(doctor 擋裸合約)+[S1] 條款+spec-trace+verified_by 雙向 |
| 知識有效期限/相關碼變了重驗 | valid_under+revalidate_when+`lumos stale`+cochange 守衛 |
| 意見必附證據、缺證據降級 | 抑噪紀律逐字進 prompt(無失敗場景不標/無 file:line 不臆測) |
| 真實指標(逃逸缺陷等) | [[Projects/loop數據收集_計劃]] 逃逸帳=ground truth |

### 吸收(四件)
1. **改考卷自動升險**(待辦,本計劃主交付):同一變更(commit 或 branch diff)同時觸碰 {業務代碼} ∧ {測試/hook/CI 設定/審查規則檔} → `pitfalls --diff` tier 強制 high。機械可判、成本近零;補 anchor verify 只守驗證器檔案的缺口(組合訊號沒人算)。**動 gate code(tier 是 pre-push blocking 的輸入)→ 須走 brainstorm→design-loop→TDD,不得順手改。**
2. **未修 findings 逐條接受理由**(✅ 2026-07-17 已落):design-loop / code-loop 兩份 SKILL.md 收斂節各加一句——凍結/pass 時存活未修的 minor findings 逐條附一句「為什麼接受不修」,沒理由不得收斂留痕。防「AI 說有問題就無限改」與「拖著不裁」兩頭。散文紀律,trivial 跳 loop(本行即註明)。
3. **TDD 例外明文化**(✅ 2026-07-17 已落 CLAUDE.md):已知行為→測試先行;未知行為(UI 探索/SDK 試接/效能調查/PoC)→最小實驗先行,結論定案補回歸測試;嚴禁湊數測試。實務已如此(design-loop 對 glue 空轉實證),此次只是明文。
4. **北極星指標**(✅ 2026-07-17 已落 loop數據收集_計劃):「這套流程是否讓正常改動變快,而不只是讓錯誤改動變困難」——防錯但人人想繞的流程終會被繞過。

### 拒收(記理由防重提)
- **canary 加權可信度評分**(命中率30%+引用25%+…):每項自報/自判,權重不可驗——假精確。oracle 品質天花板教訓已有帳(PBT 打臉案)。fail-closed 一票作廢是刻意設計;其擔憂已有配套:①錯殺 findings 下輪重挖兜底 ②per-auditor missed 已記帳、golden replay 校準已在累積「哪家模型審哪類 spec 可靠」。
- **誘餌多樣化五類**:四型輪替(壞引用/未定義旗標/欄位/產物)+事故反轉(incident-inv)+載重錨定+haiku 難度探針已覆蓋其五類實質。

### 待盤點
- pre-commit「改 code 沒帶架構圖」gate 是機械判定,分不出行為變更 vs 改 padding——是否實際逼出灌水節點?拿 commit 歷史統計「被 gate 逼出的節點中多少後來無人引用」再裁,勿憑感覺開豁免口。

## 下一步
- [ ] 吸收① 走 brainstorm→design-loop→TDD(tier 組合升險規則)
- [ ] 待盤點:gate 灌水數據一次性統計
- [x] 吸收②③④ 落地(2026-07-17,本 commit)
