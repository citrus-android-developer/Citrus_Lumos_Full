## 核心原則：知識架構圖即唯一真相來源 — 架構圖先行（必讀，優先級最高）

**`{{KG}}` 知識架構圖是本專案系統脈絡的唯一真相來源（single source of truth）。** 程式碼只是「現在長這樣」；架構圖才是「**為什麼這樣設計 / 邊界在哪 / 哪些是不可改的合約（★INVARIANT★）/ 驗證過沒**」——這些 code 讀不出來。

> **界線（2026-07-29 外審吸收）**：架構圖權威的是**意圖與宣告合約**；「現在實際跑成什麼樣」的真相在**測試 / 實際執行 / 生產觀測**。兩者衝突時**不自動判架構圖為真**——那是有東西壞了，該查清哪邊錯並立事故節點。

### 🟢 架構圖先行（第一動作，不可跳過）

**動任何既有系統之前，你的第一個工具呼叫必須是 `lumos`，不是 grep / Read / Explore / DB 查詢。**

- ✋ **STOP 自檢**：正要 grep code、派 Explore、或查 DB 去搞懂「為什麼這樣 / 邊界 / 合約 / 欄位語意」——**停**，先 `lumos`，再下 code/DB 驗證。**不分任務類型**：開發、重構、排查、對外支援、查 DB、對帳全算「進場」（最常被合理化跳過的破口：把任務歸成「只是查資料」就略過架構圖。別這樣）。
- **入口三步**：`lumos search <關鍵字>` 定位 → `lumos context <節點>` 掃脈絡（頭部攤 ⚠ 合約）→ `lumos contracts <節點>` 查硬合約 → 然後才 grep code / 查 DB 印證。
- **條件篩選**：`lumos query --tag 家族/值 [--tag …=AND] [--active] [--contract] [--linked <節點>]`——標籤欄位的 WHERE（「金流且未收案」「連到 X 且還開著」一發拿清單）。找「講到詞」用 search；篩「欄位條件」用 query。
- **自動輔助（不取代主動查）**：`impact` hook 會在 Edit/Write 動手前自動注入「必看合約/事故＋相關 top-8＋棧別效能檢核問」——看到就順手判波及；hook 只推「碰到的」，合約邊界仍要自己查。

### 其餘原則

- **唯一真相（分層）**：架構圖與其他文件 / 記憶 / 臆測衝突 → 以架構圖為準；但**行為事實**（測試結果 / 實際執行 / 生產觀測）與架構圖衝突時**不自動判架構圖為真**，查清哪邊錯、立事故節點。**實時更新**：影響行為 / 決策 / 驗證的 code 變更，同一次工作內同步架構圖（pre-commit gate 硬擋改 code 不帶架構圖）。**退場必寫**：做完把脈絡（決策 / 驗證 / 合約）寫回。
- **對人回報用白話**：所有給人看的東西（摘要 / 結論 / 排查回報 / 設計探討當下）預設從人話起手——先給一句話重點或生活化比喻再往下談；機制術語與 file:line 能不用就不用，非用不可則第一次出現當場給一句人話解釋。術語與精確細節收進架構圖。目標是讓人少花一層理解成本，不是零術語。
- **設計動筆前先問世界（PRIOR-ART 三問）**：① 最小解在哪一層（既有機制小修就別造新機制）② 世界解過沒（真搜，非憑印象）③ 裁定 = borrow-design（預設）/ build（真沒輪子）/ adopt（例外須理由，零依賴家規下幾乎恆排除）。答案一行 `PRIOR-ART:` 記進計劃節點。
- **已知行為測試先行、未知行為實驗先行**：可驗證規則走 TDD；探索性工作先做最小實驗、結論定案後補回歸測試。**嚴禁為滿足流程寫湊數測試**。**「實驗先行」的完成判準**：講得出**一道你已經跑過至少一次、會對「這個症狀」翻紅**的指令（貼出呼叫與輸出）之前，**不准開始建立理論**——在那之前讀 code 找原因就是這條規則要防的失敗。完整紀律（怎麼建迴圈、先列 3-5 條可證偽假說、「更嚴重的症狀 ≠ 同一個原因」、「不得在真環境製造你要驗的傷害」）見 `[[Systems/診斷迴圈先行]]`。
- **計劃/設計也歸架構圖**：任何設計 / spec / 計劃產出（不論來自哪個工具）一律寫成 `Projects/<主題>_計劃` 節點（`type: project`），不寫其他 repo 路徑；落地的 Verification 以 `plan_refs` 回指。

### 寫入架構圖（規範單源在 `lumos-project-notes` skill——動筆先調用，別憑記憶）

標籤符號、合約鏈（★INVARIANT★→[test:]→[audit:]→[kill:]）、可逆性（★IRREVERSIBLE★/★CHECKPOINT★＋[rollback:]/[guard:]）、重生標記（regen）、ADR、Verification、條款追溯（`lumos spec-trace`）、業務簽核（`lumos signoff`）規格全在該 skill。此處只留三條最毒的鐵則：

1. **不確定是不是合約就不標**——嚴禁從現況 code 反推「應該是合約吧」。
2. **多個 wikilink 必須是 YAML list、一項一行**——寫成單字串會長 ghost 節點。
3. **純量 / list / decisions 一律走 `lumos set`/`append`/`decision-add`**，別手改 frontmatter。

> 寫完節點 `lumos lint <節點>` 自驗 → 收尾 `lumos doctor`；push 前 pre-push 再擋一次（doctor --ci + anchor verify + tier=high 未過 code-loop 硬擋）。

### 主動調用 Skill（遇到情境就調用，別憑記憶硬幹）

| 你要做的事 | 必調用 |
|-----------|--------|
| 排查 / 對外支援 / 查 DB / 呼叫既有 API（動手前要懂為什麼 / 邊界 / 合約） | **`lumos-project-notes`**（先 search→context→contracts）|
| 讀架構圖 / 寫筆記 / 巡檢 / 綁合約測試 / 動 `{{KG}}` | **`lumos-project-notes`** |
| 跨專案共用業務規則（升格核心 / `core_refs` / 偏離） | **`lumos-core-knowledge`** |
| 設計 spec 完成 → 進實作前：過處置閘審計 loop 到 `lumos loop status --disposal` 收斂（2026-08-04 新制：錨定引句＋處置帳全清；canary 協議 2026-08-14 已停用、輪記帳改 `record none`；trivial 可跳並註明；進場資格與 light/settle 見 skill） | **`lumos-design-loop`** |
| 分支終審前：`lumos pitfalls --diff <merge-base>..HEAD` 出 `tier: high` → 對抗代碼審；收斂後 `lumos code-loop pass --note` 留痕才能 push（pre-push 硬擋無留痕的 tier=high） | **`lumos-code-loop`** |

> 架構圖讀寫工具是 **lumos**（`scripts/lumos`，python3 零依賴；細節見 `lumos-project-notes` skill）。`lumos-*` 是 **user-scope skills**（唯一源在 `lumos-toolchain` repo、symlink 進 `~/.claude/skills/`）——每台機器首次裝一次：`git clone <lumos-toolchain> ~/harness/lumos-toolchain && ~/harness/lumos-toolchain/install.sh`。專案技術棧 skill（如 vue / csharp）見文末〈架構參考 Skills〉。
