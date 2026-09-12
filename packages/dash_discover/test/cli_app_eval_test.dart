import 'dart:io';

import 'package:dash_discover/src/context.dart';
import 'package:dash_discover/src/rules/cli_app_rule.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CliAppRule Heuristic Evaluation', () {
    const rule = CliAppRule();
    final fixturesDir = Directory(
      p.join(Directory.current.path, 'test', 'fixtures', 'cli_app'),
    );

    test('flagged on positive ad-hoc fixture (Recall)', () {
      final file = File(p.join(fixturesDir.path, 'positive_ad_hoc.dart'));
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(
        result,
        isNotNull,
        reason: 'Must detect ad-hoc CLI argument handling without package:args',
      );
    });

    test('abstains on CommandRunner fixture (Precision)', () {
      final file = File(
        p.join(fixturesDir.path, 'negative_command_runner.dart'),
      );
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(
        result,
        isNull,
        reason: 'Must not flag entrypoints already using CommandRunner',
      );
    });

    test('abstains on valid ArgParser single-command fixture (Precision)', () {
      final file = File(p.join(fixturesDir.path, 'negative_arg_parser.dart'));
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(
        result,
        isNull,
        reason: 'Must not flag concise single-command ArgParser entrypoints',
      );
    });

    test('abstains on thin entrypoint trampoline (Precision)', () {
      final file = File(
        p.join(fixturesDir.path, 'negative_thin_trampoline.dart'),
      );
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(
        result,
        isNull,
        reason:
            'Must not flag thin entrypoint delegating to package implementation',
      );
    });

    test('abstains on HTTP server entrypoint (Abstention Guardrails)', () {
      final file = File(p.join(fixturesDir.path, 'negative_abstention.dart'));
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(
        result,
        isNull,
        reason: 'Must abstain on backend HTTP server entrypoints',
      );
    });

    test('abstains on zero-argument utility scripts', () {
      const content = '''
void main() {
  print('Running generation task...');
}
''';
      final file = File('bin/gen.dart');
      final context = PackageContext.load(Directory.current.path);
      expect(rule.checkFile(file, content, context), isNull);
    });
  });
}
