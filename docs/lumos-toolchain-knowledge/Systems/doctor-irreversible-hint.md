---
type: system
status: done
created: 2026-06-26
updated: 2026-06-26
self_audit: sonnet/2026-06-26
verified_by:
  - "[[Verification/2026-06-25_doctor-irreversible-hint]]"
tags:
  - type/system
  - status/done
  - risk/守衛面
summary: |-
  FLOW:doctor --ci → section("H") → [非 ci 印「互動模式略過」即跳]→ _scan_diff_for_irreversible_hints(str(env.vault)) → git diff --staged(優先)|HEAD~1..HEAD fallback → 逐 +行比對 7 條 pattern(跳 .md/.txt/.rst、測試檔、純注解)→ 有命中 warn_soft 提示「是否漏標 ★IRREVERSIBLE★」(hits[:8])|無命中 ok
  KEY:warn_soft 軟提示——不計 issues、不影響 rc;Check H 是「摩擦地板」提醒,不是合規守衛(NOPE hard block)
  KEY:只在 ci=True 跑;互動 lumos doctor 不掃 diff(減噪)
  KEY:pattern 字面比對,不解析架構圖對應哪個 Systems 節點(跨 code→graph 映射 v1 成本>效益);不交 LLM 判可逆性(無形式保證)
  KEY:與 Check R 互補——R 守「標了要合規」(scripts/lumos:619-642),H 提醒「沒標但可能需要」
  KEY:cwd=str(env.vault) 正確——git diff 無 pathspec 時範圍恆為全 repo,子目錄 cwd 不縮小範圍
  DEP:run_doctor(ci 旗標)｜warn_soft/ok/section(皆 nested in run_doctor)｜IRREVERSIBLE_HINT_PATTERNS 常數
  TEST:scripts/test_lumos.py t_check_h_irreversible_hint(7 案例,258 passed)
  VERIFY:[[Verification/2026-06-25_doctor-irreversible-hint]]
decisions:
  - content: 採方案 A(regex 字面掃 diff +行 + soft warn);否決 B(跨 graph 節點比對)與 C(LLM 判可逆性)
    id: d1
    context: 2026-06-22 日報 gap 提「漏標一個不可逆動作=靜默放行危險操作」,要把判可逆性從全靠人想到變機器提醒
    why_chosen: soft reminder 價值在「觸發思考」不在「精確鎖定節點」;B 因大量 Systems 無 [test:] link 會靜默漏提;C 的 LLM 判官無形式保證(gap 自承 weakness);維持「方法論工具靠確定性機制、不靠 LLM 自判」原則
    decided: 2026-06-25
    valid: true
  - content: Check H 刻意不寫 gov_events
    id: d2
    context: design-loop r4/r5 canary 質疑為何不入治理帳;辯方反證 scripts/lumos:L660/666/699/1228-1230
    why_chosen: gov schema 為「blocked/warned 級 gate finding」,Check H 是 warn_soft 摩擦地板提醒(非 gate finding);且 Check H 無具體 Systems nodes 可記錄(nodes=[]),node-less gov_event 在 cmd_gov(L1228 q in r["nodes"])查不到任何節點,對 lumos gov <node> 消費端零可見性增益
    decided: 2026-06-25
    valid: true
  - content: 常數 IRREVERSIBLE_HINT_PATTERNS 與 helper 放可逆性軸群(IRREVERSIBLE_RE 附近),helper 內自帶 import subprocess
    id: d3
    context: design-loop r1 canary 抓真 blocker:全檔 subprocess 皆函數內 lazy import、module-level 無 subprocess,module-level helper 不自帶 import 會 NameError;r2/r3 修放置位置
    why_chosen: 遵本檔既有慣例(可逆性 helper 群聚 + run_doctor 前向引用在呼叫時解析);lazy import 與 L339/L2298 等先例一致
    decided: 2026-06-25
    valid: true
aliases:
  - Check H
---
# doctor-irreversible-hint

`lumos doctor` 的 **Check H** —— 掃 git diff 裡碰 prod/外部 API/寄送/破壞性 DB 的 `+` 行,用 `warn_soft` 提示「這裡是不是漏標 ★IRREVERSIBLE★?」。把「判動作可不可逆全靠人想到」改成「機器提醒人想」。

源起:日報 2026-06-22 gap「若把判動作可不可逆自動化交 LLM 則判官無形式保證、必有誤判;維持人手標別自動化(lumos 現狀對),但補一條 doctor 對 diff 碰 prod/外部 API/寄送 主動提示漏標 ★IRREVERSIBLE★——漏標一個不可逆動作=靜默放行一次危險操作」。

## 定位
- **互補 Check R 而非取代**:Check R(`scripts/lumos:619-642`)只驗「有沒有標 ★IRREVERSIBLE★、標了回退/守衛是否合規」;Check H 反向提醒「沒標但 diff 看起來可能需要」。
- **摩擦地板,非合約守衛**:`warn_soft` 印出但不動 `issues`、不影響 rc。絕不 hard block(刻意設計:syntactic pattern 必有 false positive,軟提示成本接近零)。
- **僅 `--ci` 跑**:互動 `lumos doctor` 印「(僅 --ci 模式掃 diff;互動模式略過)」直接跳過,減噪。

## 關鍵機制
- **掃描範圍**:`git diff --staged` 優先,空則 fallback `git diff HEAD~1..HEAD`。傳 `cwd=str(env.vault)`(子目錄)無妨——git diff 無 pathspec 時範圍恆為整個 repo,cwd 僅影響 relative pathspec 解析。
- **7 條 hardcode pattern**(`IRREVERSIBLE_HINT_PATTERNS` @ `scripts/lumos:1027`):`prod[._\-/]|production` / `smtplib|sendmail|send_mail|.send_message` / `requests.post|httpx.post` / `boto3.(client|resource)` / `stripe.|twilio.|sendgrid.` / `DROP TABLE|DELETE FROM` / `external_api|ext_api`。`.delete()` 已移除(噪音過高);`DROP TABLE/DELETE FROM` 保留(SQL 層不可逆、特指性強)。
- **過濾**:只看 `+` 行;跳 `.md/.txt/.rst`(config 如 .yaml 保留);跳測試檔(`test_|_test.|.spec.|/tests?/`);跳純注解行(`# // -- /* *`)。`cur_file` 只在 `+++ b/` 更新(`/dev/null` 不更新)。
- **輸出**:命中 `hits[:8]`(截斷),`warn_soft` head =「diff 發現 N 行疑似碰外部不可逆操作」,advice 指引去確認對應 Systems 節點是否已標 `★IRREVERSIBLE★ [rollback:decisions]` / `[guard:decisions]`。

## 落點
- 常數 + helper `_scan_diff_for_irreversible_hints(cwd)`:`scripts/lumos:1027-1079`(可逆性軸群,`IRREVERSIBLE_RE` 附近)。
- Check H section:`scripts/lumos:690-704`(插在 Check S print() 與 Check K doc 註解之間)。

## 已知限制(誠實天花板)
- **pattern 是 syntactic 非 semantic**:`requests.post` 可能打 localhost mock、`DELETE FROM` 可能在 migration test → false positive 有,但軟提示成本近零。
- **CI fetch-depth=1 / 初始 commit 無 parent**:`HEAD~1..HEAD` rc≠0 → 靜默回 `[]`(安全失敗,Check H 失效)。fetch-depth=1 比初始 commit 更常見。
- **多 commit PR 只看最後一個 commit**。
- **`diff.noprefix=true`/`mnemonicPrefix=true`**:`cur_file` 解析失敗 → SKIP_EXT/TEST_PAT 過濾全失效(雜訊爆增而非安全降級)。v1 假設 git 標準 `+++ b/` 前綴。
- **不知對應哪個 Systems 節點**:提示通用,人仍要自查。

## 相關
- 設計稿:`docs/design/2026-06-25-doctor-irreversible-hint.md`(design-loop 5 輪收斂 + cross-audit;審計修正史在尾段)。
- 實作計畫:`docs/superpowers/plans/2026-06-25-doctor-irreversible-hint.md`。
- 實作 commit:`2482746`。
