---
type: project
status: doing
created: 2026-07-16
updated: 2026-07-16
tags:
  - type/project
  - status/doing
related:
  - "[[Systems/外部對照-code衍生wiki]]"
  - "[[Systems/canary-audit]]"
  - "[[Systems/design-loop]]"
  - "[[Systems/cochange-guard]]"
  - "[[Projects/decision_refs自動養成_實作計畫]]"
summary: |-
  FLAG:DECISION
  KEY:問題=lumos 唯一塌陷回 openwiki 失效模式的點——from-scratch 重生節點時失去目擊者(primary source)、被迫從 lossy 投影(code 快照)逆向工程 why=synthesis bias;只有 [test:] 合約子集有 oracle 接得住,非合約 prose 裸奔。詳見 [[Systems/外部對照-code衍生wiki]]〈重生塌陷例外〉
  KEY:統一原則=讓 from-scratch 優雅退化成「誠實的、分級的不確定」,不編自信 prose。openwiki 原罪=看不見地填滿每個缺口;lumos 反過來=把缺口變可見+有型別。標「不知道為何是 invariant」勝過捏似是而非的 why(擋假信心+指出人力該花處)
  KEY:裁定=解法不在「生成更好 prose」(那就是 openwiki);只能走三路——找回 provenance / 標出不確定 / 給重建套 oracle。且大半=組合現有機械(不對稱雙欄信任 from decision_refs + cochange git 挖掘 + design-loop 對抗審 + signoff),非造新輪子
  DECISION:MVP 只挑最硬核兩條(provenance 分級隔離 + 拒絕發明無證據合約),其餘(git-rationale 收割/訪談路由)留後續里程碑——避免又一個大機械堆小需求(記取 [[Projects/decision_refs自動養成_實作計畫]] T3 凍結教訓)
  KEY:M1 spec v4(design-loop r1-r3 折入):regen 宣告(SCALAR_KEYS 擴)+四指針只掃 summary+Check J(原G撞名改)+共用 check_regen_provenance(errs,warns,gov_events) 兩入口映射表釘死(warns 兩側皆非阻擋/落帳僅 doctor --ci)+_validate_repo_ref 防 top_dirs 靜默放行+推測合約 raw 行獨立偵測+雙報消歧 predicate;r1 canary 2/3(存活 blocker 範圍矛盾已修)、r2 canary 3/3 首有效輪(存活 max=major 接線兩條已修)
  DEP:[[Systems/外部對照-code衍生wiki]]｜[[Systems/design-loop]]｜[[Systems/cochange-guard]]
plan_refs:
  - "[[Systems/外部對照-code衍生wiki]]"
---
# from-scratch重生守衛_計劃

> **狀態**：設計 ideation 收成節點，**尚未過 design-loop**（進實作前需過；碰寫入路徑 + AI 派工 + 靜默填 prose 風險，建議 `--need 3`）。緣起見 [[Systems/外部對照-code衍生wiki]] 對話 co-develop。

## 問題（緣起）

lumos 相對 openwiki 的核心優勢是 **provenance**——決策當下第一手目擊記錄，非事後從 code 逆向工程。但這優勢有**唯一破口**：當一個節點必須 **from-scratch 重生**（目擊記錄佚失/從未存在、或 stale 到需整篇重寫、或接手無人 legacy repo），lumos 那一刻也變成 reconstructor，非合約 prose 吃到 openwiki 同款 synthesis bias，且**只有綁 `[test:]` 的 ★INVARIANT★ 合約子集有 oracle 接得住**，其餘 prose 裸奔。

**openwiki 失效是常態（每輪重生無 oracle）；lumos 同款失效是例外（僅 from-scratch 非合約 prose）**——本計劃＝把該例外壓到最小。

## PRIOR-ART（2026-07-16 真搜補正——初版憑印象，違規已修）

`PRIOR-ART:` ① 最小解在**組合既有閘層**（不對稱雙欄信任、refcheck 指涉驗證、cochange git 挖掘、design-loop 對抗審、signoff 皆已有）→ borrow-design 自家機制小修，非 build。② 世界解真搜（GitHub+文獻）：
- **repowise**（repowise-dev/repowise，3.6k★，2026-03，Python）——**最接近的先行者**：architectural decisions 從 8 源挖掘（ADR/CHANGELOG/PR body/inline 標記/git 考古/README/code comment/LLM pass），每條 rationale 必須追溯到**逐字 source span**，**anti-hallucination substring gate** 機械蓋章 **verified / fuzzy / unverified** 三級；corroborating 源疊加升級（不覆寫）；`decision confirm` 人審自動提案（同 lumos promote 型態）；`get_why` 無 ADR 退 git 考古（＝本計劃 M3）。差異：repowise 是重建器（與 openwiki 同族但**有證據閘**），lumos M1 是守重生路徑；家規零依賴排除 adopt。
- **PaperTrail**（CHI 2026）/eTracer/ClaimVer——claim 級 provenance 學術系：輸出拆原子 claim→逐條配證據→顯式映射；PaperTrail 三分類 **supported / unsupported / omitted**（第三類「來源有但生成漏了」＝完整性軸，M1 原設計沒有）。
- **Abstention 文獻**（Don't Hallucinate, Abstain ACL 2024；Know Your Limits survey；Abstain-R1）——「證據不足就 abstain」已是正式設計原則非 ad-hoc；實證：主流 LLM 對 unanswerable 問題普遍不會自發棄答→**abstain 必須外部機械強制,不能靠模型自覺**（M1 lint 硬閘的理據）。
- **Swimm/Mintlify**——stale 偵測商用解（僅 recency 軸，無 provenance 分級，佐證 openwiki 對照結論）。
③ 裁定＝**borrow-design**：借 repowise 的 **substring gate（逐字 span 存在＝機械可驗,lumos 用 refcheck 族原語原生實作）** + 三級信心疊加語意 + PaperTrail 的 omitted 完整性類 + abstention「機械強制棄答」原則；ADR（Nygard）的決策當下捕獲思想仍是 provenance 思想源。

## 統一原則（脊椎）

**讓 from-scratch 優雅退化成「誠實的、分級的不確定」，而不是編出自信的 prose。**
openwiki 原罪＝看不見地填滿每個缺口（分不出真句假句）；lumos 反過來＝**把缺口變可見 + 有型別**。一個標「這條為何是 invariant 我不知道」的節點，比一段合理的假 why 更值錢——擋假信心、且指出人力該花在哪。

## 解法堆疊（由先做到兜底；大半組合現有機械）

1. **縮面積——對舊節點 diff 重生、不整篇換**。stale 也是拿舊節點當底料、只重寫被證據推翻的部分、輸出 diff 給人審。保住殘存目擊內容，把 synthesis 鎖在真變了的地方。＝把 from-scratch 重定義為 maximal-incremental，面積趨零。（openwiki `OPENWIKI:START` 區塊保留法下沉到 claim 粒度。）
2. **provenance 分級隔離——複用不對稱雙欄信任**。每條 claim 帶證據級：Tier A（現 code 可驗,file:line）/ Tier B（git 史變更事件,sha）/ **Tier C（無直接證據的推論 why→明確標 conjecture、進低信任隔離欄）**。同構複用 `decision_refs` vs `decision_refs_ai`（by:ai 結構上抑制不了 E2）：重生推論 why 進低信任層、**不能背書任何合約直到人 promote**。
3. **git 變更序列救 why——複用 cochange 挖掘**。對變更序列（`git log -p`/revert/「fix,rollback」commit/PR merge msg）重建,非對 code 快照。revert 編碼「試過 A 退回 B」這種快照抹掉的 why。加原語:替目標子系統收割 commit-message rationale + 共改證據餵重生 agent。
4. **殘餘 Tier-C 轉問題問人——走 signoff**。目擊者還在＝問不是推。重生吐**問題清單**（Tier-C conjecture）路由給人確認。＝「重生即結構化訪談準備」,一次 lossy 推論換一次便宜人工確認。
5. **拒絕發明無證據合約——留可見 knowledge-gap 標記**。可衍生導覽（FLOW/DEP/結構）安全重生(Tier A);不可衍生的 ★INVARIANT★ 理由/DECISION why 證據沒了就別重生,老實標「已佚失/未證」。anti-openwiki 核心動作。
6. **兜底 oracle——from-scratch 節點強制過 design-loop 對抗審**。從零重生的節點＝還沒審過的 spec;審計員問「這 claim 證據呢?」→ 無 backing 的 Tier-C 浮出。＝openwiki 結構上沒有、lumos 有的「prose 的 oracle」。規則:incremental update 保留目擊 provenance 可輕放;**from-scratch 重生必過對抗審**。

## 里程碑（收窄,記取 T3 凍結教訓——別大機械堆小需求）

- **M1（MVP,最硬核）**：`provenance 分級隔離` + `拒絕發明無證據合約`。＝解法 2 + 5。純機械 + 紀律,複用既有雙欄信任,無新派工。**這兩條不做,其餘都是沙上樓閣。**
- **M2**：`from-scratch 強制對抗審`（解法 6）——把 design-loop 接成重生的 mandatory gate。複用既有 loop 機械。
- **M3（後續,選配）**：`git-rationale 收割`（解法 3,複用 cochange）+ `diff 重生`（解法 1）。
- **M4（後續,選配）**：`Tier-C→signoff 訪談路由`（解法 4）。
- 收窄理由:M1+M2 已把「重生塌陷」的**可見性 + oracle** 兩件事解決(缺口標出來 + 對抗審接住);M3/M4 是把 provenance **主動找回**(錦上添花、面積更小),真有痛點再做。

## 天花板（誠實）

沒有一條能**從無到有變出 ground truth**。目擊者走了、git 沉默、issue 沒留 → 那 why **永久佚失**,正確輸出是「unknown」不是猜。這條沒得繞——而承認它、標出來,本身就是相對 openwiki 的贏法（openwiki 把「不知道」渲染成「知道」,lumos 該把「不知道」如實留成「不知道」）。

## M1 詳細規格（v4;r1-r3 折入）

**範圍**：只做「provenance 分級隔離 + 拒絕發明無證據合約」。純機械 lint 檢查 + 行內標記語法 + skill 紀律段。**無新派工、無新巢狀結構、無自動偵測重生**。

### 宣告制（沿用 lumos 既有「宣告 + 機械驗宣告」模式,同 ★IRREVERSIBLE★）

- **節點級標記**：from-scratch 重生的節點,寫入者以 `lumos set <節點> regen from-scratch/<日期>` 標 frontmatter 純量欄 `regen`。**touchpoint（r1 三席+Codex 折入）**:`regen` 須加入 `SCALAR_KEYS` 白名單(scripts/lumos:4135,現況此指令 rc2 直接拒)——一行擴充,其餘 scalar formatter/atomic write/寫後自驗全沿用。未標＝按目擊節點對待（不進 Check J）;不標而重生＝違紀,靠 review/M2 抓（誠實天花板,同「未標=可逆」前例;**且此繞過不落 governance/bypass log、無 ★IRREVERSIBLE★ 的 Check H 式軟提醒對應——類比不對等,誠實記,M1 不建自動偵測**）。
- **claim 級證據指針**（行尾,同 `[test:]` 家族語法;適用 summary KEY/DECISION 行）：
  - `[src:路徑]` / `[src:路徑:行號]` — **Tier A**（現 code 可驗）
  - `[git:sha]` — **Tier B**（變更事件證據:commit/revert/PR）
  - `推測:` 前綴 — **Tier C**（無直接證據的推論,顯式標）。**疊放順序釘死**:summary 行內接在既有前綴後（`KEY:推測: ...`/`DECISION:推測: ...`）。**機械執法範圍=只掃 summary 行**（r1 三席矛盾修正:原「body 行兩位置皆認」撤——body 是自由長文無一行一 claim 邊界,既有 ★ 解析也只讀 summary;body 內的 `推測:`/`佚失:` 是**人讀輔助慣例,Check J 不認、不執法**,明文非裝飾歧義）。
  - `佚失:` 前綴 — **knowledge gap**（證據已不存在,老實留空不編）。疊放與執法範圍同上。
  - 語法家族精確化（r1）:`[src:]`/`[git:]` 是**行內 bracket 指針**（同 `[test:]` 族,regex 搜整行）;`推測:`/`佚失:` 是**前綴標記**（緊跟 summary 前綴）——兩類錨定方式不同,實作勿混（防照 `[test:]` 慣性把前綴做成 bracket）。
- **不對稱信任接線**：`推測:` 行**不得**承載 ★INVARIANT★/★IRREVERSIBLE★（合約不能建在推測上）;推測升級唯一路徑＝補 [src:]/[git:] 證據或走 `lumos signoff` 人工確認。**偵測必須獨立掃 raw 行（r1 B#3/Codex 折入）**:既有 `INVARIANT_RE`(scripts/lumos:1370)對 `KEY:推測:★INVARIANT★` **整行不 match**→該行對 Check T/contracts/guard bind 全隱形（比擋下更毒:人眼看到★機械看不見）;故本規則由 Check J 自掃 summary raw 行「同行含 ★INVARIANT★/★IRREVERSIBLE★ 且含 `推測:`/`佚失:` 前綴 → rc1 專屬訊息」,**不依賴** INVARIANT_RE 或既有「標記位置非法」lint。**雙報消歧 predicate 寫死（r2 Codex+C 折入,「J 優先」不夠——需機械方案;r3 B#2 分支不對稱補正）**:cmd_lint 既有 ★ 位置檢查(scripts/lumos:1836-1840)迴圈內,先判「該行 match `^(KEY|DECISION):(推測|佚失):` 且含 ★INVARIANT★/★IRREVERSIBLE★」→ 命中即 `continue` 跳過 generic 位置錯誤,只報 J 專屬訊息(同一行恰一則訊息,測試策略釘)。**分支不對稱明記（r3）**:該既有迴圈只處理 `★INVARIANT★/★DEBT★` 兩 mark、**不含 ★IRREVERSIBLE★**——故消歧只需對 INVARIANT 分支做;★IRREVERSIBLE★ 組合本無 generic 訊息,J 專屬訊息對**全部四組合**(`推測:`/`佚失:` × ★INVARIANT★/★IRREVERSIBLE★)一律觸發,無雙報之虞但四組合皆須測。

### lint Check J（只對 `regen:` 節點生效;**r1 改名:doctor `[G]` 已被同名 basename 守衛佔用** scripts/lumos:579）

**接線（r1 Codex 折入;r2 簽名+映射表補正）**：新增**共用檢查器 `check_regen_provenance(note, repo_root) -> (errs, warns, gov_events)`**,cmd_lint 與 run_doctor **同呼叫同一函式**——lint 現行無字母 Check 系統、doctor 才有,兩入口各寫一份必漂移。**兩入口映射表（r2 釘死,實作照抄不猜）**:

| 回傳桶 | lint 側 | doctor 側 |
|---|---|---|
| `errs`(J-a/J-b/J-c dangling) | errs,計入 rc1 | warn(hard),計 issues |
| `warns`(J-d 計數、shallow 降級標示) | warns **顯示、不計 rc**(J-d「提醒不擋」與 J-c「full clone 才 rc1」兩保證**兩入口皆成立**,嚴禁 lint 側升格) | warn_soft(不擋不計,同 Check S/H/K 慣例) |
| `gov_events`(shallow 跳驗事件) | **一律不寫帳**(lint 是編輯期高頻指令,寫帳=灌爆刻意低頻的治理帳;僅顯示) | 僅 `--ci` 落 `_append_governance_log` 既有通道(scripts/lumos:415/1074) |

**cmd_lint「不掃 repo」原則例外明文（r2 B#3）**:cmd_lint docstring 承諾 node-local 不掃 repo(scripts/lumos:1806);J-c 對 regen 節點需檔案系統+git 存取——這是**opt-in 例外**(僅 `regen:` 節點觸發、量小),實作時更新該 docstring 註記。

- **J-a（硬擋 rc1,拒絕發明合約）**：★INVARIANT★ 行無 `[src:]`/`[git:]` 任一 → 擋。理由:`[test:]` 只證「行為現在成立」,不證「意圖是合約」——重生場景把偶然合約化是頭號毒(既有鐵則「嚴禁從 code 反推合約」的機械化)。J-a 與既有 Check T(裸合約)疊加:regen 節點的 ★INVARIANT★ 需 [test:] **且** [src:]/[git:]。
- **J-b（硬擋 rc1,同規則擴至決策）**：summary `DECISION:` 行無證據指針且無 `推測:`/`佚失:` 標 → 擋（重建的 why 必須標來源或標推測）。
- **J-c（硬擋 rc1,substring gate——borrow repowise）**：所有 `[src:路徑(:行號)]` 指針機械驗:路徑存在、行號在檔案範圍內。**實作依據精確化（r1 B#2/A-top_dirs/Codex 折入）**:**不得**直接複用 `_refcheck_scan` 抽取入口——它只抽 inline-code span 且 `top_dirs` 靜默過濾(scripts/lumos:6048)會把假目錄 `[src:fake_dir/x.py:5]` **靜默放行**(正是 J-c 要擋的幻覺);正確做法=抽出小 helper `_validate_repo_ref(repo_root, path, line)`(existence+行號範圍,由 `_refcheck_scan` 與 Check J 共用),`[src:]` 抽取自寫 `SRC_REF_RE`/`GIT_REF_RE`(既有 `[test:]` 族皆具名閉括號,命名空間不撞——Codex 驗訖)。`[git:sha]` 驗 `git cat-file -e sha^{commit}`(新增小封裝;**presence-guard**——術語錨定 r2 A#2:節點全文無 `[git:` 子串即整節點跳過 spawn;指針>50 改走 `--batch-check`——r1 辯方降級後的一行緩解)。**shallow-repo 殘餘（r1 辯方裁定;r2 兩入口補正——r1 辯方只考慮了 doctor 入口,lint 是第二消費者）**:cat-file miss 時查 `git rev-parse --is-shallow-repository`→shallow 則進 `warns`+`gov_events` 桶:**兩入口皆顯性標示「Tier B 驗證跳過(shallow)」、皆不擋**;落帳僅 doctor `--ci`(見映射表——lint 高頻不落帳,「必顯性」兩側兌現、「留痕」由 push 時點的 doctor --ci 兌現);full clone 才 rc1。dangling 證據指針＝擋（防幻覺證據）。
- **J-d（提醒不擋）**：regen 節點中無任何 tier 標記的 KEY: 行計數提醒——**唯讀,不寫回任何欄位**（prose 級誠實機械驗不了,靠 M2 對抗審接）。

### 明確不做（範圍刀,防 T3 式膨脹）

- 不自動偵測「這算 from-scratch」（宣告制）;不做 corroboration 疊加升級語意（repowise 有,v1 不需——二值有/無證據就夠）;不做 omitted 完整性偵測（PaperTrail 第三類,記進 M2 審計鏡頭）;不做 git-rationale 收割（M3）;不動 decisions[] 巢狀欄位機械驗（只掃 summary 行,巢狀 why_chosen 靠既有 ADR 四欄紀律）。

### 測試策略

J-a:regen+★INVARIANT★ 無證據擋/有 [src:] 過/非 regen 節點不受影響;J-b:DECISION 行**四態**(有證據/推測/**佚失**/裸→擋——`佚失:` 與 `推測:` 語意不同各自一格,r3 B#3);J-c:dangling path 擋/行號越界擋/合法過/git sha 假擋/**假頂層目錄擋(top_dirs 靜默放行迴歸測,r1)**;J-d:計數提醒**兩入口皆**不影響 rc、**不寫任何檔**;raw 行偵測**四組合逐格測**(`推測:`/`佚失:` × ★INVARIANT★/★IRREVERSIBLE★ → 皆 rc1 專屬訊息,r3 B#2;**不靠 INVARIANT_RE 碰巧不 match,r1**)且 INVARIANT 組合**同一行恰一則訊息**(雙報消歧 predicate,r2;IRREVERSIBLE 組合本無 generic 訊息);`lumos set <node> regen from-scratch/<日期>` 白名單擴後 **rc0 迴歸測**(touchpoint 認領,r3 B#4);**兩入口映射表逐格測(r2)**:lint 側 warns 不計 rc(J-d/shallow 皆非阻擋)、shallow 事件 lint 不落帳、gov_events 僅 doctor --ci 落 `_append_governance_log`;shallow 降級兩入口顯性標示(r2);`INV_TAG_RE` 擴 `src|git` 後 contracts 顯示乾淨+guard 定位同文合約多重命中行為(r2 影響面);**lint 與 doctor 兩入口走同一 `check_regen_provenance()`(共用函式防漂移,r1 Codex)**。

## 實務隱患（M1）

- **宣告制繞過**：不標 `regen` 就完全繞過 Check J——這是 opt-in 閘的結構性限制（同 ★IRREVERSIBLE★「未標=可逆」）。緩解＝紀律 + review;不假裝機械能抓。**r1 補**:此繞過無 governance/bypass 留痕、無 Check H 式軟提醒對應——類比 ★IRREVERSIBLE★ 的緩解力度不對等,誠實記;自動偵測「疑似重生未標」留未來(不進 M1)。
- **假 Tier A（幻覺證據）**：編一個真實存在的 path 但內容根本不支持該 claim——J-c 只驗「指針可解析」,不驗「內容真支持 claim」（那是語意判斷,機械做不到;誠實記天花板,語意層靠 M2 對抗審）。
- **self-governance 循環**：Check J 由 lumos 自驗 lumos 架構圖——lint 規則本身錯了會系統性放行/誤擋;緩解＝Check J 測試逐條對齊合約（測試策略節）+ anchor 基線護測試不被偷改。
- **標記語法與既有解析（r1 已查證收斂;r2 影響面列全）**：`[test:]` 族皆具名閉括號,`SRC_REF_RE`/`GIT_REF_RE` 命名空間**不撞**(Codex 驗訖);但 `INV_TAG_RE`(scripts/lumos:1397)清洗族**須同步擴 `src|git`**——影響面共 11 處行號、8 類呼叫點(r2 Codex 列全,非只 contracts 顯示;計數精確化 r3):Check T 乾淨宣稱(660)/contracts(1787)/lint 裸合約訊息(1844)/guard 分類·list·trace(2419/2445/3150)/guard scaffold 子字串選取(2547)/kill-add 定位+寫後驗(2724/2793)/guard audit 定位+寫後驗(3069/3091)。**行為後果明記**:guard 定位對「正文相同、只差指針」的兩條合約改為多重命中→要求更精確正文——這**符合**「指針非宣稱正文」語意,非退化;`[test:]` 抽取不受影響(strip_test_refs 另走 invariant_test_refs,1621)。
- **`推測:`/`佚失:` 疊放**（r1 已釘死）：`KEY:推測:` 第二層前綴、只掃 summary、raw 行獨立偵測——見宣告制節與不對稱接線節。

## 進實作前（紀律）

本 spec 完成 → M1 交 **lumos-design-loop**（panel 模式;M1 純 lint/標記層無 AI 派工,標準 tier）到 `loop status --gate --panel` 收斂才實作。落地 Verification 以 `plan_refs` 回指本節點。**先只做 M1**、驗證真解決痛點,再決定 M2+。

## M1 審計修正紀錄

**r1（2026-07-16,panel:3 sonnet 異鏡頭+Codex 否決席讀 repo+opus 辯方）**:canary a✗(合約鏈豁免矛盾,A 席漏——該席 findings 按紀律剔除,與他席重疊者不受影響,A 獨有 top_dirs 細節經編排者機械自核 scripts/lumos:6048 採信折入)b✓(未定義離線跳驗旗標,性質點名偏「無留痕逃生口」記偏離——其教訓已折進 J-c 降級路徑必顯性+留痕)c✓(未定義欄位寫回+stale 接不住,精準)。Codex 總裁定:核心可建、無結構性障礙、需 7 接線零件。辯方後存活 9 條 distinct 全折 v2:
- **掃描範圍三處矛盾(blocker,B+C)**→釘死「只掃 summary,body 標記=人讀輔助不執法」。
- **KEY:推測:★INVARIANT★ 對 INVARIANT_RE 隱形(major,B+Codex)**→Check J 自掃 raw 行專屬訊息,不靠既有位置錯誤兜底。
- **refcheck 抽取入口不可直接複用(major,B+Codex+A自核)**→抽 `_validate_repo_ref` 共用,top_dirs 靜默放行列迴歸測。
- **Check G 字母撞名(major,B+Codex)**→改 Check J;lint 側無字母系統改共用函式描述。
- **SCALAR_KEYS 缺 regen(major,B+C+Codex)**→touchpoint 明列。
- **共用檢查器防兩入口漂移(major,Codex)**→`check_regen_provenance()`。
- **shallow-repo 誤擋(C major→辯方降 minor:doctor --ci 唯一消費者=本機 pre-push,repo 無 CI/shallow 場景)**→殘餘 is-shallow 偵測+warn_soft+顯性留痕。
- **per-pointer subprocess 效能(B major→辯方降 minor:最壞~1.2s vs hook 既有~32s)**→presence-guard+>50 批次 note。
- **INV_TAG_RE 清洗擴充(minor,C+Codex)**。
另 editorial:行內 bracket vs 前綴兩類語法家族明文(A 席觀察,自證)。

**r2（2026-07-16,panel v2 delta 審:3 sonnet+Codex 否決席+A 席 framing 加碼）**:canary **3/3 caught、0 missed(首個有效輪)**——a✓(未定義帳檔:A 席翻出 cmd_gov 六帳封閉清單/gitignore/cochange 排除三處接不住,type d)b✓(入口升格矛盾:與 J-c/J-d 非阻擋保證邏輯不可共存+兩個重現場景,type a)c✓(未定義巡檢旗標:codebase 無/掛載點未定/測試策略沒進,type b)。Codex 複核:核心可實作,r1 接線缺三塊。存活 6 條 distinct 折 v3(≥major 兩條皆 Codex 行號機械證實+雙席印證,依 r1 慣例免辯方):
- **留痕通道簽名不足(major,Codex+C)**→簽名擴 `(errs, warns, gov_events)`,doctor --ci 才落帳,lint 高頻一律不落帳(防治理帳灌水)。
- **兩入口映射表未明訂(major,Codex+B;含 B 席戳破 r1 辯方只考慮 doctor 入口的盲點)**→映射表釘死:errs→rc1/warn(hard),warns→lint 顯示不計 rc/doctor warn_soft,J-d 與 shallow 非阻擋**兩入口皆成立**。
- **雙報消歧 predicate(minor,Codex+C)**→寫死:generic ★ 位置檢查前判 `(KEY|DECISION):(推測|佚失):` 含 ★ → continue 只報 J。
- **INV_TAG_RE 影響面列全(minor,Codex)**→8 呼叫點+guard 同文合約多重命中行為明記。
- **lint「不掃 repo」原則例外(minor,B)**→明文 opt-in 例外+docstring 更新。
- **presence-guard 術語錨定(minor,A)**→J-c 本文定義=無 `[git:` 子串整節點跳 spawn。

**r3（2026-07-16,panel v3 delta 審,cap 末輪）**:canary **3/3 caught 全精準**——a✓(隱藏寫回:A 席列舉全庫 atomic_write_verify 呼叫點證「寫入只走使用者主動指令」+點出映射表外第四副作用通道,type c recraft×1)b✓(未定義測試 fixture:全篇唯一出現/無 schema/與零依賴純 Python 測試慣例矛盾,type d)c✓(訊息數矛盾:「兩則並列」vs「恰一則/continue」不可共存,type a)。存活真 findings 全在測試策略完整性(B 席),折 v4:
- **raw 行偵測四組合測試補全(major,B#2)**+**實測發現 1836-1840 迴圈不含 ★IRREVERSIBLE★**→分支不對稱明記(消歧只需 INVARIANT 分支;J 訊息四組合皆觸發)。
- **J-b 佚失: 獨立測試格(minor,B#3)**→三態改四態。
- **SCALAR_KEYS 迴歸測認領(minor,B#4)**。
- editorial:INV_TAG_RE 計數 8→11 處行號/8 類(探針噪音自查+B 席印證)。
