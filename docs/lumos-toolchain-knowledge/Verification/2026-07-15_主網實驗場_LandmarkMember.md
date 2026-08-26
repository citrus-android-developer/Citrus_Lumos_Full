---
type: verification
status: pass
feature: 關係層守衛實驗場——LandmarkMember 真實 vault(256 節點)實測:補網唯讀+主網全鏈沙盒實彈
commit: 待填
date: 2026-07-15
valid_under:
  - "唯讀檢查跑真 vault(installed lumos=symlink 至本 repo,新 code 即生效);全鏈翻案戲跑 scratchpad 沙盒副本(不動生產資料)"
  - "LandmarkMember 架構圖慣例:verified_by 指向 Verification、plan_refs 指向 Projects(與本 repo 同)"
revalidate_when:
  - "LandmarkMember 真 vault 上實際採用(live 翻案/decision_refs 回填)後回饋"
  - "判斷閘 AI 分級在真實工作流的採用率/誤判率觀察"
plan_refs:
  - "[[關係層主網_實作計畫]]"
tags:
  - type/verification
  - status/pass
---
# 驗證：關係層守衛實驗場——LandmarkMember（真實 256 節點 vault）

人指定的實驗場（2026-07-15）。設計：**唯讀檢查跑真 vault、全鏈翻案戲跑沙盒副本**（零生產風險）。

## 一、補網真 vault 唯讀（E1/E2/E3 首次真實訊號盤點）
- **E1 命中 5 條真死背書**：全指向同一張歸檔 stale 驗證（`2026-05-22_即時降等收回升等禮`），掛在 5 個核心模組（POS-API/點數/票券/CustTransfer/升等降級機制）的 verified_by 上——**一個根因五條邊、真訊號非噪音**（$30 交叉審級的腐爛，doctor 免費掃出）。處置留 LandmarkMember 場內裁（重驗 or 解掛）。
- E2/E3 乾淨（該 vault 尚無帶 ended 的翻案殘留、decision_refs 未採用——符合預期）。

## 二、主網全鏈沙盒實彈（`票券QR一次性核銷_計劃`，真資料）
| 步 | 動作 | 結果 |
|---|---|---|
| ① | `decision-reindex` | 4 條真決策回填 d1..d4 ✅ |
| ② | `decision-supersede "#d1"` | stdout 首行不變；stderr `CASCADE c-…-cfd98d23 ROOT …#d1` + **當場點名 2 篇實作此計劃的真驗證**（plan_refs 連入）✅ |
| ③ | 判斷閘（模擬 AI）confirm V-QR一次性核銷／prune V-always400 | 寫帳 rc=0 ✅ |
| ④ | `resume` | **續展 confirmed 下一跳 → 點名 Systems/POS-API + Systems/票券系統（各 INVARIANT_COUNT 4）**——傳播脊椎「計劃→驗證→系統模組」全通、附合約殺傷半徑提示 ✅ |
| ⑤ | `list` | `confirmed=1 pruned=1` 帳目正確 ✅ |

## 三、實地教訓（設計面誠實記錄）
1. **主網現階段牙口在計劃翻案**：Systems 節點的 typed hop-1 直接連入恆空（verified_by 慣例指向 Verification＝Systems 是源非靶）——**但 hop-2 經「驗證被 confirm → 背書它的 Systems 浮出」補足**（本次 ④ 實證）。Systems 決策**直接**翻案要主網點名鄰居，靠 `decision_refs` 增量回填（設計已備優雅降級，成長路徑明確）。
2. **INVARIANT_COUNT 在真資料上有效**：POS-API/票券系統各 4 條合約的顯著度提示，正是判斷閘要的 blast-radius 信號。
3. installed lumos＝symlink 即生效——實驗場零部署成本。

## 四、實驗場回饋修（E1↔Check3 規則矛盾，實錘→即修）
按 E1 建議拔除 5 條死背書後，Check 3 反咬 4 條「verified_by 漏寫」——stale 驗證內文仍連模組，雙向義務與 E1 打架（拔了報漏寫、掛回報死背書，無解迴圈）。**工具側修**：Check 3 對 stale/fail 驗證豁免（內文連結留作歷史導航，不構成雙向義務）；`t_check3_skips_stale_verification` 正反例釘死（stale 豁免／pass 仍強索）。LandmarkMember 復掃：E1 清零、Check 3 清零、僅剩 1 條與本案無關的 pre-existing orphan。**這正是實驗場的意義——規則對打只有真資料撞得出來。**

## 相關模組
- [[關係層主網_實作計畫]]（M1-M4 整包 + 實驗場 ✅；後續=真 vault live 採用觀察）
