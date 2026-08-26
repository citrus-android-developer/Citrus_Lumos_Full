---
type: system
status: done
created: 2026-07-02
updated: 2026-07-02
self_audit: sonnet/2026-07-24
tags:
  - type/system
  - status/done
  - risk/守衛面
verified_by:
  - "[[Verification/2026-07-02_lumos-refcheck]]"
summary: |-
  FLOW:refcheck <md> --repo <root>→FENCE剝/INLINE抽/剝反引號→跳://與*<>?→剝:suffix(純數字才當行號)→須含/且首段=頂層目錄→(token,line)去重→exists/is_dir/行號範圍核對→manifest{token,line,status,excerpt}+統計→rc 0/1/2
  KEY:vault-free(pre-Env 分流,同 install/bootstrap);--repo 省略時 cwd 逐層向上找 .git,無則 rc2
  KEY:去重粒度=(token,line) tuple,刻意不沿用 doctor Check P 的 token 級(同檔多行號不塌;manifest 粒度掛行號)——抽取 step1-2 同款、複製非共用
  KEY:只驗 spec→repo 指涉、不驗 spec 內部一致性(§ref/旗標/常數)——canary 保留地,refcheck 抓走=test-the-tester 防線報廢;(d)型 canary 靠裸檔名(無/)天然在抽取域外(散文規範非機械強制)
  KEY:誠實天花板——存在≠語意正確;行號漂移半盲(內容換掉仍 ok,excerpt 供目視);只收 inline-code 宣稱(散文路徑/fenced/頂層檔案/top-dir typo 皆域外);manifest 錨定效應要 prompt 明示「非宣稱全集」
  DEP:[[canary-audit]]｜doctor Check P(抽取規則同源)
  TEST:t_refcheck 14 checks(missing/ok+excerpt/out_of_range/範圍行號/同檔多行號不塌/目錄型/跳過規則/rc語意)
  VERIFY:[[2026-07-02_lumos-refcheck]]
decisions:
  - content: 抽取邏輯從 Check P 複製而非抽共用 helper;去重粒度 (token,line) 與 Check P 的 token 級刻意分歧
    id: d1
    context: spec r3-F1:Check P token 級去重會把同檔多行號引用塌成一條,refcheck 的 line_out_of_range/excerpt 都掛行號上;spec 明示共用方式留實作決定
    why_chosen: 兩者粒度不同,硬共用要帶 mode 參數反而耦合;複製段小(~30 行)且各自有測試鎖行為
    decided: 2026-07-02
    valid: true
  - content: refcheck 刻意不驗 spec 內部一致性,rc 不進 loop status 收斂判準
    id: d2
    context: canary a/b/c 全是 spec 內部瑕疵,refcheck 機械抓掉=auditor 看 manifest 就能「抓到」canary,test-the-tester 失效;它是 pre-audit 修正器不是第五道 gate
    why_chosen: canary 相容性是 spec 標明「不可違反」的設計約束
    decided: 2026-07-02
    valid: true
---
# lumos-refcheck

`scripts/lumos` 的 `refcheck` 子指令——spec 指涉宣稱的**確定性核對 + 證據 manifest**(vault-free)。

## 動機
design-loop/跨家族複核最吃重的「地面事實查證」恰是 LLM 最不可靠的能力(<55%);放行本 spec 時 qwen disputed 的 5 條 ≥major 指控被 python/sed 秒級全反證,即現場實證。refcheck 把「檔在不在、行號在不在範圍」機械化,LLM 只判 grep 查不到的語意。

## 三個消費端
- 自動 loop:`governance/autonomous_loop/orchestrator-prompt.md` §2 步驟 2.8(植 canary 後、spawn auditor 前對工作副本跑;missing/超界=機械 finding 修原稿留痕)+ auditor/judge prompt 附 manifest + §2.5a ground_truth 機械底座(不得刪減,散文規範)。
- 手動 loop:`skills/lumos-design-loop/SKILL.md` 步驟 2.5 同款 + (d) 型 canary 裸檔名校準規則。
- 方法論:`docs/methodology/架構圖即合約.md` 設計前審計 loop 表「機械 refcheck」列。

## 相關
- 設計稿:`docs/design/2026-07-02-spec-refcheck.md`(design-loop 3 輪收斂;qwen disputed 經人裁機械反證後放行)。
- 實作計畫:`docs/superpowers/plans/2026-07-02-spec-refcheck.md`。
