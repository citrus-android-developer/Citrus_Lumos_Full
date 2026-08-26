---
type: project
status: done
created: 2026-07-29
updated: 2026-07-29
tags:
  - type/project
  - status/done
related:
  - "[[Projects/Codex外審吸收_計劃]]"
  - "[[Issues/canary-record未落盤事件]]"
  - "[[Systems/guard-kill]]"
  - "[[Systems/canary-audit]]"
summary: |-
  FLAG:TECHNICAL
  KEY:P1-1 oracle 品質包(外審對話收斂的最高投資序)——讓每盞綠燈答得出兩問:證據真的落盤了嗎(S1 record 寫後讀回自驗)/紅燈真的是那條規則咬住的嗎(S3 guard-kill 歸因);加 S2 canary 第二判者抽查(植入者≠判定者的抽樣分權)
  KEY:出身——2026-07-29 Codex 外審對話三輪:它抓到 record 回報成功未落盤真事故([[Issues/canary-record未落盤事件]])+「guard-kill 只知紅不知為何紅」+「caught/missed 無第二判者」;與我方架構圖舊結論「驗證層天花板=oracle 品質」合流
  DEP:[[Systems/canary-audit]]
  DEP:[[Systems/guard-kill]]
verified_by:
  - "[[Verification/2026-07-29_oracle品質包落地]]"
---
# oracle 品質包_計劃（P1-1）

`PRIOR-ART:` ①寫後讀回自驗＝lumos T1 寫入既有家規（tmp→rename→自驗），S1 是把漏網的 append 路徑補進同一紀律，非新機制；②kill 歸因＝mutation testing 生態的 killing-test attribution（PItest 報告殺死變異的具體測試、Stryker 分 Survived/NoCoverage）——borrow-design：解析 runner 輸出歸因到綁定測試名，不引依賴；③第二判者抽查＝評分者間信度（inter-rater）抽樣慣例，取抽樣不取全量（成本）。裁定＝borrow-design。

## 範圍刀（明確不做）

- **不做**帳本上雲／不可竄改儲存（合規面，超出本包；見外審 P1-0/組織級路線）。
- **不做** canary caught/missed 判定自動化（判定仍是編排者，S2 只加抽樣分權）。
- **不改** `loop status` 收斂邏輯（second 行由既有 loop 欄過濾天然隔離，只加回歸釘不加代碼）——S2 純 telemetry，**不進 gate**。
- **不做**全量第二判——抽樣（成本與價值的取捨，明文）。
- guard-kill 歸因**不 parse 各框架結構化報告**（JUnit XML 等＝依賴/耦合面大）——文字輸出啟發式＋明標弱證據級別。

## 條款

### [S1] `canary record` 落盤自驗（修 [[Issues/canary-record未落盤事件]] 的機械面）

- 成功輸出改為：`✓ canary <kind> 留痕: CANARY-<id> [(auditor=<a>)] → <log 檔絕對路徑>`（auditor 段沿現行慣例**有給才印**；新增＝行尾落盤絕對路徑，消「成功了但不知寫哪」盲區）。
- **append 後讀回驗證**（**欄位名更正，r1 四方同報：現行 schema 識別欄是 `token`，無 `id` 欄——照原文實作自驗會 100% 誤報**）：**重新開檔**（獨立 read handle，以此為準）、確認存在某行 `json.loads` 可解且其 **`token` 欄 == `CANARY-<id>`**；不成立 → stderr `canary record: 落盤自驗失敗(<絕對路徑>)` ＋ **rc 2**、不印 ✓ 行。自驗 helper 介面＝「寫入一行＋caller 提供唯一鍵欄名與值」（record 用 `token`、second 用自身 `token`），不寫死欄名。**second 的成功行印自身新 token**（非 `--id` 引用的原 token——樣板佔位符消歧，r2）。
- vault 解析失敗（cwd 無 vault 且未給 --vault）→ 維持現行 rc2 路徑，但 [S1] 測試釘住「絕不靜默成功」。
- `canary second`（[S2] 新指令）與既有 record 共用同一寫入＋自驗 helper（單源，不雙寫）。

### [S2] canary 第二判定者（抽樣分權，telemetry-only）

- 新子指令：`lumos canary second --id CANARY-<id> --verdict agree|overturn --auditor <模型/人> [--note "<一句>"]`
  - **wiring 前置修改明文（r2 席1/席2 同報）**：現行 dispatch `if args.cmd == "canary":` 無條件呼叫 `cmd_canary(env, args.kind, ...)` 不看 ccmd——須改依 `args.ccmd` 分流、second 走獨立 `cmd_canary_second`（否則跑 second 取不存在的 `kind` 屬性必崩）；新增 `csub.add_parser("second", ...)`。
  - 追加一行 `{kind:"second", token:"CANARY-<新id>", ref:"CANARY-<原id>", verdict, auditor, note, ts}`——**second 必帶自身唯一 `token`**（r1 實查：gov ledger dedup key 含 token，缺 token 的 second 行會被折成一筆靜默消失）；走 [S1] 自驗 helper（唯一鍵=自身 token）。
  - `--id` 在 log 中不存在 → rc 2；`verdict` 僅收 `agree`/`overturn`（overturn 語意＝第二判者不同意原 caught/missed 判定；細節寫 note）。
  - `loop status` 忽略 second 行——**機制＝天然成立**（second 行不帶 `loop` 欄，現行 `loop==loop_id` 過濾天生濾掉，pre-flight 已實查現碼證實）；**不要為此新寫判斷（死代碼）**，[S3′] 第 5 項是回歸釘（防未來 filter 鬆動），非新邏輯。
- **抽樣紀律（skill 層，非機械閘）**：design-loop 與 code-loop 判讀段各加一條——每累計 5 個 caught 輪抽 1 輪，把「審計員原始報告全文＋植入描述（型別/位置/性質）」交乾淨第二判者判 caught/missed；抽中輪的審計員報告存 `governance/canary-samples/CANARY-<id>.md`（**寫入者＝編排者人工存檔，本條即其定義，[S3′] 不驗**；僅抽中輪保留——全量成本不值）。分歧（overturn）→ 記 `canary second --verdict overturn` ＋該 loop 下一輪 framing 復核。
- **gov 可見性 touchpoint（r3 席1）**：現行 gov 第 4 源 mapper 不讀 `verdict`/`ref`——overturn 分歧訊號寫進 log 後在治理帳完全隱形（S2 存在理由被消音）。同步修改：mapper 把 `verdict`/`ref` 併入 detail、分帳段對 kind=second 顯示 `agree/overturn` 計數；測項 5d＝`lumos gov` 可見 second 的 verdict。
- 誠實天花板：抽樣頻率 1/5 是先驗值；第二判者仍是 LLM（同門盲點靠換家族緩解，skill 建議第二判者優先跨家族）。

### [S3] guard-kill 歸因升級（「準殺」）

**現況更正（pre-flight 實查）**：現行 verdict 已六值（killed/timed_out/survived/drifted/abort/error）、`.kill-log` 已有 verdict 欄、且 **timed_out 現行計入 killed**（PIT 心智模型註解在案）。本條款＝**取值語意升級＋一項刻意行為變更**，非新增欄位：`killed` 拆歸因/未歸因兩級（新值定名 **`killed_unattributed`／`timed_out_weak`——底線風格與既有六值一致**，r2 指正勿混連字號）；`timed_out` **改不計 killed**（刻意變更——採外審「timeout 降弱證據」；理由：掛掉可能是環境非變異）。**rc 優先序明文（r1 修矛盾）**：`survived`→rc1；無 survived 但任一 `drifted/abort/error`→**rc2 不變**（執行錯誤不因弱證據條款放行）；僅 killed/killed_unattributed/timed_out_weak 組合→rc0＋摘要印弱證據（unattributed 與 timeout 同桶分列）。`--json` 模式弱證據計數入 JSON 欄位，不另印人話行；**且 guard kill 在 --json 模式下所有非 JSON 診斷（dirty-worktree 警告/--keep-worktree 路徑/多平台 legacy run_cmd 警告等）一律走 stderr**——r2 只點名兩處、r3 Codex 再抓 legacy config 警告同坑，收斂為全稱規則＋測項各釘（6c 擴：dirty 與 legacy-config 兩情境）。

**前置修改（r1 四方同報；r2 補波及面）**：現行 `_kill_run` 只回傳輸出最後 200 字元——歸因開跑前料就沒了。同步修改：`_kill_run` 完整保留 runner stdout＋stderr 供歸因（上限 256KB；**超限截斷對齊換行邊界、縫處插一行 `...[truncated N bytes]...` marker**——r2 指正：裸位元組砍半會把兩條真實行拼成假行汙染行窗掃描）。**既有 tail 寫入點兩處（baseline 非綠／survived 的 res.tail——.kill-log 與 --json 為其下游共用）於寫入時裁回 200 字**（r3 措辭校準:非三處獨立源）（r2 席1：只改 _kill_run 一處會讓帳檔與 json 膨脹到 256KB，違背「既有展示不變」）。

`lumos guard kill` 跑完 recipe 後，對完整輸出做文字歸因：

| verdict | 判準 | 語意 |
|---|---|---|
| `killed` | rc≠0 **且** 綁定測試方法名的**任一出現處**（掃全部出現行——r2 真實 pytest 重現:summary 行同行即中）其行起（含同行）往後 5 行窗內有失敗標記，**且標記命中位置不得落在測試名字串自身範圍內**（r3 Codex 反例:綁定測試叫 `test_fail_closed`,名字自帶 FAIL——回顯名字＋無關 rc≠0 就偽造強殺;此類落 unattributed）（`FAIL`/`FAILED`/`✗`/`AssertionError`——**裸 `Exception` 剔除**：非斷言類例外落 unattributed；標記大小寫不敏感） | 強證據：那條測試真的咬住了 |
| `killed_unattributed` | rc≠0 但綁定測試名未命中上述判準 | 弱證據：可能只是 compile error/環境 crash——印警告「建議 recipe 加 filter 鎖定該測試」；**與 killed 分開計數**（摘要行分列） |
| `timed_out_weak` | runner 逾時 | 弱證據、**不計 killed**（刻意變更，見上） |
| `survived` | rc 0 | 不變（稻草人證據） |

- 歸因輸出（r2 修幾何矛盾：標記行±1 行含不到 5 行外的測試名行）：摘錄＝**取跨距最短的命中出現處**（名行與標記行距離最小者），從名行到標記行整段（含兩端，至多 6 行），總長截 200 字，印於 verdict 後。`killed_unattributed`/`timed_out_weak`/`survived` 無標記行——沿現行 tail 尾段展示（明文）。**摘要措辭收斂**：「✓ 全部 killed——咬得住」僅全強 killed 時印；混弱證據改印 `強殺 X / 弱 Y`。逐行 icon 表補 `killed_unattributed`(⚠)/`timed_out_weak`(⚠)（底線——r3 抓到 r2 自己又寫回連字號,icon key 必須與 verdict 字面全等否則查表恆 `?`）。
- 綁定測試名比對：以 `[test:]` 的方法名（含多平台 `P:方法` 的方法段）做**大小寫敏感子字串**比對（測試方法名是識別字）。
- 既有 kill 測試：**timed_out 相關斷言依刻意變更同步調整**（其餘不倒退）；`.kill-log` verdict 欄既存——只擴值域，舊值讀取不變。

### [S3′] 測試（TDD，`t_canary_record_persist`／`t_canary_second`／`t_guard_kill_attribution`）

1. record 正常 → 輸出含絕對路徑；該行讀回可解、id 相符；`--auditor` 未給時無 auditor 段（沿現行）；
2. 寫入失敗（log 被目錄佔用）→ rc2 走既有 OSError 訊息（此手法誘發不到 readback 分支——r1 指正）；2b. **readback 失敗誘發＝log 為 symlink→/dev/null**（append 成功、讀回恆空）→ rc2、stderr 含「落盤自驗失敗」、無 ✓ 行；
3. record 於 vault 外 cwd（明給 --vault）→ 寫進正確 log（cwd 漂移回歸釘）；cwd 無 vault 且未給 --vault → rc2 非靜默成功；
4. second 正常 agree → log 追加 kind=second 行（含 note 落盤讀回）；`--id` 不存在 → rc2；verdict 亂值 → rc2；缺 `--auditor` → rc2（分權紀錄無名則失義）；
5. second 行存在時 `loop status --gate` 輸出與 rc 逐字節相同（回歸釘）；5b. `lumos gov` 多筆 second 不被 dedup 吞（各自 token 唯一）；5d. gov 可見 second 的 verdict（agree/overturn 計數）；5e. second 一次呼叫恰寫一行（單源不雙寫釘）；5c. canary dispatch 依 ccmd 分流（second 不因取 `kind` 屬性炸——wiring touchpoint）；
6. kill 歸因四型（fake run_cmd 各產：具名失敗／匿名 crash／逾時／全綠）→ killed／killed_unattributed（含警告）／timed_out_weak／survived；**6b. 真實 pytest 形狀 fixture**（FAILURES 區＋summary 行）→ killed 強歸因；**6d. 名字自帶標記反例**（綁定名 `test_fail_closed`＋無關失敗）→ unattributed；**6e. 三型混合批**（killed+unattributed+timed_out_weak 同批）→ `強殺 X / 弱 Y` 措辭＋分桶計數；**6c. --json 於 dirty worktree 下 stdout 恰一行合法 JSON**；**timeout-only 情境 rc0＋摘要印弱證據筆數**；摘要 killed 與 unattributed **分開計數**可見；
7. killed 歸因輸出含命中行摘錄；**超長命中行截 200 字**（構造長行驗截斷）；
8. gov ledger 對新 verdict 值原樣帶出不炸；icon 表兩新值非 `?`；（原「舊行無 verdict 欄」情境不存在，pre-flight 已證，刪）；
9. 綁定名比對大小寫敏感（`Foo_test` 不命中 `foo_test`）；**多平台綁定（`[test:P:方法]`）取方法段歸因**命中案。

### [S4] 文件/skill touchpoints

- `skills/lumos-code-loop/SKILL.md` §4「修進真碼」補一句：**修 bug 標配「還原翻紅釘」**（把 bug 還原、綁定測試必翻紅的回歸測試；testmap 實戰教訓——存在且綠的測試可空轉）。
- design-loop 與 code-loop 判讀段各加 [S2] 抽樣條（一句＋樣本保留路徑）。
- [S1] 落地後：`Issues/canary-record未落盤事件` status → resolved，回填根因調查結果（重現或「無法重現，readback 防線已閉」如實記）。

- **r2 panel**（2026-07-29，delta 3 席 sonnet＋Codex 否決；**三席 canary 全中（二連）**；存活全機械證實免辯方）：[major] ①canary dispatch 不看 ccmd——second 照字面必崩 → wiring 前置修改明文（席1+席2）；②_kill_run 改 256KB 波及三處 tail 消費點（帳檔/json 膨脹）→ 各自裁回明文（席1）；③真實 pytest 輸出標記在 5 行窗外、強殺誤判弱（席2 實跑 pytest 重現）→ 判準改「任一出現處」；④頭尾各半截斷拼假行 → 對齊換行+marker 行（席2）；⑤摘錄窗幾何矛盾（標記±1 含不到 5 行外測試名）→ 改「名行到標記行整段」（席3）；⑥guard kill --json 被 dirty 警告破純度 → 診斷改 stderr+測項（Codex）。[minor] verdict 命名統一底線風格；second 樣板 token 消歧；無標記行型摘錄明文；折入清單 reopen 措辭修正（席3 抓宣稱無落地）。測項補 6b（真 pytest fixture）/6c（dirty×json 純度）。
  canary 帳：席1 caught（c 型幽靈回填欄——append-only 檔改寫既有行＝照字面不可能,性質點滿）、席2 caught（d 型溢出檔——多 recipe 互覆寫的具體失敗場景）、席3 caught（a 型假引用——宣稱 [S4] 有某總表,逐字核證無）。

- **r3 panel（終輪，2026-07-29；席1/席2 caught、席3 missed 剔除；cap=3 到頂）**：[major] ①icon 表連字號/底線自打（r2 修過又復發同型——席1+席2 同報,席3 落選同報）→ 底線統一＋全等注記；②second 的 verdict/ref 在 gov 帳全程隱形（分歧訊號被消音）→ mapper/分帳 touchpoint＋測項 5d（席1）；③--json 純度漏 legacy config 警告同坑 → 收斂全稱規則（Codex）；④測試名自帶 FAIL 偽造強歸因（`test_fail_closed` 反例）→ 標記不得命中名字串範圍內＋反例測項 6d（Codex）。[minor] tail 寫入點計數措辭校準；摘錄取跨距最短出現處；[編排者自主修正,採落選席觀察] 三型混合批測項 6e＋單源不雙寫釘 5e。
  canary 帳：席1 caught（d 型幽靈樣本檔,點出全檔唯一出現無路徑錨）、席2 caught（a 型假引用,核 [S1] 證無裁回規則）、**席3 missed**（b 型幽靈旗標未點出且宣稱簽名無不一致——判 missed 剔除,其 icon 發現由另兩席同報存活）。

## 合約候選清單（設計端提名，落地時 guard bind 蓋章——合約鏡頭首次 dogfood）

1. 「`canary record`/`second` 回報成功 ⟺ 該行已落盤可讀回」（readback 驗不到即 rc2 不印 ✓）——候選綁 `t_canary_record_persist`。
2. 「second 紀錄純 telemetry，永不影響 `loop status` gate 輸出與 rc」——候選綁測項 5 回歸釘。
3. 「guard kill 的 rc 優先序：survived→rc1、drifted/abort/error→rc2，弱證據不放行執行錯誤」——候選綁測項 6 rc 邊界。
4. 「guard kill --json 模式 stdout 恆單行合法 JSON」——候選綁測項 6c。

## 實務隱患

- 歸因啟發式對「測試名出現在非失敗上下文」（如 runner 列印執行清單）可能誤歸因 → 判準要求名字＋失敗標記**鄰近共現**（5 行窗），仍非零誤判，明標弱證據帳分開統計。
- readback 在 NFS/延遲寫檔系統上理論上可 false-fail → append 後同 fd flush 再讀，本機 POSIX 語意下穩定；異常檔案系統列明文限制。
- 第二判者樣本檔（canary-samples/）含審計員報告全文 → 可能夾敏感碼段；保留於 repo 內 gitignore 或入版控？**裁定：入版控**（它就是稽核證據，遮掩即失義）——但列入 pitfalls 提醒別貼密鑰。

## 審計修正紀錄

- **r1 panel**（2026-07-29，3 席 sonnet＋Codex 否決；**三席 canary 全中**；存活全機械證實免辯方）：[major] ①readback 判準引用不存在的 `id` 欄（現行=`token`）——照字面自驗 100% 誤報、功能自爆（四方同報,本包要防的錯落自己身上）→ 欄名更正+helper 介面改 caller 給唯一鍵；②second 行缺 token 會被 gov dedup 靜默吞光 → 必帶自身唯一 token（席1/席3/Codex）；③`_kill_run` 僅存尾 200 字、歸因無料 → 前置修改明文（四方）；④rc 規格矛盾（「無 survived rc0」誤蓋 drifted/abort/error）→ 優先序明文（Codex）；⑤裸 `Exception` 標記偽造強歸因（InfrastructureException 反例）→ 剔除、限斷言類（Codex）；⑥[S3′]#2 誘發手法測不到新分支 → 拆 2/2b（symlink→/dev/null 誘發 readback 失敗）（席3）；⑦「全部 killed 咬得住」混弱證據時誤導 → 措辭收斂+icon 補值（席3）；⑧#8 測項對不存在的讀取點 → 改測 gov 新值顯示（席1+Codex）。[minor] 讀回機制明定為「獨立重開檔」（原 spec 前後段一講 reopen 一講同 fd,統一取前者）；--json 弱證據入欄不印人話；摘錄中心行明定；dispatch 分流 touchpoint（5c）。

- **pre-flight**（2026-07-29，機械 checklist＋現碼實查，不計 loop findings）：①[S3] 三處現況誤述更正——現行 verdict 已六值/.kill-log 已有 verdict 欄/timed_out 現行計 killed（「timeout→skipped 既有語意」是我方誤寫）→ 改述為「取值語意升級＋timeout 降級屬刻意變更」並明文 rc 影響；②[S2] loop status 忽略 second＝天然成立（second 行無 loop 欄,現有過濾天生濾掉）→ 明文防死代碼,測試改回歸釘定位;③範圍刀與 [S2] 措辭衝突消解;④auditor 段沿現行有給才印;⑤[S3′] 補 6 項測試縫(note 落盤/缺 auditor rc2/多平台方法段/分開計數/200 字截斷/timeout-only rc 邊界);⑥canary-samples 寫入者=編排者人工,明文不驗。
