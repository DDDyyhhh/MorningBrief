import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/weather_model.dart';
import '../../shared/module_state.dart';
import '../../shared/widgets/module_card.dart';
import '../../shared/widgets/module_error_widget.dart';
import '../../shared/widgets/module_loading_widget.dart';
import 'weather_provider.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final state = provider.state;
    return ModuleCard(
      title: '天气',
      icon: Icons.wb_sunny_outlined,
      offline: state.isOffline,
      child: _WeatherBody(state: state, onRetry: provider.refresh),
    );
  }
}

class _WeatherBody extends StatelessWidget {
  const _WeatherBody({required this.state, required this.onRetry});

  final ModuleState<WeatherModel> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const ModuleLoadingWidget();
    }
    if (state.hasError) {
      return ModuleErrorWidget(message: state.error!.message, onRetry: onRetry);
    }
    final weather = state.data;
    if (weather == null) {
      return const Text('暂无天气数据');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${weather.city} ${weather.temperature.toStringAsFixed(0)}°C',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          '${weather.description} · 体感 ${weather.feelsLike.toStringAsFixed(0)}°C · 湿度 ${weather.humidity}%',
        ),
        const SizedBox(height: 12),
        for (final item in weather.forecast)
          Text(
            '${DateFormat('M/d').format(item.date)} ${item.description} ${item.minTemp.toStringAsFixed(0)}°/${item.maxTemp.toStringAsFixed(0)}°',
          ),
      ],
    );
  }
}
