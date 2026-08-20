#!/usr/bin/env bash
# get.sh — 遠端一鍵裝:clone Lumos 後整段委派 bootstrap(機器層+專案層自動接線)。
# 用法:  curl -fsSL https://raw.githubusercontent.com/citrus-android-developer/Citrus_Lumos_Full/main/get.sh | bash
#   旗標: --pull(既有 clone 也拉最新)/--init(無 vault 的 repo 免確認建圖譜)
#         curl -fsSL <url> | bash -s -- --pull --init
#   環境變數:LUMOS_HOME(預設 ~/harness/lumos-toolchain)、LUMOS_URL(預設 GitHub)
# 站在專案 repo 內跑 → bootstrap 會問「要建成 lumos 專案嗎?」(y 才建;非互動跳過)。
set -euo pipefail
LUMOS_HOME="${LUMOS_HOME:-$HOME/harness/lumos-toolchain}"
LUMOS_URL="${LUMOS_URL:-https://github.com/citrus-android-developer/Citrus_Lumos_Full}"

# 迴圈解析(舊碼單點比對 $1,並帶兩旗標會無聲吃掉第二個);未知旗標 warn 忽略
ARGS=()
for a in "$@"; do
  case "$a" in
    --pull|--init) ARGS+=("$a") ;;
    *) echo "WARN: 未知旗標 $a(忽略;只認 --pull/--init)" >&2 ;;
  esac
done

if [[ -f "$LUMOS_HOME/scripts/lumos" ]]; then
  echo "[clone] Lumos 源已在: $LUMOS_HOME"
else
  echo "[clone] clone Lumos → $LUMOS_HOME …"
  mkdir -p "$(dirname "$LUMOS_HOME")"
  git clone "$LUMOS_URL" "$LUMOS_HOME"
fi

# 其餘全交 bootstrap(機器層 install+skills、專案層四分流;set -e 保錯誤傳播)
LUMOS_HOME="$LUMOS_HOME" python3 "$LUMOS_HOME/scripts/lumos" bootstrap ${ARGS[@]+"${ARGS[@]}"}

echo
echo "✓ 完成。最後一步:**重啟 Claude Code session**(hooks 在 session start 載入)"
