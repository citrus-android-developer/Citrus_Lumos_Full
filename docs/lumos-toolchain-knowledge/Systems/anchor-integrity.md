---
type: system
status: done
created: 2026-07-02
updated: 2026-07-28
self_audit: sonnet/2026-07-24
tags:
  - type/system
  - status/done
  - risk/守衛面
verified_by:
  - "[[Verification/2026-07-02_anchor-integrity]]"
  - "[[Verification/2026-08-26_全repo術語統一為架構圖]]"
summary: |-
  FLOW:anchor approve --note→5錨點(runner×2+hooks×3) sha256→anchor-baseline.json(checked-in)+治理帳 anchor-approve 事件｜anchor verify→逐錨點比對→mismatch/缺檔 rc1(pre-push 擋、自主 loop 每輪入口硬擋含 missing baseline)
  KEY:守「驗證器本身被悄悄改成一律通過」——測試綠/hook 放行的前提(批改程式沒被動過)從盲信變成可機械核對宣稱;外部實證=八大評測被 conftest 鉤子破
  KEY:刻意不守 scripts/lumos 本體(天天迭代→盲簽疲勞);分層=baseline 守驗證器、測試守被驗物
  KEY:loop 入口比 pre-push 嚴——missing baseline 視同失敗(無人看顧無人眼兜底);pre-push 維持 rc0+警示(漸進採用)
  KEY:[2026-07-28]調研 gap 候選(arXiv 2607.05743:「檢查時刻vs使用時刻」分離=agent 執行安全通病)——anchor verify 在 pre-push 本機驗、測試實跑在稍後雲端 CI,中間空窗無人看;候選解=CI 端跑測試前自算受護檔雜湊寫入該次執行紀錄、放行時比對「當時真正跑的是哪一版把關程式」;未排程(與既有天花板「真解留 future CI」同向,此為具體形狀)
  KEY:誠實天花板——同 repo 守衛悖論:決意繞過者可連守衛一起改;買到的是無痕篡改被封死(必留 baseline diff/缺 approve 事件/bypass 軌跡其一),非不可繞。baseline 自身無自我保護(手改 json 靠對帳抓,v1 人工);core.hooksPath 一行可指走整個 hooks 層(loop 入口 shell 直呼=第二條路,真解留 future CI)
  DEP:[[lumos-refcheck]](vault-free 同型)｜_append_governance_log(寫者宣稱已改:doctor --ci + anchor approve)
  TEST:t_anchor 14 checks(無 baseline 警示/approve 建檔+留痕/gov 顯示 note/改檔+缺檔 rc1/--json/重簽容缺/repo 解析 rc2)
  VERIFY:[[2026-07-02_anchor-integrity]]
decisions:
  - content: 方案 A baseline hash+顯式 approve;否決 RHB 環境硬化(方案 B)與純 diff 標記送審(方案 C)
    id: d1
    context: 本機單人工作流沒有 agent 摸不到的執行面,硬寫隔離=自欺;marker 對 agent 零成本自貼、無內容 hash 底線
    why_chosen: 機械、確定性、零依賴;無痕篡改被封死到只剩「連守衛一起改」,人 review 有明確紅旗;B 留 future 真 CI(baseline 屆時直接複用)
    decided: 2026-07-02
    valid: true
  - content: 錨點集合 v1 固定列舉 5 檔,不含 scripts/lumos 本體
    id: d2
    context: lumos 是自主 loop 天天迭代對象,收進 baseline=每天 approve→盲簽疲勞,守衛立刻形同虛設
    why_chosen: 分層——baseline 守驗證器(runner+hooks),測試守被驗物(lumos 行為);改壞 lumos 由 test_lumos.py 抓,前提「runner 沒被動」正是 baseline 守的
    decided: 2026-07-02
    valid: true
---
# anchor-integrity

`lumos anchor verify/approve`——**錨點完整性守衛**(vault-free):測試 runner 與把關 hooks 的 sha256 baseline + 顯式 approve 留痕。

## 動機
方法論最底層退路「CI 跑真測試、綠才算數」把測試結果當不可造假真值,但 runner/評分器本身可被悄悄改寫(外部實證:八大權威評測被 conftest 鉤子全破)。lumos 自主 loop 的 agent 摸得到整個 repo,同樣風險。

## 接線
- `scripts/hooks/pre-push`:環境檢查後、vault 閘門前(repo 層,無 vault 也跑);rc1 擋 push,訊息三選一(還原/approve/--no-verify 留痕)。
- `governance/autonomous-loop.sh`:每輪 gap 派 orchestrator 前(污染可能發生在當天中途);errexit-safe;missing baseline 硬擋。
- 改錨點的合法路徑=`lumos anchor approve --note`(重算寫回 + 治理帳 `anchor-approve` 事件,note 進 `lumos gov` 顯示)。

## 相關
- 設計稿:`docs/design/2026-07-02-anchor-integrity.md`(design-loop 3 輪、R1 missed 作廢、R2+R3 收斂;qwen endorsed;辯方 4 次全駁倒假 major)。
- 實作計畫:`docs/superpowers/plans/2026-07-02-anchor-integrity.md`。
