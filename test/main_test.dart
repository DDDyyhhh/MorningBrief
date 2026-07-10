import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/constants.dart';
import 'package:morningbrief/main.dart' as app_main;
import 'package:morningbrief/models/module_config.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/modules/news/news_provider.dart';
import 'package:morningbrief/shared/module_config_provider.dart';
import 'package:morningbrief/shared/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PendingNewsRepository implements NewsRepository {
  final completer = Completer<List<NewsArticle>>();
  int calls = 0;

  @override
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 10}) {
    calls++;
    return completer.future;
  }
}

class _CountingNewsRepository implements NewsRepository {
  int calls = 0;

  @override
  Future<List<NewsArticle>> fetchArticles(
    List<Uri> feeds, {
    int limit = 10,
  }) async {
    calls++;
    return [];
  }
}

Map<String, Object> _disabledNewsPreferences() {
  final configs = ModuleConfig.defaults()
      .map(
        (config) => config.id == MorningModuleId.news
            ? config.copyWith(enabled: false)
            : config,
      )
      .toList();
  return {
    AppConstants.moduleConfigs: jsonEncode(
      configs.map((config) => config.toJson()).toList(),
    ),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('startApp renders without waiting for pending news', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _PendingNewsRepository();
    addTearDown(() {
      if (!repository.completer.isCompleted) {
        repository.completer.complete([]);
      }
    });
    var returned = false;

    app_main
        .startApp(
          openCalendarDatabase: () async => throw StateError('no database'),
          newsRepository: repository,
        )
        .then((_) => returned = true);
    await tester.pump();

    expect(returned, isTrue);
    expect(find.text('MorningBrief'), findsOneWidget);
    expect(repository.calls, 1);
  });

  testWidgets('startApp does not load news while the module is disabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_disabledNewsPreferences());
    final repository = _CountingNewsRepository();

    await app_main.startApp(
      openCalendarDatabase: () async => throw StateError('no database'),
      newsRepository: repository,
    );
    await tester.pump();

    expect(repository.calls, 0);
  });

  testWidgets('enabling news triggers exactly one initial load', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_disabledNewsPreferences());
    final repository = _CountingNewsRepository();

    await app_main.startApp(
      openCalendarDatabase: () async => throw StateError('no database'),
      newsRepository: repository,
    );
    await tester.pump();
    final context = tester.element(find.byType(HomeScreen));
    final configProvider = context.read<ModuleConfigProvider>();
    expect(repository.calls, 0);

    await configProvider.toggle(MorningModuleId.news, true);
    await tester.pump();
    await configProvider.toggle(MorningModuleId.news, true);
    await tester.pump();

    expect(repository.calls, 1);
  });
}
