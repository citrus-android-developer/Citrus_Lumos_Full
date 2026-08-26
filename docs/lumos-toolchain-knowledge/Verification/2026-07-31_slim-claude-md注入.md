---
type: verification
status: pass
date: 2026-07-31
valid_under:
  - "install.sh/uninstall.sh 用專屬 sentinel `<!-- LUMOS-SLIM:START/END -->`(與完整版 `LUMOS:GRAPH-DISCIPLINE` 不同名);目標路徑=執行安裝器/卸載器時所在的目錄(cwd)下的 CLAUDE.md"
  - "合併/移除邏輯以 python3 stdlib re 模組實作(非 sed/awk 逐行拼字串),分隔符固定為單一 `\\n`,插入與移除互為精確反向操作"
revalidate_when:
  - "sentinel 名稱或分隔符規則變動 → 重跑 t_slim_install_no_project_touch/t_slim_install_claude_md_idempotent/t_slim_uninstall_removes_claude_md_block 三支確認三條寫入紀律仍成立"
  - "完整版 install.sh 的 CLAUDE.md re-inject 機制(cmd_init/cmd_update,LUMOS:GRAPH-DISCIPLINE sentinel)有變動 → 重查兩個 sentinel 是否仍不相干、不會互相覆蓋"
tags:
  - type/verification
  - status/pass
summary: |-
  TEST:t_slim_install_no_project_touch 16 checks 全綠(換形狀後,含新增的 sentinel 外 byte-equal/porcelain 只含 CLAUDE.md 斷言)、t_slim_install_claude_md_idempotent 5 checks 全綠(新增)、t_slim_uninstall_removes_claude_md_block 8 checks 全綠(新增),`python3 scripts/test_lumos.py -k slim` 137 passed/0 failed
  VERIFY:[[Projects/公開精簡版_實作計畫]] Task 8 落地;spec [S3] 的裁定變更(原禁注入/更新 CLAUDE.md → 開放 append-only 附加,仍禁覆蓋)已寫回 [[Projects/公開精簡版_計劃]] [S3]
  KEY:三條寫入紀律(只准附加/冪等/可移除)各自用「暫存副本注入單行 bug → 綁定測試翻紅 → 還原 → 綁定測試轉綠」的方式獨立驗證過,非稻草人,細節見下方
---
# 2026-07-31_slim-claude-md注入

驗證對象:[[Projects/公開精簡版_實作計畫]] Task 8 —— 推翻 [S3] 原裁定「不注入/更新任何 CLAUDE.md」,改為 append-only 附加架構圖標籤教學。實作見 [[Systems/slim-install-安裝器]](install.sh 第③步)、[[Systems/slim-uninstall-一行卸載]](uninstall.sh 第④步)。

## 裁定變更摘要

原裁定禁的是「覆蓋」——完整版 `lumos init`/`lumos update` 會用範本整段換掉 `LUMOS:GRAPH-DISCIPLINE` sentinel 之間既有的紀律區塊。新裁定開的是「附加」——用專屬且與完整版不同名的 sentinel `<!-- LUMOS-SLIM:START/END -->`,只在 CLAUDE.md 檔尾加一段教學,sentinel 以外一個位元組不動。內容五段(summary 符號/KEY 行合約性前綴/合約鏈括號/frontmatter 欄位/進場三步)逐字對齊 `skills/lumos-project-notes/reference.md`〈summary 欄位〉節。design-loop/code-loop 那套機械紀律依舊不給。

## 測試結果(slim,全量)

```
$ python3 scripts/test_lumos.py -k slim
...
137 passed, 0 failed
```

## 三條寫入紀律:紅→綠證據(暫存副本注入 bug,獨立審計實測)

1. **只准附加、絕不覆蓋**:把 `install.sh` 合併邏輯的 `target.write_text(new, ...)` 暫時改成 `target.write_text(block, ...)`(整檔覆寫)→ `t_slim_install_no_project_touch` 的「sentinel 外既有內容 byte-equal」兩條斷言翻紅 → 還原後轉綠。
2. **冪等**:把「已存在 sentinel 則走替換分支」的 `if matches:` 暫時改成 `if False:`(強迫每次都走插入路徑)→ `t_slim_install_claude_md_idempotent` 的「重跑後仍只有一塊 sentinel」翻紅(變成兩塊)→ 還原後轉綠。
3. **可移除**:把 `uninstall.sh` 的「移除後整檔變空即刪檔」`if new == "":` 暫時改成 `if False:`(強迫保留空檔)→ `t_slim_uninstall_removes_claude_md_block` 的「原本不存在的 CLAUDE.md 卸載後連檔案本身一併消失」翻紅(留下空檔)→ 還原後轉綠。

## 邊界案例(手動驗證,非自動化測試但已人工核對)

- CLAUDE.md 原本不存在 → 安裝後新建、只含這一塊 → 卸載後連檔案一起消失(回到「原本沒有這份檔案」)。
- CLAUDE.md 已有內容且不以換行結尾 → 附加時固定加一個 `\n` 分隔符,不對既有內容做任何 trim/正規化。
- `--force` 重裝(bin/skill 碰撞放行)不影響 CLAUDE.md 這一段的冪等性——重跑只更新自己的 sentinel 區塊。

## 意外

- 最初嘗試用「依既有內容結尾自動判斷分隔符」(0/1/2 個換行三種情況)的寫法,推導卸載時要精確逆算分隔符長度過於脆弱;改用「固定分隔符恆為一個 `\n`」的規則後,插入與移除變成可證明精確互逆的操作,程式碼也更短。
- `slim-scan.py` 對 `slim/README.md` 新增的〈會不會動我專案的 CLAUDE.md〉一節一度誤觸發(裸 `init`/`update`/`design-loop`/`code-loop` 候選),改寫成帶 `lumos ` 前綴與去識別化措辭後恢復零候選,未擴大白名單。

## 相關

- 設計/規格:此次為使用者直接裁定的變更(無獨立 SDD brief),報告見 `.superpowers/sdd/公開精簡版_實作計畫/task-8-report.md`
- 系統筆記:[[Systems/slim-install-安裝器]]、[[Systems/slim-uninstall-一行卸載]]、[[Systems/slim-readme]]
- 計劃節點:[[Projects/公開精簡版_計劃]] [S3]
