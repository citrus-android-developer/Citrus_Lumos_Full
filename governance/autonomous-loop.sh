#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
MODE="${1:---dry-run}"
MAXR="${2:-6}"
# 非 dry-run 停用(2026-07-29 使用者裁定,Codex 外審採納):子 agent 權限隔離
# (Systems/nested-agent-permission-scope,planned)落地前,confused-deputy 已知漏洞
# 不留可執行入口——--pr 直接拒跑。解禁條件:read-only child isolation 落地+過 code-loop。
if [ "$MODE" != "--dry-run" ]; then
  echo "autonomous-loop: 非 dry-run 已停用(2026-07-29 裁定,詳見架構圖 nested-agent-permission-scope);dry-run 照常" >&2
  exit 2
fi
TODAY="$(date +%F)"
REPORT="$SCRIPT_DIR/reports/governance-$TODAY.json"
PENDING="$SCRIPT_DIR/pending";  mkdir -p "$PENDING"
LOGDIR="$SCRIPT_DIR/logs";      mkdir -p "$LOGDIR"
SCRATCH="$(mktemp -d "/tmp/auto-loop-$TODAY.XXXXXX")"; mkdir -p "$SCRATCH/kg" "$SCRATCH/spec"   # mktemp:防可預測路徑搶佔(外審 minor)
log(){ echo "[$(date '+%F %T')] $*"; }

if [ ! -f "$REPORT" ]; then
  if [ "$MODE" = "--dry-run" ]; then
    REPORT="$(ls -t "$SCRIPT_DIR/reports/"governance-2*.json 2>/dev/null | head -1 || true)"
    [ -n "$REPORT" ] && log "今日無日報,dry-run fallback:$REPORT" || { log "無任何日報,結束"; exit 0; }
  else log "今日無日報($TODAY),跳過"; exit 0; fi
fi

# ── 週期考卷(2026-08-05 掛載):雙庫檢索考卷 ≥7 天未跑就補跑——把「hook 調參靠記得」
# 變「定期發生」;fail-open,考卷失敗只記 log 不阻斷 gap 流程。判定/漂移細節在
# retrieval_eval.py 自己的 gate 輸出與 history jsonl,此處只管排程。
run_exam(){ local repo="$1" tag="$2"
  local hist="$repo/governance/eval/retrieval-eval-history.jsonl"
  local gold="$repo/governance/eval/retrieval-goldset.json"
  [ -f "$gold" ] || { log "考卷($tag):無 goldset,跳過"; return 0; }
  # 取「最後一筆帶 ts 的 goldset 列」(單席快審 F3:末行可能是無 ts 的 auto-cochange 列→誤判 1970 天天重考)
  local last; last="$(python3 -c '
import json,sys
last="1970-01-01"
try:
    for l in open(sys.argv[1],encoding="utf-8"):
        try: d=json.loads(l)
        except ValueError: continue
        if d.get("ts") and d.get("mode","goldset")=="goldset": last=d["ts"]
except OSError: pass
print(last)' "$hist" 2>/dev/null || echo 1970-01-01)"
  local last_s; last_s="$(date -j -f %F "$last" +%s 2>/dev/null || echo 0)"
  local age=$(( ( $(date +%s) - last_s ) / 86400 ))
  if [ "$age" -ge 7 ]; then
    log "考卷($tag):距上次 ${age} 天(>7),補跑 held split"
    (cd "$repo" && python3 governance/eval/retrieval_eval.py --goldset "$gold" --split held) > "$LOGDIR/exam-$tag-$TODAY.log" 2>&1 || true
    # 完成判定看「gate 總判定」行,不看 rc——部分版本 gate FAIL 即回非零,那是調參訊號非執行失敗
    if grep -q 'gate 總判定' "$LOGDIR/exam-$tag-$TODAY.log"; then
      log "考卷($tag)完成:$(grep 'gate 總判定' "$LOGDIR/exam-$tag-$TODAY.log" | tail -1)"
      # ── 標註刷新 S4 薄接線(2026-08-18):unjudged 超通知線→產 delta 表+LINE 等人放行。
      # 邏輯全在 refresh_labels.py signal(受測);此處只 grep over=yes,不看 rc(advisory)。
      local sig; sig="$(cd "$repo" && python3 governance/eval/refresh_labels.py signal --history "$hist" 2>/dev/null || echo '')"
      log "考卷($tag)未標率:${sig:-NA}"
      if echo "$sig" | grep -q 'over=yes'; then
        # ★rc+產物存在雙查後才通報★(code-r1 資源席 F2:原 || true 吞錯照發「已產表」=假成功);
        # token 走 env 傳遞(code-r1 外家席:inline $() 展開含引號的 token 會炸 python 且被 || true 吞掉)
        local delta_rc=0
        (cd "$repo" && python3 governance/eval/refresh_labels.py delta \
          --out "$repo/governance/eval/retrieval-delta-$TODAY") >> "$LOGDIR/exam-$tag-$TODAY.log" 2>&1 || delta_rc=$?
        if [ "$delta_rc" -eq 0 ] && [ -f "$repo/governance/eval/retrieval-delta-$TODAY-sheet.md" ]; then
          log "考卷($tag)未標率超線,已產 delta 表 retrieval-delta-$TODAY-sheet.md 等人放行補標"
          MSG="📝 檢索考卷($tag)未標率超線($sig)——delta 表已備:governance/eval/retrieval-delta-$TODAY-sheet.md,補標流程見 Projects/標註刷新_計劃" \
          LINE_TOKEN="$(cat "$HOME/.config/ai-daily/line_token" 2>/dev/null)" python3 -c "
import sys, os; sys.path.insert(0,'$REPO/governance')  # \$REPO(工具鏈本體)刻意非 \$repo:line_notify 模組只存在於本體
from autonomous_loop import line_notify
t=os.environ.get('LINE_TOKEN','')
print('LINE', line_notify.send(line_notify.build_message('labeling-refresh', os.environ['MSG'], None), t) if t else 'no-token')" || true
        else
          log "⚠ 考卷($tag)未標率超線但 delta 表產製失敗(rc=$delta_rc),不通報假成功;詳 $LOGDIR/exam-$tag-$TODAY.log"
        fi
      fi
    else
      log "⚠ 考卷($tag)執行失敗(fail-open 不阻斷),詳 $LOGDIR/exam-$tag-$TODAY.log"
    fi
  else
    log "考卷($tag):${age} 天前跑過,略"
  fi
}
run_exam "$REPO" toolchain
[ -d "$HOME/backend/LandmarkMember/governance/eval" ] && run_exam "$HOME/backend/LandmarkMember" landmark

SKIP_CAP=3; skip_n=0
while : ; do
GAP_JSON="$(cd "$REPO" && python3 -c "
import sys, json; sys.path.insert(0,'governance')
from autonomous_loop import gap_select
mode='pr' if '$MODE'=='--pr' else 'dryrun'
g=gap_select.select('$REPORT','$SCRIPT_DIR/backlog.jsonl','$PENDING',mode,'$TODAY','$SCRIPT_DIR/covered.jsonl')
print(json.dumps(g, ensure_ascii=False) if g else '')
")"
[ -n "$GAP_JSON" ] || { log "無可展開 gap(N=1 gate 或 backlog 空),結束"; exit 0; }
log "選中 gap:$GAP_JSON"

# 錨點完整性:驗證器被污染時跑出的「收斂/綠」全是假訊號,寧停。
# loop 入口比 pre-push 嚴:missing baseline 亦硬擋(無人看顧場景無人眼兜底)。
if [ ! -f "$REPO/governance/anchor-baseline.json" ] || ! (cd "$REPO" && python3 scripts/lumos anchor verify); then
  log "錨點完整性失敗(anchor verify 不過或 baseline 缺失),loop 拒跑"
  MSG="⚠ 錨點完整性失敗,自主 loop 拒跑(anchor verify)" LINE_TOKEN="$(cat "$HOME/.config/ai-daily/line_token" 2>/dev/null)" python3 -c "
import sys, os; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import line_notify
t=os.environ.get('LINE_TOKEN','')
print('LINE', line_notify.send(line_notify.build_message('anchor-integrity', os.environ['MSG'], None), t) if t else 'no-token')" || true
  exit 1
fi

# ── tier 分級(risk-tiered-review):gap 文本 assess → 注入 NEED/TIER/MAXR_EFF ──
read -r TIER NEED < <(echo "$GAP_JSON" | python3 -c "
import sys, json; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import difficulty
g=json.load(sys.stdin)
a=difficulty.assess((g.get('weakness','') or '')+'\n'+(g.get('suggestion','') or ''))
p=difficulty.params(a['tier'])
print(a['tier'], p['need'])")
MAXR_EFF="$MAXR"
[ "$TIER" = "high" ] && MAXR_EFF="$(( MAXR > 8 ? MAXR : 8 ))"
log "tier 分級:$TIER(need=$NEED, maxr=$MAXR_EFF)"

PROMPT_FILE="$(mktemp)"
sed -e "s#__SCRATCH__#$SCRATCH#g" -e "s#__DATE__#$TODAY#g" -e "s#__MAXR__#$MAXR_EFF#g" \
    -e "s#__NEED__#$NEED#g" -e "s#__TIER__#$TIER#g" \
    "$SCRIPT_DIR/autonomous_loop/orchestrator-prompt.md" > "$PROMPT_FILE"
printf '\n\n## 要處理的 gap\n%s\n模式:%s\n' "$GAP_JSON" "$MODE" >> "$PROMPT_FILE"
export ANTHROPIC_API_KEY=""
export CLAUDE_CODE_OAUTH_TOKEN="$(cat "$HOME/.config/ai-daily/claude_oauth_token" 2>/dev/null)"
ORCH_OUT="$LOGDIR/orchestrator-$TODAY.json"
log "派 orchestrator(claude -p,最多 $MAXR_EFF 輪)..."
(cd "$REPO" && claude -p "$(cat "$PROMPT_FILE")" \
  --allowedTools "Read,Edit,Bash,Grep,Glob,Agent" \
  --permission-mode acceptEdits --output-format json) > "$ORCH_OUT" 2>"$LOGDIR/orchestrator-$TODAY.err" || true
rm -f "$PROMPT_FILE"

PARSED="$(cd "$REPO" && python3 -c "
import json, sys; sys.path.insert(0,'governance')
from autonomous_loop import orchestrator_result
try: o=json.load(open('$ORCH_OUT'))
except Exception as e: print('PARSE_FAIL:'+str(e)); sys.exit(0)
r=orchestrator_result.extract_json(o.get('result',''))
print(json.dumps(r, ensure_ascii=False) if r else 'NO_JSON')
")"
log "orchestrator 回傳:$PARSED"
case "$PARSED" in PARSE_FAIL*|NO_JSON*|"") log "orchestrator 輸出無法解析,中止(log $ORCH_OUT)"; exit 1;; esac

get(){ echo "$PARSED" | python3 -c "import json,sys;print(json.load(sys.stdin).get('$1',''))"; }
SKIPPED="$(get skipped)"; CONVERGED="$(get converged)"; TOPIC="$(get topic)"; SPEC="$(get spec_path)"
CROSS_VERDICT="$(get cross_verdict)"; CROSS_WORST="$(get cross_worst)"; CROSS_SUMMARY="$(get cross_summary)"
TIER_RESULT="$(get tier)"
CROSS_SUMMARY="${CROSS_SUMMARY//$'\n'/ }"   # F3 防破版:換行→空格

if [ "$SKIPPED" = "True" ]; then
  skip_n=$((skip_n+1))
  echo "$GAP_JSON" | python3 -c "
import sys, json; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import gap_select
w=json.load(sys.stdin).get('weakness','')
if w: gap_select.mark_covered('$SCRIPT_DIR/covered.jsonl', w)
" 2>/dev/null || true
  log "gap 已被既有 spec 覆蓋,skip(reason: $(get reason));已記入 covered、永久不再選。循環選下一個($skip_n/$SKIP_CAP)。"
  [ "$skip_n" -ge "$SKIP_CAP" ] && { log "連 skip $SKIP_CAP 個已覆蓋 gap,今天結束(剩餘留 backlog 明天再選)。"; exit 0; }
  continue
fi
break
done

RESIDUAL='["跨家族複核已加(qwen3-max 放行前複核 opus 設計、補同門盲點);但 degrade 時退回單一 opus、qwen 也是 AI、verdict 判定仍在 orchestrator(prompt 層自律)","severity 由 judge 評(已斷 orchestrator 自填)但 judge 也是 AI、且同輪判 canary+severity=集中化","type d canary 沒測(限 a/b/c)","自動 brainstorm 無人回澄清;AI 自選 gap=自己決定改自己方向(自我強化偏誤)","唯一外部錨點是你 review 這個 PR"]'
if [ "$CONVERGED" != "True" ]; then
  if [ "$CROSS_VERDICT" = "disputed" ]; then
    MSG="⚠ 跨家族否決(qwen 持續異議):$CROSS_SUMMARY"; log "未收斂(跨家族否決 disputed),不放行:$CROSS_SUMMARY"
  elif [ "$CROSS_VERDICT" = "degraded" ] && [ "$TIER" = "high" ]; then
    MSG="⚠ 高風險級複核缺席(degraded)、fail-closed 擋下:$CROSS_SUMMARY"; log "未收斂(高風險級複核 degraded fail-closed),不放行:$CROSS_SUMMARY"
  else
    MSG="⚠ 今日 spec 未收斂、未放行(撞 cap)"; log "未收斂(converged=$CONVERGED),不放行,scratch 不入庫。"
  fi
  MSG="$MSG" LINE_TOKEN="$(cat "$HOME/.config/ai-daily/line_token" 2>/dev/null)" python3 -c "
import sys, os; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import line_notify
t=os.environ.get('LINE_TOKEN','')
print('LINE', line_notify.send(line_notify.build_message('$TOPIC',os.environ['MSG'],None),t) if t else 'no-token')" || true
  # 副作用 A:未收斂 gap 回 backlog 降分 + 累計 unconverged;達 3 次 → covered(放棄自動、留人),不立即消失
  RQ="$(echo "$GAP_JSON" | python3 -c "
import sys, json; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import gap_select
g=json.load(sys.stdin)
print(gap_select.requeue_unconverged('$SCRIPT_DIR/backlog.jsonl', g, '$SCRIPT_DIR/covered.jsonl'))
" 2>/dev/null || echo '?')"
  log "未收斂 gap 處置:$RQ(回 backlog 降分重試 / 累計達 3 次 covered)"
  exit 0
fi

[ -n "$CROSS_VERDICT" ] && log "跨家族複核:$CROSS_VERDICT($CROSS_WORST)— $CROSS_SUMMARY"

# ── tier 收檔守衛:不信自報 converged——wrapper 自算 tier、以其 need 重驗 gate ──
if [ -z "$SPEC" ] || [ ! -f "$SPEC" ]; then
  log "tier 守衛擋下:converged=True 但 spec_path 空或不存在($SPEC)"
  MSG="⚠ tier 守衛擋下:自報收斂但 spec_path 無效" LINE_TOKEN="$(cat "$HOME/.config/ai-daily/line_token" 2>/dev/null)" python3 -c "
import sys, os; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import line_notify
t=os.environ.get('LINE_TOKEN','')
print('LINE', line_notify.send(line_notify.build_message('$TOPIC',os.environ['MSG'],None),t) if t else 'no-token')" || true
  RQ="$(echo "$GAP_JSON" | python3 -c "
import sys, json; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import gap_select
g=json.load(sys.stdin)
print(gap_select.requeue_unconverged('$SCRIPT_DIR/backlog.jsonl', g, '$SCRIPT_DIR/covered.jsonl'))
" 2>/dev/null || echo '?')"
  log "未收斂 gap 處置:$RQ(tier 守衛/spec_path)"
  exit 0
fi
REPORT_MD="$(cd "$REPO" && python3 -c "
import sys, json; sys.path.insert(0,'governance')
from autonomous_loop import confidence_report, difficulty
a=difficulty.assess_spec(open('$SPEC').read())
print(confidence_report.build_report('$SCRATCH/.canary-log.jsonl','$TOPIC', json.loads('''$RESIDUAL'''),
      tier=a['tier'], hits=a['hits'], reported_tier='$TIER_RESULT'))
")"
TIER_FINAL="$(cd "$REPO" && python3 -c "
import sys; sys.path.insert(0,'governance')
from autonomous_loop import difficulty
print(difficulty.assess_spec(open('$SPEC').read())['tier'])")"
NEED_FINAL="$NEED"
if [ "$TIER_FINAL" = "high" ] && [ "$NEED_FINAL" -lt 3 ]; then NEED_FINAL=3; fi
if ! (cd "$REPO" && python3 scripts/lumos --vault "$SCRATCH/kg" loop status "$TOPIC" --need "$NEED_FINAL" --gate --spec "$SPEC" --repo "$REPO"); then
  log "tier 守衛擋下:自報收斂但 gate 重驗不過(自算 tier=$TIER_FINAL, need=$NEED_FINAL)"
  MSG="⚠ tier 守衛擋下:自報收斂但 gate 重驗不過(tier=$TIER_FINAL)" LINE_TOKEN="$(cat "$HOME/.config/ai-daily/line_token" 2>/dev/null)" python3 -c "
import sys, os; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import line_notify
t=os.environ.get('LINE_TOKEN','')
print('LINE', line_notify.send(line_notify.build_message('$TOPIC',os.environ['MSG'],None),t) if t else 'no-token')" || true
  RQ="$(echo "$GAP_JSON" | python3 -c "
import sys, json; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import gap_select
g=json.load(sys.stdin)
print(gap_select.requeue_unconverged('$SCRIPT_DIR/backlog.jsonl', g, '$SCRIPT_DIR/covered.jsonl'))
" 2>/dev/null || echo '?')"
  log "未收斂 gap 處置:$RQ(tier 守衛)"
  exit 0
fi
if [ "$TIER_FINAL" = "high" ] && [ "$CROSS_VERDICT" != "endorsed" ]; then
  log "tier 守衛擋下:high 級 cross_verdict=$CROSS_VERDICT 非乾淨 endorsed,不放行"
  MSG="⚠ tier 守衛擋下:high 級複核非乾淨 endorsed(=$CROSS_VERDICT)" LINE_TOKEN="$(cat "$HOME/.config/ai-daily/line_token" 2>/dev/null)" python3 -c "
import sys, os; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import line_notify
t=os.environ.get('LINE_TOKEN','')
print('LINE', line_notify.send(line_notify.build_message('$TOPIC',os.environ['MSG'],None),t) if t else 'no-token')" || true
  RQ="$(echo "$GAP_JSON" | python3 -c "
import sys, json; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import gap_select
g=json.load(sys.stdin)
print(gap_select.requeue_unconverged('$SCRIPT_DIR/backlog.jsonl', g, '$SCRIPT_DIR/covered.jsonl'))
" 2>/dev/null || echo '?')"
  log "未收斂 gap 處置:$RQ(tier 守衛/cross)"
  exit 0
fi

if [ "$MODE" = "--dry-run" ]; then
  cp "$SPEC" "$PENDING/" 2>/dev/null || true
  printf '%s\n' "$REPORT_MD" > "$PENDING/$(basename "$SPEC" .md)-confidence.md"
  log "dry-run:收斂!spec + 可信度報告寫入 $PENDING/(repo 未動)"
  LINE_TOKEN="$(cat "$HOME/.config/ai-daily/line_token" 2>/dev/null)" python3 -c "
import sys; sys.path.insert(0,'$REPO/governance')
from autonomous_loop import line_notify
t=os.environ.get('LINE_TOKEN','')
print('LINE', line_notify.send(line_notify.build_message('$TOPIC','(dry-run)收斂[跨家族:$CROSS_VERDICT]、待你看 pending/',None),t) if t else 'no-token')" || true
else
  cd "$REPO"; BR="auto/spec-$TOPIC-$TODAY"
  cp "$SPEC" "docs/design/$(basename "$SPEC")"
  git checkout -b "$BR"; git add "docs/design/$(basename "$SPEC")"
  git commit -m "auto-spec: $TOPIC（自主迭代 loop 收斂產出，待人放行）"
  echo "$REPORT_MD" | gh pr create --title "auto-spec: $TOPIC" --body-file - || true
  log "已開 PR(branch $BR)"
fi
log "完成。"
