---
name: lumos-project-notes
description: 維護專案知識架構圖（docs/{project}-knowledge/）— 追蹤進行中/待辦工作、系統關聯、Issue、會話交接。當專案工作開始、結束、遇到 issue、或需要掌握現況時觸發。
---

# 專案知識架構圖系統（lumos）

## 一眼看懂

- **金科玉律**:所有改動/調研/計畫都**同一次工作內**同步進架構圖。查知識**優先讀架構圖**;與其他文件/記憶/臆測衝突以架構圖為準、向人確認。**但與行為事實(測試結果/實際執行/生產觀測)衝突時不自動判架構圖為真**——那是有東西壞了,查清哪邊錯並立事故節點(2026-07-29 外審吸收)。
- **主工具 = `lumos`**(python3 零依賴,`find_vault` 自動鎖定 `docs/*-knowledge/`)。**禁止**用 Grep/Read/Edit/Write 直接碰 vault 的 .md——繞過寫後自驗與鐵則防護。需讀節點**完整 body**(決策全文/章節內文)→ `lumos show <節點> [--body-only]`(2026-07-21 新增,補「context 只給 summary 索引」的全文讀取缺口);context 仍是進場導航首選。
- **進場三步**:`lumos search <關鍵字>` 定位 → `lumos context <節點>` 掃脈絡(頭部攤 ⚠ 合約) → `lumos contracts <節點>` 查硬合約。**然後**才 grep code / 查 DB 驗證。
- **★命中≠查完★**:search 只給索引——命中節點要 `lumos show` 讀**全文**才准下結論;拿摘要判「架構圖沒記」是實證過的破口(2026-08-14 金鑰事故:值在節點第 64 行,靠摘要判成沒有)。★「只是查個值/查個狀態」不是跳過架構圖的理由,是最該查的情境★;每個**子任務**進場都重新觸發架構圖先行,不是 session 開頭一次。
- **寫完一個節點**:`lumos lint <節點>`(單檔快檢) → 收尾 `lumos doctor`(全圖)。
- **push 後拉回 CI 結論（僅當專案 `.lumos/config.json` 宣告 `ci` 區塊時；未宣告＝此條不存在）**：`lumos ci-wait` → 綠且 `verdict=green` 才收工；**rc1（紅）＝當輪修**（讀它印的失敗步驟＋log 尾段 → 修 → 推 → 再等，上限 2 次，仍紅則寫 Issue 攤給人）；rc0 但 verdict 是 `timeout`/`no-run`/`unavailable`/`undetermined` **不算綠**（分別是：還沒跑完要手動查／此 sha 沒觸發任何 workflow／環境缺 gh／跑完了但結論既非成功也非失敗——`cancelled`·`action_required`·`stale`，要人判）。**紅燈不過夜**：修不完也要在收尾報告明講「main 上有紅燈未解」，不得靜默收工。⚠ **這是觀測不是強制**：`ci-wait` 擋不了 push、也擋不了 merge，工具缺席／config 壞損一律 fail-open rc0；要「紅燈進不了 main」得在 GitHub 設 branch protection required check（本工具不碰 GitHub 設定）。
- **rich 節點** = Write/Edit 內文 + `summary` block;**純量/list/decisions 一律走 `lumos set`/`append`/`decision-add`**(別手改 frontmatter)。

> ### ⤵ 何時去翻 `reference.md`（本 skill 目錄下,權威展開版 880 行）
> 本頭版給「做什麼 + 紀律」;**細節/模板/完整規格/邊角在 reference.md**。撞到下列情境**動手前先 `Read` 它對應段**,別只憑 176 行摘要硬幹:
>
> | 你正要做 | Read reference.md 的 |
> |---|---|
> | 綁合約 `[test:]`/`[audit:]`/`[kill:]`、跑 `lumos guard` scaffold/bind/kill、或不確定會不會**帶風向** | 「合約鏈深規 + guard 工作流 + 防帶風向鐵則」段 |
> | 寫**重大決策**要填 ADR 四欄、或某欄不知怎麼填 | 「decisions ADR 完整版」段 |
> | 建/改 Verification（`valid_under`/`revalidate_when`/雙向 `verified_by` 細節） | 「Verification 完整規格」段 |
> | 跑**自足性審計**要 prompt 模板 / 無主脈絡時的交叉審計變體 B | 「架構圖更新後審計」段 |
> | 查某 lumos 子命令的**完整旗標** | 「操作方式」段(或 `lumos <cmd> --help`) |
> | 需要 Obsidian GUI / 權威解析驗證 / File Recovery（少數場景） | 「Obsidian CLI」段 |
>
> **拿不準就 Read**——漏翻深規的代價 > 多讀一次的成本。

---

## Vault 偵測 / 初始化

```bash
ls -d docs/*-knowledge/Projects/ 2>/dev/null   # 已存在? 存在即 lumos doctor 確認鎖得到
lumos init                                       # 不存在 → 建 5 資料夾 + hooks(改 code 沒更圖被擋);--name 自訂 / --no-hooks 輕量
```
vault 名 = 資料夾 basename,lumos 自動解析。**全程無需 Obsidian**(僅 obsidian-only 功能才註冊,見 `reference.md`)。
> `lumos init` = 專案層(架構圖+該 repo hooks);`lumos bootstrap` = 機器層(clone/skills/全域 lumos,一輩子一次)。

## 核心架構圖接點(core-knowledge)

看到 frontmatter `core_refs:` 或 summary `CORE:` 行 → **該主題權威在核心架構圖,專案筆記殘留描述不可當權威**(疑似快照 = drift 該清);語意異動改核心節點(走 `lumos-core-knowledge` skill),不在專案筆記改。

## 跨 session 傳訊的形狀(2026-08-14 拍板)

本專案改動需要**他專案配合**時,可用 `ListAgents`/`SendMessage` 直接通知對造 session(實測互動視窗雙向可用、能喚醒閒置 peer,見 [[Verification/2026-08-14_跨session傳訊互動視窗實測]])。

> ★鐵則★ **訊息只傳「指標＋觸發」,不傳「內容本身」。**

理由:訊息內容只活在對造那個 session 的記憶裡,視窗一關即蒸發;把協同結論當訊息送過去就算數 = 在架構圖之外長出第二個沒人維護的真相源。

三步形狀:①先把改動寫進架構圖(跨專案規則走核心架構圖升格) ②訊息只說「我動了哪一條/去讀哪個節點/你那邊要跟什麼」 ③明確要求對造把跟進結果也寫回它自己的架構圖。

⛔ **禁止**:拿傳訊當「問規則的捷徑」(規則權威在架構圖,不在誰的 session 記憶)、拿 peer session 當審計獨立席次(脈絡髒於全新子代理且更貴)、以及**把本 session 被閘擋下的動作轉請 peer 執行**(權限洗白;同機確實存在跳權限確認的 session,此條純自律無機械守衛)。
> ⚠ 本節目前**沒有任何機械檢查**在守——對造沒把跟進寫回架構圖,工具不會知道。

---

## 常用指令(速查;完整旗標見 `reference.md` 或 `lumos --help`)

**讀 / 巡檢**
| 要做的事 | 指令 |
|---|---|
| 進場掃脈絡(頭部突顯 ⚠ 合約 + valid_under 過期標紅) | `lumos context <節點> [--brief]` |
| 全文搜尋(預設 BM25F 相關性排序) | `lumos search <詞> [--path Systems] [--top N]` |
| 條件篩選(標籤欄位 WHERE) | `lumos query --tag 家族/值 [--active] [--contract] [--linked 節點]` |
| 動模組前查硬合約 | `lumos contracts [節點]` |
| 健康巡檢(orphans/verified_by 同步/合約綁定/鐵則 lint…) | `lumos doctor [--ci]` |
| 單檔快檢(寫完立刻自驗,比 doctor 快) | `lumos lint <節點>` |
| 測試層軟提醒(diff 命中宣告棧→提醒該跑的測試層,恆 rc0) | `lumos test-layers --diff <range> [--json]` |
| lint 宣告健康檢查(格式校驗+--smoke 真跑抓「宣告了跑不動」) | `lumos lint-check [--repo R] [--smoke]` |
| 反查連入/連出 | `lumos backlinks <節點>` / `links` |
| 讀決策 / 掃被推翻 | `lumos decisions <節點>` / `--superseded` |
| 該重驗哪幾篇 / stale 清單 / 最近異動 | `lumos stale [--candidate --match ..]` / `recent --days 7` |
| 條款級追溯([SN] 誰認領) | `lumos spec-trace <計劃節點>` |
| 治理事件帳(被哪幾道閘攔過) | `lumos gov [<節點>] [--since N]` |

**寫入**(一律 tmp→自驗→atomic rename;BOM/CRLF 拒寫)
| 操作 | 指令 |
|---|---|
| 改純量 status/updated/type | `lumos set <note> <key> <value>`(日期 bare 不加引號) |
| list 追加 verified_by/related/tags | `lumos append <note> <key> "[[x]]"`(安全格式+dedup) |
| 依模板建檔 | `lumos new <type> <name>` |
| 新增/翻盤決策(巢狀,非 ruamel) | `lumos decision-add` / `decision-supersede` |
| rename/移檔(連結改寫) | `scripts/graph-rename.sh <舊> <新>` |
| 歸檔老 Verification | `lumos archive [--days N] [--apply]` |

> ⛔ **禁用 `notesmd-cli` 的 `frontmatter --edit`**(只准 `move`):實測會把整篇 frontmatter 鍵序重排字母序、縮排 2→4、**日期加引號(date→text 靜默損傷)**——一碰整篇 diff 不可審、pre-commit 擋。frontmatter 合法寫入只有 lumos T1 + obsidian `processFrontMatter`。
> body 段落/checkbox/表格 → 用 **Edit**(非 lumos T1 範圍);版本歷史 → git。
> 對抗審計 loop(`pitfalls`/`canary`/`loop`/`code-loop`/`refcheck`/`impact`/`cochange`/`fold-check` 等)→ 見 `lumos-design-loop`、`lumos-code-loop` skill。

---

## Frontmatter 鐵則(違反 = 長 ghost 節點或整篇 frontmatter 報廢)

血換來的四條,**不可犯**:

1. **多 wikilink 必須是 YAML list,一項一行**。❌ `verified_by: "[[A]], [[B]]"`(單字串)→ 貪婪吃成一個超長連結 → ghost 節點 + 垃圾檔。✅ list 一項一連結。
2. **block scalar(`summary: |`)內的 wikilink 不被索引**。summary 裡的 `[[X]]` 只是文字;要建關聯必須同時在內文或 list 型 property 放一份。
3. **含 `: `(冒號+空格)的長文必須 block scalar 或引號**。❌ `- content: 處置 SQL: UPDATE`(未引號)→ 整篇 frontmatter 解析失敗、所有 property 隱性失效。✅ `- content: |-` 換行縮排。
4. **同層禁重複鍵**。`decided:`/`valid:` 出現兩次 → Obsidian js-yaml 整篇 fail(CLI ruby 寬鬆放行,**CLI 過不代表 Obsidian 讀得到**)。

> 純量/list/decisions 走 lumos T1 天生避開這些雷;手改 frontmatter 才要盯。巡檢偵測指令見 `reference.md`。

---

## 標籤家族(2026-08-05 收編定版;值域 lint 自 2026-08-06 硬擋新節點,舊帳不回溯)

| 家族 | 值域 | 語意/消費者 |
|---|---|---|
| `type/` `status/` | enum(status 依 type:system=doing/done/planned/deferred/rejected/superseded/stale;project=todo/doing/done/superseded;issue=open/doing/resolved/done/wontfix;verification=**pass**;moc=doing/done) | 生命週期;lint 硬擋野值 |
| `priority/` | **P0-P3** | 處理優先級(P0 最急),主用 Issues |
| `scope/` | 自由 kebab 值(pointsmall/concurrency…) | 業務域切片;★feature/ 與 area/ 已凍結,新寫入一律 scope/(讀側仍認舊帳)★ |
| `risk/` | **金流/對外送出/不可逆/守衛面** | Systems 專用;消費者=impact ★固定席★(RISK·值 保送必看)+design-loop light 硬否決 |
| `flag/` | 小寫語意標;已知有效:do-not-modify/security-relevant/depends-on-claude-code-internals/depends-on-obsidian-internals | 節點級警示,AI 讀 |

- **這些是寫給 AI 看的**(2026-08-05 Enzo 定調):context 頭部自動攤出 type/status 以外全部家族——寫了就會被進場讀到,不用重複進 summary。
- summary 的 `FLAG:` 行=語意類別,只收 TECHNICAL/DECISION/ORIGIN 三值(敘述內容放 KEY: 行);與 `flag/` tag 家族是兩回事。

## summary block(Systems/Issues 必有;掃一眼掌握全貌)

每行一個前綴。Systems 重 `FLOW`+`KEY`+`DEP`+`TEST`;Issues 重 `FLAG`+`DECISION`+`KEY`;Verification 重 `TEST`+`VERIFY`。

| 前綴 | 用途 | 前綴 | 用途 |
|---|---|---|---|
| `FLOW:` | 核心流程 `a→b→c` | `VERIFY:` | 驗證紀錄 `[[..]]` |
| `KEY:` | 關鍵概念/欄位 | `DECISION:` | 決策簡版 `[日期]內容(valid)` |
| `DEP:` | 依賴模組 `[[..]]` | `FLAG:` | 語意標記 TECHNICAL/DECISION/ORIGIN |
| `TEST:` | 測試狀態 | `AUTH:` | 認證方式 |

分隔:`→` 流程方向、`｜` 分隔同類、`,` 分隔同欄。

### ★已結案的 Issue:body 開頭必須有結案橫幅★(2026-08-13 立,血換的)

`status: done/resolved` 的 Issue 節點,**body 第一段就要寫「已結案 + 一句修法 + 一句實證」**,
並標明「以下症狀/根因是當時的排查紀錄,不是現況」。

**為什麼不能只靠 frontmatter**:`status` 與 summary 的 `FLAG:✅已結案` 只在
`search`/`context` 看得到;**`lumos show --body-only` 刻意剝掉 frontmatter 與 summary**,
從 body 讀的人完全看不到結案訊息——長節點尤其危險(排查紀錄動輒上百行,
修法與驗證埋在後半)。

★實際事故(2026-08-13)★:`Issues/註冊來源空白_storeCode模組層凍結`(body 220 行)
兩層結案標記都在(`status: done` + `FLAG:✅已結案`),但讀者跑
`show --body-only | head -45` 只看到「症狀:34.7% 註冊來源為 NULL、7/16 起每天發生」,
**把兩週前就修好並驗證過的問題當成正在發生**,並據此對使用者做出錯誤的資料判讀。
修法(A/B 對照實證)與結案結論全在第 130 行之後。

橫幅最小內容:

```markdown
# <標題>

> ## ✅ 已結案（<日期>）— <修法一句話>
>
> <修法做了什麼>。**<實證形式>**：<關鍵對照數據>。
> 詳見下方〈X〉〈Y〉節。
>
> ⚠ <殘留限制/仍需知道的事,若有>
>
> ★以下「症狀 / 根因」是**當時的排查紀錄**,不是現況。★
```

⚠ **這是第二道保險,不是主要解法**。主要解法是**進場走 `search → context`**,
別拿 `show --body-only` 當「快速看一下」——那個旗標的用途是讀全文,且**不要截斷**。

---

## 合約性標記(合約 vs 偶然;最重要,動筆前掃一眼)

Systems 記的是「現在長怎樣」,分不出哪些是**合約**(改=breaking)哪些是**偶然**(可改)。用 KEY 行前綴聲明:

```
KEY:★INVARIANT★ <業務合約,改=breaking> [test:測試名] [audit:模型/日期] [kill:recipes]
KEY:★DEBT★ <已知偶然行為,可改不算 breaking>
```
- **未標 = 未聲明**;**不確定就不標**(寧漏勿錯)。**嚴禁從現況 code 反推「應該是合約吧」**——把偶然合約化會鎖死重構,比沒標更毒。只有業務語意明確或 decisions[] 載明意圖才配 ★INVARIANT★。
- 跨專案級不變量不在這標 → 走 `lumos-core-knowledge` 升格,KEY 留 `CORE:` 指針。

**合約鏈(行尾指針,遞增嚴格;深度規格見 `reference.md`)**:
- `[test:方法名]` — 綁一個真實測試(doctor Check T 強制,裸合約擋)。**綁定走指令**:`lumos guard bind <node> "<KEY子字串>" <測試名>`。
- `[audit:模型/日期]` — 綁測試後,合法性須經**無脈絡獨立 agent** 審過(prompt 中立「試圖反駁」,不帶風向;**判準=五問 rubric 逐條打勾,五項全過才 legal**——意圖證據/合約vs偶然/測試夠格/可證偽/爆炸半徑,含穩定性探針與防應試化兩道,完整規格見 reference.md〈[audit:] 獨立合法性審計〉段)。`lumos guard audit <node> "<KEY子字串>"`。
- `[kill:recipes]`(選配,金流建議)— 沙盒真弄壞、綁定測試必翻紅。`lumos guard kill-add` / `kill`。
- **綁 `[test:]` 前對照 [[Systems/測試假綠形態]] 八型清單**——綁上去的測試若中了其中一型,合約鏈看起來完整、實際什麼都沒守住(★最隱蔽的是「現場走不到被測分支」★:把修法還原回去測試照樣全綠)。修 bug 的翻紅釘★必須配一條「現場成立」前置斷言★。
- **天花板**:[test:] 只買 verification;「這規則現在還符不符合真實業務」是 validation,要對業務現實的人確認(`lumos signoff`)。

**可逆性(危險動作動手前先寫好收回,僅 Systems)**:
```
KEY:★IRREVERSIBLE★ <收不回:上架/prod遷移> [rollback:decisions]   # 必綁,否則 doctor Check R 擋
KEY:★CHECKPOINT★   <改了難救>                                     # 建議補 [rollback:],缺=提醒不擋
```
外部不可逆(信已送/下游已消費)→ 改用 `[guard:decisions]`(事前冪等鍵/核可閘)。`[rollback:]` 證「有寫 undo」≠「驗過能跑」。

**重生標記(from-scratch 重建的節點必蓋,Check J 守衛)**:
- **何時**:目擊記錄佚失/接手無人 legacy/整篇重寫——由 AI 看 code「重建」筆記時(≠平常 incremental 更新)。重建=逆向工程,可能編出自信的假 why/假合約,故課更嚴檢查。
- **蓋章**:`lumos set <節點> regen from-scratch/<日期>`(不蓋=Check J 不看;蓋了才守)。
- **summary 每條 claim 標身分**(四選一):`[src:路徑(:行號)]` code 作證(Tier A)/`[git:sha]` 提交作證(Tier B)/`推測:` 前綴=沒證據的猜(接在 KEY:/DECISION: 後)/`佚失:` 前綴=查不到,不編。
- **Check J 擋什麼**(lint/doctor 自動):★INVARIANT★ 無 [src:]/[git:] 意圖證據→擋(拒發明合約);DECISION 裸寫→擋;證據指針假的(檔案不存在/行號越界/git 查無)→擋;`推測:` 行承載 ★合約→擋。無標記 KEY 行只提醒不擋。
- **升級**:查證後補 [src:]/[git:] 或走 `lumos signoff`;**佚失的 why 正確輸出是「佚失:」,嚴禁編一個合理的**。深規見 `reference.md`〈重生守衛〉段。

---

## 決策(ADR)· 驗證 · 雙向同步(要點;完整見 `reference.md`)

- **重大決策**(架構/技術/流程/安全選型)`decisions[]` 必填四欄:`context`/`alternatives_considered`(≥2)/`why_chosen`/`trade_offs`——**缺資訊就問人,不可編造**污染學習資產。翻盤:舊條 `valid:false`+`superseded_by`+`ended`,新條重填完整四欄。
- **Verification** 必填 `valid_under`(有效條件:版本/規模/schema)+ `revalidate_when`(重驗觸發)。建 Verification **同步**把 wikilink 加進相關 Systems 的 `verified_by`(雙向,缺一不可;漏寫 `lumos sync-verified-by --apply` 補)。
- **plan_refs**:落地某計劃的 Verification(含後續迭代)填 `plan_refs` 反指計劃節點(意圖鏈,doctor Check 4 把關)。
- **計劃/設計一律寫架構圖計劃節點**(`Projects/<主題>_計劃`,`type:project`),**不寫 `docs/superpowers/specs/`、`openspec/` 等 repo 路徑**——覆寫任何 SDD 工具的預設落點。

---

## 自足性審計(架構圖實質更新後必做)

派**乾淨 sonnet agent 只讀架構圖**還原脈絡 → 主對話比對「還原結果 vs 腦中現存脈絡」:有出入 = 架構圖當下不健全,補缺後**重審到一致**。純格式修正可豁免。審過留痕:`lumos self-audit <node>`(doctor Check S 軟提醒未審/過期)。
> 無主對話脈絡時(定期巡檢/接手陌生專案)→ 改用「架構圖×程式碼交叉審計」(以 code 為真值),做法見 `reference.md`。
> 對抗**設計稿**審計(乾淨 agent 逐輪找洞+引句錨定收貨)→ 走 `lumos-design-loop` skill,不在此。

---

## 常見工作流

```bash
# 開工:掌握現況
lumos query --tag status/doing; lumos recent --days 7; lumos context Systems/<模組>

# 改完 code:更新架構圖
lumos set Systems/<模組> updated <日期>
lumos append Systems/<模組> verified_by "[[Verification/<日期>_xxx]]"
# body 進度/表格 → Edit;寫完 → lumos lint <節點>

# 環境變動後:掃該重驗的
lumos stale --match "<變更關鍵字>"
```

## 退場自問（code 有「拿掉/反轉」的改動時，收工前跑一遍）

1. 這次改動**拿掉或反轉**了什麼？（函式/呼叫點/欄位/條件/預設值——過期幾乎都來自拿掉，不是新增）
2. 把那些名字逐個丟 `lumos search <名> --code`（--code 必帶：search 預設排除 code block；另注意預設排除 superseded）。哪些節點內文在講它們？貼原句。
3. 逐句判：改動後這句還成立嗎？成立→一句話為什麼；不成立→**現在改掉或標作廢**。
4. **這次有動到使用者看得到的畫面嗎？**（Android／web UI 都算）
   有 → 除了單元測試，補一支**可重放的 UI flow 檔**（Android＝maestro `.maestro/*.yaml`），
   並用 `[test:<平台>:<flow名>]` 綁回該功能的架構圖節點。
   ★斷言必須含「畫面上出現什麼字」★——只斷言「有沒有被擋」等於白做（實例：折扣超過 100%
   確實被擋，但畫面顯示的是登入頁的「請輸入員工編號!」，單元測試結構上測不到）。
   寫法與七個坑見 `reference.md` 的〈產 maestro UI flow 的派工要求〉。
   ★綁定前置★：`guard bind`／Check T **只認 `KEY:★INVARIANT★` 行**——該節點沒有合約行就
   **別為了綁而標**（鐵則：不確定是不是合約就不標）；先只寫 flow 檔、在節點內文記一句指向它。
   沒裝置／起不了環境 → **明記「未驗＋原因」**，不得靜默跳過。
⚠ 新增一條 verified_by/related 連結**不算同步**。有裝 delguard（pre-commit Gate DG）的 repo，S1 命中時會機械吐**上面 1-3 這三問**（delguard 不管 UI，第 4 問純靠自律）；沒裝的 repo 四問全靠這段自律。

## 資料夾 / 位置

`docs/{slug}-knowledge/{Projects,Systems,Issues,Verification,MOC}`(隨 git 版控)。某主題筆記 >5 份 → 建/更新 MOC 索引。
