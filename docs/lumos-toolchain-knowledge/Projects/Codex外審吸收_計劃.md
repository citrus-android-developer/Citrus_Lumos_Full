---
type: project
status: done
created: 2026-07-29
updated: 2026-07-30
tags:
  - type/project
  - status/done
related:
  - "[[Projects/上下文瘦身_計劃]]"
  - "[[Projects/GPT外部評審吸收_計劃]]"
summary: |-
  FLAG:DECISION
  KEY:2026-07-29 Codex(gpt-5.6 high)全項目外審(總分 5.2/10;全文存 session scratchpad):三大風險=假確信(形式合規≠語意正確)/治理熵超過維護力/強制力只在本機——P0 已落地,P1/P2 列帳待辦
  KEY:★P0 已落地★——①GitHub Actions CI 信任根(.github/workflows/ci.yml:compileall+SyntaxWarning 閘+全套 1588+doctor --ci+anchor verify 缺 baseline 必紅)②pre-push「CI 仍會抓」假話改為指名 Actions 的真話③外審實錘壞節點修復(heterogeneous-finder-ensemble d1 id 吞進 content)+lint decisions 結構守衛(正牌 parse_decisions 驗:空 content/條數對不上)④文件漂移批次(ONBOARDING 一鍵化/ARCHITECTURE+README.en 44→49/Obsidian 誠實註記/anchor 定性=改動偵測非信任根/方法論上手時間分層)⑤SyntaxWarning 歸零(3 處 docstring 轉 raw)⑥命令數漂移守衛測試(t_docs_command_count,首跑即抓到 README.en 漏網)
  KEY:待辦 backlog(依價值序)——①合約普查(星標 INVARIANT 密度慘案:172 篇僅 2 條掛最強鏈;嚴禁 code 反推,按業務語意逐一判)②cluster 帳設為 panel 預設(capture-recapture 降 advisory 已在 cluster 模式,預設化即回應「統計儀式」批評)③測試 hermetic 化(碰真 ~/.claude 的測試改 temp HOME;Windows 分支無條件 pass 清除)④同名節點 resolver 載重操作 fail-closed⑤supply-chain:get.sh pin+fetch-notesmd SHA 驗證⑥branch protection required checks+PR auto-merge(GitHub 設定面,人做;合體版=紅燈進不了 main 又免手動合併)⑦**guard kill 排程化**(2026-07-29 使用者採納:合約「牙齒檢查」目前是手動按需跑,前四道關卡[Check T 綁定/[audit:]/pre-push 全套/CI 複核]只驗形式與綠燈,唯有 kill 證明測試真咬得住 → 排進每日治理腳本定期自動跑,讓三層[有測試/測試會跑/測試有牙]全閉環;成本考量:kill 要真弄壞跑一輪,排程時段與範圍[全部合約 vs 抽樣]待設計)
  DECISION:[2026-07-29]緩辦不採清單——單檔拆模組(P1):方向對但大手術,anchor/測試/vendor 全連動,單人維護期回報<風險,等第二維護者;tier 三檔收斂兩檔:與 d4「前置加重一律拒」同源但需 replay 數據支撐再裁;autonomous loop 非 dry-run 停用:2026-07-29 使用者已裁**停用**(--pr 硬閘 exit 2+scratch 改 mktemp;解禁=隔離落地過 code-loop;決策記於 nested-agent-permission-scope)
---
# Codex 外審吸收（2026-07-29）

`PRIOR-ART:` 外審本身即先例掃描——評審對照 ADR/Spec Kit/OpenSpec/coverage gate 界定差異化：「整合與治理生命週期是真差異，基礎方法論非發明」（與我方對外論述一致）；其批評「衝突時架構圖為準」應限縮為**意圖權威**、行為事實衝突該進 incident——此認識論修正值得吸入方法論文（待辦⑦）。

## 外審要點與裁決

| 外審批評 | 裁決 | 依據 |
|---|---|---|
| 無 CI 信任根＋hook 謊稱「CI 仍會抓」 | **採，P0 已落地** | 實錘：repo 無 workflows；謊言句 3 處已改真話 |
| 壞 YAML 逃過 doctor（d1 吞進 content） | **採，已修＋守衛** | 實錘；lint 新守衛用正牌 parser 驗空 content/條數 |
| 文件漂移（44 指令/兩步安裝/Obsidian 宣稱） | **採，已修＋機械守衛** | t_docs_command_count 首跑抓到 README.en 漏網＝守衛有效性自證 |
| anchor 非信任根應稱改動偵測 | **採，定性已改** | 同 repo 自簽悖論架構圖本有記載 |
| 合約密度 2/172 | **採，列 backlog①** | 最強鏈幾乎空載屬實 |
| capture-recapture＝統計儀式 | **半採** | 批評與架構圖自記天花板一致；但漏看 cluster 帳已降 advisory——待辦＝預設化，非砍除 |
| canary 有自嗨成分 | **不另動** | d4 定位（抬質量非保正確）＋誠實天花板已同款；其建議與現行定位一致 |
| 單檔拆模組 | **緩** | 見 DECISION |
| 一小時上手不可信 | **採，已改分層敘述** | |
| autonomous confused-deputy 未修仍可跑 | **採，已停用** | 使用者 2026-07-29 裁定；--pr 硬閘拒跑、dry-run 照常 |

## 驗證

- P0 全套：本機 1588 checks 全綠＋乾淨 HOME 預演全綠（CI 可行性驗證）＋doctor 0 issues。
- CI 首跑實錄：run#1 **紅**——當場抓到 `t_impact_incidents_smoke` 硬編 `/Users/enzo/...` 絕對路徑（外審 hermetic 批評第一天就兌現價值）；改 `__file__` 相對後 run#2 **綠**（3m15s 全套 1588＋doctor --ci＋anchor verify）。信任根已活。
- **對話輪收官（2026-07-29，三輪互審）**：總分 5.2→**6.4**（方法論 7.5/治理 7.5/架構 6.0/可用性 5.5/安全 5.5）。全程五份文件歸檔 `governance/external-reviews/`。對話戰果：①它改口四處（canary 鑑別力/負結果文化/可移植性基準/拆檔時點——皆因實證）②我方採納其「第一刀」三步與 guard-kill 升準殺全案③**它反查出真事故**：code-testmap r2 三筆 canary record 回報成功未落盤（[[Issues/canary-record未落盤事件]]），11 中 10 降級為 8 原生+3 補記④終稿仍明標分歧：「架構圖為準」正文未改不給預支分、dry-run 寫權未隔離、required check 未設。⑤路線圖重排：P1-0 部署最後一哩/P1-1 oracle 品質包（record 落盤自驗+canary 第二判者抽查+guard-kill 歸因）/P1-2 砍統計儀式/P1-3 合約普查——與我方 backlog 合流，oracle 品質升為最高投資序。終稿結語可當北極星：「讓每一盞綠燈都能回答：證據真的落盤了嗎？紅燈真的是那條規則咬住的嗎？」

## Round3 重審（2026-07-29 晚，基準 b75266c；全文 `governance/external-reviews/2026-07-29-codex-round3-recheck.md`）

**總分 6.4 → 6.4（不動）**。唯一上升＝治理機制 7.5→**7.7**（append-readback／timed_out 弱化／全弱 rc1／還原翻紅釘／CI 當輪回流／INVARIANT 2→6）；架構 6.0→**5.9**、安全 5.5→**5.4**（新增 489 行 god module＋一個「看起來像強制、實際 fail-open」的回路）。

**它實查後點名我方自報不實五處，我逐條複驗＝全中（非誤報）**：

| 自報 | 實況 | 佐證 |
|---|---|---|
| 「紅則吐失敗步驟＋log 尾段」 | 只進 `--json`；**預設文字 emitter 不印**，人跑指令看不到任何失敗證據 | `scripts/lumos` `cmd_ci_wait.emit()` |
| 「cwd 漂移/錯 vault/不可寫路徑回歸測試」 | `t_canary_record_persist` 只有「正常落盤」＋「symlink /dev/null 必失敗」兩例 | `scripts/test_lumos.py` |
| 「第二判者＝分權成立」 | telemetry-only、不影響閘、auditor 是自由字串（換個名字即過）、**帳上零筆 second、抽樣目錄只有 README** | `cmd_canary_second` |
| 「guard-kill 輸出 assertion 與行為歸因」 | 文字鄰接啟發法；且 `attr_excerpt` **不寫進 kill ledger、預設輸出也不印** | `_kill_attribute` |
| 「hook 三方 ⟺ 已守衛」 | 斷言實為**單向** `registered ⊆ copied`；「複製了沒註冊」的幽靈 hook 照樣過 | `t_docs_enumeration_drift` ③ |

**另抓三個真缺陷（已複驗）**：
1. **CI 假綠**——只認 `failure/timed_out/startup_failure` 為紅，`cancelled`／`action_required` 完成即判 green（計劃節點自列的 conclusion 矩陣未實作完）。
2. **指令數三版本並存**——`AGENTS.md` 44／`reference.md` 49／實際 51；`t_docs_command_count` 只掃 README/README.en/ARCHITECTURE，守衛面沒覆蓋到。
3. **架構圖自己是舊的**——`Systems/guard-kill.md` 仍寫「六態／timed_out 歸 killed／全 killed 含 timed_out=rc0」，與現碼七態相反；昨日只同步 skill reference，守衛也只驗 reference。

**★最毒的一擊（認識論）★**：本輪由我方親手製造出「架構圖錯、code 對」的活例——照 CLAUDE.md「衝突以架構圖為準」，正確的新程式會被判成錯。外審兩輪都指此條該限縮為**意圖權威**（行為事實歸測試/執行/生產觀測，衝突立 incident）；正文仍未改（`CLAUDE.md`／`README.md`／project-notes skill 三處），本輪不給分且被當反證。

**正名建議（採納傾向）**：「CI 回流**閉環**」→「CI 回流**觀測**」——它擋不了 push/merge/direct-main，沒有 required check 就不是強制面；續稱閉環會製造「反正 agent 會修」的道德風險。

**6.4 上限理由收窄（非撤銷）**：舊理由「完全缺乏寫後驗證」已修正；新理由＝「寫後可見性已補，但證據帳的**持久性／唯一性／身份／並發／不可竄改**仍未成立」（無 fsync/鎖、不比對讀回的是否為本筆、選錯合法 vault 仍成功、TOCTOU/inode 替換無防、事故根因至今未證）。

## backlog 追加（2026-07-30 治理日報引入，非 Codex 外審項）

來源：`governance/reports/governance-2026-07-30.json`。三個缺口中一個當日已做（見 [[Systems/canary-audit]]），另兩個列此待排：

- **⑧ 判官分帳＋校準卡**（來源：arXiv 2607.08535，Zongyou Yang 等，2026-07-09）：實測「答案不動、只換打分的 AI，分數就移動」，且**當判官錯的地方相同時，多數決幾乎無效**。對應到本專案：canary 帳與對抗層增量帳目前**跨判官混記**，換模型等於換量尺、趨勢不可比。建議 ①帳按判官模型分開算趨勢 ②換判官前先跑一小組已知答案的校準題 ③剛 ship 的第二判者「我同意」要附**錯誤相關性估計**（分歧率太低＝兩把一樣的尺互相蓋章，那聲同意只能算同門背書、不能當獨立證據）。
- **⑨ 長期腐化回測（三週 vs 九週）**（來源：arXiv 2607.21962，Quentin Spencer，2026-07-24）：作者給每個事實設有效期間再生成文本，於是能同時量短期與長期——**排名反轉**：人工摘要式記憶三週領先、九週由 96% 掉到 72%；**帶出處指針的架構圖式記憶反升到 90%**。另發現**寫入當下的品質是下游對錯的最大單一因素**（失敗率 24% vs 2%）。對應：本專案的檢索與記憶評測都是單一時點打分，看不到「用久了才腐」。建議拿 repo 真歷史做三週對九週回測，看壓實過的 summary 會不會開始答不出來；並在壓實規則裡**硬性保留出處指針**。註：lumos 同時做了會贏的那半（帶出處的架構圖）與會腐的那半（壓實摘要），不分開量就不知道哪半在起作用。

### ⑨ 第一道探針結果（2026-07-30，純機械、無 agent）

**問題**：論文說「壓實摘要式記憶用久了會腐」。本專案的 summary block 就是那個壓實層——它真的在腐嗎？

**做法**：對每個節點逐 commit 取出 frontmatter 的 summary 行，比對前後版，找「曾出現、後來不見」的行。
**方法論修正（自己抓到的）**：初版用字串完全相等比對，把「原地改一個字」誤算成「被移除」——
`lumos-cli-read` 的 `doctor 是全圖權威巡檢` 一行被改了 7 次，就貢獻 7 筆假移除。
改用相似度（difflib ratio < 0.6 才算真消失）後數字才可信。

**數字**：
- 全圖（179 篇 / 683 次改寫）：表面移除 197 → **真消失 56（28%）**
- 但真消失集中在**計劃節點**（`TEST:未開工`→`TEST:T1 DONE`、方案 C→方案 C'）＝活文件的正常演進，不是腐化
- **只看 `Systems/`（38 篇耐久知識）：表面移除 74 → 真消失 6（8%）**

**抽驗（2/6 逐條查證）**：
- `lumos-cli-read` 的「Check T 無 Python profile」缺口行消失 → **因為缺口被補了**（現行 summary 寫
  「[缺口已補 2026-07-25]」，`.lumos/config.json` 確有 `test_profile: python`），且附了根因更正。
- 同節點「真遺忘核心行為」行消失 → **升格**成帶 `[test:]`＋`[audit:]` 的正式 ★INVARIANT★ 行，沒丟。

**初步結論（負面結果，對我們有利）**：耐久知識層的 summary **沒有觀察到靜默腐化**；抽驗到的移除都是
「事實不再為真」的正當汰換。餘 4 例未逐條查證。

**★這道探針看不到的（最重要的誠實）★**：它只量**刪除**。論文真正的失效模式是
「**行還在，但壓實到答不出問題**」——摘要沒少一行，可是細節被壓掉了。那要靠答題實驗才量得到，
本探針對它**零覆蓋**。
