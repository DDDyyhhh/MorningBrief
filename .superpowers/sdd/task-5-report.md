# Task 5 Report: Calendar and Schedule Module

## Status
DONE_WITH_CONCERNS

## Implementation Summary
- Added `CalendarService` abstraction with in-memory and SQLite implementations.
- Added `CalendarProvider` using `ModuleState<List<CalendarEvent>>` with loading, data, empty, and storage-error states.
- Added `CalendarCard` rendering today's schedule, empty/loading/error states, event times, and completion toggles.
- Wired `SqliteCalendarService` and `CalendarProvider` into `lib/main.dart` via `MultiProvider`.
- Replaced the home screen calendar placeholder with `CalendarCard`.
- Updated existing widget tests to provide `CalendarProvider`, matching the new runtime dependency.

## Files Changed
- `lib/modules/calendar/calendar_service.dart` created
- `lib/modules/calendar/calendar_provider.dart` created
- `lib/modules/calendar/calendar_card.dart` created
- `lib/main.dart` modified
- `lib/shared/screens/home_screen.dart` modified
- `test/modules/calendar/calendar_service_test.dart` created
- `test/modules/calendar/calendar_provider_test.dart` created
- `test/widget_test.dart` modified
- `test/shared/home_screen_test.dart` modified

## TDD Evidence

### Calendar service RED
Command:
```bash
flutter test test/modules/calendar/calendar_service_test.dart
```
Observed failure before implementation:
- Missing `lib/modules/calendar/calendar_service.dart`
- `MemoryCalendarService` not found

### Calendar service GREEN
Command:
```bash
flutter test test/modules/calendar/calendar_service_test.dart
```
Observed:
- `+2: All tests passed!`

### Calendar provider RED
Command:
```bash
flutter test test/modules/calendar/calendar_provider_test.dart
```
Observed failure before implementation:
- Missing `lib/modules/calendar/calendar_provider.dart`
- `CalendarProvider` not found

### Calendar provider GREEN
Command:
```bash
flutter test test/modules/calendar/calendar_provider_test.dart
```
Observed:
- `+1: All tests passed!`

### Existing widget integration failure and fix
After adding `CalendarCard`, existing widget tests failed because they rendered the home screen without the newly-required `Provider<CalendarProvider>`. Root cause: `CalendarCard` calls `context.watch<CalendarProvider>()`, but test harnesses only provided `ModuleConfigProvider`. Updated test harnesses to use `MultiProvider` with `CalendarProvider(MemoryCalendarService())`.

## Verification

### Required test and analyzer command
Command:
```bash
flutter test test/modules/calendar/calendar_service_test.dart test/modules/calendar/calendar_provider_test.dart test/widget_test.dart test/shared/home_screen_test.dart && flutter analyze
```
Observed:
- `+5: All tests passed!`
- `No issues found!`

### Code review
A review subagent inspected the Task 5 changes and reported:
- Critical: none
- Important: none
- Minor: none

### Runtime verification attempt
Attempted to launch the app surface:
- `flutter run -d windows` could not run because no Windows desktop project is configured.
- `flutter run -d chrome` launched debug service but target crashed after startup; project output also stated it is not configured to build on the web.

Because the task target context is Android and no Android device/emulator was available in this environment, runtime GUI verification could not be completed here. Automated verification and analyzer passed.

## Commit
- `129c73d feat: add local calendar module`

## Self-Review
- Confirmed Task 5 requested files are present.
- Confirmed service API matches the brief: `createEvent`, `todayEvents`, `toggleCompleted`, `deleteEvent`.
- Confirmed provider API matches the brief: `loadToday`, `addEvent`, `toggleCompleted`, `deleteEvent`.
- Confirmed home dashboard uses `CalendarCard` for `MorningModuleId.calendar`.
- Confirmed SQLite service uses existing `calendar_events` schema from `AppDatabase`.
- Confirmed analyzer is clean after removing the unused import from the generated service test.

## Concerns
- Runtime app verification was blocked by available device/project configuration: no Windows desktop project, web target crashed/not configured, and no Android device was listed.


---

## Review Fix: Calendar Isolation

### Files Changed
- `lib/main.dart`
- `lib/modules/calendar/calendar_provider.dart`
- `test/modules/calendar/calendar_provider_test.dart`
- `.superpowers/sdd/task-5-report.md`

### Fix Summary
- Moved app startup wiring into `startApp()` and isolated calendar database opening inside `_createCalendarProvider()` so `runApp` still executes when calendar SQLite initialization fails.
- Added a calendar fallback path that uses `MemoryCalendarService` and sets the calendar provider to storage-error state (`日程读取失败`) when database initialization or initial calendar loading fails.
- Wrapped `CalendarProvider.addEvent`, `toggleCompleted`, and `deleteEvent` service calls so storage/mutation exceptions become `ModuleStatus.error` with `日程保存失败` instead of escaping as unhandled async errors.
- Added focused provider tests covering mutation failures and startup rendering when calendar DB initialization fails.

### Test Commands and Results
Command:
```bash
export PATH="/e/Program Files/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && flutter test test/modules/calendar/calendar_provider_test.dart
```
Result:
- RED before implementation: new mutation tests failed with `Bad state: write/update/delete failed`; startup test failed because `startApp` did not exist.
- GREEN after implementation: `+5: All tests passed!`

Command:
```bash
export PATH="/e/Program Files/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && flutter test test/modules/calendar/calendar_service_test.dart test/modules/calendar/calendar_provider_test.dart test/widget_test.dart test/shared/home_screen_test.dart
```
Result:
- `+9: All tests passed!`

Command:
```bash
export PATH="/e/Program Files/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && flutter analyze
```
Result:
- `No issues found! (ran in 12.0s)`

### Runtime Verification Note
- Checked for project verifier skills under `.claude/skills`, `lib/.claude/skills`, and `test/.claude/skills`; none were present.
- `flutter devices` listed Windows, Chrome, and Edge only.
- `flutter run -d windows` was blocked because no Windows desktop project is configured.
- `flutter run -d chrome --web-port=0` was blocked by web project configuration (`This application is not configured to build on the web`) and did not reach an observable app surface before timeout.
