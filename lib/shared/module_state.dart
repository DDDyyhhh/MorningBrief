import '../core/app_error.dart';

enum ModuleStatus { idle, loading, data, empty, error, offline }

class ModuleState<T> {
  const ModuleState._({required this.status, this.data, this.error});

  final ModuleStatus status;
  final T? data;
  final AppError? error;

  factory ModuleState.idle() => const ModuleState._(status: ModuleStatus.idle);
  factory ModuleState.loading() => const ModuleState._(status: ModuleStatus.loading);
  factory ModuleState.data(T data) => ModuleState._(status: ModuleStatus.data, data: data);
  factory ModuleState.empty() => const ModuleState._(status: ModuleStatus.empty);
  factory ModuleState.error(AppError error) => ModuleState._(status: ModuleStatus.error, error: error);
  factory ModuleState.offline(T data) => ModuleState._(status: ModuleStatus.offline, data: data);

  bool get isLoading => status == ModuleStatus.loading;
  bool get hasData => status == ModuleStatus.data || status == ModuleStatus.offline;
  bool get isEmpty => status == ModuleStatus.empty;
  bool get hasError => status == ModuleStatus.error;
  bool get isOffline => status == ModuleStatus.offline;
}
