import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/module_config.dart';
import '../../modules/calendar/calendar_card.dart';
import '../../modules/calendar/calendar_provider.dart';
import '../../modules/news/news_card.dart';
import '../../modules/news/news_provider.dart';
import '../../modules/stocks/stocks_card.dart';
import '../../modules/stocks/stocks_provider.dart';
import '../../modules/tech_news/tech_news_card.dart';
import '../../modules/tech_news/tech_news_provider.dart';
import '../../modules/weather/weather_card.dart';
import '../../modules/weather/weather_provider.dart';
import '../module_config_provider.dart';
import '../widgets/module_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _refreshEnabledModules() async {
    final config = context.read<ModuleConfigProvider>();
    final refreshes = <Future<void>>[];

    if (config.isEnabled(MorningModuleId.weather)) {
      refreshes.add(context.read<WeatherProvider>().refresh());
    }
    if (config.isEnabled(MorningModuleId.news)) {
      refreshes.add(context.read<NewsProvider>().refresh());
    }
    if (config.isEnabled(MorningModuleId.calendar)) {
      refreshes.add(context.read<CalendarProvider>().loadToday());
    }
    if (config.isEnabled(MorningModuleId.stocks)) {
      refreshes.add(context.read<StocksProvider>().refresh());
    }
    if (config.isEnabled(MorningModuleId.techNews)) {
      refreshes.add(context.read<TechNewsProvider>().refresh());
    }

    await Future.wait(refreshes);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已刷新晨间简报')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModuleConfigProvider>();
    final enabled = provider.configs.where((config) => config.enabled).toList();
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('MorningBrief'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshEnabledModules,
          ),
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('早安！', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(_formatChineseDate(now)),
            const SizedBox(height: 16),
            for (final config in enabled) ...[
              _PlaceholderModuleCard(config.id),
              const SizedBox(height: 12),
            ],
            Text(
              '上次更新：${DateFormat('HH:mm').format(now)}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatChineseDate(DateTime date) {
  try {
    return DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(date);
  } catch (_) {
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return '${date.year}年${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
  }
}

class _PlaceholderModuleCard extends StatelessWidget {
  const _PlaceholderModuleCard(this.id);

  final MorningModuleId id;

  @override
  Widget build(BuildContext context) {
    if (id == MorningModuleId.weather) return const WeatherCard();
    if (id == MorningModuleId.news) return const NewsCard();
    if (id == MorningModuleId.calendar) return const CalendarCard();
    if (id == MorningModuleId.stocks) return const StocksCard();
    if (id == MorningModuleId.techNews) return const TechNewsCard();
    final icon = switch (id) {
      MorningModuleId.weather => Icons.wb_sunny_outlined,
      MorningModuleId.news => Icons.article_outlined,
      MorningModuleId.calendar => Icons.event_note_outlined,
      MorningModuleId.stocks => Icons.show_chart,
      MorningModuleId.techNews => Icons.memory_outlined,
    };
    return ModuleCard(title: id.title, icon: icon, child: const Text('模块正在加载'));
  }
}
