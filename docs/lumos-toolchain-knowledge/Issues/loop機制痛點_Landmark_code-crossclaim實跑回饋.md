---
type: issue
status: open
created: 2026-08-14
updated: 2026-08-14
aliases:
  - 修得越勤收斂越慢
  - K計數懲罰即時修復
tags:
  - type/issue
  - status/open
  - priority/P2
  - scope/loop-engineering
related:
  - "[[Systems/pitfalls-code-loop]]"
  - "[[Systems/design-loop]]"
  - "[[Verification/2026-08-14_canary協議停用none制落地]]"
summary: |-
  FLAG:TECHNICAL
  KEY:來源=Landmark session 對 code-crossclaim loop(11 輪 24 席)的實跑回饋,經跨 session 傳訊取得(2026-08-14,Enzo 指示);五點中的「r5 單席輪無效白跑」已被 none 制解掉(見 verification),其餘四點懸置待裁
  KEY:①★K=2 與「折入即修」互相打架★——每輪把真 findings 當場修掉,該輪照記 major→不算乾淨輪→永遠差兩輪;修得越勤收斂越慢,11 輪一半是「修→審修法→再挖到→再修」長尾;候選解=「折入已修+翻紅釘已驗」的輪在 K 計數與「存活未修」區別對待
  KEY:②留痕座標三方不一致——code-loop pass 綁當前 branch/pre-push 查推送目的地 branch/check 無參數用 merge-base,三個入口三種答案;worktree 開發推 HEAD:develop 的工作流必踩,排查要三步才對上
  KEY:③覆蓋盲區實證——OrdersPayway PK 地雷(合約宣稱的行為被 schema 結構性禁止)14 席 code review 無人從 schema 對照合約;建議把「schema(PK/唯一索引/CHECK)允許合約宣稱的行為發生嗎」加進 reviewer 固定鏡頭
  KEY:④「對話裁定何時可替代 design-loop」無明文——金流設計變更按慣例該走 design-loop 處置閘,實際由 Enzo 對話中三連裁定+code-loop 11 輪收斂替代;偏離已留痕但規則缺席,值得立一條明文
---
# loop機制痛點_Landmark_code-crossclaim實跑回饋

來源:2026-08-14 Enzo 要 Landmark 專案的 session 回報當日 loop 過程(跨 session 傳訊),回報中的「機制不順」段。原始回報存於該 session 對話;其架構圖留痕見 Landmark repo `governance/review-reports/code-crossclaim/`。

## 五點回饋與現況

1. **K=2 懲罰即時修復**(上面 KEY①)——**懸置待裁**。動收斂判準屬守衛面,要走 design-loop,不可順手改。
2. **panel 補位席數要求不明**——原回饋是「r4 missed 後單席補位被判輪無效(caught<2)白跑」。**已被 none 制間接解掉**:協議停用後輪有效=記帳席≥2,不再有 caught 門檻;但「補位輪該派幾席」在 skill 仍無明文,留此條。
3. **留痕座標三方不一致**(KEY②)——**懸置**,屬工具面可修(統一三入口的 branch 語意或至少印出「本判定用的座標」)。
4. **schema 對照合約鏡頭**(KEY③)——**懸置**,是便宜的派工模板增量(reviewer 固定鏡頭加一句),但屬審計紀律變更,過一輪輕審再進。
5. **對話裁定替代 design-loop 無明文**(KEY④)——**懸置待 Enzo 裁**:回饋原話「值得 Enzo 裁一條」。

正面回饋(不入案,記著):「missed 席 findings 先 repro triage 再丟」實證有效撈回 3 條真 findings——該規則已在停用制下改寫為「可疑席(引句錨不到/通用回應)同樣觸發 triage」,寫進 code-loop skill。
