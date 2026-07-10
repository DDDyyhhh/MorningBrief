import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/app_error.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/constants.dart';
import 'package:morningbrief/models/weather_model.dart';
import 'package:morningbrief/modules/weather/weather_provider.dart';
import 'package:morningbrief/shared/module_state.dart';

class FakeWeatherRepository implements WeatherRepository {
  int calls = 0;
  @override
  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  }) async {
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

class _FixedWeatherRepository implements WeatherRepository {
  _FixedWeatherRepository(this.weather);

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

class _ThrowingWeatherRepository implements WeatherRepository {
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

class _ControllableCacheManager implements CacheManager {
  _ControllableCacheManager({
    this.freshValue,
    this.anyValue,
    this.freshError,
    this.anyError,
    this.saveError,
  });

  CachedValue? freshValue;
  CachedValue? anyValue;
  Object? freshError;
  Object? anyError;
  Object? saveError;
  int freshReads = 0;
  int anyReads = 0;
  int saveCalls = 0;

  @override
  Future<void> save(String key, String jsonValue) async {
    saveCalls++;
    if (saveError != null) {
      throw saveError!;
    }
  }

  @override
  Future<CachedValue?> readFresh(String key, Duration ttl) async {
    freshReads++;
    if (freshError != null) {
      throw freshError!;
    }
    return freshValue;
  }

  @override
  Future<CachedValue?> readAny(String key) async {
    anyReads++;
    if (anyError != null) {
      throw anyError!;
    }
    return anyValue;
  }
}

WeatherModel _weather({String city = '\u4e0a\u6d77'}) {
  return WeatherModel(
    city: city,
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

Future<void> _seedWeatherCache(CacheManager cache, WeatherModel weather) {
  return cache.save(AppConstants.cacheWeather, jsonEncode(weather.toJson()));
}

CachedValue _cachedWeather(String jsonValue) {
  return CachedValue(
    key: AppConstants.cacheWeather,
    jsonValue: jsonValue,
    savedAt: DateTime(2026, 7, 7, 8),
    isFresh: true,
  );
}

void main() {
  test('WeatherProvider caches a successful fetch', () async {
    final cache = MemoryCacheManager();
    final weather = _weather();
    final repository = _FixedWeatherRepository(weather);
    final provider = WeatherProvider(
      repository: repository,
      cache: cache,
      cityReader: () => '\u4e0a\u6d77',
      apiKeyReader: () => 'key',
    );
    addTearDown(provider.dispose);

    await provider.refresh();

    final cached = await cache.readAny(AppConstants.cacheWeather);
    expect(provider.state.status, ModuleStatus.data);
    expect(repository.calls, 1);
    expect(cached, isNotNull);
    expect(
      WeatherModel.fromJson(
        jsonDecode(cached!.jsonValue) as Map<String, dynamic>,
      ).city,
      weather.city,
    );
  });

  test('WeatherProvider uses fresh cache without fetching', () async {
    final cache = MemoryCacheManager(now: () => DateTime(2026, 7, 7, 8));
    final cachedWeather = _weather();
    final repository = _ThrowingWeatherRepository();
    await _seedWeatherCache(cache, cachedWeather);
    final provider = WeatherProvider(
      repository: repository,
      cache: cache,
      cityReader: () => '\u4e0a\u6d77',
      apiKeyReader: () => 'key',
    );
    addTearDown(provider.dispose);

    await provider.loadFromCacheOrRefresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.city, cachedWeather.city);
    expect(repository.calls, 0);
  });

  test(
    'WeatherProvider exposes cached data offline after fetch failure',
    () async {
      final cache = MemoryCacheManager();
      final cachedWeather = _weather();
      final repository = _ThrowingWeatherRepository();
      await _seedWeatherCache(cache, cachedWeather);
      final provider = WeatherProvider(
        repository: repository,
        cache: cache,
        cityReader: () => '\u4e0a\u6d77',
        apiKeyReader: () => 'key',
      );
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.offline);
      expect(provider.state.data!.city, cachedWeather.city);
      expect(repository.calls, 1);
    },
  );
  test('WeatherProvider requires API key', () async {
    final provider = WeatherProvider(
      repository: FakeWeatherRepository(),
      cache: MemoryCacheManager(),
      cityReader: () => '上海',
      apiKeyReader: () => '',
    );
    addTearDown(provider.dispose);

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.error);
    expect(provider.state.error!.message, '请先在设置中填写 OpenWeatherMap API Key');
  });

  test('WeatherProvider fetches and caches weather', () async {
    final repository = FakeWeatherRepository();
    final provider = WeatherProvider(
      repository: repository,
      cache: MemoryCacheManager(now: () => DateTime(2026, 7, 7, 8)),
      cityReader: () => '上海',
      apiKeyReader: () => 'key',
    );
    addTearDown(provider.dispose);

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.city, '上海');
    expect(repository.calls, 1);
  });

  test(
    'WeatherProvider treats malformed fresh cache as a cache miss',
    () async {
      final weather = _weather();
      final repository = _FixedWeatherRepository(weather);
      final cache = _ControllableCacheManager(
        freshValue: _cachedWeather('not valid JSON'),
      );
      final provider = WeatherProvider(
        repository: repository,
        cache: cache,
        cityReader: () => 'Shanghai',
        apiKeyReader: () => 'key',
      );
      addTearDown(provider.dispose);

      await provider.loadFromCacheOrRefresh();

      expect(provider.state.status, ModuleStatus.data);
      expect(provider.state.data!.city, weather.city);
      expect(repository.calls, 1);
    },
  );

  test(
    'WeatherProvider treats a failing fresh-cache read as a cache miss',
    () async {
      final weather = _weather();
      final repository = _FixedWeatherRepository(weather);
      final cache = _ControllableCacheManager(
        freshError: StateError('cache unavailable'),
      );
      final provider = WeatherProvider(
        repository: repository,
        cache: cache,
        cityReader: () => 'Shanghai',
        apiKeyReader: () => 'key',
      );
      addTearDown(provider.dispose);

      await provider.loadFromCacheOrRefresh();

      expect(provider.state.status, ModuleStatus.data);
      expect(provider.state.data!.city, weather.city);
      expect(repository.calls, 1);
    },
  );

  test('WeatherProvider keeps fetched data when cache save fails', () async {
    final weather = _weather();
    final repository = _FixedWeatherRepository(weather);
    final cache = _ControllableCacheManager(
      saveError: StateError('cache unavailable'),
    );
    final provider = WeatherProvider(
      repository: repository,
      cache: cache,
      cityReader: () => 'Shanghai',
      apiKeyReader: () => 'key',
    );
    addTearDown(provider.dispose);

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.city, weather.city);
    expect(repository.calls, 1);
    expect(cache.saveCalls, 1);
  });

  test(
    'WeatherProvider reports network error for malformed stale cache',
    () async {
      final repository = _ThrowingWeatherRepository();
      final cache = _ControllableCacheManager(
        anyValue: _cachedWeather('not valid JSON'),
      );
      final provider = WeatherProvider(
        repository: repository,
        cache: cache,
        cityReader: () => 'Shanghai',
        apiKeyReader: () => 'key',
      );
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.error);
      expect(provider.state.error!.type, AppErrorType.network);
      expect(repository.calls, 1);
    },
  );

  test(
    'WeatherProvider reports network error for a failing stale-cache read',
    () async {
      final repository = _ThrowingWeatherRepository();
      final cache = _ControllableCacheManager(
        anyError: StateError('cache unavailable'),
      );
      final provider = WeatherProvider(
        repository: repository,
        cache: cache,
        cityReader: () => 'Shanghai',
        apiKeyReader: () => 'key',
      );
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.error);
      expect(provider.state.error!.type, AppErrorType.network);
      expect(repository.calls, 1);
    },
  );
}
