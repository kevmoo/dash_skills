import 'package:test/test.dart';

class Vector2D {
  final double x;
  final double y;
  const Vector2D(this.x, this.y);

  // Geometric magnitude (double), not a collection length:
  double get length => x * x + y * y;
}

class ToggleSwitch {
  bool isEnabled = true;
}

void main() {
  group('Non-collection assertions (abstention fixture)', () {
    test('vector length is magnitude, not collection hasLength', () {
      const vec = Vector2D(3.0, 4.0);
      expect(vec.length, equals(25.0));
    });

    test('custom boolean property with no matcher', () {
      final toggle = ToggleSwitch();
      expect(toggle.isEnabled, isTrue);
    });

    test('scalar arithmetic assertion', () {
      const a = 10;
      const b = 20;
      expect(a + b, equals(30));
    });
  });
}
