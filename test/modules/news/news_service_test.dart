import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morningbrief/core/api_client.dart';
import 'package:morningbrief/modules/news/news_service.dart';

http.Response _rssResponse(String body) => http.Response.bytes(
  utf8.encode(body),
  200,
  headers: {'content-type': 'application/rss+xml; charset=utf-8'},
);

void main() {
  test(
    'NewsService merges RSS feeds and sorts articles newest first',
    () async {
      final firstFeed = Uri.parse('https://example.com/first.xml');
      final secondFeed = Uri.parse('https://example.com/second.xml');
      final requested = <Uri>[];
      final client = ApiClient(
        MockClient((request) async {
          requested.add(request.url);
          if (request.url == firstFeed) {
            return _rssResponse('''
            <rss version="2.0">
              <channel>
                <title>第一新闻</title>
                <item>
                  <title>较早报道</title>
                  <description>较早摘要</description>
                  <link>https://example.com/older</link>
                  <pubDate>Wed, 08 Jul 2026 06:00:00 GMT</pubDate>
                </item>
              </channel>
            </rss>
          ''');
          }
          return _rssResponse('''
          <rss version="2.0">
            <channel>
              <title>第二新闻</title>
              <item>
                <title>最新报道</title>
                <description>最新摘要</description>
                <link>https://example.com/newest</link>
                <pubDate>Thu, 09 Jul 2026 08:30:00 GMT</pubDate>
              </item>
            </channel>
          </rss>
        ''');
        }),
      );

      final articles = await NewsService(
        client,
      ).fetchArticles([firstFeed, secondFeed]);

      expect(requested, [firstFeed, secondFeed]);
      expect(articles, hasLength(2));
      expect(articles.first.title, '最新报道');
      expect(articles.first.summary, '最新摘要');
      expect(articles.first.source, '第二新闻');
      expect(articles.first.url, Uri.parse('https://example.com/newest'));
      expect(articles.first.publishedAt, DateTime.utc(2026, 7, 9, 8, 30));
      expect(articles.last.title, '较早报道');
    },
  );

  test(
    'NewsService uses epoch for optional invalid dates and applies the limit',
    () async {
      final feed = Uri.parse('https://example.com/news.xml');
      final client = ApiClient(
        MockClient(
          (_) async => _rssResponse('''
            <rss version="2.0">
              <channel>
                <title>示例新闻</title>
                <item>
                  <title>有日期</title>
                  <description>摘要一</description>
                  <link>https://example.com/dated</link>
                  <pubDate>Fri, 10 Jul 2026 01:00:00 GMT</pubDate>
                </item>
                <item>
                  <title>日期无效</title>
                  <description>摘要二</description>
                  <link>https://example.com/invalid</link>
                  <pubDate>not-a-date</pubDate>
                </item>
                <item>
                  <title>日期缺失</title>
                  <description>摘要三</description>
                  <link>https://example.com/missing</link>
                </item>
              </channel>
            </rss>
          '''),
        ),
      );

      final allArticles = await NewsService(client).fetchArticles([feed]);
      final limitedArticles = await NewsService(
        client,
      ).fetchArticles([feed], limit: 2);

      expect(allArticles, hasLength(3));
      expect(allArticles.first.title, '有日期');
      expect(
        allArticles[1].publishedAt,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(
        allArticles[2].publishedAt,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(limitedArticles.map((article) => article.title), ['有日期', '日期无效']);
    },
  );
}
