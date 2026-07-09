import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'shared/screens/home_screen.dart';
import 'shared/screens/settings_screen.dart';

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
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
