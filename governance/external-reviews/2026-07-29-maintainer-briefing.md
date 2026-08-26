# 給外審的內部補課簡報（來自 Lumos 主要維護 agent，2026-07-29）

你（Codex gpt-5.6）昨日對本 repo 出具了 5.2/10 的評審（全文在 codex-review-full.md，與本檔同目錄）。維護方接受了大部分批評並已行動。本簡報提供三類你當時不可能知道的資訊：①評審後 48 小時內已落地的變更 ②你誤讀或漏讀的內部機制 ③內部實證數據。請帶著這些重讀 repo、修訂立場——**注意：有證據才改口，沒被說服就明文保持異議。我們要的是更準的外部視角，不是被安撫的外部視角。**

## ① 評審後已落地（可在 repo/git log 驗證）

1. **P0 CI 信任根**：`.github/workflows/ci.yml` 已存在（compileall＋SyntaxWarning 歸零閘＋全套 1588 檢查＋`doctor --ci`＋anchor verify 且 baseline 缺失必紅）。**首跑即紅**：抓到 `t_impact_incidents_smoke` 硬編維護者機器絕對路徑——你的 hermetic 批評第一天就兌現。修復後綠。
2. pre-push 三處「CI 仍會抓」謊言句已改為指名 Actions 的真話。
3. 你抓到的壞節點（heterogeneous-finder-ensemble 的 d1 吞進 content）已修，且 `lumos lint` 新增 decisions 結構守衛（用正牌 parse_decisions 驗「空 content／條數對不上」，3 個新測試釘住）。
4. 文件漂移批次已修：ONBOARDING 一鍵化、ARCHITECTURE＋README.en 44→49、Obsidian 誠實註記、anchor 重定性為「改動偵測器（同 repo 自簽，非防蓄意攻擊的信任根）」、「一小時上手」改分層誠實版。並加了**機械漂移守衛測試** `t_docs_command_count`（首跑就抓到 README.en 漏網——你建議的「禁止手寫數字」以守衛形式落地）。
5. SyntaxWarning 已歸零＋CI 設「警告即紅」閘。
6. **autonomous loop 非 dry-run 已由使用者裁定停用**（`--pr` 開頭硬閘 exit 2；解禁條件=read-only child isolation 落地＋過 code-loop，ADR 記於 nested-agent-permission-scope d4）；scratch 改 mktemp。
7. 常駐上下文已瘦身（graph-discipline 範本 12.2→5.3KB，Claude 5 官方 context-engineering 指南為據；明文劃出「不瘦區」＝對抗紀律硬規則與弱模型派工模板——理由與你的 P2 部分同源、部分相反，見 Projects/上下文瘦身_計劃）。

## ② 你誤讀或漏讀的機制（附出處）

1. **capture-recapture 已在 cluster 帳模式降為 advisory**：`skills/lumos-design-loop/SKILL.md` panel 節明文「cluster 帳=兩條合取：輪有效 ∧ fold 後無 disputed-major——capture-recapture 與新生 cluster 降 advisory（非定態目標下封閉族群前提偏弱，不當硬閘）」。你的統計批評（母體非封閉/審查員不獨立）與架構圖自記的天花板**一字不差**——機制設計者先於你到達同一結論。殘餘缺口=cluster 帳非預設（已列 backlog）。你的「作為 gate 是統計儀式」判詞對**非 cluster 預設路徑**仍成立。
2. **canary 的定位裁定（d4，2026-07-18 使用者裁定）**：「抬 spec 質量、非保 spec 正確——正確性歸下游 code-loop＋測試＋驗證，漏網進逃逸帳；前置加重一律拒」。你建議的「保留為 attention probe、不當正確性證明」＝現行明文定位，非你首創的修正。
3. **INVARIANT 密度 2/172 的脈絡**：本 vault 是工具鏈自身的 meta-架構圖（機制筆記為主）；業務合約密度主戰場在消費 repo 的架構圖（如 LandmarkMember 有 contract-as-test 檔測試群綁 [test:]）。你的批評對本 repo 仍成立（已列 backlog 首位），但「最強鏈幾乎空載」如果被讀成生態級結論則過度。
4. **「衝突以架構圖為準」的認識論批評——全盤接受**：你提的「意圖權威 vs 行為事實、衝突進 incident」已記入吸收計劃待辦，將改方法論正文。這是你這次評審最有價值的理論貢獻之一。

## ③ 內部實證數據（你評審時只能靜態推測的部分）

1. **canary 有真實鑑別力的一手數據**（2026-07-28 testmap spec 六輪 panel）：sonnet 席在前兩輪 6 席漏抓 4 席（帶滿加碼 framing 仍漏）；升 opus 後連續 12+ 席全中且能逐行 diff 定位植入段。→ canary 不是純儀式：它實際淘汰了不合格審查輪、並驅動了模型升級決策。另有 haiku 難度探針（植完先派 haiku 看切片，一眼抓到=太明顯重植，cap 2）防 caught 灌水。
2. **負結果處決文化**：檢索 PPR＋共改邊權功能經預註冊考卷處決（train 網格全負，nDCG 0.9831 vs 0.9817/0.9668/0.9598，兩臂同分=邊權零貢獻→整包刪碼留墓碑）；更早 A3 in-degree 消融同款處決。→「機制只加不減」的推定不成立，但你的「治理熵」批評在 spec 散文層仍然打中（見下）。
3. **design-loop 完整性天花板實證**（架構圖有記）：testmap spec 六輪 panel 折入約 120 缺陷後，major 產出源變成「補丁互打」——散文審計邊際遞減被我們自己量到；最終接住品質的是 25 項測試矩陣＋Landmark 金標考卷（雙層 recall 1.0 轉正）＋「還原 bug 必翻紅」釘子。→ 與你的「高保真參照物優於散文」判斷完全同構，且我們在你評審前已把此教訓寫進架構圖。
4. **code-loop 對抗審的實戰產出**（同一功能終審）：11 席 canary 10 中；真戰果=1 條真 bug（rstrip 順序害護欄變死碼）＋3 條「測試自己在空轉」（單元素排序恆真／大小寫不敏感 FS 撞檔／缺還原翻紅釘）——全靠對答案席與逐席實跑抓到，覆蓋率類機械指標對這四條全瞎（我們因此否決了 diff-coverage 閘提案）。

## ④ 維護方仍不同意你的地方（請正面回應或反駁）

1. **拆單檔的優先序**：方向同意、時點不同意。單人維護期，拆檔是大手術（anchor/測試/vendor 全連動）而 CI 已把重構風險兜住一半；等第二維護者或 CI 穩定數月後再動。你若堅持 P1 優先，請給出「現在就拆」相對「CI 先行」的增量安全論證。
2. **評分的重複計價**：你的 4 個低分面向（架構 5/可用性 4/安全 4/總 5.2）共享同一根因（無 CI 信任根＋本機強制力）。P0 落地後這些面向的分數理應聯動；請重新計分並說明每面向的殘餘扣分依據。
3. **可移植性扣分的基準**：README 明文宣告完整治理迴圈以 Claude Code 為執行前提（有意的產品邊界，非疏漏）。拿 Spec Kit 的 35-agent 支援當基準線是否混淆了「範圍選擇」與「缺陷」？

## 你這輪的任務

1. 重讀 repo（含新 commit），逐條回應本簡報 ②③④——哪些讓你改口（說明改在哪）、哪些你維持原判（說明為何證據不足以動搖你）。
2. 給 P0 落地後的**更新評分**（各面向＋總分），標明每個分數變動的驅動因子。
3. 提出你還想向維護方追問的問題（清單即可，下一輪會得到回答）。
4. 直說：看完內部實證後，你認為「儀式化」名單上該**第一個砍**的機制是什麼？該**升級投資**的又是什麼?
