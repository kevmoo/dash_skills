import 'rule.dart';
import 'rules/checks_migration_rule.dart';
import 'rules/cli_app_rule.dart';
import 'rules/doc_examples_rule.dart';
import 'rules/encapsulated_method_object_rule.dart';
import 'rules/mock_generation_rule.dart';
import 'rules/path_package_rule.dart';
import 'rules/pattern_matching_rule.dart';

/// Authoritative registry of all built-in discovery rules.
final List<DiscoveryRule> defaultDiscoveryRules = List.unmodifiable([
  ChecksMigrationRule(),
  PatternMatchingRule(),
  DocExamplesRule(),
  CliAppRule(),
  PathPackageRule(),
  MockGenerationRule(),
  EncapsulatedMethodObjectRule(),
]);
