---
type: verification
status: pass
date: 2026-07-21
valid_under:
  - "show 掛 links/backlinks/context/map 派發組(args.note 命名),cmd_decisions 無條件 fallback 前有 show if 分支"
  - "唯讀語意=不改架構圖節點檔;usage-log 事件帳為預期副作用(同 context)"
revalidate_when:
  - "動 scripts/lumos 派發組(9656 一帶)或 split_frontmatter"
  - "動 _usage_log 簽章或讀側合約措辭"
plan_refs:
  - "[[Projects/lumos-show讀取入口_計劃]]"
tags:
  - type/verification
  - status/pass
summary: |-
  TEST:t_show 11 checks 全綠(找到全文/找不到 stderr+rc2/--body-only 剝離/模糊名沿 env.find/唯讀節點檔不變/派發組迴歸/重開檔失敗 rc2 無 traceback[壞 symlink 模擬]/無 frontmatter 檔印整檔)+全套迴歸 1268 passed 0 failed
  KEY:TDD 紅→綠——先寫 t_show 跑紅(invalid choice)再實作;實作三件套=cmd_show(:3717 前)+argparse show parser(note 命名,陷阱②)+派發組 tuple 加 show+fallback 前 if 分支(陷阱①)+utf-8-sig 開檔(陷阱③)+重開檔 try/except rc2
  KEY:實機 smoke——show 全文/--body-only/不存在 rc2 皆驗
  VERIFY:spec 過 light r1→ratchet→std panel 3 輪+Codex 否決席 3 次介入,實質收斂人裁(2026-07-21);golden 凍結 governance/golden/lumos-show讀取入口-std/
---
# 2026-07-21_lumos-show讀取入口

`lumos show <node> [--body-only]` 落地驗證。spec：[[Projects/lumos-show讀取入口_計劃]]（light 首戰 → ratchet → standard panel 實質收斂）。

- 測試：`python3 scripts/test_lumos.py -k t_show` → 11 checks 綠；全套 1268 passed 0 failed。
- 架構圖同步（同 commit）：`Systems/lumos-cli-read` 六處零副作用措辭＋12→13＋23→24＋show 條目＋doctor 寫者順手修真；`reference.md:85` 44→49（含漏列四指令歸類，加總自洽）；`README.md:42` 44→49；`lumos-project-notes` SKILL 禁 Read 段補 show 出口。
