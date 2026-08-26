# 設計:lumos refcheck — spec 指涉宣稱的確定性核對 + 證據 manifest(spec-refcheck)

- 日期:2026-07-02
- 狀態:design-approved(2026-07-02 人裁放行)
- 收斂紀錄:design-loop 3 輪收斂(canary 3/3 caught、R2+R3 連兩好輪;dry-run 於 /tmp scratch,canary 紀錄以 orchestrator log 為證)。qwen 跨家族複核 reject×2 → disputed 留人裁:其 5 條 ≥major 指控經 python/sed 機械實測 0/5 成立(典型:F2 宣稱 `_suffix_re` 誤匹配 `file:123:extra`,實跑 token/suffix 剝離行為正確),真 minor 8 條已全折入;人裁判定否決不成立、放行。此案例本身即本 spec 動機的現場實證(LLM 評審地面事實查證不可靠、確定性比對秒裁)。
- 動機來源:2026-06-23 治理日報 gap「design-loop 與跨家族複核最吃重的『地面事實查證』,正是 AI 評審最不可靠的能力(<55%)」;建議「能用 grep/diff/存在性死板核對的證據檢查,改成確定性比對,LLM 只判 grep 查不到的業務正確性」。
- loop_id:spec-refcheck

## 目標(一句話)

新增 vault-free 指令 `lumos refcheck <md檔> --repo <root>`:**確定性**抽取 spec 裡的指涉宣稱(inline-code 檔路徑 + `:行號`),機械核對「檔在不在、行號在不在範圍內」並輸出**證據 manifest**(含實際行內容摘錄);design-loop 與跨家族複核把「存在性/位置」這片查證從 LLM 手裡拿走——**auditor/judge 只剩 grep 查不到的語意正確性要判**。

## 方案評比與選擇(brainstorm,2026-07-02)

| 方案 | 內容 | 判定 |
|---|---|---|
| **A(選)** | `lumos refcheck` 確定性核對器:抽 spec 指涉宣稱→機械驗存在/行號→產 manifest,餵 auditor(免驗存在)、judge(免評存在性查證)、cross_audit(ground_truth 機械核心) | **選**:複用 Check P 已收斂的抽取機械(`scripts/lumos:749-786`;僅 step 1-2 抽取與過濾,去重粒度刻意分歧、見抽取規則 step 3),一個原語買三個消費端;確定性、可測、零第三方依賴 |
| B(否決) | 結構化證據協議:auditor 輸出機器可讀查證指令(JSON),orchestrator 逐條重執行 | 否決 v1:重執行 LLM 產的指令=命令注入面;且只驗「auditor 說的那幾條」,漏報不可見。v2 可在 A 的 manifest 基礎上做白名單重執行 |
| C(否決) | 純 prompt 加碼:要求 auditor 列更多查證行、judge 更嚴查 | 否決:查證行是 LLM 自報,加碼不改變 <55% 的能力地板——gap 指名要脫離的正是這個 |

## 前提與既驗事實(逐字查證,2026-07-02)

- **auditor 的地面查證是 LLM 自報**:`governance/autonomous_loop/orchestrator-prompt.md:36` 要 auditor「強制地面事實查證(spec 每個現況假設——欄位/函數/檔案/常數——實際 grep/Read 驗…報告列查證指令與結果)」——查了沒、查得對不對,無人機械複核。
- **judge 的存在性閘也是 LLM 判**:同檔 `:37`「唯有『對最嚴重 finding 無任一 grep/Read 查證行』才至少 major(客觀二值)」——判「有沒有查證行」是 judge 讀文字,非機械 count。
- **cross_audit 的 ground_truth 由編排者自取材**:§2.5a「把本 spec 引用到的真實檔案/符號 grep/Read 出來…整理成 ground-truth 片段」;run_cross_audit(spec_text, canary_log_path, loop_id, ground_truth, ...)(`governance/autonomous_loop/cross_audit.py:62`)只把 ground_truth 當字串塞進 prompt(`:79`)——取材忠實度/完整度無機械保證,是編排者(利害關係人)自填。
- **Check P 已有確定性抽取機械**:`scripts/lumos:749-786`——INLINE_CODE_RE.findall(FENCE_RE.sub("", text)) + strip 反引號(`:761`)、`_suffix_re` 剝行號(`:754`)、`://`/萬用字元跳過、須含 `/`、首段錨定 repo 頂層目錄、exists() 核對。regex 常數在 `scripts/lumos:39-40`(FENCE_RE/INLINE_CODE_RE)。
- **vault-free 指令有先例**:`scripts/lumos` main() 對 install/bootstrap 在建 vault Env 前分流(`scripts/lumos:3715`、`:3721`)——refcheck 同型:吃顯式檔案+repo 參數,不需 `--vault`。
- **手動版同構**:`skills/lumos-design-loop/SKILL.md` 步驟 3-4(派審計員/判讀)與 orchestrator-prompt §2 步驟 3-4.5 動作對稱、step 號各異(finding-refute spec 已正名)。

## 範圍:refcheck 指令規格

**CLI**:`lumos refcheck <md檔路徑> [--repo <root>] [--json]`,vault-free(不需 `--vault`,同 install/bootstrap 分流)。`--repo` 省略時以 cwd 起**逐層向上**(`Path.cwd()` 及其 parents,至檔案系統根為止)找最近含 `.git/` 的目錄;走到根仍無 → rc 2 + 錯誤訊息(不猜)。此為新行為(cross-r1-qF3):repo 自動發現無既有 code 可複用,stdlib 數行實作,「沿用既有」只指抽取規則、不含此段。

**抽取規則(沿用 Check P,`scripts/lumos:761-777` 同款,不另發明;連帶依賴 `_suffix_re` 定義 `:754` 與 `top_dirs` 初始化 `:753`,cross-r1-qF1/r3-F3)**:
1. 先 FENCE_RE 剝 fenced block,再 INLINE_CODE_RE 取 inline-code span、剝反引號定界符。
2. 每個 span,依 code 實際順序(r2-F4):**先**跳過含 `://` 或萬用字元 `*<>?` 者(`scripts/lumos:764`);**再**剝尾端 `:suffix`(token 一律剝去;suffix 全數字或 `N-M` 才記為行號,否則行號留空,`:766-771`);**須含 `/`**(`:772`);首段須是 `--repo` root 的現有頂層目錄(成員檢查 `:774`;top_dirs 只收目錄且排隱藏,初始化 `:753`)。
3. 同檔以 **`(token, line)` 組合**去重(seen 集合以 `(token, line)` tuple 為鍵;r3-F1:**不沿用** Check P 的 token 級去重——`scripts/lumos:772/:776` 以剝行號後 token 為鍵,同檔多行號引用會塌成一條;refcheck 的 manifest 粒度是 per-(token,line),`line_out_of_range`/excerpt 都掛在行號上,此為 refcheck ≠ Check P 的**關鍵分歧點**,「同款」僅指 step 1-2 的抽取與過濾)。

**核對與 manifest(新增,Check P 沒有的部分)**:
- 每條宣稱 → `{token, line, status, excerpt}`(`line` 為字串:單行 `"39"`、範圍保留原字面 `"2-4"`、無行號 `""`,cross-r2-F20):
  - `missing`:repo 下該路徑不存在。
  - `line_out_of_range`:檔在、但行號 N(或 N-M 的 M)> 檔案總行數。
  - `ok`:檔在;有行號則 excerpt = 該行(或範圍首尾各 1 行,中間省略)實際內容;無行號 excerpt 留空。
- **目錄型 token(r3-F4)**:`(repo / token)` 存在但是目錄 → status=ok、行號視為不適用(不做 out_of_range 判定、excerpt 留空、manifest 註 `dir`)——**不把目錄當檔案讀**。
- 輸出:人讀版(逐條 + 統計)與 `--json`(`{"claims":[...],"missing":N,"out_of_range":N,"ok":N}`)。
- **rc**:全 ok → 0;有 missing 或 out_of_range → 1;參數/repo 解析失敗 → 2。

## 三個消費端整合

### ① orchestrator-prompt §2:步驟 3 前插「機械核對」

新步驟(2.8,植 canary 後、spawn auditor 前,對**工作副本**跑):
- `lumos refcheck <工作副本> --repo <REPO> --json` → missing/out_of_range 宣稱=**機械 finding**:orchestrator 直接修正原稿 spec(**偵測**確定性無爭議;**修成什麼**是編排者判斷,故必須記入審計修正紀錄、標「機械 refcheck」留痕,且修正會被後續輪 auditor 重審——收斂輪的修正則由 §2.5 cross_audit 讀最終原稿覆蓋,r1-F4 殘餘窄縫)。
- manifest(ok 宣稱 + excerpts)**附進 auditor prompt**:「以下指涉宣稱的存在性/行號已機械驗訖,不必花查證力氣在『在不在』;你的地面查證聚焦**語意**——spec 對這些位置的描述、欄位/函數行為的宣稱,對不對」。
- judge prompt 同附 manifest + refcheck rc:「存在性由機械 refcheck 保證;『查證行』閘只計語意查證」。

### ② orchestrator-prompt §2.5a:ground_truth 機械核心

取材改為:**refcheck manifest 為必含底座**,編排者再補語意片段(函數體、欄位定義等),**不得刪減 manifest 部分**——把「編排者自填 ground_truth」收窄成「機械底座 + 補充」。**誠實標示底座的薄度(r1-F5)**:manifest 對無行號宣稱只有存在性(excerpt 空)、有行號者也只是孤立單行——它保證的是「引用座標經機械核對」,**不是**充分的語意 ground-truth;cross_audit prompt 欄位叫「真實代碼片段」,語意份量仍主要來自編排者補充段。run_cross_audit 簽名不動(ground_truth 仍是字串,只是來源規範化)。**守衛強度(r3-F5,同 §canary 誠實慣例)**:「不得刪減」是 orchestrator-prompt 散文規範、無機械強制——編排者仍可能漏貼;v1 接受(manifest 同時附給 auditor,漏貼可被對照發現),機械拼接(cross_audit 直接吃 manifest 檔)留 v2。

### ③ skills/lumos-design-loop/SKILL.md:步驟 3 前同款

手動版同構插入:派審計員前先 refcheck 工作副本、missing 直接修、manifest 餵審計員。措辭對齊 ①(動作對稱、step 號各異,同 finding-refute 慣例)。**canary (d) 型注意(r1)**:手動 loop 的第 4 型 canary(未定義產物/檔名)須**保持裸檔名**(如 `xxx.json`,勿帶 repo 路徑)——裸檔名無 `/`,天然在 refcheck 抽取域外(`scripts/lumos:772` 同款規則),canary 防線不受影響;SKILL.md 同步時把這句寫進 canary 校準規則。

## canary 相容性(關鍵設計約束,不可違反)

refcheck **只驗 spec→repo 指涉,刻意不驗 spec 內部一致性**(§ref 存不存在、`--旗標` 它處有無定義、ALL_CAPS 有無值)。理由:canary a/b/c 全是 spec 內部瑕疵——若 refcheck 把它們機械抓掉,auditor 看 manifest 就能「抓到」canary,canary 從此量不到「審計員有沒有醒著」,整條 test-the-tester 防線報廢。**spec 內部一致性=canary 的保留地=審計員的責任田**,這是邊界,不是 v1 偷懶。**守衛強度誠實聲明(r2-F3)**:消費端 ③ 的「(d) 型保持裸檔名」是**散文規範、無機械強制**——未來植入者若寫帶路徑產物名(如 `configs/foo.json`),canary 仍會被 refcheck 吃掉;「未誘導」≠「已防止」。v1 接受此殘餘(SKILL.md 校準規則明文寫入是唯一防線),機械豁免(如 refcheck 跳過帶 canary token 的行)留 v2 評估。

## 邊界 / 非目標(YAGNI)

- ❌ **不重執行 auditor 宣稱的查證指令**(方案 B):injection 面 + 只驗自報條目;v2 候選。
- ❌ **不做 spec 內部一致性檢查**:見 canary 相容性。
- ❌ **不做裸符號 grep**(`cmd_canary`、`good()` 這類無 `/` 的識別字):無錨定檔案,全 repo grep 要嘛恆真要嘛噪音;語意層留 auditor。
- ❌ **不當新收斂閘**:refcheck rc 不進 `loop status` 判準;它是 pre-audit 修正器(missing 當場修掉),不是第五道 gate。
- ❌ **不動 canary / judge / 辯方 / cross_audit.py 代碼**:run_cross_audit 簽名與實作零改動;judge「無查證行→major」閘保留(改為只計語意查證,措辭改)。
- ❌ **不主動遍歷 vault**(逐節點巡檢是 doctor Check P 的地盤):refcheck 吃**顯式指定的單一 md 檔**(指到 vault 內的檔也照吃,不拒收),兩者共用抽取邏輯但入口/對象不同。共用實作方式(抽函數 vs 複製)留實作計畫決定,spec 不鎖。

## 誠實天花板

1. **存在 ≠ 語意正確**(同 Check P 天花板):refcheck 證「檔在、行號在範圍內」,證不了「spec 對該位置的描述仍對」。gap 說的 <55% 弱項**只被買走「存在性/位置」這一片**;語意地面查證(欄位意義、函數行為、常數用途)仍靠 LLM——這是「LLM 只判 grep 查不到的」的原意,不是把弱項清零。
2. **行號漂移半盲**:檔在、行 N 在範圍內、但內容早換掉——status 仍 ok。manifest excerpt 把實際行內容擺到 auditor/人眼前(可目視比對),但「內容還是不是 spec 說的那回事」是語意判斷,不在 v1。
3. **只收 inline-code 宣稱**:散文路徑、fenced block 內引用、縮排 fence(FENCE_RE 行首限制,同 Check P 已知)都漏。**首段非現有頂層目錄的引用被靜默丟棄(r2-F2)**:top-dir 拼錯(如 `srcs/main.py`)不進 claims、不報 missing——假陰性,不在 v1 射程(同 Check P 既有行為);**repo 頂層檔案亦然(cross-r1-qF6)**:`top_dirs` 只收目錄(`scripts/lumos:753` `p.is_dir()`),`README.md:10` 這類頂層檔引用不進 claims;manifest 統計只對「有入 claims」的宣稱負責。spec 寫作慣例(路徑用反引號)是前提。
4. **manifest 錨定效應**:auditor 拿到 manifest 可能只圍著清單審、漏掉 spec 沒 backtick 的現況假設——auditor prompt 須明示「manifest 非宣稱全集,散文裡的現況假設仍要自己查」。此風險是換來的,不是免費的。

## 測試策略

CLI subprocess 風格(run(...) + check(name, cond, detail),t_-prefixed 自動收集),零第三方依賴。fixture:temp repo(直接 `--repo` 顯式指定免 git)+ `scripts/real.py`(5 行)+ 一份 spec md。

1. **missing 報出**:spec 含 `scripts/ghost.py` 反引號引用 → rc 1,`--json` 該條 status=missing。
2. **ok + excerpt**:spec 含 `scripts/real.py:3` → rc 0(僅此條時),excerpt = real.py 第 3 行實際內容。
3. **line_out_of_range**:`scripts/real.py:99` → rc 1,該條 out_of_range。
4. **跳過規則**:`https://x/y`、`and/or`(首段非頂層目錄)、`cmd_context`(無 `/`)、fenced block 內路徑 → 皆不入 claims。
5. **範圍行號**:`scripts/real.py:2-4` → ok,excerpt 首尾行。
6. **--repo 解析失敗**:不存在的 root → rc 2。
7. **同檔多行號(r3-F1)**:同一 spec 引 `scripts/real.py:3`、`scripts/real.py:99`、`scripts/real.py` 三條 → 三條各自成 claim(ok/out_of_range/ok),**不塌成一條**——防繼承 Check P token 級去重。
8. **回歸**:既有測試全綠;doctor Check P 行為不變。

## 知識同步影響

| 受影響文件 | 需同步什麼 |
|---|---|
| `docs/methodology/架構圖即合約.md` | 「確定性 > AI 判斷」軸補:design-loop 的存在性查證已機械化(refcheck),LLM 只判語意——gap→機制的落地例 |
| `docs/methodology/架構圖即合約-對外論述.md` | 白話:審查員不再自己聲稱「我查過檔案在」,系統先機械查好、附上原文,審查員只判「描述對不對」 |
| `skills/lumos-design-loop/SKILL.md` | 步驟 3 前插 refcheck(消費端 ③) |
| `governance/autonomous_loop/orchestrator-prompt.md` | §2 步驟 2.8 + auditor/judge prompt 措辭 + §2.5a 取材規範(消費端 ①②) |
| `lumos-project-notes` skill | 指令清單補 `lumos refcheck`(vault-free 工具) |
| memory `autonomous-iteration-loop` | 補:存在性查證機械化,canary 保留地=spec 內部一致性 |

## 審計修正紀錄(design-loop)

### R1(2026-07-02,canary type a=壞§ref「§11 錯誤碼與訊息對照表」,opus,**CAUGHT**,辯方重算後 severity=minor)

canary 被正確識別(明指「全 spec 無 §11、無編號章節」)。judge 原評 F1=blocker/F3=F4=major/F5=minor;三條 ≥major 全被獨立辯方駁倒(各附 file:line 反證,依規不折、留痕如下),存活僅 F5(minor),本輪 severity=minor:

- **F1 blocker→minor(辯方反證:`skills/lumos-design-loop/SKILL.md:23` + `scripts/lumos:772`)**:指控「手動 loop 的 (d) 型 canary(未定義產物/檔名)會被 refcheck 抓到並在審計員看到前自動修掉」。反證:(d) 型範例是**裸檔名 `xxx.json`(無 `/`)**,refcheck 抽取第一道 `"/" not in token → continue`(`scripts/lumos:772`)直接跳過;SKILL.md 未要求/誘導帶 repo 路徑。殘餘價值已吸收:消費端 ③ 補一句「(d) 型 canary 保持裸檔名(勿帶 repo 路徑),與 refcheck 抽取域天然不相交」(見該節)。
- **F3 major→minor(辯方反證:spec §抽取規則行號 cite + `scripts/lumos:766-771`)**:散文「否則整個 token 不動」與 code(token 恆剝 suffix、非數字僅 line 留空)確有分歧,但 spec 以「`scripts/lumos:761-777` 同款,不另發明」綁定 code 為權威、觸發面(backtick `path:symbol`)近零。散文已順手改正與 code 一致(非折入 major,係更正筆誤)。
- **F4 major→minor(辯方反證:orchestrator-prompt.md:34/36/42 多輪機制)**:指控「機械修正繞過全部審計層」。反證:loop 每輪從原稿重 cp 工作副本,任何 refcheck 修正至少被後續輪 auditor→judge→辯方重審,放行前另有跨族 cross_audit 讀最終原稿;殘餘窄縫(最終收斂輪的修正僅被 cross_audit 覆蓋)為 minor 級,已在消費端 ① 註記。
- **F5 minor(折入)**:消費端 ② 的「機械核心」名過其實(無行號宣稱 excerpt 全空、有行號者只是孤立單行)→ 措辭誠實下修為「機械底座」,明示語意份量仍來自編排者補充。

### R2(2026-07-02,canary type b=未定義旗標 `--fail-fast`,opus,**CAUGHT**,severity=minor)→ 連 2 輪 good

canary 被正確識別(明指「消費端強制使用卻不在 CLI 簽名、全 spec 無定義」,並點出它與消費端 ① 完整-manifest 需求的矛盾)。排掉 canary 後全 minor(無 ≥major,未觸發辯方),全數折入:
- **F2 minor**:誠實天花板補「首段非頂層目錄引用被靜默丟棄(top-dir typo 假陰性)」。
- **F3 minor**:canary 相容性節補「守衛強度誠實聲明」——(d) 型裸檔名是散文規範非機械強制,殘餘風險明列、機械豁免留 v2。
- **F4 minor**:抽取規則 step 2 判斷順序改為與 code 一致(先跳 `://` 再剝 suffix,逐步附行號)。
- auditor 查證紀錄:spec 引用的全部檔案/行號/regex/函數/CLI 分流逐條 Read/Grep 屬實。

### Cross-family r1(2026-07-02,qwen3-max,status=ok,自評 worst=blocker → 編排者逐條機械驗證後:真 minor×3 折入、誤報×5 標反證,cross_reject_count=1,回 loop 續審)

- **qF1 minor(折入)**:抽取規則行號 cite 補「連帶依賴 `:754`/`:752-753`」。
- **qF2 major→誤報(反證:python 實測)**:指控 `_suffix_re` 對 `path:123:func` 會產生 token=`path:123`;實測 `re.search(r":([^/]+)$")` 最左匹配 → token=`foo/bar.py`、sfx=`123:func`、line=""——token 正確、純數字行號(`file:123`)剝離完全可靠,「line_out_of_range 判定失效」不成立。
- **qF3 blocker→minor 折入(反證:spec §CLI 本就定義 rc 2 fallback;「沿用既有」僅指抽取規則)**:repo 自動發現是**新規格行為**非複用宣稱,stdlib 數行;真 gap 只有 walk-up 邊界未明 → 已補「至檔案系統根為止」。
- **qF4 minor→誤報(反證:消費端 ① 原文「修正記入審計修正紀錄、標『機械 refcheck』留痕」)**:留痕已規定;canary 在工作副本、修正折原稿的分離即 design-loop 既有機制(orchestrator-prompt.md:34)。
- **qF5 major→誤報(重複:即 r2-F3 已折入的「守衛強度誠實聲明」)**:qwen 引用的正是 spec 自承段落;「散文規範+SKILL.md 校準規則明文」即 v1 的防線決定,機械豁免已明列 v2。
- **qF6 minor(折入)**:誠實天花板補「頂層檔案(`README.md:10`)不進 claims」(`top_dirs` 只收目錄)。
- **qF7 minor→誤報(反證:python 實測 `'/' in 'and/or' == True`)**:`and/or` 含 `/`、首段 `and` 非頂層目錄 → spec 測試案例 4 標的跳過原因正確,qwen 對 `:772` 的字面推理錯誤。
- **qF8 blocker→誤報(反證:qF8 的兩根支柱皆倒)**:①「R2 查證紀錄與 F2 矛盾」——qF2 本身是誤報(見上實測);②「R1『全被駁倒』誤導」——審計紀錄逐條寫明降級理由+殘餘價值吸收位置(消費端 ③ 補句、r2-F3 誠實聲明),「駁倒」指 ≥major 裁決被辯方以 file:line 反證降級,係 finding-refute 機制既定語意(docs/design/2026-06-24-finding-refute.md)。

### R3(2026-07-02,canary type c=未定義常數 `MAX_EXCERPT_WIDTH`,opus,**CAUGHT**,辯方重算後 severity=minor)→ 連 2 輪 good(r2+r3)

canary 被正確識別(明指「ALL_CAPS 常數被當截斷閾值使用、全 spec 無定義無賦值無旗標」)。judge 原評 F1=blocker;辯方裁決 blocker→minor(依規不折 major、殘餘以 minor 吸收):
- **F1 blocker→minor(辯方反證:spec manifest schema {token,line,status,excerpt}/`line_out_of_range` 定義/per-line excerpt/測試案例 2-3-5 同檔多行——四處皆已編碼 per-(token,line) 意圖;未實作 draft、一行措辭修正)**:機械前提為真(Check P `scripts/lumos:762/:772/:776` token 級去重會塌同檔多行號引用,auditor python 實跑證實)——已吸收:step 3 改明「以 (token,line) 去重、不沿用 Check P token 級去重(關鍵分歧點)」+ 新增測試案例 7(同檔多行號不塌)。辯方誠實 caveat:原測試各 ref 孤立、接不住字面照抄,故新測試案例必要、非裝飾。
- **F3 minor(折入)**:行號歸屬更正——`p.is_dir()`/排隱藏在 `:753`(非 `:752`/`:774`),`:774` 只做成員檢查。
- **F4 minor(折入)**:目錄型 token 行為明定(status=ok、行號不適用、不把目錄當檔案讀)。
- **F5 minor(折入)**:消費端 ② 補「守衛強度」聲明(散文規範無機械強制,v1 接受、機械拼接留 v2)。

### Cross-family r2(2026-07-02,qwen3-max,status=ok,自評 worst=blocker → 編排者逐條機械驗證:真 minor×4 折入、blocker/major×4 全誤報,cross_reject_count=2 → **disputed、不放行**)

- **cF1 major→minor 折入**:方案評比「複用 Check P」補限定「僅 step 1-2,去重粒度刻意分歧」(與 step 3 對齊)。
- **cF3 minor→誤報(反證:`sed -n '3713,3723p' scripts/lumos | cat -n` 實測)**:qwen 稱「bootstrap 在 3718、init 在 3721」;實測 `:3715`=install、`:3721`=bootstrap,spec 引用分毫不差,qwen 讀錯 ground-truth。
- **cF4 major→誤報(反證:spec §CLI「走到根仍無 → rc 2」)**:`Path.cwd().parents` 純詞法迭代、終止於(drive)根,無 symlink loop 面;Windows 多 drive 不跨即落入既定 rc 2 fallback,行為完全確定。
- **cF6 major→誤報(機制已完備)**:「以 (token,line) 組合去重」即完整機制規格(tuple set),測試案例 7 專防字面照抄;已補三字澄清,非 major。
- **cF8 blocker→誤報(反證:orchestrator-prompt.md:34+41——步驟 7 本就「折辯方存活 finding 進原稿 spec」)**:折回原稿是 design-loop 既定機制;canary 只活在當輪工作副本、下輪重植,修正原稿不碰 canary 隔離。qwen 把 loop 的核心折入語意當成 bug。
- **cF11 minor→不折(已定義)**:「spec 內部一致性」在 §canary 相容性已以列舉定義(§ref/旗標/常數)。
- **cF13 minor 折入**:「不掃 vault 節點」改述「不主動遍歷 vault;顯式指定單一檔照吃」。
- **cF20 minor 折入**:manifest `line` 欄位格式明定(字串;單行/範圍原字面/空)。
- 其餘 findings(2/5/7/9/10/12/14-19)qwen 自評 clean。
- **裁定**:cross_reject_count 達 2,依 §2.5c 停、不放行、cross_verdict=disputed(converged:false)。兩遍複核的 ≥major 指控 0/5 經得起機械驗證(qF2/qF7/cF3 被 python/sed 實測直接反證),但真 minor 8 條已全數折入;留人裁奪。
