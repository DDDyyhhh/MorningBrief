import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/app_error.dart';
import 'package:morningbrief/shared/module_state.dart';

void main() {
  test('ModuleState exposes data and loading flags', () {
    expect(ModuleState<String>.loading().isLoading, true);
    expect(ModuleState.data('ok').data, 'ok');
    expect(ModuleState<String>.empty().isEmpty, true);
  });

  test('ModuleState stores retryable errors', () {
    const error = AppError(type: AppErrorType.network, message: '网络异常');
    final state = ModuleState<String>.error(error);

    expect(state.hasError, true);
    expect(state.error?.message, '网络异常');
  });
}
