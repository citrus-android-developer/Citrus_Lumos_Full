---
type: system
status: done
created: 2026-08-11
updated: 2026-08-26
aliases: []
tags:
  - type/system
  - status/done
  - scope/governance
  - risk/守衛面
related:
  - "[[code側刪除傳播守衛_計劃]]"
  - "[[code側刪除傳播守衛_實作計畫]]"
  - "[[Systems/cochange-guard]]"
summary: |-
  FLOW:pre-commit Gate DG(Gate CC 旁)→`lumos delguard --staged`→S1 staged diff `-` 行抽被刪識別字(per-file 回收表/stopword/排除域路徑段+lockfile/.md/簿記檔 不抽)→單次 git grep --cached 判兩檔信心(全域消失=high/呼叫點殘存=low)→三件套 regex 掃 vault 指名「還在講它」的節點+原句(型別只排序不壓低,Systems 排前)→S2 純連結編輯(LINK_KEYS 子集)∧S1 命中=假同步嫌疑→S3 退場三問(stdout)
  KEY:advisory 恆 rc0——crash(`|| true`+except Exception)/timeout(python 內建 deadline,env LUMOS_DELGUARD_DEADLINE,預設 2.0s)/git diff rc≠0 皆降級放行,降級訊息走 stdout;--json 含 tokens/hits/fake_sync/degraded/reason
  KEY:降級與正常通過都不擋 commit,訊息是唯一區別——故降級輸出一律自陳「★本輪未實際守衛★」;TimeoutExpired 走專屬 except 歸 reason=timeout(2026-08-26 前混進 error,文字說「內部錯誤」,違反自家 reason 契約且讀起來像程式壞掉)
  KEY:簿記檔(*.jsonl 帳本、anchor-baseline.json)不抽 token——內容是**紀錄**不是宣告,刪一行從來不代表符號沒了。修前治理帳一變動就報「code 側刪除傳播」(純假陽性),且欄位名 commit/gate/kind/nodes 這類常見字會餵爆 git grep [test:t_delguard]
  KEY:★DEBT★ 掃描成本未解,但根因已定位:**不是掃描量,是 git grep 的 pattern 數**。2026-08-26 量測(同一組檔案):1 個常見 token 0.03s / 10 個 83.71s;拿掉 -w 是 97.23s、拿掉 -n 是 108.59s——與 -w/-n 無關,單 pattern 快、多 pattern 退化。階段耗時:git diff 0.02s / parse 0.00s / **_delguard_confidence 159.97s** / vault_scan 0.21s。候選解=改逐 token 各跑一次 grep(單 pattern 0.03s × 40 ≈ 1.2s),但會動到本節點宣告的「單次 git grep」設計,未做
  KEY:快照契約=staged index(git grep --cached;diff 帶 -M 與 -c core.quotePath=off -c diff.noprefix=false -c diff.mnemonicPrefix=false);vault-only repo(graph_root=".")靜默 return 0
  KEY:先驗值 cap=40(DELGUARD_TOKEN_CAP)/top-10(DELGUARD_TOP_N),超 cap 保留高信心逐條+統計行不清零;replay 校準後以數據取代
  KEY:天花板=只抓「符號消失」型;死碼盲區(符號在、機制停用=存在性比對放行)/行為反轉/純語意矛盾不響——見 [[code側刪除傳播守衛_計劃]] 天花板節能力邊界表;v2 候選=呼叫點判定
  KEY:排除域與 pre-commit should_exclude 對齊(7 目錄+lock 三檔名),漂移由 t_precommit_whitelist_drift_guard 釘第三份清單;S3 問句同步在 lumos-project-notes skill 退場段(無 delguard 的 repo 靠自律)
  DEP:[[Systems/cochange-guard]](同型 advisory 前例,Gate CC 鄰位)｜scripts/hooks/pre-commit Gate DG｜find_vault/_cochange_repo_root 共用 helper
  TEST:t_delguard(scripts/test_lumos.py,96 條=85+2026-08-26 超時分類 8 條+簿記檔排除 3 條:S1 抽取/信心/掃描/S2/S3/fail-open/deadline/邊界輸入/鑑別力翻紅驗證)+t_precommit_whitelist_drift_guard 擴充;全量 2515/0@95c4224
verified_by:
  - "[[Verification/2026-08-11_delguard落地]]"
  - "[[Verification/2026-08-26_全repo術語統一為架構圖]]"
  - "[[Verification/2026-08-26_delguard超時分類與降級訊息修復]]"
  - "[[Verification/2026-08-26_delguard簿記檔排除與成本根因定位]]"
---
# delguard — code 側刪除傳播守衛（S1+S2+S3）

**一句話**：commit 當下抓「code 拿掉了某個東西、架構圖還在講它」，把過期指名到具體哪一句（advisory，不擋 commit）。

設計脈絡、失守實錄（mOrangePos aff2329）、誤報處置、能力邊界表全在 [[code側刪除傳播守衛_計劃]]（design-loop r1/r2 收斂，golden 凍結）；實作拆解與審計歷程在 [[code側刪除傳播守衛_實作計畫]]（SDD 8 task＋code-loop 三輪 panel 收斂，留痕 `governance/review-reports/code-delguard/`）。

已知殘項（v2／另案）：死碼判定（呼叫點為零＝過期嫌疑）、存量掃描另案、誤報帳人工記錄升自動化憑數據再議、vendored 白名單源 repo 反轉語意。
