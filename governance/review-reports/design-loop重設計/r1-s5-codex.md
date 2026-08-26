codex
我會先完整讀投稿（含 frontmatter）與 repo 的單一真相來源，再逐一核對指定函式和 canary 量測；全程唯讀。
# CLAUDE.md
<!-- LUMOS:GRAPH-DISCIPLINE:START v1.0 — 自動注入/更新,勿手改本區塊;改範本 scripts/templates/graph-discipline.md -->
## 核心原則：知識架構圖即唯一真相來源 — 架構圖先行（必讀，優先級最高）

**`docs/lumos-toolchain-knowledge/` 知識架構圖是本專案系統脈絡的唯一真相來源（single source of truth）。** 程式碼只是「現在長這樣」；架構圖才是「**為什麼這樣設計 / 邊界在哪 / 哪些是不可改的合約（★INVARIANT★）/ 驗證過沒**」——這些 code 讀不出來。

> **界線（2026-07-29 外審吸收）**：架構圖權威的是**意圖與宣告合約**；「現在實際跑成什麼樣」的真相在**測試 / 實際執行 / 生產觀測**。兩者衝突時**不自動判架構圖為真**——那是有東西壞了，該查清哪邊錯並立事故節點。

### 🟢 架構圖先行（第一動作，不可跳過）

**動任何既有系統之前，你的第一個工具呼叫必須是 `lumos`，不是 grep / Read / Explore / DB 查詢。**

- ✋ **STOP 自檢**：正要 grep code、派 Explore、或查 DB 去搞懂「為什麼這樣 / 邊界 / 合約 / 欄位語意」——**停**，先 `lumos`，再下 code/DB 驗證。**不分任務類型**：開發、重構、排查、對外支援、查 DB、對帳全算「進場」（最常被合理化跳過的破口：把任務歸成「只是查資料」就略過架構圖。別這樣）。
- **入口三步**：`lumos search <關鍵字>` 定位 → `lumos context <節點>` 掃脈絡（頭部攤 ⚠ 合約）→ `lumos contracts <節點>` 查硬合約 → 然後才 grep code / 查 DB 印證。
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
| 讀架構圖 / 寫筆記 / 巡檢 / 綁合約測試 / 動 `docs/lumos-toolchain-knowledge/` | **`lumos-project-notes`** |
| 跨專案共用業務規則（升格核心 / `core_refs` / 偏離） | **`lumos-core-knowledge`** |
| 設計 spec 完成 → 進實作前：過 canary-護對抗審計 loop 到 `lumos loop status --gate` 收斂（trivial 可跳並註明；進場資格與 light/settle 模式見 skill） | **`lumos-design-loop`** |
| 分支終審前：`lumos pitfalls --diff <merge-base>..HEAD` 出 `tier: high` → 對抗代碼審；收斂後 `lumos code-loop pass --note` 留痕才能 push（pre-push 硬擋無留痕的 tier=high） | **`lumos-code-loop`** |

> 架構圖讀寫工具是 **lumos**（`scripts/lumos`，python3 零依賴；細節見 `lumos-project-notes` skill）。`lumos-*` 是 **user-scope skills**（唯一源在 `lumos-toolchain` repo、symlink 進 `~/.claude/skills/`）——每台機器首次裝一次：`git clone <lumos-toolchain> ~/harness/lumos-toolchain && ~/harness/lumos-toolchain/install.sh`。專案技術棧 skill（如 vue / csharp）見文末〈架構參考 Skills〉。
<!-- LUMOS:GRAPH-DISCIPLINE:END -->
---
type: moc
status: doing
---
# lumos-toolchain 知識架構圖總索引

Lumos 工具鏈(`scripts/lumos` + skills + governance 自動化)自身的知識架構圖。節點現況以 code 為準,完整設計史/收斂史指回 `docs/design/`。狀態標記:無標=已實作;`[planned]`=設計收斂未落地;`[deferred]`=擱置;`[rejected]`=評估後不做(輕方案落地)。

> **慣例**:節點內嵌的 `scripts/lumos:行號`(或 `@行號`、`:行號`)是**近似導航參考**,code 重構後可能漂移——以 code 現況與函式名為準,行號僅供快速定位。

## 設計審計 loop(進實作前的把關)
- [[Systems/design-loop]] — canary-護的設計審計 loop;Claude 編排、lumos 出原語,連 2 輪 caught 才放行實作。
- [[Systems/canary-audit]] — test-the-tester:每輪偷植已知假錯驗審計員有沒有認真抓(防假陰性/放水)。
- [[Systems/loop-convergence-recording]] — `canary record --loop/--severity` + `loop status --need` 算收斂、可機械終止多輪。
- [[Systems/finding-refute]] — 辯方 refute:對 ≥major finding 派獨立 opus 強制 file:line 反證才降(防假陽性,對稱 canary)。
- [[Systems/judge-severity-gate]] — 讓 judge 覆蓋 severity 維度,堵「收斂門檻沒覆蓋處偷工」。
- [[Systems/cross-family-audit]] — 換模型家族複核(qwen3-max),解 opus 審 opus 的自我偏好偏心。
- [[Systems/judge-perturbation-stability]] `[rejected]` — 評審擾動穩定性;評估後改走輕量 confidence_report.py。

## doctor 合約 / 可逆性檢查
- [[Systems/check-t-sentinel]] — Check T:★INVARIANT★ 合約綁可執行測試 `[test:]`(+ stub 紅燈哨兵)。
- [[Systems/check-r-guard]] — Check R:不可逆動作(★IRREVERSIBLE★)動手前要有實質 `[rollback:]`/`[guard:]`。
- [[Systems/reversibility-governance-ledger]] — 可逆性綁定 + gov 治理事件帳(某節點被哪幾道閘攔過)。
- [[Systems/doctor-irreversible-hint]] — `[H]` 軟提醒:掃 diff 碰 prod/外部 API → 是否漏標 ★IRREVERSIBLE★。
- [[Systems/check-j-regen-guard]] — Check J:from-scratch 重建節點 provenance 分級(regen 蓋章+[src:]/[git:]/推測:/佚失: 標身分;拒發明無證據合約、假指針機械擋)。
- [[Systems/core-invariant-baseline]] `[deferred]` — 核心節點已知良好快照 + 可回退(pivot 為 content-baseline,擱置)。

## 自主治理 / loop engineering
- [[Systems/autonomous-iteration-loop]] — 日報 gap→brainstorm→design-loop→收斂備 pending 的無人看顧自主迭代。
- [[Systems/verification-rot-eval]] `[planned]` — 從架構圖史抽衝突測試集定期回測 L3 腐化偵測(設計收斂未落地)。

## 安全與權限
- [[Systems/nested-agent-permission-scope]] — 子 agent 權限收窄(maker≠checker 的審計員不繼承主對話權限)。

## 平台支援
- [[Systems/native-windows-support]] — 原生 Windows(get.ps1 / mklink / junction / hook 路徑正斜線化)。
- [[Systems/lumos-deinit]] — 專案層反安裝指令(對稱 `lumos init`);四重閘保護不可逆的 vault rmtree。

## 完整性 / 影響 / 漂移守衛
- [[Systems/guard-kill]] — 殺傷力驗證:宣告壞法→worktree 隔離→綁定測試必翻紅;survived=稻草人證據(合約鏈最後一哩)。
- [[Systems/cochange-guard]] — co-change 漏改守衛:git 歷史挖共改規則(ROSE 非對稱 confidence),pre-commit Gate CC 警告漏改夥伴(advisory)。

## 檢索與推薦
- [[Systems/retrieval-ranking]] — BM25F 排序+圖分融合推薦+impact 降噪(search 與 hook 面均已轉正——§6 七盞全綠;recommend 面 dormant)。

## CLI 核心原語
- [[Systems/lumos-cli-read]] — 讀/巡檢:doctor/context/contracts/search/links/backlinks/map/export/decisions/stale/recent/stats。
- [[Systems/lumos-cli-write]] — 寫:set/append/new/archive/decision-add/decision-supersede/self-audit;T1 寫後自驗 atomic。
- [[Systems/lumos-cli-lifecycle]] — install/uninstall/update/bootstrap/init/deinit;機器層 vs 專案層分工。

## 外部對照 / PRIOR-ART
- [[Systems/外部對照-code衍生wiki]] — langchain-ai/openwiki(11.6k★ code 衍生 wiki)反例世界解:站在 lumos 導覽層、賭注相反(code 衍生+可丟 vs 架構圖手寫+機械守);核心論點=重生保新鮮≠正確、無輸出 oracle(maker-only),反證 lumos「架構圖即真相/合約驗證層」的必要。

## 外部設計 / 計畫文件(架構圖外,但屬本工具鏈)
- `docs/design/` — 各功能設計稿(含 design-loop 收斂紀錄,18 份)。
- `docs/superpowers/plans/` — 實作計畫(TDD 任務分解)。
- `docs/methodology/` — 「架構圖即合約」方法論。
- `governance/reports/` — AI 治理日報(研究 → gap → 觸發上述功能的 provenance,各 Verification/Systems 節點內有溯源)。
---
type: project
status: doing
created: 2026-08-04
updated: 2026-08-04
related:
  - "[[Systems/design-loop]]"
  - "[[Systems/canary-audit]]"
  - "[[Systems/loop-convergence-recording]]"
  - "[[Systems/convergence-evidence-gate]]"
  - "[[Projects/canary注意力檢查失效]]"
  - "[[Projects/design-loop判準重定位]]"
  - "[[Projects/design-loop提效_計劃]]"
tags:
  - type/project
  - status/doing
summary: |-
  FLAG:DECISION
  KEY:★定位(使用者 2026-08-04 確認)★——design-loop=實作前的★便宜初篩網★,抓「十塊錢就能抓到的缺陷」(矛盾/未定義詞/缺失敗路徑)一輪放行;★正確性歸下游 TDD+E2E(真 oracle 在那裡)★;終極要能★無人自跑★——一道從不亮綠燈的閘放進自主 loop=每件事卡死等人,自動化是假的
  KEY:★全流程體檢結論(2026-08-04,十一站逐站查)★——真機械的只有 G3 hash 一個;gate 實測 ★1/38、panel 0/23 從未放行★(37/38 靠人裁/cap 出場);canary 判定 334 筆★無留痕不可稽核★(歷史 81.5% caught 率永遠查不出真假);S2 抽樣/cluster 帳/min-seats/tier 四個機制★蓋好沒人用★(同日四例=系統病:每個機制都在等一個記得用它的人,而那個人不存在)
  KEY:★重設計原則(一句話)★——閘只留可重算的;其餘全部降級成★強制留痕★的觀測;lumos 已知的值★預設而非選配★
  KEY:★canary 裁定:退出逐輪 gate,退到離線校準★——今天實測:r1 四個 missed 席交出整輪最有價值的發現(含打掉提案地基的那條;r1=[[Projects/design-loop判準重定位]] 的第一輪 panel),★間接證據(抓埋伏)在否決直接證據(經查證的 findings)★;canary 唯一有資訊量的場景=審查員回報 clean,而 184 筆帳裡 clean 只有 1 筆——守一個幾乎不發生的情況,代價是每輪植入+判定+誤殺真發現
  KEY:★取代 canary 的三件套★——①錨定檢查(機械):每條 finding 必須引用文件真實存在的原文,grep 可驗、零成本、不需植入不需人判;夢遊模型編的 finding 錨不到真文字 ②席間對照(觀測):四席各交 8 條、一席說全乾淨→那席可疑記帳;panel 本身就是注意力檢查 ③植假錯保留為★定期離線校準★(凍結語料上量「哪種配置抓得到什麼」),對齊 replay 校準構想
  KEY:★誠實天花板★——五席全 clean 且同門盲點:①②接不住→下游 TDD+E2E 接(定位本來就不保正確);錨定檢查驗得了「引了真文」驗不了「推論正確」→辯方 refute 接;處置帳 folded/accepted 仍是編排者自報→算術核對+留痕買摩擦,不買防竄改
  PRIOR-ART:①最小解在既有機制層——錨定檢查=把 G1 refcheck 的機械比對用到審查員產出上(自家已有的信任階梯「機械查>LLM判官」);處置帳=擴充既有 M2 cluster 帳非新造 ②世界解過(2026-08-04 網搜)——品管三件套(ACM 綜述:gold/互評/冗餘★並列★,gold 有應試缺陷「通過金標的工人照樣交低品質答案」且實務全是跨題累積統計判定,★單題一票否決無人採用★);citation grounding 文獻(CiteCheck 2026):★機械比對引文>讓 LLM 判官判可信度★;fault seeding 文獻定義=★評估檢測流程有效性的離線量測工具★(IBIR/FLAWS 原始論文全是 benchmark 用法,無一當逐輪放行條件);Prolific:>5min 研究失敗≥2 次才可拒 ③裁定=borrow-design(零依賴;真正無文獻背書的反而是現狀「單席單 canary 一票否決」)
  DEP:scripts/lumos _loop_status_panel / _panel_extra_checks / cmd_canary / cmd_loop_next｜skills/lumos-design-loop/SKILL.md + templates.md｜governance/canary-samples/
decisions:
  - content: 定位確認:design-loop=便宜初篩網(抓便宜缺陷一輪放行),正確性歸下游 TDD+E2E,終極要能無人自跑
    id: d1
    context: 全流程體檢發現 gate 從未放行(1/38)、每次靠人裁繞過;追問後使用者確認 d4 定位並補述:下游有 TDD 落地與 E2E 檢驗功能性,且治理大方向是無人看顧的自主 loop——從不亮綠燈的閘在自主 loop 裡=全部卡死等人
    why_chosen: 分層生產線裡每層用它有真 oracle 的判準:設計稿是散文沒有真裁判,在這層追求證明正確是緣木求魚;初篩網的價值在覆蓋率(每份稿都過得起)不在單次深度
    decided: 2026-08-04
    valid: true
  - content: 重設計原則:閘只留可重算的;其餘降強制留痕的觀測;lumos 已知的值預設而非選配
    id: d2
    context: 五個錨只有 G3 hash 真機械;canary 判定 334 筆零留痕不可稽核;S2/cluster/min-seats/tier 四機制蓋好沒人用——閘與觀測倒置:該觀測的做成硬閘,該硬的(留痕/兌現)反而選配
    why_chosen: 可重算=事後任何人能覆核,這是閘的最低資格;強制留痕讓觀測值未來可校準;預設化消滅「機制等一個記得用它的人」整類病。備選「全部收緊成硬閘」被否:會複製現狀(從不放行→人裁兜底→帳面假嚴謹)
    decided: 2026-08-04
    valid: true
  - content: canary 退出逐輪 gate,退到定期離線校準;逐輪改用錨定檢查(機械)+席間對照(觀測)
    id: d3
    context: 實測:r1 四個 missed 席交出整輪最有價值的發現(含打掉提案地基那條)——間接證據在否決直接證據;配對實驗 n=20 整體 caught 僅 10%,歷史 81.5% 不可稽核;canary 唯一有資訊量的場景(審查員報 clean)在 184 筆帳裡只出現 1 次
    why_chosen: 品管三件套文獻中 gold/互評/冗餘並列且 gold 有應試缺陷、實務全是累積統計判定,單題一票否決無人採用;citation grounding 實證機械比對引文>LLM 判官;fault seeding 文獻定義=離線量測工具(IBIR/FLAWS 皆 benchmark 用法)。查貨不查人:經查證的 findings 是「他讀了」的直接證據。備選 A(只改抑噪措辭)被否:p≈0.47 未證實其為主因且有反例;備選 B(canary 明示分離)被否:covert 變 overt 違反 attention-check 方法學
    decided: 2026-08-04
    valid: true
---
# design-loop 重設計（計劃）

> **狀態**：2026-08-04 立案。吸收 [[Projects/design-loop判準重定位]]（該案不再獨立推進）與
> [[Projects/canary注意力檢查失效]]（實驗與追查結論全數併入本案）。**尚未進實作。**

## 一、定位（使用者確認，本案一切設計以此為準）

> **design-loop 是實作前的一道便宜初篩網，不是正確性的法院。**

- 抓「十塊錢就能抓到的缺陷」：自相矛盾、詞沒定義、失敗路徑沒想、明顯的洞。**抓完放行，不糾纏。**
- **正確性歸下游**：TDD 落地（測試是真 oracle）＋ E2E（真跑是真 oracle）。設計稿是散文，散文沒有真裁判——在這層追求「證明沒問題」是緣木求魚（**[[Systems/design-loop]] 的決策 d4**——非本文件編號，本文件只有 d1–d3；2026-07-18 裁、2026-08-04 再確認）。
- **終極要能無人自跑**（loop engineering 大方向）：一道從不亮綠燈的閘，在有人時靠人工繞過；放進自主 loop 就是全部卡死等人——★自動化是假的★。
- 省輪數不是摳門：**初篩網的價值在覆蓋率**（每份稿都過得起），不在單次深度。

## 二、全流程體檢（2026-08-04，問題盤點）

十一站逐站查的完整記錄散在 [[Projects/design-loop判準重定位]] 與 [[Projects/canary注意力檢查失效]]，此處只留判決表：

| 站 | 機制 | 判決 |
|---|---|---|
| 1 進場分級 | tier | 講出來的沒驗；fallback 掉最鬆檔 legacy=cap 6（見 [[Issues/loop-next吐不可宣告的tier]]，死路已修） |
| 2 真相入口 | 計劃節點＋G3 hash | ✅ **真機械，留** |
| 3 pre-flight | 清單掃描 | 有效，但掃的類別與 canary 同組（三方互打） |
| 4 難度探針 | ±20 行片段 | 規格壞（交叉引用全變「未定義」，無鑑別力）——改餵全文 |
| 5 植 canary | 每席一個 | 單一 check 訊號極弱（實測便宜模型 2/20）；文獻：通過一個不預測通過另一個 |
| 6 派工 panel | 多席多鏡頭＋抑噪 | 找洞能力是真的；抑噪×canary 衝突假說未證實（p≈0.47）；派工卡死無監控（跨家族 Codex CLI 席曾 61 分鐘空跑無人察覺） |
| 7 判讀 caught/missed | 編排者自判 | ★**全流程最壞**★：判定者=植入者、334 筆零留痕、歷史 81.5% 不可稽核；missed 一票否決誤殺真發現（r1 四個 missed 席交出整輪最有價值的東西） |
| 8 辯方 refute | 外家反證 | 可用；留痕不足；是處置帳分母的操縱點 |
| 9 折入＋fold-check | 鏡像段機械查 | 守衛真；但折入本身在生產下一輪缺陷（歷史第三輪常見的「補丁沒同步」型 findings 即此） |
| 10 gate | 五條合取 | **1/38、panel 0/23 從未放行**；五個錨只有 G3 是真的 |
| 11 收斂後 | golden/接受理由 | 因第 10 站不亮，歷史上全靠人裁進入 |

**橫向系統病**：S2 抽樣（=canary second 第二判者抽樣分權，[[Systems/canary-audit]]；落地至今 0 次）、cluster 帳（35 個 panel loop 僅 1 個採用）、min-seats（要記得傳旗標才驗）、tier（要記得標才記帳）——
★機制蓋好了，沒有任何東西在該用的時候提起它★（同日四例）。

## 三、重設計原則

> **① 閘只留可重算的。② 其餘全部降級成「強制留痕」的觀測。③ lumos 已知的值預設帶上，不再選配。**

### 新架構：閘／觀測分層

| 層 | 內容 | 為什麼 |
|---|---|---|
| **閘**（過不了就不放行） | G3 hash 鏈；處置帳算術（`folded+accepted==findings`＋blocker 不得 accepted）；**留痕存在性**（record 不附審查員報告→拒收）；**錨定檢查**（finding 引文 grep 不到→該條不採信） | 每一條都機械可重算、事後可稽核 |
| **觀測**（記帳亮燈，不擋） | canary caught/missed（若該輪有跑離線校準型植入）；severity 分佈；capture-recapture；席間對照（clean 席 vs 產出席）；抑噪合規 | 自報或統計性訊號，當校準輸入，不當放行條件 |
| **預設**（不再靠人記得） | tier 定錨、min-seats、cluster/處置帳模式——`loop next` 已算出的值自動進 record/gate | 消滅「機制蓋好沒人用」的整類病 |

### canary 的去向（本案核心裁定）

**退出逐輪 gate，退到定期離線校準。** 取代它的三件套：

1. **錨定檢查（機械）**——每條 finding 必須引用文件裡真實存在的原文；grep 可驗。
   「他讀了沒」的證明從「踩沒踩到我的陷阱」換成「他的話對不對得上原文」。
   ★這是把自家信任階梯（真跑＞機械查＞LLM 判官＞自報）用到審查員產出上——與 G1 refcheck（spec→repo 引用的機械核對）同型。★
2. **席間對照（觀測）**——panel 冗餘本身就是注意力檢查；全場獨我 clean 的席標記記帳。
3. **離線校準（canary 的文獻本職）**——定期在凍結語料植入已知缺陷，量「哪種模型×prompt 配置抓得到什麼」，
   結果用來選配置（密集 spec 直接上 opus 之類），不進任何單輪判定。對齊既有 replay 校準構想。

**code-loop 不跟進**：它定位「保正確」、canary missed 率 9.3% 未見異常、其 canary 型別（off-by-one 等）
有失敗場景不與抑噪互打。**先不動，觀察。**（兩份 skill 的差異要明文註記，防誤同步。）

## 四、誠實天花板（先寫死）

1. **五席全 clean 且同門盲點**——錨定與席間對照都接不住。下游 TDD＋E2E 接；本層定位本來就不保正確。
2. **錨定檢查驗得了「引了真文」，驗不了「推論正確」**——引真文講錯話仍過錨定；靠辯方 refute 接。
3. **處置帳的 folded/accepted 仍是編排者自報**——算術核對＋留痕買的是摩擦與可稽核，不是防竄改。
4. **離線校準的結論會過期**——模型換代後要重跑；校準頻率是新的維護負擔。

## 五、實務隱患

- **錨定檢查會逼審查員多引原文**——報告變長；且「引文存在」的機械比對要處理改寫／斷行（子字串比對的正規化規則要釘死，否則變成新的假綠來源）。
- **「留痕存在性」當閘**＝record 要帶報告檔路徑或內容——canary-log 是 JSONL 單行慣例，塞全文會爆；傾向存檔於 `governance/canary-samples/`（既有位置）、record 帶路徑＋sha256，**寫側驗檔案存在**。
- **舊帳相容**：新閘對舊 loop 不回溯（定錨模式，同 M2 前例）。
- **本案自己怎麼審**（bootstrapping）：舊閘已被本案證明失效，用它審本案＝用壞尺量新尺。
  **提議**：pre-flight＋panel（含跨家族）＋★錨定紀律先行試用★＋**人裁當最終閘**，
  並在留痕明記「舊機械閘知情繞過，理由＝其為本案改造對象」。★這是例外不是先例。★

## 六、待決（人裁）

1. 第五節的「本案自己怎麼審」提議，可不可以。
2. 實作拆包順序（傾向：①record 強制留痕→②錨定檢查→③gate 分層改造→④skill 重寫**（含「code-loop 不跟進」的差異明文註記，防誤同步）**→⑤離線校準腳本）。
3. [[Projects/design-loop判準重定位]] 的 d1（blocker 不得 accepted）與 d2（模式旗標分流）**沿用**進本案；其餘內容以本案為準。

---

## 審計修正紀錄

### r1 · pre-flight（機械清單，全文餵便宜模型；不算 loop findings）

8 條全是「只用不定義／缺指針」：`d4` 懸空（★與上一份 spec 同型，第二次犯★→ 補「[[Systems/design-loop]] 的 d4、非本文件編號」）；`r1`/`r3 型`/`S2`/`Codex`/`tier 檔級`/`G1 refcheck`/`35 選 1` 各補一句就地解釋或指針；「skill 差異註記」明確掛進拆包 ④。數字一致性／章節引用／decisions 對映／範圍刀＝全過。

codex
已讀到核心提案；下一步補完文件尾段，並用 lumos 查 design-loop/canary 合約後核真碼與帳本。會特別追「可重算」是否真的能由現有資料重算，以及拆包是否會製造中間失效狀態。
  6.477  Issues/design-loop折入漂移_機械守衛.md  [design-loop,design,loop]
    12 [fm]: - "[[design-loop折入守衛_計劃]]"
    13 [fm]: - "[[design-loop折入守衛_實作計畫]]"
    16 [KEY]: KEY:lumos-design-loop 機制缺陷——每輪把 finding 折進 spec body 後,summary/schema 範例/審計紀錄/天花板無機械綁定要同步 …
    18 [KEY]: KEY:修法定案(見 [[design-loop折入守衛_計劃]]+[[design-loop折入守衛_實作計畫]]):**初版 lint ①§-ref+②summary→body…
    19 [DECISION]: DECISION:先記為 lumos 工具鏈改進 Issue(非某 spec 問題);真要做需自己走 brainstorm→design-loop(注意別遞歸)。與知識同步散落漂移…
    20 [KEY]: KEY:[2026-07-18]第四場域=權威派工模板漂移——templates.md 辯方段直到今日仍寫「opus;對每條≥major各派一個」:M1 路由制(07-16)與 S…
    21 [KEY]: KEY:[2026-07-17]同病新案例=架構圖節點自身也漂——[[design-loop]] M1 落地只在 summary 頂加 KEY 增量行,FLOW 主幹+辯方 KEY …
    23 [DEP]: DEP:[[design-loop]]
    … 還有 4 處
  6.442  Projects/design-loop輕量檔_計劃.md  [design-loop,design,loop]
    10 [fm]: - "[[Systems/design-loop]]"
    13 [fm]: - "[[Projects/design-loop提效_計劃]]"
    16 [KEY]: KEY:問題=design-loop 粒度只有兩檔(trivial 完全跳過｜standard 完整 panel),中間是空的——小而不 trivial 的 spec(小 flag…
    17 [KEY]: KEY:方向裁定——只解「小任務被過度審」(降成本方向),不碰「大任務多跑」(那半撞 cap=3 效率前緣/RHB 縱深非解藥,已由 [[Projects/design-loop提…
    18 [KEY]: KEY:d5 經濟學合規——輕量檔=便宜 spec 便宜審=缺陷分層定價,降成本非精確度軍備競賽,教義站這邊(見 [[Systems/design-loop]] d5);d4 定位…
    21 [KEY]: KEY:軟提示(往下,advisory,唯一新東西)——三訊號全沒響+體積遠低天花板→design-loop 進場跳一句「這條像 light,要用嗎」maker 拍板;維持 adv…
    22 [KEY]: KEY:light 跑什麼(壓縮 loop)——pre-flight cascade(複用 M1 排乾清單型)+1 輪·1 通才審計員·canary 護·K=1(踩 [[Proje…
    24 [KEY]: KEY:★meta 自我約束★——加一檔+ratchet 延伸動到 loop status gate 語意=self-governance 風險類=high;按 risk-tier…
    … 還有 9 處
  6.376  Projects/design-loop折入守衛_計劃.md  [design-loop,design,loop]
    10 [fm]: - "[[design-loop折入漂移_機械守衛]]"
    11 [fm]: - "[[design-loop]]"
    14 [KEY]: KEY:解 design-loop 折入漂移(每輪把 finding 折進 body 後、鏡像段 summary/schema/審計紀錄/天花板忘了同步→下輪審計員耗 findin…
    19 [DECISION]: DECISION:兩交付=lumos fold-check 指令(顧問級,有flag rc1)+ design-loop skill step 7 加強制子步(源在 lumos-t…
    20 [DECISION]: DECISION:閘是紀律非防篡改(同 design-loop 本身,lumos 擋不住不跑就 commit);跨段語意矛盾清單逼看不替判;啟發式有假陽假陰
    21 [DEP]: DEP:[[design-loop]]
    22 [TEST]: TEST:已實作(branch feat/fold-check,528 passed;2 design-loop 輪+TDD 5 task+opus 終審);VERIFY:[[20…
    31 [fm]: - "[[2026-07-05_design-loop折入守衛]]"
    … 還有 9 處
  6.359  Systems/design-loop.md  [design-loop,design,loop]
    11 [fm]: - "[[Verification/2026-06-19_design-loop]]"
    17 [KEY]: KEY:★定位★[2026-07-18 使用者裁定,見 decisions d4]——design-loop=抬 spec 質量,非保 spec 正確:一輪 panel 抓便宜的(…
    20 [KEY]: KEY:[2026-07-16]提效 M1 落地(見[[Projects/design-loop提效_計劃]])——pre-flight 排乾(panel 前便宜 agent 掃清…
    22 [KEY]: KEY:[2026-07-21]light 輕量檔 M0 落地(見[[Projects/design-loop輕量檔_計劃]])——補 trivial|standard 間缺檔:小…
    33 [KEY]: KEY:派工模板權威=skills/lumos-design-loop/templates.md(6角色 dispatch prompt+編排者判讀規則,Landmark 實戰抽取…
    35 [DEP]: DEP:lumos canary record --loop/--severity｜lumos loop status --need(Component A 原語)｜skills/…
    36 [TEST]: TEST:Component A 原語有 test_lumos.py 覆蓋;B 是 skill 非 code,以 design-loop 自跑收斂為驗證
    37 [VERIFY]: VERIFY:[[Verification/2026-06-19_design-loop]]
    … 還有 7 處
  6.358  Systems/judge-perturbation-stability.md  [design-loop,design,loop]
    11 [FLOW]: FLOW:gap(單一 judge 不可靠)→設計擾動穩定度測試(關鍵輪換序審兩次、翻盤即不採信)→design-loop r1 折機械 reorder→r2 揭機制堵不住自證(只…
    12 [KEY]: KEY:評估後放棄(2026-06-20)——非未完成,是 design-loop 揭示「用同一 judge 審它自己穩定性逃不出『誰控制擾動』的自證悖論」後的主動不做判斷
    17 [VERIFY]: VERIFY:無(放棄決定無功能可驗,design-loop 收斂史見設計稿)
    21 [fm:context]: context: design-loop r1→r2 每次折修只把自證悖論換個藏身處(agent 產擾動→機械 reorder,但 reorder 由誰執行/種子誰選仍可被被審者操…
    27 [fm:context]: context: design-loop r1 major F3 揪出原方案讓被審者自填擾動=judge-severity-gate 才斷開的「被審者自填」反模式在新位置復發
    34 [body]: > **狀態:評估後放棄(2026-06-20)。** 這是一份「決定不做」的節點 —— design-loop 揭示方案堵不住自證悖論後的主動判斷,非未完成的功能。
    37 [body]: 為 autonomous design-loop 的 **judge 抗擾動性** 設計的方案:在要判 clean/minor 的**收斂關鍵輪**,把同一份輸入換個呈現再讓**同…
    42 [body]: design-loop 兩輪揭示方案的根本兩難:
    … 還有 2 處
  6.345  Projects/design-loop折入守衛_實作計畫.md  [design-loop,design,loop]
    10 [fm]: - "[[design-loop折入守衛_計劃]]"
    12 [fm]: - "[[design-loop折入守衛_計劃]]"
    15 [KEY]: KEY:「design-loop 折入守衛」TDD 實作計畫(設計見 [[design-loop折入守衛_計劃]]);兩交付=lumos fold-check <path> 指令(…
    19 [DEP]: DEP:[[design-loop折入守衛_計劃]]
    23 [body]: # design-loop 折入守衛 Implementation Plan
    26 [body]: > **設計權威**:[[design-loop折入守衛_計劃]](§2 fold-check 演算法 / §3 skill step7 / §4 天花板 / §5 測試)。本計畫…
    28 [body]: **Goal:** 造 `lumos fold-check <path>` + 改 `lumos-design-loop` SKILL.md step7,把 design-loop…
    158 [body]: 實作完成寫 `Verification/2026-..._design-loop折入守衛.md`,`plan_refs: "[[design-loop折入守衛_計劃]]"` 回指;…
  6.326  Projects/pitfalls網搜補漏_計劃.md  [design-loop,design,loop]
    18 [KEY]: KEY:形態=on-demand lumos-* skill(源 lumos-toolchain repo symlink,像 lumos-design-loop);Claude …
    22 [DECISION]: DECISION:跳 design-loop——純散文 skill 無演算法/code,design-loop 對散文空轉(見記憶 design-loop-completeness…
    33 [body]: 一個 **on-demand lumos-* skill**(源在 lumos-toolchain repo `skills/`、symlink 進 `~/.claude/skil…
    56 [body]: ## §5 驗收(跳 design-loop 的替代)
    57 [body]: - **跳 design-loop 理由**:純散文 skill、無演算法/code,design-loop canary 對散文空轉(見記憶 design-loop-comple…
  6.313  Systems/judge-severity-gate.md  [design-loop,design,loop]
    13 [FLOW]: FLOW:design-loop每輪 sub-step3 派auditor→sub-step4 派獨立judge(明文傳入auditor完整報告+canary token)回 ca…
    17 [KEY]: KEY:只改 governance/autonomous_loop/orchestrator-prompt.md 的 judge prompt 與數據流;scripts/lumos…
    20 [TEST]: TEST:功能改動在 prompt(非 Python),以 design-loop 自跑收斂為驗證(人解張力後重跑 R1 major→R2 major→R3 clean→R4 cl…
    37 [fm:context]: context: design-loop 重跑 R2-F-R2-2 審出:一評「打不打中」就把主觀性、進而模糊性保守請回來、卡收斂——根本取捨無兩全(主觀判卡收斂 / 客觀數可敷衍…
    44 [body]: 讓 autonomous design-loop 收斂條件 `good(r) = caught AND severity∈{clean,minor}`(`scripts/lumos…
    46 [body]: > 源起:日報 2026-06-20 gap「收斂門檻只覆蓋部分維度,定理證明優化者必在沒覆蓋處偷工」(借「有限評估均衡定理」)——明指 spec 自己已抓到『severity 自…
    52 [body]: 唯一改動點是 `governance/autonomous_loop/orchestrator-prompt.md` 步驟 2 design-loop 的 sub-steps:
    72 [body]: - 設計稿:`docs/design/2026-06-20-judge-severity-gate.md`(autonomous-loop 自動產出,人解核心張力後重跑 desig…
    … 還有 1 處
  6.270  Issues/code-loop守衛main-direct盲區.md  [design-loop,design,loop]
    19 [KEY]: KEY:候選修法(未裁)——①pre-push 對 main-direct push 改用「本次 push 的 range(remote..HEAD)」算 tier ②家規化:ga…
    21 [KEY]: KEY:排程[2026-07-21 使用者裁「排」]——①✅M1包 事後 code-loop 終審**已完成**(三輪+Codex NO-VETO+pass 留痕,補審抓 15 洞…
    29 [body]: 修法候選見 summary；動 hook 屬改守衛，須過 design-loop。
  6.261  Verification/2026-07-05_design-loop折入守衛.md  [design-loop,design,loop]
    7 [fm]: - "[[design-loop折入守衛_計劃]]"
    9 [fm]: - "[[design-loop折入守衛_計劃]]"
    10 [fm]: - "[[design-loop折入漂移_機械守衛]]"
    15 [TEST]: TEST:lumos fold-check <path> + design-loop SKILL.md step7 實作完成,528 passed 0 failed(branch …
    19 [body]: # 2026-07-05 design-loop 折入守衛 驗證
    21 [body]: `lumos fold-check` + `lumos-design-loop` SKILL.md step7 實作完成並通過 opus 終審。落地 [[design-loop折入…
    38 [body]: 用建好的 `fold-check` 檢查它自己的設計節點:2 value-drift(皆自指範例:`fold-check <node>`/`2..depth` 是本 spec 討論…
  6.260  Projects/canary注意力檢查失效.md  [design-loop,design,loop]
    8 [fm]: - "[[Systems/design-loop]]"
    9 [fm]: - "[[Projects/design-loop判準重定位]]"
    12 [fm]: - "[[Projects/design-loop重設計]]"
    18 [KEY]: KEY:★問題:design-loop 的 canary 與它自己的派工模板互斥★——`templates.md:83` 官方抑噪紀律逐字寫「低嚴重度疑慮,給不出具體失敗場景就不要…
    20 [KEY]: KEY:★帳面證據(n=334)★——design-loop missed 率 ★18.5%★(42/227) vs code-loop ★9.3%★(10/107),兩倍。兩份 …
    21 [KEY]: KEY:★誠實界線:這是相關不是因果★——兩者材料不同(散文 spec vs code diff)、只有 design-loop 有 pre-flight 掃同類、整體 promp…
    22 [KEY]: KEY:★2026-08-04 現場實例★——design-loop判準重定位 r1(tier=high 5席)1 caught/4 missed;唯一抓到的那席是★違反抑噪指示★…
    27 [DEP]: DEP:skills/lumos-design-loop/templates.md §1｜skills/lumos-design-loop/SKILL.md 步驟 2/2.7/3｜…
    … 還有 15 處
  6.258  Projects/全盤外審2026-07_調研.md  [design-loop,design,loop]
    10 [fm]: - "[[Systems/design-loop]]"
    13 [fm]: - "[[Projects/design-loop輕量檔_計劃]]"
    18 [KEY]: KEY:★最痛★真相入口兩道裂縫(blocker,已驗證)——①spec 雙真相:CLAUDE.md 規定計劃寫 Projects 節點,design-loop skill 卻仍以…
    23 [DECISION]: DECISION:[2026-07-21]使用者裁「逐條進行」,划算排序:①真相入口二合一(1a skill 散文先行+1b lumos show 走 light 首戰)→②文檔漂…
    25 [DEP]: DEP:[[Systems/design-loop]]｜[[Systems/convergence-evidence-gate]]｜[[Projects/loop數據收集_計劃]]
    68 [body]: - 順位3：待開 gate-code M1 包 spec（loop next＋light K=1 謂詞＋spec hash＋成本欄位），過完整 design-loop `--nee…
  6.257  Projects/design-loop重設計.md  [design-loop,design,loop]
    7 [fm]: - "[[Systems/design-loop]]"
    12 [fm]: - "[[Projects/design-loop判準重定位]]"
    13 [fm]: - "[[Projects/design-loop提效_計劃]]"
    19 [KEY]: KEY:★定位(使用者 2026-08-04 確認)★——design-loop=實作前的★便宜初篩網★,抓「十塊錢就能抓到的缺陷」(矛盾/未定義詞/缺失敗路徑)一輪放行;★正確性…
    22 [KEY]: KEY:★canary 裁定:退出逐輪 gate,退到離線校準★——今天實測:r1 四個 missed 席交出整輪最有價值的發現(含打掉提案地基的那條;r1=[[Projects/…
    26 [DEP]: DEP:scripts/lumos _loop_status_panel / _panel_extra_checks / cmd_canary / cmd_loop_next｜sk…
    28 [fm]: - content: 定位確認:design-loop=便宜初篩網(抓便宜缺陷一輪放行),正確性歸下游 TDD+E2E,終極要能無人自跑
    47 [body]: # design-loop 重設計（計劃）
    … 還有 6 處
  6.255  Systems/cross-family-audit.md  [design-loop,design,loop]
    13 [FLOW]: FLOW:design-loop §2 步驟8 達標(連2輪caught+sev∈{clean,minor})→§2.5 放行前複核一次：opus 取材(grep spec 引用檔…
    14 [KEY]: KEY:autonomous loop design-loop 收斂判定後、放行前多一道 qwen3-max 跨家族複核，補 opus 同門盲點；不取代每輪 judge-sever…
    26 [fm:context]: context: design-loop R4 排掉 canary 後 3 個 major(報告標題層級錯亂 / $SCRATCH 跨程序歸因 / build_report 第4參…
    32 [fm:context]: context: design-loop R5 F6：API 不可用時不可卡死 loop，但也不能把「複核被旁路」謊報成「通過」
    38 [fm:context]: context: design-loop R5 F2：disputed 不伴 converged:false 就走不進 wrapper 未收斂分支(L80-85)；硬編碼「撞 ca…
    45 [body]: autonomous loop 的 design-loop 在判定收斂、**真正放行前**多一道 **qwen3-max 跨家族複核**，補 opus 同門盲點。qwen 提出 m…
    47 [body]: 源起:日報 2026-06-20 inspiration「design-loop 每輪只靠單一 judge、外部證據顯示沒有單一評審穩定可靠 → 借 RAND JRH『換模型家族＋…
    50 [body]: - **放行前的額外關卡,不取代既有 judge**:每輪 severity 仍歸 judge-severity-gate 的獨立 opus judge;qwen 只在 desig…
    … 還有 3 處
  6.238  Projects/先問世界_存量掃描裁定.md  [design-loop,design,loop]
    16 [KEY]: KEY:最大收穫=suspect 語意(兩層合一設計):Doorstop 邊級(連結攜帶目標 summary 內容指紋,不符=suspect,明確 clear 才解除)+ Swim…
    23 [TEST]: TEST:批次1(純文字5條)已落地 2026-07-07——抑噪紀律+刻意不借findings硬上限(防污染G2)/算子速查/timeout+Survived-NoCoverag…
    35 [body]: | `[NEEDS CLARIFICATION: 問題]` 標記慣例:計劃節點內未解 → design-loop gate 視同 blocker | spec-kit | 慣例 +…
    49 [body]: | 收斂即凍結:converged spec 快照 + 辯方裁決後存活 findings → governance/golden/(規劃路徑,批次2待做未建) | Giskard …
    53 [body]: ### 中(1 條,唯一需正式 design-loop)
    55 [body]: - **邊級(Doorstop)**:Verification 寫入/重驗時記「被驗 Systems 的 summary block sha8」進 governance/link-…
    57 [body]: - Swimm 證明**不用 AST、純 diff+內容比對堪用**——正對零依賴體質。動 anchor/Check P 合約邊界 → 過 design-loop。
  6.198  Projects/code-loop必用守衛_計劃.md  [design-loop,design,loop]
    21 [DECISION]: DECISION:直接 writing-plans+TDD(hook+gate glue+一條 staleness 規則,無深演算法,design-loop 對 glue 空轉)
    22 [KEY]: KEY:誠實天花板=非 oracle——關掉「忘了」(Stop push)+「隨手漏」(pre-push 擋),關不掉「刻意繞+不誠實」;同 design-loop/impact「…
    58 [body]: - **非 oracle**:Stop 注入可被 Claude 無視;pre-push 可 --no-verify。**能關的**:「忘了看」(Stop push 到眼前)、「隨手…
    69 [body]: Verification `plan_refs` 回指本節點;本節點 TEST/status;更新 lumos-project-notes/CLAUDE.md 使用指南(Stop …
  6.191  Projects/GPT外部評審吸收_計劃.md  [design-loop,design,loop]
    10 [fm]: - "[[Systems/design-loop]]"
    15 [KEY]: KEY:吸收④——①同一變更同碰{業務碼,測試,hook/CI/審查規則}→tier 自動升 high(改考卷升險;待辦,動 gate code 須過 design-loop)②收…
    18 [DECISION]: DECISION:[2026-07-17]吸收走最小動作:散文紀律當場落(trivial 註明)、gate code 改動留 design-loop;拒收項記理由防重提(valid…
    41 [body]: 1. **改考卷自動升險**(待辦,本計劃主交付):同一變更(commit 或 branch diff)同時觸碰 {業務代碼} ∧ {測試/hook/CI 設定/審查規則檔} → …
    42 [body]: 2. **未修 findings 逐條接受理由**(✅ 2026-07-17 已落):design-loop / code-loop 兩份 SKILL.md 收斂節各加一句——凍結…
    43 [body]: 3. **TDD 例外明文化**(✅ 2026-07-17 已落 CLAUDE.md):已知行為→測試先行;未知行為(UI 探索/SDK 試接/效能調查/PoC)→最小實驗先行,結…
    54 [body]: - [ ] 吸收① 走 brainstorm→design-loop→TDD(tier 組合升險規則)
  6.170  Systems/autonomous-iteration-loop.md  [design-loop,design,loop]
    13 [FLOW]: FLOW:cron 10:10 → autonomous-loop.sh:驗當日日報存在(真模式無報即跳;dry-run fallback 最近一份)→ gap_select(日報…
    20 [KEY]: KEY:★抽掉人之前必辦清單(觸發條件=迴圈能不經人放行寫架構圖/開 PR 那天,今天人在放行點故全部不建)★——①提案者≠寫入者結構分離(Mnemosyne arXiv 2607.…
    40 [fm:context]: context: design-loop R3 揪出「severity 自報 = 收斂門檻自填」是全自動判收斂最弱環——被審者自填收斂了沒;此缺口本身就是 loop 上線後自己選中…
    70 [body]: 日報(9:30)→ 抽當日最高價值 gap → 自動 brainstorm 成 spec → 跑 design-loop 審到收斂 → 跨家族複核 → 把「收斂 spec + 可信…
    81 [body]: - `autonomous_loop/orchestrator-prompt.md` — `claude -p` orchestrator 的 prompt 模板(brainsto…
    85 [body]: - **CONVERGED** = `lumos loop status <topic> --need 2` exit 0 = **連 2 輪 canary caught 且 se…
    89 [body]: ## design-loop 對 skill 預設的覆寫(autonomous 版)
    106 [body]: - 設計稿:`docs/design/2026-06-20-autonomous-iteration-loop.md`(canary-護 design-loop 5 輪、K=2 收…
  6.166  Verification/2026-07-16_dloop提效M2_cluster帳.md  [design-loop,design,loop]
    7 [fm]: - "[[Projects/design-loop提效_計劃]]"
    10 [fm]: - "[[Systems/design-loop]]"
    18 [KEY]: KEY:design-loop 3 輪 22 條 findings 全折的 spec v4 逐格實作;人裁實質收斂條件=實作後必過 tier=high full code-loop…
    20 [body]: # 2026-07-16 design-loop 提效 M2:risk-cluster 三態帳落地驗證
    22 [body]: [[Projects/design-loop提效_計劃]] M2 的實作驗證。design-loop 3 輪 panel 達 cap、人裁實質收斂(golden: `governa…
  6.161  Systems/finding-refute.md  [design-loop,design,loop]
    19 [DEP]: DEP:skills/lumos-design-loop/SKILL.md 步驟4.5｜governance/autonomous_loop/orchestrator-prompt…
    20 [TEST]: TEST:無單元測(prompt 紀律);spec 品質以 design-loop 自走驗:3 輪自動收斂、canary 3/3 全中;辯方降級效力(假 major 當輪被駁)本輪…
    25 [fm:context]: context: design-loop 全是檢察官(auditor 找洞)、缺辯方;canary 只驗審計員有沒有認真讀(防漏抓),抓不到「認真讀了但判錯」(誤抓)。2026-0…
    44 [body]: design-loop 審計 loop 的**辯方 refute 階段**(step 4.5)—— 檢察官(auditor)/辯方雙向對抗的「辯方」側,防 auditor「認真讀了…
    46 [body]: > 源起:日報 2026-06-23 inspiration「借 REFLECT『評審最弱在核對證據』:能用死板比對(grep/diff)的就別交給 AI 判,只把 grep 查不…
    67 [body]: - **無單元測**:prompt 紀律(同 cross-family/judge-severity-gate 的 prompt 改),無代碼可單元測;驗證靠 design-loo…
    70 [body]: - 設計稿:`docs/design/2026-06-24-finding-refute.md`(design-loop 3 輪自動收斂、canary 3/3 全中)。
  6.151  Systems/convergence-evidence-gate.md  [design-loop,design,loop]
    15 [KEY]: KEY:★收斂 K 值依模式而異,而 skill 曾在四處講錯或漏標(2026-08-03 修)★——★循序模式 K=2★(`--need 2`,code:`all(good(r)…
    16 [KEY]: KEY:★panel 是風險最高的路徑(tier=high 專用),判準卻最鬆(K=1)——這個取捨目前★未經檢驗★★。外部案例研究 arXiv 2605.12280 §3.5 明…
    37 [fm:context]: context: design-loop R1 辯方對此 major 反駁失敗、維持原判,導致當輪拆錨重構(gate 從三錨收斂為兩錨)
    50 [body]: design-loop 收斂判準升級:**輪次算術 → 機械證據錨 + 發現枯竭**。四組件:`canary record --findings`(記錄面)、`loop statu…
    61 [body]: - 設計稿:`docs/design/2026-07-03-convergence-evidence-gate.md`(design-loop 4 輪、canary 4/4、R1 …
  6.114  Projects/pitfalls-lint-integration_計劃.md  [design-loop,design,loop]
    12 [FLOW]: FLOW:brainstorm 收斂(2026-07-04)→ 四塊有序落地(①lint adapter+SARIF → ②每日 linter 版本偵測 → ③網搜補漏 → ④事故…
    23 [fm:context]: context: 使用者要「全做完」;但四塊是獨立子系統,一個 spec 吞下 design-loop 審不動、實作 subagent 也吞不下
    45 [body]: > **狀態(2026-07-04)**:**已實作(subagent-driven 5 task)**。spec design-approved(KDS tracer 坐實六大承…
    50 [body]: > **狀態(2026-07-04)**:spec `docs/design/2026-07-04-lint-version-watch.md`。design-loop 6 輪 c…
    54 [body]: > **狀態(2026-07-04)**:spec `docs/design/2026-07-04-compose-metrics-adapter.md`。**KDS 真機驅動**…
  6.096  Verification/2026-07-09_loop三輪壓縮.md  [design-loop,design,loop]
    11 [fm]: - "[[design-loop]]"
    18 [VERIFY]: VERIFY:T1 capture-recapture 殘餘估計(Chao1 偏差修正純函式)/ T2 canary record --round 留痕欄 / T3 loop st…
    25 [body]: 把 canary-護對抗審計 loop(design-loop/code-loop)從「6 輪同族循序」壓成「平行多樣 panel」,收斂信號改建在 framing 汙染不到的結構…
    36 [body]: 5. **T5 prose**:design-loop SKILL 平行 panel 段、templates.md §7 派工模板、Systems/design-loop + co…
    46 [body]: - **orchestrator panel 化延後**:自主 loop 暫停中(2026-07-07),panel 化其 orchestrator-prompt 低優先。**co…
    50 [body]: 緣起:使用者質疑「code-loop 該全盤沿用 design-loop 慣例嗎?code review 不該不一樣?」→ 交叉查文獻(AutoSafeCoder / Multi-…
  6.093  Verification/2026-06-20_judge-severity-gate.md  [design-loop,design,loop]
    8 [fm]: - autonomous design-loop 經 orchestrator-prompt.md sub-step4/4.5/5/6 執行,judge 為獨立 spawn 的 o…
    11 [fm]: - orchestrator-prompt.md 步驟 2 design-loop 的 sub-step 結構或 judge prompt 改動
    18 [body]: 功能改動位於 prompt(`governance/autonomous_loop/orchestrator-prompt.md`),非 Python code,故無 `test_…
    20 [body]: ## design-loop 收斂結果
    22 [body]: - **人工解核心張力後重跑**:刪「純模糊性保守取高」、改靠評定者獨立 + judge 據實評 + 客觀二值保守。重跑 design-loop:
    35 [body]: PASS — design-loop 4 輪收斂(R3+R4 clean),功能已落地進 prompt 真源並經 C4 同步。
  6.059  Systems/nested-agent-permission-scope.md  [design-loop,design,loop]
    11 [fm]: - "[[Verification/2026-06-23_nested-agent-permission-scope_design-loop收斂]]"
    20 [TEST]: TEST:無單元測試(prompt 層,smoke test 即可);spec 經 design-loop 5 輪收斂(R2 實證 Write 被拒)
    21 [VERIFY]: VERIFY:[[Verification/2026-06-23_nested-agent-permission-scope_design-loop收斂]]
    31 [fm:context]: context: design-loop R1-B1 揪出 $SCRATCH 在 autonomous-loop.sh 從不 export(orchestrator 子程序中展開為…
    50 [body]: autonomous-loop 的 design-loop 子 agent(auditor / judge)權限範圍收窄 —— 把它們從「**Agent 工具** spawn(繼承…
    57 [body]: - **源起**:日報 2026-06-21 backlog gap「自主 loop 巢狀 spawn 子 agent,卻沒有範圍受限身分,子 agent 繼承全權(confuse…
    76 [body]: - 實作後 smoke test(見 [[Verification/2026-06-23_nested-agent-permission-scope_design-loop收斂]]…
  6.017  Projects/design-loop判準重定位.md  [design-loop,design,loop]
    7 [fm]: - "[[Systems/design-loop]]"
    10 [fm]: - "[[Projects/design-loop提效_計劃]]"
    14 [fm]: - "[[Projects/design-loop重設計]]"
    27 [KEY]: KEY:★共用碼風險(必先解)★——design-loop 與 code-loop ★共用同一段 `_loop_status_panel`★,改判準會同時打到 code-loop,…
    30 [DEP]: DEP:scripts/lumos _loop_status_panel / _loop_status_panel_clusters / _panel_extra_checks /…
    38 [fm]: - content: 共用碼分流採 A 案:gate 加模式旗標(如 --disposal),design-loop 用、code-loop 不用
    40 [fm:context]: context: _loop_status_panel 是 design-loop 與 code-loop 共用的同一段碼。design-loop 定位=抬品質(下游有 TDD+E…
    44 [fm]: - content: 2026-08-04 本案併入 [[Projects/design-loop重設計]],不再獨立推進;d1/d2 沿用進該案,其餘以該案為準
    … 還有 10 處
  5.999  Verification/2026-06-24_finding-refute.md  [design-loop,design,loop]
    8 [fm]: - design-loop 辯方階段維持「prompt 紀律」形態(SKILL.md 步驟 4.5 + orchestrator-prompt §2 步驟 4.5),無代碼化
    12 [fm]: - 下一個真實 design-loop 出現 auditor 假陽性(首次能實測辯方當輪降級的場景)
    14 [fm]: finding-refute spec 自走 design-loop 3 輪於 2026-06-24 自動收斂(canary 3/3 全中、r2+r3 連 2 good、全程無假陽…
    18 [body]: ## 證據:design-loop 3 輪自動收斂(2026-06-24)
  5.997  Verification/2026-07-22_prepush範圍修法落地.md  [design-loop,design,loop]
    21 [VERIFY]: VERIFY:spec 過 design-loop 3 輪+Codex 3 次否決確認+實質收斂人裁(2026-07-21,[[Projects/prepush主幹範圍修法_計劃]…
    25 [body]: 盲區修法 hook code 落地。spec：[[Projects/prepush主幹範圍修法_計劃]]（過 design-loop 收斂）。緣起 [[Issues/code-lo…
  5.979  Projects/skill寫法學借鑒與design-loop剪枝.md  [design-loop,design,loop]
    11 [DECISION]: DECISION:PRIOR-ART: ① 最小解在既有機制層(code-loop 已有的「精實 SKILL.md + reference.md + 撞到就 Read 表」結構,直…
    13 [KEY]: KEY:證據=lumos-design-loop 15,462 字元、單行最長 1,361 字;對照 mattpocock 最長的 wayfinder 11,790、tdd 3,1…
    14 [DEP]: DEP:skills/lumos-design-loop/SKILL.md｜skills/lumos-code-loop/{SKILL.md,reference.md}(已驗證的目…
    16 [body]: # skill 寫法學借鑒與 design-loop 剪枝
    135 [body]: ★對齊 design-loop 的 d4 裁定「前置加重一律拒」★：新守衛要有證據才加，不是有道理就加。
  5.976  Systems/loop-convergence-recording.md  [design-loop,design,loop]
    16 [KEY]: KEY:[2026-07-28]第四模式 settle(opt-in,`--settle 清單檔`)落地——收斂=清單全結清∧G1∧G3(末筆 result=現檔;K-streak…
    17 [KEY]: KEY:[M2 2026-07-16]risk-cluster 三態帳(見[[Projects/design-loop提效_計劃]])——canary record --clust…
  5.951  Verification/2026-06-19_design-loop.md  [design-loop,design,loop]
    4 [fm:feature]: feature: design-loop
    11 [fm]: - design-loop skill 自身的 spec 經 canary-護對抗審計、用 K=2 判準達 CONVERGED(連 2 輪 caught 且無 blocker/ma…
    17 [body]: # Verification:design-loop(2026-06-19)
    19 [body]: ## 證據:spec 自身跑 design-loop 收斂(dogfooding)
  5.928  Verification/2026-06-23_nested-agent-permission-scope_design-loop收斂.md  [design-loop,design,loop]
    8 [fm]: - "design-loop 走 opus auditor/judge + canary 偷植,連 2 輪 caught 且無 blocker/major 才算收斂"
    17 [body]: # Verification: nested-agent-permission-scope(design-loop 收斂)
    21 [body]: ## design-loop 收斂(opus,5 輪)
  5.925  Projects/design-loop提效_計劃.md  [design-loop,design,loop]
    10 [fm]: - "[[Systems/design-loop]]"
    16 [KEY]: KEY:問題=design-loop 常態跑滿 3 輪 cap 靠人裁,收斂慢。真因兩個結構病:①非定態目標——每輪折入改寫 spec,下輪審的是新文件,新 findings 一半…
    20 [DECISION]: DECISION:②動 loop status gate 語意=改守衛的守衛,高風險面——本計劃進實作前必過 design-loop(用舊 loop 審新 loop);①③④⑤純 …
    21 [DEP]: DEP:[[Systems/design-loop]]｜[[Systems/loop-convergence-recording]]
    23 [fm]: - content: M2 design-loop 達 3 輪 cap,人裁實質收斂進實作(2026-07-16):形式 gate 三輪 FAIL(每輪恰一席漏 canary——同…
    32 [body]: # design-loop提效_計劃
    65 [body]: - **M2（動 gate code,必過 design-loop）**：② risk-cluster 帳——`canary record` 加 cluster 欄位、`loop …
    162 [body]: - **self-governance 循環（最重）**：M2 改的是「判定所有 spec 能否進實作」的閘——gate 邏輯錯了會系統性放行壞 spec 或永遠擋好 spec。緩…
  5.908  Verification/2026-06-24_check-r-guard.md  [design-loop,design,loop]
    15 [fm]: Check R [guard:decisions] 事前預防路徑驗證:design-loop 3 輪收斂(canary 3/3 全中、跨家族複核 2 輪 endorsed)+ Py…
    19 [body]: ## design-loop 收斂證據(2026-06-24)
  5.896  Projects/loop機械脊椎M1包_計劃.md  [design-loop,design,loop]
    11 [fm]: - "[[Projects/design-loop輕量檔_計劃]]"
    15 [fm]: - "[[Systems/design-loop]]"
    23 [KEY]: KEY:與[[Projects/design-loop輕量檔_計劃]] M1 分工——本包交付 light 的 loop-status 面(tier 認得+K=1 謂詞+ratch…
    24 [KEY]: KEY:落地同步義務(七項,由折入衍生,枚舉寫死)——skills/lumos-design-loop/SKILL.md(record 時序 C4/手算 N 改指 next/lig…
    25 [KEY]: KEY:★風險面★self-governance=high——四件全動「判定 spec 能否進實作」的閘;進實作前本 spec 必過完整 design-loop(high tier…
    28 [DEP]: DEP:[[Systems/loop-convergence-recording]](record 欄位面)｜[[Systems/convergence-evidence-gate…
    48 [body]: - **唯讀**：讀該 loop 的 canary-log（同 `loop status` 的讀側守衛：round 混用/損壞 clusters/非連續 round-id → 同款…
    68 [body]: - **不含 capture-recapture 殘餘**——2026-07-21 實證：singleton minor findings 使殘餘估計恆高（6.0-15.0），對「…
    … 還有 3 處
  5.858  Projects/送審前impact鏡頭機械化_計劃.md  [design-loop,design,loop]
    16 [KEY]: KEY:★誠實天花板(先寫,不得事後淡化)★:任何機械化只能證明「指令被執行過」,★證明不了「manifest 真的餵進 reviewer 的 prompt」★——派工發生在模型腦…
    74 [body]: - **流程**：trivial，可跳 design-loop（commit 註明）
  5.856  Issues/loop-next吐不可宣告的tier.md  [design-loop,design,loop]
    19 [DECISION]: DECISION:[2026-08-04]修 record_cmd 不吐不可宣告值(`eff_tier in LOOP_TIERS` 才帶 --tier),並補 `tier_hin…
    102 [body]: - **`_TIER_PARAMS` 的命名撞名**：`standard: (3, 3)` 的 `3` 是 design-loop 的 panel 席數，
  5.856  Verification/2026-07-05_code-loop必用守衛.md  [design-loop,design,loop]
    19 [KEY]: KEY:誠實天花板非 oracle——關「忘了/隨手漏」(Stop push+pre-push 擋),關不掉「刻意繞+不誠實」(--no-verify git-native 繞得過…
    43 [body]: - **非 oracle**:Stop 注入可被無視、pre-push 可 `--no-verify`。關得掉「忘了看」(Stop 推到眼前)、「隨手漏」(pre-push 硬擋)…
  5.836  Projects/loop三輪壓縮_計劃.md  [design-loop,design,loop]
    10 [fm]: - "[[design-loop]]"
    16 [KEY]: KEY:把 design-loop/code-loop 從「6 輪同族循序」壓到「≤3 輪:1 輪平行多樣 panel + 條件式精修」,同準確度、砍 token+wall-clo…
    22 [DEP]: DEP:[[design-loop]]
    27 [body]: > 把 canary-護的對抗審計 loop(design-loop + code-loop)從 6 輪同族循序壓到 ≤3 輪,同準確度、砍成本與時間。緣起:使用者指出 6 輪太耗…
    96 [body]: - **交 TDD(不在設計散文摳)**:`--round` 產生者/唯一性/部分寫入判定、`--panel` 謂詞分組實作、delta 產生法(git diff vs snaps…
    107 [body]: ## code-loop 差異(2026-07-09 交叉查文獻;code-loop 不全盤沿用 design-loop)
    112 [body]: - 繼承 panel 機制 + capture-recapture 收斂;但 panel 成員換異質、辯方改可執行——非「design-loop 換 canary 名」。落點:`s…
  5.804  Verification/2026-07-06_CLAUDE注入re-sync.md  [design-loop,design,loop]
    18 [KEY]: KEY:版本=標籤/advisory 非正確性守衛,內容比對(Check D)才是守衛——code 落實無偷用版本當 oracle(終審實證);design-loop 3 輪(架構…
    23 [body]: 修「vendored 教學範本(`graph-discipline.md`)改了、`lumos update`/`init` 卻從不刷新既有專案已注入的 CLAUDE.md 紀律區…
    47 [body]: - **design-loop glue 天花板**:設計層 3 輪未過 gate(glue 密集、非架構未解),殘留實作細節由本次 TDD 紅綠釘死(見設計節點 TEST)。
  5.780  Projects/code階段強化_計劃.md  [design-loop,design,loop]
    12 [fm]: - "[[Systems/design-loop]]"
    14 [KEY]: KEY:code 階段三腿補強(呼應 design-loop d4 定位裁定:正確性歸下游,下游要配得上)——正確性/品質兩腿尚可,性能腿近空(pitfalls 只有 regex …
    19 [KEY]: KEY:[S5]跨家族比重提升(使用者指示,r2 大修)——①辯方預設 Codex(兩 loop,成本中性替換=d4 合規)②雙 Codex 角色**僅 code-loop tie…
    26 [body]: > **緣起**:design-loop d4 裁定「正確性歸下游」後,使用者要求鏡頭轉向 code 階段:搜業界更全面提升正確性/品質/消除 bad performance 的做…
    74 [body]: **d4 合規聲明(r2 blocker 折入)**:帶餌 finder 席**只加在 code-loop**(tier=high)——design-loop(spec 階段)**…
    113 [body]: 1. [s2, blocker] S5「改兩份 loop skill」把帶餌席也加進 design-loop=撞同日 d4「前置加重一律拒」,而範圍刀自稱 d4 合規 → 帶餌席只…
    136 [body]: S1(✅ 2026-07-18 落地:code-loop SKILL 收斂節+參考節+reference.md 三通道)→ S5(✅ 同日落地:code-loop panel 節雙…
  5.778  Systems/lumos-refcheck.md  [design-loop,design,loop]
    40 [body]: design-loop/跨家族複核最吃重的「地面事實查證」恰是 LLM 最不可靠的能力(<55%);放行本 spec 時 qwen disputed 的 5 條 ≥major 指控…
    48 [body]: - 設計稿:`docs/design/2026-07-02-spec-refcheck.md`(design-loop 3 輪收斂;qwen disputed 經人裁機械反證後放行…
  5.760  Projects/loop三輪壓縮_實作計畫.md  [design-loop,design,loop]
    27 [body]: **Architecture:** 機械核心進 `scripts/lumos`(capture-recapture 估計 + `--panel` gate 謂詞 + `--roun…
  5.732  Verification/2026-06-22_cross-family-audit.md  [design-loop,design,loop]
    17 [body]: ## design-loop 收斂
    18 [body]: 手動 design-loop 6 輪(lumos-design-loop skill 編排,canary 序 `[a,b,c,d]`、token `CANARY-CFA-N`):*…
  5.702  Projects/impact-diff橋接_計劃.md  [design-loop,design,loop]
    20 [body]: **跳 design-loop 註明**：glue/編排層（聚合既有 cmd_impact 逐檔結果），無新演算法、無新合約；依 [[Systems/design-loop]] 已…
    38 [body]: design-loop 收斂→code-loop 過審之後,「退場必寫」目前只有 pre-commit 粗閘（有沒有帶架構圖改動）與人判;精確版=**`impact --diff` …
  5.690  Projects/CLAUDE注入re-sync與版本標籤_計劃.md  [design-loop,design,loop]
    20 [TEST]: TEST:design-loop 3 輪(全 caught,見 canary-log claude-reinject)——架構折穩(解耦/ReInjectResult三態/Bloc…
    85 [body]: ## 設計定案補充(design-loop r3 加固)
    93 [body]: 實作層細節(交付 TDD 紅綠釘,計劃不再散文摳——見下方「誠實天花板/design-loop 收斂判斷」):
    96 [body]: ## 誠實天花板 / design-loop 收斂判斷(r3 後)
    97 [body]: - **loop 未過 gate(3 輪 caught 但 severity major→blocker→blocker、未 K-streak)**。原因不是設計有未解的**架構*…
  5.663  Verification/2026-07-24_真遺忘search排除superseded.md  [design-loop,design,loop]
    20 [VERIFY]: VERIFY:design-loop 3 審收斂(2 Sonnet light+1 跨家族 Codex std,跨家族接住兩輪 Sonnet 漏的 hidden 數插點 F6+go…
    36 [body]: - design-loop：r1 light（canary missed，但 orchestrator 查碼證實 4 major，縮範圍 search-only）→ r2 ligh…
  5.643  Projects/canary生成硬化_計劃.md  [design-loop,design,loop]
    24 [body]: 解 [[Projects/社群演算法補強_調研]] 缺口 a（canary 對技術密集 spec 審計員易漏）的生成側：現行 canary 由編排者憑手感植入，「認真審就抓得到、但…
    47 [body]: - skill 文本更新後，下一個真實 design-loop（Task #3 收斂閘修正的 spec 審計）實際走新程序：haiku 探針至少跑一次、留 probe 註記於 ca…
    54 [body]: - [[Systems/design-loop]]
  5.635  Verification/2026-07-15_decision_refs養成_P前置_T1回寫.md  [design-loop,design,loop]
    23 [body]: 主網雞生蛋的解法起手（[[decision_refs自動養成_實作計畫]]）——落地純機械、低風險的 P + T1，讓 decision_refs 開始自我養成；T3（AI 語意填…
    41 [body]: - 這兩塊是機械地面真相：只涵蓋「翻案 confirm 掃過的」往前長。背包大宗（52 篇有 plan_refs 的驗證）靠 **T3 AI suggest**——那塊碰 AI 派…
    45 [body]: - [[decision_refs自動養成_實作計畫]]（P✅ T1✅ → T3 design-loop）
  5.611  Projects/from-scratch重生守衛_計劃.md  [design-loop,design,loop]
    12 [fm]: - "[[Systems/design-loop]]"
    19 [KEY]: KEY:裁定=解法不在「生成更好 prose」(那就是 openwiki);只能走三路——找回 provenance / 標出不確定 / 給重建套 oracle。且大半=組合現有機…
    21 [KEY]: KEY:M1 spec v4(design-loop r1-r3 折入):regen 宣告(SCALAR_KEYS 擴)+四指針只掃 summary+Check J(原G撞名改)+…
    22 [DEP]: DEP:[[Systems/外部對照-code衍生wiki]]｜[[Systems/design-loop]]｜[[Systems/cochange-guard]]
    26 [fm]: - content: M1 design-loop 達 3 輪 panel cap,人裁實質收斂進實作(2026-07-16):機械 gate 形式 FAIL(r3 存活 majo…
    37 [body]: > **狀態**：M1 已過 design-loop 3 輪 panel（r3 canary 3/3 全精準、設計層零存活）→ **人裁實質收斂（2026-07-16，decisi…
    47 [body]: `PRIOR-ART:` ① 最小解在**組合既有閘層**（不對稱雙欄信任、refcheck 指涉驗證、cochange git 挖掘、design-loop 對抗審、signof…
    66 [body]: 6. **兜底 oracle——from-scratch 節點強制過 design-loop 對抗審**。從零重生的節點＝還沒審過的 spec;審計員問「這 claim 證據呢?」…
    … 還有 2 處
  5.608  Systems/pitfalls-code-loop.md  [design-loop,design,loop]
    53 [body]: - 接線:orchestrator-prompt(步驟1節名+2.8 pitfalls --check)/graph-discipline(終審前 --diff→code-loop…
    56 [body]: - 設計稿:`docs/design/2026-07-04-pitfalls-code-loop.md`(design-loop 8 輪 K=3 收斂;qwen major 機械反…
  5.555  Verification/2026-06-20_autonomous-iteration-loop.md  [design-loop,design,loop]
    17 [body]: ## 設計 design-loop 收斂(2026-06-20)
    18 [body]: canary-護 design-loop **5 輪、K=2 收斂**:R1 caught(blocker,opus 用本 spec 倡導的「強制地面事實查證」抓到本 spec 自…
  5.538  Verification/2026-07-04_lint-version-watch.md  [design-loop,design,loop]
    18 [body]: lint-version-watch(pitfalls-lint-integration 第②塊)實作驗證。spec 6 輪 design-loop(核心收斂/cap,shell …
    29 [body]: - **T1 設計 defect(6 輪 design-loop 漏網,誠實記錄完整性天花板)**:§測試1 自相矛盾跨段數見證(3.9/3.20.0 behind vs 等段數守…
    36 [body]: - design-loop 未 GATE PASS(核心收斂、shell wrapper 散文 churn 達 cap);shell 以真 shell smoke 定稿而非設計散文…
  5.520  Verification/2026-07-10_審計loop研究硬化.md  [design-loop,design,loop]
    10 [fm]: - "skill 文本單源:生成硬化與 reviewer 紀律正文在 lumos-design-loop,code-loop 以引用指回"
    45 [body]: - [[Systems/design-loop]]
  5.509  Verification/2026-07-05_pitfalls網搜補漏.md  [design-loop,design,loop]
    16 [VERIFY]: VERIFY:block ③ 網搜補漏落地(skill + 純架構圖、無 lumos 新碼);跳 design-loop(純散文 skill 空轉)、驗收走 dogfood
  5.501  Projects/上下文瘦身_計劃.md  [design-loop,design,loop]
    13 [KEY]: KEY:依 Anthropic 官方 Claude 5 context-engineering 指南瘦身常駐上下文——graph-discipline 範本 12.2KB→5.1K…
  5.487  Projects/狀態標籤同步守衛_計劃.md  [design-loop,design,loop]
    18 [DECISION]: DECISION:[2026-07-20]跳 design-loop——trivial 機械小修(單函式+單 lint check),依 CLAUDE.md trivial 可跳並…
  5.474  Issues/canary-record未落盤事件.md  [design-loop,design,loop]
    15 [KEY]: KEY:2026-07-28 code-testmap r2 三筆 canary record 工具回報成功(印出 CANARY-ae139e51/521d397f/031e738…
  5.469  Verification/2026-06-19_loop-convergence-recording.md  [design-loop,design,loop]
    22 [body]: ### 1. design-loop 收斂(canary-護對抗審計)
  5.468  Verification/2026-06-23_check-t-sentinel.md  [design-loop,design,loop]
    35 [body]: ### 3. design-loop 收斂史
    36 [body]: 2026-06-23 design-loop **6 輪、canary 6/6 全 caught(opus 零漏)**,severity blocker→good→major→go…
  5.452  Projects/關係層主網_實作計畫.md  [design-loop,design,loop]
    11 [KEY]: KEY:M1 順帶收尾補網 E3(P2 是 E3 唯一缺的零件);M4 判斷閘=AI 先判分級(明顯 confirm 放寬/明顯 prune 保守留痕/拿不準才升人=無 termi…
    13 [VERIFY]: VERIFY:design-loop rel-mainnet 三輪(2026-07-15):r1 canary 3/3,24 候選→存活 D5/D10/D16 折 v2;r2 ca…
    15 [DECISION]: DECISION:進實作前必過 lumos-design-loop(高風險 spec,--need 3)到 loop status --gate --panel 收斂;本節點 sp…
    26 [fm:context]: context: spec 切 4 里程碑後進 design-loop 前，3 個範疇問題交人拍板
    30 [fm]: - content: design-loop rel-mainnet 人裁實質收斂(2026-07-15):3 輪 panel cap 到頂,r3 clean(canary 3/3…
    33 [fm:why_chosen]: why_chosen: 存活全 minor+三輪未翻架構=剩的是句級完整性;design-loop 完整性天花板已有實證(lint-version-watch:散文審有天花板、實作…
    39 [body]: 主網＝**改節點的當下就當場點出受波及的鄰居**（proactive，趁脈絡最全、最便宜時處理），對照補網（E1/E2 已上、doctor 事後週期掃）。架構經 3 輪 Codex…
    41 [body]: > **PRIOR-ART**：`lumos impact`（[[主動影響幅度偵測_計劃]]，已 done、9 輪 design-loop）是**無型別**的 downstream…
    … 還有 3 處
  5.424  Projects/pitfalls事故觸發_計劃.md  [design-loop,design,loop]
    21 [DECISION]: DECISION:有真演算法(trigger 比對)+動剛 merged impact/hook→非純散文,走(輕量 design-loop 或)writing-plans+TDD…
  5.417  Verification/2026-07-25_CheckT-Python-profile.md  [design-loop,design,loop]
    21 [VERIFY]: VERIFY:design-loop r1 light(canary caught;審計員實測揪出根因改寫整個計劃——原 dirs 診斷是錯的)+std 單席 Codex(2b+4…
  5.405  Systems/slim-skill-修剪.md  [design-loop,design,loop]
    13 [KEY]: KEY:整段刪除的三處=①`pitfall_when` 欄位說明(通篇依附已砍 `impact`)②「對抗設計審計的 canary」整節(依附已砍 design-loop/cana…
  5.388  Verification/2026-07-25_bootstrap一鍵對稱.md  [design-loop,design,loop]
    21 [VERIFY]: VERIFY:design-loop r1 light(canary caught,2b+3M+1m 折)→ratchet std 單席 Codex(12 條,F1 附真機 PTY…
  5.359  Projects/結清式收斂_計劃.md  [design-loop,design,loop]
    11 [fm]: - "[[Systems/design-loop]]"
    17 [KEY]: KEY:design-loop r1-r5 已跑(五輪 3 席 panel、15/15 canary 全 caught;r1 blocker1+major3+minor10/r2 …
    19 [DECISION]: DECISION:[2026-07-27]同日已 ship 的便宜半(不在本計劃範圍):[audit:] 五問 rubric+穩定性探針(Sage)、design-loop/cod…
    56 [body]: - [x] design-loop 出場（2026-07-28 實質收斂人裁，signoff 留痕；非機械 rc0——裁量出場，golden 已凍）；tier 註記：spec 命中…
    64 [body]: - [x] r3 minor 清掃（2026-07-28 盤整收口）：README×2 settle 行已入（含 --spec 必填）；loop next 例外紀律已落 desig…
    68 [body]: - **self-governance（真命中）**：本 spec 改的是「守自己的閘」——結清模式若設計錯，收斂閘形同虛設且不易察覺（壞掉的守衛比沒有守衛更危險）。防範：① op…
  5.335  Projects/idioms自維護迴路_計劃.md  [design-loop,design,loop]
    39 [fm:context]: context: round-1 design-loop 跨家族Codex否決席揭露:C3兩桶會讓無R真bug逃code-loop收斂閘(blocker)、canary-recor…
    45 [fm:context]: context: round-2 design-loop 跨家族Codex否決席揭露infra-fit blocker:LLM判斷鏈(refuter/草案生成/C3旁註抽取)接不上…
    49 [fm]: - content: 3輪design-loop後暫停實作:架構(M/A拆層)收斂但整合接縫未收斂,人裁定收成設計資產。phase-1 MVP=M層+人手動skill(不碰C3 h…
    131 [body]: - `[S16]` **機械命令 + 狀態一致**（修 round-2）：`lumos idioms approve <id>` / `reject <id>` / `revive…
    133 [body]: - `[S18]` **自引用斷路**（修 round-2：可執行偵測）：design-loop 審 idioms 提案時編排者設 `IDIOMS_SELF_REVIEW=1`；C…
    191 [body]: ## 八、design-loop 狀態與 Round-3 待解接縫（2026-07-12 暫停實作）
    207 [body]: - 🟠 **自引用只蓋力度②**：①trivial/③刪 R 不走 design-loop 但仍過 pre-push code-loop，C3 旁註照跑、回授環未斷。
  5.331  Systems/slim-scan-掃描器.md  [design-loop,design,loop]
    13 [KEY]: KEY:五種懸空引用形態——①prefixed(`lumos <cmd>`帶前綴)②bare-token(反引號裸 token `<cmd>`)③skill-name(DROP_S…
  5.307  Projects/社群演算法補強_調研.md  [design-loop,design,loop]
    11 [fm]: - "[[Systems/design-loop]]"
    42 [body]: - 借法：code-loop/design-loop reviewer 結構 =「N 個獨立、異家族、互不通訊 reviewer + meta-judge 收斂裁定」，**不要讓 …
    69 [body]: - [[Systems/design-loop]]
  5.265  Projects/reviewer結構明文化_計劃.md  [design-loop,design,loop]
    17 [body]: 把 [[Projects/社群演算法補強_調研]] §4/§5 的 LLM-judge 可靠度實證寫進 lumos-design-loop / lumos-code-loop sk…
    41 [body]: - [[Systems/design-loop]]
  5.231  Projects/decision_refs自動養成_實作計畫.md  [design-loop,design,loop]
    13 [DECISION]: DECISION:進實作前過 lumos-design-loop(碰寫入路徑+AI派工+靜默抑制風險);本節點 spec 完成即交 loop
    20 [fm]: - content: T3 design-loop 達 3 輪 panel cap 未 clean 收斂、人裁凍 golden 暫停實作(2026-07-15):核心穩、非收斂集中…
    23 [fm:why_chosen]: why_chosen: design-loop 的價值不只抓 bug,也體檢『功能值不值得』——連兩輪暗示『別再堆小功能大機械』。凍 v4 收斂方向進 golden 待日後真需要;…
    58 [body]: > **進度（2026-07-15）**：P ✅ + T1 ✅（[[Verification/2026-07-15_decision_refs養成_P前置_T1回寫]]）+ cod…
    62 [body]: 3. **T3 AI suggest**（含不對稱信任、provenance、audit）——覆蓋背包；design-loop 重點審這塊。
    64 [body]: ## T3 詳細規格（design-loop v3；r1+r2 四席+Codex 折入）🧊 凍結待實作
    66 [body]: > **🧊 凍結（2026-07-15，decisions#d1）**：design-loop 達 3 輪 panel cap 未 clean 收斂 → 人裁凍 golden、暫停…
    106 [body]: 本 spec 完成 → 交 **lumos-design-loop**（碰寫入路徑 + AI 派工 + E2 靜默抑制風險，建議 `--need 3`）到 `loop status…
  5.226  Verification/2026-07-04_pitfalls-code-loop.md  [design-loop,design,loop]
    22 [body]: code-loop skill 對抗紀律 1:1 對映 design-loop,三道防污染語意逐條確認、CLI(loop status --gate 無 --spec)與落地一致。
  5.221  Projects/CLAUDE注入re-sync與版本標籤_實作計畫.md  [design-loop,design,loop]
    15 [KEY]: KEY:「CLAUDE 注入 re-sync + 版本標籤」TDD 實作計畫(設計權威=[[CLAUDE注入re-sync與版本標籤_計劃]],已過 design-loop 3 輪…
    23 [body]: > **REQUIRED SUB-SKILL:** superpowers:subagent-driven-development。**設計權威**:[[CLAUDE注入re-sy…
  5.210  Systems/anchor-integrity.md  [design-loop,design,loop]
    49 [body]: - 設計稿:`docs/design/2026-07-02-anchor-integrity.md`(design-loop 3 輪、R1 missed 作廢、R2+R3 收斂;q…
  5.179  Verification/2026-07-31_slim-claude-md注入.md  [design-loop,design,loop]
    25 [body]: 原裁定禁的是「覆蓋」——完整版 `lumos init`/`lumos update` 會用範本整段換掉 `LUMOS:GRAPH-DISCIPLINE` sentinel 之間既…
  5.145  Verification/2026-07-21_loop機械脊椎M1包.md  [design-loop,design,loop]
    28 [body]: - 同步（同 commit）：SKILL.md 三處（loop next 進場/record 時序/light 機械 gate）＋templates.md（雙 hash 模板）＋c…
  5.134  Systems/lint-version-watch.md  [design-loop,design,loop]
    52 [body]: ## design-loop 判定(誠實)
  5.119  Verification/2026-07-15_主網M1_決策穩定ID.md  [design-loop,design,loop]
    24 [body]: 主網四里程碑的第一座（[[關係層主網_實作計畫]] M1，spec v4 經 3 輪 design-loop 人裁實質收斂後開建）。
    51 [body]: - 併發同節點 add 仍是全 CLI 既有 last-writer-wins（輸家整筆被蓋非撞號），M1 不加鎖（design-loop r2 辯方裁定）。
  5.092  Verification/2026-07-16_fromscratch守衛M1_CheckJ.md  [design-loop,design,loop]
    22 [body]: [[Projects/from-scratch重生守衛_計劃]] M1 的實作驗證。design-loop 3 輪 panel 人裁實質收斂（golden: `governance…
    32 [body]: - **BLOCKER 修**:`_validate_repo_ref` 原無 token 消毒——`[src: ]`(空→join 出 repo_root 自身=目錄存在)、`[…
  5.064  Projects/loop數據收集_計劃.md  [design-loop,design,loop]
    10 [fm]: - "[[Projects/design-loop提效_計劃]]"
    30 [body]: > **狀態**：ideation 收成（2026-07-16，與人共同盤點），尚未 design-loop、尚未實作。緣起：使用者問「每次真實跑 loop 能不能累積數據供後續判…
    66 [body]: M1 三件皆機械搬運/append 級,貼近 trivial——實作時單 reviewer 即可,註明;M2 stats 讀取器動分析語意,建議過一輪輕 design-loop。落…
  5.058  Issues/2026-08-03_剝除與邊界解析的既有缺陷群.md  [design-loop,design,loop]
    15 [KEY]: KEY:★共同根因=同一件事有多份實作、且正則假設輸入格式良好★。r2 已收編兩處(load_vault/guard trace),但 `FENCE_RE` ★還活著三處★,而活下…
  5.037  Verification/2026-06-25_doctor-irreversible-hint.md  [design-loop,design,loop]
    29 [body]: ## design-loop 收斂證據
  5.013  Systems/native-windows-support.md  [design-loop,design,loop]
    32 [fm:context]: context: os.symlink 在 Windows 需管理員/開發者模式權限;junction 零權限且是真連結(保「git pull 即更新」);但 mklink /J …
    75 [body]: 見 frontmatter `decisions[]`。design-loop **3 輪皆有真缺陷(major/blocker/major,從未乾淨輪)**,印證「無 Windo…
    86 [body]: - 設計稿:`docs/design/2026-06-26-native-windows-support.md`(design-loop 收斂史在尾段「審計修正紀錄」r1-r3 +…
  4.992  Verification/2026-07-28_S2S3壓縮與驗證器.md  [design-loop,design,loop]
    41 [body]: - 掛載面：orchestrator-prompt.md（長跑上下文紀律行）＋design-loop SKILL 終止輸入紀律（verify-progress 選配）＋README…
  4.957  Projects/test-layers軟提醒_計劃.md  [design-loop,design,loop]
    61 [body]: 宣告檔＋列印＋prompt 併入，無深演算法——貼 standard：走 writing-plans＋TDD（宣告解析/棧命中/rc 恆 0 三組測試），可跳 design-loo…
  4.926  Projects/pitfalls棧別效能追問_計劃.md  [design-loop,design,loop]
    54 [body]: T1 動 scripts/lumos=TDD+終審按 pitfalls --diff 分流;T2 動 anchor 檔走 approve;T3 純文字。整體貼 standard,可…
  4.869  Issues/自主loop加法偏食.md  [design-loop,design,loop]
    23 [body]: 自主迭代 loop 的產出永遠是「新增一個機制」——它的任務定義(gap → spec → design-loop)天生不會產出「這題該用既有層的便宜解」或「該刪掉什麼」。**治理…
  4.817  Verification/2026-07-15_decision_refs養成_codeloop硬化.md  [design-loop,design,loop]
    40 [body]: - [[decision_refs自動養成_實作計畫]]（P✅ T1✅ + code-loop 硬化 → T3 design-loop）
  4.813  Projects/lumos-show讀取入口_計劃.md  [design-loop,design,loop]
    21 [KEY]: KEY:light 檔資格自核(M0 honor-system)——硬否決三訊號:①風險類:唯讀指令,四類風險面皆不涉 ②硬合約:不動任何 invariant 級合約(純新增讀取口…
  4.748  Systems/heterogeneous-finder-ensemble.md  [design-loop,design,loop]
    30 [fm]: code-loop 繼承 design-loop 的 panel 機制 + capture-recapture 收斂,但 panel 成員換成
    32 [fm]: ——不是「design-loop 換 canary 名字」。
    33 [fm:context]: context: 使用者質疑「code-loop 可以沿用 design-loop 慣例嗎?程式碼的 review 方式不該不一樣?」上網找解(PRIOR-ART 先問世界)
    35 [fm]: - "純 LLM 多樣 panel(照搬 design-loop):問題=同族 LLM 錯誤相關,撞『9 judge 2 票』天花板"
    54 [body]: design-loop 審 spec(散文),只有 LLM 審計員這一種 finder;完整性理論上不可判定(散文無限可細化)。code-loop 審 diff(程式碼),多了**…
  4.672  Systems/reversibility-governance-ledger.md  [design-loop,design,loop]
    35 [fm:context]: context: design-loop R1-BLOCKER-1 / R2-BLOCKER-A — 若把可逆性塞進 extract_contracts,其 7 個 callsit…
    41 [fm:context]: context: design-loop R2-BLOCKER-B — 原稿把二者混為一談;[rollback:] 是指針、decisions[].rollback 是實際回退內容…
    47 [fm:context]: context: design-loop R1-BLOCKER-3 / R2-MAJOR-2 — 原提案合併多 hook 寫入路徑,bash+python 多寫者搶檔有 race …
    53 [fm:context]: context: design-loop R3-MAJOR-3 — run_doctor 既有 warn() 一律 issues += len,任何 warn 在 --ci 下會 …
    91 [body]: 見上方 decisions[]（四條，皆 design-loop 四輪對抗審計揪出的 blocker/major）。完整 alternatives 與逐輪修正史見設計稿末「審計修正…
    99 [body]: - 設計稿：`docs/design/2026-06-19-reversibility-and-governance-ledger.md`（design-loop 四輪 CONVE…
  4.665  Systems/slim-readme.md  [design-loop,design,loop]
    16 [KEY]: KEY:★2026-07-31 Task 8 裁定變更——README 反映安裝器不再「完全不碰 CLAUDE.md」★:新增〈會不會動我專案的 CLAUDE.md〉整節,講清楚範…
  4.659  Verification/2026-06-19_reversibility-governance-ledger.md  [design-loop,design,loop]
    21 [body]: - **design-loop**：四輪 fresh-agent 對抗審計，第四輪 CONVERGED（三輪修正逐一對著 code 驗證屬實：ci 參數 plumbing、warn…
  4.659  Projects/test-layers軟提醒_實作計畫.md  [design-loop,design,loop]
    18 [DECISION]: DECISION:[2026-07-17]跳 design-loop 並註明:宣告檔解析+列印+prompt 併入純 glue 層,無深演算法——實作真測 > 設計散文(同 cod…
  4.600  Verification/2026-06-26_lumos-deinit_跨平台.md  [design-loop,design,loop]
    41 [body]: brainstorming → design-loop(5 輪 canary 對抗審計收斂,揪出真 blocker `vault==root`)→ subagent-driven …
  4.592  Projects/oracle品質包_計劃.md  [design-loop,design,loop]
    51 [body]: - **抽樣紀律（skill 層，非機械閘）**：design-loop 與 code-loop 判讀段各加一條——每累計 5 個 caught 輪抽 1 輪，把「審計員原始報告全…
    89 [body]: - design-loop 與 code-loop 判讀段各加 [S2] 抽樣條（一句＋樣本保留路徑）。
  4.542  Projects/prepush主幹範圍修法_計劃.md  [design-loop,design,loop]
    20 [KEY]: KEY:★風險面★self-governance=high(動 pre-push 守衛本身)——spec 過 design-loop 非 light([[Issues/code-l…
  4.501  Systems/canary-audit.md  [design-loop,design,loop]
    34 [fm:context]: context: design-loop r1 canary 審計揪出的真 blocker(R1-F2):若以 token 字串出現在輸出裡當「抓到」,審計員可能只順手提到 tok…
    40 [fm:context]: context: design-loop r1(R1-F3):非局部 canary 會牽動被矛盾的那節、污染審計員對該節的真實 findings,移除 canary 也救不回
    46 [fm:context]: context: design-loop r3 唯一 must-fix(R3-Issue1):既有三條 mapper 的舊事件 row 沒有 token 鍵,r["token"] …
    120 [body]: **改動**：design-loop 的跨家族席由「不帶 canary、只作否決」改為**有可用外家時該席也帶 canary**。
  4.446  Systems/slim-install-安裝器.md  [design-loop,design,loop]
    14 [KEY]: KEY:★裁定演進三階(spec [S3],別誤讀成一次到位)★——①原裁定:絕不碰 CLAUDE.md ②Task 8:只准附加、檔尾、絕不覆蓋完整版區塊、兩套規則並存 ③**T…
    26 [TEST]: TEST:225 checks 全綠(`python3 scripts/test_lumos.py -k slim`)。t_slim_install_no_project_touc…
  4.431  Verification/2026-07-29_oracle品質包落地.md  [design-loop,design,loop]
    36 [body]: | S4 skill | code-loop：修 bug 標配「還原翻紅釘」＋抽樣分權；design-loop：4.5 抽樣條 | — |
  4.422  Projects/中心性重驗排程_計劃.md  [design-loop,design,loop]
    57 [body]: - r1 light 單席（2026-07-28，canary type a「A9 靜態先驗乘數」caught；probe 重植×2 頂格如實註記）：**blocker×1**＝排…
    63 [body]: - r3 delta panel（2026-07-28，cap=3 終輪；canary＝假 fixture 檔 `synthetic-moc.graphml`／假格式約定「§五對照…
    68 [body]: - 陳舊天數 log1p＝粗刻度；精算衰減等逃逸帳有樣本再調（同 [[Systems/design-loop]] d5 經濟學：先累後校準）。
  4.398  Verification/2026-07-04_pitfalls-lint-adapter.md  [design-loop,design,loop]
    18 [body]: pitfalls-lint-adapter(pitfalls-lint-integration 計劃第 ① 塊)實作驗證。spec 9 輪 design-loop + KDS tr…
  4.385  Verification/2026-07-05_主動影響幅度偵測.md  [design-loop,design,loop]
    21 [body]: `lumos impact` 原語 + PreToolUse hook 實作完成並通過 opus whole-branch 終審。落地 [[主動影響幅度偵測_計劃]](設計經 9 …
  4.377  Verification/2026-07-15_主網M3_cascade帳本.md  [design-loop,design,loop]
    25 [body]: 主網第三座（[[關係層主網_實作計畫]] M3/[S5b][S3寫回]）——連鎖判定的持久化帳本，design-loop 三輪錘最兇的一段全部落地。
  4.302  Systems/check-j-regen-guard.md  [design-loop,design,loop]
    39 [body]: - code-review blocker：`_validate_repo_ref` 初版無 token 消毒，`[src: ]`/絕對路徑/`..` traversal 經 pa…
  4.301  Verification/2026-07-15_主網M4_觸發與連鎖.md  [design-loop,design,loop]
    48 [body]: - design-loop 統計殘餘 ~2-3 條 minor 級由**實驗場實測**接——次站 **LandmarkMember**（真實 vault 全鏈實測）。
  4.295  Systems/doctor-irreversible-hint.md  [design-loop,design,loop]
    31 [fm:context]: context: design-loop r4/r5 canary 質疑為何不入治理帳;辯方反證 scripts/lumos:L660/666/699/1228-1230
    37 [fm:context]: context: design-loop r1 canary 抓真 blocker:全檔 subprocess 皆函數內 lazy import、module-level 無 su…
    71 [body]: - 設計稿:`docs/design/2026-06-25-doctor-irreversible-hint.md`(design-loop 5 輪收斂 + cross-audit…
  4.239  Projects/檢索PPR邊權_計劃.md  [design-loop,design,loop]
    18 [DECISION]: DECISION:[2026-07-28]light 進場→r1 即 ratchet(blocker×2)——「引 ③ 為證」被審計員正確指為反向背書(③ 也是 light 炸升)…
  4.211  Projects/主動影響幅度偵測_計劃.md  [design-loop,design,loop]
    30 [TEST]: TEST:已實作(branch feat/impact,634 passed;9 輪 design-loop + TDD 12 task + opus 終審[live 重現 C1/…
    55 [fm:why_chosen]: why_chosen: 對齊真實 per-feature 慣例(lint.json/compose-metrics.json/lint-watch.json);design-loo…
    197 [body]: 3. **「Claude 分析過」≠「影響真的處理了」**:注入只保證 Claude *看到*、被要求判;判得對不對、有沒有真同步是沒閉合的迴歸(同 design-loop 整合性…
    207 [body]: ## 審計修正紀錄(lumos-design-loop)
    300 [body]: **收尾決定(使用者選 TDD 路,2026-07-05)**:9 輪後判斷——設計層高價值 finding 已榨出(2 真 bug 修掉),findings 不枯竭主因是 (i)…
    302 [body]: **誠實天花板**:收斂只證「醒著的審計員逐輪找不到更嚴重的」,不證無更深問題;canary-caught/severity/誤判三判均植入者自判、無外部閉合(見 lumos-de…
  4.199  Systems/lumos-deinit.md  [design-loop,design,loop]
    25 [fm:context]: context: design-loop r3 canary 審計揪出的真 blocker:_vault_in 對 standalone vault(根目錄 MOC/+System…
    81 [body]: - 設計稿:`docs/design/2026-06-26-lumos-deinit.md`(design-loop 收斂,5 輪)。
  4.190  Systems/check-r-guard.md  [design-loop,design,loop]
    30 [fm:context]: context: design-loop r1 canary 揪出 F-CHECKPOINT(minor):若共用條件對所有 marker,CHECKPOINT+guard 會誤消…
    36 [fm:context]: context: design-loop r1 F-DRIFT(major):原宣稱「才能通過既有漂移測試」不成立——t_marker_doc_sync 迴圈原不含 [guard:…
    85 [body]: - 設計稿:`docs/design/2026-06-24-check-r-pre-execution-guard.md`(design-loop 收斂 3 輪,canary 3/…
  4.172  Verification/2026-07-04_compose-metrics-adapter.md  [design-loop,design,loop]
    18 [body]: compose-metrics-adapter(pitfalls 偏科層 Compose 重組效能)實作驗證。spec KDS 真機驅動 + design-loop 2 輪(核心硬…
  4.088  Projects/真遺忘召回過濾_計劃.md  [design-loop,design,loop]
    108 [body]: - 處置：**範圍縮為 search-only**，冒出的 major 多屬 context/impact，隨去範圍化解；search-only 為更小的孤立變更，重過一輪 des…
    121 [body]: - 處置：跨家族席 7 major 皆屬「search-only 內可精修」或「out-of-scope 殘留」，非設計崩壞；**使用者行使「人是最後一關」裁定：全折入後直接進 T…
  4.080  Systems/check-t-sentinel.md  [design-loop,design,loop]
    26 [fm:context]: context: design-loop r6 canary 排掉後揪出的真 major(F1):原判據 len(refs)(展開測試名數)可被 [test:a,b] 單逗號 ta…
    32 [★INVARIANT★]: context: design-loop r3 canary 排掉後揪出真 major(F3):原 spec §「★COMBO★ 無 ★INVARIANT★ 也軟提醒」與 extr…
    38 [fm:context]: context: design-loop r1 揪出 blocker(section("C") 已被 core_refs 占用)+ major(複用 Check T bound/r…
    72 [body]: - 設計稿:`docs/design/2026-06-23-check-t-sentinel.md`(design-loop 達 cap 6 輪、canary 6/6 全 caug…
  4.018  Projects/公開精簡版_計劃.md  [design-loop,design,loop]
    19 [KEY]: KEY:★安裝器只做機器層,絕不碰專案層★——專案層的 init/update 會**重新注入 CLAUDE.md 紀律區塊**(用精簡範本),會覆蓋掉既有專案含 design-l…
    132 [body]: - **內容邊界**：只教「標籤怎麼讀」（summary 符號／`KEY:` 行合約性前綴／合約鏈括號／frontmatter 欄位／進場三步，五段內容逐字對齊 `skills/l…
    257 [body]: 3. skill 名稱：`lumos-design-loop`／`lumos-code-loop`／`lumos-core-knowledge`／`lumos-pitfalls-g…
    505 [body]: 4. 架構圖既有實證（[[Systems/design-loop]]）：**本 loop 對機械核心收斂強、對散文空轉**。目前卡住的正是散文那半。
    558 [body]: **狀態**：design-loop **未收斂、人裁放行**（見〈放行裁定〉）。r1／r2 panel 兩輪 + settle 三輪，共 15 席次、10 筆 canary 記錄…
  3.945  Verification/2026-06-26_native-windows-support_真機.md  [design-loop,design,loop]
    29 [body]: ## design-loop(紙審,3 輪皆有真缺陷,從未乾淨輪)
  3.894  Systems/test-profile-multiplatform.md  [design-loop,design,loop]
    34 [★INVARIANT★]: 讓**單一知識架構圖**把 ★INVARIANT★ 的 `[test:]` 綁到**不同平台**的測試（C# xunit / Kotlin JUnit / Maestro E2E /…
  3.809  Verification/2026-07-31_slim-skill與readme落地.md  [design-loop,design,loop]
    108 [body]: - Step 3 修剪範圍比預期大:brief 只明確點名 `reference.md:85` 與 `SKILL.md:14` 兩處,但逐條過完 129 條候選後,發現「對抗設計審…
  3.766  Projects/主動影響幅度偵測_實作計畫.md  [design-loop,design,loop]
    16 [KEY]: KEY:「主動影響幅度偵測」的 TDD 實作計畫(設計經 9 輪 design-loop 收斂,見 [[主動影響幅度偵測_計劃]]);兩塊=lumos impact 原語(scri…
  3.743  Projects/公開精簡版_實作計畫.md  [design-loop,design,loop]
    24 [KEY]: KEY:★2026-07-31 補追加 Task 9——[S3] 裁定第三次變更,推翻 Task 8「只准附加」,由使用者直接指派★:Task 8 開放的「附加、兩套規則並存」被發…
  3.593  Verification/2026-07-11_hook面v1.1轉正.md  [design-loop,design,loop]
    76 [body]: **歸類**:典型「逐輪折入漂移」——同 [[Issues/design-loop折入漂移_機械守衛]] 的 finding class(增量改寫時舊數字被沿用進新結論)。v1.2…
  3.217  Systems/測試假綠形態.md  [design-loop,design,loop]
    8 [fm]: - "[[Projects/skill寫法學借鑒與design-loop剪枝]]"
    145 [body]: 本次**不採納**：它對「用 lumos 去開發產品碼」的價值遠大於「lumos 自己的工具鏈」（後者的測試是反應式跟著 finding 長的）。要做另立題目，見 [[Projec…
  3.104  Systems/verification-rot-eval.md  [design,loop]
    23 [fm:context]: context: design-loop R2 兩個 blocker 推翻 R1 自己的修法——F1:L3 的 get_diff_text() 跑 git diff HEAD~1.…
    29 [fm:context]: context: design-loop R3 BLOCKER-2——不複製這些守衛會把 L3 線上根本不會碰(早退跳過)的 diff 也算進去，recall 虛高;R4 FIND…
    35 [fm:context]: context: design-loop R1 §5(最關鍵 blocker)——build_prompt 的 verification_text 線上吃節點全文，valid_un…
  3.070  Projects/檢索多詞回退_計劃.md  [design-loop,design,loop]
    84 [body]: - [ ] M1：`--any` 實作 + 測試（本階段，trivial 級可跳 design-loop）
  2.994  Projects/檢索優化_計劃.md  [design-loop,design,loop]
    302 [body]: - **評測器（同上補正）**：獨立腳本 `governance/eval/retrieval_eval.py`（非 lumos 子命令——評測屬治理面），跑法 `python3 …
  2.718  Projects/多平台合約測試綁定_計劃.md  [design-loop,design,loop]
    141 [body]: ## 審計修正紀錄（design-loop，loop=multiplatform-test-binding，2026-07-02）
  2.421  Projects/關係層傳播守衛_計劃.md  [design-loop,design,loop]
    43 [fm]: - content: 3輪design-loop後暫停實作:架構收斂(Codex r3確認P0 typed-edge從frontmatter建得出、方向可行)但實作合約細節未釘,人…
    170 [body]: ## 八、design-loop 狀態與待釘合約（2026-07-14 暫停實作）
  2.330  MOC/index.md  [design-loop,design,loop]
    12 [body]: - [[Systems/design-loop]] — canary-護的設計審計 loop;Claude 編排、lumos 出原語,連 2 輪 caught 才放行實作。
    29 [body]: - [[Systems/autonomous-iteration-loop]] — 日報 gap→brainstorm→design-loop→收斂備 pending 的無人看顧自…
    55 [body]: - `docs/design/` — 各功能設計稿(含 design-loop 收斂紀錄,18 份)。
  2.159  Systems/lumos-cli-lifecycle.md  [design,loop]
    96 [body]: - 實作落點:`scripts/lumos` `cmd_install`/`cmd_uninstall`/`cmd_bootstrap`/`cmd_init`/`cmd_updat…
  1.986  Verification/2026-07-02_lumos-refcheck.md  [design]
    11 [fm:valid_under]: valid_under: scripts/lumos cmd_refcheck(FENCE_RE/INLINE_CODE_RE 抽取 + (token,line) 去重 + rc …
  1.972  Verification/2026-07-16_replay校準baseline_v0.md  [loop]
    10 [fm]: - "[[Systems/design-loop]]"

(候選 131;相關性排序,--legacy 走舊字母序)
# Systems/design-loop.md
type:system | status:done | created:2026-06-26 | updated:2026-07-28
summary:
  KEY:★定位★[2026-07-18 使用者裁定,見 decisions d4]——design-loop=抬 spec 質量,非保 spec 正確:一輪 panel 抓便宜的(矛盾/未定義詞/缺失敗路徑)就放行,正確性歸下游 code-loop+測試+驗證、漏網進逃逸帳;**前置加重一律拒**(日報 2026-07-18『保留題接閘』已拒收勿重提——保留題留離線 replay 校準,不進閘)
  KEY:[2026-07-18]S5 跨家族落地(見[[Projects/code階段強化_計劃]])——辯方預設 Codex(成本中性替換,d4 合規;不可用退 opus 註記)+≥3-run 多數決至少 1 run Codex+家族否決保護(外家 blocker 不得僅被同門多數推翻,須執行反證或第二外家);換手效應列 [[Projects/loop數據收集_計劃]] 觀察項(收斂輪數/辯方降級率)
  KEY:★經濟學★[2026-07-20 使用者裁定,見 decisions d5]——spec 品質目標=成本平衡非精確度漸近線:缺陷分層定價(清單型→pre-flight/撞自家現實型→架構圖接地/語意矛盾→一輪panel/深層錯→下游執行接地)+邊際遞減止損+反偏誤排序(執行接地>機械查>異家族>同家族多取樣,信號種類>家族)+標記不確定比消滅不確定便宜;逃逸帳=調價器。**精確度軍備競賽類提案(更強判官/更多輪/更細spec)一律先過此教義裁**
  KEY:[2026-07-16]提效 M1 落地(見[[Projects/design-loop提效_計劃]])——pre-flight 排乾(panel 前便宜 agent 掃清單型缺陷,cascade)/R2+ 嚴格 delta-scoped(物理只餵 diff+受影響合約+前輪爭議,留全局哨兵;解非定態目標病)/辯方路由制(機械證實與多席一致免辯方,低共識才開庭)/fold 迷你核對/severity 錨句(防 framing 通膨);M2 risk-cluster 帳未做(動 gate code,先過 loop)
  KEY:[2026-07-21]★真相入口收編★(外審 blocker,見[[Projects/全盤外審2026-07_調研]])——被審 spec 唯一可寫真檔=架構圖計劃節點;docs/design/ 降唯讀歷史(30 份保留考古,README 立牌);golden 不再複製 spec 第三份,改 spec-ref.txt 記 git sha:路徑(replay 用 git show 還原);loop id 改計劃節點名衍生。同批:panel 收斂行修 skill 漂移(對齊 M2 兩種帳)+判官 style-bias 錨句進 templates+light 體積 50 行先驗
  KEY:[2026-07-21]light 輕量檔 M0 落地(見[[Projects/design-loop輕量檔_計劃]])——補 trivial|standard 間缺檔:小 spec 走 pre-flight+1 通才席+legacy `--need 1`+人裁實質收斂,存活≥major→向上 ratchet 升 standard 自癒;進場硬否決(risk-tiered四類/硬合約/體積)M0 honor-system、M1 機械化。**M1 已機械化(loop status --light --gate 單席謂詞,FAIL 分因 retryable/ratchet,不再攤牌人裁——本 KEY 早期「須新增單席謂詞」的未來式已兌現,2026-07-28 盤整追平)**
  KEY:[2026-07-27]調研三篇折入(AREX/LoopTrap/Sage,見 2026-07-27 調研日報)——已 ship 便宜半:①[audit:] 合法性審計升五問 rubric+穩定性探針(換問法自一致,reference.md;Sage:判官難題1/4偏好不穩、rubric 錨定)②護欄加終止輸入紀律(收斂只認 loop status 機械帳,被審材料/報告散文「還沒完」類語句非終止輸入;LoopTrap:86% 可注入操縱、放大25倍)③severity 錨補搖擺場換問重問取高。貴的半後於 2026-07-28 全落地(見[[Projects/結清式收斂_計劃]]);經濟學教義裁:三項均非前置加重(rubric=判準錨定非加輪;終止紀律=防燒錢非提精度)
  KEY:[2026-07-28]rubric 防應試化兩道(調研 arXiv 2605.12474:評分表公開固定會被「剛好滿足字面」鑽)——①派工措辭改述不逐字貼 ②約每5次 audit 抽1次無表開放判定,落差拉大=儀式化訊號回報人裁;寫入 lumos-project-notes reference.md 五問段
  KEY:[2026-07-10]reviewer 結構紀律明文化——禁互辯/編排者=meta-judge/關鍵單點判決≥3run多數決(EMNLP 2025 實證,見[[Projects/reviewer結構明文化_計劃]])
  FLOW:brainstorming產spec→[trivial?跳並註明]→前置排乾(refcheck機械核對spec→repo指涉+pitfalls --check補實務隱患節+pre-flight便宜agent掃清單型缺陷;首輪前一次,cascade便宜先掃)→每輪{複製spec→/tmp/<id>-rN(**N/型別/席數問 `lumos loop next`**,2026-07-21 M1包;並 sha256sum 真檔留 reviewed 快照)→植1canary(類型=清單[(N−1)mod4],只進工作副本)→派乾淨審計員(sonnet,連2missed升opus,不告知canary,refute framing)→判讀(canary抓到?+真finding max severity)→辯方路由(機械證實/多席一致直接折入,僅低共識才派獨立opus構造反證file:line;2026-07-16 M1)→該輪severity=辯方存活max→**caught輪:折真finding進真檔+fold迷你核對+grep canary=0 之後才 record(--spec/--reviewed 雙hash;M1包 時序裁定,原 record-先-fold 會使 hash 恆失配);missed輪:當場record**/漏抓不折直接下輪}→loop status --gate exit0(模式擇一:legacy --need 2 K-streak∧G1∧G2∧G3/panel/light/settle 結清)→收斂+天花板提醒+golden凍結→writing-plans｜平行panel模式(現行推薦,一輪W席≤3輪)見下方KEY
  KEY:Claude編排,lumos只出原語——Claude用Agent tool派審計員/判讀/修spec;lumos出 canary record/loop status 記錄與算收斂,lumos不spawn agent
  KEY:canary=test-the-tester——每輪偷植已知假錯驗審計員有沒有在認真抓;漏抓(missed)=該輪審計失靈,判決不採信、不折findings(防假陰性/審計員放水)
  KEY:辯方refute=對稱防假陽性——對≥major finding 走路由制(2026-07-16 M1):機械證實/多席一致免辯方直接折入,低共識才派獨立opus(乾淨脈絡、不傳審計結論)強制拿file:line反證才能降;辯方只買code層假陽性,業務層留人
  KEY:硬閘是紀律非技術鎖——loop status未CONVERGED不得進實作,但lumos擋不住「不跑就實作」;靠Claude記得調用+誠實+cap/留痕兜底
  KEY:收斂判準K=2——連2輪 caught 且 severity∈{clean,minor};max cap=6筆record,到頂未收斂則停、攤給人
  KEY:實質收斂 early-exit(2026-07-07 Landmark 實戰調參)——連K輪 caught 無 blocker/major 且新 findings 全為文件精度級 minor → 編排者可提前攤牌請人裁「實質收斂」不跑滿 cap(「你一定找得到」framing 使 G2 數字枯竭壓不到底的誠實出口;僅手動 loop,自主 loop 走 unconverged requeue)
  KEY:派工模板權威=skills/lumos-design-loop/templates.md(6角色 dispatch prompt+編排者判讀規則,Landmark 實戰抽取;SKILL 內嵌 framing 是摘要,漂移以模板為準)
  KEY:平行 panel 模式(2026-07-09,≤3輪壓縮,見 [[loop三輪壓縮_計劃]])——買獨立廣度非相關深度:一輪平行 W 個多樣審計員(tier→panel_width);收斂判準改結構信號(無-cluster 三條合取:輪有效∧存活max≤minor∧capture-recapture殘餘<門檻,無counts=fail-closed;M2 cluster 帳=兩條合取,詳[[Systems/loop-convergence-recording]])取代 K-streak∧G2 序列;`loop status --gate --panel`;混用守衛防 None phantom 輪;legacy(無--panel)完全不變
  DEP:lumos canary record --loop/--severity｜lumos loop status --need(Component A 原語)｜skills/lumos-design-loop/SKILL.md
  TEST:Component A 原語有 test_lumos.py 覆蓋;B 是 skill 非 code,以 design-loop 自跑收斂為驗證
  VERIFY:[[Verification/2026-06-19_design-loop]]
verified_by: [[Verification/2026-06-19_design-loop]], [[Verification/2026-07-09_loop三輪壓縮]], [[Verification/2026-07-10_審計loop研究硬化]], [[Verification/2026-07-16_dloop提效M2_cluster帳]], [[Verification/2026-07-16_replay校準baseline_v0]]
→ 連出 (5):
  • Verification/2026-06-19_design-loop.md [pass]
  • Verification/2026-07-09_loop三輪壓縮.md [pass] — TEST:loop 三輪壓縮機械核心實作完成,847 passed 0 failed(branch feat/loop-panel-compre…
  • Verification/2026-07-10_審計loop研究硬化.md [pass]
  • Verification/2026-07-16_dloop提效M2_cluster帳.md [pass] — TEST:40/40 綠(t_m2_cluster_gate;含 code-loop 補格:三態後綴/kebab charset/孤席輪 MUT…
  • Verification/2026-07-16_replay校準baseline_v0.md [pass] — TEST:8 席盲測完成;標籤=各 spec v1 文本中真實存在的 r1 級 major(fs 5/m2 7),嚴格逐標籤計分
← 連入 (26):
  • Issues/design-loop折入漂移_機械守衛.md [done] — FLAG:DECISION
  • MOC/index.md [doing]
  • Projects/GPT外部評審吸收_計劃.md [doing] — KEY:來源=2026-07-17 使用者把簡化版生命週期圖餵 GPT 取得外部評審;七成建議已存在且多有實證版(L1-3分級=trivial/…
  • Projects/canary注意力檢查失效.md [done] — FLAG:TECHNICAL
  • Projects/canary生成硬化_計劃.md [done]
  • Projects/code階段強化_計劃.md [doing] — KEY:code 階段三腿補強(呼應 design-loop d4 定位裁定:正確性歸下游,下游要配得上)——正確性/品質兩腿尚可,性能腿近空(…
  • Projects/design-loop判準重定位.md [doing] — FLAG:DECISION
  • Projects/design-loop折入守衛_計劃.md [done] — FLAG:DECISION
  • Projects/design-loop提效_計劃.md [doing] — FLAG:DECISION
  • Projects/design-loop輕量檔_計劃.md [doing] — FLAG:DECISION
  • Projects/design-loop重設計.md [doing] — FLAG:DECISION
  • Projects/from-scratch重生守衛_計劃.md [doing] — FLAG:DECISION
  • Projects/impact-diff橋接_計劃.md [done]
  • Projects/loop三輪壓縮_計劃.md [done] — FLAG:DECISION
  • Projects/loop機械脊椎M1包_計劃.md [done] — FLAG:DECISION
  • Projects/reviewer結構明文化_計劃.md [done]
  • Projects/中心性重驗排程_計劃.md [done] — KEY:重驗候選排序從「字母序」升級為「風險加權」——排序鍵=關聯 System 的圖中心性(PageRank,零依賴)×陳舊天數(log 壓縮…
  • Projects/全盤外審2026-07_調研.md [doing] — FLAG:DECISION
  • Projects/公開精簡版_計劃.md [doing] — FLAG:DECISION
  • Projects/社群演算法補強_調研.md [done]
  • Projects/結清式收斂_計劃.md [doing] — KEY:把 loop 收斂判準從「連 K 輪沒挑到問題」(缺席證明)升級為可選的「逐條約束結清」(存在證明)——spec 的每條硬合約(INVA…
  • Systems/judge-severity-gate.md [done] — FLOW:design-loop每輪 sub-step3 派auditor→sub-step4 派獨立judge(明文傳入auditor完整報告…
  • Verification/2026-07-09_loop三輪壓縮.md [pass] — TEST:loop 三輪壓縮機械核心實作完成,847 passed 0 failed(branch feat/loop-panel-compre…
  • Verification/2026-07-10_審計loop研究硬化.md [pass]
  • Verification/2026-07-16_dloop提效M2_cluster帳.md [pass] — TEST:40/40 綠(t_m2_cluster_gate;含 code-loop 補格:三態後綴/kebab charset/孤席輪 MUT…
  • Verification/2026-07-16_replay校準baseline_v0.md [pass] — TEST:8 席盲測完成;標籤=各 spec v1 文本中真實存在的 r1 級 major(fs 5/m2 7),嚴格逐標籤計分
(無合約標記)
# Systems/canary-audit.md
type:system | status:done | created:2026-06-26 | updated:2026-08-03
⚠ 合約(動前必讀):
  ★INVARIANT★ canary record/second 回報成功 ⟺ 該行已落盤且可讀回(readback 驗不到即 rc2 且不印 ✓ 行;出身=2026-07-28 回報成功未落盤事故) [test:t_canary_record_persist] [audit:sonnet/2026-07-29]
  ★INVARIANT★ second(第二判者)紀錄純 telemetry,永不影響 loop status 的 gate 輸出與 rc [test:t_canary_second] [audit:sonnet/2026-07-29]
summary:
  KEY:★INVARIANT★ canary record/second 回報成功 ⟺ 該行已落盤且可讀回(readback 驗不到即 rc2 且不印 ✓ 行;出身=2026-07-28 回報成功未落盤事故) [test:t_canary_record_persist] [audit:sonnet/2026-07-29]
  KEY:★INVARIANT★ second(第二判者)紀錄純 telemetry,永不影響 loop status 的 gate 輸出與 rc [test:t_canary_second] [audit:sonnet/2026-07-29]
  KEY:[2026-07-10]折入錨點污染型事故:編排者用工作副本(含canary)的字串當折入anchor→對真檔靜默落空(replace無assert)——防範:anchor一律取真檔原文+assert;fold-check未來方向補「紀錄宣稱vs正文存在」核對
  KEY:[2026-07-10]生成硬化三條進 skill——載重錨定/haiku 難度探針(FLAWS)/事故反轉(IBIR);missed-rate 升一級指標(lumos gov 分帳);見[[Projects/canary生成硬化_計劃]]
  FLOW:對抗審計一份 spec → 在工作副本偷植 1 個純加性 canary(指向不存在章節/引用未定義詞)→ 不告訴審計員、正常跑審 → 判定:審計員清楚描述該瑕疵=抓到(只信同類同段 findings)/沒描述=放水(判決作廢、換 canary 重跑)→ `lumos canary record caught|missed` 記一筆 → `lumos gov` 第 4 源彙整成審計員可靠度史
  KEY:[2026-07-30]★caught≠覆蓋★外部實證入帳:植錯誤考審查系統實測**最強單席僅 71.6%、六模型並集才 83.3%**(arXiv 2606.19749,經 07-30 治理日報引入)——canary caught 只證該席**醒著**、不證審得夠廣;廣度只能靠多席×多鏡頭×跨家族買,買不到就把收斂宣稱講小
  KEY:[2026-07-30]跨家族席改**能力宣告制**:有外家→該席也帶 canary(舊「不帶canary只否決」作廢,理由=否決席無注意力檢查等於編排者自判);無外家→loop 照跑但 note 留「單家族」、收斂措辭降級為「單家族視角下未發現」。**刻意不採日報的「升主力席」**(連動佔W/capture帳/fail-closed,且與可攜性衝突:skill 要發給別人用,硬要求第二家 CLI=零依賴工具鏈加外部依賴)
  KEY:test-the-tester——這套方法論把判斷外包乾淨審計員,canary 是「注意力下限」探針,擋掉『審計員根本沒讀/只吐通用回應』失敗模式
  KEY:協議是主體(skill 規則),lumos 只做極小 helper:record 留痕 + gov 唯讀彙整;lumos 不 spawn agent、植入/判定留在對話/skill 層
  KEY:提交的文件永遠不含 canary;token(CANARY-<hex>)只是定位記號,非「抓到」的機械證明——唯一算數的是審計員正確描述了那個瑕疵
  KEY:誠實天花板新增(2026-07-07)——eval-awareness 有實證:Anthropic 工作空間論文讀到被評估時的 fake/fictional 內部表徵;canary 隱含前提「審計員沒察覺被測」是實在失效模式,行為層 caught/missed 分不出「真醒」vs「知道被測所以演醒」;詳見身體〈天花板〉〈外部佐證〉
  KEY:auto-mint token 用 secrets.token_hex(非時間戳:秒解析度同秒會撞被 dedup 誤折);每筆 token 唯一供 gov dedup 第 5 鑑別子
  KEY:gov dedup key 第 5 子用 r.get("token","")(不可 r["token"]——舊三源無此鍵會 KeyError 弄爆 gov);只 canary mapper 輸出 token 鍵
  DEP:scripts/lumos cmd_canary｜cmd_gov(.canary-log.jsonl 第 4 源)｜env.vault.parent 定位寫入｜skills/lumos-project-notes(canary 協議)
  TEST:t_canary｜t_canary_loop_fields(258 passed)
  VERIFY:[[Verification/2026-06-19_canary-audit]]
verified_by: [[Verification/2026-06-19_canary-audit]], [[Verification/2026-07-10_審計loop研究硬化]], [[Verification/2026-07-16_replay校準baseline_v0]]
→ 連出 (6):
  • Projects/canary注意力檢查失效.md [done] — FLAG:TECHNICAL
  • Projects/版本發布流程_計劃.md [doing] — FLAG:DECISION
  • Projects/規模影響判斷力假說.md [done] — FLAG:TECHNICAL
  • Verification/2026-06-19_canary-audit.md [pass] — canary-audit 的 record helper + gov 第 4 源彙整,經 t_canary / t_canary_loop_fi…
  • Verification/2026-07-10_審計loop研究硬化.md [pass]
  • Verification/2026-07-16_replay校準baseline_v0.md [pass] — TEST:8 席盲測完成;標籤=各 spec v1 文本中真實存在的 r1 級 major(fs 5/m2 7),嚴格逐標籤計分
← 連入 (22):
  • Issues/canary-record未落盤事件.md [done] — FLAG:TECHNICAL
  • MOC/index.md [doing]
  • Projects/Codex外審吸收_計劃.md [done] — FLAG:DECISION
  • Projects/canary注意力檢查失效.md [done] — FLAG:TECHNICAL
  • Projects/canary生成硬化_計劃.md [done]
  • Projects/design-loop判準重定位.md [doing] — FLAG:DECISION
  • Projects/design-loop提效_計劃.md [doing] — FLAG:DECISION
  • Projects/design-loop重設計.md [doing] — FLAG:DECISION
  • Projects/from-scratch重生守衛_計劃.md [doing] — FLAG:DECISION
  • Projects/loop三輪壓縮_計劃.md [done] — FLAG:DECISION
  • Projects/loop數據收集_計劃.md [doing] — FLAG:DECISION
  • Projects/oracle品質包_計劃.md [done] — FLAG:TECHNICAL
  • Projects/審查規模對照實驗.md [done] — FLAG:TECHNICAL
  • Projects/審查規模對照實驗二_Landmark真缺陷.md [done] — FLAG:TECHNICAL
  • Projects/社群演算法補強_調研.md [done]
  • Projects/規模影響判斷力假說.md [done] — FLAG:TECHNICAL
  • Systems/heterogeneous-finder-ensemble.md [done] — FLOW:code-loop 一輪 panel → 各 finder 產 finding-key(LLM reviewer 手動 --finde…
  • Systems/外部對照-code衍生wiki.md [done] — FLAG:ORIGIN
  • Systems/測試假綠形態.md [done] — FLOW:寫測試/審測試時逐條對照本清單 → 命中哪一型就照該型的「怎麼接住」處理 → 修 bug 收尾跑「還原翻紅釘」時★必須同時放一條「現場…
  • Verification/2026-06-19_canary-audit.md [pass] — canary-audit 的 record helper + gov 第 4 源彙整,經 t_canary / t_canary_loop_fi…
  • Verification/2026-07-10_審計loop研究硬化.md [pass]
  • Verification/2026-07-16_replay校準baseline_v0.md [pass] — TEST:8 席盲測完成;標籤=各 spec v1 文本中真實存在的 r1 級 major(fs 5/m2 7),嚴格逐標籤計分
# Systems/canary-audit.md
  ★INVARIANT★ canary record/second 回報成功 ⟺ 該行已落盤且可讀回(readback 驗不到即 rc2 且不印 ✓ 行;出身=2026-07-28 回報成功未落盤事故)
      ↳ test: t_canary_record_persist
  ★INVARIANT★ second(第二判者)紀錄純 telemetry,永不影響 loop status 的 gate 輸出與 rc
      ↳ test: t_canary_second

合約 2 條(改=breaking) | 技術債 0 條(可改)

nl -ba scripts/lumos | sed -n '"'3290,3890p'
nl -ba scripts/lumos | sed -n '5660,6220p'
wc -l /tmp/dlrd-r1.md docs/.canary-log.jsonl
head -2 docs/.canary-log.jsonl
tail -2 docs/.canary-log.jsonl" in /Users/enzo/harness/lumos-toolchain
2221:        # J-d:無 tier 標記的 KEY 行計數(唯讀提醒,不寫回任何欄位)
2248:        warns.append(f"{untagged_keys} 條 KEY 行無 tier 標記([src:]/[git:]/推測:/佚失:)"
2644:CLUSTER_STATES = ("resolved", "accepted-minor", "disputed-major")
2649:    三態白名單;accepted-minor 需冒號內嵌理由(整筆單一 note 對多 accepted-minor 無法對應=模糊過帳);
2664:        if base not in CLUSTER_STATES:
2665:            return None, f"狀態 {base!r} 不在白名單 {'/'.join(CLUSTER_STATES)}"
2666:        if base == "accepted-minor":
2668:                return None, f"accepted-minor 需逐 cluster 內嵌理由(accepted-minor:理由): {p!r}"
2671:            return None, f"狀態 {state!r} 夾帶後綴(僅 accepted-minor 可帶冒號理由)"
2687:def cmd_canary(env, kind, auditor=None, token=None, note=None, loop=None, severity=None, findings=None, round_id=None, capture_counts=None, clusters=None, spec=None, reviewed=None, tokens=None, wallclock_min=None, tier=None, scope_lines=None):
2720:    # ── M1包 #3 雙 hash 鏈(loop機械脊椎M1包_計劃):--spec/--reviewed 必須同現 ──
2721:    if (spec is None) != (reviewed is None):
2722:        print("ERROR: hash 雙欄必須成對(--spec 與 --reviewed 同現;reviewed=派工當下真檔 sha256)",
2731:        if not re.fullmatch(r"[0-9a-f]{64}", str(reviewed)):
2732:            print(f"ERROR: --reviewed 需 64 位 sha256 hex,收到 {reviewed!r}", file=sys.stderr)
2734:        rec["reviewed_sha256"] = reviewed
2758:    # ── M1包 #1 tier 定錨欄(選配;loop next/gate 讀首個帶 tier 記錄定錨) ──
2759:    if tier is not None:
2760:        if tier not in LOOP_TIERS:
2761:            print(f"ERROR: --tier 需 {'/'.join(LOOP_TIERS)},收到 {tier!r}", file=sys.stderr)
2763:        rec["tier"] = tier
2804:def cmd_canary_second(env, ref_id=None, verdict=None, auditor=None, note=None):
2907:def _panel_extra_checks(latest, min_seats, spec):
2909:    min-seats 數相異非空 auditor(同席灌筆/空席不計)+ G3 hash(帶 --spec=聲明要驗)。回 fails 片段。"""
2911:    if min_seats:
2913:        if seats < min_seats:
2914:            print(f"[panel] min-seats: ✗ — 席數不足({min_seats} 席制僅 {seats} 相異席;同席重複/空席不計)")
2917:            print(f"[panel] min-seats: ✓ — {seats} 相異席 ≥ {min_seats}")
2931:def _loop_status_panel(rounds, loop_id, min_seats=None, spec=None):
2990:                                           min_seats=min_seats, spec=spec, all_rounds=rounds)
3039:    fails += _panel_extra_checks(latest, min_seats, spec)
3051:def _loop_status_panel_clusters(groups, valid_of, loop_id, min_seats=None, spec=None, all_rounds=None):
3115:    fails += _panel_extra_checks(latest, min_seats, spec)   # M1包:cluster 路不得繞過(code-loop r1)
3180:    驗四件:窗級 all-or-nothing(帶=雙欄俱全)/同輪雙欄各自一致/鏈續性 reviewed[k+1]==result[k]/
3181:    窗末 result==sha256(當前檔)。窗首 reviewed 無窗內錨=已知逃逸不硬驗。"""
3183:        return "reviewed_sha256" in r and "result_sha256" in r
3185:        return ("reviewed_sha256" in r) != ("result_sha256" in r)
3188:        return "收斂窗 hash 半帶(記錄僅有 reviewed/result 其一——雙欄必須成對)", ""
3194:    per_round = []   # [(reviewed, result), ...] 每輪一組
3196:        revs = {r["reviewed_sha256"] for r in grp}
3199:            return ("同輪 hash 分裂——各席 reviewed 或 result 不一致(同輪宣稱多個版本)", "")
3203:            return (f"鏈續性斷裂——第 {k + 2} 輪 reviewed ≠ 第 {k + 1} 輪 result"
3450:def cmd_loop_status(env, loop_id, need=None, gate=False, spec=None, repo=None, panel=False, light=False, min_seats=None, settle=None):
3473:        if min_seats is not None:
3474:            print("ERROR: --settle 與 --min-seats 併用 rc2(該檢查定義在 need 窗上,settle 拔窗後無定義域;"
3483:    if min_seats is not None and min_seats < 1:
3484:        print(f"ERROR: --min-seats 需正整數,收到 {min_seats}(負/零=門檻失義;code-loop r2 折入)", file=sys.stderr)
3523:            return _loop_status_panel(rounds, loop_id, min_seats=min_seats, spec=spec)
3558:            fails.append("hash 未綁(light 強制 fail-closed:record 須帶 --spec/--reviewed)")
3559:        if min_seats and len({a for r in [last] if (a := r.get("auditor"))}) < min_seats:
3560:            fails.append(f"席數不足(min-seats={min_seats};空 auditor 不計席——code-loop r1 折入)")
3646:    if min_seats:   # legacy gate 消費;**逐輪**驗非空(code-loop r2 Codex:整窗聯集會讓「一有一空」過關)
3648:               if len({a for a in [r.get("auditor")] if a}) < min_seats]
3650:            print(f"[gate] min-seats: ✗ — 窗內第 {','.join(map(str, bad))} 輪席數不足"
3651:                  f"({min_seats} 席制;逐輪驗非空,空席不計)")
3654:            print(f"[gate] min-seats: ✓ — 窗內 {len(tail)} 輪逐輪 ≥ {min_seats}")
3667:                  "請重審一輪並於 record 帶 --spec/--reviewed)")
3682:_TIER_PARAMS = {"light": (1, 2), "standard": (3, 3), "high": (5, 3), "legacy": (1, 6)}  # tier→(width, cap)
3706:def cmd_loop_next(env, loop_id, tier=None, as_json=False, need=2, spec=None, repo=None):
3711:    tier 定錨優先:帳面首個帶 tier 記錄定錨;僅無定錨舊帳按格式推導;零記錄 rc2 要 --tier。"""
3748:    # ── tier 解析:定錨優先(v8);僅無定錨舊帳按格式推導;零記錄 rc2 ──
3749:    anchor = next((r["tier"] for r in rounds if r.get("tier")), None)
3750:    if tier and anchor and tier != anchor:
3751:        print(f"ERROR: --tier {tier} 與帳面定錨 {anchor} 衝突(定錨優先;要換 tier 開新 loop id)", file=sys.stderr)
3753:    eff_tier = anchor or tier
3754:    if eff_tier is None:
3756:            print("ERROR: 零記錄 loop 需明示 --tier(不猜——猜錯模式撞混用守衛)", file=sys.stderr)
3758:        eff_tier = "standard" if panel_fmt else "legacy"   # 無定錨舊帳 fallback
3759:    width, cap = _TIER_PARAMS[eff_tier]
3760:    light = eff_tier == "light"
3761:    # ── tier↔格式一致性(code-loop r1 折入:格式推導可被繞——high 漏帶 --round 會走鬆的 legacy 閘) ──
3763:        if eff_tier in ("standard", "high") and not panel_fmt:
3764:            print(f"ERROR: tier={eff_tier} 要求 panel 格式(記錄帶 --round),帳面為 legacy 格式——"
3765:                  "格式衝突(補 record 帶 --round,或 tier 錯誤則開新 loop id)", file=sys.stderr)
3768:            print("ERROR: tier=light 為單席 legacy 格式,帳面卻帶 --round(panel 格式)——格式衝突", file=sys.stderr)
3774:        out = {"phase": phase, "tier": eff_tier, "round": n_next, "width": width,
3775:               "min_seats": width, "cap": cap, "advisory": "tier 由編排者宣告後定錨;lumos 只做映射與定錨讀取"}
3777:            if light or eff_tier == "legacy":
3782:            rmode = "" if (light or eff_tier == "legacy") else f" --round r{n_next}"
3783:            # ★`legacy` 不是可宣告值,不得吐進 record_cmd★(2026-08-04):`--tier` 的 choices
3785:            # 的推導結果。原本這裡無條件吐 `--tier {eff_tier}`,legacy 下等於★發一條 argparse
3786:            # 當場擋掉的指令★;而使用者最自然的修復是「把 --tier 拿掉再跑一次」——拿掉就記不上
3789:            # code-teardown-windows / code-slim-handoff)全數 tier=None,即此循環的產物;
3791:            _tier_flag = f" --tier {eff_tier}" if eff_tier in LOOP_TIERS else ""
3794:                                 f" --spec <計劃節點.md> --reviewed <sha256>{_tier_flag}"
3796:            if eff_tier == "legacy":
3797:                out["tier_hint"] = (
3798:                    "★本 loop 無 tier 定錨,正在吃 legacy 判準(單席、cap 6——比 standard 的 cap 3 鬆)★。"
3800:                    "補 --tier standard|high 會被格式一致性當場擋掉(rc2)。"
3801:                    "(--tier light 格式相容,但 cap=2 且帶 ratchet 語意,對已跑數輪的 loop 通常當場 cap-reached。)"
3802:                    "要走分級判準請★開新 loop id,並在第一筆 record 就帶 --tier★。")
3820:        if phase == "plant-canary" and not light and eff_tier != "legacy" and n_next == 1:
3824:                "改用 `--clusters '名=resolved|accepted-minor:理由|disputed-major'` 逐群追蹤,"
3832:            print(f"[next] {loop_id}: phase={phase} tier={eff_tier} 下一輪 N={n_next}"
3853:                             light=light, min_seats=width)   # 恆傳(light/legacy=1;code-loop r1 折入)
4835:    hops, frontier, seen = {}, {seed}, {seed}
4838:        for u in frontier:
4844:        frontier = nxt
6567:        folded = _ledger_fold(trans)
6568:        n_c = sum(1 for t in folded.values() if t.get("state") == "confirmed")
6569:        n_p = sum(1 for t in folded.values() if t.get("state") == "pruned")
8159:        "Compose:昂貴計算有沒有 remember?不穩定型別/缺穩定 key 會不會讓重組失控(stability report 可查)?",
8715:def _compose_read_composables(reports_dir, prefix):
8726:    csv_path = os.path.join(reports_dir, prefix + "-composables.csv")
8736:    txt_path = os.path.join(reports_dir, prefix + "-composables.txt")
8766:    Removed composables (in baseline, not in current) are NOT reported.
8837:        if not isinstance(entry, dict) or not all(k in entry for k in ("name", "metrics_dir", "reports_dir")):
8838:            print("ERROR: compose-metrics.json 每條 module 必須含 name/metrics_dir/reports_dir", file=sys.stderr)
8852:        reports_dir = os.path.join(repo, entry["reports_dir"])
8874:        non_skippable_fqns, fqn_to_name, unstable_map = _compose_read_composables(reports_dir, prefix)
9268:    回 dict {"claims", "tier"[, "lint_ran", "lint_skipped", "filtered"]};git 錯回 None(呼叫端印錯)。
9327:        return {"claims": claims, "tier": "high" if claims else "standard",
9359:    out = {"claims": all_claims, "tier": "high" if all_claims else "standard",
9388:        print(f"tier: {data['tier']}")
10739:    # 每一輪 frontier 的 pending: dest -> (hop, from_node, is_backlink)
10781:def _impact_via(frontier, dest, is_backlink, env):
10787:    - outlink(is_backlink=False): wikilink 在 frontier → 讀 frontier.fields,
10789:    - backlink(is_backlink=True): wikilink 在 dest(dest 連向 frontier) →
10790:      讀 dest.fields(不是 frontier!),找含指向 frontier 的 wikilink 欄位。
10791:      **讀錯端(frontier)會全 miss → 全 body-wikilink fallback(r9-F1 的 bug)。**
10802:        # backlink: dest 連向 frontier → wikilink 在 dest,目標是 frontier
10804:        target_rel = frontier
10806:        # outlink: frontier 連向 dest → wikilink 在 frontier,目標是 dest
10807:        wikilink_node = frontier
11507:    """判定式:tier=high(pitfalls --diff <range> --no-lint --json)
11511:    diff_range 給了則跳 merge-base 推導直接算 tier;否則沿 merge-base..HEAD 現行為。
11512:    fail-open:pitfalls 出錯 / 非 git / 無 merge-base → tier 視作非 high(不 blocked)。
11513:    回傳 dict{blocked:bool, reason:str, tier:str}。
11522:        return {"blocked": False, "reason": "無法取得 HEAD sha(fail-open)", "tier": "unknown"}
11534:                    return {"blocked": False, "reason": "merge-base == HEAD(無 branch diff)", "tier": "standard"}
11537:            return {"blocked": False, "reason": "無 merge-base(fail-open)", "tier": "unknown"}
11540:    # 3. 跑 pitfalls --diff <range> --no-lint --json 取 tier
11549:            return {"blocked": False, "reason": f"pitfalls 失敗(fail-open): {r.stderr.strip()[:120]}", "tier": "unknown"}
11552:            return {"blocked": False, "reason": "pitfalls 無 JSON 輸出(fail-open)", "tier": "unknown"}
11554:        tier = data.get("tier", "standard")
11556:        return {"blocked": False, "reason": f"pitfalls 例外(fail-open): {e}", "tier": "unknown"}
11558:    if tier != "high":
11559:        return {"blocked": False, "reason": f"tier={tier}(非 high)", "tier": tier}
11567:            return {"blocked": False, "reason": f"有效留痕({rec_status}@{marker_sha[:8]})", "tier": tier}
11570:            reason = f"tier=high 且留痕 sha 過時(留痕={rec_sha[:8]} 目標={marker_sha[:8]})"
11572:            reason = f"tier=high 且留痕狀態無效({rec_status!r})"
11573:        return {"blocked": True, "reason": reason, "tier": tier}
11576:    return {"blocked": True, "reason": "tier=high 且無留痕(尚未跑 code-loop pass/skip)", "tier": tier}
11583:    check → 跑判定式回報 verdict(blocked=tier=high∧無有效留痕);--json 輸出 verdict dict。
11618:        # Task 2: 完整判定式(tier-high∧無有效留痕 → blocked)
11624:        tier = verdict["tier"]
11632:                print(f"✅ code-loop check: OK [{branch}@{head_sha[:8]}] tier={tier} {reason}")
11701:                    help="M2 risk-cluster 三態帳:'名=狀態,...'(resolved/accepted-minor:理由/disputed-major);每輪至多一筆帶,loop status --panel 消費")
11703:                    help="M1包 雙 hash:計算當下真檔 sha256 存 result_sha256(record 於 fold 後執行=post-fold);須與 --reviewed 同現")
11704:    cr.add_argument("--reviewed", help="M1包 雙 hash:派工當下真檔 sha256 hex(dispatch 快照);須與 --spec 同現")
11710:    cr.add_argument("--tier", dest="rec_tier", choices=("light", "standard", "high"),
11711:                    help="M1包 tier 定錨欄:該 loop 首個帶 tier 的記錄定錨 loop tier(loop next/gate 讀取)")
11728:                         "與 --panel/--light/--need/--min-seats 互斥,需 --gate+--spec")
11729:    ls.add_argument("--min-seats", type=int, dest="min_seats",
11740:    ln.add_argument("--tier", dest="next_tier", choices=("light", "standard", "high"),
11741:                    help="編排者宣告 tier(有帳面定錨時須一致否則 rc2;零記錄必填)")
12033:        ("check", "跑判定式:tier=high∧無有效留痕→rc1 blocked;--json 輸出 verdict dict"),
12040:                              help="以 JSON 輸出 verdict dict{blocked,reason,tier}")
12042:                              help="直接指定 diff 範圍 <A..B> 算 tier(跳 merge-base 推導;prepush範圍修法)")
12210:                          spec=args.rec_spec, reviewed=args.reviewed,
12211:                          tokens=args.tokens, wallclock_min=args.wallclock_min, tier=args.rec_tier,
12218:                                   panel=args.panel, light=args.light, min_seats=args.min_seats,
12226:            return cmd_loop_next(env, args.loop_id, tier=args.next_tier, as_json=args.next_json,
  3290	                    print("ERROR: canary-log 含不可解析行——驗證器 fail-closed(結構完整性破損,"
  3291	                          "輪序不可信)", file=sys.stderr)
  3292	                    return 2
  3293	                if d.get("loop") == loop_id:
  3294	                    rounds.append(d)
  3295	    except OSError as e:
  3296	        print(f"ERROR: 讀 {path} 失敗: {e}", file=sys.stderr)
  3297	        return 2
  3298	    for i, r in enumerate(rounds, 1):
  3299	        if not isinstance(r.get("kind"), str):
  3300	            print(f"ERROR: 第 {i} 筆 record 缺 kind——結構欄位缺失 fail-closed", file=sys.stderr)
  3301	            return 2
  3302	    def caught_ok(r):
  3303	        return r.get("kind") == "caught" and bool(r.get("auditor"))
  3304	    streak = 0
  3305	    for r in reversed(rounds):
  3306	        if caught_ok(r) and r.get("severity") in ("clean", "minor"):
  3307	            streak += 1
  3308	        else:
  3309	            break
  3310	    out = {
  3311	        "loop": loop_id,
  3312	        "rounds": len(rounds),
  3313	        "kinds": [r.get("kind") for r in rounds],
  3314	        "clean_streak": streak,
  3315	        "findings_trend": [r.get("findings") for r in rounds],
  3316	        "last": ({"kind": rounds[-1].get("kind"), "severity": rounds[-1].get("severity"),
  3317	                  "has_result_hash": "result_sha256" in rounds[-1]} if rounds else None),
  3318	    }
  3319	    if settle is not None:
  3320	        try:
  3321	            data = json.loads(Path(settle).read_text(encoding="utf-8-sig"))
  3322	            entries = data["entries"]
  3323	            assert isinstance(entries, list) and entries
  3324	        except (OSError, ValueError, KeyError, AssertionError) as e:
  3325	            print(f"ERROR: settle 清單檔不可讀/格式非法: {e}", file=sys.stderr)
  3326	            return 2
  3327	        def is_caught_round(n):
  3328	            return isinstance(n, int) and 1 <= n <= len(rounds) and caught_ok(rounds[n - 1])
  3329	        unsettled = 0
  3330	        for e in entries:
  3331	            status = e.get("status")
  3332	            if status == "llm-ok" and not is_caught_round(e.get("verified_in_round")):
  3333	                status = "unverified"
  3334	            if status == "unverified" or (e.get("kind") == "semantic" and status != "llm-ok"):
  3335	                unsettled += 1
  3336	        out["settle"] = {"total": len(entries), "unsettled": unsettled,
  3337	                         "settled": len(entries) - unsettled}
  3338	    if as_json:
  3339	        print(json.dumps(out, ensure_ascii=False, indent=1, sort_keys=True))
  3340	    else:
  3341	        print(f"[verify-progress] loop={loop_id} rounds={out['rounds']} clean_streak={out['clean_streak']}")
  3342	        print(f"  kinds={out['kinds']} findings={out['findings_trend']}")
  3343	        if out["last"]:
  3344	            print(f"  last={out['last']}")
  3345	        if "settle" in out:
  3346	            print(f"  settle={out['settle']}")
  3347	    return 0
  3348	
  3349	
  3350	def _loop_status_settle(rounds, n_badlines, loop_id, settle_path, spec, repo):
  3351	    """settle 收斂閘([S1] 結清式收斂_計劃,2026-07-28):清單全結清 ∧ G1 refcheck ∧ G3(末筆 result=現檔)。
  3352	    K-streak/G2 由「逐條存在證明」取代(G2 印 advisory 不進合取)。
  3353	    caught 輪定義收緊:kind=caught ∧ auditor 非空;否則視同 missed(貶值 llm-ok)。
  3354	    fail-closed 族:log 壞行=rc2(及於整個共用檔——壞行無法歸屬 loop);清單檔不可讀/格式非法/
  3355	    零條目/llm-ok 缺 verified_in_round=rc2;懸空輪/非 caught 輪的 llm-ok=貶值視同未結清。
  3356	    清單檔=JSON {"entries":[{id,kind:mech|semantic,claim,status,verified_in_round?,spec_sha}]}
  3357	    (零依賴家規:JSON 非 YAML——stdlib 可解)。"""
  3358	    import json
  3359	    if n_badlines:
  3360	        print(f"ERROR: canary-log 含 {n_badlines} 行不可解析——settle 輪鍵=append 序,壞行使序號位移,"
  3361	              "fail-closed 及於整個共用檔(修復或歸檔壞行後重跑)", file=sys.stderr)
  3362	        return 2
  3363	    try:
  3364	        data = json.loads(Path(settle_path).read_text(encoding="utf-8-sig"))
  3365	    except OSError as e:
  3366	        print(f"ERROR: 讀不到 --settle 清單檔 {settle_path}: {e}", file=sys.stderr)
  3367	        return 2
  3368	    except ValueError as e:
  3369	        print(f"ERROR: --settle 清單檔非合法 JSON: {e}", file=sys.stderr)
  3370	        return 2
  3371	    entries = data.get("entries") if isinstance(data, dict) else None
  3372	    if not isinstance(entries, list) or not entries:
  3373	        print("ERROR: 清單需 {\"entries\":[...]} 且至少 1 條——零條目全結清恆真=零證明,拒收",
  3374	              file=sys.stderr)
  3375	        return 2
  3376	    for i, e in enumerate(entries, 1):
  3377	        if not isinstance(e, dict) or not all(k in e for k in ("id", "kind", "status", "spec_sha")):
  3378	            print(f"ERROR: 條目 #{i} 缺必要欄(id/kind/status/spec_sha)", file=sys.stderr)
  3379	            return 2
  3380	        if e["kind"] not in ("mech", "semantic") or e["status"] not in ("unverified", "mech-ok", "llm-ok"):
  3381	            print(f"ERROR: 條目 {e.get('id')} kind/status 非法(kind=mech|semantic,"
  3382	                  "status=unverified|mech-ok|llm-ok)", file=sys.stderr)
  3383	            return 2
  3384	        if e["status"] == "llm-ok" and not isinstance(e.get("verified_in_round"), int):
  3385	            print(f"ERROR: 條目 {e.get('id')} llm-ok 缺 verified_in_round(int)——空席背書洞,schema 強制",
  3386	                  file=sys.stderr)
  3387	            return 2
  3388	    repo_root = _anchor_repo_root(repo)
  3389	    if repo_root is None:
  3390	        return 2
  3391	    try:
  3392	        cur_sha = _sha256_file(spec)
  3393	        text = Path(spec).read_text(encoding="utf-8-sig")
  3394	    except OSError as e:
  3395	        print(f"ERROR: 讀不到 --spec {spec}: {e}", file=sys.stderr)
  3396	        return 2
  3397	    fails = []
  3398	    # caught 輪(收緊定義):kind=caught ∧ auditor 非空;輪鍵=append 序(1-based)
  3399	    def is_caught_round(n):
  3400	        if not (1 <= n <= len(rounds)):
  3401	            return False   # 懸空輪 fail-closed
  3402	        r = rounds[n - 1]
  3403	        return r.get("kind") == "caught" and bool(r.get("auditor"))
  3404	    unsettled = []
  3405	    for e in entries:
  3406	        status = e["status"]
  3407	        why = None
  3408	        if status == "llm-ok" and not is_caught_round(e["verified_in_round"]):
  3409	            status, why = "unverified", f"貶值(第 {e['verified_in_round']} 輪非 caught/懸空/空席)"
  3410	        if e["spec_sha"] != cur_sha:
  3411	            why = "spec_sha 過期(spec 已改版,重拆或確認重蓋)"
  3412	        elif status == "unverified" or (e["kind"] == "semantic" and status != "llm-ok"):
  3413	            why = why or ("語意條停 " + status + "(須 llm-ok 才結清)" if status != "unverified" else "未查證")
  3414	        if why:
  3415	            unsettled.append((e["id"], why))
  3416	    if unsettled:
  3417	        print(f"[settle] 清單全結清: ✗ — {len(unsettled)}/{len(entries)} 條未結清")
  3418	        for eid, why in unsettled:
  3419	            print(f"    {eid}: {why}")
  3420	        fails.append("清單未結清")
  3421	    else:
  3422	        print(f"[settle] 清單全結清: ✓ — {len(entries)} 條(mech-ok/llm-ok 依 kind 各就終態)")
  3423	    claims, n_missing, n_oor, _n_ok = _refcheck_scan(text, repo_root)
  3424	    bad = [c for c in claims if c["status"] in ("missing", "line_out_of_range")]
  3425	    if bad:
  3426	        print(f"[settle] G1 refcheck: ✗ — {len(bad)} 條壞宣稱")
  3427	        fails.append("G1")
  3428	    else:
  3429	        print(f"[settle] G1 refcheck: ✓ — {len(claims)} 條宣稱全 ok")
  3430	    last = rounds[-1] if rounds else None
  3431	    if last is None:
  3432	        print("[settle] G3 末筆對齊: ✗ — settle 帳零 record(fail-closed)")
  3433	        fails.append("G3")
  3434	    elif last.get("result_sha256") != cur_sha:
  3435	        print("[settle] G3 末筆對齊: ✗ — 末筆 result hash≠當前 spec(缺欄同 ✗;off-fold 改版後請重審一輪)")
  3436	        fails.append("G3")
  3437	    else:
  3438	        print("[settle] G3 末筆對齊: ✓")
  3439	    fs = [r.get("findings") for r in rounds[-3:]]
  3440	    print(f"[settle] G2(advisory,不進合取): findings 近況={fs}")
  3441	    for i, r in enumerate(rounds, 1):
  3442	        print(f"{i}\t{r.get('kind', '?')}\t{r.get('severity', '-')}\t{r.get('ts', '')}\t{r.get('note', '')}")
  3443	    if fails:
  3444	        print(f"⛔ SETTLE GATE FAIL ({loop_id}: {'/'.join(fails)})")
  3445	        return 1
  3446	    print(f"✅ SETTLE GATE PASS ({loop_id}: 清單全結清 ∧ G1 ∧ G3)")
  3447	    return 0
  3448	
  3449	
  3450	def cmd_loop_status(env, loop_id, need=None, gate=False, spec=None, repo=None, panel=False, light=False, min_seats=None, settle=None):
  3451	    """算某設計 loop 的收斂(收斂留痕):連 K 輪『canary caught 且 severity∈{clean,minor}』。
  3452	    --gate:升級為證據閘(K-streak 為必要條件,合取 G1 refcheck 引用座標 + G2 發現枯竭);
  3453	    findings 數的源頭仍是 LLM 裁決——gate 機械化的是算術,不是數字的正確性(見設計 doc)。
  3454	    讀 .canary-log.jsonl 的 **append 序**(不 ts-sort:ts 只到秒、同秒會並列),篩 loop==id。
  3455	    tail-K 滑動窗:前面髒輪不影響、只看最後 K 筆;missed/缺 severity 視同未收斂。
  3456	    exit 0=CONVERGED / 1=未收斂(含無記錄=還沒開始)/ 2=真錯誤。
  3457	    天花板:收斂=連 K 輪醒著的審計員沒找到 blocker/major,非完整正確;severity 自報(見設計 doc)。"""
  3458	    import json
  3459	    if light and panel:
  3460	        print("ERROR: --light 與 --panel 互斥(light=單席 legacy 格式;三模式各自一條路)", file=sys.stderr)
  3461	        return 2
  3462	    explicit_need = need is not None
  3463	    if need is None:
  3464	        need = 2
  3465	    if settle is not None:
  3466	        # [S1] rc2 互斥/前置群(fail-closed;結清式收斂_計劃 2026-07-28)
  3467	        if panel or light:
  3468	            print("ERROR: --settle 與 --panel/--light 互斥(v1 只接 legacy 路徑)", file=sys.stderr)
  3469	            return 2
  3470	        if explicit_need:
  3471	            print("ERROR: --settle 不數輪,顯式 --need 無意義(靜默忽略會誤導)——拿掉 --need", file=sys.stderr)
  3472	            return 2
  3473	        if min_seats is not None:
  3474	            print("ERROR: --settle 與 --min-seats 併用 rc2(該檢查定義在 need 窗上,settle 拔窗後無定義域;"
  3475	                  "auditor 非空職能由 caught 定義收緊承接)", file=sys.stderr)
  3476	            return 2
  3477	        if not gate:
  3478	            print("ERROR: --settle 需 --gate(fail-closed)", file=sys.stderr)
  3479	            return 2
  3480	        if spec is None:
  3481	            print("ERROR: --settle 需 --spec(條目 spec_sha 與 G3 皆比對現檔,無對象不可判)", file=sys.stderr)
  3482	            return 2
  3483	    if min_seats is not None and min_seats < 1:
  3484	        print(f"ERROR: --min-seats 需正整數,收到 {min_seats}(負/零=門檻失義;code-loop r2 折入)", file=sys.stderr)
  3485	        return 2
  3486	    need = max(1, need)
  3487	    path = env.vault.parent / ".canary-log.jsonl"
  3488	    rounds = []
  3489	    n_badlines = 0
  3490	    try:
  3491	        if path.exists():
  3492	            for line in path.read_text(encoding="utf-8").splitlines():
  3493	                line = line.strip()
  3494	                if not line:
  3495	                    continue
  3496	                try:
  3497	                    d = json.loads(line)
  3498	                except ValueError:
  3499	                    n_badlines += 1   # settle fail-closed 用;legacy/panel 維持容忍(行為不變)
  3500	                    continue
  3501	                if d.get("loop") == loop_id:
  3502	                    rounds.append(d)
  3503	    except OSError as e:
  3504	        print(f"ERROR: 讀 {path} 失敗: {e}", file=sys.stderr)
  3505	        return 2
  3506	
  3507	    # 混用守衛(R2-F1 footgun):panel 記錄(有 round 欄)與 legacy 模式不可混用。
  3508	    # 用 all/any 而非單向 any:partial-mix(部分有 round、部分沒)也擋——否則 round-less
  3509	    # 記錄在 panel 模式會形成 None phantom 組、可能成「最新輪」偽過(review I1)。
  3510	    n_round = sum(1 for r in rounds if "round" in r)
  3511	    if panel and rounds and n_round != len(rounds):
  3512	        print("ERROR: --panel 要求本 loop 記錄全帶 round 欄(混用/legacy 記錄拒讀,防 None phantom 輪)",
  3513	              file=sys.stderr)
  3514	        return 2
  3515	    if not panel and n_round > 0:
  3516	        print("ERROR: canary-log 含 round 欄(panel 記錄)卻未加 --panel——拒絕靜默把一輪 W 筆當 W 輪",
  3517	              file=sys.stderr)
  3518	        return 2
  3519	    if settle is not None:
  3520	        return _loop_status_settle(rounds, n_badlines, loop_id, settle, spec, repo)
  3521	    if panel:
  3522	        try:
  3523	            return _loop_status_panel(rounds, loop_id, min_seats=min_seats, spec=spec)
  3524	        except OSError as e:   # G3 --spec 不可讀:與 legacy G1 對稱 rc2(code-loop r2 折入)
  3525	            print(f"ERROR: 讀不到 --spec {spec}: {e}", file=sys.stderr)
  3526	            return 2
  3527	
  3528	    # ── M1包 #2:light K=1 謂詞(loop機械脊椎M1包_計劃;hash 強制 fail-closed) ──
  3529	    if light:
  3530	        if spec is None:
  3531	            print("ERROR: --light 需 --spec(light hash 強制 fail-closed,無驗證對象不可判)", file=sys.stderr)
  3532	            return 2
  3533	        # ratchet 最先:任一 caught 筆 severity≥major → 永久 FAIL(missed 筆不觸發)
  3534	        if any(r.get("kind") == "caught" and r.get("severity") in ("major", "blocker") for r in rounds):
  3535	            print(f"⛔ LIGHT GATE FAIL ({loop_id}: ratchet——已有 caught 輪 severity≥major,永久升 standard;"
  3536	                  "開新 panel loop id(原 id+-std 後綴)承接,乾淨輪不洗回)")
  3537	            return 1
  3538	        if not rounds:
  3539	            print(f"⏳ 無記錄 ({loop_id})")
  3540	            return 1
  3541	        last = rounds[-1]
  3542	        fails = []
  3543	        if last.get("kind") != "caught":
  3544	            fails.append("retryable——末輪 missed(判決不採信;light cap=2 內可重試)")
  3545	        if last.get("severity") not in ("clean", "minor"):
  3546	            fails.append(f"severity={last.get('severity')} 不在 {{clean,minor}}")
  3547	        sev, f = last.get("severity"), last.get("findings")
  3548	        if f is None or (sev == "clean" and f != 0) or (sev == "minor" and f < 1):
  3549	            fails.append(f"欄位互證矛盾:severity={sev} 與 findings={f} 不相容")
  3550	        try:
  3551	            err, info = _hash_chain_check([[last]], spec)
  3552	        except OSError as e:   # 與 legacy G1 對稱 rc2(code-loop r2 折入)
  3553	            print(f"ERROR: 讀不到 --spec {spec}: {e}", file=sys.stderr)
  3554	            return 2
  3555	        if err:
  3556	            fails.append(err)
  3557	        elif info == "unbound":
  3558	            fails.append("hash 未綁(light 強制 fail-closed:record 須帶 --spec/--reviewed)")
  3559	        if min_seats and len({a for r in [last] if (a := r.get("auditor"))}) < min_seats:
  3560	            fails.append(f"席數不足(min-seats={min_seats};空 auditor 不計席——code-loop r1 折入)")
  3561	        for line in _cost_summary(rounds):
  3562	            print(line)
  3563	        if fails:
  3564	            print(f"⛔ LIGHT GATE FAIL ({loop_id}): " + "；".join(fails))
  3565	            return 1
  3566	        print(f"✅ LIGHT GATE PASS ({loop_id}: 單席 caught∧max≤minor∧互證∧hash 鏈驗訖 K=1)")
  3567	        return 0
  3568	
  3569	    def good(r):
  3570	        return r.get("kind") == "caught" and r.get("severity") in ("clean", "minor")
  3571	
  3572	    converged = len(rounds) >= need and all(good(r) for r in rounds[-need:])
  3573	    streak = 0                                  # 從尾往回的連續合格數(算「還需 N」)
  3574	    for r in reversed(rounds):
  3575	        if good(r):
  3576	            streak += 1
  3577	        else:
  3578	            break
  3579	    if not gate:
  3580	        if converged:
  3581	            print(f"✅ CONVERGED ({loop_id}, 連 {need} 輪 caught+乾淨;共 {len(rounds)} 輪)")
  3582	            rc = 0
  3583	        else:
  3584	            print(f"⏳ 還需 {need - streak} 輪乾淨 ({loop_id}, 已 {len(rounds)} 輪)")
  3585	            rc = 1
  3586	        for i, r in enumerate(rounds, 1):       # 留痕:每輪一行 tab 分隔
  3587	            print(f"{i}\t{r.get('kind', '?')}\t{r.get('severity', '-')}\t{r.get('ts', '')}\t{r.get('note', '')}")
  3588	        for line in _cost_summary(rounds):
  3589	            print(line)
  3590	        return rc
  3591	
  3592	    # ── 證據閘(--gate):K-streak(必要)∧ G1 refcheck(--spec 可選)∧ G2 發現枯竭 ──
  3593	    repo_root = _anchor_repo_root(repo)
  3594	    if repo_root is None:
  3595	        return 2
  3596	    fails = []
  3597	    if converged:
  3598	        print(f"[gate] K-streak(--need {need}): ✓")
  3599	    else:
  3600	        print(f"[gate] K-streak(--need {need}): ✗ — 還需 {need - streak} 輪 caught+乾淨(已 {len(rounds)} 輪)")
  3601	        fails.append("K-streak")
  3602	    if spec is None:
  3603	        print("[gate] G1 refcheck(引用座標): skipped(無 spec 對象,code-loop 情境)")
  3604	    else:
  3605	        try:
  3606	            text = Path(spec).read_text(encoding="utf-8-sig")
  3607	        except OSError as e:
  3608	            print(f"ERROR: 讀不到 --spec {spec}: {e}", file=sys.stderr)
  3609	            return 2
  3610	        claims, n_missing, n_oor, _n_ok = _refcheck_scan(text, repo_root)
  3611	        bad = [c for c in claims if c["status"] in ("missing", "line_out_of_range")]
  3612	        if bad:
  3613	            print(f"[gate] G1 refcheck(引用座標): ✗ — {len(bad)} 條壞宣稱")
  3614	            for c in bad:
  3615	                loc = f"{c['token']}:{c['line']}" if c["line"] else c["token"]
  3616	                print(f"    {loc}({c['status']})")
  3617	            fails.append("G1")
  3618	        else:
  3619	            print(f"[gate] G1 refcheck(引用座標): ✓ — {len(claims)} 條宣稱全 ok")
  3620	    tail = rounds[-need:]
  3621	    fs = [r.get("findings") for r in tail]
  3622	    g2_fail = ""
  3623	    if len(tail) < need:
  3624	        g2_fail = f"紀錄不足 {need} 輪"
  3625	    elif any(f is None for f in fs):
  3626	        g2_fail = "tail-K 有輪缺 findings 欄位(fail-closed:用 canary record --findings N 記錄)"
  3627	    else:
  3628	        for r in tail:
  3629	            sev, f = r.get("severity"), r.get("findings")
  3630	            if (sev == "clean" and f != 0) or (sev == "minor" and f < 1):
  3631	                g2_fail = f"欄位互證矛盾:severity={sev} 與 findings={f} 不相容"
  3632	                break
  3633	        if not g2_fail:
  3634	            if need == 1:
  3635	                drained = fs[-1] == 0
  3636	            else:
  3637	                mono = all(fs[i] >= fs[i + 1] for i in range(len(fs) - 1))
  3638	                drained = mono and fs[-1] <= 1 and (fs[-1] == 0 or fs[-1] < fs[-2])
  3639	            if not drained:
  3640	                g2_fail = f"findings={fs} 未枯竭(需單調不增、末輪 ≤1 且末輪=0 或末步嚴格下降)"
  3641	    if g2_fail:
  3642	        print(f"[gate] G2 發現枯竭: ✗ — {g2_fail}")
  3643	        fails.append("G2")
  3644	    else:
  3645	        print(f"[gate] G2 發現枯竭: ✓ — findings={fs}")
  3646	    if min_seats:   # legacy gate 消費;**逐輪**驗非空(code-loop r2 Codex:整窗聯集會讓「一有一空」過關)
  3647	        bad = [i for i, r in enumerate(tail, 1)
  3648	               if len({a for a in [r.get("auditor")] if a}) < min_seats]
  3649	        if bad:
  3650	            print(f"[gate] min-seats: ✗ — 窗內第 {','.join(map(str, bad))} 輪席數不足"
  3651	                  f"({min_seats} 席制;逐輪驗非空,空席不計)")
  3652	            fails.append("席數不足")
  3653	        else:
  3654	            print(f"[gate] min-seats: ✓ — 窗內 {len(tail)} 輪逐輪 ≥ {min_seats}")
  3655	    # ── M1包 #3 G3 雙 hash 鏈(帶 --spec=聲明要驗;收斂窗=tail need 筆) ──
  3656	    if spec is not None:
  3657	        try:
  3658	            err, info = _hash_chain_check([[r] for r in tail], spec)
  3659	        except OSError as e:   # 對稱 G1 rc2(code-loop r2 折入;G1 讀 text 過≠hash 讀 bytes 必過,race 窗)
  3660	            print(f"ERROR: 讀不到 --spec {spec}: {e}", file=sys.stderr)
  3661	            return 2
  3662	        if err:
  3663	            print(f"[gate] G3 hash 鏈: ✗ — {err}")
  3664	            fails.append("G3")
  3665	        elif info == "unbound":
  3666	            print("[gate] G3 hash 鏈: ✗ — 收斂窗未綁 spec hash(帶 --spec 即要求驗證;"
  3667	                  "請重審一輪並於 record 帶 --spec/--reviewed)")
  3668	            fails.append("G3")
  3669	        else:
  3670	            print(f"[gate] G3 hash 鏈: ✓ — {info}")
  3671	    for i, r in enumerate(rounds, 1):
  3672	        print(f"{i}\t{r.get('kind', '?')}\t{r.get('severity', '-')}\t{r.get('findings', '-')}\t{r.get('ts', '')}\t{r.get('note', '')}")
  3673	    for line in _cost_summary(rounds):
  3674	        print(line)
  3675	    if fails:
  3676	        print(f"⛔ GATE FAIL ({loop_id}: {'/'.join(fails)})")
  3677	        return 1
  3678	    print(f"✅ GATE PASS ({loop_id}: K-streak ∧ G1 ∧ G2 ∧ G3)")
  3679	    return 0
  3680	
  3681	
  3682	_TIER_PARAMS = {"light": (1, 2), "standard": (3, 3), "high": (5, 3), "legacy": (1, 6)}  # tier→(width, cap)
  3683	# ★一輪能丟多少給審查員的軟上限★(2026-08-02)
  3684	# 為什麼有這條:審查員的任務是「在 N 行裡找出那個植入的錯」,而 context rot(脈絡越長、
  3685	# 注意力越差)是已發表的實測現象——有效脈絡長度約標稱值的 60-70%,★退化在 32K token 就
  3686	# 量得到★(不必塞爆),報告的退化幅度 13.9%-85%。
  3687	# ★這條門檻★純粹★借自外部文獻,本專案自己的資料不支持它★(2026-08-02 更正,
  3688	# 原註解在此宣稱「本專案資料落在線的兩邊、方向是反的」——★那個宣稱是錯的,已撤★):
  3689	#   ① 原始觀察(code-slim-python r1/r2 大 payload 零 findings、r3-r6 小 payload 有 findings)
  3690	#      經查證★兩組審的根本不是同一份碼★(前者 bash→Python 移植,後者後來才寫的 manifest 步驟),
  3691	#      拿來比就是拿蘋果比橘子,不構成任何證據。
  3692	#   ② 之後跑了★兩次刻意設計的對照實驗★(見架構圖 [[Projects/審查規模對照實驗]] 與
  3693	#      [[Projects/審查規模對照實驗二_Landmark真缺陷]]),★都不支持「量大→漏看」★:
  3694	#      命中率沒掉。實驗二甚至 7/7 全中,撞到天花板。
  3695	#   ③ 反而浮出另一個假說:量大影響的可能不是「有沒有看到」而是★判斷的自信度★——
  3696	#      大 payload 的席位會★有把握地宣稱有缺陷的地方沒問題★(見 [[Projects/規模影響判斷力假說]],
  3697	#      3/3 大 payload 席位講反、1/1 小 payload 席位找到)。★該假說 n=4、觀察性、
  3698	#      編碼者=提出者,尚未閉合 maker≠checker,★不得據以動 gate★。
  3699	# 門檻取 1800 行 ≈ 30K token,是★借用已發表的 32K 起點取略保守整數★,不是本專案量出來的。
  3700	# 這是軟上限:超過不擋(輪已經跑完才記帳,擋也來不及),但★記進帳並要求收斂宣稱講小★。
  3701	_CANARY_SCOPE_SOFT_CAP_LINES = 1800
  3702	
  3703	_CANARY_TYPES = ("a", "b", "c", "d")   # 壞交叉引用/未定義旗標/未定義欄位常數/未定義產物裸檔名
  3704	
  3705	
  3706	def cmd_loop_next(env, loop_id, tier=None, as_json=False, need=2, spec=None, repo=None):
  3707	    """M1包 #1(loop機械脊椎M1包_計劃):帳本吐唯一下一動作。唯讀指針——lumos 不 spawn agent,
  3708	    編排仍是 Claude(Systems/design-loop 分工)。phase 五值:escalate/gate-pending/converged/
  3709	    cap-reached/plant-canary;判定優先序=escalate→gate-pending(資訊不足,先於 cap)→converged
  3710	    (僅 full-basis)→cap-reached→plant-canary。converged=rc0/其餘 phase=rc1/錯誤=rc2。
  3711	    tier 定錨優先:帳面首個帶 tier 記錄定錨;僅無定錨舊帳按格式推導;零記錄 rc2 要 --tier。"""
  3712	    import json as _json
  3713	    import io
  3714	    import contextlib
  3715	    path = env.vault.parent / ".canary-log.jsonl"
  3716	    rounds = []
  3717	    try:
  3718	        if path.exists():
  3719	            for line in path.read_text(encoding="utf-8").splitlines():
  3720	                line = line.strip()
  3721	                if not line:
  3722	                    continue
  3723	                try:
  3724	                    d = _json.loads(line)
  3725	                except ValueError:
  3726	                    continue
  3727	                if d.get("loop") == loop_id:
  3728	                    rounds.append(d)
  3729	    except OSError as e:
  3730	        print(f"ERROR: 讀 {path} 失敗: {e}", file=sys.stderr)
  3731	        return 2
  3732	    n_round = sum(1 for r in rounds if "round" in r)
  3733	    if rounds and n_round not in (0, len(rounds)):
  3734	        print("ERROR: canary-log round 欄混用(partial-mix)——帳損壞,同 status 拒讀", file=sys.stderr)
  3735	        return 2
  3736	    panel_fmt = n_round > 0
  3737	    if panel_fmt:   # 讀側損壞守衛不得因缺 --spec 提前 return 而繞過(code-loop r2 折入)
  3738	        seen, cur_rid = set(), None
  3739	        for r in rounds:
  3740	            rid = r["round"]
  3741	            if rid != cur_rid:
  3742	                if rid in seen:
  3743	                    print(f"ERROR: round-id {rid!r} 非連續重現(append-only 帳次序損壞)——同 status 拒讀",
  3744	                          file=sys.stderr)
  3745	                    return 2
  3746	                seen.add(rid)
  3747	                cur_rid = rid
  3748	    # ── tier 解析:定錨優先(v8);僅無定錨舊帳按格式推導;零記錄 rc2 ──
  3749	    anchor = next((r["tier"] for r in rounds if r.get("tier")), None)
  3750	    if tier and anchor and tier != anchor:
  3751	        print(f"ERROR: --tier {tier} 與帳面定錨 {anchor} 衝突(定錨優先;要換 tier 開新 loop id)", file=sys.stderr)
  3752	        return 2
  3753	    eff_tier = anchor or tier
  3754	    if eff_tier is None:
  3755	        if not rounds:
  3756	            print("ERROR: 零記錄 loop 需明示 --tier(不猜——猜錯模式撞混用守衛)", file=sys.stderr)
  3757	            return 2
  3758	        eff_tier = "standard" if panel_fmt else "legacy"   # 無定錨舊帳 fallback
  3759	    width, cap = _TIER_PARAMS[eff_tier]
  3760	    light = eff_tier == "light"
  3761	    # ── tier↔格式一致性(code-loop r1 折入:格式推導可被繞——high 漏帶 --round 會走鬆的 legacy 閘) ──
  3762	    if rounds:
  3763	        if eff_tier in ("standard", "high") and not panel_fmt:
  3764	            print(f"ERROR: tier={eff_tier} 要求 panel 格式(記錄帶 --round),帳面為 legacy 格式——"
  3765	                  "格式衝突(補 record 帶 --round,或 tier 錯誤則開新 loop id)", file=sys.stderr)
  3766	            return 2
  3767	        if light and panel_fmt:
  3768	            print("ERROR: tier=light 為單席 legacy 格式,帳面卻帶 --round(panel 格式)——格式衝突", file=sys.stderr)
  3769	            return 2
  3770	    rounds_count = len({r["round"] for r in rounds}) if panel_fmt else len(rounds)
  3771	    n_next = rounds_count + 1
  3772	
  3773	    def emit(phase, extra=None):
  3774	        out = {"phase": phase, "tier": eff_tier, "round": n_next, "width": width,
  3775	               "min_seats": width, "cap": cap, "advisory": "tier 由編排者宣告後定錨;lumos 只做映射與定錨讀取"}
  3776	        if phase == "plant-canary":
  3777	            if light or eff_tier == "legacy":
  3778	                out["canary_type"] = _CANARY_TYPES[(n_next - 1) % 4]
  3779	            else:
  3780	                out["canary_type"] = {f"slot{i}": _CANARY_TYPES[(i + n_next - 1) % 4]
  3781	                                      for i in range(1, width + 1)}
  3782	            rmode = "" if (light or eff_tier == "legacy") else f" --round r{n_next}"
  3783	            # ★`legacy` 不是可宣告值,不得吐進 record_cmd★(2026-08-04):`--tier` 的 choices
  3784	            # 只有 light/standard/high(LOOP_TIERS),legacy 純粹是「無定錨舊帳 + legacy 格式」
  3785	            # 的推導結果。原本這裡無條件吐 `--tier {eff_tier}`,legacy 下等於★發一條 argparse
  3786	            # 當場擋掉的指令★;而使用者最自然的修復是「把 --tier 拿掉再跑一次」——拿掉就記不上
  3787	            # 定錨,下一輪 next 又推成 legacy、又吐一條跑不動的指令。
  3788	            # ★這個 bug 自己維持自己★:2026-08 三個走循序的 loop(code-slim-python /
  3789	            # code-teardown-windows / code-slim-handoff)全數 tier=None,即此循環的產物;
  3790	            # 其中 code-slim-python 吃到 legacy 的 cap 6(standard 是 3)才被逼停。
  3791	            _tier_flag = f" --tier {eff_tier}" if eff_tier in LOOP_TIERS else ""
  3792	            out["record_cmd"] = (f"lumos canary record caught|missed --loop {loop_id}{rmode}"
  3793	                                 f" --auditor <席> --severity <s> --findings <M>"
  3794	                                 f" --spec <計劃節點.md> --reviewed <sha256>{_tier_flag}"
  3795	                                 f" --scope-lines <這輪審了幾行>")
  3796	            if eff_tier == "legacy":
  3797	                out["tier_hint"] = (
  3798	                    "★本 loop 無 tier 定錨,正在吃 legacy 判準(單席、cap 6——比 standard 的 cap 3 鬆)★。"
  3799	                    "legacy 不是可宣告值,★這個 loop 補標不了★:帳面已是 legacy 格式(記錄不帶 --round),"
  3800	                    "補 --tier standard|high 會被格式一致性當場擋掉(rc2)。"
  3801	                    "(--tier light 格式相容,但 cap=2 且帶 ratchet 語意,對已跑數輪的 loop 通常當場 cap-reached。)"
  3802	                    "要走分級判準請★開新 loop id,並在第一筆 record 就帶 --tier★。")
  3803	            # ★預防端:警告必須在派工「之前」★——記帳時才喊已經來不及(輪跑完了)。
  3804	            # loop next 是每輪第一步,所以量尺放這裡。
  3805	            out["scope_cap"] = (
  3806	                f"★派工前先量★ `wc -l <工作副本/patch>`:超過 {_CANARY_SCOPE_SOFT_CAP_LINES} 行"
  3807	                f"(≈30K token)就★拆開審★——切成多輪,或拆給多席各審一段。"
  3808	                "理由:審查員的任務是『在 N 行裡找出那個植入的錯』,而脈絡越長注意力越差是"
  3809	                "已發表的實測(退化在 32K token 就量得到)。"
  3810	                "★這條門檻純粹借自外部文獻——本專案自己跑過三次對照實驗都測不出規模效應,"
  3811	                "不得引用自家資料當佐證★(原本這裡寫「本專案資料落在線兩邊」,該宣稱已撤:"
  3812	                "兩組審的根本不是同一份碼;之後兩次刻意設計的實驗一次撞天花板 7/7、一次撞"
  3813	                "地板 0/6,見 Projects/規模影響判斷力假說)。"
  3814	                "超標不擋,但會在帳上標 scope_oversize、該輪 caught 視為弱證據。")
  3815	        # ★cluster 帳的選擇只有第一輪能做★(2026-08-02):模式由「第一個有效輪」定錨,之後
  3816	        # 要換只能開新 loop id。而 M2 落地至今 316 筆 canary 記錄裡★只有 1 筆帶 clusters★,
  3817	        # 且那一筆是開發它的 code-m2cluster 自己——34 個 panel loop 中有 33 個靜默落回
  3818	        # 無-cluster 舊帳。根因不是機制不好,是★沒有任何地方在該選的時候提起它★。
  3819	        # 只在 N=1 提(那是選擇真正還開著的唯一時刻),避免對已定錨的 loop 噴無效噪音。
  3820	        if phase == "plant-canary" and not light and eff_tier != "legacy" and n_next == 1:
  3821	            out["cluster_hint"] = (
  3822	                "★本 loop 第一輪——cluster 帳只有現在能選(模式由第一個有效輪定錨,之後要換只能開新 loop id)★:"
  3823	                "若預期 findings 會散成★性質不同★的風險群(例:「規格縮水」與「邊界 bug」),"
  3824	                "改用 `--clusters '名=resolved|accepted-minor:理由|disputed-major'` 逐群追蹤,"
  3825	                "gate 改判「無 disputed-major」——不把不同性質的問題壓成單一 max severity(一軸會遮蔽另一軸)。"
  3826	                "單一主題、findings 同性質的 loop 用預設(無-cluster)即可。")
  3827	        if extra:
  3828	            out.update(extra)
  3829	        if as_json:
  3830	            print(_json.dumps(out, ensure_ascii=False))
  3831	        else:
  3832	            print(f"[next] {loop_id}: phase={phase} tier={eff_tier} 下一輪 N={n_next}"
  3833	                  f" width={width} cap={cap}")
  3834	            for k in ("canary_type", "record_cmd", "scope_cap", "cluster_hint", "note"):
  3835	                if k in out:
  3836	                    print(f"  {k}: {out[k]}")
  3837	        return 0 if phase == "converged" else 1
  3838	
  3839	    # ⓪ escalate:light ratchet 永久態最先短路
  3840	    if light and any(r.get("kind") == "caught" and r.get("severity") in ("major", "blocker")
  3841	                     for r in rounds):
  3842	        return emit("escalate", {"note": "light ratchet 已觸發——停止本 loop,開新 panel loop id(原 id+-std 後綴)承接"})
  3843	    if not rounds:
  3844	        return emit("plant-canary")
  3845	    # ① gate-pending:判 converged 需 gate 結果,資訊不足絕不背書(先於 cap)
  3846	    if spec is None:
  3847	        return emit("gate-pending", {"note": "缺 --spec,gate 判定資訊不足——跑 loop status --gate 附完整參數自判"})
  3848	    # ② full-basis gate 委派(靜默跑既有謂詞,零新判定邏輯)
  3849	    buf = io.StringIO()
  3850	    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
  3851	        rc = cmd_loop_status(env, loop_id, need=(1 if light else need), gate=True,
  3852	                             spec=spec, repo=repo, panel=(panel_fmt and not light),
  3853	                             light=light, min_seats=width)   # 恆傳(light/legacy=1;code-loop r1 折入)
  3854	    if rc == 2:
  3855	        sys.stderr.write(buf.getvalue())
  3856	        return 2
  3857	    if rc == 0:
  3858	        return emit("converged", {"gate_basis": "full(G 合取+hash 委派既有謂詞全過)"})
  3859	    # ③ cap(資訊充分且未 PASS)
  3860	    if rounds_count >= cap:
  3861	        return emit("cap-reached", {"note": f"cap={cap} 到頂未收斂——停,攤給人裁(別無限燒)"})
  3862	    # ④ plant-canary
  3863	    return emit("plant-canary")
  3864	
  3865	
  3866	# ───────────── guard: 合約守衛 scaffold(對談驅動)─────────────
  3867	# lumos 只做機械活:① 列出 ★INVARIANT★ 綁定狀態 ② 套範本產 stub(預設紅燈) ③ 把 [test:] 綁回 KEY 行(自驗)。
  3868	# 「斷言本體」由 Claude 經對談向人確認意圖後填 — claim 的真來自人確認,不來自 code 反推
  3869	# (反推=套套邏輯=Check T 在打的偽證據)。範本是技術棧專屬、放專案 .lumos/guard-templates/<type>.tmpl,
  3870	# lumos 本體維持語言無關。
  3871	GUARD_TYPES = ("pure", "behavioral", "state")
  3872	GUARD_ICON = {"real": "✅ 已綁真方法", "dangling": "❌ 懸空(找不到方法)",
  3873	              "fake": "⚠ 偽證據(非測試方法)", "naked": "❌ 裸合約(未綁)"}
  3874	
  3875	
  3876	def _repo_root_from_env(env):
  3877	    for p in env.vault.parents:
  3878	        if p.name == "docs":
  3879	            return p.parent
  3880	    return env.vault.parent  # standalone vault root
  3881	
  3882	
  3883	def _platform_test_index(repo_root):
  3884	    """依 .lumos/config 建「平台 → (method set, code haystack)」的惰性索引 + 解析參數。
  3885	    多平台 discover 呼叫點(Check T / classify_invariants / cmd_archive)共用,避免各自重寫平台迴圈。
  3886	    回 (split, default, methods_for, hay_for):
  3887	    - split = multiplatform 時的 platforms dict、legacy 時 {}(→ resolve_test_refs 不切分);
  3888	    - default = default_platform;
  3889	    - methods_for(plat)/hay_for(plat) = 惰性(一次 CLI 內快取)取該平台 root+profile 的測試方法集/haystack
  3890	      (haystack 也跨 repo,修 r4:fake vs dangling 訊息品質)。"""
  5660	  pbody.scrollTop=0; panel.classList.add('open');
  5661	}
  5662	document.getElementById('close').onclick=clearSel;
  5663	
  5664	// ---- 搜尋:命中者高亮,其餘暗化 ----
  5665	const searchEl=document.getElementById('search');
  5666	searchEl.oninput=e=>{
  5667	  const q=e.target.value.trim().toLowerCase();
  5668	  hlN.clear(); hlL.clear(); sel=null;
  5669	  if(q) DATA.nodes.forEach(n=>{ if(n.label.toLowerCase().includes(q)) hlN.add(n); });
  5670	  refresh();
  5671	};
  5672	searchEl.onkeydown=e=>{
  5673	  if(e.key!=='Enter') return;
  5674	  const q=searchEl.value.trim().toLowerCase(); if(!q) return;
  5675	  // 最佳命中:前綴 > 包含;同級取重要度排名前者 → 直接飛過去開面板
  5676	  const hits=DATA.nodes.filter(n=>n.label.toLowerCase().includes(q));
  5677	  if(!hits.length) return;
  5678	  hits.sort((a,b)=>{
  5679	    const ap=a.label.toLowerCase().startsWith(q)?0:1, bp=b.label.toLowerCase().startsWith(q)?0:1;
  5680	    return ap-bp || a.lrank-b.lrank;
  5681	  });
  5682	  focusNode(hits[0]);
  5683	};
  5684	
  5685	// ---- type 過濾 chips ----
  5686	const tcw=document.getElementById('typechips');
  5687	types.forEach(t=>{
  5688	  const c=document.createElement('div');c.className='chip on';
  5689	  c.innerHTML='<span class="dot" style="background:'+tc(t)+'"></span>'+t;
  5690	  c.onclick=()=>{active.has(t)?active.delete(t):active.add(t);
  5691	    c.classList.toggle('on');c.classList.toggle('off');applyVis();};
  5692	  tcw.appendChild(c);
  5693	});
  5694	
  5695	// ---- stale 切換(預設 off=全部;on=只看 stale)----
  5696	const st=document.getElementById('staletoggle');st.classList.remove('on');st.classList.add('off');
  5697	st.onclick=()=>{staleOnly=!staleOnly;st.classList.toggle('on');st.classList.toggle('off');applyVis();};
  5698	
  5699	// ---- 只看合約(合約節點+其守衛驗證) ----
  5700	const iv=document.getElementById('invtoggle');iv.classList.remove('on');iv.classList.add('off');
  5701	iv.onclick=()=>{invOnly=!invOnly;iv.classList.toggle('on');iv.classList.toggle('off');applyVis();};
  5702	
  5703	// ---- 驗證摺疊(預設開;關=全部攤開) ----
  5704	const vf=document.getElementById('vfold');
  5705	vf.onclick=()=>{vFold=!vFold;vf.classList.toggle('on');vf.classList.toggle('off');applyVis();};
  5706	
  5707	// ---- 2D/3D 切換:壓平力場+鎖旋轉(工作模式),還原=3D 展示模式 ----
  5708	const d2=document.getElementById('dim2d');d2.classList.remove('on');d2.classList.add('off');
  5709	let is2d=false;
  5710	d2.onclick=()=>{
  5711	  is2d=!is2d;d2.classList.toggle('on');d2.classList.toggle('off');
  5712	  Graph.numDimensions(is2d?2:3);
  5713	  const ctl=Graph.controls(); if(ctl) ctl.enableRotate=!is2d;
  5714	  if(is2d) Graph.cameraPosition({x:0,y:0,z:900},{x:0,y:0,z:0},800);
  5715	};
  5716	
  5717	// ---- 時間軸:按節點日期回放架構圖生長 ----
  5718	const tt=document.getElementById('timetoggle');tt.classList.remove('on');tt.classList.add('off');
  5719	const tb=document.getElementById('timebar'),tr=document.getElementById('trange'),
  5720	      td=document.getElementById('tdate'),tp=document.getElementById('tplay');
  5721	const dates=[...new Set(DATA.nodes.map(n=>n.dnum).filter(d=>d>0))].sort((a,b)=>a-b);
  5722	let playTimer=null;
  5723	function fmtd(d){const s=String(d);return s.slice(0,4)+'-'+s.slice(4,6)+'-'+s.slice(6,8);}
  5724	function setCut(i){
  5725	  timeCut=dates[i]; td.textContent=fmtd(timeCut);
  5726	  if(i>=dates.length-1){ timeCut=null; td.textContent='現在(全量)'; }
  5727	  applyVis();
  5728	}
  5729	if(dates.length){ tr.max=dates.length-1; tr.value=dates.length-1; td.textContent='現在(全量)'; }
  5730	else { tt.style.opacity=.35; tt.style.pointerEvents='none'; tt.title='無日期資料'; }   // 空集停用(codex r1)
  5731	tt.onclick=()=>{
  5732	  tt.classList.toggle('on');tt.classList.toggle('off');
  5733	  const showing=tb.classList.toggle('show');
  5734	  if(!showing){ timeCut=null; if(playTimer){clearInterval(playTimer);playTimer=null;tp.textContent='▶';} applyVis(); }
  5735	};
  5736	tr.oninput=()=>setCut(+tr.value);
  5737	tp.onclick=()=>{
  5738	  if(playTimer){ clearInterval(playTimer); playTimer=null; tp.textContent='▶'; return; }
  5739	  tp.textContent='⏸'; let i=(+tr.value>=dates.length-1)?0:+tr.value;
  5740	  tr.value=i; setCut(i);
  5741	  playTimer=setInterval(()=>{
  5742	    i++; if(i>=dates.length){ clearInterval(playTimer); playTimer=null; tp.textContent='▶'; return; }
  5743	    tr.value=i; setCut(i);
  5744	  }, 380);
  5745	};
  5746	
  5747	// ---- legend ----
  5748	document.getElementById('legend').innerHTML='<div class="lt">Legend</div>'+
  5749	  Object.entries(TYPE_COLOR).map(([t,c])=>'<div class="row"><span class="sw" style="background:'+c+';color:'+c+'"></span>'+t+'</div>').join('')
  5750	  +'<div class="row"><span class="sw" style="background:'+GOLD+';color:'+GOLD+'"></span>★ 合約 invariant</div>'
  5751	  +'<div class="row"><span class="sw" style="background:'+STALE+';color:'+STALE+'"></span>stale(腐爛)</div>'
  5752	  +'<div class="row"><span class="ed" style="border-color:#b98cff"></span>plan_refs(粒子流)</div>'
  5753	  +'<div class="row"><span class="ed" style="border-color:#4fd6a8"></span>verified_by</div>';
  5754	setTimeout(()=>{const h=document.getElementById('hint');if(h)h.style.opacity=0;},7000);
  5755	</script>
  5756	</body>
  5757	</html>"""
  5758	
  5759	
  5760	def _html_model(env):
  5761	    """蒐集語意模型給 HTML 視圖:nodes(含 type/status/合約/stale/raw)+ typed edges。"""
  5762	    out_e, in_e = env.edges
  5763	    nodes, edges, seen = [], [], set()
  5764	    for rel, n in env.notes.items():
  5765	        inv, debt = extract_contracts(n)
  5766	        summ = n.fields.get("summary")
  5767	        summ = summ if isinstance(summ, str) else ""
  5768	        status = status_of(env, rel)
  5769	        ntype = n.fields.get("type")
  5770	        ntype = ntype if isinstance(ntype, str) and ntype else rel.split("/")[0].lower()
  5771	        try:
  5772	            raw = (env.vault / rel).read_text(encoding="utf-8-sig")
  5773	        except Exception:
  5774	            raw = ""
  5775	        _dt = n.fields.get("date") or n.fields.get("created")
  5776	        nodes.append({
  5777	            "id": rel, "label": n.stem, "rel": rel, "type": ntype, "status": status,
  5778	            "folder": rel.split("/")[0], "inv": inv, "debt": debt,
  5779	            "date": str(_dt) if _dt else "",
  5780	            "indeg": len(set(in_e.get(rel, []))),
  5781	            "summary": [l.strip() for l in summ.split("\n") if l.strip()][:6],
  5782	            "raw": raw,
  5783	        })
  5784	    # typed edges: plan_refs / verified_by / link
  5785	    for rel, n in env.notes.items():
  5786	        plan = {env.resolve(link_target(x)) for x in as_list(n.fields.get("plan_refs"))}
  5787	        verify = {env.resolve(link_target(x)) for x in as_list(n.fields.get("verified_by"))}
  5788	        plan.discard(None); verify.discard(None)
  5789	        for d in set(out_e.get(rel, [])):
  5790	            kind = "plan" if d in plan else "verify" if d in verify else "link"
  5791	            key = (rel, d, kind)
  5792	            if key not in seen:
  5793	                seen.add(key)
  5794	                edges.append({"source": rel, "target": d, "kind": kind})
  5795	    return {"nodes": nodes, "edges": edges}
  5796	
  5797	
  5798	_VIZ_LIBS = {
  5799	    "3d-force-graph": ("https://cdn.jsdelivr.net/npm/3d-force-graph",
  5800	                       '<script src="https://cdn.jsdelivr.net/npm/3d-force-graph"></script>'),
  5801	    "marked": ("https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js",
  5802	               '<script src="https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js"></script>'),
  5803	}
  5804	_FONT_LINKS = ('<link rel="preconnect" href="https://fonts.googleapis.com">\n'
  5805	               '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
  5806	               '<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">')
  5807	
  5808	
  5809	def _fetch_text(url, cache):
  5810	    """下載文字資源並快取(scripts/vendor/)。離線重複 export 不再抓。
  5811	    用 curl(走系統憑證;macOS python urllib 常無 cert store 致 SSL verify 失敗)。"""
  5812	    import subprocess
  5813	    if cache.exists():
  5814	        return cache.read_text(encoding="utf-8")
  5815	    cache.parent.mkdir(parents=True, exist_ok=True)
  5816	    txt = subprocess.run(["curl", "-fsSL", url], capture_output=True, text=True,
  5817	                         timeout=60, check=True).stdout
  5818	    if not txt:
  5819	        raise RuntimeError("空回應")
  5820	    cache.write_text(txt, encoding="utf-8")
  5821	    return txt
  5822	
  5823	
  5824	def cmd_export_html(env, out_path, standalone=False):
  5825	    import json
  5826	    import datetime
  5827	    model = _html_model(env)
  5828	    # </script> 在嵌入 JSON 裡會提早關閉 <script> 標籤破壞整頁 → 轉義 </(標準作法)
  5829	    data = json.dumps(model, ensure_ascii=False).replace("</", "<\\/")
  5830	    stamp = datetime.date.today().isoformat()
  5831	    html = _HTML_TEMPLATE.replace("__DATA__", data).replace("__STAMP__", stamp) \
  5832	                         .replace("__VAULT__", env.vault.name) \
  5833	                         .replace("__NC__", str(len(model["nodes"]))) \
  5834	                         .replace("__EC__", str(len(model["edges"])))
  5835	    if standalone:
  5836	        # inline cytoscape/marked(去 CDN,防火牆/離線可開);字體退化系統字(移除 google link)
  5837	        vendor = Path(__file__).resolve().parent / "vendor"
  5838	        for name, (url, tag) in _VIZ_LIBS.items():
  5839	            try:
  5840	                src = _fetch_text(url, vendor / f"{name}.min.js").replace("</script", "<\\/script")
  5841	            except Exception as e:
  5842	                print(f"ERROR: --standalone 需抓 {name}(此機需一次網路): {e}", file=sys.stderr)
  5843	                return 2
  5844	            html = html.replace(tag, f"<script>{src}</script>")
  5845	        html = html.replace(_FONT_LINKS, "<!-- standalone: 字體退化系統字(無外部 CDN) -->")
  5846	    Path(out_path).write_text(html, encoding="utf-8")
  5847	    mode = "standalone(自包含/離線可開)" if standalone else "CDN"
  5848	    print(f"✓ export html [{mode}]: {out_path}  ({len(model['nodes'])} 節點 / {len(model['edges'])} 邊)")
  5849	    return 0
  5850	
  5851	
  5852	# ═══════════════════════ 階段三: 寫側 T1(行級手術) ═══════════════════════
  5853	
  5854	SCALAR_KEYS = {"status", "updated", "created", "type", "self_audit", "signed_off", "regen"}
  5855	LIST_KEYS = {"verified_by", "plan_refs", "related", "tags"}
  5856	DATE_KEYS = {"updated", "created", "date", "decided", "ended"}
  5857	DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
  5858	
  5859	
  5860	def fm_structure(fm_lines):
  5861	    """回傳 ordered [(key, start, end, kind)]，kind ∈ scalar/list/block。
  5862	    end = 該 key 區塊最後一行的 index(含)。"""
  5863	    out = []
  5864	    i, n = 0, len(fm_lines)
  5865	    while i < n:
  5866	        m = TOP_KEY_RE.match(fm_lines[i])
  5867	        if not m:
  5868	            i += 1
  5869	            continue
  5870	        key, val = m.group(1), m.group(2).strip()
  5871	        start = i
  5872	        if val in ("|", "|-", ">", ">-"):
  5873	            i += 1
  5874	            while i < n and (fm_lines[i].startswith("  ") or not fm_lines[i].strip()):
  5875	                i += 1
  5876	            out.append((key, start, i - 1, "block"))
  5877	        elif val == "":
  5878	            # 消費所有縮排行(含 list item 的 sub-mapping,如 decisions 的 content/decided),
  5879	            # 與 parse_frontmatter 一致 → fm_structure 算出的 end 涵蓋整個區塊(BUG-5 對齊)
  5880	            i += 1
  5881	            while i < n and (fm_lines[i].startswith(" ") or not fm_lines[i].strip()):
  5882	                i += 1
  5883	            out.append((key, start, i - 1, "list"))
  5884	        else:
  5885	            out.append((key, start, start, "scalar"))
  5886	            i += 1
  5887	    return out
  5888	
  5889	
  5890	def fmt_scalar(key, value):
  5891	    """純量值格式化。日期 bare(不加引號避污染指紋);含 ': ' 或特殊字元才引號。"""
  5892	    v = value.strip()
  5893	    if key in DATE_KEYS:
  5894	        if not DATE_RE.match(v):
  5895	            raise ValueError(f"{key} 需 YYYY-MM-DD,得到: {v}")
  5896	        return v  # bare,絕不加引號
  5897	    # YAML 型別劫持守衛: true/false/null/yes/no/~ 與純數字當 status 會被解析成 bool/num/null
  5898	    if v.lower() in ("true", "false", "null", "yes", "no", "on", "off", "~") or \
  5899	       re.fullmatch(r"-?\d+(\.\d+)?", v):
  5900	        return '"' + v + '"'
  5901	    if re.search(r":\s|^[\[\{>|*&!#@`]|^\s|\s$", v) or v == "":
  5902	        return '"' + v.replace('"', '\\"') + '"'
  5903	    return v
  5904	
  5905	
  5906	def fmt_list_item(value):
  5907	    """list 項格式化。wikilink / 含特殊字元 → 引號(鐵則1 安全:一項一行)。"""
  5908	    v = value.strip()
  5909	    if v.startswith("[[") or re.search(r":\s|^[\[\{]", v):
  5910	        return '"' + v.replace('"', '\\"') + '"'
  5911	    return v
  5912	
  5913	
  5914	def edit_fm_scalar(fm_lines, key, value):
  5915	    fm = list(fm_lines)
  5916	    formatted = fmt_scalar(key, value)
  5917	    struct = {k: (s, e, kind) for k, s, e, kind in fm_structure(fm)}
  5918	    if key in struct:
  5919	        s, e, kind = struct[key]
  5920	        if kind != "scalar":
  5921	            raise ValueError(f"{key} 是 {kind} 型,set 只改純量(list 用 append,巢狀用 T3)")
  5922	        fm[s] = f"{key}: {formatted}"
  5923	    else:
  5924	        # 插在開頭純量區之後(第一個 list/block key 之前,否則末尾)
  5925	        ins = len(fm)
  5926	        for k, s, e, kind in fm_structure(fm):
  5927	            if kind in ("list", "block"):
  5928	                ins = s
  5929	                break
  5930	        fm.insert(ins, f"{key}: {formatted}")
  5931	    return fm
  5932	
  5933	
  5934	def edit_fm_sync_status_tag(fm_lines, status):
  5935	    """set status 的反正規化同步:tags 內既有 status/* 項就地改寫為 status/<新值>。
  5936	    無 tags/無 status/* 標籤則不動(純同步不發明;繞過本路徑的寫入由 lint/doctor
  5937	    漂移守衛兜底)。回傳 (new_fm, tags 內有無 status/* 標籤)。"""
  5938	    fm = list(fm_lines)
  5939	    struct = {k: (s, e, kind) for k, s, e, kind in fm_structure(fm)}
  5940	    if "tags" not in struct or struct["tags"][2] != "list":
  5941	        return fm, False
  5942	    s, e, _kind = struct["tags"]
  5943	    found = False
  5944	    for i in range(s + 1, e + 1):
  5945	        m = re.match(r"^(\s*-\s*)status/\S+\s*$", fm[i])
  5946	        if m:
  5947	            fm[i] = f"{m.group(1)}status/{status}"
  5948	            found = True
  5949	    return fm, found
  5950	
  5951	
  5952	def edit_fm_append(fm_lines, key, value):
  5953	    fm = list(fm_lines)
  5954	    item = fmt_list_item(value)
  5955	    tgt = link_target(value)
  5956	    struct = {k: (s, e, kind) for k, s, e, kind in fm_structure(fm)}
  5957	    if key in struct:
  5958	        s, e, kind = struct[key]
  5959	        if kind != "list":
  5960	            raise ValueError(f"{key} 是 {kind} 型,append 只加 list 項")
  5961	        # dedup: 精確 full-target 比對(保留路徑;非子字串、非 basename-only)
  5962	        for j in range(s + 1, e + 1):
  5963	            existing = fm[j].strip()
  5964	            if existing.startswith("-") and link_target(existing[1:]) == tgt:
  5965	                return fm  # 已存在,no-op
  5966	        # 偵測現有項縮排,否則預設 2 空格
  5967	        indent = "  "
  5968	        for j in range(s + 1, e + 1):
  5969	            if fm[j].lstrip().startswith("-"):
  5970	                indent = fm[j][:len(fm[j]) - len(fm[j].lstrip())]
  5971	                break
  5972	        # 插在最後一個非空行之後(避開區塊尾部空行,免在 list 中插出空行)
  5973	        last = e
  5974	        while last > s and not fm[last].strip():
  5975	            last -= 1
  5976	        fm.insert(last + 1, f"{indent}- {item}")
  5977	    else:
  5978	        ins = len(fm)
  5979	        fm.insert(ins, key + ":")
  5980	        fm.insert(ins + 1, f"  - {item}")
  5981	    return fm
  5982	
  5983	
  5984	def decisions_items(fm_lines):
  5985	    """surgical 定位 decisions[] 的每個項目行範圍(不重序列化,延伸 T1 到巢狀)。
  5986	    回傳 (block_start, block_end, [(item_start, item_end)], item_indent, sub_indent)
  5987	    或 None(無 decisions)。item_end 含,已去尾部空行。處理項目內含 nested 子清單。"""
  5988	    block = None
  5989	    for k, s, e, kind in fm_structure(fm_lines):
  5990	        if k == "decisions" and kind == "list":
  5991	            block = (s, e)
  5992	            break
  5993	    if block is None:
  5994	        return None
  5995	    s, e = block
  5996	    item_indent = None
  5997	    starts = []
  5998	    for i in range(s + 1, e + 1):
  5999	        ln = fm_lines[i]
  6000	        if not ln.strip():
  6001	            continue
  6002	        m = re.match(r"^(\s*)-\s", ln)
  6003	        if m:
  6004	            ind = len(m.group(1))
  6005	            if item_indent is None:
  6006	                item_indent = ind
  6007	            if ind == item_indent:  # 只認最淺層 dash(子清單的 dash 更深,不算項目)
  6008	                starts.append(i)
  6009	    items = []
  6010	    for idx, st in enumerate(starts):
  6011	        en = (starts[idx + 1] - 1) if idx + 1 < len(starts) else e
  6012	        while en > st and not fm_lines[en].strip():
  6013	            en -= 1
  6014	        items.append((st, en))
  6015	    sub_indent = (item_indent + 2) if item_indent is not None else 4
  6016	    return s, e, items, (item_indent or 2), sub_indent
  6017	
  6018	
  6019	def load_raw_for_edit(path: Path):
  6020	    """讀 raw,拒 BOM/CRLF(本 vault 慣例 LF/no-BOM,異常不靜默正規化)。
  6021	    回傳 (all_lines, fm_start, fm_end_exclusive)。fm = all_lines[1:fm_end]。"""
  6022	    raw = path.read_bytes()
  6023	    if raw.startswith(b"\xef\xbb\xbf"):
  6024	        raise ValueError("T1 不寫 BOM 檔(慣例外),請用 obsidian CLI / 先正規化")
  6025	    if b"\r\n" in raw:
  6026	        raise ValueError("此檔是 CRLF(慣例要求 LF)。Windows 常見=git autocrlf;"
  6027	                         "修:確認 .gitattributes 已套用(vault 標 eol=lf)+ `git add --renormalize .`,"
  6028	                         "或單檔 `dos2unix`。lumos 不靜默改行尾。")
  6029	    lines = raw.decode("utf-8").split("\n")
  6030	    if not lines or lines[0].strip() != "---":
  6031	        raise ValueError("無 frontmatter,T1 不處理")
  6032	    fm_end = None
  6033	    for i in range(1, len(lines)):
  6034	        if lines[i].strip() == "---":
  6035	            fm_end = i
  6036	            break
  6037	    if fm_end is None:
  6038	        raise ValueError("frontmatter 未閉合")
  6039	    return lines, 1, fm_end
  6040	
  6041	
  6042	def _write_lf(path: Path, text: str):
  6043	    """寫 UTF-8 / LF / no-BOM,平台無關(不靠 text mode)。vault 唯一寫入原語。
  6044	    用 write_bytes:write_text(newline=) 要 Python 3.10,違反本專案 ≥3.8。"""
  6045	    path.write_bytes(text.encode("utf-8"))
  6046	
  6047	
  6048	def atomic_write_verify(path: Path, new_lines, key, expected_check):
  6049	    """寫 tmp → re-parse 自驗 + lint 無新指紋 → atomic rename。任一步敗:tmp 丟棄,原檔不動。"""
  6050	    orig_fm = load_raw_for_edit(path)
  6051	    orig_lint = set(parse_frontmatter(orig_fm[0][1:orig_fm[2]])[2])
  6052	    text = "\n".join(new_lines)
  6053	    new_fm_lines = new_lines[1:]
  6054	    for i in range(1, len(new_lines)):
  6055	        if new_lines[i].strip() == "---":
  6056	            new_fm_lines = new_lines[1:i]
  6057	            break
  6058	    fields, _, new_lint = parse_frontmatter(new_fm_lines)
  6059	    if not expected_check(fields):
  6060	        raise RuntimeError(f"自驗失敗:{key} 寫入後值不符預期")
  6061	    introduced = set(new_lint) - orig_lint
  6062	    if introduced:
  6063	        raise RuntimeError("自驗失敗:引入新 frontmatter 指紋:" + "; ".join(sorted(introduced)))
  6064	    import os
  6065	    tmp = path.with_suffix(path.suffix + ".lumos-tmp")
  6066	    try:
  6067	        _write_lf(tmp, text)
  6068	        os.replace(tmp, path)
  6069	    finally:
  6070	        if tmp.exists():
  6071	            tmp.unlink()
  6072	
  6073	
  6074	def cmd_set(env, rel, key, value):
  6075	    if key not in SCALAR_KEYS:
  6076	        print(f"ERROR: set 白名單={sorted(SCALAR_KEYS)};{key} 不在內"
  6077	              f"(list 用 append;decisions 翻盤/新增用 decision-supersede / decision-add)", file=sys.stderr)
  6078	        return 2
  6079	    path = env.vault / rel
  6080	    lines, s, e = load_raw_for_edit(path)
  6081	    new_fm = edit_fm_scalar(lines[1:e], key, value)
  6082	    exp = fmt_scalar(key, value)
  6083	    exp_val = strip_quotes(exp)
  6084	    tag_synced = False
  6085	    if key == "status":
  6086	        new_fm, tag_synced = edit_fm_sync_status_tag(new_fm, exp_val)
  6087	    new_lines = lines[:1] + new_fm + lines[e:]
  6088	
  6089	    def _check(f):
  6090	        if str(f.get(key, "")) != exp_val:
  6091	            return False
  6092	        if tag_synced:
  6093	            want = f"status/{exp_val}"
  6094	            tags = [t for t in as_list(f.get("tags")) if isinstance(t, str)]
  6095	            return want in tags and all(t == want for t in tags if t.startswith("status/"))
  6096	        return True
  6097	
  6098	    atomic_write_verify(path, new_lines, key, _check)
  6099	    print(f"✓ set {rel}: {key} = {exp}" + (";tags 的 status/* 已同步" if tag_synced else ""))
  6100	    return 0
  6101	
  6102	
  6103	def cmd_self_audit(env, rel, model="sonnet", date=None):
  6104	    """L4 自足性審計留痕:寫 self_audit: <model>/<date> 到節點 frontmatter。
  6105	    語意:這整篇節點的「自足性」(無主對話脈絡的乾淨 agent 只讀架構圖能不能還原
  6106	    專案現況)已由一個獨立 agent 審過並通過。對應 guard audit 的角色(乾淨 agent
  6107	    審後蓋戳),但程式路徑獨立——這是節點級戳記,guard audit 是行級 [audit:]。
  6108	    工具只記留痕,不證明審計真乾淨——派 agent 的乾淨脈絡/中立 prompt 靠主對話誠實。"""
  6109	    import datetime
  6110	    if date is None:
  6111	        date = datetime.date.today().isoformat()
  6112	    else:
  6113	        try:
  6114	            datetime.date.fromisoformat(date)
  6115	        except ValueError:
  6116	            print(f"ERROR: --date 須為 YYYY-MM-DD:{date!r}", file=sys.stderr)
  6117	            return 2
  6118	    return cmd_set(env, rel, "self_audit", f"{model}/{date}")
  6119	
  6120	
  6121	def cmd_append(env, rel, key, value):
  6122	    if key not in LIST_KEYS:
  6123	        print(f"ERROR: append 白名單={sorted(LIST_KEYS)};{key} 不在內", file=sys.stderr)
  6124	        return 2
  6125	    path = env.vault / rel
  6126	    lines, s, e = load_raw_for_edit(path)
  6127	    new_fm = edit_fm_append(lines[1:e], key, value)
  6128	    new_lines = lines[:1] + new_fm + lines[e:]
  6129	    tgt = link_target(value)
  6130	    atomic_write_verify(path, new_lines, key,
  6131	                        lambda f: any(link_target(x) == tgt for x in as_list(f.get(key))))
  6132	    print(f"✓ append {rel}: {key} += {value}")
  6133	    return 0
  6134	
  6135	
  6136	def _fm_of(all_lines):
  6137	    """從完整檔行抽 frontmatter 行(供 decision 自驗用 parse_decisions 重解)。"""
  6138	    for i in range(1, len(all_lines)):
  6139	        if all_lines[i].strip() == "---":
  6140	            return all_lines[1:i]
  6141	    return all_lines[1:]
  6142	
  6143	
  6144	def _fmt_decision_value(v):
  6145	    """decision 子欄位值格式化(含 ': ' 或特殊字元 → 引號,避鐵則 3)。"""
  6146	    v = v.strip()
  6147	    if re.search(r":\s|^[\[\{>|*&!#@`\"']|^\s|\s$", v) or v == "":
  6148	        return '"' + v.replace('"', '\\"') + '"'
  6149	    return v
  6150	
  6151	
  6152	def cmd_decision_supersede(env, rel, match, by, ended=None):
  6153	    """T3 巢狀手術:把 decisions[] 中 content 含 match 的決策標 valid:false + 補
  6154	    superseded_by/ended。surgical line-based(不重序列化,最小 diff;優於 ruamel reflow)。
  6155	    [P1]:ended 缺則自動補今日 + 同步 bump 頂層 updated(單次 atomic,供 E2 時序法)。"""
  6156	    import datetime
  6157	    if ended and not DATE_RE.match(ended):
  6158	        raise ValueError(f"--ended 需 YYYY-MM-DD,得到: {ended}")
  6159	    path = env.vault / rel
  6160	    lines, s_fm, e_fm = load_raw_for_edit(path)
  6161	    fm = lines[1:e_fm]
  6162	    loc = decisions_items(fm)
  6163	    if loc is None:
  6164	        raise ValueError("此筆記無 decisions")
  6165	    if not loc[2]:  # block 存在但解析不到項目(Bug2:0-indent / 非標準縮排)
  6166	        raise ValueError("decisions 區塊解析不到項目(本工具要求 2-space 縮排,不支援 0-indent/tab)")
  6167	    _, _, items, _, sub = loc
  6168	    pad = " " * sub
  6169	    needle = nfc(match)
  6170	    id_mode = re.fullmatch(r"#d\d+", match.strip())
  6171	    if id_mode:
  6172	        # [M1/R12] #dN 精確定址:比對項內 id 行
  6173	        want = match.strip()[1:]
  6174	        hits = [(st, en) for (st, en) in items
  6175	                if any(re.match(rf"^{pad}id:\s*{re.escape(want)}\s*$", fm[i])
  6176	                       for i in range(st, en + 1))]
  6177	        if not hits:
  6178	            raise ValueError(f"以 {match} 定址查無決策——該節點決策可能尚無 id,先跑 lumos decision-reindex {rel}")
  6179	    else:
  6180	        hits = [(st, en) for (st, en) in items
  6181	                if needle in nfc("\n".join(fm[st:en + 1]))]
  6182	        if not hits:
  6183	            raise ValueError(f"找不到 content 含「{match}」的決策")
  6184	        if len(hits) > 1:
  6185	            # [M1/R12] 選擇端唯一命中:first-match 會「先改錯項、再用錯項 id 精確驗證它改成功」
  6186	            cands = "; ".join(first_line(fm[st].split("content:", 1)[-1].strip(), 40)
  6187	                              for (st, _) in hits[:5])
  6188	            raise ValueError(f"「{match}」命中 {len(hits)} 條決策,拒絕 first-match(防改錯項)。"
  6189	                             f"候選: {cands} …改用更長子字串或 --match \"#dN\" 精確定址")
  6190	    st, en = hits[0]
  6191	    valid_line = None
  6192	    for i in range(st, en + 1):
  6193	        if re.match(rf"^{pad}valid:\s", fm[i]):   # 只認精確 sub_indent(Bug5:移除過寬 fallback,免誤命中子清單)
  6194	            valid_line = i
  6195	            break
  6196	    if valid_line is None:
  6197	        raise ValueError("該決策無 valid 欄位(或縮排非標準 2-space),T3 不自動 supersede(請手動 / 確認結構)")
  6198	    # Bug3: 已 superseded 不重插(免重複鍵)。同 sub_indent 已有 superseded_by → 拒
  6199	    for i in range(st, en + 1):
  6200	        if re.match(rf"^{pad}superseded_by:\s", fm[i]):
  6201	            raise ValueError("該決策已有 superseded_by(已翻盤過),不重複 supersede;要改取代者請手動編輯")
  6202	    fm[valid_line] = f"{pad}valid: false"
  6203	    # [P1] ended 選填 → 缺則自動補今日(E2 時序法要 ended 才判得了「鄰居晚於翻案沒?」)
  6204	    if not ended:
  6205	        ended = datetime.date.today().isoformat()
  6206	    ins = [f"{pad}superseded_by: {_fmt_decision_value(by)}", f"{pad}ended: {ended}"]
  6207	    fm[valid_line + 1:valid_line + 1] = ins
  6208	    # [P1] supersede = 對本節點的實質編輯 → 同步 bump 頂層 updated(單次 atomic,同一份 fm;
  6209	    #   不串第二個寫命令避免半完成)。有則就地換、無則插在 decisions: 前(不動決策區索引)。
  6210	    today = datetime.date.today().isoformat()
  6211	    upd_i = next((k for k, ln in enumerate(fm) if re.match(r"^updated:\s", ln)), None)
  6212	    if upd_i is not None:
  6213	        fm[upd_i] = f"updated: {today}"
  6214	    else:
  6215	        dec_i = next((k for k, ln in enumerate(fm) if re.match(r"^decisions:\s*$", ln)), len(fm))
  6216	        fm[dec_i:dec_i] = [f"updated: {today}"]
  6217	    new_lines = lines[:1] + fm + lines[e_fm:]
  6218	    # [M1/P2] 讀 target 的 id → 組全域格式 <rel>#d<N> 回傳(下游 header/CASCADE/--from 同格式,無裸碼流出)
  6219	    did = None
  6220	    for i in range(st, en + 1):
     136 /tmp/dlrd-r1.md
     334 docs/.canary-log.jsonl
     470 total
{"ts": "2026-06-30T17:41:04+08:00", "kind": "caught", "auditor": "sonnet", "token": "CANARY-b84c9700", "note": "r1 type=a caught(§repo_root解析節懸空引用抓到);辯方三 major→minor:F2 silent-pass誤(正向斷言會FAIL)、F3 FENCE_RE既有慣例必沿用、F4 純措辭誤植;存活全minor:F2測試建scripts/、F3剝fenced、F4措辭、F5 line輸出、F6 repo_root沿用CheckC、F7排隱藏夾、F8 Check2正名", "loop": "doctor-stale-file-claim", "severity": "minor"}
{"ts": "2026-06-30T17:53:00+08:00", "kind": "caught", "auditor": "sonnet", "token": "CANARY-f04fdaeb", "note": "r2 type=b caught(--skip-stale-claim未定義旗標抓到);辯方 M2 major→minor(實測故障鏈講反:反引號頭尾殘留→rule3全擋→全偽陰性靜默,非全偽陽性;且測試案例1正向斷言會FAIL接住);存活全minor:M2剝定界符、m3慣例措辭+行號40、m4縮排fence、m5無行號輸出格式、m6 read_text引用", "loop": "doctor-stale-file-claim", "severity": "minor"}
{"ts": "2026-08-04T11:48:17+08:00", "kind": "missed", "auditor": "slot4-整合", "token": "CANARY-be4ddeb7", "note": "r1 type=a(第十四節) MISSED;交 blocker 但漏抓餌 → findings 全不折", "loop": "design-loop判準重定位", "round": "r1", "severity": "blocker", "findings": 0, "result_sha256": "3ca0b2a874830f129c049bdfd5be22e976dbe988678446c4802d49b4333cb64d", "reviewed_sha256": "3ca0b2a874830f129c049bdfd5be22e976dbe988678446c4802d49b4333cb64d", "scope_lines": 365, "tier": "high"}
{"ts": "2026-08-04T11:48:17+08:00", "kind": "missed", "auditor": "slot5-Codex跨家族", "token": "CANARY-cc63c629", "note": "r1 type=b(--legacy-scoring) MISSED;交 blocker 但漏抓餌 → findings 全不折", "loop": "design-loop判準重定位", "round": "r1", "severity": "blocker", "findings": 0, "result_sha256": "3ca0b2a874830f129c049bdfd5be22e976dbe988678446c4802d49b4333cb64d", "reviewed_sha256": "3ca0b2a874830f129c049bdfd5be22e976dbe988678446c4802d49b4333cb64d", "scope_lines": 365, "tier": "high"}

nl -ba scripts/lumos | sed -n '2898,3130p'
nl -ba scripts/lumos | sed -n '3170,3240p'
nl -ba scripts/lumos | sed -n '3680,3865p'
rg -n 'CiteCheck|IBIR|FLAWS|Prolific|ACM|gold|fault seeding|citation' /tmp/dlrd-r1.md docs/lumos-toolchain-knowledge governance | head -160" in /Users/enzo/harness/lumos-toolchain
  2638	        print(f"  對抗層增量帳(折入=測試綠後仍被抓;長期趨零=機關裝飾該砍): "
  2639	              f"折入 {fold_total} 筆缺陷 [{sev_s}] | 依審計員: {aud_s} {legacy_s}".rstrip())
  2640	    print(f"\n{len(ded)} 筆(近 {since_days} 天)")
  2641	    return 0
  2642	
  2643	
  2644	CLUSTER_STATES = ("resolved", "accepted-minor", "disputed-major")
  2645	
  2646	
  2647	def _parse_clusters(raw):
  2648	    """M2 risk-cluster 寫側解析:--clusters '名=狀態,...' → (dict{名:狀態}, None) 或 (None, 錯誤訊息)。
  2649	    三態白名單;accepted-minor 需冒號內嵌理由(整筆單一 note 對多 accepted-minor 無法對應=模糊過帳);
  2650	    尾逗號空段靜默過濾,但過濾後空列表=rc2(帶旗標即須有效內容,無「空字串=未帶」特例);
  2651	    設計:Projects/design-loop提效_計劃 M2(golden: governance/golden/dloop-m2-cluster)。"""
  2652	    parts = [p.strip() for p in str(raw).split(",") if p.strip()]
  2653	    if not parts:
  2654	        return None, "帶了 --clusters 但無有效內容(空字串/全逗號)"
  2655	    out = {}
  2656	    for p in parts:
  2657	        if "=" not in p:
  2658	            return None, f"段缺 '='(格式 名=狀態): {p!r}"
  2659	        name, state = p.split("=", 1)
  2660	        name, state = name.strip(), state.strip()
  2661	        if not re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,63}", name):
  2662	            return None, f"cluster 名非法(kebab 短 slug:小寫英數起頭+[-_],≤64): {name!r}"
  2663	        base = state.split(":", 1)[0]
  2664	        if base not in CLUSTER_STATES:
  2665	            return None, f"狀態 {base!r} 不在白名單 {'/'.join(CLUSTER_STATES)}"
  2666	        if base == "accepted-minor":
  2667	            if ":" not in state or not state.split(":", 1)[1].strip():
  2668	                return None, f"accepted-minor 需逐 cluster 內嵌理由(accepted-minor:理由): {p!r}"
  2669	        elif state != base:
  2670	            # resolved/disputed-major 必須精確相等——夾帶冒號後綴=未定義第四態(帳面破三態白名單)
  2671	            return None, f"狀態 {state!r} 夾帶後綴(僅 accepted-minor 可帶冒號理由)"
  2672	        if name in out:
  2673	            return None, f"同輪同名 cluster 重複: {name!r}"
  2674	        out[name] = state
  2675	    return out, None
  2676	
  2677	
  2678	LOOP_TIERS = ("light", "standard", "high")
  2679	
  2680	
  2681	def _sha256_file(path):
  2682	    """檔案 sha256(M1包 #3);OSError 交呼叫端兜(目錄/無權限/不存在統一 rc2,沿 G1 慣例)。"""
  2683	    import hashlib
  2684	    return hashlib.sha256(Path(path).read_bytes()).hexdigest()
  2685	
  2686	
  2687	def cmd_canary(env, kind, auditor=None, token=None, note=None, loop=None, severity=None, findings=None, round_id=None, capture_counts=None, clusters=None, spec=None, reviewed=None, tokens=None, wallclock_min=None, tier=None, scope_lines=None):
  2688	    """記一筆 canary 審計留痕(test-the-tester):某輪對抗審計有沒有抓到植入瑕疵。
  2689	    record-only、本機;漏抓(missed)= 該輪審計員放水的訊號,經 lumos gov 可查詢。
  2690	    --loop/--severity:把這輪歸進某設計 loop(供 lumos loop status 算收斂)。
  2691	    --clusters(M2):該輪 risk-cluster 三態帳(每輪至多一筆帶;讀側 loop status --panel 消費)。
  2692	    天花板:這只證明「審計員有沒有醒著讀」,不證明它抓到所有真問題(見設計 doc)。"""
  2693	    import json
  2694	    import datetime
  2695	    import secrets
  2696	    if not token:
  2697	        token = "CANARY-" + secrets.token_hex(4)   # 隨機,非時間戳(同秒不撞)
  2698	    rec = {"ts": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
  2699	           "kind": kind, "auditor": auditor or "", "token": token, "note": note or ""}
  2700	    if loop:
  2701	        rec["loop"] = loop
  2702	    if round_id:
  2703	        rec["round"] = round_id   # panel 一輪 W 筆共享 round-id(loop status --panel 分組)
  2704	    if capture_counts:
  2705	        try:
  2706	            rec["capture_counts"] = [int(x) for x in str(capture_counts).split(",") if x.strip()]
  2707	        except ValueError:
  2708	            print(f"ERROR: --capture-counts 需逗號分隔整數,收到 {capture_counts!r}", file=sys.stderr)
  2709	            return 2
  2710	    if severity:
  2711	        rec["severity"] = severity
  2712	    if findings is not None:
  2713	        rec["findings"] = findings
  2714	    if clusters is not None:   # 空字串也進解析器 → rc2(帶旗標即須有效內容,勿被 falsy 吞)
  2715	        parsed, err = _parse_clusters(clusters)
  2716	        if err:
  2717	            print(f"ERROR: --clusters {err}", file=sys.stderr)
  2718	            return 2
  2719	        rec["clusters"] = parsed   # dict{名:狀態},同 capture_counts 寫側轉型慣例
  2720	    # ── M1包 #3 雙 hash 鏈(loop機械脊椎M1包_計劃):--spec/--reviewed 必須同現 ──
  2721	    if (spec is None) != (reviewed is None):
  2722	        print("ERROR: hash 雙欄必須成對(--spec 與 --reviewed 同現;reviewed=派工當下真檔 sha256)",
  2723	              file=sys.stderr)
  2724	        return 2
  2725	    if spec is not None:
  2726	        try:
  2727	            rec["result_sha256"] = _sha256_file(spec)   # record 於 fold 後執行=post-fold hash
  2728	        except OSError as e:
  2729	            print(f"ERROR: 讀不到 --spec {spec}: {e}", file=sys.stderr)
  2730	            return 2
  2731	        if not re.fullmatch(r"[0-9a-f]{64}", str(reviewed)):
  2732	            print(f"ERROR: --reviewed 需 64 位 sha256 hex,收到 {reviewed!r}", file=sys.stderr)
  2733	            return 2
  2734	        rec["reviewed_sha256"] = reviewed
  2735	    # ── M1包 #4 成本選配欄:非負整數,不給不寫鍵(同 --findings 慣例) ──
  2736	    # ★scope_lines(2026-08-02)★:這輪「被審材料有多少行」。
  2737	    # 為什麼要記——canary 抓到只證審查員醒著,但★東西越多越抓不到★是外部實測裡
  2738	    # 最主導的因素(arXiv 2606.15689:合成缺陷抓得到不可靠地預測真實缺陷抓得到,
  2739	    # 且 diff 大小是主導混淆變數)。本專案十輪 code-loop 的 diff 從 332 到 2770 行,
  2740	    # ★在帳上長得一模一樣★——等於無法回答「小 diff 上的 caught 是不是灌水」。
  2741	    # 這一欄不改任何判定、不進任何 gate,★純粹是把缺的變數記下來★,好讓
  2742	    # 「caught 率 vs 規模」這個問題日後答得出來(三種結果都有用:有關係→大 diff
  2743	    # 要切開或加席;沒關係→這個擔心在本情境不成立、寫下來別再擔心;反過來→查)。
  2744	    # ★不能回溯★:既有記錄沒有這個數字,時鐘從加上去那天才開始走。
  2745	    for _name, _val in (("tokens", tokens), ("wallclock_min", wallclock_min),
  2746	                        ("scope_lines", scope_lines)):
  2747	        if _val is not None:
  2748	            if _val < 0:
  2749	                print(f"ERROR: --{_name.replace('_', '-')} 需非負整數,收到 {_val}", file=sys.stderr)
  2750	                return 2
  2751	            rec[_name] = _val
  2752	    if scope_lines is not None and scope_lines > _CANARY_SCOPE_SOFT_CAP_LINES:
  2753	        rec["scope_oversize"] = True
  2754	        print(f"⚠ 本輪被審材料 {scope_lines} 行,超過軟上限 {_CANARY_SCOPE_SOFT_CAP_LINES} 行"
  2755	              f"(≈30K token,context rot 的已發表退化起點是 32K)。", file=sys.stderr)
  2756	        print("  已在帳上標記 scope_oversize。★這一輪的 caught 是弱證據★——"
  2757	              "審查員可能是「看不完」而不是「沒問題」;收斂宣稱請講小,下一輪拆開審。", file=sys.stderr)
  2758	    # ── M1包 #1 tier 定錨欄(選配;loop next/gate 讀首個帶 tier 記錄定錨) ──
  2759	    if tier is not None:
  2760	        if tier not in LOOP_TIERS:
  2761	            print(f"ERROR: --tier 需 {'/'.join(LOOP_TIERS)},收到 {tier!r}", file=sys.stderr)
  2762	            return 2
  2763	        rec["tier"] = tier
  2764	    path = env.vault.parent / ".canary-log.jsonl"
  2765	    rc = _jsonl_append_verified(path, rec, "token", token)
  2766	    if rc != 0:
  2767	        return rc
  2768	    print(f"✓ canary {kind} 留痕: {token}" + (f" (auditor={auditor})" if auditor else "")
  2769	          + f" → {path.resolve()}")
  2770	    return 0
  2771	
  2772	
  2773	def _jsonl_append_verified(path, rec, key_field, key_value):
  2774	    """[S1 oracle品質包] append 一行 JSONL + 讀回自驗(成功宣稱與證據綁死)。
  2775	    caller 給唯一鍵欄名與值——不寫死欄名(record 用 token、second 用自身 token)。
  2776	    寫入 OSError → rc2(既有訊息);寫成功但重開檔讀不回該鍵 → rc2「落盤自驗失敗」。
  2777	    出身:2026-07-28 record 回報成功未落盤事故([[Issues/canary-record未落盤事件]])。"""
  2778	    import json
  2779	    try:
  2780	        with open(path, "a", encoding="utf-8") as f:
  2781	            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
  2782	    except OSError as e:
  2783	        print(f"ERROR: 寫入 {path} 失敗: {e}", file=sys.stderr)
  2784	        return 2
  2785	    try:
  2786	        with open(path, encoding="utf-8", errors="replace") as f:   # 獨立重開檔(非同 fd)
  2787	            for line in f:
  2788	                if not line.strip():
  2789	                    continue
  2790	                try:
  2791	                    d = json.loads(line)
  2792	                except ValueError:
  2793	                    continue
  2794	                if isinstance(d, dict) and d.get(key_field) == key_value:
  2795	                    return 0
  2796	    except (OSError, ValueError) as e:
  2797	        print(f"canary record: 落盤自驗失敗({path.resolve()}): 讀回失敗 {e}", file=sys.stderr)
  2798	        return 2
  2799	    print(f"canary record: 落盤自驗失敗({path.resolve()}): 寫入回報成功但讀不回該筆",
  2800	          file=sys.stderr)
  2801	    return 2
  2802	
  2803	
  2804	def cmd_canary_second(env, ref_id=None, verdict=None, auditor=None, note=None):
  2805	    """[S2 oracle品質包] canary 判定的第二判者留痕(抽樣分權,telemetry-only)。
  2806	    走 [S1] 同一自驗 helper(唯一鍵=自身新 token);loop status 天然忽略(second 行無 loop 欄)。
  2807	    天花板:第二判者仍是 LLM,只壓「植入者=唯一判定者」的單點,不證判定為真。"""
  2808	    import json
  2809	    import datetime
  2810	    import secrets
  2811	    if not ref_id or not verdict:
  2812	        print("ERROR: canary second 需 --id 與 --verdict", file=sys.stderr)
  2813	        return 2
  2814	    if verdict not in ("agree", "overturn"):
  2815	        print(f"ERROR: --verdict 僅收 agree/overturn,收到 {verdict!r}", file=sys.stderr)
  2816	        return 2
  2817	    if not auditor:
  2818	        print("ERROR: canary second 需 --auditor(分權紀錄無名則失義)", file=sys.stderr)
  2819	        return 2
  2820	    path = env.vault.parent / ".canary-log.jsonl"
  2898	    """M2 統一單位謂詞(有效輪):caught≥2 ∧ missed=0 ∧ 全部 kind ∈ {caught,missed}。
  2899	    gate/fold/定錨/ledger/W 歸屬五處共用——嚴禁記錄級判定(2caught+1missed 輪的
  2900	    clusters 掛 caught 記錄上也不得採納);未知 kind 使輪無效(既有 2303 謂詞對此是盲的)。"""
  2901	    kinds = [r.get("kind") for r in recs]
  2902	    if any(k not in ("caught", "missed") for k in kinds):
  2903	        return False
  2904	    return kinds.count("caught") >= 2 and kinds.count("missed") == 0
  2905	
  2906	
  2907	def _panel_extra_checks(latest, min_seats, spec):
  2908	    """M1包 判定輪加驗(code-loop 補審 r1 折入:cluster 與無-cluster 兩路皆須過,不得繞):
  2909	    min-seats 數相異非空 auditor(同席灌筆/空席不計)+ G3 hash(帶 --spec=聲明要驗)。回 fails 片段。"""
  2910	    fails = []
  2911	    if min_seats:
  2912	        seats = len({a for r in latest if (a := r.get("auditor"))})
  2913	        if seats < min_seats:
  2914	            print(f"[panel] min-seats: ✗ — 席數不足({min_seats} 席制僅 {seats} 相異席;同席重複/空席不計)")
  2915	            fails.append("席數不足")
  2916	        else:
  2917	            print(f"[panel] min-seats: ✓ — {seats} 相異席 ≥ {min_seats}")
  2918	    if spec is not None:
  2919	        err, info = _hash_chain_check([latest], spec)   # OSError 上拋至 cmd_loop_status 統一 rc2
  2920	        if err:
  2921	            print(f"[panel] G3 hash: ✗ — {err}")
  2922	            fails.append("G3")
  2923	        elif info == "unbound":
  2924	            print("[panel] G3 hash: ✗ — 判定輪未綁 spec hash(帶 --spec 即要求驗證)")
  2925	            fails.append("G3")
  2926	        else:
  2927	            print(f"[panel] G3 hash: ✓ — {info}(同輪雙欄一致∧末 result=當前檔)")
  2928	    return fails
  2929	
  2930	
  2931	def _loop_status_panel(rounds, loop_id, min_seats=None, spec=None):
  2932	    """平行 panel 收斂謂詞(loop 三輪壓縮)。無-cluster 舊帳:三條合取(輪有效∧存活max≤minor
  2933	    ∧capture-recapture 殘餘,fail-closed)。cluster 帳(M2,設計 Projects/design-loop提效_計劃;
  2934	    golden: governance/golden/dloop-m2-cluster):首個有效輪帶 clusters 定錨 → 兩條合取
  2935	    (輪有效∧fold 後無 disputed-major),新生 cluster/capture-recapture 降 advisory,
  2936	    無效輪 clusters 忽略+警告區列帳(不蒸發)。讀側 rc2 類:round-id 非連續/型別損壞/
  2937	    有效輪 W 歸屬衝突/有效輪級混用。"""
  2938	    from collections import OrderedDict
  2939	    groups = OrderedDict()
  2940	    for r in rounds:
  2941	        rid_ = r.get("round")
  2942	        if rid_ in groups and next(reversed(groups)) != rid_:
  2943	            # M2:round-id 被其他 round 隔開後重現=帳本次序損壞(append-only 不容跳寫)
  2944	            print(f"ERROR: round-id {rid_!r} 非連續重現(被其他輪隔開;append-only 帳次序損壞)",
  2945	                  file=sys.stderr)
  2946	            return 2
  2947	        groups.setdefault(rid_, []).append(r)
  2948	    if not groups:
  2949	        print(f"⏳ 無 panel 輪記錄 ({loop_id})")
  2950	        return 1
  2951	    # ── M2 讀側型別防禦:clusters 欄必須是 dict[str,str](寫側轉型慣例;手改/損壞 → rc2 非 traceback)
  2952	    for r in rounds:
  2953	        if "clusters" in r:
  2954	            c = r["clusters"]
  2955	            if (not isinstance(c, dict)
  2956	                    or any(not isinstance(k, str) or not isinstance(v, str) for k, v in c.items())):
  2957	                print(f"ERROR: 記錄 clusters 欄非 dict{{名:狀態}} 結構(損壞/手改 JSONL?): {c!r}",
  2958	                      file=sys.stderr)
  2959	                return 2
  2960	    valid_of = {rid_: _round_valid_m2(recs) for rid_, recs in groups.items()}
  2961	    # ── M2 W 歸屬:有效輪同輪 >1 筆帶 clusters → rc2(無效輪多筆帶=豁免,列警告區)
  2962	    for rid_, recs in groups.items():
  2963	        if valid_of[rid_] and sum(1 for r in recs if "clusters" in r) > 1:
  2964	            print(f"ERROR: 輪 {rid_} 有 {sum(1 for r in recs if 'clusters' in r)} 筆記錄帶 clusters"
  2965	                  f"(每輪至多一筆;衝突不靜默取第一筆)", file=sys.stderr)
  2966	            return 2
  2967	    # ── M2 定錨:第一個有效輪定模式(無效輪不定錨——首輪全 missed 的新 loop 不得鎖死)
  2968	    anchor_rid, anchor_cluster = None, False
  2969	    for rid_, recs in groups.items():
  2970	        if valid_of[rid_]:
  2971	            anchor_rid = rid_
  2972	            anchor_cluster = any("clusters" in r for r in recs)
  2973	            break
  2974	    if anchor_rid is not None:
  2975	        # 有效輪級混用守衛(無效輪豁免:帶或不帶皆不觸發)
  2976	        for rid_, recs in groups.items():
  2977	            if not valid_of[rid_]:
  2978	                continue
  2979	            has_c = any("clusters" in r for r in recs)
  2980	            if anchor_cluster and not has_c:
  2981	                print(f"ERROR: 本 loop 已定錨 cluster 帳(定錨輪 {anchor_rid}),有效輪 {rid_} 未帶"
  2982	                      f" clusters(半帶);補該輪 cluster 記錄或開新 loop id", file=sys.stderr)
  2983	                return 2
  2984	            if not anchor_cluster and has_c:
  2985	                print(f"ERROR: 本 loop 已定錨無-cluster 模式(定錨輪 {anchor_rid}),有效輪 {rid_} 帶了"
  2986	                      f" clusters;要用 cluster 帳請開新 loop id(不升級既有 loop)", file=sys.stderr)
  2987	                return 2
  2988	    if anchor_rid is not None and anchor_cluster:
  2989	        return _loop_status_panel_clusters(groups, valid_of, loop_id,
  2990	                                           min_seats=min_seats, spec=spec, all_rounds=rounds)
  2991	    # ── 無-cluster 舊帳(或零有效輪=未定錨):既有三條合取,fail-closed 不變 ──
  2992	    # cluster-intent 但未定錨(零有效輪):條 1 改用 M2 嚴格謂詞(unknown-kind 盲區補;
  2993	    # 純無-cluster loop 不受影響——舊行為迴歸保證只對真 legacy 帳)
  2994	    _cluster_intent = any("clusters" in r for r in rounds)
  2995	    rid, latest = next(reversed(groups.items()))
  2996	    if _cluster_intent and not valid_of[rid]:
  2997	        print(f"[panel] 輪有效: ✗ — cluster-intent loop 判定輪 {rid} 無效(M2 謂詞:caught≥2∧missed=0∧kind 白名單)")
  2998	        for i, r in enumerate(latest, 1):
  2999	            print(f"  {rid}.{i}\t{r.get('kind','?')}\t{r.get('severity','-')}\t{r.get('auditor','')}")
  3000	        print(f"⛔ PANEL GATE FAIL ({loop_id} 輪 {rid}: 輪無效[未定錨 cluster-intent])")
  3001	        return 1
  3002	    order = {"clean": 0, "minor": 1, "major": 2, "blocker": 3}
  3003	    fails = []
  3004	    caught_recs = [r for r in latest if r.get("kind") == "caught"]
  3005	    caught = len(caught_recs)
  3006	    missed = sum(1 for r in latest if r.get("kind") == "missed")
  3007	    # near-perfect(2026-07-10,borrow mutation score 文獻:只有近滿分 caught-rate 才有強訊號,
  3008	    # 中段分數與真實審計力相關弱)→ 輪有效 = caught≥2 且該輪 0 missed(全 caught)
  3009	    if caught >= 2 and missed == 0:
  3010	        print(f"[panel] 輪有效(canary caught {caught}/{caught},near-perfect): ✓")
  3011	    elif missed > 0:
  3012	        print(f"[panel] 輪有效: ✗ — {missed} missed(near-perfect 要求全 caught;中段分數弱訊號不背書收斂)")
  3013	        fails.append("輪無效")
  3014	    else:
  3015	        print(f"[panel] 輪有效: ✗ — canary caught {caught} <2(輪無效)")
  3016	        fails.append("輪無效")
  3017	    # maxsev 只算 caught(醒著)審計員——missed 者 findings 已剔除(設計 §判定;review M1)
  3018	    maxsev = max((order.get(r.get("severity", "clean"), 1) for r in caught_recs), default=0)
  3019	    if maxsev >= 2:
  3020	        print(f"[panel] falsification+ODC(存活 max≤minor): ✗ — 存活 {'blocker' if maxsev==3 else 'major'}")
  3021	        fails.append("存活≥major")
  3022	    else:
  3023	        print("[panel] falsification+ODC(存活 max≤minor): ✓")
  3024	    cc = next((r["capture_counts"] for r in latest if r.get("capture_counts")), None)
  3025	    if cc is None:
  3026	        # fail-closed(review C1):panel 的收斂本體就是 capture-recapture 結構信號,
  3027	        # 沒 capture_counts 就無從證母體枯竭 → 不當「跳過」,當「未枯竭」擋。
  3028	        # 否則不寫 counts 即繞過殘餘檢查、退回舊「2 caught+無 major」弱信號。
  3029	        print("[panel] capture-recapture 殘餘: ✗ — 無 capture_counts(母體未證枯竭;panel 模式必帶)")
  3030	        fails.append("無capture_counts")
  3031	    else:
  3032	        remaining = _estimate_remaining_defects(cc)
  3033	        THRESH = 1.0
  3034	        if remaining < THRESH:
  3035	            print(f"[panel] capture-recapture 殘餘: ✓ — 估計 {remaining:.2f} < {THRESH}")
  3036	        else:
  3037	            print(f"[panel] capture-recapture 殘餘: ✗ — 估計 {remaining:.2f} ≥ {THRESH}(母體未枯竭)")
  3038	            fails.append("殘餘超門檻")
  3039	    fails += _panel_extra_checks(latest, min_seats, spec)
  3040	    for i, r in enumerate(latest, 1):
  3041	        print(f"  {rid}.{i}\t{r.get('kind','?')}\t{r.get('severity','-')}\t{r.get('capture_counts','-')}\t{r.get('auditor','')}")
  3042	    for line in _cost_summary(rounds):
  3043	        print(line)
  3044	    if fails:
  3045	        print(f"⛔ PANEL GATE FAIL ({loop_id} 輪 {rid}: {'/'.join(fails)})")
  3046	        return 1
  3047	    print(f"✅ PANEL GATE PASS ({loop_id} 輪 {rid}: 輪有效 ∧ 存活≤minor ∧ capture-recapture 枯竭)")
  3048	    return 0
  3049	
  3050	
  3051	def _loop_status_panel_clusters(groups, valid_of, loop_id, min_seats=None, spec=None, all_rounds=None):
  3052	    """M2 cluster 帳 gate:兩條合取(判定輪有效 ∧ fold 後無 disputed-major)。
  3053	    fold 只採有效輪(last-wins,同名跨輪最後狀態勝);無效輪 clusters 警告區列帳不蒸發;
  3054	    新生 cluster 與 capture-recapture 皆 advisory 不進合取。"""
  3055	    order = {"clean": 0, "minor": 1, "major": 2, "blocker": 3}
  3056	    rid, latest = next(reversed(groups.items()))
  3057	    fails = []
  3058	    # 條 1:判定輪(latest)有效——同一謂詞
  3059	    caught_recs = [r for r in latest if r.get("kind") == "caught"]
  3060	    n_caught, n_missed = len(caught_recs), sum(1 for r in latest if r.get("kind") == "missed")
  3061	    if valid_of[rid]:
  3062	        print(f"[panel/cluster] 條1 輪有效(caught {n_caught}≥2,0 missed): ✓")
  3063	    else:
  3064	        print(f"[panel/cluster] 條1 輪有效: ✗ — caught {n_caught}/missed {n_missed}"
  3065	              f"(謂詞:caught≥2∧missed=0∧kind 全白名單)")
  3066	        fails.append("輪無效")
  3067	    # fold(僅有效輪,append 序 last-wins)+ ledger(首現/末更輪僅計有效輪,與 advisory 同源)
  3068	    from collections import OrderedDict as _OD
  3069	    ledger = _OD()
  3070	    for rid_, recs in groups.items():
  3071	        if not valid_of[rid_]:
  3072	            continue
  3073	        for r in recs:
  3074	            for name, state in (r.get("clusters") or {}).items():
  3075	                if name not in ledger:
  3076	                    ledger[name] = {"state": state, "first": rid_, "last": rid_}
  3077	                else:
  3078	                    ledger[name]["state"] = state
  3079	                    ledger[name]["last"] = rid_
  3080	    disputed = [n for n, e in ledger.items() if e["state"].split(":", 1)[0] == "disputed-major"]
  3081	    if disputed:
  3082	        print(f"[panel/cluster] 條2 fold 後無 disputed-major: ✗ — {len(disputed)} 個: {','.join(disputed)}")
  3083	        fails.append("存在disputed-major")
  3084	    else:
  3085	        print("[panel/cluster] 條2 fold 後無 disputed-major: ✓")
  3086	    # advisory:新生 cluster(僅基於有效輪;判定輪無效 → 不適用)
  3087	    if valid_of[rid]:
  3088	        born = [n for n, e in ledger.items() if e["first"] == rid]
  3089	        print(f"[panel/cluster] (advisory) 新生 cluster: {len(born)} 個"
  3090	              + (f": {','.join(born)}" if born else ""))
  3091	    else:
  3092	        print("[panel/cluster] (advisory) 新生 cluster: 判定輪無效,新生統計不適用")
  3093	    # advisory:capture-recapture(照算照印,不進合取;無 counts 不 fail-closed——cluster 帳接手守門)
  3094	    cc = next((r["capture_counts"] for r in latest if r.get("capture_counts")), None)
  3095	    if cc is not None:
  3096	        remaining = _estimate_remaining_defects(cc)
  3097	        print(f"[panel/cluster] (advisory) capture-recapture 殘餘估計: {remaining:.2f}(不進合取)")
  3098	    else:
  3099	        print("[panel/cluster] (advisory) capture-recapture: 無 counts(advisory,不擋)")
  3100	    # 警告區:無效輪攜帶的 clusters(已忽略;資料本在 canary-log,顯示即留痕——status 唯讀)
  3101	    for rid_, recs in groups.items():
  3102	        if valid_of[rid_]:
  3103	            continue
  3104	        carried = []   # 全列:同名多筆逐條保留(dict.update 會靜默覆蓋掩掉爭議狀態)
  3105	        for r in recs:
  3106	            carried.extend((n, s) for n, s in (r.get("clusters") or {}).items())
  3107	        if carried:
  3108	            print(f"  ⚠ {rid_}(無效輪) clusters 已忽略: "
  3109	                  + ",".join(f"{n}={s}" for n, s in carried))
  3110	    # ledger 表
  3111	    if ledger:
  3112	        print("  ── cluster ledger(僅計有效輪)──")
  3113	        for n, e in ledger.items():
  3114	            print(f"  {n}\t{e['state']}\t首現 {e['first']}\t末更 {e['last']}")
  3115	    fails += _panel_extra_checks(latest, min_seats, spec)   # M1包:cluster 路不得繞過(code-loop r1)
  3116	    for i, r in enumerate(latest, 1):
  3117	        print(f"  {rid}.{i}\t{r.get('kind','?')}\t{r.get('severity','-')}\t{r.get('auditor','')}")
  3118	    for line in _cost_summary(all_rounds or []):
  3119	        print(line)
  3120	    if fails:
  3121	        print(f"⛔ PANEL GATE FAIL ({loop_id} 輪 {rid}: {'/'.join(fails)})")
  3122	        return 1
  3123	    print(f"✅ PANEL GATE PASS ({loop_id} 輪 {rid}: 輪有效 ∧ fold 後無 disputed-major"
  3124	          f"[cluster 帳,{len(ledger)} 個 cluster])")
  3125	    return 0
  3126	
  3127	
  3128	def cmd_loop_capture_counts(env, finders, from_pitfalls=None, repo=None):
  3129	    """異質 panel 接線的機械生產者(code-loop 三輪壓縮):把各 finder 的 finding-key
  3130	    彙成 capture_counts + 算殘餘估計,吐出可直接餵 `canary record --capture-counts` 的逗號串。
  3170	          f"({'枯竭 <1.0 → 收斂側' if remaining < 1.0 else '殘餘 ≥1.0 → 續跑側'})")
  3171	    if cc:
  3172	        print(f"→ canary record ... --capture-counts {','.join(str(c) for c in cc)}")
  3173	    return 0
  3174	
  3175	
  3176	def _hash_chain_check(rounds_list, spec_path):
  3177	    """M1包 #3 雙 hash 鏈收斂窗驗證(loop機械脊椎M1包_計劃)。
  3178	    rounds_list=[[rec,...],...] 窗內按序的「輪」列表(legacy=每筆一輪;panel=判定輪一組)。
  3179	    回 (fail_msg or None, info):fail=None 且 info='unbound' 表窗內全無 hash(呼叫端裁 FAIL/advisory)。
  3180	    驗四件:窗級 all-or-nothing(帶=雙欄俱全)/同輪雙欄各自一致/鏈續性 reviewed[k+1]==result[k]/
  3181	    窗末 result==sha256(當前檔)。窗首 reviewed 無窗內錨=已知逃逸不硬驗。"""
  3182	    def has_hash(r):
  3183	        return "reviewed_sha256" in r and "result_sha256" in r
  3184	    def half(r):
  3185	        return ("reviewed_sha256" in r) != ("result_sha256" in r)
  3186	    all_recs = [r for grp in rounds_list for r in grp]
  3187	    if any(half(r) for r in all_recs):
  3188	        return "收斂窗 hash 半帶(記錄僅有 reviewed/result 其一——雙欄必須成對)", ""
  3189	    banded = [has_hash(r) for r in all_recs]
  3190	    if not any(banded):
  3191	        return None, "unbound"
  3192	    if not all(banded):
  3193	        return "收斂窗 hash 半帶——收斂憑證無法互證(窗內任一筆帶即全體必須帶)", ""
  3194	    per_round = []   # [(reviewed, result), ...] 每輪一組
  3195	    for grp in rounds_list:
  3196	        revs = {r["reviewed_sha256"] for r in grp}
  3197	        ress = {r["result_sha256"] for r in grp}
  3198	        if len(revs) > 1 or len(ress) > 1:
  3199	            return ("同輪 hash 分裂——各席 reviewed 或 result 不一致(同輪宣稱多個版本)", "")
  3200	        per_round.append((next(iter(revs)), next(iter(ress))))
  3201	    for k in range(len(per_round) - 1):
  3202	        if per_round[k + 1][0] != per_round[k][1]:
  3203	            return (f"鏈續性斷裂——第 {k + 2} 輪 reviewed ≠ 第 {k + 1} 輪 result"
  3204	                    "(折入版本與下輪受審版本不接)", "")
  3205	    cur = _sha256_file(spec_path)   # OSError 上拋——呼叫端統一 rc2(code-loop r2:panel/light 原轉字串成 rc1,與 G1 不對稱)
  3206	    if per_round[-1][1] != cur:
  3207	        return "spec 於審計後被改動(窗末 result ≠ 當前檔),需再過一輪", ""
  3208	    return None, f"{len(per_round)} 輪鏈驗訖"
  3209	
  3210	
  3211	def _cost_summary(rounds):
  3212	    """M1包 #4:任一筆有成本欄時回摘要行 list,否則空(零噪音)。"""
  3213	    rows = [(i, r) for i, r in enumerate(rounds, 1)
  3214	            if "tokens" in r or "wallclock_min" in r]
  3215	    if not rows:
  3216	        return []
  3217	    out = ["成本(自報,GIGO 同 anchors):"]
  3218	    tt = tm = 0
  3219	    for i, r in rows:
  3220	        tk, mn = r.get("tokens"), r.get("wallclock_min")
  3221	        tt += tk or 0
  3222	        tm += mn or 0
  3223	        out.append(f"  #{i}: tokens={tk if tk is not None else '-'} 分鐘={mn if mn is not None else '-'}")
  3224	    out.append(f"  總計: tokens={tt} 分鐘={tm}")
  3225	    return out
  3226	
  3227	
  3228	_COMPRESS_PIN_RE = re.compile(
  3229	    r"★INVARIANT★|★IRREVERSIBLE★|★CHECKPOINT★|停在放行點|anchor\s*驗證|anchor\s*verify|\[PIN\]", re.I)
  3230	_COMPRESS_EVID_RE = re.compile(r"VERIFY:|✅|\[test:|^\s*TEST:", re.I)
  3231	_COMPRESS_OPEN_RE = re.compile(r"-\s*\[\s\]|TODO|BLOCKER|⏳|未結", re.I)
  3232	
  3233	
  3234	def cmd_loop_compress(file, as_json=False):
  3235	    """[S2] 結構化壓縮(結清式收斂_計劃,2026-07-28):長跑上下文不交通用摘要——規則式三欄:
  3236	    壓不掉白名單(★合約/停在放行點/anchor 驗證/[PIN] 口頭約定)/已驗證證據(VERIFY:/✅/[test:)/
  3237	    未結約束(checkbox/TODO/BLOCKER)。白名單行在輸出**必存在**(治 governance decay 殘餘面:
  3238	    對話中途口頭約定寫成 [PIN] 行即壓不掉);無標記散文可丟。零模型、純規則,輸出走 stdout
  3239	    (落檔權在消費者——orchestrator 自行重導)。rc0 成功/rc2 檔不可讀。"""
  3240	    import json
  3680	
  3681	
  3682	_TIER_PARAMS = {"light": (1, 2), "standard": (3, 3), "high": (5, 3), "legacy": (1, 6)}  # tier→(width, cap)
  3683	# ★一輪能丟多少給審查員的軟上限★(2026-08-02)
  3684	# 為什麼有這條:審查員的任務是「在 N 行裡找出那個植入的錯」,而 context rot(脈絡越長、
  3685	# 注意力越差)是已發表的實測現象——有效脈絡長度約標稱值的 60-70%,★退化在 32K token 就
  3686	# 量得到★(不必塞爆),報告的退化幅度 13.9%-85%。
  3687	# ★這條門檻★純粹★借自外部文獻,本專案自己的資料不支持它★(2026-08-02 更正,
  3688	# 原註解在此宣稱「本專案資料落在線的兩邊、方向是反的」——★那個宣稱是錯的,已撤★):
  3689	#   ① 原始觀察(code-slim-python r1/r2 大 payload 零 findings、r3-r6 小 payload 有 findings)
  3690	#      經查證★兩組審的根本不是同一份碼★(前者 bash→Python 移植,後者後來才寫的 manifest 步驟),
  3691	#      拿來比就是拿蘋果比橘子,不構成任何證據。
  3692	#   ② 之後跑了★兩次刻意設計的對照實驗★(見架構圖 [[Projects/審查規模對照實驗]] 與
  3693	#      [[Projects/審查規模對照實驗二_Landmark真缺陷]]),★都不支持「量大→漏看」★:
  3694	#      命中率沒掉。實驗二甚至 7/7 全中,撞到天花板。
  3695	#   ③ 反而浮出另一個假說:量大影響的可能不是「有沒有看到」而是★判斷的自信度★——
  3696	#      大 payload 的席位會★有把握地宣稱有缺陷的地方沒問題★(見 [[Projects/規模影響判斷力假說]],
  3697	#      3/3 大 payload 席位講反、1/1 小 payload 席位找到)。★該假說 n=4、觀察性、
  3698	#      編碼者=提出者,尚未閉合 maker≠checker,★不得據以動 gate★。
  3699	# 門檻取 1800 行 ≈ 30K token,是★借用已發表的 32K 起點取略保守整數★,不是本專案量出來的。
  3700	# 這是軟上限:超過不擋(輪已經跑完才記帳,擋也來不及),但★記進帳並要求收斂宣稱講小★。
  3701	_CANARY_SCOPE_SOFT_CAP_LINES = 1800
  3702	
  3703	_CANARY_TYPES = ("a", "b", "c", "d")   # 壞交叉引用/未定義旗標/未定義欄位常數/未定義產物裸檔名
  3704	
  3705	
  3706	def cmd_loop_next(env, loop_id, tier=None, as_json=False, need=2, spec=None, repo=None):
  3707	    """M1包 #1(loop機械脊椎M1包_計劃):帳本吐唯一下一動作。唯讀指針——lumos 不 spawn agent,
  3708	    編排仍是 Claude(Systems/design-loop 分工)。phase 五值:escalate/gate-pending/converged/
  3709	    cap-reached/plant-canary;判定優先序=escalate→gate-pending(資訊不足,先於 cap)→converged
  3710	    (僅 full-basis)→cap-reached→plant-canary。converged=rc0/其餘 phase=rc1/錯誤=rc2。
  3711	    tier 定錨優先:帳面首個帶 tier 記錄定錨;僅無定錨舊帳按格式推導;零記錄 rc2 要 --tier。"""
  3712	    import json as _json
  3713	    import io
  3714	    import contextlib
  3715	    path = env.vault.parent / ".canary-log.jsonl"
  3716	    rounds = []
  3717	    try:
  3718	        if path.exists():
  3719	            for line in path.read_text(encoding="utf-8").splitlines():
  3720	                line = line.strip()
  3721	                if not line:
  3722	                    continue
  3723	                try:
  3724	                    d = _json.loads(line)
  3725	                except ValueError:
  3726	                    continue
  3727	                if d.get("loop") == loop_id:
  3728	                    rounds.append(d)
  3729	    except OSError as e:
  3730	        print(f"ERROR: 讀 {path} 失敗: {e}", file=sys.stderr)
  3731	        return 2
  3732	    n_round = sum(1 for r in rounds if "round" in r)
  3733	    if rounds and n_round not in (0, len(rounds)):
  3734	        print("ERROR: canary-log round 欄混用(partial-mix)——帳損壞,同 status 拒讀", file=sys.stderr)
  3735	        return 2
  3736	    panel_fmt = n_round > 0
  3737	    if panel_fmt:   # 讀側損壞守衛不得因缺 --spec 提前 return 而繞過(code-loop r2 折入)
  3738	        seen, cur_rid = set(), None
  3739	        for r in rounds:
  3740	            rid = r["round"]
  3741	            if rid != cur_rid:
  3742	                if rid in seen:
  3743	                    print(f"ERROR: round-id {rid!r} 非連續重現(append-only 帳次序損壞)——同 status 拒讀",
  3744	                          file=sys.stderr)
  3745	                    return 2
  3746	                seen.add(rid)
  3747	                cur_rid = rid
  3748	    # ── tier 解析:定錨優先(v8);僅無定錨舊帳按格式推導;零記錄 rc2 ──
  3749	    anchor = next((r["tier"] for r in rounds if r.get("tier")), None)
  3750	    if tier and anchor and tier != anchor:
  3751	        print(f"ERROR: --tier {tier} 與帳面定錨 {anchor} 衝突(定錨優先;要換 tier 開新 loop id)", file=sys.stderr)
  3752	        return 2
  3753	    eff_tier = anchor or tier
  3754	    if eff_tier is None:
  3755	        if not rounds:
  3756	            print("ERROR: 零記錄 loop 需明示 --tier(不猜——猜錯模式撞混用守衛)", file=sys.stderr)
  3757	            return 2
  3758	        eff_tier = "standard" if panel_fmt else "legacy"   # 無定錨舊帳 fallback
  3759	    width, cap = _TIER_PARAMS[eff_tier]
  3760	    light = eff_tier == "light"
  3761	    # ── tier↔格式一致性(code-loop r1 折入:格式推導可被繞——high 漏帶 --round 會走鬆的 legacy 閘) ──
  3762	    if rounds:
  3763	        if eff_tier in ("standard", "high") and not panel_fmt:
  3764	            print(f"ERROR: tier={eff_tier} 要求 panel 格式(記錄帶 --round),帳面為 legacy 格式——"
  3765	                  "格式衝突(補 record 帶 --round,或 tier 錯誤則開新 loop id)", file=sys.stderr)
  3766	            return 2
  3767	        if light and panel_fmt:
  3768	            print("ERROR: tier=light 為單席 legacy 格式,帳面卻帶 --round(panel 格式)——格式衝突", file=sys.stderr)
  3769	            return 2
  3770	    rounds_count = len({r["round"] for r in rounds}) if panel_fmt else len(rounds)
  3771	    n_next = rounds_count + 1
  3772	
  3773	    def emit(phase, extra=None):
  3774	        out = {"phase": phase, "tier": eff_tier, "round": n_next, "width": width,
  3775	               "min_seats": width, "cap": cap, "advisory": "tier 由編排者宣告後定錨;lumos 只做映射與定錨讀取"}
  3776	        if phase == "plant-canary":
  3777	            if light or eff_tier == "legacy":
  3778	                out["canary_type"] = _CANARY_TYPES[(n_next - 1) % 4]
  3779	            else:
  3780	                out["canary_type"] = {f"slot{i}": _CANARY_TYPES[(i + n_next - 1) % 4]
  3781	                                      for i in range(1, width + 1)}
  3782	            rmode = "" if (light or eff_tier == "legacy") else f" --round r{n_next}"
  3783	            # ★`legacy` 不是可宣告值,不得吐進 record_cmd★(2026-08-04):`--tier` 的 choices
  3784	            # 只有 light/standard/high(LOOP_TIERS),legacy 純粹是「無定錨舊帳 + legacy 格式」
  3785	            # 的推導結果。原本這裡無條件吐 `--tier {eff_tier}`,legacy 下等於★發一條 argparse
  3786	            # 當場擋掉的指令★;而使用者最自然的修復是「把 --tier 拿掉再跑一次」——拿掉就記不上
  3787	            # 定錨,下一輪 next 又推成 legacy、又吐一條跑不動的指令。
  3788	            # ★這個 bug 自己維持自己★:2026-08 三個走循序的 loop(code-slim-python /
  3789	            # code-teardown-windows / code-slim-handoff)全數 tier=None,即此循環的產物;
  3790	            # 其中 code-slim-python 吃到 legacy 的 cap 6(standard 是 3)才被逼停。
  3791	            _tier_flag = f" --tier {eff_tier}" if eff_tier in LOOP_TIERS else ""
  3792	            out["record_cmd"] = (f"lumos canary record caught|missed --loop {loop_id}{rmode}"
  3793	                                 f" --auditor <席> --severity <s> --findings <M>"
  3794	                                 f" --spec <計劃節點.md> --reviewed <sha256>{_tier_flag}"
  3795	                                 f" --scope-lines <這輪審了幾行>")
  3796	            if eff_tier == "legacy":
  3797	                out["tier_hint"] = (
  3798	                    "★本 loop 無 tier 定錨,正在吃 legacy 判準(單席、cap 6——比 standard 的 cap 3 鬆)★。"
  3799	                    "legacy 不是可宣告值,★這個 loop 補標不了★:帳面已是 legacy 格式(記錄不帶 --round),"
  3800	                    "補 --tier standard|high 會被格式一致性當場擋掉(rc2)。"
  3801	                    "(--tier light 格式相容,但 cap=2 且帶 ratchet 語意,對已跑數輪的 loop 通常當場 cap-reached。)"
  3802	                    "要走分級判準請★開新 loop id,並在第一筆 record 就帶 --tier★。")
  3803	            # ★預防端:警告必須在派工「之前」★——記帳時才喊已經來不及(輪跑完了)。
  3804	            # loop next 是每輪第一步,所以量尺放這裡。
  3805	            out["scope_cap"] = (
  3806	                f"★派工前先量★ `wc -l <工作副本/patch>`:超過 {_CANARY_SCOPE_SOFT_CAP_LINES} 行"
  3807	                f"(≈30K token)就★拆開審★——切成多輪,或拆給多席各審一段。"
  3808	                "理由:審查員的任務是『在 N 行裡找出那個植入的錯』,而脈絡越長注意力越差是"
  3809	                "已發表的實測(退化在 32K token 就量得到)。"
  3810	                "★這條門檻純粹借自外部文獻——本專案自己跑過三次對照實驗都測不出規模效應,"
  3811	                "不得引用自家資料當佐證★(原本這裡寫「本專案資料落在線兩邊」,該宣稱已撤:"
  3812	                "兩組審的根本不是同一份碼;之後兩次刻意設計的實驗一次撞天花板 7/7、一次撞"
  3813	                "地板 0/6,見 Projects/規模影響判斷力假說)。"
  3814	                "超標不擋,但會在帳上標 scope_oversize、該輪 caught 視為弱證據。")
  3815	        # ★cluster 帳的選擇只有第一輪能做★(2026-08-02):模式由「第一個有效輪」定錨,之後
  3816	        # 要換只能開新 loop id。而 M2 落地至今 316 筆 canary 記錄裡★只有 1 筆帶 clusters★,
  3817	        # 且那一筆是開發它的 code-m2cluster 自己——34 個 panel loop 中有 33 個靜默落回
  3818	        # 無-cluster 舊帳。根因不是機制不好,是★沒有任何地方在該選的時候提起它★。
  3819	        # 只在 N=1 提(那是選擇真正還開著的唯一時刻),避免對已定錨的 loop 噴無效噪音。
  3820	        if phase == "plant-canary" and not light and eff_tier != "legacy" and n_next == 1:
  3821	            out["cluster_hint"] = (
  3822	                "★本 loop 第一輪——cluster 帳只有現在能選(模式由第一個有效輪定錨,之後要換只能開新 loop id)★:"
  3823	                "若預期 findings 會散成★性質不同★的風險群(例:「規格縮水」與「邊界 bug」),"
  3824	                "改用 `--clusters '名=resolved|accepted-minor:理由|disputed-major'` 逐群追蹤,"
  3825	                "gate 改判「無 disputed-major」——不把不同性質的問題壓成單一 max severity(一軸會遮蔽另一軸)。"
  3826	                "單一主題、findings 同性質的 loop 用預設(無-cluster)即可。")
  3827	        if extra:
  3828	            out.update(extra)
  3829	        if as_json:
  3830	            print(_json.dumps(out, ensure_ascii=False))
  3831	        else:
  3832	            print(f"[next] {loop_id}: phase={phase} tier={eff_tier} 下一輪 N={n_next}"
  3833	                  f" width={width} cap={cap}")
  3834	            for k in ("canary_type", "record_cmd", "scope_cap", "cluster_hint", "note"):
  3835	                if k in out:
  3836	                    print(f"  {k}: {out[k]}")
  3837	        return 0 if phase == "converged" else 1
  3838	
  3839	    # ⓪ escalate:light ratchet 永久態最先短路
  3840	    if light and any(r.get("kind") == "caught" and r.get("severity") in ("major", "blocker")
  3841	                     for r in rounds):
  3842	        return emit("escalate", {"note": "light ratchet 已觸發——停止本 loop,開新 panel loop id(原 id+-std 後綴)承接"})
  3843	    if not rounds:
  3844	        return emit("plant-canary")
  3845	    # ① gate-pending:判 converged 需 gate 結果,資訊不足絕不背書(先於 cap)
  3846	    if spec is None:
  3847	        return emit("gate-pending", {"note": "缺 --spec,gate 判定資訊不足——跑 loop status --gate 附完整參數自判"})
  3848	    # ② full-basis gate 委派(靜默跑既有謂詞,零新判定邏輯)
  3849	    buf = io.StringIO()
  3850	    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
  3851	        rc = cmd_loop_status(env, loop_id, need=(1 if light else need), gate=True,
  3852	                             spec=spec, repo=repo, panel=(panel_fmt and not light),
  3853	                             light=light, min_seats=width)   # 恆傳(light/legacy=1;code-loop r1 折入)
  3854	    if rc == 2:
  3855	        sys.stderr.write(buf.getvalue())
  3856	        return 2
  3857	    if rc == 0:
  3858	        return emit("converged", {"gate_basis": "full(G 合取+hash 委派既有謂詞全過)"})
  3859	    # ③ cap(資訊充分且未 PASS)
  3860	    if rounds_count >= cap:
  3861	        return emit("cap-reached", {"note": f"cap={cap} 到頂未收斂——停,攤給人裁(別無限燒)"})
  3862	    # ④ plant-canary
  3863	    return emit("plant-canary")
  3864	
  3865	
/tmp/dlrd-r1.md:25:  PRIOR-ART:①最小解在既有機制層——錨定檢查=把 G1 refcheck 的機械比對用到審查員產出上(自家已有的信任階梯「機械查>LLM判官」);處置帳=擴充既有 M2 cluster 帳非新造 ②世界解過(2026-08-04 網搜)——品管三件套(ACM 綜述:gold/互評/冗餘★並列★,gold 有應試缺陷「通過金標的工人照樣交低品質答案」且實務全是跨題累積統計判定,★單題一票否決無人採用★);citation grounding 文獻(CiteCheck 2026):★機械比對引文>讓 LLM 判官判可信度★;fault seeding 文獻定義=★評估檢測流程有效性的離線量測工具★(IBIR/FLAWS 原始論文全是 benchmark 用法,無一當逐輪放行條件);Prolific:>5min 研究失敗≥2 次才可拒 ③裁定=borrow-design(零依賴;真正無文獻背書的反而是現狀「單席單 canary 一票否決」)
/tmp/dlrd-r1.md:43:    why_chosen: 品管三件套文獻中 gold/互評/冗餘並列且 gold 有應試缺陷、實務全是累積統計判定,單題一票否決無人採用;citation grounding 實證機械比對引文>LLM 判官;fault seeding 文獻定義=離線量測工具(IBIR/FLAWS 皆 benchmark 用法)。查貨不查人:經查證的 findings 是「他讀了」的直接證據。備選 A(只改抑噪措辭)被否:p≈0.47 未證實其為主因且有反例;備選 B(canary 明示分離)被否:covert 變 overt 違反 attention-check 方法學
/tmp/dlrd-r1.md:77:| 11 收斂後 | golden/接受理由 | 因第 10 站不亮，歷史上全靠人裁進入 |
docs/lumos-toolchain-knowledge/Issues/design-loop折入漂移_機械守衛.md:63:- 已修:FLOW 行重寫(路由制+前置排乾+--gate 三錨+golden 凍結+panel 指針)、辯方 KEY 行同步、pitfalls-code-loop FLOW 補 tier 三分流(trivial/standard/high)。
docs/lumos-toolchain-knowledge/Systems/retrieval-ranking.md:13:  KEY:search面已轉正預設(2026-07-11,goldset §6全過:修正尺 nDCG@5 +58.1%/held +99.6%(2026-08-03 凍結值);--legacy逃生,--regex走舊路,預設全量+逐檔命中明細——資訊零損失);hook面已轉正(2026-07-11:P@8 .707/中位3/p95 9;dyn_coef .55/direct_base .30/名額10;trigger delta-scoped;必看視野19/30=精度代價(2026-08-03 凍結值;原記 24/30 不重現),見[[Verification/2026-07-11_hook面v1.1轉正]]);recommend面dormant;hop≥2需L>0、hop1只受靜態底線;結構前綴停用集(KEY:/FLOW:模板詞不算詞彙訊號);A1型別先驗:moc×0.4乘於詞彙分(train網格凍結,held零倒退,見[[Projects/節點靜態先驗_調研]])
docs/lumos-toolchain-knowledge/Systems/retrieval-ranking.md:14:  KEY:★DEBT★ 多詞片語候選=legacy片語語意(0候選不回退)★2026-08-02 部分緩解:`--any` 旗標(預設關)在整串片語全庫無命中時退成各詞 OR 召回;fallback-only 故對既有查詢零回歸(現有 goldset 30 題全部回>0候選,回退條件永不觸發)。Landmark 284 篇真庫實測:10/10 現實多詞查詢在預設下全 0 命中,`--any` 後 7/10 第一名正確。★2026-08-03 人裁翻預設★:多詞回退改為預設開、`--no-any` 逃生、`--any` 留相容。證據=補了 10 題多詞評測(雙評 Claude+Codex 跨家族、分歧交乾淨 opus 裁決):nDCG@5 0→0.767、MRR 0.95、第一名為「必看」7/10;對照組 5 題(現有命中的多詞查詢)逐檔完全相同=零回歸實證。誠實邊界:pooling bias(池半數來自回退自己)、n=10、單一快照。交付版已同步重生。見 [[Projects/檢索多詞回退_計劃]]★｜cochange proxy對架構圖related面太稀(兩vault實證,僅sanity check)｜hook接線v1.1待評測
docs/lumos-toolchain-knowledge/Systems/retrieval-ranking.md:16:  TEST:t_tokenizer/search_ranked/context_recommend/impact_ranked/impact_diff/impact_hook_v11 全綠+全套1018 | VERIFY:[[Verification/2026-07-11_hook面v1.1轉正]] | VERIFY:[[Verification/2026-07-10_檢索排序v1]][[Verification/2026-07-11_檢索goldset評測]]
docs/lumos-toolchain-knowledge/Systems/retrieval-ranking.md:24:  - "[[Verification/2026-07-11_檢索goldset評測]]"
docs/lumos-toolchain-knowledge/Systems/retrieval-ranking.md:29:設計三輪 panel（Codex 跨家族否決席全勤、5/5 canary 零漏——史上首例）收斂於 [[Projects/檢索優化_計劃]]，golden 凍結 governance/golden/retrieval/。雙盲合併（Claude×GPT-5.6）八處分歧裁定見計劃節點。
docs/lumos-toolchain-knowledge/Systems/retrieval-ranking.md:47:| [[Verification/2026-07-11_檢索goldset評測]](掛 verified_by 的源頭) | +57.6% | +104.7% |
docs/lumos-toolchain-knowledge/Systems/retrieval-ranking.md:57:- goldset 生成器 `governance/eval/build_goldset.py`：30 search（分層:繁中短詞/identifier/縮寫/單漢字）+20 edit（真 git 案例）；候選池=legacy∪ranked 去識別洗牌（sha256+salt 可重現）；標註表 retrieval-labeling-sheet.md（留白=0 省力制）。人標完解析回 goldset → retrieval_eval 跑 gate。
docs/lumos-toolchain-knowledge/Systems/slim-scan-掃描器.md:14:  KEY:★DEBT★(2026-08-01 代碼審 r6 方法論收穫)★掃描器只認「指令名」,認不得「路徑」★——`Projects/xxx_計劃`、`governance/golden/<id>/`、`docs/design/...` 這類指向完整版才有的檔案路徑,五種形態一條都比不到;`scripts/lumos` 保留的註解裡就有一批(那些註解是刻意原樣保留的 why-context,不該砍)。處置=不擴充掃描器(路徑型比對要維護一份「什麼路徑有交付」的清單,是新的漂移源),改在 `slim/README.md` 明講「註解裡看到查不到的路徑是正常的,不是你漏拿了什麼」並同樣不宣稱窮盡。★通則★:任何「我枚舉了 N 種形態」的守衛都要假設有第 N+1 種——驗證推到反例回歸,不推到「我列全了」的宣稱上
governance/golden/dloop-m2-cluster/spec.md:51:6. **（後續,等語料）** 歷史 replay 校準 Bayesian expected-loss 門檻（golden 語料 10+ 份後）；severity 錨句進派工模板（major=照實作會做錯行為;文件精度/測試枚舉=minor 除非漏合約）。
docs/lumos-toolchain-knowledge/Systems/check-j-regen-guard.md:31:Check J：from-scratch 重建節點的 provenance 分級守衛。設計三輪對抗審與收斂史見 [[Projects/from-scratch重生守衛_計劃]] 與 `governance/golden/fromscratch-m1/`；使用紀律見 lumos-project-notes skill〈重生標記〉段與 reference〈重生守衛〉段。
governance/eval/raters/adj-verdict-S.json:19:  "S07|Projects/canary生成硬化_計劃.md": {"v": 1, "why": "第3條『事故反轉(借IBIR)』專講查事故語料把修法反轉成canary"},
governance/golden/rel-layer-guard/spec.md:42:    why_chosen: 架構已穩、續推邊際遞減且剩的是實作合約非設計對錯;凍golden保三輪findings+待釘合約清單,實作另議。補網E1現成可建、立刻把頭號腐爛變免費週期檢查;主網typed-edge+CLI後上
governance/golden/rel-mainnet/spec.md:31:    why_chosen: 存活全 minor+三輪未翻架構=剩的是句級完整性;design-loop 完整性天花板已有實證(lint-version-watch:散文審有天花板、實作真測才接住)——散文再摳邊際遞減,真測開始接手才有增量;凍 golden 保三輪語料供 replay 校準
governance/golden/code-prepush-range/findings.md:23:## 審計員校準數據（golden 語料，本 loop 最有價值）
docs/lumos-toolchain-knowledge/Systems/canary-audit.md:18:  KEY:[2026-07-10]生成硬化三條進 skill——載重錨定/haiku 難度探針(FLAWS)/事故反轉(IBIR);missed-rate 升一級指標(lumos gov 分帳);見[[Projects/canary生成硬化_計劃]]
docs/lumos-toolchain-knowledge/Systems/cochange-guard.md:27:解「知識同步散落」缺口的機械守衛：從 git 歷史挖「改 A 歷史上 X% 同改 B」的關聯規則，commit 時警告漏改的夥伴檔。警告型、不擋人。設計全程見 [[Projects/cochange守衛_計劃]]（3 輪 canary-護 panel 審計 + golden 凍結於 `governance/golden/cochange-guard/`）。
docs/lumos-toolchain-knowledge/Systems/guard-kill.md:31:合約鏈最後一哩：`★INVARIANT★→[test:]` 只證「保鑣存在」，`guard kill` 真的打一拳——隔離 worktree 裡故意弄壞被守護的行為，綁定測試必須翻紅；全綠＝稻草人證據（rc 1）。設計三輪 panel 收斂見 [[Projects/guard殺傷力驗證_計劃]]，golden 凍結 `governance/golden/guard-kill/`。
governance/golden/lumos-show讀取入口-std/findings.md:19:## 審計員校準數據（golden 語料用）
docs/lumos-toolchain-knowledge/Systems/design-loop.md:21:  KEY:[2026-07-21]★真相入口收編★(外審 blocker,見[[Projects/全盤外審2026-07_調研]])——被審 spec 唯一可寫真檔=架構圖計劃節點;docs/design/ 降唯讀歷史(30 份保留考古,README 立牌);golden 不再複製 spec 第三份,改 spec-ref.txt 記 git sha:路徑(replay 用 git show 還原);loop id 改計劃節點名衍生。同批:panel 收斂行修 skill 漂移(對齊 M2 兩種帳)+判官 style-bias 錨句進 templates+light 體積 50 行先驗
docs/lumos-toolchain-knowledge/Systems/design-loop.md:26:  FLOW:brainstorming產spec→[trivial?跳並註明]→前置排乾(refcheck機械核對spec→repo指涉+pitfalls --check補實務隱患節+pre-flight便宜agent掃清單型缺陷;首輪前一次,cascade便宜先掃)→每輪{複製spec→/tmp/<id>-rN(**N/型別/席數問 `lumos loop next`**,2026-07-21 M1包;並 sha256sum 真檔留 reviewed 快照)→植1canary(類型=清單[(N−1)mod4],只進工作副本)→派乾淨審計員(sonnet,連2missed升opus,不告知canary,refute framing)→判讀(canary抓到?+真finding max severity)→辯方路由(機械證實/多席一致直接折入,僅低共識才派獨立opus構造反證file:line;2026-07-16 M1)→該輪severity=辯方存活max→**caught輪:折真finding進真檔+fold迷你核對+grep canary=0 之後才 record(--spec/--reviewed 雙hash;M1包 時序裁定,原 record-先-fold 會使 hash 恆失配);missed輪:當場record**/漏抓不折直接下輪}→loop status --gate exit0(模式擇一:legacy --need 2 K-streak∧G1∧G2∧G3/panel/light/settle 結清)→收斂+天花板提醒+golden凍結→writing-plans｜平行panel模式(現行推薦,一輪W席≤3輪)見下方KEY
governance/golden/idioms-self-maint/spec.md:48:    why_chosen: 架構已穩、續推邊際遞減且接縫需真build(非spec patch);凍成golden保住三輪findings語料+架構決策,實作另議。phase-1只做真做得出的M層+人跑skill,C3/全自動列phase-2
governance/golden/loop機械脊椎M1包/findings.md:18:## 審計員校準數據（golden 語料）
docs/lumos-toolchain-knowledge/Systems/slim-skill-修剪.md:16:  KEY:★2026-08-01 補一條非指令型的懸空引用★——reference.md:679「設計全文與三輪對抗審:`Projects/from-scratch重生守衛_計劃`+`governance/golden/fromscratch-m1/`」指向本包完全未交付的檔案,接手者查無此檔且無人可問;改寫成「留在完整版工具鏈,★本精簡版沒有交付那些檔案★——這裡列的規則本身就是全部,不必去找」。★方法論教訓★:`slim-scan.py` 只掃指令名(prefixed/bare-token/skill-name/span/prose 五形態),★掃不到路徑型懸空引用★(架構圖節點路徑、governance/ 語料目錄)——與「任何『我枚舉了 N 種形態』的規格都要假設有第 N+1 種」同型,本次由人眼逐檔複閱補上,不宣稱已窮盡
governance/golden/t3-dref/spec.md:3:> **狀態**：達 3 輪 panel cap 未 clean 收斂 → 人裁「凍 golden、暫停實作」（2026-07-15）。
governance/external-reviews/2026-07-28-codex-initial.md:198:- capture counts、cluster、golden replay
governance/external-reviews/2026-07-28-codex-initial.md:283:11k CLI、11k tests、49 commands、多代 loop gate、skills/reference/golden/graph/methodology 多份真相同時存在。已出現：
governance/golden/t3-dref/findings.md:39:→ **達 3 輪 panel cap 未 clean 收斂**（非收斂localized 在 rejected-memory late add-on）。收斂到明確 v4 方向（見 spec.md §v4）→ 人裁凍 golden、暫停實作。
governance/golden/retrieval/spec.md:24:PRIOR-ART: 見 [[Projects/檢索優化_調研]]（deep-research 3 票查證）。**本計劃為雙盲草案合併**：Claude 與 GPT-5.6（Codex CLI）各自獨立出案後擇優——分歧裁定見下表，兩份原始草案存 governance/golden/retrieval-drafts/。裁定=borrow-design，stdlib 原生。
governance/golden/retrieval/spec.md:268:- **goldset schema（r2 折入 r3 補正——r2 錨點沾考題字樣對真檔落空，審計紀錄先於正文,本輪修復）**：`governance/eval/retrieval-goldset.json` = `{"snapshot_commit","split_salt","search":[{"id","query","split"}],"edit":[{"id","file","delta","split"}],"labels":{"<case_id>":{"<node>":{"claude","codex","final"}}}}`；60/40 由 `split` 欄凍結，切分演算法=`sha256(id+split_salt)` 前綴取模（可重現）。held-out 僅 ~12/8 例、統計力弱——15% gate 以方向一致+效應量解讀，不做顯著性宣稱。
governance/golden/retrieval/spec.md:269:- **評測器（同上補正）**：獨立腳本 `governance/eval/retrieval_eval.py`（非 lumos 子命令——評測屬治理面），跑法 `python3 governance/eval/retrieval_eval.py [--split train|held] [--build-pool]`；讀 goldset + 呼叫 `lumos search/impact --ranked --json` 算指標，逐輪 append `governance/eval/retrieval-eval-history.jsonl`；cochange proxy 過濾在此腳本內。**目錄分工**：`governance/golden/` 存收斂快照（design-loop 產物）、`governance/eval/` 存評測資產——兩者不混。
governance/golden/retrieval/spec.md:292:- **cochange 金標 proxy（r1 修正）**：`lumos cochange rules`（**預設門檻**——`--all` 是解除門檻、與「高 conf」意圖相反）的規則，過濾兩端皆在 docs/*-knowledge 的對、方向規則取無向 max(conf)——作為 **related/hook 面**的免標註相關對（無 query 詞、不適用 search 評測）；快速 A/B 迭代用，正式驗收仍走人工標註（§6）。稀疏 fallback：99 節點的 knowledge git 史可能出不了幾條 conf≥0.8 對——proxy 空/過稀時退回純人工 goldset,不阻斷。
governance/golden/retrieval/spec.md:298:- **r3（2026-07-10，終輪：1 opus delta + Codex 終審；canary 1/1 caught（b 型幽靈旗標+指出與裁定相衝,probe:recraft×1→pass）、0 missed → 連續第三輪 near-perfect）**：Codex 終審 1 major（「任意 hop 合約固定席」與 depth≤2 候選池矛盾→改「有效深度內」+誠實限定深度外不保證;全圖掃描留 v2）;opus 7 major+6 minor 全屬補丁殘留——**其中揭出 r2 折入事故：兩條折入錨點沾考題字樣、對真檔靜默落空（goldset schema/評測器跑法「紀錄宣稱已折、正文沒有」）→ 本輪以真錨點+assert 補正**（教訓：折入 anchor 禁止取自工作副本文字,一律取真檔原文;此為 fold-check 該擋而未擋的型——錨點污染,記入 canary-audit 未來方向）;其餘：裁定表評審主體同步、COMBO 記法正名、--incidents-only/--files-only 入語法行、--limit 壞前提改寫、pooling 五→四、雙標題/跳號/硬行號清理、golden vs eval 目錄分工。
governance/golden/retrieval/spec.md:299:- **r2（2026-07-10，panel W=3：2 opus + Codex 覆核位；canary 2/2 caught（c 型未定義欄位/d 型未定義產物,probe 皆 pass）、0 missed → near-perfect；三員高度收斂〔s1 1 blocker+6 major、s2 6 major、Codex 覆核 confirm 上輪兩點修到位+點同一 gate 矛盾〕）**：折入 ~18 條——**blocker（s1/Codex 同抓）**:stdin 單載 delta 卻要兼傳 prospective content→改**單包 JSON payload（`--stdin-payload`）**含 query+prospective map,抽取規格含 replace_all/MultiEdit 失敗 fallback。**major 群**:①hop1 純圖 vs §3 動態閾值→hop1 只受靜態 0.20 底線（不與 direct 對打）②hop≥2 L>0 砍安全合約→固定席擴**任意 hop 的 ★INVARIANT★/★IRREVERSIBLE★**（回退現行 hook 行為,安全類 must-see 由固定席機保）③gate「或」殘留（增補段）→統一為「與」④§2/§3 hook active 殘句→**版本歸屬:hook 側全屬 v1.1**、v1 僅 dormant CLI+評測器⑤TTL 機制→冷卻窗內帶 delta 走 `--incidents-only` 快速模式（只跑 trigger、不 BFS）⑥prospective incident 測試補⑦goldset.json schema 明列+切分 sha256(id+salt) 可重現⑧評測器落點 `governance/eval/retrieval_eval.py`（獨立腳本非子命令）+跑法+eval-history⑨pooling 操作化（legacy/ranked/graph-only/fusion 去識別+洗牌,雙 LLM 同份不見身份）⑩計數旗標統一 `--top`。**minor**:壞行號:318 去具體化、step8 空殼刪、99 兩義、overflow 純資訊計數、cochange 稀疏 fallback、姐妹折疊測試+歸屬、Γ/len(d)/K1 尺度注記。Codex 覆核裁決:「rollout 核心已修到位;先釘死 prospective 傳輸/fallback 與 gate 與/或」→本輪全折。
governance/golden/retrieval/spec.md:301:- **r1（2026-07-10，panel W=3：2 canaried opus + **Codex/GPT-5.6 跨家族否決位首戰**；canary 2/2 caught（s1=a 型假表列引用〔probe:recraft×1,末次探針因節錄視野誤標,判 pass 附註〕、s2=b 型幽靈旗標〔probe:pass〕;token 見 canary-log r1〕）、0 missed → near-perfect 有效輪）**：折入 ~20 條——否決位 2 major（rollout 拆兩階段:hook 維持 legacy、gate 過後 opt-in——原 spec 會讓主要自動消費者未經驗證直接切 top-8；**prospective incident 修既有盲點**:content 觸發改比對套用 delta 後內容+TTL 不壓事故段——本次新增危險內容原本不會觸發事故提醒）+ s1 4 major（hop1 純圖過閾證偽原宣稱→hop≥2 需 L>0；輸出合約 8/10/5 三數統一為固定席不占 top_k+overflow=N−top_k；fusion gate baseline 統一 graph-only+「與」邏輯；〔canary〕）+ s2 4 major（hook delta 抽取規格三工具明列+512 cap 在 hook 端；overflow 綁 top_k；評審=雙 LLM 異家族+人裁；切分凍結 goldset.json+15% gate 統計力誠實限定；must-see 改固定席機械保證）+ minors（Γ 定義、len(d) 總數、K1/B 可調+尺度注記、L 全零:=0、--code/--sort/--files-only 交互、cochange proxy 用預設門檻+無向化+限 related 面、姐妹折疊鍵=去尾段、P@k 分母/label/macro/snapshot）。否決位裁決原文:「這版不能直接進實作——修 rollout、delta incident 語意、TTL 與 gate 定義後才可」→ 本輪已全部折入。
docs/lumos-toolchain-knowledge/Verification/2026-07-21_loop機械脊椎M1包.md:20:  VERIFY:spec 過 3 輪 panel(canary 1/4→4/4→2/2)+Codex 否決鏈五迭代 NO-VETO+實質收斂人裁;golden governance/golden/loop機械脊椎M1包/
docs/lumos-toolchain-knowledge/Verification/2026-07-16_dloop提效M2_cluster帳.md:22:[[Projects/design-loop提效_計劃]] M2 的實作驗證。design-loop 3 輪 panel 達 cap、人裁實質收斂(golden: `governance/golden/dloop-m2-cluster/`,Codex 否決於 v4 解除)後照 spec v4 落地。
governance/eval/multiword/adj-verdict-mw.json:21:      "why": "summary 第二條就把「事故反轉(IBIR)」列為 canary 生成硬化三條之一,是事故語料反轉成 canary 的落點節點。"
governance/eval/multiword/adj-verdict-mw.json:45:      "why": "講的是 ③ 網搜找 linter 沒收錄的新坑+反證(refute)預篩,與事故語料反轉(IBIR)無關,只是和 ④ 語料同住一個 Issue 檔。"
governance/eval/multiword/adj-verdict-mw.json:49:      "why": "★強衝突★ §3 就是查詢命題本身——「IBIR 模式:把 Issues 事故語料的修法反轉成 canary 模板、植在 pitfall_when 命中的段落」;B 判 0 極可能是看「社群演算法」檔名誤以為在談推薦演算法而沒讀內容。"
docs/lumos-toolchain-knowledge/Verification/2026-07-28_PPR邊權消融.md:7:  - "edit 卷 goldset snapshot=285d429(train 有效題 n=5)"
docs/lumos-toolchain-knowledge/Verification/2026-07-28_PPR邊權消融.md:10:  - "edit 卷擴題(free 池變大)或 goldset 換代——負結論可依 spec 同款考卷重試"
docs/lumos-toolchain-knowledge/Verification/2026-07-24_真遺忘search排除superseded.md:20:  VERIFY:design-loop 3 審收斂(2 Sonnet light+1 跨家族 Codex std,跨家族接住兩輪 Sonnet 漏的 hidden 數插點 F6+goldset 安全網破洞 F7);使用者裁定進 TDD;TDD 紅→綠
docs/lumos-toolchain-knowledge/Verification/2026-07-24_真遺忘search排除superseded.md:33:- **召回不退**：goldset §6 gate 只比相對 lift、擋不住「兩邊一起藏掉好答案」（Codex std F7）——測試改用改動前後對照式 fixture（活節點保留、只 superseded 被藏）。
governance/eval/retrieval-goldset.json:671:    "why": "第3條『事故反轉(借IBIR)』專講查事故語料把修法反轉成canary"
docs/lumos-toolchain-knowledge/Verification/2026-07-11_hook面v1.1轉正.md:5:valid_under: goldset labels 2026-07-11 定稿;凍結參數 direct_base=0.30/free_quota=10/dyn_coef=0.65(v1.2 追記由 0.55 調升;本欄原記 0.55 已過時,2026-07-20 對帳更正);Landmark 實驗場 12 真實案例
docs/lumos-toolchain-knowledge/Verification/2026-07-11_hook面v1.1轉正.md:6:revalidate_when: 排序參數再調整、goldset 重建、或 pitfall_when trigger 語意變更時重跑 §6
docs/lumos-toolchain-knowledge/Verification/2026-07-11_hook面v1.1轉正.md:23:推播面（impact ranked）從 goldset FAIL（P@8=.509）修到 §6 七盞全綠 PASS 並接上 PreToolUse hook。
docs/lumos-toolchain-knowledge/Verification/2026-07-11_hook面v1.1轉正.md:35:- **考卷段**（本 vault goldset train）量精度；**Landmark 實驗場**（12 個真實 git 改檔案例,含 `RedeemActivityService.cs` 單體怪物）量條數/延遲——**兩場同好才凍結**。
docs/lumos-toolchain-knowledge/Verification/2026-07-11_hook面v1.1轉正.md:50:2. **[major] delta-scoped trigger 的函式內部盲區**——編輯片段不含函式名時 tripwire 漏抓。修=探測範圍改「delta+±600 字元鄰域窗」(goldset 驗證噪音不回來)。
docs/lumos-toolchain-knowledge/Verification/2026-07-11_hook面v1.1轉正.md:52:4. **[major,方法論] 評測可重現性**——活語料漂移使 P@8 隨「寫文件」±1pp 擺動。修=評測預設釘 goldset snapshot worktree(edit 面走 --repo——實測 impact 不吃全域 --vault);史帳記 eval_head+旋鈕。
docs/lumos-toolchain-knowledge/Verification/2026-07-11_hook面v1.1轉正.md:62:重跑釘定快照(`retrieval_eval.py --goldset ...`,即凍結配置 dyn_coef=0.65/direct_base=0.30/free_quota=10):
docs/lumos-toolchain-knowledge/Verification/2026-07-11_hook面v1.1轉正.md:97:- [[Verification/2026-07-11_檢索goldset評測]]
docs/lumos-toolchain-knowledge/Verification/2026-07-10_審計loop研究硬化.md:14:  - "golden replay 語料達 10+ 份(啟動 auditor 校準與 conformal 校準集議題)"
governance/eval/retrieval-labeling-sheet.md:4:**留白 = 0(噪音)**,所以只要標有價值的,省力。標完存檔告訴 Claude 解析回 goldset。
governance/eval/build_goldset.py:2:"""生成 retrieval goldset 骨架 + 人工標註表(spec:檢索優化_計劃 §6)。stdlib。
governance/eval/build_goldset.py:3:跑法: python3 governance/eval/build_goldset.py
governance/eval/build_goldset.py:4:產出: retrieval-goldset.json(骨架,labels 空) + retrieval-labeling-sheet.md(人標)
governance/eval/build_goldset.py:45:  # 舊行為。本函式要的是★片語語意的候選池★,吃到回退擴召回會讓 goldset/評測基線
governance/eval/build_goldset.py:66:        elif line.strip() and not line.startswith("docs/") and not line.startswith("governance/golden"):
governance/eval/build_goldset.py:110:             "**留白 = 0(噪音)**,所以只要標有價值的,省力。標完存檔告訴 Claude 解析回 goldset。",
governance/eval/build_goldset.py:137:    (out / "retrieval-goldset.json").write_text(json.dumps(gs, ensure_ascii=False, indent=1), encoding="utf-8")
docs/lumos-toolchain-knowledge/Verification/2026-07-21_lumos-show讀取入口.md:20:  VERIFY:spec 過 light r1→ratchet→std panel 3 輪+Codex 否決席 3 次介入,實質收斂人裁(2026-07-21);golden 凍結 governance/golden/lumos-show讀取入口-std/
governance/eval/multiword/mw-labels-final.json:153:   "why": "summary 第二條就把「事故反轉(IBIR)」列為 canary 生成硬化三條之一,是事故語料反轉成 canary 的落點節點。"
governance/eval/multiword/mw-labels-final.json:205:   "why": "講的是 ③ 網搜找 linter 沒收錄的新坑+反證(refute)預篩,與事故語料反轉(IBIR)無關,只是和 ④ 語料同住一個 Issue 檔。"
governance/eval/multiword/mw-labels-final.json:222:   "why": "★強衝突★ §3 就是查詢命題本身——「IBIR 模式:把 Issues 事故語料的修法反轉成 canary 模板、植在 pitfall_when 命中的段落」;B 判 0 極可能是看「社群演算法」檔名誤以為在談推薦演算法而沒讀內容。"
docs/lumos-toolchain-knowledge/Verification/2026-07-11_檢索goldset評測.md:5:valid_under: goldset snapshot=labels 定稿於 2026-07-11(50 案例/424 候選);vault 99 節點規模;BM25F/融合參數現值
docs/lumos-toolchain-knowledge/Verification/2026-07-11_檢索goldset評測.md:6:revalidate_when: vault 節點數倍增、排序參數(欄位權重/K1/B/融合 0.6-0.4)調整、或 goldset 重建時重跑
docs/lumos-toolchain-knowledge/Verification/2026-07-11_檢索goldset評測.md:16:  VERIFY:goldset+評審底稿凍 governance/eval/(raters/ 四份 JSON+指引);評測器 goldset 模式 fail-closed(空標 FAIL)
docs/lumos-toolchain-knowledge/Verification/2026-07-11_檢索goldset評測.md:18:# 2026-07-11_檢索goldset評測
docs/lumos-toolchain-knowledge/Verification/2026-07-11_檢索goldset評測.md:23:人工 goldset(50 案例/424 候選)雙 AI 盲標定稿後,跑 `retrieval_eval.py --goldset` 的 §6 gate 首次正式評測。
docs/lumos-toolchain-knowledge/Verification/2026-07-11_檢索goldset評測.md:60:**可重現性與漂移（r2 Codex 複核折入）**：本表數字快照於 eval 當下 HEAD（見 eval-history 的 `eval_head` 欄）;vault 是活語料——之後任何節點增修（含本篇更正本身）會使 ranked 分數 ±1pp 內漂移，屬評測特性非 bug。嚴格重現=checkout 該 `eval_head` 重跑 `retrieval_eval.py --goldset`。gate 各條的判定方向在漂移幅度內穩定。
docs/lumos-toolchain-knowledge/Verification/2026-07-11_檢索goldset評測.md:64:- `governance/eval/retrieval_eval.py` goldset 模式(nDCG/MRR/P/Recall+§6 gate,fail-closed)
docs/lumos-toolchain-knowledge/Verification/2026-07-11_檢索goldset評測.md:65:- `governance/eval/retrieval-goldset.json` labels 定稿(claude/codex/final+裁決出處)
docs/lumos-toolchain-knowledge/Verification/2026-07-11_檢索goldset評測.md:67:- `governance/eval/retrieval-eval-history.jsonl` 首筆 goldset 紀錄
docs/lumos-toolchain-knowledge/Verification/2026-07-16_replay校準baseline_v0.md:11:valid_under: "golden 語料=2026-07 世代;受試模型 haiku 4.5/sonnet;2 spec(fromscratch-m1/dloop-m2-cluster)×2 模型×釘住/未釘=8 席"
docs/lumos-toolchain-knowledge/Verification/2026-07-16_replay校準baseline_v0.md:12:revalidate_when: "模型換代、golden 語料格式變更、replay 協議(釘定/prompt)修訂時重跑"
docs/lumos-toolchain-knowledge/Verification/2026-07-16_replay校準baseline_v0.md:17:  KEY:★replay 方法論鐵則三條(v0 主產出)★——①golden 凍的是折入後 spec,replay 受試對象必須從 git 史撈前折 v1 ②repo 必須 worktree 釘在該 loop 開跑時的 commit(否則實作後 code=答案卡:haiku 抄答案/演化殘影被當缺陷) ③prompt 必須明示「spec 提案的新機制 code 尚未實作=正常」(否則弱模型刷範疇錯誤:把提案未實作當 blocker)
docs/lumos-toolchain-knowledge/Verification/2026-07-16_replay校準baseline_v0.md:22:[[Projects/loop數據收集_計劃]] 的獨立實驗首跑。受試:fromscratch-m1 與 dloop-m2-cluster 兩份 spec 的前折 v1(git 史 5db767b/36540f5)+ 對應釘住 worktree;golden findings 當標籤。
docs/lumos-toolchain-knowledge/Verification/2026-07-16_replay校準baseline_v0.md:41:① 受試=前折 v1(git 史撈),golden 凍的折後版只能當標籤源;② repo 釘 worktree 於同期 commit;③ prompt 明示提案語意。三條缺一,分數即污染。
docs/lumos-toolchain-knowledge/Verification/2026-07-29_CI回流閉環v1落地.md:81:- 掃描對象由手維護的三檔清單改為**全部活文件**（排除外審歸檔與 `governance/golden/` 這兩類不得回改的歷史）。
governance/eval/retrieval_eval_multiword.py:71:        gold = labels.get(cid, {})
governance/eval/retrieval_eval_multiword.py:74:        all_rels = list(gold.values())
governance/eval/retrieval_eval_multiword.py:79:        base_lab = [gold.get(x, 0) for x in base]
governance/eval/retrieval_eval_multiword.py:80:        fb_lab = [gold.get(x, 0) for x in fb]
governance/eval/retrieval_eval_multiword.py:91:            "top1_label": (gold.get(fb[0], 0) if fb else None),
docs/lumos-toolchain-knowledge/Verification/2026-07-10_檢索排序v1.md:12:  - "人工 goldset 評測跑完(翻預設 gate)"
docs/lumos-toolchain-knowledge/Verification/2026-07-10_檢索排序v1.md:37:- 負面實證：cochange proxy 金標兩 vault 皆稀（1/0 seeds）→ 正式評測須人工 goldset。
docs/lumos-toolchain-knowledge/Verification/2026-07-31_公開精簡版交付.md:9:  - "goldset 30 條等價驗證跑在 docs/lumos-toolchain-knowledge 這份 vault 的當下內容(對照組=scripts/lumos,實驗組=dist/scripts/lumos 同一次生成的產物)"
docs/lumos-toolchain-knowledge/Verification/2026-07-31_公開精簡版交付.md:12:  - "governance/eval/retrieval-goldset.json 的 search 鍵條目變動 → 第3/第5道等價驗證需重跑"
docs/lumos-toolchain-knowledge/Verification/2026-07-31_公開精簡版交付.md:23:  KEY:goldset search 30 條全量等價 0 不一致(完整版 vs 精簡版 `--files-only` 逐條 stdout 相同)
docs/lumos-toolchain-knowledge/Verification/2026-07-31_公開精簡版交付.md:97:gs = json.load(open("governance/eval/retrieval-goldset.json"))
docs/lumos-toolchain-knowledge/Verification/2026-07-16_fromscratch守衛M1_CheckJ.md:22:[[Projects/from-scratch重生守衛_計劃]] M1 的實作驗證。design-loop 3 輪 panel 人裁實質收斂（golden: `governance/golden/fromscratch-m1/`）後照 spec v4 落地。
docs/lumos-toolchain-knowledge/Verification/2026-07-31_公開精簡版終審修復.md:7:  - "以本次修復當下的 scripts/lumos(24 支保留指令白名單)與 governance/eval/retrieval-goldset.json(30 條 search 查詢)為準;白名單或 goldset 改動需重跑 t_slim_gate 全批"
docs/lumos-toolchain-knowledge/Projects/decision_refs自動養成_實作計畫.md:20:  - content: T3 design-loop 達 3 輪 panel cap 未 clean 收斂、人裁凍 golden 暫停實作(2026-07-15):核心穩、非收斂集中在 v3 硬加的 rejected-memory+backlog 判準;v4 收斂方向=砍 rejected-memory 回雙欄+backlog 改集合差(B 洞)+count-check 精確化;T1 已交付真價值,T3 是窄覆蓋小加分
docs/lumos-toolchain-knowledge/Projects/decision_refs自動養成_實作計畫.md:23:    why_chosen: design-loop 的價值不只抓 bug,也體檢『功能值不值得』——連兩輪暗示『別再堆小功能大機械』。凍 v4 收斂方向進 golden 待日後真需要;T1 繼續自我養成,不損失。簡化實作是乾淨路徑但換來的價值 design-loop 已判小
docs/lumos-toolchain-knowledge/Projects/decision_refs自動養成_實作計畫.md:58:> **進度（2026-07-15）**：P ✅ + T1 ✅（[[Verification/2026-07-15_decision_refs養成_P前置_T1回寫]]）+ code-loop 硬化 ✅（異質 panel 5 修，[[Verification/2026-07-15_decision_refs養成_codeloop硬化]]，1130 tests 綠）→ **T3 🧊 凍結（達 design-loop 3 輪 cap、人裁暫停實作，見 decisions#d1 + `governance/golden/t3-dref/`；v4 簡化方向已定向，日後真需要再撿）**。T1 繼續自我養成，不損失。
docs/lumos-toolchain-knowledge/Projects/decision_refs自動養成_實作計畫.md:66:> **🧊 凍結（2026-07-15，decisions#d1）**：design-loop 達 3 輪 panel cap 未 clean 收斂 → 人裁凍 golden、暫停實作。下方 v3 spec 保留為凍結快照；**收斂到的 v4 簡化方向**（砍 `decision_refs_rejected` 回雙欄 + backlog 改集合差 + candidates 讀側去重 + count-check 精確化）記在 `governance/golden/t3-dref/spec.md` 的 §v4 段。日後真需要 T3，撿 v4 直接實作（實作前 v4 本身重跑一輪 panel 確認簡化無新洞）。
docs/lumos-toolchain-knowledge/Projects/decision_refs自動養成_實作計畫.md:108:**🧊 T3 loop 結局（2026-07-15）**：跑滿 3 輪 panel（12→6→5 findings，canary 全 caught）未 clean 收斂——非收斂 localized 在 v3 晚加的 `decision_refs_rejected`（否決記憶）半成品。人裁凍結（decisions#d1）、暫停實作。golden 已凍在 `governance/golden/t3-dref/`（spec.md + findings.md）。**T1 仍是已交付的真價值，繼續自我養成。**
governance/eval/retrieval-eval-history.jsonl:2:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 57.0, "search_gate": true, "hook_p_gate": false, "hook_p": 0.5179, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}, "train": {"search_lift_pct": 44.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.4722, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:3:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false}, "pass": false, "verdicts": {"train": {"search_lift_pct": 43.4, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:4:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false}, "pass": false, "verdicts": {"train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:5:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false}, "pass": false, "verdicts": {"train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:6:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false}, "pass": false, "verdicts": {"train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.625, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:7:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false}, "pass": false, "verdicts": {"held": {"search_lift_pct": 106.8, "search_gate": true, "hook_p_gate": false, "hook_p": 0.4583, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:8:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false}, "pass": false, "verdicts": {"held": {"search_lift_pct": 106.8, "search_gate": true, "hook_p_gate": false, "hook_p": 0.4583, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:9:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false}, "pass": false, "verdicts": {"held": {"search_lift_pct": 106.8, "search_gate": true, "hook_p_gate": false, "hook_p": 0.4583, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:10:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": false, "hook_p": 0.5089, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}, "held": {"search_lift_pct": 106.8, "search_gate": true, "hook_p_gate": false, "hook_p": 0.4583, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:11:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": false, "hook_p": 0.5089, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}, "held": {"search_lift_pct": 106.8, "search_gate": true, "hook_p_gate": false, "hook_p": 0.4583, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:12:{"mode": "goldset", "ts": "2026-07-11", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 57.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.5089, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}, "held": {"search_lift_pct": 104.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.4583, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_see_recall": 1.0}}}
governance/eval/retrieval-eval-history.jsonl:13:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "4f436e0", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": false, "非固定 p95 ≤ top_k+2": false, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 57.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.5089, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_in_out_recall": 1.0, "must_pinned_count": 1}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_in_out_recall": 1.0, "must_pinned_count": 1}, "held": {"search_lift_pct": 104.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.4583, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": false, "free_p95_le_topk2": false, "must_in_out_recall": 1.0, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:14:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "5f38b65", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": false, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 57.6, "search_gate": true, "hook_p_gate": true, "hook_p": 0.707, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": false, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8629, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 104.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6204, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": false, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:15:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "5f38b65", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": true, "verdicts": {"all": {"search_lift_pct": 57.6, "search_gate": true, "hook_p_gate": true, "hook_p": 0.706, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6333, "must_pinned_count": 0}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}, "held": {"search_lift_pct": 104.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6019, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": false, "must_in_out_recall": 0.6, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:16:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "5f38b65", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": false, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 57.6, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7994, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.5667, "must_pinned_count": 0}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": true, "hook_p": 1.0, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}, "held": {"search_lift_pct": 104.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.688, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.5, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:17:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "5f38b65", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": true, "verdicts": {"all": {"search_lift_pct": 57.6, "search_gate": true, "hook_p_gate": true, "hook_p": 0.707, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8629, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 104.7, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6204, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:18:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "22ca311", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.4, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6917, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 1}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8533, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 1}, "held": {"search_lift_pct": 109.5, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6019, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:19:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "22ca311", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.4, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6917, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 1}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8533, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 1}, "held": {"search_lift_pct": 109.5, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6019, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:20:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "22ca311", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.4, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6951, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8629, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 109.5, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6019, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:21:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "22ca311", "knobs": {"LUMOS_IMPACT_TRIG_WIN": "0"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.4, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6951, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8629, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 109.5, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6019, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:22:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "22ca311", "knobs": {"LUMOS_IMPACT_TRIG_WIN": "600"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.4, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6951, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 44.7, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8629, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 109.5, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6019, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:23:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "22ca311", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6951, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8629, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6019, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:24:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "22ca311", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6998, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8429, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6204, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:25:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "22ca311", "knobs": {"LUMOS_IMPACT_TRIG_WIN": "0"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6998, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8429, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6204, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:26:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "22ca311", "knobs": {"LUMOS_IMPACT_TRIG_WIN": "300"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6998, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8429, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6204, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:27:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "cf4be7e", "knobs": {"LUMOS_RANK_AUTH_W": "0", "LUMOS_RANK_STATUS_MULT": "1.0"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": false, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true}, "pass": false, "verdicts": {"train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8429, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:28:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "cf4be7e", "knobs": {"LUMOS_RANK_AUTH_W": "0", "LUMOS_RANK_STATUS_MULT": "0.4"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": false, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true}, "pass": false, "verdicts": {"train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8429, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:29:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "cf4be7e", "knobs": {"LUMOS_RANK_AUTH_W": "0.1", "LUMOS_RANK_STATUS_MULT": "1.0"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true}, "pass": true, "verdicts": {"train": {"search_lift_pct": 43.8, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8164, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:30:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "cf4be7e", "knobs": {"LUMOS_RANK_AUTH_W": "0.1", "LUMOS_RANK_STATUS_MULT": "0.4"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true}, "pass": true, "verdicts": {"train": {"search_lift_pct": 43.8, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8164, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:31:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "cf4be7e", "knobs": {"LUMOS_RANK_AUTH_W": "0.2", "LUMOS_RANK_STATUS_MULT": "1.0"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true}, "pass": true, "verdicts": {"train": {"search_lift_pct": 41.4, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7664, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:32:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "cf4be7e", "knobs": {"LUMOS_RANK_AUTH_W": "0.2", "LUMOS_RANK_STATUS_MULT": "0.4"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true}, "pass": true, "verdicts": {"train": {"search_lift_pct": 41.4, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7664, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:33:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "cf4be7e", "knobs": {"LUMOS_RANK_AUTH_W": "0"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6998, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8429, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6204, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:34:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "cf4be7e", "knobs": {"LUMOS_RANK_AUTH_W": "0.1"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 57.9, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6529, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 43.8, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8164, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 106.3, "search_gate": true, "hook_p_gate": false, "hook_p": 0.562, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:35:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "79e26d7", "knobs": {"LUMOS_IMPACT_PIN_HOP": "2", "LUMOS_IMPACT_DYN_COEF": "0.55"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6998, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8429, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6204, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:36:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "79e26d7", "knobs": {"LUMOS_IMPACT_PIN_HOP": "2", "LUMOS_IMPACT_DYN_COEF": "0.65"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": true, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7298, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6333, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6389, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:37:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "79e26d7", "knobs": {"LUMOS_IMPACT_PIN_HOP": "1", "LUMOS_IMPACT_DYN_COEF": "0.55"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6998, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8429, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 1.0, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6204, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:38:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "79e26d7", "knobs": {"LUMOS_IMPACT_PIN_HOP": "1", "LUMOS_IMPACT_DYN_COEF": "0.65"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": true, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7298, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6333, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6389, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:39:{"mode": "goldset", "ts": "2026-07-11", "eval_head": "79e26d7", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": true, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7298, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6333, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6389, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:40:{"mode": "goldset", "ts": "2026-07-20", "eval_head": "f99efb5", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": false, "fusion 勝 BM25-only": false, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": false, "verdicts": {"all": {"search_lift_pct": 84.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6226, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6667, "must_pinned_count": 0}, "train": {"search_lift_pct": 68.3, "search_gate": true, "hook_p_gate": true, "hook_p": 0.76, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.8, "must_pinned_count": 0}, "held": {"search_lift_pct": 143.8, "search_gate": true, "hook_p_gate": false, "hook_p": 0.5463, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:41:{"mode": "goldset", "ts": "2026-07-20", "eval_head": "f99efb5", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": true, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7298, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6333, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6389, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:42:{"mode": "goldset", "ts": "2026-07-20", "eval_head": "f99efb5", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": true, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7298, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6333, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6389, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:43:{"mode": "goldset", "ts": "2026-07-20", "eval_head": "f99efb5", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": true, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7298, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6333, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6389, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:44:{"mode": "goldset", "ts": "2026-07-28", "eval_head": "862d638", "knobs": {"LUMOS_IMPACT_PPR": "flat"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": false, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true}, "pass": false, "verdicts": {"train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:45:{"mode": "goldset", "ts": "2026-07-28", "eval_head": "862d638", "knobs": {"LUMOS_IMPACT_PPR": "flat"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": false, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true}, "pass": false, "verdicts": {"train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:46:{"mode": "goldset", "ts": "2026-07-28", "eval_head": "862d638", "knobs": {"LUMOS_IMPACT_PPR": "cochange"}, "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": false, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true}, "pass": false, "verdicts": {"train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:47:{"mode": "goldset", "ts": "2026-08-03", "eval_head": "8680ac1", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": true, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7298, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6333, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6389, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6, "must_pinned_count": 0}}}
governance/eval/retrieval-eval-history.jsonl:48:{"mode": "goldset", "ts": "2026-08-03", "eval_head": "a226fc5", "knobs": "frozen-defaults", "vault_note": "活語料:節點增修致數字 ±1pp 漂移;重現=checkout eval_head 重跑", "k": 8, "gates": {"search nDCG@5 提升≥15%": true, "hook P@top_k ≥0.70": true, "fusion 勝 BM25-only": true, "fusion 勝 graph-only": true, "非固定中位 ≤ top_k": true, "非固定 p95 ≤ top_k+2": true, "held-out 不倒退(lift>0)": true}, "pass": true, "verdicts": {"all": {"search_lift_pct": 58.1, "search_gate": true, "hook_p_gate": true, "hook_p": 0.7298, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6333, "must_pinned_count": 0}, "train": {"search_lift_pct": 46.0, "search_gate": true, "hook_p_gate": true, "hook_p": 0.8933, "fusion_vs_bm25": false, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.7, "must_pinned_count": 0}, "held": {"search_lift_pct": 99.6, "search_gate": true, "hook_p_gate": false, "hook_p": 0.6389, "fusion_vs_bm25": true, "fusion_vs_graph": true, "free_median_le_topk": true, "free_p95_le_topk2": true, "must_in_out_recall": 0.6, "must_pinned_count": 0}}}
governance/autonomous_loop/orchestrator-prompt.md:53:   **收斂即凍結(§2.5 過後)**:把最終 spec 快照 + 各輪辯方裁決後存活 findings 清單凍進 `<REPO>/governance/golden/<topic>/`(spec.md + findings.md;零判斷純搬運)——golden 語料供日後 auditor replay 校準(borrow:Giskard)。
docs/lumos-toolchain-knowledge/Projects/canary注意力檢查失效.md:26:  PRIOR-ART:①最小解在既有機制層——改 `lumos-design-loop/templates.md` 的抑噪紀律措辭 ＋/或 canary 型別清單,不動任何碼、不造新機制 ②世界解過=調查方法學的 attention check／instructed manipulation check:公認做法是「covert、與題材同型、嵌進真題裡」而非讓它突出;且 ★單一 check 不足以判定不專心★(Prolific 政策:>5 分鐘的研究須失敗 ≥2 次才可拒絕),★通過一個 check 不預測通過另一個★ ③裁定=borrow-design(借 attention-check 方法學,零依賴)
docs/lumos-toolchain-knowledge/Projects/canary注意力檢查失效.md:118:Prolific（大規模跑這件事的商業平台）的政策：**超過 5 分鐘的研究，受試者必須失敗
docs/lumos-toolchain-knowledge/Projects/canary注意力檢查失效.md:142:**C. 一席多 canary（借 Prolific 的「失敗兩次才判」）**
docs/lumos-toolchain-knowledge/Projects/canary注意力檢查失效.md:283:  ★Prolific 對 >5 分鐘的研究要求失敗 ≥2 次才可拒絕★。
docs/lumos-toolchain-knowledge/Projects/design-loop判準重定位.md:29:  PRIOR-ART:★①原答「不造新機制」是錯的(r1 查證推翻)★——M2 cluster 帳已是幾乎等價的處置帳:`CLUSTER_STATES=(resolved,accepted-minor,disputed-major)`、accepted-minor ★已機械強制內嵌理由★、其閘實測只有兩條(輪無效/disputed-major)★沒有存活≤minor★,且有 golden fixture。原案是在同一函式群造第二套平行實作=d2 否決 C 案時引的「多份實作立刻漂移」。★修正後的①=擴充既有 cluster 帳(如允許 accepted-major:理由)+讓它不再是沒人選的 opt-in★ ②世界解過=GitHub/GitLab conversation-resolution 合併閘(OpenSSF 最佳實務);capture-recapture 原始文獻自陳非 hard gate ③裁定=borrow-design(零依賴)
docs/lumos-toolchain-knowledge/Projects/design-loop判準重定位.md:433:| 1 | PRIOR-ART「最小解在既有機制層——**不造新機制**」 | `grep CLUSTER_STATES` → `("resolved", "accepted-minor", "disputed-major")`；`accepted-minor` **已機械強制內嵌理由**；cluster 閘實測只有兩條（輪無效／disputed-major），**沒有存活≤minor** | ★**地基錯誤**★：提案的「處置帳」已上線、有閘、有 golden fixture。原案是在同一函式群造第二套平行實作——正是 d2 否決 C 案時引的「多份實作立刻漂移」 |
docs/lumos-toolchain-knowledge/Projects/skill寫法學借鑒與design-loop剪枝.md:152:- 剪枝的收益（模型更可靠地走同一條路）**沒有機械量測**。本次不宣稱行為改善，只宣稱「規則沒少、字數變少、單行不再破千字」。真要驗，得拿 golden 語料做 replay 對照，那是另一個題目。
docs/lumos-toolchain-knowledge/Projects/檢索PPR邊權_計劃.md:16:  KEY:[r1 樞紐重定向]目標面=**edit(impact hook 推薦)**非 related——r1 light 審出考卷實況:goldset 無 related 人工分卷,唯一 related 自動評測以 cochange 當金標=treatment 洩入 oracle 必自我確證(循環);edit 卷=人工標註+train/held 切分俱在,且 PPR 種子導向天然合 edit 面(diff 命中節點=種子)。PPR(personalization 種子向量,對稱化圖)+cochange 邊權(僅加權既有邊);**轉正閘=edit 卷 A/B:train 網格、held 確認、容忍帶內退步即殺+刪碼(A3 前例)**。源=2026-07-28 閉環盤點②
docs/lumos-toolchain-knowledge/Projects/檢索PPR邊權_計劃.md:26:PRIOR-ART: ① 最小解層級——[[Projects/中心性重驗排程_計劃]] 已落 `_graph_pagerank(env, personalization=None)`，本計劃啟用參數位；cochange 挖掘複用 `_cochange_mine`。② 世界解——HippoRAG/fast-graphrag 以 PPR 做檢索傳播（2026 共識）；**在地反證必答**：A3（in-degree 加分）goldset 雙面被殺——PPR 與 in-degree 的差異＝**種子導向**（從 seed 傳播的個人化分數，非全域權威度），這正是 A3 死因（全域樞紐≠對此 seed 相關）所不涵蓋的軸；但此差異是假設，**考卷裁決，輸即殺**。③ 裁定=borrow-design。
docs/lumos-toolchain-knowledge/Projects/檢索PPR邊權_計劃.md:55:- r3-std panel（2026-07-28,cap=3 終輪,canary=`goldset run-id` 假對帳鍵／ghosts 政策假援引／`--pin-remote` 假旗標:**3 席全 caught**;輪存活 blocker）：**blocker**＝eval(top50/quota10) vs hook(top8) 參數錯位使「閾後純重排」同構斷裂→重排改閾後截斷前+S4c 參數對齊。**major 批**＝裁決單位未定（殺整包 vs 轉正勝臂矛盾格）→逐臂三態重寫+嚴格勝=帶外+macro 聚合+b2 獨勝歸因債如實;[S4] 降級路自相矛盾→拆 S4a 硬前置(封存)/S4b 軟前置/守衛交互與 snapshot 歸屬補;A3 程序三度不符→忠實轉述不再稱範式;母體閾前後歧義→定死截斷前。**minor 批**＝(b) 記號、融合式明文、moc sentinel、_dbase 歸因、PPR knob 命名、macro 明文。**達 cap 攤牌**。

codex
目前抓到兩個結構性破口：錨定若對「折入後的現檔」grep，會把 finding 自己新增的文字當成原文而假綠；留痕若只在寫入時驗存在，之後刪檔仍可能放行。再核數據分母與既有 cluster 語意後收斂清單。
import json,collections
rs=[json.loads(x) for x in open('docs/.canary-log.jsonl') if x.strip()]
print('total',len(rs),collections.Counter(r.get('kind') for r in rs))
for pref in ['design','code']:
 x=[r for r in rs if str(r.get('loop','')).startswith(pref)]
 print(pref,len(x),collections.Counter(r.get('kind') for r in x),collections.Counter(r.get('severity') for r in x))
loop=[r for r in rs if r.get('loop')]
print('loop records',len(loop),'clean severity',sum(r.get('severity')=='clean' for r in loop),'unique loops',len(set(r['loop'] for r in loop)))
print('caught/missed only',sum(r.get('kind') in ('caught','missed') for r in rs))
print('second',sum(r.get('kind')=='second' for r in rs))
PY
nl -ba /tmp/dlrd-r1.md | sed -n '1,150p'
nl -ba scripts/lumos | sed -n '3020,3130p'
nl -ba scripts/lumos | sed -n '3744,3860p'" in /Users/enzo/harness/lumos-toolchain
zsh:1: can't create temp file for here document: operation not permitted
     1	---
     2	type: project
     3	status: doing
     4	created: 2026-08-04
     5	updated: 2026-08-04
     6	related:
     7	  - "[[Systems/design-loop]]"
     8	  - "[[Systems/canary-audit]]"
     9	  - "[[Systems/loop-convergence-recording]]"
    10	  - "[[Systems/convergence-evidence-gate]]"
    11	  - "[[Projects/canary注意力檢查失效]]"
    12	  - "[[Projects/design-loop判準重定位]]"
    13	  - "[[Projects/design-loop提效_計劃]]"
    14	tags:
    15	  - type/project
    16	  - status/doing
    17	summary: |-
    18	  FLAG:DECISION
    19	  KEY:★定位(使用者 2026-08-04 確認)★——design-loop=實作前的★便宜初篩網★,抓「十塊錢就能抓到的缺陷」(矛盾/未定義詞/缺失敗路徑)一輪放行;★正確性歸下游 TDD+E2E(真 oracle 在那裡)★;終極要能★無人自跑★——一道從不亮綠燈的閘放進自主 loop=每件事卡死等人,自動化是假的
    20	  KEY:★全流程體檢結論(2026-08-04,十一站逐站查)★——真機械的只有 G3 hash 一個;gate 實測 ★1/38、panel 0/23 從未放行★(37/38 靠人裁/cap 出場);canary 判定 334 筆★無留痕不可稽核★(歷史 81.5% caught 率永遠查不出真假);S2 抽樣/cluster 帳/min-seats/tier 四個機制★蓋好沒人用★(同日四例=系統病:每個機制都在等一個記得用它的人,而那個人不存在)
    21	  KEY:★重設計原則(一句話)★——閘只留可重算的;其餘全部降級成★強制留痕★的觀測;lumos 已知的值★預設而非選配★
    22	  KEY:★canary 裁定:退出逐輪 gate,退到離線校準★——今天實測:r1 四個 missed 席交出整輪最有價值的發現(含打掉提案地基的那條;r1=[[Projects/design-loop判準重定位]] 的第一輪 panel),★間接證據(抓埋伏)在否決直接證據(經查證的 findings)★;canary 唯一有資訊量的場景=審查員回報 clean,而 184 筆帳裡 clean 只有 1 筆——守一個幾乎不發生的情況,代價是每輪植入+判定+誤殺真發現
    23	  KEY:★取代 canary 的三件套★——①錨定檢查(機械):每條 finding 必須引用文件真實存在的原文,grep 可驗、零成本、不需植入不需人判;夢遊模型編的 finding 錨不到真文字 ②席間對照(觀測):四席各交 8 條、一席說全乾淨→那席可疑記帳;panel 本身就是注意力檢查 ③植假錯保留為★定期離線校準★(凍結語料上量「哪種配置抓得到什麼」),對齊 replay 校準構想
    24	  KEY:★誠實天花板★——五席全 clean 且同門盲點:①②接不住→下游 TDD+E2E 接(定位本來就不保正確);錨定檢查驗得了「引了真文」驗不了「推論正確」→辯方 refute 接;處置帳 folded/accepted 仍是編排者自報→算術核對+留痕買摩擦,不買防竄改
    25	  PRIOR-ART:①最小解在既有機制層——錨定檢查=把 G1 refcheck 的機械比對用到審查員產出上(自家已有的信任階梯「機械查>LLM判官」);處置帳=擴充既有 M2 cluster 帳非新造 ②世界解過(2026-08-04 網搜)——品管三件套(ACM 綜述:gold/互評/冗餘★並列★,gold 有應試缺陷「通過金標的工人照樣交低品質答案」且實務全是跨題累積統計判定,★單題一票否決無人採用★);citation grounding 文獻(CiteCheck 2026):★機械比對引文>讓 LLM 判官判可信度★;fault seeding 文獻定義=★評估檢測流程有效性的離線量測工具★(IBIR/FLAWS 原始論文全是 benchmark 用法,無一當逐輪放行條件);Prolific:>5min 研究失敗≥2 次才可拒 ③裁定=borrow-design(零依賴;真正無文獻背書的反而是現狀「單席單 canary 一票否決」)
    26	  DEP:scripts/lumos _loop_status_panel / _panel_extra_checks / cmd_canary / cmd_loop_next｜skills/lumos-design-loop/SKILL.md + templates.md｜governance/canary-samples/
    27	decisions:
    28	  - content: 定位確認:design-loop=便宜初篩網(抓便宜缺陷一輪放行),正確性歸下游 TDD+E2E,終極要能無人自跑
    29	    id: d1
    30	    context: 全流程體檢發現 gate 從未放行(1/38)、每次靠人裁繞過;追問後使用者確認 d4 定位並補述:下游有 TDD 落地與 E2E 檢驗功能性,且治理大方向是無人看顧的自主 loop——從不亮綠燈的閘在自主 loop 裡=全部卡死等人
    31	    why_chosen: 分層生產線裡每層用它有真 oracle 的判準:設計稿是散文沒有真裁判,在這層追求證明正確是緣木求魚;初篩網的價值在覆蓋率(每份稿都過得起)不在單次深度
    32	    decided: 2026-08-04
    33	    valid: true
    34	  - content: 重設計原則:閘只留可重算的;其餘降強制留痕的觀測;lumos 已知的值預設而非選配
    35	    id: d2
    36	    context: 五個錨只有 G3 hash 真機械;canary 判定 334 筆零留痕不可稽核;S2/cluster/min-seats/tier 四機制蓋好沒人用——閘與觀測倒置:該觀測的做成硬閘,該硬的(留痕/兌現)反而選配
    37	    why_chosen: 可重算=事後任何人能覆核,這是閘的最低資格;強制留痕讓觀測值未來可校準;預設化消滅「機制等一個記得用它的人」整類病。備選「全部收緊成硬閘」被否:會複製現狀(從不放行→人裁兜底→帳面假嚴謹)
    38	    decided: 2026-08-04
    39	    valid: true
    40	  - content: canary 退出逐輪 gate,退到定期離線校準;逐輪改用錨定檢查(機械)+席間對照(觀測)
    41	    id: d3
    42	    context: 實測:r1 四個 missed 席交出整輪最有價值的發現(含打掉提案地基那條)——間接證據在否決直接證據;配對實驗 n=20 整體 caught 僅 10%,歷史 81.5% 不可稽核;canary 唯一有資訊量的場景(審查員報 clean)在 184 筆帳裡只出現 1 次
    43	    why_chosen: 品管三件套文獻中 gold/互評/冗餘並列且 gold 有應試缺陷、實務全是累積統計判定,單題一票否決無人採用;citation grounding 實證機械比對引文>LLM 判官;fault seeding 文獻定義=離線量測工具(IBIR/FLAWS 皆 benchmark 用法)。查貨不查人:經查證的 findings 是「他讀了」的直接證據。備選 A(只改抑噪措辭)被否:p≈0.47 未證實其為主因且有反例;備選 B(canary 明示分離)被否:covert 變 overt 違反 attention-check 方法學
    44	    decided: 2026-08-04
    45	    valid: true
    46	---
    47	# design-loop 重設計（計劃）
    48	
    49	> **狀態**：2026-08-04 立案。吸收 [[Projects/design-loop判準重定位]]（該案不再獨立推進）與
    50	> [[Projects/canary注意力檢查失效]]（實驗與追查結論全數併入本案）。**尚未進實作。**
    51	
    52	## 一、定位（使用者確認，本案一切設計以此為準）
    53	
    54	> **design-loop 是實作前的一道便宜初篩網，不是正確性的法院。**
    55	
    56	- 抓「十塊錢就能抓到的缺陷」：自相矛盾、詞沒定義、失敗路徑沒想、明顯的洞。**抓完放行，不糾纏。**
    57	- **正確性歸下游**：TDD 落地（測試是真 oracle）＋ E2E（真跑是真 oracle）。設計稿是散文，散文沒有真裁判——在這層追求「證明沒問題」是緣木求魚（**[[Systems/design-loop]] 的決策 d4**——非本文件編號，本文件只有 d1–d3；2026-07-18 裁、2026-08-04 再確認）。
    58	- **終極要能無人自跑**（loop engineering 大方向）：一道從不亮綠燈的閘，在有人時靠人工繞過；放進自主 loop 就是全部卡死等人——★自動化是假的★。
    59	- 省輪數不是摳門：**初篩網的價值在覆蓋率**（每份稿都過得起），不在單次深度。
    60	
    61	## 二、全流程體檢（2026-08-04，問題盤點）
    62	
    63	十一站逐站查的完整記錄散在 [[Projects/design-loop判準重定位]] 與 [[Projects/canary注意力檢查失效]]，此處只留判決表：
    64	
    65	| 站 | 機制 | 判決 |
    66	|---|---|---|
    67	| 1 進場分級 | tier | 講出來的沒驗；fallback 掉最鬆檔 legacy=cap 6（見 [[Issues/loop-next吐不可宣告的tier]]，死路已修） |
    68	| 2 真相入口 | 計劃節點＋G3 hash | ✅ **真機械，留** |
    69	| 3 pre-flight | 清單掃描 | 有效，但掃的類別與 canary 同組（三方互打） |
    70	| 4 難度探針 | ±20 行片段 | 規格壞（交叉引用全變「未定義」，無鑑別力）——改餵全文 |
    71	| 5 植 canary | 每席一個 | 單一 check 訊號極弱（實測便宜模型 2/20）；文獻：通過一個不預測通過另一個 |
    72	| 6 派工 panel | 多席多鏡頭＋抑噪 | 找洞能力是真的；抑噪×canary 衝突假說未證實（p≈0.47）；派工卡死無監控（跨家族 Codex CLI 席曾 61 分鐘空跑無人察覺） |
    73	| 7 判讀 caught/missed | 編排者自判 | ★**全流程最壞**★：判定者=植入者、334 筆零留痕、歷史 81.5% 不可稽核；missed 一票否決誤殺真發現（r1 四個 missed 席交出整輪最有價值的東西） |
    74	| 8 辯方 refute | 外家反證 | 可用；留痕不足；是處置帳分母的操縱點 |
    75	| 9 折入＋fold-check | 鏡像段機械查 | 守衛真；但折入本身在生產下一輪缺陷（歷史第三輪常見的「補丁沒同步」型 findings 即此） |
    76	| 10 gate | 五條合取 | **1/38、panel 0/23 從未放行**；五個錨只有 G3 是真的 |
    77	| 11 收斂後 | golden/接受理由 | 因第 10 站不亮，歷史上全靠人裁進入 |
    78	
    79	**橫向系統病**：S2 抽樣（=canary second 第二判者抽樣分權，[[Systems/canary-audit]]；落地至今 0 次）、cluster 帳（35 個 panel loop 僅 1 個採用）、min-seats（要記得傳旗標才驗）、tier（要記得標才記帳）——
    80	★機制蓋好了，沒有任何東西在該用的時候提起它★（同日四例）。
    81	
    82	## 三、重設計原則
    83	
    84	> **① 閘只留可重算的。② 其餘全部降級成「強制留痕」的觀測。③ lumos 已知的值預設帶上，不再選配。**
    85	
    86	### 新架構：閘／觀測分層
    87	
    88	| 層 | 內容 | 為什麼 |
    89	|---|---|---|
    90	| **閘**（過不了就不放行） | G3 hash 鏈；處置帳算術（`folded+accepted==findings`＋blocker 不得 accepted）；**留痕存在性**（record 不附審查員報告→拒收）；**錨定檢查**（finding 引文 grep 不到→該條不採信） | 每一條都機械可重算、事後可稽核 |
    91	| **觀測**（記帳亮燈，不擋） | canary caught/missed（若該輪有跑離線校準型植入）；severity 分佈；capture-recapture；席間對照（clean 席 vs 產出席）；抑噪合規 | 自報或統計性訊號，當校準輸入，不當放行條件 |
    92	| **預設**（不再靠人記得） | tier 定錨、min-seats、cluster/處置帳模式——`loop next` 已算出的值自動進 record/gate | 消滅「機制蓋好沒人用」的整類病 |
    93	
    94	### canary 的去向（本案核心裁定）
    95	
    96	**退出逐輪 gate，退到定期離線校準。** 取代它的三件套：
    97	
    98	1. **錨定檢查（機械）**——每條 finding 必須引用文件裡真實存在的原文；grep 可驗。
    99	   「他讀了沒」的證明從「踩沒踩到我的陷阱」換成「他的話對不對得上原文」。
   100	   ★這是把自家信任階梯（真跑＞機械查＞LLM 判官＞自報）用到審查員產出上——與 G1 refcheck（spec→repo 引用的機械核對）同型。★
   101	2. **席間對照（觀測）**——panel 冗餘本身就是注意力檢查；全場獨我 clean 的席標記記帳。
   102	3. **離線校準（canary 的文獻本職）**——定期在凍結語料植入已知缺陷，量「哪種模型×prompt 配置抓得到什麼」，
   103	   結果用來選配置（密集 spec 直接上 opus 之類），不進任何單輪判定。對齊既有 replay 校準構想。
   104	
   105	**code-loop 不跟進**：它定位「保正確」、canary missed 率 9.3% 未見異常、其 canary 型別（off-by-one 等）
   106	有失敗場景不與抑噪互打。**先不動，觀察。**（兩份 skill 的差異要明文註記，防誤同步。）
   107	
   108	## 四、誠實天花板（先寫死）
   109	
   110	1. **五席全 clean 且同門盲點**——錨定與席間對照都接不住。下游 TDD＋E2E 接；本層定位本來就不保正確。
   111	2. **錨定檢查驗得了「引了真文」，驗不了「推論正確」**——引真文講錯話仍過錨定；靠辯方 refute 接。
   112	3. **處置帳的 folded/accepted 仍是編排者自報**——算術核對＋留痕買的是摩擦與可稽核，不是防竄改。
   113	4. **離線校準的結論會過期**——模型換代後要重跑；校準頻率是新的維護負擔。
   114	
   115	## 五、實務隱患
   116	
   117	- **錨定檢查會逼審查員多引原文**——報告變長；且「引文存在」的機械比對要處理改寫／斷行（子字串比對的正規化規則要釘死，否則變成新的假綠來源）。
   118	- **「留痕存在性」當閘**＝record 要帶報告檔路徑或內容——canary-log 是 JSONL 單行慣例，塞全文會爆；傾向存檔於 `governance/canary-samples/`（既有位置）、record 帶路徑＋sha256，**寫側驗檔案存在**。
   119	- **舊帳相容**：新閘對舊 loop 不回溯（定錨模式，同 M2 前例）。
   120	- **本案自己怎麼審**（bootstrapping）：舊閘已被本案證明失效，用它審本案＝用壞尺量新尺。
   121	  **提議**：pre-flight＋panel（含跨家族）＋★錨定紀律先行試用★＋**人裁當最終閘**，
   122	  並在留痕明記「舊機械閘知情繞過，理由＝其為本案改造對象」。★這是例外不是先例。★
   123	
   124	## 六、待決（人裁）
   125	
   126	1. 第五節的「本案自己怎麼審」提議，可不可以。
   127	2. 實作拆包順序（傾向：①record 強制留痕→②錨定檢查→③gate 分層改造→④skill 重寫**（含「code-loop 不跟進」的差異明文註記，防誤同步）**→⑤離線校準腳本）。
   128	3. [[Projects/design-loop判準重定位]] 的 d1（blocker 不得 accepted）與 d2（模式旗標分流）**沿用**進本案；其餘內容以本案為準。
   129	
   130	---
   131	
   132	## 審計修正紀錄
   133	
   134	### r1 · pre-flight（機械清單，全文餵便宜模型；不算 loop findings）
   135	
   136	8 條全是「只用不定義／缺指針」：`d4` 懸空（★與上一份 spec 同型，第二次犯★→ 補「[[Systems/design-loop]] 的 d4、非本文件編號」）；`r1`/`r3 型`/`S2`/`Codex`/`tier 檔級`/`G1 refcheck`/`35 選 1` 各補一句就地解釋或指針；「skill 差異註記」明確掛進拆包 ④。數字一致性／章節引用／decisions 對映／範圍刀＝全過。
  3020	        print(f"[panel] falsification+ODC(存活 max≤minor): ✗ — 存活 {'blocker' if maxsev==3 else 'major'}")
  3021	        fails.append("存活≥major")
  3022	    else:
  3023	        print("[panel] falsification+ODC(存活 max≤minor): ✓")
  3024	    cc = next((r["capture_counts"] for r in latest if r.get("capture_counts")), None)
  3025	    if cc is None:
  3026	        # fail-closed(review C1):panel 的收斂本體就是 capture-recapture 結構信號,
  3027	        # 沒 capture_counts 就無從證母體枯竭 → 不當「跳過」,當「未枯竭」擋。
  3028	        # 否則不寫 counts 即繞過殘餘檢查、退回舊「2 caught+無 major」弱信號。
  3029	        print("[panel] capture-recapture 殘餘: ✗ — 無 capture_counts(母體未證枯竭;panel 模式必帶)")
  3030	        fails.append("無capture_counts")
  3031	    else:
  3032	        remaining = _estimate_remaining_defects(cc)
  3033	        THRESH = 1.0
  3034	        if remaining < THRESH:
  3035	            print(f"[panel] capture-recapture 殘餘: ✓ — 估計 {remaining:.2f} < {THRESH}")
  3036	        else:
  3037	            print(f"[panel] capture-recapture 殘餘: ✗ — 估計 {remaining:.2f} ≥ {THRESH}(母體未枯竭)")
  3038	            fails.append("殘餘超門檻")
  3039	    fails += _panel_extra_checks(latest, min_seats, spec)
  3040	    for i, r in enumerate(latest, 1):
  3041	        print(f"  {rid}.{i}\t{r.get('kind','?')}\t{r.get('severity','-')}\t{r.get('capture_counts','-')}\t{r.get('auditor','')}")
  3042	    for line in _cost_summary(rounds):
  3043	        print(line)
  3044	    if fails:
  3045	        print(f"⛔ PANEL GATE FAIL ({loop_id} 輪 {rid}: {'/'.join(fails)})")
  3046	        return 1
  3047	    print(f"✅ PANEL GATE PASS ({loop_id} 輪 {rid}: 輪有效 ∧ 存活≤minor ∧ capture-recapture 枯竭)")
  3048	    return 0
  3049	
  3050	
  3051	def _loop_status_panel_clusters(groups, valid_of, loop_id, min_seats=None, spec=None, all_rounds=None):
  3052	    """M2 cluster 帳 gate:兩條合取(判定輪有效 ∧ fold 後無 disputed-major)。
  3053	    fold 只採有效輪(last-wins,同名跨輪最後狀態勝);無效輪 clusters 警告區列帳不蒸發;
  3054	    新生 cluster 與 capture-recapture 皆 advisory 不進合取。"""
  3055	    order = {"clean": 0, "minor": 1, "major": 2, "blocker": 3}
  3056	    rid, latest = next(reversed(groups.items()))
  3057	    fails = []
  3058	    # 條 1:判定輪(latest)有效——同一謂詞
  3059	    caught_recs = [r for r in latest if r.get("kind") == "caught"]
  3060	    n_caught, n_missed = len(caught_recs), sum(1 for r in latest if r.get("kind") == "missed")
  3061	    if valid_of[rid]:
  3062	        print(f"[panel/cluster] 條1 輪有效(caught {n_caught}≥2,0 missed): ✓")
  3063	    else:
  3064	        print(f"[panel/cluster] 條1 輪有效: ✗ — caught {n_caught}/missed {n_missed}"
  3065	              f"(謂詞:caught≥2∧missed=0∧kind 全白名單)")
  3066	        fails.append("輪無效")
  3067	    # fold(僅有效輪,append 序 last-wins)+ ledger(首現/末更輪僅計有效輪,與 advisory 同源)
  3068	    from collections import OrderedDict as _OD
  3069	    ledger = _OD()
  3070	    for rid_, recs in groups.items():
  3071	        if not valid_of[rid_]:
  3072	            continue
  3073	        for r in recs:
  3074	            for name, state in (r.get("clusters") or {}).items():
  3075	                if name not in ledger:
  3076	                    ledger[name] = {"state": state, "first": rid_, "last": rid_}
  3077	                else:
  3078	                    ledger[name]["state"] = state
  3079	                    ledger[name]["last"] = rid_
  3080	    disputed = [n for n, e in ledger.items() if e["state"].split(":", 1)[0] == "disputed-major"]
  3081	    if disputed:
  3082	        print(f"[panel/cluster] 條2 fold 後無 disputed-major: ✗ — {len(disputed)} 個: {','.join(disputed)}")
  3083	        fails.append("存在disputed-major")
  3084	    else:
  3085	        print("[panel/cluster] 條2 fold 後無 disputed-major: ✓")
  3086	    # advisory:新生 cluster(僅基於有效輪;判定輪無效 → 不適用)
  3087	    if valid_of[rid]:
  3088	        born = [n for n, e in ledger.items() if e["first"] == rid]
  3089	        print(f"[panel/cluster] (advisory) 新生 cluster: {len(born)} 個"
  3090	              + (f": {','.join(born)}" if born else ""))
  3091	    else:
  3092	        print("[panel/cluster] (advisory) 新生 cluster: 判定輪無效,新生統計不適用")
  3093	    # advisory:capture-recapture(照算照印,不進合取;無 counts 不 fail-closed——cluster 帳接手守門)
  3094	    cc = next((r["capture_counts"] for r in latest if r.get("capture_counts")), None)
  3095	    if cc is not None:
  3096	        remaining = _estimate_remaining_defects(cc)
  3097	        print(f"[panel/cluster] (advisory) capture-recapture 殘餘估計: {remaining:.2f}(不進合取)")
  3098	    else:
  3099	        print("[panel/cluster] (advisory) capture-recapture: 無 counts(advisory,不擋)")
  3100	    # 警告區:無效輪攜帶的 clusters(已忽略;資料本在 canary-log,顯示即留痕——status 唯讀)
  3101	    for rid_, recs in groups.items():
  3102	        if valid_of[rid_]:
  3103	            continue
  3104	        carried = []   # 全列:同名多筆逐條保留(dict.update 會靜默覆蓋掩掉爭議狀態)
  3105	        for r in recs:
  3106	            carried.extend((n, s) for n, s in (r.get("clusters") or {}).items())
  3107	        if carried:
  3108	            print(f"  ⚠ {rid_}(無效輪) clusters 已忽略: "
  3109	                  + ",".join(f"{n}={s}" for n, s in carried))
  3110	    # ledger 表
  3111	    if ledger:
  3112	        print("  ── cluster ledger(僅計有效輪)──")
  3113	        for n, e in ledger.items():
  3114	            print(f"  {n}\t{e['state']}\t首現 {e['first']}\t末更 {e['last']}")
  3115	    fails += _panel_extra_checks(latest, min_seats, spec)   # M1包:cluster 路不得繞過(code-loop r1)
  3116	    for i, r in enumerate(latest, 1):
  3117	        print(f"  {rid}.{i}\t{r.get('kind','?')}\t{r.get('severity','-')}\t{r.get('auditor','')}")
  3118	    for line in _cost_summary(all_rounds or []):
  3119	        print(line)
  3120	    if fails:
  3121	        print(f"⛔ PANEL GATE FAIL ({loop_id} 輪 {rid}: {'/'.join(fails)})")
  3122	        return 1
  3123	    print(f"✅ PANEL GATE PASS ({loop_id} 輪 {rid}: 輪有效 ∧ fold 後無 disputed-major"
  3124	          f"[cluster 帳,{len(ledger)} 個 cluster])")
  3125	    return 0
  3126	
  3127	
  3128	def cmd_loop_capture_counts(env, finders, from_pitfalls=None, repo=None):
  3129	    """異質 panel 接線的機械生產者(code-loop 三輪壓縮):把各 finder 的 finding-key
  3130	    彙成 capture_counts + 算殘餘估計,吐出可直接餵 `canary record --capture-counts` 的逗號串。
  3744	                          file=sys.stderr)
  3745	                    return 2
  3746	                seen.add(rid)
  3747	                cur_rid = rid
  3748	    # ── tier 解析:定錨優先(v8);僅無定錨舊帳按格式推導;零記錄 rc2 ──
  3749	    anchor = next((r["tier"] for r in rounds if r.get("tier")), None)
  3750	    if tier and anchor and tier != anchor:
  3751	        print(f"ERROR: --tier {tier} 與帳面定錨 {anchor} 衝突(定錨優先;要換 tier 開新 loop id)", file=sys.stderr)
  3752	        return 2
  3753	    eff_tier = anchor or tier
  3754	    if eff_tier is None:
  3755	        if not rounds:
  3756	            print("ERROR: 零記錄 loop 需明示 --tier(不猜——猜錯模式撞混用守衛)", file=sys.stderr)
  3757	            return 2
  3758	        eff_tier = "standard" if panel_fmt else "legacy"   # 無定錨舊帳 fallback
  3759	    width, cap = _TIER_PARAMS[eff_tier]
  3760	    light = eff_tier == "light"
  3761	    # ── tier↔格式一致性(code-loop r1 折入:格式推導可被繞——high 漏帶 --round 會走鬆的 legacy 閘) ──
  3762	    if rounds:
  3763	        if eff_tier in ("standard", "high") and not panel_fmt:
  3764	            print(f"ERROR: tier={eff_tier} 要求 panel 格式(記錄帶 --round),帳面為 legacy 格式——"
  3765	                  "格式衝突(補 record 帶 --round,或 tier 錯誤則開新 loop id)", file=sys.stderr)
  3766	            return 2
  3767	        if light and panel_fmt:
  3768	            print("ERROR: tier=light 為單席 legacy 格式,帳面卻帶 --round(panel 格式)——格式衝突", file=sys.stderr)
  3769	            return 2
  3770	    rounds_count = len({r["round"] for r in rounds}) if panel_fmt else len(rounds)
  3771	    n_next = rounds_count + 1
  3772	
  3773	    def emit(phase, extra=None):
  3774	        out = {"phase": phase, "tier": eff_tier, "round": n_next, "width": width,
  3775	               "min_seats": width, "cap": cap, "advisory": "tier 由編排者宣告後定錨;lumos 只做映射與定錨讀取"}
  3776	        if phase == "plant-canary":
  3777	            if light or eff_tier == "legacy":
  3778	                out["canary_type"] = _CANARY_TYPES[(n_next - 1) % 4]
  3779	            else:
  3780	                out["canary_type"] = {f"slot{i}": _CANARY_TYPES[(i + n_next - 1) % 4]
  3781	                                      for i in range(1, width + 1)}
  3782	            rmode = "" if (light or eff_tier == "legacy") else f" --round r{n_next}"
  3783	            # ★`legacy` 不是可宣告值,不得吐進 record_cmd★(2026-08-04):`--tier` 的 choices
  3784	            # 只有 light/standard/high(LOOP_TIERS),legacy 純粹是「無定錨舊帳 + legacy 格式」
  3785	            # 的推導結果。原本這裡無條件吐 `--tier {eff_tier}`,legacy 下等於★發一條 argparse
  3786	            # 當場擋掉的指令★;而使用者最自然的修復是「把 --tier 拿掉再跑一次」——拿掉就記不上
  3787	            # 定錨,下一輪 next 又推成 legacy、又吐一條跑不動的指令。
  3788	            # ★這個 bug 自己維持自己★:2026-08 三個走循序的 loop(code-slim-python /
  3789	            # code-teardown-windows / code-slim-handoff)全數 tier=None,即此循環的產物;
  3790	            # 其中 code-slim-python 吃到 legacy 的 cap 6(standard 是 3)才被逼停。
  3791	            _tier_flag = f" --tier {eff_tier}" if eff_tier in LOOP_TIERS else ""
  3792	            out["record_cmd"] = (f"lumos canary record caught|missed --loop {loop_id}{rmode}"
  3793	                                 f" --auditor <席> --severity <s> --findings <M>"
  3794	                                 f" --spec <計劃節點.md> --reviewed <sha256>{_tier_flag}"
  3795	                                 f" --scope-lines <這輪審了幾行>")
  3796	            if eff_tier == "legacy":
  3797	                out["tier_hint"] = (
  3798	                    "★本 loop 無 tier 定錨,正在吃 legacy 判準(單席、cap 6——比 standard 的 cap 3 鬆)★。"
  3799	                    "legacy 不是可宣告值,★這個 loop 補標不了★:帳面已是 legacy 格式(記錄不帶 --round),"
  3800	                    "補 --tier standard|high 會被格式一致性當場擋掉(rc2)。"
  3801	                    "(--tier light 格式相容,但 cap=2 且帶 ratchet 語意,對已跑數輪的 loop 通常當場 cap-reached。)"
  3802	                    "要走分級判準請★開新 loop id,並在第一筆 record 就帶 --tier★。")
  3803	            # ★預防端:警告必須在派工「之前」★——記帳時才喊已經來不及(輪跑完了)。
  3804	            # loop next 是每輪第一步,所以量尺放這裡。
  3805	            out["scope_cap"] = (
  3806	                f"★派工前先量★ `wc -l <工作副本/patch>`:超過 {_CANARY_SCOPE_SOFT_CAP_LINES} 行"
  3807	                f"(≈30K token)就★拆開審★——切成多輪,或拆給多席各審一段。"
  3808	                "理由:審查員的任務是『在 N 行裡找出那個植入的錯』,而脈絡越長注意力越差是"
  3809	                "已發表的實測(退化在 32K token 就量得到)。"
  3810	                "★這條門檻純粹借自外部文獻——本專案自己跑過三次對照實驗都測不出規模效應,"
  3811	                "不得引用自家資料當佐證★(原本這裡寫「本專案資料落在線兩邊」,該宣稱已撤:"
  3812	                "兩組審的根本不是同一份碼;之後兩次刻意設計的實驗一次撞天花板 7/7、一次撞"
  3813	                "地板 0/6,見 Projects/規模影響判斷力假說)。"
  3814	                "超標不擋,但會在帳上標 scope_oversize、該輪 caught 視為弱證據。")
  3815	        # ★cluster 帳的選擇只有第一輪能做★(2026-08-02):模式由「第一個有效輪」定錨,之後
  3816	        # 要換只能開新 loop id。而 M2 落地至今 316 筆 canary 記錄裡★只有 1 筆帶 clusters★,
  3817	        # 且那一筆是開發它的 code-m2cluster 自己——34 個 panel loop 中有 33 個靜默落回
  3818	        # 無-cluster 舊帳。根因不是機制不好,是★沒有任何地方在該選的時候提起它★。
  3819	        # 只在 N=1 提(那是選擇真正還開著的唯一時刻),避免對已定錨的 loop 噴無效噪音。
  3820	        if phase == "plant-canary" and not light and eff_tier != "legacy" and n_next == 1:
  3821	            out["cluster_hint"] = (
  3822	                "★本 loop 第一輪——cluster 帳只有現在能選(模式由第一個有效輪定錨,之後要換只能開新 loop id)★:"
  3823	                "若預期 findings 會散成★性質不同★的風險群(例:「規格縮水」與「邊界 bug」),"
  3824	                "改用 `--clusters '名=resolved|accepted-minor:理由|disputed-major'` 逐群追蹤,"
  3825	                "gate 改判「無 disputed-major」——不把不同性質的問題壓成單一 max severity(一軸會遮蔽另一軸)。"
  3826	                "單一主題、findings 同性質的 loop 用預設(無-cluster)即可。")
  3827	        if extra:
  3828	            out.update(extra)
  3829	        if as_json:
  3830	            print(_json.dumps(out, ensure_ascii=False))
  3831	        else:
  3832	            print(f"[next] {loop_id}: phase={phase} tier={eff_tier} 下一輪 N={n_next}"
  3833	                  f" width={width} cap={cap}")
  3834	            for k in ("canary_type", "record_cmd", "scope_cap", "cluster_hint", "note"):
  3835	                if k in out:
  3836	                    print(f"  {k}: {out[k]}")
  3837	        return 0 if phase == "converged" else 1
  3838	
  3839	    # ⓪ escalate:light ratchet 永久態最先短路
  3840	    if light and any(r.get("kind") == "caught" and r.get("severity") in ("major", "blocker")
  3841	                     for r in rounds):
  3842	        return emit("escalate", {"note": "light ratchet 已觸發——停止本 loop,開新 panel loop id(原 id+-std 後綴)承接"})
  3843	    if not rounds:
  3844	        return emit("plant-canary")
  3845	    # ① gate-pending:判 converged 需 gate 結果,資訊不足絕不背書(先於 cap)
  3846	    if spec is None:
  3847	        return emit("gate-pending", {"note": "缺 --spec,gate 判定資訊不足——跑 loop status --gate 附完整參數自判"})
  3848	    # ② full-basis gate 委派(靜默跑既有謂詞,零新判定邏輯)
  3849	    buf = io.StringIO()
  3850	    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
  3851	        rc = cmd_loop_status(env, loop_id, need=(1 if light else need), gate=True,
  3852	                             spec=spec, repo=repo, panel=(panel_fmt and not light),
  3853	                             light=light, min_seats=width)   # 恆傳(light/legacy=1;code-loop r1 折入)
  3854	    if rc == 2:
  3855	        sys.stderr.write(buf.getvalue())
  3856	        return 2
  3857	    if rc == 0:
  3858	        return emit("converged", {"gate_basis": "full(G 合取+hash 委派既有謂詞全過)"})
  3859	    # ③ cap(資訊充分且未 PASS)
  3860	    if rounds_count >= cap:

334 Counter({'caught': 282, 'missed': 52})
loop 334 clean 33 caught 282 missed 52
design Counter({'caught': 185, 'missed': 42})
code Counter({'caught': 97, 'missed': 10})

web search: 
web search: CiteCheck 2026 citation grounding mechanical citation verification LLM judge ...
codex
[major] 錨定若對折入後的現檔檢查，finding 可以用自己剛補進文件的文字完成循環自證  
引句:「每條 finding 必須引用文件裡真實存在的原文；grep 可驗。」  
理由:現行流程先折入、再 record，`scripts/lumos:2727` 儲存的是 post-fold hash；設計卻沒規定錨定必須對派工時的 immutable reviewed snapshot 執行。只對現檔 grep，原本不存在的引句在折入後便會「存在」，產生機械假綠。`reviewed_sha256` 只有雜湊而沒有可還原內容，單靠它也無法事後重算。

[major] 「留痕存在性」只做寫側檢查，並不是文件宣稱的可重算 gate  
引句:「record 帶路徑＋sha256，**寫側驗檔案存在**。」  
理由:報告在 record 後被刪除、替換或路徑改指時，gate 若不重新讀檔並核對 sha256 仍會放行；這只證明「曾經存在」，不證明 gate 當下存在且內容未變，直接違反「事後可稽核」。應由讀側 gate 重算 existence、regular-file、repo-bound path 與 digest。

[major] 處置帳只核總數，無法證明每條 finding 恰好被處置一次  
引句:「處置帳算術（`folded+accepted==findings`＋blocker 不得 accepted）」  
理由:純計數允許同一 finding 同時計入 folded 與 accepted、重複計數、拿虛構項補分母，或漏掉 A 再用 B 重複兩次補平。要成為機械閘，必須有穩定 finding ID，並檢查 findings 集合與 folded/accepted 兩集合互斥且聯集相等；否則算術通過不代表逐條結清。

[major] 新帳允許 accepted 的嚴重度邊界與既有 cluster 合約不一致  
引句:「[[Projects/design-loop判準重定位]] 的 d1（blocker 不得 accepted）與 d2（模式旗標分流）**沿用**進本案」  
理由:現碼只允許 `accepted-minor`，且要求逐 cluster 理由；見 `scripts/lumos:2644`、`scripts/lumos:2666`。投稿只禁止 blocker accepted，照字面等於放行 accepted-major，卻沒有定義新狀態、理由要求、既有 `disputed-major` 如何遷移，或 major 接受是否應擋。這不是「擴充既有帳」可自然推出的語意，實作者會做出互不相容的 gate。

[major] 「tier 自動帶入」建立在不存在的自動計算上  
引句:「tier 定錨、min-seats、cluster/處置帳模式——`loop next` 已算出的值自動進 record/gate」  
理由:`loop next` 對零記錄明確要求人先宣告 tier，否則 rc2；見 `scripts/lumos:3753`–`scripts/lumos:3757`。其輸出也明載「tier 由編排者宣告後定錨；lumos 只做映射」；見 `scripts/lumos:3773`–`scripts/lumos:3775`。自動傳遞只能消滅漏抄，不能消滅 tier 的人工選擇；投稿把「傳值」偷換成「算值」，原系統病仍在入口。

[major] 拆包順序會先把現行 record 呼叫全部打壞  
引句:「實作拆包順序（傾向：①record 強制留痕→②錨定檢查→③gate 分層改造→④skill 重寫」  
理由:現行 `loop next` 產生的 `record_cmd` 沒有報告路徑或報告 hash；見 `scripts/lumos:3792`–`scripts/lumos:3795`。若第①包先把留痕改為必填，而產生指令與 skill 到第④包才更新，中間版本的正常 design-loop 將全面拒收。CLI schema、`loop next` 產生器、skill/template 與 gate 消費端必須同包原子切換，或先做兼容雙讀再收緊。

[major] CiteCheck 被引用成「機械比對勝過 LLM 判官」，原論文摘要並不支持這個二選一結論  
引句:「citation grounding 文獻(CiteCheck 2026):★機械比對引文>讓 LLM 判官判可信度★」  
理由:CiteCheck 描述的是 scholarly retrieval、結構化 LLM comparison 與 calibrated decision rules 的組合，不是純 grep 對 LLM judge 的消融勝負；投稿把「檢索接地的混合系統」偷換成「字串存在檢查優於 LLM 判讀」。更重要的是，citation hallucination 驗的是引文是否支持 claim，而本方案只驗字串是否出現，任務情境並不同型。[CiteCheck 原文摘要](https://arxiv.org/abs/2605.27700)

[major] 支撐 canary 退役的「184 筆只有 1 clean」無法由指定量測帳重算  
引句:「canary 唯一有資訊量的場景=審查員回報 clean,而 184 筆帳裡 clean 只有 1 筆」  
理由:`docs/.canary-log.jsonl` 現有 334 筆皆帶 loop，其中 `severity=="clean"` 為 33 筆；design-loop 類帳為 227 筆（185 caught、42 missed），也不是 184。若「clean」指報告正文而非 severity，帳本沒有結構化 reviewer verdict 可重算。這個數字被用作退役核心論據，卻沒有母體篩選式或外部報告索引。

[minor] 「code-loop 保正確」把下游責任鏈縮成單一機制，容易造成過度承諾  
引句:「**code-loop 不跟進**：它定位『保正確』、canary missed 率 9.3% 未見異常」  
理由:架構圖現行定位是正確性歸「code-loop＋測試＋驗證」共同承接，不是 code-loop 本身提供 correctness oracle。此處應寫成「code-loop 是下游正確性防線之一」，否則會把保留 canary 的理由建立在不實保證上。

MAX_SEVERITY: major
84,978
[major] 錨定若對折入後的現檔檢查，finding 可以用自己剛補進文件的文字完成循環自證  
引句:「每條 finding 必須引用文件裡真實存在的原文；grep 可驗。」  
理由:現行流程先折入、再 record，`scripts/lumos:2727` 儲存的是 post-fold hash；設計卻沒規定錨定必須對派工時的 immutable reviewed snapshot 執行。只對現檔 grep，原本不存在的引句在折入後便會「存在」，產生機械假綠。`reviewed_sha256` 只有雜湊而沒有可還原內容，單靠它也無法事後重算。

[major] 「留痕存在性」只做寫側檢查，並不是文件宣稱的可重算 gate  
引句:「record 帶路徑＋sha256，**寫側驗檔案存在**。」  
理由:報告在 record 後被刪除、替換或路徑改指時，gate 若不重新讀檔並核對 sha256 仍會放行；這只證明「曾經存在」，不證明 gate 當下存在且內容未變，直接違反「事後可稽核」。應由讀側 gate 重算 existence、regular-file、repo-bound path 與 digest。

[major] 處置帳只核總數，無法證明每條 finding 恰好被處置一次  
引句:「處置帳算術（`folded+accepted==findings`＋blocker 不得 accepted）」  
理由:純計數允許同一 finding 同時計入 folded 與 accepted、重複計數、拿虛構項補分母，或漏掉 A 再用 B 重複兩次補平。要成為機械閘，必須有穩定 finding ID，並檢查 findings 集合與 folded/accepted 兩集合互斥且聯集相等；否則算術通過不代表逐條結清。

[major] 新帳允許 accepted 的嚴重度邊界與既有 cluster 合約不一致  
引句:「[[Projects/design-loop判準重定位]] 的 d1（blocker 不得 accepted）與 d2（模式旗標分流）**沿用**進本案」  
理由:現碼只允許 `accepted-minor`，且要求逐 cluster 理由；見 `scripts/lumos:2644`、`scripts/lumos:2666`。投稿只禁止 blocker accepted，照字面等於放行 accepted-major，卻沒有定義新狀態、理由要求、既有 `disputed-major` 如何遷移，或 major 接受是否應擋。這不是「擴充既有帳」可自然推出的語意，實作者會做出互不相容的 gate。

[major] 「tier 自動帶入」建立在不存在的自動計算上  
引句:「tier 定錨、min-seats、cluster/處置帳模式——`loop next` 已算出的值自動進 record/gate」  
理由:`loop next` 對零記錄明確要求人先宣告 tier，否則 rc2；見 `scripts/lumos:3753`–`scripts/lumos:3757`。其輸出也明載「tier 由編排者宣告後定錨；lumos 只做映射」；見 `scripts/lumos:3773`–`scripts/lumos:3775`。自動傳遞只能消滅漏抄，不能消滅 tier 的人工選擇；投稿把「傳值」偷換成「算值」，原系統病仍在入口。

[major] 拆包順序會先把現行 record 呼叫全部打壞  
引句:「實作拆包順序（傾向：①record 強制留痕→②錨定檢查→③gate 分層改造→④skill 重寫」  
理由:現行 `loop next` 產生的 `record_cmd` 沒有報告路徑或報告 hash；見 `scripts/lumos:3792`–`scripts/lumos:3795`。若第①包先把留痕改為必填，而產生指令與 skill 到第④包才更新，中間版本的正常 design-loop 將全面拒收。CLI schema、`loop next` 產生器、skill/template 與 gate 消費端必須同包原子切換，或先做兼容雙讀再收緊。

[major] CiteCheck 被引用成「機械比對勝過 LLM 判官」，原論文摘要並不支持這個二選一結論  
引句:「citation grounding 文獻(CiteCheck 2026):★機械比對引文>讓 LLM 判官判可信度★」  
理由:CiteCheck 描述的是 scholarly retrieval、結構化 LLM comparison 與 calibrated decision rules 的組合，不是純 grep 對 LLM judge 的消融勝負；投稿把「檢索接地的混合系統」偷換成「字串存在檢查優於 LLM 判讀」。更重要的是，citation hallucination 驗的是引文是否支持 claim，而本方案只驗字串是否出現，任務情境並不同型。[CiteCheck 原文摘要](https://arxiv.org/abs/2605.27700)

[major] 支撐 canary 退役的「184 筆只有 1 clean」無法由指定量測帳重算  
引句:「canary 唯一有資訊量的場景=審查員回報 clean,而 184 筆帳裡 clean 只有 1 筆」  
理由:`docs/.canary-log.jsonl` 現有 334 筆皆帶 loop，其中 `severity=="clean"` 為 33 筆；design-loop 類帳為 227 筆（185 caught、42 missed），也不是 184。若「clean」指報告正文而非 severity，帳本沒有結構化 reviewer verdict 可重算。這個數字被用作退役核心論據，卻沒有母體篩選式或外部報告索引。

[minor] 「code-loop 保正確」把下游責任鏈縮成單一機制，容易造成過度承諾  
引句:「**code-loop 不跟進**：它定位『保正確』、canary missed 率 9.3% 未見異常」  
理由:架構圖現行定位是正確性歸「code-loop＋測試＋驗證」共同承接，不是 code-loop 本身提供 correctness oracle。此處應寫成「code-loop 是下游正確性防線之一」，否則會把保留 canary 的理由建立在不實保證上。

MAX_SEVERITY: major
