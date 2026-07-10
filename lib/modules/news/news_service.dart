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
    final articles = <NewsArticle>[];
    for (final feed in feeds) {
      final xmlText = await _client.getText(feed);
      final document = XmlDocument.parse(xmlText);
      final channel = document.findAllElements('channel').first;
      final source = _elementText(channel, 'title');
      for (final item in channel.findElements('item')) {
        articles.add(
          NewsArticle(
            title: _elementText(item, 'title'),
            summary: _elementText(item, 'description'),
            source: source,
            url: Uri.parse(_elementText(item, 'link')),
            publishedAt: _parsePublishedAt(_elementText(item, 'pubDate')),
          ),
        );
      }
    }
    articles.sort(
      (left, right) => right.publishedAt.compareTo(left.publishedAt),
    );
    return articles.take(limit).toList();
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
