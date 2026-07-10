# Repository Guidelines

## Project Structure & Module Organization

MorningBrief is a Flutter Android dashboard. Application code lives in `lib/`:

- `core/` contains API, cache, storage, database, theme, and shared error code.
- `models/` contains serializable domain models.
- `modules/<feature>/` groups a feature's service, provider, and card UI (for example, `modules/weather/`).
- `shared/` contains module state, configuration, reusable widgets, and screens.

Tests mirror this structure in `test/` (`test/core/`, `test/models/`, `test/modules/`, and `test/shared/`). There is no registered asset directory yet; add assets under `assets/` and declare them in `pubspec.yaml` when needed.

## Build, Test, and Development Commands

Run commands from the Flutter project root:

```bash
flutter pub get        # resolve dependencies
flutter run            # launch on an emulator or device
flutter test           # run the complete test suite
flutter analyze        # apply flutter_lints and project rules
dart format lib test   # format Dart source and tests
```

Use a focused test while iterating, for example:

```bash
flutter test test/modules/weather/weather_provider_test.dart
```

## Coding Style & Naming Conventions

Follow `dart format` output (two-space indentation). Use `snake_case.dart` filenames, `PascalCase` types, and `camelCase` members; prefix private implementation details with `_`. Keep feature boundaries explicit: API parsing belongs in services, state transitions and caching in `ChangeNotifier` providers, and rendering in cards/widgets. Avoid `print`; `analysis_options.yaml` enables Flutter lints plus const-constructor and immutable-literal preferences.

## Testing Guidelines

Use `flutter_test` with deterministic fakes such as `MemoryCacheManager` and mocked HTTP clients; tests must not call live APIs. Name tests as observable behavior, e.g. `WeatherProvider uses fresh cache without fetching`. Cover success, empty/API-key, error, cache, and offline paths when changing a module. Run `flutter analyze` and the relevant focused test before the full suite.

## Commit & Pull Request Guidelines

Follow the existing Conventional Commit style: `feat: add weather module`, `fix: normalize ApiClient failures`, `chore: scaffold ...`, or `docs: ...`. Keep each commit focused. Pull requests should summarize behavior changes, link related issues when available, list verification commands, and include screenshots for visible UI changes. Never commit API keys; configure OpenWeatherMap and Alpha Vantage keys through the app settings.
