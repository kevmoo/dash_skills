import 'package:test/test.dart';

void main() {
  group('Suboptimal matchers fixture', () {
    test('collection checks', () {
      final items = ['apple', 'banana', 'cherry'];
      final emptyList = <String>[];
      final map = {'name': 'Alice', 'role': 'admin'};

      // Suboptimal length check (should be hasLength(3))
      expect(items.length, 3);

      // Suboptimal isEmpty check (should be isEmpty)
      expect(emptyList.isEmpty, true);

      // Suboptimal isNotEmpty check (should be isNotEmpty)
      expect(items.isNotEmpty, true);

      // Suboptimal contains check (should be contains('banana'))
      expect(items.contains('banana'), true);

      // Suboptimal map lookup (should be containsPair('name', 'Alice'))
      expect(map['name'], 'Alice');
    });

    test('exception checks', () {
      // Suboptimal try/catch with fail() (should be throwsA(isA<StateError>()))
      try {
        throw StateError('bad state');
        fail('should have thrown');
      } catch (e) {
        expect(e, isA<StateError>());
      }
    });
  });
}
