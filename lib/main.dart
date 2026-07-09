import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/storage.dart';
import 'shared/module_config_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  final storage = await AppStorage.create();
  final moduleConfigProvider = ModuleConfigProvider(storage);
  await moduleConfigProvider.load();

  runApp(
    ChangeNotifierProvider.value(
      value: moduleConfigProvider,
      child: const MorningBriefApp(),
    ),
  );
}
