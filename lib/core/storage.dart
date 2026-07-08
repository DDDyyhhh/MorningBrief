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
    return list
        .map((item) => ModuleConfig.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<void> setModuleConfigs(List<ModuleConfig> configs) async {
    final raw = jsonEncode(configs.map((item) => item.toJson()).toList());
    await _prefs.setString(AppConstants.moduleConfigs, raw);
  }
}
