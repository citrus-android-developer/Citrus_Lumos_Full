---
type: verification
status: pass
date: 2026-07-25
valid_under:
  - "bootstrap step3 四分流(有vault+vendored→hooks/中間態→提示/無vault→確認後init/非git→跳過);cmd_init 一律 force=False+no_pull=True"
  - "_confirm_tty 三階 v2:isatty→input(EOFError 落第2階)/os.open O_RDWR+select timeout/None;LUMOS_TTY/LUMOS_TTY_TIMEOUT 測試接縫"
  - "get.sh 迴圈解析 --pull/--init 後整段委派 bootstrap(set -e 保錯誤傳播)"
revalidate_when:
  - "動 cmd_bootstrap/_confirm_tty/get.sh 或 cmd_init 的輕重路徑分流"
plan_refs:
  - "[[Projects/bootstrap一鍵對稱_計劃]]"
tags:
  - type/verification
  - status/pass
summary: |-
  TEST:t_confirm_tty_unit 6(三階全蓋含★第2階 pty 成功路徑★+stdin 全程未被讀斷言+timeout→None)/t_bootstrap_autoinit 9(--init 建vault+hooks+注入/冪等二跑走接hooks分支/非互動不建+提示/中間態提示不動)/t_getsh_forwards_args 5(真跑 bash:兩旗標轉發非只$1/未知旗標warn/委派無 install 雙寫/失敗傳播 exit 非零)+全套 1392 綠零迴歸
  KEY:裝側一鍵對稱落地——bootstrap 專案層四分流(無 vault 經 _confirm_tty 確認才 auto-init,--init 免確認;中間態不自動動),get.sh clone 後整段委派;與拆側 teardown 成鏡像(bootstrap 不刪 vault、teardown 不建 vault,架構圖兩邊都不碰)
  KEY:_confirm_tty 實作要點=os.open(O_RDWR) 低階 fd(std Codex 真機實驗:open r+ 對 tty 炸 not seekable)+os.write prompt+select timeout(預設30s,有控制終端≠有人回答)+嚴格 y/yes 預設 N;EOFError 落第2階非當 False(isatty 撒謊雙向)。測試接縫=LUMOS_TTY(單元測指 pty slave)/LUMOS_TTY_TIMEOUT——spec 原寫 monkeypatch os.open,實作改 env 接縫等價達意(誠實記偏離)
  KEY:失敗傳播(std F8)=install/hooks/init 各步查 rc,任一失敗尾端彙報+最終 rc1(修掉現碼 step2 吞 returncode 的既有病);LUMOS_HOME env 傳導自訂 home 給 cmd_init(std F6)
  VERIFY:design-loop r1 light(canary caught,2b+3M+1m 折)→ratchet std 單席 Codex(12 條,F1 附真機 PTY 實驗=可執行反證>論證);TDD 紅→綠
  KEY:已知殘留(std 照出既有病,另立)=F4 半成品 vault 無自癒/F9 docs/knowledge與standalone 佈局 slug 反推錯/F10 Windows get.ps1 仍兩步(本案範圍 POSIX)
---
# 2026-07-25_bootstrap一鍵對稱

裝側一鍵對稱落地。spec：[[Projects/bootstrap一鍵對稱_計劃]]。緣起：拆側有一鍵 `teardown`，裝側要「curl → cd → init」三步；使用者要「一鍵建立↔一鍵解除、冪等」。

## 做了什麼
- `bootstrap` 專案層四分流：已是專案→接 hooks；中間態（有 vault 無工具）→提示不動；**無 vault→`_confirm_tty` 確認（印完整路徑、預設 N）y 才 `cmd_init`**（`--init` 免確認）；非 git→只做機器層。
- `_confirm_tty` 三階：isatty→`input()`（EOFError 落第 2 階）；`os.open('/dev/tty', O_RDWR)` 低階 fd＋select 30s timeout；皆不可→None 跳過。
- `get.sh`：迴圈解析旗標（修掉只看 `$1` 的無聲吞旗標）→ clone 後整段委派 bootstrap（`set -e` 保錯誤傳播）。
- 失敗傳播：各步查 rc、尾端彙報、任一失敗最終 rc=1（順修現碼 step2 吞錯的既有病）。

## 全流程驗證
`cd 專案 && curl … | bash` 一條指令：機器層＋專案層（確認後建架構圖）全完成；`lumos teardown` 一鍵拆。兩邊都不碰架構圖內容。

## 測試
20 檢查（confirm 6／bootstrap 整合 9／get.sh 真跑 bash 5）＋全套 1392 綠。單元層用真 pty 蓋掉「curl|bash 唯一互動路徑」（Codex F11 主訴）；整合層 `stdin=DEVNULL＋start_new_session=True` 防 /dev/tty 掛死。
