---
type: system
status: done
created: 2026-06-26
updated: 2026-08-26
self_audit: sonnet/2026-07-24
tags:
  - type/system
  - status/done
related:
  - "[[Systems/lumos-cli-read]]"
  - "[[Systems/lumos-cli-lifecycle]]"
  - "[[Verification/2026-08-11_T1_remove_list項移除]]"
  - "[[Systems/check-u-overgeneralization]]"
summary: |-
  KEY:[2026-08-05 標籤收編]值域 lint(cutoff 2026-08-06 新節點硬擋,舊帳不回溯)——status 依 type enum(verification 用 pass)/summary FLAG: 三值(敘述移 KEY 行)/priority P0-P3/risk 四值;feature/area 凍結 warning 勸轉 scope/。schema 表單源=lumos-project-notes SKILL〈標籤家族〉 [test:t_lint_tag_value_enums]
  KEY:[2026-08-05]aliases 宣告制——system/issue 新節點(created≥2026-08-05)lint 硬擋「缺 aliases 鍵」;逼★判過★不逼有值(aliases: []=明示無同義詞,合法;湊數別名吃 3.5 檢索權重=主動污染排序)。配套:模板自帶 aliases: []+NEW_HINT 教學(來源限真實出現過的說法)+append 白名單納 aliases;兩庫回填 2026-08-05(toolchain 22 節點 23 條/Landmark 71 節點 152 條,grounded 規則) [test:t_lint_aliases_declared]
  KEY:[2026-08-05]decisions 結構守衛修假陽性——原始條數只認 entry 縮排層(恰 2 空格),alternatives_considered 巢狀清單不計(Landmark 回填實戰:照 ADR 規範寫巢狀清單被誤報「壞損」;真壞型 sibling 吞沒照抓) [test:t_lint_decisions_nested_list_not_false_positive]
  KEY:[2026-08-05]`new verification <名> --plan <計劃> --systems <A,B>` 一鍵雙向——建檔當下填 plan_refs+對每個 Systems append verified_by(寫後自驗沿 cmd_append);指到不存在節點 rc2 且不建檔(不留半套);把「事後 sync-verified-by 撿漏」變「寫入時就對」 [test:t_new_verification_bidirectional]
  FLOW:set/append/self-audit/decision-*→load_raw_for_edit(讀raw,拒BOM/CRLF)→line-based改fm→atomic_write_verify(寫tmp→re-parse自驗值正確+無新lint指紋→os.replace)→敗則tmp丟棄原檔不動
  KEY:[2026-08-11]新增 `remove <note> <key> <value>`=append 逆操作(T1 list 項移除)。缺口來自實戰:死背書(verified_by 指向已 superseded 的驗證)與降格後殘留 core_refs,都只能靠移除 list 項來收,而 set 只收純量、append 只能加,唯一退路 obsidian processFrontMatter 需 Obsidian 執行中→實務無路可走。比對沿用 link_target()(精確 target,不做前綴/basename 匹配);★不命中一律 rc=2★(靜默 no-op 回成功=呼叫端以為清乾淨了,比報錯危險);清空後連 key 行一併移除(裸鍵被 YAML 解成 null 比沒鍵更糟);core_refs 納入 LIST_KEYS(升格加/降格拆兩向都走 T1)。★不支援巢狀 dict 型 list 項★(core-knowledge facet 的 implements 需 T3 手術層,非本次範圍)。實戰驗收:LandmarkMember doctor E1 死背書 14→0、C 指針轉「無」。詳 [[Verification/2026-08-11_T1_remove_list項移除]]
  KEY:[2026-08-26]decision-add 補齊 ADR 四欄位——新增 `--alternatives`(可重複→`alternatives_considered` 巢狀清單,項縮排 sub+2)與 `--trade-offs`;欄位順序對齊 lumos-project-notes reference 的 ADR 完整版範例(content/id/context/alternatives_considered/why_chosen/trade_offs/decided/valid)。先前只有 context/why_chosen,規範要求的四欄位寫不進 frontmatter,「為什麼不選 B」與「代價」只能塞本文——而那正是 ADR 的價值所在。★兩條 block 組裝路徑抽成單一源 `_decision_block`★(無 decisions 新建 / append 既有,原本各組裝一次,欄位一多必分歧——同 2026-08-01 被代碼審抓到的分支簿記形態);寫後自驗升級到驗四欄位(只驗 id+content 的話,巢狀縮排寫錯會靜默成假成功;實測植入 sub+2→sub 壞法,自驗擋下、原檔零變動) [test:t_decision_add_four_field_adr,t_decision_add_alternatives_parse_back,t_decision_add_four_field_no_existing_decisions,t_decision_add_four_field_lint_clean]
  KEY:8個寫入原語(set/append/remove/new/archive/decision-add/decision-supersede/self-audit)是「專案層」圖譜寫入的唯一安全路徑,取代手改 frontmatter / obsidian property:set
  KEY:T1 寫後自驗 atomic——所有 fm mutation 經 atomic_write_verify:寫 .lumos-tmp → re-parse 斷言該 key 寫成目標值 + 無引入新 lint 指紋 → os.replace 原子換入;任一步失敗 tmp 丟棄、原檔零變動 [test:t_set_minimal_diff,t_append_exact_dedup]
  KEY:set 走 SCALAR_KEYS 白名單{status,updated,created,type,self_audit,signed_off,regen[M1 2026-07-16 from-scratch守衛宣告欄]}、append 走 LIST_KEYS{verified_by,plan_refs,related,tags};白名單外 key 直接 rc2(list 用 append、decisions 翻盤/新增走 decision-*) [test:t_append_block_key_rejected]
  KEY:鐵則1(多wikilink必YAML list)由 append 結構性保證——一項一行 + link_target dedup,絕不字串塞多個[[]];鐵則3/4(含「: 」長文引號化、日期 bare)由 fmt_scalar/_fmt_decision_value 包辦
  KEY:decisions[] 是巢狀結構,只能走 decision-add/decision-supersede/decision-reindex 的 surgical line-based 手術(非 ruamel round-trip,避免 reflow 破壞最小 diff);要求 2-space 縮排
  KEY:[M1/P2 2026-07-15]決策穩定 ID——add 指派 id:d<max+1>(翻案永不重用)、supersede 唯一命中(子字串多重命中 rc=2 列候選/#dN 精確定址)+回傳全域 id <rel>#d<N>(dispatcher 解包,CLI 對外仍 int rc)、reindex 冪等回填(混合狀態 max+1 不撞號);寫後自驗升級 ID 精確驗證(有 id 時)
  KEY:[M4/S1 2026-07-15]supersede 觸發主網 surfacing——rc=0 後 dispatcher 獨立 try 包「rel_cascade_create 建帳+cascade_surface 列鄰居」;stdout 首行逐字保留、cascade 面全走 stderr(CASCADE/NEIGHBOR 行式 schema);無 id→CASCADE-SKIP、失敗→CASCADE-ERROR fail-open(rc 仍 0,補網 E2 兜底)
  KEY:[decision_refs 自動養成 P+T1 2026-07-15]decision-reindex --all 批次編號(顯式,前置);rel-cascade confirm 回寫 decision_ref(_append_decision_ref exact-string dedup,非 link_target——它剝 #dN 會誤合同節點不同決策)。不對稱信任雙欄:by ai→decision_refs_ai(E3 firing 讀聯集/E2 抑制碰不到)、by human→decision_refs(可抑制)
  KEY:[2026-07-20]set status 反正規化同步——status 存兩處(欄位+tags 的 status/* 標籤,模板生),set status 同一次原子寫入就地改寫 tags 內既有 status/* 項(無則不添,純同步不發明);寫後自驗同驗兩處;繞過路徑(手改/外部工具)由 lint+doctor Check M 漂移守衛硬擋(見[[Projects/狀態標籤同步守衛_計劃]])
  DEP:scripts/lumos atomic_write_verify｜load_raw_for_edit｜_write_lf(唯一寫入原語,UTF-8/LF/no-BOM)｜parse_frontmatter｜parse_decisions
  TEST:set/append/decision/archive/new 全套 t_-prefixed 回歸(t_set_*,t_append_*,t_decision_*,t_archive_*,t_new_*);狀態標籤同步 t_set_status_syncs_tag+t_status_tag_drift_guard
decisions:
  - content: 所有 frontmatter 寫入經 atomic_write_verify「寫 tmp → re-parse 自驗(值正確且無新 lint 指紋)→ os.replace」,任一步敗則原檔零變動
    id: d1
    context: 圖譜檔被 doctor/lint 把關,半寫壞的 frontmatter(YAML 解析爆、引入新指紋)會污染全圖;直接寫檔無法保證寫完仍合法
    why_chosen: 寫後自驗把「寫出來的東西真的 parse 得回目標值、且沒新增 lint 問題」變成寫入成功的前置條件;atomic rename 確保不留半截檔,失敗即無痕回滾
    decided: 2026-06-26
    valid: true
  - content: 純量走 set(SCALAR_KEYS 白名單)、list 走 append(LIST_KEYS)、巢狀 decisions[] 走 decision-add/decision-supersede;白名單外 key 一律 rc2 拒絕
    id: d2
    context: frontmatter 三種結構(純量/list/巢狀)各有不同的安全格式鐵則與最小 diff 策略,混用會破格(如把 list 當純量塞逗號串、reflow 巢狀)
    why_chosen: 按結構分原語各自保證對應鐵則(append 保鐵則1 的 YAML list、decision-* 保 surgical 巢狀不 reflow);白名單擋誤用,把錯誤導向正確指令
    decided: 2026-06-26
    valid: true
  - content: decisions[] 翻盤/新增用 surgical line-based 編輯(只動目標行),不走 ruamel round-trip
    id: d3
    context: ruamel round-trip 重序列化整份 YAML 會 reflow、破壞「構造性最小 diff」(只改該改的行、其餘逐字原樣),也可能誤動子清單
    why_chosen: line-based 手術精確命中目標決策的 valid/superseded_by 行,diff 最小可審;代價是要求 2-space 標準縮排(0-indent/tab 直接報錯不靜默處理)
    decided: 2026-06-26
    valid: true
verified_by:
  - "[[Verification/2026-07-15_主網M1_決策穩定ID]]"
  - "[[Verification/2026-07-15_主網M3_cascade帳本]]"
  - "[[Verification/2026-07-15_主網M4_觸發與連鎖]]"
  - "[[Verification/2026-07-15_主網實驗場_LandmarkMember]]"
  - "[[Verification/2026-07-15_decision_refs養成_P前置_T1回寫]]"
  - "[[Verification/2026-07-15_decision_refs養成_codeloop硬化]]"
  - "[[Verification/2026-07-16_fromscratch守衛M1_CheckJ]]"
  - "[[2026-07-20_狀態標籤同步守衛]]"
  - "[[Verification/2026-08-05_流程優化六件落地]]"
  - "[[Verification/2026-08-05_標籤結構收編落地]]"
  - "[[Verification/2026-08-11_T1_remove_list項移除]]"
  - "[[Verification/2026-08-26_decision-add四欄位ADR]]"
---
# lumos-cli-write

`scripts/lumos` 的**專案層圖譜寫入原語**(7 個子指令)—— 對知識圖譜 frontmatter 的唯一安全寫入路徑。直接手改 frontmatter / obsidian `property:set` 會繞過寫後自驗與格式鐵則(實測 `property:set` 塞多 wikilink 會長出亂碼 ghost 節點)。

> 源起:CLI 核心非日報觸發。

## 七個原語(對應 `cmd_*`)
| 指令 | 結構層 | 做什麼 |
|---|---|---|
| `set <node> <key> <value>` | 純量 | 改 `SCALAR_KEYS`={status,updated,created,type,self_audit,signed_off,regen};行級手術最小 diff |
| `append <node> <key> "[[x]]"` | list | 追加 `LIST_KEYS`={verified_by,plan_refs,related,tags};鐵則1 安全格式 + `link_target` dedup |
| `self-audit <node> [--model][--date]` | 純量 | 寫 `self_audit: <model>/<date>` 節點級自足性審計戳記(內部即 `set self_audit`) |
| `decision-add <node> "<content>" --decided DATE [--context][--why]` | 巢狀 | append 一條 ADR 決策(無 `decisions:` 則在 fm 末尾建) |
| `decision-supersede <node> "<content子字串>" --by "..." [--ended DATE]` | 巢狀 | 把該條決策標 `valid:false` + 補 `superseded_by`/`ended` |
| `new <type> <name>` | 建檔 | 依 `TEMPLATES`(system/verification/issue/project)建檔 + 印「寫入當下教學」(符號行/合約鏈) |
| `archive <days> [--apply]` | 移檔 | 滾動歸檔老 Verification(另見 `cmd_archive` 的「活守衛護欄」邏輯) |

`new`/`archive` 嚴格說是建檔/移檔而非 fm mutation;前五個(set/append/self-audit/decision-add/decision-supersede)才走 `atomic_write_verify`。

## T1 寫後自驗 atomic(核心不變式)
所有 frontmatter mutation 都經 `atomic_write_verify(path, new_lines, key, expected_check)`:
1. `load_raw_for_edit` 讀 raw bytes,**拒 BOM、拒 CRLF**(vault 慣例 LF/no-BOM,異常不靜默正規化,報錯指路 `.gitattributes`/`dos2unix`)。
2. 改完後 re-parse 新 frontmatter,跑 `expected_check(fields)` 斷言**該 key 真的寫成目標值**(decision 類會 `parse_decisions` 重解確認 valid/superseded_by)。
3. 比對 lint 指紋:`set(new_lint) - orig_lint` 必須為空——**不准引入新的 frontmatter 指紋**。
4. 上述全過才 `_write_lf` 寫 `.lumos-tmp` → `os.replace` 原子換入;任一步丟 `RuntimeError`,tmp 丟棄、**原檔零變動**。

`_write_lf` 是 vault 唯一寫入原語:`write_bytes` 強制 UTF-8/LF/no-BOM,平台無關(不靠 text mode、不需 Python 3.10 的 `newline=`)。

## 格式鐵則由原語結構性保證(不靠人手)
鐵則完整清單(鐵則2/5 等)在 `CLAUDE.md`;本節點只處理寫入相關鐵則(1/3/4)。

- **鐵則1(多 wikilink 必 YAML list)**:`append` 天生一項一行寫 list,用 `link_target` 比對 dedup,絕不字串串接多個 `[[]]`。
- **鐵則3(含「: 」長文引號化)**:`_fmt_decision_value` 對含 `: `/特殊起首字元的值自動加引號;summary 走 block scalar。
- **鐵則4(日期 bare 不加引號)**:`fmt_scalar` / decision 子欄位格式化保持日期裸值;`--decided`/`--ended`/`--date` 先過 `DATE_RE`/`fromisoformat` 校驗,非 `YYYY-MM-DD` 直接拒。

## 機器層 vs 專案層分工
這組原語只動**專案層**圖譜檔(`docs/<slug>-knowledge/`);與機器層(`install`/`uninstall` 動 `~/.local/bin`、user-scope skills)、生命週期(`bootstrap`/`update`/`init`/`deinit`)正交。

## 已知限制
- decision-* 要求 **2-space 標準縮排**;0-indent / tab 縮排的 decisions 區塊報錯、不自動處理。
- `decision-supersede` 對**已 superseded**(同層已有 `superseded_by`)的決策拒絕重插,避免重複鍵;要改取代者需手動編輯。
- BOM/CRLF 檔一律拒寫,需先正規化行尾(走 obsidian CLI 或 `dos2unix`)。

## 相關
- 操作表:`lumos-project-notes` skill SKILL.md(寫入原語表 + obsidian fallback 對照)。
- 鐵則總綱:`CLAUDE.md`(純量/list/decisions 一律走 lumos,別手改 frontmatter)。
- 實作落點:`scripts/lumos` `cmd_set`/`cmd_append`/`cmd_self_audit`/`cmd_decision_add`/`cmd_decision_supersede`/`cmd_new`/`cmd_archive` + `atomic_write_verify`/`load_raw_for_edit`/`_write_lf`。
- 回歸測試:`scripts/test_lumos.py` `t_set_*`/`t_append_*`/`t_decision_*`/`t_archive_*`/`t_new_*`。
