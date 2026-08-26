# lumos-design-loop:參考層

> ⛔ **canary 協議已於 2026-08-14 停用**(Enzo 裁;單源=Systems/canary-audit d5 與 SKILL.md 頁頂告示)。本檔所有 canary 段(§A 生成硬化、§C 帶餌條款、caught/missed 判定)**僅供回放歷史帳判讀,不再是動作指令**;每輪記帳改 `canary record none`。

> `SKILL.md` 是操作層(每輪都要走的步驟與判準)。這裡放**按需查閱**的深規、理據與出處。
> `SKILL.md` 裡的指標會告訴你什麼時候該翻到這裡的哪一段——**撞到就讀，別憑摘要硬幹**。

---

## A · canary 生成硬化(植 canary 前讀)

三條，2026-07-10 立；borrow FLAWS(arXiv 2511.21843)／IBIR(ACM TOSEM 2022)。設計見 `[[canary生成硬化_計劃]]`。

**A1 · 載重錨定。** 植入位置不隨機挑段——先掃 spec 抽 3-5 條**載重最高的可證偽 claim**（演算法定義／門檻數字／整合接點），canary 植在其中一條的失效變體上。canary 測「有沒有讀懂核心」，不是「有沒有掃過周邊」。

**A2 · 難度探針。** 植完、派審計員前，派一個 **haiku 探針**：只給被植段落 ±20 行，prompt「這段有沒有內部不一致／未定義引用？」

- haiku 一眼抓到 → **太明顯**，重植更藏的變體再探（上限 2 次）
- 沒抓到 → 難度合格

探針結果記入該輪 canary note（`probe:pass` 或 `probe:recraft×N`）。

理由：FLAWS 實測**生成者自己抓得到的錯有 61-93% 被過濾掉**——不濾，caught 會灌水（與 mutation score 冗餘教訓同源）。

**A3 · 事故反轉（機會性）。** 型別輪替前先查事故語料：`lumos search --path Issues`，加上 `pitfall_when` 命中 spec 主題域。

- 有匹配 → 把該事故的**修法反轉**成 canary（標 `type=incident-inv`），取代該 slot 的通用型別
- 無匹配 → 照舊輪替

理由：事故驅動的植錯比盲 mutation 寫實且有區分力（IBIR 實證）。

---

## B · reviewer 結構紀律(派 panel 前讀)

2026-07-10 研究明文化；實證出處見 `[[reviewer結構明文化_計劃]]`。

**B1 · 禁互辯（硬規則）。** reviewer 互不通訊、不得看彼此輸出迭代辯論；分歧交編排者裁，不回饋重辯。

實證：multi-agent debate **第一輪即劇烈放大** position／verbosity／CoT／bandwagon 偏誤，且後續輪不自癒（EMNLP 2025）。★範圍限定★：該實證測的是**偏誤軸**，另有研究稱 debate 提升**準確率軸**——lumos 審計場景選抗偏誤。

**B2 · 編排者＝meta-judge。** 判讀段（canary 判定／去重／severity max／辯方裁決聚合）是 meta-judge 聚合——**只聚合一級判決、不重審內容**。judgment pool 越大越抗偏誤（這是 W 寬 panel 的理據；meta-judge position consistency 0.793→0.854）。

**B3 · 關鍵單點判決 ≥3 run 多數決。** 適用窄集合：cap 攤牌前的最後裁定、blocker 級辯方裁決有爭議。

★誠實限定★：同 judge 同輸入跨 run α 最好僅 **0.563**（低於 0.8 可靠線）——多數決**只壓 stochastic 變異，不壓 correlated 系統性盲點**；後者靠異家族 panel，兩者不互替。

跨家族 slot：≥3 run 中**至少 1 run 用 Codex CLI**（qwen 次選）；皆不可用才退異型號同門，並於 note 註記偏離。

**B4 · 家族否決保護（2026-07-18）。** 任一家族 run 提出 blocker，**不得僅以他家族的同門多數推翻**——降級須具備可執行反證（真跑）或第二外家族確認；拿不出則 blocker 維持。

理由：fail toward safety，防同門 2:1 壓掉唯一外家的正確意見（＝重現同門盲點）。

---

## C · 跨家族席的能力宣告制(2026-07-30 修訂)

**有可用的外家 → 該席也要帶 canary。** 舊版「不帶 canary、只作否決」已作廢：否決席過去沒有注意力檢查，等於「它講得有沒有道理」全由編排者自己讀了算——**maker 自判**，正是本機制要消滅的東西。

2026-07-30 實例：外家席交出打掉整份 spec 前提的最重發現，但帳上沒有任何機械證據證明它醒著。

其 findings 是否佔 W／計入重疊帳，**維持現狀不動**（見下）。

**沒有可用的外家 → loop 照跑，不擋。** 但必須在 `canary record` 的 note 留「單家族」，且收斂結論的措辭降級為「單家族視角下未發現」。

★沒有跨家族不是「不准收斂」，而是「收斂的宣稱要更小」★——本 skill 是要發給別人用的，硬性要求第二家廠商 CLI 等於給零依賴工具鏈加一個外部依賴、讓沒有的人開箱即壞。**誠實地少講一點 > 擋住別人不給用。**

**為什麼不直接升主力席。** 2026-07-30 日報建議「跨家族席從否決席升為主力席」，本次**刻意只採一半**：升主力席會動到佔 W、capture-recapture 帳與 fail-closed 分級（code-loop 已走過該路，但其 fail-closed 是為本 repo 寫的，套到消費端＝跑不了），與可攜性直接衝突。另立題目再審。

---

## D · panel 收斂的兩種帳(問收斂前讀)

2026-07-21 修 skill 漂移、對齊 M2 現碼；見 `[[design-loop提效_計劃]]` M2。

指令：

```
lumos loop status <id> --gate --panel --spec <計劃節點.md> --min-seats <W> --repo <root>
```

★兩個旗標各自兌現一個承諾★：

- 不帶 `--spec` → **G3 hash 不啟用**
- 不帶 `--min-seats` → **caught≥2 即可過**（standard/high 的 3／5 席承諾就沒兌現）

cluster 帳模式同樣生效，不得繞。

### D0 · 先決定用哪一種帳（★只有第一輪能決定★）

模式由**第一個有效輪**定錨，之後要換只能開新 loop id。`lumos loop next` 在 N=1 且 panel 模式時會提示你這件事——**看到那條 hint 就是要你現在做決定**。

| 這個 loop 的 findings 會長成什麼樣 | 選 |
|---|---|
| 散成**性質不同**的風險群（例：「規格縮水」＋「邊界 bug」＋「效能回歸」） | **cluster 帳**（D2） |
| 單一主題、findings 同性質 | 預設**無-cluster**（D1） |

**為什麼性質不同就別壓成一個數**：單一 max severity 會讓一軸遮蔽另一軸——「規格縮水 minor」躲在「邊界 bug major」後面，修完 bug 那輪就乾淨了，縮水那條只在 findings 數裡留下一個 +1。cluster 帳逐群追蹤，每群要嘛 `resolved`、要嘛 `accepted-minor:理由`（**理由內嵌必填**），`disputed-major` 存在就不收斂。

★2026-08-02 量測（誠實的反面教材）★：M2 落地至今 **316 筆 canary 記錄裡只有 1 筆帶 `--clusters`**，而那一筆是開發它的 `code-m2cluster` 自己——**34 個用過 panel 的 loop 有 33 個靜默落回無-cluster 舊帳**。機制不是不好，是**沒有任何地方在該選的時候提起它**。`loop next` 的 hint 就是補這個洞。

### D1 · 無-cluster 舊帳＝三條合取

1. **輪有效**：caught≥2 且 0 missed（near-perfect）
2. **存活 max ≤ minor**（只算 caught 席）
3. ~~capture-recapture 殘餘 < 門檻~~ **⛔ 2026-08-14 降 advisory 不進合取**(鑑別力≈0:67% vs 對照 79%,p≈0.25;見 Projects/收斂閘殘餘估計降級_計劃)——觀測行照印,無 counts 印缺席提示不 fail

### D2 · cluster 帳＝兩條合取

首個有效輪帶 `--clusters` 定錨後啟用：

1. **輪有效**
2. **fold 後無 disputed-major**

capture-recapture 與新生 cluster **降為 advisory**。理由：非定態目標下，封閉族群前提偏弱，不當硬閘。

### D3 · 收斂與不收斂

一個乾淨 panel 輪即收斂（K=1）。

存活 ≥major → fix → **下一輪嚴格 delta-scoped**（2026-07-16；Codex「若只能改一件」）：

- 審計員**物理上只餵**「折入 diff ＋ 被改 claim 的上下游合約段 ＋ 前輪爭議清單」
- ★不給整份 spec★——給整份＋叮嚀「重點審 delta」**無效**：審計員照樣全文翻，且折入的新文字持續污染輪間可比性（非定態目標病）
- 另留 **1 席便宜全局哨兵**掃全文防 delta 外漏（弱檢查器，advisory）
- cap＝3

### D4 · 混用守衛

panel 記錄（帶 round）與 legacy 記錄**不可混用**：`--panel` 要求全帶 round，否則 rc2。防 None phantom 輪偽過。

### D5 · 為什麼這樣算(理據)

散文收斂沒有干擾信號可用，但 **framing 汙染 count、不汙染結構**：capture-recapture 讀重疊、ODC 讀 class、AC 讀 coverage——三者繞開被汙染的 count，framing 不動它們。詳見 `[[loop三輪壓縮_計劃]]`。

---

## E · 誠實天花板的證據

**E1 · caught ≠ 覆蓋（2026-07-30 外部實證入帳）。**

canary 抓到只證該席**醒著**，不證它審得夠廣。植錯誤考審查系統的實測：**最強單一配置只抓到 71.6%，六個模型的並集才 83.3%**，且不同模型抓到的是**不同種類**的錯（arXiv 2606.19749，Dang Nguyen 等，2026-06-18；經 2026-07-30 治理日報引入）。

推論：**單席 caught 的輪次不得被當成「這一輪審夠了」**；廣度只能靠多席 × 多鏡頭 × 跨家族買，買不到就如實把收斂宣稱講小。

同源提醒：該研究同時指出真實部署最常見的抱怨是**誤報與無關痛癢的小意見**——與本 skill 的抑噪紀律同向。

**E2 · 沒閉合的迴歸。** canary-caught／severity／哪些是「誤判」，三個都由植入者（你）自己判、無外部檢查。loop 是**可觀測 ＋ 摩擦 ＋ 地板**，不是 oracle。

（`SKILL.md` 步驟 4.5 的抽樣分權壓的正是這個單點，但它是 telemetry、不進 gate，所以壓的是「唯一判定者」而非證明判定為真。）

---

## F · light 檔的天花板

light 用深度換速度是**設計本意**：單通才席漏的細微 bug，靠 ratchet ＋ 下游 code-loop／測試 ＋ 逃逸帳兜。

M0 的進場硬否決是 **honor-system，不比 maker 誠實更可靠**（M1 才機械化成 filter）。

light 檔 spec 的**下游逃逸率該留意**（逃逸帳＝調價器）：偏高＝進場訊號要收緊。

---

## G · 收斂後為什麼要凍結

borrow：Giskard meta-evaluation。

凍進 `governance/golden/<loop-id>/`：

- **spec 不再複製第三份**（2026-07-21 真相入口收編：多一份副本＝多一個漂移源），改寫 `spec-ref.txt` 一行 `<git commit sha>:<計劃節點路徑>`；replay 時 `git show <sha>:<路徑>` 即還原凍結版
- `findings.md` 照舊——辯方裁決後存活 findings 清單，**這是 golden 獨有的數據**
- 存活未修的 finding **逐條附一句「接受理由」**（文件精度級／成本不值／延後至何時）。沒理由的未修 finding 不得收斂留痕——防「說有問題就無限改」與「拖著不裁」兩頭（2026-07-17 外部評審吸收，見 `[[GPT外部評審吸收_計劃]]`）

golden 語料是 **auditor 校準的時間資產**：累到 10+ 份即可做 replay 校準——拿凍結 spec 重跑審計、對照已知 findings 算各模型接住率，決定哪類 spec 直接上 opus。

---

## H · 出處與考古

操作層刻意不帶日期與工作包編號（那是規則的**來歷**不是規則本身）。要追溯就從這裡進：

| 規則群 | 來歷 | 架構圖節點 |
|---|---|---|
| loop 定位「抬質量非保正確」 | 2026-07-18 d4 使用者裁定；**前置加重一律拒** | `[[design-loop]]` d4 |
| 真相入口＝架構圖計劃節點；`docs/design/` 降唯讀 | 2026-07-21 收編 | `[[全盤外審2026-07_調研]]` finding 1 |
| canary 生成硬化三條 | 2026-07-10 | `[[canary生成硬化_計劃]]` |
| reviewer 結構紀律 | 2026-07-10 研究明文化 | `[[reviewer結構明文化_計劃]]` |
| panel ≤3 輪壓縮、收斂判準理據 | 2026-07-09 | `[[loop三輪壓縮_計劃]]` |
| pre-flight 排乾、severity 錨、辯方路由、delta-scoped、兩種帳 | 2026-07-16 提效 M1 / 2026-07-21 M1包・M2 | `[[design-loop提效_計劃]]` |
| light 檔 | M0 2026-07-21 落地 | `[[design-loop輕量檔_計劃]]` |
| settle 結清模式 | 2026-07-28 落地 | `[[結清式收斂_計劃]]` |
| 未修 finding 要附接受理由 | 2026-07-17 外部評審吸收 | `[[GPT外部評審吸收_計劃]]` |
| caught≠覆蓋 | 2026-07-30 治理日報引入 | arXiv 2606.19749 |
| 終止輸入紀律 | 2026-07-27；borrow LoopTrap arXiv 2605.05846 | — |
| 難判搖擺換問法重問 | Sage 2026-07-27 | — |
| `[NEEDS CLARIFICATION]` 慣例 | borrow spec-kit | — |
| 實質收斂 early-exit | 2026-07-07 Landmark 實戰調參 | — |
| 合約候選清單 | 2026-07-29 使用者採納 | — |
| r1 通才席 | 2026-07-16 replay baseline 實證 | `[[Verification/2026-07-16_replay校準baseline_v0]]` |
| 跨家族席能力宣告制 | 2026-07-30 修訂 | — |

設計全文（**唯讀歷史，僅供考古**；新設計一律寫架構圖計劃節點）：`docs/design/2026-06-19-design-loop-skill.md`、`…-convergence-recording.md`、`…-canary-audit.md`。
