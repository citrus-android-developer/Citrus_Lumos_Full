---
type: project
status: todo
created: 2026-08-11
updated: 2026-08-11
self_audit: sonnet/2026-08-11
related:
  - "[[test-layers軟提醒_計劃]]"
  - "[[Systems/pitfalls-code-loop]]"
  - "[[Systems/test-profile-multiplatform]]"
  - "[[Systems/delguard]]"
  - "[[Android側UI測試綁架構圖工作流_實作計畫]]"
tags:
  - type/project
  - status/todo
  - scope/governance
summary: |-
  FLOW:功能完成→除單元測試外,用 maestro 建該功能的 UI flow 檔→以檔案形式實跑通過→用 [test:] 綁回該功能的架構圖節點→之後重測/重驗直接跑檔
  KEY:★缺口是三重的,且都很精確(對照既有 [[Systems/pitfalls-code-loop]] 的「UI 層驗收慣例」2026-08-05)★—①**時機**:既有慣例掛在 code-loop 終審(審查時派 agent 去看一眼),使用者要的是**功能完成當下** ②**產物**:既有留截圖+console 存 governance/review-reports/<loop-id>/ui-evidence/,那是**一次性證據**;要的是 flow 檔=**可重放資產**。⚠既有慣例自己寫著「證據可重放非口頭」——★但截圖其實不可重放,flow 檔才是★ ③**棧(★分兩層,原稿把範圍講太大★)**:`[test:]`/Check T 機制層**Android 早有通道**(maestro profile,見下方 KEY);缺的只有**慣例散文層**——UI 層驗收慣例只點名 Playwright MCP / claude-in-chrome(逐字核對 Systems/pitfalls-code-loop:17),沒寫「agent 要開 Android 時走哪條路」
  KEY:★綁定機制不只已存在,maestro 這條早在 2026-07-02 就交付並驗證過★(見 [[Systems/test-profile-multiplatform]],status done + 兩份 Verification;commit f527e7f)—TEST_PROFILES 內建 maestro profile(scripts/lumos:1763):掃 `.maestro/` 下 yaml、`^appId:` 濾非 flow、綁 flow 的 **`name:` 欄位**,Check T 驗存在性,測試 t_maestro_profile_discover。語法=`[test:maestro:flow_name]`,指令=`lumos guard bind <node> "<KEY子字串>" <flow_name> --platform maestro`。★原稿提的「[test:] 接受檔案路徑」不是缺口而是與既有設計正面衝突★:cmd_guard_bind 明文「method 維持識別字、不含冒號,IDENT_RE 不放寬」(scripts/lumos:4479-4482)、profile 註解「綁 name: 欄位(識別字安全)」——檔案路徑含 `/`、`.`、`-`,放寬會一併鬆掉 `[test:平台:名]` 的冒號解析。★剩的是消費端設定,但比一行 JSON 複雜(r1-F1)★:`platforms` 是**全域模式開關**,一宣告 legacy test_profile 即失效、無冒號的舊 ref 全歸 default_platform——mOrangePos 只宣告 maestro 會讓既有 5 條 kotlin 綁定全懸空、doctor 直接紅(r2 實測訂正,r1 誤寫 19);正解=**雙平台宣告**(android=kotlin-junit + maestro,default_platform=android,maestro 的 root 指 `.maestro/` 免 doctor 掃整個 repo)。★三個照抄就壞★:①KEY 行必須單行單括號逗號分隔(續行對 Check T/contracts/lint 全隱形)②測試名須合法識別字(`Class.中文` 被 guard bind rc2 拒收)③`name:` 行不得帶行尾註解(`\s*$` 硬錨+不剝 YAML `#`)。既有 flow 是**加** name: 不是改(實查三支都沒有)
  KEY:★實戰要求一:斷言重點是「使用者看到什麼」,不是「有沒有被擋」★—mOrangePos 2026-08-11 實機抓到的缺陷:折扣超過 100% 的提示誤用 `R.string.input_err`(登入頁的「請輸入員工編號!」)。★單元測試斷言的回傳值 `Result.OutOfRange` 一直是對的,錯的是 UI 拿它去換哪一句話★——這一型單元測試結構上測不到,也正是 UI flow 唯一無可取代的價值。故 flow 的斷言必須含「畫面上出現什麼字」,只斷言「流程有沒有被擋」等於白做
  KEY:★實戰要求二:「寫了 flow」≠「flow 會跑」★—inline 跑通不代表寫成檔案跑得通(runFlow 相對路徑、optional 步驟、共用子流程都可能出錯)。★工作流必須要求以檔案形式實跑通過一次才算完成★,同 [test:] 綁定後要真跑一次的精神(信任階梯:真跑>機械查>LLM 判官>自報)
  KEY:★實戰要求三:裝置前置是這條路線的真實成本,沒文件化第二次就沒人跑得起來★—mOrangePos 實測撞到四關:①首次使用授權閘(要算挑戰碼)②複製設定★務必改裝置名★(否則兩台產生重複單號,踩既有事故)③一人登入開著時重裝沒登出會被擋(要 logo 連點解鎖)④**別台機器編的 APK 簽章不同,要換版本得先移除、設定全掉**。工作流要把「裝置 ready 的定義」寫成可檢查的前置,不能當常識
  KEY:★四個會讓腳本「沉默地做錯事」的坑(不是報錯,是回報成功但做錯)★—①同畫面兩個鍵盤共用同一組 resource-id→用 text/id 選會打到另一個且不報錯 ②Maestro 的 `text:` 是**全字串正則**,`tapOn:"."` 匹配任意字元(實測點到「1」,把 3.25 打成 3125)③某些欄位點選付款方式會自動帶值,再自己輸入反而錯 ④SeekBar 要 swipe 不能 tap,起點落在元件外會靜默無效。★這類「綠燈但做錯」比紅燈危險,產生 flow 的 agent 必須被明確警告★
  KEY:★實務隱患(r1 三席一致補;pitfalls --check 機械零命中≠不需要)★—★金流/prod 不可逆最重★:flow 跑真裝置真後端,參考實作檔頭記著「驗過…單號 M092026081100001」=真開了一張單,而「複製設定務必改裝置名否則重複單號」證明單號序列跨裝置共用且會寫入 → v1 硬性:只准跑測試門店/測試帳,無測試門店則標「僅手動不進回歸集」;併發=裝置獨佔(人機同時操作→綠燈但畫面已亂=第六型)+`cmd_guard_bind` 無鎖 read-modify-write(兩次綁定重疊會無聲吃掉先寫的 ref);資源=裝置狀態不自動還原、換版本不可逆清設定;認證=挑戰碼人工步驟→**v1 不進自主 loop**;PII=影片/截圖含帳號單據,證據只留遮罩截圖、影片不入庫(無機械守衛);效能=root 指 `.maestro/` 免 doctor os.walk 整個 Android repo。已排除:快取/限流/遷移
  PRIOR-ART:①最小解在既有層—`[test:]` 合約鏈 + `lumos guard bind --platform` + `.lumos/test-layers.json` 三個都已存在,★且 maestro 綁定已交付(2026-07-02)★;剩下的只有消費端設定與慣例散文層 Android 通道,**不造新機制、不新增治理層、也不改語法**(★訂正:原稿此處寫「只需讓 [test:] 接受 flow 檔路徑」——那是誤判,見 d1★;★教訓:PRIOR-ART ① 要問的不只「最小解在哪一層」,還有「那一層現在做到哪了」——查了才知道已完成★) ②世界解過—**Serenity BDD / Cucumber 的 living documentation**:把驗收條件變成可執行測試、再由測試結果產出活文件,核心價值=**同一份東西同時是規格與測試,兩者不會漂移**;**Maestro** 本身則提供 YAML flow(無編譯循環)、CI 整合、每次執行留影片/log/flake 偵測 ③裁定=**borrow-design**(借「規格與測試不分家」的意圖,原生實作;零依賴家規排除 adopt)
  KEY:★與 Serenity/Cucumber 的刻意偏離★—它們引入 Gherkin + step definitions 這一層**翻譯層**,規格與程式之間多一組要維護的膠水。本設計**不做翻譯層**:敘述本來就在架構圖節點裡、可執行步驟本來就在 flow 檔裡,★只需要一個指標把兩者綁起來★。不新增第三種產物
  KEY:★天花板(先寫明,免得被當成全覆蓋)★—①UI flow 對「畫面長怎樣」敏感,版面一改就要重錄 ②只驗走得到的路徑,取不到裝置仍是「明記未驗+原因」不得靜默跳過 ③不取代單元測試:規則面仍歸單元測試,UI flow 守的是接線與呈現 ★r1 補★ ④`[kill:]` 第三階 v1 **走不通**(kill 改副本原始碼,但裝置跑的是已裝 APK;斷言被刪掉不會有任何機械檢查翻紅) ⑤`name:` 唯一性與 name↔檔名一致性**都無守衛**(discover 回不記路徑的扁平 set) ⑥Check T **不看目錄**(dirs 只被 scaffold 用,任何帶 appId: 的 yaml 有合法 name 就算證據,含共用子流程) ⑦★第一缺口「時機」v1 沒關上★—待辦全是設定/散文/清單/prompt,沒一條動觸發點,既有軟提醒只掛 pre-push
  DECISION:[2026-08-11]先**用**既有 [test:] 與 test-layers,不新造機制(原寫「擴」,審閱訂正為「用」——不需擴,見下條);Android 通道補在既有「UI 層驗收慣例」之下而非另立
  DECISION:[2026-08-11 r1→r2 翻盤]d2「豁免 S1+改 skill」已被 d3 取代(前提錯:S1 是紀律層非機械閘)(invalid)
  DECISION:[2026-08-11 r2]★不改任何 skill★—綁定照常綁星標合約;有裝置真跑記 pass --note,沒裝置走既有 code-loop skip --note 留痕。d2 為解一個不存在的死鎖要改 skill+造新產物,PRIOR-ART ① 沒重跑(本 loop 第二次犯同型錯)(valid)
  DECISION:[2026-08-11 審閱訂正]★不改 [test:] 語法★—maestro 綁定已交付且綁 name: 欄位(識別字安全),改吃檔案路徑會鬆掉 IDENT_RE 與 [test:平台:名] 冒號解析;v1 只補消費端設定+慣例散文層 Android 通道(valid)
decisions:
  - content: "不改 [test:] 語法接受檔案路徑;maestro 綁定沿用既有「綁 flow name: 欄位」設計,v1 只補消費端設定與慣例散文層 Android 通道"
    id: d1
    context: "原稿把「[test:] 接受 flow 檔路徑」列為待辦第一條。查證:maestro profile 2026-07-02 已交付(Systems/test-profile-multiplatform,commit f527e7f),綁 flow 的 name: 欄位、Check T 已驗、有 t_maestro_profile_discover;且 cmd_guard_bind 明文『method 維持識別字、不含冒號,IDENT_RE 不放寬』(scripts/lumos:4479-4482)"
    alternatives_considered: |-
      ①放寬 IDENT_RE 讓 [test:] 吃檔案路徑(原稿提案) ②沿用既有 [test:maestro:flow_name] 綁 name: 欄位
      ③兩者並存(路徑與 name 都認)——等於一個合約兩種綁法,Check T 要維護兩條存在性判定
    why_chosen: "檔案路徑含 / . - ,放寬 IDENT_RE 會一併鬆掉 [test:平台:名] 的冒號解析與識別字保證;既有 name: 綁法是刻意設計非疏漏,重新發明會製造第二套語意"
    trade_offs: |-
      綁 name: 而非路徑,代價=flow 檔改名/搬家時 name 與檔名可能不一致(靠命名慣例自律,無機械守衛);
      且既有 flow 若 name 非識別字須先改。接受——換到的是識別字保證與單一綁法語意
    decided: 2026-08-11
    valid: true
  - content: maestro 平台的 [test:] 綁定豁免 code-loop S1 的本機真跑;終審改驗「flow 存在+上次實跑留痕」,真跑硬閘留 CI/人工。改 skill 加平台例外是綁 ★INVARIANT★ 的前置
    id: d2
    context: r1 opus 席(F3):code-loop S1 要求 diff 命中綁 [test:] 的星標節點時 pass 前必跑該測試且須綠、『解析不了所以沒跑』不構成放行,pre-push 對 tier=high 硬擋;把 maestro flow 綁上去=每次動合約都要當場有裝置才能 push。而 test-layers軟提醒_計劃(done)明文裁過『E2E 慢+flaky,本機硬擋逼出 --no-verify 文化反噬其他硬閘;真硬閘留 CI 合併點』。天花板的『取不到裝置→明記未驗』接不上 S1(其退路階梯是為指令解析失敗設計)
    alternatives_considered: |-
      ①照原稿綁上去、接受本機硬跑(撞 test-layers 裁定,且沒裝置就 push 不了)
      ②不綁 ★INVARIANT★ 只放一般測試層宣告(保不住追溯性,回到「截圖不可重放」的原問題)
      ③綁定但豁免 S1 本機真跑,硬閘留 CI/人工(本案)
    why_chosen: 既有裁定已針對同一風險做過權衡且理由更強(反噬其他硬閘=系統性代價);綁定的價值是追溯性,不是把 E2E 變成本機閘——兩者可分離
    trade_offs: |-
      豁免後本機終審對 UI 合約只剩「存在+留痕」的弱驗證,真綠燈要等 CI/人工;
      且要動 lumos-code-loop skill(跨 skill 改動、需自己走一次 loop)。接受——換到的是不逼出 --no-verify 文化
    decided: 2026-08-11
    valid: false
    superseded_by: "#d3"
    ended: 2026-08-11
  - content: 不改 lumos-code-loop skill;沒裝置時走既有 code-loop skip --note 留痕路徑,有裝置則真跑並記 pass --note。maestro 綁定照常綁 ★INVARIANT★
    id: d3
    context: r2 opus 席(F6)實查推翻 d2 的前提:S1 條文自身標明「紀律層規則非機械閘」(skills/lumos-code-loop/SKILL.md:227),pre-push 硬擋的是「tier=high 沒有 code-loop 留痕」而非真跑,且錯誤訊息直接給第二條出路 lumos code-loop skip --note。也就是說 d2 為了解一個不存在的機械死鎖,換來跨 skill 改動的成本;另 d2 要求終審改驗的「上次實跑留痕」全份未定義(F7),唯一近似物是 flow 檔頭人寫註解=信任階梯最底層的自報
    alternatives_considered: |-
      ①d2 原案:改 S1 條文加平台例外(基於「沒裝置就 push 不了」的錯誤前提,且成本=跨 skill 改動+自走一輪 loop)
      ②另立「上次實跑留痕」格式讓終審驗(新增產物,且落到信任階梯最底層的自報)
      ③什麼都不改,沿用既有 skip --note(本案)
    why_chosen: 既有 skip --note 留痕路線已覆蓋同一情境(取不到裝置=可接受的略過,帶理由留痕);PRIOR-ART ①「最小解在哪一層」在 d2 沒重跑,d3 補跑的結論是「這一層什麼都不用動」
    trade_offs: |-
      沒裝置的終審對 UI 合約只留「skip+理由」,不是綠燈——誠實但弱;要真綠仍得有人有裝置跑一次。
      接受:這正是既有紀律對 E2E 的既定態度,不為 UI 破例
    decided: 2026-08-11
    valid: true
verified_by:
  - "[[Verification/2026-08-11_AndroidUI工作流A段落地]]"
---
# Android 側 UI 測試綁架構圖工作流_計劃

**Goal:** 讓 Android 功能完成時，除了單元測試，也產出一支**可重放的 maestro flow**，並綁回該功能的架構圖節點——之後任何人要重測或重驗，跑一個檔就行。

> **狀態：待評估與拍板。** 由 mOrangePos 2026-08-11 實跑一輪 smoke 後就地寫回。
> 進實作前依家規需過 `lumos-design-loop`。

---

## 缺口在哪（不是「沒有 UI 驗收」，是三個維度都差一點）

既有的 UI 層驗收慣例（[[Systems/pitfalls-code-loop]]，2026-08-05）長這樣：

> test-layers 宣告 layer 含「UI 驗收」的棧被 diff 命中時，終審驗收＝agent 以 Playwright MCP／claude-in-chrome 真開頁執行驗收條款，截圖+console 證據存 `governance/review-reports/<loop-id>/ui-evidence/`

對照使用者要的：

| | 既有慣例 | 要的 |
|---|---|---|
| **時機** | code-loop **終審**時 | **功能完成當下** |
| **產物** | 截圖 + console（一次性證據） | **flow 檔（可重放資產）** |
| **棧** | 慣例散文只點名 Playwright / claude-in-chrome（**都是 web**） | **Android**——分三層看：**機制層**（`[test:]`/Check T 的 maestro profile）2026-07-02 已交付；**設定層**（消費專案的 `platforms` 宣告）未做**且比想像複雜**（見下節 r1-F1）；**慣例散文層**（終審 agent 怎麼開 Android）未做 |

第二列值得特別講：那條慣例自己寫著「**證據可重放非口頭**」——立意完全正確，**但截圖其實不可重放**。要重驗還是得再派一次 agent、再點一遍。flow 檔才真的可重放，而且下一個人跑它不需要理解當初為什麼那樣點。

## 綁定機制不用新造——**而且 maestro 這條早就做完了**

> **原稿訂正（2026-08-11 審閱）**：本節原本寫「讓 `[test:]` 也能指 flow 檔路徑就接上了」，並把它列為待辦第一條。查證後：**maestro 綁定在 2026-07-02 已交付並驗證**（[[Systems/test-profile-multiplatform]]，status done，兩份 Verification；commit `f527e7f`「多平台合約測試綁定——多根多 profile + maestro/playwright + `[test:平台:名]`」）。而且**檔案路徑那個提法與既有設計正面衝突**，不只是重複。

既有機制長這樣（`scripts/lumos:1763-1771` 的 `TEST_PROFILES["maestro"]`）：掃 `.maestro/` 下的 `.yaml`／`.yml`，用 `^appId:` 濾掉非 flow 的 yaml，綁 flow 檔內的 **`name:` 欄位**；Check T 驗它存不存在，回歸測試是 `t_maestro_profile_discover`。

所以正確寫法是綁**流程名**，不是檔案路徑：

```
KEY:★INVARIANT★ 手動折扣百分比不得超過 100% [test:manualDiscountOver100Blocked,maestro:smoke_05_manual_discount_over_100] [audit:opus/2026-08-11]
```

★三個照抄就壞的地方（r1 三席抓到，逐條釘死）★：

1. **同一行、同一個中括號、逗號分隔**——不能寫成兩行兩括號。`INVARIANT_RE` 要求行首是 `KEY:★INVARIANT★`，續行對 Check T／`contracts`／`lint` **全部隱形**（不報錯、也不顯示成綁定）；`guard bind` 實際也是把新 ref 逗號併進同一括號。
2. **測試名必須是合法識別字**——`IDENT_RE = ^[A-Za-z_][A-Za-z0-9_]*$`（`scripts/lumos:4335`），`Class.方法` 的點號、中文都會被 `guard bind` 當場 rc2 拒收；kotlin profile 抽出的也只有函式名不含類別。原稿示範的 `ManualDiscountValidatorTest.百分比超過100必須擋下` 照抄會直接失敗。
3. **`[audit:]` 不能省**——見下方「三階鏈在 UI 層的實況」。

★r2 補的第四條（兩席一致抓到，且原稿示範自己犯了）★：**Kotlin 慣用的反引號中文測試名綁不上**。mOrangePos 實際的測試叫 `` `百分比超過 100 必須擋下` ``，`KOTLIN_TEST_RE` 抽出來的就是含空白的中文原名——`IDENT_RE` 一樣拒收。**要綁合約的測試，函式名必須先改成識別字**（本例：`manualDiscountOver100Blocked`）。這是綁定路線的實質前置成本，原稿與 r1 折入都漏了。

```yaml
# .maestro/smoke-05-manual-discount-over-100.yaml
appId: com.example.morangepos
name: smoke_05_manual_discount_over_100
```

★`name:` 行不得有任何其他內容★（含行尾 `#` 註解）——`MAESTRO_NAME_RE` 行尾是 `\s*$` 硬錨，而 maestro profile 沒覆寫 `comment_strip`（預設 c-style 只剝 `//`、`/* */`，**不剝 YAML 的 `#`**）。帶註解 → discover 抓不到 → `guard bind` 仍寫得進去、但 Check T 判懸空。這是「綠燈但做錯」的第五型，且紅在 doctor 而非 maestro，人會找錯方向。

```bash
lumos guard bind <節點> "<KEY子字串>" smoke_05_manual_discount_over_100 --platform maestro
```

**為什麼不能改成吃檔案路徑**：`cmd_guard_bind` 第一件事就是擋非識別字，旁邊註解白紙黑字「多平台：平台另帶（method 維持識別字、不含冒號），寫成 `[test:平台:方法]`。**IDENT_RE 不放寬**」（`scripts/lumos:4479-4482`）；profile 註解也寫「綁 `name:` 欄位（**識別字安全**）」。檔案路徑含 `/`、`.`、`-`，一旦放寬，`[test:平台:名]` 的冒號解析與識別字保證會一起鬆掉。這是當初刻意的設計選擇，不是沒想到。

**剩下的是消費端設定——但它比一行 JSON 複雜（r1-F1，本輪最重的一條）**：

★`platforms` 是全域模式開關，不是「多加一個平台」★。`load_platforms`（`scripts/lumos:1875-1907`）一看到這個鍵就進 multiplatform、**legacy `test_profile` 整個失效**；`resolve_test_refs` 把所有不帶冒號的舊 ref 歸給 `default_platform`。mOrangePos 現況是 `{"test_profile": "kotlin-junit"}`，架構圖有 **5 條已綁裸名的 ★INVARIANT★**（r2 兩席獨立實測：`lumos guard list` → 「合約 5 條 — 真綁 5 / 懸空 0」；★r1 折入時寫的 19 條是錯的，我當時信了席位的數字沒自核，r2 兩席各自實跑抓回★）——照原稿只宣告 maestro 一個平台，這 5 條會全部拿去 maestro 的 name 集合裡找，**Check T 全報懸空、doctor 直接紅**。

正確設定要**同時宣告兩個平台並指定 default**（`Systems/test-profile-multiplatform` 早寫明「平台前綴≠profile 名」「default_platform 缺省即報錯，不猜」，原稿引用了該節點卻沒帶到這兩條）：

```json
{
  "default_platform": "android",
  "platforms": {
    "android": {"profile": "kotlin-junit", "root": "."},
    "maestro": {"profile": "maestro", "root": ".maestro/"}
  }
}
```

**既有 flow 要「加」`name:` 不是「改」**——實查 mOrangePos 三支 flow 一個 `name:` 欄位都沒有，且必須加在 `---` 之前的 config 區塊——★但注意方向：Check T **不看 `---` 分界**，`name:` 誤放步驟區且頂格寫，Check T 照樣判「存在」（綠），而 maestro 讀不到、flow 本身壞（r2-F12）。這是「綠燈但做錯」的第七型，不是「不算」★。`.lumos/test-layers.json` 的 `{layer, cmd, when}` 宣告 maestro 指令也已可用——機制見 [[test-layers軟提醒_計劃]]（status done）；**本 repo 自身沒有這個檔**（宣告是 per-project opt-in、無檔靜默跳過），「已可用」的證據來自 mOrangePos 2026-08-11 實測會印提醒，不是本 repo 的檔案。

## 三條從實戰得到的設計要求

### 一 · 斷言重點是「使用者看到什麼」，不是「有沒有被擋」

mOrangePos 這次抓到的缺陷：折扣超過 100% 的提示誤用了 `R.string.input_err`，而那是登入頁的「請輸入員工編號!」。擋是擋住了，但店員看到一句與折扣無關的話。

**單元測試斷言的回傳值 `Result.OutOfRange` 一直是對的**——錯的是 UI 拿它去換哪一句話。這一型單元測試**結構上**測不到，也正是 UI flow 唯一無可取代的價值。

所以產生 flow 的 agent 必須被要求：斷言要含「畫面上出現什麼字」。只斷言「流程有沒有被擋」等於白做。

```yaml
- assertVisible: "折扣超過上限。.*"
- assertNotVisible: "請輸入員工編號.*"   # 回歸釘：不可再退回誤用的字串
```

### 二 · 「寫了 flow」不等於「flow 會跑」

inline 跑得通，不代表寫成檔案跑得通——`runFlow` 的相對路徑、`optional` 步驟、共用子流程都可能出錯。工作流必須要求**以檔案形式實跑通過一次**才算完成。

這不是新紀律，是既有「**真跑 > 機械查 > LLM 判官 > 自報**」信任階梯在 UI 層的實例。

> ★但接上去會撞到既有裁定（r1-F3，opus 席抓到）★：code-loop S1 是「diff 命中綁 `[test:]` 的星標合約節點時，**pass 前只跑該綁定測試且須綠**，『解析不了所以沒跑』不構成放行理由」，而 pre-push 對 tier=high 無留痕硬擋。把 maestro flow 綁進 ★INVARIANT★，等於**每次動到那個合約就必須當場有一台備妥的裝置才能 push**——這正是 [[test-layers軟提醒_計劃]]（status done）明文裁掉的路：「E2E 慢＋flaky，**本機硬擋逼出 `--no-verify` 文化、反噬其他硬閘**；真硬閘留 CI 合併點」。
>
> 而天花板寫的逃生口「取不到裝置→明記未驗＋原因」**接不上 S1**：S1 的退路階梯（退跑檔案級／模組級／全套）是為「指令解析不出來」設計的，對「沒有裝置」完全無效。
>
> ★r2 訂正（F6，opus 席實查）：上面這個「撞裁定」的擔憂**前提是錯的**★——S1 條文自己標明「**紀律層規則非機械閘**」（`skills/lumos-code-loop/SKILL.md:227`），pre-push 硬擋的是「tier=high 沒有 code-loop 留痕」**而不是真跑**，而且它的錯誤訊息直接給第二條出路 `lumos code-loop skip --note "<理由>"`。所以「沒裝置就 push 不了」的死鎖不存在。
>
> **本輪裁定（decisions d3，翻盤 d2）**：**什麼都不用改**——綁定照常綁 ★INVARIANT★；有裝置就真跑並記 `pass --note`，沒裝置走既有 `code-loop skip --note` 留痕。d2 原本要改 `lumos-code-loop` skill 加平台例外、還要新造一個「上次實跑留痕」產物，兩者都是為了解一個不存在的死鎖——**PRIOR-ART ① 在 d2 沒重跑，這是本 loop 第二次犯同一型錯**（第一次見審計修正紀錄）。
>
> ⚠ 誠實記著代價：沒裝置的終審對 UI 合約只留「skip＋理由」，**不是綠燈**；要真綠仍得有人有裝置跑一次。這正是既有紀律對 E2E 的既定態度，不為 UI 破例。

### 三 · 裝置前置是真實成本

mOrangePos 實測撞到四關，任何一關沒文件化，第二次就沒人跑得起來：

1. 首次使用授權閘（要算挑戰碼）
2. 複製設定時**務必改裝置名**（否則兩台產生重複單號，直接踩既有事故）
3. 一人登入開著時，重裝沒登出會被「此帳號已被登入」擋死
4. **別台機器編的 APK 簽章不同** → 要換版本得先移除，**設定全掉**

工作流要把「裝置 ready 的定義」寫成可檢查的前置，不能當常識。

## 四個會讓腳本「沉默地做錯事」的坑

這類**綠燈但做錯**比紅燈危險——maestro 回報成功，實際做的是別的事。產生 flow 的 agent 必須被明確警告：

| 坑 | 症狀 |
|---|---|
| 同畫面兩個鍵盤共用同一組 `resource-id` | 用 `text:`/`id:` 選會打到另一個，**不報錯**，只是輸入進錯地方 |
| Maestro 的 `text:` 是**全字串正則** | `tapOn: "."` 匹配任意單一字元（實測點到「1」，把 3.25 打成 3125） |
| 選付款方式會自動帶入金額 | 再自己輸入反而算錯 |
| SeekBar 要 `swipe` 不能 `tap` | 起點落在元件外會靜默無效 |

## 世界怎麼解的（PRIOR-ART ②）

**Serenity BDD / Cucumber 的 living documentation**：把驗收條件變成可執行測試，再由測試結果產出活文件。核心價值＝**同一份東西同時是規格與測試，兩者不會漂移**。

**Maestro** 本身提供 YAML flow（無編譯循環）、CI 整合、每次執行留影片／log／flake 偵測。

**刻意偏離**：Serenity／Cucumber 引入 Gherkin + step definitions 這一層**翻譯層**，規格與程式之間多一組要維護的膠水。本設計**不做翻譯層**——敘述本來就在架構圖節點裡，可執行步驟本來就在 flow 檔裡，**只需要一個指標把兩者綁起來**，不新增第三種產物。

（註：翻譯層的維護成本是設計考量，非本次檢索所得的引用——搜尋結果只涵蓋其優點，未涵蓋缺點，此處不冒充有出處。）

出處：[Serenity BDD — Living Documentation](https://serenity-bdd.github.io/docs/reporting/living_documentation)、[Maestro Docs](https://docs.maestro.dev/)

## 怎麼知道這份工作流有效（驗收方式）

這份 spec 的產出是**工作流與慣例**，不是程式碼，所以驗收看的是「照著做會不會真的接上」，逐條可查：

| 驗收項 | 怎麼驗 | 通過長怎樣 |
|---|---|---|
| 綁定真的接上 | mOrangePos 補完**雙平台** `platforms` 宣告後跑 `lumos doctor` | Check T 對該節點不再報裸合約／懸空 test_ref，**且既有 5 條 kotlin 綁定不變紅**（r1-F1／r2-F9 訂正數字）。⚠ 此時仍會報 **`unaudited`**——Check T 五判定含「未審」，補 `[audit:]` 才真的綠（r1-F8） |
| 綁定看得到 | `lumos contracts <該節點>` | 該 ★INVARIANT★ 行下列出 maestro 那條 test_ref |
| flow 真的可跑 | 以**檔案形式**跑 `maestro test .maestro/<flow>.yaml` | rc0，且斷言含「畫面上出現什麼字」（非只驗被擋） |
| **name → 檔案路徑查得到** | 由 `[test:maestro:X]` 反推要跑哪個檔 | ⚠ **目前無路徑**（r1-F4）：maestro 只吃檔案路徑，`discover_test_methods` 回的是不記路徑的扁平集合，`dotnet --filter`／`pytest -k` 那種「用名字選測試」maestro 沒有對應機制。v1 的解：**命名慣例硬性**——`name:` 必須等於檔名去副檔名並轉底線（`smoke-05-manual-discount-over-100.yaml` → `smoke_05_manual_discount_over_100`），讓人與 agent 都能機械反推。**此慣例目前無守衛**，見天花板 |
| 回歸釘有效 | 把 `R.string.input_err` 那個錯誤字串改回去再跑一次 | flow **翻紅**（證明這條 flow 真的在守那個缺陷，不是恆綠） |
| 慣例層通了 | 下一個帶 Android UI 面的工作走 code-loop 終審 | 終審紀錄裡有 maestro 通道的證據，或明記「未驗＋原因」 |

★回歸釘那列是關鍵★：`[test:]` 綁上只證明「flow 名存在」，證明不了「它咬得住」。

**三階鏈在 UI 層的實況（r1-F5 訂正，原稿宣稱「不另立機制」不成立）**：

| 階 | 機制 | UI 層可行嗎 |
|---|---|---|
| 一 · 存在性 | Check T | ✅ 可行（本 spec 主體） |
| 二 · 夠格 `[audit:]` | `lumos guard audit` | ✅ 可行，且**不可省**——省了 doctor 會停在 `unaudited` |
| 三 · 咬得住 `[kill:]` | `guard kill-add` / `guard kill` | ❌ **v1 走不通**：`guard kill` 要 `platforms.<plat>.run_cmd`（缺即 ERROR），且它的做法是 `git worktree` 複製**原始碼**套壞法再跑——但裝置上跑的是**已安裝的 APK**，改副本 `.kt` 不會改變被測物；除非 `run_cmd` 自含 build+install，而換版本要先移除、**設定全清**（本節第三條實戰要求已記）。 |

所以驗收表的「把錯誤字串改回去再跑一次」是**一次性人工動作，不是 `kill-add` 配方**——意思是：日後有人把 `assertVisible` 斷言刪掉，Check T 綠、真跑也綠，**合約已空但全部機械檢查都通過**。這個洞 v1 明文接受，寫進天花板。

## 實務隱患（r1 三席一致要求補；`pitfalls --check` 機械零命中，但機械只認四個關鍵詞類，不能當「不需要」的證據）

**此功能碰到的風險類**：金流／不可逆、併發、資源、認證、PII、效能。逐類答：

- **★金流／prod 不可逆（最重）★**：這些 flow 跑在**真裝置、真後端**——參考實作 `smoke-01-cash-checkout.yaml` 的檔頭註解記著「驗過：2026-08-11 通過，單號 M092026081100001」，也就是那次 smoke **真的開出了一張單**；而「複製設定務必改裝置名，否則兩台產生重複單號」這條前置本身就證明單號序列是**跨裝置共用且會寫入**的。把 flow 當「反覆重放的回歸資產」意味著每跑一次就灌一筆測試單進真帳。**v1 硬性要求**：flow 只准跑在**測試門店代號／測試帳**上（`.maestro/README.md` 必須寫明是哪一個），跑正式帳＝禁止；無測試門店可用時，該 flow 標「僅手動、不進回歸集」。★這條沒解決之前不得把 smoke-01 當自動回歸跑★。
- **併發（裝置是獨佔資源）**：①同一台裝置被兩個 flow／或人與 agent 同時操作 → maestro 每個 `tapOn` 都會點到「某個東西」所以不報錯，flow 回報綠燈但畫面狀態已被打亂＝**第六型「綠燈但做錯」**。②`cmd_guard_bind` 是無鎖的 read-modify-write（讀整檔→算→`os.replace`），對同一節點連下兩次綁定（單元測試一次、maestro 一次）若窗口重疊，後寫者會**無聲吃掉**先寫者的 ref。v1 對策：裝置一次一人（`.maestro/README.md` 記占用約定，無機械鎖）；`guard bind` 逐次序跑、跑完 `lumos contracts` 目視確認兩條 ref 都在。
- **資源**：裝置狀態（登入態／單號序列／設定）會被 flow 改變且不自動還原；換 APK 版本要先移除、**設定不可逆全清**。v1 對策：把「跑完要不要復原、怎麼復原」寫進每支 flow 的檔頭。
- **認證**：首次授權閘「要算挑戰碼」是**人工步驟**，與「無人看顧 loop」方向牴觸——v1 明文：**這條路線 v1 不進自主 loop**，只在有人的工作階段跑。
- **PII／證據外流**：maestro 每次執行留影片／log，終審證據若照慣例存進 `governance/review-reports/<loop-id>/ui-evidence/` 就會**進版控**，內容含店員帳號、真實單據。v1 對策：證據只留**必要截圖**且過遮罩（帳號、單號打碼）；影片預設不入庫。★此對策目前無機械守衛，靠人★。
- **效能**：`platforms.<plat>.root="."` 會讓 `discover_test_methods` `os.walk` 整個 Android repo 讀所有 `.yaml`／`.yml`，而 doctor 是 pre-push／CI 常跑的指令——成本會跳一個量級。v1 對策：把 maestro 平台的 `root` 指到 `.maestro/`（不是 `.`），縮小掃描面。
- **已排除**：快取（不涉快取層）／限流（不打有配額的外部 API）／資料遷移（不改 schema）。

## 天花板（先寫明，免得之後被當成全覆蓋）

- UI flow 對「畫面長怎樣」敏感，**版面一改就要重錄**。mOrangePos 的折扣面板因 id 衝突只能用座標點擊，改版必壞。
- 只驗走得到的路徑。取不到裝置／起不了環境時仍是「**明記未驗＋原因**」，不得靜默跳過。
- **不取代單元測試**：規則面仍歸單元測試，UI flow 守的是接線與呈現。
- **`name:` 唯一性與 name↔檔名一致性都沒有守衛**（r1-F13／F4）：`discover_test_methods` 回的是不記路徑的扁平集合，兩支 flow 同名照樣判「存在」；複製 flow 忘了改 `name:` → Check T 綠，但人依檔名跑的是另一支。v1 靠命名慣例自律。
- **`[kill:]` 第三階 v1 走不通**（見上表）：合約可以「存在且夠格」，但「咬得住」沒有機械證明——斷言被刪掉不會有任何機械檢查翻紅。
- **Check T 不看目錄**（r1-F10）：`dirs` 鍵只被 scaffold 用；任何角落帶 `appId:` 的 yaml 只要有合法 `name:` 就算合法證據，包括共用子流程 `common-login.yaml`。
- **第一缺口「時機」v1 沒關上**（r1-F6）：待辦全是設定／散文／清單／prompt，沒有一條動到「功能完成當下」這個觸發點；既有軟提醒實作只掛 pre-push。★這是本 spec 立論的第一格，v1 誠實承認未解★，見待辦最後一條。

## 參考實作（已落地，可直接看）

mOrangePos `8f239db`：

```
.maestro/common-login.yaml                        啟動→登入，內建一人登入解鎖
.maestro/smoke-01-cash-checkout.yaml              最重要的回歸（關帳閘沒擋到最常見路徑）
.maestro/smoke-05-manual-discount-over-100.yaml   含「使用者看到什麼」的斷言
.maestro/README.md                                裝置前置 + 四個坑 + 座標對照表
.lumos/test-layers.json                           kt → UI 驗收層
```

## 審計修正紀錄

- **2026-08-11 審閱（folded）**：①原待辦第 1 條「`[test:]` 接受 flow 檔路徑」**整條作廢**——maestro 綁定 2026-07-02 已交付（[[Systems/test-profile-multiplatform]]），且檔案路徑寫法與 `IDENT_RE 不放寬` 的明文設計衝突；已改寫「綁定機制」節並換成消費端設定工作。②缺口③範圍收窄為「慣例散文層缺、機制層已有」。③原待辦第 1 條括號問「檔案存在即算綁上？還是要求跑過？」——既有合約鏈已有三階答案（`[test:]` 存在性 → `[audit:]` 夠格 → `[kill:]` 咬得住）＋「真跑優先」紀律，接階梯不另問。
- **pre-flight（2026-08-11，機械排乾，不計 loop findings）**：①補「怎麼知道這份工作流有效（驗收方式）」節（原稿無驗收描述）②`.lumos/test-layers.json`「已可用」措辭補明「本 repo 無此檔、證據來自 mOrangePos 實測」，避免讀成本 repo 現況。
- **本節點自身即案例**：PRIOR-ART ① 答對方向（不造新機制）卻沒查到該機制**已完成到什麼程度**，把「已交付」寫成「待接上」。教訓：PRIOR-ART ① 除了問「最小解在哪一層」，還要問「**那一層現在做到哪了**」（`lumos search` 該機制名，不只憑印象）。★r1 三席一致訂正：原稿把這型失守歸給 [[Systems/delguard]] 是錯的★——delguard 守的是「code 刪了、架構圖還在講」（由 code diff 的刪除行觸發），本案沒有任何刪除、也沒有符號消失，delguard 一聲都不會響。**「設計前沒查架構圖就重新發明」這一型目前沒有任何機械守衛**，掛錯守衛會讓人以為已經有網子接著。

- **r1（2026-08-11，panel 3 席：sonnet 通才／sonnet 邊界可執行性／opus 整合合約；canary 2 caught 1 missed；單家族豁免留痕 waiver.json）**：去重後折入 18 條——①`platforms` 是全域開關，補了會讓既有 19 條 kotlin 綁定全懸空（改雙平台設定範例）②KEY 行必須單行單括號逗號分隔（續行對 Check T 隱形）③示範測試名改合法識別字（`Class.中文` 會被 rc2 拒收）④`name:` 行不得帶行尾註解（`\s*$` 硬錨＋不剝 YAML `#`）⑤綁 `[test:]` 與 code-loop S1 本機硬跑衝突 → 裁定 d2（豁免＋改 skill 為前置）⑥`[audit:]` 不可省（否則停在 unaudited）⑦`[kill:]` 第三階 v1 走不通（改副本原始碼不影響已裝 APK）⑧name→檔案路徑無解析 → 立命名慣例⑨補「實務隱患」節（金流不可逆／併發／資源／認證／PII／效能，逐類答＋已排除三類）⑩`root` 指 `.maestro/` 免 doctor 掃整個 repo⑪缺口表改三層（機制已有／設定未做且複雜／慣例未做）⑫證據路徑補 `governance/` 前綴⑬「改 name:」訂正為「加 name:」⑭天花板補 name 唯一性、kill 走不通、Check T 不看目錄、時機未關⑮delguard 歸因訂正（三席一致）⑯待辦重排並加兩條前置。**流程事件**：⑮⑪兩條是上一輪人工審閱折入時我自己引入的錯，由 panel 抓回。

- **r2（2026-08-11，delta 輪 2 席：sonnet 新宣稱正確性／opus 折入一致性與整合；canary 1 caught 1 missed）**：★這輪抓的幾乎全是我 r1 折入時自己製造的錯★，折入 13 條——①示範測試名仍是中文（r1 只砍了類別前綴沒砍中文，兩席一致）＋補「反引號中文 Kotlin 測試名綁不上」這條真前置②JSON 範例 `root` 還是 `.`（散文改了、唯一會被複製的那塊沒改，兩席一致）③**19 條 kotlin 綁定實測只有 5 條**（r1 我信了席位數字沒自核，r2 兩席各自實跑 `guard list` 抓回）④`multiplatform` 鍵是推導結果非輸入，刪⑤命名慣例自己的示範違反自己（`smoke_manual_...` 少了 `05`）⑥「步驟區加不算」方向反了——Check T 不看 `---` 分界，放步驟區照樣綠但 flow 壞（第七型「綠燈但做錯」）⑦待辦 1「先綁非星標節點」機制上做不到（`guard bind`／Check T 只認 ★INVARIANT★）⑧**d2 的前提是錯的 → 翻盤成 d3**：S1 明文「紀律層規則非機械閘」、pre-push 擋的是留痕不是真跑、且已有 `code-loop skip --note` 出路，「沒裝置就 push 不了」的死鎖不存在⑨「上次實跑留痕」未定義且落在信任階梯最底層 → 隨 d2 一起撤⑩待辦 4 沒帶前置會讓終審 agent 開真單 → 補「已標可自動＋測試門店已確認」⑪frontmatter 證據路徑同步 `governance/` 前綴＋新增待辦修源頭節點⑫（一條為植入的假錯，不計）⑬d1 範圍宣告隨 d3 恢復一致（不動治理層）。
  **本 loop 兩次犯同一型錯**：r1 的 delguard 歸因、r2 的 d2 前提——都是「沒把 PRIOR-ART ① 的第二問（那一層現在做到哪了／那條規則實際長怎樣）跑完就下裁定」。這份 spec 的主題正是這件事，而它在自己的審計過程裡示範了兩次。

## 合約候選清單（收斂時提名；★候選 ≠ 已標★，蓋章仍走 guard scaffold→bind→audit 與「不確定不標」鐵則）

- **flow 的 `name:` 必須是識別字且等於檔名轉底線**——改了就從「可機械反推檔案」退化成「只能全庫 grep」
- **`name:` 必須在 config 區塊、且該行無其他內容**——放步驟區／帶行尾註解都會造成「Check T 綠但 flow 壞」
- **maestro 平台的 `root` 必須是 `.maestro/`**——指 `.` 會讓 doctor（pre-push 常跑）掃整個 Android repo
- **雙平台宣告不可只宣告 maestro**——只宣告一個會讓既有 kotlin 綁定全懸空
- **flow 只准跑測試門店／測試帳**——跑正式帳＝在真帳開真單（金流不可逆）

★這五條目前都沒有機械守衛★（`[kill:]` 在 UI 層走不通、命名慣例無 linter），提名的意思是「日後若要蓋 ★INVARIANT★，先從這裡挑」，不是現在就標。

## 待辦

- [ ] **消費端接上既有 maestro 綁定**（非開發新機制，但比一行 JSON 複雜）：mOrangePos `.lumos/config.json` 補**雙平台**宣告（android=kotlin-junit + maestro，`default_platform: android`，maestro 的 `root` 指 `.maestro/` 不是 `.`）→ 跑 `lumos doctor` 確認既有 5 條 kotlin 綁定**沒變紅** → 三支 flow 的 config 區塊**加** `name:`（識別字、無行尾註解、等於檔名轉底線）→ 把要綁的 Kotlin 測試函式名先改成識別字（反引號中文名綁不上，r2-F1b）→ `guard bind ... --platform maestro` → 補 `guard audit`（否則停在 unaudited）。★r2 訂正：原寫「先綁非星標節點」在機制上做不到——`guard bind` 只在 ★INVARIANT★ 行上找目標、Check T 也只掃 ★INVARIANT★（r2-F5）；且 d3 翻盤後沒有前置，直接綁星標即可★
- [x] ~~先改 `lumos-code-loop` skill 的 S1 加平台例外~~ → **r2 撤銷（d3）**：S1 是紀律層非機械閘、pre-push 擋的是留痕、且已有 `code-loop skip --note` 出路，**不需要改任何 skill**。取而代之的操作紀律（寫進待辦的 agent prompt 即可）：有裝置→真跑並記 `pass --note`；沒裝置→`code-loop skip --note "無可用 Android 裝置，UI 合約未驗"`
- [ ] **測試門店／測試帳的約定**（★全局約束，非執行順序：沒確定測試門店之前，任何 flow 都只能標「僅手動、不進回歸集」★）：`.maestro/README.md` 寫明 flow 只准跑哪個門店代號；無測試門店可用時，該 flow 標「僅手動、不進回歸集」
- [x] Android 通道補進「UI 層驗收慣例」**散文層**（範圍已收窄：只補「終審 agent 怎麼開 Android」）：maestro MCP 的 `list_devices` → `inspect_screen` → `run`，與既有 Playwright 通道並列。★前置（r2-F8）：只准對「已標可自動、且測試門店已確認」的 flow 這樣做★——否則終審 agent 會在真裝置真後端開出真單；未達此條件的 flow 一律「僅手動」，終審走 skip 留痕；證據仍存 `governance/review-reports/<loop-id>/ui-evidence/`（★前綴不可省★：少了 `governance/` 不但路徑錯，還會漏掉 `pitfalls --diff` 對該目錄的排除，歸檔證物會被當代碼掃）
- [x] **修 [[Systems/pitfalls-code-loop]] 自身的證據路徑**（r2-F11）：該節點第 17 行寫的是無前綴的 `review-reports/<loop>/ui-evidence/`，而 `pitfalls --diff` 的排除規則吃的是帶 `governance/` 前綴的路徑（`scripts/lumos:10740` 實查）——本 spec 引用時已修正，但**源頭節點才是該改的地方**
- [ ] 「裝置 ready」的可檢查前置清單（各專案自填，如 `.maestro/README.md`）
- [x] 產 flow 的 agent prompt（落成 `lumos-project-notes` reference.md 的〈產 maestro UI flow 的派工要求〉）：要求斷言含「畫面上出現什麼字」＋四個坑的警告＋必須以檔案形式實跑通過
- [x] ★**「時機」觸發者已裁定（2026-08-11 Enzo）＝`lumos-project-notes` skill 退場段**★——收工前多問一句「這次有動到使用者看得到的畫面嗎」，user-scope 跨專案生效、零新機制；pre-push 軟提醒方案落選（觸發點在 push 前、不是功能完成當下）。★誠實記著：這是紀律不是機械閘，忘了就是忘了——第一缺口只從「完全沒有」變成「有人問」，沒有機械化★。落地見 [[Android側UI測試綁架構圖工作流_實作計畫]] Task 2
