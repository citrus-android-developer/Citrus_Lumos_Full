#!/bin/bash
# AI 治理調研日報：搜集 AI 治理文章，以「架構圖即合約」方法論為透鏡綜合判斷，
# 產出靈感與打磨建議，發送直式卡片到 LINE（Oreo AI 報報）
# crontab: 30 9 * * * /Users/enzo/script/ai-governance-research.sh >> /Users/enzo/script/logs/governance.log 2>&1

set -euo pipefail
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
# cron 讀不到鑰匙圈的登入 → 用 setup-token 長效 OAuth token（仍走訂閱，非 API 計費）
export CLAUDE_CODE_OAUTH_TOKEN="$(cat "$HOME/.config/ai-daily/claude_oauth_token" 2>/dev/null)"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TODAY="$(date +%Y-%m-%d)"
OUT_DIR="$SCRIPT_DIR/reports"
mkdir -p "$OUT_DIR" "$SCRIPT_DIR/logs"
REPORT_FILE="$OUT_DIR/governance-$TODAY.json"
TOKEN_FILE="$HOME/.config/ai-daily/line_token_research"

# 方法論筆記（每次現場重讀，筆記更新後調研透鏡自動跟上）
NOTE_MAIN="/Users/enzo/harness/lumos-toolchain/docs/methodology/架構圖即合約.md"
NOTE_ESSAY="/Users/enzo/harness/lumos-toolchain/docs/methodology/架構圖即合約-對外論述.md"

# 累積觀點總帳（長期去重用）＋ 過去 3 天完整報告
HISTORY_FILE="$OUT_DIR/governance-history.md"
# 已介紹過的 arXiv id 硬黑名單(2026-07-26:同篇論文換標題騙過標題比對實錘——2605.25665 於
# 07-22/07-26 重複入報;id 機械抽出注入 prompt,去重不再只靠模型比標題)
KNOWN_IDS=""
if [[ -f "$HISTORY_FILE" ]]; then
  KNOWN_IDS="$(grep -oE 'arXiv[ :]?[0-9]{4}\.[0-9]{4,6}' "$HISTORY_FILE" | grep -oE '[0-9]{4}\.[0-9]{4,6}' | sort -u | tr '\n' ' ')"
fi
RECENT_FILES="$( (ls -t "$OUT_DIR"/governance-2*.json 2>/dev/null || true) | head -3 | tr '\n' ' ')"

# 現行實作狀態（權威現況——防止把已 ship 的機制當成 gap 重提）
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LUMOS_CAPS="$(python3 "$REPO_ROOT/scripts/lumos" --help 2>/dev/null | head -12 || true)"
RECENT_SHIPPED="$( { cd "$REPO_ROOT" && git log --oneline --since='21 days ago' -- scripts/lumos skills 2>/dev/null; } | head -30 || true)"

PROMPT="今天是 ${TODAY}。你是 AI 治理領域的調研主編，服務對象是「架構圖即合約（graph-as-contract）」方法論的設計者，
目標是幫助他不斷打磨這套 best practice 的不足之處。

【第一步：建立分析透鏡】用 Read 工具完整閱讀以下兩個檔案，掌握方法論的設計、
已知限制（§7 權衡、故意不做的事、L4 否決案）與核心架構圖 v1 已知盲區：
- ${NOTE_MAIN}
- ${NOTE_ESSAY}
這套方法論有多個面向。【主軸＝迴圈工程，尤其「驗證層自己可不可信」這一層】——其餘面向是支線，最終都回扣到一個問題：這對「自主／無人看顧的自我檢查 loop」有沒有用。可用的透鏡：
- ★主透鏡★ 驗證層自身的可靠度（eval 的 eval）：LLM-as-judge、AI 自審、canary／test-the-tester 這類「驗證機制」本身會不會放水、會漏判多少、missed 率怎麼追蹤、adversarial verification 的極限、收斂條件可不可信。這是這套方法論目前最前沿、最沒解決的一層。
- 迴圈工程（inner/outer loop、plan-execute-verify、自主迴圈、termination 與收斂、回饋品質、open-loop 風險）
- 記憶治理（架構圖當跨 session 記憶、summary 漂移、固化與遺忘）
- 稽核與可追溯（留痕、bypass 率、agent 身分、可重跑驗證）
- 多 agent 安全與權限（最小權限、共通節點保護、鏈式注入、越權）
- 可逆性與回退（決策能否安全 undo、補償步驟）
- 合約即測試 / SDD（★INVARIANT★ 綁測試、白話規格生測試、合格證明標準）
切入點每天可輪替（避免連日只盯同一面向），但主軸不變：今天無論從哪個面向切入，最後都要回答一句「它對『驗證層／自主 loop 的可靠度』說了什麼」。
參考：內迴圈是 invariant→test→CI 的 write-run-read-correct，外迴圈是架構圖跨 session 記憶＋valid_under 條件式有效期＋週彙整與 L4 自足性審計；這份調研本身也是一個迴圈（定目標→找料→綜合→去重記帳→影響明日）。

【第一·五步：對齊 lumos『現行實作狀態』（權威現況，優先於散文與舊報告）】
以下是 lumos 工具鏈【現在真的有的能力】與【近三週剛 ship 的東西】——這才是現況真相；方法論散文與舊日報只是輔助、可能落後於實作。
· 現行子命令（＝現有能力全景）：
${LUMOS_CAPS}
· 近三週剛實作/上線（scripts/skills 的 commit）：
${RECENT_SHIPPED:-（近期無 scripts/skills 變更）}
⚠【防重提鐵則】凡上面清單已有的機制，一律視為【已解決】，不得在 gaps 裡當『缺這個功能』重提；舊日報若把它列為 gap，那是過期框架、別沿用。真要對它提 gap，必須具體說『現行實作為何仍不足』並附外部證據，而不是泛泛說『可以加 X』（X 已經有了）。
⚠【參數要查現值，別憑印象或舊報告】要寫某機制的【具體參數／數值】（收斂輪數、K 值、閾值、panel 寬 W、cap 幾輪…）時，先用 Read 讀對應檔確認【現值】：收斂／canary／辯方相關 → ${REPO_ROOT}/skills/lumos-code-loop/reference.md 或 ${REPO_ROOT}/skills/lumos-design-loop/SKILL.md（頭版是精簡版、細節在同目錄 reference.md）；其餘機制查對應 skill 或架構圖。查不到就別寫死數字，改講定性（例：「有上限、連續乾淨才收斂」）。舊報告與方法論散文裡的具體數字可能已過期，不得直接沿用——【只有拿最新的 lumos 現值來比，這個比較才有意義】。

【第二步：去重——文章與觀點兩個層級都要】
1. 若存在，用 Read 讀取累積觀點總帳：${HISTORY_FILE}
2. 若存在，用 Read 讀取最近的完整報告：${RECENT_FILES:-（尚無歷史報告）}
去重規則：
- 已介紹過的「同一篇文章」一律不重複。**「同一篇」以 arXiv/DOI id 為準——標題換寫法、換語言、換切入角度都算同一篇**（實錘教訓：2605.25665 換標題後 07-22/07-26 重複入報）。
- **已介紹過的 arXiv id 硬黑名單（機械抽自總帳，凡在列一律不得再選）**：${KNOWN_IDS:-（尚無）}
- 選定每篇文章後，先自查其 id 不在上列黑名單，再往下寫。
- 「觀點」去重是針對【具體的靈感/不足】，不是針對【整個面向】：
  同一條靈感/不足換句話說再講一次算重複；但同一個面向（如記憶治理、稽核、安全）只要是新的角度、新的切入點，就可以再談，不算重複。
  別因為某面向先前被一兩篇講過就把整個面向封死——舊題只要有新證據、新進展或新角度即可舊題新報，並註明新在哪裡。
- 視角輪替（重要，但只管支線）：先看最近 3 天報告主要落在哪些【支線】面向，今天刻意挑【不同支線】切入；
  避免連續多天集中在同一支線（例如連三天都在談記憶治理）。當天若數個面向都有料，優先補最近最少出現的那個。
  ⚠ 輪替只適用【支線面向】；★主透鏡★（驗證層自身可靠度）是每期都要回扣的主軸，不受輪替限制、不因「最近談過」而迴避。

【第二·五步：回顧自己的建議落地了沒（吃自己的狗糧）】
用 Read 讀 lumos 設計目錄 /Users/enzo/harness/lumos-toolchain/docs/design/ 裡【檔名日期最新的最多 2 份】spec（不是全掃），對照最近幾天報告的 gaps/inspirations、以及第一·五步的『現行實作狀態』清單（清單裡已有的＝已落地）：
- 哪些建議已變成 spec 或實作？（看得到對應主題的設計檔即算落地）
- 落地後是驗證了原假設、還是反而推翻了它？（spec 裡常有「審計修正紀錄」「擱置決定」記錄真相）
把一句話回顧放進 overview 或 watch（例：「上次提的 X 已落地為 spec、但 Y 假設在實作中被推翻」）。
【邊界】目錄不存在或 Read 失敗 → 直接略過這步、繼續第三步；這步花的 token 不得超過主調研，別讓回顧喧賓奪主。沒有可回顧的就略過，別硬湊。

【第三步：調研】搜尋最近 24-48 小時（或近期高價值）的 AI 治理文章、新聞、論文、開源專案動態，雙軌並行：
(a) 主軌：AI 協作開發治理——context engineering、loop engineering（agentic loops、
    inner/outer loop、plan-execute-verify、背景 agent 與自主迴圈、verification/feedback loop 設計、
    termination 與收斂條件）、AI coding agent 的知識管理與審計、spec-driven development、
    文件與程式碼同步、agent 權限與安全治理、多 agent 協作規範、長期記憶系統
(b) 副軌：廣義 AI 治理（政策法規、企業 AI 治理框架、模型安全標準）——只挑與工程實務有交集者
精選 3-5 篇，寧缺勿濫，標題黨或無實質內容的不收。

【第四步：綜合判斷——一切以「打磨方法論」為目的】
- 每篇文章的 relevance：這篇與架構圖即合約的對話——驗證了哪個設計？挑戰了哪個假設？可借鏡什麼？
- 【對抗視角——不可省略，至少一條】每期至少有一條觀點是「打臉」而非「印證」：找外部證據挑戰 lumos 的某個核心假設、或顯示某個機制其實沒用／有更好的替代。只找印證你的＝maker 審自己＝確認偏誤，正是這套方法論在反對的東西。寧可指出一個真弱點，也不要湊一條恭維。這條打臉觀點放進 gaps。
  【逃生艙——優先於「不可省略」】若當日調研確實找不到有外部證據支持的反證，就明寫一條 gap「本期未找到有力反證」即可，【絕不為湊滿『至少一條』而捏造假打臉】——湊假打臉比沒有更糟，那正是另一種確認偏誤。
- 多面向透鏡（擇優戴，不強制）：每篇問一句——它對架構圖即合約的哪個面向（記憶治理／稽核／安全權限／可逆性／合約即測試／迴圈工程……）說了什麼？
  驗證了哪個設計？挑戰了哪個假設？可借鏡什麼？哪個面向最切題就從哪個切入，不必每天都套迴圈工程。
  整體上 inspirations 與 gaps 合計盡量涵蓋 2 個以上不同面向，避免一份報告所有觀點都擠在同一面向。
- inspirations：可具體落地的靈感（可加進四道強制力的機制、可寫進 skill 的規範、frontmatter 設計改進等），要具體可行動，不要空話
- gaps：對照方法論已記載的限制/盲區、或你從今日調研新發現的弱點，每條配一個打磨建議；優先提有外部證據支持的。【先過第一·五步的『現行實作狀態』清單，濾掉已 ship 的機制——那不是 gap】【至少 1 條須為「對抗類」】——不是「可以再加強」，而是「外部證據顯示 lumos 某個假設可能站不住／某機制可能沒用」，weakness 寫清楚打臉的是哪個假設、證據是什麼
- 判斷要客觀：外界做法不一定更好，值得借鏡才提；方法論已明確否決過的方案（如 L4），除非有新證據否則不要重提

【白話規範——讓外行也讀得懂（重要）】
寫給「聰明但非本領域」的讀者看，像跟朋友解釋，不是寫給專家看的速記：
- 專有名詞、縮寫、論文或產品代號第一次出現，就用一句白話說它是什麼（例：不要只丟『GAM』，要寫成『一套叫 GAM 的 agent 記憶設計』）。
- 一句只講一件事。不要層層括號、不要用箭頭符號串接（→）、不要塞滿術語的長句；寧可多寫一句把話講完整。
- 先說人話結論，再補細節；能用日常生活的比喻就用。少用『機械化、收斂、隔離、固化態、神諭』這類硬詞，真要用就順手解釋一下。
- 數字或評測（像 F1 分數、勝率）要說清楚『所以這代表什麼』，不要只貼數據。
目標：一個沒讀過這套方法論的人，看完也能懂今天在講什麼、以及為什麼跟他有關。

【輸出格式】只輸出一個 JSON 物件，不要 markdown 程式碼框、不要任何前後說明。使用繁體中文：
{
  \"date\": \"${TODAY}\",
  \"overview\": \"今日治理動態總覽，白話講（140字內）\",
  \"loop_lens\": \"今日從★主透鏡★（驗證層可靠度／迴圈工程）角度，對這套工作流的一句白話總結或最該補的那個環節（110字內；真的無從談起可省略此欄）\",
  \"articles\": [{\"title\": \"標題（40字內）\", \"source\": \"媒體或作者\", \"summary\": \"這篇在講什麼，用人話說（130字內）\", \"relevance\": \"跟這套方法論有什麼關係、為什麼值得看（130字內）\"}],
  \"inspirations\": [\"具體可落地的靈感，白話寫（100字內）\"],
  \"gaps\": [{\"weakness\": \"現有不足，一句話講清楚（60字內）\", \"suggestion\": \"打磨建議，白話說怎麼做（120字內）\"}],
  \"watch\": \"值得持續追蹤的議題（80字內）\"
}
articles 3-5 篇、inspirations 2-4 條、gaps 2-3 條。

【寧缺勿濫鐵則】若當天去重後值得介紹的文章不足 2 篇、或擠不出未重複的觀點，
不要硬湊，改輸出：{\"skip\": true, \"reason\": \"一句話說明原因\"}（同樣只輸出這個 JSON）。\n\n⚠️ 嚴格輸出規定：回覆的第一個字元必須是 {，最後一個字元必須是 }。禁止任何開場白、前言、思考過程、結語、markdown 程式碼框——直接給 JSON 本體。"

# 一律用 Opus（訂閱內，$0）。
# 註：原本週日跑 Fable 5 深度版，但 cron 用的 setup-token OAuth（走訂閱）無權存取
#     claude-fable-5，週日會直接報錯空轉，故改回一律 Opus。
MODEL="opus"

echo "[$(date '+%F %T')] 開始產生 AI 治理調研（model: ${MODEL}）..."
RAW_FILE="$(mktemp)"
claude -p "$PROMPT" --model "$MODEL" --allowedTools "Read,WebSearch,WebFetch" > "$RAW_FILE"

if [ ! -s "$RAW_FILE" ]; then
  echo "[$(date '+%F %T')] 錯誤：調研內容為空，中止發送" >&2
  rm -f "$RAW_FILE"
  exit 1
fi

# 模型偶爾會在 { 前後加旁白(即使有嚴格指示),直接寫會讓報告檔變非合法 JSON。
# 在落地時就抽出 JSON 本體並 re-dump,保證 $REPORT_FILE 永遠是合法 JSON。
if ! python3 - "$RAW_FILE" "$REPORT_FILE" <<'PY'
import json, re, sys
raw = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"\{.*\}", raw, re.S)   # 第一個 { 到最後一個 }(與下游萃取一致)
if not m:
    sys.exit(1)
obj = json.loads(m.group(0))          # 驗證真的是合法 JSON,否則 exit 非 0
with open(sys.argv[2], "w", encoding="utf-8") as f:
    json.dump(obj, f, ensure_ascii=False, indent=2)
PY
then
  echo "[$(date '+%F %T')] 錯誤：模型輸出找不到合法 JSON,原始輸出保留於 ${REPORT_FILE}.raw" >&2
  cp "$RAW_FILE" "${REPORT_FILE}.raw"
  rm -f "$RAW_FILE"
  exit 1
fi
rm -f "$RAW_FILE"

echo "[$(date '+%F %T')] 調研已產生：$REPORT_FILE"

# 寧缺勿濫：claude 判定當天沒有足夠內容時不發送（報告檔保留作紀錄）
SKIP_REASON="$(python3 -c "
import json, re, sys
raw = open('$REPORT_FILE', encoding='utf-8').read()
m = re.search(r'\{.*\}', raw, re.S)
r = json.loads(m.group(0)) if m else {}
print(r.get('reason', '') if r.get('skip') else '')
")"
if [ -n "$SKIP_REASON" ]; then
  echo "[$(date '+%F %T')] 今日跳過不發送：$SKIP_REASON"
  exit 0
fi

# 產出即記總帳(2026-07-26 解耦:原「發送成功後才記」使配額死亡期 07-21~23 的調研
# 從去重帳消失→同篇論文重複入報。去重帳語意=「調研過」非「推播過」,故移到發送前)
python3 - "$REPORT_FILE" "$HISTORY_FILE" <<'PY'
import json, re, sys
raw = open(sys.argv[1], encoding="utf-8").read()
r = json.loads(re.search(r"\{.*\}", raw, re.S).group(0))
lines = [f"## {r['date']}"]
for a in r.get("articles", []):
    lines.append(f"- 文章: {a['title']}（{a.get('source', '')}）")
for i in r.get("inspirations", []):
    lines.append(f"- 靈感: {i}")
for g in r.get("gaps", []):
    lines.append(f"- 不足: {g['weakness']} → {g['suggestion']}")
with open(sys.argv[2], "a", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n\n")
PY

BODY="$(python3 "$SCRIPT_DIR/governance_flex_builder.py" "$REPORT_FILE")"

LINE_TOKEN="$(cat "$TOKEN_FILE")"
HTTP_CODE=$(curl -s -o /tmp/line_gov_resp.json -w "%{http_code}" \
  -X POST https://api.line.me/v2/bot/message/broadcast \
  -H "Authorization: Bearer $LINE_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$BODY")

if [ "$HTTP_CODE" = "200" ]; then
  echo "[$(date '+%F %T')] LINE broadcast 發送成功"
else
  echo "[$(date '+%F %T')] LINE 發送失敗 HTTP $HTTP_CODE：$(cat /tmp/line_gov_resp.json)" >&2
  exit 1
fi

echo "[$(date '+%F %T')] 已寫入觀點總帳：$HISTORY_FILE"
