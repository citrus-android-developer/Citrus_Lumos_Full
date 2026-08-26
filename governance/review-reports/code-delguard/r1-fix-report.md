# code-loop r1 修復波報告（delguard）

- 分支：`feat/delguard`
- 範圍：`scripts/lumos` delguard 區（`_delguard_*` / `cmd_delguard_check`）、`scripts/hooks/pre-commit` Gate DG、`scripts/test_lumos.py`（`t_delguard` / `t_precommit_whitelist_drift_guard`）、架構圖兩節點
- 目標測試：`t_delguard` + `t_precommit_whitelist_drift_guard` → **102 PASS / 0 FAIL**
- 鄰接迴歸抽驗：`t_hooks_python_fallback` / `t_precommit_vendored_exempt` / `t_hook_cmd_home_resolved` / `t_hook_copy_list_completeness` / `t_cochange` → 39 PASS / 0 FAIL
- 全量套件由控制器跑（本波未跑）

## 翻紅驗證（新斷言不是恆真裝飾）

方法：逐條把修復回退成缺陷版、跑目標測試、看有沒有翻紅，跑完立刻還原（腳本：scratchpad `redcheck.py`）。

| 項 | 回退成 | 結果 |
|---|---|---|
| A 排除域路徑段 | `seg in c` 子字串比對 | ✗ `排除域路徑段:src/robin/ 不被 bin/ 誤殺`（tokens=[]） |
| B confidence 內容域 | 對整行 `path:lineno:content` 配 token | ✗ `檔名撞名不誤降級`（Login 判成 low） |
| C 回收表 per-file | 全 diff 共用 added（含 .md）※需同時回退收集面與查表面才重現原缺陷 | ✗ `別檔 + 行不滅聲`（tokens=[]） |
| D diff 前綴固定 | 拿掉 `-c diff.noprefix=false …` | ✗ ×2（`diff.noprefix=true` 下 tokens=0） |
| E vault-only 靜默 | 拿掉 `gr_rel == "."` 早退 | ✗ `standalone vault repo rc0 且靜默`（吐出誤報警告） |
| F env float 防炸 | except 改抓不到 ValueError | ✗ CRASH rc=1（traceback） |
| G 非 UTF-8 replace | 拿掉 `errors="replace"` | ✗ ×2（整支降級 degraded=true、正常檔 token 全漏） |
| N S2 重排判動內容 | 短路成不判 | ✗ `重縮排同內容=False` |
| O② 檔頭判定 | `startswith(("---","+++"))` | ✗ `SQL -- 註解型被刪行照抽`（legacyAuditTrigger 被吃） |
| J top-10 截斷 | 不截斷 | ✗ `逐條列出剛好截到 top-10`（印 12 行） |
| M Gate DG `-f` | 拿掉 `-f` | ✗ `Gate DG 條件含 -f scripts/lumos` |
| L 漂移斷言 | pre-commit lock 行改 `*yarnx.lock` | ✗ `lockfile yarn.lock 見於 pre-commit lock 排除行` |
| H 巨檔 deadline 粒度 | — | 依 brief 免測（設計級），無斷言，回退不翻紅（預期） |

## 逐項修法

**A（major）排除域子字串誤殺**：`_delguard_parse_diff` 的排除判定改路徑段比對
`any(c.startswith(seg) or ("/" + seg) in c for seg in _DELGUARD_EXCLUDE_DIRS)`。
測試：`src/robin/Handler.kt` 的刪除**要**抽到；`node_modules/x/a.js`、`app/node_modules/y.js`、`app/bin/z.kt` 不抽。

**B（major）confidence 檔名撞名誤降級**：git grep 輸出行先 `split(":", 2)`，`len<3` 直接丟（順帶吃掉 `Binary file … matches` 這類無內容行），只對 `parts[2]` 配 token。
測試（新 fixture repo）：index 有 `app/Login.kt`（內容無字面 `Login`，但有一行命中 `helperStillUsed` 而讓該路徑出現在 grep 輸出裡）→ `Login` 判 high、`helperStillUsed` 判 low。

**C（major）回收表跨檔滅聲**：`added` 改 per-file dict。第一遍沿 `diff --git` 切檔收 `+` 行 token，vault／`.md`／排除檔不收；第二遍剔除判定改「token 在**同檔** added set 才回收」。
測試①：`app/Risk.kt` 刪 `computeUserRiskScore` ＋ `CHANGELOG.md` 加一行提及它 → token 仍在。②既有同檔 `keep` 回收案例照舊綠。

**D（major）diff 前綴設定打破解析**：`cmd_delguard_check` 的 git diff 加 `-c diff.noprefix=false -c diff.mnemonicPrefix=false`（緊接既有 `-c core.quotePath=off`）。
測試：fixture repo `git config diff.noprefix true` 後跑 CLI → tokens 照抽且照命中 vault。

**E（major）standalone vault repo 全壞**：`gr_rel` 算出後若 == `"."` → 直接 `return 0`（vault-only repo 無 code 側，靜默）。順手把下游第二次 `os.path.relpath` 改用同一個 `gr_rel`（原本算兩次）。
測試：MOC/Systems 型 vault-root repo，staged 改 `.md` → rc0 且 stdout 全空；`--json` 也不炸。fixture 的節點內文刻意帶 ASCII 識別字——不帶的話缺陷版也抽不到 token，測試會恆綠（第一版寫錯，紅測時抓到並修）。

**F（minor）env float 破 rc0**：`deadline = float(...)` 包 `try/except (ValueError, TypeError)` → fallback 2.0。
測試：`LUMOS_DELGUARD_DEADLINE=abc` → rc0 且 `degraded=false`（行為如常，不是靠降級兜）。

**G（minor）非 UTF-8 staged 檔炸整支**：git diff 的 `subprocess.run` 加 `errors="replace"`。
測試：staged 一個 big5 bytes 的 `.kt`（`write_bytes`）＋另一 code 檔正常刪除 → 正常檔 token 照抽、不降級。

**H（minor）單巨檔 deadline 超支**：`_delguard_vault_scan` 檔內逐行迴圈每 2000 行呼叫一次 `deadline_check`，回 True 就排序並回傳現有 hits。依 brief 免測（設計級）。

**I（minor）fixture 洩漏**：`t_delguard` 收尾 `shutil.rmtree(..., ignore_errors=True)` 清全部 fixture repo（原 3 個＋本波新增 8 個）。實測：跑一輪前後 `$TMPDIR/gctl-delg-*` 數量差 0。

**J（major）top-10 測試無鑑別力**：`_mk_delguard_capflood_repo` 的 vault 改成 12 個節點各提及 `capTok0`（12 > `DELGUARD_TOP_N`）；加前置斷言 `len(hits) > DELGUARD_TOP_N`，再斷言文字模式逐條行數 `== DELGUARD_TOP_N`、統計行含 `另有 2 處命中`（rest>0）。

**K（minor）benchmark 現場成立**：confidence 計時改對**真 repo** staged index 跑（`Path(GRAPHCTL).parent.parent`，40 個 `zzNoSuchTok`）＋vault 掃真 vault，合計仍 <1s。

**L（minor）漂移守衛恆真斷言**：刪掉「lockfile 名見於 scripts/lumos 源碼」那條（值本來就讀自該檔，恆真）。只留跨檔斷言：三個 lockfile 名都要出現在 pre-commit 抽出的**那一行** lock 排除規則裡。

**M（minor）Gate DG 補 `-f`**：條件改 `[[ -n "${CC_PY:-}" && -f "$REPO_ROOT/scripts/lumos" ]]`；`t_delguard` 加一條斷言釘 Gate DG 段落含 `-f "$REPO_ROOT/scripts/lumos"`（既有掛載斷言不受影響，無需改字樣）。

**N（major, spec C5）S2 縮排重排誤判純連結**：`_delguard_purelink` 加判——某 `-` 與某 `+` 變更行 strip 後內容相同（僅空白差異＝重排／搬行）→ `return False`。
測試：同一連結行重縮排（`-  - "[[V/x]]"` / `+    - "[[V/x]]"`）→ False。

**O（spec 縮水補測）**：`t_delguard` 補 7 項＋一處真碼修正
- ① binary diff 段跳過（`Binary files a/x and b/x differ`）：後續檔照抽、binary 段本身不抽。
- ② 檔頭判定收緊成新 helper `_delguard_is_diff_header`：僅 `--- a/`、`--- /dev/null`、`+++ b/`、`+++ /dev/null` 算檔頭。**這修掉一個真 bug（s5 F6）**：被刪的 SQL/Lua `--` 註解行在 diff 裡長成 `--- x`，舊判定當成檔頭整行吃掉。測試釘 `legacyAuditTrigger` 要抽到、`schema`/`sql`（真檔頭）不得抽。
- ③ initial commit（無 HEAD、只 staged）→ CLI rc0 不炸。
- ④ CJK 路徑／檔名 fixture（`app/登入模組/登入.kt`）→ 照抽照命中。
- ⑤ 純 rename（`git mv` 後未 commit）→ `tokens == 0`。
- ⑥ metachar token 直餵 `_delguard_vault_scan(["a.b{c", "x)y"], {}, …)` 不炸。
- ⑦ S2 negative：純連結∧無 S1 命中 → `fake_sync == []`。

**P（誠實性）**：`Verification/2026-08-11_delguard落地` 把「43 條斷言」「2463 passed」等數字快照改寫成機制式宣稱（全數綠＋全量 0 failed，以 push 前控制器實測留痕為準；明寫「本節點不做數字快照」與病根）；`revalidate_when` 追加「delguard 測試斷言結構變動」。lint 0 問題。

**Q（留痕）**：spec 節點審計修正紀錄節 append code-loop r1 一行（15 條摘要）。lint 0 問題。

## 接受不補（明文）

- **partial-hunk stage（`git add -p` 只 stage 一部分 hunk）**：不補測試。理由：fixture 成本高（要腳本化互動式 `add -p` 或手搓 index blob），而「delguard 讀的是 staged index、不是 worktree」這條契約已由既有 worktree 案釘住（`delguard 快照=index 不被 worktree 救回`）——partial-hunk 只是同一契約的另一個輸入形狀，沒有新的機制面向。若未來 staged 快照來源改動（例如改讀 worktree 或加 `--no-index`），該契約測試會先翻紅。

## 修不動／有疑義

- `revalidate_when` 不在 `lumos append` 的 `LIST_KEYS` 白名單（也不在 `set` 的 `SCALAR_KEYS`），CLI 拒寫。改以 Edit 直接加一行 YAML list 項（一項一行，符合鐵則 2），`lumos lint` 0 問題。若這個鍵應該進 append 白名單，是另案。

## code-loop r2 追加接受（不改碼）

- **S2 重排判定的副作用方向（N6）**：`_delguard_purelink` 的重排判定（N：某 `-` 與某 `+` strip 後同內容→判「有動內容」）本意是防「純掛連結」誤報，但代價是「重排＋補連結」這個複合形狀——節點本次 diff 既重排了既有內容又補了一條 `verified_by` 連結——會因為「有動內容」而被排除出 S2 純連結判定，連帶漏掉假同步嫌疑標記（本該報而沒報）。這是 r1 N 修復本就選定的取捨方向的自然延伸，不是新缺陷,故不改碼。副作用方向已登記：換來的是**漏報（miss）**而非誤報（false positive）——advisory 層級下漏報比誤報溫和（不會訓練人無視警訊），可受。
