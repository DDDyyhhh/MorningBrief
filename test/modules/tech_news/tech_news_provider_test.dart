import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/app_error.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/constants.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/modules/tech_news/tech_news_provider.dart';
import 'package:morningbrief/shared/module_state.dart';

class _FixedTechNewsRepository implements TechNewsRepository {
  _FixedTechNewsRepository(this.articles);

  final List<NewsArticle> articles;
  int calls = 0;
  int? receivedLimit;

  @override
  Future<List<NewsArticle>> fetchArticles({int limit = 8}) async {
    calls++;
    receivedLimit = limit;
    return articles;
  }
}

class _ThrowingTechNewsRepository implements TechNewsRepository {
  int calls = 0;

  @override
  Future<List<NewsArticle>> fetchArticles({int limit = 8}) async {
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
  String? freshKey;
  Duration? freshTtl;
  String? anyKey;
  String? savedKey;
  String? savedJson;

  @override
  Future<CachedValue?> readFresh(String key, Duration ttl) async {
    freshReads++;
    freshKey = key;
    freshTtl = ttl;
    if (freshError != null) throw freshError!;
    return freshValue;
  }

  @override
  Future<CachedValue?> readAny(String key) async {
    anyReads++;
    anyKey = key;
    if (anyError != null) throw anyError!;
    return anyValue;
  }

  @override
  Future<void> save(String key, String jsonValue) async {
    saveCalls++;
    savedKey = key;
    savedJson = jsonValue;
    if (saveError != null) throw saveError!;
  }
}

NewsArticle _article({String title = 'AI 新闻'}) {
  return NewsArticle(
    title: title,
    summary: '摘要',
    source: '量子位',
    url: Uri.parse('https://example.com/$title'),
    publishedAt: DateTime.utc(2026, 7, 11),
  );
}

CachedValue _cache(String jsonValue, {bool isFresh = true}) {
  return CachedValue(
    key: AppConstants.cacheTechNews,
    jsonValue: jsonValue,
    savedAt: DateTime.utc(2026, 7, 11),
    isFresh: isFresh,
  );
}

void main() {
  test(
    'TechNewsProvider loads and caches Tech/AI articles separately',
    () async {
      final repository = _FixedTechNewsRepository([_article()]);
      final cache = _ControllableCacheManager();
      final provider = TechNewsProvider(repository: repository, cache: cache);
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.data);
      expect(provider.state.data?.single.source, '量子位');
      expect(repository.receivedLimit, 8);
      expect(cache.savedKey, AppConstants.cacheTechNews);
      expect(jsonDecode(cache.savedJson!), isA<List<dynamic>>());
    },
  );

  test('TechNewsProvider exposes an empty result without caching', () async {
    final repository = _FixedTechNewsRepository([]);
    final cache = _ControllableCacheManager();
    final provider = TechNewsProvider(repository: repository, cache: cache);
    addTearDown(provider.dispose);

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.empty);
    expect(cache.saveCalls, 0);
  });

  test(
    'TechNewsProvider uses a one-hour fresh cache without fetching',
    () async {
      final cachedArticle = _article();
      final repository = _ThrowingTechNewsRepository();
      final cache = _ControllableCacheManager(
        freshValue: _cache(jsonEncode([cachedArticle.toJson()])),
      );
      final provider = TechNewsProvider(repository: repository, cache: cache);
      addTearDown(provider.dispose);

      await provider.loadFromCacheOrRefresh();

      expect(provider.state.status, ModuleStatus.data);
      expect(provider.state.data?.single.title, cachedArticle.title);
      expect(repository.calls, 0);
      expect(cache.freshKey, AppConstants.cacheTechNews);
      expect(cache.freshTtl, const Duration(hours: 1));
    },
  );

  test('TechNewsProvider fetches when its fresh cache is corrupt', () async {
    final repository = _FixedTechNewsRepository([_article()]);
    final cache = _ControllableCacheManager(freshValue: _cache('not JSON'));
    final provider = TechNewsProvider(repository: repository, cache: cache);
    addTearDown(provider.dispose);

    await provider.loadFromCacheOrRefresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(repository.calls, 1);
  });

  test(
    'TechNewsProvider fetches when its fresh cache cannot be read',
    () async {
      final repository = _FixedTechNewsRepository([_article()]);
      final cache = _ControllableCacheManager(
        freshError: StateError('cache unavailable'),
      );
      final provider = TechNewsProvider(repository: repository, cache: cache);
      addTearDown(provider.dispose);

      await provider.loadFromCacheOrRefresh();

      expect(provider.state.status, ModuleStatus.data);
      expect(repository.calls, 1);
    },
  );

  test('TechNewsProvider uses stale cache when fetching fails', () async {
    final cachedArticle = _article();
    final repository = _ThrowingTechNewsRepository();
    final cache = _ControllableCacheManager(
      anyValue: _cache(jsonEncode([cachedArticle.toJson()]), isFresh: false),
    );
    final provider = TechNewsProvider(repository: repository, cache: cache);
    addTearDown(provider.dispose);

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.offline);
    expect(provider.state.data?.single.title, cachedArticle.title);
    expect(cache.anyKey, AppConstants.cacheTechNews);
  });

  test(
    'TechNewsProvider reports a network error with no usable cache',
    () async {
      final provider = TechNewsProvider(
        repository: _ThrowingTechNewsRepository(),
        cache: _ControllableCacheManager(),
      );
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.error);
      expect(provider.state.error?.type, AppErrorType.network);
      expect(provider.state.error?.message, '科技新闻加载失败，请稍后重试');
    },
  );

  test(
    'TechNewsProvider reports a network error when stale cache cannot be read',
    () async {
      final provider = TechNewsProvider(
        repository: _ThrowingTechNewsRepository(),
        cache: _ControllableCacheManager(
          anyError: StateError('cache unavailable'),
        ),
      );
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.error);
      expect(provider.state.error?.type, AppErrorType.network);
    },
  );

  test(
    'TechNewsProvider keeps articles when cache persistence fails',
    () async {
      final articles = [_article()];
      final cache = _ControllableCacheManager(
        saveError: StateError('disk full'),
      );
      final provider = TechNewsProvider(
        repository: _FixedTechNewsRepository(articles),
        cache: cache,
      );
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.data);
      expect(provider.state.data, same(articles));
    },
  );
}
