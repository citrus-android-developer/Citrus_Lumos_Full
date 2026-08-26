---
type: project
status: done
created: 2026-07-05
updated: 2026-07-06
tags:
  - type/project
  - status/done
related:
  - "[[lumos-cli-lifecycle]]"
summary: |-
  FLAG:DECISION
  KEY:收破口——`lumos update`/`init` 從不刷新既有專案 CLAUDE.md 紀律區塊(教會 Claude 用工具的 vendored 範本改了傳不到消費端);根因三合謀:_scaffold_project 遇既有 vault 提早 return(:3654)+ 注入 create-only(:3671)+ update 在 re-vendor 範本「之前」才呼叫 scaffold(:3557 vs copy2 :3571 順序錯)
  KEY:修法=解耦——把「注入 CLAUDE.md」從「scaffold 架構圖資料」拆開;scaffold skip-if-exists 對架構圖資料是對的,錯在注入搭便車
  DECISION:再注入語意=覆蓋 sentinel 之間 + 印 diff(sentinel 外逐字保留;無變靜默;手改區塊內會被蓋但區塊本標「勿手改」,diff 讓覆蓋可見)
  DECISION:含機械漂移守衛(test + doctor Check):本 repo CLAUDE.md 區塊 == resolved template,逐字比對(內容比對 > 版本比對)
  DECISION:交付物 3 版本號=「人可讀標籤 + 粗 nudge」,嚴禁當 staleness oracle;單一源 LUMOS_VERSION → 機械蓋進 START sentinel 行(在比對區「外」,不耦合守衛)
  KEY:誠實天花板=版本號不證內容對(bump 可漏),真守衛是內容比對;--no-verify 繞得過 doctor;非 oracle
  DEP:[[lumos-cli-lifecycle]]
  TEST:design-loop 3 輪(全 caught,見 canary-log claude-reinject)——架構折穩(解耦/ReInjectResult三態/BlockSpan單一源/版本=標籤/內容比對守衛);severity 未收斂(major→blocker→blocker)因 glue 密集=文檔化天花板memory:design-loop-completeness-ceiling-shown;使用者裁定轉 TDD(gate 未形式過關,偏離理由=glue非架構,已註明),殘留實作細節交紅綠測試釘
---
# CLAUDE 注入 re-sync 與版本標籤_計劃

> 收「vendored 教學範本(`graph-discipline.md`)改了、傳不到既有消費專案 CLAUDE.md」的破口(使用者點出「最重要的是教會 Claude 用本工具」)。設計權威節點;進實作前過 `lumos-design-loop` skill 到收斂。

## 背景:破口(三環節合謀)
`graph-discipline.md` 是注入每個消費專案 `CLAUDE.md` 的「教會 Claude 用本工具」範本。它更新後,`lumos update` 會刷新 CLI/hooks/vendored 範本檔本身,**但 CLAUDE.md 的注入區塊從不重跑**。根因:
1. `_scaffold_project`(`scripts/lumos:3652-3654`)遇既有 vault 提早 `return` → 走不到注入。
2. 注入是 create-only(`:3671` `elif SENTINEL not in cm`)→ 有 sentinel 就跳過。
3. update 路徑 `_vendor_toolchain` 在 **re-vendor 範本之前**(`:3557` 呼叫 scaffold vs copy2 `:3571`)→ 就算注入也讀到舊範本。

`Systems/lumos-cli-lifecycle` 的 KEY 已宣稱「graph-discipline.md 要重跑 init/update 才刷新」——**這是文件寫的意圖,code 沒做到**。本計劃是讓 code 對齊既有意圖(bug fix,非 spec 變更)。

## 修法核心:解耦
把「注入 CLAUDE.md」從「scaffold 架構圖資料」拆開。scaffold 的 skip-if-exists 對**架構圖資料**是對的(保護資料不被動),錯在注入搭了它的便車、繼承了 skip。

## 交付物 1:re-inject(覆蓋 + diff)
**回傳型別(F1 blocker,三態不可塞進 `str|None`)**:`_reinject_claude_block(root, slug) -> ReInjectResult`,`ReInjectResult = namedtuple("ReInjectResult", "status diff")`,`status ∈ {"created","updated","unchanged","appended","sentinel_broken"}`、`diff: str|None`(僅 updated 帶 unified_diff,其餘 None)。呼叫端依 status 印(updated→印 diff;sentinel_broken→印警示)。取代原 `str|None`(值多載 = 隱式約定,無型別守護)。

流程:
- 讀**已 vendor 的**範本 → 把 `{{KG}}` 佔位符換成該專案的 knowledge 資料夾相對路徑 → strip → 包 sentinel(START 行含交付物 3 版本戳)。
- CLAUDE.md 不存在 → 建(status=created);**兩 sentinel 齊全** → 替換之間(status=updated 帶 diff / unchanged);無 sentinel → 附加(status=appended)。marker 尋找 + body 定位用交付物 2 的 `_extract_claude_block_span`(prefix-based find 對版本後綴穩健)。
- **sentinel 外內容逐字保留**;`difflib.unified_diff(舊body, 新body)`:有變 → 寫、status=updated;無變 → 不寫、status=unchanged(idempotent 靜默)。

**半壞 sentinel(F-04,顯式)**:只 START 無 END / 只 END 無 START / END 在 START 前 / 重複出現 → **繼承 `_deinit_strip_claude:3480-3481` 的 no-op 邏輯**(不覆蓋、不自動修復),但回 `status="sentinel_broken"`(非靜默;呼叫端印警示,由交付物 2 doctor 報漂移交人肉裁)。理由:半壞=使用者可能手改過(START 標「勿手改」),盲改毀狀態。

**BOM/CRLF(F-09)**:讀時 strip 前導 BOM(`﻿`)後再 find marker;寫一律走 `_write_lf`(強制 LF,同既有寫入慣例)。BOM 檔:注入後正規化為無 BOM + LF(與 T1 寫入「拒 BOM/CRLF」哲學一致)。

接線:
- `_scaffold_project` **移除**注入段(只留 vault 夾 + MOC + gitignore;其 skip-if-exists 只保護架構圖資料)。
- `_vendor_toolchain`:注入改到 **copy2 vendor 迴圈之後**呼叫(讀新範本 + 修 :3557 先於 :3567-3576 的順序錯)。
- `cmd_init`(F-06 + F5 順序):現有 `existing and not force → return 0`(`:3759`)會**繞過** re-inject。修法明定序列:**① 確保範本已 vendor(最新)→ ② re-inject → ③ 才走 existing/force 的 return 邏輯**。關鍵:re-inject「讀已 vendor 的範本」,故 vendor 必先於 re-inject(否則讀到上次留的舊 vendored 範本);兩條路徑(init/update)都保證 re-inject 讀到當次最新範本。不要求 `--force` 才刷新紀律區塊(re-inject idempotent+diff、對既有專案安全)。

## 交付物 2:漂移守衛(內容比對,真守衛)
- **test** `t_claude_block_matches_template`:斷言本 repo `CLAUDE.md` 兩 sentinel 之間 == `resolve(template)`。
- **doctor Check(新字母)**:`scripts/templates/graph-discipline.md` 存在 且 CLAUDE.md 有 sentinel → 區塊必 == resolved 範本,否則報漂移;`--ci` 擋。比對的是**repo 內範本↔自己 CLAUDE.md**(內部一致性,與上游新舊無關,消費專案不誤報)。
- 比對區 = 兩 sentinel「之間」,**不含 sentinel 行本身**(版本戳在 START sentinel 行,落在比對區外,故版本差不觸發內容守衛——標籤與守衛解耦)。
- **比對 slice 單一源 + 位移(F-05 + F2)**:單一函數 `_extract_claude_block_span(text) -> BlockSpan|None`,`BlockSpan = namedtuple("BlockSpan", "body body_start body_end")`——`body` = `START 行結尾 \n 之後` 到 `END 行開頭 \n 之前`、strip 首尾空白行的字串;`body_start/body_end` = 該 body 在原文的字元位移。**doctor** 用 `.body` 比對;**re-inject** 用 `body_start/body_end` splice(`text[:body_start] + 新body + text[body_end:]`),不再自己找一次 sentinel → 真「單一源」(F2:回 str 不夠 splice,故回 span)。半壞 → 回 `None`。對應測試 `t_version_bump_not_trigger_guard`(START 行改版本 → `.body` 不變 → 守衛淨)。
- **遷移零時點(F-02 + F8,分開兩情形)**:
  - **sentinel 完好** → doctor Check 與 re-inject 同批經一次 `lumos update` 送達(同 `_vendor_toolchain`;re-inject 在該次先跑)→「有新 check」時必已 re-inject,**無「有 check 未同步」窗口**。
  - **半壞 sentinel** → re-inject 回 `sentinel_broken`(no-op)→ doctor 會報漂移。這是**設計內 tradeoff、語意正確的真報**(半壞=手改痕跡,該讓人看見),**不納入「無窗口」保證**、也不是誤報。

## 交付物 3:版本標籤 + 粗 nudge(嚴禁當守衛)
**新增常數** `LUMOS_VERSION`(`scripts/lumos` 頂部,目前 code 中**不存在、本計劃新建**;release 手動 bump,允許粗——它是標籤,不是內容指紋)。

- **機械蓋落點(F4,免雙處維護)**:**範本 `graph-discipline.md` 的 START sentinel 保持無版本戳**(canonical `<!-- LUMOS:GRAPH-DISCIPLINE:START — 勿手改... -->`);版本由 `_reinject_claude_block` 在**包 sentinel 當下字串插值** `LUMOS_VERSION` 進去(`START_SENTINEL.format(version=...)`)。單一源=`LUMOS_VERSION` 常數,範本不帶戳→不會「改範本忘了 bump」。讀取 = 對 START 行空格切分取 `vX.Y`(parse 容錯:取不到 → 未知、不 nudge、不 crash)。
- **跨邊界 nudge 來源(F3,CI/無源可行性)**:比對「消費專案 CLAUDE.md sentinel 蓋的版本 vs **來源 clone 的 `LUMOS_VERSION`**」;來源 clone 用既有 `_lumos_src()` 解析(`$LUMOS_HOME`/`~/harness/lumos-toolchain`)。**來源 clone 不在本機(CI 只 checkout 專案 repo)→ 靜默 skip nudge**(不 crash、不誤報)。故 nudge 定位=**開發機 advisory**(源可達才提示),非 CI 硬檢查。`lumos update` 本身順手刷新版本;nudge 主要給獨立 `lumos doctor`(源可達時)的可見性。
- **F-03 定位澄清(消除「nudge 用版本落後 vs 版本非判準」的表面矛盾)**:版本與內容比對答**兩個不同問題**,不衝突——
  - **「你在不在最新 release?」**→ 版本比對,**粗、advisory、不擋**(nudge)。它是提醒「也許該更新」,**不是**「你的區塊此刻正確與否」的裁決。
  - **「你的 CLAUDE.md 區塊內容 == 你自己的範本嗎?」**→ 內容比對(交付物 2),**精確、擋(--ci)**,這才是正確性守衛。
  - 所以版本號**永不**回答正確性問題;它只回答「哪個 release」。版本落後 ≠ 內容不一致(update 後兩者一致但版本仍可能落後上游一個 tag)。版本可與內容差一格而不算 breaking——因為它從不被當正確性 oracle。

## 誠實天花板
- 版本號「有=那版」是假命題(bump 可漏)→ 只當人可讀標籤 + 粗 nudge,真守衛是內容比對(同「有寫下 undo ≠ 驗過能跑」)。
- doctor 那道 `--no-verify` 繞得過;覆蓋語意會蓋掉手改區塊內容(但標「勿手改」+ diff 可見)。非 oracle:守得掉「範本改了沒傳到」「repo 內漂移」,守不掉「刻意繞 + 手改還不看 diff」。

## 測試(TDD)
- 核心:`t_reinject_updates_existing`(status=updated 帶 diff)/ `_idempotent`(status=unchanged 無寫)/ `_creates_when_absent`(created)/ `_appends_when_no_sentinel`(appended)/ `_preserves_outside`。
- 整合(F10 邊界明定):`t_update_resyncs_claude` — **整合測試**,用臨時 fixture(本機臨時來源目錄 + 臨時消費專案,`_lumos_src` 指向該臨時源;**不走網路**),驗 `lumos update` 後 CLAUDE.md 區塊被刷新。CI 可跑(純檔案系統)。
- 半壞 sentinel(F-07):`t_reinject_only_start_no_end` / `_only_end_no_start` / `_end_before_start` / `_duplicate_sentinel` —— 皆斷言 `status=="sentinel_broken"` + 原檔不動。
- BOM/CRLF(F-09):`t_reinject_bom_crlf_normalized`。
- 守衛:`t_claude_block_matches_template`(本 repo 區塊==範本)/ doctor check 測試(漂移報、同步淨)/ `t_version_bump_not_trigger_guard`(F-05:START 版本改、`.body` 不變 → 守衛淨)。
- 版本:`t_version_stamped_in_sentinel`(inject 字串插值 LUMOS_VERSION)/ `t_version_parse_tolerant`(取不到版本不 crash)/ `t_version_nudge_when_behind`(源可達時 nudge)/ `t_nudge_skip_when_no_source`(F3:`_lumos_src` 不存在 → 靜默 skip、不 crash)。

## 設計定案補充(design-loop r3 加固)
架構層(進 TDD 前定案):
- **marker 常數單一源(F1/F2)**:sentinel 字串常數集中一處(名稱由實作定,計劃不硬指);START/END 兩個字串。**版本格式** = `vMAJOR.MINOR`(如 `v1.2`)。**find 用穩定前綴** `"<!-- LUMOS:GRAPH-DISCIPLINE:START"`(版本戳與後綴在其後,前綴 find 不受影響);re-inject 寫入時才把版本插值進 START 行(範本存無戳的前綴形式)。
- **`_extract_claude_block_span` 三態(F4,不可都回 None)**:回 `("found", BlockSpan)` / `("absent", None)`(無 sentinel→re-inject 走 appended)/ `("broken", None)`(半壞→re-inject 走 sentinel_broken;doctor 走「報漂移」分支、**不取 `.body` 避免 crash**)。三態分開,re-inject 與 doctor 各自 switch。
- **★INVARIANT★ 精確語意(F6)**:「sentinel 之外逐字保留」= 替換後,`text[:block_start]` 與 `text[block_end:]` 與原文**位元組完全相同**(含空白/換行);`t_reinject_preserves_outside` 斷言前後綴 byte-equal。created/appended 路徑無「之外內容」則真空成立。
- **doctor Check 字母(F7)**:用 **Check D**(Discipline-drift;若與現有字母撞,實作時順移,計劃不硬綁字母值)。
- **`--no-hooks`/無範本路徑(F8)**:`root/scripts/templates/graph-discipline.md` 不存在 → re-inject skip(status=`"no_template"`)、不 crash;doctor Check 已用「範本存在」guard,無範本不 check。

實作層細節(交付 TDD 紅綠釘,計劃不再散文摳——見下方「誠實天花板/design-loop 收斂判斷」):
- 5-status 各呼叫端印什麼、rc(F3);body strip 與 splice 位移一致性(F9);整合測試 `_lumos_src` 用 monkeypatch/env override(F10);nudge 是「CLAUDE.md 版本 vs 當前上游」兩號比對、與 vendored copy 版本可能三號不一(F5,honest note:nudge 是近似 advisory 非精確)。

## 誠實天花板 / design-loop 收斂判斷(r3 後)
- **loop 未過 gate(3 輪 caught 但 severity major→blocker→blocker、未 K-streak)**。原因不是設計有未解的**架構**洞——架構層(解耦注入/scaffold、ReInjectResult 三態、BlockSpan 單一源、版本=標籤非守衛、內容比對守衛、nudge 定位 dev-machine)已在 r1-r3 折穩;而是本 spec **glue 密集**(sentinel 字串處理、call-site 接線、版本插值),審計員每輪都能再挖出「這個字串/rstrip/status 沒精確到位元」的實作級細節。**這是文檔化的天花板(見 memory:design-loop-completeness-ceiling-shown:design-loop 對機械核心收斂強、對 shell/glue 散文空轉)**。
- **判斷**:架構已定案、殘留為 glue 實作細節 → 該由 **TDD 紅綠測試釘死**(每個 status、每個 sentinel 邊界、每個 strip 都寫真測試),而非續磨散文到 cap。續磨只會生更多「字串沒指定到位元」的 finding、不增架構信心。

## 落地回填
- Verification `plan_refs` 回指本節點;本節點 TEST/status。
- 更新 `Systems/lumos-cli-lifecycle`(F-10,附 KEY 草稿):
  - 改既有 KEY「graph-discipline.md 要重跑 init/update 才刷新」→ 標明**現已成真**且注入與 vault-scaffold 已解耦(re-inject 無條件跑、不受既有 vault skip 影響)。
  - 新增 `KEY:★INVARIANT★ re-inject 保留 sentinel 之外的 CLAUDE.md 內容逐字不動 [test:t_reinject_preserves_outside]`(F9 設計層裁定=**合約級**:違反 = 毀掉使用者手寫內容 = breaking;落地後綁 `[test:]` + 經 `[audit:]`)。
  - 新增 `KEY:★DEBT★ 版本戳=人可讀標籤/advisory nudge,非正確性守衛(內容比對才是)`(非合約,可改)。
