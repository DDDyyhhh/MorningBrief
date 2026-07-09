import 'package:sqflite/sqflite.dart';
import '../../models/calendar_event.dart';

abstract class CalendarService {
  Future<CalendarEvent> createEvent(String title, DateTime startsAt);
  Future<List<CalendarEvent>> todayEvents();
  Future<void> toggleCompleted(int id, bool completed);
  Future<void> deleteEvent(int id);
}

class MemoryCalendarService implements CalendarService {
  MemoryCalendarService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final List<CalendarEvent> _events = [];
  int _nextId = 1;

  @override
  Future<CalendarEvent> createEvent(String title, DateTime startsAt) async {
    final event = CalendarEvent(id: _nextId++, title: title, startsAt: startsAt, isCompleted: false, createdAt: _now());
    _events.add(event);
    return event;
  }

  @override
  Future<List<CalendarEvent>> todayEvents() async {
    final now = _now();
    return _events.where((event) => event.startsAt.year == now.year && event.startsAt.month == now.month && event.startsAt.day == now.day).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Future<void> toggleCompleted(int id, bool completed) async {
    final index = _events.indexWhere((event) => event.id == id);
    if (index >= 0) _events[index] = _events[index].copyWith(isCompleted: completed);
  }

  @override
  Future<void> deleteEvent(int id) async {
    _events.removeWhere((event) => event.id == id);
  }
}

class SqliteCalendarService implements CalendarService {
  SqliteCalendarService(this._database, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Database _database;
  final DateTime Function() _now;

  @override
  Future<CalendarEvent> createEvent(String title, DateTime startsAt) async {
    final createdAt = _now();
    final id = await _database.insert('calendar_events', {
      'title': title,
      'starts_at': startsAt.toIso8601String(),
      'is_completed': 0,
      'created_at': createdAt.toIso8601String(),
    });
    return CalendarEvent(id: id, title: title, startsAt: startsAt, isCompleted: false, createdAt: createdAt);
  }

  @override
  Future<List<CalendarEvent>> todayEvents() async {
    final now = _now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _database.query(
      'calendar_events',
      where: 'starts_at >= ? AND starts_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'starts_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> toggleCompleted(int id, bool completed) async {
    await _database.update('calendar_events', {'is_completed': completed ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteEvent(int id) async {
    await _database.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
  }

  CalendarEvent _fromRow(Map<String, Object?> row) => CalendarEvent(
        id: row['id'] as int,
        title: row['title'] as String,
        startsAt: DateTime.parse(row['starts_at'] as String),
        isCompleted: row['is_completed'] == 1,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
