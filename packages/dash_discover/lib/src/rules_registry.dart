import 'rule.dart';
import 'rules/checks_migration_rule.dart';
import 'rules/cli_app_rule.dart';
import 'rules/matcher_best_practices_rule.dart';
import 'rules/mock_generation_rule.dart';
import 'rules/path_package_rule.dart';
import 'rules/pattern_matching_rule.dart';
import 'rules/sealed_hierarchy_rule.dart';

export 'rules/checks_migration_rule.dart';
export 'rules/cli_app_rule.dart';
export 'rules/matcher_best_practices_rule.dart';
export 'rules/mock_generation_rule.dart';
export 'rules/path_package_rule.dart';
export 'rules/pattern_matching_rule.dart';
export 'rules/sealed_hierarchy_rule.dart';

/// Authoritative registry of all built-in discovery rules.
const List<DiscoveryRule> defaultDiscoveryRules = [
  ChecksMigrationRule(),
  PatternMatchingRule(),
  CliAppRule(),
  PathPackageRule(),
  MockGenerationRule(),
  MatcherBestPracticesRule(),
  SealedHierarchyRule(),
];
