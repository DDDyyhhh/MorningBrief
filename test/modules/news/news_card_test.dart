import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/constants.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/modules/news/news_card.dart';
import 'package:morningbrief/modules/news/news_provider.dart';
import 'package:provider/provider.dart';

class _FixedNewsRepository implements NewsRepository {
  _FixedNewsRepository(this.articles);

  final List<NewsArticle> articles;
  int calls = 0;

  @override
  Future<List<NewsArticle>> fetchArticles(
    List<Uri> feeds, {
    int limit = 10,
  }) async {
    calls++;
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

class _PendingNewsRepository implements NewsRepository {
  final completer = Completer<List<NewsArticle>>();
  int calls = 0;

  @override
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 10}) {
    calls++;
    return completer.future;
  }
}

class _RetryNewsRepository implements NewsRepository {
  int calls = 0;

  @override
  Future<List<NewsArticle>> fetchArticles(
    List<Uri> feeds, {
    int limit = 10,
  }) async {
    calls++;
    if (calls == 1) throw StateError('first request failed');
    return [_article(1)];
  }
}

NewsArticle _article(int index) {
  return NewsArticle(
    title: '新闻标题$index',
    summary: '新闻摘要$index，包含用于验证卡片展示的内容。',
    source: '新闻来源$index',
    url: Uri.parse('https://example.com/articles/$index'),
    publishedAt: DateTime.utc(2026, 7, 10, index),
  );
}

NewsProvider _provider({
  required NewsRepository repository,
  CacheManager? cache,
}) {
  return NewsProvider(
    repository: repository,
    cache: cache ?? MemoryCacheManager(),
    feedsReader: () => [Uri.parse('https://example.com/news.xml')],
  );
}

Widget _newsCard(NewsProvider provider) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider.value(
        value: provider,
        child: const NewsCard(),
      ),
    ),
  );
}

void main() {
  testWidgets('NewsCard renders title, icon, and empty copy while idle', (
    tester,
  ) async {
    final provider = _provider(repository: _FixedNewsRepository([]));
    addTearDown(provider.dispose);

    await tester.pumpWidget(_newsCard(provider));

    expect(find.text('新闻头条'), findsOneWidget);
    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    expect(find.text('暂无新闻'), findsOneWidget);
  });

  testWidgets('NewsCard renders loading while a fetch is pending', (
    tester,
  ) async {
    final repository = _PendingNewsRepository();
    final provider = _provider(repository: repository);
    addTearDown(provider.dispose);

    final refresh = provider.refresh();
    await tester.pumpWidget(_newsCard(provider));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completer.complete([]);
    await refresh;
  });

  testWidgets('NewsCard renders empty copy for an empty response', (
    tester,
  ) async {
    final provider = _provider(repository: _FixedNewsRepository([]));
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_newsCard(provider));

    expect(find.text('暂无新闻'), findsOneWidget);
  });

  testWidgets('NewsCard renders an error and retries through the provider', (
    tester,
  ) async {
    final repository = _RetryNewsRepository();
    final provider = _provider(repository: repository);
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_newsCard(provider));
    expect(find.text('新闻加载失败，请稍后重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(repository.calls, 2);
    expect(find.text('新闻标题1'), findsOneWidget);
  });

  testWidgets('NewsCard marks stale cached articles as offline', (
    tester,
  ) async {
    final cache = MemoryCacheManager();
    await cache.save(
      AppConstants.cacheNews,
      jsonEncode([_article(1).toJson()]),
    );
    final provider = _provider(
      repository: _ThrowingNewsRepository(),
      cache: cache,
    );
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_newsCard(provider));

    expect(find.text('离线'), findsOneWidget);
    expect(find.text('新闻标题1'), findsOneWidget);
  });

  testWidgets('NewsCard shows at most five bounded article summaries', (
    tester,
  ) async {
    final provider = _provider(
      repository: _FixedNewsRepository([
        for (var index = 1; index <= 6; index++) _article(index),
      ]),
    );
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_newsCard(provider));

    for (var index = 1; index <= 5; index++) {
      expect(find.text('新闻标题$index'), findsOneWidget);
      expect(find.text('新闻来源$index'), findsOneWidget);
      expect(find.text('新闻摘要$index，包含用于验证卡片展示的内容。'), findsOneWidget);
    }
    expect(find.text('新闻标题6'), findsNothing);

    final title = tester.widget<Text>(find.text('新闻标题1'));
    final source = tester.widget<Text>(find.text('新闻来源1'));
    final summary = tester.widget<Text>(find.text('新闻摘要1，包含用于验证卡片展示的内容。'));
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(source.maxLines, 1);
    expect(source.overflow, TextOverflow.ellipsis);
    expect(summary.maxLines, 2);
    expect(summary.overflow, TextOverflow.ellipsis);
  });
}
