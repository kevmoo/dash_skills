import '../lib/test_extended.dart';

/// A third subtype declared outside `lib/`. Sealing `Extended` would break
/// this file, so the rule must not suggest it.
class ExtendedThree extends Extended {}

void main() {}
