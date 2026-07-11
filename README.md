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

- Flutter SDK 3.44 or newer
- Dart SDK 3.12 or newer
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

News and Tech/AI News use RSS feeds and do not require API keys. Never commit API keys to source control.

## Local Data

- Module settings and API keys are stored with `shared_preferences` on the device.
- Cached module data and calendar events are stored in local SQLite.
- The MVP does not use a custom backend server.
