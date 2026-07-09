import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/shared/module_config_provider.dart';
import 'package:morningbrief/shared/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'HomeScreen shows greeting, enabled module placeholders, and updated time',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await AppStorage.create();
      final provider = ModuleConfigProvider(storage);
      await provider.load();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('早安！'), findsOneWidget);
      expect(find.text('天气'), findsOneWidget);
      expect(find.text('新闻头条'), findsOneWidget);
      expect(find.text('日历与日程'), findsOneWidget);
      expect(find.textContaining('上次更新'), findsOneWidget);
    },
  );
}
