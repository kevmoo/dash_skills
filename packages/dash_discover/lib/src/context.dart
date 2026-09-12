import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Cached evaluation context for a target Dart or Flutter package.
class PackageContext {
  final String packagePath;
  final String packageName;
  final String rawPubspec;
  final Map<String, dynamic> pubspecYaml;
  final List<File> libFiles;
  final List<File> testFiles;
  final List<File> binFiles;
  final Map<String, String> _contentCache = {};

  PackageContext._({
    required this.packagePath,
    required this.packageName,
    required this.rawPubspec,
    required this.pubspecYaml,
    required this.libFiles,
    required this.testFiles,
    required this.binFiles,
  });

  factory PackageContext.load(String targetPath) {
    final absPath = Directory(targetPath).absolute.path;
    final packageName = p.basename(absPath);

    final pubspecFile = File(p.join(absPath, 'pubspec.yaml'));
    var rawPubspec = '';
    var pubspecYaml = <String, dynamic>{};
    if (pubspecFile.existsSync()) {
      rawPubspec = pubspecFile.readAsStringSync();
      try {
        final yaml = loadYaml(rawPubspec);
        if (yaml is Map) {
          pubspecYaml = Map<String, dynamic>.from(yaml);
        }
      } catch (_) {}
    }

    final libDir = Directory(p.join(absPath, 'lib'));
    final libFiles = libDir.existsSync()
        ? libDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
              .toList()
        : <File>[];

    final testDir = Directory(p.join(absPath, 'test'));
    final testFiles = testDir.existsSync()
        ? testDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('_test.dart'))
              .toList()
        : <File>[];

    final binDir = Directory(p.join(absPath, 'bin'));
    final binFiles = binDir.existsSync()
        ? binDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
              .toList()
        : <File>[];

    return PackageContext._(
      packagePath: absPath,
      packageName: packageName,
      rawPubspec: rawPubspec,
      pubspecYaml: pubspecYaml,
      libFiles: libFiles,
      testFiles: testFiles,
      binFiles: binFiles,
    );
  }

  bool hasDependency(String name) {
    final deps = pubspecYaml['dependencies'];
    final devDeps = pubspecYaml['dev_dependencies'];
    return (deps is Map && deps.containsKey(name)) ||
        (devDeps is Map && devDeps.containsKey(name)) ||
        rawPubspec.contains('$name:');
  }

  String readContent(File file) {
    return _contentCache.putIfAbsent(file.path, () => file.readAsStringSync());
  }

  String relativePath(File file) => p.relative(file.path, from: packagePath);
}
