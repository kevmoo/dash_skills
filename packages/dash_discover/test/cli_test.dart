import 'dart:convert';
import 'dart:io';

import 'package:dash_discover/dash_discover.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _findRepoRoot(Directory start) {
  var dir = start.absolute;
  while (dir.path != dir.parent.path) {
    if (Directory(p.join(dir.path, 'skills')).existsSync()) {
      return dir;
    }
    dir = dir.parent;
  }
  return start;
}

void main() {
  final repoRoot = _findRepoRoot(Directory.current);

  group('CLI in-memory unit tests', () {
    late StringBuffer out;
    late StringBuffer err;

    setUp(() {
      out = StringBuffer();
      err = StringBuffer();
    });

    test(
      '--help outputs usage to stdout and returns ExitCode.success',
      () async {
        final code = await runCli(['--help'], stdout: out, stderr: err);

        expect(code, equals(ExitCode.success.code));
        expect(out.toString(), contains('Usage: dart run dash_discover'));
        expect(out.toString(), contains('--json'));
        expect(out.toString(), contains('--include-alternatives'));
        expect(out.toString(), contains('--list-rules'));
        expect(err.toString(), isEmpty);
      },
    );

    test('invalid option writes error and usage to stderr and returns '
        'ExitCode.usage', () async {
      final code = await runCli(['--unknown-flag'], stdout: out, stderr: err);

      expect(code, equals(ExitCode.usage.code));
      expect(
        err.toString(),
        contains('Could not find an option named "--unknown-flag".'),
      );
      expect(err.toString(), contains('Usage: dart run dash_discover'));
      expect(out.toString(), isEmpty);
    });

    test('non-existent target directory writes error to stderr and returns '
        'ExitCode.noInput', () async {
      final nonExistent = p.join(
        Directory.systemTemp.path,
        'non_existent_dir_12345',
      );
      final code = await runCli([nonExistent], stdout: out, stderr: err);

      expect(code, equals(ExitCode.noInput.code));
      expect(
        err.toString(),
        contains('Error: Target directory does not exist:'),
      );
      expect(out.toString(), isEmpty);
    });

    test('--list-rules outputs rule listing to stdout and returns '
        'ExitCode.success', () async {
      final code = await runCli(
        [repoRoot.path, '--list-rules'],
        stdout: out,
        stderr: err,
      );

      expect(code, equals(ExitCode.success.code));
      expect(out.toString(), contains('Available Discovery Rules'));
      expect(out.toString(), contains('checks-migration'));
      expect(out.toString(), contains('dart-seal-type-hierarchies'));
      expect(out.toString(), contains('Trigger:     Defect'));
      expect(out.toString(), contains('Trigger:     Capability'));
      expect(out.toString(), contains('Trigger:     Alternative'));
      expect(err.toString(), isEmpty);
    });

    test(
      'unmatched rule filter writes error to stderr and returns ExitCode.usage',
      () async {
        final code = await runCli(
          [repoRoot.path, '--rule', 'non-existent-rule-id'],
          stdout: out,
          stderr: err,
        );

        expect(code, equals(ExitCode.usage.code));
        expect(
          err.toString(),
          contains('Error: No rules match the specified filters.'),
        );
        expect(err.toString(), contains('Available rules:'));
        expect(out.toString(), isEmpty);
      },
    );

    test('valid discovery run emits Markdown report to stdout', () async {
      final code = await runCli(
        [repoRoot.path, '--rule', 'seal-type-hierarchies'],
        stdout: out,
        stderr: err,
      );

      expect(code, equals(ExitCode.success.code));
      expect(out.toString(), contains('Meta-Skill Discovery Report'));
      expect(err.toString(), isEmpty);
    });

    test('valid discovery run with --json emits JSON to stdout', () async {
      final code = await runCli(
        [repoRoot.path, '--rule', 'seal-type-hierarchies', '--json'],
        stdout: out,
        stderr: err,
      );

      expect(code, equals(ExitCode.success.code));
      final decoded = jsonDecode(out.toString()) as Map<String, dynamic>;
      expect(decoded, containsPair('package_name', isNotEmpty));
      expect(decoded, contains('static_opportunities'));
      expect(err.toString(), isEmpty);
    });

    test('valid discovery run with --outline-only emits repository outline '
        'to stdout', () async {
      final code = await runCli(
        [repoRoot.path, '--outline-only'],
        stdout: out,
        stderr: err,
      );

      expect(code, equals(ExitCode.success.code));
      expect(out.toString(), contains('REPOSITORY OUTLINE'));
      expect(err.toString(), isEmpty);
    });

    test(
      'valid discovery run with --prompt-only emits probe prompt to stdout',
      () async {
        final code = await runCli(
          [repoRoot.path, '--prompt-only'],
          stdout: out,
          stderr: err,
        );

        expect(code, equals(ExitCode.success.code));
        expect(out.toString(), contains('Meta Skill Discovery Engine'));
        expect(err.toString(), isEmpty);
      },
    );

    group('trigger filtering and --include-alternatives', () {
      late Directory samplePkg;

      setUp(() {
        samplePkg = Directory.systemTemp.createTempSync('cli_trigger_test_');
        File(p.join(samplePkg.path, 'pubspec.yaml')).writeAsStringSync('''
name: cli_trigger_sample
environment:
  sdk: ^3.5.0
dev_dependencies:
  test: ^1.25.0
''');
        final libDir = Directory(p.join(samplePkg.path, 'lib'))..createSync();
        File(p.join(libDir.path, 'sample.dart')).writeAsStringSync(r'''
String buildPath(String root, Object item) {
  if (item is int) {
    return '$root/int.txt';
  } else if (item is String) {
    return '$root/$item';
  }
  return '$root/default.txt';
}
''');
        final testDir = Directory(p.join(samplePkg.path, 'test'))..createSync();
        File(p.join(testDir.path, 'sample_test.dart')).writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('checks', () {
    final values = [1, 2];
    expect(values.length, 2);
  });
}
''');
      });

      tearDown(() {
        samplePkg.deleteSync(recursive: true);
      });

      test('suppresses alternative rules by default', () async {
        final code = await runCli(
          [samplePkg.path, '--json'],
          stdout: out,
          stderr: err,
        );

        expect(code, equals(ExitCode.success.code));
        expect(err.toString(), isEmpty);
        final decoded = jsonDecode(out.toString()) as Map<String, dynamic>;
        final opps = (decoded['static_opportunities'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        expect(
          opps.map((o) => o['skill']).toList(),
          equals(['dart-use-path-package']),
        );
        expect(opps.single['trigger'], equals('defect'));
        expect(opps.single['trigger_label'], equals('Defect'));
      });

      test('includes alternative rules with --include-alternatives', () async {
        final code = await runCli(
          [samplePkg.path, '--include-alternatives', '--json'],
          stdout: out,
          stderr: err,
        );

        expect(code, equals(ExitCode.success.code));
        expect(err.toString(), isEmpty);
        final decoded = jsonDecode(out.toString()) as Map<String, dynamic>;
        final skills = (decoded['static_opportunities'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((o) => o['skill'])
            .toSet();
        expect(
          skills,
          equals({
            'dart-use-path-package',
            'dart-migrate-to-checks-package',
            'dart-use-pattern-matching',
            'dart-matcher-best-practices',
          }),
        );
      });

      test('explicit --rule runs an alternative rule without '
          '--include-alternatives', () async {
        final code = await runCli(
          [samplePkg.path, '--rule', 'checks-migration', '--json'],
          stdout: out,
          stderr: err,
        );

        expect(code, equals(ExitCode.success.code));
        expect(err.toString(), isEmpty);
        final decoded = jsonDecode(out.toString()) as Map<String, dynamic>;
        final opps = (decoded['static_opportunities'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        expect(opps, hasLength(1));
        expect(opps.single['skill'], equals('dart-migrate-to-checks-package'));
        expect(opps.single['trigger'], equals('alternative'));
      });

      test('--lifecycle hygiene without --include-alternatives hints about '
          'suppressed alternative rules', () async {
        final code = await runCli(
          [samplePkg.path, '--lifecycle', 'hygiene'],
          stdout: out,
          stderr: err,
        );

        expect(code, equals(ExitCode.usage.code));
        expect(
          err.toString(),
          contains('Error: No rules match the specified filters.'),
        );
        expect(err.toString(), contains('matcher-best-practices'));
        expect(err.toString(), contains('--include-alternatives'));
        expect(out.toString(), isEmpty);
      });

      test(
        '--lifecycle hygiene with --include-alternatives runs hygiene rules',
        () async {
          final code = await runCli(
            [
              samplePkg.path,
              '--lifecycle',
              'hygiene',
              '--include-alternatives',
              '--json',
            ],
            stdout: out,
            stderr: err,
          );

          expect(code, equals(ExitCode.success.code));
          expect(err.toString(), isEmpty);
          final decoded = jsonDecode(out.toString()) as Map<String, dynamic>;
          final opps = (decoded['static_opportunities'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          expect(
            opps.map((o) => o['skill']).toList(),
            equals(['dart-matcher-best-practices']),
          );
        },
      );

      test('Markdown output renders Trigger field', () async {
        final code = await runCli([samplePkg.path], stdout: out, stderr: err);

        expect(code, equals(ExitCode.success.code));
        expect(out.toString(), contains('- **Trigger**: Defect'));
        expect(err.toString(), isEmpty);
      });
    });
  });
}
