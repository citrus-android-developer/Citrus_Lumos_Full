---
type: project
status: doing
created: 2026-08-11
updated: 2026-08-11
tags:
  - type/project
  - status/doing
  - scope/governance
related:
  - "[[Android側UI測試綁架構圖工作流_計劃]]"
  - "[[Systems/pitfalls-code-loop]]"
  - "[[Systems/test-profile-multiplatform]]"
summary: |-
  FLOW:A 段(本 repo,可立即做完)=修 pitfalls-code-loop 證據路徑+補 Android 通道散文→skill 退場段加 UI 面問句(時機觸發者)→reference.md 加產 flow 派工要求→架構圖收尾;B 段(mOrangePos,需真裝置)=雙平台 config→測試名/flow name 改識別字+bind+audit→測試門店與裝置 ready 清單→真跑驗收含回歸釘翻紅
  KEY:spec 單源=[[Android側UI測試綁架構圖工作流_計劃]](design-loop r1/r2 雙 PASS,golden@governance/golden/Android側UI測試綁架構圖工作流/);本節點只管「怎麼落地」,行為合約以 spec 為準
  KEY:★A 段(本 repo 4 task)已完成 2026-08-11★—慣例節點證據路徑+Android 通道／skill 退場自問第 4 問／reference.md 派工要求／架構圖收尾,全量 0 failed;驗證見 [[Verification/2026-08-11_AndroidUI工作流A段落地]]。★B 段(mOrangePos,需真裝置)未動★
  KEY:★兩 repo 分段,B 段驗不完不擋 A 段★—A 段全在 lumos-toolchain(散文/節點/skill),B 段在 mOrangePos 且要真裝置;B 段任一步驟卡住=明記未驗+原因,不得靜默跳過
  KEY:★時機觸發者已裁(2026-08-11 Enzo)=skill 退場段★—寫進 lumos-project-notes 既有退場自問(delguard S3 三問旁),user-scope 跨專案生效、零新機制;pre-push 軟提醒方案落選(觸發點是 push 前不是功能完成當下)
  KEY:★本計畫不新增任何機制★—唯一近似新增的是 Task 1 的路徑同源斷言,走「既有 t_precommit_whitelist_drift_guard 同型小修」而非新 detector(新機制準入三問已答,見 Task 1)
  TEST:A 段=python3 scripts/test_lumos.py 全綠 + lumos lint/doctor 0;B 段=mOrangePos 側 lumos doctor 0 + maestro test 檔案形式 rc0 + 回歸釘翻紅實測
verified_by:
  - "[[Verification/2026-08-11_AndroidUI工作流A段落地]]"
---
# Android 側 UI 測試綁架構圖工作流_實作計畫

> **For agentic workers:** 建議 `superpowers:subagent-driven-development`（每 task 派乾淨 subagent、task 間審查）。Steps 用 checkbox 追蹤；**動 code 的 commit 必須同時勾本節點對應 checkbox**（pre-commit Gate 3 硬擋）。

**Goal:** 把 [[Android側UI測試綁架構圖工作流_計劃]]（已收斂）落地成兩件事——本 repo 的慣例／skill／節點補齊，mOrangePos 的 maestro 綁定真的接上並跑通一次。

**Architecture:** 全部是**接既有機制**，零新機制：`[test:maestro:名]` 綁定用既有多平台 profile；終審通道補進既有 UI 層驗收慣例散文；時機觸發掛既有 skill 退場段；沒裝置走既有 `code-loop skip --note`。

**Tech Stack:** markdown（架構圖節點／skill 散文）、`.lumos/config.json`、maestro YAML flow、既有 lumos CLI（`guard bind/audit`、`doctor`、`lint`）。

## Global Constraints（每個 task 隱含遵守；值抄自 spec，不得偏離）

- **證據路徑一律 `governance/review-reports/<loop-id>/ui-evidence/`**——前綴不可省（少了會漏掉 `pitfalls --diff` 的排除，歸檔證物被當代碼掃）。
- **flow 的 `name:`**：識別字、**等於檔名去副檔名轉底線**、**該行不得有其他內容**（含行尾 `#` 註解）、**必須在 `---` 之前的 config 區塊**（放步驟區 Check T 照樣綠但 flow 壞）。
- **要綁合約的 Kotlin 測試函式名必須是識別字**——反引號中文名綁不上（`IDENT_RE` 拒收、`KOTLIN_TEST_RE` 抽的是原名）。
- **`platforms` 是全域開關**：宣告即 legacy `test_profile` 失效；必須同時宣告 android＋maestro 並指定 `default_platform: android`；maestro 的 `root` 指 `.maestro/`。
- **金流全局約束**：測試門店未確認前，任何 flow 只能標「僅手動、不進回歸集」；終審 agent 不得自動 `run` 未標可自動的 flow。
- **沒裝置的終審**：走 `lumos code-loop skip --note "無可用 Android 裝置，UI 合約未驗"`——不是綠燈，是誠實留痕。
- A 段測試跑法：`python3 scripts/test_lumos.py`（全量，尾行判綠）；架構圖改動 `lumos lint <節點>` → `lumos doctor`。

## 檔案結構

**A 段（lumos-toolchain）**
- Modify `docs/lumos-toolchain-knowledge/Systems/pitfalls-code-loop.md`：證據路徑補前綴＋UI 驗收慣例補 Android 通道
- Modify `scripts/test_lumos.py`：`t_precommit_whitelist_drift_guard` 加一條路徑同源斷言
- Modify `skills/lumos-project-notes/SKILL.md`：退場自問加第 4 問（UI 面）
- Modify `skills/lumos-project-notes/reference.md`：新增「產 maestro UI flow 的派工要求」段
- Create `docs/lumos-toolchain-knowledge/Verification/<日期>_AndroidUI工作流落地.md`

**B 段（mOrangePos，另一個 repo）**
- Modify `.lumos/config.json`：雙平台宣告
- Modify `app/src/test/.../ManualDiscountValidatorTest.kt` 等：要綁合約的測試函式改識別字名
- Modify `.maestro/*.yaml`：config 區塊加 `name:`
- Modify `.maestro/README.md`：測試門店約定＋裝置 ready 清單
- Modify `docs/morangepos-knowledge/Systems/*.md`：`guard bind`／`audit` 寫入的綁定

---

# A 段 · lumos-toolchain（可立即做完，不需裝置）

### Task 1：修 `pitfalls-code-loop` 證據路徑＋補 Android 通道散文＋路徑同源斷言

**Files:** Modify `docs/lumos-toolchain-knowledge/Systems/pitfalls-code-loop.md`；Modify `scripts/test_lumos.py`（`t_precommit_whitelist_drift_guard` 內）

**新機制準入三問（本 task 唯一近似新增的機械檢查，先答完才准加）**
1. *真造成過事故嗎*：是——本 spec 的 r2-F11 就是實例（節點寫無前綴路徑，而 `pitfalls --diff` 排除吃的是帶前綴的，照節點做會讓歸檔證物被當代碼掃、push 被自己的留痕擋下，`scripts/lumos:10740` 註解記著「C 慣例首擋實錄」）。
2. *是風格偏好嗎*：不是，是路徑字串對不對得上。
3. *既有機制小修蓋得住嗎*：蓋得住——`t_precommit_whitelist_drift_guard` 已經是「跨檔同源清單」守衛，加一條斷言即可，**不新造 detector**。

- [x] **Step 1：寫失敗測試**（加進 `scripts/test_lumos.py` 的 `t_precommit_whitelist_drift_guard` 末尾）

```python
    # delguard/UI 證據路徑同源(2026-08-11,Android UI 工作流 r2-F11):
    # pitfalls --diff 的排除規則與架構圖節點寫的路徑必須是同一個字串前綴
    lumos_src = (_P(GRAPHCTL)).read_text(encoding="utf-8")
    excl = "governance/review-reports/"
    check("delguard 證據路徑排除規則仍在 scripts/lumos", excl in lumos_src, excl)
    node = (_P(GRAPHCTL).parent.parent / "docs" / "lumos-toolchain-knowledge"
            / "Systems" / "pitfalls-code-loop.md").read_text(encoding="utf-8")
    bad = "存 review-reports/"      # 無前綴的舊寫法
    check("pitfalls-code-loop 節點證據路徑帶 governance/ 前綴",
          bad not in node and excl in node, f"bad_present={bad in node} good_present={excl in node}")
```

- [x] **Step 2：跑紅**

Run：`python3 -c "import sys; sys.path.insert(0,'scripts'); import test_lumos as T; T.t_precommit_whitelist_drift_guard(); print(T.PASS, T.FAIL)"`
Expected：FAIL ≥1（節點目前是無前綴的 `存 review-reports/<loop>/ui-evidence/`）

- [x] **Step 3：修節點**——把 `Systems/pitfalls-code-loop.md` 第 17 行 KEY 內的 `截圖+console 證據存 review-reports/<loop>/ui-evidence/` 改成 `截圖+console 證據存 governance/review-reports/<loop-id>/ui-evidence/`，並在同一 KEY 行尾追加 Android 通道（★用 Edit 改 body／summary block，不手改 frontmatter 純量★）：

```
;★Android 通道(2026-08-11,[[Projects/Android側UI測試綁架構圖工作流_計劃]])★=maestro MCP list_devices→inspect_screen→run,與 Playwright/chrome 並列;★前置:只准對「已標可自動且測試門店已確認」的 flow 自動跑★(否則會在真裝置真後端開真單),未達條件的 flow 一律僅手動、終審走 lumos code-loop skip --note 留痕
```

- [x] **Step 4：跑綠＋全量**

Run：同 Step 2 指令 → FAIL 0；再 `python3 scripts/test_lumos.py 2>&1 | tail -2` → `0 failed`
（⚠ 全量跑幾分鐘屬正常，**用單一前景呼叫等它跑完**，不要丟背景輪詢）

- [x] **Step 5：`lumos lint "Systems/pitfalls-code-loop"` 0 問題 → `lumos doctor` 0 issues → commit**

```bash
git add docs/lumos-toolchain-knowledge/Systems/pitfalls-code-loop.md scripts/test_lumos.py \
        docs/lumos-toolchain-knowledge/Projects/Android側UI測試綁架構圖工作流_實作計畫.md
git commit -m "fix(kg): pitfalls-code-loop 證據路徑補 governance/ 前綴+補 Android 通道+路徑同源斷言"
```

### Task 2：skill 退場自問加第 4 問（時機觸發者＝已裁定的落點）

**Files:** Modify `skills/lumos-project-notes/SKILL.md`（既有「## 退場自問」節，第 189-194 行附近）
**Interfaces / Consumes:** Task 1 已把 Android 通道寫進慣例節點；本 task 是「功能完成當下」的觸發點。

- [x] **Step 1：在既有退場自問的第 3 問之後、`⚠ 新增一條 verified_by...` 那行之前，插入第 4 問**

```markdown
4. **這次有動到使用者看得到的畫面嗎？**（Android／web UI 都算）
   有 → 除了單元測試，補一支**可重放的 UI flow 檔**（Android＝maestro `.maestro/*.yaml`），
   並用 `[test:<平台>:<flow名>]` 綁回該功能的架構圖節點。
   ★斷言必須含「畫面上出現什麼字」★——只斷言「有沒有被擋」等於白做（實例：折扣超過 100%
   確實被擋，但畫面顯示的是登入頁的「請輸入員工編號!」，單元測試結構上測不到）。
   寫法與七個坑見 `reference.md` 的〈產 maestro UI flow 的派工要求〉。
   沒裝置／起不了環境 → **明記「未驗＋原因」**，不得靜默跳過。
```

- [x] **Step 2：驗證落點正確**

Run：`grep -n "這次有動到使用者看得到的畫面嗎" -B 3 -A 2 skills/lumos-project-notes/SKILL.md`
Expected：出現在第 3 問之後、`⚠ 新增一條 verified_by` 之前；且該節仍在「## 常見工作流」與「## 資料夾 / 位置」之間

- [x] **Step 3：全量測試**（skill 散文無專屬測試，跑全量確認沒撞到既有 skill 相關斷言）

Run：`python3 scripts/test_lumos.py 2>&1 | tail -2` → `0 failed`

- [x] **Step 4：commit**（skill 是 code 側，需同 commit 帶架構圖 → 勾本節點 Task 2 checkbox）

```bash
git add skills/lumos-project-notes/SKILL.md docs/lumos-toolchain-knowledge/Projects/Android側UI測試綁架構圖工作流_實作計畫.md
git commit -m "feat(skill): 退場自問加第 4 問(UI 面→補可重放 flow 並綁架構圖)——時機觸發者裁定落地"
```

### Task 3：`reference.md` 新增〈產 maestro UI flow 的派工要求〉

**Files:** Modify `skills/lumos-project-notes/reference.md`（新增一節，放在檔尾「Obsidian CLI」段之前或之後皆可，**與既有段落同層級 `##`**）
**Interfaces / Consumes:** Task 2 的第 4 問指過來這一節。

- [x] **Step 1：新增整節**（逐字，這是派工給「產 flow 的 agent」的單源）

```markdown
## 產 maestro UI flow 的派工要求（Android UI 驗收；spec＝`Projects/Android側UI測試綁架構圖工作流_計劃`）

派 agent 產 flow 時，prompt 必須含下列全部：

**1 · 斷言要驗「使用者看到什麼」**
```yaml
- assertVisible: "折扣超過上限。.*"
- assertNotVisible: "請輸入員工編號.*"   # 回歸釘：不可再退回誤用的字串
```
只斷言「流程有沒有被擋」等於白做——回傳值對、UI 拿它去換錯的字串，單元測試結構上測不到。

**2 · 命名與位置（錯了會「Check T 綠但 flow 壞」）**
- `name:` ＝檔名去副檔名轉底線（`smoke-05-x.yaml` → `smoke_05_x`），**識別字**、**該行無其他內容**（不得有行尾 `#` 註解）、**放在 `---` 之前的 config 區塊**。
- 要綁的 Kotlin 測試函式名也必須是識別字——反引號中文名綁不上。

**3 · 七個會「沉默地做錯事」的坑（回報成功但做的是別的事，比紅燈危險）**
| 坑 | 症狀 |
|---|---|
| 同畫面兩個鍵盤共用同一組 `resource-id` | 用 `text:`／`id:` 選會打到另一個，不報錯 |
| Maestro 的 `text:` 是**全字串正則** | `tapOn: "."` 匹配任意單一字元（實測把 3.25 打成 3125） |
| 選付款方式會自動帶入金額 | 再自己輸入反而算錯 |
| SeekBar 要 `swipe` 不能 `tap` | 起點落在元件外會靜默無效 |
| `name:` 行帶行尾註解 | discover 抓不到 → Check T 判懸空（紅在 doctor，人會找錯方向） |
| 人與 agent 同時操作同一台裝置 | 每個 `tapOn` 都點到「某個東西」→ 綠燈但畫面狀態已亂 |
| `name:` 放在步驟區 | Check T 不看 `---` 分界 → 照樣判「存在」（綠），但 maestro 讀不到、flow 壞 |

**4 · 完成判準**
- ★以**檔案形式**實跑通過一次★才算完成（inline 跑得通 ≠ 寫成檔案跑得通：`runFlow` 相對路徑、`optional`、共用子流程都可能出錯）。
- 跑之前先確認裝置 ready（各專案自填清單，如 `.maestro/README.md`）。
- ★金流前置★：flow 只准跑**測試門店／測試帳**；測試門店未確認前，該 flow 標「僅手動、不進回歸集」，終審不得自動 `run`。

**5 · 天花板（要講給人聽）**
版面一改就要重錄；`name:` 唯一性與 name↔檔名一致性都沒有機械守衛；`[kill:]` 第三階在 UI 層走不通（斷言被刪掉不會有任何機械檢查翻紅）。
```

- [x] **Step 2：驗證**

Run：`grep -c "產 maestro UI flow 的派工要求" skills/lumos-project-notes/reference.md` → `1`
Run：`python3 -c "import sys; sys.path.insert(0,'scripts'); import test_lumos as T; T.t_slim_skill_no_dangling() if hasattr(T,'t_slim_skill_no_dangling') else None; print('ok')"`（若無此函式名則跳過——slim 掃的是 `slim/skills/` 的副本，本 task 改的是主 skill，不影響）

- [x] **Step 3：全量測試** → `0 failed`

- [x] **Step 4：commit**（勾 Task 3 checkbox 同 commit）

### Task 4：A 段架構圖收尾

**Files:** Create `docs/lumos-toolchain-knowledge/Verification/<今日>_AndroidUI工作流A段落地.md`；Modify 兩個 Projects 節點（`lumos set`／`append`）

- [x] **Step 1** `lumos new verification "<今日>_AndroidUI工作流A段落地"`，body 記：Task 1-3 的落地內容、路徑同源斷言先紅後綠的證據、全量套件結果（**以實測留痕為準，不記數字快照**）
- [x] **Step 2** `lumos set` 填 `valid_under`（如「lumos 現行 pitfalls 排除規則；lumos-project-notes skill v 現行」）與 `revalidate_when`（如「pitfalls --diff 排除路徑變更／退場自問改寫／maestro profile 變更」）；`lumos append` 加 `plan_refs` 回指本節點與 spec 節點
- [x] **Step 3** 兩個 Projects 節點各 `lumos append <節點> verified_by "[[Verification/<今日>_AndroidUI工作流A段落地]]"`
- [x] **Step 4** `lumos lint` 三節點 0 問題 → `lumos doctor` 0 issues → commit

---

# B 段 · mOrangePos（另一個 repo，需真裝置）

> ★B 段任一步驟卡住＝明記「未驗＋原因」，不得靜默跳過；A 段不因 B 段未完而回退。★
> 所有 lumos 指令在 mOrangePos 目錄下用**全域 `lumos`**（不要用 `python3 scripts/lumos`，那會呼叫到別版）。

### Task 5：雙平台 config（★做完先確認既有綁定沒被弄紅★）

- [ ] **Step 1：先存基準**——`lumos guard list` 記下目前數字（實測基準：合約 5 條 — 真綁 5 / 懸空 0）
- [ ] **Step 2：改 `.lumos/config.json`**

```json
{
  "default_platform": "android",
  "platforms": {
    "android": {"profile": "kotlin-junit", "root": "."},
    "maestro":  {"profile": "maestro",     "root": ".maestro/"}
  }
}
```
（★不要寫 `"multiplatform": true`★——那是回傳的推導結果、程式從不讀；★maestro 的 `root` 不能是 `.`★——會讓 doctor 掃整個 Android repo）

- [ ] **Step 3：驗證沒弄紅**——`lumos guard list` 與 `lumos doctor`：既有 5 條 kotlin 綁定仍是「真綁 5 / 懸空 0」。**若變懸空＝設定錯，回退再修，不要往下做。**
- [ ] **Step 4：commit**（mOrangePos 的 pre-commit 同樣要求帶架構圖 .md，把本次設定寫進該 repo 的架構圖節點一併 commit）

### Task 6：測試名／flow name 改識別字 → `guard bind` → `guard audit`

- [ ] **Step 1：把要綁合約的 Kotlin 測試函式改成識別字名**（例：`` `百分比超過 100 必須擋下` `` → `manualDiscountOver100Blocked`），跑該模組測試確認仍綠
- [ ] **Step 2：三支 flow 的 config 區塊加 `name:`**（識別字、無行尾註解、＝檔名轉底線）：
  - `common-login.yaml` → `name: common_login`
  - `smoke-01-cash-checkout.yaml` → `name: smoke_01_cash_checkout`
  - `smoke-05-manual-discount-over-100.yaml` → `name: smoke_05_manual_discount_over_100`
- [ ] **Step 3：綁定**

```bash
lumos guard bind <節點> "<KEY子字串>" manualDiscountOver100Blocked --platform android
lumos guard bind <節點> "<KEY子字串>" smoke_05_manual_discount_over_100 --platform maestro
lumos guard audit <節點> "<KEY子字串>"        # 不補會停在 unaudited
```
（結果應是**同一行同一括號**逗號分隔：`[test:android:manualDiscountOver100Blocked,maestro:smoke_05_manual_discount_over_100]`）

- [ ] **Step 4：驗證**——`lumos contracts <節點>` 兩條 ref 都在；`lumos doctor` 0（不再有 unaudited／懸空）
- [ ] **Step 5：commit**

### Task 7：測試門店約定＋裝置 ready 清單

- [ ] **Step 1：`.maestro/README.md` 補兩節**
  - **測試門店／測試帳**：寫明 flow 只准跑哪個門店代號；每支 flow 標「可自動」或「僅手動、不進回歸集」（★未確認測試門店前，全部標僅手動★）
  - **裝置 ready 的可檢查前置**（實測撞過的四關，寫成逐條可勾）：①首次使用授權閘（要算挑戰碼）②複製設定★務必改裝置名★（否則兩台產生重複單號，踩既有事故）③一人登入開著時重裝沒登出會被擋（logo 連點解鎖）④別台機器編的 APK 簽章不同 → 換版本要先移除、**設定全掉**
- [ ] **Step 2：把「這支 flow 跑完要不要復原、怎麼復原」寫進每支 flow 的檔頭註解**（裝置狀態不自動還原）
- [ ] **Step 3：commit**

### Task 8：真跑驗收（★含回歸釘翻紅★）

- [ ] **Step 1：檔案形式實跑**——`maestro test .maestro/smoke-05-manual-discount-over-100.yaml` → rc0（★不是 inline★）
- [ ] **Step 2：★回歸釘翻紅驗證★**——把 `R.string.input_err` 那個錯誤字串改回去、重裝、再跑同一支 flow → **必須翻紅**。這是唯一能證明「這條 flow 真的在守那個缺陷、不是恆綠」的一步；★不做這步等於沒有回歸釘★。驗完把字串改回正確值、重裝、再跑一次確認轉綠
- [ ] **Step 3：把兩次結果（紅／綠）記進 mOrangePos 的 Verification 節點**，`plan_refs` 回指本節點
- [ ] **Step 4：終審紀律演練一次**——在沒有裝置的情境下跑一次 `lumos code-loop skip --note "無可用 Android 裝置，UI 合約未驗"`，確認留痕路徑通（d3 的操作紀律）
- [ ] **Step 5：commit＋把 B 段結論寫回本節點的「B 段實測紀錄」**

---

## B 段實測紀錄（做完回填；★沒做的項目寫「未驗＋原因」，不得留空★）

> **執行者回填 2026-08-11（消費端＝mOrangePos，commit `7a208e5`）**

| 項目 | 結果 | 備註 |
|---|---|---|
| 雙平台 config 後既有綁定沒變紅 | ✅ 通過 | 切換前後皆「合約 5 條 — 真綁 5／懸空 0／偽證據 0／裸 0／未審 0」，`doctor` 0 issues。`default_platform: android` 讓既有不帶冒號的 ref 全歸 android，符合設計預期。★`maestro` 的 `root` 設 `.maestro/` 而非 `.`★ |
| `guard bind` 兩條 ref 同行同括號 | ✅ 通過 | `↳ test: taxBaseUsesDiscountedAmount, maestro:smoke_06_setmeal_item_discount`（同行逗號分隔）。★但綁定對象與派工不同，見下方「假設不成立」★ |
| `guard audit` 後 doctor 0 | ✅ 通過（**未新跑 audit**） | 綁的是既有合約「稅基恆為折扣後」，它原本就有 `[audit:sonnet/2026-07-28]`；`guard list` 未審 0、`doctor` 0 issues，故未重跑 audit。**若設計要求「新增 ref 就要重審」，這格算未做，需回頭補規範** |
| flow 檔案形式實跑 rc0 | ✅ 通過 | `maestro test .maestro/smoke-05-manual-discount-over-100.yaml` → rc0（**非 inline**） |
| **回歸釘翻紅** | ✅ **實測翻紅過** | 把 `R.string.input_err` 改回去 → rebuild → `install -r` → 同一支 flow **rc=1**，紅在 `Assert that "折扣超過上限。.*" is visible... FAILED`；還原後複跑 rc=0 轉綠 |
| 測試門店已確認／全部標僅手動 | ⚠ **未驗＋原因** | **A5251 是否可隨意開單，未向人確認** → 依規範四支 flow 全標「僅手動、不進回歸集」。`smoke_01_cash_checkout` 會開真單且 App 端無回收路徑 |

### ★派工假設不成立（執行時發現，未繞路硬做）★

派工要求把 `smoke_05_manual_discount_over_100` 綁上「百分比不得超過 100%」的合約。
**消費端全圖查無該星標合約行**——該規則在 `Systems/付款結帳主流程_checkAmount狀態機`
是普通 `KEY:` 行（第 17、18 行）；全圖唯一與折扣相關的合約是「稅基恆為折扣後」。

依鐵則「該節點沒有合約行就別為了綁而標」，**未自行新標合約**。改為綁既有合約，並
**補強 `smoke_06` 使它真的驗稅基**（斷言 GST=`SGD 1.08` 對折後 12.00 課；回退成折前
課稅會變 1.35）。`smoke_05` 無合約可綁 → 只寫 flow 檔、節點內文記一句指向它。

> **回饋給設計**：派工預設「要綁的合約已經存在」。實務上**更常見的是規則有記錄、但沒被標成合約**。
> 建議在 skill 的派工要求補一句：先跑 `lumos contracts <節點>` 確認有星標行，沒有就走「只寫 flow 不綁」那條路，
> 別讓執行者面臨「要嘛違反鐵則、要嘛交不出來」的兩難。

### 其他與派工描述不符之處

- 派工提醒「Task 8 第 2 步重裝 APK 會清掉裝置設定」——**只適用別台機器編的 APK**（簽章不同才需先移除）。
  ★同一台自己重 build 用 `adb install -r` 設定完整保留★：本輪重裝四次驗證，翻紅實驗前後
  `KEY_DEVICE_NAME`／`KEY_RSNO`／`KEY_PUNCH_ID` 皆在。已更正寫進消費端 `.maestro/README.md`。
- `plan_refs` **不能填跨 vault 的純文字**——實測 doctor Check 4 會判「斷鏈」。設計節點的指標改記在 Verification 內文。

### 未驗清單（全部明記，無靜默跳過）

| 未驗項目 | 原因 |
|---|---|
| 測試門店 A5251 可否隨意開單 | 未向人確認；在此之前全部 flow 標僅手動 |
| `smoke_01` 納入回歸集 | 會開真單、App 端無回收路徑 |
| smoke 3／4（PayNow 取碼→取消→關帳、取碼失敗→再滑一次） | 未跑；會產生真 2C2P sandbox 交易，第 4 條還需斷網 |
| 實機 D3 驗收 | 簽章與本機不同，換版本要先移除、設定全掉 |
| 新增 ref 是否需重跑 `guard audit` | 規範未明；本次沿用既有 audit 戳記 |

## 誠實天花板（交付時要講）

- 本計畫**只接線、不造機制**——所以 spec 天花板列的東西一條都沒被解決：`name:` 唯一性無守衛、`[kill:]` 在 UI 層走不通、版面一改要重錄。
- **時機這一格 v1 只做到「skill 退場段會問」**——它是紀律不是機械閘，忘了就是忘了；pre-push 那條軟提醒方案落選（觸發點在 push 前，不是功能完成當下）。
- B 段需要真裝置，**沒裝置就驗不完**；驗不完的部分一律明記，不得用「應該可以」帶過。

## Self-Review 紀錄（writing-plans 自查，2026-08-11）

- **Spec 覆蓋**：spec 待辦 8 條 → Task 1（證據路徑＋Android 通道散文）／Task 2（時機觸發者）／Task 3（agent prompt＋七個坑＋完成判準）／Task 5（雙平台設定）／Task 6（name:＋識別字＋bind＋audit）／Task 7（測試門店＋裝置 ready）／Task 8（真跑＋回歸釘）；d3 的操作紀律進 Task 8 Step 4。★spec 天花板列為「v1 不解」的項目（kill、name 唯一性、時機機械化）本計畫同樣不解，已在誠實天花板重述★。
- **Placeholder 掃**：無 TBD／「適當處理」；`<節點>`／`<KEY子字串>`／`<今日>` 是執行時才知道的實值佔位，非規避。
- **型別一致**：`[test:平台:名]` 語法、`--platform` 旗標、`guard bind/audit` 簽名、config 鍵名（`default_platform`／`platforms.<name>.{profile,root}`）在各 task 一致，且與 spec 的訂正版一致（無 `multiplatform` 鍵、maestro `root` 為 `.maestro/`）。
