import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/modules/calendar/calendar_provider.dart';
import 'package:morningbrief/modules/calendar/calendar_service.dart';
import 'package:morningbrief/models/weather_model.dart';
import 'package:morningbrief/modules/weather/weather_provider.dart';
import 'package:morningbrief/shared/module_config_provider.dart';
import 'package:morningbrief/shared/screens/home_screen.dart';

class _HomeScreenWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  }) {
    return Future.value(
      WeatherModel(
        city: city,
        temperature: 0,
        feelsLike: 0,
        humidity: 0,
        windSpeed: 0,
        description: 'test',
        iconCode: '01d',
        forecast: const <WeatherForecast>[],
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'HomeScreen shows greeting, enabled module placeholders, and updated time',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await AppStorage.create();
      final provider = ModuleConfigProvider(storage);
      await provider.load();
      final calendarProvider = CalendarProvider(MemoryCalendarService());
      await calendarProvider.loadToday();
      final weatherProvider = WeatherProvider(
        repository: _HomeScreenWeatherRepository(),
        cache: MemoryCacheManager(),
        cityReader: () => 'Shanghai',
        apiKeyReader: () => 'test-key',
      );
      addTearDown(weatherProvider.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: calendarProvider),
            ChangeNotifierProvider.value(value: weatherProvider),
          ],
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
