import 'package:flutter/foundation.dart';
import '../../core/app_error.dart';
import '../../models/calendar_event.dart';
import '../../shared/module_state.dart';
import 'calendar_service.dart';

class CalendarProvider extends ChangeNotifier {
  CalendarProvider(this._service);

  final CalendarService _service;
  ModuleState<List<CalendarEvent>> _state = ModuleState.idle();

  ModuleState<List<CalendarEvent>> get state => _state;

  void setStorageError() {
    _state = ModuleState.error(const AppError(type: AppErrorType.storage, message: '日程读取失败'));
    notifyListeners();
  }

  Future<void> loadToday() async {
    _state = ModuleState.loading();
    notifyListeners();
    try {
      final events = await _service.todayEvents();
      _state = events.isEmpty ? ModuleState.empty() : ModuleState.data(events);
    } catch (_) {
      _state = ModuleState.error(const AppError(type: AppErrorType.storage, message: '日程读取失败'));
    }
    notifyListeners();
  }

  Future<void> addEvent(String title, DateTime startsAt) async {
    try {
      await _service.createEvent(title, startsAt);
      await loadToday();
    } catch (_) {
      _state = ModuleState.error(const AppError(type: AppErrorType.storage, message: '日程保存失败'));
      notifyListeners();
    }
  }

  Future<void> toggleCompleted(int id, bool completed) async {
    try {
      await _service.toggleCompleted(id, completed);
      await loadToday();
    } catch (_) {
      _state = ModuleState.error(const AppError(type: AppErrorType.storage, message: '日程保存失败'));
      notifyListeners();
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      await _service.deleteEvent(id);
      await loadToday();
    } catch (_) {
      _state = ModuleState.error(const AppError(type: AppErrorType.storage, message: '日程保存失败'));
      notifyListeners();
    }
  }
}
