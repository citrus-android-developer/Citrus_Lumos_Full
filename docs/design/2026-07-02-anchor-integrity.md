# 設計:錨點完整性守衛(anchor-integrity)— 測試 runner / 把關 hook 的 baseline hash + 顯式 approve

- 日期:2026-07-02
- 狀態:design-approved(2026-07-02 人裁放行)
- 收斂紀錄:design-loop 3 輪(R1 missed 依規作廢不折、R2+R3 連 2 輪 caught+minor 自動收斂);辯方 4 次出動全駁倒假 major(各附 file:line 反證);qwen 跨家族複核 endorsed(worst=minor);refcheck 步驟 2.8 首次實戰(前置修 1 條提案新檔誤報、3 輪 manifest 全程餵審計)。canary 紀錄於 dry-run scratch,以 orchestrator log 為證。
- 動機來源:治理日報 gap(2026-06-24):方法論最底層退路「CI 跑真測試、綠才算數」把測試結果當不可造假真值,但 runner/評分器本身可被悄悄改成一律通過(外部實證:八大權威評測被破,手法=conftest 塞鉤子改寫每題結果為通過,評分器毫無察覺)。lumos 自主 loop 的 agent 能碰整個 repo,同樣風險。
- loop_id:anchor-integrity

## 目標(一句話)

新增 vault-free 指令 `lumos anchor verify/approve`:對固定列舉的錨點檔(測試 runner + git 把關 hooks)維護 sha256 baseline(`anchor-baseline.json`,落點 governance/ 目錄),錨點被改而未經顯式 approve → verify rc=1;pre-push 與自主 loop 入口接線,讓「測試綠/hook 放行」這句話的前提——**驗證器本身沒被動過**——從盲信變成機械可核對。

## 前提與既驗事實(grep/Read 驗於 2026-07-02)

- **本 repo 沒有 CI workflow**(無 `.github/`、無 yml):方法論說的「CI 跑測試是錨點」(`docs/methodology/架構圖即合約.md:83`)與「真錨點=把測試真的跑綠+人拍板」(`docs/methodology/架構圖即合約-全景圖.md:110`)在本 repo 的實體是**本機跑** `python3 scripts/test_lumos.py`(1960 行,stdlib-only,rc=0/1)與 `scripts/test_autonomous_loop.py`(227 行)。
- **驗證器全部 agent 可寫**:`scripts/test_lumos.py` 的 `check()`/`run()`(斷言與評分都在同檔)、`scripts/hooks/pre-commit`(L2 架構圖同步硬擋)、`scripts/hooks/pre-push`(doctor 把關)、`scripts/hooks/post-commit`(bypass 留痕器,`docs/.bypass-log.jsonl` 的唯一寫者)——改掉任何一個,對應的「綠/放行/留痕」就是無聲假訊號。hooks 生效機制=`git config core.hooksPath scripts/hooks`(已驗證當前設定)。
- **既有近親機制不覆蓋此洞**:`core-invariant-baseline`(設計擱置)守核心知識節點語意欄位 hash,不守 repo 驗證器檔;`spec-refcheck` 驗 spec→repo 指涉存在性;doctor Check 系列全是 vault 導向。「驗證器自身完整性」目前零覆蓋。
- **vault-free 指令有前例**:`lumos refcheck`(`scripts/lumos` `cmd_refcheck(md_path, repo=None, as_json=False)`)不吃 `--vault`,本 spec 的 `anchor` 同型。
- **governance-log 寫者宣稱**:`scripts/lumos:336` `_append_governance_log` docstring 明言「doctor --ci 唯一寫者」。本 spec 的 `anchor approve` 要留痕就成為第二寫者——必須連動改該 docstring(這是宣稱變更,記入實作 checklist,不是靜默擴權)。
- **測試風格**:`test_lumos.py` = subprocess-only,`run(vault, *args, expect_rc=)` + `check(name, cond, detail)`,新增 `t_*` 函式自動被收集(既有慣例,見 `2026-06-19-reversibility-and-governance-ledger-plan.md` Global Constraints)。

## 方案評比與選擇

### 方案 A(選此)— baseline hash + 顯式 approve 留痕
固定列舉錨點檔 → sha256 進 `anchor-baseline.json`(落點 governance/ 目錄,checked-in)→ `lumos anchor verify` 比對(mismatch 列檔、rc=1)→ 改錨點的合法路徑=`lumos anchor approve`(重算寫回 + governance-log 留痕事件)。pre-push 擋、自主 loop 入口先 verify 再信任任何「測試綠」。
**為什麼選**:機械、確定性、零依賴,對齊「確定性 > AI 判斷」主軸;把「一行靜默改寫 runner」升級成「必須連動出現 baseline diff + approve 留痕(或 --no-verify 走 bypass 軌跡)」——人 review 時 `anchor-baseline.json` 變更是明確紅旗,無痕篡改路徑被封死到只剩「連守衛一起改」(見誠實天花板 1)。

### 方案 B(否決 v1)— RHB 環境硬化(錨點跑在 agent 改不到的地方)
gap 建議借 RHB 讓錨點跑在 agent 摸不到的環境。**本機單人工作流沒有這樣的執行面**:agent 有 shell、能改 `core.hooksPath`、能動 git 本身;「從 origin/main checkout runner 再跑」只是搬問題(wrapper 可改、origin 也在 agent 可達範圍)。硬寫=假設「換個地方就摸不到」的破口,重蹈 `judge-perturbation-stability` 否決教訓(寫了做不到的隔離=自欺)。**留作 future**:真 CI(GitHub Actions + branch protection)上線時,錨點跑雲端 runner + 保護分支,才有真硬化;本 spec 的 baseline 屆時直接複用(CI 端 verify)。

### 方案 C(否決獨立成案,精神併入 A)— 純 diff 標記送審
pre-commit 掃 staged 碰錨點路徑 → 要求 commit message 帶 marker。無內容 hash 底線:rename / 繞路徑 / hooksPath 改指向都繞得過,且 marker 對 agent 是零成本自貼。A 的 approve 就是「標記送審」的機械強化版(帶內容 hash + 結構化留痕)。

## 邊界 / 非目標(YAGNI)

- ❌ **不守 `scripts/lumos` 本體**:它是自主 loop 天天迭代的對象,收進 baseline = 每天 approve → 盲簽疲勞,守衛立刻形同虛設。分層:**baseline 守驗證器(測試 runner + hooks),測試守被驗物(lumos 行為)**——改壞 lumos 由 `test_lumos.py` 抓,前提「runner 沒被動」正是 baseline 守的。天花板 2 誠實記這個分層的缺口。
- ❌ **不做簽名/密鑰**:單機無密鑰隔離面(agent 讀得到任何本機私鑰),簽名只是更貴的 sha256。
- ❌ **不做語意掃描**(「找出所有像測試的檔案」):v1 固定列舉;新增錨點=改 baseline 走 approve,列舉本身受守。
- ❌ **不動 doctor**:doctor 是 vault 檢查器;anchor 是 repo 層,走 refcheck 式 vault-free 獨立指令。
- ❌ **不擋 --no-verify**:業界標準逃生口保留(同 pre-commit/pre-push 既有哲學);繞過的可見性靠既有 bypass 軌跡與 PR diff,非本 spec 新增。

## 組件

### 1. `anchor-baseline.json`(新檔,落點 governance/ 目錄,checked-in)
```json
{
  "version": 1,
  "anchors": {
    "scripts/test_lumos.py": "<sha256>",
    "scripts/test_autonomous_loop.py": "<sha256>",
    "scripts/hooks/pre-commit": "<sha256>",
    "scripts/hooks/pre-push": "<sha256>",
    "scripts/hooks/post-commit": "<sha256>"
  },
  "approved_at": "<iso ts>",
  "note": "<approve 時的一句話理由>"
}
```
錨點集合 v1 = 測試 runner ×2 + 把關 hooks ×3(post-commit 必收:它是 bypass 留痕器,改掉它=審計軌跡斷頭)。

### 2. `lumos anchor verify` / `lumos anchor approve`(新子指令,vault-free)
- `verify [--repo <root>] [--json]`:讀 baseline、對每個錨點算 sha256;全符 → rc=0;任一 mismatch/缺檔 → 列出(檔、期望、實際)、rc=1;**baseline 檔不存在 → rc=0 加一行警示**(未啟用 ≠ 失敗,漸進採用;但 pre-push 接線後本 repo 恆有)。
- `approve [--repo <root>] --note "<理由>"`:重算全部錨點寫回 baseline + append governance-log 事件 `{"gate":"anchor-approve","kind":"approved","hard":false,"nodes":[<改動的錨點檔>],"note":...}`。`--note` 必填(空理由=無資訊留痕)。
- 實作:`cmd_anchor_*` 進 `scripts/lumos`(同 `cmd_refcheck` 的掛法;**「vault-free」指 CLI 不吃 `--vault` flag,非程式內取不到 vault**)。approve 留痕:vault 取得**優先走 `--vault`/env 解析(同 doctor 呼叫模式,`scripts/lumos:789` 傳 env.vault;fixture 可直接驅動,見 `t_governance_log_write`)**,無顯式 vault 才後備 `find_vault(Path.cwd())`(`scripts/lumos:3537` 起),取得後複用 `_append_governance_log`,並**改其 docstring**(「doctor --ci 唯一寫者」→「寫者=doctor --ci + anchor approve」);**無 vault 分支**:find_vault 回 None → baseline 照寫、gov-log 跳過並印警示(缺 vault 不擋 approve,但留痕降級要喊出來)。
- **note 可見性**:`lumos gov` 的 governance-log mapper 現把 detail 硬編 ""(`scripts/lumos:1342`)——實作須連動讓 anchor-approve 事件的 note 進 `lumos gov` 顯示(該 mapper 是**全事件共用面**,doctor 事件同源:改法須向後相容如 `d.get("note","")`,不得回歸 doctor 事件的顯示),否則留痕理由僅 raw jsonl 可見,對帳可用性打折。

### 3. pre-push 接線(改 `scripts/hooks/pre-push`)
插在環境檢查(`scripts/hooks/pre-push:23` 起,無 python3/lumos 降級放行)之後、**vault 閘門(:28-33 have_vault exit 0)之前**——anchor 是 repo 層,無 vault 的 checkout 也要跑,不得被 vault 存在性短路:`lumos anchor verify` rc=1 → 擋 push,訊息三選一(同既有 pre-push 風格):① 非刻意改動 → `git checkout` 還原;② 刻意改錨點 → `lumos anchor approve --note` 後重 push;③ `--no-verify`(留 PR diff 與缺 approve 事件的對帳痕)。
> 自指注意:pre-push 自己也是錨點——改 pre-push 接線的那次 commit,approve 要在同批完成,否則自己擋自己(這是 feature 不是 bug:守衛上線即自護)。

### 4. 自主 loop 入口接線(改 `governance/autonomous-loop.sh`)
**每輪 gap 派 orchestrator 前**(非僅 while 迴圈前一次)跑 `lumos anchor verify`——污染可能發生在當天中途(前一輪 agent 改壞錨點),成本毫秒級;rc=1 → abort、LINE 通知「錨點完整性失敗,loop 拒跑」。**loop 入口比 pre-push 嚴**:對本 repo(已採用,baseline 恆有)missing baseline 視同 rc=1 硬擋——無人看顧場景沒有人眼看 diff,「rm baseline 無聲停用」這扇門在 loop 入口關死(pre-push 維持 rc=0 警示,漸進採用語意不變)。**接線必須 errexit-safe**:`governance/autonomous-loop.sh:2` 是 `set -euo pipefail`,裸呼叫 rc=1 會在通知前殺掉整個腳本、退化成無聲中止——須寫 `if ! …verify; then <LINE 通知(沿檔內 || true 慣例)>; exit 1; fi`。理由:無人看顧場景,錨點已污染時跑出來的「收斂/綠」全是假訊號,寧可停。

### 5. 測試(`scripts/test_lumos.py` 新增 `t_anchor_*`)
tempdir 造假 repo——**複用 `_mk_git_vault` 慣例(`scripts/test_lumos.py:1331` 起:git init + 建假 vault + initial commit;`_append_governance_log` 無 HEAD 會靜默 no-op,fixture 不 commit 則 gov-log 斷言無聲失敗)**,再疊加假錨點檔 + baseline:
- verify 全符 → rc=0;改一檔 → rc=1 且輸出列出該檔;缺檔 → rc=1。
- approve 後 verify → rc=0;governance-log 多一筆 `anchor-approve` 事件(格式含 gate/nodes/note)。
- baseline 不存在 → rc=0 + 警示行。

## 誠實天花板

1. **同 repo 守衛悖論(最大天花板,明說)**:verify 代碼、baseline、pre-push 接線全都在 agent 可寫的同一 repo——決意繞過者可以「錨點+baseline+守衛」一起改。本 spec 買到的不是不可繞,是**無痕篡改被封死**:任何繞法都留下至少一種可見痕跡(baseline diff / 缺 approve 事件的對帳缺口 / --no-verify bypass 軌跡 / hooksPath 改動),人 review PR 時有明確紅旗可查。摩擦與留痕,非保證——同 canary/辯方/cross-family 的天花板措辭。gap 說「別把 CI 綠當神諭」——本 spec 之後,「綠」的可信前提(驗證器未動)至少變成一條可機械核對、有留痕的宣稱,而不是沒人想起來要問的盲點。
2. **分層缺口**:不守 `scripts/lumos` 本體(見 YAGNI)——改壞 doctor 的 Check 邏輯靠 `test_lumos.py` 的行為鎖定測試抓,但「測試沒覆蓋到的 doctor 行為」被靜默改仍無感。這是測試覆蓋率問題,不是完整性問題,不在本 spec 軸上。
3. **baseline 自身無自我保護**:手改 json(不走 approve)+ 改錨點同 commit 可讓 verify 過。抓它靠**對帳**:baseline diff 存在而 governance-log 無對應 `anchor-approve` 事件 = 紅旗。v1 對帳是人工(review PR 時查),機械對帳(doctor 軟 Check 比對 baseline mtime/git log vs gov-log)留 v2——先驗證「approve 流程本身跑得順」再加閘,避免一次上兩層新流程。
4. **`git config core.hooksPath` 是更上游的旁路**:整個 hooks 層可被一行 config 指走。本 spec 不解(config 不在 repo、無檔可 hash);唯一緩解=自主 loop 入口的 verify 不走 hook(shell 直呼),兩條路徑至少一條要活。真解在 future CI(方案 B 留作)。

## 測試策略

- **單元**:組件 5 的 `t_anchor_*` fixtures(subprocess-only,tempdir 假 repo,不碰真 baseline)。
- **實錨自測**:實作 PR 內跑一次真 repo `lumos anchor approve --note "初始 baseline"` + `verify` rc=0,把首個 baseline 與首筆 approve 事件一起進版——上線即有效,不留「baseline 空窗期」。
- **回歸**:`python3 scripts/test_lumos.py` 全綠;pre-push 在錨點未動時行為不變(doctor 段照舊)。

## 知識同步影響

| 受影響文件 | 需同步什麼 |
|---|---|
| `docs/methodology/架構圖即合約.md` | 把關表加一行「anchor verify(pre-push/loop 入口,硬擋)」;`架構圖即合約.md:83` ★COMBO★ 行「CI 跑才是錨點」補後綴:錨點自身完整性由 anchor baseline 守 |
| `docs/methodology/架構圖即合約-全景圖.md` | §真錨點(:110)補:「測試真的跑綠」成立的前提=批改程式沒被動過,anchor verify 把這前提變成可核對宣稱 |
| `docs/methodology/架構圖即合約-對外論述.md` | 白話:考卷可信的前提是「改答案的學生不能同時改批改程式」;我們給批改程式拍了指紋,動過就要簽名留痕 |
| `skills/lumos-project-notes/SKILL.md` | 指令表加 `lumos anchor verify/approve` |
| `governance/autonomous_loop/orchestrator-prompt.md` | 無需改(orchestrator 不直接信任測試綠;入口 verify 在 wrapper `autonomous-loop.sh`) |
| memory `lumos-governance-tag-rigor` | 補:治理帳寫者從 doctor --ci 單一擴為 +anchor approve |

## 審計修正紀錄

### R1 前置(2026-07-02,機械 refcheck)
- refcheck 報 baseline 檔(governance 下的 anchor-baseline.json,原以完整路徑 inline-code 書寫)missing——它是本 spec 提案新建的檔,非現況宣稱。依 spec-refcheck「(d) 型裸檔名」慣例改寫為裸檔名 `anchor-baseline.json` + 散文標落點(裸檔名無 `/`,在 refcheck 抽取域外,不再誤報)。其餘 16 條指涉宣稱全 ok。

### R1(2026-07-02,canary type a=壞§ref,opus,**MISSED**,severity=minor)
canary(§錨點註冊表治理 不存在章節引用)**未被點出**——auditor 地面查證紮實(F1-F5 全附 grep/Read 行)但漏 spec 內部一致性,本輪不採信、findings 不折。辯方複核兩條 major 皆駁倒:
- F1「vault-free 與複用 _append_governance_log 互斥」→ **辯方反證:scripts/lumos:351 + :1316,:1325(寫讀同錨 vault.parent)、:3537-3546(find_vault 一行可得)、:3566-3569(vault-free=不吃 --vault flag 而非取不到 vault)**;「互斥」為稻草人,殘餘=spec 未明寫 approve 需 find_vault(minor)。
- F2「fixture 產不出 governance-log 事件」→ **辯方反證:scripts/test_lumos.py:1331-1343(_mk_git_vault 既定慣例含 commit+vault)**;spec fixture 描述是示意速記,殘餘=值得補「fixture 須 commit 使 HEAD 存在」(minor)。
- F3(gov 不顯示 note)/F4(pre-push vault 閘門)/F5(set -e 陷阱)= minor,本輪 missed 不折,留待後續輪重審。

### R2(2026-07-02,canary type b=未定義旗標,opus,**CAUGHT**,severity=minor)
canary(`--soft-fail` 簽名未列、它處無定義)被識別(auditor 併點出其反噬機制本質)。排掉 canary 後 judge 評 minor(auditor 主張 F2 major,judge 據檔內 `|| true` 慣例判為實作層陷阱非設計缺陷;無 ≥major → 未派辯方),折入:
- **F2(minor)**:組件 4 補 errexit-safe 接線寫法(set -euo pipefail 下裸呼叫會吞掉 LINE 通知)。
- **F3(minor)**:組件 2 補 note 可見性——gov mapper detail 硬編 "",須連動接 note。
- **F4(minor)**:組件 3 明寫插點=vault 閘門(pre-push:28-33)之前,不得被 have_vault 短路。
- **F5(minor)**:組件 5 fixture 明寫複用 _mk_git_vault(含 initial commit),堵無 HEAD 靜默 no-op。
- **F6(minor)**:組件 2 澄清「vault-free」=CLI 不吃 --vault;approve 內部 find_vault,並定義無 vault 分支(R1 F1 辯方殘餘正式寫回)。
- CL1-CL6 地面事實(行數/hooksPath/docstring/bypass-log 寫者/refcheck 簽名/line_notify)auditor 全查證 clean;R1 辯方反證 file:line 亦經其逐條複驗屬實。

### R3(2026-07-02,canary type c=未定義常數,opus,**CAUGHT**,severity=minor)→ **CONVERGED(連 2 輪 R2+R3 caught+minor)**
canary(`ANCHOR_MAX_AGE_DAYS` 無值、組件 1/2 不一致)被識別。judge 初評 major(F1/F2),辯方複核兩條皆駁倒:
- F1「approve find_vault(cwd) 與 fixture 不相容、兩路皆死」→ **辯方反證:scripts/test_lumos.py:1146-1161(t_governance_log_write 以 --vault 驅動 _append_governance_log 寫進 fixture gov-log 並斷言成功)、scripts/lumos:335,351,345(函式 vault-參數化、不看 Path.cwd())、:789(doctor 傳 env.vault 模式)**;「兩路皆死」是建立在「approve 不吃 --vault」臆測上的假二分。殘餘真核(minor,已折):組件 2 澄清 approve 取 vault 優先 --vault/env、find_vault 僅後備。
- F2「rm baseline=無聲停用,擊穿組件 4」→ **辯方反證:spec :61「pre-push 接線後本 repo 恆有」已區分未採用/已採用、:81 天花板 1 明列 baseline diff 留痕、:83 手改 json(更隱蔽)已列 minor,governance/.gitignore 不忽略 *.json 故刪檔必現 diff**;非「無聲」。殘餘真核(minor,已折):loop 入口對已採用 repo 的 missing baseline 升硬擋(無人看顧場景無人眼兜底)。
- **F4(minor,折入)**:gov mapper 是全事件共用面,note 改法須向後相容。
- **F5(minor,折入)**:組件 4 插點釘死=每輪 gap 派工前(非僅 while 前一次)。
- CLEAN 項(行數/hooksPath/bypass-log 寫者/docstring/mapper/find_vault/refcheck 簽名/pre-push 插點行號/errexit/_mk_git_vault/方法論引用/無指令衝突)auditor 全附查證行屬實。

> **3 輪收斂(2026-07-02)**:r1 missed(壞§ref 未抓,辯方駁倒 2 條假 major)→ r2 good(caught+minor,折 5 條)→ r3 good(caught+minor,辯方駁倒 2 條假 major、折 2 條殘餘真核+2 條 minor)。連 2 輪 caught+minor 達 K=2。canary 2/3(r1 漏);辯方 4 次出動全部駁倒假 major,佐證「技術密集 spec 的 auditor 假陽性率高、辯方階段有效」。
