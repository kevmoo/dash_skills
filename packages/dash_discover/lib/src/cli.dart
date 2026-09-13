import 'dart:convert';
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:io/io.dart';

import '../dash_discover.dart';

/// Builds the command-line argument parser for `dash_discover`.
ArgParser buildArgParser() => ArgParser()
  ..addFlag('json', negatable: false, help: 'Output results in JSON format.')
  ..addFlag(
    'outline-only',
    negatable: false,
    help: 'Output only the generated token-efficient outline.',
  )
  ..addFlag(
    'prompt-only',
    negatable: false,
    help: 'Output only the assembled LLM probe prompt.',
  )
  ..addOption(
    'rule',
    abbr: 'r',
    help:
        'Run only a specific rule by ID (e.g. checks-migration, pattern-matching).',
  )
  ..addOption(
    'category',
    abbr: 'c',
    allowed: RuleCategory.values.map((c) => c.name).toList(),
    help: 'Filter rules by category.',
  )
  ..addOption(
    'lifecycle',
    abbr: 'l',
    allowed: SkillLifecycle.values.map((l) => l.name).toList(),
    help: 'Filter rules by skill lifecycle (migration, hygiene, architecture).',
  )
  ..addFlag(
    'list-rules',
    negatable: false,
    help: 'List all available discovery rules and their upstream targets.',
  )
  ..addOption(
    'skills-dir',
    help: 'Optional directory path containing skills to catalog.',
  )
  ..addFlag(
    'update-skill',
    negatable: false,
    help: 'Updates the discovery rules block in skills/dash-discover/SKILL.md.',
  )
  ..addFlag(
    'validate-skill',
    negatable: false,
    help:
        'Validates that skills/dash-discover/SKILL.md is in sync with registered rules.',
  )
  ..addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Show usage information.',
  );

/// Executes the `dash_discover` CLI entrypoint with the given [args].
///
/// Accepts optional [stdout] and [stderr] sinks to facilitate fast in-memory
/// unit testing without spawning OS subprocesses.
Future<int> runCli(
  List<String> args, {
  StringSink? stdout,
  StringSink? stderr,
}) async {
  final out = stdout ?? io.stdout;
  final err = stderr ?? io.stderr;
  final parser = buildArgParser();

  final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    err.writeln('Error: ${e.message}\n');
    err.writeln(
      'Usage: dart run dash_discover [path-to-target-package] [options]\n',
    );
    err.writeln(parser.usage);
    return ExitCode.usage.code;
  }

  if (results.flag('help')) {
    out.writeln(
      'Usage: dart run dash_discover [path-to-target-package] [options]\n',
    );
    out.writeln(parser.usage);
    return ExitCode.success.code;
  }

  if (results.flag('update-skill') || results.flag('validate-skill')) {
    final skillFile = findSkillFile();
    if (skillFile == null) {
      err.writeln('Error: Could not find skills/dash-discover/SKILL.md');
      return ExitCode.config.code;
    }
    final content = skillFile.readAsStringSync();
    final updated = updateSkillContent(content);
    if (results.flag('validate-skill')) {
      if (content == updated) {
        out.writeln('skills/dash-discover/SKILL.md is up-to-date!');
        return ExitCode.success.code;
      } else {
        err.writeln('Error: skills/dash-discover/SKILL.md is out of date.');
        err.writeln(
          'Run `dart run dash_discover --update-skill` to update it.',
        );
        return ExitCode.data.code;
      }
    }
    if (results.flag('update-skill')) {
      skillFile.writeAsStringSync(updated);
      out.writeln(
        'Successfully updated ${skillFile.path} with the latest rules!',
      );
      return ExitCode.success.code;
    }
  }

  final targetPath = results.rest.isNotEmpty ? results.rest.first : '.';
  final absPath = io.Directory(targetPath).absolute.path;

  if (!io.Directory(absPath).existsSync()) {
    err.writeln('Error: Target directory does not exist: $absPath');
    return ExitCode.noInput.code;
  }

  if (results.flag('list-rules')) {
    out.writeln(
      'Available Discovery Rules (${defaultDiscoveryRules.length}):\n',
    );
    final skillsDir = results.option('skills-dir');
    final catalog = SkillsCatalog.discover(
      searchPaths: skillsDir != null ? [skillsDir] : null,
      workingDirectory: io.Directory(absPath),
    );
    for (final rule in defaultDiscoveryRules) {
      out.writeln(
        '• ${rule.id} (${rule.category.label}) [${rule.lifecycle.label}]',
      );
      out.writeln('  Skill:       ${rule.target.skillName}');
      out.writeln('  Lifecycle:   ${rule.lifecycle.label}');
      out.writeln('  Category:    ${rule.category.label}');
      out.writeln(
        '  Confidence:  ${rule.defaultConfidence.name.toUpperCase()}',
      );
      out.writeln('  Description: ${rule.description}');
      final local = catalog.findByName(rule.target.skillName);
      if (local != null) {
        out.writeln('  Resolution:  Local (${local.skillPath})');
      } else {
        out.writeln('  Resolution:  Remote (${rule.target.githubUrl})');
      }
      if (rule.target.commitSha != null) {
        out.writeln('  Pinned SHA:  ${rule.target.commitSha}');
      }
      out.writeln('');
    }
    return ExitCode.success.code;
  }

  final ruleId = results.option('rule');
  final categoryFilter = results.option('category');
  final lifecycleFilter = results.option('lifecycle');

  final activeRules = defaultDiscoveryRules.where((r) {
    if (ruleId != null && r.id != ruleId) return false;
    if (categoryFilter != null && r.category.name != categoryFilter) {
      return false;
    }
    if (lifecycleFilter != null && r.lifecycle.name != lifecycleFilter) {
      return false;
    }
    return true;
  }).toList();

  if (activeRules.isEmpty) {
    err.writeln('Error: No rules match the specified filters.');
    err.writeln(
      'Available rules: ${defaultDiscoveryRules.map((r) => r.id).join(', ')}',
    );
    return ExitCode.usage.code;
  }

  final skillsDir = results.option('skills-dir');
  final catalog = SkillsCatalog.discover(
    searchPaths: skillsDir != null ? [skillsDir] : null,
    workingDirectory: io.Directory(absPath),
  );

  final engine = DiscoveryEngine(absPath, catalog: catalog, rules: activeRules);
  final report = engine.run();

  if (results.flag('outline-only')) {
    out.writeln(report.outline);
    return ExitCode.success.code;
  }

  if (results.flag('prompt-only')) {
    out.writeln(report.probePrompt);
    return ExitCode.success.code;
  }

  if (results.flag('json')) {
    out.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  } else {
    out.writeln(report.toMarkdown());
  }
  return ExitCode.success.code;
}
