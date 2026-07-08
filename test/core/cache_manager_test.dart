import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/cache_manager.dart';

void main() {
  test('MemoryCacheManager returns fresh cached values', () async {
    final cache = MemoryCacheManager(now: () => DateTime(2026, 7, 7, 8));

    await cache.save('weather', '{"ok":true}');
    final value = await cache.readFresh('weather', const Duration(minutes: 30));

    expect(value?.jsonValue, '{"ok":true}');
    expect(value?.isFresh, true);
  });

  test('MemoryCacheManager returns stale values as not fresh', () async {
    var current = DateTime(2026, 7, 7, 8);
    final cache = MemoryCacheManager(now: () => current);

    await cache.save('weather', '{"ok":true}');
    current = DateTime(2026, 7, 7, 9);

    expect(
      await cache.readFresh('weather', const Duration(minutes: 30)),
      isNull,
    );
    expect((await cache.readAny('weather'))?.isFresh, false);
  });
}
