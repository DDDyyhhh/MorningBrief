import '../../core/constants.dart';
import '../../models/news_article.dart';
import '../news/news_service.dart';

abstract class TechNewsRepositorySource {
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 8});
}

class NewsServiceTechNewsSource implements TechNewsRepositorySource {
  NewsServiceTechNewsSource(this._service);

  final NewsService _service;

  @override
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 8}) {
    return _service.fetchArticles(feeds, limit: limit);
  }
}

class TechNewsService {
  TechNewsService(this._source, {List<Uri>? feeds})
    : _feeds = feeds ?? AppConstants.techNewsFeeds;

  final TechNewsRepositorySource _source;
  final List<Uri> _feeds;

  Future<List<NewsArticle>> fetchArticles({int limit = 8}) {
    return _source.fetchArticles(_feeds, limit: limit);
  }
}
