---
type: issue
status: done
created: 2026-07-05
updated: 2026-07-18
tags:
  - type/issue
  - status/done
  - priority/P2
related:
  - "[[主動影響幅度偵測_計劃]]"
  - "[[design-loop折入守衛_計劃]]"
  - "[[design-loop折入守衛_實作計畫]]"
summary: |-
  FLAG:DECISION
  KEY:lumos-design-loop 機制缺陷——每輪把 finding 折進 spec body 後,summary/schema 範例/審計紀錄/天花板無機械綁定要同步 → 下輪審計員花 finding 抓「植入者沒同步的漂移」而非新設計問題;污染 G2 枯竭判準、拉長輪次、讓真收斂被自傷 finding 遮住
  KEY:實證來源=「主動影響幅度偵測」9 輪 loop:findings 10→7→7→8→6→5→5→8→7 不枯竭,經測約 ~2 finding/輪是折入漂移(summary 殘留舊記號/審計紀錄未標翻案/schema 範例與 body 不同步),非真設計缺口
  KEY:修法定案(見 [[design-loop折入守衛_計劃]]+[[design-loop折入守衛_實作計畫]]):**初版 lint ①§-ref+②summary→body token 被否決**(逐條對照 impact 9 輪真漂移命中≈0)→ 改**折入強制一致性閘**:lumos fold-check <path>(全文域 value-drift+reverse-omission+鏡像段列舉,排除審計紀錄段/placeholder)+ SKILL.md step7 強制子步。經 2 輪 design-loop(dogfood 鐵證機械 fold-check 剛需)→ 轉 TDD 實作
  DECISION:先記為 lumos 工具鏈改進 Issue(非某 spec 問題);真要做需自己走 brainstorm→design-loop(注意別遞歸)。與知識同步散落漂移同病根(需機械守衛逼)
  KEY:[2026-07-18]第四場域=權威派工模板漂移——templates.md 辯方段直到今日仍寫「opus;對每條≥major各派一個」:M1 路由制(07-16)與 S5 Codex 辯方(07-18)都只同步了 SKILL 沒動模板,而 design-loop KEY 明文「漂移以模板為準」=權威文件反而最舊;教訓:凡宣告「權威=X」的 X 必須進每次同步的 checklist 首位
  KEY:[2026-07-17]同病新案例=架構圖節點自身也漂——[[design-loop]] M1 落地只在 summary 頂加 KEY 增量行,FLOW 主幹+辯方 KEY 仍舊制(每條≥major開庭/無pre-flight),據 FLOW 畫生命週期圖被誤導;fold-check 只掃 spec 檔,架構圖節點 summary 內 KEY↔FLOW 一致性目前無守衛(scope 缺口)
  DEP:[[lumos-refcheck]]
  DEP:[[design-loop]]
---
# design-loop 折入漂移 → 需機械守衛

## 問題(實證發現)

`lumos-design-loop` 每一輪:審計員找 finding → 植入者(Claude)把 finding **折進真檔 spec 的 body**。但 spec 的其他表述(frontmatter `summary` block、`--json` schema 範例、`## 審計修正紀錄`、`## 誠實天花板`)**沒有機械綁定要跟著同步**,靠植入者記得手動同步。

→ 下一輪乾淨審計員讀到「body 改了、summary/schema/紀錄沒跟上」的**內部漂移**,把它當 finding 報。**這些 finding 是 loop 機制的自傷,不是設計本身的缺口**,卻:
- 污染 **G2 發現枯竭** 判準(findings 數被自傷灌水、永遠不枯竭)
- 拉長輪次(每輪 ~2 finding 花在補漂移)
- 讓「真收斂」被自傷 finding 遮住,難判斷何時該停

## 實證

「[[主動影響幅度偵測_計劃]]」9 輪 loop findings 軌跡 **10→7→7→8→6→5→5→8→7**,不枯竭。逐輪拆解約 **~2 finding/輪是折入漂移**:
- r6-F1 / r9-F3:summary KEY 殘留舊「2..depth」記號(body 已改)
- r4-F3 / r9-F4:審計紀錄某條被後輪翻案卻沒標 superseded
- r8-F5(部分)/一致性掃描抓的:schema 範例與 body 演算法不同步

即使中途做了兩次「整體固化 pass」手動補漂移,下輪仍冒新漂移——**手動同步壓不住,需機械守衛**。

## 修法方向(機械守衛,非靠紀律記得)

給 `lumos lint` / `refcheck` 加**文件內一致性檢查**(spec 內部,不只 spec→repo):
1. **§-ref 解析**:body/summary 裡 `見 §N`、`§N〈...〉` 的 `§N` 必須對到實際存在的 `## §N` 標題。**副效益**:機械擋掉 design-loop 的 (a) 型 canary(壞 §交叉引用)+ 真實 §漂移。
2. **summary↔body 欄位一致**:`summary` FLOW/KEY 提到的旗標(`--xxx`)/config 欄位/schema key,必須在 body 出現(反向亦可警示 body 有、summary 漏)。
3. **審計紀錄翻案標記**:`## 審計修正紀錄` 內某條若被後輪條目否定,需標 `superseded`/`已被 rN 翻案`(這條較難全自動,可先做半自動提醒)。

①②機械可行且高價值(①順帶強化 canary 防線);③偏語意,先做提醒級。

## 現況 / 下一步
- 先記為 lumos 工具鏈改進 Issue。真要實作需自己走 brainstorm→design-loop(⚠ 注意別遞歸:改 design-loop 的工具本身也會過 design-loop)。
- 與「知識同步散落、機制同步只改最相關段漏散落列舉」同病根——都要機械守衛逼,人手動(含 Claude 折入)都會漏。

## 新案例:架構圖節點自身漂移(2026-07-17)

同病根第三個場域——**不只 spec、不只機制文件,架構圖節點 summary 自己也漂**:
- [[design-loop]] 2026-07-16 M1 落地時,只在 summary 頂部**加了一條 KEY 增量行**(辯方路由制/pre-flight 排乾),**FLOW 主幹行沒重寫**(仍寫「對≥major每條派辯方」、無前置排乾),第 22 行辯方 KEY 也仍舊制——同一節點內 KEY 與 FLOW 互相矛盾。
- 實害:據 FLOW 行畫「lumos 生命週期圖」被誤導成舊制(辯方每條開庭/無 pre-flight/循序模式當主幹),對照 SKILL.md 才發現。skill 正文當時有同步、架構圖主幹沒有。
- 已修:FLOW 行重寫(路由制+前置排乾+--gate 三錨+golden 凍結+panel 指針)、辯方 KEY 行同步、pitfalls-code-loop FLOW 補 tier 三分流(trivial/standard/high)。
- **scope 缺口**:fold-check 只掃 spec 檔;架構圖節點 summary 內「KEY 增量 vs FLOW 主幹」一致性目前無機械守衛。若日後擴 fold-check,此為候選場域(增量 KEY 落款日期 > FLOW 未動 = 嫌疑訊號)。
