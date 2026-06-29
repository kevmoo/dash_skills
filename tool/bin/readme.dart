import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Writes the updated skills table to README.md.',
    )
    ..addFlag(
      'validate',
      negatable: false,
      help: 'Validates that README.md is up-to-date with the latest skills.',
    );

  final results = parser.parse(arguments);
  final writeMode = results['write'] as bool;
  final validateMode = results['validate'] as bool;

  final currentDir = Directory.current;
  final repoRoot = _findRepoRoot(currentDir);
  if (repoRoot == null) {
    print('Error: Could not find repository root containing skills');
    exit(1);
  }

  final repoName = p.basename(repoRoot.path);
  final repoSlug = 'kevmoo/$repoName';

  final skillsDir = Directory(p.join(repoRoot.path, 'skills'));
  if (!skillsDir.existsSync()) {
    print('Error: Skills directory does not exist at ${skillsDir.path}');
    exit(1);
  }

  final readmeFile = File(p.join(repoRoot.path, 'README.md'));
  if (!readmeFile.existsSync()) {
    print('Error: README.md not found at ${readmeFile.path}');
    exit(1);
  }

  final skillDirs =
      skillsDir
          .listSync()
          .whereType<Directory>()
          .where((dir) => File(p.join(dir.path, 'SKILL.md')).existsSync())
          .toList()
        ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

  final listBuffer = StringBuffer();
  listBuffer.writeln('<!-- SKILLS_LIST_START -->');
  listBuffer.writeln('To install any skill individually:');
  listBuffer.writeln('```bash');
  listBuffer.writeln('npx skills add $repoSlug --skill <skill-name>');
  listBuffer.writeln('```\n');
  listBuffer.writeln('| Skill | Description | Key Features |');
  listBuffer.writeln('|-------|-------------|--------------|');
  for (final dir in skillDirs) {
    final skillName = p.basename(dir.path);
    final skillFile = File(p.join(dir.path, 'SKILL.md'));
    final content = skillFile.readAsStringSync();

    final frontMatter = _parseFrontMatter(content);
    final title =
        frontMatter['name'] as String? ?? _getSkillTitle(content, skillName);
    final description = frontMatter['description'] as String? ?? '';
    final keyFeaturesRaw = frontMatter['key_features'];
    final List<String> keyFeatures = [];
    if (keyFeaturesRaw is List) {
      keyFeatures.addAll(keyFeaturesRaw.map((e) => e.toString()));
    } else if (keyFeaturesRaw is String) {
      keyFeatures.add(keyFeaturesRaw);
    }

    if (title.toLowerCase().contains('deprecated') ||
        description.toLowerCase().startsWith('deprecated')) {
      continue;
    }

    final cleanDescription = LineSplitter.split(
      description.trim(),
    ).map((line) => line.trim()).join(' ').replaceAll('|', '\\|');

    final cleanFeatures = keyFeatures.join(', ').replaceAll('|', '\\|');

    listBuffer.writeln(
      '| **[$title](skills/$skillName/SKILL.md)** | $cleanDescription | $cleanFeatures |',
    );
  }
  listBuffer.write('<!-- SKILLS_LIST_END -->');

  final generatedTable = listBuffer.toString();

  final readmeContent = readmeFile.readAsStringSync();
  final startTag = '<!-- SKILLS_LIST_START -->';
  final endTag = '<!-- SKILLS_LIST_END -->';

  final startIndex = readmeContent.indexOf(startTag);
  final endIndex = readmeContent.indexOf(endTag);

  if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
    print(
      'Error: Could not find comments <!-- SKILLS_LIST_START --> and <!-- SKILLS_LIST_END --> in correct order in README.md',
    );
    exit(1);
  }

  final updatedReadme = readmeContent.replaceRange(
    startIndex,
    endIndex + endTag.length,
    generatedTable,
  );

  if (validateMode) {
    final normalizedReadme = readmeContent.replaceAll('\r\n', '\n');
    final normalizedUpdated = updatedReadme.replaceAll('\r\n', '\n');
    if (normalizedReadme == normalizedUpdated) {
      print('README.md is up-to-date!');
      exit(0);
    } else {
      print('Error: README.md is out-of-date.');
      print('Run `dart tool/bin/readme.dart --write` to update it.');
      exit(1);
    }
  }

  if (writeMode) {
    readmeFile.writeAsStringSync(updatedReadme);
    print('Successfully updated README.md with the latest skills!');
  } else {
    print('--- Generated Skills Table ---');
    print(generatedTable);
    print('------------------------------');
    print('Run with --write (or -w) to save changes to README.md.');
  }
}

Directory? _findRepoRoot(Directory startDir) {
  var dir = startDir;
  while (true) {
    if (Directory(p.join(dir.path, 'skills')).existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  return null;
}

Map<dynamic, dynamic> _parseFrontMatter(String content) {
  final trimmed = content.trimLeft();
  if (!trimmed.startsWith('---')) return {};
  final regExp = RegExp(r'^---\s*$', multiLine: true);
  final matches = regExp.allMatches(trimmed).toList();
  if (matches.length < 2) return {};
  final secondTripleDash = matches[1].start;
  final yamlText = trimmed.substring(matches[0].end, secondTripleDash);
  try {
    final yamlMap = loadYaml(yamlText);
    if (yamlMap is Map) return yamlMap;
  } catch (_) {}
  return {};
}

String _getSkillTitle(String content, String fallback) {
  final lines = LineSplitter.split(content);
  for (final line in lines) {
    if (line.startsWith('# ')) {
      return line.substring(2).trim();
    }
  }
  return fallback
      .split('-')
      .map(
        (word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
