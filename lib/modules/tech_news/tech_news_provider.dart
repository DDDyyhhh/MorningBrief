import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import '../../core/cache_manager.dart';
import '../../core/constants.dart';
import '../../models/news_article.dart';
import '../../shared/module_state.dart';
import 'tech_news_service.dart';

abstract class TechNewsRepository {
  Future<List<NewsArticle>> fetchArticles({int limit = 8});
}

class TechNewsServiceRepository implements TechNewsRepository {
  TechNewsServiceRepository(this._service);

  final TechNewsService _service;

  @override
  Future<List<NewsArticle>> fetchArticles({int limit = 8}) {
    return _service.fetchArticles(limit: limit);
  }
}

class TechNewsProvider extends ChangeNotifier {
  TechNewsProvider({required this.repository, required this.cache});

  final TechNewsRepository repository;
  final CacheManager cache;
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
      articles = await repository.fetchArticles();
    } catch (_) {
      final cachedArticles = await _readAnyCachedArticles();
      if (cachedArticles != null) {
        _state = ModuleState.offline(cachedArticles);
      } else {
        _state = ModuleState.error(
          const AppError(type: AppErrorType.network, message: '科技新闻加载失败，请稍后重试'),
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
        AppConstants.cacheTechNews,
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
      () =>
          cache.readFresh(AppConstants.cacheTechNews, const Duration(hours: 1)),
    );
  }

  Future<List<NewsArticle>?> _readAnyCachedArticles() {
    return _readCachedArticles(() => cache.readAny(AppConstants.cacheTechNews));
  }

  Future<List<NewsArticle>?> _readCachedArticles(
    Future<CachedValue?> Function() readCache,
  ) async {
    try {
      final cached = await readCache();
      if (cached == null) return null;
      final articles = (jsonDecode(cached.jsonValue) as List<dynamic>)
          .map((value) => NewsArticle.fromJson(value as Map<String, dynamic>))
          .toList();
      return articles.isEmpty ? null : articles;
    } catch (_) {
      return null;
    }
  }
}
