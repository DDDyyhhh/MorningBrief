import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

class MorningBriefApp extends StatelessWidget {
  const MorningBriefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MorningBrief',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routes: {
        '/': (_) => const _TemporaryHomeScreen(),
        '/settings': (_) => const _TemporarySettingsScreen(),
      },
    );
  }
}

class _TemporaryHomeScreen extends StatelessWidget {
  const _TemporaryHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MorningBrief'),
        actions: [
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('早安！'),
      ),
    );
  }
}

class _TemporarySettingsScreen extends StatelessWidget {
  const _TemporarySettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('配置将在后续任务中添加'),
      ),
    );
  }
}
