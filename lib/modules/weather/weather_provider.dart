import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/app_error.dart';
import '../../core/cache_manager.dart';
import '../../core/constants.dart';
import '../../models/weather_model.dart';
import '../../shared/module_state.dart';
import 'weather_service.dart';

abstract class WeatherRepository {
  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  });
}

class WeatherServiceRepository implements WeatherRepository {
  WeatherServiceRepository(this._service);

  final WeatherService _service;

  @override
  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  }) {
    return _service.fetchWeather(city: city, apiKey: apiKey);
  }
}

class WeatherProvider extends ChangeNotifier {
  WeatherProvider({
    required this.repository,
    required this.cache,
    required this.cityReader,
    required this.apiKeyReader,
  });

  final WeatherRepository repository;
  final CacheManager cache;
  final String Function() cityReader;
  final String Function() apiKeyReader;
  ModuleState<WeatherModel> _state = ModuleState.idle();

  ModuleState<WeatherModel> get state => _state;

  Future<void> loadFromCacheOrRefresh() async {
    final cachedWeather = await _readFreshCachedWeather();
    if (cachedWeather != null) {
      _state = ModuleState.data(cachedWeather);
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    final apiKey = apiKeyReader();
    if (apiKey.isEmpty) {
      _state = ModuleState.error(
        const AppError(
          type: AppErrorType.apiKeyMissing,
          message: '请先在设置中填写 OpenWeatherMap API Key',
        ),
      );
      notifyListeners();
      return;
    }
    _state = ModuleState.loading();
    notifyListeners();
    late final WeatherModel weather;
    try {
      weather = await repository.fetchWeather(
        city: cityReader(),
        apiKey: apiKey,
      );
    } catch (_) {
      final cachedWeather = await _readAnyCachedWeather();
      if (cachedWeather != null) {
        _state = ModuleState.offline(cachedWeather);
      } else {
        _state = ModuleState.error(
          const AppError(type: AppErrorType.network, message: '天气加载失败，请检查网络'),
        );
      }
      notifyListeners();
      return;
    }
    try {
      await cache.save(AppConstants.cacheWeather, jsonEncode(weather.toJson()));
    } catch (_) {
      // Cache persistence is best effort after a successful fetch.
    }
    _state = ModuleState.data(weather);
    notifyListeners();
  }

  Future<WeatherModel?> _readFreshCachedWeather() {
    return _readCachedWeather(
      () => cache.readFresh(
        AppConstants.cacheWeather,
        const Duration(minutes: 30),
      ),
    );
  }

  Future<WeatherModel?> _readAnyCachedWeather() {
    return _readCachedWeather(() => cache.readAny(AppConstants.cacheWeather));
  }

  Future<WeatherModel?> _readCachedWeather(
    Future<CachedValue?> Function() readCache,
  ) async {
    try {
      final cached = await readCache();
      if (cached == null) {
        return null;
      }
      return WeatherModel.fromJson(
        jsonDecode(cached.jsonValue) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
