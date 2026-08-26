---
type: project
status: done
created: 2026-07-11
updated: 2026-07-11
tags:
  - type/project
  - status/done
---
# kotlin慣例skill_計劃（後擴為三棧）

使用者提問「如何規範 AI 寫得好（如兩支 API 該 combine 不該串聯）」→ 裁定三層解（linter 管形狀/慣例文件管選型/審查鏡頭補漏)→ 首份技術棧慣例文件選 Kotlin。

PRIOR-ART: 網搜評審真搜權威源(Google coroutines best practices/Kotlin 官方/detekt coroutines ruleset/mrmans0n compose-rules/Slack compose-lints,附 URL)× Codex 讀 Citrus_KDS 真碼盤點——雙研究員收斂後合成。裁定=borrow-design(規則借官方,文件原生)。

## 關鍵裁定

- **分層(使用者糾正後定調)**:skill 只寫「不隨框架選擇改變的通用不變量」(R1-R18,以「可注入可替換」等能力措辭);Hilt/Koin 等當地選擇歸各專案架構圖——KDS 盤點(好範式/壞味道)寫進 KDS 自己的 Issues 節點,不進 skill。
- **不可機檢的排最前**:R1 並行/R2 combine/R8 main-safe 恰好都是語意判斷,文件+審查鏡頭是唯一防線——這是文件存在的理由;可機檢的收進「機檢接線」段交 detekt/compose-rules。
- **審查鏡頭紀律**:finding 必須引用條號,引用不出=風格意見不收(執法不立法)。
- **飛輪**:每次人工糾正 AI 醜寫法→回填一條/一例,同事故語料哲學。

## 落地

- `skills/kotlin-idioms/SKILL.md`(user-scope,install 自動 symlink)。
- 順手修 `_SKILLS` 硬編碼漂移:改掃 skills/ 目錄(實效:先前漏裝的 code-loop/pitfalls-gapfill 這次全掛上)——「列舉表會漏」的又一實證與機械解。
- KDS 當地盤點:`Citrus_KDS docs/kds-knowledge/Issues/ISSUE-kotlin慣例盤點待遷移`。

## 三棧擴展（2026-07-11 晚,使用者「兩個版都做」）

同管線再跑兩輪:`vue-idioms`(R1-R13)與 `csharp-idioms`(R1-R12)——各自=網搜權威源(Vue 官方含 vuejs-ai/skills AI 專用 repo、eslint-plugin-vue 規則表;Fowler AsyncGuidance、MS Learn 五頁、AsyncFixer/VSTHRD/Meziantou 三包對照)× Codex 讀 Landmark 真碼(前端+後端)。當地盤點入 Landmark vault(ISSUE-vue慣例盤點/ISSUE-csharp慣例盤點,非教條)。

**最好的收穫**:Codex 在 Landmark 後端抓到**現行串聯 await 病例兩處**(RedeemActivityService.cs:223/:84,各自建連線互不依賴卻依序等)——skill 的頭號條款在自家現場有真病人;同時抓到**反例現場**(DispatchAsync 批次共用 conn/tx 不准平行)——寫進 csharp skill R1 的「資源共享前提」,防矯枉過正。

## 相關模組

- [[Systems/lumos-cli-lifecycle]]
