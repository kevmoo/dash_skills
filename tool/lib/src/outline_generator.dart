import 'dart:io';
import 'package:path/path.dart' as p;

/// Generates a compact, token-efficient repository outline suitable for LLM
/// discovery probing (~1k-1.5k tokens).
class OutlineGenerator {
  final String packagePath;
  final String packageName;

  OutlineGenerator(this.packagePath) : packageName = p.basename(packagePath);

  /// Builds the markdown outline string.
  String generate({int maxSignatureLines = 250}) {
    final buffer = StringBuffer();
    buffer.writeln('# REPOSITORY OUTLINE: $packageName');
    buffer.writeln('Path: $packagePath\n');

    _appendPubspec(buffer);
    _appendDirectoryStructure(buffer);
    _appendStructuralSignatures(buffer, maxSignatureLines: maxSignatureLines);

    return buffer.toString();
  }

  void _appendPubspec(StringBuffer buffer) {
    final pubspecFile = File(p.join(packagePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      buffer.writeln('## 1. pubspec.yaml\n(No pubspec.yaml found)\n');
      return;
    }

    buffer.writeln('## 1. pubspec.yaml');
    final lines = pubspecFile.readAsLinesSync();
    var inDeps = false;
    for (final line in lines) {
      if (line.startsWith('name:') ||
          line.startsWith('environment:') ||
          line.startsWith('dependencies:') ||
          line.startsWith('dev_dependencies:')) {
        inDeps = true;
        buffer.writeln(line);
      } else if (inDeps) {
        if (line.startsWith(RegExp(r'^[a-z_]+:')) && !line.startsWith('sdk:')) {
          inDeps = false;
        } else {
          buffer.writeln(line);
        }
      }
    }
    buffer.writeln();
  }

  void _appendDirectoryStructure(StringBuffer buffer) {
    buffer.writeln('## 2. Directory Structure');
    final dir = Directory(packagePath);
    if (!dir.existsSync()) {
      buffer.writeln('  (Directory does not exist)\n');
      return;
    }

    final entries = <String>[];
    try {
      final list = dir.listSync(recursive: true, followLinks: false);
      for (final entity in list) {
        final relPath = p.relative(entity.path, from: packagePath);
        final parts = p.split(relPath);
        // Exclude hidden, build, and deeply nested paths
        if (parts.any((part) => part.startsWith('.') || part == 'build')) {
          continue;
        }
        if (parts.length <= 3) {
          entries.add(relPath);
        }
        if (entries.length >= 40) {
          break;
        }
      }
    } catch (_) {
      // Fallback
    }

    if (entries.isEmpty) {
      buffer.writeln('  (Empty or unreadable directory)');
    } else {
      for (final entry in entries) {
        buffer.writeln('  $entry');
      }
    }
    buffer.writeln();
  }

  void _appendStructuralSignatures(
    StringBuffer buffer, {
    required int maxSignatureLines,
  }) {
    buffer.writeln('## 3. Structural API & Code Signatures');
    final libDir = Directory(p.join(packagePath, 'lib'));
    if (!libDir.existsSync()) {
      buffer.writeln('  (No lib/ directory found)');
      return;
    }

    // Attempt sem entities first
    try {
      final semRun = Process.runSync('sem', [
        'entities',
        'lib/',
        '--signatures',
      ], workingDirectory: packagePath);
      if (semRun.exitCode == 0) {
        final raw = (semRun.stdout as String).split('\n');
        final trimmed = raw.take(maxSignatureLines).join('\n');
        buffer.writeln(trimmed);
        if (raw.length > maxSignatureLines) {
          buffer.writeln(
            '\n... [${raw.length - maxSignatureLines} signature lines truncated for token efficiency] ...',
          );
        }
        return;
      }
    } catch (_) {
      // sem not available on path
    }

    // Fallback: list top declarations in lib/*.dart files
    _appendFallbackSignatures(buffer, libDir, maxSignatureLines);
  }

  void _appendFallbackSignatures(
    StringBuffer buffer,
    Directory libDir,
    int maxLines,
  ) {
    var lineCount = 0;
    for (final file in libDir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final relPath = p.relative(file.path, from: packagePath);
      buffer.writeln('  $relPath:');
      try {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('class ') ||
              trimmed.startsWith('abstract class ') ||
              trimmed.startsWith('enum ') ||
              trimmed.startsWith('extension ') ||
              trimmed.startsWith('mixin ') ||
              trimmed.startsWith('typedef ')) {
            buffer.writeln('    $trimmed');
            lineCount++;
            if (lineCount >= maxLines) break;
          }
        }
      } catch (_) {}
      if (lineCount >= maxLines) {
        buffer.writeln('    ... [signatures truncated]');
        break;
      }
    }
  }
}
