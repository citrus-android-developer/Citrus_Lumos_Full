# 設計:Check P v2 精度精煉(check-p-precision-v2)

- 日期:2026-06-30
- 狀態:design-approved
- 動機來源:Check P(失效檔案認領)v1 落地後在真 vault 跑出 15 條,**全是噪音**(pattern/glob/占位/符號錨),真 drift = 0 → 一個近乎全噪音的軟提醒會被無視。v2 精煉抽取規則把噪音清掉,讓 check 有用。
- loop_id:check-p-precision-v2

## 目標(一句話)

精煉 `lumos doctor` Check P 的路徑抽取:**跳 glob/模板 token + 一般化後綴剝除**,把真 vault 的 15 條噪音降到 1 條真指針(`scripts/rot-eval/`),其餘 rule 不動。純降噪、可逆。

## 前提與既驗事實(2026-06-30 真 vault 實測)

Check P v1(已合進 main,`994b404`)在本 repo 跑出 15 條,逐條歸類**全非真 drift**:
- **glob/模板**:`governance/pending/*.md`、`governance/reports/*`、`docs/*-knowledge`、`docs/<slug>-knowledge/`、`governance/reports/governance-<date>.json`、`governance/pending/<date>-<topic>.md`、`docs/knowledge/`——pattern 描述,非字面檔。
- **符號/中文錨**:`scripts/lumos:行號`(中文占位)、`scripts/test_lumos.py:t_check_h_irreversible_hint`(`:測試名` 錨;**檔本身存在**)——v1 的 `:\d+(?:-\d+)?$` 只剝數字行號,非數字後綴留著 → token 解不開 → 誤報。
- **真指針(planned)**:`scripts/rot-eval/`(`verification-rot-eval` 是 `[planned]` 節點,子目錄未建)——唯一「架構圖指向不存在路徑」的真實項。

v1 抽取現況(`scripts/lumos` Check P 區段,rule 2):`_line_re = re.compile(r":\d+(?:-\d+)?$")`;剝行號後直接進 rule 3。

## 範圍:兩條抽取精煉(只動 rule 2 一帶)

### ① 跳 glob/模板 token(新增,在 rule 2 的過濾鏈)

token(剝定界符後)含 `*`、`<`、`>`、`?` 任一 → **skip**(glob/模板 pattern,非字面路徑)。放在「含 `/`」「頂層目錄錨定」等檢查的同一過濾段。

### ② 一般化後綴剝除(改 rule 2 的行號剝除)

把「只剝數字行號」改成「剝任何尾端 `:<非斜線後綴>` 做存在檢查;僅當後綴是純數字才當行號顯示」:
- `m = re.search(r":([^/]+)$", token_full)`;有 match → `token = token_full[:m.start()]`、`sfx = m.group(1)`;`line = sfx if re.fullmatch(r"\d+(?:-\d+)?", sfx) else ""`。無 match → `token = token_full`、`line = ""`。
- 效果:`scripts/lumos:行號` → token `scripts/lumos`(存在,不報)、line 空;`scripts/test_lumos.py:t_check_h…` → token `scripts/test_lumos.py`(存在,不報);`docs/foo.py:10`(真死指針)→ token `docs/foo.py`、line `10`、輸出顯示 `:10`。
- `://` 跳過仍在 ② 之前(`http://` 不受影響)。

**其餘 rule 不動**:剝 fenced + 反引號定界符(rule 1)、含 `/`、頂層目錄非隱藏錨定(rule 3)、`(repo_root/token).exists()`(rule 4)、同節點去重(rule 5)、warn_soft 不改 rc、repo_root 重用 Check C、輸出格式(有/無行號)全照 v1。

## 邊界 / 非目標(YAGNI)

- ❌ **不跳 [planned]/[deferred] 節點**——`scripts/rot-eval/` 留著報(真指針、1 條低噪音;落地後自消)。
- ❌ **不特殊處理尾端 `/` 目錄 token**——目錄不存在仍是真指針。
- ❌ **不改其餘 rule、不改 rc、不碰其他 check**。
- ❌ glob 字元集只取 `* < > ?`(觀測到的 + glob `?`);不擴及 `[` `]`(罕見、且 KG 未見)。

## 測試策略

沿用 v1 的 `_mk_docs_vault` fixture(docs/<slug>-knowledge + sibling scripts/,不需 git)。新增/補:
1. **glob 不報**:節點含 `` `governance/pending/*.md` ``、`` `docs/<slug>-knowledge/` ``(含 `*`/`<>`)→ 不報(需先建 `governance/` 頂層目錄讓 rule 3 不先擋,確保是 glob 過濾在起作用)。
2. **符號/中文錨且檔存在 → 不報**:建 `scripts/real.py`,節點含 `` `scripts/real.py:t_some_test` ``、`` `scripts/real.py:行號` `` → 不報(後綴剝除 + 檔存在)。
3. **真死指針帶數字行號 → 報且顯示行號**:節點含 `` `scripts/ghost.py:10` ``(ghost 不存在)→ 報、輸出含 `:10`。
4. **回歸**:v1 既有 7 案例仍綠(尤其案例 1 `scripts/ghost.py` 仍報、案例 2 `scripts/real.py:10` 仍不報)。

## 知識同步影響

- skill/方法論/KG:Check P 的對外描述(「節點正文 inline-code 路徑指向不存在檔」)不變,**無需改**;v2 只精煉內部抽取精度。
- 可選:`docs/design/2026-06-30-doctor-stale-file-claim.md` 的誠實天花板補一句「v2 已加 glob/符號錨降噪」(放行時順手,非必須)。

## 誠實天花板

1. **後綴剝除變貪婪**:剝任何尾端 `:<非斜線>` → 理論上誤剝「合法以 `:x` 結尾的路徑」;但 repo 路徑不含冒號(只當行號/符號錨),可接受。
2. **glob 跳過 = 放棄檢查 pattern 描述的路徑**:若某 glob 模式對應的目錄真的整個不存在,v2 不再報(換得降噪)。低風險、可接受。
3. **仍只證「指的檔還在」**,不證語義正確(同 v1 天花板)。
