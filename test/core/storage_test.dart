import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/models/module_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppStorage stores strings and module configs', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();

    await storage.setString('city_name', '杭州');
    expect(await storage.getString('city_name'), '杭州');

    const configs = [
      ModuleConfig(id: MorningModuleId.news, enabled: false, order: 4),
    ];
    await storage.setModuleConfigs(configs);

    expect(await storage.getModuleConfigs(), configs);
  });

  test('AppStorage returns default configs when none are saved', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();

    expect(await storage.getModuleConfigs(), ModuleConfig.defaults());
  });
}
