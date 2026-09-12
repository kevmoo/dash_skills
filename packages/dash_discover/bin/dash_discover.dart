import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:dash_discover/dash_discover.dart';
import 'package:dash_discover/src/skills_catalog.dart';

void main(List<String> args) {
  final parser = ArgParser()
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
      help:
          'Filter rules by skill lifecycle (migration, hygiene, architecture).',
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
      help:
          'Updates the discovery rules block in skills/dash-discover/SKILL.md.',
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

  final results = parser.parse(args);
  if (results['help'] as bool) {
    print('Usage: dart run dash_discover [path-to-target-package] [options]\n');
    print(parser.usage);
    exit(0);
  }

  if (results['update-skill'] as bool || results['validate-skill'] as bool) {
    final skillFile = findSkillFile();
    if (skillFile == null) {
      stderr.writeln('Error: Could not find skills/dash-discover/SKILL.md');
      exit(1);
    }
    final content = skillFile.readAsStringSync();
    final updated = updateSkillContent(content);
    if (results['validate-skill'] as bool) {
      if (content == updated) {
        print('skills/dash-discover/SKILL.md is up-to-date!');
        exit(0);
      } else {
        stderr.writeln('Error: skills/dash-discover/SKILL.md is out of date.');
        stderr.writeln(
          'Run `dart run dash_discover --update-skill` to update it.',
        );
        exit(1);
      }
    }
    if (results['update-skill'] as bool) {
      skillFile.writeAsStringSync(updated);
      print('Successfully updated ${skillFile.path} with the latest rules!');
      exit(0);
    }
  }

  if (results['list-rules'] as bool) {
    print('Available Discovery Rules (${defaultDiscoveryRules.length}):\n');
    for (final rule in defaultDiscoveryRules) {
      print('• ${rule.id} (${rule.category.label}) [${rule.lifecycle.label}]');
      print('  Skill:       ${rule.target.skillName}');
      print('  Lifecycle:   ${rule.lifecycle.label}');
      print('  Category:    ${rule.category.label}');
      print('  Confidence:  ${rule.defaultConfidence.name.toUpperCase()}');
      print('  Description: ${rule.description}');
      print('  Target:      ${rule.target.githubUrl}');
      if (rule.target.commitSha != null) {
        print('  Pinned:      ${rule.target.commitSha}');
      }
      print('');
    }
    exit(0);
  }

  final targetPath = results.rest.isNotEmpty ? results.rest.first : '.';
  final absPath = Directory(targetPath).absolute.path;

  if (!Directory(absPath).existsSync()) {
    stderr.writeln('Error: Target directory does not exist: $absPath');
    exit(1);
  }

  final ruleId = results['rule'] as String?;
  final categoryFilter = results['category'] as String?;
  final lifecycleFilter = results['lifecycle'] as String?;

  final activeRules = defaultDiscoveryRules.where((r) {
    if (ruleId != null && r.id != ruleId) return false;
    if (categoryFilter != null && r.category.name != categoryFilter)
      return false;
    if (lifecycleFilter != null && r.lifecycle.name != lifecycleFilter) {
      return false;
    }
    return true;
  }).toList();

  if (activeRules.isEmpty) {
    stderr.writeln('Error: No rules match the specified filters.');
    stderr.writeln(
      'Available rules: ${defaultDiscoveryRules.map((r) => r.id).join(', ')}',
    );
    exit(1);
  }

  final skillsDir = results['skills-dir'] as String?;
  final catalog = SkillsCatalog.discover(
    searchPaths: skillsDir != null ? [skillsDir] : null,
  );

  final engine = DiscoveryEngine(absPath, catalog: catalog, rules: activeRules);
  final report = engine.run();

  if (results['outline-only'] as bool) {
    print(report.outline);
    return;
  }

  if (results['prompt-only'] as bool) {
    print(report.probePrompt);
    return;
  }

  if (results['json'] as bool) {
    print(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  } else {
    print(report.toMarkdown());
  }
}
