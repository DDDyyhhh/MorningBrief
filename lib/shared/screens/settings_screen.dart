import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/module_config.dart';
import '../module_config_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _cityController;
  late final TextEditingController _weatherKeyController;
  late final TextEditingController _stockKeyController;
  late final TextEditingController _symbolsController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ModuleConfigProvider>();
    _cityController = TextEditingController(text: provider.city);
    _weatherKeyController = TextEditingController(text: provider.weatherApiKey);
    _stockKeyController = TextEditingController(text: provider.stockApiKey);
    _symbolsController = TextEditingController(
      text: provider.stockSymbols.join(','),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _weatherKeyController.dispose();
    _stockKeyController.dispose();
    _symbolsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModuleConfigProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('模块管理', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final config in provider.configs)
            SwitchListTile(
              value: config.enabled,
              title: Text(config.id.title),
              onChanged: (enabled) => provider.toggle(config.id, enabled),
            ),
          const SizedBox(height: 24),
          Text('偏好设置', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: '城市',
              border: OutlineInputBorder(),
            ),
            onEditingComplete: () => provider.updateCity(_cityController.text),
            onSubmitted: provider.updateCity,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weatherKeyController,
            decoration: const InputDecoration(
              labelText: 'OpenWeatherMap API Key',
              border: OutlineInputBorder(),
            ),
            onEditingComplete: () =>
                provider.updateWeatherApiKey(_weatherKeyController.text),
            onSubmitted: provider.updateWeatherApiKey,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stockKeyController,
            decoration: const InputDecoration(
              labelText: 'Alpha Vantage API Key',
              border: OutlineInputBorder(),
            ),
            onEditingComplete: () =>
                provider.updateStockApiKey(_stockKeyController.text),
            onSubmitted: provider.updateStockApiKey,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _symbolsController,
            decoration: const InputDecoration(
              labelText: '股票代码（逗号分隔）',
              border: OutlineInputBorder(),
            ),
            onEditingComplete: () =>
                provider.updateStockSymbols(_symbolsController.text.split(',')),
            onSubmitted: (value) =>
                provider.updateStockSymbols(value.split(',')),
          ),
        ],
      ),
    );
  }
}
