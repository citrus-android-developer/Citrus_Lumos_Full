# dloop-m2-cluster — 凍結 findings 語料（3 輪 panel，人裁實質收斂）

design-loop `dloop-m2-cluster`（M2：panel gate 由 finding 計數改 risk-cluster 三態帳）。**首個全程按 M1 提效規則跑的 loop**（pre-flight/delta-scoped/辯方路由/fold 迷你核對/severity 錨）。panel：3 異鏡頭 + Codex 否決席；r3 起 b 席升 opus。22 條 distinct 全折；形式 gate 三輪 FAIL（canary 1/3→2/3→2/3）→ 人裁實質收斂（plan decisions#d1）。

## pre-flight（M1 步驟 2.7 首戰，panel 前）
排乾 4 條清單型：cmd_canary_record 函式名不存在／「四條合取」自相矛盾（實三條）／「四條舊合取」與現碼不符／legacy 一詞雙義。零 panel 成本。

## r1（canary a✗ b✗ c✓＝無效輪｜折 6｜max major）
canary：a=advisory 高殘餘回鍋硬條件 ✗、b=未定義 ledger 查詢旗標 ✗（兩 missed 席均挖深洞漏表面植入——canary 藏過頭，r2 校準）、c=憑空第四狀態 ✓ 精準。Codex：核心可建、無結構性障礙 + W-record 歸屬洞。
折入：gate 三條收兩條（原條 3 字面版擋 accepted-minor 首現＝隱性最少兩輪、自打「解 minor 永續供應」；放寬版與條 2 冗餘 → 降 advisory）／W 歸屬每輪至多一筆／混用守衛讀側+首輪定錨／fold 只採 caught 輪（睡著席 resolved 不得清 disputed-major）／解析防禦三態／M3 引用消歧。

## r2（canary a✓ b✗ c✓＝無效輪｜折 9｜max major）
canary：a=孤兒治理帳檔 ✓ 精準（四路實證：grep 零命中/六帳封閉清單×2/_codeloop_gov_log 慣例/範圍刀）、b=時間型容忍窗 ✗（被當正當設計接受——連兩輪 missed → r3 升 opus）、c=借名旗標 ✓ 精準（argparse 實證）。**Codex 行使否決**：兩必補+六副作用。
折入：**★統一單位裁定**——cluster 一切語意（定錨/混用/fold/advisory/ledger）只作用於「有效輪」，一刀收四洞（Codex 謂詞/A 三讀法/B 首輪 missed 定錨+中段卡死/C ledger 蒸發）／round-id 非連續 rc2／第三空態統一 rc2／ledger 不蒸發（警告區列帳）／型別防禦／summary 舊停止條件消歧（架構圖即真相）。

## r3（canary a✓ b✗ c✓＝無效輪｜折 7｜max major｜cap 末輪）
canary：a=不可執行慣例（note 前綴解析——round 欄就在手上，邏輯反了）✓ 完美、b=未定義快取檔 ✗ **opus 亦漏＝該席三連 missed**、c=無效輪防灌帳例外 vs 完全豁免互打 ✓ 精準（含「測試策略照字面轉測試會把它鎖死成 bug」分析）。Codex 覆核：否決維持但殘餘收窄（六項判已解決）。
折入：unknown-kind 謂詞補全（caught≥2∧missed=0∧kind 全白名單，Codex+opus 互證）／W 歸屬收口有效輪（**三重互證** Codex+opus+A）／accepted-minor 逐 cluster 理由內嵌／留痕指稱修正（status 唯讀，警告區顯示即留痕）／clusters 存 dict{名:狀態}／ledger 僅計有效輪+零有效輪未定錨+latest 無效輪 advisory 邊界。探針噪音自查修一條（gate 條 1「全數」與現碼謂詞不符）。
**v4 後 Codex 終核：否決解除**（逐項對原文行號查證）。

## 人裁實質收斂（誠實天花板）
1. **形式 gate 三輪全 FAIL**：無一輪 canary 全 caught。漏席恆為深鏡頭位（sonnet→sonnet→opus 三連）——**深挖與表面植入偵測是兩軸**的系統性觀察：該席每輪交全場最深 findings、每輪漏表面植入。canary 校準語料重要一課。
2. 補償性結構證據：三模型家族獨立收斂同批洞（framing 偽造不了）；每個 canary 每輪至少一席抓到。
3. M2 是 gate code：實作必過 tier=high full code-loop + mutation 冒煙——雙層安全網（M1 Check J 前例：token 消毒洞由實作級審接住）。
4. 照例：收斂只證「三輪審計員沒再找到未折的 major」，非「沒有更深的洞」；canary 判定/溯源排除/cluster 歸併皆編排者自判，非 tamper-proof。

## M1 提效實測（本 loop 即第一個受試者）
pre-flight 排乾 4 條（零 panel 成本）／辯方三輪**零 opus 開庭**（機械證實+多席互證路由）／fold 迷你核對接 4 處漏同步（1+3）／delta 包 60 行 vs 整份 spec（非定態污染受控——r2/r3 findings 均對準當輪折入,無跨輪重播）。輪數未縮（3 輪滿）——但本 spec 是守衛之守衛（最難材料），且每輪 findings 是真貨非重播。
