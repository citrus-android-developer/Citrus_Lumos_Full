---
type: verification
status: pass
feature: 多平台合約測試綁定（多根多 profile + maestro/playwright + [test:plat:name]）
commit: (working tree, 未 commit)
date: 2026-07-02
plan_refs:
  - "[[Projects/多平台合約測試綁定_計劃]]"
valid_under:
  - "scripts/lumos 單檔架構（TEST_PROFILES / discover_test_methods / classify_invariants / cmd_archive / cmd_guard_scaffold / cmd_guard_bind / cmd_guard_trace）"
  - "test_lumos.py 自建 t_* harness（python3 stdlib、subprocess + 模組 import 兩式）"
  - "csharp-xunit / kotlin-junit / maestro / playwright 四 profile 的 method_re 與 file_must_match 現行定義"
revalidate_when:
  - "TEST_PROFILES 結構或任一 profile 的 method_re/file_must_match 變更"
  - "load_platforms / resolve_test_refs / _platform_test_index 簽章或回傳結構變更"
  - "guard bind/scaffold CLI 參數變更（尤其 --platform）"
  - "IDENT_RE 放寬（會影響含空白 title/name 的可綁性結論）"
tags:
  - type/verification
  - status/pass
---
# 驗證：多平台合約測試綁定

計劃 [[Projects/多平台合約測試綁定_計劃]] T1–T5 實作，TDD（每項先寫失敗測試→實作→綠）。

## 變更範圍（scripts/lumos）
- `TEST_PROFILES` 新增 `maestro`、`playwright`；`MAESTRO_NAME_RE`/`MAESTRO_FLOW_RE`/`PLAYWRIGHT_TEST_RE`。
- `discover_test_methods` 新增 `file_must_match`（`.get()` 相容舊 profile，讀檔後去註解前過濾）。
- 新增 `load_platforms`、`resolve_test_refs`、`_platform_test_index`、`_classify_one`。
- `classify_invariants` / Check T（cmd_doctor）/ `cmd_archive` / `cmd_guard_trace` 改多平台感知（跨 repo）。
- `cmd_guard_scaffold` / `cmd_guard_bind` 加 `--platform`（bind 寫 `[test:plat:method]`、去重/verify 比完整 ref；scaffold 範本/副檔名/目錄偵測跟平台 root）。

## 測試項目（test_lumos.py，333 passed / 0 failed）

| 測試 | 覆蓋 | 結果 |
|------|------|------|
| t_maestro_profile_discover | maestro name: 綁定、file_must_match 濾非 flow、多字 name NO MATCH | ✅ |
| t_playwright_profile_discover | playwright test('id') 綁定、多字 title 不收 real | ✅ |
| t_load_platforms | 向後相容（無 config/舊 test_profile）+ 多平台 + default_platform 缺省/指向不存在報錯 | ✅ |
| t_resolve_test_refs | 平台前綴解析、無前綴 fallback、未定義前綴報錯、legacy 不切分 | ✅ |
| t_multiplatform_guard_list | 前端 Kotlin + 後端 C# 跨 repo 各自 discover → 真綁 2 | ✅ |
| t_multiplatform_doctor_check_t | 跨 repo 綁真方法+審計 → Check T 過；未定義前綴 → 報錯 | ✅ |
| t_archive_live_guard_multiplatform | 活守衛護欄跨 repo（後端 C# 守衛存活 → Verification 保留） | ✅ |
| t_guard_trace_multiplatform | trace 剝平台前綴後命中 Verification | ✅ |
| t_guard_bind_scaffold_platform | bind 寫 [test:plat:method]+去重、scaffold 依平台 profile 副檔名 | ✅ |

既有 296 案例全數維持綠（向後相容無回歸）。

## 測試方式
`python3 scripts/test_lumos.py`（退出碼 0）。多平台案例以暫存目錄建「主 repo（架構圖）+ sibling 後端 repo」雙 root fixture 驗跨 repo discover。

## 天花板（同計劃）
Check T 只驗測試識別子存在、不驗跑綠（CI 的事）；E2E 要裝置/瀏覽器（無裝置才 skip）；跨 repo 只讀不寫。T6 架構圖補建 + T7 docs 為落地收尾，尚未 git commit。

## 相關模組
- [[Systems/test-profile-multiplatform]]
- [[Systems/check-t-sentinel]]
