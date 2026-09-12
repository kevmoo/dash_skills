import 'dart:io';

import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying CLI entrypoints in `bin/` that use monolithic
/// ad-hoc `main()` functions instead of structured CLI architectures.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e/skills/dart-build-cli-app
final class CliAppRule extends DiscoveryRule {
  const CliAppRule();

  static final _mainFunctionPattern = RegExp(
    r'\bmain\s*\(\s*(?:List<String>\s+(\w+))?\s*\)',
  );

  @override
  String get id => 'build-cli-app';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'dart-lang',
    repo: 'skills',
    path: 'skills/dart-build-cli-app',
    commitSha: '26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e',
  );

  @override
  RuleCategory get category => RuleCategory.cli;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.architecture;

  @override
  String get description =>
      'Detects ad-hoc bin/*.dart CLI entrypoints lacking structured argument parsing.';

  @override
  Confidence get defaultConfidence => Confidence.high;

  @override
  bool appliesTo(PackageContext context) => context.binFiles.isNotEmpty;

  /// Checks a single file in `bin/` and returns matching diagnostic reason, or null.
  String? checkFile(File file, String content, PackageContext context) {
    // 1. Abstention: HTTP / Socket servers
    if (content.contains('HttpServer.bind') ||
        content.contains('shelf_io.serve') ||
        content.contains('ServerSocket.bind')) {
      return null;
    }

    // 2. Abstention: Zero-arg scripts (void main() without parameters)
    final mainMatch = _mainFunctionPattern.firstMatch(content);
    if (mainMatch == null) {
      return null;
    }
    final argName = mainMatch.group(1);
    if (argName == null) {
      // main() takes zero arguments: internal automation or task script
      return null;
    }

    // 3. Thin Trampoline Guardrail (<30 non-empty lines delegating to package library)
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).length;
    if (lines <= 30 && content.contains('package:${context.packageName}/')) {
      return null;
    }

    // 4. CommandRunner: idiomatic multi-command architecture
    if (content.contains('CommandRunner') ||
        content.contains('package:args/command_runner.dart')) {
      return null;
    }

    // 5. ArgParser: idiomatic single-command architecture
    final usesArgParser =
        content.contains('ArgParser') ||
        content.contains('package:args/args.dart');

    if (!usesArgParser) {
      return 'Ad-hoc CLI entrypoint without package:args';
    }

    // 6. Monolithic ArgParser in bin/ (>120 lines with exit or exitCode)
    if (lines > 120 &&
        (content.contains('exit(') || content.contains('exitCode ='))) {
      return 'Monolithic CLI entrypoint in bin/';
    }

    return null;
  }

  @override
  Iterable<Opportunity> evaluate(PackageContext context) sync* {
    if (!appliesTo(context)) return;

    final adHocFiles = <String>[];
    for (final file in context.binFiles) {
      final content = context.readContent(file);
      final check = checkFile(file, content, context);
      if (check != null) {
        adHocFiles.add(context.relativePath(file));
      }
    }

    if (adHocFiles.isNotEmpty) {
      yield Opportunity(
        target: target,
        category: category,
        lifecycle: lifecycle,
        confidence: defaultConfidence,
        affectedCount: adHocFiles.length,
        diagnosis:
            '${adHocFiles.length} CLI entrypoint(s) in bin/ use ad-hoc main() without structured argument parsing.',
        prescription:
            'Structure CLI with `package:args` (CommandRunner or ArgParser) for standardized flags, POSIX exit codes, and stdout/stderr separation.',
        evidence: adHocFiles,
      );
    }
  }
}
