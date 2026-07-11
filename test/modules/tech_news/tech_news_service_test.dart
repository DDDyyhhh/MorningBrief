import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/modules/tech_news/tech_news_service.dart';

class _RecordingTechNewsSource implements TechNewsRepositorySource {
  List<Uri>? receivedFeeds;
  int? receivedLimit;

  @override
  Future<List<NewsArticle>> fetchArticles(
    List<Uri> feeds, {
    int limit = 8,
  }) async {
    receivedFeeds = feeds;
    receivedLimit = limit;
    return [
      NewsArticle(
        title: 'AI 模型发布',
        summary: '摘要',
        source: '机器之心',
        url: Uri.parse('https://example.com/ai'),
        publishedAt: DateTime.utc(2026, 7, 11),
      ),
    ];
  }
}

void main() {
  test('TechNewsService delegates Tech/AI feeds and requested limit', () async {
    final source = _RecordingTechNewsSource();
    final feeds = [Uri.parse('https://example.com/tech.xml')];
    final service = TechNewsService(source, feeds: feeds);

    final articles = await service.fetchArticles(limit: 3);

    expect(articles.single.title, 'AI 模型发布');
    expect(source.receivedFeeds, same(feeds));
    expect(source.receivedLimit, 3);
  });
}
