---
type: project
status: doing
created: 2026-07-14
updated: 2026-07-14
summary: |-
  FLAG:DECISION
  KEY:關係層守衛「主網(proactive 連鎖確認)」的 TDD 實作計畫;設計/架構收斂見 [[關係層傳播守衛_計劃]] §八待釘合約,本節點把 🔴🟠 合約逐條釘死 + 切 4 里程碑
  KEY:里程碑鏈 M1 P2決策ID+E3精確 → M2 P0 typed-edge索引 → M3 cascade ledger(append-only JSONL,生成式 cascade-id=c-<ts>-<hash8> 消解中文淨化)+rel-cascade CLI(confirm/prune/list --stale/resume,--cascade-id/--from 全域格式/--edge/--by) → M4 觸發+typed hop-1+判斷閘連鎖;依序建測、整包交付;supersede 選擇端 --match 多重命中 rc=2/#dN 定址
  KEY:PRIOR-ART=lumos impact(主動影響幅度偵測,已 done)是 code-file seed 工具(CLAUDE.md PreToolUse hook 走 --file/--diff,已有 --json 無 --node);主網 typed hop-1=新增 --node 第三模式建在新 [P0] typed 索引上(支援 --json、與 --depth 互斥),熱路徑不受影響(r1 Codex 修正 r2 舊宣稱)
  KEY:M1 順帶收尾補網 E3(P2 是 E3 唯一缺的零件);M4 判斷閘=AI 先判分級(明顯 confirm 放寬/明顯 prune 保守留痕/拿不準才升人=無 terminal 事件靠 list --stale/resume 浮出),最軟最不確定、design-loop 要重點審
  KEY:輸出協議已釘(supersede stdout 首行逐字保留/surface 走 stderr 行式固定 schema=CASCADE/NEIGHBOR 行,即編排者交接通道/失敗仍 rc=0);cascade-id 鑄造者=觸發端 dispatcher(O_CREAT|O_EXCL 建檔寫 header,全鏈唯一);並行=helper O_APPEND fd+單次 bytes write,撤的是跨平台強保證非 O_APPEND 本身
  VERIFY:design-loop rel-mainnet 三輪(2026-07-15):r1 canary 3/3,24 候選→存活 D5/D10/D16 折 v2;r2 canary 3/3,12 候選→存活 R1 鑄造/交接+R3/R4/R12 折 v3;r3 canary 3/3,8 major 候選經辯方全降 minor(header 全域格式/rc=0 範圍皆有 spec 原文反證)=clean round,15 句級殘留折 v4;九席 canary 全 caught、架構三輪未翻
  DEP:[[關係層傳播守衛_計劃]]｜[[主動影響幅度偵測_計劃]]｜[[Systems/lumos-cli-read]]｜[[Systems/lumos-cli-write]]
  DECISION:進實作前必過 lumos-design-loop(高風險 spec,--need 3)到 loop status --gate --panel 收斂;本節點 spec 完成即交 design-loop、非直接 code
tags:
  - type/project
  - status/doing
plan_refs:
  - "[[關係層傳播守衛_計劃]]"
related:
  - "[[主動影響幅度偵測_計劃]]"
decisions:
  - content: 主網實作範疇拍板:整包交付(M1-M4 依序建/測、不中途獨立 ship)、decision_refs 單向、次路觸發(手改 Edit 翻 valid)v1 不做
    context: spec 切 4 里程碑後進 design-loop 前，3 個範疇問題交人拍板
    why_chosen: 整包=避免 E3 半成品先上又回頭改;單向 decision_refs 省寫入負擔+少一處漂移;次路觸發 diff 偵測脆、E2 已週期兜底，v1 不值得冒過寬/過窄風險
    decided: 2026-07-14
    valid: true
  - content: design-loop rel-mainnet 人裁實質收斂(2026-07-15):3 輪 panel cap 到頂,r3 clean(canary 3/3+存活全 minor),唯 capture-recapture 殘餘 2.50≥1.0 未過——人裁定實質收斂進實作,殘餘 minor 級交實作真測接
    context: gate 三條件過二:輪有效+嚴重度收斂(blocker→blocker→全 minor,架構三輪未翻);統計殘餘未枯竭(r3 五條單席發現→推估 ~2.5 條未發現)。skill 自承 framing 逼每輪必交 minor、G2 數字枯竭天生壓不到底,誠實出口=人裁
    why_chosen: 存活全 minor+三輪未翻架構=剩的是句級完整性;design-loop 完整性天花板已有實證(lint-version-watch:散文審有天花板、實作真測才接住)——散文再摳邊際遞減,真測開始接手才有增量;凍 golden 保三輪語料供 replay 校準
    decided: 2026-07-15
    valid: true
---
# 關係層主網_實作計畫

主網＝**改節點的當下就當場點出受波及的鄰居**（proactive，趁脈絡最全、最便宜時處理），對照補網（E1/E2 已上、doctor 事後週期掃）。架構經 3 輪 Codex design-loop 收斂，設計全文見 [[關係層傳播守衛_計劃]]；本節點把該計劃 §八 的待釘合約（🔴🟠）**逐條釘死**、切成 4 個獨立可測里程碑。

> **PRIOR-ART**：`lumos impact`（[[主動影響幅度偵測_計劃]]，已 done、9 輪 design-loop）是**無型別**的 downstream 影響工具（CLAUDE.md 那個 PreToolUse hook）。主網的 typed hop-1（[S2]）**不複用它的 `_impact_bfs`**（雙向走全邊、`_impact_via` 事後單值猜型不可靠）——r2 Codex 揭露架構圖建圖層丟邊型，故主網另建 [P0] typed 索引。兩者互補、不重疊。

---

## 里程碑總覽

| M | 名稱 | 交付 | 依賴 | 對應 [S] |
|---|---|---|---|---|
| **M1** | P2 決策穩定 ID + E3 精確版 | 決策固定編號、`decision-reindex` 回填、E3 補網收尾、E2 首判精化、supersede 回傳 decision_id+唯一命中 | 無（現成可建） | [P2][S8] |
| **M2** | P0 typed-edge 反向索引 | 可重用的「誰以哪種邊指向我」記憶體索引，doctor+impact 共用 | 無（可與 M1 併行） | [P0] |
| **M3** | cascade ledger + rel-cascade CLI | append-only JSONL 帳本 + `confirm`/`prune` 寫回 + `list --stale` + `resume` | M1（決策 ID）、M2（邊型） | [S5b][S3寫回] |
| **M4** | 觸發 + typed hop-1 + 判斷閘連鎖 | supersede 觸發 → typed hop-1 列鄰居 → AI 判斷閘 → 確認才前進的工作清單 | M1+M2+M3 全部 | [S1][S2][S3][S4] |

**交付節奏＝整包（M1-M4 一起上，2026-07-14 拍板）**：里程碑仍**依序建/測**（M1→M2→M3→M4，各自可測），但**不中途獨立 ship**，最後整包交付。M1 順帶把補網最後一道 E3 收尾（P2 是 E3 唯一缺件），E3 隨整包一起上。M4 最大最軟（含 AI 判斷閘），design-loop 要重點審。

---

## M1 · P2 決策穩定 ID + E3 精確版

**目標**：每條決策有一個穩定、不重用的編號，讓「哪條決策」機器可定址——E3 靠它精準、主網帳本靠它當粒度、supersede 靠它回傳身分。

**建什麼**
1. **決策 ID schema**：每條 decision 加 `id: d<N>`（節點內單調計數、**翻案後永不重用**）。全域定址 = `<節點rel>#d<N>`。
2. **`decision-add` 指派 + 回傳** 新 id；**`decision-supersede` 改回 `(rc, decision_id)`**（現回 int 0 → 解 🔴「決策 ID 回傳」，M4 [S1] 才能用精確 ID 呼 surface、不再靠 content 子字串重找）。**decision_id 由 supersede 端組成全域格式 `<節點rel>#d<N>` 再回傳**（rel 在其作用域內；下游 header/CASCADE 行/`--from` 全鏈同一格式，無裸碼流出，T1）。**dispatcher 同步解包**（`main()` 現直接 `sys.exit(cmd_decision_supersede(...))`——scripts/lumos 8553-8573——改 tuple 必須同改唯一呼叫端；CLI 對外仍只回整數 rc）。寫後自驗升級為 **ID 精確驗證**；**選擇端同修（R12，root cause 在此非 verify 層）**：`--match` 子字串**多重命中→rc=2 列候選**（現 first-match 會「先改錯項、再用錯項 id 精確驗證它改成功」——驗證恆綠的假安心），並接受 `--match "#d<N>"` 精確定址（argparse help 同步；未 reindex 節點以 `#dN` 查無 → rc=2 提示先跑 reindex）。
3. **`lumos decision-reindex <節點>`（回填遷移；簽名＝單節點一次一篇，同其他 T3 寫入原語）**：對既有無 id 決策依文件順序、**從既有最大 id+1 接續編號**（不重排既有、不回收缺號；混合狀態下絕不撞既有 id）；**冪等**（已有 id 跳過）；解析不到的決策項明確拒絕（同 supersede 現行 0-indent/tab 拒絕語意），不靜默跳過造成缺洞。解 🟠「P2 舊決策回填」。
4. **E3 精確版**：Verification `decision_refs: ["<節點rel>#d<N>"]` → 檢查該被指的決策是否 `valid:false` → warn。**dangling ref 也要浮出**：指到不存在節點/未指派過的 `d<N>` → warn「dangling decision_ref」（不靜默通過，對齊 M2 反靜默紀律）。取代現高噪音 advisory（[[關係層傳播守衛_計劃]] [S8]）。
5. **E2 首判精化**（🟠）：鄰居若有 `decision_refs` → 只在指到「那條」翻案決策時才標；無 `decision_refs` → 退回現行節點+ended 級（相容不退化）。

**釘死的合約**
- `decision_refs` 形狀：list of `"<節點rel>#d<N>"` 字串（非 wikilink，`#` 後接 id；避免 ghost trap）。
- ID 穩定性：一旦指派，即使決策被 supersede 也**保留原 id**（翻案是加 `valid:false`、不刪不換號）；reindex 只補缺、不重排既有。**唯一性以序列化提交態為準**：兩 session 併發改同節點 frontmatter 是全 CLI 既有 last-writer-wins 性質（`atomic_write_verify` tmp→replace，輸家整筆被蓋非撞號），非 M1 新引入、不在 M1 加鎖。
- **decision_refs＝單向**（Verification→決策，2026-07-14 定案）：反向「誰引用我」用 P0-style 掃描，不加寫入負擔、少一處雙向漂移。
- **舊 Verification 的 decision_refs 回填＝語意任務**（某 V 實作「哪一條」決策需讀內容判斷），機械不可導、無自動交付項；靠設計好的優雅降級（E2 無 refs 退節點級、E3 未 refs 不觸發）+ 人/AI 增量補。

**測試**：decision-add 指派唯一遞增 id、supersede 回傳正確 id、reindex 冪等且不動既有 id + 混合狀態（部分有 id）從 max+1 接續不撞號、E3 精確（指到翻案決策才報／指到有效決策不報／dangling ref 報 dangling）、E2 有 decision_refs 時精化、無時相容。

---

## M2 · P0 typed-edge 反向索引

**目標**：一個「每節點 ← 誰、以哪種邊型指向我」的可重用索引（`verified_by`/`plan_refs`/`related` 各自獨立），補 `Env.edges` 無型別的洞。

**建什麼**：記憶體 API（**每次 invocation 從 frontmatter 具名欄位重建**，故**天生新鮮、無持久化索引 = 無腐爛**，解「索引自身新鮮度」）。反向 `{target → [(source, edge_type)]}` + 正向 `{source → {type → [targets]}}`。doctor Check E（把 E2 內聯反查遷來共用）+ M4 impact typed 模式共用。

**釘死的合約（解 🟠 P0 解析政策）**
- **只索引「整個值恰為一個 wikilink」**（沿 `load_vault` 現行 fm_targets 規則）；具名邊欄位裡的**殘留 scalar → lint warn「非 wikilink 值」+ 不進索引**（不靜默納入）。
- **ghost 目標（unresolved）→ 記進索引標 `resolved:false`**（浮出給 doctor/impact 報，**不靜默丟**）。
- **同名無路徑 `[[X]]` 有多篇候選 → 記 ambiguous + 候選清單、flag；消費端浮出歧義，嚴禁靜默指第一篇**。
- 去重鍵 `(source, target, type)`（ambiguous 條目的 `target`＝原 wikilink 字面字串——同 ghost 處理法；補一條測試釘此行為）。消費端（surfacing/`impact --node`/resume 共用的 hop-1 原語）遇 ambiguous 邊 → 輸出 `NEIGHBOR-AMBIG` 行浮出（見 M4 輸出協議），不折進 resolved 清單、不入自動判。

**測試**（純函式）：逐欄 exact-wikilink 抽取、正反向對稱、去重、scalar 拒斥+warn、ghost 標 unresolved、同名歧義不靜默取首、與現行 `Env.edges` 對照做**投影比較**（每條 resolved typed edge 必存在於 `Env.edges`；`Env.edges` 是 body wikilink + 全 frontmatter 邊的超集，不做集合等價）。

> 建置順序註：M1（E2 首判精化）與 M2（E2 內聯反查遷共用）都碰 doctor E2 那段 code——「可併行」指依賴圖層；實際依交付節奏序列建置（先落地者先，後者 rebase 該段），不做同段併發改動。

---

## M3 · cascade ledger + rel-cascade CLI

**目標**：連鎖判定的持久化帳本（可中斷/續/稽核）+ 寫回指令。

**建什麼**
- **append-only JSONL**：`governance/rel-cascade/<cascade-id>.jsonl`，**每行帶判別欄 `event`**（R7）：header 行 `{event:"header", ts, root_decision_id, node}`（由觸發端 O_EXCL 建檔時寫入，root 決策全域格式存檔內、不進檔名）、transition 行 `{event:"transition", ts, neighbor, edge_type, from_decision_id, state, by}`；ts 一律 **UTC**。**狀態 = 重放折疊**（只折 `event:"transition"` 行，同 `(neighbor×edge_type×from_decision_id)` 取**檔內物理序最後一筆**——append-only 帳的正典義，沿 canary-log 重放慣例「讀 append 序、不 ts-sort」scripts/lumos:2114；ts 是資訊欄非排序鍵）。**torn header**（首行即壞）→ root 不可恢復，resume 報「不可恢復、交補網 E2 兜底」rc=1。
- **`lumos rel-cascade confirm|prune <鄰居> --cascade-id <id> --from <決策id> --edge <邊型> --by ai|human`**：append 一筆 transition。**寫前驗證（R4）**：檔必須已存在且 header 合法（不存在→rc=2 指示「由 supersede 觸發建立」；**header 損毀（torn）→ rc=2 拒寫**——寫指令前置驗證一律 rc=2，與 resume 的 rc=1「救不回」信號按指令類別分流（T8）；`--from` ≠ header 的 root_decision_id → rc=2 拒——v1 全鏈同源，見 resume 語意）；**建檔只屬觸發端**（O_CREAT|O_EXCL），confirm/prune 永不建檔。`--from`/`from_decision_id` 一律**全域格式** `<節點rel>#d<N>`（裸 `d<N>` 拒收 rc=2——裸格式會讓折疊鍵跨節點誤合）。超過 4KB 的事件行**寫前拒絕 rc=2**（不截斷、不靜默破壞原子假設）；header 行超限走觸發端 fail-open（`CASCADE-ERROR`、supersede 仍 rc=0——建檔無 CLI rc 語意，兩套失敗語意在此交會）。
- **`lumos rel-cascade list [--stale N]`**：以**活動齡**列 cascade（`--stale N` = 最後事件 ts 早於 N 天；不判「開放/完成」精確分類——ledger 無 cascade 級完成事件、鄰居集逐跳遞增發現，活動齡才是可算的 crash/失敗偵測器）。
- **`lumos rel-cascade resume <cascade-id>`（D16 折入，「續」的交付項；演算法釘死 R3）**：① 讀 ledger 重放（只折 transition、取每鍵最終態）→ ② 取 header 的 root_decision_id → ③ 重呼 `cascade_surface` 於 root 及每個**最終態=confirmed** 的鄰居（先 confirm 後 prune 的**不**重展；歷史出現過 confirmed 不算）→ ④ 對 transition 粒度鍵做差集 → 列出剩餘 pending 待判項（stdout、NEIGHBOR 行 schema）。**decision_id 語意＝root 全鏈攜帶**：整個 cascade 的每一跳、每筆 transition 的 `from_decision_id` 都是**同一個 root 全域決策 id**（傳播起源），非各鄰居本地決策——**resume 差集鍵全鏈可算**；**E2 抑制鍵＝root 的直接連入邊**（恰覆蓋 E2 全部 candidate——E2 只掃「鄰居→被翻案節點」直接邊、hop-2 candidate 不存在，T3 措辭收斂）；參數名定為 `root_decision_id` 防混淆。**E2 定位帳檔**＝復用 `list` 的全目錄掃（或 glob `c-*-<hash8>`——hash8 由決策 id 決定性導出），不需重建含秒數的完整檔名。**visited 重建**＝root ∪ 最終態 confirmed 鄰居集（不另存展開紀錄；重複展開無害——粒度鍵冪等去重，只多列不多寫）。中斷接續、escalate 待人項、**誤 prune 翻案後補跑下游**（重 confirm 後 resume 會把該鄰居重展）三個場景共用此入口。

**釘死的合約**
- **定址（🔴，D5 折入：消解淨化而非定義淨化；R2 辯方修正措辭）**：cascade-id = `c-<YYYYMMDDHHMMSS>-<sha1(root全域決策id)[:8]>`（UTC；sha1/compact-ts 是**本機制新格式**、非沿既有慣例——repo 現用 SHA-256+ISO，zero-dep stdlib 皆可）——**純生成、不含節點名**，天然滿足 charset、無中文/`/` 淨化問題、跨節點同秒不撞（hash 區分）。**同決策實際恆單 cascade**（supersede-once 閘：已 superseded 再 supersede 被 rc 拒，scripts/lumos 4302 區——「同決策可多 cascade」不可達，原措辭撤）；防禦兜底＝觸發端 `O_CREAT|O_EXCL`，遇同名（理論角落）**同秒遞增序號**：正式公式 `c-<ts>-<hash8>(-<正整數>)?`（不等下一秒；上限 99 防異常目錄無限迴圈，仍合 charset 正則）。`--cascade-id` 必填；跨 cascade 不共享 state。
- **path 安全**：cascade-id 限 `^[A-Za-z0-9._-]+$`、擋 `..`/`/`（生成式 id 天然合規，驗證擋手打）。
- **並行（🟠，D10 折入：降宣稱+釘實作形）**：append-only 免 in-place lost-update；寫入走**專用 helper——O_APPEND fd + 單次 `os.write()` 整行 bytes**（≤4KB 行長上限），POSIX regular file 下實務原子；**Windows/跨平台為 best-effort、預期單寫者**（誠實：TextIOWrapper `open("a")` 不保證 syscall 級行原子，repo 既有 ledger 全是它——本帳本用 helper 升一級，但不宣稱全平台強保證）。torn 尾行（crash 半行）由重放跳過（沿 repo jsonl 慣例 `json.loads` fail→skip；torn=未提交事件，丟棄正確）。
- **粒度 = 決策id×邊型×鄰居**（[S5b]）；`confirmed`+`pruned` 都是 terminal 事件、各自帶 `ts`（**「pruned/confirmed ts」= terminal 事件的 ts，非獨立欄位**——命名統一，D19）；terminal ts 晚於決策 ended → 補網 E2 跳過（解永久假陽性）。**E2 讀 ledger 的整合改動列入本里程碑交付**（非只測試句提及）。
- **escalate（升人）＝無 terminal 事件**：append-only 原生 pending 表示法，不加第三態；靠 `list --stale`/`resume` 浮出待人項（與 crash 同一救援路徑，代價僅重判一次）。
- **crash 恢復（🟠）**：檔存在後的 crash → `list --stale`+`resume`；**觸發後首筆寫入前**的窗（含 header 未落）→ 決策已 atomic 寫成 valid:false，補網 E2 週期掃 hop-1 兜底（E2 不依賴 cascade 檔）。
- **菱形依賴（🟠，D18 折入：釘作用點；T5 措辭校正）**：抵達鄰居時**先攤出候選（粒度鍵各一筆，記憶體層——非 ledger 寫入，pending＝無事件）交判斷**，`chain_visited`（節點級、由重放重建、隨 cascade 生命週期）只決定**展不展開下一跳**；被 visited 擋下的「不再展」寫一行 stderr log 留痕（對齊反靜默紀律）。**confirm 落盤後才展開該鄰居的下一跳**（visited 只認已落盤 confirmed——先展後寫會讓菱形防護看不到）。

**測試**（行為）：confirm/prune 依粒度鍵寫對、寫前驗證（檔不存在 rc=2／`--from` 不符 header rc=2／裸 `d<N>` rc=2／>4KB 行 rc=2）、重放折疊只折 transition 取物理序最後一筆、torn 尾行跳過不炸、torn header → resume rc=1 報不可恢復、append 併發不 lost-update（POSIX conditional；Windows 標 best-effort）、path 擋 `../`、中文節點名生成 cascade-id 合 pattern（生成側，D5 本旨）、list --stale 以活動齡撈到放置 cascade、resume 只重展**最終態** confirmed（先 confirm 後 prune 不重展）並列出正確剩餘待判、terminal ts 讓 E2 跳過、菱形（同鄰居經兩邊型各成一筆 item、僅展開一次）。

---

## M4 · 觸發 + typed hop-1 + 判斷閘連鎖（orchestration，最大最軟）

**目標**：把前三塊接成活的主網——翻案觸發、列鄰居、AI 判分級、確認才前進。

**建什麼**
- **[S1] 觸發（R1 折入：鑄造者＝觸發端 dispatcher，全鏈唯一）**：`decision-supersede` rc=0 → dispatcher ① **mint cascade-id**（公式計算）→ ② **`O_CREAT|O_EXCL` 建 ledger 檔 + 寫 header**（遇已存在→秒內重試綴序號；建檔是觸發端**唯一**的 ledger 寫入，transition 事件仍只由 confirm/prune 寫）→ ③ 用解包的 decision_id 呼**新內部 API `cascade_surface(env, node, root_decision_id)`** 列鄰居——進程內直呼函式、不 shell-out（現有 impact CLI **有 `--json` 但無 `--node` 模式**、seed 是 code 檔——D24 修正過時宣稱；`cascade_surface` 掛圖演算法層、吃現成 `Env`，不放會自建 Env 的 `cmd_impact`）。**②建檔＋③列舉同包一個獨立 try/except**（T6 釘範圍——rc=0 合約明文覆蓋「建檔/列舉失敗」，②的 IO 例外若沒同包，R8 的 bug 在建檔步重演）——不得放 supersede 的 atomic try 內（否則例外被既有 `except (ValueError,RuntimeError): return 2` 吞成 rc=2、違反 rc=0 合約，R8）。**移除 decision-add 觸發**（恆 valid:true、無 valid 變動語意）。**surfacing 對既有事件唯讀**、不叫 AI（判斷閘是外部 agent 步驟）；測試呼 supersede 只多出 temp vault 內的 header 檔、無真帳污染（D6 澄清）。
- **[S2] typed hop-1**：新增 CLI 皮 `impact --node <節點>`（供人手動查）與內部 API 共用同一 typed hop-1 原語：在 [P0] 索引上列 hop-1、只走 `verified_by`/`plan_refs`（`related` 弱、**v1 恆不展**，無覆寫旗標——要展等真需求）+ 標邊型 + 標受影響合約。單層列舉，多跳/visited 交 [S4]。**`--node` 是新增第三模式**（既有 `--file`/`--diff` 與 PreToolUse hook 熱路徑不受影響——hook 從不傳 `--node`；`--node` 支援既有 `--json`、與 `--depth` 互斥報 rc=2——單層列舉無深度語意）。
- **[S3] 判斷閘（AI 先判分級）**：AI 讀鄰居內容 + 翻的決策，判「真牽連嗎」。**不對稱防漏**：明顯牽連 → 自動 confirm（放寬）；明顯無關 → 自動 prune **但只在有把握時**（誤 prune＝靜默漏＝本守衛要防的頭號腐爛，故保守 + 留痕可抽查）；拿不準 → 升人（＝不寫 terminal 事件，靠 `list --stale`/`resume` 浮出）。寫回走 M3 CLI（`--by ai|human`）。
- **[S4] 連鎖＝確認才前進的工作清單**：只有判「真傳播」的鄰居進清單、展下一跳（**同一內部 typed hop-1 原語**，編排者進程內呼叫，不 shell-out CLI——與 [S1] 同軌，D3 消歧）；判無關當場斷。cycle-guard 防環（作用點見 M3 菱形合約）。

**釘死的合約**
- **觸發偵測（🟠）→ 縮 v1 範圍**：主路＝**decision-supersede 指令本身**當觸發（機械、不需 diff 啟發）；次路（手改 Edit 把 valid 翻 false）**v1 不做**（diff 偵測脆、補網 E2 週期兜底）。解「過寬/過窄」兩難＝先只認指令路徑。
- **輸出協議（D4+R1 折入：stderr 就是交接通道，schema 在此釘死）**：supersede 既有 stdout 成功行**逐字保留、仍在最前**（不破壞既有腳本假設）；cascade surfacing 輸出走 **stderr、行式固定 schema**（人可讀＋編排者可 parse，取代 `--json`）：
  ```
  CASCADE <cascade-id> ROOT <root_decision_id>
  NEIGHBOR <節點rel> EDGE <verified_by|plan_refs> [INVARIANT_COUNT <n>]   # 一(鄰居×邊型)一行
  NEIGHBOR-AMBIG <原wikilink字面> CANDIDATES <n>   # 歧義邊浮出:列候選數、不入自動判、升人(T4)
  ```
  （CASCADE 行由 **dispatcher** 印——它持有 mint 的 id 與 root id；NEIGHBOR 行由 `cascade_surface` 印——純 hop-1 列舉器不需 cascade_id 進簽名，職責切分 T2。`INVARIANT_COUNT`＝鄰居 invariant 總數（`extract_contracts` 現成），是顯著度提示——「受影響子集」是判斷閘的語意判斷、機械不標（T7 正名）。節點 rel 命名慣例不含空白（全 vault 實測 0 例），行式斷欄安全。）
  編排者（AI 判斷閘）從此 schema 取得 cascade-id/鄰居/邊型組 confirm/prune 指令——**判斷閘就是機器消費者，通道即協議**（R1 核心）。`rel-cascade list`/`resume` 為讀指令：輸出走 **stdout**（resume **首行印 CASCADE 行**——編排者跨 session 拿 `--from` 用的 root id 不需另讀帳檔——待判項沿用 NEIGHBOR 行 schema）、查有 rc=0／查無 rc=0 空輸出／參數錯 rc=2（沿 lumos 讀指令慣例）。surface 建檔/列舉失敗 → **supersede 仍 rc=0**（決策寫入已 atomic 完成，沿母設計失敗語意：不回滾、stderr 記一行 `CASCADE-ERROR <原因>`、補網 E2 兜底；gov 留痕以 stderr 行為主軌——既有 `_append_governance_log` 是 gate-finding 專用且寫失敗靜默吞，R5——另記 gov 事件為 best-effort 非「必留痕」宣稱）。
- **debounce（🟠）→ v1 簡化**：每次 supersede 各自一個 cascade；items 粒度鍵冪等去重。跨同 session 合併成單一 cascade **v1 不做**（無狀態 CLI 難判 session），`log()` 註明簡化。
- **判斷閘的可錯性（天花板）**：工具只保證把鄰居攤出來、留痕誰判的；**判得對不對是 GIGO**（AI/人）。auto-prune 的留痕須可事後抽查/翻案；誤 prune 的下游補跑走「重 confirm + `resume` 重展」（M3）。E3 落地時與 E2 的目標集重疊做統一去重（兩者皆 advisory、雙報僅噪音，v1 註記）。

**測試**（行為 + E2E）：supersede 觸發 surface（stdout 首行逐字不變、surface 走 stderr、surface 失敗仍 rc=0）、typed hop-1 只走對邊型不走無型別全邊、既有 `--file`/`--diff` 行為不受 `--node` 新模式影響、判「真傳播」才展下一跳、剪除不展、**升人＝無 terminal 事件且 resume 列得出**、環不重入；E2E×2（R10）＝①「B 決策翻案、A 沒跟上」→ 主網當場點名 A、且與補網 E2 不重報（terminal ts 跳過）；②全鏈場景「AI 誤 prune → 人翻案重 confirm → resume 重展該鄰居下游 → 下游新 item 進待判」逐步斷言（非只泛化 ledger 層）。

---

## 已拍板（2026-07-14 locked，進 design-loop 前定案）

1. **交付節奏＝整包**：M1-M4 依序建/測、不中途獨立 ship，最後整包交付（E3 隨整包上）。
2. **decision_refs＝單向**（Verification→決策）：反向查用 P0-style 掃描，不加寫入負擔。
3. **次路觸發（手改 Edit 翻 valid）v1 不做**：只認 `decision-supersede` 指令路徑，手改交補網 E2 週期兜底。

## 實務隱患

- **AI 判斷閘 GIGO（M4）**：auto-prune 判錯＝靜默漏傳播＝本守衛要防的頭號腐爛。緩解＝不對稱分級（prune 只在有把握時）+ 留痕 `--by ai` 可抽查翻案；但「有把握」的判準本身是散文、無機械閘——這是全案最軟的一塊。
- **reindex 髒圖遷移（M1）**：既有 vault 決策格式不齊（0-indent/tab/block scalar content），`decision-reindex` 對解析不到的決策項要明確拒絕（同 supersede 現行「不支援 0-indent」語意），不可靜默跳過造成 ID 缺洞。
- **ledger 檔案增長**：append-only 不清理 → 帳本目錄（M3 新建的 `governance/rel-cascade/<cascade-id>.jsonl`）隨翻案累積。v1 接受（翻案頻率低、檔小），`list --stale` 兼作可見性；閾值清理列 future。
- **supersede 觸發的執行環境**：dispatcher 在 CLI 進程內呼 `cascade_surface` → 輸出協議已在 M4 合約釘死（既有 stdout 首行逐字保留、surface 走 stderr、失敗仍 rc=0）；殘留風險＝消費 stderr 的腳本若有（罕見）會多看到 surface 行。
- **item 級發現齡盲點（r3 C5，已知接受）**：`list --stale` 量 cascade 級活動齡——同 cascade 其他 item 持續動、恰有一個 escalate 項被遺忘時撈不到它；item 第一次被 surface 的時間無記錄（surface 唯讀）。v1 接受（resume 每次仍會列出它），逐 item 齡列 future。
- **E2 精化的相容窗**：M1 後「有 decision_refs 精化、無則退回節點級」雙軌並存——舊 Verification 未回填 decision_refs 前，E2 精度不均；reindex+回填的推進節奏要留意。

## 審計修正紀錄

**r1（2026-07-15，panel：3×sonnet 異鏡頭 + Codex 否決席讀 repo + opus 批次辯方）**：canary 3/3 caught（a 壞交叉引用 recraft×1／b 未定義旗標／c 未定義欄位 recraft×1，均過 haiku 難度探針）。機械 refcheck 1 修（帳本目錄裸路徑宣稱改模板形式——尚不存在的提案路徑不寫成現存宣稱）。去重 24 條候選 → 辯方駁倒 3（D11 重放序歧義——被 canary-log 慣例 scripts/lumos:2114 反證；D12 torn write——repo jsonl fail-skip 慣例已定；D20 熱路徑相容——`--node` 是新模式 hook 不傳）、降級 18、存活 3 硬傷全數折入：
- **D5（blocker）→ cascade-id 改純生成式** `c-<ts>-<hash8>`，消解中文淨化問題；`from_decision_id` 釘全域格式。
- **D10（major）→ 並行宣稱降級**：專用 helper 單次 bytes write + 平台誠實聲明，撤「O_APPEND 行級原子不需鎖」強宣稱。
- **D16（major）→ 補 `rel-cascade resume`** 交付項（「續」落地；兼收 escalate 浮出與誤 prune 翻案補跑下游）。
- D4（major）→ M4 輸出協議釘死（stdout 首行逐字保留/surface 走 stderr/失敗仍 rc=0）。
- minor 批次折入：dispatcher 解包與 ID 自驗（D8/Codex）、reindex max+1 接續（D14）、E3 dangling ref（D13）、投影比較（D9）、活動齡措辭（D17）、菱形作用點+skip 留痕（D18）、terminal ts 命名統一+E2 讀 ledger 入交付（D19）、[S1]/[S4] 同軌消歧（D3）、`--json` 過時宣稱修正（D24）、E2/E3 去重註記（D23）、回填語意任務註記（D21）、M1/M2 序列建置註（D15）、升人原生 pending 表示（D2）、併發 last-writer-wins 註（D1）、觸發唯讀無污染澄清（D6）、首筆前 crash E2 兜底（D7）。

**r2（2026-07-15，panel 同制）**：canary 3/3 caught（d 憑空測試夾具 recraft×1／a 壞引用指向 M2 不存在的小節／b reindex 未定義檢核旗標）。去重 12 候選 → 辯方駁倒 1（R6 escalate 凍齡——spec 原文已明標接受）、降級 7（R2 同秒重用被 **supersede-once 閘**反殺——同決策二次 supersede 被 rc 拒，「多 cascade」不可達；R8 被綁定測試接住；R5 stderr 主軌已保留痕）、存活 4 全折入：
- **R1（blocker）→ 鑄造者＝觸發端 dispatcher**（mint + O_EXCL 建檔寫 header，全鏈唯一）＋ **stderr 行式固定 schema（CASCADE/NEIGHBOR 行）＝編排者交接通道**；list/resume 輸出協議補釘。
- **R3（major）→ decision_id 語意＝root 全鏈攜帶**（參數改名 root_decision_id；resume 只重展最終態 confirmed）。
- **R4（major）→ confirm/prune 寫前驗證**（檔存在/header 相符/--from 歸屬），建檔只屬觸發端。
- **R12（major）→ supersede 選擇端唯一命中**（多重命中 rc=2 列候選＋接受 #dN 定址——root cause 在選擇端非 verify 層）。
- minor 批次：event 判別欄（R7）、torn header rc=1、4KB 寫前拒、裸 d\<N\> 拒收、UTC 釘死、sha1/ts 標新格式、summary O_APPEND 措辭（R11）、總覽表補 reindex/list/resume（R9）、E2E×2 全鏈場景（R10）、`related` v1 恆不展、`--node`×`--json`/`--depth` 互動、reindex 簽名單節點、visited 重建規則、gov 留痕降 best-effort（R5）、B 席行號宣稱 8461 被機械反證（實際 8553——B 的結構觀察仍真，成就 R8）。

**r3（2026-07-15，panel 同制，cap 末輪）**：canary 3/3 caught（c 未定義欄位／d 憑空快照檔／a 引用被引合約不存在的分款編號，各 recraft×1 過探針）。三席聚焦「修補之間互相打架」，去重 8 條 ≥major 候選（decision_id 格式鏈、cascade_surface 簽名、E2 讀帳鍵、歧義邊隱形、item 舊措辭、try 範圍、framing/CONTRACTS、torn header rc）+ 7 minor。**辯方 8 條全數降級 minor、無一維持**——關鍵反證：header 全域格式其實已釘（spec「root 決策全域格式存檔內」，兩席漏看）、rc=0 覆蓋範圍被輸出協議明文鎖死、E2 本就 typed 反查帶邊型、direct-hop 恰覆蓋 E2 全部 candidate（Codex 自己的行號核）、全 vault 實測 0 空白檔名。Codex 否決席轉 fold：E2「全鏈可算」收斂為 resume 全鏈/E2 direct-hop、`CONTRACTS`→`INVARIANT_COUNT` 正名、綴序號公式 `c-<ts>-<hash8>(-<n>)?`。**存活 max=minor → clean round**；15 條殘留（全句級）折入 v4：supersede 端組全域格式回傳、dispatcher/cascade_surface 印行職責切分、NEIGHBOR-AMBIG 行、「一(鄰居×邊型)一行」、②③同包 try、torn header rc=2 枚舉、resume 首行 CASCADE、confirm 落盤才展、header 超限 fail-open、ambiguous 去重鍵字面、item 發現齡盲點註記、#dN help/reindex 指引。

## 進實作前（紀律）

本 spec 完成 → 交 **lumos-design-loop**（高風險：碰寫入路徑/ledger 並行/連鎖爆炸面，`--need 3`）過 canary-護的對抗審計到 `loop status --gate` 收斂，**才**進實作。各里程碑落地的 Verification 以 `plan_refs` 回指本節點（意圖鏈）。
