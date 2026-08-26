---
type: issue
status: done
created: 2026-08-17
updated: 2026-08-17
aliases: []
tags:
  - type/issue
  - status/done
summary: |-
  FLAG:TECHNICAL
  KEY:2026-08-17 Landmark 跑 lumos update 後自測 2139綠/76skip/★3紅★,三紅全是引用來源 repo 資產的測試漏掛「來源 repo 專用」skip 守衛
  KEY:①t_precommit_whitelist_drift_guard 讀 docs/lumos-toolchain-knowledge/Systems/pitfalls-code-loop.md ②「snr 腳本 rc0」③t_s2_snr_synthetic 跑 governance/eval/canary_snr.py——兩檔皆僅存在 toolchain 本體,vendored 專案必炸 Errno 2
  KEY:修法=比照既有 76 支的 skip 判準(偵測 vendored 環境)把這 3 支納入;工具本身無回歸(doctor/query 冒煙皆過)
related:
  - "[[Issues/vendored測試套件在消費端假紅]]"
---
# vendored自測3紅_來源repo專用測試漏標skip

> ## ✅ 已結案(2026-08-17)— 兩處 skip 守衛補齊/修細,消費端模擬實證轉 skip
>
> ①`t_precommit_whitelist_drift_guard` 頂部補 `_need_src("docs/lumos-toolchain-knowledge/Systems/pitfalls-code-loop.md")`(尾段直讀來源 repo 架構圖節點);②`t_s2_snr_synthetic` 守衛從目錄粒度 `governance/eval` 修細到檔案粒度 `governance/eval/canary_snr.py`——Landmark 自己有 governance/eval(檢索考卷),目錄粒度會放行後炸,★判準粒度必須到「真正要用的檔」★。**實證**:新回歸釘 `t_vendored_consumer_srconly_skip_regression` 搭消費端模擬環境(scripts/ 有、docs/ 無、governance/eval 目錄在但腳本不在),修前重現 Landmark 三紅一字不差、修後兩支轉 skip 零 ✗;來源 repo 兩支照跑不跳(30+5 斷言),全量 2642 綠。
>
> ⚠ 三紅實為兩支測試(②③是同一支的連鎖:check 翻紅後 json 解析再炸)。同類前案見 [[Issues/vendored測試套件在消費端假紅]](2026-08-02 立 _need_src 機制那案;本案=機制立了但兩支漏掛/掛太粗的復發)。
>
> ★以下「現場輸出」是當時的排查紀錄,不是現況。★

消費端現場:LandmarkMember@develop cec3645f(chore(lumos) commit message 引本案)。
三紅輸出原文:

```
✗ t_precommit_whitelist_drift_guard EXCEPTION: [Errno 2] No such file or directory: .../docs/lumos-toolchain-knowledge/Systems/pitfalls-code-loop.md
✗ snr 腳本 rc0  python3: can't open file '.../governance/eval/canary_snr.py': [Errno 2] No such file or directory
✗ t_s2_snr_synthetic EXCEPTION: Expecting value: line 1 column 1 (char 0)
```
