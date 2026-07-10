import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morningbrief/core/api_client.dart';
import 'package:morningbrief/modules/weather/weather_service.dart';

http.Response _jsonResponse(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'WeatherService parses current weather and three-day forecast',
    () async {
      final client = ApiClient(
        MockClient((request) async {
          if (request.url.host == 'api.openweathermap.org' &&
              request.url.path.contains('/geo/1.0/direct')) {
            return _jsonResponse([
              {'lat': 31.2304, 'lon': 121.4737},
            ]);
          }
          return _jsonResponse({
            'current': {
              'temp': 24.5,
              'feels_like': 25.1,
              'humidity': 61,
              'wind_speed': 3.2,
              'weather': [
                {'description': '多云', 'icon': '03d'},
              ],
            },
            'daily': [
              {
                'dt': 1783382400,
                'temp': {'min': 22, 'max': 28},
                'weather': [
                  {'description': '小雨', 'icon': '10d'},
                ],
              },
              {
                'dt': 1783468800,
                'temp': {'min': 23, 'max': 29},
                'weather': [
                  {'description': '晴', 'icon': '01d'},
                ],
              },
              {
                'dt': 1783555200,
                'temp': {'min': 24, 'max': 30},
                'weather': [
                  {'description': '阴', 'icon': '04d'},
                ],
              },
            ],
          });
        }),
      );
      final service = WeatherService(
        client,
        now: () => DateTime(2026, 7, 7, 8),
      );

      final model = await service.fetchWeather(city: '上海', apiKey: 'key');

      expect(model.city, '上海');
      expect(model.temperature, 24.5);
      expect(model.forecast.length, 3);
    },
  );
}
