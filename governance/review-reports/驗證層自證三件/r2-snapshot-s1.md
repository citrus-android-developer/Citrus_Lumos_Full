# 驗證層自證三件_計劃(r2 delta 審查材料=r1 折入後的全部受動段)
# 驗證層自證三件_計劃

PRIOR-ART: ① 最小解層級——主體是既有留痕與既有子命令(quote-check/refcheck/canary_calibration/canary record --canary-type)的讀取面與收貨慣例;唯一新增=一項新對帳機制(S1 有講沒做),產出兩份留痕檔:派工 manifest `rN-dispatch.json`(既有派工留痕的結構化補檔)+越界帳 `out-of-scope.jsonl`(全新格式);無新治理層、無新閘、無新依賴(r1 審計修正:原宣稱「零新機制」不成立,S1 有講沒做對帳需 prescribe 端資料,現況只活在派工 prompt 散文)。**內部 prior-art(r1 補)**:`lumos refcheck`(席報告 file:line 實在性原地可用)、`governance/eval/canary_calibration.py`+`plants.json`(固定題×多席判定矩陣=真 SNR 該接的資料結構)、[[Systems/canary-audit]] D 案(型別數據驅動,開工條件=帶型別記錄攢滿 15 筆,`--canary-type`/`--probe` 欄位 2026-08-05 已上線)。② 世界解=真搜真讀兩個 repo:**ClawBench**(openclaw/shellbench,⭐134,MIT)——trace-based scoring(read-before-write/self-verification 從執行軌跡機械判)、每題 SNR=跨模型變異÷同模型重跑變異(40 題殺 21 題雜訊題)、13 種失敗模式決定論分類、「judge 永不救活機械紅燈」寫成測試守著;**evidra**(vitas/evidra,⭐15,Apache-2.0)——prescribe→execute→report 三步協議+8 個純函數 signal(protocol_violation 對帳「有講沒做/有做沒講」、retry/repair/thrashing 三分、Growth test 準入三問+detector≤15 硬上限、明文禁 ML/自適應閾值=「同證據恆同分」)。③ 裁定=**borrow-design**(兩邊都只搬設計不搬碼:ClawBench 是 python 評測 harness、evidra 是 Go+Prometheus 多租戶棧,依賴與場景都不合;演算法本身零依賴可自寫)。

## 三件(按便宜×對上日報 gap 排序)

### S1 席位自證粗篩(borrow ClawBench trace-scoring + evidra protocol_violation)
收貨時對每席報告跑三道機械檢查,**前兩道是既有子命令直用、零新碼**(r1 審計修正:原稿兩處重造既有機制):
- **引句錨定**:`lumos quote-check <席報告> --spec <凍結快照>`(已上線;rc0/rc1 是退出碼,--json 欄位為 `total`/`miss`/`quotes[].ok`——無 `unverified` 欄位,該詞屬 verify-progress --settle 狀態機,勿混)。
- **file:line 指涉實在性**:`lumos refcheck <席報告> --repo <root>`——refcheck 是通用 inline-code 路徑/行號抽取(vault-free),對席報告原地可用(r1 實跑驗證:對歷史席報告成功抽 11 claim 判 ok/missing/out_of_range),**不另寫**。
- **有講沒做對帳**(evidra protocol_violation 語彙,本計劃唯一新碼):
  - 前提=補 prescribe 端留痕:派工當下把 `{round, seat, lens, materials:[被審檔], auditor}` 落 `governance/review-reports/<loop>/rN-dispatch.json`(留痕合約小擴充,與 snapshot/席報告同目錄同 commit 節奏)。
  - `unreported`=dispatch 宣告的 materials/lens 在報告中零觸及;`out_of_scope`=finding 的 spec 錨定引句落在 materials 之外。
  - **scope 三集合語意(r1 折入,防把必要查證誤記越界)**:materials=必查;repo 查證引用=恆合法(證據 file:line 永不算越界);只有 finding 的「被審對象錨定」出界才記 `out_of_scope`。
  - 越界帳=`governance/review-reports/<loop>/out-of-scope.jsonl`(欄位:`{round, seat, quote, reason}`;與席報告同 commit 節奏,不改 code-loop pass 白名單——追尾考量見實務隱患)。
- 產出:每輪 loop 收貨時 rc0 報表,先觀測不擋(canary 降級同款路徑:先量命中率再議升閘)。

### S2 canary 效度自檢(borrow ClawBench variance decomposition;r1 重寫)
**r1 折入的母體修正**:`docs/.canary-log.jsonl` 每筆是當輪臨時植入的獨特瑕疵,**無「同一題×多席/重跑」配對鍵**——ClawBench 式 SNR(分母=同席同題重跑雜訊)在這本帳上算不出來,硬套=母體錯置(量到的是題目間難度差)。故 S2 拆兩層:
- **回溯層(現況可算,descriptive 不裁決)**:對 canary-log 按型別算 caught 率+樣本數。型別來源如實分層:note regex `type=[a-d]` 僅覆蓋 177/355(50%),結構化 `canary_type` 欄位歷史 0 筆——報表必附覆蓋率(口徑沿 calibration-log 既有 `pass_streak` 欄位),無型別線索的 178 筆列 unknown,不硬猜。此層只出觀測,不做換題裁決。
- **前瞻層(真 SNR,接對資料結構)**:資料源=`governance/eval/canary_calibration.py`+`plants.json` 的固定題×多席判定矩陣(`calibration-log.jsonl`,現僅 1 行——樣本遠不足,先攢)。公式明確化:每題(plant)分子=跨席 caught 變異(分辨力),分母=同席同題重跑變異,同題重跑≥3 次才算;分母=0 或樣本不足→判「不裁決」非「高訊號」;SNR<1 才標記換題候選,**換題恆人裁**(SNR 邊界=1 歸不換)。
- **開工條件(沿 [[Systems/canary-audit]] D 案既有閘,不另立)**:即日起 `canary record` 一律帶 `--canary-type`(結構化欄位 2026-08-05 已上線、待啟用);帶型別記錄攢滿 15 筆後回溯層才出第一份型別報表。
- 排程:掛 `governance/autonomous-loop.sh` 的 run_exam 同路徑(dry-run 模式下仍真跑、唯讀觀測輸出;該腳本非 --dry-run 直接 exit 2 之限制不影響 v1,超出唯讀觀測的自動動作一律不做),不建新排程。⚠ `governance/canary-samples/` 目前只有 README 空殼,S2 不依賴它。
- **範圍收斂(r1)**:v1 只做 canary 題庫;每週檢索考卷已有 goldset+held-split 重跑結構、更適合變異分解,列未來方向不進本計劃驗收。
- 同場補:canary 型別改派工當下隨機抽(日報 gap③「固定輪替=可猜」)。

### S3 Growth test 準入三問(borrow evidra scope boundaries)
- 治理機制(新閘/新 detector/新 lint)提案前必答:①這 pattern 真造成過事故嗎(要能指到事故節點/日報)②是不是風格偏好類關切(出界)③既有機制小修蓋得住嗎。答不全=不准加。
- **落點裁定(r1)**:寫進 **lumos-design-loop skill**(準入閘語意歸它;lumos-project-notes 不動);三問答案記在該提案的架構圖計劃節點 PRIOR-ART/緣起段(既有留痕位,無新帳)。

## 射程聲明(borrow evidra 誠實文化)
S1 測的是「報告與留痕的協議內一致性」,不是真實世界正確性——席若一致地說謊(引句自己編但格式對)抓不到;那層靠既有辯方+canary。S2 兩層皆有已知天花板:行為層 caught/missed 分不出「真醒」vs「知道被測所以演醒」([[Systems/canary-audit]] 已載)——低 SNR 可能是 eval-awareness 偽訊號,故換題恆人裁;樣本下限已裁定(型別層 15 筆沿 D 案閘、題層同題重跑≥3),未達下限一律「不裁決」。

## 實務隱患
- **併發**:S1/S2 皆為離線批次讀取(收貨時/每週 runner 單進程),不進熱路徑、無共享資源競爭;review-reports 為 write-once 多檔目錄(每輪每席獨立 .md,非單一 append log——勿做 tail 式增量讀取假設),掃描與寫入不同時。
- **pass 自失效追尾([[Issues/code-loop-pass自失效追尾]] 同型,r1 折入)**:S1 新增的 `rN-dispatch.json`/`out-of-scope.jsonl` 不在 `code-loop pass` 留痕失效白名單——裁定:與席報告同目錄、同 commit 節奏寫入(收貨當下一次進),不產生獨立後續 commit,故不觸發追尾;若未來改為高頻獨立寫入,須先議白名單,那是 code 面改動、過 code-loop。
- **效能**:全量重放歷史 review-reports 為一次性驗收動作,常態每輪只掃當輪 3-5 份報告,量級 KB,無效能面。
- **資源**:純檔案讀取+stdout 報表,無連線/鎖。
- **[prod-irreversible]**:三件皆無不可逆動作——S1 rc0 觀測不擋、S2 產清單人裁換題、S3 純文本;回滾=刪腳本/revert 文本,無資料遷移。
- **[self-governance] 誤擋逃生口**:S1 v1 恆 rc0(觀測),不存在誤擋;未來若升閘須另立計劃過 loop,並依 Growth test 三問(S3)自審——升閘決策本身留痕於治理帳。S2 換題為人裁非自動,誤判 SNR 最壞=誤換一題,樣本少時射程聲明已載明不穩。

## 審計修正紀錄
- **pre-flight(2026-08-06,機械排乾,不算 loop findings)**:①S2 資料源 `governance/canary-samples/` 實為 README 空殼,改指 `docs/.canary-log.jsonl`+補每週 runner 真實路徑 ②S1「看了沒」與已上線 `lumos quote-check` 機制重複(PRIOR-ART 鐵則①漏查自家),改為 quote-check 分工聲明+只留未覆蓋類 ③驗收線誤把 canary-missed(沒看出植入的假)當「自己引不實指涉」證據,兩種失敗模式已切開。
- **r1(2026-08-06,panel:3 sonnet(通才/正確性/整合)+Codex 外家席,4/4 canary caught;去重 15 條全數折入,存活 max=blocker×2;全屬機械證實/多席一致路由,免辯方)**:
  - [blocker] S1 第三類重造既有 `refcheck`(s1+s3,實跑驗證原地可用)→ 改為收貨直接跑 refcheck 對席報告,零新碼。
  - [blocker] S2 SNR 母體錯置——canary-log 無「同題×多席/重跑」配對鍵,分母算不出;統計量/邊界未定義;漏查自家 `canary_calibration.py` 固定題矩陣(s2+Codex×2)→ S2 重寫為回溯層(descriptive caught 率)+前瞻層(接 calibration 結構,公式/邊界/樣本下限明確化)。
  - [major] quote-check 無 `unverified` 欄位(4 席同報)→ 描述改為退出碼+實際 JSON 欄位。
  - [major] 有講沒做對帳缺 prescribe 端資料源(s2+s3+Codex)→ 新增派工 manifest `rN-dispatch.json`;PRIOR-ART「零新機制」宣稱同步修正。
  - [major] canary-log type 覆蓋率 50%/`canary_type` 歷史 0 筆/D 案 15 筆開工閘未對照(3 席)→ 回溯層如實分層+開工條件沿 D 案;PRIOR-ART 補內部條目(s1 F1 同源)。
  - [major] 驗收母體「32 份」錯且混快照、檔名慣例不一(4 席)→ 母體改由 canary-log `report_path` 欄位機械界定。
  - [major] 驗收「清單非空」把預期結論寫成通過條件(Codex)→ 改合成樣本單元測試,真實資料清單可空;同型鬆綁同步套用 S1(「至少找到一筆」刪除,零命中不算失敗)。
  - [major] `out_of_scope` 語意未定、必要查證會被誤記越界(Codex)→ scope 三集合定義折入 S1。
  - [major] S2「+每週檢索考卷」未落地(Codex)→ v1 範圍收斂為 canary,考卷列未來方向。
  - [major] S3 落點「或」未裁定(3 席)→ 裁定 design-loop skill。
  - [minor×5] 越界帳無名+追尾風險(→定名+實務隱患裁定)、SNR 除零/邊界(→併前瞻層)、eval-awareness 射程(→射程聲明)、「min样本數待定」未標記+簡體字(→當場裁定樣本下限消滅待定)、append-only 措辭(→write-once 多檔目錄)。

## 驗收線(先粗)
- S1:重放母體=`docs/.canary-log.jsonl` 各筆 `report_path` 所指的席報告集合(機械界定,不手數;快照/patch 天然不在內)。全量重放後人工抽 10 筆比對粗篩判定與人工判定一致即過;`unreported`/`out_of_scope` 命中數如實記錄,**零命中不算失敗**(觀測層不設「必須抓到」的通過條件,防把預期結論寫成驗收)。⚠ canary-missed 記錄測的是「沒看出植入的假」,與 S1 抓的「自己引了不實指涉」是兩種失敗模式,不得混當證據。
- S2:①回溯層對 canary-log 跑通,報表含型別覆蓋率與 unknown 分層 ②前瞻層以合成樣本單元測試證明「低 SNR 題會被標出、樣本不足會判不裁決」(真實資料清單可空) ③`--canary-type` 即日啟用,攢滿 15 筆出第一份型別報表。
- S3:lumos-design-loop skill 文本 diff+下一次新機制提案實際走過三問留痕。
