---
type: project
status: todo
created: 2026-08-11
updated: 2026-08-11
related:
  - "[[test-layers軟提醒_計劃]]"
  - "[[Systems/pitfalls-code-loop]]"
  - "[[Systems/test-profile-multiplatform]]"
  - "[[Systems/delguard]]"
tags:
  - type/project
  - status/todo
  - scope/governance
summary: |-
  FLOW:功能完成→除單元測試外,用 maestro 建該功能的 UI flow 檔→以檔案形式實跑通過→用 [test:] 綁回該功能的架構圖節點→之後重測/重驗直接跑檔
  KEY:★缺口是三重的,且都很精確(對照既有 [[Systems/pitfalls-code-loop]] 的「UI 層驗收慣例」2026-08-05)★—①**時機**:既有慣例掛在 code-loop 終審(審查時派 agent 去看一眼),使用者要的是**功能完成當下** ②**產物**:既有留截圖+console 存 review-reports/<loop>/ui-evidence/,那是**一次性證據**;要的是 flow 檔=**可重放資產**。⚠既有慣例自己寫著「證據可重放非口頭」——★但截圖其實不可重放,flow 檔才是★ ③**棧(★分兩層,原稿把範圍講太大★)**:`[test:]`/Check T 機制層**Android 早有通道**(maestro profile,見下方 KEY);缺的只有**慣例散文層**——UI 層驗收慣例只點名 Playwright MCP / claude-in-chrome(逐字核對 Systems/pitfalls-code-loop:17),沒寫「agent 要開 Android 時走哪條路」
  KEY:★綁定機制不只已存在,maestro 這條早在 2026-07-02 就交付並驗證過★(見 [[Systems/test-profile-multiplatform]],status done + 兩份 Verification;commit f527e7f)—TEST_PROFILES 內建 maestro profile(scripts/lumos:1763):掃 `.maestro/` 下 yaml、`^appId:` 濾非 flow、綁 flow 的 **`name:` 欄位**,Check T 驗存在性,測試 t_maestro_profile_discover。語法=`[test:maestro:flow_name]`,指令=`lumos guard bind <node> "<KEY子字串>" <flow_name> --platform maestro`。★原稿提的「[test:] 接受檔案路徑」不是缺口而是與既有設計正面衝突★:cmd_guard_bind 明文「method 維持識別字、不含冒號,IDENT_RE 不放寬」(scripts/lumos:4479-4482)、profile 註解「綁 name: 欄位(識別字安全)」——檔案路徑含 `/`、`.`、`-`,放寬會一併鬆掉 `[test:平台:名]` 的冒號解析。★真正剩的只有消費端設定★:專案 `.lumos/config.json` 補 platforms 宣告 + flow 的 `name:` 寫成識別字(裝置前置清單各專案自填,如 `.maestro/README.md`)
  KEY:★實戰要求一:斷言重點是「使用者看到什麼」,不是「有沒有被擋」★—mOrangePos 2026-08-11 實機抓到的缺陷:折扣超過 100% 的提示誤用 `R.string.input_err`(登入頁的「請輸入員工編號!」)。★單元測試斷言的回傳值 `Result.OutOfRange` 一直是對的,錯的是 UI 拿它去換哪一句話★——這一型單元測試結構上測不到,也正是 UI flow 唯一無可取代的價值。故 flow 的斷言必須含「畫面上出現什麼字」,只斷言「流程有沒有被擋」等於白做
  KEY:★實戰要求二:「寫了 flow」≠「flow 會跑」★—inline 跑通不代表寫成檔案跑得通(runFlow 相對路徑、optional 步驟、共用子流程都可能出錯)。★工作流必須要求以檔案形式實跑通過一次才算完成★,同 [test:] 綁定後要真跑一次的精神(信任階梯:真跑>機械查>LLM 判官>自報)
  KEY:★實戰要求三:裝置前置是這條路線的真實成本,沒文件化第二次就沒人跑得起來★—mOrangePos 實測撞到四關:①首次使用授權閘(要算挑戰碼)②複製設定★務必改裝置名★(否則兩台產生重複單號,踩既有事故)③一人登入開著時重裝沒登出會被擋(要 logo 連點解鎖)④**別台機器編的 APK 簽章不同,要換版本得先移除、設定全掉**。工作流要把「裝置 ready 的定義」寫成可檢查的前置,不能當常識
  KEY:★四個會讓腳本「沉默地做錯事」的坑(不是報錯,是回報成功但做錯)★—①同畫面兩個鍵盤共用同一組 resource-id→用 text/id 選會打到另一個且不報錯 ②Maestro 的 `text:` 是**全字串正則**,`tapOn:"."` 匹配任意字元(實測點到「1」,把 3.25 打成 3125)③某些欄位點選付款方式會自動帶值,再自己輸入反而錯 ④SeekBar 要 swipe 不能 tap,起點落在元件外會靜默無效。★這類「綠燈但做錯」比紅燈危險,產生 flow 的 agent 必須被明確警告★
  PRIOR-ART:①最小解在既有層—`[test:]` 合約鏈 + `lumos guard bind --platform` + `.lumos/test-layers.json` 三個都已存在,★且 maestro 綁定已交付(2026-07-02)★;剩下的只有消費端設定與慣例散文層 Android 通道,**不造新機制、不新增治理層、也不改語法**(★訂正:原稿此處寫「只需讓 [test:] 接受 flow 檔路徑」——那是誤判,見 d1★;★教訓:PRIOR-ART ① 要問的不只「最小解在哪一層」,還有「那一層現在做到哪了」——查了才知道已完成★) ②世界解過—**Serenity BDD / Cucumber 的 living documentation**:把驗收條件變成可執行測試、再由測試結果產出活文件,核心價值=**同一份東西同時是規格與測試,兩者不會漂移**;**Maestro** 本身則提供 YAML flow(無編譯循環)、CI 整合、每次執行留影片/log/flake 偵測 ③裁定=**borrow-design**(借「規格與測試不分家」的意圖,原生實作;零依賴家規排除 adopt)
  KEY:★與 Serenity/Cucumber 的刻意偏離★—它們引入 Gherkin + step definitions 這一層**翻譯層**,規格與程式之間多一組要維護的膠水。本設計**不做翻譯層**:敘述本來就在架構圖節點裡、可執行步驟本來就在 flow 檔裡,★只需要一個指標把兩者綁起來★。不新增第三種產物
  KEY:★天花板(先寫明,免得被當成全覆蓋)★—①UI flow 對「畫面長怎樣」敏感,版面一改就要重錄(mOrangePos 的折扣面板因 id 衝突只能用座標點擊,改版必壞)②只驗走得到的路徑,取不到裝置/起不了環境時仍是「明記未驗+原因」,不得靜默跳過 ③不取代單元測試:規則面仍歸單元測試,UI flow 守的是接線與呈現
  DECISION:[2026-08-11]先**用**既有 [test:] 與 test-layers,不新造機制(原寫「擴」,審閱訂正為「用」——不需擴,見下條);Android 通道補在既有「UI 層驗收慣例」之下而非另立
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
---
# Android 側 UI 測試綁架構圖工作流_計劃

**Goal:** 讓 Android 功能完成時，除了單元測試，也產出一支**可重放的 maestro flow**，並綁回該功能的架構圖節點——之後任何人要重測或重驗，跑一個檔就行。

> **狀態：待評估與拍板。** 由 mOrangePos 2026-08-11 實跑一輪 smoke 後就地寫回。
> 進實作前依家規需過 `lumos-design-loop`。

---

## 缺口在哪（不是「沒有 UI 驗收」，是三個維度都差一點）

既有的 UI 層驗收慣例（[[Systems/pitfalls-code-loop]]，2026-08-05）長這樣：

> test-layers 宣告 layer 含「UI 驗收」的棧被 diff 命中時，終審驗收＝agent 以 Playwright MCP／claude-in-chrome 真開頁執行驗收條款，截圖+console 證據存 `review-reports/<loop>/ui-evidence/`

對照使用者要的：

| | 既有慣例 | 要的 |
|---|---|---|
| **時機** | code-loop **終審**時 | **功能完成當下** |
| **產物** | 截圖 + console（一次性證據） | **flow 檔（可重放資產）** |
| **棧** | 慣例散文只點名 Playwright / claude-in-chrome（**都是 web**） | **Android**——⚠ 但**只缺慣例層**：`[test:`/Check T 機制層的 maestro 通道 2026-07-02 已交付（見下節訂正） |

第二列值得特別講：那條慣例自己寫著「**證據可重放非口頭**」——立意完全正確，**但截圖其實不可重放**。要重驗還是得再派一次 agent、再點一遍。flow 檔才真的可重放，而且下一個人跑它不需要理解當初為什麼那樣點。

## 綁定機制不用新造——**而且 maestro 這條早就做完了**

> **原稿訂正（2026-08-11 審閱）**：本節原本寫「讓 `[test:]` 也能指 flow 檔路徑就接上了」，並把它列為待辦第一條。查證後：**maestro 綁定在 2026-07-02 已交付並驗證**（[[Systems/test-profile-multiplatform]]，status done，兩份 Verification；commit `f527e7f`「多平台合約測試綁定——多根多 profile + maestro/playwright + `[test:平台:名]`」）。而且**檔案路徑那個提法與既有設計正面衝突**，不只是重複。

既有機制長這樣（`scripts/lumos:1763-1771` 的 `TEST_PROFILES["maestro"]`）：掃 `.maestro/` 下的 `.yaml`／`.yml`，用 `^appId:` 濾掉非 flow 的 yaml，綁 flow 檔內的 **`name:` 欄位**；Check T 驗它存不存在，回歸測試是 `t_maestro_profile_discover`。

所以正確寫法是綁**流程名**，不是檔案路徑：

```
KEY:★INVARIANT★ 手動折扣百分比不得超過 100% [test:ManualDiscountValidatorTest.百分比超過100必須擋下]
                                              [test:maestro:smoke_manual_discount_over_100]
```

```yaml
# .maestro/smoke-05-manual-discount-over-100.yaml
appId: com.example.morangepos
name: smoke_manual_discount_over_100   # ← [test:] 綁的是這個,必須是識別字
```

```bash
lumos guard bind <節點> "<KEY子字串>" smoke_manual_discount_over_100 --platform maestro
```

**為什麼不能改成吃檔案路徑**：`cmd_guard_bind` 第一件事就是擋非識別字，旁邊註解白紙黑字「多平台：平台另帶（method 維持識別字、不含冒號），寫成 `[test:平台:方法]`。**IDENT_RE 不放寬**」（`scripts/lumos:4479-4482`）；profile 註解也寫「綁 `name:` 欄位（**識別字安全**）」。檔案路徑含 `/`、`.`、`-`，一旦放寬，`[test:平台:名]` 的冒號解析與識別字保證會一起鬆掉。這是當初刻意的設計選擇，不是沒想到。

**真正剩下的只有消費端設定**：專案 `.lumos/config.json` 補 `platforms` 宣告（`{maestro: {profile: "maestro", root: "."}}` 之類）、把既有 flow 的 `name:` 改成識別字。`.lumos/test-layers.json` 的 `{layer, cmd, when}` 宣告 maestro 指令也已可用——機制見 [[test-layers軟提醒_計劃]]（status done）；**本 repo 自身沒有這個檔**（宣告是 per-project opt-in、無檔靜默跳過），「已可用」的證據來自 mOrangePos 2026-08-11 實測會印提醒，不是本 repo 的檔案。

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

這不是新紀律，是既有「**真跑 > 機械查 > LLM 判官 > 自報**」信任階梯在 UI 層的實例（code-loop 已有「綁 `[test:]` 的星標合約節點被 diff 命中時，pass 前只跑該綁定測試且須綠」）。寫成接既有階梯即可，不必另立規則。

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
| 綁定真的接上 | mOrangePos 補完 `platforms` 宣告後跑 `lumos doctor` | Check T 對綁了 `[test:maestro:*]` 的節點**不再報**裸合約／懸空 test_ref |
| 綁定看得到 | `lumos contracts <該節點>` | 該 ★INVARIANT★ 行下列出 maestro 那條 test_ref |
| flow 真的可跑 | 以**檔案形式**跑 `maestro test .maestro/<flow>.yaml` | rc0，且斷言含「畫面上出現什麼字」（非只驗被擋） |
| 回歸釘有效 | 把 `R.string.input_err` 那個錯誤字串改回去再跑一次 | flow **翻紅**（證明這條 flow 真的在守那個缺陷，不是恆綠） |
| 慣例層通了 | 下一個帶 Android UI 面的工作走 code-loop 終審 | 終審紀錄裡有 maestro 通道的證據，或明記「未驗＋原因」 |

★第四列是關鍵★：`[test:]` 綁上只證明「檔案存在」，證明不了「它咬得住」——這是既有合約鏈三階（存在性 → `[audit:]` 夠格 → `[kill:]` 咬得住）的第三階在 UI 層的樣子，**不另立機制**。

## 天花板（先寫明，免得之後被當成全覆蓋）

- UI flow 對「畫面長怎樣」敏感，**版面一改就要重錄**。mOrangePos 的折扣面板因 id 衝突只能用座標點擊，改版必壞。
- 只驗走得到的路徑。取不到裝置／起不了環境時仍是「**明記未驗＋原因**」，不得靜默跳過。
- **不取代單元測試**：規則面仍歸單元測試，UI flow 守的是接線與呈現。

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
- **本節點自身即案例**：PRIOR-ART ① 答對方向（不造新機制）卻沒查到該機制**已完成到什麼程度**，把「已交付」寫成「待接上」——正是 [[Systems/delguard]] 要防的失守形狀（架構圖有權威節點、計劃沒查就重新發明）。教訓：PRIOR-ART ① 除了問「最小解在哪一層」，還要問「**那一層現在做到哪了**」（`lumos search` 該機制名，不只憑印象）。

## 待辦

- [ ] **消費端接上既有 maestro 綁定**（非開發新機制）：mOrangePos `.lumos/config.json` 補 `platforms` 宣告、既有 flow 的 `name:` 改識別字、跑一次 `lumos guard bind ... --platform maestro` 驗 Check T 認得
- [ ] Android 通道補進「UI 層驗收慣例」**散文層**（範圍已收窄：只補「終審 agent 怎麼開 Android」）：maestro MCP 的 `list_devices` → `inspect_screen` → `run`，與既有 Playwright 通道並列；證據仍存 `review-reports/<loop>/ui-evidence/`
- [ ] 「裝置 ready」的可檢查前置清單（各專案自填，如 `.maestro/README.md`）
- [ ] 產 flow 的 agent prompt：要求斷言含「畫面上出現什麼字」＋四個坑的警告＋必須以檔案形式實跑通過
- [ ] 決定要不要在功能完成時**硬要求**產 flow，還是只軟提醒（傾向後者：不是每個功能都有 UI 面）
