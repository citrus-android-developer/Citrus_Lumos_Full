# 設計:★COMBO★ 組合覆蓋軟規範(check-t-sentinel)

- 日期:2026-06-23
- 狀態:**人工定稿放行**(2026-06-23 design-loop 6 輪、canary 6/6 全 caught、達 cap 未自動收斂;核心地面事實全 clean、F1 判據漏洞已修、剩 F3/F4 文檔級無 blocker,人工 review 放行)
- 動機來源:2026-06-23 日報 gap「Check T 賭『綁一個會跑的測試=合約為真』,但測試只是 proxy、會被反向優化刷掉」+「驗證正確性 > AI 審計」主軸定調
- loop_id:check-t-sentinel

## 目標(一句話)

新增軟性 Tag `★COMBO★` 標在最重的 `★INVARIANT★` 鐵則上,doctor 加一道**軟 Check**(照 Check S 模板,`warn_soft`、不擋、不計 issues):標了 `★COMBO★` 卻只綁 1 條 `[test:]` happy-path → 提醒「補組合測試」,養成「最重的地方測組合情境」的習慣。

## 前提與既驗事實

- **Check T 現狀**(`scripts/lumos:561` `section("T")`,解析 L568-613):doctor 不執行測試,只靜態驗每條 `★INVARIANT★` 綁了真實存在 + 經審計的 `[test:名]`,收集 `bound = (rel, clean, refs)`,`refs` 是該 invariant 的 `[test:]` 名列表。
- **gap**:Check T 驗「綁了測試」,但測試是 proxy——maker 看得到綁的 happy-path 測試,可寫「剛好過這條」的實作而不真守規格,CI 照樣綠。「綁了幾條」不等於「測夠了組合情境」。
- **CI 是真確定性錨點**:bound 測試在 CI 跑、綠才部署——已確定性驗「測試跑了 + 綠了」。本機制**不重複** CI(不執行測試、不驗有效);CI 唯一接不住的縫=「只跑你寫了的測試,不提醒你漏寫組合情境」,本機制只補這道縫。
- **軟規範範本**(`scripts/lumos:648` `section("S")`,註釋塊 L644 起,L4 自足性審計):`warn_soft`(`scripts/lumos:381`,印出但不動 issues、不影響 rc)+ `gov_events {"gate":..., "kind":"warned", "hard":False, ...}`(`scripts/lumos:660`)。本 Check 照此模板。
- **invariant 解析**(`scripts/lumos:817` `INVARIANT_RE`,要求 `KEY:` 前綴 + `★INVARIANT★` marker;group(1)=marker 之後的文字):`★COMBO★` 寫在 marker 之後 → 落在 group(1),Check K 在 group(1) 做 `"★COMBO★" in` 檢測。**勿援引** `scripts/lumos:707` `"★INVARIANT★" in s`——那是 `_search_region`(grep 結果區域標記)、與 doctor invariant 解析無關(F7)。
- **既有 Tag 體系**:`★INVARIANT★` / `★IRREVERSIBLE★` / `★CHECKPOINT★` / `★DEBT★`(grep 坐實)。`★COMBO★` 為新增第 5 個,語義=「★INVARIANT★ 的子修飾:這條最重、該有組合覆蓋」。

## 邊界 / 非目標(YAGNI + 誠實)

- ❌ **不驗組合性**:lumos 只**數 `[test:...]` 標記個數**(非展開名數,F1),驗不了「第 2 個標記是不是真組合、夠不夠」——那靠寫測試的人 + CI 跑。
- ❌ **不隱藏 sentinel**:組合測試只要進 CI 跑,maker 看得到也無妨(組合爆炸→刷=真實作);不搞單獨 repo/權限隔離。
- ❌ **不驗測試有效**:CI 跑、綠才部署已驗;本機制不重複。
- ❌ **不執行測試**:lumos 一貫靜態(同 Check T/S);跑 = CI/人。
- ❌ **不擋**:`warn_soft`、不計 issues、不影響 rc(同 Check S)。
- ❌ **不改 Check T / 既有 Tag / 不動 `[test:]` 機制**:純加 `★COMBO★` 過濾 + 一道軟 Check。

## 架構:新 Tag + 軟 Check

```
doctor 掃節點
  ├─ Check T(不動):invariant 綁 [test:] 真實性
  └─ Check K(新增,接在既有 T→R→S 之後、段尾;軟,照 Check S):
       掃所有含 ★INVARIANT★ 的行 → 過濾其中也含 ★COMBO★ 的
         · [test:...] 標記數==1 → warn_soft「最重鐵則只綁 1 個 [test:] happy-path,建議補組合測試」
                            + gov_events {"gate":"check-k","kind":"warned","hard":False,"nodes":[stem]}
         · 標記數>=2 → 視為有意識補了,不提醒
         · 無 ★COMBO★    → 整個 Check 靜默(ok「無 ★COMBO★ 標記」)
```

`★COMBO★` 是 `★INVARIANT★` 的**子修飾**:只標在已是 `★INVARIANT★` 的鐵則上(最重的那幾條)。**★COMBO★ 無 ★INVARIANT★ 是盲區(F3)**:`★COMBO★` 寫在沒有 `★INVARIANT★` 的 KEY 行,會被 `INVARIANT_RE` 漏掉、`extract_contracts` 收不到 → Check K 看不到、無法軟提醒(誤標靜默忽略)。已知盲區,**YAGNI 不另跑掃描處理**(★COMBO★ 本就設計為 ★INVARIANT★ 子修飾,單獨用屬罕見誤用)。

**`★COMBO★` 必須寫在 `★INVARIANT★` 之後(F3)**(如 `KEY: ★INVARIANT★ … ★COMBO★`):寫在前會讓 `INVARIANT_RE`(要求 `★INVARIANT★` 緊跟 `KEY:` 可選 `(...)` 後)不匹配,整條 invariant 從 Check T/K 雙雙消失。Check K 在 `INVARIANT_RE` group(1) 裡檢測 `★COMBO★`。

## 組件(改動)

### 改:`scripts/lumos`(cmd_doctor)

1. **`★COMBO★` 不改節點分類**:它是 invariant 行內標記,Check K 在 `INVARIANT_RE` group(1)(★INVARIANT★ 之後文字)做 `"★COMBO★" in` 檢測(見前提、§架構「★COMBO★ 必寫在 ★INVARIANT★ 之後」一段);無需碰既有 tag/節點分類邏輯。
2. **新增 `section("K", "★COMBO★ 組合覆蓋提醒 ...")`**(接在 **Check S 之後**、Check 區段尾——既有順序 T→R→S,K 排最後;照 Check S 結構):
   - **自己重掃(F2,不複用 Check T 局部變數)**:`bound`/`refs` 是 Check T `else:` 區塊局部、出作用域,且 spec 不改 Check T。改為比照 Check T 調 **`extract_contracts(n)`**(`scripts/lumos:821`,回 `(inv, debt)` 兩個 list;`invs, _ = extract_contracts(n)` 取 invariants,同 Check T `scripts/lumos:564`;`inv` 內部為 `INVARIANT_RE.match` group(1) 文字) + `strip_test_refs(inv)`(回 `(clean, refs)`,`refs`=`[test:]` 名 list)取 refs,**照 Check S `for rel, n in sorted(notes.items())` 迴圈保留 note 物件 `n`(F4:`n.stem` 即來自此)**。過濾 `inv` 含 `★COMBO★` 的(F-B:用 extract_contracts,非逐行 INVARIANT_RE loop——對齊 Check T 實際結構)。
   - **數 `[test:...]` 標記個數(F1,非 `strip_test_refs` 展開名數)**:用 `INV_TAG_RE.findall(inv)` 數該 invariant 的 `[test:...]` 標記出現次數——`[test:a,b]` 是 **1 個標記**不是 2 個名,免「單逗號 tag 繞過提醒」(動機正要防的反向優化)。標記數==1 → 把該 invariant 顯示字串(`clean`,`.replace("★COMBO★","").strip()` 去殘留+殘白 F-C/F4)收進 `combo_thin`(**元素為字串**);**透過 `_soft_list`(`scripts/lumos:668`,照 Check S:`[:8]` 截斷)** 印(F3:`_soft_list` 溢出文案硬寫「還有 N 篇」,對 invariant 條數略不貼切——cosmetic、接受),advice=「為這條最重鐵則補一條組合情境測試(多條件交叉),別只測 happy-path」(F2:走 _soft_list、非直接 warn_soft,對齊 Check S 模板)。
   - `gov_events.append({"gate":"check-k","kind":"warned","hard":False,"nodes":[n.stem]})`(同 Check S L660;`n`=重掃迴圈的 note 物件,F5)。
   - 無 combo 標記 → `ok("無 ★COMBO★ 標記(無鐵則宣告需組合覆蓋)")`。

### 不改

`[test:]` 解析、Check T、`warn`/`fail`、既有 Tag、節點分類、`gov_events` schema。

## 誠實天花板

1. **lumos 只數 `[test:...]` 標記個數,驗不了「組合性 / 夠不夠」**:綁 2 個標記都是 happy-path 也算「滿足」;`[test:a,b]` 單標記多名只算 1(F1:免單逗號繞過,但 2 個標記仍可都 happy)——已知弱保證。真正的組合覆蓋靠寫測試的人 + CI 跑;本 Check 只是「提醒別只綁 1 個」的摩擦地板。
2. **「最重」由人標 `★COMBO★`,主觀**:沒標 = 不管。lumos 不自動判哪條最重(同 ★IRREVERSIBLE★ 靠人標)。
3. **真驗證是 CI 跑測試**:本機制是軟提醒、不是保證;CI 綠才部署才是確定性錨點。同 Check S「摩擦地板、非神諭」。
4. **軟規範會被無視**:warn_soft 不擋,maker 可不理。設計如此(養成習慣、非強制),接受。

## 測試策略

- **fixture 驅動**(構造臨時 vault 跑 doctor,驗輸出):
  - `★INVARIANT★ + ★COMBO★` 綁 1 條 `[test:]` → doctor 輸出含 Check K 的 warn_soft「建議補組合」、rc 不變(不計 issues)。
  - 同上綁 2 條 `[test:]` → Check K 不提醒該條。
  - 有 `★INVARIANT★` 無 `★COMBO★` → Check K 靜默/ok。
  - `★COMBO★` 不影響既有 Check T 結果(回歸:Check T 輸出不變)。
- **rc 驗證**:Check K 觸發時 `lumos doctor` 退出碼**不變**(warn_soft 不計 issues,同 Check S)。
- 跑:沿用 lumos 既有 doctor 測試方式(design-loop/實作時確認 lumos 測試基建);無則手動構造 fixture vault 驗。

## 知識同步影響

| 受影響文件 | 需同步什麼 |
|---|---|
| `docs/methodology/架構圖即合約.md` | Tag 體系補第 5 個 `★COMBO★`(★INVARIANT★ 子修飾);Check 體系補 Check K(組合覆蓋軟提醒);點出「驗證正確性 > AI 審計」主軸——CI 跑測試是錨點,lumos 軟提醒補組合 |
| `docs/methodology/架構圖即合約-對外論述.md` | 對外白話:最重的鐵則別只測一個順風案例,該測「各種情況湊一起」——lumos 軟提醒、不強制 |
| `scripts/lumos`(本體) | 新增 section("K") + ★COMBO★ 子字串檢測;Tag 說明/help 補 ★COMBO★ |
| `lumos-*` skills | 確認有無 Tag 教學 skill 需補 ★COMBO★(design-loop 查) |

## 審計修正紀錄

### R1(2026-06-23,canary type a=壞§ref,opus,**CAUGHT**,severity=blocker)
canary(§Tag 交互矩陣 不存在)被識別。排掉 canary 後仍有真 finding,折入:
- **Blocker(F1)**:`section("C")` 已被 core_refs 檢查占用(scripts/lumos:514)→ 全改未占用的 `section("K")`(Check K/check-k)。
- **Major(F2)**:「複用 Check T 的 bound/refs」不成立(局部變數出作用域 + 違反「不改 Check T」)→ Check K 自己重掃(INVARIANT_RE + strip_test_refs)。
- **Major(F3)**:`★COMBO★` 寫在 ★INVARIANT★ 前會讓 INVARIANT_RE 不匹配、invariant 消失 → 規定必寫在 ★INVARIANT★ 之後、在 group(1) 檢測。
- **Minor(F4)**:section 位置「緊接 Check T 後」與既有 T→R→S 矛盾 → 改「接 Check S 後、段尾」。
- **Minor(F5)**:gov_events `[stem]` 作用域無定義 → 重掃保留 note 物件 `n`、用 `[n.stem]`。
- **Minor(F7)**:錯引 `scripts/lumos:707`(`_search_region`,與 doctor 解析無關)→ 改引 `INVARIANT_RE`(L817,KEY 行前綴嚴格解析)。
- 其餘(warn_soft L381/Check S gov_events/4 既有 tag/strip_test_refs 回 refs)經 auditor 查證 clean。

### R2(2026-06-23,canary type b=未定義旗標,opus,**CAUGHT**,severity=minor)
canary(`--no-combo` 未定義旗標)被識別。排掉 canary 後僅 minor(此輪 good):
- **Minor(F-A)**:Check S section 行號 644→648(L644 是註釋塊、call 在 648)。
- **Minor(F-B)**:Check K 應調 `extract_contracts(n)`(scripts/lumos:821,Check T 實際用的)取 invariants,非 spec 誤述的「逐行 INVARIANT_RE loop」。已改。
- **Minor(F-C)**:`strip_test_refs` 不剝 `★COMBO★`,顯示殘留 marker(cosmetic,不影響 len(refs))→ 顯示前可 .replace。
- 其餘(section("K") 不撞名/warn_soft L381/INVARIANT_RE L817/gov_events L660/L707/4 tag)經 auditor 全查證 clean;`★COMBO★` 必寫 ★INVARIANT★ 之後經 INVARIANT_RE 證實 load-bearing。

### R3(2026-06-23,canary type c=未定義常數,opus,**CAUGHT**,severity=major)
canary(`COMBO_MIN_REFS` 未定義常數)被識別。排掉 canary 後仍有真 finding:
- **Major(F3)**:§43「★COMBO★ 無 ★INVARIANT★ 軟提醒」與 §53 extract_contracts 路徑互斥不可實作(extract_contracts 只收 INVARIANT_RE 命中行,純 ★COMBO★ 行進不了)→ 改誠實標「已知盲區、誤標靜默忽略、YAGNI 不另掃」。
- **Minor(F2)**:extract_contracts 回 `(inv, debt)` 兩 list → 寫清 `invs, _ = extract_contracts(n)`(同 Check T L564)。
- 其餘(行號 S648/T561/C514、group(1)/strip_test_refs/warn_soft 不動 issues/gov_events L660/L707/4 tag)全查證 clean。

### R4(2026-06-23,canary type d=未定義產物,opus,**CAUGHT**,severity=minor)
canary(`governance/.combo-debt.jsonl` 憑空產物 + 違反 warn_soft/不寫檔邊界)被識別、刪除。排掉 canary 後僅 minor(此輪 good):
- **Minor(F2)**:warn_soft 應透過 `_soft_list`(scripts/lumos:668,照 Check S 的 [:8] 截斷)調用,非直接;combo_thin 元素定為字串。
- **Minor(F4)**:重掃照 Check S `for rel, n in sorted(notes.items())` 迴圈,n.stem 來自此。
- 核心地面事實(INVARIANT_RE L817/extract_contracts L821 回(inv,debt)/strip_test_refs L963/warn_soft L381/section S648 T561 C514 K不撞名/gov_events ci時寫/4 tag)經 auditor 全查證 clean,R1-R3 修正站得住。

### R5(2026-06-23,canary type a=壞§ref,opus,**CAUGHT**,severity=major)
canary(§Check 分級表 不存在)被識別。排掉 canary 後仍有真 finding:
- **Major(F2)**:第二個壞§ref「§架構位置規定」(組件 step1,R1 折入時自引)——spec 無此標題 → 改指真章節「§架構『★COMBO★ 必寫在 ★INVARIANT★ 之後』」。
- **Minor(F3)**:`_soft_list` 溢出文案「還有 N 篇」對 invariant 條數略不貼切 → cosmetic 標註接受。
- 核心地面事實(INVARIANT_RE/extract_contracts/strip_test_refs/warn_soft/_soft_list L668/section/gov_events/L707/4 tag)經 auditor **逐項查證全與代碼一致**,設計鏈閉合可實作。

### R6(2026-06-23,canary type b=未定義旗標,opus,**CAUGHT**,severity=major)
canary(`--only-combo` 未定義旗標)被識別。排掉 canary 後仍有真 finding:
- **Major(F1)**:判據 `len(refs)`(展開測試名數)可被 `[test:a,b]` 單逗號 tag(=2 名)繞過提醒——正中動機要防的反向優化。改為**數 `[test:...]` 標記個數**(`INV_TAG_RE.findall`),`[test:a,b]` 算 1 個標記。
- **Minor(F3)**:★COMBO★ 誤寫 ★INVARIANT★ 前會靜默丟整條 invariant(Check T 漏報)——prose 已標、無護欄,YAGNI 接受、留痕。
- **Minor(F4)**:`.replace("★COMBO★","")` 留殘白 → `.replace(...).strip()`。
- 核心地面事實 auditor 第 6 輪再次逐項查證全與代碼一致。

---

> **達 cap 6 未收斂(2026-06-23)**:6 輪 canary **全 caught(6/6,opus 零漏)**,severity blocker→good(minor)→major→good(minor)→major→major。**核心地面事實 5–6 輪逐項查證全 clean、設計鏈可實作**;未收斂主要卡在文檔級「壞§ref」(R1 canary、R1 自引 §架構位置規定、R5 canary)與 F1 判據漏洞(已修)。依 design-loop 護欄:達 cap 未收斂 → 停、**人工定稿**(F1 核心修正已折、剩 F3/F4 文檔級無 blocker;放行的人最後兜底)。
