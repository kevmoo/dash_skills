import 'package:test/test.dart';

void main() {
  group('Idiomatic matchers fixture', () {
    test('collection checks', () {
      final items = ['apple', 'banana', 'cherry'];
      final emptyList = <String>[];
      final map = {'name': 'Alice', 'role': 'admin'};

      expect(items, hasLength(3));
      expect(emptyList, isEmpty);
      expect(items, isNotEmpty);
      expect(items, contains('banana'));
      expect(map, containsPair('name', 'Alice'));
    });

    test('exception checks', () {
      expect(() => throw StateError('bad state'), throwsA(isA<StateError>()));
    });
  });
}
