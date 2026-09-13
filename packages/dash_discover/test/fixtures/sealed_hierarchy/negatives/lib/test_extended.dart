/// Would be a sealing candidate on the strength of `lib/` alone, but a
/// subtype is declared in `test/`, which makes sealing a compile error.
abstract class Extended {}

class ExtendedOne extends Extended {}

class ExtendedTwo extends Extended {}
