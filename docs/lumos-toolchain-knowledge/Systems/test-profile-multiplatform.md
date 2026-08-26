---
type: system
status: done
created: 2026-07-02
updated: 2026-07-30
self_audit: sonnet/2026-07-02
related:
  - "[[Systems/check-t-sentinel]]"
verified_by:
  - "[[Verification/2026-07-02_multiplatform-test-binding]]"
  - "[[Verification/2026-07-25_CheckT-Python-profile]]"
plan_refs:
  - "[[Projects/多平台合約測試綁定_計劃]]"
tags:
  - type/system
  - status/done
summary: |-
  FLOW:load_platforms 讀 .lumos/config→{multiplatform,default_platform,platforms:{plat:{profile,root}}}→resolve_test_refs 把 [test:plat:name] 逐段解析為 (plat,name)→_platform_test_index 惰性建每平台 root+profile 的 method set/haystack→Check T/classify_invariants/cmd_archive 各 ref 對其平台判 real/fake/dangling(跨 repo)
  KEY:單一架構圖跨平台綁測試——config 從單 test_profile 擴為 platforms 多根多 profile map;[test:plat:name] 的**平台前綴**(android/backend/maestro/playwright)★注意:平台前綴≠profile 名★——profile 名是 csharp-xunit/kotlin-junit/maestro/playwright/dart/python 共 6 個(見下方 KEY);兩者同名的只有 maestro/playwright,android 對應 kotlin-junit、backend 對應 csharp-xunit
  KEY:向後相容以「config 有無 platforms 鍵」為信號(multiplatform bool)——無 platforms=legacy,resolve 不切分整串當方法名,舊 test_profile/裸 [test:X] 照舊
  KEY:default_platform 規則——多平台缺省即報錯(不猜);未定義平台前綴 [test:foo:X] Check T 明確報錯(不 fallback)
  KEY:新增內建 profile maestro(綁 flow name:,file_must_match=^appId: 濾非flow yaml,\s*$ 錨多字 name NO MATCH)/ playwright(綁 test('id'),多字 title NO MATCH)
  KEY:file_must_match 是 discover 選填 knob(讀檔後去註解前過濾,.get() 相容無此鍵的舊 profile)
  KEY:guard bind/scaffold --platform 旗標——method 維持識別字、平台另帶,bind 寫 [test:plat:method] 去重/verify 比完整 ref;scaffold 範本/scaffold_ext/測試目錄偵測跟平台 root 走
  KEY:天花板——Check T 只驗測試識別子存在,不驗跑綠(CI 的事);E2E 要裝置/瀏覽器(無裝置才 skip);跨 repo 只讀不寫
  KEY:dart profile(2026-07-26,taroko_app Flutter 接入)=第 6 個 profile:DART_TEST_RE 認 test('id')/testWidgets('id')(識別字名才可綁,含空白 NO MATCH 同 playwright 設計)+檔名錨 *_test.dart+comment_strip=c-style(Dart 有雙式註解)+scaffold_name={m}_test;dirs pure=test/、behavioral 含 integration_test/ [test:t_dart_profile_discovery]
  KEY:python profile(2026-07-25,[[Projects/CheckT-Python-profile_計劃]])=第 5 個 profile:行首錨 PYTHON_TEST_RE+檔名錨 file_name_match(basename fnmatch,新欄位,與 maestro file_must_match 內容錨是兩機制)+comment_strip="none"+scaffold_name 模板;discover_test_methods 的註解剝離改語言感知(c-style 預設向後相容)——根因:原對所有語言剝 /*..*/,Python 檔中文註解/字串的巧合配對會吃掉大段內容(本 repo 實測 260→94)。新欄位放 TEST_PROFILES dict 靜態值(multiplatform 路徑繞過 load_test_profile,dict 直達兩路徑都吃到)
  DEP:[[Systems/check-t-sentinel]]
  TEST:t_maestro_profile_discover｜t_playwright_profile_discover｜t_load_platforms｜t_resolve_test_refs｜t_multiplatform_guard_list｜t_multiplatform_doctor_check_t｜t_archive_live_guard_multiplatform｜t_guard_trace_multiplatform｜t_guard_bind_scaffold_platform(333 passed)
  VERIFY:[[Verification/2026-07-02_multiplatform-test-binding]]
aliases:
  - 多平台合約測試綁定
---
# 多平台合約測試綁定（test-profile multiplatform）

讓**單一知識架構圖**把 ★INVARIANT★ 的 `[test:]` 綁到**不同平台**的測試（C# xunit / Kotlin JUnit / Maestro E2E / Playwright），解決舊機制「一 repo 一 profile、只掃自己 repo」的三道牆。設計與審計全紀錄見計劃節點 [[Projects/多平台合約測試綁定_計劃]]（design-loop 4 輪收斂）。

## 核心元件（scripts/lumos）

- `load_platforms(repo_root)`：讀 `.lumos/config.json` 的 `platforms` map（多根多 profile）。回 `{multiplatform, default_platform, platforms:{plat:{profile,root}}}`。無 `platforms` 鍵 → legacy 單一條目（向後相容）。
- `resolve_test_refs(inv_text, platforms, default_platform)`：`[test:...]` → `[(platform, name)]`。`platforms` 空（legacy）不切分；非空則含冒號段前綴須為已定義平台（否則 raise）、無冒號段歸 default。
- `_platform_test_index(repo_root)`：惰性建「平台 → (method set, code haystack)」索引，Check T / `classify_invariants` / `cmd_archive` 共用（haystack 也跨 repo）。
- 新內建 profile `maestro` / `playwright`（見 `TEST_PROFILES`），`discover_test_methods` 新增 `file_must_match` 選填 knob。
- **本節點亦為 `test_profile` 機制（原 P5，`csharp-xunit`/`kotlin-junit`）的權威說明**——P5 當初未建 Systems 節點，此處一併涵蓋四 profile，不另建重複節點（L4 審計 2026-07-02 決策）。`csharp-xunit`=預設（`.cs`/`[Fact]`/頂層 `*Tests` suffix）、`kotlin-junit`=Android 單元（`.kt`/`@Test`/`src/` 下 rglob）。
- `guard bind` / `guard scaffold` 新增 `--platform` 旗標。

## 相關系統
- [[Systems/check-t-sentinel]]（Check T/K 機制；本機制擴充其 discover 面為多平台多根）
