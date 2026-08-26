---
name: lumos-core-knowledge
description: 跨專案核心架構圖(core-knowledge)的讀寫規範——核心業務規則的查詢、升格、偏離登記、純度治理。當對話涉及「跨專案共用的業務規則」「升格為核心」「core_refs 指針」「偏離核心」或直接操作 $CORE_KNOWLEDGE_ROOT 時觸發。與 lumos-project-notes(專案層)分工:專案的事歸專案 skill,跨專案的事歸這份。
---

# 跨專案核心架構圖(core-knowledge)

> 依據:graph-as-contract 文件 Part 2。**v1 試點階段(2026-06-10 起)**——一條核心 + 一個 facet + 純手動同步。標 ⚠v2 的規則是規劃,尚未實作。

## 位置與掛載

- **Repo**:`$CORE_KNOWLEDGE_ROOT/`(獨立 git repo,與任何專案脫鉤)
- **環境變數**:`$CORE_KNOWLEDGE_ROOT` 指向上述路徑
- **掛載**:依賴核心的專案在 `.claude/settings.json` 宣告 `requires_core: true` + `core_project_id`,session 以 add-dir 掛載核心 repo
- **讀寫工具**:同專案 skill,**以 lumos 為主**——核心 repo 是 standalone vault root,`cd` 進去或 `lumos --vault <核心路徑>` 即可 `doctor`/`context`/`search`/`set`/`append`(lumos find_vault 支援 standalone root)。Obsidian CLI(vault 名 `core-knowledge`,leading `vault=`)只留給 lumos 沒有的 obsidian-only 場景。
- **跨 repo 指針完整性**:`lumos doctor` 的 **Check C** 會驗專案端 `core_refs:` 指到的核心檔案是否還存在(核心改名→專案指針懸空=權威失聯,本地無快照可救)——這是「敢只留指針、不留快照」的前提守門。

## 結構

```
projects/         # 專案 facet:宣告依賴與下游(implements/params/references/verified_at/deviations)
Business/         # 核心節點:業務規則本身(類別 A),以領域子資料夾分域
  member/         #   會員系統域
  dining/         #   餐飲系統域(KDS 等)
  common/         #   跨域共通
Technical/        # 類別 B 技術模式(v1 不做)
Verification/     # 核心規則本身的驗證(valid_under/revalidate_when 必填)
Decisions/        # 跨領域重大決策
MOC/              # 索引
```

## 兩種 schema(不可混淆,違反 = 結構腐蝕)

### 核心節點(`Business/*.md`)——事實宣告,不知道下游

允許欄位:`type: core-business`、`domain`(member/dining/common,對應子資料夾)、`status`(active/stale/superseded/demoted)、`summary`、`decisions`(ADR 四欄位)、`valid_under`、`revalidate_when`、`verified_by`。

**禁止欄位**(看到想加就是該擋下的時候):
- ❌ `used_by` / `referenced_by` / `references`(下游關係 → facet)
- ❌ `variants` / `parameters_by_project` / 任何以專案名為 key 的欄位
- 唯一例外:`status: demoted` 節點可留 `project_versions`(歷史指針,腳本不讀)

### 專案 facet(`projects/{name}.md`)——關係樞紐,只能是指針+參數

`implements` 條目:`rule`(wikilink 指核心節點)、`params`(參數差異)、`references`(該專案程式碼路徑)、`verified_at`(v1 純記錄)、`deviations`(合規偏離,每筆必有 reason + decision_link)。

**絕對不能寫實質業務邏輯**——規則本身只能在 `Business/`。

### 分域紀律(軟邊界)

- 核心節點放 `Business/{domain}/`,frontmatter `domain:` 同步——**單 repo 資料夾分域,不拆多 repo**(邊界 v1 猜不準、facet 是專案級可能跨域、wikilink 按 basename 解析搬資料夾零成本)
- 跨域都用的規則放 `common/`;分類錯了直接搬,不用改連結
- **拆獨立 repo 的訊號**(v2+ 再議):某域節點多到 MOC 難讀、或兩域治理節奏明顯不同

## 閱讀規則(查核心知識時)

1. **入口一:專案筆記的指針**——專案架構圖筆記見 `core_refs:` property 或 summary `CORE:` 行 → 該主題權威在核心,**專案筆記殘留的描述不可當權威**(專案側依紀律不留快照,若看到疑似快照內容 = drift,該清)
2. **入口二:核心 MOC**——`MOC/核心知識索引.md` 列全部核心節點與狀態
3. **讀核心節點先看 status**:`active` 才是現行;`stale` 警告勿依賴;`superseded`/`demoted` 是歷史脈絡與學習資產
4. **查某專案的參數/偏離**:讀該專案 facet 的 `implements`,不在核心節點找(那裡沒有,也不該有)
5. **查「誰偏離了某條核心」**:掃所有 `projects/*.md` 過濾 deviations 非空(v1 即席掃,規模化後讀快取表)
6. **自足性審計**:審計 agent 的可讀範圍要涵蓋已掛載的核心 repo,否則升格後的規則會被誤判為「架構圖缺漏」

## 寫入規則

### 升格(專案知識 → 核心)門檻 = 品質契約四條,缺一不可

1. 具體的 `valid_under`(不准寫「目前有效」)
2. 完整 ADR 四欄位(context/alternatives≥2/why_chosen/trade_offs)——不可編造,缺資訊問使用者
3. 對應 Verification(證明**規則本身**在現實成立,如 DB 實證;不是「我覺得它對」)
4. 認真的 `revalidate_when`(從 valid_under 反推)

### 升格不是遷徙(指針紀律)

- 專案筆記**不搬走不掏空**:加 `core_refs:`(純文字路徑,**禁用跨 vault wikilink**——會斷鏈長 ghost 節點)+ summary `CORE:` 行 + 內文指引段落
- **不留內容快照**(快照 = 雙寫帳本必 drift);專案層只保留本來就屬於專案的部分(寫入路徑/實作慣例/UI 細節)
- 同時建/更新 facet 的 `implements`(含 references)——**facet `implements` ↔ 專案筆記 `core_refs` 雙向核對**,audit 時檢查
- 異動核心規則 = 改核心節點 + 跑核心 Verification + 手動 commit 兩邊 repo(v1 無自動化)

### 偏離與變體:四類型決策樹(降級才是主軸)

| 情況 | 類型 | 處理 |
|------|------|------|
| 只差參數(tax_rate 之類) | 一:參數差異 | facet `params`,核心不動,**不算變體** |
| 少量、有正當理由的例外 | 二:合規偏離 | facet `deviations` 登記(reason+decision_link 必填),核心不動 |
| 偏離專案數 ≥3 或偏離規模 > 規則本身 | 三:分裂 | ADR + 原核心 superseded + 拆新核心 |
| 只剩 1 專案在用 / 各專案版本根本不同 | 四:降級 | 搬回專案層,核心標 demoted。**降級不是失敗,是健康** |

新增偏離前三問:真的不可避免?理由半年後還成立?是不是核心切分錯了?——任一答「不」就走分裂/降級,不是登記。

**主動發問規則**:某核心**偏離總數 ≥2**(全 facet 加總)時,處理該核心的 Claude 必須主動問:「這還是真核心,還是該分裂/降級?」(偏離專案數 vs 偏離總數是兩個指標,別混用:前者管降級訊號,後者管提醒頻率)

### 三條結構紀律

1. **禁止 version pinning**:核心只有當前版本;facet 想加 `version:` 欄位就是違規訊號
2. **粒度 ≥ 最小可獨立驗證的 Bounded Context**:小到寫不出有意義 alternatives 的規則,併進更大節點
3. **引用密度 ≥2 專案**才是真核心;只被 1 個專案用的內容回專案層(v1 節點豁免——它是「候選核心」,第二專案接入才測純度)

## v1 已知盲區(詳 README,動手前讀)

新核心識別無機械輔助(最弱環節)/判斷漂移/單人前提/品質失守=定時炸彈/休眠專案隱形腐爛/facet 漏登記靜默漏抓。

## v1 不做(⚠v2 規劃,別當現有功能)

掃描機制(implements 反查 diff)、跨 repo hook、`verified_at` 影響分析、偏離計數快取表。

> 已落地(原列此處,現移除):**`core_refs` 指針存在性檢查**=lumos doctor Check C(跨 repo 驗專案指針指到的核心檔還在不在);更深的「核心模式」(implements↔core_refs 雙向核對、deviation 掃描)仍待 v2。
