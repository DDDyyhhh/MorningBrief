import 'package:sqflite/sqflite.dart';

class CachedValue {
  CachedValue({
    required this.key,
    required this.jsonValue,
    required this.savedAt,
    required this.isFresh,
  });

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
    _values[key] = CachedValue(
      key: key,
      jsonValue: jsonValue,
      savedAt: _now(),
      isFresh: true,
    );
  }

  @override
  Future<CachedValue?> readFresh(String key, Duration ttl) async {
    final value = _values[key];
    if (value == null) return null;
    final fresh = _now().difference(value.savedAt) <= ttl;
    if (!fresh) return null;
    return CachedValue(
      key: value.key,
      jsonValue: value.jsonValue,
      savedAt: value.savedAt,
      isFresh: true,
    );
  }

  @override
  Future<CachedValue?> readAny(String key) async {
    final value = _values[key];
    if (value == null) return null;
    final fresh =
        _now().difference(value.savedAt) <= const Duration(minutes: 1);
    return CachedValue(
      key: value.key,
      jsonValue: value.jsonValue,
      savedAt: value.savedAt,
      isFresh: fresh,
    );
  }
}

class SqliteCacheManager implements CacheManager {
  SqliteCacheManager(this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Database _database;
  final DateTime Function() _now;

  @override
  Future<void> save(String key, String jsonValue) async {
    await _database.insert('module_cache', {
      'cache_key': key,
      'json_value': jsonValue,
      'saved_at': _now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<CachedValue?> readFresh(String key, Duration ttl) async {
    final value = await readAny(key);
    if (value == null) return null;
    final fresh = _now().difference(value.savedAt) <= ttl;
    if (!fresh) return null;
    return CachedValue(
      key: value.key,
      jsonValue: value.jsonValue,
      savedAt: value.savedAt,
      isFresh: true,
    );
  }

  @override
  Future<CachedValue?> readAny(String key) async {
    final rows = await _database.query(
      'module_cache',
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    final savedAt = DateTime.parse(row['saved_at'] as String);
    return CachedValue(
      key: key,
      jsonValue: row['json_value'] as String,
      savedAt: savedAt,
      isFresh: false,
    );
  }
}
