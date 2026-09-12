import 'dart:io';
import 'context.dart';
import 'models.dart';

/// Base contract for a discovery rule aligning project signals with an upstream skill.
abstract class DiscoveryRule {
  const DiscoveryRule();

  /// Unique machine identifier for this rule (e.g. `checks-migration`).
  String get id;

  /// The exact upstream GitHub skill target this rule aligns with.
  SkillTarget get target;

  /// Architectural category (e.g. 'Testing Architecture', 'Dart 3 Language Idioms').
  String get category;

  /// Default recommendation priority.
  Priority get defaultPriority;

  /// Fast precondition check before running full evaluation.
  bool appliesTo(PackageContext context) => true;

  /// Evaluates the package and yields any discovered modernization opportunities.
  Iterable<Opportunity> evaluate(PackageContext context);
}

/// A discovery rule that evaluates source files in a single pass.
abstract class FileDiscoveryRule extends DiscoveryRule {
  const FileDiscoveryRule();

  /// Returns matching evidence string if the file triggers this rule, or null.
  String? checkFile(File file, String content, PackageContext context);

  /// Target files to inspect: defaults to `context.libFiles`.
  List<File> selectFiles(PackageContext context) => context.libFiles;

  String get diagnosisTemplate;
  String get prescription;

  @override
  Iterable<Opportunity> evaluate(PackageContext context) sync* {
    final matchedFiles = <String>[];
    for (final file in selectFiles(context)) {
      final content = context.readContent(file);
      final match = checkFile(file, content, context);
      if (match != null) {
        matchedFiles.add(context.relativePath(file));
      }
    }

    if (matchedFiles.isNotEmpty) {
      yield Opportunity(
        target: target,
        category: category,
        priority: defaultPriority,
        diagnosis: diagnosisTemplate.replaceAll(
          '{count}',
          '${matchedFiles.length}',
        ),
        prescription: prescription,
        evidence: matchedFiles.take(4).toList(),
      );
    }
  }
}
