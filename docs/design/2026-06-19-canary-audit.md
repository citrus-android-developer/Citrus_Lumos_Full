# 設計:Canary 審計(test-the-tester,給對抗設計審計防放水)

- 日期:2026-06-19
- 狀態:✅ CONVERGED(經 4 輪 Sonnet 對抗審計收斂,implementable as-is)
- 動機來源:2026-06-18 AI 治理日報 Gap 1 + Codex `/goal`「驗收要比迴圈本身可靠」

## 0. 動機

這套方法論把判斷外包給乾淨 Sonnet 審計員(例:設計/spec 的對抗審計 loop),**卻從沒檢查審計員這一輪到底有沒有在認真抓**。一個放水的審計員回報的「沒問題 / 看起來不錯」是最危險的假乾淨——自主迴圈只會更快、更自信地犯錯。

借 Codex `/goal` 的共識「**你判斷『做完沒』的那套檢查,必須比迴圈本身更可靠**」:每一輪對抗審計**偷塞一個已知的瑕疵(canary)**,若審計員沒抓到,代表這輪審計失靈 → 它的判決作廢、重跑。

## 1. 範圍(v1)

- **只做「對抗設計/spec 審計」**:被審的是**你控制的文件**(spec/設計稿),可以乾淨地植入瑕疵再移除。這正是我們反覆在跑的那種審計 loop。
- **不做「架構圖自足性審計」**(§795/§831):審計員讀的是**真實架構圖**,植 canary 會污染架構圖或要 temp-copy 體操 → v1 延後。
- **形式 = skill 協議規則 + 極小 lumos helper**:協議是主體(怎麼跑帶 canary 的審計);helper 只負責**把 canary 結果記進本機 log,漏抓事件餵進 `lumos gov`**(審計員可靠度的可查詢軌跡)。lumos 不 spawn agent,植入/判定留在對話/skill 層。

## 2. 協議(寫進 skill 的規則)

用乾淨 agent 對抗審計一份 spec/設計時:

1. **植一個 canary**(在文件的工作副本上):一個刻意、已知、**純加性(additive)**的瑕疵——v1 **只允許不牽動其他段落**的類型:**指向不存在章節的交叉引用**、或**約束引用了未定義的詞**。**禁用「與另一節矛盾的需求」這類非局部 canary**(R1-F3:它會牽動被矛盾的那節、污染審計員對該節的真實 findings,移除 canary 也救不回)。給它一個**唯一 token**(如 `CANARY-7f3a`)當**定位記號**——不是「抓到」的證明(見 step 3),只是讓你在審計員輸出裡快速找到 canary 鄰域去細看。記下 canary 是什麼、在哪。**提交的文件永遠不含 canary。**
2. **正常跑審計**——**不告訴審計員有 canary**(告訴它就會作弊)。
3. **判定有沒有抓到**:唯一算數的是審計員**清楚且正確地描述了那個植入瑕疵**(R1-F2:光是 token 字串出現在輸出裡**不算**——它可能只是順手提到卻沒真懂;token 只幫你定位)。
   - **抓到** → 審計員這輪是醒的。**只信它對「同類、同段」的真實 findings,不是整份文件的全面合格證**(R1-F1;見天花板)。移除 canary,依真實 findings 行動。
   - **沒抓到** → 審計員放水(或對這份文件來說太弱)。**這輪判決作廢。** 換一個**不同的** canary 重跑。`lumos canary record missed` 記一筆。
4. **連續 2 次沒抓到就升級**(開始新一輪前先 `lumos gov --since 7` 看最近 missed 次數,別只憑記憶):換更強的審計模型、或把文件切小(太長導致審不仔細)——別只是用同一套一直重跑。
5. **panel 變體**:若一輪派 N 個獨立審計員,**每個各給自己的 canary**;漏抓自己 canary 的那個,從投票中剔除。

**校準鐵則**:canary 要「**認真的審計員一定抓得到、但不是一眼就看穿**」——對齊你真正在意的那類瑕疵。太細 = 不公平地判審計員失敗;太明顯 = 訊號太弱、形同走過場。

**天花板(同 [test:]/[audit:]/[rollback:] 的誠實)**:抓到 canary 只證明審計員**醒到足以抓那一個、那一類、那一段的植入瑕疵**,**不證明它抓到了所有真實瑕疵**(它可能細讀了 canary 那段、略過其餘)。canary 是「**注意力的下限**」,不是完整性保證。別把「canary 抓到了」當成「這份東西審乾淨了」。**canary 抓得到的失敗模式**是「審計員根本沒讀這份文件 / 只吐通用回應」;**抓不到的**是「讀了、但對複雜權衡判斷錯」(R2-F7)——後者 canary 無能為力,別在複雜 spec 上因 canary pass 就過度信任。

**迴歸沒閉合(誠實)**:判定「有沒有抓到」的是**植入者本人,沒有外部檢查**。canary 是**降低放水機率的摩擦**,不是閉合的驗證迴路——它把問題從「審計員審得好不好」換成「你判得準不準」,只是後者較難自欺、不是消失了。

## 3. Helper(極小 lumos 工具)

**只有一個指令**(R1-F6:砍掉 `lumos canary new`——token 鑄造 shell 一行就行,而且 `record` 會自動補):

- `lumos canary record caught|missed [--auditor 模型] [--token T] [--note 文字]` → append 一筆事件到 `<vault.parent>/.canary-log.jsonl`。
- **argparse 結構(R2-F4,比照 `guard audit`)**:`canary` 為頂層 subparser → `csub = canary.add_subparsers(dest="ccmd", required=True)` → `csub.add_parser("record")` → `kind` 是 `record` 的 positional,`choices=("caught","missed")`(非法值 argparse 自動 rc2)。dispatch:`if args.cmd == "canary": return cmd_canary(env, args.kind, args.auditor, args.token, args.note)`(R3-Issue3:`dest="ccmd"`)。
- **`cmd_canary(env, …)` 用 `env.vault.parent` 定位寫入**(R2-F1,比照 `cmd_gov`——只用到 vault.parent、不額外依賴已載入的圖)。
- **`--token` 沒給就自動鑄一個 `CANARY-<secrets.token_hex(4)>`**(R2-F2:**隨機、非時間戳**——時間戳是秒解析度,同秒兩筆會撞 token 被 dedup 誤折)。保證每筆 token 唯一(供 gov dedup,R1-F4)。
  - 寫入 schema:`{"ts","kind","auditor","token","note"}`(`ts` = `datetime.now().astimezone().isoformat(timespec="seconds")`,比照 `_append_governance_log`)。

- `lumos gov` 新增 `.canary-log.jsonl` 為**第 4 個讀取來源**。**明確 mapper**(R1-F4):
  ```
  {"ts": d["ts"], "commit": "", "gate": "canary", "kind": d["kind"], "hard": False,
   "nodes": [], "token": d.get("token",""), "detail": (d.get("auditor","")+" "+d.get("note","")).strip()}
  ```
  並把 `cmd_gov` 的 dedup key 從 `(r["commit"], frozenset(r["nodes"]), r["gate"], r["kind"])` 改成加第 5 個鑑別子 **`r.get("token", "")`**(R3-Issue1:**務必用 `.get()` 不可用 `r["token"]`**——既有三條 mapper 的 row 沒有 `token` 鍵,`r["token"]` 會對所有舊事件 `KeyError` 弄爆 `lumos gov`)。既有三條 mapper **維持原樣、不加 token 鍵**;**只有 canary mapper 輸出 `token` 鍵**。其他來源 token 取到 `""`、行為不變;canary 每筆 token 唯一 → **不會被誤折成單列**(R1-F4 的 collapse 修掉)。顯示沿用既有格式,`token`/`auditor`/`note` 收進 `detail`。

**寫入路徑**:canary 寫**自己的** `.canary-log.jsonl`(單一寫者=`lumos canary`),不碰 doctor 的 `.governance-log.jsonl`(沿用「不合併寫入、gov 唯讀彙整多檔」的決定)。

## 4. 範圍 / YAGNI(v1 明確不做)
- ❌ 架構圖自足性審計的 canary(真實架構圖污染)——延後。
- ❌ 自動注入/自動判定工具(lumos 不 spawn agent;植入與判定留在對話/skill)。
- ❌ `lumos canary` 擋任何東西——record-only、本機(同 `gov` 是可見性、不是閘)。
- ❌ `lumos canary new`(token 鑄造):已砍,`record` 自動補 token(R1-F6)。
- ❌ 非局部 canary 類型(矛盾需求等):v1 只收純加性瑕疵(R1-F3)。

## 5. 受影響
- `skills/lumos-project-notes/SKILL.md` — 新增一節:對抗設計審計的 canary 協議(放在 `[audit:]`/maker-checker 內容附近)。順手把「怎麼跑一輪對抗設計審計」也輕量 codify(目前是 ad hoc)。
- `scripts/lumos` — `cmd_canary`(new/record)+ subparser/dispatch;`cmd_gov` 加讀 `.canary-log.jsonl`。
- 測試 `scripts/test_lumos.py` — canary record 寫事件;gov 顯示 canary 事件。

## 6. 驗收標準
- `lumos canary record missed --auditor sonnet`(帶 `--vault`)→ append 到 `<vault.parent>/.canary-log.jsonl`,且該筆有自動鑄的 `token`;`lumos gov` 出現 `canary/missed` 列。
- 兩筆 record 帶**明確不同的** `--token CANARY-A` / `--token CANARY-B`(R2-F2:測試不依賴 auto-mint 時序)→ `gov` **各自一列、不被 dedup 折成一列**。
- `lumos canary record bogus`(非 caught/missed)→ rc2(argparse choices)。
- 既有測試全綠(回歸)。

## 審計修正紀錄
### 第一輪(Sonnet 對抗審計)
- R1-F2(blocker):token 不是「抓到」的機械證明,只當定位記號;唯一算數的是正確描述瑕疵 → §2 step 3。
- R1-F3:v1 canary 只收純加性瑕疵,禁矛盾需求等非局部型(會污染其他 findings)→ §2 step 1 / §4。
- R1-F1:抓到 canary 只信同類同段判決,非全面合格證 → §2 step 3 / 天花板。
- R1-F4:gov dedup 會把 canary 事件折成單列 → mapper 寫明 + dedup key 加 `token` 第 5 鑑別子 → §3。
- R1-F5:迴歸沒閉合(植入者判定無外部檢查)→ §2 加誠實段。
- R1-F6:砍 `lumos canary new`,`record` 自動補 token → §3 / §4。
- R1-F7:`canary record` 用全域 `--vault` 定位寫入 → §3 / §6。
- R1-F8:升級前先 `lumos gov --since 7` 看 missed 次數 → §2 step 4。

### 第二輪(Sonnet 對抗審計)— R1 修正經 code 驗證屬實
- R2-F2(blocker):auto-mint token 改隨機 `secrets.token_hex(4)`(時間戳秒解析度同秒會撞);§6 dedup 測試用明確 `--token`。
- R2-F4(major):寫明 argparse 結構(`canary`→sub-subparser `record`→positional `kind` choices)。
- R2-F1:`cmd_canary` 用 `env.vault.parent`(比照 cmd_gov,不額外載圖)。
- R2-F7:天花板補「canary 抓得到『沒讀』、抓不到『讀了但判錯複雜權衡』」。
- 第二輪結論:R1 修正全部 hold;審計員確認「值得做、非過度設計」(~100 行、每輪約 2 分鐘,擋掉『審計員根本沒讀』失敗模式 + gov 可查詢可靠度史)。

### 第三輪(Sonnet 對抗審計)— R2 修正全部 hold
- R3-Issue1(唯一 must-fix,一行):dedup 用 `r.get("token","")` 不可 `r["token"]`(舊事件無此鍵會 KeyError);既有 mapper 不加 token、只 canary mapper 加 → §3。
- R3-Issue3(nit):canary sub-subparser `dest="ccmd"` 寫明 → §3。
- 第三輪結論:除上述一行澄清外無 blocker/major,實作決策已全部 pin 死。

### 第四輪(Sonnet 對抗審計)— ✅ CONVERGED
- 四源 dedup 經確認 crash-free(`r.get("token","")` 對舊事件回 `""`)、argparse/dispatch 全 pin、§6 測試可直接寫。
- 唯一 nit:`ts` 用 local astimezone(已 pin,比照 governance-log)。
- 結論:**CONVERGED,implementable as-is**,審計迴圈結束。
