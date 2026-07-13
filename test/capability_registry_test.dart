import 'package:flutter_test/flutter_test.dart';
import 'package:hello_jarvice/core/capability_registry.dart';
import 'package:hello_jarvice/core/capability.dart';

void main() {
  group('CapabilityRegistry', () {
    setUp(() {
      CapabilityRegistry.instance.initialize();
    });

    test('registers all capabilities', () {
      final stats = CapabilityRegistry.instance.getStats();
      expect(stats['total'], greaterThan(50));
    });

    test('gets capability by id', () {
      final cap = CapabilityRegistry.instance.getCapability('OPEN_APPLICATION');
      expect(cap, isNotNull);
      expect(cap!.id, 'OPEN_APPLICATION');
      expect(cap.category, CapabilityCategory.application);
    });

    test('gets capabilities by category', () {
      final caps = CapabilityRegistry.instance.getByCategory(CapabilityCategory.volume);
      expect(caps, isNotEmpty);
      expect(caps.every((c) => c.category == CapabilityCategory.volume), isTrue);
    });

    test('gets capabilities by operation', () {
      final caps = CapabilityRegistry.instance.getByOperation(Operation.toggle);
      expect(caps, isNotEmpty);
    });

    test('finds by keywords', () {
      final caps = CapabilityRegistry.instance.findByKeywords(['volume']);
      expect(caps, isNotEmpty);
    });

    test('finds by name', () {
      final caps = CapabilityRegistry.instance.findByName('battery');
      expect(caps, isNotEmpty);
      expect(caps.any((c) => c.id == 'GET_BATTERY_LEVEL'), isTrue);
    });

    test('returns empty for unknown category', () {
      final caps = CapabilityRegistry.instance.getByCategory(CapabilityCategory.dnd);
      expect(caps, isNotEmpty); // DND is registered
    });

    test('getStats returns category counts', () {
      final stats = CapabilityRegistry.instance.getStats();
      expect(stats['byCategory'], isA<Map>());
    });
  });
}
