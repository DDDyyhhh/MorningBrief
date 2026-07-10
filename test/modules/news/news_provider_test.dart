import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/app_error.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/constants.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/modules/news/news_provider.dart';
import 'package:morningbrief/shared/module_state.dart';

class _FixedNewsRepository implements NewsRepository {
  _FixedNewsRepository(this.articles);

  final List<NewsArticle> articles;
  int calls = 0;
  List<Uri>? receivedFeeds;
  int? receivedLimit;

  @override
  Future<List<NewsArticle>> fetchArticles(
    List<Uri> feeds, {
    int limit = 10,
  }) async {
    calls++;
    receivedFeeds = feeds;
    receivedLimit = limit;
    return articles;
  }
}

class _ThrowingNewsRepository implements NewsRepository {
  int calls = 0;

  @override
  Future<List<NewsArticle>> fetchArticles(
    List<Uri> feeds, {
    int limit = 10,
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
  String? readFreshKey;
  Duration? readFreshTtl;
  String? savedKey;
  String? savedJson;

  @override
  Future<void> save(String key, String jsonValue) async {
    saveCalls++;
    savedKey = key;
    savedJson = jsonValue;
    if (saveError != null) throw saveError!;
  }

  @override
  Future<CachedValue?> readFresh(String key, Duration ttl) async {
    freshReads++;
    readFreshKey = key;
    readFreshTtl = ttl;
    if (freshError != null) throw freshError!;
    return freshValue;
  }

  @override
  Future<CachedValue?> readAny(String key) async {
    anyReads++;
    if (anyError != null) throw anyError!;
    return anyValue;
  }
}

NewsArticle _article({String title = '新闻一'}) {
  return NewsArticle(
    title: title,
    summary: '$title摘要',
    source: '示例来源',
    url: Uri.parse('https://example.com/$title'),
    publishedAt: DateTime.utc(2026, 7, 10, 1),
  );
}

CachedValue _cachedArticles(String jsonValue) {
  return CachedValue(
    key: AppConstants.cacheNews,
    jsonValue: jsonValue,
    savedAt: DateTime.utc(2026, 7, 10),
    isFresh: true,
  );
}

String _articlesJson(List<NewsArticle> articles) {
  return jsonEncode(articles.map((article) => article.toJson()).toList());
}

NewsProvider _provider({
  required NewsRepository repository,
  required CacheManager cache,
  List<Uri> Function()? feedsReader,
}) {
  return NewsProvider(
    repository: repository,
    cache: cache,
    feedsReader:
        feedsReader ?? () => [Uri.parse('https://example.com/news.xml')],
  );
}

void main() {
  test('NewsProvider starts idle', () {
    final provider = _provider(
      repository: _FixedNewsRepository([]),
      cache: MemoryCacheManager(),
    );
    addTearDown(provider.dispose);

    expect(provider.state.status, ModuleStatus.idle);
  });

  test('NewsProvider fetches up to ten articles and caches them', () async {
    final article = _article();
    final repository = _FixedNewsRepository([article]);
    final cache = _ControllableCacheManager();
    final feeds = [Uri.parse('https://example.com/news.xml')];
    final provider = _provider(
      repository: repository,
      cache: cache,
      feedsReader: () => feeds,
    );
    addTearDown(provider.dispose);

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.single.title, article.title);
    expect(repository.receivedFeeds, same(feeds));
    expect(repository.receivedLimit, 10);
    expect(cache.savedKey, AppConstants.cacheNews);
    expect(
      NewsArticle.fromJson(
        (jsonDecode(cache.savedJson!) as List<dynamic>).single
            as Map<String, dynamic>,
      ).title,
      article.title,
    );
  });

  test(
    'NewsProvider returns empty state without caching empty results',
    () async {
      final repository = _FixedNewsRepository([]);
      final cache = _ControllableCacheManager();
      final provider = _provider(repository: repository, cache: cache);
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.empty);
      expect(cache.saveCalls, 0);
    },
  );

  test('NewsProvider uses one-hour fresh cache without fetching', () async {
    final cachedArticle = _article(title: '缓存新闻');
    final repository = _ThrowingNewsRepository();
    final cache = _ControllableCacheManager(
      freshValue: _cachedArticles(_articlesJson([cachedArticle])),
    );
    final provider = _provider(repository: repository, cache: cache);
    addTearDown(provider.dispose);

    await provider.loadFromCacheOrRefresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.single.title, cachedArticle.title);
    expect(repository.calls, 0);
    expect(cache.readFreshKey, AppConstants.cacheNews);
    expect(cache.readFreshTtl, const Duration(hours: 1));
  });

  test(
    'NewsProvider exposes stale cached articles offline on failure',
    () async {
      final cachedArticle = _article(title: '离线新闻');
      final repository = _ThrowingNewsRepository();
      final cache = _ControllableCacheManager(
        anyValue: _cachedArticles(_articlesJson([cachedArticle])),
      );
      final provider = _provider(repository: repository, cache: cache);
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.offline);
      expect(provider.state.data!.single.title, cachedArticle.title);
      expect(repository.calls, 1);
    },
  );

  test('NewsProvider reports network error without usable cache', () async {
    final repository = _ThrowingNewsRepository();
    final provider = _provider(
      repository: repository,
      cache: MemoryCacheManager(),
    );
    addTearDown(provider.dispose);

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.error);
    expect(provider.state.error!.type, AppErrorType.network);
    expect(provider.state.error!.message, '新闻加载失败，请稍后重试');
  });

  test(
    'NewsProvider treats malformed or unreadable fresh cache as a miss',
    () async {
      for (final cache in [
        _ControllableCacheManager(
          freshValue: _cachedArticles('not valid JSON'),
        ),
        _ControllableCacheManager(freshError: StateError('cache unavailable')),
      ]) {
        final repository = _FixedNewsRepository([_article()]);
        final provider = _provider(repository: repository, cache: cache);

        await provider.loadFromCacheOrRefresh();

        expect(provider.state.status, ModuleStatus.data);
        expect(repository.calls, 1);
        provider.dispose();
      }
    },
  );

  test('NewsProvider keeps fetched data when cache save fails', () async {
    final repository = _FixedNewsRepository([_article()]);
    final cache = _ControllableCacheManager(
      saveError: StateError('cache unavailable'),
    );
    final provider = _provider(repository: repository, cache: cache);
    addTearDown(provider.dispose);

    await provider.refresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data, hasLength(1));
    expect(cache.saveCalls, 1);
  });

  test(
    'NewsProvider reports network error for malformed or unreadable stale cache',
    () async {
      for (final cache in [
        _ControllableCacheManager(anyValue: _cachedArticles('not valid JSON')),
        _ControllableCacheManager(anyError: StateError('cache unavailable')),
      ]) {
        final provider = _provider(
          repository: _ThrowingNewsRepository(),
          cache: cache,
        );

        await provider.refresh();

        expect(provider.state.status, ModuleStatus.error);
        expect(provider.state.error!.message, '新闻加载失败，请稍后重试');
        provider.dispose();
      }
    },
  );

  test('NewsProvider isolates feed-reader failures', () async {
    final provider = _provider(
      repository: _FixedNewsRepository([_article()]),
      cache: MemoryCacheManager(),
      feedsReader: () => throw StateError('settings unavailable'),
    );
    addTearDown(provider.dispose);

    await expectLater(provider.refresh(), completes);

    expect(provider.state.status, ModuleStatus.error);
    expect(provider.state.error!.message, '新闻加载失败，请稍后重试');
  });
}
