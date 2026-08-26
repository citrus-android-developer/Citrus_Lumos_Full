# 設計:放行前跨家族複核(cross-family-audit)

- 日期:2026-06-22
- 狀態:**人工定稿放行**(2026-06-22 design-loop 6 輪、canary 6/6 全 caught、達 cap 未自動收斂;剩 F2/F4 屬文檔級無 blocker,人工 review 放行進 writing-plans。本 spec 由 opus 單審——qwen 機制尚未上)
- 動機來源:backlog gap[4]「6/20 放棄 judge 抗自偏,結論建在『換模型家族做不到』,漏了…解法」+ 2026-06-22 實戰(opus canary missed 2/6、把 python3-m 真 blocker 低估成 minor)
- loop_id:cross-family-audit

## 目標(一句話)

autonomous loop 的 design-loop 在判定收斂、真正放行前,多一道 **qwen3-max 跨家族複核**,補 opus 同門盲點;qwen 提出 major+ 異議則退回讓 opus 驗證,API 不可用則 degrade 回 opus 放行並標註。

## 前提與既驗事實

- **跨家族補盲已實證**(2026-06-22 PoC):同一份草稿,opus 6 輪把 `python3 -m` import 失敗只標 minor,qwen3-max 一次判 blocker(已 ground-truth 坐實 `governance/__init__.py` 不存在)。
- **qwen 走 API 無 grep**:不餵 ground-truth 會誤報(PoC 1 誤判 `$PENDING` 未定義);餵了 `autonomous-loop.sh` 全文 + 目錄結構後,誤報消失且多挖到 3 個真問題(PoC 2)。
- **key 已驗**:`sk-...`(存 config、不入 repo)走**國際 endpoint** `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`(國內 endpoint 回 401),OpenAI 兼容模式,`qwen3-max` 可調。
- **計費前提(風險)**:`qwen-max` 舊別名回過「free tier 已耗盡」,暗示此帳號靠免費額度。正式啟用前須至 Model Studio console 確認有付費額度;額度耗盡(429)由 degrade 閘涵蓋(不致卡死 loop)。

## 邊界 / 非目標(YAGNI)

- ❌ **不每輪跑 qwen**:只在關鍵放行輪(design-loop 判定收斂那一刻)觸發。
- ❌ **不用 qwen 當 severity judge**:每輪 severity 仍歸 judge-severity-gate 的獨立 opus judge(orchestrator-prompt §2 步驟 4);qwen 是放行前的額外關卡,不取代既有 judge。
- ❌ **不本地跑 qwen**:API only(本機 M1 Pro/32G 能跑的 30B-A3B 留作未來 $0 後路,非本 spec)。
- ❌ **不支援 GPT/其他家族**:只接 qwen(YAGNI;$0 OAuth 只路由 Claude,qwen 是唯一已驗的跨家族補充)。
- ❌ **不改 design-loop 每輪流程**:orchestrator-prompt §2(Design-loop)的每輪 8 步驟不動,只在步驟 8 收斂判定後加一步。
- ❌ **不改 canary / lumos 原語 / judge-severity-gate / confidence_report / build_report**(R4:結果回流改走扁平欄位,完全不碰可信度報告)。

## 架構:觸發點與資料流

跨家族複核插在 **orchestrator 內部** design-loop 的收斂判定處(orchestrator-prompt §2 步驟 8 `loop status --need 2` exit 0 後、§3 輸出前)。**不可放在 wrapper 層**:autonomous-loop.sh 收到 orchestrator 結果時 design-loop 已結束,退不回繼續審、也拿不到逐輪狀態。orchestrator 有 Bash/Agent 工具(autonomous-loop.sh:L43 `--allowedTools "Read,Edit,Bash,Grep,Glob,Agent"`),能 grep 取材 + 調 cross_audit.py。

```
design-loop §2 步驟 8 達標(連 2 輪 caught + severity∈{clean,minor})
  │
  ├─① opus 取材:grep/Read spec 引用到的檔案/符號,整理成 ground-truth 片段
  │   (opus 本輪 §2 步驟 3 強制地面事實查證時本來就查過,取材近乎免費)
  │
  ├─② 調 cross_audit.run_cross_audit(spec, canary_log, ground_truth) → qwen3-max(refute framing)
  │
  └─③ 依回傳(**先判 status**;degraded 態無 worst_severity 鍵,不可讀,防 KeyError):
       ├ status=ok 且 worst ≤ minor → 收斂(converged:true);cross_verdict=endorsed
       ├ status=ok 且 worst ≥ major → 把 qwen findings 當「新一輪 audit」:
       │     opus 自己 grep 驗證每條 → 真的則折進 spec、誤報則在審計紀錄標反證(ground truth)
       │     cross_reject_count += 1;回 §2 步驟 1 繼續(換 canary、N+1)
       │     └ cross_reject_count ≥ 2 → 停、converged:false、cross_verdict=disputed
       └ status=degraded(無 key/http_<code>/超時/error)→ 照常收斂(converged:true);cross_verdict=degraded
```

**結果回流(R4 簡化,消 F-A/F-B/F-C)**:cross_audit 結果**不進 build_report、不寫跨程序檔**(該數據流反覆出 major:報告層級錯亂 / `$SCRATCH` 跨程序歸因 / dict-vs-檔路徑型別死結,與前輪 F2 同源)。改為 orchestrator 在 §3 result JSON 輸出**三個扁平欄位**:`cross_verdict`(endorsed|degraded|disputed)、`cross_worst`(severity)、`cross_summary`(短單行摘要)。autonomous-loop.sh 用既有 `get()` 取三欄,寫進 `log` 與 LINE notify:endorsed/degraded(放行)走收斂分支、disputed(不放行)走未收斂分支(L77-85)——兩出口統一、皆不碰 build_report、不寫檔。

**收斂條件變更**:原「連 2 輪 caught + severity∈{clean,minor}」(scripts/lumos `good()`)維持不變,**疊加跨家族三態(F6)**:`endorsed`=通過 / `degraded`=旁路放行(fail-open,API 不可用時不卡死,log/LINE 標註)/ `disputed`=否決不放行。degraded 是『複核被旁路』非『通過』,計入放行屬刻意 fail-open(見誠實天花板 #4),不偽裝成「滿足要求」。(注:`good()` 是 scripts/lumos `cmd_loop_status` 內的巢狀函數、只決定 `loop status` exit code;qwen 複核是 **orchestrator-prompt 層的疊加步驟**,scripts/lumos 一行不動——本變更不碰 `good()`。)

**失控保護**:`cross_reject_count` 累計;達 2 → 升級給人裁決(不放行 + cross_summary 標明)。同時仍受 design-loop 原 `__MAXR__`(預設 6 輪)cap 約束。

## 組件(新建 / 改動)

### 新建:`governance/autonomous_loop/cross_audit.py`

```python
def run_cross_audit(spec_text, canary_log_path, loop_id, ground_truth,
                    key_path="~/.config/ai-daily/qwen_api_key",
                    model="qwen3-max", timeout=120, temperature=0.2):
    """
    回傳 dict,status 三態:
      {"status":"degraded","worst_severity":null,"reason":"no_key"}     # key 檔不存在
      {"status":"degraded","worst_severity":null,"reason":"http_<code>(含 429)"|"timeout"|"error:..."}  # API 失敗(F4:worst_severity 統一回 null,免無條件讀鍵 KeyError)
      {"status":"ok","worst_severity":"<clean|minor|major|blocker>",
       "findings":"<qwen 全文>","usage":{...}}
    步驟:
      1. 讀 key(展開 ~);不存在 → degraded/no_key
      2. 讀 canary_log_path,過濾 loop==loop_id(沿用 confidence_report 讀法),組「收斂證據」
      3. 組 refute prompt:spec_text + 收斂證據 + ground_truth(opus 取材片段)
         指令:逐節找洞、基於提供的真實代碼審、最後一行輸出「最嚴重 severity = <值>」
      4. urllib POST dashscope-intl compatible-mode(無第三方依賴,同 PoC)
      5. 解析 worst_severity:正則抓「最嚴重 severity = X」;抓不到 → 從 findings 掃
         {blocker>major>minor>clean} 最高者(防 qwen 沒照格式)
      6. 逾時 / 非 200 / 例外 → degraded(reason 帶 http_<code> 或 exception)
    """
```

- **verdict 判定在 orchestrator(prompt 層),非此模組**:run_cross_audit 只回 status + worst_severity;orchestrator 據此決定 cross_verdict(ok+≤minor→endorsed / ok+≥major→disputed 流程 / degraded→degraded)並寫 §3 扁平欄位。
- **調用方式**:由 **orchestrator 端**用 `python3 -c "import sys;sys.path.insert(0,'$REPO/governance');from autonomous_loop import cross_audit;..."`(**絕對路徑版**,對齊 autonomous-loop.sh:L64/80/98;orchestrator cwd 未必是 REPO,不可用相對路徑版 L25/48/88)。**禁用 `python3 -m governance.autonomous_loop.cross_audit`**:`governance/` 無 `__init__.py`(頂層非 package),雖 `governance/autonomous_loop/__init__.py` 存在,`-m` 仍會因頂層 `governance` 非 package 失敗;現有代碼正是靠 `sys.path.insert('$REPO/governance')` + `from autonomous_loop import` 繞過(2026-06-22 auditor 坐實)。
- **endpoint/model**:`https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions`,`qwen3-max`,`temperature=0.2`。
- 無第三方依賴(urllib),與現有模組一致。

### 改:`governance/autonomous_loop/orchestrator-prompt.md`

§2 步驟 8(`loop status` 收斂判定)後新增**步驟 9「跨家族複核」**(放行前、只收斂時做一次)。**步驟 9 覆寫步驟 8 的終止語意(F4)**:步驟 8 `loop status exit 0` 不再直接終止 loop,改由步驟 9 複核後決定——endorsed/degraded→終止並放行、disputed→續審或達 2 次終止不放行;orchestrator-prompt 改寫時須明文覆寫步驟 8 的「則停」。複核流程:依上述資料流——opus 取材 → 調 cross_audit → 判 cross_verdict → endorsed/degraded 則收斂、disputed 則折入 qwen findings(opus 驗證後)續審、達 2 次 disputed → **§3 輸出 `converged:false` + `cross_verdict=disputed`**(釘死 F2:disputed 必伴 converged:false,才走得進 wrapper 未收斂分支)。§3 輸出 JSON 新增**三個扁平欄位** `cross_verdict`(endorsed|degraded|disputed)、`cross_worst`(severity)、`cross_summary`(短單行摘要,orchestrator 自保證單行無換行,供 log/LINE);不用巢狀物件(autonomous-loop.sh `get()` 只取頂層欄位)。

### 不改:`governance/autonomous_loop/confidence_report.py`

**R4 決定不動 build_report**:原方案「加 cross_audit 參數 + 報告節」有報告標題層級錯亂(H2 節插進既有 H2「收斂可信度報告」與其 H3「⚠ 沒檢查到的維度」之間,破壞層級 — F-A)、且 dict-vs-檔路徑型別死結(F-C)。cross_audit 結果改走 orchestrator result JSON 扁平欄位 + log + LINE(見架構「結果回流」)。可信度報告維持原樣,既有 test 不動。

### 改:`governance/autonomous-loop.sh`

從 PARSED 取三個扁平欄位(沿用 L58 `get()`):`CROSS_VERDICT="$(get cross_verdict)"`、`CROSS_WORST="$(get cross_worst)"`、`CROSS_SUMMARY="$(get cross_summary)"`。

- **收斂放行分支**(L87 後):`log` 一行 + LINE notify 訊息附「跨家族:$CROSS_VERDICT($CROSS_WORST)— $CROSS_SUMMARY」(承載 endorsed/degraded)。
- **未收斂分支**(L77-85):依 `$CROSS_VERDICT` 區分 notify 文案(F2)——`disputed` → 『跨家族否決(qwen 持續異議)』+ $CROSS_SUMMARY;否則維持原『撞 cap/未收斂』。**不可沿用 L83 硬編碼『撞 cap』一概而論**(該句只適用真撞 cap,disputed 會誤導)。
- **不改 build_report、不寫跨程序檔**:`$SCRATCH` 跨程序(前輪 F6)與字面量注入(前輪 F4)問題隨之消失——`get()` 取的是 `json.load` 後的值、以 shell 變數傳遞給 `log`/notify,非 `python3 -c` 字面量拼接。
- **空值處理**:三欄缺失(舊 orchestrator / degrade 前)→ `get()` 回空字串,訊息該段省略,不報錯(set -euo 安全)。
- **防破版(F3)**:`$CROSS_SUMMARY` 取後把換行 replace 成空格(shell 參數展開或 tr),不純靠 orchestrator 自律保證單行。

### 新增(本機,不入 repo):`~/.config/ai-daily/qwen_api_key`

單行存 key,沿用 `claude_oauth_token`(autonomous-loop.sh:L39)模式。**不進 repo、不進 git**;cross_audit.py 讀不到 → degraded/no_key。spec/README 註明此檔需人手放置。

## 誠實天花板

1. **qwen 也是 AI**:跨家族**降低**共同盲點 ≠ 消滅「AI 評 AI」回歸,只把回歸推遠(兩個不同家族都漏才漏)。不是 oracle。
2. **opus 取材 = opus 框定 qwen 視野**:opus 漏 grep 的檔案/符號,qwen 照樣盲。視野上限由取材者決定,非 qwen 自主。
3. **qwen 誤報由 opus 下輪驗證兜,但 opus 驗證本身也可能錯**(遞歸未閉合;`$PENDING` 類誤報靠 opus grep 擋,但 opus 也會漏)。
4. **degrade 時無跨家族背書**:API 掛/額度盡 → 退回 opus 單審放行,log/LINE 明確標 degraded,讓放行的人知道這次少了一道。
5. **放行的人仍是最後也唯一真兜底**:本機制是「多一個不同家族的眼睛」,不改「放行=人 merge,絕不自動」。
6. **計費未閉環**:免費額度若靜默耗盡(429),degrade 會讓跨家族長期失效而 loop 照跑;須靠 console 監看額度(本 spec 不自動查餘額)。
7. **prompt 層自律張力(F3/F4/F6 揭示)**:orchestrator 是 LLM,cross_summary 單行、先判 status 再讀 worst_severity、verdict 判定都靠它自律——與本 spec『別信 LLM 自填』(judge-severity-gate 斷開自填)精神有張力。已加防呆(degraded 統一回 `worst_severity:null`、summary strip 換行)降低,但 **verdict 判定本身仍在 orchestrator 手裡、未完全斷開**;此為 prompt-orchestrated 設計的固有殘留,放行的人需知曉。

## 測試策略

- `cross_audit.py` **單元測試**(mock urllib,加入 `scripts/test_autonomous_loop.py`):
  - key 檔不存在 → `{"status":"degraded","reason":"no_key"}`
  - mock 200 + 回文含「最嚴重 severity = minor」→ `status=ok, worst_severity=minor`
  - mock 200 + 回文含「最嚴重 severity = blocker」→ `worst_severity=blocker`
  - mock 200 + 回文**沒照格式**(無「最嚴重 severity =」)→ 從內文掃出最高 severity(防呆)
  - mock 403/429 / timeout → `degraded` 且 reason 帶 `http_<code>` / timeout
- `confidence_report.build_report` **不改**(R4 決定),既有 test 不動。
- cross_audit 結果回流(扁平欄位 + log/LINE)由人工驗 dry-run log(sh 層難單元測,不強做整合 test)。
- `python3 scripts/test_autonomous_loop.py` 全綠,且總數 ≥ 原 16(寫 spec 當下基數)。
- **不寫**:真打 qwen API 的整合測試(單元 mock 即可;真連通已由本 spec 的 PoC 證明,且整合測試會燒額度)。

## 知識同步影響

| 受影響文件 | 需同步什麼 |
|---|---|
| `docs/methodology/架構圖即合約.md` | 自主 loop 段(§四自節)補:放行前跨家族複核 = 對抗同門偏心的具體機制 |
| `docs/methodology/架構圖即合約-對外論述.md` | 對外白話段補一句:loop 放行前由「不同家族的 AI」再看一眼 |
| `docs/design/2026-06-20-autonomous-iteration-loop.md` | §放行閘補:收斂後、放行前的 qwen 跨家族複核步驟 + degrade |
| `governance/autonomous_loop/orchestrator-prompt.md` | 見上:§2 末新增步驟 9 + §3 輸出加 cross_verdict/cross_worst/cross_summary 三欄 |
| `governance/autonomous_loop/cross_audit.py` | 新建此模組 |
| `governance/autonomous-loop.sh` | 取三扁平欄位 → 收斂/未收斂兩分支的 log + LINE |
| memory `autonomous-iteration-loop` | 補:放行閘加跨家族複核(gap[4] 的解、前提『換家族做不到』已被 qwen API 破) |

## 審計修正紀錄

> **語境(F2 澄清)**:以下 R1–R6 是**手動 design-loop**(主對話用 lumos-design-loop skill 編排、審這份 spec,canary 序 `[a,b,c,d][(N-1)%4]`(含 d)、token `CANARY-CFA-N`)。與 spec 正文描述的 **autonomous loop 內部 orchestrator design-loop**(限 a/b/c、禁 d、token `CANARY-AUTO-N`)是**不同語境、不同執行者**——本紀錄用 type d 不違反 spec 對 orchestrator 的規定,勿混淆。

### R1(2026-06-22,canary type a=壞§ref,opus,**CAUGHT**,severity=blocker)
canary(orchestrator-prompt §2.11 不存在)被識別。排掉 canary 後仍有同類真 blocker,一併折入:
- **Blocker(F1)**:orchestrator-prompt 章節引用全用不存在的小數點編號(§2.4/§2.8/§2.9)——真實檔為扁平結構(### 0/1/2/3,§2 下步驟 1–8)。全改「§2 步驟 N」。canary 與此真缺陷同類。
- **Major(F2)**:python3-m blocker 歸因修正——autonomous_loop/ 有 __init__.py、governance/ 無;真因是頂層 governance 非 package。
- **Minor(F3)**:調用改絕對路徑版 `sys.path.insert(0,'$REPO/governance')`(orchestrator cwd 未必 REPO)。
- **Minor(F4)**:cross_audit 摘要傳遞(R4 已改為扁平欄位,不再走 `python3 -c` 字面量)。
- **Minor(F5)**:build_report 相容(R4 已決定不改 build_report)。

### R2(2026-06-22,canary type b=未定義旗標,opus,**CAUGHT**,severity=major)
canary(`--cross-audit-dry` 未定義旗標、落點斷裂)被識別。排掉 canary 後仍有真 finding,折入:
- **Major(F1)**:相對路徑組行號修正 L24/47/87 → L25/48/88(off-by-one;auditor grep 坐實)。諷刺:R1 自夸修掉同類錯,卻在新引入行號重蹈,故此輪嚴查行號。
- **Major(F6)**:$SCRATCH 跨程序陷阱(R4 已隨「不寫跨程序檔」消除)。
- **Minor(F2/F3/F5/F7)**:呼叫點精確、good() 層級澄清、test 驗收、degraded 先判 status 防 KeyError。
- F4(`__init__.py`/`-m` 歸因)經 auditor 查證為 clean(R1 修正正確)。

### R3(2026-06-22,canary type c=未定義常數,opus,**CAUGHT**,severity=major)
canary(`MAX_CROSS_REJECT` 未定義常數、落點層級矛盾)被識別。排掉 canary 後仍有真 finding,折入:
- **Major(F1)**:build_report「必須改第 4 參」與「optional default 向後相容」自相矛盾(R4 已隨「不改 build_report」消除)。
- **Major(F2)**:disputed→converged:false 經 build_report 不可達(R4 已改 disputed 走未收斂分支 log+LINE)。
- **Minor(F3)**:temperature=0.2 加入 run_cross_audit 簽名。
- F4(MAX_CROSS_REJECT)為 canary,不折;真檔門檻維持硬編碼 `cross_reject_count ≥ 2`。
- 其餘(行號/__init__/sys.path/SCRATCH/good()/§結構/$PENDING/test 基數)經 auditor 全查證 clean。

### R4(2026-06-22,canary type d=未定義產物,opus,**CAUGHT**,severity=major)
canary(`qwen-verdicts.jsonl` 憑空產物)被識別。排掉 canary 後 3 個 major(F-A 報告層級錯亂 / F-B `$SCRATCH` 跨程序歸因 / F-C build_report 第 4 參 dict-vs-檔路徑型別死結)**全集中在「cross_audit 結果回流 build_report」這條數據流**——與前輪 F2 同源,反覆牽動。判定此組件為根因,**簡化(非打補丁)**:
- **砍掉**整條「寫 `.cross-audit.json` 跨程序檔 + 改 build_report 簽名 + 加報告節」數據流 → 一舉消 F-A/F-B/F-C + 前輪 F2/F4/F6。
- 改為 orchestrator 輸出三扁平欄位(cross_verdict/cross_worst/cross_summary),autonomous-loop.sh `get()` 取後走既有 log+LINE(收斂/未收斂兩分支),不碰 build_report、不寫跨程序檔、confidence_report 維持原樣。
- **Minor(F-E)**:路徑版本邊界敘述分清(orchestrator 絕對 / wrapper 相對)。
- **Minor(F-G)**:degrade reason 泛化 `http_<code>`(含 429 額度耗盡,正是計費風險主場景)。
- F-D(qwen-verdicts.jsonl)為 canary,不折(簡化後本就不寫該檔)。
- 行號/__init__/path/test 基數 auditor 再次坐實 clean。

### R5(2026-06-22,canary type a=壞§ref,opus,**CAUGHT**,severity=major)
canary(`§決策表` 不存在)被識別。排掉 canary 後折入:
- **Major(F2)**:disputed 出口前提沒釘死——① orchestrator §3 須明文輸出 `converged:false`(disputed 才走得進 wrapper 未收斂分支);② 未收斂分支 notify 不可沿用硬編碼『撞 cap』,須依 cross_verdict 區分『跨家族否決』vs 真撞 cap。
- **Minor(F3)**:cross_summary 改 wrapper 端 strip 換行防破版。
- **Minor(F4)**:run_cross_audit degraded 統一回 `worst_severity:null`,免 KeyError。
- **Minor(F6)**:收斂條件改三態表述(endorsed 通過 / degraded 旁路 / disputed 否決),不把 degraded 偽裝成滿足要求。
- **誠實天花板 #7 新增**:prompt 層靠 orchestrator LLM 自律 vs『別信 LLM 自填』哲學的固有張力,已防呆但 verdict 判定未完全斷開。
- canary(§決策表)+ Finding 5(token 殘留=工作副本現象)不折;代碼級 ground-truth 全坐實 clean。

### R6(2026-06-22,canary type b=未定義旗標,opus,**CAUGHT**,severity=major)
canary(`--cross-strict` 未定義旗標)被識別。排掉 canary 後:
- **Major(F2)**:審計紀錄與 spec 描述的 autonomous orchestrator 語境混淆(type d / token 命名)——已在審計紀錄區開頭加語境說明。
- **Minor(F4)**:步驟 8「exit 0 則停」vs 步驟 9 終止語意衝突——已在 orchestrator 組件段澄清步驟 9 覆寫之。
- Finding 3/8(--cross-strict 命名/無消費端)為 canary 延伸,不折。
- 行號/__init__/path/good()/confidence_report/build_report/test 基數 auditor 全坐實 clean。

---

> **達 cap 6 未收斂(2026-06-22)**:6 輪 canary **全 caught(6/6,opus 零漏、校准良好)**,但 severity 持續 blocker→major→major→major→major→major(每輪都有真 finding)。spec 經 6 輪已大幅打磨(ground-truth 全對、R4 砍掉反覆出問題的 build_report 回流數據流、disputed 釘死、防呆齊備),剩 F2/F4 屬文檔級/小、無 blocker。依 design-loop 護欄:**達 cap 未收斂 → 停、摊給人定稿**(放行的人是最後兜底)。
