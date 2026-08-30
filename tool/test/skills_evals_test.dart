import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _getRepoRoot() {
  return Directory.current.path.endsWith('tool')
      ? Directory.current.parent
      : Directory.current;
}

List<File> _findEvalsFiles(Directory baseDir) {
  if (!baseDir.existsSync()) {
    return [];
  }
  return baseDir.listSync(recursive: true).whereType<File>().where((File f) {
    final String name = p.basename(f.path);
    return name == 'evals.json' || name.endsWith('_evals.json');
  }).toList();
}

void _verifyStructuralConsistency(List<File> files, String itemsKey) {
  Set<String>? expectedRootKeys;
  String? expectedRootKeysFilePath;
  Set<String>? expectedItemKeys;
  String? expectedItemFilePath;

  for (final file in files) {
    final Object? decoded = jsonDecode(file.readAsStringSync());
    final Map<String, dynamic> decodedMap = switch (decoded) {
      final Map<String, dynamic> map => map,
      _ => fail('${file.path} must be a JSON map.'),
    };
    final Set<String> rootKeys = decodedMap.keys.toSet();
    if (expectedRootKeys == null) {
      expectedRootKeys = rootKeys;
      expectedRootKeysFilePath = file.path;
    } else {
      expect(
        rootKeys,
        equals(expectedRootKeys),
        reason:
            '${file.path} root keys do not match consistency pattern. '
            'Expected keys to match the first processed file ($expectedRootKeysFilePath).',
      );
    }

    final Object? itemsRaw = decodedMap[itemsKey];
    final List<dynamic> itemsList = switch (itemsRaw) {
      final List<dynamic> list => list,
      _ => fail('$itemsKey key in ${file.path} must be a List.'),
    };
    for (final Object? item in itemsList) {
      final Map<String, dynamic> itemMap = switch (item) {
        final Map<String, dynamic> map => map,
        _ => fail('Item in $itemsKey list in ${file.path} must be a JSON map.'),
      };
      final Set<String> itemKeys = itemMap.keys.toSet();
      if (expectedItemKeys == null) {
        expectedItemKeys = itemKeys;
        expectedItemFilePath = file.path;
      } else {
        expect(
          itemKeys,
          equals(expectedItemKeys),
          reason:
              'Item in ${file.path} keys do not match consistency pattern. '
              'Expected item keys to match the first processed file ($expectedItemFilePath).',
        );
      }
    }
  }
}

void main() {
  group('Evals structure consistency', () {
    test(
      'all evals.json files across skills share consistent structure and keys',
      () {
        final repoRoot = _getRepoRoot();
        final List<File> evalsFiles = [
          ..._findEvalsFiles(Directory(p.join(repoRoot.path, 'skills'))),
          ..._findEvalsFiles(Directory(p.join(repoRoot.path, 'evals'))),
        ]..sort((a, b) => a.path.compareTo(b.path));

        expect(
          evalsFiles,
          isNotEmpty,
          reason:
              'Should find at least one evals.json file in skills or evals.',
        );

        _verifyStructuralConsistency(evalsFiles, 'evals');
      },
    );

    test('all published skills with evals have an evals.json file', () {
      final repoRoot = _getRepoRoot();
      final skillsDir = Directory(p.join(repoRoot.path, 'skills'));
      if (!skillsDir.existsSync()) {
        return;
      }

      final List<Directory> skillDirsWithEvals = skillsDir
          .listSync()
          .whereType<Directory>()
          .where((dir) => Directory(p.join(dir.path, 'evals')).existsSync())
          .toList();

      expect(
        skillDirsWithEvals,
        isNotEmpty,
        reason: 'Expected at least one published skill to define evals.',
      );

      for (final skillDir in skillDirsWithEvals) {
        final evalsFile = File(p.join(skillDir.path, 'evals', 'evals.json'));
        expect(
          evalsFile.existsSync(),
          isTrue,
          reason:
              'Published skill "${p.basename(skillDir.path)}" has an evals directory but is missing an evals.json file at ${evalsFile.path}',
        );
      }
    });

    test(
      'all referenced rubrics in evals.json exist and have valid structure',
      () {
        final repoRoot = _getRepoRoot();
        final List<File> evalsFiles = [
          ..._findEvalsFiles(Directory(p.join(repoRoot.path, 'skills'))),
          ..._findEvalsFiles(Directory(p.join(repoRoot.path, 'evals'))),
        ];

        expect(evalsFiles, isNotEmpty);

        for (final file in evalsFiles) {
          final Object? decoded = jsonDecode(file.readAsStringSync());
          final Map<String, dynamic> decodedMap = switch (decoded) {
            final Map<String, dynamic> map => map,
            _ => fail('${file.path} must be a JSON map.'),
          };

          final Object? repoCriteriaRaw = decodedMap['repo_criteria'];
          if (repoCriteriaRaw == null) {
            continue;
          }

          final List<dynamic> repoCriteriaList = switch (repoCriteriaRaw) {
            final List<dynamic> list => list,
            _ => fail('repo_criteria in ${file.path} must be a List.'),
          };

          for (final Object? rubricPath in repoCriteriaList) {
            expect(rubricPath, isA<String>());
            final rubricFile = File(
              p.join(repoRoot.path, rubricPath as String),
            );
            expect(
              rubricFile.existsSync(),
              isTrue,
              reason:
                  'Referenced rubric "$rubricPath" in ${file.path} does not exist at ${rubricFile.path}',
            );

            final Object? rubricDecoded = jsonDecode(
              rubricFile.readAsStringSync(),
            );
            final Map<String, dynamic> rubricMap = switch (rubricDecoded) {
              final Map<String, dynamic> map => map,
              _ => fail('${rubricFile.path} must be a JSON map.'),
            };
            expect(
              rubricMap['evals'],
              isA<List<dynamic>>(),
              reason: '${rubricFile.path} must contain an "evals" array.',
            );
          }
        }
      },
    );

    test(
      'all rubric JSON files in evals/ share consistent structure and keys',
      () {
        final repoRoot = _getRepoRoot();
        final rubricsDir = Directory(p.join(repoRoot.path, 'evals'));
        if (!rubricsDir.existsSync()) {
          return;
        }

        final List<File> rubricFiles =
            rubricsDir
                .listSync()
                .whereType<File>()
                .where(
                  (File f) =>
                      f.path.endsWith('.json') &&
                      !f.path.endsWith('_evals.json'),
                )
                .toList()
              ..sort((a, b) => a.path.compareTo(b.path));

        if (rubricFiles.isEmpty) {
          return;
        }

        _verifyStructuralConsistency(rubricFiles, 'evals');
      },
    );
  });
}
