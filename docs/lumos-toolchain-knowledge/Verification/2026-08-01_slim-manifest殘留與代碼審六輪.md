---
type: verification
status: pass
date: 2026-08-01
valid_under: macOS/Linux 真跑;Windows 路徑僅靠 LUMOS_SLIM_SIMULATE_WINDOWS 旗標模擬,★無真機驗證★
revalidate_when: slim/uninstall.py 的清理步驟增減、bin_cleared 判斷式改動、manifest schema 或落點變動、或首次拿到 Windows 真機
plan_refs:
  - "[[Projects/公開精簡版_實作計畫]]"
  - "[[Projects/公開精簡版_計劃]]"
tags:
  - type/verification
  - status/pass
---
# 2026-08-01_slim-manifest殘留與代碼審六輪

## Summary
FLOW: 對打包後的 dist 做端到端真跑冒煙 → 發現卸載完 manifest 殘留在 $HOME 但彙總印「全部完成」 → 補第⑤步 → code-loop `code-slim-python` 六輪對抗審(r1-r6) → 每輪抓到的真缺陷逐一修 + 綁翻紅釘測試 → 達 cap 未收斂 → 使用者人裁放行
TEST: python3 scripts/test_lumos.py 全套 ★2039 passed / 0 failed★(loop 起點 2011 → 終點 2039,新增 28 條);`-k slim` 345 passed
VERIFY: dist 端到端真跑:裝 → `search` 讀得懂 ★INVARIANT★/`KEY:` 標籤 → `set` 寫入 → 卸載;CLAUDE.md 位元組級還原 sha 一致、連卸兩次 rc 皆 0、家目錄零殘留(僅剩 `~/.local/bin`、`~/.local/share` 兩個共用空目錄,正確不動)
DECISION: 達 cap 6 筆未收斂(K-streak 差最後一輪),★明確不開新 loop id 繞 cap★,攤給使用者 → 人裁放行
FLAG: Windows 無真機驗證;`LUMOS_SLIM_SIMULATE_WINDOWS` 只切 `IS_WIN` 旗標,模擬不了 `os.linesep` 等 OS 屬性,此類換行轉譯缺陷在 macOS/Linux 跑測試★結構上看不見★
DEP: [[Systems/slim-uninstall-一行卸載]]｜[[Systems/slim-install-安裝器]](canary-audit 與 slim-skill-修剪 本篇只是描述性提及、非驗證對象,故不連 wikilink——本架構圖裡 Verification→Systems 的連結語意就是「驗證了它」)

## 起點:測試套件看不見的殘留

對**打包後的 `dist/`**（不是 repo 內副本）做端到端真跑冒煙時發現:卸載跑完會把 `~/.local/share/lumos-slim/manifest.json` 留在使用者家目錄,彙總卻印「✓ 全部完成」。

★盲區型別★:這次是「**根本沒去驗**」,不是「斷言寫錯」——2011 條測試全綠,沒有任何一條斷言過它該消失。與本專案已撞十一次的「測試存在但沒在驗它宣稱要驗的」互補:兩者都不是靠加測試數量能解的。接住它的是**對交付產物本身的端到端真跑**（本專案第二次由真跑接住測試套件盲區,第一次是兩行安裝路徑下卸載完全失效）。

## 六輪對抗審:每一輪的真缺陷

canary（偷埋的假錯,驗審查員有沒有認真讀）六輪**全部 caught**,無 missed。排掉 canary 與溯源影子後的存活真 finding:

| 輪 | canary 型 | 存活真 finding | 性質 |
|---|---|---|---|
| r1 | 邊界/off-by-one | 0 | — |
| r2 | 資源未釋放 | 0 | — |
| r3 | None/例外未接 | 1 (minor) | `unlink` 與父目錄 `rmdir` 共用同一個 `try/except`:`rmdir` 失敗印成「移除 manifest 失敗」並 `bump(2)`,但 manifest 其實已刪成功 → **錯誤歸因誤導** |
| r4 | 冪等/併發 | 1 (major) | 「bin 清乾淨沒」靠在每條分支手動設旗標,①b 的 `OSError` 分支**漏設一條** → Windows 上 shim 還在、manifest 卻被刪,銷毀重試時唯一的比對基準 |
| r5 | 邊界/off-by-one | 2 (major+minor) | r4 改用「查檔案系統實況」後,**那一行謂詞自己有兩個邊界寫錯**:(a) shim 那半沒受 `IS_WIN` 限定 → 非 Windows 上一個不相干的 `lumos.cmd` 就把 manifest 永久卡住,且⑤無 `--force` 分支救不回 (b) 左右不對稱,shim 少了 `is_symlink()` → 斷鏈 symlink 仍佔路徑卻被判成已清 |
| r6 (opus) | 資源未釋放 | 1 (minor,純文件) | README 三處:改成五步後漏改「現在四步互不相干」/ rc=2 仍舉例「找不到 sha256 工具」但 Python 版不可能發生 / 第 5 點 manifest 保留條件漏了 Windows ①b shim |

**findings 序列 [0,0,1,1,2,1]**。r6 是唯一一輪**零代碼缺陷**的,只剩文件精度——這是這段程式趨穩的訊號。r6 的 opus 席同時獨立複驗:r3/r4/r5 三次修法皆真的修對（代值算 + 實跑）、六條新測試皆真的跑到宣稱路徑、冪等連跑三次 rc 全 0、爆炸半徑受控（`parent.name == "lumos-slim"` + 目錄非空即不動,實測 `~/.local/share` 本身與其他內容完全不動）。

## ★方法論收穫(比缺陷本身值錢)★

**① 換機制不等於免疫,只是把缺陷面搬家。** r4 用「查檔案系統實況」取代「逐條分支設旗標」,確實消掉了一整類「會漏哪條分支」的缺陷——但實況查詢那一行謂詞本身立刻又生出兩個新邊界（r5）。缺陷面從「會漏哪條分支」搬到「這一行的 `and`/`or` 組合寫對沒」。**這不是說換機制沒用**（分支簿記會隨未來新增分支持續漏,單行謂詞不會）,而是說「我換了個更好的機制」不構成「這次不用再審」的理由。

**② 第十一次撞到「測試存在但沒在驗它宣稱要驗的」,而且是我自己剛寫的測試。** r3 的還原翻紅釘第一版:現場用「父目錄塞別的檔案讓它非空」→ 但那樣 `if ... and not any(parent.iterdir())` 直接判假,`rmdir()` **根本不會被執行**,例外路徑一次都沒跑到,把修法還原成共用 `try` 的突變照樣全綠。改成 `chmod ~/.local/share 0o500`（`unlink` 需 `lumos-slim/` 寫權限仍有、`rmdir` 需 `share/` 寫權限已無）才真的翻紅 3 條斷言。
★通則★:**要驗例外處理,現場必須真的讓那個呼叫拋例外,不能只是讓它不被執行。** 前十次的型態是「斷言寫得太鬆」,這次是「現場根本走不到被測分支」——後者更隱蔽,因為測試名稱、docstring、斷言看起來都對。

**③ 每個「我枚舉了 N 種形態」的守衛都要假設有第 N+1 種。** `slim-scan.py` 掃五種指令名形態,但**掃不到路徑型懸空引用**（架構圖節點路徑、`governance/` 語料目錄）——r6 之外由人眼複閱補上一條(見 Systems/slim-skill-修剪,同上,描述性提及不連 wikilink)。不宣稱已窮盡。

## 收斂判定與人裁

達 cap 6 筆,機械帳:K-streak(--need 2) ✗（差最後一輪）/ G1 skipped（code 情境無引用座標）/ G2 ✓ findings 枯竭 / G3 ✓。

★明確不開新 loop id 繞 cap★——本 loop 本身就是從 `code-slim-handoff` 開新 id 承接的,理由是實作整批 bash→Python 替換（寫死在 r1 帳上）;再開一次沒有同等理由,開了就是在自己帳上作弊。

依 skill「到頂仍未收斂 → 停、把現況攤給人」,攤牌後**使用者裁定放行**（2026-08-01）。未修 findings **0 條**（各輪存活 findings 全部已修並各自綁翻紅釘測試）。

## 誠實天花板

1. **Windows 無真機驗證**。`LUMOS_SLIM_SIMULATE_WINDOWS` 只切 `IS_WIN` 這個旗標,模擬不了 `os.linesep` 等作業系統屬性——這類換行轉譯缺陷在 macOS/Linux 跑測試**結構上就是看不見的**。真碼目前讀寫對稱（`read_text`/`write_text` 皆做轉譯）故無此洞,但這是「目前剛好沒事」不是「有守衛擋著」。
2. **canary caught ≠ 覆蓋**。六輪全 caught 只證明每一席都醒著,不證明審得夠廣。
3. **cap 未收斂的放行是人裁,不是機械證明**。帳上留痕可查、可駁。
