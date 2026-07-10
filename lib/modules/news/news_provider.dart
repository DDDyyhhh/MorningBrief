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
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 10}) {
    return _service.fetchArticles(feeds, limit: limit);
  }
}

class NewsProvider extends ChangeNotifier {
  NewsProvider({
    required this.repository,
    required this.cache,
    required this.feedsReader,
  });

  final NewsRepository repository;
  final CacheManager cache;
  final List<Uri> Function() feedsReader;
  ModuleState<List<NewsArticle>> _state = ModuleState.idle();

  ModuleState<List<NewsArticle>> get state => _state;

  Future<void> loadFromCacheOrRefresh() async {
    final cachedArticles = await _readFreshCachedArticles();
    if (cachedArticles != null) {
      _state = ModuleState.data(cachedArticles);
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    _state = ModuleState.loading();
    notifyListeners();

    late final List<NewsArticle> articles;
    try {
      articles = await repository.fetchArticles(feedsReader(), limit: 10);
    } catch (_) {
      final cachedArticles = await _readAnyCachedArticles();
      if (cachedArticles != null) {
        _state = ModuleState.offline(cachedArticles);
      } else {
        _state = ModuleState.error(
          const AppError(type: AppErrorType.network, message: '新闻加载失败，请稍后重试'),
        );
      }
      notifyListeners();
      return;
    }

    if (articles.isEmpty) {
      _state = ModuleState.empty();
      notifyListeners();
      return;
    }

    try {
      await cache.save(
        AppConstants.cacheNews,
        jsonEncode(articles.map((article) => article.toJson()).toList()),
      );
    } catch (_) {
      // Cache persistence is best effort after a successful fetch.
    }
    _state = ModuleState.data(articles);
    notifyListeners();
  }

  Future<List<NewsArticle>?> _readFreshCachedArticles() {
    return _readCachedArticles(
      () => cache.readFresh(AppConstants.cacheNews, const Duration(hours: 1)),
    );
  }

  Future<List<NewsArticle>?> _readAnyCachedArticles() {
    return _readCachedArticles(() => cache.readAny(AppConstants.cacheNews));
  }

  Future<List<NewsArticle>?> _readCachedArticles(
    Future<CachedValue?> Function() readCache,
  ) async {
    try {
      final cached = await readCache();
      if (cached == null) return null;
      return (jsonDecode(cached.jsonValue) as List<dynamic>)
          .map((value) => NewsArticle.fromJson(value as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
