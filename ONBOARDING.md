# Lumos 上手指南(ONBOARDING)

> **Lumos —— 揭開全 AI 開發的黑箱,照亮通往正確需求的路。**

這份給新加入、要開始用「架構圖即合約」這套方法論的人。照著做即可,不用問。

---

## TL;DR — 一鍵(推薦)

clone 專案後,在專案裡跑一個指令,**連 Lumos 都會自動幫你 clone**,skills / 全域 lumos / hooks 一次裝好:

```bash
git clone <你的專案> && cd <你的專案>
python3 scripts/lumos bootstrap     # 自動:clone Lumos + skills + 全域 lumos + repo hooks
# 然後重啟 Claude Code session(L1/L3 hooks 要 session start 載入)
```

之後再 clone 別的專案,因為機器已設定好,只要 `python3 scripts/lumos bootstrap`(或 `scripts/install-hooks.sh --force`)即可。

> `bootstrap` 做的事 = 下面「手動三步」的自動版,適用**已導入 Lumos(專案已帶 `scripts/lumos`)**的 repo。
>
> **全新、還沒帶 `scripts/lumos` 的專案**改走兩條指令:
> ```bash
> cd <你的專案> && curl -fsSL https://raw.githubusercontent.com/citrus-android-developer/Citrus_Lumos_Full/main/get.sh | bash
> # 一鍵到底(2026-07-25 起):機器層+專案層 auto-init(會先問一句,按 y 建架構圖+工具+hooks);顆粒操作(只 init/只 install)見 README 4b
> ```
> **原生 Windows(PowerShell)**改用 `get.ps1` 入口:`irm https://raw.githubusercontent.com/citrus-android-developer/Citrus_Lumos_Full/main/get.ps1 | iex`(全域 lumos 用 `.cmd` shim、skills 用 junction),重啟 session 後 `cd <你的專案>; lumos init`。詳見 [README 4c](README.md)。
> (離線/企業內網仍可用手動 `install-graph-toolchain`,見維護者備註。)

<details><summary>手動三步(bootstrap 底層做的事)</summary>

```bash
# ① 一次性(每台機器):裝共用 skills（缺 Lumos 先 git clone <URL> ~/harness/lumos-toolchain）
~/harness/lumos-toolchain/install.sh
# ② 每個專案 repo:裝 hooks
cd <你的專案> && scripts/install-hooks.sh --force
# ③ 選用:全域 lumos
~/harness/lumos-toolchain/scripts/lumos install
```
</details>

---

## 前置需求

| 需要 | 用途 | 沒有會怎樣 |
|------|------|-----------|
| `git` | 全部 | 無法運作 |
| `python3` | lumos CLI + hooks merge(純標準庫,不裝套件) | 無法運作 |
| Claude Code | skills / hooks 才會 fire | 工具能跑,但 AI 不會自動載方法論 |
| Claude Max 訂閱 | 第三層 AI 後驗(L3)才划算 | L3 後驗會吃配額/降級,其餘正常 |
| notesmd-cli(選用) | rename/移檔(`graph-rename.sh`) | 只有改檔名時才需要;`fetch-notesmd.sh` 可抓 |

---

## Step ① 一次性(每台機器):共用 skills

`lumos-project-notes` / `lumos-core-knowledge` 是 **user-scope** 共用 skill(跨所有專案、不在任何 product repo 裡),唯一源就是這個 repo。

```bash
git clone <lumos-toolchain repo URL> ~/harness/lumos-toolchain
cd ~/harness/lumos-toolchain
./install.sh          # symlink ~/.claude/skills/lumos-* → 本 repo(預設)
```

- **更新 = `git pull`**,symlink 即時生效,不必重裝。
- 不想 symlink → `./install.sh --copy`(但更新要再跑一次)。
- 移除 → `./install.sh --uninstall`(機器層)。

## Step ② 每個專案(每 clone 一個 repo 做一次):hooks

```bash
git clone <你的專案 repo>
cd <你的專案>
scripts/install-hooks.sh --force
```
裝三樣:
- **git hooks**(pre-commit 擋「改 code 沒更新架構圖」/ post-commit 留痕 / pre-push 跑 lumos doctor)— 透過 `core.hooksPath`,**per-clone 必裝一次**
- **Claude hooks**(L1 收工提醒 / L3 提交後 AI 後驗)→ 複製到 `~/.claude/hooks/`
- **settings 註冊** → merge 進 `~/.claude/settings.json`

> `--force` 是必要的:你機器上可能有舊版 Claude hooks,不 force 會被 skip 不更新。

## Step ③ 選用(每台機器):全域 lumos 命令

```bash
python3 scripts/lumos install     # ~/.local/bin/lumos
```
之後任何專案目錄直接 `lumos doctor`,不必打 `python3 scripts/lumos`。不裝也行。

---

## 卸載(移除)

Lumos 分兩層卸載:

- **專案層** —— `cd <你的專案> && lumos deinit` 移除該 repo 的 hooks/工具組/CLAUDE.md 區塊/架構圖(見 README「卸載」段)
- **機器層** —— `lumos uninstall` 移除全域 `~/.local/bin/lumos`;移除 user-scope skills 用 `cd ~/harness/lumos-toolchain && ./install.sh --uninstall`(或 `rm -rf ~/harness/lumos-toolchain`)

---

## 日常使用

**核心原則(也寫在每個專案的 CLAUDE.md):**
- 知識架構圖(`docs/<專案>-knowledge/`)是**唯一真相來源**;程式碼只是「現在長這樣」,架構圖是「為什麼 + 邊界 + 驗證過沒」。
- **實時更新**:影響系統行為/決策/驗證的 code 變更,**同一次工作內**更新架構圖(pre-commit 會擋)。
- 動架構圖一律用 **lumos**,別直接 Grep/Edit 亂改 `.md`。

**常用指令:**
```bash
lumos doctor                  # 健康巡檢(破連結/孤節點/verified_by 同步/合約測試綁定…)
lumos context <節點>          # 進場掃脈絡(節點+鄰居,突顯 ⚠ 合約)
lumos search <詞>             # 全文搜尋
lumos contracts [節點]        # 動模組前查硬合約(★INVARIANT★)
lumos set <節點> <key> <值>   # 改 frontmatter 純量(status/updated…)
lumos append <節點> <key> "[[x]]"   # 加 verified_by/plan_refs/related(自動去重)
lumos new <type> <名稱>       # 依模板建節點(system/verification/issue/project)
lumos archive --days 180      # 滾動歸檔(dry-run 預設;活守衛護欄保護仍存活的守衛證據)
```
body 內容(進度段落、checkbox、表格)用 Edit;rename/移檔用 `scripts/graph-rename.sh`。

---

## 更新

| 要更新 | 怎麼做 |
|--------|--------|
| 共用 skills | `cd ~/harness/lumos-toolchain && git pull`(symlink 立即生效);或在任一專案 `python3 scripts/lumos bootstrap --pull`(既有 clone 也拉最新後重裝) |
| **某專案的 vendored 工具組(lumos/hooks/紀律範本)** | 在該專案目錄跑 **`lumos update`** — 自動 `git pull` Lumos 來源 + 重新 vendor(工具組更新、CLAUDE.md 紀律同步、hooks 重裝、**架構圖資料 scaffold-skip 不動**)。`--no-pull` 用現有來源、`--source <path>` 指定來源 |

> `lumos update` 就是 `install-graph-toolchain --target <本專案>` 的便利包裝:它從 cwd 自動偵測專案 root + slug,從 Lumos 唯一源(`$LUMOS_HOME` 或 `~/harness/lumos-toolchain`)拉最新再 vendor 進來。等於「一鍵把本專案的工具組對齊 Lumos」。

---

## 唯一源 vs 各專案 vendor copy

**Lumos repo 是整個工具組的唯一源**(CLI / hooks / 安裝器 / 範本 / skills 都在這)。但實際生效分兩種 scope:

| 元件 | 唯一源 | 實際生效在哪 | scope |
|------|--------|-------------|-------|
| skills | Lumos `skills/` | symlink → `~/.claude/skills/` | user(全機一份) |
| lumos CLI + git hooks | Lumos `scripts/` | **vendor 進各專案 `scripts/`** | project |
| Claude hooks(L1/L3) | Lumos `scripts/hooks/claude/` | install-hooks 裝到 `~/.claude/hooks/` | user |

**為什麼工具組要 vendor 進專案、不能只留 Lumos 一份**:CI 只 checkout 專案 repo(跑 `scripts/lumos doctor`)、git hook 是 per-repo——所以 lumos/hooks 必須在專案 repo 裡。模型是「**Lumos 唯一源 → install-graph-toolchain 把它 vendor 進專案**」,要升級就再從 Lumos 跑一次(idempotent)。skills 例外:它是純方法論文件,user-scope 共用一份不必 vendor。

---

## 疑難排解

- **AI 沒有自動用架構圖方法論** → Step ① 沒做(該機沒裝 user-scope skills)。`ls ~/.claude/skills/` 看有沒有 `lumos-*`。
- **commit 被擋「改了 code 沒更新架構圖」** → 正常,這是 pre-commit gate。更新對應架構圖節點再 commit;真的不需要架構圖(typo/格式)才 `git commit --no-verify`。
- **`lumos: command not found`** → 沒做 Step ③,改用 `python3 scripts/lumos`;或確認 `~/.local/bin` 在 PATH。
- **hooks 沒作用** → 在該專案 repo 跑過 `scripts/install-hooks.sh --force` 沒?`git config core.hooksPath` 應顯示 `scripts/hooks`。

---

## 維護者備註(owner)

- **本 repo 是整個工具組的唯一源**(CLI / hooks / 安裝器 / 範本 / skills)。改任何工具組檔案 = 改這裡 → `git push`。
  - skills 改完團隊 `git pull` 即同步(symlink);CLI/hooks 改完,各專案要再跑一次 install-graph-toolchain 才更新它們的 vendored copy。
- **裝進「新專案」**(從 Lumos 跑):
  ```bash
  ~/harness/lumos-toolchain/scripts/install-graph-toolchain.sh --target <新 repo 路徑> --slug <知識庫名>
  ```
  把 lumos+hooks+範本 vendor 進去、注入 CLAUDE.md 紀律、scaffold 架構圖、裝 hooks。重跑 = 工具組更新(架構圖資料不動)。
- **不放進本 repo**:各專案的業務架構圖、app 發版/部署腳本(release.sh 等)、project-scope 技術棧 skill。
- 此 repo 已公開:推任何東西前確認**無公司識別資訊**(專案名/表名/業務規則/內部 repo 名);skills 與範本用通用範例,真實業務域活在各專案自己的架構圖。
