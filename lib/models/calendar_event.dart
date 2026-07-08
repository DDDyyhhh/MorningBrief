class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.isCompleted,
    required this.createdAt,
  });

  final int? id;
  final String title;
  final DateTime startsAt;
  final bool isCompleted;
  final DateTime createdAt;

  CalendarEvent copyWith({
    int? id,
    String? title,
    DateTime? startsAt,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startsAt: startsAt ?? this.startsAt,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startsAt': startsAt.toIso8601String(),
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'] as int?,
    title: json['title'] as String,
    startsAt: DateTime.parse(json['startsAt'] as String),
    isCompleted: json['isCompleted'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
