import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/utils/uuid_generator.dart';

void main() {
  group('UuidGenerator', () {
    test('generates UUID v4 values', () {
      final generator = UuidGenerator();

      final first = generator();
      final second = generator();

      expect(first, matches(RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      )));
      expect(second, matches(RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      )));
      expect(first, isNot(equals(second)));
    });
  });
}
