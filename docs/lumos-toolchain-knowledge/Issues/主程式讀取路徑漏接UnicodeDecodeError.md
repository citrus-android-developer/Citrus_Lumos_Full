---
type: issue
status: open
created: 2026-08-02
updated: 2026-08-02
related:
  - "[[Verification/2026-08-02_slim三缺陷修復_實驗產出]]"
  - "[[Systems/slim-uninstall-一行卸載]]"
  - "[[Systems/診斷迴圈先行]]"
tags:
  - type/issue
  - status/open
summary: |-
  FLAG:TECHNICAL — 未修,刻意不在 slim 修復那一次順手擴大範圍;嚴重度自評 minor(開發者工具吐 traceback,非資料損毀),但★是剛在 slim 判定為缺陷的同一個類別★,不修就等於雙標
  KEY:`scripts/lumos` 有 ★20 處★ `read_text`/`read_bytes` 包在只接 `OSError` 的 try 裡——`UnicodeDecodeError` 繼承 `ValueError` 不是 `OSError` 子類,攔不到,直接 traceback 炸給使用者
  KEY:★不是全部 20 處都是真風險★——讀我們自己產的檔(架構圖節點/`.lumos/testmap.json`/canary log)本來就一定是 utf-8(寫入端 BOM/CRLF 拒寫);真風險只在★吃 CLI 參數路徑、讀別人的檔★那幾處,含收斂閘 `--spec` 走的 `refcheck`
  KEY:★已跑過會翻紅的指令(依 [[Systems/診斷迴圈先行]] 完成判準,不是讀 code 推理出來的)★:`printf` 造一個含 `\xff\xfe` 的 .md → `lumos refcheck bad.md --repo <repo>` → `UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 23` 完整堆疊
  KEY:發現路徑=修完 slim 的姊妹漏洞後,拿★同一副鏡頭★(「防護只涵蓋寫、漏了讀」+「只接 OSError、漏了非 OSError 子類」)回頭掃主程式。★把一次缺陷的形狀變成一副可重複使用的鏡頭,比修掉那一次更值錢★
  DECISION:[2026-08-02]先立節點不修——(a)與當下交付修復無關,順手擴大範圍會讓那次 commit 的因果變糊 (b)20 處要逐處判「這個檔是誰寫的」,不是機械替換 (c)沒有使用者回報過。待排(valid)
---
# 主程式讀取路徑漏接 `UnicodeDecodeError`

## 白話

**`lumos` 讀檔時只防了「讀不到」，沒防「讀得到但看不懂」。** 餵它一個編碼壞掉的檔案，它不會好好講一句「這個檔不是 UTF-8」，而是吐一整段程式堆疊。

## 可重現（已跑過）

```bash
mkdir /tmp/lumos-enc-probe && cd /tmp/lumos-enc-probe
python3 -c "open('bad.md','wb').write(b'---\ntype: system\n---\n# \xff\xfe not utf8\n')"
lumos refcheck bad.md --repo <某個 repo>
# → UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 23: invalid start byte
#   (完整 traceback)
```

## 根因

`UnicodeDecodeError` 繼承 `ValueError`，**不是 `OSError` 子類**。所以

```python
try:
    text = path.read_text(encoding="utf-8-sig")
except OSError as e:          # ← 攔不到編碼錯誤
    ...
```

AST 掃描結果：`scripts/lumos` 共 **20 處** `read_text`/`read_bytes` 落在只接 `OSError`（或 `FileNotFoundError, OSError`）的 try 裡。

## 但不是 20 處都是真風險

| 讀的是誰的檔 | 例子 | 風險 |
|---|---|---|
| **我們自己寫的** | 架構圖節點、`.lumos/testmap.json`、canary log | 低——寫入端本來就 BOM/CRLF 拒寫、只寫 utf-8 |
| **別人的／CLI 參數指定的** | `refcheck <spec>`、`--file <清單>`、`spec-trace <節點>` | **真風險** |
| **已經自保的** | `errors="replace"`（版本偵測那處） | 無 |

**收斂閘的 `--spec` 走的正是 `refcheck`** ——架構圖節點理論上是我們寫的，但路徑由使用者給，指到任何檔都行。

## 為什麼先不修（2026-08-02 決定）

1. 與當下那次 slim 交付修復**無關**，順手擴大範圍會讓那次 commit 的因果變糊。
2. 20 處要**逐處判斷「這個檔是誰寫的」**，不是機械替換 `except OSError` → `except (OSError, UnicodeDecodeError)`。無差別替換會把「我們自己寫壞了 utf-8」這種真 bug 也吞掉。
3. 沒有使用者回報過。嚴重度自評 **minor**——開發者工具吐 traceback，不是資料損毀。

★**但要誠實記著：這跟剛在 `slim/` 判定為 major 的是同一個類別。**★ 差別只在爆炸半徑（slim 那邊會讓卸載步驟整段不執行、留下殘留檔）。不修可以，**雙標不行**——所以立節點。

## 這件事真正的收穫

發現路徑是：修完 `slim/` 的姊妹漏洞後，**拿同一副鏡頭回頭掃主程式**。鏡頭是兩句話：

> 「防護只涵蓋了**寫**，漏了**讀**嗎？」
> 「只接了 `OSError`，漏了**非 `OSError` 子類**的例外嗎？」

★**把一次缺陷的形狀，變成一副可以重複使用的鏡頭，比修掉那一次更值錢。**★
