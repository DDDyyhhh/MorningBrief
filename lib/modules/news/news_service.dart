import 'dart:io';

import 'package:xml/xml.dart';

import '../../core/api_client.dart';
import '../../models/news_article.dart';

class NewsService {
  NewsService(this._client);

  final ApiClient _client;

  Future<List<NewsArticle>> fetchArticles(
    List<Uri> feeds, {
    int limit = 10,
  }) async {
    final feedResults = await Future.wait(feeds.map(_fetchFeed));
    final successfulFeeds = feedResults.whereType<List<NewsArticle>>().toList();
    if (feeds.isNotEmpty && successfulFeeds.isEmpty) {
      throw NewsFeedException('所有新闻源均加载失败');
    }
    final articles = successfulFeeds.expand((items) => items).toList();
    articles.sort(
      (left, right) => right.publishedAt.compareTo(left.publishedAt),
    );
    return articles.take(limit).toList();
  }

  Future<List<NewsArticle>?> _fetchFeed(Uri feed) async {
    try {
      final xmlText = await _client.getText(feed);
      final document = XmlDocument.parse(xmlText);
      final channels = document.findAllElements('channel');
      if (channels.isEmpty) throw const FormatException('RSS channel missing');
      final channel = channels.first;
      final source = _elementText(channel, 'title');
      final articles = <NewsArticle>[];
      for (final item in channel.findElements('item')) {
        final article = _parseItem(item, source);
        if (article != null) articles.add(article);
      }
      return articles;
    } catch (_) {
      return null;
    }
  }

  NewsArticle? _parseItem(XmlElement item, String source) {
    try {
      final url = Uri.parse(_elementText(item, 'link'));
      if (!url.hasScheme || url.host.isEmpty) return null;
      return NewsArticle(
        title: _elementText(item, 'title'),
        summary: _elementText(item, 'description'),
        source: source,
        url: url,
        publishedAt: _parsePublishedAt(_elementText(item, 'pubDate')),
      );
    } on FormatException {
      return null;
    }
  }

  String _elementText(XmlElement parent, String name) {
    final elements = parent.findElements(name);
    return elements.isEmpty ? '' : elements.first.innerText.trim();
  }

  DateTime _parsePublishedAt(String value) {
    if (value.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    try {
      return HttpDate.parse(value);
    } on FormatException {
      return DateTime.fromMillisecondsSinceEpoch(0);
    } on HttpException {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

class NewsFeedException implements Exception {
  NewsFeedException(this.message);

  final String message;

  @override
  String toString() => 'NewsFeedException: $message';
}
