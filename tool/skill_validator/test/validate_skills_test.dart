import 'dart:io';
import 'package:dart_skills_lint/dart_skills_lint.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  test('Validate skills', () async {
    Logger.root.level = Level.ALL;
    final subscription = Logger.root.onRecord.listen((record) {
      print(record.message);
    });

    try {
      final isValid = await validateSkills(
        skillDirPaths: ['../../.agent/skills'],
        resolvedRules: {
          'check-relative-paths': AnalysisSeverity.error,
          'check-absolute-paths': AnalysisSeverity.error,
          'check-trailing-whitespace': AnalysisSeverity.error,
        },
      );
      expect(
        isValid,
        isTrue,
        reason: 'Skills validation failed. See above for details.',
      );
    } finally {
      await subscription.cancel();
    }
  });

  test('Run skill/scripts/test', () {
    final skillsDir = Directory('../../.agent/skills');
    if (!skillsDir.existsSync()) return;

    final skillDirs = skillsDir.listSync().whereType<Directory>();
    for (final dir in skillDirs) {
      final scriptsDir = Directory('${dir.path}/scripts');
      if (scriptsDir.existsSync() &&
          File('${scriptsDir.path}/pubspec.yaml').existsSync()) {
        print('Running tests in ${scriptsDir.path}');

        // Run pub get first to ensure dependencies are resolved
        Process.runSync(
          'dart',
          ['pub', 'get'],
          workingDirectory: scriptsDir.path,
        );

        final result = Process.runSync(
          'dart',
          ['test'],
          workingDirectory: scriptsDir.path,
        );
        print(result.stdout);
        print(result.stderr);
        expect(result.exitCode, 0,
            reason: 'Tests failed in ${scriptsDir.path}');
      }
    }
  });
}
