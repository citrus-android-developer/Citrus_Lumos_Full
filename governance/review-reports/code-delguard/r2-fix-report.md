# code-loop r2 修復波報告（delguard）

- 分支：`feat/delguard`
- 範圍：`scripts/lumos` delguard 區（`_delguard_parse_diff` / `cmd_delguard_check`）、`scripts/test_lumos.py`（`t_delguard`）、架構圖兩節點（`Projects/code側刪除傳播守衛_計劃`、`Verification/2026-08-11_delguard落地`）
- 目標測試：`t_delguard` + `t_precommit_whitelist_drift_guard` → **111 PASS / 0 FAIL**（較 r1 的 102 淨增 9：N1×2、N3②×3、N4×3、N5×1）
- 鄰接迴歸抽驗：`t_hooks_python_fallback` / `t_precommit_vendored_exempt` / `t_hook_cmd_home_resolved` / `t_hook_copy_list_completeness` / `t_cochange` → 39 PASS / 0 FAIL
- 全量套件由控制器跑（本波未跑，沿用 r1 慣例）

## 翻紅驗證（新斷言不是恆真裝飾）

方法：逐條把修復回退成缺陷版、跑 `t_delguard`、看有沒有翻紅，跑完立刻還原。

| 項 | 回退成 | 結果 |
|---|---|---|
| N1 vault 路徑邊界 | `vault = c.startswith(graph_root) and c.endswith(".md")`（無邊界） | ✗ `手足目錄 docs/kg-legacy 不進 vault_diffs`（誤把手足目錄內容收進 vault_diffs） |
| N2 rename -M | 拿掉 `git diff` 的 `-M`（fixture 已 `git config diff.renames false`） | ✗ `純 rename tokens=0(-M 認得搬檔)`（tokens=1，rename 被誤判成刪除） |
| N3① git diff rc 守門 | 拿掉 `r.returncode != 0` 的 raise | ✗ ×2（`--json degraded=True`→實際 `{"tokens":0,...,"degraded":false}`；文字模式「內部錯誤」缺席——證實舊碼會把失敗偽裝成「掃描乾淨」） |
| N4 capflood or 語意 | `if rest or dropped` 改 `if rest and dropped` | ✗ `capflood 單節點版:rest=0∧dropped>0 統計行仍印`（rest=0 時 and 短路,統計行消失） |
| N5 per-file .md 對稱 | 第二遍 `continue` 條件拿掉 `or cur.endswith(".md")` | ✗ `非 vault .md 重排 diff:tokens=[]`（README.md 重排把 alphaLine/betaLine/gammaLine/deltaLine 當 token 抽出） |

## 逐項修法

**N1（major）vault 前綴無路徑邊界**：`_delguard_parse_diff._flags` 的 `vault` 判定改
`(c == graph_root or c.startswith(graph_root + "/")) and c.endswith(".md")`，堵住 `graph_root="docs/kg"` 誤配手足目錄 `docs/kg-legacy/notes.md`（字首相同、不同目錄）的路徑邊界漏洞。
測試：`docs/kg-legacy/notes.md` 刪除行不得進 `vault_diffs`；同一 diff 內另一個真 code 檔（`app/Real.kt`）的 token 正常抽到、不受牽連。
**測試設計偏離說明**：finding 原文寫「token 要抽到」指 notes.md 自身的刪除行，但 notes.md 同時是非 vault 的 `.md`——N5 修復後**所有**非 vault `.md`（含此手足目錄檔）在第二遍一律不產 token，兩條修復在此處必然疊加，notes.md 自身的字面不可能再被抽成 token（已用 monkeypatch 交叉驗證：N1 revert／N5 present 時 tokens 恆空，並非有效鑑別點）。故 N1 的鑑別力改落在 `vault_diffs` 路由這一項唯一會隨 N1 翻轉的觀察量，另補一個真 code 檔佐證流水線其餘部分不受牽連——不是漏做，是原斷言在雙修復疊加下不成立，已收斂到可翻紅的等價命題。

**N2（major）rename fixture 測不到 -M**：`_mk_delguard_repo` 系列的 rename fixture（`gctl-delg-rename-`）建 repo 後加一行 `git config diff.renames false`，讓「唯一撐著 rename 偵測」的只剩 CLI 自己下的 `-M`——若環境的全域 `~/.gitconfig` 開著 `diff.renames=true`，舊 fixture 拿掉 `-M` 也不會翻紅（本機 `git config --global diff.renames` 未設，恰好僥倖過關，其他機器未必）。

**N3①（major）git diff rc≠0 production 靜默失敗**：`cmd_delguard_check` 的 `git diff --cached` 呼叫後補 `if r.returncode != 0: raise RuntimeError(...)`——原本失敗時 `r.stdout` 恆空，會被 `_delguard_parse_diff` 解析成「tokens=0」，長得像「掃描乾淨」的成功結果，實為沒掃到東西的失敗。丟給既有 `except Exception` 落成 `degraded=true`／「內部錯誤」，不再偽裝成功。
**N3②（major）新測試**：造一個有 vault 佈局（`docs/kg-knowledge/Systems`）但**無 `.git`** 的目錄，帶 `--repo /nonexistent-zzz --json` 跑 CLI——`_cochange_repo_root` 對不存在的 `--repo` 靜默退回 `os.getcwd()`，該 cwd 本身沒有 `.git`，`git diff --cached` 因而真的失敗，觸發 N3① 的新守門。斷言 `--json` 模式 `degraded=True`、文字模式含「內部錯誤」。
**N3③（minor）initial-commit 斷言誠實化**：`delguard initial commit(無 HEAD)rc0 不炸` 改名為 `...rc0 不炸(僅煙霧;initial commit 無先前內容可刪)`——該案例本質上抽不到任何被刪 token（沒有 HEAD 就沒有「先前內容」可比對刪除），舊名稱容易讓人誤以為它驗證了某種業務邏輯，實際只是煙霧測試。

**N4（major）capflood 弄丟 rest=0∧dropped>0 案例**：新增 `_mk_delguard_capflood_repo_single`（45 個被刪符號超 cap、僅 1 個節點命中 `capTok0`）與既有 12 節點版並存。舊 fixture 恆 `rest>0 ∧ dropped>0`，對 `if rest or dropped` 與誤植的 `if rest and dropped` 皆為真、無鑑別力；新 fixture 前置斷言 `rest==0` 後，斷言統計行 `另有 0 處命中/5 個符號超 cap 未展開` 仍要印出，專釘 `or` 語意。

**N5（minor）per-file 回收表 .md 不對稱**：`_delguard_parse_diff` 第二遍的 `continue` 條件由 `is_vault or is_excl` 補成 `is_vault or is_excl or cur.endswith(".md")`，與第一遍（`added` 回收表collection,本就無條件跳過所有 `.md`）對齊——非 vault 的 `.md`（README.md 等）不是 code，重排/縮排這類散文層級的差異不該被當成「符號被刪」抽出 token。測試：README.md 兩行對調（`alphaLine betaLine` / `gammaLine deltaLine` 互換順序）→ `tokens == []`。

## 架構圖節點

- **N7**：`Projects/code側刪除傳播守衛_計劃` 的「code-loop r1」折入行，把重複列的「SQL 註解型 `--` 被刪行修抽取」（該項已含在同一行的「縮水測試補 7 項」內，即 r1 fix report 的 O②）換成漏列的 I 項「fixture 洩漏 rmtree 收尾」，折入條目仍為 15 條、無重複、無遺漏。lint 0 問題。
- **N8**：`Verification/2026-08-11_delguard落地` 的「全量套件」行改為「本節點只認 `t_delguard` 實跑結果；全量套件結果以 push 前控制器實測留痕為準（控制器 2026-08-11 實測 2506/0@701bf18，後續以最新留痕為準）」——避免節點自行宣稱全量結果早於控制器實測（r1 已修過兩次數字快照過期，這次改成不讓 Verification 節點越權代答全量）。lint 0 問題。

## 接受不改碼（N6）

- **S2 重排判定的「重排＋補連結→漏報假同步標記」**：`_delguard_purelink` 的重排判定（r1 N 修復）本意是防「純掛連結」誤報，代價是「重排＋補連結」複合形狀（節點本次 diff 既重排既有內容又補一條 `verified_by` 連結）會因判「有動內容」而漏掉假同步標記——這是 r1 N 已知取捨方向的自然延伸，不是新缺陷。已在 `r1-fix-report.md` 尾端補一段接受理由：副作用方向是漏報（miss）而非誤報（false positive），advisory 層級下漏報比誤報溫和，可受。

## 修不動／有疑義

- 無。全部 8 條 finding（N1–N8）均已照單處理；N1 的測試設計與 finding 原文字面有一處偏離（見上「測試設計偏離說明」），已用交叉驗證證明是必然結果、非疏漏。
