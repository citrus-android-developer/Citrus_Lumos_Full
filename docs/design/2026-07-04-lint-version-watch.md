# lint-version-watch 設計(pitfalls-lint-integration 第②塊)

> 計劃節點:[[Projects/pitfalls-lint-integration_計劃]] 第②塊「每日 linter 版本/新規則偵測」。地基=第①塊 lint-adapter(已 merge)。

## 目標(一句)

每日排程機械偵測「專案宣告的社群 linter 有沒有新的穩定版」→ 落後即產「該升級 X」候選 → 走輕量放行紀律(暫存 + LINE 通知 + 人放行),**只做版本偵測、不自建規則差異比對**。

## 動機 / 定位

第①塊讓 pitfalls 吃社群 linter(SARIF),但 linter 會出新版、新版常帶新規則(= 新的偏科坑覆蓋)。專案鎖定版一旦落後,就吃不到新規則、也可能有已修的誤報。第②塊補這個「維護面」:機械盯 registry 最新穩定版 vs 專案鎖定版,落後就提醒人升級。

**核心認知**:版本偵測是**機械任務**(registry JSON API → semver 比較),符合本專案「機械 > LLM」「composition over invention」哲學。**「新規則」不自己逐工具比對**——那要 per-tool 解 changelog/rule-registry,高工、易腐化(正是第①塊「規則庫讓給社群」的教訓)。新版本**本身就是信號**:候選叫人去審該版 changelog。做「新版偵測」,不做「新規則 diff」。

## 為什麼需要新宣告檔(不能重用 lint.json)

第①塊的 `.lumos/lint.json` 是 `{副檔名: [含 {LINT_SARIF_OUT} 的 shell 指令]}`——指令是**不透明字串**(可能是 detekt jar 路徑、`npx eslint`、`dotnet build`)。**無法可靠從任意 shell 指令抽出「工具身分 + 鎖定版 + 該查哪個 registry」**。所以第②塊需要一份**顯式 watch 清單**,把「查什麼」講清楚(宣告是專案責任,同 lint.json 哲學)。

## 架構

兩層,沿本專案既有分工(機械核心在 `scripts/lumos`、排程/通知在 `governance/`):

1. **機械核心**:`scripts/lumos` 新增 `lint-watch` 子命令(vault-free、可測、rc 語意,同 `refcheck`/`pitfalls`)。讀 watch 清單 → 查各 registry 最新穩定版 → semver 比較 → 落後者輸出候選 manifest(`--json`)。HTTP 抓取層可注入(測試用 fixture,不打真網路)。
2. **治理排程層**:**governance/lint-watch-check.sh** 掛進 `daily-governance.sh` wrapper 第 3 步(單一喚醒窗)。跑 `lumos lint-watch` → 對新候選(seen-ledger 去重,每個新版只通知一次)LINE 通知 + 暫存到 **governance/lint-upgrades/**。人放行。去重比對本體在可測的 python helper(見〈治理排程層〉),shell 只做接線。

### 為什麼不走既有 backlog→orchestrator→design-loop 管線

升級候選是**操作型**(「把 detekt 1.23.7 → 1.24.0」),不是**設計 gap**。既有自主 loop 管線(`gap_select`→orchestrator→design-loop)是拿來 brainstorm **設計 spec** 的——對「bump 版本」用錯工具(不需要 design-loop、不需要 spec)。第②塊**重用「放行紀律」的形狀**(暫存 + 人放行 + LINE),**不重用 design-spec orchestrator**。獨立輕量路徑。

## 產出物清單(本 spec 建立)

- `scripts/lumos` 新增 `lint-watch` 子命令 + helper(`_semver_parse`/`_is_prerelease`/`_compare_versions`/`_registry_latest`/`_http_get_json`)。
- **governance/lint-watch-check.sh**(治理排程 shell,掛 wrapper 第 3 步)。
- **governance/autonomous_loop/lint_watch_dedup.py**(seen-ledger 去重 helper,可單元測)。
- **governance/lint-upgrades/**(暫存目錄:`pending-<DATE>.json` + `seen.jsonl`)。
- 測試:`scripts/test_lumos.py`(機械核心)+ `governance/autonomous_loop` 既有 test harness(去重 helper)。

## 資料契約

### 宣告檔 `.lumos/lint-watch.json`(專案根,選配;缺 = 無 watch)

```json
[
  {"name": "detekt", "registry": "github:detekt/detekt", "current": "1.23.7"},
  {"name": "eslint", "registry": "npm:eslint",            "current": "8.57.0"},
  {"name": "ruff",   "registry": "pypi:ruff",             "current": "0.4.2"},
  {"name": "sonar",  "registry": "maven:org.sonarsource.scanner.cli:sonar-scanner-cli", "current": "5.0.2.4997"}
]
```

- `name`:人可讀識別(通知/候選顯示用)。
- `registry`:`<type>:<coord>`。type ∈ `{pypi, npm, maven, google-maven, github}`:
  - `pypi:<pkg>` → `GET https://pypi.org/pypi/<pkg>/json` → `info.version`。**注意 `info.version` 可能是 PEP 440 prerelease**(如 dev/nightly 通道無穩定版時),見〈prerelease 處理〉。
  - `npm:<pkg>` → `GET https://registry.npmjs.org/<pkg>/latest` → `version`(latest dist-tag = 最新穩定)。
  - `maven:<group>:<artifact>` → 查 Solr,**q 參數值必須 `urllib.parse.quote`**(雙引號→`%22`):`https://search.maven.org/solrsearch/select?q=` + `quote('g:"<group>" AND a:"<artifact>"')` + `&core=gav&sort=timestamp+desc&rows=20&wt=json` → 取 `data["response"]["docs"]`(**完整 JSON 巢狀在 `response` 下,非頂層 `docs`**,r2 認)每筆 `["v"]`、過濾 `_is_prerelease` 者 → **以 `_semver_parse` tuple 為 key 取數值最大**(**嚴禁 `max()` 字串比較**——r2 辯方實測 commons-lang3 字串 `max` 回 `3.9` 而非真 latest `3.20.0`)。**未編碼的字面 `"` 會被 Solr 回 HTTP 400**(r1 辯方實測);`sort=timestamp+desc` 確保高版本數 artifact 的 latest 在 rows 窗內(r2 辯方:預設 relevance 排序 + 字串 max 才是病灶)。
  - `google-maven:<group>:<artifact>` → **Google Maven(dl.google.com),非 Maven Central**(v1.1 補;KDS 真機坐實 `maven:` 對 AGP 靜默假陰性)。`GET https://dl.google.com/dl/android/maven2/<group 以 . 換 />/<artifact>/maven-metadata.xml`(**回 XML 非 JSON**,需 `xml.etree.ElementTree` + 新 `_http_get_text` 抓取層)→ 迭代 `<versions><version>` 全清單、過濾 `_is_prerelease` 與 `_semver_parse` None、**數值 tuple max**。**⚠ 陷阱**:`<latest>`/`<release>` tag **可能是 prerelease**(真機:AGP `<latest>`=`9.4.0-alpha03`)——**嚴禁直接用 `<latest>`**,必須走 versions 清單過濾後取數值 max(真機:AGP 穩定 max=`9.2.1`)。過濾後空 → `(None,"no stable version")`。適用 AGP / AndroidX / 多數 Google-hosted artifact。
  - `github:<owner>/<repo>` → `GET https://api.github.com/repos/<owner>/<repo>/releases/latest` → `tag_name`(GitHub `/latest` 已排除 prerelease/draft;剝前綴 `v`)。
- `current`:專案目前鎖定版。**必須與該 registry 的版本格式同方案、同精度**(段數一致——見〈semver 比較〉的等段數守衛);人放行升級後手動 bump 此欄。

### 候選 manifest(`lumos lint-watch --json` stdout)

```json
{
  "candidates": [
    {"name":"detekt","registry":"github:detekt/detekt","current":"1.23.7","latest":"1.24.0"}
  ],
  "checked": 3,
  "failed": [{"name":"sonar","reason":"registry query failed: timeout"}]
}
```

- `candidates`:僅列落後條(latest 可解析、與 current 等段數、且嚴格大於 current)。**不含 `behind` 欄**(candidates 恆為落後條,布林恆真無資訊)。
- `checked`:**成功查到 latest 並完成比較的條數**(不含 failed)。上例 4 條宣告、1 條 failed → checked=3。
- `failed`:查詢/解析失敗、或等段數守衛擋下(current/latest 段數不一致、prerelease、非數字段)的條目 `{name, reason}`。fail-open,不列入候選、不升 rc。

### 暫存 + 去重(治理層)

- 候選暫存:**governance/lint-upgrades/pending-<YYYY-MM-DD>.json**(當日新候選快照)。
- 去重 ledger:**governance/lint-upgrades/seen.jsonl**,一行一個已通知過的升級 `{"name":..,"latest":..,"seen":"YYYY-MM-DD"}`。**通知只對 `(name, latest)` 未在 seen 的候選發**(每個新版只通知一次,不每天洗版)。
- **seen 寫入時機**:候選一旦暫存即寫 seen(**不論 LINE 是否成功**)——通知是 best-effort,seen 記的是「已處置過此升級」,避免缺 token 時每天重打。缺點是缺 token 那次人收不到 LINE,但 `pending-<DATE>.json` 仍留檔可查(接受:token 缺是設定問題,pending 檔是兜底)。
- 人放行 = ① 把 `.lumos/lint-watch.json` 的 `current` bump 到 latest(並實際更新 lint.json 對應指令的版本)② 候選自然不再落後。seen 保留(冪等)。

## 機械核心細節(**scripts/lumos** 的 lint-watch 子命令)

### CLI 接線(沿既有 subcommand 慣例,同 refcheck)

- `sub.add_parser("lint-watch")`;`--repo`(dest=`lint_watch_repo`,預設 `.`);`--json`(store_true)。無位置參數——清單固定讀 `<repo>/.lumos/lint-watch.json`。
- dispatch:`if args.cmd == "lint-watch": ...`,**須置於 `vault = args.vault or find_vault(...)` 之前**(vault-free,同 `refcheck`/`pitfalls`/`anchor`;置於其後會對無 `docs/*-knowledge/` vault 的專案報「找不到 vault」而失效)。非 `--json` 時印人可讀摘要(每候選一行 `<name> <current> → <latest>`),`--json` 時印上述 manifest。

### semver 解析與比較

- `_semver_parse(v) -> tuple|None`:剝前綴 `v`;`split('.')`;**每段須為純數字**(`str.isdigit()`),任一段非純數字 → None(不猜、不做 prerelease 切段——prerelease 由 `_is_prerelease` 先擋,`_semver_parse` 只接純數字點分)。回 `(n, ...)`。
- `_is_prerelease(v) -> bool`:涵蓋兩種慣例——① 含 `-`(SemVer prerelease,如 `1.24.0-RC1`);② PEP 440 dashless 後綴,**release 數字段後**接 `a`/`b`/`c`/`rc`/`alpha`/`beta`/`dev`/`pre`(可再接數字)。正則:`re.search(r'(?:\d|[-._])(a|b|c|rc|alpha|beta|dev|pre)\d*(?:$|[-._\d])', v_lower)` 或含 `-`。**前綴分隔符不可 optional**(r3 認:`(?:...)?` 會讓 `a/b/c` 匹配任意字串中段,如 `cobra`→True 假陽性;要求標記前必為數字或分隔符)。**r1 辯方坐實 `'-' in '0.5.0b1'` 為 False**,單靠 `-` 會漏 PEP 440 prerelease。正則行為以測試釘死(見〈測試策略〉正/負例);實作可微調正則,但須通過那組案例。**殘留限制**:極少見非標準寫法可能漏判——但 npm/github `/latest` server-side 排除、pypi/maven 標準寫法涵蓋,列天花板不硬追。以測試案例為準,不在 spec 窮舉正則所有邊角。
- `_compare_versions(current, latest) -> (state, reason)`:**回三態**(非 bool——bool 無法區分「未落後」與「守衛擋下」,r2 辯方指出 bool 承載不了 failed 分流):
  - `state ∈ {"behind","current","skip"}`;`reason` 僅 skip 時非空。
  - 任一 `_is_prerelease` 為真 → `("skip","prerelease")`。
  - 任一 `_semver_parse` 為 None → `("skip","unparseable")`。
  - **等段數守衛**:兩 tuple 長度不同 → `("skip","segment-count-mismatch")`。同時擋掉 calendar `2024.1`(2 段)vs `1.23.7`(3 段)、Maven 3 段 current vs 4 段 registry(`5.0.1` vs `5.0.1.3006`)兩類假陽性(r1 辯方坐實)。
  - `latest_tuple > current_tuple` → `("behind","")`;否則 → `("current","")`。
- 呼叫端據三態分流:`behind`→candidate、`current`→計入 checked、`skip`→ `failed[]` 記 reason(非靜默丟)。checked = behind + current 條數。

### prerelease 處理(依 registry)

prerelease 過濾在 `_registry_latest` 內做(回 `(None, reason)`),不到 `_compare_versions` 才擋:
- pypi:`info.version` 若 `_is_prerelease` → 回 `(None, "latest is prerelease")`;不改抓其他版(pypi json 的 `releases` 全量過濾成本高、YAGNI,dev/nightly 通道非本工具目標)。
- npm/github:`/latest` 端點本就排除 prerelease;若仍拿到 prerelease(異常)→ 同 pypi 回 `(None, "latest is prerelease")`。
- maven:`data["response"]["docs"][].v` 過濾掉 `_is_prerelease` 者後、以 `_semver_parse` tuple 為 key 取數值最大(非字串 max);過濾後空 → 回 `(None, "no stable version")`。
- `_compare_versions` 的 `_is_prerelease` 守衛保留為防禦(擋 `current` 被宣告成 prerelease 的少見情形);happy path 的 latest 已在 `_registry_latest` 濾過。

### HTTP 抓取層(可注入,測試不打網路)

- `_http_get_json(url) -> dict|None`:`urllib.request`(timeout 10s、`User-Agent: lumos-lint-watch`);非 2xx / 例外 / 非 JSON → None(fail-open)。
- `_http_get_text(url) -> str|None`(v1.1,給 google-maven XML 用):同 `_http_get_json` 但回原始文字(decode utf-8)、不 `json.loads`;fixture 模式(`LUMOS_LINT_WATCH_FIXTURE`)下 `fixture.get(url)` 預期是**字串**(XML 文字),JSON 型的 fixture 值仍是 dict——fixture 檔可混存(依 url key 區分)。fail-open 同 `_http_get_json`。
- `_registry_latest(registry, fetch=_http_get_json) -> (str|None, str|None)`:**回 `(latest, reason)` 二元組**——成功回 `(版本字串, None)`;失敗回 `(None, reason)`。**單一 `None` 承載不了三種失敗原因**(網路失敗 / prerelease / 無穩定版),故用二元組帶 reason(r3 認)。reason ∈ `"registry query failed: <e>"` / `"latest is prerelease"` / `"no stable version"`。呼叫端:`latest` 非 None → 進 `_compare_versions`;None → 該條 `failed[]` 記 reason。
- **測試 seam(端到端可測的具體機制)**:環境變數 `LUMOS_LINT_WATCH_FIXTURE=<json 檔路徑>` 存在時,`_http_get_json` **不打網路**,改讀該 fixture 檔(內容 = `{url: response_dict}` 映射,依 url 回對應假 response;無對應 key → None)。production 無此環境變數即走真 `urllib`。此 seam 讓 `test_lumos.py` 以 subprocess 跑真 CLI + fixture 驗完整 `--json` 管線(subprocess 無法注入 python 函式,故用環境變數 + 檔案)。

### rc 語意

- 全部查完(含部分 failed)= 0;`.lumos/lint-watch.json` 缺 = 0(無 watch、輸出空 candidates,非錯);**空 list `[]` 同缺檔**(rc 0、空 candidates,非格式錯)。
- 清單存在但**格式壞**(非 JSON list / 條目非 dict / 缺 `name`/`registry`/`current` 必填欄)= 2。
- **網路失敗永不升 rc**(fail-open)。

## 治理排程層(**governance/lint-watch-check.sh** + `lint_watch_dedup.py`)

- 掛進 `governance/daily-governance.sh` 第 3 步(在報告、autonomous-loop 之後;wrapper `set -uo pipefail` 無 `-e`,本步失敗不影響前兩步)。
- **repo 根探法**:同 `autonomous-loop.sh`——`SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`、repo 根 = `$SCRIPT_DIR/..`(shell 在 `governance/` 下)。
- **shell 變數初始化**:`REPO="$SCRIPT_DIR/.."`;`DIR="$REPO/governance/lint-upgrades"`;`mkdir -p "$DIR"`;`SEEN="$DIR/seen.jsonl"`;`PENDING="$DIR/pending-$TODAY.json"`(**全檔路徑,非目錄**);`TODAY=$(date +%Y-%m-%d)`。
- **去重 helper** `lint_watch_dedup.py`(**所有 JSON 讀寫都在 python;shell 完全不解析/組裝 JSON**——r4 認 shell 組 JSON 破格、r5 認 shell 也不該解析 JSON):
  - 純函式 `new_candidates(candidates, seen_path) -> list`——讀 `seen.jsonl`(**檔不存在 → 視為空 seen、回全部候選**,首跑無 seen.jsonl 是常態)、回 `(name, latest)` 不在 seen 的候選(單元測對象)。
  - **`__main__` 契約(把 ①②③ 的 JSON 側效全收進 python,shell 只判空字串)**:`python3 lint_watch_dedup.py <seen_path> <pending_path> <today>`,**stdin 讀** `lumos lint-watch --json` 全量 manifest。行為:算 new candidates → 若非空:**① 寫 `<pending_path>`**(JSON array of `{name, registry, current, latest}`)**② append `<seen_path>`**(每筆 `{name, latest, seen:<today>}`)**③ stdout 印**組好的完整 LINE API dict `{"messages":[{"type":"text","text":"🔧 lint 升級候選(<N>):\n<name> <current>→<latest>(<type>)\n..."}]}`(`<type>`=`registry.split(":",1)[0]`;`json.dumps` 自動轉義 `\n`/emoji);若 new 為空 → 不寫檔、stdout 印空字串。
  - `__main__` **stdin 非 JSON 容錯**:`lumos lint-watch` rc=2 時 stdout 是錯誤訊息非 JSON → `__main__` 包 `json.load` 於 try/except `JSONDecodeError`,失敗印空字串乾淨退出(不 traceback)。
  - shell 只需(**直接 pipe、不經中間檔;沿 `autonomous-loop.sh` 的雙引號 `-c` + `sys.path` 慣例**):
    ```bash
    MSG=$(lumos lint-watch --repo "$REPO" --json | python3 "$REPO/governance/autonomous_loop/lint_watch_dedup.py" "$SEEN" "$PENDING" "$TODAY")
    TOKEN_FILE="$HOME/.config/ai-daily/line_token"
    if [ -n "$MSG" ] && [ -f "$TOKEN_FILE" ]; then
      MSG="$MSG" python3 -c "import os,json,sys; sys.path.insert(0,'$REPO/governance'); from autonomous_loop import line_notify; line_notify.send(json.loads(os.environ['MSG']), open('$TOKEN_FILE').read().strip())"
    fi
    ```
    (**shell 把 `$MSG` 當不透明字串傳,不解析 JSON**;token 缺檔 → 跳過不失敗。)
  - ⚠ 此 `MSG` 用法**與 `autonomous-loop.sh` 不同**:那邊 `MSG` 是純文字經 `build_message` 包裝;這邊 `MSG` 已是 `json.dumps` 過的完整 dict、python 端 `json.loads` 後直接 `send`(跳過 `build_message`,領域不符)。**`send` 內部再 `json.dumps` POST broadcast(r2 認)**。
- 本步任何失敗只 log、rc 不外傳(wrapper 不 `-e`)。

## 實務隱患

- **併發**:daily wrapper 單一喚醒窗序列跑,無並發;seen.jsonl 單寫者(本步),無競爭。
- **冪等**:seen-ledger 保證每個 `(name,latest)` 只通知一次;重跑同日不重複通知(pending-<TODAY> 覆寫、seen 去重)。
- **資源**:HTTP timeout 10s、每 registry 一次呼叫、watch 清單通常個位數條 → 無熱路徑、無大資料。urllib response 讀完即釋放。
- **外部依賴**:registry API 可用性 = 外部;fail-open 確保單一 registry 掛不影響其他條與 wrapper。
- **rate limit**:GitHub 未認證 API 有速率限(60/hr/IP);watch 清單個位數 + 每日一次 → 遠低於限。

## 錯誤處理

- registry 單條失敗 → `failed[]`、跳過、續查其他(fail-open)。
- watch 清單缺 → rc 0 空候選(常態:沒宣告就沒事)。
- watch 清單格式壞 → rc 2(宣告錯要人修)。
- LINE token 缺 / broadcast 失敗 → log 跳過,不阻斷;pending 檔仍留。
- 網路整體不通 → 全部 failed、0 候選、rc 0、wrapper 續跑。

## 測試策略

機械核心(`scripts/test_lumos.py`,注入 fixture、不打網路):
1. `_semver_parse`/`_compare_versions`:`1.23.7` vs `1.24.0`→behind;反向→current;相等→current;`v1.2.3` 前綴剝除;非 semver 段(亂字串)→ parse None → skip(unparseable);**等段數守衛**:`2024.1`(2 段)vs `1.23.7`(3 段)→ skip(segment-count-mismatch);`5.0.1`(3 段)vs `5.0.1.3006`(4 段)→ skip。**數值排序見證(同段數)**:`1.9.0` vs `1.20.0` → behind(證非字串比較——字串 `1.9.0`>`1.20.0` 但數值 `(1,9,0)<(1,20,0)`;跨段數的 `3.9`/`3.20.0` 數值 max 見證屬 Maven 選取,見 §測試 3)。
2. `_is_prerelease`:**正例** `1.24.0-RC1`/`0.5.0b1`(PEP 440 dashless)/`2.22.0.dev20260702`→True;**負例(不可假陽性)** `1.24.0`/`5.0.2.4997`/`cobra`(字母中段無數字/分隔前綴)→False。
3. `_registry_latest`(回 `(latest, reason)` 二元組)四型:fixture 餵各 registry JSON 形狀(pypi info.version / npm version / maven `data["response"]["docs"][].v` 過濾後**數值** max / github tag_name **剝 `v` 前綴**驗)→ 正確抽出回 `(版本, None)`;**pypi info.version 為 prerelease(如 `0.4.3a1`)→ 回 `(None, "latest is prerelease")`**;maven prerelease 過濾 + 數值 max 見證(docs 含 `3.9`/`3.20.0`/`RC` → 回 `3.20.0`);maven 過濾後空 → `(None, "no stable version")`;抓取回 None(例外/欄位缺)→ `(None, "registry query failed: ...")`。
4. `lint-watch --json` 端到端(subprocess 跑真 CLI + `LUMOS_LINT_WATCH_FIXTURE` + 臨時目錄當 `--repo` 根[**無 git 互動**,lint-watch 不碰 git]+ `.lumos/lint-watch.json`):落後條進 candidates、**skip 三路徑各一 fixture 條進 failed 且 reason 對**(prerelease / unparseable / segment-count-mismatch,非只測最易觸發的一條)、**已是最新條(current)計入 checked 但不進 candidates/failed**、checked 計數 = behind+current 條數。
5. rc:缺清單→0 空候選;**空 list `[]`→0 空候選**;壞清單(非 list / 缺必填欄)→2;全條 fixture-fail→rc 0(fail-open)。

治理層:`lint_watch_dedup.new_candidates` 單元測(候選 + seen → 新候選集,含 ① 空 seen(**含 seen.jsonl 不存在**)② 全已見 ③ 部分新 ④ **同 name 但新 latest**(seen 有 `detekt/1.23.7`、候選 `detekt/1.24.0` → 算新,證去重 key 是 `(name,latest)` 非僅 `name`)四例);`__main__` 側效測(餵 manifest → 驗 `pending_path` 寫出正確 array、`seen.jsonl` append 正確、stdout 為完整 LINE dict;無新候選 → 不寫檔、stdout 空);LINE `send` 重用既有、不重測;shell 接線以 `lint_watch_dedup` 的 `__main__` 契約為準。

## 知識同步影響

| 受影響文件 | 需同步什麼 |
|---|---|
| `skills/lumos-project-notes/SKILL.md` | 指令表補 `lint-watch`(vault-free 版本偵測、rc 語意、`.lumos/lint-watch.json` 宣告) |
| `docs/methodology/架構圖即合約.md` | pitfalls 列補「版本偵測(lint-watch)——機械盯 registry 新穩定版」 |
| `Projects/pitfalls-lint-integration_計劃` | 第②塊 status → done + verified_by 回指落地 Verification |
| `governance/daily-governance.sh` 頭註 | 補第 3 步 lint-watch-check |

## 天花板 / 誠實邊界

1. **只驗「有沒有新版」,不驗「新版好不好 / 該不該升」**——升級決策(相容性、破壞性變更)是人的事,候選只搬信號到人眼前。
2. **不做 per-tool 新規則 diff**——新版是信號,changelog 由人審。
3. **registry 端點語意依賴上游**(pypi info.version / github /latest 排除 prerelease 的行為);上游改語意本偵測會失準——記進 valid_under。
4. **watch 清單靠人維護**(bump current);清單漂移(實際升了沒 bump)會漏報,同 lint.json「宣告是專案責任」的既有限制。
5. **版本比較是純數字 tuple + 等段數守衛**:current 必須與 registry 同版本方案、同段數宣告;段數不一致 / prerelease / 非數字段 → 進 failed 不猜(不會假陽性,但也不會跨方案比較)。calendar/hash 等非 semver 方案不支援。

## 審計修正紀錄(design-loop)

### R1(2026-07-04,canary type a=壞章節交叉引用(指向不存在的錯誤碼對照表節),sonnet,**CAUGHT**,辯方裁決後 severity=blocker,存活 findings=11)

canary 被正確識別(dangling pointer,全文無此節)。此輪 sonnet 紮實挖出真缺口,辯方(opus)對 3 條經驗性 ≥major 全實測**維持**(refute 不能):
- **B-2 blocker(折)**:Maven Solr URL 字面 `"` urllib 送出回 HTTP 400(辯方實測 `%22` 編碼才 200)→〈registry 端點〉改 `urllib.parse.quote` 編碼 q 值。
- **M-2 major(折)**:PyPI `info.version` 可為 PEP 440 prerelease(dev/nightly),`-` filter 漏抓(辯方實測 `'-' in '0.5.0b1'`=False)→ 新增 `_is_prerelease` 涵蓋 dashless PEP 440 後綴。
- **M-4 major(折)**:calendar `2024.1` 解析成全 int tuple、`(2024,1)>(1,23,7)`=True 假陽性,與天花板5 矛盾(辯方實測)→ 加**等段數守衛**(段數不一 → failed),一併解 m-2 的 4 段 Maven 假陽性;天花板5 改為誠實描述。
- **M-1 major(折)**:`checked` 定義(成功條數)與範例值(4,含 1 failed)矛盾 → 範例改 3、定義明確化。
- **M-3 major(折)**:LINE 通知訊息格式未定義、`build_message` 領域不符 → 明定批次訊息格式 + 只重用 `send()`。
- **M-5 major(折)**:端到端 fake-fetch 注入機制「環境或測試 hook」未定義(subprocess 無法注入 python)→ 明定 `LUMOS_LINT_WATCH_FIXTURE` 環境變數 + fixture 檔 seam。
- **m-1(折)**:seen 寫入 vs 通知失敗時序未定 → 明定「暫存即寫 seen,不論 LINE 結果」。
- **m-3(折)**:`lint-watch` argparse 接線未定 → 補 CLI 接線節。
- **m-4(折)**:去重 python 位置未定 → 明定 `lint_watch_dedup.py` helper + 進產出物清單。
- **m-5(折)**:`behind:true` 恆真冗餘 → 從 candidate schema 移除。
- **m-2(折,併入 M-4)**:4 段 Maven vs 3 段 current 假陽性 → 等段數守衛涵蓋。
存活 11 條全折入。

### R2(2026-07-04,canary type b=未定義旗標 `--skip-prerelease-check`,sonnet,**CAUGHT**,辯方裁決後 severity=blocker,存活 findings=8)

canary 性質被點出(旗標引入卻不在 CLI 接線/rc/schema/測試——依規不折)。此輪挖出 r1 折入後新生的可執行性缺口:
- **B-1 blocker(折)**:`_semver_behind -> bool` 無法承載三態(behind/current/skip),`failed[]` 分流不可實作 → 改 `_compare_versions -> (state, reason)` 三態、呼叫端分流。
- **Maven latest 選取 major(折,M-1+M-2 併)**:r2 辯方實測——排序 sub-claim 反證(Solr 預設 timestamp desc、latest 在窗內),但**字串 `max` 病灶為真**(commons-lang3 字串 max 回 `3.9` 非 `3.20.0`)→ 改 `sort=timestamp+desc` + `_semver_parse` tuple 數值 max、嚴禁字串比較。
- **M-4 major(折)**:`_semver_parse`「見下 prerelease 切法」懸空交叉引用(無此段)→ 明定 `_semver_parse` 只接純數字點分(prerelease 由 `_is_prerelease` 先擋)、刪懸空引用。
- **m-1(折)**:`line_notify.send` 收 LINE API dict 非裸字串 → 明定 helper 包 `{"messages":[{"type":"text","text":..}]}` 再傳。
- **m-2(折)**:maven `docs` 巢狀路徑 → 明定 `data["response"]["docs"][].v`。
- **m-3(折)**:空 list `[]` vs 缺檔未定 → 明定空 list 同缺檔(rc 0 空候選)。
- **m-4(折)**:`_is_prerelease` 正則漏 `1.0.alpha.1`/`1.0.0b` → 放寬正則 + 列殘留限制天花板。
- **m-5(折)**:測試缺 maven 數值 max 見證/github v 剝除/current 計入 checked → 補測試案。
存活 8 條全折入(canary M-3 不折)。

### R3(2026-07-04,canary type c=未定義常數 `LINT_WATCH_STALE_DAYS`,sonnet,**CAUGHT**,severity=blocker,存活 findings=5)

canary 性質被點出(無儲存/無 schema/無測試的懸空常數,auditor 還比對 block ① 同型 canary——依規不折)。此輪 majors 為設計契約/缺席型(非經驗代碼宣稱,辯方無 file:line 可反證),直接折:
- **M-1 major(折)**:`_registry_latest -> str|None` 單一 None 承載不了三失敗原因(網路/prerelease/無穩定)→ 改回 `(latest, reason)` 二元組;prerelease 過濾移進 `_registry_latest`。
- **M-2 major(折)**:`lint_watch_dedup.py` 無 CLI/`__main__`、shell↔python 接線未定 → 補 `__main__`(stdin 讀 manifest、stdout 印 `{new, line_text}`)+ shell pipe 契約 + repo 根探法(`SCRIPT_DIR/..`)。
- **m-1(折)**:`_is_prerelease` 正則 optional 前綴假陽性(`cobra`→True)、且原「`1.0.0b` 漏判」殘留描述錯(`$` 是行尾錨已涵蓋)→ 前綴分隔符改必需、殘留描述改「以測試釘死、不窮舉」。
- **m-2(折)**:測試缺 pypi prerelease 路徑 / 去重同 name 新 latest → 補案。
- **m-3(折)**:LINE `<type>` 來源未定 → 明定 `registry.split(":",1)[0]`。
存活 5 條全折入(canary B-1 不折)。

### R4(2026-07-04,canary type d=未定義產物 `registry-cache.json`(裸檔名),sonnet,**CAUGHT**,severity=major,存活 findings=4)

canary 被點出(唯一提及快取行、無 schema/測試/清單,auditor 比對 canary c/d 型——依規不折)。此輪 auditor 列出大量「無缺陷」乾淨區(spec 已硬化),存活真 finding:
- **F2 major(折)**:shell 把多行 `line_text`(含 `\n`/emoji)內插進 shell-built JSON 會破格 → 改由 dedup helper(python)直接輸出**完整 LINE dict** `line_message`,shell 只透過 env-var 傳回 python `send`,不碰 JSON 組裝。
- **F3 minor(折)**:產出物清單殘留舊名 `_semver_behind`(r2 已改 `_compare_versions`)→ 更正。
- **F4 minor(折)**:測試 4 誤稱「git fixture」(lint-watch 無 git 互動)→ 改「臨時目錄當 repo 根」。
- **F5 minor(折)**:dispatch 未言明須置於 `find_vault()` 前(vault-free)→ 補明。
存活 4 條全折入(canary F1 不折)。

### R5(2026-07-04,canary type a=壞章節交叉引用(不存在的退避策略節),sonnet,**CAUGHT**,severity=major,存活 findings=5)

canary 被點出(懸空節指標,20 節無此節——依規不折)。findings 較 r4 回升(4→5),因 r4「shell 不組 JSON」修法的反面:shell 現在需**解析** DEDUP_OUT 才能做 ①②③(M-1)。結構性解:把 ①②③ 的 JSON 側效全收進 `lint_watch_dedup.py __main__`,shell 只判空字串、不碰 JSON。auditor 另列大量乾淨區(核心設計已穩)。
- **M-1 major(折)**:shell 需解析 dedup JSON 做 ①②③ 但未定義機制、且 spec 禁 shell 組 JSON → `__main__` 收 pending 寫入 + seen append 側效(收 `<pending_path> <today>` 參數),shell 只 `MSG=$(...)` + 判空傳 send。
- **m-1(折)**:`MSG` 用法與 autonomous-loop 不同(dict vs 純文字、跳 build_message)→ 明標「與慣例不同」。
- **m-2(折)**:`pending-<DATE>.json` schema 未定 → 明定 array of `{name,registry,current,latest}`。
- **m-3(折)**:測試 4「skip 進 failed」未指哪條路徑 → 三 skip reason 各一 fixture。
- **m-4(折)**:`new_candidates` seen.jsonl 不存在行為未定 → 明定不存在=空 seen。
存活 5 條全折入(canary B-1 不折)。**註:findings 回升 + M-1 為 r4 修法反面,收斂訊號未穩;結構性合併後 r6 應收斂。**

### R6(2026-07-04,canary type b=未定義旗標 `--registry-timeout`,sonnet,**CAUGHT**,severity=blocker,存活 findings=4)—— 達 cap(6 筆)

canary 被點出(旗標宣告卻未接進 `_http_get_json`——依規不折)。此輪 4 真 finding **全在 shell wrapper 散文**(核心 python 設計 auditor 連 3 輪列為乾淨):
- **B-1 blocker(折)**:shell `python3 -c` 片段不可執行(`TOKEN` 未定義 NameError / `import line_notify` 模組路徑錯 / 單引號擋 token 讀取)→ 改沿 `autonomous-loop.sh` 雙引號 `-c` + `sys.path.insert` + `from autonomous_loop import line_notify` + `$(cat token)`。
- **B-2 blocker(折)**:`cat "$OUT"` 語意未定(變數內容 vs 檔路徑)→ 改直接 pipe `lumos ... | python3 dedup.py`,消 `$OUT`。
- **#3 major(折)**:`$SEEN`/`$PENDING` 未初始化、`$PENDING` 目錄 vs 全檔路徑歧義 → 補 shell 變數初始化節(全檔路徑 + `mkdir -p`)。
- **#5 minor(折)**:`__main__` 收 rc=2 非 JSON stdin 會 JSONDecodeError → 明定 try/except 印空乾淨退。

**達 cap 收斂判定(誠實結論)**:6 輪 canary **6/6 全 caught**(auditor 全程醒著),但 `lumos loop status --gate` **未 GATE PASS**——K-streak 需連 2 輪 caught+乾淨,而每輪都折了真 finding(無乾淨輪);findings 序列 11→8→5→4→5→4 未枯竭到 ≤1。**根因**:核心機械設計(registry 查詢 / semver / prerelease / 三態 / fixture seam)r4-r6 連 3 輪判乾淨、已收斂;churn 全集中在**治理 shell wrapper 散文**——在設計 spec 裡逐字寫 shell 片段,每個不精確範例都招一條 finding。**建議(護欄「spec 切小」)**:核心視為 design-approved;shell wrapper 屬薄整合層,其正確性應在**實作階段以真 shell 測試**定稿(照 `autonomous-loop.sh` 既有模式),不在散文設計裡硬摳。進實作前由人放行本判定。

## v1.1 addendum:google-maven registry type(2026-07-04,KDS 真機驅動)

**動機**:KDS 真機驗證發現 `maven:` 只查 Maven Central,對 Google-hosted artifact(AGP/AndroidX)靜默假陰性(AGP 8.2.2 誤判「已最新」,因 Central 只剩遠古 2.x)。補 `google-maven:` type 查 Google Maven。

**真機坐實的端點與陷阱**(curl 實測):
- URL `https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/maven-metadata.xml` → HTTP 200 XML `<metadata><versioning><latest>/<release>/<versions><version>…`。
- `<latest>`=`<release>`=`9.4.0-alpha03`(**prerelease!** 不可直接用);versions 清單過濾 prerelease 後數值 max = **9.2.1**(真 AGP 穩定 latest)。AGP `8.2.2`→`9.2.1` 正確落後(取代舊 maven: 的假「current」)。
- 641 versions、105 stable;`xml.etree.ElementTree` + `root.iter("version")` 解析。

**design-loop 判定**:**跳過 canary 設計 loop 並註明**——本項為既有已驗機制(`maven:` 數值 max + prerelease 過濾)的小幅機械延伸,唯一新面是 XML 抓取 + Google Maven URL scheme,且**端點/回應形狀/prerelease 陷阱已 curl 真機坐實**。風險在 code(XML 解析、prerelease-in-`<latest>` 陷阱、fixture-text seam),由**單元測(fixture)+ KDS AGP 真機驗證**接住,非設計散文 canary 審計能加值(見 [[design-loop-completeness-ceiling-shown]] 教訓:機械延伸靠真測而非 canary-prose)。實作走 subagent-driven 保留 reviewer code-quality 閘。
