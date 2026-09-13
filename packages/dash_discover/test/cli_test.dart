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
        expect(out.toString(), contains('--list-rules'));
        expect(err.toString(), isEmpty);
      },
    );

    test(
      'invalid option writes error and usage to stderr and returns ExitCode.usage',
      () async {
        final code = await runCli(['--unknown-flag'], stdout: out, stderr: err);

        expect(code, equals(ExitCode.usage.code));
        expect(
          err.toString(),
          contains('Could not find an option named "--unknown-flag".'),
        );
        expect(err.toString(), contains('Usage: dart run dash_discover'));
        expect(out.toString(), isEmpty);
      },
    );

    test(
      'non-existent target directory writes error to stderr and returns ExitCode.noInput',
      () async {
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
      },
    );

    test(
      '--list-rules outputs rule listing to stdout and returns ExitCode.success',
      () async {
        final code = await runCli(
          [repoRoot.path, '--list-rules'],
          stdout: out,
          stderr: err,
        );

        expect(code, equals(ExitCode.success.code));
        expect(out.toString(), contains('Available Discovery Rules'));
        expect(out.toString(), contains('checks-migration'));
        expect(out.toString(), contains('dart-seal-type-hierarchies'));
        expect(err.toString(), isEmpty);
      },
    );

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

    test(
      'valid discovery run with --outline-only emits repository outline to stdout',
      () async {
        final code = await runCli(
          [repoRoot.path, '--outline-only'],
          stdout: out,
          stderr: err,
        );

        expect(code, equals(ExitCode.success.code));
        expect(out.toString(), contains('REPOSITORY OUTLINE'));
        expect(err.toString(), isEmpty);
      },
    );

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
  });
}
