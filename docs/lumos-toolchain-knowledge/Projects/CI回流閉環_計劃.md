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
  - "[[Systems/nested-agent-permission-scope]]"
summary: |-
  FLAG:DECISION
  KEY:問題——CI(GitHub Actions)紅了只存在 GitHub 網頁,本機 lumos/架構圖/治理帳全不知情;下個 session 開場也讀不到 → 自動開發迴圈在「推出去之後」斷掉
  KEY:★彈性宣告(2026-07-29 使用者裁定,零侵入預設)★——推送路徑由專案 `.lumos/config.json` 的 `ci.flow` 宣告:**無宣告=direct(現況,裝了新功能行為不變)**／`pr`(一律分支+PR,紅燈碰不到 main)／`tier`(混合:pitfalls tier=high 才走 PR);GitHub 端 branch protection/ruleset **完全不必動**(工具端行為,隨時改 config 切換,不影響其他人與消費專案)
  KEY:解法方向=**push 後同輪等待+修復重試(watch-fix-retry)**,非雲端自動修也非留到下次開場:`lumos ci-wait` 在 push 成功後阻塞等 CI 結論→紅則印失敗步驟+log 尾段→在場 session 當輪修→重推→再等(最多 2 次自動重試,之後攤人);SessionStart 推播降為**後備網**(session 中斷/機器關機才用),不是主路徑
  KEY:★不採雲端 autofix(明文裁定)★——世界主流(Copilot cloud agent 一鍵修/Codex workflow_run autofix/GH Agentic Workflows)是 CI 失敗觸發 agent 在雲端改碼開 PR;與 2026-07-29 剛裁定的「autonomous 非 dry-run 停用」同源風險(無人看顧 agent 握寫入權=confused-deputy),且需把金鑰放進 CI → 本案明文排除,解禁條件同 [[Systems/nested-agent-permission-scope]] d4
  DEP:[[Systems/reversibility-governance-ledger]]
verified_by:
  - "[[Verification/2026-07-29_CI回流閉環v1落地]]"
---
# CI 回流閉環_計劃

`PRIOR-ART:` **⓪ 自家後院已有實作（2026-07-29 使用者指出，本案 PRIOR-ART 第一問的真漏查——當時只查外部世界沒查消費專案）**：LandmarkMember（消費 repo，非本 repo 路徑）的 fetch-bundle 發版腳本早已在輪詢 CI——`gh run list --workflow=<指定> --branch=<tag> --json databaseId,status,conclusion` 每 N 秒重試、有次數上限；`completed+success` 才往下走、`completed+非 success` 印 run URL 後中止、逾時中止；其 release 腳本事後再撈 run id 寫進發版紀錄。**這是本案的實戰驗證來源**（輪詢間隔/逾時處置/run 撈不到的 fail 形態/`--branch` 配 tag 過濾皆已在真環境跑順），**差別在範圍**：它等「一支指定 workflow、發版時機、紅了交人」；本案要「該 sha 全部檢查、每次 push、紅了 AI 當輪修＋進治理帳」。

① 最小層：`gh run list --json` 已能查狀態、`lumos gov` 已是多帳彙整器、Claude hook 註冊機制（`merge-claude-settings.py` 的 `HOOK_ENTRIES`）已存在——主路徑 [S1][S2] 屬接線；**但 [S2b]-① 的 SessionStart hook 是新建**（實查現有僅註冊 PreToolUse/PostToolUse/Stop 三事件，無 SessionStart），需新增 hook 檔＋新事件登記，pre-flight 已更正原「已存在」的誤述。② 世界解過：Copilot cloud agent 一鍵修復、Codex `workflow_run` autofix、GH Agentic Workflows self-healing CI——全屬「雲端 agent 自動改碼開 PR」型。③ 裁定＝**borrow-design 但反向取捨**：借「CI 失敗要有下游接手」的問題定義，**拒絕**其雲端無人值守實作（見上方 ★ 裁定），改為本機拉取＋人在場修復。

## 範圍刀（明確不做）

- **不做**雲端自動修復／自動開 PR（見 ★ 裁定；解禁＝子 agent 唯讀隔離落地）。
- **不做** webhook／常駐監聽（要開埠、要密鑰；pull 模式夠用）。
- **不擋** push／commit：CI 狀態不新增本機硬閘（`ci-wait` 的 rc1 是給 skill 判讀用的訊號，不是閘）。
- **不做**無限重試：修復重試上限 2 次，之後攤人＋寫 Issue（防燒錢與掩蓋真 bug）。
- **不做**跨 repo 聚合：只查當前 repo 當前分支。
- **不動 GitHub 設定**：不要求也不代設 branch protection／ruleset／auto-merge repo 選項（那是人的決定，且會全域影響消費專案）——工具端在有無保護下都能運作。
- **不改預設行為**：未宣告 `ci.flow` 的專案（含所有既有消費 repo）行為與現在**逐字相同**（直推、無 PR、無新閘）。
- **不解析** CI log 全文做根因判讀（v1 只取失敗步驟名＋log 尾段；判讀交在場的人／session）。

## 條款

### [S1] `lumos ci-wait [--timeout 600] [--repo-dir D] [--sha S] [--branch B] [--json]`——push 後同輪等結論（主路徑）

**旗標更名（r1 四方同報）**：原 `--repo` 與 `gh` 原生 `-R/--repo`（吃 `OWNER/REPO` 字串）語意相反、直傳會被 gh 拒收 → 改名 `--repo-dir`（本機目錄，沿 lumos 家族語意）；**owner/repo 由本案自行從 `git -C D remote get-url origin` 解析後餵 `gh -R`，不轉發使用者輸入**。

- **時機**：`git push` 成功之後**立刻**在同一輪跑（CI 於 push 完成即觸發，~3 分鐘出結論）。
- 行為：先解析當前 HEAD sha → 輪詢 `gh run list --branch <分支> --json databaseId,headSha,status,conclusion,displayTitle,url,workflowName`（間隔 15s，`--timeout` 預設 600s）直到**該 sha 的所有 run 全部** `status=completed`（r2 Codex：只取最近一筆會假綠——快 lint 先綠就收工、慢 integration 五分鐘後才紅，後備網讀最後一筆也是綠，主目標破功）。
- **`ci.workflow` 宣告（選配，2026-07-29 折入；借 Landmark 實戰形態，把複雜度退回已驗證等級）**：
  - **有宣告**（字串或字串陣列）→ `gh run list --workflow=<名>` **只等宣告的那幾支**。此路徑**沒有聚合問題也沒有晚註冊假綠問題**（等的是確定的集合），複雜度＝Landmark 現行做法。適合「只有一支關鍵 workflow 要等」的專案。
  - **未宣告**（預設）→ 等該 sha 的**全部** run，走下列聚合＋grace period（保守但複雜；適合 workflow 會增減的專案）。
- **聚合判定（未宣告 workflow 時）**：全綠才綠；**任一紅即紅**（紅的 workflow 全列）；有 run 仍在跑就繼續等。帳每個 run 各記一筆（`workflow` 欄）。
- **晚註冊 run 的 grace period（r3 席2：原「等目前已註冊的都完成」只是把假綠從『完成時間』搬到『註冊時間』——path-filter 或依賴型 workflow 可能在你判綠後才註冊）**：判定為綠之前，**再等一個 grace 期（預設 30s）重查一次**；期間出現新 run 就繼續等。仍為綠才收工，並在輸出附「已知 N 個 workflow」供人核對。**此為緩解非保證**（無法證明沒有更晚的 run），明文列入誠實天花板。
- **綠**：印一行綠燈訊息、寫帳、rc0。
- **conclusion 九值分三類（r1：原紅/綠二分不窮盡；gh 實有 success/failure/cancelled/skipped/timed_out/action_required/neutral/stale/startup_failure）**：
  - **綠**＝`success`／`neutral`／`skipped` → rc0。
  - **紅**＝`failure`／`timed_out`／`startup_failure` → rc1＋失敗證據（下行）。
  - **未定**＝`cancelled`／`action_required`／`stale` → rc0＋印「非成功但無失敗步驟可歸因」＋寫帳，**不進修復路徑**。
- **紅燈證據取得（r1+Codex：`--log-failed` 是純文字 log 非結構化 step API，多 job 平行時輸出交錯，且可能只標 UNKNOWN STEP）**：步驟名走 **`gh run view <id> --json jobs`** 取 `jobs[].steps[]` 中 `conclusion=="failure"` 者——**多個失敗步驟全列**（`job/step` 成對，`failed_step` 欄以 `;` 串接）；log 證據才用 `--log-failed`，**先取尾 40 行、再截 4000 字**（兩上限依序，r1 定序）；＋run URL；寫帳；**rc 1**。
- 逾時未出結論：印已知狀態＋提示手動查，寫帳（`conclusion=timeout-waiting`），**rc 0**（不把等待逾時當失敗）。
- `gh` 不存在／未登入／非 GitHub remote → stderr 一行說明＋**rc0** fail-open（不因缺工具卡住任何流程）。
- 帳檔：docs 下的 ci-log JSONL（本案新建產物，檔名比照既有六帳的 dot-log 慣例；欄位單源定義見 [S3]）。
- 輸出：文字模式一行 `CI <conclusion> <sha 前7> <title> → <url>`；`--json` 單行純 JSON。
- **rc 單源（全 spec 以此為準，含優先序）**：`--repo-dir` 非目錄 rc2 ＞ **帳檔寫入/自驗失敗 rc2**（沿 `_jsonl_append_verified` 語意，優先於紅燈；**該 helper 的失敗訊息目前硬編「canary record:」前綴，本案須先把前綴改為呼叫端可傳入**——r2 席1，否則 CI 帳寫壞會印出文不對題的 canary 訊息）＞ 紅 rc1 ＞ 綠/未定/逾時/工具缺席 rc0（fail-open）。無 `--refresh` 旗標（`ci-wait` 恆打網路——它的存在意義就是等本次 push 的結論；讀快取那條是 `ci-status` 的語意，見 [S3]）。

### [S1b] 推送路徑分派（`.lumos/config.json` 的 `ci.flow`，彈性宣告）

```json
{"ci": {"flow": "direct|pr|tier", "auto_merge": true, "workflow": "CI"}}
```

- **`direct`（宣告了 ci 區塊但 flow=direct）**：直接 push → `ci-wait` → 紅則當輪修（[S2]）。
- **未宣告 `ci` 區塊（絕大多數既有專案）＝功能全關**：不跑 `ci-wait`、skill 不加等待紀律、hook 不提醒、gov 無此源——**行為與現在逐字相同**。（r2 席3 抓到原文致命縫：原文把 direct 當「無宣告的預設」又要求三 flow 共用等待紀律，等於每個既有專案裝上就被迫每次 push 多等最長 600s＋可能自動修推——與「零侵入」承諾直接矛盾。**修法＝把「有沒有 ci 區塊」當總開關**，flow 三態只在開關開啟後才分派。）
- **`pr`**：改動走 feature 分支，`lumos ship` 串流程（定義見 [S1c]）：建/推分支 → 開 PR → 等分支 run 綠 → 合併 → **合併後再等一次 main 的 run**。
  **合併後複查是必要的（r2 席2）**：squash merge 在 main 產生**全新 sha**，它不是分支 sha 的子孫——所以 ①分支綠不代表 main 綠（squash 後的樹可能與分支不同：期間 main 有他人推進）②所有「sha 是祖先」型提醒對 pr flow 恆為 false、後備網永久靜默。故 `ship` 在合併成功後**必須對合併後的 main sha 再跑一次 `ci-wait`**並寫帳；該筆才是 main 的真實狀態。
- **`tier`（混合，推薦）**：跑 `lumos pitfalls --diff $(git merge-base HEAD <base>)..HEAD` 取尾行 tier——`high` 走 `pr`、`standard` 走 `direct`。**base 解析同 [S1c] 單源**；**必須用 merge-base 而非兩點 diff**（base 領先本地時兩點 diff 會混進無關差異、污染判定）。**與既有 `_codeloop_guard_verdict` 的關係澄清（r3 席1 實查更正 r2 措辭）**：該函式的 merge-base 是**硬編只試 main/master**、且無 base 參數，與 [S1c] 的解析鏈（`--base` > 預設分支 > origin/HEAD）不同機制——故本案**只借用它跑 pitfalls 的管線、自行算好 diff_range 傳入**，不是整支沿用。另：該函式 fail-open 會回第三值 `unknown`（pitfalls 本身只吐 high/standard）——**`unknown` 一律走 `direct`**（保守：判不出風險就不強制 PR）。
- **config 讀取**：沿既有 `.lumos/config.json` 慣例（r2 席1 更正：真正共用 `config.json` 的是 `test_profile`/`platforms`；cochange/test-layers/lint 各有專屬檔）；未知 `flow` 值 → stderr 警告＋**退回 `direct`**；**無 `ci` 區塊 → 功能全關**（見上）。
- **`auto_merge` 前提硬檢（r2 席2 實查本 repo 現況：`allow_auto_merge=false`、無 branch protection、rulesets 空）**：
  - 開啟 `auto_merge` 前先驗兩件事：① repo 已開 Allow auto-merge（`gh repo view --json autoMergeAllowed`）② **該分支有必要檢查**——須**同時查 branch protection 與 rulesets**（`gh api repos/{o}/{r}/branches/{b}/protection` 與 `.../rules/branches/{b}`；後者不需 admin，前者需 Administration:read）。
  - **權限不足（403）或任一查詢失敗＝「無法證明前提成立」→ 一律拒用 `--auto`**（fail-safe，r3 席2+Codex：開 PR 的權限不等於讀保護設定的權限，最需要這道防線的貢獻者身分恰好最可能查不到），改走「本工具等綠再合」。
  - **缺 ①** → `--auto` 每次都失敗 → 降級「PR 已開、請人工合併」＋一次性提示怎麼開，rc 不變。
  - **缺 ②（更危險）** → `--auto` 沒有東西可等，會**立刻合併**、CI 都還沒跑完——**此時本工具拒用 `--auto`**，改為「等 `ci-wait` 綠後再 `gh pr merge --squash`」（本工具自己當閘）。
  - 兩種降級都在 stderr 說明現況，不視為錯誤。
- **GitHub 端硬保護（選配、與本案解耦）**：若日後要機械強制「紅燈不准進 main」，走 GitHub **Rulesets**（支援 evaluate 只記錄不擋的試跑模式、支援 bypass 名單保留緊急直推並留痕）——本 spec 不代設、不依賴其存在。

### [S1c] `lumos ship [--repo-dir D] [--base B] [--json]`——pr flow 的串接器（r2 席2：原文只提名未定義）

僅在 flow 解析為 `pr` 時使用；`direct` 路徑不需要它。

- **分支決定**：已在非 base 分支上 → 沿用當前分支；在 base 分支上 → 建 `lumos/<topic>-<sha7>` 新分支（topic 取自最新 commit 的 type/scope，無法解析則用 `work`）並把當前 commit 帶過去（`git switch -c`，不動已推出的歷史）。
- **PR**：`gh pr create --fill --base <B>`；**該分支已有開啟中的 PR** → `gh pr create` 會報錯，捕捉後改用既有 PR（`gh pr view --json number,url`）繼續流程，不視為錯誤。
- **base 解析（單源，[S1b] 的 tier 判定也用它）**：`--base` > `gh repo view --json defaultBranchRef` > `git symbolic-ref refs/remotes/origin/HEAD`；三者皆無 → rc2 明說「無法決定 base」。
- **合併**：依 [S1b] 的 `auto_merge` 前提硬檢決定用 `--auto` 或「本工具等綠再合」。
- **合併後複查（r3 席2+Codex 修：原文沒定義 sha 從哪來，本機仍停在 feature 分支、也沒 fetch 到 merge commit，照字面會複查到錯的 sha 而測項仍會過）**：
  1. 先輪詢 `gh pr view <n> --json state,mergeCommit` 直到 `state=MERGED`（`--auto` 只代表「已排程」不代表已合併）；
  2. 取 `mergeCommit.oid` 為 merge sha；
  3. 以 **`ci-wait --sha <merge_oid> --branch <base>`** 複查（故 `ci-wait` 簽名新增 `--sha`／`--branch` 兩旗標，不再只認本機 HEAD）＋寫帳。
  - 人工合併降級路徑（未啟用 auto-merge）：`ship` 印「PR 已開、待人工合併」後**直接返回 rc0**，不阻塞等待；複查責任回到人工合併者（skill 文件記此分岔）。
- **code-loop 留痕互動（r2 席3）**：pr flow 下 main 由 GitHub 端更新、本機 pre-push 不會在 main 上跑，故留痕綁在**分支 sha** 即可；但**人工合併降級路徑**若改用本機 merge＋push main，新 merge sha 會與留痕 sha 不符而被判過時擋下——此時正解是 `lumos code-loop pass --note "PR #N 分支上已終審，合併後 sha 變更"` 補記，不是 `skip`。此條寫進 [S5] 的 skill 文件。

### [S2] 修復重試迴圈（skill 紀律，機械原語由 [S1] 出）

`lumos-project-notes` skill 的收尾段與 code-loop 收斂後段各加一條——**僅當專案 `.lumos/config.json` 宣告 `ci` 區塊時**，push（或 `lumos ship`）成功後必跑 `lumos ci-wait`（r3 席2：原文是無條件祈使句，agent 照字面會對每個未宣告的既有專案每次 push 都等最長 600s——r2 剛修掉的「零侵入假承諾」在此路徑原地復發；紀律文字必須自帶條件）（[S1b] 三種 flow 共用同一套修復迴圈；差別只在「紅燈修在 main 上還是分支上」）：

- rc0（綠）→ 收工。
- rc1（紅）→ **當輪修**：讀 [S1] 印出的失敗步驟＋log 尾段 → 定位 → 修 → commit → push → **再跑一次 `ci-wait`**。
- **重試上限 2 次**（＝最多推三次）。仍紅 → **停、攤給人**，並把失敗步驟／log 尾段／已試修法寫成 Issue 節點（`Issues/CI-<sha7>-紅燈`，帶 `pitfall_when`），不無限燒。
- **flaky 判別（誠實，不自動化）**：同一 sha 重跑一次就綠 → 記為疑似 flaky 進 Issue，不當修好（避免「重跑到綠」變成掩蓋真 bug 的慣性）。
- **[S1c] 的 code-loop 留痕指引與 [S2] 全段同屬 skill 紀律層（同誠實天花板一類），非機械閘**（r3 席3：[S1c] 該條原缺同款免責聲明，易被誤讀為遺漏測試）：重試上限、flaky 判別、Issue 產出都靠自覺遵守＋收尾報告留痕；工具端只出 rc1 訊號與失敗證據（[S1]）。明文記此邊界，勿誤以為有機械保證。
- **紅燈不過夜**：修不完就寫 Issue 並在收尾報告明講「main 上有紅燈未解」，不得靜默收工。

### [S2b] 後備網（主路徑失效時才用，都只提醒不擋）

1. **SessionStart hook（新建）**：讀帳最後一筆，紅則開場注入提醒；綠／無資料靜默。
   - **落地三處必改（r1 實查，缺一即靜默失效）**：① 新 hook 檔進 `scripts/hooks/claude/`；② 登記進 `merge-claude-settings.py` 的 `HOOK_ENTRIES`（新事件 SessionStart）；③ **檔名加進 `scripts/lumos` 的 `_GLOBAL_CLAUDE_HOOKS` 白名單**——否則檔案不被複製到 `~/.claude/hooks/`，下次 init/bootstrap 時 `_prune_dangling` 會把註冊剪掉。
   - **生命週期對稱（impact hook 推播命中 [[Issues/hook卸載殘留註冊]]，其通則正中本案）**：該事故通則＝「凡 A 端刪除／B 端引用的成對資源，守衛要嘛對稱操作、要嘛 B 端懸空自癒」；本案是同一面鏡子的另一面「註冊了沒複製＝silent no-op」——故三處必改缺一不可，且 [S4] 須有測項釘住「註冊存在 ⟺ 檔案存在」（沿既有 `t_merge_settings_prunes_dangling` 的守衛精神）。
   - **輸出契約**：沿 PreToolUse hook 的 stdout JSON 形式（`hookSpecificOutput.additionalContext`），不用 Stop hook 的 stderr+exit2（事件語意不同）。
   - **提醒精準度（r1+Codex）**：帳檔加 `branch` 欄；觸發條件＝最後一筆為紅 ∧ 其 sha 是當前 HEAD 祖先 ∧ 其 branch＝當前分支——防「從紅 sha 開的新分支被永久提醒」。
2. **pre-push**：同上三條件 → stderr 一行提醒（不改 rc、不新增擋點）。**插入點明定（r1 實查）**：須放在 `have_vault` 早退之前——否則無 vault 的 repo 永遠看不到提醒。
3. **`lumos gov` 第 7 源**：CI 事件併入治理時間軸。**mapper 欄位明定（一律 `d.get(...)` dict 存取，對齊既有六源——r1 指正屬性存取會讓 `lumos gov` 全源炸掉）**：ts／commit（取 sha）／gate＝ci／kind（取 conclusion，缺則 ?）／hard＝False／nodes＝[]／token（取 dedup_key，第 5 去重鑑別子）／detail（title＋failed_step 串接後 strip）。**無 severity 欄**（CI 事件無嚴重度語意）。**總開關在 gov 端的落地（r3 Codex）**：`cmd_gov` 現不讀 `.lumos/config.json`——本源需先讀 config，**未宣告 `ci` 區塊即完全不 load 此帳**（否則專案移除宣告後歷史 CI 事件仍會顯示，違反「功能全關」）。

### [S3] 帳與離線查詢

- `lumos ci-status`（唯讀、不打網路）：印帳上最後一筆＋`(檢查於 <ts>)`；超過 24 小時加註可能過期。供 hook 與離線用。
- **帳檔（單源，全 spec 以此為準）**：檔名**字面釘死＝docs／.ci-log.jsonl**（讀作 docs 目錄下、點號開頭的 ci-log.jsonl；續審再指正前版「敘述式收窄不算釘死」——實作三處（gitignore／cochange exclude／gov load）需逐字同一字串，此處即權威）；欄位 `{ts, run_id, attempt, sha, branch, workflow, conclusion, title, url, failed_step, dedup_key}`——`branch` 供跨分支防誤提醒（r2 席1：原單源清單漏此欄，但 [S2b]/[S4] 都依賴它）；`workflow` 供多 run 分筆；`failed_step` 僅紅燈非空。
- **只在終局寫帳（r1 修矛盾：原文暗示 in_progress 也記，與 [S1] 終局寫帳打架）**：`ci-wait` 只在**綠／紅／未定／逾時**四種終局各寫一筆；輪詢中的 `in_progress` 不寫帳。
- **去重是應用層責任（r1 實查：`_jsonl_append_verified` 是「無條件寫入再讀回自驗」，不是 upsert，擋不了重複）**：寫入前先掃帳檔，已存在同 `dedup_key`（＝`run_id:attempt:conclusion`——**加 `attempt`**，續審：`gh run rerun` 沿用同一 run_id 只增 attempt，「紅→重跑→又紅」第二筆會被吞掉，而 [S2] 的 flaky 紀律正需要看到重跑次數）→ 跳過寫入直接輸出（不算失敗）；否則才呼叫 helper（`key_field` 傳 `dedup_key`）。
- **逾時且該 sha 的 run 從未出現**：`run_id` 記 null、`dedup_key` 改用 `nosha:<sha>:timeout-waiting`（避免此型互相去重吞掉）。
- **SessionStart hook 與 `ci-status` 皆不打網路**（避免拖慢開場）；只有 `ci-wait` 會連線。

### [S4] 測試（TDD，拆**四**函式：`t_ci_wait`／`t_ci_status_and_gov`／`t_ci_hooks`／**`t_ci_ship_flow`**；gh 一律 fixture 腳本，**不打真 API**）

**歸屬明定（r3 席3：測項 19/20/23/24/25/26 測的都是 ship／flow 分派，不屬前三支任一職責）**：測項 1-18b→`t_ci_wait`＋`t_ci_status_and_gov`＋`t_ci_hooks` 依主題分；**19/20/23/24/25/26→`t_ci_ship_flow`**。

1. `gh` 不存在（PATH 隔離）→ ci-wait rc0＋stderr 說明＋不寫帳；
2. 假 `gh` fixture（第一次回 in_progress、第二次回 success）→ 輪詢後 rc0、寫帳一筆（狀態變化各一筆）；
3. 假 `gh` 回 failure ＋ `--log-failed` 吐固定文字 → **rc1**、輸出含失敗步驟名與 log 尾段（截 4000 字）；**步驟名須取自 jobs JSON 非 log 解析**（r3 席3：不明釘資料來源，錯誤實作會用 log 硬解也矇混過關）；
4. 只認**當前 HEAD sha 的 run**：fixture 回別的 sha 的 run → 不當結論、繼續等到逾時；
5. 逾時（`--timeout 1` ＋ 恆 in_progress fixture）→ rc0＋提示，帳記 `timeout-waiting`；
6. `--json` 單行純 JSON（含 conclusion/url/failed_step）；
7. `ci-status` 唯讀不呼叫 `gh`（fixture 設成呼叫即失敗，仍 rc0、讀帳輸出）；帳 >24h 加註過期；
8. gov 第 7 源顯示 CI 事件；
9. SessionStart hook：紅且為祖先 → 注入；綠 → 靜默；紅但 sha 非祖先（已 rebase 掉）→ 靜默；
10. pre-push 提醒：帳最後一筆紅且為祖先 → stderr 有提醒且 **rc 不變**（不新增擋點）；綠 → 無提醒；
11. 去重：同 run 同 conclusion 連跑兩次 → 帳只一筆；
12. 寫後自驗失敗（帳檔 symlink→/dev/null）→ ci-wait 印落盤自驗失敗、rc2（沿 `_jsonl_append_verified` 既有語意，優先於紅燈 rc1）；
13. **`--repo-dir`**（非舊名 `--repo`——r2 三方同報測項殘留舊旗標，照抄只會測到 argparse 未知旗標的巧合 rc2）指非目錄 → rc2；`gh` 未登入 → rc0 fail-open＋stderr；非 GitHub remote → rc0 fail-open；
14. conclusion 九值分類：neutral／skipped → rc0 綠；cancelled／action_required／stale → rc0 未定且不取失敗步驟；timed_out／startup_failure → rc1 紅；
15. 多 job 平行失敗 fixture（兩 job 各有失敗 step）→ failed_step 含兩者（`;` 串接）且取自 jobs JSON 非 log 解析；
16. log 兩上限依序：先 40 行後 4000 字（構造 100 行超長 log 驗）；
17. 逾時且 run 從未出現 → run_id null、dedup_key 走 nosha 形式；兩個不同 sha 的逾時各記一筆（不互吞）；
18. branch 欄與提醒精準度：紅 sha 是祖先但 branch 不同 → hook 靜默；
18b. hook 生命週期對稱：新 hook 同時在 `HOOK_ENTRIES` 與 `_GLOBAL_CLAUDE_HOOKS` 白名單中（缺一即紅），且 merge 後註冊不被 `_prune_dangling` 剪掉；
19. **flow 分派**：無宣告 → 走 direct（不呼叫 gh pr，行為與現況逐字相同）；`flow=pr` → 呼叫 pr create/merge（fixture 攔截）；`flow=tier` ＋ pitfalls 吐 `tier: high` → 走 pr 路徑，吐 `standard` → 走 direct；未知 flow 值 → 警告＋退 direct；
20. **auto_merge 降級**：`gh pr merge --auto` fixture 回失敗 → 印「PR 已開、請人工合併」、rc 不變（非錯誤）；
21. **總開關**：無 `ci` 區塊 → `ci-wait`/hook/gov 源全靜默，且 skill 紀律不觸發（行為與功能未安裝時逐字相同）；
22. **多 run 聚合**：同 sha 兩個 workflow（一綠一紅、紅的較慢完成）→ 判紅、rc1、兩筆各記帳（不因先綠者收工）；
23. **auto_merge 前提**：無必要檢查 fixture → 不用 `--auto`、改等綠再合；未開 allow-auto-merge fixture → 降級提示、rc 不變；
24. **合併後複查**：ship 在合併後對新 main sha 再跑一次 ci-wait 並寫帳（fixture 驗第二次呼叫發生）；
25. **base 解析**：`--base` 優先 > 預設分支；三者皆無 → rc2；tier 判定用 merge-base 範圍（非兩點）；
26. **ship 分支決定**：在 base 上 → 建新分支；已在分支 → 沿用；PR 已存在 → 沿用既有 PR 不報錯；
27. **grace period**：判綠前的重查窗內出現新 run → 繼續等（fixture：第二次列表多一個 in_progress run）；
28. **合併後複查取 sha**：ship 對 `gh pr view` 輪詢至 MERGED、取 mergeCommit.oid，並以 `--sha` 複查（fixture 斷言第二次 ci-wait 帶的是 merge oid 而非分支 sha）；
29. **前提查詢 403**：branch protection 查詢回 403 → 拒用 `--auto`（不誤判為「無必要檢查」）；rulesets 查得到必要檢查 → 可用；
30. **gov 總開關**：移除 `ci` 區塊後 `lumos gov` 不再顯示歷史 CI 事件；
31. **tier=unknown**（fixture 讓 pitfalls fail-open）→ 走 direct；
32. **`ci.workflow` 指定路徑**：宣告單一 workflow → 只等該支（fixture 讓另一支同 sha 的 run 恆 in_progress，仍能判綠收工）；宣告陣列 → 等該子集全部；未宣告 → 走聚合＋grace（沿測項 22/27）；
33. **重試上限機械面**：`ci-wait` 不含重試邏輯（重試是 [S2] skill 紀律）——測項僅釘「rc1 時輸出含可據以修復的失敗步驟＋log 尾段」，重試次數不由工具強制（明文取捨：紀律面不機械化，防工具替人決定何時放棄）。

### [S5] 文件

- README 指令參考加 `ci-wait`／`ci-status`／`ship` 三行＋`.lumos/config.json` 的 `ci.flow` 宣告一段（含「無宣告＝現況不變」的醒目說明）＋工作流圖加「push → ci-wait → 紅則當輪修」一步；**skill 文件**補兩條（r3 席3：原 [S1c] 承諾寫進 [S5] 卻未列入交付範圍）：① pr flow 人工合併後 sha 變更 → 補 `code-loop pass` 非 `skip`；② 合併後複查的責任歸屬（自動合併＝ship 做、人工合併＝合併者做）。**README §8「治理事件帳」**更新為七帳（r2 席3 實查更正：ARCHITECTURE 無此段落，且 README 現文還停在「三個 JSONL」＝已落後現碼六源，本次一併補正）；**`cmd_gov` docstring「六帳」改七帳**（in-code 文件同步）；**新帳檔補進 vault `.gitignore` 樣板與 `_COCHANGE_DEFAULT_EXCLUDE`**（比照既有六帳，防誤入版控與假共改警訊）。
- 本節點記「為什麼不做雲端 autofix」，供未來重議時看得到取捨。

## 實務隱患

- `gh` 未登入時 `gh run list` 會回錯誤而非空結果 → fail-open 需吃 rc≠0 與空輸出兩型。
- 同一 sha 可能有多個 workflow（未來擴充）→ v1 只取最近一次 run，明文限制。
- 分支切換頻繁時快取最後一筆可能屬別的分支 → 記錄帶 sha，推播前驗「是當前分支祖先」才提醒。

## 審計修正紀錄

- **pre-flight**（2026-07-29，機械 checklist＋現碼實查，不計 loop findings）：①rc 規格自相矛盾（「恆 0」vs 紅燈 rc1，會讓主路徑失去觸發訊號）→ rc 明定五態；②`--refresh` 誤植（`ci-wait` 恆打網路，讀快取是 `ci-status` 語意）→ 刪；③帳檔欄位兩處打架＋檔名未定 → 單源定義於 [S3]＋補 `dedup_key` 欄（對齊 `_jsonl_append_verified` 實查簽名）；④PRIOR-ART 誤述「SessionStart hook 已存在」→ 實查僅 PreToolUse/PostToolUse/Stop 三事件，更正為新建；⑤gov mapper 欄位未定 → 對齊既有 load() 契約逐欄明定；⑥[S4] 測試名與慣例不符＋漏 6 型 → 拆三函式＋補測項 10-14；⑦重試/flaky/Issue 屬紀律層非機械閘 → 邊界明文（防誤以為有機械保證）。
- **r1 panel**（2026-07-29，3 席 sonnet＋Codex 否決；**三席 canary 全中**；存活全機械證實免辯方）：[major] ①`--repo` 與 gh 原生 `-R` 語意相反、直傳被拒 → 更名 `--repo-dir`＋自行解析 owner/repo（四方同報）；②conclusion 當紅綠二分、實有九值 → 三類明定（席2）；③`--log-failed` 非結構化 step API＋多 job 交錯 → 步驟名改走 `--json jobs` 且全列（席1+Codex）；④gov mapper 用屬性存取會讓 `lumos gov` 全源炸、且 severity 欄是幽靈 → 改 dict 存取＋刪欄（席2）；⑤`_jsonl_append_verified` 不是 upsert、去重須應用層自己擋 → 明文（席3）；⑥SessionStart hook 漏 `_GLOBAL_CLAUDE_HOOKS` 白名單 → 註冊會被 `_prune_dangling` 剪掉而靜默失效 → 三處必改＋輸出契約明定（席3+Codex）；⑦pre-push 提醒若放 `have_vault` 早退之後永不觸發 → 插入點明定（席3+Codex）；⑧rc 表與測項 12 打架（自驗失敗 rc2 未入表）→ rc 單源含優先序；⑨in_progress 是否寫帳自相矛盾 → 只在四終局寫帳；⑩`DEP` 指向不存在的節點（ghost）→ 改指真實治理帳節點（席2）。[minor] 逾時無 run_id 的 dedup 形式；log 兩上限定序；branch 欄防跨分支誤提醒；`cmd_gov` docstring 六→七帳；新帳檔補 gitignore 與 cochange exclude。測項補 14-18。
  canary 帳：席1 caught（b 型幽靈旗標）、席2 caught（c 型幽靈欄位，並點出屬性存取致命）、席3 caught（d 型幽靈產物）。
- **r2 panel**（2026-07-29，彈性版 delta；3 席 sonnet＋Codex；**三席 canary 全中**；存活全機械證實免辯方）：[major] ①**「無宣告＝零侵入」是假承諾**——原文要求三 flow 共用等待紀律，等於每個既有專案裝上就被迫每次 push 多等最長 600s → 改以「有無 `ci` 區塊」為總開關（席3，直接打臉本輪設計賣點）；②多 workflow 只取一筆會假綠（快 lint 先綠收工、慢 integration 後紅沒人看到）→ 等該 sha 全部 run 完成、任一紅即紅（Codex）；③`auto_merge` 前提未驗：本 repo 實查 allow_auto_merge=false 且無必要檢查——缺前者每次降級（功能虛設）、缺後者 `--auto` 會立刻合併（CI 還沒跑完，賣點反噬）→ 前提硬檢＋兩種降級路徑（席2）；④squash merge 後 main 是全新 sha、非分支 sha 子孫 → 分支綠≠main 綠，且祖先型提醒對 pr flow 恆靜默 → 合併後必須再等一次 main run 並寫帳（席2）；⑤`lumos ship` 全篇只提名未定義（分支命名/已在分支/PR 已存在/base 解析全空白）→ 新增 [S1c]（席2）；⑥tier 用兩點 diff 會被 base 端演進污染 → 改 merge-base，沿用既有寫法（席1+Codex）；⑦帳檔單源 schema 漏 `branch` 欄但他處依賴、且檔名未釘死 → 補欄＋釘死單一檔名（席1+Codex）；⑧code-loop 留痕綁 sha，人工合併降級路徑會被判過時而誤擋 → 正解記為補 `pass` 非 `skip`（席3）。[minor] 測項 13 殘留舊旗標 `--repo`（三方同報）；`_jsonl_append_verified` 訊息硬編 canary 前綴須參數化；config.json 慣例引用錯（真正共用者是 test_profile/platforms）；README §8 而非 ARCHITECTURE，且現文停在三帳需一併補正。測項補 21-26。
  canary 帳：席1 caught（c 型幽靈欄位）、席2 caught（d 型幽靈 schema 檔）、席3 caught（a 型假引用）。
- **r3 panel（終輪，2026-07-29；3 席 sonnet＋Codex；**三席 canary 全中（三連）**；存活全機械證實免辯方）：[major] ①**零侵入假承諾在 [S2] 原地復發**——r2 才修過的同型錯：紀律文字是無條件祈使句，agent 照字面仍會對未宣告專案每次 push 等 600s → 條件寫進紀律句（席2）；②合併後複查取不到正確 sha（本機停在分支、未 fetch merge commit；`--auto` 只代表已排程非已合併）→ 輪詢 PR 至 MERGED 取 mergeCommit.oid＋`ci-wait` 新增 `--sha`/`--branch`（席2+Codex）；③auto-merge 前提硬檢的權限現實：讀 branch protection 需 admin 權限，開 PR 的人不一定有；且必要檢查也可能來自 rulesets → 兩處都查、403 一律 fail-safe 拒用 `--auto`（席2+Codex）；④晚註冊 run 的假綠：r2 的修法只是把漏洞從「完成時間」搬到「註冊時間」→ 加 grace period 重查＋明文「緩解非保證」（席2）；⑤r2 誤述「沿用既有 merge-base 寫法」——該函式硬編 main/master 且無 base 參數，機制不同 → 改為只借管線、自算 range，並定義 fail-open 第三值 `unknown` 走 direct（席1）；⑥gov 端總開關要讀 config，否則移除宣告後歷史事件仍顯示（Codex）；⑦帳檔名字面自相矛盾（自稱 dot 前綴卻沒 dot）→ 敘述式釘死，防三處各解讀成兩個檔（席1+Codex）；⑧測項 19/20/23-26 測的是 ship 卻無對應測試函式 → 拆第四支 `t_ci_ship_flow`（席3）。[minor] 測項 3 未釘資料來源；[S5] 漏收 [S1c] 承諾的 skill 文件兩條；[S1c] 留痕指引缺紀律層免責聲明；折入清單編號與測項對不上。測項補 27-31。
  canary 帳：席1 caught（d 型幽靈 schema 檔）、席2 caught（a 型假引用）、席3 caught（b 型幽靈旗標 `--draft-first`）。
  **cap=3 到頂**：三輪皆有效輪且三席全中，但每輪仍出真 major（本輪含一條 r2 同型復發）——依紀律停、攤人裁。
  **帳面時序偏差（如實記）**：r3 三筆 canary record 因折入腳本首跑中止而先於折入寫入，log 內 `reviewed`/`result` hash 為折入前版本；findings 內容與判定不受影響（審計報告在先、折入在後），惟 hash 鏈該輪不代表 post-fold 版——同 2026-07-28 testmap r3 的同型註記。
- **r3 後補充折入（2026-07-29，使用者指出，非新一輪審計）**：①PRIOR-ART 補 ⓪「自家後院已有實作」（Landmark 的發版輪詢腳本＝本案實戰驗證來源；家規三問第一問當時只查外部世界，漏查消費專案——教訓記入）；②借其形態新增 `ci.workflow` 選配宣告：**指定要等哪支 workflow 即可繞開聚合與晚註冊假綠兩個複雜度**（複雜度退回已在真環境驗證的等級），未宣告才走保守聚合路徑。測項補 32。
- **人裁放行（2026-07-29）**：續審 r1 後使用者裁定進實作。理由記：範圍手術已砍掉缺陷密度最高的 PR 路徑，v1 剩下的是 `ci-wait`＋帳＋後備網＋gov 一源；剩餘風險屬「外部行為（gh CLI/GitHub）對不對」型——**真 fixture 跑一次比再審一輪散文有效**（同 testmap 教訓）。兜底＝[S4] 測項矩陣＋CI＋code-loop 終審。

## 結案與正名（2026-07-29 外審 round3 吸收）

**status → done（v1 範圍）**。本節點自此為 v1 的歷史檔；PR flow / `ship` / auto-merge / tier 混合等仍留在上文的
設計段落，**均屬未實作的 v2 構想**，讀本節點時勿當現況（外審實錘：節點 `status: doing` 又留著整套 PR 設計，
與 code 的 direct-only 實作對不上）。v2 若啟動另開節點。

**★正名：「閉環」→「觀測」★**（外審兩輪的一致判詞，此處採納）
`ci-wait` **不是強制面**：它擋不了 push、擋不了 merge、擋不了 direct-to-main；`gh` 缺席／config 壞損／逾時／
無 run 一律 fail-open rc0。它買到的是**回饋延遲**（雲端紅 → 同輪知道 → 當輪修），不是控制。
續稱「閉環」會製造「反正 agent 會修」的道德風險，讓 branch protection 這種**真**強制面被無限延後。
要「紅燈進不了 main」，唯一的路是 GitHub 端 required status check（backlog ⑥，人工設定，本工具不碰）。

## r3 外審抓到的實作缺陷（皆已複驗屬實並修）

| 缺陷 | 實況 | 修法 |
|---|---|---|
| **假綠**：completed 且非明列紅即判綠 | `cancelled`／`action_required`／`stale`／未知未來值全被判 green——**計劃 [S1] 早就寫了三分類矩陣，實作只做二分** | 綠改**白名單制**（只認 `_CI_GREEN`），非綠非紅一律 `undetermined` rc0＋提示人判；4 個 conclusion＋混合案共 10 檢查，mutation 驗過（退回舊碼即 5 紅） |
| **紅燈證據看不到** | `failed_step`／`log_tail` 只進 `--json`；預設文字輸出只有狀態＋URL，人跑指令拿不到任何可修線索——而 README／兩支 skill／本節點都承諾會印 | 文字 emitter 補印失敗步驟＋log 尾段；斷言直接驗 stdout（非 rc），mutation 驗過 |
| **`ci-status` 同型假綠** | 只讀檔尾最後一筆；同 sha 多支 workflow 時綠的排在後面就把紅的蓋掉（＝ r1 對 SessionStart hook 抓過的同一個坑，`ci-status` 漏修） | 改取最新 sha 的**全部**筆、報最壞的（紅 > 未定 > 綠），3 檢查 |

**教訓（進方法論）**：同一類缺陷在一個功能裡會出現在**多個消費點**（hook／wait／status 三處讀同一份帳）。
r1 修了 hook 那處就以為修完了——**修一處不等於修一類**，該當場列出全部消費點逐一檢查。
