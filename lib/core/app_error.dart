enum AppErrorType { network, apiKeyMissing, empty, storage, unknown }

class AppError {
  const AppError({required this.type, required this.message});

  final AppErrorType type;
  final String message;
}
