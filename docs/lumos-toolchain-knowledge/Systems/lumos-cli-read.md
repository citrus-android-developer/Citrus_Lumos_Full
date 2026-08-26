---
type: system
status: done
created: 2026-06-26
updated: 2026-08-16
self_audit: sonnet/2026-08-16
tags:
  - type/system
  - status/done
summary: |-
  KEY:[2026-08-05]檢索考卷加 synonym 類(toolchain 4 題/landmark 3 題,查詢用別名期望命中帶 aliases 節點;檢索實跑 ground、單標註者、goldset 註記題集變更)——aliases 欄的貢獻自此每週考卷自動量;出題日 held 基線:toolchain ranked nDCG@5=0.789、landmark=0.840
  KEY:[2026-08-05 標籤收編]context 頭部攤出 type/status 以外全部 tag 家族(priority/scope/flag/risk…,`家族:值` 併入 meta 行)——寫給 AI 的分類資訊原本在進場主讀路徑隱形 [test:t_context_header_extra_tag_families];impact 固定席加第三軸 RISK·值(risk/ 標節點保送必看,軸序 IRREVERSIBLE>INVARIANT>RISK) [test:t_impact_contract_risk_axis]
  KEY:[2026-08-05]search 排序加 aliases 欄(權重 3.5,略低於標題 4.0)——frontmatter aliases list 進 BM25F;同義詞落空(搜「作廢」架構圖寫「沖銷」)的最便宜解,寫入者留同義詞一次、檢索受益永久 [test:t_search_aliases_field]
  KEY:[2026-08-04]+quote-check(vault-free 讀命令):報告引句逐條對回凍結快照(_quote_norm 正規化;rc0 全 ok/rc1 miss/rc2 IO或零引句)——disposal 閘的④號合取同源消費 [test:t_quote_check_normalization_and_verdict]
  FLOW:任一讀指令 → find_vault(從 cwd 往上找 docs/*-knowledge 或 standalone vault root) → load_vault(掃全 .md、解 frontmatter+wikilink) → Env(notes/by_stem/edges) → 各 cmd_* 純讀印出(context/show 另寫 usage-log 事件帳;doctor --ci 寫 governance-log) → return 0(查無/正則錯=非0)
  KEY:[2026-08-16 query 結構化查詢]新讀原語 `query`——WHERE over 標籤家族(--tag 可重複=AND/--no-tag/--active 排收案態/--contract 沿 extract_contracts/--linked 1-hop 鄰域/--json);旗標 AND 疊加不發明查詢語言(borrow zk list);預設排除 superseded 對齊 search 真遺忘+--include-superseded 逃生;bare 無條件 rc2(對齊 stale --candidate);緣起=標籤收編後「欄位只有顯示沒有篩選」,Landmark 三情境實測見 [[Projects/架構圖結構化查詢_計劃]] [test:t_query_tag_and,t_query_no_tag_and_active,t_query_contract_uses_real_parser,t_query_linked_scope,t_query_forget_superseded,t_query_bare_rc2,t_query_json]
  KEY:read/traverse 14 原語全建在記憶體 Env 之上(notes 字典 + 雙向 edges + by_stem 索引);**不改架構圖節點檔**——context 與 show 寫 best-effort usage-log 事件帳(A2,2026-07-11 起)、doctor --ci 視 findings 寫 governance-log,其餘讀指令純讀([[Projects/lumos-show讀取入口_計劃]] r4 收斂措辭,修 A2 起「零副作用」宣稱漂移);與 7 個寫入原語(set/append/new/decision-* …)互斥
  KEY:進場三步入口固定 search(定位節點) → context(掃脈絡,頭部突顯 ⚠ 合約) → contracts(查硬合約 invariant 改=breaking),CLAUDE.md 規定動既有系統第一個工具呼叫必須是 lumos 而非 grep/Read/DB
  KEY:doctor 是全圖權威巡檢(4 檢查 orphans/unresolved/verified_by 雙向(stale/fail 驗證豁免——E1 拔死背書後不反咬漏寫)/plan_refs 意圖鏈 + 同名守衛 + frontmatter lint + Check T/R/H;Check P 失效檔案認領(inline-code 路徑指死碼);Check E1 失效背書(verified_by 指向 stale/fail/superseded 驗證→死背書;superseded=真遺忘第二刀 2026-07-26,同刀:Check3 skip 集+sync-verified-by 過濾+orphan 豁免四位一致)+ Check E2 建在被推翻決策上(決策 valid:false+ended → M2 共用 typed 索引查連入來源、updated 早於 ended → 落後邊;decision_refs 精化只標指到那條;M3 帳本抑制 terminal ts>=ended 跳過=主/補網不重報)+ Check E3 意圖鏈斷義(decision_refs 指翻案決策+dangling 浮出);關係層皆軟提醒;Check J regen 重生來源守衛[M1 2026-07-16]——regen 節點 provenance 分級:J-a 拒發明合約(INVARIANT 標記行需 [src:]/[git:] 意圖證據)+J-b DECISION 四態+J-c 證據指針 substring gate(共用 _validate_repo_ref 不經 top_dirs 靜默過濾;shallow 降 warn_soft 顯性)+J-d 唯讀提醒;與 lint 共用 check_regen_provenance 防兩入口漂移 [test:t_check_j_regen,t_check_j_git]);與 lint 分工——lint 只看單篇 node-local(regen 節點 Check J 為 opt-in 例外需檔案+git 存取)、predicts pre-push 會不會擋
  KEY:search 預設排除 fenced+inline code(對齊 doctor 連結抽取慣例,--code 才含)、大小寫不敏感 substring、--regex 切正則;結構化查詢走 query(標籤家族 WHERE)/contracts/decisions/stale 而非 search
  KEY:★多詞回退(2026-08-03 人裁翻為預設,--no-any 逃生;--any 留相容)★——整串片語在檢查範圍內無命中時,退成各詞 OR 召回再交 BM25F 排序。★fallback-only 不是永遠 OR★:片語找得到就不觸發,故對既有查詢零回歸(機械可證+對照組 5 題逐檔實證)。同時印★逐詞覆蓋★到 stderr——回退後搜尋幾乎不可能再回 0,「查無」這個訊號會消失,逐詞覆蓋把它換一種形式還回來(某詞 0 命中會標 ★)。★訊息宣稱的範圍不得大於實際檢查的範圍★:範圍字串必須同時反映 --path／作廢與否／--code 三個維度(這條在 code-loop 四輪裡被抓到三次,每次都是漏掉其中一個維度) [test:t_search_multiword_fallback_is_default_and_only_on_zero,t_search_multiword_fallback_reports_per_term_coverage,t_search_multiword_fallback_scope_message_covers_path_and_superseded]
  KEY:★預檢迴圈與主迴圈共用 `_search_visible_lines` 單一實作★(2026-08-03 code-loop r2)——原本預檢自己一份「整段 regex 剝 fence」,遇未閉合圍欄與主迴圈分岔,導致逐詞覆蓋虛報非零;同源修法也收編了 `load_vault`／`cmd_guard_trace`(見 [[Issues/2026-08-03_剝除與邊界解析的既有缺陷群]],★`FENCE_RE` 仍活在 refcheck 家族三處未收編★)
  KEY:★INVARIANT★ search 預設排除 status=superseded 節點但不排除 stale(真遺忘,GateMem 2026-07-24;stale 是待重驗警訊,藏了=製造新洞,doctor Check S 綁 stale+superseded 正是反例),--include-superseded 逃生;濾網插「命中確認後、三路分岔前」故 ranked/legacy/regex 三路一致、hidden 數=命中被藏筆數非全庫;隱藏數走 stderr(全模式含 --files-only,不污染 stdout)、--json 加 hidden_superseded 欄位 [test:t_search_forget_superseded] [audit:sonnet/2026-07-24]
  KEY:[缺口已補 2026-07-25]原「Check T 無 Python profile」缺口已補(TEST_PROFILES 加 python:行首錨+檔名錨+comment_strip=none),本合約隨之升回正式;★根因更正★:當初被判偽證據的真兇不是 dirs(Check T 掃描走全 repo 不吃 dirs),是 discover 對所有語言剝 C 式註解、test_lumos.py 中文註解的 status/* 與遠處 glob 字面 **/ 配對吃掉半個檔(260→94);詳 [[Projects/CheckT-Python-profile_計劃]]
  KEY:真遺忘只做 search 這一刀(2026-07-24 使用者裁定);context 基本鄰居/推薦、impact、doctor 對作廢驗證的不一致=已知殘留(impact 永不做預設藏——direct 命中是事故記憶);設計與三審見 [[Projects/真遺忘召回過濾_計劃]]
  KEY:讀指令屬「專案層」——以 cwd find_vault 鎖定本專案 vault(不受同名 vault 影響);對比 install/bootstrap 的「機器層」(全域 lumos + user-scope skills)
  DEP:scripts/lumos load_vault/Env/find_vault｜extract_contracts(contracts/context 共用)｜parse_decisions(decisions/stale)｜status_of(links/map/stale 標狀態)
  KEY:stale --candidate 無 --match 直接 rc2 拒絕(反直覺限制:即使給了 --candidate 沒帶 --match 也拒,避免列全 vault 變噪音);--candidate --match <詞> 才有效
  TEST:scripts/test_lumos.py(t_-prefixed Python 回歸,非 doctor Check T 認的 C# xunit)
related:
  - "[[Systems/lumos-cli-write]]"
  - "[[Systems/lumos-cli-lifecycle]]"
  - "[[Projects/檢索多詞回退_計劃]]"
  - "[[Issues/2026-08-03_剝除與邊界解析的既有缺陷群]]"
  - "[[Projects/架構圖結構化查詢_計劃]]"
decisions:
  - content: 讀寫原語嚴格分軌——13 個讀指令不改架構圖節點檔(context/show 寫 best-effort usage-log 事件帳、doctor --ci 寫 governance-log,其餘純讀;2026-07-21 修 A2 漂移後措辭);一切 frontmatter 寫入走 set/append/decision-* 等寫入原語(走 atomic_write_verify:寫 tmp → re-parse 自驗 + lint 無新指紋 → atomic rename)
    id: d1
    context: 直接手改 frontmatter 會繞過寫後自驗與鐵則防護(YAML 格式爆、ghost 節點、裸合約),且讀指令若兼寫會讓「查脈絡」帶副作用
    why_chosen: 讀路徑不動架構圖內容才能放心當入口反覆掃(best-effort 事件帳/治理帳不在此限,2026-07-21 措辭修真);寫路徑集中過 atomic 自驗閘,任一步敗則 tmp 丟棄原檔不動,保證架構圖永遠可解析
    decided: 2026-06-26
    valid: true
  - content: doctor(全圖權威)與 lint(單檔快檢)分工——lint node-local 不掃 repo 比 doctor 快、寫完一篇立刻自驗、error 即 pre-push 會擋的同類;doctor 跑全圖跨節點完整性 + [test:] 存在性
    id: d2
    context: 每寫一個節點都跑全圖 doctor 太慢、回饋慢;但單檔檢查看不到跨節點完整性(orphans/雙向同步/意圖鏈)
    why_chosen: 兩段式——寫節點當下用 lint 拿快回饋(預測 pre-push),收尾再用 doctor 跑全圖權威巡檢;push 前 pre-push 仍兜底再擋一次
    decided: 2026-06-26
    valid: true
  - content: 讀指令以 cwd find_vault 鎖定「專案層」vault(往上找 docs/*-knowledge 或 standalone vault root),不受多專案同名 vault 影響;與 install/bootstrap 的「機器層」分軌
    id: d3
    context: Obsidian CLI 的 vault= 只吃資料夾 basename,多專案都叫 docs/knowledge 會撞名;lumos 改以 cwd 往上找消歧
    why_chosen: cwd-based 定位讓任何專案子目錄直接 lumos <cmd> 都鎖到正確 vault,機器層工具(全域 lumos/skills)則一次裝好共用
    decided: 2026-06-26
    valid: true
verified_by:
  - "[[Verification/2026-07-14_relguard_E1失效背書]]"
  - "[[Verification/2026-07-14_relguard_E2建在被推翻決策上]]"
  - "[[Verification/2026-07-15_主網M1_決策穩定ID]]"
  - "[[Verification/2026-07-15_主網M2_typed-edge索引]]"
  - "[[Verification/2026-07-15_主網M3_cascade帳本]]"
  - "[[Verification/2026-07-15_主網M4_觸發與連鎖]]"
  - "[[Verification/2026-07-16_fromscratch守衛M1_CheckJ]]"
  - "[[Verification/2026-07-24_真遺忘search排除superseded]]"
  - "[[Verification/2026-08-05_流程優化六件落地]]"
  - "[[Verification/2026-08-05_標籤結構收編落地]]"
  - "[[Verification/2026-08-16_架構圖結構化查詢query落地]]"
---
# lumos-cli-read

`scripts/lumos` 的 **read/traverse 核心原語**(14 個)——架構圖的查詢與遍歷面。對既有系統動手前,CLAUDE.md 規定第一個工具呼叫必須是這組 `lumos` 讀指令,而非 grep / Read / Explore / DB(code 讀不出「為什麼 / 邊界 / 哪些是不可改合約 / 驗過沒」)。

源起:CLI 核心非日報觸發(read 原語是 lumos 工具鏈的地基能力,非某日報 gap/inspiration 衍生的單一功能)。

## 共同地基
所有讀指令先 `find_vault`(從 cwd 往上找 `docs/*-knowledge` 或 standalone vault root)→ `load_vault` 掃全 `.md`、解 frontmatter + wikilink → 建記憶體 `Env`(`notes` 節點字典、`by_stem` 名稱索引、雙向 `edges` = (out_e, in_e))。各 `cmd_*` 在此 Env 上純讀、印出、`return 0`(查無資料 / 正則無效等 → 非 0)。**不改架構圖節點檔**——context/show 寫 best-effort usage-log 事件帳(A2)、doctor --ci 視 findings 寫 governance-log,其餘讀指令純讀(2026-07-21 修「全程不寫檔」措辭與現實的 A2 漂移)。

## 14 個原語(對應 cmd_* / scripts/lumos)
- **進場三步(入口固定順序)**
  - `search <詞> [--path Systems] [--regex] [--files-only] [--code] [--include-superseded]`(`cmd_search`):全文搜尋 frontmatter+body,大小寫不敏感 substring。**預設排除 fenced + inline code 區塊**(對齊 doctor 連結抽取慣例),`--code` 才含;`context` 標記命中區域(★INVARIANT★/KEY/fm:欄位/body)。**預設排除 `status=superseded` 節點(真遺忘;不排 stale)**,`--include-superseded` 逃生、隱藏數走 stderr(核心行為與回歸守衛見上方 summary KEY)。**多詞查詢預設走回退**(2026-08-03；`--no-any` 關)，並印逐詞覆蓋到 stderr。職責=自由文字,結構化查詢走 query/contracts/decisions/stale。
  - `context <節點> [--brief]`(`cmd_context`):節點 + 鄰居 summary 壓縮索引(MemPalace closet)。**頭部直接攤出 ⚠ 合約**(extract_contracts);`--brief` 只給 meta + summary 首兩行 + 鄰居名單(壓 token)。
  - `show <節點> [--body-only]`(`cmd_show`,2026-07-21):**節點檔完整內容**(frontmatter+body)——context 是壓縮導航(不含 body),show 是完整真相讀取;解「規範禁 Read 架構圖但無全文入口」的結構性違章(外審 blocker,設計/審計 loop 見 [[Projects/lumos-show讀取入口_計劃]])。`--body-only` 以 `split_frontmatter` 剝離開頭 frontmatter;重開檔失敗(壞 symlink/race)→ stderr+rc2 不裸 traceback。
  - `contracts [節點]`(`cmd_contracts`):合約登記簿,列 `★INVARIANT★`(改=breaking)/ `★DEBT★`(可改);**只認 KEY 行前綴標準格式**;★INVARIANT★ 顯示綁定的 `[test:]`,未綁=⚠(doctor Check T 會擋)。
- **巡檢 / 完整性**
  - `doctor [--ci]`(`run_doctor`,非 cmd_ 前綴——L4 審計 2026-07-24 修正指針):全圖權威健康巡檢——4 檢查(1/4 Verification orphans、2/4 unresolved wikilinks 破連結、3/4 verified_by 雙向同步(stale/fail 驗證豁免,E1↔Check3 矛盾修 2026-07-15)、4/4 plan_refs 意圖鏈)+ 同名守衛 + frontmatter lint + Check T(★INVARIANT★→測試綁定)/ Check R(可逆性回退)/ Check H(漏標可逆性軟提醒,僅 --ci 掃 diff)+ Check P(失效檔案認領:inline-code 路徑指向已不存在檔案)+ Check E1/E2/E3(關係層:E1 失效背書 verified_by→stale/fail、E2 建在被推翻決策上 決策翻案而 typed 連入來源未跟上——鄰居有 decision_refs 時精化為只標指到那條、且 M3 rel-cascade 帳本有 terminal 判定(ts>=ended)即跳過＝主/補網不重報、E3 意圖鏈斷義 decision_refs 指向的決策已翻案+dangling 浮出;皆軟提醒)。`--ci` = `--strict` + 無色彩,且會寫 `.governance-log.jsonl`(寫者=doctor --ci＋anchor approve,scripts/lumos:416 自述;原「唯一寫者」為漂移,2026-07-21 順手修真)。
- **遍歷 / 關聯**
  - `links <節點>` / `backlinks <節點>`(`cmd_links`,reverse=True 即 backlinks):列連出 / 連入節點 + 狀態。
  - `map <節點> [--depth 2]`(`cmd_map`):鄰域樹狀展開,`↺` 標已出現過(防環)。
  - `export --folders <…> [dot|mermaid]`(`cmd_export`):導出指定資料夾子圖為 graphviz dot / mermaid。
- **結構化查詢(2026-08-16)**
  - `query [--tag 家族/值]… [--no-tag …] [--active] [--contract] [--linked <節點>] [--include-superseded] [--json]`(`cmd_query`):**WHERE over 標籤家族**——旗標一律 AND 疊加,不發明查詢語言(borrow zk `list` 旗標語意)。`--active`=status 不在收案態(done/pass/superseded/resolved/wontfix);`--contract` 沿用 `extract_contracts` 只認 KEY 行標準格式(散文提及不算);`--linked`=範圍縮到該節點連入+連出 1-hop 鄰居(不含錨點);預設排除 superseded(對齊 search 真遺忘)、bare 無條件 rc2(對齊 stale --candidate 慣例)。`--json` 輸出結構:`{results:[{node,status,tags}],hidden_superseded}`(tags=type/status 以外家族)。緣起與 Landmark 三情境實測見 [[Projects/架構圖結構化查詢_計劃]]。
- **決策 / 重驗 / 概覽**
  - `decisions [節點] [--superseded]`(`cmd_decisions`):讀單篇 ADR 決策;`--superseded` 全 vault 掃 `valid:false` 被推翻的決策。
  - `stale [--match <字串>] [--candidate]`(`cmd_stale`):`status:stale` 清單;`--match` 掃 valid_under + revalidate_when 命中(含 Archive);`--candidate --match <關鍵字>` 聚焦活躍 Verification 的 revalidate_when(排 Archive)= 「改 X 時該重驗哪幾篇」。bare `--candidate` 或空 `--match` 直接 rc2 拒絕(避免列全部變噪音)。
  - `recent --days N`(`cmd_recent`):近 N 天修改節點(mtime 排序)。
  - `stats`(`cmd_stats`):各資料夾節點數 + total。

## 關鍵設計
- **讀寫嚴格分軌**:這 13 個不改架構圖節點檔(context/show 寫 usage-log 事件帳、doctor --ci 寫 governance-log,其餘純讀);寫入走另 7 個原語(set/append/new/archive/decision-add/decision-supersede/self-audit),經 `atomic_write_verify`(寫 tmp → re-parse 自驗 + lint 無新指紋 → atomic rename,任一步敗則 tmp 丟棄原檔不動)。詳見寫入原語節點。
- **doctor vs lint 分工**:doctor 全圖權威(跨節點 + [test:] 存在性);`lint <節點>` 單檔 node-local 快檢,predicts pre-push 會不會擋。寫節點當下 lint,收尾 doctor。
- **專案層 vs 機器層**:讀指令以 cwd `find_vault` 鎖本專案 vault(不受同名影響);install / bootstrap 是機器層(全域 `lumos` + user-scope skills),不在本節點範圍。

## 已知限制
- `search` 對 fenced/inline code 內字串預設看不到(需 `--code`);要查「散文裡剛好提到 ★ 字面」與「真合約標記」靠 `contracts` 的 KEY 行錨定區分,不靠 search。
- 同名節點:`find` 取第一個並印 `⚠ 同名筆記` stderr 警示;消歧靠資料夾前綴命名(`docs/<slug>-knowledge/`)。

## 相關
- 操作表權威:`CLAUDE.md`(入口三步 + 標籤規範)、`skills/lumos-project-notes/SKILL.md`(25 子命令全覽:讀取 14 + 寫入 7 + 安裝/生命週期 4)。
- 實作落點:`scripts/lumos` `cmd_search`/`cmd_context`/`cmd_contracts`/`run_doctor`/`cmd_links`/`cmd_map`/`cmd_export`/`cmd_decisions`/`cmd_stale`/`cmd_recent`/`cmd_stats` + `load_vault`/`Env`/`find_vault`。
- 回歸測試:`scripts/test_lumos.py`(Python t_-prefixed)。
- 對稱寫入原語見 [[Systems/lumos-cli-write]];安裝 / 生命週期見 [[Systems/lumos-cli-lifecycle]];`lumos --help` 為現行權威。

## 近期修正
- 2026-07-11 export html 視覺化七項優化（使用者提案全採）：①標籤 LOD（重要度排名×相機距離預算,hover/選中恆顯）②驗證摺疊預設開（Verification 隱藏、母節點標 ✓N 徽章、選中母節點自動現形）③單擊容差（pointerup 位移<5px 兜底,修 3D 旋轉吃 click）＋2D/3D 切換（numDimensions+鎖旋轉）④搜尋 Enter 飛至最佳命中開面板（前綴>包含,同級取重要度）⑤「只看合約」chip（合約節點+其 verify 目標）⑥面板返回鈕（navStack;搜尋跳轉不入棧=已知取捨）⑦時間軸生長回放（節點 date/created,拉桿+▶ 播放）。真機驗證：Chrome 擴充+Playwright 雙路實測全過;t_export_html +10 骨架斷言。


- 2026-07-11 export html 視覺化修：節點面板關閉鈕 `#close` 被後繪的 `#phead`（透明背景）蓋住，真實點擊被攔截而程式呼叫正常——Playwright elementFromPoint 實測定位，補 `z-index:3`。教訓：疊層 UI 的可點性要用真實命中測試驗，不能只驗 handler 有綁。
