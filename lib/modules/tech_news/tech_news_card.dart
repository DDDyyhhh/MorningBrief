import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/news_article.dart';
import '../../shared/module_state.dart';
import '../../shared/widgets/module_card.dart';
import '../../shared/widgets/module_empty_widget.dart';
import '../../shared/widgets/module_error_widget.dart';
import '../../shared/widgets/module_loading_widget.dart';
import 'tech_news_provider.dart';

class TechNewsCard extends StatelessWidget {
  const TechNewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TechNewsProvider>();
    final state = provider.state;
    return ModuleCard(
      title: '科技 AI 新闻',
      icon: Icons.memory_outlined,
      offline: state.isOffline,
      child: _TechNewsBody(state: state, onRetry: provider.refresh),
    );
  }
}

class _TechNewsBody extends StatelessWidget {
  const _TechNewsBody({required this.state, required this.onRetry});

  final ModuleState<List<NewsArticle>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const ModuleLoadingWidget();
    }
    if (state.hasError) {
      return ModuleErrorWidget(message: state.error!.message, onRetry: onRetry);
    }
    final articles = state.data;
    if (state.isEmpty || articles == null || articles.isEmpty) {
      return const ModuleEmptyWidget(message: '暂无科技资讯');
    }
    final visibleArticles = articles.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < visibleArticles.length; index++) ...[
          if (index > 0) const Divider(height: 24),
          _TechNewsArticleSummary(article: visibleArticles[index]),
        ],
      ],
    );
  }
}

class _TechNewsArticleSummary extends StatelessWidget {
  const _TechNewsArticleSummary({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          article.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          article.source,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(article.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
