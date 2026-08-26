---
type: system
status: done
created: 2026-07-31
updated: 2026-07-31
tags:
  - type/system
  - status/done
summary: |-
  FLOW:`cp -R skills/lumos-project-notes slim/skills/` 建交付源目錄副本 → 跑 `slim-scan.py` 出 129 條候選 → 逐條人工裁(改寫句子/刪整段/判假陽性)→ 重跑掃描器剩 14 條、逐條可指出假陽性理由(全是「明講某指令未交付」的誠實揭露句,被裸 token/prefixed 形態誤判成教學) → SKILL.md 本身收斂到 0 候選
  KEY:修剪原則=只修懸空引用,紀律語氣照舊不動(spec 已裁定①)——語氣豁免保的是「話」不是「話所在的段落」,如 SKILL.md 原 ci-wait bullet 整段圍繞已砍指令展開,但「紅燈不過夜…不得靜默收工」這句的主詞是「CI 紅燈」不是工具,拆出來留、工具子句砍
  KEY:reference.md「子命令全覽」行(原列 53 支)整行改寫成只列 24 支保留指令,分四類(讀取/導航 12＋巡檢/治理 4＋寫入 7＋合約守衛 1=24)
  KEY:整段刪除的三處=①`pitfall_when` 欄位說明(通篇依附已砍 `impact`)②「對抗設計審計的 canary」整節(依附已砍 design-loop/canary/loop,無可拆的獨立紀律)③「安裝/生命週期」指令表(四支已砍指令的完整用法列)
  KEY:★DEBT★ 剩 14 條候選全是誠實揭露句(如「本精簡版無 `signoff` 指令,人工記錄即可」),故意保留這些句子讓讀者知道某功能不存在,不算懸空引用;唯一一條真正的假陽性形態不同=reference.md:340 的 `npx playwright install` 撞到裸散文 `install` 比對,與 lumos 指令無關
  KEY:★2026-07-31 終審 C1/C4 修復,候選數變動★——C1 在 reference.md:60 加一段揭露「doctor 建議跑 lumos init/update/self-audit,這三支未交付請忽略」,新增 5 條候選(init/update/self-audit prefixed + init/update bare-token);C4 在 reference.md:18 把「下表指令前綴與全域 lumos 等價」改寫成「不要用 python3 scripts/lumos,vendored 情境下不等價」,連帶新增 2 條候選(init/update bare-token)。兩者性質同前——都是「明講某指令不存在/某用法有風險」的誠實揭露句,不是懸空引用。候選數 14→21(SKILL.md+reference.md 合計);C4 同時把 reference.md 內 37 處 `python3 scripts/lumos <cmd>` 前綴全改成 `lumos`(vendored 完整版下前綴不等價,詳見 [[Verification/2026-07-31_公開精簡版終審修復]])——這些改動全落在保留指令上(append/context/doctor 等),不新增候選
  KEY:★2026-08-01 補一條非指令型的懸空引用★——reference.md:679「設計全文與三輪對抗審:`Projects/from-scratch重生守衛_計劃`+`governance/golden/fromscratch-m1/`」指向本包完全未交付的檔案,接手者查無此檔且無人可問;改寫成「留在完整版工具鏈,★本精簡版沒有交付那些檔案★——這裡列的規則本身就是全部,不必去找」。★方法論教訓★:`slim-scan.py` 只掃指令名(prefixed/bare-token/skill-name/span/prose 五形態),★掃不到路徑型懸空引用★(架構圖節點路徑、governance/ 語料目錄)——與「任何『我枚舉了 N 種形態』的規格都要假設有第 N+1 種」同型,本次由人眼逐檔複閱補上,不宣稱已窮盡
  KEY:★2026-08-01 交付前真跑補的教學缺口★——`claude-block.md` 與交付 `SKILL.md` 都只說「summary 欄位/summary block」,★沒明講它必須在 frontmatter 的 `summary:` 底下、不是 body 的 `## Summary` 標題★。寫錯位置的症狀很陰:`search` 照樣命中、標籤照樣解析出合約標記,但 `contracts`/`guard` 靜默回「(無合約標記)」——讀的人因此以為該節點沒有硬合約,★是靜默給錯答案不是報錯★。發現路徑:交付前對 dist 做端到端真跑時,我自己寫的測試節點就踩了這個坑;完整版行為完全一致(不是精簡造成的),故是既有教學缺口而非新缺陷。兩份文件各補一段含正確 YAML 範例的警告
  DEP:scripts/slim-scan.py｜slim/skills/lumos-project-notes/{SKILL.md,reference.md}
  TEST:掃描器對修剪後兩檔重跑 rc1(終審後候選 21/129,SKILL.md 單獨掃仍 rc0)——本身無自動化 t_slim_* 測試(內容裁決是人工判斷,機械層只有掃描器,已在 [[Systems/slim-scan-掃描器]] 覆蓋),verified_by 見下
verified_by:
  - "[[Verification/2026-07-31_slim-skill與readme落地]]"
  - "[[Verification/2026-07-31_公開精簡版終審修復]]"
  - "[[Verification/2026-07-31_接手者演練複審修復]]"
---
# slim-skill-修剪

公開精簡版交付前,對「直接複製」的 `skills/lumos-project-notes/`（`SKILL.md` + `reference.md`）做懸空引用修剪——原始檔教了大量已被精簡版砍掉的指令（`pitfalls`／`impact`／`canary`／`loop`／`self-audit`／`signoff`／`spec-trace`／`install`／`bootstrap` 等 29 支)與不交付的 skill（`lumos-design-loop`／`lumos-core-knowledge` 等)，直接複製給接手者會教他們去用不存在的東西。詳見 [[Projects/公開精簡版_實作計畫]] Task 4。

裁決統計(129 條候選逐條裁):改寫句子 50 條、整段/整列刪除 78 條、初裁即判假陽性 1 條(reference.md:340,`npx playwright install` 撞裸散文 `install` 比對,與 lumos 指令無關)。重跑掃描器後剩 14 條候選——其中 13 條是改寫後仍含指令名的「明講某功能未交付」誠實揭露句(如「本精簡版無 `signoff` 指令,人工記錄即可」),掃描器的裸 token/prefixed 形態無法分辨「教你用」與「告訴你沒有」而誤判,連同前述 1 條合計剩餘候選 14 條、逐條可指出假陽性理由,詳見 [[Verification/2026-07-31_slim-skill與readme落地]]。

規格/設計脈絡見 `.superpowers/sdd/公開精簡版_實作計畫/task-4-brief.md`(SDD 產出,非架構圖路徑,依計畫落地於此)。
