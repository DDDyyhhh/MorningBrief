# Task 3 Report: API Client, Shared Module State, and Shared Widgets

## Implementation

Implemented Task 3 exactly from the brief in `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/.superpowers/sdd/task-3-brief.md`.

Created API client infrastructure:
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/core/api_client.dart`
  - `ApiClient.getJson(Uri uri)` returning `Future<Map<String, dynamic>>`
  - `ApiClient.getText(Uri uri)` returning `Future<String>`
  - `ApiClientException` with message and optional status code
  - 12 second default timeout
  - non-2xx responses mapped to `ApiClientException('请求失败', statusCode: ...)`
  - timeouts mapped to `ApiClientException('请求超时')`
  - non-object JSON mapped to `ApiClientException('返回数据不是 JSON 对象')`

Created shared module state:
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/module_state.dart`
  - `ModuleStatus` enum: `idle`, `loading`, `data`, `empty`, `error`, `offline`
  - `ModuleState<T>` factories: `idle`, `loading`, `data`, `empty`, `error`, `offline`
  - convenience flags: `isLoading`, `hasData`, `isEmpty`, `hasError`, `isOffline`
  - consumes `AppError` from `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/core/app_error.dart`

Created shared module interface:
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/morning_module.dart`
  - `MorningModule` abstract interface with `id`, `title`, `icon`, `isEnabled`, `buildCard`, and `refresh`
  - consumes `MorningModuleId` from `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/models/module_config.dart`

Created reusable shared widgets:
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/widgets/module_card.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/widgets/module_error_widget.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/widgets/module_loading_widget.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/widgets/module_empty_widget.dart`

## Tests Added

Created the requested tests:
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/test/shared/module_state_test.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/test/shared/module_widgets_test.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/test/core/api_client_test.dart`

## TDD Evidence

Followed the brief's TDD order.

1. Wrote `test/shared/module_state_test.dart` first.
   - RED verification: `flutter test test/shared/module_state_test.dart` failed because `lib/shared/module_state.dart` did not exist and `ModuleState` constructors were missing.
   - GREEN verification: after implementing `ModuleState`, the same command passed with 2 tests.

2. Wrote `test/shared/module_widgets_test.dart` before widget implementation.
   - RED verification: `flutter test test/shared/module_widgets_test.dart` failed because the shared widget files did not exist and widget classes were missing.
   - GREEN verification: after implementing shared widgets and `MorningModule`, `flutter test test/shared/module_state_test.dart test/shared/module_widgets_test.dart` passed with 5 tests.

3. Wrote `test/core/api_client_test.dart` before API client implementation.
   - RED verification: `flutter test test/core/api_client_test.dart` failed because `lib/core/api_client.dart`, `ApiClient`, and `ApiClientException` did not exist.
   - GREEN verification: after implementing `ApiClient`, the focused final test command passed.

## Verification

Ran the required focused test and analyzer command with the specified environment:

```bash
export PATH="/e/Program Files/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter test test/core/api_client_test.dart test/shared/module_state_test.dart test/shared/module_widgets_test.dart && flutter analyze
```

Result:
- `flutter test`: 7 tests passed, 0 failures.
- `flutter analyze`: `No issues found! (ran in 21.1s)`.

## Files Changed

- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/core/api_client.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/module_state.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/morning_module.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/widgets/module_card.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/widgets/module_error_widget.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/widgets/module_loading_widget.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/shared/widgets/module_empty_widget.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/test/core/api_client_test.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/test/shared/module_state_test.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/test/shared/module_widgets_test.dart`

## Self-Review

- Compared implementation against each interface and file listed in the task brief.
- Confirmed no scope expansion beyond Task 3.
- Confirmed API client, module state, module interface, and shared widgets use the exact strings and public APIs requested by the brief.
- Ran a low-effort diff review for runtime-correctness issues visible from the production hunks; no qualifying findings.
- Confirmed final focused tests and analyzer passed before commit preparation.

## Concerns

No implementation concerns.

Notes:
- Flutter emitted dependency update notices during test/analyze runs, but all dependencies resolved and verification passed. These notices are unrelated to Task 3.

## Review Fix: ApiClient exception normalization

Addressed the Task 3 review finding that `ApiClient` leaked raw parse and transport exceptions.

Files changed:
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/lib/core/api_client.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/test/core/api_client_test.dart`
- `/e/Claude_code_Project/MorningBrief/.worktrees/morningbrief-sdd/.superpowers/sdd/task-3-report.md`

Fix details:
- `getJson` now converts malformed JSON (`FormatException`) into `ApiClientException('返回数据不是有效 JSON')`.
- `getJson` continues converting non-object JSON into `ApiClientException('返回数据不是 JSON 对象')`.
- `getText` continues preserving timeout and non-2xx behavior.
- `getText` now converts `http.ClientException` and `SocketException` into `ApiClientException`.

TDD evidence:
- Added failing tests first for malformed JSON, non-object JSON, `http.ClientException`, and `SocketException` normalization.
- RED verification: `flutter test test/core/api_client_test.dart` failed because malformed JSON leaked `FormatException`, and client/transport failures leaked raw exceptions.
- GREEN verification: after updating `ApiClient`, `flutter test test/core/api_client_test.dart` passed with 6 tests.

Verification commands run with:

```bash
export PATH="/e/Program Files/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

Results:
- `flutter test test/core/api_client_test.dart`: 6 tests passed, 0 failures.
- `flutter test test/shared/module_state_test.dart test/shared/module_widgets_test.dart test/core/api_client_test.dart`: 11 tests passed, 0 failures.
- `flutter analyze`: `No issues found! (ran in 11.7s)`.

Concerns:
- No implementation concerns.
- Flutter emitted dependency update notices during test/analyze runs, but all dependencies resolved and verification passed. These notices are unrelated to this fix.
