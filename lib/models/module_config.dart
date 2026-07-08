enum MorningModuleId { weather, news, calendar, stocks, techNews }

extension MorningModuleIdX on MorningModuleId {
  String get storageKey => switch (this) {
    MorningModuleId.weather => 'weather',
    MorningModuleId.news => 'news',
    MorningModuleId.calendar => 'calendar',
    MorningModuleId.stocks => 'stocks',
    MorningModuleId.techNews => 'tech_news',
  };

  String get title => switch (this) {
    MorningModuleId.weather => '天气',
    MorningModuleId.news => '新闻头条',
    MorningModuleId.calendar => '日历与日程',
    MorningModuleId.stocks => '股票财经',
    MorningModuleId.techNews => '科技 AI 新闻',
  };

  static MorningModuleId fromStorageKey(String key) {
    return MorningModuleId.values.firstWhere(
      (id) => id.storageKey == key,
      orElse: () => MorningModuleId.weather,
    );
  }
}

class ModuleConfig {
  const ModuleConfig({
    required this.id,
    required this.enabled,
    required this.order,
  });

  final MorningModuleId id;
  final bool enabled;
  final int order;

  ModuleConfig copyWith({MorningModuleId? id, bool? enabled, int? order}) {
    return ModuleConfig(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.storageKey,
    'enabled': enabled,
    'order': order,
  };

  factory ModuleConfig.fromJson(Map<String, dynamic> json) {
    return ModuleConfig(
      id: MorningModuleIdX.fromStorageKey(json['id'] as String),
      enabled: json['enabled'] as bool,
      order: json['order'] as int,
    );
  }

  static List<ModuleConfig> defaults() => const [
    ModuleConfig(id: MorningModuleId.weather, enabled: true, order: 0),
    ModuleConfig(id: MorningModuleId.news, enabled: true, order: 1),
    ModuleConfig(id: MorningModuleId.calendar, enabled: true, order: 2),
    ModuleConfig(id: MorningModuleId.stocks, enabled: true, order: 3),
    ModuleConfig(id: MorningModuleId.techNews, enabled: true, order: 4),
  ];

  @override
  bool operator ==(Object other) {
    return other is ModuleConfig &&
        other.id == id &&
        other.enabled == enabled &&
        other.order == order;
  }

  @override
  int get hashCode => Object.hash(id, enabled, order);
}
