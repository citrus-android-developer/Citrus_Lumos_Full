---
type: project
status: done
created: 2026-07-21
updated: 2026-07-21
signed_off: 2026-07-21
tags:
  - type/project
  - status/done
related:
  - "[[Projects/全盤外審2026-07_調研]]"
  - "[[Systems/lumos-cli-read]]"
summary: |-
  FLAG:DECISION
  KEY:問題=規範禁直接 Read/Grep 架構圖(lumos-project-notes skill),但 lumos 無全文讀取指令——context 只給 summary 壓縮索引不含 body(scripts/lumos:3717 docstring 自述),agent 要讀完整決策理由只能違章(外審 blocker,見[[Projects/全盤外審2026-07_調研]] finding 2)
  KEY:解=新增唯讀 `lumos show <node> [--body-only]`——輸出節點檔完整內容(frontmatter+body);--body-only 略過 frontmatter 只印 body。分工:context=低 token 導航,show=完整真相讀取。stdlib 薄介面,非新治理層
  KEY:實作錨=掛既有名稱解析派發組(scripts/lumos:9656 的 links/backlinks/context/map 組,env.find 解析、找不到 stderr ERROR+rc2)——不造新解析路徑;show 同時寫 _usage_log(env,rel,"show")(三位置參數,對齊 scripts/lumos:3704 簽章與 :3721 呼叫慣例;r1 折入:原引用抄丟 env)
  KEY:★實作陷阱三條(r1 審計折入)★——①派發組尾行是**無條件** `return cmd_decisions(env,rel)`(scripts/lumos:9670),只把 "show" 加進 tuple 忘插 if 分支=靜默印出 decisions;必須在該行前插 `if args.cmd=="show": return cmd_show(...)` ②argparse 位置引數**必須命名 note 非 node**(:9658 getattr(args,"note")、:9660 裸 args.note 無保護,命名 node 會 AttributeError crash;codebase 有 note/node 兩套並存慣例,本組用 note) ③--body-only 開檔須 **utf-8-sig**(loader :195 慣例;show 是首個原樣吐全文的指令,一般 utf-8 會把 BOM 印進輸出)
  KEY:範圍刀=不做 --at <git-sha>(git show 已覆蓋歷史版本)/不做 --json/不做多節點批次;lumos-project-notes skill 補一行「讀 body 用 show」(解禁章的成文出口)
  KEY:架構圖同步義務(r1 折入 F8;r2 擴列散落面)——同一 commit 須帶:[[Systems/lumos-cli-read]]「12」至少 5 處+「23」算式全改+cmd_show 入清單、skills/lumos-project-notes/reference.md:85 獨立總表(r2 Codex C2:「44」本身陳舊、現行實 48,+show=49/讀取12)、README.md:42(44→49,C2 補列)、lumos-cli-read **全節點**零副作用宣稱**六處**(:11 FLOW/:12 KEY/:24+:27 d1/:58 共同地基/:78 全純讀)修 A2 漂移(C1;r3 Codex 擴列+r4 opus 輪補全;措辭限定 context/show 寫 usage-log+doctor --ci 寫 governance-log+其餘純讀——概括除外會謊稱全部,r4 終局 Codex 再收一格)、Verification 節點(plan_refs 回指)——pre-commit Gate 3 對 test_lumos.py(.py 命中 code regex)要求同 commit 架構圖檔,天然滿足;原版只列一處=正中「知識同步散落會漏」病灶
  KEY:light 檔資格自核(M0 honor-system)——硬否決三訊號:①風險類:唯讀指令,四類風險面皆不涉 ②硬合約:不動任何 invariant 級合約(純新增讀取口) ③體積:預估 ~40 行 code+測試,50 行先驗內、孤立 → light 放行。⚠自核時 pitfalls --check 對本段「引用風險類名稱」關鍵字誤報全四類——honor-system 下人工判掉;此發現餵 [[Projects/design-loop輕量檔_計劃]] M1(機械化硬否決須剝自核段,同 risk-tiered assess_spec 黑名單剝除前例)
  DECISION:[2026-07-21]走 light 路徑(M0 首戰,pre-flight+1 通才席+legacy --need 1+人裁)→r1 存活 4 major,**ratchet 已觸發、升 standard**(W=3 panel,loop id lumos-show讀取入口-std 承接;r2 修正:本行與審計紀錄結論同步,原「審計中」進行式誤導下一棒走錯路徑)
  TEST:t_show 計畫覆蓋(八項,與 body 測試策略同單,r1 折入 F5 對齊、r2 增 7-8):找到(rc0 全文含 frontmatter)/找不到(stderr+rc2)/--body-only(無 frontmatter 鍵行)/模糊名解析(沿 env.find)/show 不改檔(唯讀)/派發組迴歸/重開檔失敗(stderr rc2 無 traceback)/無 frontmatter 檔 --body-only 印整檔
  DEP:[[Projects/全盤外審2026-07_調研]]｜scripts/lumos env.find/派發組
  PRIOR-ART:①最小解=既有派發組掛一個子指令+檔案讀取,無新機制 ②世界解=全文讀取是 notes-CLI 普適原語(cat 級),無需深搜;r2 修正:原引 Spec Kit persistence 警告係外審 finding 1(雙真相)的證據、非本題,張冠李戴已除 ③裁定=borrow-design(cat 級功能原生實作)
verified_by:
  - "[[Verification/2026-07-21_lumos-show讀取入口]]"
---
# lumos-show讀取入口_計劃

> **狀態**：light 首戰 r1 觸發 ratchet **已升 standard**，現於 W=3 panel 審計中（loop id `lumos-show讀取入口-std`；r2 修正：頂部狀態與審計紀錄結論同步）。緣起：外審 finding 2（blocker）——規範禁直接 Read 架構圖，但 lumos 沒有全文讀取入口，結構性逼 agent 違章。
>
> **light 資格與審計路徑（frontmatter KEY 的 body 鏡像，r1 折入 F6）**：硬否決三訊號自核（風險類不涉／不動 invariant 級合約／~40 行孤立）→ 走 light：pre-flight＋1 通才席＋canary 護＋`--need 1`＋人裁實質收斂；**存活 ≥major 即 ratchet 升 standard 完整 panel**。自核時 `pitfalls --check` 對「引用風險類名稱」的段落誤報全四類（關鍵字迴聲）——honor-system 人工判掉，發現已餵 M1。

## 問題

`lumos-project-notes` skill 禁止直接 Grep/Read vault、指定以 `context` 進場；但 `cmd_context` 是「summary 壓縮索引」（scripts/lumos:3717 docstring 自述），只輸出 metadata/summary/合約/鄰居，**不輸出 body**。agent 要讀完整決策理由（decisions 全文、章節內文）就只能違反規範。今天實際發生：本會話讀 `design-loop提效_計劃` body 時 `lumos show` 不存在、只能退回 Read——當場踩坑。

## 規格

- **指令**：`lumos show <node> [--body-only]`（CLI 顯示名 `<node>`；**argparse 位置引數內部必須命名 `note`**，見下方陷阱②）
- **行為**：解析節點名（沿用既有 `env.find`，掛 scripts/lumos:9656 的 `links/backlinks/context/map` 派發組）→ 印該節點檔完整內容（frontmatter + body）到 stdout。
  - `--body-only`：略過 frontmatter 區塊（**只認檔案開頭**首個 `---` 對到第二個 `---`），只印 body；開檔用 `utf-8-sig`（陷阱③）。
  - 找不到節點：沿組內慣例 `ERROR: 找不到筆記: <名>` 到 stderr、rc 2。
  - **重開檔失敗（r2 折入，S2-F2）**：`env.find` 解析成功≠檔案此刻可讀——`load_vault` 對讀檔失敗節點（壞符號連結/權限錯/race 刪檔）**照樣收進 notes dict**（scripts/lumos:196-199，`n.lint=["讀檔失敗:…"]`），且 `Note.__slots__` 不存 body（:182），show 必然重開檔。重開失敗必須 try/except → `ERROR: 讀檔失敗: <rel>: <e>` 到 stderr、rc 2——嚴禁裸 traceback。
  - **frontmatter 剝離掛既有函式（r2 折入，S2-F5）**：`--body-only` 剝離**必須複用 `split_frontmatter()`**（scripts/lumos:95 起，逐行比對 `---`，非子字串搜尋）、不重造——body 內 `|---|` 表格分隔列才不會誤觸；**無 frontmatter 的檔** → `split_frontmatter` 回 `(None, text)` → `--body-only` 印整檔（此即規格）。
  - 模糊名：`env.find` 既有解析行為（多筆命中 stderr 警告取第一筆，scripts/lumos:287-299），不另造。
  - 唯讀（r2 Codex 否決折入，措辭修正）：**不改任何架構圖節點檔**；寫一筆 best-effort usage-log 事件帳（`_usage_log(env, rel, "show")`，簽章 scripts/lumos:3704、appends `docs/.usage-log.jsonl`——同 `context` :3721 既有行為）。原「不寫任何檔」與 usage_log 自相矛盾（Codex C1）；且 [[Systems/lumos-cli-read]] d1「全程不寫檔」合約自 A2 事件帳（2026-07-11）起已與現實漂移——本案一併修合約措辭（見架構圖同步 4）。**裁量偏離記錄**：Codex 建議移除 show 記帳；編排者選保留＋修合約，理由：漂移因 context 既有行為本就得修，修後 show 跟進零額外成本、保住 context:show 比例觀測值。業務層留人簽核。
- **實作陷阱三條（r1 審計折入，照抄會炸）**：
  1. 派發組尾行是**無條件** `return cmd_decisions(env, rel)`（scripts/lumos:9670）——把 `"show"` 加進 tuple 後**必須**在該行前插 `if args.cmd == "show": return cmd_show(...)` 分支，否則 `lumos show` 靜默印出 decisions（rc0 無錯誤）。
  2. 位置引數命名 **`note`**（非 `node`）：:9658 `getattr(args, "note", ...)`、:9660 **裸** `args.note` 無保護——命名 `node` 會讓所有 show 呼叫 AttributeError crash。codebase 有 note/node 兩套並存慣例（gov/spec-trace 用 node），本派發組是 note 套。
  3. `utf-8-sig` 開檔：loader 慣例（scripts/lumos:195，BOM 容錯）；show 是首個「原樣吐出全文」的指令，一般 `utf-8` 會把歷史 BOM 檔的 `﻿` 印進輸出。
- **skill 同步**：`lumos-project-notes` SKILL「禁直接 Read」段補一行成文出口——「需讀節點完整 body（決策全文/章節內文）→ `lumos show <node>`；context 仍是進場導航首選」。
- **架構圖同步（r1 折入 F8；r2 擴列散落面 S1-F4+S2-F3 合併——「12」不是一處是一片）**：同一 commit 必帶：
  1. `Systems/lumos-cli-read`——「12」在節點內**至少 5 處**（summary KEY 行/decisions d1/`## 12 個原語` 標題/body 散文/「23 子命令=讀 12+寫 7+生命週期 4」交叉算式），全部 12→13、23→24，`cmd_*` 清單補 `cmd_show`；
  2. `skills/lumos-project-notes/reference.md:85`——**獨立的另一份**頂層命令總表。⚠ **r2 Codex 否決修正（C2）**：「44」本身已是陳舊數字——現行 argparse 實有 **48** 個頂層命令（總表漏列 `decision-reindex`/`rel-cascade`/`test-layers`/`lint-check`），加 show 應改 **49**、讀取/導航 11→12；落地時一併修真（原 spec「44→45」會把錯數字刻進權威文件）；
  3. `README.md:42`——「44 個頂層命令」同為陳舊硬編碼（Codex C2 補列），一併 →49；
  4. `Systems/lumos-cli-read` **全節點零副作用宣稱一併改寫（r3 Codex 復核擴列；r4 opus 輪補全）**：**六處**——:11 FLOW「各 cmd_* 純讀印出」（r4 S2-F2 補）、:12 summary KEY 行、:24＋:27 d1 決策（content＋why_chosen 兩行）、:58 共同地基、:78「這 12 個全純讀」——全部修為「**不改架構圖節點檔；context 與 show 寫 best-effort usage-log 事件帳（A2，2026-07-11 起）；doctor --ci 視 findings 寫 governance-log（:416 寫者自述）；其餘讀指令純讀**」語意（末句 scope 為 r4 終局 Codex 折入——原「其餘純讀」對 doctor --ci 仍是假話）。⚠ scope 精確（r4 S1-F2）：概括寫「usage-log 除外」會謊稱 13 個讀指令全寫帳——實查全庫僅 `cmd_context`（:3721）呼叫 `_usage_log`，措辭必須限定 context/show 兩個。另 `Projects/檢索優化_計劃:269` 有同宣稱，屬論證此邊界的討論節點非權威合約，不入同步清單（r4 S2-F4 context）。修的是 A2 起即存在的合約漂移，非為 show 開新特權；
  5. Verification 節點（`plan_refs` 回指本計劃）。
  此條正中「知識同步散落會漏」的已知病灶——枚舉寫死在 spec，實作照單掃，不靠記憶。pre-commit Gate 3 對 `test_lumos.py` 變更要求同 commit 架構圖檔——上列天然滿足。
- **CLI help**：`sub.add_parser("show", help="節點完整內容(frontmatter+body;--body-only 略 frontmatter)")`。

## 明確不做（範圍刀）

- `--at <git-sha>` 歷史版本：`git show <sha>:<path>` 已覆蓋，不重造。
- `--json` 結構化輸出：context 已有 as_json 導航用；show 是給人/agent 讀全文的，YAGNI。
- 多節點批次 show：逐個呼叫即可。

## 測試策略（t_show，八項，與 frontmatter TEST 行同單）

1. 找到節點 → rc0、輸出含 frontmatter `---` 與 body 標題行。
2. 找不到 → stderr 含「找不到筆記」、rc2。
3. `--body-only` → 輸出不含 frontmatter 鍵行（如 `type:`）、含 body 內容。
4. 模糊名 → 沿 `env.find` 既有行為（多筆命中 stderr 警告、取第一筆）。
5. 唯讀驗證 → show 前後節點檔 mtime/內容不變。
6. 派發組迴歸 → context/links 既有行為不受影響（既有測試不紅）。
7. 重開檔失敗（r2 折入）→ vault 載入後刪掉節點檔再 show → stderr 含「讀檔失敗」、rc2、無 traceback。
8. 無 frontmatter 檔 `--body-only`（r2 折入）→ 印整檔（`split_frontmatter` 回 `(None, text)` 語意）。

## 實務隱患

- **frontmatter 邊界剝離**：`--body-only` 對「無 frontmatter 的檔」「body 內含 `---` 分隔線」要正確——剝離只認檔案開頭第一組 `--- ... ---`，不掃全文。
- **usage_log 副作用**：show 寫用量記帳（append `docs/.usage-log.jsonl`，git tracked——正常執行會弄髒 worktree，Codex C1 實證）不算「改架構圖節點」——與 context 同慣例；測試 5 的「唯讀」**明定只斷言節點檔不變、usage-log append 為預期副作用**（r2 修正 S2-F4：4→5；C1：防測試 5 對副作用假通過）。
- **編碼（r1 修正 F7）**：show 是首個「重新開檔、原樣吐全文」的指令——**不是**其他 cmd 已處理的同路徑（它們只印已解析的 fields）。開檔必須 `utf-8-sig`（loader :195 同慣例），否則歷史 BOM 檔會在輸出頭多印不可見 `﻿`。

## 審計修正紀錄

**r1（2026-07-21，light 通才席首戰，sonnet×1）**：canary=summary↔body rc 矛盾型（TEST 行 rc1 vs 規格 rc2；probe 紀律偏離記錄：同窗重植×2 皆被 haiku 抓 → 改植入拓撲跨 frontmatter/body，r4 probe pass——**小 spec 的 ±20 行 probe 窗≈半份 spec，協議失準，發現已餵輕量檔計劃 M0 數據**）→ **caught**（審計員精準點出性質＋全庫 rc2 慣例佐證）。真 findings 7 條全折入 v2：
- **F2 派發組無條件 fallback（major，機械證實免辯方）**：:9670 `return cmd_decisions` 無守衛——必須插 if 分支，否則 show 靜默印 decisions。
- **F3 note/node 命名陷阱（major，機械證實）**：:9660 裸 `args.note`——引數必須命名 note。
- **F4 `_usage_log` 簽章抄錯（major，機械證實）**：spec 原文丟了 `env`，照抄必炸 TypeError。
- **F8 架構圖同步義務漏列（major）**：test_lumos.py 命中 pre-commit code regex，Gate 3 要求同 commit 架構圖檔；spec 原版只列 skill 同步（不在 knowledge 路徑下）＝首 commit 被自家 gate 擋。折入：同 commit 帶 lumos-cli-read 12→13＋Verification 節點。
- **F6 自核內容無 body 鏡像（審計員評 major→編排者按 severity 錨降 minor，理由：文件鏡像精度、非錯行為；照折）**：body 補 light 資格鏡像段。
- **F5 測試單 frontmatter/body 不一致（minor）**：統一六項。
- **F7 BOM 新風險面（minor）**：「無新風險」宣稱被駁——show 是新路徑，須 utf-8-sig。
- **輪判定**：canary caught；存活 max=major（F2/F3/F4/F8）→ **按 M0 ratchet 規則升 standard，r2 起走完整 panel（W=3）**。

**r2（2026-07-21，standard panel r1，loop id `lumos-show讀取入口-std` 承接 ratchet；W=3：sonnet 通才＋sonnet 邊界/整合＋Codex 否決席）**：canary slot1=b 型（憑空旗標「plain」，probe：植定義行同片段被抓→重植審計紀錄段 pass）✓ 精準抓（grep 全庫證無）；slot2=c 型（憑空截斷常數「TRUNC 位元組上限」）✓ 抓到且挖出反先例（全庫唯一 precedent 是 4KB 拒絕非截斷，:5030）。**caught 2/2、0 missed=輪有效**。真 findings 去重 6 條折入 v3：
- **S2-F2 重開檔失敗路徑未定義（major，機械證實 :196-199 編排者自核）**：load_vault 容忍讀檔失敗節點照進 notes dict＋Note 不存 body 必重開檔——照 spec 字面實作對壞連結/race 刪檔裸 traceback。折入：try/except→stderr rc2＋測試 7。
- **S1-F4＋S2-F3 架構圖同步散落面（合併，major——graph-sync 屬合約級義務）**：「12」在 lumos-cli-read 至少 5 處＋23 算式＋reference.md:85 獨立總表（44/讀取 11）——spec 原列「12→13 一處」嚴重低估，正中「知識同步散落會漏」病灶。折入：枚舉寫死。
- **S1-F1 頂部狀態與 ratchet 結論矛盾（審計員評 major→編排者按錨降 minor，理由：loop 過程記帳非實作行為；但認下一棒誤導風險，即修）**：狀態行/DECISION 行同步「已升 standard」。
- **S1-F3 PRIOR-ART 引據張冠李戴（minor）**：Spec Kit 引用屬外審 finding 1 證據，非本題——改誠實版（cat 級普適原語）。
- **S2-F4 測試指標未跟重排（minor）**：usage_log 段「測試 4」→「測試 5」。
- **S2-F5 剝離未指定複用 split_frontmatter（minor）**：明定掛 :95、無 frontmatter 檔 --body-only 印整檔＋測試 8。
- **Codex 否決席判決（gpt-5.6-sol high，讀 live v3，133k tokens）：VETO，2 major，全數證實折入 v4**：
  - **C1 show 非唯讀且撞讀側合約（major）**：spec「不寫任何檔」與 usage_log 自相矛盾；`.usage-log.jsonl` 為 git tracked（`git ls-files --stage` 實證），正常執行弄髒 worktree；[[Systems/lumos-cli-read]] d1「全程不寫檔」被違反——**實為 A2（07-11）起的既有合約漂移（context 已在寫），本輪 loop 順手抓到**。折入：措辭修正＋合約同步義務＋測試 5 防假通過。裁量偏離：Codex 建議移除記帳，編排者選保留＋修合約（理由記錄於規格段），業務層留人。
  - **C2 同步算術仍錯＋漏 README（major）**：reference.md「44」本身陳舊——現行實為 48（漏 `decision-reindex`/`rel-cascade`/`test-layers`/`lint-check`），+show=49 非 45；README.md:42 同病。折入：數字全修真＋README 入同步清單。
  - Codex 同時複核：三條陷阱/重開檔/split_frontmatter/lumos-cli-read 12→13/pre-commit Gate 全部與現碼吻合（跨家族背書）。
- **r2 輪判定**：canary 2/2 caught、0 missed=輪有效；distinct findings 7（同步散落 cluster 三席互證，其餘單席）；**存活 max=major → fold 後下一輪 delta-scoped**。

**r4（2026-07-21，delta 重審輪，opus×2 升級席（護欄觸發），canary 植 diff hunk 內）**：slot1=c 型（憑空錯誤訊息長度常數＋憑空「截齊」慣例）✓ **完美抓**（grep 全庫 0 命中＋反先例 :5030 拒絕非截斷＋工作包/真檔落差三重證據）；slot2=d 型（憑空勾稽帳檔名）✓ **完美抓**（grep 0＋git ls-files 無＋直接判讀「極可能是本輪 canary」）。**caught 2/2、0 missed=輪有效**。真 findings 4 條全 minor 折入 v6：
- **S1-F2 合約措辭 scope 過寬（minor）**：「usage-log 除外」概括會謊稱 13 個讀指令全寫帳——實查僅 cmd_context 呼叫；措辭限定 context/show。
- **S2-F2 零副作用宣稱實為六處（minor）**：:11 FLOW「純讀印出」漏列——item 4 自己立論「只修兩處自造漂移」卻漏第六處。
- **S2-F3 frontmatter 四處 vs body 五處鏡像差（minor）**：統一為六處。
- **S2-F4 檢索優化_計劃:269 同宣稱（context）**：討論節點非權威合約，註明不入清單。
- **r4 輪判定：輪有效＋存活 max=minor（全文件精度級）**。
- **r4 終局 Codex**：六處枚舉完整 ✓；措辭再收一格（doctor --ci 寫 governance-log，:416 寫者自述）——照其原句逐字折入，異議按其自開條件成立即解。

**實質收斂裁定（2026-07-21，使用者）**：cap 3 輪到頂＋r3(帳面)輪有效＋存活全文件精度 minor＋全數已折——capture-recapture 殘餘卡門屬已知結構病（singleton findings 壓不到底，M2 cluster 帳為此而生但本 loop 定錨無-cluster 模式）。**人裁實質收斂放行，進實作**。C1 業務簽核（保留記帳）尚待使用者明示。

**r3-前置（2026-07-21，delta 輪 r2 無效＋Codex 復核）**：delta 輪 sonnet×2 **canary 0/2 全 missed=輪無效**（d 型裸檔名/a 型壞節引用皆植於編排者爭議清單——驗了同行 README 卻放過憑空 json/鏡頭即一致性仍漏）→ **兩席 findings 全剔除不折**（判決不採信）；護欄觸發（連 2 筆 missed）→ r3 升 opus。偏離記錄：canary 植 briefing 非受審物、相關性弱，r3 改植 diff hunk 內（協議缺口回饋 M1）。**Codex 復核（46k tokens）：C1 解除（接受保留記帳裁量：副作用已明揭露、非新增行為類型）、C2 解除（獨立重數 argparse=48、+show=49 算術確認）、新 major：同步義務漏 :12 summary KEY 與 :78「全純讀」——只修 d1+共同地基會自造新鏡像漂移（此即被剔除的 slot2 finding 之跨家族獨立再發現——missed 席真 finding 從可信通道浮回,機制自證）→ 折入 v5（同步義務擴為全節點零副作用宣稱）。VETO 維持至 v5 落地。**
