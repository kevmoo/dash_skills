import 'dart:io';

import 'package:dash_discover/src/context.dart';
import 'package:dash_discover/src/rules/pattern_matching_rule.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('PatternMatchingRule Heuristic Evaluation', () {
    const rule = PatternMatchingRule();
    final fixturesDir = Directory(
      p.join(Directory.current.path, 'test', 'fixtures', 'pattern_matching'),
    );

    test('flagged on positive cascade and switch fixture (Recall)', () {
      final file = File(
        p.join(fixturesDir.path, 'positive_cascade_and_switch.dart'),
      );
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(
        result,
        isNotNull,
        reason: 'Must detect multi-branch type cascades and returning switches',
      );
    });

    test('abstains on negative idiomatic fixture (Precision)', () {
      final file = File(p.join(fixturesDir.path, 'negative_idiomatic.dart'));
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(
        result,
        isNull,
        reason: 'Must not flag code already using Dart 3 pattern matching',
      );
    });

    test(
      'abstains on negative 2-branch guard fixture (Abstention Guardrails)',
      () {
        final file = File(
          p.join(fixturesDir.path, 'negative_two_branch_guard.dart'),
        );
        final context = PackageContext.load(Directory.current.path);
        final result = rule.checkFile(file, file.readAsStringSync(), context);
        expect(
          result,
          isNull,
          reason:
              'Must abstain on simple 2-branch guards with single type promotion',
        );
      },
    );

    test('flags isolated returning switch statement', () {
      const content = '''
enum Priority { low, high }
String label(Priority p) {
  switch (p) {
    case Priority.low:
      return 'Low';
    case Priority.high:
      return 'High';
  }
}
''';
      final file = File('test/isolated_switch.dart');
      final context = PackageContext.load(Directory.current.path);
      expect(rule.checkFile(file, content, context), isNotNull);
    });

    test('abstains on void switch with break', () {
      const content = '''
enum Priority { low, high }
void execute(Priority p) {
  switch (p) {
    case Priority.low:
      doLow();
      break;
    case Priority.high:
      doHigh();
      break;
  }
}
''';
      final file = File('test/isolated_void_switch.dart');
      final context = PackageContext.load(Directory.current.path);
      expect(rule.checkFile(file, content, context), isNull);
    });

    test(
      'abstains on separate methods with isolated single else-if checks',
      () {
        const content = '''
void methodOne(Object? a) {
  if (a == null) {
    return;
  } else if (a is String) {
    print(a);
  }
}

void methodTwo(Object? b) {
  if (b == null) {
    return;
  } else if (b is int) {
    print(b);
  }
}
''';
        final file = File('test/isolated_separate_methods.dart');
        final context = PackageContext.load(Directory.current.path);
        expect(
          rule.checkFile(file, content, context),
          isNull,
          reason: 'Must not scan across separate method boundaries',
        );
      },
    );
  });
}
