import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/constants.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/modules/tech_news/tech_news_card.dart';
import 'package:morningbrief/modules/tech_news/tech_news_provider.dart';
import 'package:provider/provider.dart';

class _FixedTechNewsRepository implements TechNewsRepository {
  _FixedTechNewsRepository(this.articles);

  final List<NewsArticle> articles;

  @override
  Future<List<NewsArticle>> fetchArticles({int limit = 8}) async => articles;
}

class _ThrowingTechNewsRepository implements TechNewsRepository {
  @override
  Future<List<NewsArticle>> fetchArticles({int limit = 8}) {
    throw StateError('network unavailable');
  }
}

class _PendingTechNewsRepository implements TechNewsRepository {
  final completer = Completer<List<NewsArticle>>();

  @override
  Future<List<NewsArticle>> fetchArticles({int limit = 8}) {
    return completer.future;
  }
}

class _RetryTechNewsRepository implements TechNewsRepository {
  int calls = 0;

  @override
  Future<List<NewsArticle>> fetchArticles({int limit = 8}) async {
    calls++;
    if (calls == 1) throw StateError('first request failed');
    return [_article(1)];
  }
}

NewsArticle _article(int index) {
  return NewsArticle(
    title: '科技标题$index',
    summary: '科技摘要$index',
    source: '科技来源$index',
    url: Uri.parse('https://example.com/tech/$index'),
    publishedAt: DateTime.utc(2026, 7, 11, index),
  );
}

Widget _card(TechNewsProvider provider) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider.value(
        value: provider,
        child: const TechNewsCard(),
      ),
    ),
  );
}

void main() {
  testWidgets('TechNewsCard renders its title, icon, and idle empty copy', (
    tester,
  ) async {
    final provider = TechNewsProvider(
      repository: _FixedTechNewsRepository([]),
      cache: MemoryCacheManager(),
    );
    addTearDown(provider.dispose);

    await tester.pumpWidget(_card(provider));

    expect(find.text('科技 AI 新闻'), findsOneWidget);
    expect(find.byIcon(Icons.memory_outlined), findsOneWidget);
    expect(find.text('暂无科技资讯'), findsOneWidget);
  });

  testWidgets('TechNewsCard displays at most five article summaries', (
    tester,
  ) async {
    final provider = TechNewsProvider(
      repository: _FixedTechNewsRepository([
        for (var index = 1; index <= 6; index++) _article(index),
      ]),
      cache: MemoryCacheManager(),
    );
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_card(provider));

    for (var index = 1; index <= 5; index++) {
      expect(find.text('科技标题$index'), findsOneWidget);
      expect(find.text('科技来源$index'), findsOneWidget);
      expect(find.text('科技摘要$index'), findsOneWidget);
    }
    expect(find.text('科技标题6'), findsNothing);
  });

  testWidgets('TechNewsCard renders loading while a fetch is pending', (
    tester,
  ) async {
    final repository = _PendingTechNewsRepository();
    final provider = TechNewsProvider(
      repository: repository,
      cache: MemoryCacheManager(),
    );
    addTearDown(provider.dispose);

    final refresh = provider.refresh();
    await tester.pumpWidget(_card(provider));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completer.complete([]);
    await refresh;
  });

  testWidgets(
    'TechNewsCard renders an error and retries through the provider',
    (tester) async {
      final repository = _RetryTechNewsRepository();
      final provider = TechNewsProvider(
        repository: repository,
        cache: MemoryCacheManager(),
      );
      addTearDown(provider.dispose);
      await provider.refresh();

      await tester.pumpWidget(_card(provider));
      expect(find.text('科技新闻加载失败，请稍后重试'), findsOneWidget);

      await tester.tap(find.text('重试'));
      await tester.pump();
      await tester.pump();

      expect(repository.calls, 2);
      expect(find.text('科技标题1'), findsOneWidget);
    },
  );

  testWidgets('TechNewsCard marks stale cached articles as offline', (
    tester,
  ) async {
    final cache = MemoryCacheManager();
    await cache.save(
      AppConstants.cacheTechNews,
      jsonEncode([_article(1).toJson()]),
    );
    final provider = TechNewsProvider(
      repository: _ThrowingTechNewsRepository(),
      cache: cache,
    );
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_card(provider));

    expect(find.text('离线'), findsOneWidget);
    expect(find.text('科技标题1'), findsOneWidget);
  });
}
