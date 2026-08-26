---
type: system
status: done
created: 2026-07-31
updated: 2026-08-01
tags:
  - type/system
  - status/done
summary: |-
  FLOW:先寫 `t_slim_readme_assertions`(紅)→ 寫 `slim/README.md` 滿足 7 項必要內容 → 跑測試轉綠 → 跑 `slim-scan.py` 掃 README 本身,調整措辭到 rc0(README 不像 skill 文件允許留假陽性候選,測試斷言死板要求 rc0)
  KEY:7 項必要內容=①怎麼裝(`install.sh`)+怎麼確認(`lumos --help`)②進場三步 search→context→contracts ③frontmatter 四鐵則(逐字轉錄自 reference.md)④合約鏈是什麼+doctor 為什麼擋+怎麼解 ⑤範圍聲明(功能子集,不含對抗審計;「移除的是入口不是全部程式碼」逐字句)⑥明講不要跑 install-hooks.sh、不要照 CLAUDE.md clone 完整版跑 install.sh,且誠實承認「本 README 壓不住專案自己的 CLAUDE.md」⑦凍結聲明(逐字句「凍結快照」)
  KEY:★掃描器對 README 要求接近 rc0,比 skill 文件嚴格★(2026-07-31 終審後放寬,見下條)——skill 文件允許重跑後留候選只要能逐條說假陽性理由,README 原本測試斷言直接判 `r.returncode == 0` 不接受任何候選殘留;終審 C1 修復後改成「候選須落在已審查白名單內」,見下條
  KEY:2026-07-31 Task 5 修正 `slim-scan.py` 的 prose 形態假陽性(見 [[Systems/slim-scan-掃描器]])後,安裝指令已改回慣用的 `./install.sh`——原本因「`/` 緊貼 `install` 前面、`.sh` 緊貼後面」撞裸散文誤判,遷就掃描器改寫成「用 `bash` 執行 `install.sh`」,那條遺留債已隨掃描器修正解除(舊 DEBT 標記已移除)
  KEY:★2026-07-31 終審 C1 修復★——README 新增一段揭露「`doctor` 有些檢查會建議跑 `lumos init`/`lumos update`/`lumos self-audit`,這三支未交付,看到請忽略;`CLAUDE.md` 相關檢查(Check D)在本版無修復路徑,是刻意的」。這段文字必然會被掃描器命中(自己寫出 `lumos init` 等已移除指令名),但這是「自我指涉的誠實揭露」不是意外懸空引用——`t_slim_readme_assertions` 的斷言因此從死板 `rc == 0` 改成「候選須落在已審查白名單 {(init,prefixed),(update,prefixed),(self-audit,prefixed)} 內,任何超出白名單的候選仍判失敗」,守衛對其餘內容仍零容忍
  KEY:2026-07-31 Task 6 補「怎麼裝」與新增「怎麼移除」「`~/.lumos-slim` 是什麼」兩段——一行安裝(`curl | bash` 跑 [[Systems/slim-get-一行安裝]])與兩行版(先 `git clone` 再跑 `install.sh`)並列讓人選;一行卸載(`curl | bash` 跑 [[Systems/slim-uninstall-一行卸載]])逐條列「會做什麼／不會碰什麼」(尤其明講 skill 目錄先備份不直接刪、不碰專案與 settings.json);解釋固定落點 `~/.lumos-slim` 可以自己刪但建議留著(卸載的 sha256 比對基準)。改動後重跑 `slim-scan.py` 對 README.md 掃描,候選集合仍等於已審查白名單(見下條 TEST),無新增非預期懸空引用
  KEY:★2026-07-31 Task 8 裁定變更——README 反映安裝器不再「完全不碰 CLAUDE.md」★:新增〈會不會動我專案的 CLAUDE.md〉整節,講清楚範圍刀(附加 vs 覆蓋)、注入內容五段摘要、三條寫入紀律(只准附加/冪等/可移除)、目標路徑(執行安裝器時所在目錄);「怎麼裝」「怎麼確認裝好」兩段同步改口(不再宣稱「不會注入或更新任何 CLAUDE.md」);「怎麼移除」新增第 4 步;doctor Check D 那段改寫成「本包只附加名字不同的 `LUMOS-SLIM` sentinel,完全不觸碰完整版 `LUMOS:GRAPH-DISCIPLINE` sentinel,故 Check D 在本版仍無修復指令」(理由從「本包不注入」換成「注入的是另一個不相干的 sentinel」)。改動後重跑 `slim-scan.py`,新文字裡的 `init`/`update` 一律改寫成帶 `lumos ` 前綴(落入既有已審查白名單),design-loop/code-loop 改用不含指令名的泛稱措辭,避免製造新的非預期候選——候選集合仍等於已審查白名單,見下條 TEST
  KEY:★2026-07-31 Task 9 裁定第三次變更——README 反映「附加」升級成「有完整版區塊就整段取代」★:〈會不會動我專案的 CLAUDE.md〉整節重寫,明列裁定演進三階(原裁定絕不碰→Task 8 只准附加→Task 9 可移除既有區塊並策展吸收)、策展範圍(吸收合約鏈/regen 重生標記/frontmatter 欄位,拿掉依賴已移除指令的段落)、插入位置改變(有完整版區塊原地取代/沒有插檔首標題後,不再是純檔尾附加)、備份機制(base64 藏在精簡版區塊自己的 HTML 註解裡,不新增檔案、`~/.lumos-slim` 刪掉也還原得了)、已知風險(完整版若自稱自動更新,其他人跑更新流程會裝回來,兩邊來回覆蓋——已知並接受)。doctor Check D 那段改寫成準確版本:取代後 `LUMOS:GRAPH-DISCIPLINE` sentinel 不存在,Check D 自動略過(不是「刻意不觸碰另一個 sentinel」,是那個 sentinel 真的被拿掉了)。改動時把新增的 `init`/`update` 提及一律寫成 `lumos init`/`lumos update`(落入既有白名單 prefixed 形態),避免製造新的非預期候選
  KEY:★2026-07-31 Task 10——端到端實測抓到真 bug 後同步★:〈怎麼移除〉改寫成強調「四步互不阻擋」+ rc 三段式語意(0=全成功,1=安全性跳過非硬錯誤,2=真正錯誤)+ bin 比對基準分兩層(manifest 優先、`~/.lumos-slim/scripts/lumos` 備援)+「基準缺失」與「內容真的不符」訊息分開講;〈`~/.lumos-slim` 是什麼〉改寫成明講「兩行版安裝本來就不會建立這個路徑,是正常用法不是錯誤操作」,並更正「比對基準已改成優先讀 manifest,這個目錄留不留都不影響卸載」(舊版寫「沒有這份參照卸載只能靠 --force」已不成立)
  KEY:★2026-08-01 Task 11——新增第 8 節,注入目標守衛★:新增〈注入目標守衛(裝到哪裡才安全)〉,插在〈會不會動我專案的 CLAUDE.md〉之後——逐條說明三層守衛(不像專案根拒絕/拒絕裝進 lumos 工具鏈來源 repo/動手前印大聲目標路徑)各擋什麼,明講第一層擋不住那兩次真實事故(事故現場本身就有 `.git`/`CLAUDE.md`/`docs/*-knowledge/`)、真正擋住的是第二層,以及 `--here` 逃生閥用法。改動後重跑 `slim-scan.py`,新文字未提及任何已移除指令名,候選集合仍等於既有已審查白名單、無新增非預期殘留
  KEY:★2026-08-01 補追加 Task 13——新增〈支援平台〉節,插在最前面(標題之後、〈怎麼裝〉之前)★:明講三平台(macOS/Linux/Windows)都支援、單一 Python 邏輯來源+薄殼分工的架構、各平台一行安裝指令(Windows 是 `irm ... | iex`)、`~/.local/bin` 不在預設 PATH 要自己加(分平台講法)。★誠實標記(不可省)★:這台開發機是 macOS 沒有 Windows/PowerShell,Windows 路徑沒有真機驗證過,`install.py`/`uninstall.py` 的 Windows 分支只靠 `LUMOS_SLIM_SIMULATE_WINDOWS=1` 環境變數注入驗過分支邏輯本身,`.cmd` shim 真機行為/PATH 真實生效方式/三支 `.ps1` 薄殼本身都沒驗證——這段誠實聲明與 [[Verification/2026-08-01_slim-python移植]] 的 `valid_under`/`revalidate_when` 對齊,別讓兩邊各說各話。〈怎麼裝〉段落補 Windows 對應指令(PowerShell 版兩行安裝、`--force` 語法)。改動後重跑 `slim-scan.py`,新文字未新增非預期懸空引用,候選集合仍等於既有白名單(見下條 TEST)
  DEP:scripts/test_lumos.py t_slim_readme_assertions｜scripts/slim-scan.py
  TEST:t_slim_readme_assertions 9 checks 全綠(`python3 scripts/test_lumos.py -k slim_readme`);`slim-scan.py slim/README.md --json` 驗證候選集合 == 已審查白名單(4 類 token:init/update/self-audit/signoff,皆 prefixed 形態),Task 10/11 改動後仍等於白名單、無非預期殘留(217 checks 全綠,`python3 scripts/test_lumos.py -k slim`)
  KEY:★2026-08-01 Task 14——〈支援平台〉誠實標記段追加兩項未驗清單★:與 Task 13 那段既有誠實聲明同一段落,追加兩個具體項目(不是新開一節)——①`.cmd` shim 直譯器 fallback(`install.py` 的 `_pick_windows_interpreter()` 用 `shutil.which()` 安裝當下偵測,邏輯層級已驗,`shutil.which()` 在真實 Windows PATH/`PATHEXT` 下的實際解析行為未驗)②三支 `.ps1` 收尾改成 `$global:LASTEXITCODE = $LASTEXITCODE`(不再呼叫裸 `exit`,見 [[Systems/slim-install-安裝器]]/[[Systems/slim-uninstall-一行卸載]]/[[Systems/slim-get-一行安裝]] 對應 KEY 行),修法本身完全沒有真機驗證。這段誠實聲明與 [[Verification/2026-08-01_slim-windows兩缺陷修復]] 的 `valid_under`/`revalidate_when` 對齊。改動未新增/移除任何 `slim-scan.py` 掃描的候選 token(只在既有誠實標記段追加說明文字),`t_slim_readme_assertions` 斷言未動,無需新增測試。
verified_by:
  - "[[Verification/2026-07-31_slim-skill與readme落地]]"
  - "[[Verification/2026-07-31_公開精簡版交付]]"
  - "[[Verification/2026-07-31_公開精簡版終審修復]]"
  - "[[Verification/2026-07-31_接手者演練複審修復]]"
  - "[[Verification/2026-07-31_公開精簡版一行安裝卸載與代碼審修復]]"
  - "[[Verification/2026-07-31_slim-claude-md注入]]"
  - "[[Verification/2026-07-31_slim-claude-md第三次裁定取代與備份還原]]"
  - "[[Verification/2026-08-01_slim-python移植]]"
  - "[[Verification/2026-08-01_slim-windows兩缺陷修復]]"
  - "[[Verification/2026-08-03_Windows真機三輪驗證通過]]"
related:
  - "[[Systems/slim-scan-掃描器]]"
  - "[[Systems/slim-get-一行安裝]]"
  - "[[Systems/slim-uninstall-一行卸載]]"
  - "[[Systems/slim-install-安裝器]]"
plan_refs:
  - "[[Projects/公開精簡版_計劃]]"
---
# slim-readme

公開精簡版交付內容之一:`slim/README.md`,新人 clone 到精簡版後唯一的自足說明文件(★不假設讀過完整版任何文件★)。涵蓋安裝、進場三步、frontmatter 鐵則、合約鏈與 doctor 解法、範圍聲明(功能子集非全部)、明講不要跑哪些(含「本 README 壓不住專案 CLAUDE.md」的誠實界線)、凍結聲明七項必要內容,每項都被 `t_slim_readme_assertions` 的內容斷言鎖住。詳見 [[Projects/公開精簡版_實作計畫]] Task 4、Task 8、Task 9(CLAUDE.md 注入裁定第三次變更)。

★2026-07-31 Task 9(裁定第三次變更)★:〈會不會動我專案的 CLAUDE.md〉整節重寫——不再只是「附加一段教學句」,而是「有完整版紀律區塊就整段策展取代,原地換掉,先位元組級備份供 uninstall 還原;沒有就插檔首標題後」,細節與範圍刀見 [[Systems/slim-install-安裝器]]。Task 8 那句「本包不會注入或更新任何 CLAUDE.md」的說法(已在 Task 8 就被推翻)在本輪進一步被具體化。

規格/設計脈絡見 `.superpowers/sdd/公開精簡版_實作計畫/task-4-brief.md`(SDD 產出,非架構圖路徑,依計畫落地於此)、Task 8/9 見對應 `task-8-report.md`/`task-9-report.md`。
