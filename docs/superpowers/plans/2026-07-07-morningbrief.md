# MorningBrief Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter Android MVP for MorningBrief: a Chinese-first, customizable morning dashboard with Weather, News, Calendar, Stocks, and Tech/AI News modules.

**Architecture:** Use a modular layered Flutter app: each feature module owns its provider, service, card widget, and tests; shared infrastructure lives in `lib/core/` and shared UI in `lib/shared/`. The first implementation is pure client-side: user preferences and calendar items are local, external feeds are fetched directly from public APIs/RSS and cached locally.

**Tech Stack:** Flutter/Dart, Provider, Material Design 3, `shared_preferences`, `sqflite`, `path`, `http`, `xml`, `intl`, `flutter_test`, Android target.

## Global Constraints

- Target platform: Android.
- Primary language: Chinese UI copy.
- Framework: Flutter (Dart).
- State management: Provider with `ChangeNotifier` classes.
- Local configuration storage: `shared_preferences`.
- Local cache and calendar storage: `sqflite` (SQLite).
- HTTP: use `http` for MVP; do not introduce `dio` unless a task explicitly replaces the API client.
- Design language: Material Design 3 / Material You.
- Theme: support light and dark modes, following the system theme.
- MVP has no custom backend server.
- Each dashboard module must fail independently; one module error must not break other cards.
- API keys are user-entered in Settings and stored locally.
- Cache TTLs: Weather 30 minutes, News 1 hour, Stocks 15 minutes, Tech/AI News 1 hour.
- Chinese-first data sources: RSS feeds and Chinese UI labels are preferred where available.
- New files should stay focused; avoid large files that mix services, state, and UI.

---

## Scope Check

The approved spec covers five dashboard modules. They are independent enough to implement task-by-task, but they share the same app shell, storage, cache, and card patterns. This plan keeps them in one MVP because every task produces independently testable software and the shared foundation prevents repeated setup across five separate plans.

## File Structure Map

### Project and configuration

- `pubspec.yaml` — Flutter dependencies, assets, app metadata.
- `README.md` — setup, API key instructions, run/test/build commands.
- `analysis_options.yaml` — lint rules using Flutter defaults.
- `android/app/src/main/AndroidManifest.xml` — Android internet permission.

### App shell

- `lib/main.dart` — initializes Flutter bindings, storage, providers, and runs `MorningBriefApp`.
- `lib/app.dart` — `MaterialApp`, routes, theme mode.
- `lib/core/theme/app_theme.dart` — Material 3 light/dark theme definitions.
- `lib/core/theme/colors.dart` — MorningBrief color constants.

### Core infrastructure

- `lib/core/api_client.dart` — typed HTTP wrapper with timeout and status-code errors.
- `lib/core/app_error.dart` — user-facing error model and categories.
- `lib/core/cache_manager.dart` — SQLite-backed module cache with TTL.
- `lib/core/storage.dart` — `shared_preferences` wrapper for settings.
- `lib/core/database/app_database.dart` — SQLite database opening and table creation.
- `lib/core/constants.dart` — cache keys, default RSS URLs, default stock symbols.

### Domain models

- `lib/models/module_config.dart` — module IDs, enablement, display order, API/prefs keys.
- `lib/models/weather_model.dart` — current weather and forecast models.
- `lib/models/news_article.dart` — RSS/API article model.
- `lib/models/calendar_event.dart` — local task/event model.
- `lib/models/stock_item.dart` — stock quote model.

### Shared UI and contracts

- `lib/shared/module_state.dart` — generic loading/data/error/offline state.
- `lib/shared/morning_module.dart` — common module interface.
- `lib/shared/widgets/module_card.dart` — reusable card container.
- `lib/shared/widgets/module_error_widget.dart` — retryable error UI.
- `lib/shared/widgets/module_loading_widget.dart` — loading skeleton.
- `lib/shared/widgets/module_empty_widget.dart` — empty state UI.
- `lib/shared/screens/home_screen.dart` — dashboard layout and refresh orchestration.
- `lib/shared/screens/settings_screen.dart` — module toggles, preferences, API key fields.

### Module files

- `lib/modules/weather/weather_service.dart` — OpenWeatherMap API and parsing.
- `lib/modules/weather/weather_provider.dart` — weather state, cache, refresh.
- `lib/modules/weather/weather_card.dart` — weather card UI.
- `lib/modules/news/news_service.dart` — general RSS/API article fetching.
- `lib/modules/news/news_provider.dart` — general news state and cache.
- `lib/modules/news/news_card.dart` — general news card UI.
- `lib/modules/calendar/calendar_service.dart` — SQLite CRUD for events.
- `lib/modules/calendar/calendar_provider.dart` — calendar state and mutations.
- `lib/modules/calendar/calendar_card.dart` — today agenda and checkbox UI.
- `lib/modules/stocks/stocks_service.dart` — Alpha Vantage quote fetching.
- `lib/modules/stocks/stocks_provider.dart` — stock quote state and cache.
- `lib/modules/stocks/stocks_card.dart` — stock quote card UI.
- `lib/modules/tech_news/tech_news_service.dart` — Tech/AI RSS fetching.
- `lib/modules/tech_news/tech_news_provider.dart` — Tech/AI news state and cache.
- `lib/modules/tech_news/tech_news_card.dart` — Tech/AI card UI.

### Tests

- `test/core/api_client_test.dart`
- `test/core/cache_manager_test.dart`
- `test/core/storage_test.dart`
- `test/models/model_serialization_test.dart`
- `test/shared/module_state_test.dart`
- `test/shared/module_widgets_test.dart`
- `test/shared/home_screen_test.dart`
- `test/shared/settings_screen_test.dart`
- `test/modules/calendar/calendar_service_test.dart`
- `test/modules/calendar/calendar_provider_test.dart`
- `test/modules/weather/weather_service_test.dart`
- `test/modules/weather/weather_provider_test.dart`
- `test/modules/news/news_service_test.dart`
- `test/modules/news/news_provider_test.dart`
- `test/modules/stocks/stocks_service_test.dart`
- `test/modules/stocks/stocks_provider_test.dart`
- `test/modules/tech_news/tech_news_service_test.dart`
- `test/modules/tech_news/tech_news_provider_test.dart`
- `test/widget_test.dart`

---

### Task 1: Flutter Project Scaffold and App Shell

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `lib/main.dart`
- Create: `lib/app.dart`
- Create: `lib/core/theme/colors.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `test/widget_test.dart`
- Modify: `android/app/src/main/AndroidManifest.xml` after `flutter create` creates it
- Create: `README.md`

**Interfaces:**
- Consumes: Flutter SDK installed on the development machine.
- Produces: `MorningBriefApp extends StatelessWidget`, route names `/` and `/settings`, theme definitions `AppTheme.lightTheme` and `AppTheme.darkTheme`.

- [ ] **Step 1: Create the Flutter project in the workspace root**

Run from `e:\Claude_code_Project\MorningBrief`:

```bash
flutter create --platforms=android --org com.morningbrief .
```

Expected: command creates `android/`, `lib/`, `test/`, `pubspec.yaml`, and prints `All done!`.

- [ ] **Step 2: Replace `pubspec.yaml` with MVP dependencies**

```yaml
name: morningbrief
description: Chinese-first customizable morning dashboard for Android.
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  shared_preferences: ^2.2.3
  sqflite: ^2.3.3+1
  path: ^1.9.0
  http: ^1.2.1
  xml: ^6.5.0
  intl: ^0.19.0

  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Replace `analysis_options.yaml`**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: true
```

- [ ] **Step 4: Write the first failing widget test**

Replace `test/widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/app.dart';

void main() {
  testWidgets('MorningBrief app shows Chinese dashboard title', (tester) async {
    await tester.pumpWidget(const MorningBriefApp());

    expect(find.text('MorningBrief'), findsOneWidget);
    expect(find.text('早安！'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run the test to verify it fails before implementation**

```bash
flutter test test/widget_test.dart
```

Expected: FAIL because `package:morningbrief/app.dart` or `MorningBriefApp` is missing.

- [ ] **Step 6: Add theme colors**

Create `lib/core/theme/colors.dart`:

```dart
import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const seed = Color(0xFF2E7D8A);
  static const morningBlue = Color(0xFFBFEAF5);
  static const morningGreen = Color(0xFFCDEDD8);
  static const cardLight = Color(0xFFF8FBFC);
  static const cardDark = Color(0xFF1B2326);
  static const profitRed = Color(0xFFE53935);
  static const lossGreen = Color(0xFF43A047);
}
```

- [ ] **Step 7: Add Material 3 themes**

Create `lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF2F7F9),
      cardTheme: CardTheme(
        color: AppColors.cardLight,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF101719),
      cardTheme: CardTheme(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
```

- [ ] **Step 8: Add app shell with temporary home and settings routes**

Create `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

class MorningBriefApp extends StatelessWidget {
  const MorningBriefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MorningBrief',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routes: {
        '/': (_) => const _TemporaryHomeScreen(),
        '/settings': (_) => const _TemporarySettingsScreen(),
      },
    );
  }
}

class _TemporaryHomeScreen extends StatelessWidget {
  const _TemporaryHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MorningBrief'),
        actions: [
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('早安！'),
      ),
    );
  }
}

class _TemporarySettingsScreen extends StatelessWidget {
  const _TemporarySettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('配置将在后续任务中添加'),
      ),
    );
  }
}
```

- [ ] **Step 9: Add the app entrypoint**

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const MorningBriefApp());
}
```

- [ ] **Step 10: Add Android internet permission**

In `android/app/src/main/AndroidManifest.xml`, add this line directly under the opening `<manifest ...>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

- [ ] **Step 11: Add setup instructions**

Create `README.md`:

```markdown
# MorningBrief

MorningBrief is a Chinese-first customizable morning dashboard for Android, built with Flutter.

## Requirements

- Flutter SDK 3.22 or newer
- Android Studio or Android SDK command-line tools
- Android emulator or physical Android device

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
```

## API Keys

Weather and stock modules require user-provided API keys configured inside the Settings screen:

- OpenWeatherMap One Call API 3.0
- Alpha Vantage

RSS-based news modules do not require API keys.
```

- [ ] **Step 12: Run tests and analyzer**

```bash
flutter pub get
flutter test test/widget_test.dart
flutter analyze
```

Expected: PASS for `widget_test.dart`; analyzer reports `No issues found!`.

- [ ] **Step 13: Commit**

```bash
git add pubspec.yaml analysis_options.yaml lib/main.dart lib/app.dart lib/core/theme/colors.dart lib/core/theme/app_theme.dart test/widget_test.dart android/app/src/main/AndroidManifest.xml README.md
git commit -m "chore: scaffold MorningBrief Flutter app"
```

Expected: commit succeeds if the workspace is a git repository. If not a git repository, record the skipped commit in the task notes and continue.

---

### Task 2: Core Models, Storage, Database, and Cache

**Files:**
- Create: `lib/core/app_error.dart`
- Create: `lib/core/constants.dart`
- Create: `lib/core/storage.dart`
- Create: `lib/core/database/app_database.dart`
- Create: `lib/core/cache_manager.dart`
- Create: `lib/models/module_config.dart`
- Create: `lib/models/weather_model.dart`
- Create: `lib/models/news_article.dart`
- Create: `lib/models/calendar_event.dart`
- Create: `lib/models/stock_item.dart`
- Create: `test/models/model_serialization_test.dart`
- Create: `test/core/storage_test.dart`
- Create: `test/core/cache_manager_test.dart`

**Interfaces:**
- Consumes: no production interfaces from earlier tasks except Dart package setup.
- Produces:
  - `enum MorningModuleId { weather, news, calendar, stocks, techNews }`
  - `class ModuleConfig { MorningModuleId id; bool enabled; int order; }`
  - `class AppStorage { Future<String?> getString(String key); Future<void> setString(String key, String value); Future<List<ModuleConfig>> getModuleConfigs(); Future<void> setModuleConfigs(List<ModuleConfig> configs); }`
  - `class CacheManager { Future<void> save(String key, String jsonValue); Future<CachedValue?> readFresh(String key, Duration ttl); }`
  - Serializable model classes with `fromJson(Map<String, dynamic>)` and `toJson()`.

- [ ] **Step 1: Write failing model serialization tests**

Create `test/models/model_serialization_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/models/calendar_event.dart';
import 'package:morningbrief/models/module_config.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/models/stock_item.dart';
import 'package:morningbrief/models/weather_model.dart';

void main() {
  test('ModuleConfig serializes module ID and ordering', () {
    const config = ModuleConfig(
      id: MorningModuleId.weather,
      enabled: true,
      order: 2,
    );

    expect(ModuleConfig.fromJson(config.toJson()), config);
  });

  test('WeatherModel serializes current weather and forecast', () {
    final model = WeatherModel(
      city: '上海',
      temperature: 24.5,
      feelsLike: 25.1,
      humidity: 61,
      windSpeed: 3.2,
      description: '多云',
      iconCode: '03d',
      forecast: [
        WeatherForecast(date: DateTime(2026, 7, 7), minTemp: 22, maxTemp: 28, description: '小雨', iconCode: '10d'),
      ],
      updatedAt: DateTime(2026, 7, 7, 8),
    );

    expect(WeatherModel.fromJson(model.toJson()).toJson(), model.toJson());
  });

  test('NewsArticle serializes source and URL', () {
    final article = NewsArticle(
      title: 'AI 新闻',
      summary: '摘要',
      source: '机器之心',
      url: Uri.parse('https://example.com/a'),
      publishedAt: DateTime(2026, 7, 7, 7, 30),
    );

    expect(NewsArticle.fromJson(article.toJson()).toJson(), article.toJson());
  });

  test('CalendarEvent serializes completion state', () {
    final event = CalendarEvent(
      id: 7,
      title: '晨会',
      startsAt: DateTime(2026, 7, 7, 9),
      isCompleted: false,
      createdAt: DateTime(2026, 7, 7, 6),
    );

    expect(CalendarEvent.fromJson(event.toJson()).toJson(), event.toJson());
  });

  test('StockItem serializes quote values', () {
    final item = StockItem(
      symbol: '600036.SHH',
      name: '招商银行',
      price: 35.2,
      change: 0.3,
      changePercent: 0.86,
      updatedAt: DateTime(2026, 7, 7, 10),
    );

    expect(StockItem.fromJson(item.toJson()).toJson(), item.toJson());
  });
}
```

- [ ] **Step 2: Run model tests to verify they fail**

```bash
flutter test test/models/model_serialization_test.dart
```

Expected: FAIL because the model files do not exist.

- [ ] **Step 3: Implement module config model**

Create `lib/models/module_config.dart`:

```dart
enum MorningModuleId { weather, news, calendar, stocks, techNews }

extension MorningModuleIdX on MorningModuleId {
  String get storageKey => switch (this) {
        MorningModuleId.weather => 'weather',
        MorningModuleId.news => 'news',
        MorningModuleId.calendar => 'calendar',
        MorningModuleId.stocks => 'stocks',
        MorningModuleId.techNews => 'tech_news',
      };

  String get title => switch (this) {
        MorningModuleId.weather => '天气',
        MorningModuleId.news => '新闻头条',
        MorningModuleId.calendar => '日历与日程',
        MorningModuleId.stocks => '股票财经',
        MorningModuleId.techNews => '科技 AI 新闻',
      };

  static MorningModuleId fromStorageKey(String key) {
    return MorningModuleId.values.firstWhere(
      (id) => id.storageKey == key,
      orElse: () => MorningModuleId.weather,
    );
  }
}

class ModuleConfig {
  const ModuleConfig({required this.id, required this.enabled, required this.order});

  final MorningModuleId id;
  final bool enabled;
  final int order;

  ModuleConfig copyWith({MorningModuleId? id, bool? enabled, int? order}) {
    return ModuleConfig(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id.storageKey,
        'enabled': enabled,
        'order': order,
      };

  factory ModuleConfig.fromJson(Map<String, dynamic> json) {
    return ModuleConfig(
      id: MorningModuleIdX.fromStorageKey(json['id'] as String),
      enabled: json['enabled'] as bool,
      order: json['order'] as int,
    );
  }

  static List<ModuleConfig> defaults() => const [
        ModuleConfig(id: MorningModuleId.weather, enabled: true, order: 0),
        ModuleConfig(id: MorningModuleId.news, enabled: true, order: 1),
        ModuleConfig(id: MorningModuleId.calendar, enabled: true, order: 2),
        ModuleConfig(id: MorningModuleId.stocks, enabled: true, order: 3),
        ModuleConfig(id: MorningModuleId.techNews, enabled: true, order: 4),
      ];

  @override
  bool operator ==(Object other) {
    return other is ModuleConfig && other.id == id && other.enabled == enabled && other.order == order;
  }

  @override
  int get hashCode => Object.hash(id, enabled, order);
}
```

- [ ] **Step 4: Implement remaining serializable models**

Create `lib/models/weather_model.dart`:

```dart
class WeatherForecast {
  WeatherForecast({required this.date, required this.minTemp, required this.maxTemp, required this.description, required this.iconCode});

  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String description;
  final String iconCode;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minTemp': minTemp,
        'maxTemp': maxTemp,
        'description': description,
        'iconCode': iconCode,
      };

  factory WeatherForecast.fromJson(Map<String, dynamic> json) => WeatherForecast(
        date: DateTime.parse(json['date'] as String),
        minTemp: (json['minTemp'] as num).toDouble(),
        maxTemp: (json['maxTemp'] as num).toDouble(),
        description: json['description'] as String,
        iconCode: json['iconCode'] as String,
      );
}

class WeatherModel {
  WeatherModel({
    required this.city,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconCode,
    required this.forecast,
    required this.updatedAt,
  });

  final String city;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String iconCode;
  final List<WeatherForecast> forecast;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'city': city,
        'temperature': temperature,
        'feelsLike': feelsLike,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'description': description,
        'iconCode': iconCode,
        'forecast': forecast.map((item) => item.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WeatherModel.fromJson(Map<String, dynamic> json) => WeatherModel(
        city: json['city'] as String,
        temperature: (json['temperature'] as num).toDouble(),
        feelsLike: (json['feelsLike'] as num).toDouble(),
        humidity: json['humidity'] as int,
        windSpeed: (json['windSpeed'] as num).toDouble(),
        description: json['description'] as String,
        iconCode: json['iconCode'] as String,
        forecast: (json['forecast'] as List<dynamic>).map((item) => WeatherForecast.fromJson(item as Map<String, dynamic>)).toList(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
```

Create `lib/models/news_article.dart`:

```dart
class NewsArticle {
  NewsArticle({required this.title, required this.summary, required this.source, required this.url, required this.publishedAt});

  final String title;
  final String summary;
  final String source;
  final Uri url;
  final DateTime publishedAt;

  Map<String, dynamic> toJson() => {
        'title': title,
        'summary': summary,
        'source': source,
        'url': url.toString(),
        'publishedAt': publishedAt.toIso8601String(),
      };

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
        title: json['title'] as String,
        summary: json['summary'] as String,
        source: json['source'] as String,
        url: Uri.parse(json['url'] as String),
        publishedAt: DateTime.parse(json['publishedAt'] as String),
      );
}
```

Create `lib/models/calendar_event.dart`:

```dart
class CalendarEvent {
  CalendarEvent({required this.id, required this.title, required this.startsAt, required this.isCompleted, required this.createdAt});

  final int? id;
  final String title;
  final DateTime startsAt;
  final bool isCompleted;
  final DateTime createdAt;

  CalendarEvent copyWith({int? id, String? title, DateTime? startsAt, bool? isCompleted, DateTime? createdAt}) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startsAt: startsAt ?? this.startsAt,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startsAt': startsAt.toIso8601String(),
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as int?,
        title: json['title'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String),
        isCompleted: json['isCompleted'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
```

Create `lib/models/stock_item.dart`:

```dart
class StockItem {
  StockItem({required this.symbol, required this.name, required this.price, required this.change, required this.changePercent, required this.updatedAt});

  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final DateTime updatedAt;

  bool get isUp => change >= 0;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'price': price,
        'change': change,
        'changePercent': changePercent,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        change: (json['change'] as num).toDouble(),
        changePercent: (json['changePercent'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
```

- [ ] **Step 5: Run model tests to verify they pass**

```bash
flutter test test/models/model_serialization_test.dart
```

Expected: PASS.

- [ ] **Step 6: Add app error and constants**

Create `lib/core/app_error.dart`:

```dart
enum AppErrorType { network, apiKeyMissing, empty, storage, unknown }

class AppError {
  const AppError({required this.type, required this.message});

  final AppErrorType type;
  final String message;
}
```

Create `lib/core/constants.dart`:

```dart
class AppConstants {
  const AppConstants._();

  static const weatherApiKey = 'weather_api_key';
  static const stockApiKey = 'stock_api_key';
  static const cityName = 'city_name';
  static const stockSymbols = 'stock_symbols';
  static const moduleConfigs = 'module_configs';

  static const defaultCity = '上海';
  static const defaultStockSymbols = ['600036.SHH', '000001.SHZ'];

  static const cacheWeather = 'cache_weather';
  static const cacheNews = 'cache_news';
  static const cacheStocks = 'cache_stocks';
  static const cacheTechNews = 'cache_tech_news';

  static final generalNewsFeeds = <Uri>[
    Uri.parse('https://www.thepaper.cn/rss_newsDetail.jsp'),
  ];

  static final techNewsFeeds = <Uri>[
    Uri.parse('https://www.jiqizhixin.com/rss'),
    Uri.parse('https://www.qbitai.com/feed'),
  ];
}
```

- [ ] **Step 7: Write failing storage tests**

Create `test/core/storage_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/models/module_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppStorage stores strings and module configs', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();

    await storage.setString('city_name', '杭州');
    expect(await storage.getString('city_name'), '杭州');

    const configs = [ModuleConfig(id: MorningModuleId.news, enabled: false, order: 4)];
    await storage.setModuleConfigs(configs);

    expect(await storage.getModuleConfigs(), configs);
  });

  test('AppStorage returns default configs when none are saved', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();

    expect(await storage.getModuleConfigs(), ModuleConfig.defaults());
  });
}
```

- [ ] **Step 8: Implement `AppStorage`**

Create `lib/core/storage.dart`:

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/module_config.dart';
import 'constants.dart';

class AppStorage {
  AppStorage._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorage._(prefs);
  }

  Future<String?> getString(String key) async => _prefs.getString(key);

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<List<String>> getStringList(String key, List<String> fallback) async {
    return _prefs.getStringList(key) ?? fallback;
  }

  Future<void> setStringList(String key, List<String> values) async {
    await _prefs.setStringList(key, values);
  }

  Future<List<ModuleConfig>> getModuleConfigs() async {
    final raw = _prefs.getString(AppConstants.moduleConfigs);
    if (raw == null) return ModuleConfig.defaults();
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((item) => ModuleConfig.fromJson(item as Map<String, dynamic>)).toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<void> setModuleConfigs(List<ModuleConfig> configs) async {
    final raw = jsonEncode(configs.map((item) => item.toJson()).toList());
    await _prefs.setString(AppConstants.moduleConfigs, raw);
  }
}
```

- [ ] **Step 9: Run storage tests**

```bash
flutter test test/core/storage_test.dart
```

Expected: PASS.

- [ ] **Step 10: Write failing cache manager tests**

Create `test/core/cache_manager_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/cache_manager.dart';

void main() {
  test('MemoryCacheManager returns fresh cached values', () async {
    final cache = MemoryCacheManager(now: () => DateTime(2026, 7, 7, 8));

    await cache.save('weather', '{"ok":true}');
    final value = await cache.readFresh('weather', const Duration(minutes: 30));

    expect(value?.jsonValue, '{"ok":true}');
    expect(value?.isFresh, true);
  });

  test('MemoryCacheManager returns stale values as not fresh', () async {
    var current = DateTime(2026, 7, 7, 8);
    final cache = MemoryCacheManager(now: () => current);

    await cache.save('weather', '{"ok":true}');
    current = DateTime(2026, 7, 7, 9);

    expect(await cache.readFresh('weather', const Duration(minutes: 30)), isNull);
    expect((await cache.readAny('weather'))?.isFresh, false);
  });
}
```

- [ ] **Step 11: Implement cache interfaces and in-memory test cache**

Create `lib/core/cache_manager.dart`:

```dart
class CachedValue {
  CachedValue({required this.key, required this.jsonValue, required this.savedAt, required this.isFresh});

  final String key;
  final String jsonValue;
  final DateTime savedAt;
  final bool isFresh;
}

abstract class CacheManager {
  Future<void> save(String key, String jsonValue);
  Future<CachedValue?> readFresh(String key, Duration ttl);
  Future<CachedValue?> readAny(String key);
}

class MemoryCacheManager implements CacheManager {
  MemoryCacheManager({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, CachedValue> _values = {};

  @override
  Future<void> save(String key, String jsonValue) async {
    _values[key] = CachedValue(key: key, jsonValue: jsonValue, savedAt: _now(), isFresh: true);
  }

  @override
  Future<CachedValue?> readFresh(String key, Duration ttl) async {
    final value = _values[key];
    if (value == null) return null;
    final fresh = _now().difference(value.savedAt) <= ttl;
    if (!fresh) return null;
    return CachedValue(key: value.key, jsonValue: value.jsonValue, savedAt: value.savedAt, isFresh: true);
  }

  @override
  Future<CachedValue?> readAny(String key) async {
    final value = _values[key];
    if (value == null) return null;
    final fresh = _now().difference(value.savedAt) <= const Duration(minutes: 1);
    return CachedValue(key: value.key, jsonValue: value.jsonValue, savedAt: value.savedAt, isFresh: fresh);
  }
}
```

- [ ] **Step 12: Add SQLite database and persistent cache manager**

Create `lib/core/database/app_database.dart`:

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static Future<AppDatabase> open() async {
    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, 'morningbrief.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE module_cache(
            cache_key TEXT PRIMARY KEY,
            json_value TEXT NOT NULL,
            saved_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE calendar_events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            starts_at TEXT NOT NULL,
            is_completed INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return AppDatabase._(database);
  }
}
```

Append this class to `lib/core/cache_manager.dart`:

```dart
import 'package:sqflite/sqflite.dart';

class SqliteCacheManager implements CacheManager {
  SqliteCacheManager(this._database, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Database _database;
  final DateTime Function() _now;

  @override
  Future<void> save(String key, String jsonValue) async {
    await _database.insert(
      'module_cache',
      {'cache_key': key, 'json_value': jsonValue, 'saved_at': _now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<CachedValue?> readFresh(String key, Duration ttl) async {
    final value = await readAny(key);
    if (value == null) return null;
    final fresh = _now().difference(value.savedAt) <= ttl;
    if (!fresh) return null;
    return CachedValue(key: value.key, jsonValue: value.jsonValue, savedAt: value.savedAt, isFresh: true);
  }

  @override
  Future<CachedValue?> readAny(String key) async {
    final rows = await _database.query('module_cache', where: 'cache_key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.single;
    final savedAt = DateTime.parse(row['saved_at'] as String);
    return CachedValue(key: key, jsonValue: row['json_value'] as String, savedAt: savedAt, isFresh: false);
  }
}
```

If Dart reports imports cannot appear after declarations, move `import 'package:sqflite/sqflite.dart';` to the top of `lib/core/cache_manager.dart` above all class definitions.

- [ ] **Step 13: Run core tests and analyzer**

```bash
flutter test test/models/model_serialization_test.dart test/core/storage_test.dart test/core/cache_manager_test.dart
flutter analyze
```

Expected: all tests PASS; analyzer reports `No issues found!`.

- [ ] **Step 14: Commit**

```bash
git add lib/core lib/models test/models test/core
git commit -m "feat: add core models storage and cache"
```

Expected: commit succeeds if the workspace is a git repository. If not a git repository, record the skipped commit in the task notes and continue.

---

### Task 3: API Client, Shared Module State, and Shared Widgets

**Files:**
- Create: `lib/core/api_client.dart`
- Create: `lib/shared/module_state.dart`
- Create: `lib/shared/morning_module.dart`
- Create: `lib/shared/widgets/module_card.dart`
- Create: `lib/shared/widgets/module_error_widget.dart`
- Create: `lib/shared/widgets/module_loading_widget.dart`
- Create: `lib/shared/widgets/module_empty_widget.dart`
- Create: `test/core/api_client_test.dart`
- Create: `test/shared/module_state_test.dart`
- Create: `test/shared/module_widgets_test.dart`

**Interfaces:**
- Consumes: `AppError` from `lib/core/app_error.dart` and model config IDs.
- Produces:
  - `ApiClient.getJson(Uri uri)` returning `Future<Map<String, dynamic>>`.
  - `ApiClient.getText(Uri uri)` returning `Future<String>`.
  - `ModuleState<T>` factories: `idle`, `loading`, `data`, `empty`, `error`, `offline`.
  - `MorningModule` interface with `id`, `title`, `icon`, `isEnabled`, `buildCard`, `refresh`.
  - Shared card widgets used by all module UI tasks.

- [ ] **Step 1: Write failing state tests**

Create `test/shared/module_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/app_error.dart';
import 'package:morningbrief/shared/module_state.dart';

void main() {
  test('ModuleState exposes data and loading flags', () {
    expect(ModuleState<String>.loading().isLoading, true);
    expect(ModuleState.data('ok').data, 'ok');
    expect(ModuleState<String>.empty().isEmpty, true);
  });

  test('ModuleState stores retryable errors', () {
    const error = AppError(type: AppErrorType.network, message: '网络异常');
    final state = ModuleState<String>.error(error);

    expect(state.hasError, true);
    expect(state.error?.message, '网络异常');
  });
}
```

- [ ] **Step 2: Implement `ModuleState`**

Create `lib/shared/module_state.dart`:

```dart
import '../core/app_error.dart';

enum ModuleStatus { idle, loading, data, empty, error, offline }

class ModuleState<T> {
  const ModuleState._({required this.status, this.data, this.error});

  final ModuleStatus status;
  final T? data;
  final AppError? error;

  factory ModuleState.idle() => const ModuleState._(status: ModuleStatus.idle);
  factory ModuleState.loading() => const ModuleState._(status: ModuleStatus.loading);
  factory ModuleState.data(T data) => ModuleState._(status: ModuleStatus.data, data: data);
  factory ModuleState.empty() => const ModuleState._(status: ModuleStatus.empty);
  factory ModuleState.error(AppError error) => ModuleState._(status: ModuleStatus.error, error: error);
  factory ModuleState.offline(T data) => ModuleState._(status: ModuleStatus.offline, data: data);

  bool get isLoading => status == ModuleStatus.loading;
  bool get hasData => status == ModuleStatus.data || status == ModuleStatus.offline;
  bool get isEmpty => status == ModuleStatus.empty;
  bool get hasError => status == ModuleStatus.error;
  bool get isOffline => status == ModuleStatus.offline;
}
```

- [ ] **Step 3: Run state tests**

```bash
flutter test test/shared/module_state_test.dart
```

Expected: PASS.

- [ ] **Step 4: Write failing widget tests for shared module widgets**

Create `test/shared/module_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/shared/widgets/module_card.dart';
import 'package:morningbrief/shared/widgets/module_empty_widget.dart';
import 'package:morningbrief/shared/widgets/module_error_widget.dart';
import 'package:morningbrief/shared/widgets/module_loading_widget.dart';

void main() {
  testWidgets('ModuleCard displays title and child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ModuleCard(title: '天气', icon: Icons.wb_sunny_outlined, child: Text('24°C')),
      ),
    ));

    expect(find.text('天气'), findsOneWidget);
    expect(find.text('24°C'), findsOneWidget);
  });

  testWidgets('ModuleErrorWidget calls retry callback', (tester) async {
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ModuleErrorWidget(message: '网络异常', onRetry: () => retries++)),
    ));

    await tester.tap(find.text('重试'));
    expect(retries, 1);
  });

  testWidgets('Loading and empty widgets show Chinese labels', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [ModuleLoadingWidget(), ModuleEmptyWidget(message: '暂无数据')]),
    ));

    expect(find.text('加载中...'), findsOneWidget);
    expect(find.text('暂无数据'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Implement shared widgets**

Create `lib/shared/widgets/module_card.dart`:

```dart
import 'package:flutter/material.dart';

class ModuleCard extends StatelessWidget {
  const ModuleCard({super.key, required this.title, required this.icon, required this.child, this.trailing, this.offline = false});

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                if (offline) const Chip(label: Text('离线'), visualDensity: VisualDensity.compact),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
```

Create `lib/shared/widgets/module_error_widget.dart`:

```dart
import 'package:flutter/material.dart';

class ModuleErrorWidget extends StatelessWidget {
  const ModuleErrorWidget({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('重试'),
        ),
      ],
    );
  }
}
```

Create `lib/shared/widgets/module_loading_widget.dart`:

```dart
import 'package:flutter/material.dart';

class ModuleLoadingWidget extends StatelessWidget {
  const ModuleLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 12),
        Text('加载中...'),
      ],
    );
  }
}
```

Create `lib/shared/widgets/module_empty_widget.dart`:

```dart
import 'package:flutter/material.dart';

class ModuleEmptyWidget extends StatelessWidget {
  const ModuleEmptyWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: Theme.of(context).textTheme.bodyMedium);
  }
}
```

- [ ] **Step 6: Add the module interface**

Create `lib/shared/morning_module.dart`:

```dart
import 'package:flutter/widgets.dart';
import '../models/module_config.dart';

abstract class MorningModule {
  MorningModuleId get id;
  String get title;
  IconData get icon;
  bool get isEnabled;
  Widget buildCard();
  Future<void> refresh();
}
```

- [ ] **Step 7: Run shared widget tests**

```bash
flutter test test/shared/module_state_test.dart test/shared/module_widgets_test.dart
```

Expected: PASS.

- [ ] **Step 8: Write failing API client tests**

Create `test/core/api_client_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morningbrief/core/api_client.dart';

void main() {
  test('ApiClient decodes JSON responses', () async {
    final client = ApiClient(MockClient((request) async {
      return http.Response(jsonEncode({'city': '上海'}), 200, headers: {'content-type': 'application/json'});
    }));

    expect(await client.getJson(Uri.parse('https://example.com')), {'city': '上海'});
  });

  test('ApiClient throws ApiClientException for non-200 responses', () async {
    final client = ApiClient(MockClient((request) async => http.Response('no', 500)));

    expect(client.getText(Uri.parse('https://example.com')), throwsA(isA<ApiClientException>()));
  });
}
```

- [ ] **Step 9: Implement API client**

Create `lib/core/api_client.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClientException implements Exception {
  ApiClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiClientException($statusCode): $message';
}

class ApiClient {
  ApiClient([http.Client? client, Duration? timeout])
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 12);

  final http.Client _client;
  final Duration _timeout;

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final text = await getText(uri);
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiClientException('返回数据不是 JSON 对象');
  }

  Future<String> getText(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiClientException('请求失败', statusCode: response.statusCode);
      }
      return response.body;
    } on TimeoutException {
      throw ApiClientException('请求超时');
    }
  }
}
```

- [ ] **Step 10: Run API client tests and analyzer**

```bash
flutter test test/core/api_client_test.dart test/shared/module_state_test.dart test/shared/module_widgets_test.dart
flutter analyze
```

Expected: all tests PASS; analyzer reports `No issues found!`.

- [ ] **Step 11: Commit**

```bash
git add lib/core/api_client.dart lib/shared test/core/api_client_test.dart test/shared
git commit -m "feat: add shared module infrastructure"
```

Expected: commit succeeds if the workspace is a git repository. If not a git repository, record the skipped commit in the task notes and continue.

---

### Task 4: Home Dashboard, Settings, and Module Configuration Provider

**Files:**
- Create: `lib/shared/module_config_provider.dart`
- Create: `lib/shared/screens/home_screen.dart`
- Create: `lib/shared/screens/settings_screen.dart`
- Modify: `lib/app.dart`
- Modify: `lib/main.dart`
- Create: `test/shared/home_screen_test.dart`
- Create: `test/shared/settings_screen_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `AppStorage`, `ModuleConfig`, shared widgets, and route names from Task 1.
- Produces:
  - `ModuleConfigProvider extends ChangeNotifier`
  - `Future<void> load()`, `Future<void> toggle(MorningModuleId id, bool enabled)`, `Future<void> updateCity(String city)`, `Future<void> updateWeatherApiKey(String key)`, `Future<void> updateStockApiKey(String key)`, `Future<void> updateStockSymbols(List<String> symbols)`
  - `HomeScreen` and `SettingsScreen` replace temporary screens.

- [ ] **Step 1: Write failing settings screen test**

Create `test/shared/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/shared/module_config_provider.dart';
import 'package:morningbrief/shared/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsScreen shows module toggles and preference fields', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final provider = ModuleConfigProvider(storage);
    await provider.load();

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: SettingsScreen()),
    ));

    expect(find.text('模块管理'), findsOneWidget);
    expect(find.text('天气'), findsOneWidget);
    expect(find.text('城市'), findsOneWidget);
    expect(find.text('OpenWeatherMap API Key'), findsOneWidget);
    expect(find.text('Alpha Vantage API Key'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Implement module configuration provider**

Create `lib/shared/module_config_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../core/storage.dart';
import '../models/module_config.dart';

class ModuleConfigProvider extends ChangeNotifier {
  ModuleConfigProvider(this._storage);

  final AppStorage _storage;
  List<ModuleConfig> _configs = ModuleConfig.defaults();
  String _city = AppConstants.defaultCity;
  String _weatherApiKey = '';
  String _stockApiKey = '';
  List<String> _stockSymbols = AppConstants.defaultStockSymbols;

  List<ModuleConfig> get configs => List.unmodifiable(_configs);
  String get city => _city;
  String get weatherApiKey => _weatherApiKey;
  String get stockApiKey => _stockApiKey;
  List<String> get stockSymbols => List.unmodifiable(_stockSymbols);

  bool isEnabled(MorningModuleId id) => _configs.firstWhere((config) => config.id == id).enabled;

  Future<void> load() async {
    _configs = await _storage.getModuleConfigs();
    _city = await _storage.getString(AppConstants.cityName) ?? AppConstants.defaultCity;
    _weatherApiKey = await _storage.getString(AppConstants.weatherApiKey) ?? '';
    _stockApiKey = await _storage.getString(AppConstants.stockApiKey) ?? '';
    _stockSymbols = await _storage.getStringList(AppConstants.stockSymbols, AppConstants.defaultStockSymbols);
    notifyListeners();
  }

  Future<void> toggle(MorningModuleId id, bool enabled) async {
    _configs = _configs.map((config) => config.id == id ? config.copyWith(enabled: enabled) : config).toList();
    await _storage.setModuleConfigs(_configs);
    notifyListeners();
  }

  Future<void> updateCity(String city) async {
    _city = city.trim().isEmpty ? AppConstants.defaultCity : city.trim();
    await _storage.setString(AppConstants.cityName, _city);
    notifyListeners();
  }

  Future<void> updateWeatherApiKey(String key) async {
    _weatherApiKey = key.trim();
    await _storage.setString(AppConstants.weatherApiKey, _weatherApiKey);
    notifyListeners();
  }

  Future<void> updateStockApiKey(String key) async {
    _stockApiKey = key.trim();
    await _storage.setString(AppConstants.stockApiKey, _stockApiKey);
    notifyListeners();
  }

  Future<void> updateStockSymbols(List<String> symbols) async {
    _stockSymbols = symbols.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    await _storage.setStringList(AppConstants.stockSymbols, _stockSymbols);
    notifyListeners();
  }
}
```

- [ ] **Step 3: Implement settings screen**

Create `lib/shared/screens/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/module_config.dart';
import '../module_config_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _cityController;
  late final TextEditingController _weatherKeyController;
  late final TextEditingController _stockKeyController;
  late final TextEditingController _symbolsController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ModuleConfigProvider>();
    _cityController = TextEditingController(text: provider.city);
    _weatherKeyController = TextEditingController(text: provider.weatherApiKey);
    _stockKeyController = TextEditingController(text: provider.stockApiKey);
    _symbolsController = TextEditingController(text: provider.stockSymbols.join(','));
  }

  @override
  void dispose() {
    _cityController.dispose();
    _weatherKeyController.dispose();
    _stockKeyController.dispose();
    _symbolsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModuleConfigProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('模块管理', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final config in provider.configs)
            SwitchListTile(
              value: config.enabled,
              title: Text(config.id.title),
              onChanged: (enabled) => provider.toggle(config.id, enabled),
            ),
          const SizedBox(height: 24),
          Text('偏好设置', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: '城市', border: OutlineInputBorder()),
            onSubmitted: provider.updateCity,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weatherKeyController,
            decoration: const InputDecoration(labelText: 'OpenWeatherMap API Key', border: OutlineInputBorder()),
            onSubmitted: provider.updateWeatherApiKey,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stockKeyController,
            decoration: const InputDecoration(labelText: 'Alpha Vantage API Key', border: OutlineInputBorder()),
            onSubmitted: provider.updateStockApiKey,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _symbolsController,
            decoration: const InputDecoration(labelText: '股票代码（逗号分隔）', border: OutlineInputBorder()),
            onSubmitted: (value) => provider.updateStockSymbols(value.split(',')),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run settings screen test**

```bash
flutter test test/shared/settings_screen_test.dart
```

Expected: PASS.

- [ ] **Step 5: Write failing home screen test**

Create `test/shared/home_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/shared/module_config_provider.dart';
import 'package:morningbrief/shared/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HomeScreen shows greeting, enabled module placeholders, and updated time', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final provider = ModuleConfigProvider(storage);
    await provider.load();

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: HomeScreen()),
    ));

    expect(find.text('早安！'), findsOneWidget);
    expect(find.text('天气'), findsOneWidget);
    expect(find.text('新闻头条'), findsOneWidget);
    expect(find.text('日历与日程'), findsOneWidget);
    expect(find.textContaining('上次更新'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Implement home screen with placeholders**

Create `lib/shared/screens/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/module_config.dart';
import '../module_config_provider.dart';
import '../widgets/module_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModuleConfigProvider>();
    final enabled = provider.configs.where((config) => config.enabled).toList();
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('MorningBrief'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('早安！', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(now)),
          const SizedBox(height: 16),
          for (final config in enabled) ...[
            _PlaceholderModuleCard(config.id),
            const SizedBox(height: 12),
          ],
          Text('上次更新：${DateFormat('HH:mm').format(now)}', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _PlaceholderModuleCard extends StatelessWidget {
  const _PlaceholderModuleCard(this.id);

  final MorningModuleId id;

  @override
  Widget build(BuildContext context) {
    final icon = switch (id) {
      MorningModuleId.weather => Icons.wb_sunny_outlined,
      MorningModuleId.news => Icons.article_outlined,
      MorningModuleId.calendar => Icons.event_note_outlined,
      MorningModuleId.stocks => Icons.show_chart,
      MorningModuleId.techNews => Icons.memory_outlined,
    };
    return ModuleCard(
      title: id.title,
      icon: icon,
      child: const Text('模块正在加载'),
    );
  }
}
```

- [ ] **Step 7: Update app wiring to real screens and provider initialization**

Replace `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'shared/screens/home_screen.dart';
import 'shared/screens/settings_screen.dart';

class MorningBriefApp extends StatelessWidget {
  const MorningBriefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MorningBrief',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
```

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/storage.dart';
import 'shared/module_config_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await AppStorage.create();
  final moduleConfigProvider = ModuleConfigProvider(storage);
  await moduleConfigProvider.load();

  runApp(
    ChangeNotifierProvider.value(
      value: moduleConfigProvider,
      child: const MorningBriefApp(),
    ),
  );
}
```

Update `test/widget_test.dart` so it provides `ModuleConfigProvider`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/app.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/shared/module_config_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MorningBrief app shows Chinese dashboard title', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final provider = ModuleConfigProvider(storage);
    await provider.load();

    await tester.pumpWidget(ChangeNotifierProvider.value(value: provider, child: const MorningBriefApp()));

    expect(find.text('MorningBrief'), findsOneWidget);
    expect(find.text('早安！'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
```

- [ ] **Step 8: Run screen tests and analyzer**

```bash
flutter test test/widget_test.dart test/shared/home_screen_test.dart test/shared/settings_screen_test.dart
flutter analyze
```

Expected: tests PASS; analyzer reports `No issues found!`.

- [ ] **Step 9: Commit**

```bash
git add lib/app.dart lib/main.dart lib/shared/module_config_provider.dart lib/shared/screens test/widget_test.dart test/shared/home_screen_test.dart test/shared/settings_screen_test.dart
git commit -m "feat: add configurable dashboard shell"
```

Expected: commit succeeds if the workspace is a git repository. If not a git repository, record the skipped commit in the task notes and continue.

---

### Task 5: Calendar and Schedule Module

**Files:**
- Create: `lib/modules/calendar/calendar_service.dart`
- Create: `lib/modules/calendar/calendar_provider.dart`
- Create: `lib/modules/calendar/calendar_card.dart`
- Modify: `lib/shared/screens/home_screen.dart`
- Create: `test/modules/calendar/calendar_service_test.dart`
- Create: `test/modules/calendar/calendar_provider_test.dart`

**Interfaces:**
- Consumes: `CalendarEvent`, `ModuleState<List<CalendarEvent>>`, `ModuleCard`.
- Produces:
  - `CalendarService` with `createEvent`, `todayEvents`, `toggleCompleted`, `deleteEvent`.
  - `CalendarProvider` with `loadToday`, `addEvent`, `toggleCompleted`, `deleteEvent`.
  - `CalendarCard` displaying today's events and empty state.

- [ ] **Step 1: Write failing calendar service test with in-memory service contract**

Create `test/modules/calendar/calendar_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/models/calendar_event.dart';
import 'package:morningbrief/modules/calendar/calendar_service.dart';

void main() {
  test('MemoryCalendarService creates, lists, toggles, and deletes today events', () async {
    final service = MemoryCalendarService(now: () => DateTime(2026, 7, 7, 8));

    final event = await service.createEvent('写晨报', DateTime(2026, 7, 7, 9));
    expect(event.id, isNotNull);

    expect((await service.todayEvents()).single.title, '写晨报');

    await service.toggleCompleted(event.id!, true);
    expect((await service.todayEvents()).single.isCompleted, true);

    await service.deleteEvent(event.id!);
    expect(await service.todayEvents(), isEmpty);
  });

  test('MemoryCalendarService does not include tomorrow events in todayEvents', () async {
    final service = MemoryCalendarService(now: () => DateTime(2026, 7, 7, 8));
    await service.createEvent('明天任务', DateTime(2026, 7, 8, 9));

    expect(await service.todayEvents(), isEmpty);
  });
}
```

- [ ] **Step 2: Implement calendar service**

Create `lib/modules/calendar/calendar_service.dart`:

```dart
import 'package:sqflite/sqflite.dart';
import '../../models/calendar_event.dart';

abstract class CalendarService {
  Future<CalendarEvent> createEvent(String title, DateTime startsAt);
  Future<List<CalendarEvent>> todayEvents();
  Future<void> toggleCompleted(int id, bool completed);
  Future<void> deleteEvent(int id);
}

class MemoryCalendarService implements CalendarService {
  MemoryCalendarService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final List<CalendarEvent> _events = [];
  int _nextId = 1;

  @override
  Future<CalendarEvent> createEvent(String title, DateTime startsAt) async {
    final event = CalendarEvent(id: _nextId++, title: title, startsAt: startsAt, isCompleted: false, createdAt: _now());
    _events.add(event);
    return event;
  }

  @override
  Future<List<CalendarEvent>> todayEvents() async {
    final now = _now();
    return _events.where((event) => event.startsAt.year == now.year && event.startsAt.month == now.month && event.startsAt.day == now.day).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Future<void> toggleCompleted(int id, bool completed) async {
    final index = _events.indexWhere((event) => event.id == id);
    if (index >= 0) _events[index] = _events[index].copyWith(isCompleted: completed);
  }

  @override
  Future<void> deleteEvent(int id) async {
    _events.removeWhere((event) => event.id == id);
  }
}

class SqliteCalendarService implements CalendarService {
  SqliteCalendarService(this._database, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Database _database;
  final DateTime Function() _now;

  @override
  Future<CalendarEvent> createEvent(String title, DateTime startsAt) async {
    final createdAt = _now();
    final id = await _database.insert('calendar_events', {
      'title': title,
      'starts_at': startsAt.toIso8601String(),
      'is_completed': 0,
      'created_at': createdAt.toIso8601String(),
    });
    return CalendarEvent(id: id, title: title, startsAt: startsAt, isCompleted: false, createdAt: createdAt);
  }

  @override
  Future<List<CalendarEvent>> todayEvents() async {
    final now = _now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _database.query(
      'calendar_events',
      where: 'starts_at >= ? AND starts_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'starts_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> toggleCompleted(int id, bool completed) async {
    await _database.update('calendar_events', {'is_completed': completed ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteEvent(int id) async {
    await _database.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
  }

  CalendarEvent _fromRow(Map<String, Object?> row) => CalendarEvent(
        id: row['id'] as int,
        title: row['title'] as String,
        startsAt: DateTime.parse(row['starts_at'] as String),
        isCompleted: row['is_completed'] == 1,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
```

- [ ] **Step 3: Run calendar service tests**

```bash
flutter test test/modules/calendar/calendar_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Write failing provider test**

Create `test/modules/calendar/calendar_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/modules/calendar/calendar_provider.dart';
import 'package:morningbrief/modules/calendar/calendar_service.dart';
import 'package:morningbrief/shared/module_state.dart';

void main() {
  test('CalendarProvider loads today events and toggles completion', () async {
    final service = MemoryCalendarService(now: () => DateTime(2026, 7, 7, 8));
    final provider = CalendarProvider(service);

    await provider.addEvent('写晨报', DateTime(2026, 7, 7, 9));

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.single.title, '写晨报');

    await provider.toggleCompleted(provider.state.data!.single.id!, true);

    expect(provider.state.data!.single.isCompleted, true);
  });
}
```

- [ ] **Step 5: Implement provider**

Create `lib/modules/calendar/calendar_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import '../../core/app_error.dart';
import '../../models/calendar_event.dart';
import '../../shared/module_state.dart';
import 'calendar_service.dart';

class CalendarProvider extends ChangeNotifier {
  CalendarProvider(this._service);

  final CalendarService _service;
  ModuleState<List<CalendarEvent>> _state = ModuleState.idle();

  ModuleState<List<CalendarEvent>> get state => _state;

  Future<void> loadToday() async {
    _state = ModuleState.loading();
    notifyListeners();
    try {
      final events = await _service.todayEvents();
      _state = events.isEmpty ? ModuleState.empty() : ModuleState.data(events);
    } catch (_) {
      _state = ModuleState.error(const AppError(type: AppErrorType.storage, message: '日程读取失败'));
    }
    notifyListeners();
  }

  Future<void> addEvent(String title, DateTime startsAt) async {
    await _service.createEvent(title, startsAt);
    await loadToday();
  }

  Future<void> toggleCompleted(int id, bool completed) async {
    await _service.toggleCompleted(id, completed);
    await loadToday();
  }

  Future<void> deleteEvent(int id) async {
    await _service.deleteEvent(id);
    await loadToday();
  }
}
```

- [ ] **Step 6: Implement calendar card**

Create `lib/modules/calendar/calendar_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/calendar_event.dart';
import '../../shared/module_state.dart';
import '../../shared/widgets/module_card.dart';
import '../../shared/widgets/module_empty_widget.dart';
import '../../shared/widgets/module_error_widget.dart';
import '../../shared/widgets/module_loading_widget.dart';
import 'calendar_provider.dart';

class CalendarCard extends StatelessWidget {
  const CalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    return ModuleCard(
      title: '日历与日程',
      icon: Icons.event_note_outlined,
      child: _CalendarBody(state: provider.state, provider: provider),
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({required this.state, required this.provider});

  final ModuleState<List<CalendarEvent>> state;
  final CalendarProvider provider;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const ModuleLoadingWidget();
    if (state.hasError) return ModuleErrorWidget(message: state.error!.message, onRetry: provider.loadToday);
    if (state.isEmpty) return const ModuleEmptyWidget(message: '今天还没有日程');
    final events = state.data ?? [];
    return Column(
      children: [
        for (final event in events)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: event.isCompleted,
            title: Text(event.title),
            subtitle: Text(DateFormat('HH:mm').format(event.startsAt)),
            onChanged: (value) => provider.toggleCompleted(event.id!, value ?? false),
          ),
      ],
    );
  }
}
```

- [ ] **Step 7: Replace calendar placeholder on the home screen and wire provider in `main.dart`**

Modify `lib/main.dart` to create `AppDatabase`, `SqliteCalendarService`, and provide `CalendarProvider`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/database/app_database.dart';
import 'core/storage.dart';
import 'modules/calendar/calendar_provider.dart';
import 'modules/calendar/calendar_service.dart';
import 'shared/module_config_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await AppStorage.create();
  final database = await AppDatabase.open();
  final moduleConfigProvider = ModuleConfigProvider(storage);
  await moduleConfigProvider.load();
  final calendarProvider = CalendarProvider(SqliteCalendarService(database.database));
  await calendarProvider.loadToday();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: moduleConfigProvider),
        ChangeNotifierProvider.value(value: calendarProvider),
      ],
      child: const MorningBriefApp(),
    ),
  );
}
```

In `lib/shared/screens/home_screen.dart`, import the calendar card and use it in `_PlaceholderModuleCard.build` for `MorningModuleId.calendar`:

```dart
import '../../modules/calendar/calendar_card.dart';
```

Replace the first line inside `_PlaceholderModuleCard.build` with:

```dart
if (id == MorningModuleId.calendar) return const CalendarCard();
```

- [ ] **Step 8: Run calendar tests, widget tests, and analyzer**

```bash
flutter test test/modules/calendar/calendar_service_test.dart test/modules/calendar/calendar_provider_test.dart test/widget_test.dart test/shared/home_screen_test.dart
flutter analyze
```

Expected: all tests PASS; analyzer reports `No issues found!`.

- [ ] **Step 9: Commit**

```bash
git add lib/modules/calendar lib/main.dart lib/shared/screens/home_screen.dart test/modules/calendar
git commit -m "feat: add local calendar module"
```

Expected: commit succeeds if the workspace is a git repository. If not a git repository, record the skipped commit in the task notes and continue.

---

### Task 6: Weather Module

**Files:**
- Create: `lib/modules/weather/weather_service.dart`
- Create: `lib/modules/weather/weather_provider.dart`
- Create: `lib/modules/weather/weather_card.dart`
- Modify: `lib/main.dart`
- Modify: `lib/shared/screens/home_screen.dart`
- Create: `test/modules/weather/weather_service_test.dart`
- Create: `test/modules/weather/weather_provider_test.dart`

**Interfaces:**
- Consumes: `ApiClient`, `CacheManager`, `WeatherModel`, `ModuleConfigProvider`, `ModuleState`.
- Produces:
  - `WeatherService.fetchWeather({required String city, required String apiKey})`.
  - `WeatherProvider.refresh()` that uses cache and exposes offline cached values.
  - `WeatherCard` with API-key prompt, loading, error, empty, offline, and data states.

- [ ] **Step 1: Write failing weather service test using fixed API JSON**

Create `test/modules/weather/weather_service_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morningbrief/core/api_client.dart';
import 'package:morningbrief/modules/weather/weather_service.dart';

void main() {
  test('WeatherService parses current weather and three-day forecast', () async {
    final client = ApiClient(MockClient((request) async {
      if (request.url.host == 'api.openweathermap.org' && request.url.path.contains('/geo/1.0/direct')) {
        return http.Response(jsonEncode([{'lat': 31.2304, 'lon': 121.4737}]), 200);
      }
      return http.Response(jsonEncode({
        'current': {
          'temp': 24.5,
          'feels_like': 25.1,
          'humidity': 61,
          'wind_speed': 3.2,
          'weather': [{'description': '多云', 'icon': '03d'}]
        },
        'daily': [
          {'dt': 1783382400, 'temp': {'min': 22, 'max': 28}, 'weather': [{'description': '小雨', 'icon': '10d'}]},
          {'dt': 1783468800, 'temp': {'min': 23, 'max': 29}, 'weather': [{'description': '晴', 'icon': '01d'}]},
          {'dt': 1783555200, 'temp': {'min': 24, 'max': 30}, 'weather': [{'description': '阴', 'icon': '04d'}]}
        ]
      }), 200);
    }));
    final service = WeatherService(client, now: () => DateTime(2026, 7, 7, 8));

    final model = await service.fetchWeather(city: '上海', apiKey: 'key');

    expect(model.city, '上海');
    expect(model.temperature, 24.5);
    expect(model.forecast.length, 3);
  });
}
```

- [ ] **Step 2: Implement weather service**

Create `lib/modules/weather/weather_service.dart`:

```dart
import 'dart:convert';
import '../../core/api_client.dart';
import '../../models/weather_model.dart';

class WeatherService {
  WeatherService(this._client, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final ApiClient _client;
  final DateTime Function() _now;

  Future<WeatherModel> fetchWeather({required String city, required String apiKey}) async {
    final geoUri = Uri.https('api.openweathermap.org', '/geo/1.0/direct', {'q': city, 'limit': '1', 'appid': apiKey});
    final geoText = await _client.getText(geoUri);
    final geo = jsonDecode(geoText) as List<dynamic>;
    if (geo.isEmpty) throw ApiClientException('未找到城市');
    final first = geo.first as Map<String, dynamic>;
    final lat = (first['lat'] as num).toString();
    final lon = (first['lon'] as num).toString();

    final weatherUri = Uri.https('api.openweathermap.org', '/data/3.0/onecall', {
      'lat': lat,
      'lon': lon,
      'exclude': 'minutely,hourly,alerts',
      'appid': apiKey,
      'units': 'metric',
      'lang': 'zh_cn',
    });
    final json = await _client.getJson(weatherUri);
    final current = json['current'] as Map<String, dynamic>;
    final currentWeather = (current['weather'] as List<dynamic>).first as Map<String, dynamic>;
    final daily = (json['daily'] as List<dynamic>).take(3).map((item) {
      final map = item as Map<String, dynamic>;
      final weather = (map['weather'] as List<dynamic>).first as Map<String, dynamic>;
      final temp = map['temp'] as Map<String, dynamic>;
      return WeatherForecast(
        date: DateTime.fromMillisecondsSinceEpoch((map['dt'] as int) * 1000),
        minTemp: (temp['min'] as num).toDouble(),
        maxTemp: (temp['max'] as num).toDouble(),
        description: weather['description'] as String,
        iconCode: weather['icon'] as String,
      );
    }).toList();

    return WeatherModel(
      city: city,
      temperature: (current['temp'] as num).toDouble(),
      feelsLike: (current['feels_like'] as num).toDouble(),
      humidity: current['humidity'] as int,
      windSpeed: (current['wind_speed'] as num).toDouble(),
      description: currentWeather['description'] as String,
      iconCode: currentWeather['icon'] as String,
      forecast: daily,
      updatedAt: _now(),
    );
  }
}
```

- [ ] **Step 3: Run weather service test**

```bash
flutter test test/modules/weather/weather_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Write failing weather provider test**

Create `test/modules/weather/weather_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/models/weather_model.dart';
import 'package:morningbrief/modules/weather/weather_provider.dart';
import 'package:morningbrief/shared/module_state.dart';

class FakeWeatherRepository implements WeatherRepository {
  int calls = 0;
  @override
  Future<WeatherModel> fetchWeather({required String city, required String apiKey}) async {
    calls++;
    return WeatherModel(
      city: city,
      temperature: 24,
      feelsLike: 25,
      humidity: 60,
      windSpeed: 3,
      description: '多云',
      iconCode: '03d',
      forecast: [],
      updatedAt: DateTime(2026, 7, 7, 8),
    );
  }
}

void main() {
  test('WeatherProvider requires API key', () async {
    final provider = WeatherProvider(repository: FakeWeatherRepository(), cache: MemoryCacheManager(), cityReader: () => '上海', apiKeyReader: () => '');

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.error);
    expect(provider.state.error!.message, '请先在设置中填写 OpenWeatherMap API Key');
  });

  test('WeatherProvider fetches and caches weather', () async {
    final repository = FakeWeatherRepository();
    final provider = WeatherProvider(repository: repository, cache: MemoryCacheManager(now: () => DateTime(2026, 7, 7, 8)), cityReader: () => '上海', apiKeyReader: () => 'key');

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.city, '上海');
    expect(repository.calls, 1);
  });
}
```

- [ ] **Step 5: Implement weather provider**

Create `lib/modules/weather/weather_provider.dart`:

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/app_error.dart';
import '../../core/cache_manager.dart';
import '../../core/constants.dart';
import '../../models/weather_model.dart';
import '../../shared/module_state.dart';
import 'weather_service.dart';

abstract class WeatherRepository {
  Future<WeatherModel> fetchWeather({required String city, required String apiKey});
}

class WeatherServiceRepository implements WeatherRepository {
  WeatherServiceRepository(this._service);

  final WeatherService _service;

  @override
  Future<WeatherModel> fetchWeather({required String city, required String apiKey}) {
    return _service.fetchWeather(city: city, apiKey: apiKey);
  }
}

class WeatherProvider extends ChangeNotifier {
  WeatherProvider({required this.repository, required this.cache, required this.cityReader, required this.apiKeyReader});

  final WeatherRepository repository;
  final CacheManager cache;
  final String Function() cityReader;
  final String Function() apiKeyReader;
  ModuleState<WeatherModel> _state = ModuleState.idle();

  ModuleState<WeatherModel> get state => _state;

  Future<void> loadFromCacheOrRefresh() async {
    final cached = await cache.readFresh(AppConstants.cacheWeather, const Duration(minutes: 30));
    if (cached != null) {
      _state = ModuleState.data(WeatherModel.fromJson(jsonDecode(cached.jsonValue) as Map<String, dynamic>));
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    final apiKey = apiKeyReader();
    if (apiKey.isEmpty) {
      _state = ModuleState.error(const AppError(type: AppErrorType.apiKeyMissing, message: '请先在设置中填写 OpenWeatherMap API Key'));
      notifyListeners();
      return;
    }
    _state = ModuleState.loading();
    notifyListeners();
    try {
      final weather = await repository.fetchWeather(city: cityReader(), apiKey: apiKey);
      await cache.save(AppConstants.cacheWeather, jsonEncode(weather.toJson()));
      _state = ModuleState.data(weather);
    } catch (_) {
      final cached = await cache.readAny(AppConstants.cacheWeather);
      if (cached != null) {
        _state = ModuleState.offline(WeatherModel.fromJson(jsonDecode(cached.jsonValue) as Map<String, dynamic>));
      } else {
        _state = ModuleState.error(const AppError(type: AppErrorType.network, message: '天气加载失败，请检查网络'));
      }
    }
    notifyListeners();
  }
}
```

- [ ] **Step 6: Implement weather card**

Create `lib/modules/weather/weather_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/weather_model.dart';
import '../../shared/module_state.dart';
import '../../shared/widgets/module_card.dart';
import '../../shared/widgets/module_error_widget.dart';
import '../../shared/widgets/module_loading_widget.dart';
import 'weather_provider.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final state = provider.state;
    return ModuleCard(
      title: '天气',
      icon: Icons.wb_sunny_outlined,
      offline: state.isOffline,
      child: _WeatherBody(state: state, onRetry: provider.refresh),
    );
  }
}

class _WeatherBody extends StatelessWidget {
  const _WeatherBody({required this.state, required this.onRetry});

  final ModuleState<WeatherModel> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const ModuleLoadingWidget();
    if (state.hasError) return ModuleErrorWidget(message: state.error!.message, onRetry: onRetry);
    final weather = state.data;
    if (weather == null) return const Text('暂无天气数据');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${weather.city} ${weather.temperature.toStringAsFixed(0)}°C', style: Theme.of(context).textTheme.headlineSmall),
        Text('${weather.description} · 体感 ${weather.feelsLike.toStringAsFixed(0)}°C · 湿度 ${weather.humidity}%'),
        const SizedBox(height: 12),
        for (final item in weather.forecast)
          Text('${DateFormat('M/d').format(item.date)} ${item.description} ${item.minTemp.toStringAsFixed(0)}°/${item.maxTemp.toStringAsFixed(0)}°'),
      ],
    );
  }
}
```

- [ ] **Step 7: Wire weather provider and card**

Modify `lib/main.dart` to create an `ApiClient`, `SqliteCacheManager`, and `WeatherProvider` inside `MultiProvider`:

```dart
final apiClient = ApiClient();
final cacheManager = SqliteCacheManager(database.database);
final weatherProvider = WeatherProvider(
  repository: WeatherServiceRepository(WeatherService(apiClient)),
  cache: cacheManager,
  cityReader: () => moduleConfigProvider.city,
  apiKeyReader: () => moduleConfigProvider.weatherApiKey,
);
await weatherProvider.loadFromCacheOrRefresh();
```

Add to `providers`: 

```dart
ChangeNotifierProvider.value(value: weatherProvider),
```

In `lib/shared/screens/home_screen.dart`, import and route weather card:

```dart
import '../../modules/weather/weather_card.dart';
```

Inside `_PlaceholderModuleCard.build`, before the calendar check:

```dart
if (id == MorningModuleId.weather) return const WeatherCard();
```

- [ ] **Step 8: Run weather tests, widget tests, and analyzer**

```bash
flutter test test/modules/weather/weather_service_test.dart test/modules/weather/weather_provider_test.dart test/widget_test.dart
flutter analyze
```

Expected: all tests PASS; analyzer reports `No issues found!`.

- [ ] **Step 9: Commit**

```bash
git add lib/modules/weather lib/main.dart lib/shared/screens/home_screen.dart test/modules/weather
git commit -m "feat: add weather module"
```

Expected: commit succeeds if the workspace is a git repository. If not a git repository, record the skipped commit in the task notes and continue.

---

### Task 7: General News RSS Module

**Files:**
- Create: `lib/modules/news/news_service.dart`
- Create: `lib/modules/news/news_provider.dart`
- Create: `lib/modules/news/news_card.dart`
- Modify: `lib/main.dart`
- Modify: `lib/shared/screens/home_screen.dart`
- Create: `test/modules/news/news_service_test.dart`
- Create: `test/modules/news/news_provider_test.dart`

**Interfaces:**
- Consumes: `ApiClient`, `CacheManager`, `NewsArticle`, `ModuleState`.
- Produces:
  - `NewsService.fetchArticles(List<Uri> feeds, {int limit = 10})`.
  - `NewsProvider.loadFromCacheOrRefresh()` and `refresh()`.
  - `NewsCard` with clickable article list in future UI extension; MVP displays title/source/summary.

- [ ] **Step 1: Write failing RSS parsing test**

Create `test/modules/news/news_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morningbrief/core/api_client.dart';
import 'package:morningbrief/modules/news/news_service.dart';

void main() {
  test('NewsService parses RSS items into articles', () async {
    const rss = '''
<rss><channel><title>新闻源</title>
<item><title>新闻一</title><description>摘要一</description><link>https://example.com/1</link><pubDate>Tue, 07 Jul 2026 08:00:00 GMT</pubDate></item>
<item><title>新闻二</title><description>摘要二</description><link>https://example.com/2</link><pubDate>Tue, 07 Jul 2026 09:00:00 GMT</pubDate></item>
</channel></rss>
''';
    final service = NewsService(ApiClient(MockClient((request) async => http.Response(rss, 200))));

    final articles = await service.fetchArticles([Uri.parse('https://example.com/rss')], limit: 10);

    expect(articles.length, 2);
    expect(articles.first.title, '新闻一');
    expect(articles.first.source, '新闻源');
  });
}
```

- [ ] **Step 2: Implement news service**

Create `lib/modules/news/news_service.dart`:

```dart
import 'package:xml/xml.dart';
import '../../core/api_client.dart';
import '../../models/news_article.dart';

class NewsService {
  NewsService(this._client);

  final ApiClient _client;

  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 10}) async {
    final articles = <NewsArticle>[];
    for (final feed in feeds) {
      final xmlText = await _client.getText(feed);
      articles.addAll(_parseRss(xmlText));
    }
    articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles.take(limit).toList();
  }

  List<NewsArticle> _parseRss(String xmlText) {
    final document = XmlDocument.parse(xmlText);
    final channel = document.findAllElements('channel').isEmpty ? null : document.findAllElements('channel').first;
    final source = channel?.findElements('title').firstOrNull?.innerText.trim() ?? '新闻源';
    return document.findAllElements('item').map((item) {
      final title = item.findElements('title').firstOrNull?.innerText.trim() ?? '未命名新闻';
      final summary = item.findElements('description').firstOrNull?.innerText.trim() ?? '';
      final link = item.findElements('link').firstOrNull?.innerText.trim() ?? 'https://example.com';
      final pubDate = item.findElements('pubDate').firstOrNull?.innerText.trim();
      return NewsArticle(
        title: title,
        summary: summary,
        source: source,
        url: Uri.parse(link),
        publishedAt: pubDate == null ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(HttpDateParser.toIso8601(pubDate)),
      );
    }).toList();
  }
}

class HttpDateParser {
  const HttpDateParser._();

  static String toIso8601(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toIso8601String();
    return DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();
  }
}
```

Replace `publishedAt` parsing in `_parseRss` with this robust Dart standard-library parser and add `dart:io` import:

```dart
import 'dart:io';
```

```dart
publishedAt: pubDate == null ? DateTime.fromMillisecondsSinceEpoch(0) : HttpDate.parse(pubDate),
```

Remove the `HttpDateParser` class after using `HttpDate.parse`.

- [ ] **Step 3: Run news service test**

```bash
flutter test test/modules/news/news_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Write failing news provider test**

Create `test/modules/news/news_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/modules/news/news_provider.dart';
import 'package:morningbrief/shared/module_state.dart';

class FakeNewsRepository implements NewsRepository {
  @override
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 10}) async {
    return [NewsArticle(title: '新闻一', summary: '摘要', source: '新闻源', url: Uri.parse('https://example.com'), publishedAt: DateTime(2026, 7, 7))];
  }
}

void main() {
  test('NewsProvider loads articles', () async {
    final provider = NewsProvider(repository: FakeNewsRepository(), cache: MemoryCacheManager(), feedsReader: () => [Uri.parse('https://example.com/rss')]);

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.single.title, '新闻一');
  });
}
```

- [ ] **Step 5: Implement news provider**

Create `lib/modules/news/news_provider.dart`:

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/app_error.dart';
import '../../core/cache_manager.dart';
import '../../core/constants.dart';
import '../../models/news_article.dart';
import '../../shared/module_state.dart';
import 'news_service.dart';

abstract class NewsRepository {
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 10});
}

class NewsServiceRepository implements NewsRepository {
  NewsServiceRepository(this._service);

  final NewsService _service;

  @override
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 10}) => _service.fetchArticles(feeds, limit: limit);
}

class NewsProvider extends ChangeNotifier {
  NewsProvider({required this.repository, required this.cache, required this.feedsReader});

  final NewsRepository repository;
  final CacheManager cache;
  final List<Uri> Function() feedsReader;
  ModuleState<List<NewsArticle>> _state = ModuleState.idle();

  ModuleState<List<NewsArticle>> get state => _state;

  Future<void> loadFromCacheOrRefresh() async {
    final cached = await cache.readFresh(AppConstants.cacheNews, const Duration(hours: 1));
    if (cached != null) {
      _state = ModuleState.data(_decodeArticles(cached.jsonValue));
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    _state = ModuleState.loading();
    notifyListeners();
    try {
      final articles = await repository.fetchArticles(feedsReader(), limit: 10);
      if (articles.isEmpty) {
        _state = ModuleState.empty();
      } else {
        await cache.save(AppConstants.cacheNews, jsonEncode(articles.map((item) => item.toJson()).toList()));
        _state = ModuleState.data(articles);
      }
    } catch (_) {
      final cached = await cache.readAny(AppConstants.cacheNews);
      if (cached != null) {
        _state = ModuleState.offline(_decodeArticles(cached.jsonValue));
      } else {
        _state = ModuleState.error(const AppError(type: AppErrorType.network, message: '新闻加载失败，请稍后重试'));
      }
    }
    notifyListeners();
  }

  List<NewsArticle> _decodeArticles(String raw) {
    return (jsonDecode(raw) as List<dynamic>).map((item) => NewsArticle.fromJson(item as Map<String, dynamic>)).toList();
  }
}
```

- [ ] **Step 6: Implement news card**

Create `lib/modules/news/news_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/news_article.dart';
import '../../shared/module_state.dart';
import '../../shared/widgets/module_card.dart';
import '../../shared/widgets/module_empty_widget.dart';
import '../../shared/widgets/module_error_widget.dart';
import '../../shared/widgets/module_loading_widget.dart';
import 'news_provider.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    return ModuleCard(
      title: '新闻头条',
      icon: Icons.article_outlined,
      offline: provider.state.isOffline,
      child: _NewsBody(state: provider.state, onRetry: provider.refresh),
    );
  }
}

class _NewsBody extends StatelessWidget {
  const _NewsBody({required this.state, required this.onRetry});

  final ModuleState<List<NewsArticle>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const ModuleLoadingWidget();
    if (state.hasError) return ModuleErrorWidget(message: state.error!.message, onRetry: onRetry);
    if (state.isEmpty) return const ModuleEmptyWidget(message: '暂无新闻');
    final articles = state.data ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final article in articles.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                Text(article.source, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 7: Wire news provider and card**

In `lib/main.dart`, create provider:

```dart
final newsProvider = NewsProvider(
  repository: NewsServiceRepository(NewsService(apiClient)),
  cache: cacheManager,
  feedsReader: () => AppConstants.generalNewsFeeds,
);
await newsProvider.loadFromCacheOrRefresh();
```

Add to `MultiProvider`:

```dart
ChangeNotifierProvider.value(value: newsProvider),
```

In `lib/shared/screens/home_screen.dart`, import and route:

```dart
import '../../modules/news/news_card.dart';
```

Inside `_PlaceholderModuleCard.build`:

```dart
if (id == MorningModuleId.news) return const NewsCard();
```

- [ ] **Step 8: Run news tests and analyzer**

```bash
flutter test test/modules/news/news_service_test.dart test/modules/news/news_provider_test.dart test/widget_test.dart
flutter analyze
```

Expected: all tests PASS; analyzer reports `No issues found!`.

- [ ] **Step 9: Commit**

```bash
git add lib/modules/news lib/main.dart lib/shared/screens/home_screen.dart test/modules/news
git commit -m "feat: add general news module"
```

Expected: commit succeeds if the workspace is a git repository. If not a git repository, record the skipped commit in the task notes and continue.

---

### Task 8: Stocks Module

**Files:**
- Create: `lib/modules/stocks/stocks_service.dart`
- Create: `lib/modules/stocks/stocks_provider.dart`
- Create: `lib/modules/stocks/stocks_card.dart`
- Modify: `lib/main.dart`
- Modify: `lib/shared/screens/home_screen.dart`
- Create: `test/modules/stocks/stocks_service_test.dart`
- Create: `test/modules/stocks/stocks_provider_test.dart`

**Interfaces:**
- Consumes: `ApiClient`, `CacheManager`, `StockItem`, `ModuleConfigProvider`, `AppColors`.
- Produces:
  - `StocksService.fetchQuotes(List<String> symbols, String apiKey)`.
  - `StocksProvider.refresh()` with API-key validation and cache fallback.
  - `StocksCard` showing red gains and green losses.

- [ ] **Step 1: Write failing stock service test**

Create `test/modules/stocks/stocks_service_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morningbrief/core/api_client.dart';
import 'package:morningbrief/modules/stocks/stocks_service.dart';

void main() {
  test('StocksService parses Alpha Vantage quote', () async {
    final service = StocksService(ApiClient(MockClient((request) async {
      return http.Response(jsonEncode({
        'Global Quote': {
          '01. symbol': '600036.SHH',
          '05. price': '35.2000',
          '09. change': '0.3000',
          '10. change percent': '0.8600%'
        }
      }), 200);
    })), now: () => DateTime(2026, 7, 7, 10));

    final quotes = await service.fetchQuotes(['600036.SHH'], 'key');

    expect(quotes.single.symbol, '600036.SHH');
    expect(quotes.single.price, 35.2);
    expect(quotes.single.changePercent, 0.86);
  });
}
```

- [ ] **Step 2: Implement stock service**

Create `lib/modules/stocks/stocks_service.dart`:

```dart
import '../../core/api_client.dart';
import '../../models/stock_item.dart';

class StocksService {
  StocksService(this._client, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final ApiClient _client;
  final DateTime Function() _now;

  Future<List<StockItem>> fetchQuotes(List<String> symbols, String apiKey) async {
    final items = <StockItem>[];
    for (final symbol in symbols) {
      final uri = Uri.https('www.alphavantage.co', '/query', {'function': 'GLOBAL_QUOTE', 'symbol': symbol, 'apikey': apiKey});
      final json = await _client.getJson(uri);
      final quote = json['Global Quote'] as Map<String, dynamic>?;
      if (quote == null || quote.isEmpty) continue;
      items.add(StockItem(
        symbol: quote['01. symbol'] as String? ?? symbol,
        name: symbol,
        price: double.parse(quote['05. price'] as String),
        change: double.parse(quote['09. change'] as String),
        changePercent: double.parse((quote['10. change percent'] as String).replaceAll('%', '')),
        updatedAt: _now(),
      ));
    }
    return items;
  }
}
```

- [ ] **Step 3: Run stock service test**

```bash
flutter test test/modules/stocks/stocks_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Write failing stock provider test**

Create `test/modules/stocks/stocks_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/models/stock_item.dart';
import 'package:morningbrief/modules/stocks/stocks_provider.dart';
import 'package:morningbrief/shared/module_state.dart';

class FakeStocksRepository implements StocksRepository {
  @override
  Future<List<StockItem>> fetchQuotes(List<String> symbols, String apiKey) async {
    return [StockItem(symbol: symbols.first, name: symbols.first, price: 35.2, change: -0.1, changePercent: -0.28, updatedAt: DateTime(2026, 7, 7, 10))];
  }
}

void main() {
  test('StocksProvider requires API key', () async {
    final provider = StocksProvider(repository: FakeStocksRepository(), cache: MemoryCacheManager(), symbolsReader: () => ['600036.SHH'], apiKeyReader: () => '');

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.error);
    expect(provider.state.error!.message, '请先在设置中填写 Alpha Vantage API Key');
  });

  test('StocksProvider loads quotes', () async {
    final provider = StocksProvider(repository: FakeStocksRepository(), cache: MemoryCacheManager(), symbolsReader: () => ['600036.SHH'], apiKeyReader: () => 'key');

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.single.symbol, '600036.SHH');
  });
}
```

- [ ] **Step 5: Implement stock provider**

Create `lib/modules/stocks/stocks_provider.dart`:

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/app_error.dart';
import '../../core/cache_manager.dart';
import '../../core/constants.dart';
import '../../models/stock_item.dart';
import '../../shared/module_state.dart';
import 'stocks_service.dart';

abstract class StocksRepository {
  Future<List<StockItem>> fetchQuotes(List<String> symbols, String apiKey);
}

class StocksServiceRepository implements StocksRepository {
  StocksServiceRepository(this._service);

  final StocksService _service;

  @override
  Future<List<StockItem>> fetchQuotes(List<String> symbols, String apiKey) => _service.fetchQuotes(symbols, apiKey);
}

class StocksProvider extends ChangeNotifier {
  StocksProvider({required this.repository, required this.cache, required this.symbolsReader, required this.apiKeyReader});

  final StocksRepository repository;
  final CacheManager cache;
  final List<String> Function() symbolsReader;
  final String Function() apiKeyReader;
  ModuleState<List<StockItem>> _state = ModuleState.idle();

  ModuleState<List<StockItem>> get state => _state;

  Future<void> loadFromCacheOrRefresh() async {
    final cached = await cache.readFresh(AppConstants.cacheStocks, const Duration(minutes: 15));
    if (cached != null) {
      _state = ModuleState.data(_decode(cached.jsonValue));
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    final apiKey = apiKeyReader();
    if (apiKey.isEmpty) {
      _state = ModuleState.error(const AppError(type: AppErrorType.apiKeyMissing, message: '请先在设置中填写 Alpha Vantage API Key'));
      notifyListeners();
      return;
    }
    _state = ModuleState.loading();
    notifyListeners();
    try {
      final quotes = await repository.fetchQuotes(symbolsReader(), apiKey);
      if (quotes.isEmpty) {
        _state = ModuleState.empty();
      } else {
        await cache.save(AppConstants.cacheStocks, jsonEncode(quotes.map((item) => item.toJson()).toList()));
        _state = ModuleState.data(quotes);
      }
    } catch (_) {
      final cached = await cache.readAny(AppConstants.cacheStocks);
      if (cached != null) {
        _state = ModuleState.offline(_decode(cached.jsonValue));
      } else {
        _state = ModuleState.error(const AppError(type: AppErrorType.network, message: '股票行情加载失败'));
      }
    }
    notifyListeners();
  }

  List<StockItem> _decode(String raw) => (jsonDecode(raw) as List<dynamic>).map((item) => StockItem.fromJson(item as Map<String, dynamic>)).toList();
}
```

- [ ] **Step 6: Implement stock card**

Create `lib/modules/stocks/stocks_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../models/stock_item.dart';
import '../../shared/module_state.dart';
import '../../shared/widgets/module_card.dart';
import '../../shared/widgets/module_empty_widget.dart';
import '../../shared/widgets/module_error_widget.dart';
import '../../shared/widgets/module_loading_widget.dart';
import 'stocks_provider.dart';

class StocksCard extends StatelessWidget {
  const StocksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StocksProvider>();
    return ModuleCard(
      title: '股票财经',
      icon: Icons.show_chart,
      offline: provider.state.isOffline,
      child: _StocksBody(state: provider.state, onRetry: provider.refresh),
    );
  }
}

class _StocksBody extends StatelessWidget {
  const _StocksBody({required this.state, required this.onRetry});

  final ModuleState<List<StockItem>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const ModuleLoadingWidget();
    if (state.hasError) return ModuleErrorWidget(message: state.error!.message, onRetry: onRetry);
    if (state.isEmpty) return const ModuleEmptyWidget(message: '暂无行情');
    final items = state.data ?? [];
    return Column(
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.symbol),
            subtitle: Text(item.name),
            trailing: Text(
              '${item.price.toStringAsFixed(2)} ${item.changePercent.toStringAsFixed(2)}%',
              style: TextStyle(color: item.isUp ? AppColors.profitRed : AppColors.lossGreen),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 7: Wire stock provider and card**

In `lib/main.dart`, create provider:

```dart
final stocksProvider = StocksProvider(
  repository: StocksServiceRepository(StocksService(apiClient)),
  cache: cacheManager,
  symbolsReader: () => moduleConfigProvider.stockSymbols,
  apiKeyReader: () => moduleConfigProvider.stockApiKey,
);
await stocksProvider.loadFromCacheOrRefresh();
```

Add to `MultiProvider`:

```dart
ChangeNotifierProvider.value(value: stocksProvider),
```

In `lib/shared/screens/home_screen.dart`, import and route:

```dart
import '../../modules/stocks/stocks_card.dart';
```

Inside `_PlaceholderModuleCard.build`:

```dart
if (id == MorningModuleId.stocks) return const StocksCard();
```

- [ ] **Step 8: Run stock tests and analyzer**

```bash
flutter test test/modules/stocks/stocks_service_test.dart test/modules/stocks/stocks_provider_test.dart test/widget_test.dart
flutter analyze
```

Expected: all tests PASS; analyzer reports `No issues found!`.

- [ ] **Step 9: Commit**

```bash
git add lib/modules/stocks lib/main.dart lib/shared/screens/home_screen.dart test/modules/stocks
git commit -m "feat: add stocks module"
```

Expected: commit succeeds if the workspace is a git repository. If not a git repository, record the skipped commit in the task notes and continue.

---

### Task 9: Tech/AI News Module

**Files:**
- Create: `lib/modules/tech_news/tech_news_service.dart`
- Create: `lib/modules/tech_news/tech_news_provider.dart`
- Create: `lib/modules/tech_news/tech_news_card.dart`
- Modify: `lib/main.dart`
- Modify: `lib/shared/screens/home_screen.dart`
- Create: `test/modules/tech_news/tech_news_service_test.dart`
- Create: `test/modules/tech_news/tech_news_provider_test.dart`

**Interfaces:**
- Consumes: `NewsService` RSS parser, `NewsArticle`, `CacheManager`, `AppConstants.techNewsFeeds`.
- Produces:
  - `TechNewsService.fetchArticles({int limit = 8})`.
  - `TechNewsProvider` with a separate cache key from general news.
  - `TechNewsCard` titled `科技 AI 新闻`.

- [ ] **Step 1: Write failing Tech/AI service test**

Create `test/modules/tech_news/tech_news_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/modules/tech_news/tech_news_service.dart';

class FakeTechNewsRepository implements TechNewsRepositorySource {
  @override
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 8}) async {
    return [NewsArticle(title: 'AI 模型发布', summary: '摘要', source: '机器之心', url: Uri.parse('https://example.com/ai'), publishedAt: DateTime(2026, 7, 7))];
  }
}

void main() {
  test('TechNewsService delegates to RSS source with Tech/AI feeds', () async {
    final service = TechNewsService(FakeTechNewsRepository(), feeds: [Uri.parse('https://example.com/rss')]);

    final articles = await service.fetchArticles(limit: 8);

    expect(articles.single.title, 'AI 模型发布');
  });
}
```

- [ ] **Step 2: Implement Tech/AI service wrapper**

Create `lib/modules/tech_news/tech_news_service.dart`:

```dart
import '../../core/constants.dart';
import '../../models/news_article.dart';
import '../news/news_service.dart';

abstract class TechNewsRepositorySource {
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 8});
}

class NewsServiceTechSource implements TechNewsRepositorySource {
  NewsServiceTechSource(this._service);

  final NewsService _service;

  @override
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 8}) => _service.fetchArticles(feeds, limit: limit);
}

class TechNewsService {
  TechNewsService(this._source, {List<Uri>? feeds}) : _feeds = feeds ?? AppConstants.techNewsFeeds;

  final TechNewsRepositorySource _source;
  final List<Uri> _feeds;

  Future<List<NewsArticle>> fetchArticles({int limit = 8}) => _source.fetchArticles(_feeds, limit: limit);
}
```

- [ ] **Step 3: Run Tech/AI service test**

```bash
flutter test test/modules/tech_news/tech_news_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Write failing Tech/AI provider test**

Create `test/modules/tech_news/tech_news_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/modules/tech_news/tech_news_provider.dart';
import 'package:morningbrief/shared/module_state.dart';

class FakeTechNewsRepository implements TechNewsRepository {
  @override
  Future<List<NewsArticle>> fetchArticles({int limit = 8}) async {
    return [NewsArticle(title: 'AI 新闻', summary: '摘要', source: '量子位', url: Uri.parse('https://example.com'), publishedAt: DateTime(2026, 7, 7))];
  }
}

void main() {
  test('TechNewsProvider loads Tech/AI articles', () async {
    final provider = TechNewsProvider(repository: FakeTechNewsRepository(), cache: MemoryCacheManager());

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.single.source, '量子位');
  });
}
```

- [ ] **Step 5: Implement Tech/AI provider**

Create `lib/modules/tech_news/tech_news_provider.dart`:

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/app_error.dart';
import '../../core/cache_manager.dart';
import '../../core/constants.dart';
import '../../models/news_article.dart';
import '../../shared/module_state.dart';
import 'tech_news_service.dart';

abstract class TechNewsRepository {
  Future<List<NewsArticle>> fetchArticles({int limit = 8});
}

class TechNewsServiceRepository implements TechNewsRepository {
  TechNewsServiceRepository(this._service);

  final TechNewsService _service;

  @override
  Future<List<NewsArticle>> fetchArticles({int limit = 8}) => _service.fetchArticles(limit: limit);
}

class TechNewsProvider extends ChangeNotifier {
  TechNewsProvider({required this.repository, required this.cache});

  final TechNewsRepository repository;
  final CacheManager cache;
  ModuleState<List<NewsArticle>> _state = ModuleState.idle();

  ModuleState<List<NewsArticle>> get state => _state;

  Future<void> loadFromCacheOrRefresh() async {
    final cached = await cache.readFresh(AppConstants.cacheTechNews, const Duration(hours: 1));
    if (cached != null) {
      _state = ModuleState.data(_decode(cached.jsonValue));
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    _state = ModuleState.loading();
    notifyListeners();
    try {
      final articles = await repository.fetchArticles(limit: 8);
      if (articles.isEmpty) {
        _state = ModuleState.empty();
      } else {
        await cache.save(AppConstants.cacheTechNews, jsonEncode(articles.map((item) => item.toJson()).toList()));
        _state = ModuleState.data(articles);
      }
    } catch (_) {
      final cached = await cache.readAny(AppConstants.cacheTechNews);
      if (cached != null) {
        _state = ModuleState.offline(_decode(cached.jsonValue));
      } else {
        _state = ModuleState.error(const AppError(type: AppErrorType.network, message: '科技新闻加载失败'));
      }
    }
    notifyListeners();
  }

  List<NewsArticle> _decode(String raw) => (jsonDecode(raw) as List<dynamic>).map((item) => NewsArticle.fromJson(item as Map<String, dynamic>)).toList();
}
```

- [ ] **Step 6: Implement Tech/AI news card**

Create `lib/modules/tech_news/tech_news_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/news_article.dart';
import '../../shared/module_state.dart';
import '../../shared/widgets/module_card.dart';
import '../../shared/widgets/module_empty_widget.dart';
import '../../shared/widgets/module_error_widget.dart';
import '../../shared/widgets/module_loading_widget.dart';
import 'tech_news_provider.dart';

class TechNewsCard extends StatelessWidget {
  const TechNewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TechNewsProvider>();
    return ModuleCard(
      title: '科技 AI 新闻',
      icon: Icons.memory_outlined,
      offline: provider.state.isOffline,
      child: _TechNewsBody(state: provider.state, onRetry: provider.refresh),
    );
  }
}

class _TechNewsBody extends StatelessWidget {
  const _TechNewsBody({required this.state, required this.onRetry});

  final ModuleState<List<NewsArticle>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const ModuleLoadingWidget();
    if (state.hasError) return ModuleErrorWidget(message: state.error!.message, onRetry: onRetry);
    if (state.isEmpty) return const ModuleEmptyWidget(message: '暂无科技资讯');
    final articles = state.data ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final article in articles.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('${article.title} · ${article.source}', maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}
```

- [ ] **Step 7: Wire Tech/AI provider and card**

In `lib/main.dart`, create provider:

```dart
final techNewsProvider = TechNewsProvider(
  repository: TechNewsServiceRepository(TechNewsService(NewsServiceTechSource(NewsService(apiClient)))),
  cache: cacheManager,
);
await techNewsProvider.loadFromCacheOrRefresh();
```

Add to `MultiProvider`:

```dart
ChangeNotifierProvider.value(value: techNewsProvider),
```

In `lib/shared/screens/home_screen.dart`, import and route:

```dart
import '../../modules/tech_news/tech_news_card.dart';
```

Inside `_PlaceholderModuleCard.build`:

```dart
if (id == MorningModuleId.techNews) return const TechNewsCard();
```

- [ ] **Step 8: Run Tech/AI tests and analyzer**

```bash
flutter test test/modules/tech_news/tech_news_service_test.dart test/modules/tech_news/tech_news_provider_test.dart test/widget_test.dart
flutter analyze
```

Expected: all tests PASS; analyzer reports `No issues found!`.

- [ ] **Step 9: Commit**

```bash
git add lib/modules/tech_news lib/main.dart lib/shared/screens/home_screen.dart test/modules/tech_news
git commit -m "feat: add tech AI news module"
```

Expected: commit succeeds if the workspace is a git repository. If not a git repository, record the skipped commit in the task notes and continue.

---

### Task 10: Refresh Orchestration, Polish, Documentation, and Android Build

**Files:**
- Modify: `lib/shared/screens/home_screen.dart`
- Modify: `lib/shared/screens/settings_screen.dart`
- Modify: `README.md`
- Modify: `test/shared/home_screen_test.dart`
- Modify: `test/shared/settings_screen_test.dart`

**Interfaces:**
- Consumes: all module providers and `ModuleConfigProvider`.
- Produces:
  - Home refresh button refreshes enabled network modules.
  - Settings save behavior updates providers on next refresh.
  - README contains exact run/test/build steps and API key notes.

- [ ] **Step 1: Update home screen test for refresh button**

Modify `test/shared/home_screen_test.dart` to add this test below the existing test:

```dart
testWidgets('HomeScreen has refresh and settings actions', (tester) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await AppStorage.create();
  final provider = ModuleConfigProvider(storage);
  await provider.load();

  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: HomeScreen()),
  ));

  expect(find.byIcon(Icons.refresh), findsOneWidget);
  expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
});
```

- [ ] **Step 2: Implement refresh orchestration in HomeScreen**

Convert `HomeScreen` in `lib/shared/screens/home_screen.dart` from `StatelessWidget` to `StatefulWidget`. Add this method to `_HomeScreenState`:

```dart
Future<void> _refreshEnabledModules(BuildContext context) async {
  final config = context.read<ModuleConfigProvider>();
  final futures = <Future<void>>[];

  if (config.isEnabled(MorningModuleId.weather)) futures.add(context.read<WeatherProvider>().refresh());
  if (config.isEnabled(MorningModuleId.news)) futures.add(context.read<NewsProvider>().refresh());
  if (config.isEnabled(MorningModuleId.calendar)) futures.add(context.read<CalendarProvider>().loadToday());
  if (config.isEnabled(MorningModuleId.stocks)) futures.add(context.read<StocksProvider>().refresh());
  if (config.isEnabled(MorningModuleId.techNews)) futures.add(context.read<TechNewsProvider>().refresh());

  await Future.wait(futures);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已刷新晨间简报')));
  }
}
```

Update refresh button:

```dart
IconButton(
  tooltip: '刷新',
  icon: const Icon(Icons.refresh),
  onPressed: () => _refreshEnabledModules(context),
),
```

Add required imports:

```dart
import 'package:provider/provider.dart';
import '../../modules/calendar/calendar_provider.dart';
import '../../modules/news/news_provider.dart';
import '../../modules/stocks/stocks_provider.dart';
import '../../modules/tech_news/tech_news_provider.dart';
import '../../modules/weather/weather_provider.dart';
```

- [ ] **Step 3: Make settings changes persist on editing completion**

In `lib/shared/screens/settings_screen.dart`, add `onEditingComplete` handlers so keyboard completion saves values without requiring the user to press enter:

```dart
onEditingComplete: () => provider.updateCity(_cityController.text),
```

```dart
onEditingComplete: () => provider.updateWeatherApiKey(_weatherKeyController.text),
```

```dart
onEditingComplete: () => provider.updateStockApiKey(_stockKeyController.text),
```

```dart
onEditingComplete: () => provider.updateStockSymbols(_symbolsController.text.split(',')),
```

Keep the existing `onSubmitted` handlers.

- [ ] **Step 4: Update README with final usage instructions**

Replace `README.md` with:

```markdown
# MorningBrief

MorningBrief is a Chinese-first customizable morning dashboard for Android, built with Flutter.

## What It Includes

- Weather card using OpenWeatherMap
- General news RSS card
- Local calendar and schedule card
- Alpha Vantage stock quotes card
- Tech/AI RSS card
- Local module configuration
- SQLite cache for offline display
- Light and dark Material 3 themes

## Requirements

- Flutter SDK 3.22 or newer
- Android Studio or Android SDK command-line tools
- Android emulator or physical Android device

## Setup

```bash
flutter pub get
```

## Run on Android

```bash
flutter run
```

## Test

```bash
flutter test
flutter analyze
```

## Build APK

```bash
flutter build apk --debug
```

## API Keys

Open Settings inside the app and fill in:

- OpenWeatherMap API Key for Weather
- Alpha Vantage API Key for Stocks

News and Tech/AI News use RSS feeds and do not require API keys.

## Local Data

- Module settings and API keys are stored with `shared_preferences`.
- Cached module data and calendar events are stored in local SQLite.
- The MVP does not use a custom backend server.
```

- [ ] **Step 5: Run full automated verification**

```bash
flutter pub get
flutter test
flutter analyze
```

Expected: all tests PASS; analyzer reports `No issues found!`.

- [ ] **Step 6: Run the app on Android**

Start an emulator or connect a device, then run:

```bash
flutter devices
flutter run
```

Expected:
- App launches with title `MorningBrief`.
- Home screen shows `早安！`.
- Settings button opens `设置`.
- Module toggles are visible.
- Calendar module can show empty state without crashing.
- Weather and Stocks cards show API-key guidance if keys are empty.
- News cards either load RSS items or show retryable errors without crashing the app.

- [ ] **Step 7: Build APK**

```bash
flutter build apk --debug
```

Expected: APK created under `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 8: Commit**

```bash
git add lib/shared/screens README.md test/shared
git commit -m "chore: polish dashboard refresh and docs"
```

Expected: commit succeeds if the workspace is a git repository. If not a git repository, record the skipped commit in the task notes and continue.

---

## Final End-to-End Verification

Run these commands from `e:\Claude_code_Project\MorningBrief` after all tasks:

```bash
flutter clean
flutter pub get
flutter test
flutter analyze
flutter build apk --debug
```

Expected final result:

- `flutter test` passes all test files.
- `flutter analyze` reports `No issues found!`.
- Debug APK exists at `build/app/outputs/flutter-apk/app-debug.apk`.
- Manual Android run confirms:
  - Home dashboard opens.
  - Settings screen opens.
  - Module toggles do not crash.
  - Empty API keys produce Chinese guidance messages.
  - Calendar events persist locally.
  - Network failures show per-module retry UI and do not break the whole dashboard.

## Self-Review Notes

- Spec coverage: app shell, modular architecture, Provider state, local settings, SQLite cache, Weather, News, Calendar, Stocks, Tech/AI News, error states, dark mode, and APK build are covered by Tasks 1-10.
- Placeholder scan: no `TBD`, `TODO`, `implement later`, or unspecified edge-handling instructions remain.
- Type consistency: `ModuleConfigProvider`, `ModuleState`, `CacheManager`, module providers, and model serialization signatures are defined before use in later tasks.
- Known implementation caution: RSS source availability can change. Tests use local mock RSS strings so app correctness does not depend on live feed availability during automated verification.
