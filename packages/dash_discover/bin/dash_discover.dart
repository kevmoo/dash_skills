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
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information.',
    );

  final results = parser.parse(args);
  if (results['help'] as bool) {
    print(
      'Usage: dart tool/bin/discover.dart [path-to-target-package] [options]\n',
    );
    print(parser.usage);
    exit(0);
  }

  if (results['list-rules'] as bool) {
    print('Available Discovery Rules (${defaultDiscoveryRules.length}):\n');
    for (final rule in defaultDiscoveryRules) {
      print('• ${rule.id} (${rule.category})');
      print('  Skill:  ${rule.target.skillName}');
      print('  Target: ${rule.target.githubUrl}');
      if (rule.target.commitSha != null) {
        print('  Pinned: ${rule.target.commitSha}');
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
  final activeRules = ruleId != null
      ? defaultDiscoveryRules.where((r) => r.id == ruleId).toList()
      : defaultDiscoveryRules;

  if (ruleId != null && activeRules.isEmpty) {
    stderr.writeln('Error: No rule found matching ID "$ruleId".');
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
