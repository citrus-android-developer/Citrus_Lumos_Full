---
type: system
status: done
created: 2026-07-10
updated: 2026-08-18
self_audit: sonnet/2026-07-20
tags:
  - type/system
  - status/done
summary: |-
  FLOW:tokenize(CJK bigram+ASCII拆分)→BM25F(欄位tf加權於飽和前,平滑IDF)→search --ranked只重排既有候選｜_reco(BFS-decay 1/2^k+共引同行×2飽和+Jaccard;G=0.6/0.25/0.15)×BM25F融合(R=0.6L+0.4G)→context --recommend｜impact --ranked(固定席=事故+合約,不占top_k;動態閾;stdin單包JSON prospective)→hook降噪(v1.1待接)
  KEY:★2026-08-03 一次性重新凍結(認領本節點原本掛著的「尚無人認領」待辦)★——eval_head=`8680ac1`、語料釘 snapshot=`285d429`、knobs=frozen-defaults,已入 `governance/eval/retrieval-eval-history.jsonl`:**search nDCG@5 整體 legacy 0.5411→ranked 0.8556(+58.1%,n=30)｜train +46.0%(n=21)｜held +99.6%(n=9,MRR 1.0)｜edit P@8 fusion 0.7298｜必看視野 19/30｜gate 7/7 PASS**。★與 2026-07-20 那次重跑逐項相同 → 尺是穩定可重現的,當初對不上的只有「+106.8%」與「24/30」這兩個★被沿用進句子、卻不對應任何一次實跑★的數★(歷程與三處出處對照見本節點〈數字已統一〉段)
  KEY:[2026-08-18 query 品質閘,plan:[[Projects/edit面查詢品質閘_計劃]]]impact ranked 加 _impact_query_junk——剝 shebang 首行後壓縮殘餘<MINLEN(預設 1=僅 shebang/空白)→視同空查詢(L 臂靜默;事故探針刻意不受閘);held hook P@8 0.6842→0.7467 六閘全綠;★E15 教訓:短真代碼的 L 撐動態閾殺 hop1 噪,「短≠無訊息」,長度分支撤★;旋鈕 LUMOS_IMPACT_QGATE_MINLEN(<=0/NaN/Inf=停用);觀測=query_gated 欄(--diff 聚合轉發) [test:t_impact_query_junk_unit,t_impact_query_gate_e2e]
  KEY:[2026-08-18 標註刷新落地,plan:[[Projects/標註刷新_計劃]]]語料前進解鎖——delta 補標流水線(refresh_labels.py delta/repin/merge/apply/signal)+重釘機械閘(計分觸及集 unjudged==0 才准動 snapshot_commit,rc1 硬擋)+考卷常設未標率(history 新欄 goldset_snapshot/unjudged_count/unjudged_rate;週閘超 10% 自動產表+LINE 等人放行);評測母體=計分觸及集(search 兩臂各前10/edit free 前8+全固定席)——全召回口徑實測連原快照都 54% 未標故收斂;B 席=Gemini Flash(Codex 到期);build_goldset 裸跑加 --force-full 拆清空金標雷 [test:t_refresh_delta,t_refresh_repin,t_refresh_merge_apply,t_eval_touched_universe_bounds]
  KEY:[2026-08-07 hook必看召回修復落地,plan:[[Projects/hook必看召回修復_計劃]]]①驗屍 11 筆必看 miss 歸因:直連被動態閾砍 6/裸檔名 1/連結缺失 4——★動態閾現行係數=0.65(v1.2)非本節點舊記 .55,以此行為準★ ②R1 直連保底席轉正(第三桶:rescued 恆 pinned:false,threshold/quota 不作用,LUMOS_IMPACT_RESCUE_N 預設 1)③R2 裸檔名容錯轉正(反查第二條抽取路,git ls-files 唯一母體,BASENAME_MATCH 預設 1,hit provenance 穿透)④held A/B:P@8 0.6389→0.6944、Σmust 12→14(E14/E15 救回)⑤[2026-08-07 同日續,plan:[[Projects/連結缺失補全_計劃]]]S2 水位謂詞轉正(free direct<N 補至 need=N−count;N=3 train 網格選出;前案「僅零 direct」候選經考卷重裁改寫)——held Σmust→17、P@8→0.7130,★週閘 hook P@top_k ≥0.70 翻綠(v1.1 以來首次)★;新暴露兩紅如實記:p95=11>10(N=3 外加席 vs 席數閘語意未跟)、graph-only 0.7269>fusion(direct 在 fusion 權重偏低的訊號,未動排序);S1=lumos link-candidates 補鏈候選(唯讀,人裁待辦)[test:t_impact_direct_rescue][test:t_s2_waterline_rescue][test:t_link_candidates][test:t_impact_basename_match] | VERIFY:[[Verification/2026-08-07_hook必看召回修復落地]]
  KEY:search面已轉正預設(2026-07-11,goldset §6全過:修正尺 nDCG@5 +58.1%/held +99.6%(2026-08-03 凍結值);--legacy逃生,--regex走舊路,預設全量+逐檔命中明細——資訊零損失);hook面已轉正(2026-07-11:P@8 .707/中位3/p95 9;dyn_coef .55/direct_base .30/名額10;trigger delta-scoped;必看視野19/30=精度代價(2026-08-03 凍結值;原記 24/30 不重現),見[[Verification/2026-07-11_hook面v1.1轉正]]);recommend面dormant;hop≥2需L>0、hop1只受靜態底線;結構前綴停用集(KEY:/FLOW:模板詞不算詞彙訊號);A1型別先驗:moc×0.4乘於詞彙分(train網格凍結,held零倒退,見[[Projects/節點靜態先驗_調研]])
  KEY:★DEBT★ 多詞片語候選=legacy片語語意(0候選不回退)★2026-08-02 部分緩解:`--any` 旗標(預設關)在整串片語全庫無命中時退成各詞 OR 召回;fallback-only 故對既有查詢零回歸(現有 goldset 30 題全部回>0候選,回退條件永不觸發)。Landmark 284 篇真庫實測:10/10 現實多詞查詢在預設下全 0 命中,`--any` 後 7/10 第一名正確。★2026-08-03 人裁翻預設★:多詞回退改為預設開、`--no-any` 逃生、`--any` 留相容。證據=補了 10 題多詞評測(雙評 Claude+Codex 跨家族、分歧交乾淨 opus 裁決):nDCG@5 0→0.767、MRR 0.95、第一名為「必看」7/10;對照組 5 題(現有命中的多詞查詢)逐檔完全相同=零回歸實證。誠實邊界:pooling bias(池半數來自回退自己)、n=10、單一快照。交付版已同步重生。見 [[Projects/檢索多詞回退_計劃]]★｜cochange proxy對架構圖related面太稀(兩vault實證,僅sanity check)｜hook接線v1.1待評測
  DEP:[[Systems/lumos-cli-read]][[Systems/cochange-guard]]
  TEST:t_tokenizer/search_ranked/context_recommend/impact_ranked/impact_diff/impact_hook_v11 全綠+全套1018 | VERIFY:[[Verification/2026-07-11_hook面v1.1轉正]] | VERIFY:[[Verification/2026-07-10_檢索排序v1]][[Verification/2026-07-11_檢索goldset評測]]
related:
  - "[[Projects/檢索優化_計劃]]"
  - "[[Systems/lumos-cli-read]]"
  - "[[Projects/節點靜態先驗_調研]]"
  - "[[Projects/檢索多詞回退_計劃]]"
verified_by:
  - "[[Verification/2026-07-10_檢索排序v1]]"
  - "[[Verification/2026-07-11_檢索goldset評測]]"
  - "[[Verification/2026-07-11_hook面v1.1轉正]]"
  - "[[Verification/2026-08-07_hook必看召回修復落地]]"
  - "[[Verification/2026-08-07_連結缺失補全落地]]"
  - "[[Verification/2026-08-18_標註刷新落地]]"
  - "[[Verification/2026-08-18_edit面查詢品質閘落地]]"
aliases:
  - 檢索排序與關聯推薦
---
# retrieval-ranking（檢索排序與關聯推薦 v1）

設計三輪 panel（Codex 跨家族否決席全勤、5/5 canary 零漏——史上首例）收斂於 [[Projects/檢索優化_計劃]]，golden 凍結 governance/golden/retrieval/。雙盲合併（Claude×GPT-5.6）八處分歧裁定見計劃節點。

## CLI（search 面已轉正；recommend/impact 面 dormant）

- `lumos search <詞> [--top N] [--json]` — **BM25F 排序已是預設**（2026-07-11 轉正；標題權重 4×body；輸出保留逐檔命中明細，只換排檔順序）；`--legacy` 走舊字母序全量、`--regex` 自動走舊路、`--ranked` 保留相容。
- `lumos context <節點> --recommend [--top 8] [--min-score 0.20] [--json]` — 圖分×詞彙融合推薦+姐妹折疊。
- `lumos impact --file F --ranked [--stdin-payload] [--incidents-only]` — 固定席降噪；**已接 PreToolUse hook（v1.1 轉正）**：窗外 ranked top-8、TTL 窗內 incidents-only；content trigger 比對 delta 內容（非整檔）。
- `lumos impact --diff <base>..HEAD [--json]` — **code-loop 橋接（2026-07-11）**：聚合整段 diff 各檔 ranked impact（query=該檔 hunk）成受影響功能面 manifest（固定席全保+top-8+來源檔）；advisory 審計鏡頭(--diff 聚合版不接 hook;單檔版已轉正接 hook)。見 [[Projects/impact-diff橋接_計劃]]。
- **事件帳種子(A2 前置)**:`lumos context` 查閱即 append `docs/.usage-log.jsonl`({ts,node,cmd},best-effort 靜默;cochange 已排除)——先累語料不進分數,frecency 等語料夠再做(查詢時現算)。
- A3 權威度已消融殺除、A1.5 狀態降權旋鈕預設關——消融數字見 [[Projects/節點靜態先驗_調研]]。
- 評測器 `governance/eval/retrieval_eval.py`（nDCG/MRR/P@k；LUMOS_EVAL_VAULT 覆寫）。

## ✅ 數字已統一(2026-08-03 凍結;原〈數字未對齊〉待辦已認領結案)

本節點 summary 記的 search 提升「+58.1% / held **+106.8%**」**查無來源**——三處記載互不相同,且 held 值三個版本全不一樣:

| 出處 | 整體 | held-out |
|---|---|---|
| [[Verification/2026-07-11_檢索goldset評測]](掛 verified_by 的源頭) | +57.6% | +104.7% |
| [[Projects/檢索優化_計劃]] §6 與**本節點** | +58.1% | **+106.8%** |
| 2026-07-20 釘定快照重跑(可重現) | **+58.1%** | **+99.6%** |
| **2026-08-03 一次性凍結(eval_head 8680ac1)** | **+58.1%** | **+99.6%** |

- 整體值 +58.1% 今日可重現。
- **held +106.8% 對不上任何一次跑出來的數**(源頭是 104.7、今日是 99.6)——最可能同 [[Verification/2026-07-11_hook面v1.1轉正]] 更正註那條:**數字被沿用進新句子**。
- 源頭 07-11 的 57.6/104.7 今日也不完全重現,合理解釋=**其後合併了 A1 型別先驗(moc×0.4)** 等排序改動,語料雖釘定但**程式碼會動**;惟這只解釋得了 ranked 側,legacy 基線同時飄(0.5317→0.5411)尚未查明。
- **★處置(2026-08-03 結案)★**:待辦已認領。今日跑出的數與 2026-07-20 那次**逐項相同**(整體 +58.1%、held +99.6%、必看 19/30、gate 7/7 PASS)——★兩次獨立重跑一致,代表尺本身穩定可重現,當初對不上的只有「+106.8%」與「24/30」這兩個被沿用進句子、卻不對應任何一次實跑的數★。已把三處統一到本組凍結值,code 版本 `8680ac1` 記入`governance/eval/retrieval-eval-history.jsonl`。
- ★保留的誠實邊界★:語料雖釘 snapshot,**排序程式碼會動**(A1 型別先驗等),故凍結值只對 `eval_head` 那版有效;日後重跑若不同,先 `checkout eval_head` 對照再判是漂移還是回歸。2026-07-11 源頭的 57.6/104.7 今日仍不完全重現,ranked 側可用 A1 解釋,**legacy 基線同時飄(0.5317→0.5411)至今未查明,維持掛著**。
- goldset 生成器 `governance/eval/build_goldset.py`：30 search（分層:繁中短詞/identifier/縮寫/單漢字）+20 edit（真 git 案例）；候選池=legacy∪ranked 去識別洗牌（sha256+salt 可重現）；標註表 retrieval-labeling-sheet.md（留白=0 省力制）。人標完解析回 goldset → retrieval_eval 跑 gate。
