---
type: verification
status: pass
date: 2026-07-31
valid_under:
  - "安裝器只做①全域 lumos 指令 ②實體複製 skills/lumos-project-notes 到 ~/.claude/skills/;交付包結構固定為 <pkg>/scripts/lumos + <pkg>/skills/lumos-project-notes/"
  - "呼叫方式含直接執行/路徑含空白/symlink 呼叫(含相對路徑多層鏈)三種,由 slim/install.sh 開頭的手捲 symlink 解析迴圈涵蓋"
revalidate_when:
  - "交付包目錄結構改變(scripts/lumos 或 skills/lumos-project-notes 路徑搬動)→ 重跑 t_slim_install_no_project_touch 確認仍找得到來源"
  - "完整版 install.sh 的碰撞語意/_sync_global_claude 有變動 → 重查 slim/install.sh 是否又意外繼承了不該給的 hooks 安裝行為"
tags:
  - type/verification
  - status/pass
summary: |-
  TEST:t_slim_install_no_project_touch 8 checks 全綠(`python3 scripts/test_lumos.py -k slim_install`);全套回歸見報告
  VERIFY:[[Projects/公開精簡版_實作計畫]] Task 3 落地;spec [S4-c] 的 symlink 邊界(未經審計、必須實測)已實測,結論見 [[Projects/公開精簡版_計劃]] [S4-c]
  KEY:symlink 呼叫邊界原生寫法會壞,已改用手捲 symlink 解析迴圈修正(選項(a)),細節見 [[Systems/slim-install-安裝器]]
---
# 2026-07-31_slim-install安裝器落地

驗證對象:[[Projects/公開精簡版_實作計畫]] Task 3 —— 機器層安裝器(`slim/install.sh`)。反誤傷測試 `t_slim_install_no_project_touch` 是本 Task 最重要的產出,證明安裝器跑完後專案 worktree porcelain 為空、`.git/config` 前後相同,且對既有機器層資產(碰撞)無備份不覆寫。

## 測試結果(slim_install)

```
$ python3 scripts/test_lumos.py -k slim_install
lumos 測試(1 案例)
  ✓ 安裝器 rc0
  ✓ ★專案 worktree porcelain 為空★
  ✓ ★專案 .git/config 前後相同★
  ✓ 全域指令已裝
  ✓ skill 已實體複製(非 symlink)
  ✓ 不裝任何 Claude hook
  ✓ 既有一般檔 → 拒絕 rc2
  ✓ 既有一般檔內容未被動

────────────────────────────────────────
8 passed, 0 failed
```

## spec [S4-c] symlink 邊界實測

`$(dirname "$0")` 原生寫法在「透過 symlink 呼叫」下會解析到 symlink 所在目錄而非真實包目錄,實測必壞(`ERROR: 找不到 .../scripts/lumos`,rc2)。裁定採 brief 給的選項 (a):修正寫法,而非 (b) 只寫清楚的錯誤訊息。`slim/install.sh` 開頭加一段手捲 symlink 解析迴圈(macOS 無 `readlink -f`,逐層 `readlink` 接回所在目錄再判斷是否還是 symlink),零依賴。已實測三種邊界:

1. 路徑含空白(直接執行):過。
2. 絕對路徑 symlink 呼叫:過(原生寫法會壞,修正後過)。
3. 相對路徑 2 層 symlink 鏈(`link2.sh → link1.sh → 真實 install.sh`):過。

選 (a) 不選 (b) 的理由:「新人自己拿到那份精簡版包」的情境本來就可能被使用者建 alias/symlink 呼叫,(b) 把已知可解的邊界丟給使用者自己繞,不必要地加重 [S4-c] 「自足性」(無人可問)這條代價。結論已寫回 [[Projects/公開精簡版_計劃]] [S4-c]。

## 意外

- brief Step 4 敘述「9 條 check 全綠」,實測 `check()` 呼叫共 8 條(逐一核對測試原始碼確認無漏抄),推定是 brief 手數的筆誤,非測試本身缺漏。

## 相關

- 設計/規格:`.superpowers/sdd/公開精簡版_實作計畫/task-3-brief.md`(SDD 產出,非架構圖路徑,依計畫落地於此)
- 系統筆記:[[Systems/slim-install-安裝器]]
