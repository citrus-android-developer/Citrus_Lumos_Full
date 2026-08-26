# 設計:design-loop 審計派工的第三方框架補強(audit-thirdparty-framing)

- 日期:2026-06-30
- 狀態:design-approved
- 動機來源:2026-06-30 治理日報 gap G1「AI 改不動『掛自己名』的錯(差 23–93pp),只能結構繞開;逐字查 design-loop 與 [audit:] 派工提示,確認待審物一律包裝成第三方」
- loop_id:audit-thirdparty-framing

## 目標(一句話)

把 G1 的「免費結構招」(待審物框定為第三方、不是自己的)在 design-loop 兩條審計路徑拉滿:① 消除 orchestrator 對「自己 spec 之批評」的折入裁量;② 審計員派工明說「當外部投稿審」。**純提示措辭、零 code 改動。**

## 前提與既驗事實(逐字審計,2026-06-30)

- **`[audit:]` / L4 已到位**:`skills/lumos-project-notes/SKILL.md:324` 已明文「prompt 必須中立(用『試圖反駁』而非『請確認這條合法』——後者帶風向,等於自己改自己的考卷)」+「不餵你的結論」。本 spec **不動這條**。
- **審計員本就是乾淨 spawn + refute framing**(`skills/lumos-design-loop/SKILL.md:25`「派乾淨審計員…不告知有 canary…refute framing」;`orchestrator-prompt.md:36`「spawn opus auditor 要它 REFUTE 工作副本」)——第三方框架靠 maker≠checker 分離天生達成,本 spec 只把它「說滿」。
- **orchestrator 自折張力**:`orchestrator-prompt.md` step 5(L39)「你讀 auditor 報告**決定哪些** findings 折進 spec」(有裁量)與 step 7(L41)「caught → 只折**辯方存活**的真 finding」(無裁量)用語不一致;step 5 的裁量語句正是 G1「作者放生對自己作品的批評」最會咬的縫。

## 範圍(兩處改動,皆 prompt markdown)

### fix #1 — orchestrator 自折措辭對齊(`governance/autonomous_loop/orchestrator-prompt.md` step 5)

把 step 5 的裁量語句改成與 step 7 一致的無裁量語句:存活(辯方裁決後)的真 finding **一律折入,不挑、不過濾;被辯方駁倒的不折**。orchestrator 仍負責「執行折入(編輯 spec)」,但**沒有「哪些值得折」的裁量空間**。step 7 既有的「fold 後 grep canary token == 0」自查不變。

### fix #2 — 審計員「當外部投稿」framing(兩處,接在既有 refute framing 前)

- `governance/autonomous_loop/orchestrator-prompt.md` step 3(spawn opus auditor)
- `skills/lumos-design-loop/SKILL.md` step 3(派乾淨審計員)

各加一句語意等同:**「把這份工作副本當外部第三方的投稿來審,不是你/本系統寫的——你的職責是挑出投稿者沒看到的洞」**。措辭可依各檔語氣微調,語意一致即可。

## 邊界 / 非目標(YAGNI)

- ❌ 不動 `[audit:]` / L4 派工(已到位)。
- ❌ 不加 per-finding 折入帳(brainstorm 選「措辭對齊(輕)」,非「對齊+折入帳」)。
- ❌ 不動 judge / 辯方 的 framing。
- ❌ **不改任何 code**(`scripts/lumos`、`governance/autonomous_loop/*.py` 一律不碰)。
- ❌ 不做「量各層邊際抓錯率」的 A/B 實驗(另一條工作,延後;G1 把它與本招混為「二選一」是 category 混淆——第三方框架治『偏袒自己產出』、cross-family 治『同家族共有盲點』,互補非替代)。

## 測試策略

純 prompt markdown、無 code → **無單元測試**。驗證 =:
1. 改動存在:`orchestrator-prompt.md` step 5 無「決定哪些」裁量語、step 3 與 SKILL.md step 3 含「外部投稿/第三方」框架句。
2. 流程仍順:orchestrator-prompt.md 與 SKILL.md 通讀一遍,步驟編號/引用未被改動破壞。
3. 自然 dogfood:下次 design-loop 實跑(手動或自主)即驗審計派工讀起來正確。

## 知識同步影響

- `docs/methodology/架構圖即合約.md` / `架構圖即合約-對外論述.md`:無影響(未改方法論語義,只強化既有 maker≠checker 的派工措辭)。
- skills:**`skills/lumos-design-loop/SKILL.md` 本身就是被改對象**(step 3 framing 句)——改動即同步,無額外 drift。
- KG:無新節點;本 spec 屬「機制提示打磨」,落地後可於 `Systems/design-loop` 與 `Systems/finding-refute` 內文補一句「審計派工採第三方投稿框架」(放行時順手,非必須)。

## 誠實天花板

1. **framing 是機率性微調**:23–93pp 是研究分布、非保證;這次拉滿免費招,真正邊際價值要靠延後的 A/B 量。
2. **第三方框架 ≠ 同家族盲點**:本 spec 不取代 cross-family;兩者治不同失效。
3. **orchestrator 自折仍是作者執行**:措辭對齊消除「裁量放生」的語言縫,但「作者忠實編輯」最終仍靠誠實 + step 7 的 canary grep 自查兜底(同 maker/checker 天花板,未閉合)。
