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

  bool isEnabled(MorningModuleId id) =>
      _configs.firstWhere((config) => config.id == id).enabled;

  Future<void> load() async {
    _configs = await _storage.getModuleConfigs();
    _city =
        await _storage.getString(AppConstants.cityName) ??
        AppConstants.defaultCity;
    _weatherApiKey = await _storage.getString(AppConstants.weatherApiKey) ?? '';
    _stockApiKey = await _storage.getString(AppConstants.stockApiKey) ?? '';
    _stockSymbols = await _storage.getStringList(
      AppConstants.stockSymbols,
      AppConstants.defaultStockSymbols,
    );
    notifyListeners();
  }

  Future<void> toggle(MorningModuleId id, bool enabled) async {
    _configs = _configs
        .map(
          (config) =>
              config.id == id ? config.copyWith(enabled: enabled) : config,
        )
        .toList();
    await _storage.setModuleConfigs(_configs);
    notifyListeners();
  }

  Future<void> updateCity(String city) async {
    final nextCity = city.trim().isEmpty
        ? AppConstants.defaultCity
        : city.trim();
    if (_city == nextCity) return;
    _city = nextCity;
    await _storage.setString(AppConstants.cityName, _city);
    notifyListeners();
  }

  Future<void> updateWeatherApiKey(String key) async {
    final nextKey = key.trim();
    if (_weatherApiKey == nextKey) return;
    _weatherApiKey = nextKey;
    await _storage.setString(AppConstants.weatherApiKey, _weatherApiKey);
    notifyListeners();
  }

  Future<void> updateStockApiKey(String key) async {
    final nextKey = key.trim();
    if (_stockApiKey == nextKey) return;
    _stockApiKey = nextKey;
    await _storage.setString(AppConstants.stockApiKey, _stockApiKey);
    notifyListeners();
  }

  Future<void> updateStockSymbols(List<String> symbols) async {
    final nextSymbols = symbols
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (listEquals(_stockSymbols, nextSymbols)) return;
    _stockSymbols = nextSymbols;
    await _storage.setStringList(AppConstants.stockSymbols, _stockSymbols);
    notifyListeners();
  }
}
