# AGENTS.md（Codex 等外部 agent 的入口指路檔）

本 repo 的規矩與現況**單一來源**如下，本檔只指路、不複製內容（防漂移）：

1. **專案規矩**：讀 `CLAUDE.md`（架構圖先行、零依賴家規、合約鏈、寫入規範）。
2. **系統現況**：讀 `docs/lumos-toolchain-knowledge/MOC/index.md`（知識架構圖索引），再按需讀 `Systems/`（機制）、`Projects/`（計劃與決策）、`Verification/`（驗證紀錄）。架構圖是唯一真相來源，與 code 衝突以架構圖的合約（★INVARIANT★）為準。
3. **CLI**：`python3 scripts/lumos --help`（61 個頂層命令；讀架構圖用 `context`/`search`/`contracts`/`query`）。
4. 你通常被以唯讀審計員/協作者身分派入：**不要**改 `docs/*-knowledge/` 下的檔（那是 lumos 管的），發現問題用報告回覆。
