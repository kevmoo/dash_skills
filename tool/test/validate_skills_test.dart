import 'dart:io';

import 'package:dart_skills_lint/dart_skills_lint.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

void main() {
  test('Validate skills', () async {
    Logger.root.level = Level.ALL;
    final subscription = Logger.root.onRecord.listen((record) {
      print(record.message);
    });

    final originalDir = Directory.current;
    final parts = p.split(originalDir.path);
    final isRoot = !(parts.isNotEmpty && parts.last == 'tool');
    if (isRoot) {
      Directory.current = Directory('tool');
    }

    try {
      final config = await ConfigParser.loadConfig();
      expect(
        config.directoryConfigs,
        isNotEmpty,
        reason: 'Configuration directoryConfigs should not be empty.',
      );

      final isValid = await validateSkills(config: config);
      expect(
        isValid,
        isTrue,
        reason: 'Skills validation failed. See above for details.',
      );
    } finally {
      if (isRoot) {
        Directory.current = originalDir;
      }
      await subscription.cancel();
    }
  });

  test('Run skill/scripts/test', () async {
    final skillsDir = Directory(
      Directory.current.path.endsWith('tool') ? '../skills' : 'skills',
    );
    expect(
      skillsDir.existsSync(),
      isTrue,
      reason: 'Skills directory not found at ${skillsDir.path}',
    );

    final skillDirs = skillsDir.listSync().whereType<Directory>();
    for (final dir in skillDirs) {
      final scriptsDir = Directory('${dir.path}/scripts');
      if (scriptsDir.existsSync() &&
          File('${scriptsDir.path}/pubspec.yaml').existsSync()) {
        print('Running tests in ${scriptsDir.path}');

        final packageConfig = File(
          '${scriptsDir.path}/.dart_tool/package_config.json',
        );
        if (!packageConfig.existsSync()) {
          final pubGetProcess = await TestProcess.start(
            Platform.resolvedExecutable,
            ['pub', 'get'],
            workingDirectory: scriptsDir.path,
          );
          await pubGetProcess.shouldExit(0);
        }

        final process = await TestProcess.start(Platform.resolvedExecutable, [
          'test',
        ], workingDirectory: scriptsDir.path);
        await process.shouldExit(0);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test(
    'Verify formatting and analysis of all skills Dart code',
    () async {
      final skillsDir = Directory(
        Directory.current.path.endsWith('tool') ? '../skills' : 'skills',
      );
      expect(
        skillsDir.existsSync(),
        isTrue,
        reason: 'Skills directory not found at ${skillsDir.path}',
      );

      final formatProcess = await TestProcess.start(
        Platform.resolvedExecutable,
        ['format', '--output=none', '--set-exit-if-changed', skillsDir.path],
      );
      await formatProcess.shouldExit(0);

      // Ensure pub get has been run for all nested packages to prevent analysis failures
      final pubspecs = <File>[];
      for (final dir in skillsDir.listSync().whereType<Directory>().where(
        (dir) => File('${dir.path}/SKILL.md').existsSync(),
      )) {
        final pubspec = File('${dir.path}/pubspec.yaml');
        if (pubspec.existsSync()) {
          pubspecs.add(pubspec);
        }
        final scriptsPubspec = File('${dir.path}/scripts/pubspec.yaml');
        if (scriptsPubspec.existsSync()) {
          pubspecs.add(scriptsPubspec);
        }
      }
      for (final pubspec in pubspecs) {
        final packageConfig = File(
          '${pubspec.parent.path}/.dart_tool/package_config.json',
        );
        if (!packageConfig.existsSync()) {
          final process = await TestProcess.start(Platform.resolvedExecutable, [
            'pub',
            'get',
          ], workingDirectory: pubspec.parent.path);
          await process.shouldExit(0);
        }
      }

      final analyzeProcess = await TestProcess.start(
        Platform.resolvedExecutable,
        ['analyze', '--fatal-infos', skillsDir.path],
      );
      await analyzeProcess.shouldExit(0);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
