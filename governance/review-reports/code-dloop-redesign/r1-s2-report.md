# Code Review 報告：design-loop 重設計 T1-T7（r1-s2）

審查對象：`/private/tmp/claude-501/.../scratchpad/codeloop/code-dloop-redesign-r1-s2.patch`(已逐 hunk 讀完整份 diff)。repo 內 `72c30a4..HEAD` 絕大部分內容與此 diff 逐字相符(已用於印證/重現,見 Finding 1);唯 Finding 2 所在 hunk 經核對後**與 repo 現況、乃至整個 git 歷史都對不上**,細節見該條。

---

## Finding 1 — MAJOR：T6「留痕轉強制」定錨檢查在帳面出現任一壞行時會靜默失效（fail-open，非 fail-closed）

- **file:line**：`scripts/lumos:2827-2834`（`cmd_canary` 內 T6 定錨區塊）
- **引句**：「`except (OSError, ValueError):\n            _anchored = False   # 帳面壞行由既有讀側守衛處理,寫側不因此誤擋`」

### 失敗場景

T6 的設計承諾是：某 loop 一旦被任何一筆 `--findings-set` 記錄「定錨」為 disposal loop，之後**每一筆** `canary record` 都必須帶 `--report`/`--snapshot`，否則 rc2（寫側擋）。但判斷「有沒有定錨」的程式碼是：

```python
try:
    _anchored = any(
        _json6.loads(_l).get("loop") == loop and "findings_set" in _json6.loads(_l)
        for _l in path.read_text(encoding="utf-8").splitlines() if _l.strip())
except (OSError, ValueError):
    _anchored = False   # 帳面壞行由既有讀側守衛處理,寫側不因此誤擋
```

這段把**整個掃描過程**包在一個 `try/except`裡：只要 `.canary-log.jsonl`（跨 loop 共用的同一個檔）裡**任何一行**（不必是這個 loop 的行、也不必在這個 loop 的記錄之後）JSON 解析失敗，`any()` 生成器就會在讀到那一行時整個中斷、拋出 `ValueError`，被外層 `except` 接住，直接判定 `_anchored = False`——也就是「當作沒定錨」，於是放行一筆**沒有 report/snapshot** 的紀錄,且印出成功訊息 `✓ canary caught 留痕:...`,呼叫端完全看不出留痕要求被繞過了。

已用真的 `scripts/lumos` 二進位重現（非臆測）：

```
$ python3 scripts/lumos --vault $V canary record caught --loop t6bug --auditor s1 --severity minor \
    --findings-set a --folded-set a --report report.md --snapshot snap.md
✓ canary caught 留痕: ...   # 定錨成功

$ python3 scripts/lumos --vault $V canary record caught --loop t6bug --auditor s2 --severity minor
ERROR: loop 't6bug' 已定錨為 disposal loop(帳面有 findings_set 記錄)——後續 record 必帶 --report 與 --snapshot(留痕強制;T6)
rc=2   # 正確擋下

# 在帳面最前面插入一行壞 JSON(模擬中途被殺掉的寫入 / 磁碟滿 / 併發寫入半行)
$ (echo '{"bad json line no closing brace' ; cat .canary-log.jsonl) > tmp && mv tmp .canary-log.jsonl

$ python3 scripts/lumos --vault $V canary record caught --loop t6bug --auditor s3 --severity minor
✓ canary caught 留痕: CANARY-d6d692a5 (auditor=s3) → .../.canary-log.jsonl
rc=0   # BUG:定錨形同虛設,這筆完全沒有 report/snapshot 卻放行了
```

寫入結果：`{"ts": "...", "kind": "caught", "auditor": "s3", ..., "loop": "t6bug", "severity": "minor"}`——確實少了 `report_path`/`report_sha256`/`snapshot_path`/`snapshot_sha256`。

### 為什麼是真隱患

1. **與同檔既有寫法不一致、且更弱**：同一支檔案裡 `_jsonl_append_verified`（scripts/lumos:2847-2872,pre-existing）處理帳面壞行的方式是**逐行** `try: json.loads(line) except ValueError: continue`——單行壞掉只跳過那一行,不影響其他行的判讀。T6 這段反而把整個 `any()` 掃描包在**一個外層** try/except,壞行位置在被掃到的那一刻就讓後面所有行(含真正要找的定錨行)全部判不到,行為退化成「一行壞→整檔失憶」。
2. **觸發門檻低且非惡意也會發生**:`.canary-log.jsonl` 是多 session/多 loop 共用、單純 append、無鎖的檔案(`_jsonl_append_verified` 用獨立 `open(path,"a")`)。行程被中斷於 `write()` 途中、磁碟滿、或未來若有並發 record 呼叫,都可能在檔案裡留下不完整的一行——只要那一行**排在**這個 loop 的定錨行之前(檔案是 append 序,舊事故/壞行通常在前面),T6 的強制留痕從那一刻起對這個 loop 永久失效,且**沒有任何錯誤訊息**,呼叫端拿到的是成功訊息。
3. 這正好牴觸 CLAUDE.md 與這份 diff 自己反覆強調的「讀側 fail-closed」原則——T4 的四條合取閘特意做到「帳面壞行/竄改必 FAIL」,但 T6 的寫側定錨判斷卻是相反方向的 fail-open。T6 存在的唯一目的就是保證「定錨後留痕不可跳過」,這個保證被自己的例外處理繞過了。

### 建議

`except` 只該吞掉「這個 loop 找不到定錨證據」,不該吞掉「掃描因為別行壞掉而提早中止」。改成逐行 try/except(比照 `_jsonl_append_verified` 的寫法),壞行跳過而非整體判 False;或至少把判斷限定在「已讀到 EOF 且沒找到」才等於「未定錨」,遇到解析例外應該 fail-closed(retained as 已定錨/擋下)而非 fail-open(放行)。

---

## Finding 2 — MAJOR：`_disposal_export` 這個 hunk 機械核對不自洽(patch 損壞),且其內容(手動 open/close、無 with)、無任何呼叫點,不應這樣併入

- **對應 diff 位置**:patch 檔第 750-761 行(`diff --git a/scripts/lumos` 區塊內、`cmd_loop_compress` 與 `cmd_loop_verify_progress` 之間的新增函式)
- **引句**:「`out = open(out_path, "w", encoding="utf-8")`」(後面接 `out.write(...)` 與手動 `out.close()`,中間無 try/finally)

### 內容(diff 裡逐字如下)

```python
def _disposal_export(log_path, out_path):
    """dsp_export_v1:匯出 disposal 判定輪摘要供離線校準吃(觀測,不進 gate)。"""
    import json
    with open(log_path, encoding="utf-8") as fh:
        rows = [json.loads(l) for l in fh.read().splitlines() if l.strip()]
    carriers = [r for r in rows if "findings_set" in r]
    out = open(out_path, "w", encoding="utf-8")
    out.write(json.dumps({"carriers": len(carriers),
                          "loops": sorted({r.get("loop") or "" for r in carriers})},
                         ensure_ascii=False) + "\n")
    out.close()
    return 0
```

讀端(`log_path`)正確用 `with`;寫端(`out_path`)手動 open/close,萬一 `out.write(...)` 中途拋例外(例如寫入途中磁碟滿導致 `OSError`),`out.close()` 不會被執行,handle 洩漏——單看這段程式碼本身就違反本審查主鏡頭「資源 handle 要 with/確定 close」。

### 進一步核對:這個 hunk 有機械層面的異常,不只是風格問題

1. **這個 hunk 的行數頭跟本體對不上**:標頭寫 `@@ -3264,8 +3338,18 @@`(宣稱舊檔 8 行、新檔 18 行),但實際逐行數過本體是舊檔 **7** 行、新檔 **21** 行——`git apply --check` 對整份 patch 直接回報 `error: corrupt patch at line 766`(766 正好落在這個 hunk 內)。我用腳本逐一核對這份 diff 對 `scripts/lumos` 的**全部 11 個 hunk**,只有這一個算不出來,其餘 10 個 header/本體行數完全吻合(見下方核對記錄)。
2. **`git log --all -S "_disposal_export"` 與 `-S "dsp_export_v1"` 在整個 repo 歷史(含所有分支)都是零命中**——這個函式從未出現在任何一次真正的 commit 裡。對照之下,同一份 diff 裡其他新增符號(`_quote_norm`/`_quote_rows`/`_loop_status_disposal`/`cmd_quote_check`/T1 六個新參數……)都能在目前 repo(`scripts/lumos` 現況,`ba3ae1f`/`f9aec4b`)裡逐字找到,行為也用真的二進位重現過(見 Finding 1)。**只有這個函式是例外:它既不在現在的檔案裡,也不在任何歷史 commit 裡,而且在同一份 diff 的 argparse 區塊(`main()` 那幾個 hunk)裡也完全沒有被接上任何子命令、沒有被任何測試呼叫、沒有被任何架構圖/skill 文件提到**——即使照這份 diff 原樣套用,它也是個進不了任何入口的孤兒函式。

核對記錄(對 `scripts/lumos` 段每個 `@@` 逐行數,OK=標頭與本體一致):
```
OK       line 625  @@ -2677,21 +2677,21 @@ ...
OK       line 648  @@ -2754,21 +2754,95 @@ ...              ← Finding 1 所在 hunk,核對一致
MISMATCH line 744  @@ -3264,8 +3338,18 @@ ...   counted old=7 new=21   ← _disposal_export 所在 hunk
OK       line 766  @@ -3440,35 +3514,44 @@ ...
OK       line 812  @@ -3505,20 +3588,22 @@ ...
OK       line 835  @@ -3786,20 +3871,30 @@ ...
OK       line 866  @@ -7971,20 +8066,179 @@ ...
OK       line 1046 @@ -11702,26 +11956,37 @@ ...
OK       line 1084 @@ -11994,20 +12259,25 @@ ...
OK       line 1110 @@ -12102,20 +12372,22 @@ ...
OK       line 1133 @@ -12202,28 +12474,30 @@ ...
```

### 判定

這不是「風格瑕疵」等級的 minor:這段 hunk 本身**機械上不成立**(算不出自洽的行數、`git apply` 判它損壞)、內容**在真實 repo 歷史裡完全查無此函式**、而且即使當作合法程式碼看待,它也帶著本審查主鏡頭明確要抓的「無 with/無 try-finally」資源缺口。三者疊加,判定為 **major**:建議這個 hunk 不該照現狀併入——要嘛是投稿時的手動拼接/貼上造成的 patch 損壞(該重新產生這段 diff 再審一次),要嘛就是不該存在、該整段砍掉的孤兒函式(若要保留,至少要接上一個真正的呼叫點、補 `with open(out_path,"w",...) as out:`、並補測試)。

---

## Manifest 命中判定(governance/eval/canary_calibration.py:81)

**提問**:「檔案 handle 有沒有 with/確定 close?」

**判定:誤報(false positive)。**

實際第 81 行:
```python
81	        with log.open("a", encoding="utf-8") as f:
82	            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
```
`log.open("a", ...)` 是用 `with` 語句開的,離開 block 保證 close,沒有殘檔/未關閉風險。檔案內其餘所有讀取(`pathlib.Path(a.plants).read_text(...)`、`rp.read_text(...)`)也都是 `pathlib` 的一次性讀取 API,內部自行管理 handle,沒有裸 `open()` 忘記 close 的情形。本檔在 lens 1(資源/例外路徑)上唯一有問題的其實是 **Finding 2** 那個在 `scripts/lumos` 裡的 `_disposal_export`,不是 `canary_calibration.py`。

---

## 總結

- Finding 1(major):`scripts/lumos:2827-2834`(對照現行 repo 行號;diff 內第 648 行 hunk),T6 定錨檢查對帳面壞行 fail-open,真實可重現(附完整重現指令與輸出),靜默繞過「留痕強制」核心承諾。
- Finding 2(major):diff 第 750-761 行的 `_disposal_export` hunk——header/本體行數對不上(全份 diff 對 scripts/lumos 的 11 個 hunk 中唯一一個)、`git apply --check` 判損壞、函式在整個 repo git 歷史裡查無、diff 內也沒接上任何呼叫點,且內容本身無 with/try-finally。建議這段 hunk 重新產生或整段移除,不要照現狀併入。
- Manifest(canary_calibration.py:81):誤報,已用 `with log.open("a", ...) as f:`,無隱患;該檔其餘讀取皆走 `pathlib` 一次性 API,無裸 open 忘關閉的情形。

**Max severity: major**
