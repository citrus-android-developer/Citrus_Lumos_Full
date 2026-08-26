#!/usr/bin/env bash
# install-graph-toolchain.sh — 薄殼:vendor/scaffold 邏輯已收進 python 單一源(scripts/lumos)。
# 保留檔名供舊文檔/離線。解析既有 --target/--slug,轉呼叫 `lumos init`(在目標 repo 建架構圖 + vendor + hooks)。
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET=""; SLUG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --slug)   SLUG="${2:-}"; shift 2 ;;
    --no-hooks|--no-scaffold|--dry-run) shift ;;
    *) shift ;;
  esac
done
cd "${TARGET:-.}"
if [[ -n "$SLUG" ]]; then
  exec python3 "$HERE/lumos" init --name "$SLUG" --force
else
  exec python3 "$HERE/lumos" init --force
fi
