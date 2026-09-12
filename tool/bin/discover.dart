import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import '../lib/src/discovery_engine.dart';
import '../lib/src/skills_catalog.dart';

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

  final targetPath = results.rest.isNotEmpty ? results.rest.first : '.';
  final absPath = Directory(targetPath).absolute.path;

  if (!Directory(absPath).existsSync()) {
    stderr.writeln('Error: Target directory does not exist: $absPath');
    exit(1);
  }

  final skillsDir = results['skills-dir'] as String?;
  final catalog = SkillsCatalog.discover(
    searchPaths: skillsDir != null ? [skillsDir] : null,
  );

  final engine = DiscoveryEngine(absPath, catalog: catalog);
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
