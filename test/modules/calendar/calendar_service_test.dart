import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/modules/calendar/calendar_service.dart';

void main() {
  test('MemoryCalendarService creates, lists, toggles, and deletes today events', () async {
    final service = MemoryCalendarService(now: () => DateTime(2026, 7, 7, 8));

    final event = await service.createEvent('写晨报', DateTime(2026, 7, 7, 9));
    expect(event.id, isNotNull);

    expect((await service.todayEvents()).single.title, '写晨报');

    await service.toggleCompleted(event.id!, true);
    expect((await service.todayEvents()).single.isCompleted, true);

    await service.deleteEvent(event.id!);
    expect(await service.todayEvents(), isEmpty);
  });

  test('MemoryCalendarService does not include tomorrow events in todayEvents', () async {
    final service = MemoryCalendarService(now: () => DateTime(2026, 7, 7, 8));
    await service.createEvent('明天任务', DateTime(2026, 7, 8, 9));

    expect(await service.todayEvents(), isEmpty);
  });
}
