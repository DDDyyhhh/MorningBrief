import 'dart:convert';
import '../../core/api_client.dart';
import '../../models/weather_model.dart';

class WeatherService {
  WeatherService(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ApiClient _client;
  final DateTime Function() _now;

  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  }) async {
    final geoUri = Uri.https('api.openweathermap.org', '/geo/1.0/direct', {
      'q': city,
      'limit': '1',
      'appid': apiKey,
    });
    final geoText = await _client.getText(geoUri);
    final geo = jsonDecode(geoText) as List<dynamic>;
    if (geo.isEmpty) throw ApiClientException('未找到城市');
    final first = geo.first as Map<String, dynamic>;
    final lat = (first['lat'] as num).toString();
    final lon = (first['lon'] as num).toString();

    final weatherUri =
        Uri.https('api.openweathermap.org', '/data/3.0/onecall', {
          'lat': lat,
          'lon': lon,
          'exclude': 'minutely,hourly,alerts',
          'appid': apiKey,
          'units': 'metric',
          'lang': 'zh_cn',
        });
    final json = await _client.getJson(weatherUri);
    final current = json['current'] as Map<String, dynamic>;
    final currentWeather =
        (current['weather'] as List<dynamic>).first as Map<String, dynamic>;
    final daily = (json['daily'] as List<dynamic>).take(3).map((item) {
      final map = item as Map<String, dynamic>;
      final weather =
          (map['weather'] as List<dynamic>).first as Map<String, dynamic>;
      final temp = map['temp'] as Map<String, dynamic>;
      return WeatherForecast(
        date: DateTime.fromMillisecondsSinceEpoch((map['dt'] as int) * 1000),
        minTemp: (temp['min'] as num).toDouble(),
        maxTemp: (temp['max'] as num).toDouble(),
        description: weather['description'] as String,
        iconCode: weather['icon'] as String,
      );
    }).toList();

    return WeatherModel(
      city: city,
      temperature: (current['temp'] as num).toDouble(),
      feelsLike: (current['feels_like'] as num).toDouble(),
      humidity: current['humidity'] as int,
      windSpeed: (current['wind_speed'] as num).toDouble(),
      description: currentWeather['description'] as String,
      iconCode: currentWeather['icon'] as String,
      forecast: daily,
      updatedAt: _now(),
    );
  }
}
