import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class SkillMetadata {
  final String name;
  final String description;
  final List<String> keyFeatures;
  final String skillPath;

  const SkillMetadata({
    required this.name,
    required this.description,
    required this.keyFeatures,
    required this.skillPath,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'key_features': keyFeatures,
    'path': skillPath,
  };
}

class SkillsCatalog {
  final List<SkillMetadata> skills;
  final Map<String, SkillMetadata> _byName;

  SkillsCatalog(this.skills) : _byName = {for (final s in skills) s.name: s};

  SkillMetadata? findByName(String name) => _byName[name];

  factory SkillsCatalog.discover({
    List<String>? searchPaths,
    Directory? workingDirectory,
  }) {
    final paths = searchPaths != null
        ? List<String>.from(searchPaths)
        : <String>[];
    if (paths.isEmpty) {
      void addIfDirExists(String dirPath) {
        if (!paths.contains(dirPath) && Directory(dirPath).existsSync()) {
          paths.add(dirPath);
        }
      }

      void scanDirectoryAncestors(Directory start) {
        var dir = start.absolute;
        while (dir.path != dir.parent.path) {
          addIfDirExists(p.join(dir.path, 'skills'));
          addIfDirExists(p.join(dir.path, '.agents', 'skills'));
          dir = dir.parent;
        }
      }

      final targetDir = (workingDirectory ?? Directory.current).absolute;
      scanDirectoryAncestors(targetDir);

      final currentDir = Directory.current.absolute;
      if (currentDir.path != targetDir.path) {
        scanDirectoryAncestors(currentDir);
      }

      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null) {
        addIfDirExists(p.join(home, '.agents', 'skills'));
      }
    }

    final discovered = <String, SkillMetadata>{};

    for (final searchPath in paths) {
      final dir = Directory(searchPath);
      if (!dir.existsSync()) continue;

      for (final sub in dir.listSync().whereType<Directory>()) {
        final skillFile = File(p.join(sub.path, 'SKILL.md'));
        if (!skillFile.existsSync()) continue;

        try {
          final content = skillFile.readAsStringSync();
          final meta = _parseSkillFile(
            p.basename(sub.path),
            content,
            skillFile.path,
          );
          if (meta != null) {
            // First search path wins (preserves search order priority)
            discovered.putIfAbsent(meta.name, () => meta);
          }
        } catch (_) {
          // Ignore invalid files
        }
      }
    }

    final sorted = discovered.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return SkillsCatalog(sorted);
  }

  static SkillMetadata? _parseSkillFile(
    String fallbackName,
    String content,
    String filePath,
  ) {
    if (!content.startsWith('---')) return null;
    final endFrontmatter = content.indexOf('\n---', 3);
    if (endFrontmatter == -1) return null;

    final yamlStr = content.substring(3, endFrontmatter);
    final yaml = loadYaml(yamlStr);
    if (yaml is! Map) return null;

    final name = (yaml['name'] as String?) ?? fallbackName;
    final description =
        (yaml['description'] as String?)?.replaceAll('\n', ' ').trim() ?? '';
    final rawFeatures = yaml['key_features'];
    final keyFeatures = <String>[];
    if (rawFeatures is List) {
      for (final item in rawFeatures) {
        if (item != null) keyFeatures.add(item.toString());
      }
    }

    return SkillMetadata(
      name: name,
      description: description,
      keyFeatures: keyFeatures,
      skillPath: filePath,
    );
  }

  /// Formats the skills catalog for inclusion in an LLM probe prompt.
  String formatForPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('### AVAILABLE SKILLS CATALOG (${skills.length} skills):');
    for (final skill in skills) {
      buffer.writeln('- **${skill.name}**: ${skill.description}');
    }
    return buffer.toString();
  }
}
