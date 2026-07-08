class WeatherForecast {
  WeatherForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.description,
    required this.iconCode,
  });

  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String description;
  final String iconCode;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'minTemp': minTemp,
    'maxTemp': maxTemp,
    'description': description,
    'iconCode': iconCode,
  };

  factory WeatherForecast.fromJson(Map<String, dynamic> json) =>
      WeatherForecast(
        date: DateTime.parse(json['date'] as String),
        minTemp: (json['minTemp'] as num).toDouble(),
        maxTemp: (json['maxTemp'] as num).toDouble(),
        description: json['description'] as String,
        iconCode: json['iconCode'] as String,
      );
}

class WeatherModel {
  WeatherModel({
    required this.city,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconCode,
    required this.forecast,
    required this.updatedAt,
  });

  final String city;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String iconCode;
  final List<WeatherForecast> forecast;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'city': city,
    'temperature': temperature,
    'feelsLike': feelsLike,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'description': description,
    'iconCode': iconCode,
    'forecast': forecast.map((item) => item.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WeatherModel.fromJson(Map<String, dynamic> json) => WeatherModel(
    city: json['city'] as String,
    temperature: (json['temperature'] as num).toDouble(),
    feelsLike: (json['feelsLike'] as num).toDouble(),
    humidity: json['humidity'] as int,
    windSpeed: (json['windSpeed'] as num).toDouble(),
    description: json['description'] as String,
    iconCode: json['iconCode'] as String,
    forecast: (json['forecast'] as List<dynamic>)
        .map((item) => WeatherForecast.fromJson(item as Map<String, dynamic>))
        .toList(),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
