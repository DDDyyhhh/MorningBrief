import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/constants.dart';
import 'package:morningbrief/models/weather_model.dart';
import 'package:morningbrief/modules/weather/weather_card.dart';
import 'package:morningbrief/modules/weather/weather_provider.dart';
import 'package:provider/provider.dart';

class _SuccessfulWeatherRepository implements WeatherRepository {
  _SuccessfulWeatherRepository(this.weather);

  final WeatherModel weather;
  int calls = 0;

  @override
  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  }) async {
    calls++;
    return weather;
  }
}

class _FailingWeatherRepository implements WeatherRepository {
  int calls = 0;

  @override
  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  }) async {
    calls++;
    throw StateError('network unavailable');
  }
}

class _PendingWeatherRepository implements WeatherRepository {
  final completer = Completer<WeatherModel>();
  int calls = 0;

  @override
  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  }) {
    calls++;
    return completer.future;
  }
}

WeatherModel _weather() {
  return WeatherModel(
    city: '\u4e0a\u6d77',
    temperature: 24,
    feelsLike: 25,
    humidity: 60,
    windSpeed: 3,
    description: '\u591a\u4e91',
    iconCode: '03d',
    forecast: [
      WeatherForecast(
        date: DateTime(2026, 7, 8),
        minTemp: 22,
        maxTemp: 28,
        description: '\u5c0f\u96e8',
        iconCode: '10d',
      ),
    ],
    updatedAt: DateTime(2026, 7, 7, 8),
  );
}

WeatherProvider _provider({
  required WeatherRepository repository,
  CacheManager? cache,
  String apiKey = 'key',
}) {
  return WeatherProvider(
    repository: repository,
    cache: cache ?? MemoryCacheManager(),
    cityReader: () => '\u4e0a\u6d77',
    apiKeyReader: () => apiKey,
  );
}

Future<void> _seedWeatherCache(CacheManager cache, WeatherModel weather) {
  return cache.save(AppConstants.cacheWeather, jsonEncode(weather.toJson()));
}

Widget _weatherCard(WeatherProvider provider) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider.value(
        value: provider,
        child: const WeatherCard(),
      ),
    ),
  );
}

void main() {
  testWidgets('WeatherCard renders no-data copy while idle', (tester) async {
    final provider = _provider(
      repository: _SuccessfulWeatherRepository(_weather()),
    );
    addTearDown(provider.dispose);

    await tester.pumpWidget(_weatherCard(provider));

    expect(find.text('\u6682\u65e0\u5929\u6c14\u6570\u636e'), findsOneWidget);
  });

  testWidgets('WeatherCard renders API-key guidance for an empty key', (
    tester,
  ) async {
    final repository = _SuccessfulWeatherRepository(_weather());
    final provider = _provider(repository: repository, apiKey: '');
    addTearDown(provider.dispose);

    await provider.refresh();
    await tester.pumpWidget(_weatherCard(provider));

    expect(
      find.text(
        '\u8bf7\u5148\u5728\u8bbe\u7f6e\u4e2d\u586b\u5199 OpenWeatherMap API Key',
      ),
      findsOneWidget,
    );
    expect(repository.calls, 0);
  });

  testWidgets(
    'WeatherCard renders loading while a valid-key fetch is pending',
    (tester) async {
      final repository = _PendingWeatherRepository();
      final provider = _provider(repository: repository);
      addTearDown(provider.dispose);

      final refresh = provider.refresh();
      await tester.pumpWidget(_weatherCard(provider));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(repository.calls, 1);

      repository.completer.complete(_weather());
      await refresh;
    },
  );

  testWidgets('WeatherCard renders network error after an uncached failure', (
    tester,
  ) async {
    final repository = _FailingWeatherRepository();
    final provider = _provider(repository: repository);
    addTearDown(provider.dispose);

    await provider.refresh();
    await tester.pumpWidget(_weatherCard(provider));

    expect(
      find.text(
        '\u5929\u6c14\u52a0\u8f7d\u5931\u8d25\uff0c\u8bf7\u68c0\u67e5\u7f51\u7edc',
      ),
      findsOneWidget,
    );
    expect(repository.calls, 1);
  });

  testWidgets(
    'WeatherCard renders offline indicator and cached content after a failure',
    (tester) async {
      final cache = MemoryCacheManager();
      final cachedWeather = _weather();
      final repository = _FailingWeatherRepository();
      await _seedWeatherCache(cache, cachedWeather);
      final provider = _provider(repository: repository, cache: cache);
      addTearDown(provider.dispose);

      await provider.refresh();
      await tester.pumpWidget(_weatherCard(provider));

      expect(find.text('\u79bb\u7ebf'), findsOneWidget);
      expect(find.text('\u4e0a\u6d77 24\u00b0C'), findsOneWidget);
      expect(repository.calls, 1);
    },
  );

  testWidgets('WeatherCard renders current weather and a forecast item', (
    tester,
  ) async {
    final repository = _SuccessfulWeatherRepository(_weather());
    final provider = _provider(repository: repository);
    addTearDown(provider.dispose);

    await provider.refresh();
    await tester.pumpWidget(_weatherCard(provider));

    expect(find.text('\u4e0a\u6d77 24\u00b0C'), findsOneWidget);
    expect(
      find.text(
        '\u591a\u4e91 \u00b7 \u4f53\u611f 25\u00b0C \u00b7 \u6e7f\u5ea6 60%',
      ),
      findsOneWidget,
    );
    expect(find.text('7/8 \u5c0f\u96e8 22\u00b0/28\u00b0'), findsOneWidget);
    expect(repository.calls, 1);
  });
}
