/// Positive fixture: a closed algebraic hierarchy that should be sealed.
///
/// `Shape` is abstract, has two direct subtypes, and both are declared in this
/// same library, so `sealed class Shape` would compile.
library;

abstract class Shape {}

class Circle extends Shape {
  Circle(this.radius);
  final double radius;
}

class Square extends Shape {
  Square(this.side);
  final double side;
}
