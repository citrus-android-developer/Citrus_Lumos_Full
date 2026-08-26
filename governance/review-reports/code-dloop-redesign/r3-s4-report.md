# r3-s4 第三輪對抗審查報告

範圍:`/private/tmp/.../scratchpad/codeloop/code-dloop-redesign-r3-s4.patch`(HEAD→現行工作樹全量 diff),
對照真代碼 `/Users/enzo/harness/lumos-toolchain`。主鏡頭:測試品質(假綠八型對照+fixture 衛生);次鏡頭:本輪新增修法完整性/新引入 bug/相容回歸。

---

## Finding 1(HIGH):送審 diff 檔與現行工作樹不符——一個宣稱新增的測試分支實際不存在

**類別**: review-integrity / test-coverage(delivered-vs-claimed)

**引句**:「dsp_lock_dir: 唯讀目錄內快照仍可讀(quote-check 純讀不需寫權)」

diff 檔第 757-764 行(對應 hunk `@@ -12360,5 +12630,13 @@ def t_quote_check_nested_quotes_and_min_length():`)宣稱在
`t_quote_check_nested_quotes_and_min_length` 尾端追加一段「唯讀目錄內快照仍可讀」的 chmod 0o500 hygiene 測試:

```
+    locked = d / "locked"
+    locked.mkdir()
+    snap_l = locked / "ls.md"
+    snap_l.write_text(snap.read_text(encoding="utf-8"), encoding="utf-8")
+    locked.chmod(0o500)
+    r4 = run(v, "quote-check", str(ok_rpt), "--spec", str(snap_l))
+    check("唯讀目錄內快照純讀 rc0", r4.returncode == 0, f"rc={r4.returncode}")
```

**驗證**:實地比對——`git diff -U10 -- scripts/test_lumos.py`(現行工作樹真實 diff)與送審 patch 檔的
`scripts/test_lumos.py` 段落逐行 diff,發現**只有這一個 hunk** 對不上:現行工作樹裡完全沒有這段
（`grep -rn "唯讀目錄內快照\|dsp_lock_dir" .` 全庫零命中;`t_quote_check_nested_quotes_and_min_length`
在真檔案 `scripts/test_lumos.py:12313-12341` 只到「② 下限」那條 check 就結束,直接接
`def t_disposal_snapshot_provenance():`)。另外兩個變更檔(`scripts/lumos`、
`governance/eval/canary_calibration.py`)的真實 diff 與送審 patch **逐位元組相同**,確認差異只集中在
這一個 hunk,不是我環境問題。

**失敗場景**:若這份報告(或前幾輪的審查結論)被視為「chmod hygiene 已補測試」的證據往上呈報,
實際上此案例從未落地——「唯讀目錄快照可讀」這條路徑目前是**零測試覆蓋**。以這個專案自己的紀律
(架構圖/留痕誠實原則、「行為事實與宣稱衝突時不自動判宣稱為真」)來說,這正是「文件宣稱 vs 現場事實
分岔」的教科書案例,值得往上一級確認:是上一輪 reviewer 核可後被人手動回退、還是產生送審 patch 檔
時的擷取/同步失誤。

**附註(不算獨立 bug)**:純從程式邏輯看,`cmd_quote_check`/`_quote_rows` 本來就只做
`Path(spec).read_text()`(純讀,不寫目錄),所以就算這段測試真的補上,大概率會過——但那正是「沒有
這段測試就不知道」的意思,不能用「應該沒事」取代「有沒有測」。

---

## Finding 2(MEDIUM):round-less 記錄插在兩筆同 round-id 之間,會被 disposal 閘誤判為「帳次序損壞」

**類別**: correctness / new-regression(本輪新增分組邏輯與既有守衛的交互)

**引句**:「if rid_ in groups and next(reversed(groups)) != rid_:」(scripts/lumos,`_loop_status_disposal` 內,對應 diff 第 268 行)

`_loop_status_disposal` 本輪把 round-less 記錄改回「逐筆自成一輪」(`__seq{len(groups)}`),
同時沿用既有的 round-id 非連續重現守衛。這守衛只檢查「同一個 round-id 是否被『其他任何一組』隔開」,
但它不區分「隔開的那一組」是別的顯式 round,還是一筆單純的 round-less 記錄——round-less 進了
`groups` 就成了合法的「另一組」,足以觸發這條守衛。

**實測重現**(真跑 `scripts/lumos`,非臆測):

```
canary record --loop probe1 --round r1 --auditor s1 ...   # rc=0
canary record --loop probe1 --auditor s2 ...               # rc=0(round-less)
canary record --loop probe1 --round r1 --auditor s3 ...    # rc=0
loop status probe1 --disposal --spec ... --repo ...
```

輸出:
```
disposal rc= 2
ERROR: round-id 'r1' 非連續重現(被其他輪隔開;append-only 帳次序損壞)
```

三筆記錄本身完全合法(逐一 record 都 rc0),帳面也沒有真的「壞行」或「次序損壞」——只是中間夾了一筆
沒帶 `--round` 的記錄。但 disposal 閘直接回報「帳次序損壞」並 rc2,訊息語氣暗示帳面被破壞,實際上只是
分類方式把 round-less 記錄也算進「別的一輪」。這與程式碼自己的註解矛盾:

> 「round-less 逐筆自成一輪(r2 回歸修:併成單一 __legacy 組會讓較早 carrier 冒充最新判定/合法 legacy
> 第二筆假 rc2;守衛只管顯式 round-id)」

註解說「守衛只管顯式 round-id」,但實作上 round-less 分組**仍會被顯式 round-id 守衛採計進「是否被隔開」
的判斷**,兩者沒有真正解耦。

**失敗場景**:操作者對一個已經在跑 panel 模式(`--round r1/r2/...`)的 loop,某次不小心漏打 `--round`
(或刻意補一筆不掛 round 的旁註 canary),事後補回 `--round r1` 想接續原輪——結果 `--disposal` 永久
回報「帳次序損壞」,即使實際上沒有任何資料被竄改或錯序。修復手段不明確(帳面沒壞,不能靠「隔離壞行」
解決,說明文字裡建議的補救方式對不上真正病因)。

**建議方向(僅供參考,不代改)**:contiguity 檢查應該只在「兩個顯式 round-id 分組」之間比對相鄰性,
略過中間插入的 `__seq*` round-less 分組,而不是把 round-less 分組也當作「合法的鄰居/合法的隔斷者」。

**測試覆蓋缺口**:`t_disposal_gate_r1_panel_hardening`②只測了純顯式 round(r1,r2,r1)序列;
`t_disposal_gate_r2_panel_hardening`①只測了純 round-less 序列;兩者的**交叉場景(round-less 夾在
兩個同名顯式 round 之間)完全沒有測試覆蓋**,而這正是本輪新增「round-less 逐筆 __seq 分組」邏輯與
既有(r1 導入)round-id 守衛第一次產生交互的地方。

---

## Finding 3(LOW-MEDIUM):`t_calibration_readback_hardening` 直接讀寫真實生產路徑的累積帳,而非隔離的 tmp 檔

**類別**: test-fixture-hygiene(fixture 清理與衛生,符合本輪主鏡頭①)

**引句**:「log = repo_root / "governance" / "eval" / "calibration-log.jsonl"」

```python
src = Path(__file__).resolve().parent.parent / "governance" / "eval" / "canary_calibration.py"
repo_root = Path(__file__).resolve().parent.parent
log = repo_root / "governance" / "eval" / "calibration-log.jsonl"
had = log.exists()
orig = log.read_text(encoding="utf-8") if had else None
try:
    log.write_text((orig or "") + '{"half":', encoding="utf-8")
    ...
finally:
    if had:
        log.write_text(orig, encoding="utf-8")
    elif log.exists():
        log.unlink()
```

`canary_calibration.py` 的 `ROOT`/log 路徑是寫死的(`pathlib.Path(__file__).resolve().parents[2]`),
沒有環境變數或參數可以覆蓋輸出位置,而這支新測試又是用 `subprocess.run` 起真正的 CLI 進程(不是
in-process monkeypatch),所以唯一能測「讀回自驗」邏輯的方式就是直接對**真實的、repo 內
`governance/eval/calibration-log.jsonl`(即專案文件裡說明的「累積帳」)動手**:先塞一段半行破壞它,
跑腳本,再用 `finally` 整檔覆寫還原。

try/finally 確保「測試框架內部」的例外(check 失敗等)不會漏掉還原,這點沒問題。但這個檔案是**跨進程
共用的真實資源**——不是這支測試自己的私有 tempdir(對照 `mkvault()` 的 docstring 自己講的教訓:
「共用時代任兩個測試(或平行 agent)寫帳即互踩」,2026-07-26 才把 vault 相關帳檔全部改成各自私有
tempdir 以避免這類問題;這裡等於在同一個 PR 裡,對另一個檔案又重新踩進同一類坑)。

**具體失敗場景**:若測試套件執行期間,剛好有另一個進程也在寫這份累積帳(例如記憶庫記錄的「自主迭代
loop」每天 09:30 自動跑校準/設計流程,或有人手動跑一次真實 `canary_calibration.py` 累積校準訊號),
該次寫入會落在這支測試的 `write_text((orig or "")+'{"half":')` 與 `finally` 的
`log.write_text(orig, ...)` 之間——`finally` 用整檔覆寫方式還原,會把外部那次寫入**整筆蓋掉遺失**,
而不是善意地「只清掉自己加的部分」。目前 repo 內該檔案尚未存在(`git ls-files` 查無),所以眼下風險是
理論性的,但這份檔案的定位就是「累積帳」,一旦開始被生產流程使用,這支測試就會變成該帳本的潛在數據
遺失來源。

---

## 其餘掃過、未列入 finding 的觀察(供參考,不構成具體可證偽場景,不計入計數)

- `_loop_status_disposal` 的「全帳域壞行檢查」(`n_badlines`)不分 loop_id、對整份 `.canary-log.jsonl`
  生效,任何一個其他 loop 的壞行都會讓本 loop 的 `--disposal` 也 rc2。這是刻意沿用 `--settle` 既有
  precedent(docstring 自己承認:「全帳域檢查=共用帳完整性,同 settle 前例」),非本輪新引入,不算新洞。
- `cmd_loop_status` 的 `--disposal` 分支在混用守衛(`if not panel and n_round > 0`)之前就 `return`,
  導致 disposal 模式完全繞過該守衛——這是既有(diff 前)行為,本輪未改動這段順序,只是與 Finding 2
  共同造成 round-less/round 混用可以一路走到 disposal 內部的新 contiguity 檢查,已在 Finding 2 說明。
- `_vault_repo_root`/寫讀兩側路徑正規化、`_prov_path` 解析、`_quote_rows` 巢狀『』修法、
  `_QUOTE_MIN_NORM_LEN` 下限、canary_calibration.py 的補換行+run_id 全檔掃描邏輯——逐行覆核後邏輯自洽,
  且均有對應的機械 repro 測試(t_disposal_gate_r1/r2_panel_hardening、t_calibration_readback_hardening)
  直接翻紅驗證,測試鑑別力足夠(★前置★ 現場成立斷言 + 修法還原會翻紅的敘述均對得上實作),未發現額外
  correctness 問題。

---

## 總結

- Findings 數:**3**
- Max severity:**HIGH**(Finding 1,診斷理由:送審物件與現行程式碼不符,影響整個審查鏈的可信度)
