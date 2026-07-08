import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/models/calendar_event.dart';
import 'package:morningbrief/models/module_config.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/models/stock_item.dart';
import 'package:morningbrief/models/weather_model.dart';

void main() {
  test('ModuleConfig serializes module ID and ordering', () {
    const config = ModuleConfig(
      id: MorningModuleId.weather,
      enabled: true,
      order: 2,
    );

    expect(ModuleConfig.fromJson(config.toJson()), config);
  });

  test('WeatherModel serializes current weather and forecast', () {
    final model = WeatherModel(
      city: '上海',
      temperature: 24.5,
      feelsLike: 25.1,
      humidity: 61,
      windSpeed: 3.2,
      description: '多云',
      iconCode: '03d',
      forecast: [
        WeatherForecast(
          date: DateTime(2026, 7, 7),
          minTemp: 22,
          maxTemp: 28,
          description: '小雨',
          iconCode: '10d',
        ),
      ],
      updatedAt: DateTime(2026, 7, 7, 8),
    );

    expect(WeatherModel.fromJson(model.toJson()).toJson(), model.toJson());
  });

  test('NewsArticle serializes source and URL', () {
    final article = NewsArticle(
      title: 'AI 新闻',
      summary: '摘要',
      source: '机器之心',
      url: Uri.parse('https://example.com/a'),
      publishedAt: DateTime(2026, 7, 7, 7, 30),
    );

    expect(NewsArticle.fromJson(article.toJson()).toJson(), article.toJson());
  });

  test('CalendarEvent serializes completion state', () {
    final event = CalendarEvent(
      id: 7,
      title: '晨会',
      startsAt: DateTime(2026, 7, 7, 9),
      isCompleted: false,
      createdAt: DateTime(2026, 7, 7, 6),
    );

    expect(CalendarEvent.fromJson(event.toJson()).toJson(), event.toJson());
  });

  test('StockItem serializes quote values', () {
    final item = StockItem(
      symbol: '600036.SHH',
      name: '招商银行',
      price: 35.2,
      change: 0.3,
      changePercent: 0.86,
      updatedAt: DateTime(2026, 7, 7, 10),
    );

    expect(StockItem.fromJson(item.toJson()).toJson(), item.toJson());
  });
}
