# 設計:doctor Check P — 失效檔案認領(doctor-stale-file-claim)

- 日期:2026-06-30
- 狀態:design-approved
- 動機來源:2026-06-30 治理日報 gap G3「doctor 只抓孤兒筆記、不抓孤兒程式碼;架構圖×程式碼交叉審計只靠偶爾手動」。收窄後 v1 取「**B 失效認領**」:架構圖正文指向**已不存在**的檔路徑(碼被刪/改名,架構圖還指著)。
- loop_id:doctor-stale-file-claim

## 目標(一句話)

`lumos doctor` 新增**軟性 Check P**:掃每個節點正文裡「指向 repo 內檔案的路徑引用」,**檔案不存在即軟提醒**——把「架構圖指向死碼」這類漂移從偶爾手動交叉審計,變成每次 doctor 都跑的確定性檢查。**不計 issues、不改 rc。**

## 收窄決定(brainstorm,2026-06-30)

G3 字面的「孤兒程式碼=有碼沒節點」太吵(lumos 刻意只記載載重碼,多數碼本就不必有節點)。三種解讀中選 **B 失效認領**(低噪、高值、確定性);**不做** A(字面孤兒,噪音最高)與 C(改動碼沒節點的漂移提醒,v1 延後)。gate 行為選**軟提醒起步**(同 Check S/V;路徑抽取仍可能偶有偽陽性,不擋 CI)。

## 前提與既驗事實(逐字審計,2026-06-30)

- **既有「code→節點認領」靠 path/stem 提及**:`scripts/hooks/claude/check-graph-sync.py:266 find_notes_mentioning` 以「檔名 stem」反查節點提及——本 spec 沿用「節點正文提路徑」即認領的既有語義,但方向相反(掃節點→驗檔在不在)。
- **doctor 現有 [2/4] Unresolved wikilinks 只抓壞 `[[wikilink]]`**(`scripts/lumos` run_doctor 內),**抓不到節點正文 inline-code 裡指向死碼的檔路徑**——Check P 補的正是這條缺口,兩者互補不重疊。
- **doctor 落點**:`run_doctor`(`scripts/lumos:360`);Check 段尾現為 T→R→S→H→K→V(`section("V")` 在 `scripts/lumos:729`,`if ci:` 在 `:749`)。Check P 接在 V 之後、`if ci:` 之前 → 段尾變 T→R→S→H→K→V→P。
- **節點原文可讀**:`(env.vault / rel).read_text(encoding="utf-8-sig")`(load_vault 既有讀法,`scripts/lumos:173` 一帶;`:804` cmd_search 亦同模式)。`env.notes` 為節點 dict、`env.vault` 為 vault 路徑。
- **軟提醒原語**:`warn_soft(lines, head, advice)`(`scripts/lumos:384`,不計 issues、不改 rc)、`section(idx, title)`(`:369`)、`ok(msg)`(`:372`)皆 run_doctor 閉包。

## 範圍:Check P 路徑抽取與判定

**repo_root 取法**(r1-F6:沿用既有,不另造):**重用 Check C 已推導的 `repo_root`**(`scripts/lumos:518-522`,`for p in env.vault.parents: if p.name=="docs": repo_root=p.parent`)。`repo_root` 為 None(vault 不在 `docs/` 下,如 standalone vault)→ Check P 印 ok「(無 docs/ 佈局,略過失效認領檢查)」並跳過。**不引入 `git rev-parse` 新方法**(避免 run_doctor 內兩套 repo_root 推導)。

**逐節點掃**(`for rel, n in sorted(env.notes.items())`),讀該節點原文,抽「檔路徑引用」:
1. **先剝 fenced code block 再取反引號 inline-code span,並剝掉 span 的反引號定界符**(`[s.strip("`") for s in INLINE_CODE_RE.findall(FENCE_RE.sub("", text))]`)。**注意(r2-M2)`INLINE_CODE_RE`(`scripts/lumos:40`)無 capture group → `findall` 回傳含兩端反引號的字串(`` `scripts/x.py:10` ``);不 `.strip("`")` 的話 rule 2 的 `:\d+$` 與 rule 3 的頭段比對都會被反引號破壞(行號剝不掉、`first_seg` 變 `` `scripts `` 永不匹配頂層目錄 → 全偽陰性靜默)。** fenced 剝法對齊 load_vault 既有慣例(`scripts/lumos:184` 的 `FENCE_RE.sub` 順序);但 inline-code 處理相反——load_vault 是 `.sub("")` **移除** inline-code 抽 wikilink,Check P 是 `findall` **保留** span 內容,只共用「先剝 fence」這一步。
2. 對每個 span token:剝尾端 `:行號` / `:行-行`(regex `:\d+(?:-\d+)?$`,記住剝下的行號);跳過 `http://`/`https://`/含 `://` 者;**須含 `/`**(排除裸符號如 `cmd_context`,以及不含 `/` 的 `T→R→S` 之類)。
3. **第一段須是 repo_root 的現有頂層目錄**(`first_seg in {p.name for p in repo_root.iterdir() if p.is_dir() and not p.name.startswith('.')}`,r1-F7:排除 `.git/` 等隱藏目錄)——錨定真實結構;非頂層目錄起始的 token(含 inline-code 的 `maker/checker`、`and/or`)在此被擋下。
4. 解析 `repo_root / token`;**不存在** → 一條 finding `{node: rel, path: token, line: <剝下的行號或空>}`。
5. 同一節點同一路徑去重。

**輸出**:
- 有 finding → `warn_soft`,逐條(r2-m5 明定格式):有行號 → `「<rel>:<line> → <token>(已不存在)」`;無行號 → `「<rel> → <token>(已不存在)」`(不印 `:None`/空冒號)。line 帶進輸出讓人直接定位節點哪行(r1-F5)。advice=「碼被刪/改名?更新節點正文的路徑引用,或補對應節點」。
- 無 finding → `ok("無失效檔案認領 (節點引用的 repo 路徑都存在)")`。

## 邊界 / 非目標(YAGNI)

- ❌ **不做 A**(字面孤兒:碼沒節點)——噪音最高,非 v1。
- ❌ **不做 C**(改動碼沒節點的漂移提醒)——v1 延後。
- ❌ **不抓裸符號/函數名引用**(`cmd_context`、class 名)——非路徑、無法對檔案系統判存在。
- ❌ **不抓非反引號的散文路徑**——偽陽性來源,刻意只收 inline-code。
- ❌ **不抓整個頂層目錄被刪**的情形(第一段錨定會讓它落空)——罕見,v1 接受。
- ❌ **不改 rc、不擋 CI**(warn_soft);**不改** doctor 既有 `[2/4] Unresolved wikilinks` 邏輯、不碰其他 check。
- ❌ **不做語義正確性判斷**——只證「指的檔還在」,不證「節點描述仍對」。

## 測試策略

CLI subprocess 風格(`run(v, "doctor")` 斷言 stdout),`t_`-prefixed,`check()` 斷言。

**fixture 佈局(r1-F2/F6:repo_root = `docs/` 的母目錄,故 fixture 不靠 git,但須建 docs/ 佈局 + sibling 頂層目錄)**:temp_root/ 下建 `docs/<slug>-knowledge/`(vault,放節點)+ **sibling `scripts/` 目錄**(rule 3 錨定靠它存在;放 `scripts/real.py`、不放 ghost.py)。repo_root 即 temp_root。**不需 `git init`**(repo_root 用 Check C 的 `docs/` 母目錄法,非 git toplevel)。

需覆蓋:
1. **失效認領報出**:**先建 `scripts/` 目錄**(否則 rule 3 錨定不過),節點正文含 `` `scripts/ghost.py` ``(該檔不存在)→ doctor stdout 含該節點與 `scripts/ghost.py`、含 `[P]` 段。
2. **存在路徑不報**(剝行號):建真實檔 `scripts/real.py`,節點含 `` `scripts/real.py:10` `` → 不報該路徑。
3. **散文/非路徑不報**:節點反引號 `` `and/or` ``(`and` 非頂層目錄)、散文(非反引號)`maker/checker`、反引號 `cmd_context`(無 `/`)→ 皆不報。
4. **fenced block 內不抓**(r1-F3):節點含 ```` ```\n`scripts/ghost.py`\n``` ```` fenced block → 不報(先 FENCE_RE.sub 剝掉)。
5. **無路徑引用 → ok**:節點無任何反引號路徑 → Check P 印 ok。
6. **無 docs/ 佈局 → 略過**:vault 非 `docs/<slug>-knowledge` 佈局(repo_root=None)→ Check P 印「略過」ok,doctor rc 不受影響。
7. **rc 不變**:有失效認領時 doctor 仍 rc 0(warn_soft 不計 issues)。

## 知識同步影響

- `docs/methodology/架構圖即合約.md` / `對外論述.md`:可在「commit-time 強制 / doctor 巡檢」相關段補一句「doctor 亦抓架構圖指向死碼的失效檔案認領(Check P)」;無對應段則略。
- skills:`lumos-project-notes` 的 doctor 巡檢表(「健康巡檢一次到位」那段)補列 Check P;`lumos-design-loop` 無關。
- KG:落地後於 `Systems/lumos-cli-read`(doctor 屬讀/巡檢原語)summary 補一句 Check P;或新增 doctor-checks 節點(非必須,v1 放行時順手)。

## 誠實天花板

1. **死指針 ≠ 語義漂移**:Check P 只證「節點引用的檔還在」,證不了「節點對該檔的描述仍正確」(同 [test:]/[rollback:] 天花板)。
2. **路徑抽取靠 inline-code + 頂層目錄錨定**:漏裸符號引用、整頂層目錄被刪;偶有偽陽性(故軟、不擋)。**`FENCE_RE` 的 `^```` 在 MULTILINE 下只匹配行首,縮排的 fenced block(list 內 code block)不被剝**(r2-m4)→ 縮排 fence 內的路徑可能漏剝;此為 codebase 既有 FENCE_RE 行為,v1 接受(warn_soft 兜底)。
3. **B 不是 A**:Check P **不**保證「重要的碼都有節點認領」(那是 A,刻意不做);它只保證「架構圖既有的檔指針沒指空」。覆蓋率視角的「碼有沒有被記載」仍靠人 + 交叉審計(變體 B),未被本 spec 取代。

## 審計修正紀錄(design-loop)

- **r1**(canary type a:植入「§repo_root 解析與錨定規格」懸空節引用,caught):存活全 minor(辯方把 3 條 ≥major 全降),已折入:
  - **F2→minor**(辯方:正向斷言會大聲 FAIL、非 silent-pass,不是 blocker):測試策略明寫案例 1 fixture 須先建 `scripts/` 目錄。
  - **F3→minor**(辯方:FENCE_RE.sub 是 codebase 明確慣例 `scripts/lumos:184`、實作必沿用;偽陽性窗口窄):rule 1 補「先剝 fenced block」+ 測試案例 4。
  - **F4→minor**(辯方:純散文括號誤植過濾功勞,pipeline 輸出正確無 bug):rule 1 措辭改述、例子移到真正生效的 rule 2/3。
  - **F5 [minor]**:輸出帶上 line(`<rel>:<line> → <token>`)。
  - **F6 [minor]**:repo_root 改用 Check C 既有推導(`docs/` 母目錄),不引入 git rev-parse 新方法;測試 fixture 連動(不需 git、須 docs/ 佈局)。
  - **F7 [minor]**:rule 3 頂層目錄排除隱藏目錄(`.git/` 等)。
  - **F8 [minor]**:邊界節「Check 2」正名為「[2/4] Unresolved wikilinks」。
- **r2**(canary type b:植入未定義旗標 `--skip-stale-claim`,caught):**收斂輪**,存活全 minor,已折入:
  - **M2→minor**(辯方實測:故障鏈反了——反引號頭尾殘留 → rule3 全擋 → 全偽陰性靜默,非全偽陽性;且測試案例1正向斷言會 FAIL 接住):rule 1 補「`.strip("`")` 剝定界符」+ 點明 INLINE_CODE_RE 無 capture group。
  - **m3 [minor]**:rule 1 釐清「對齊慣例」僅指先剝 fence,inline-code 處理與 load_vault `.sub` 相反;行號引用 INLINE_CODE_RE 定義在 `:40`。
  - **m4 [minor]**:誠實天花板補「FENCE_RE `^` 只匹配行首,縮排 fenced block 不被剝」。
  - **m5 [minor]**:輸出格式明定無行號時不印 `:None`。
  - **m6 [minor]**:節點讀法引用改 `:173`(load_vault),`:804` 為 cmd_search 同模式。
