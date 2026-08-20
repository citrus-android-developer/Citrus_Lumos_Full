# get.ps1 — 用法:  irm https://raw.githubusercontent.com/citrus-android-developer/Citrus_Lumos_Full/main/get.ps1 | iex
$ErrorActionPreference = "Stop"
$homeDir = if ($env:LUMOS_HOME) { $env:LUMOS_HOME } else { "$HOME\harness\lumos-toolchain" }
$url = if ($env:LUMOS_URL) { $env:LUMOS_URL } else { "https://github.com/citrus-android-developer/Citrus_Lumos_Full" }
if (-not (Test-Path "$homeDir\scripts\lumos")) {
  New-Item -ItemType Directory -Force -Path (Split-Path $homeDir) | Out-Null
  git clone $url $homeDir
}
python "$homeDir\scripts\lumos" install --force    # = 全域 lumos.cmd + skills
Write-Host "`n✓ 機器層裝好。下一步:"
Write-Host "  1. 重啟 Claude Code session(L1/L3 hooks 在 session start 載入)"
Write-Host "  2. 進你的專案:cd <專案>; lumos init"
