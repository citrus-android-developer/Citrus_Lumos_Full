# spec-conformance 審查報告：design-loop重設計_實作計畫 T1-T7 vs 真實 diff

審查方法：讀計畫全文（含 Global Constraints）→ 逐 hunk 讀 diff（scripts/lumos、scripts/test_lumos.py、
governance/eval/canary_calibration.py、skills/*、Systems/Verification 節點）→ 對照現行 repo 真碼
（diff 已是 HEAD，對應 commit 72a92b9/ba3ae1f）→ 實跑新測試驗證真綠 → 用 `lumos fold-check` 對 T5
宣稱的驗收證據做讀側複驗。〈進度〉節完全沒採信為證據，只用來定位要查哪裡。

## 逐項裁決

### 1. T1 六選配欄與寫側驗證表 —— **做了**

`cmd_canary`（scripts/lumos:637 起）逐條核對：
- `--report`/`--snapshot`：sha256 落帳、檔案存在且非空（`scripts/lumos:704-717`）。
- `--findings-set`：非空、無重複 id（`:668-674`）。
- `--folded-set`/`--accepted-set`：⊆ findings-set（`:676-679`）、folded∩accepted=∅（`:680-682`）、
  聯集＝findings-set（`:683-686`）、`severity==blocker⇒accepted 必空`（`:698-700`）。
- `--accept-reason`：鍵集合==accepted-set 且理由去空白後非空（`:687-697`）。
- 「不給不寫鍵」：`t_canary_record_disposal_fields_optional` 首斷言「★舊呼叫不變★:零新參 rc0 且無新鍵」
  實跑通過。

引句（計畫）：「折 折入計劃節點的 id 子集…聯集＝findings_set；severity==blocker ⇒ 必空(d1)」——
逐條與 code 比對皆命中。5 條 bad-case rc2 斷言＋1 條 blocker 折入合法案例，實跑 **29 個斷言全綠**
（`python3 scripts/test_lumos.py -k disposal`）。

### 2. T2 quote-check —— **做了**

- `_quote_norm`（`scripts/lumos:855`）：NFC → 剝 `*`/`` ` `` → 空白摺疊，恰一份實作；
  `grep -c "def _quote_norm" scripts/lumos` = 1（機械代理，測試 `t_quote_check_normalization_and_verdict`
  自己也做同一斷言）。
- 抽取與比對共用 `_quote_rows`（`scripts/lumos:865-873`），`quote-check` CLI 與 `--disposal` 閘的第④條
  合取都呼叫它——無第二份 regex/正規化。
- rc 語意：全 ok rc0、有 miss rc1、IO 或零引句 rc2（`cmd_quote_check`, `scripts/lumos:982-1011`）。
- 實跑 6 斷言全綠：粗體/反引號/跨行正規化 ok、編造引句 miss、零引句 rc2、快照不存在 rc2、單一實作代理。

### 3. T3 凍結快照留痕 —— **縮水（minor）**

sha256 落帳可重算、quote-check 對快照跑非現檔的反循環合約已釘死並實測
（`t_disposal_snapshot_provenance`：先證「對折入後現檔跑會假 ok」真的發生，再證「對凍結快照跑必 miss」，
3 斷言全綠）。

但計畫寫的是具體檔名慣例：

引句（計畫 T3）：「快照存 `governance/review-reports/<loop-id>/<round>-snapshot.md`、席報告存
`<round>-<席>.md`」

實際落地的 SKILL.md 只留了目錄層級的慣例，沒有檔名 pattern：

引句（skills/lumos-design-loop/SKILL.md:12）：「留痕慣例:凍結快照與席報告存
`governance/review-reports/<loop-id>/`;record 的 --report/--snapshot 指向它們」

檔名（`<round>-snapshot.md`／`<round>-<席>.md`）沒有落進任何文件或測試——純散文慣例，不是機械要求，
但計畫原文明確給了格式，屬於縮水（非阻斷；quote-check/sha256 的核心合約沒受影響）。

### 4. T4 --disposal 閘 —— **縮水（minor）**

四條合取、互斥、canary 不進合取、舊閘不動全部核實：
- 互斥：`--panel`/`--light`/`--settle`/`--need`（且額外含 `--min-seats`，比計畫列的四項更嚴，合理不算違反）
  ——`scripts/lumos:773`。
- 四條合取（G3 hash 鏈／處置集合重算／留痕讀側重驗／quote-check）：`_loop_status_disposal`
  （`scripts/lumos:876-979`），canary caught/missed 只印出不進 `fails` 列表——d4 觀測非閘核實。
- 舊路徑：`if disposal: return _loop_status_disposal(...)` 插在既有分支之間，不帶 `--disposal` 的呼叫
  路徑一行未改（`scripts/lumos:801-806` 周邊）。
- 實跑 `t_loop_status_disposal_gate`：10 個斷言全綠，含 missed 席在場照樣收斂、竄改報告必 FAIL、
  quote-check 讀側 FAIL、跨席 blocker 輪級重算 FAIL。

但計畫〈實務隱患〉明確要求的取捨記載沒有落地：

引句（計畫〈實務隱患〉）：「T4 的「舊輸出逐字節相同」斷言可能過脆…若太脆改為「rc＋判定行集合相同」，
在測試 docstring 記載取捨」

實際測試（`t_loop_status_disposal_gate`）確實用了偏鬆的驗證——`r_old.returncode == 1 and "輪有效" in
r_old.stdout`（`scripts/test_lumos.py` 對應行，非逐字節比對）——但測試 docstring 全篇沒有一句記載
「為什麼從逐字節改成 rc+子字串」這個取捨；`grep -n "逐字節\|取捨" scripts/test_lumos.py` 只命中一處
無關的舊測試（second 命令），與 T4 無關。屬於流程要求缺項，功能本身沒問題。

### 5. T5 skill 三檔與 loop next 模板 —— **縮水（minor）**

三檔皆改：`skills/lumos-design-loop/SKILL.md`（定位段+處置閘流程節）、`templates.md`（錨定紀律+抑噪例外口）、
`skills/lumos-code-loop/SKILL.md`（分流註記，未動判準本體）。`loop next` 吐 `disposal_cmd`/`disposal_gate`，
欄位名與 T1 argparse 完全一致（`--findings-set`/`--folded-set`/`--accepted-set`/`--accept-reason`/
`--report`/`--snapshot`），`record_cmd` 原樣保留給 code-loop。`t_loop_next_disposal_cmd_actually_runs`
真跑 oracle：填完佔位符後 `disposal_cmd`/`disposal_gate` 兩條指令都真的跑得動（rc0 / rc∈{0,1}），
2 個前置斷言＋2 個真跑斷言全綠。

但計畫寫的驗收條件之一沒有留下證據：

引句（計畫 T5）：「此包無新機械測試(散文),驗收＝T4 的模板真跑斷言＋fold-check 對兩份 skill 的
SSOT 掃描」

實跑 `lumos fold-check skills/lumos-design-loop/SKILL.md` 與 `lumos fold-check
skills/lumos-code-loop/SKILL.md` 現在**都是 rc1**，各自跑出 30+ 條 `reverse-omission`/`value-drift`
警告（例如 design-loop 那份：「body 有「--disposal」summary 無」等）。diff 與 Verification 節點裡都
沒有任何一句提到跑過這個掃描、或對這些警告做過 triage（很可能是因為 SKILL.md 的 frontmatter 沒有
`summary` 欄位，`fold-check` 設計給架構圖節點用、套在 SKILL.md 上大概率是雜訊）。這件事本身不影響
功能行為，但計畫寫的驗收步驟沒有被履行或記載結果。

### 6. T6 定錨收緊 —— **做了**

定錨規則：loop 首筆帶 `findings_set` 的記錄定錨（`scripts/lumos:719-733`，用「帳面是否已有一筆
`loop==loop 且含 findings_set`」判定，等同 M2 cluster「首個有效輪定錨」前例）。定錨後缺
`--report`/`--snapshot` 必 rc2；未定錨/其他 loop 不受影響——`t_disposal_loop_requires_provenance`
5 個斷言全綠，含「未定錨 loop 照舊自由」與定錨 loop／自由 loop 同庫共存的前置斷言。

### 7. T7 離線校準腳本 —— **做了**

`governance/eval/canary_calibration.py` 用 `importlib.machinery.SourceFileLoader` 直接載入
`scripts/lumos` 取 `_m._quote_norm`（`:560-564`）——不是複製第二份實作。輸出印「★寬判訊號,嚴判需人
抽驗;不進任何 gate★」的誠實聲明；預設寫入 `governance/eval/calibration-log.jsonl`（累積帳），
`--no-log` 可跳過。`t_calibration_smoke` 冒煙測試（`_need_src` 守門）2 個斷言全綠：caught/missed
判定正確、「不進任何 gate」聲明真的出現在輸出上。

### 8. 每包宣稱的新測試 —— **做了**

5+ 支測試全部存在於 `scripts/test_lumos.py` 且已實跑：

| 測試 | 斷言數 | 結果 |
|---|---|---|
| `t_canary_record_disposal_fields_optional` | 10 | ✓ 全綠 |
| `t_quote_check_normalization_and_verdict` | 6 | ✓ 全綠 |
| `t_disposal_snapshot_provenance` | 3 | ✓ 全綠 |
| `t_loop_status_disposal_gate` | 10 | ✓ 全綠 |
| `t_disposal_loop_requires_provenance` | 5 | ✓ 全綠 |
| `t_loop_next_disposal_cmd_actually_runs` | 4 | ✓ 全綠 |
| `t_calibration_smoke` | 2 | ✓ 全綠 |

`-k disposal` 群組合計 **29 個斷言全綠**、`quote_check` 群組 6 綠、`calibration` 群組 2 綠——
與計畫「T1 10 斷言／T2 6 斷言／T3 3 斷言／T4 10 斷言」的自報數字完全吻合。每支測試 docstring
都帶「★前置★ 現場成立」或「翻紅釘」性質的敘述（部分是文字記載、部分有實跑代理，如 T2 的
「單一實作機械代理」）。`python3 -m py_compile scripts/lumos governance/eval/canary_calibration.py`
通過。

## Global Constraints 核對

- **相容鐵則**：`t_canary_record_disposal_fields_optional` 首斷言 + `t_loop_status_disposal_gate`
  的「舊閘同帳照舊 FAIL」斷言都實跑通過——舊呼叫行為不變、舊閘輸出（弱化後的判準）不變。
- **舊 panel 閘一行不動**：讀 `scripts/lumos` 對應 hunk，`--panel`/`--light`/`--settle` 分支本體
  只在 `cmd_loop_status`/`cmd_canary` 簽名處新增參數，函式體未改動一行；`--disposal` 走獨立
  `_loop_status_disposal` 函式。
- **寫入 tmp→自驗→atomic**：T1 新欄沿用既有 `_jsonl_append_verified`，未新開寫入路徑。
- **假綠八型對照**：Verification 節點記載「過程抓到的新假綠變體 2 例」（T1 翻紅釘假紅、T4 測試被
  T6 咬到）；`t_canary_record_disposal_fields_optional` 的 bad-case 也在 docstring 裡明確記載這個
  修法（讓目標檢查成為唯一能翻紅的路）。

## 統計

- 做了：5（T1、T2、T6、T7、測試存在性）
- 縮水：3（T3 檔名慣例文件化缺項、T4 逐字節取捨未記載、T5 fold-check SSOT 掃描證據缺項）
- 多做：0
- 未實作：0

**max severity：minor**（三個縮水項都是流程/文件層缺項，功能本身——寫側驗證、quote-check 正規化、
disposal 四條合取、定錨強制、校準腳本——皆逐項機械核實且真跑全綠，無阻斷性缺陷）。
