import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/modules/calendar/calendar_provider.dart';
import 'package:morningbrief/modules/calendar/calendar_service.dart';
import 'package:morningbrief/shared/module_state.dart';

void main() {
  test('CalendarProvider loads today events and toggles completion', () async {
    final service = MemoryCalendarService(now: () => DateTime(2026, 7, 7, 8));
    final provider = CalendarProvider(service);

    await provider.addEvent('写晨报', DateTime(2026, 7, 7, 9));

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.single.title, '写晨报');

    await provider.toggleCompleted(provider.state.data!.single.id!, true);

    expect(provider.state.data!.single.isCompleted, true);
  });
}
