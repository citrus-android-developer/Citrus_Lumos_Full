# golden findings — Android側UI測試綁架構圖工作流（design-loop 收斂，2026-08-11）

處置閘 r1/r2 雙 PASS。canary 5 席 3 caught / 2 missed（missed 席 findings 依 d4 觀測制不作廢，且皆與他席獨立重合或實測有據）。**全數折入、零「接受不修」**——無 accept-reason 條目。★單家族（Anthropic）panel★：Codex ChatGPT 授權無可用模型、qwen/gemini 未安裝（waiver.json），收斂宣稱降級為單家族視角。

## r1（3 席：sonnet 通才／sonnet 邊界可執行性／opus 整合合約；去重 18 條全折）
最重三條：`platforms` 是全域開關（只宣告 maestro 會讓既有 kotlin 綁定全懸空）／綁 `[test:]` 與 code-loop S1 的關係（當時裁 d2，r2 翻盤）／真裝置重放結帳 flow 會開真單（補實務隱患節，硬性限測試門店）。
其餘：`[kill:]` 三階 v1 走不通、`[audit:]` 不可省、KEY 行單行單括號、`name:` 不得帶註解、name→path 無解析、Check T 不看目錄、缺口表三層、證據路徑前綴、delguard 歸因訂正（三席一致）。

## r2（delta 2 席：sonnet 新宣稱正確性／opus 折入一致性；去重 13 條全折）
★這輪抓的幾乎全是 r1 折入時編排者自己製造的錯★：示範測試名仍是中文／JSON `root` 沒跟散文改／「19 條」實測只有 5 條／`multiplatform` 鍵不存在／命名慣例示範違反自己／「步驟區加不算」方向反了／待辦 1 綁非星標機制上做不到／待辦 4 沒前置會開真單。
**最重：d2 前提被推翻 → 翻盤 d3**——S1 明文「紀律層規則非機械閘」、pre-push 擋的是留痕不是真跑、且已有 `code-loop skip --note` 出路；d2 為解一個不存在的死鎖要改 skill 並新造「上次實跑留痕」產物，兩者隨 d2 一起撤。

## 本 loop 的教訓（已寫進節點）
兩次犯同一型錯（r1 delguard 歸因、r2 d2 前提）＝**沒把 PRIOR-ART ① 的第二問（那一層現在做到哪了／那條規則實際長怎樣）跑完就下裁定**。這份 spec 的主題正是這件事，它在自己的審計過程裡示範了兩次。
