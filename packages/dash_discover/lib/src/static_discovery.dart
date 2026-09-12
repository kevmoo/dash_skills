import 'context.dart';
import 'models.dart';
import 'rule.dart';
import 'rules_registry.dart';

export 'context.dart';
export 'models.dart';
export 'rule.dart';
export 'rules_registry.dart';

/// Evaluates a package against registered [DiscoveryRule] instances.
class StaticDiscoveryEngine {
  final PackageContext context;
  final List<DiscoveryRule> rules;

  StaticDiscoveryEngine(this.context, {List<DiscoveryRule>? rules})
    : rules = rules ?? defaultDiscoveryRules;

  factory StaticDiscoveryEngine.forPath(
    String path, {
    List<DiscoveryRule>? rules,
  }) {
    return StaticDiscoveryEngine(PackageContext.load(path), rules: rules);
  }

  /// Runs all applicable rules against the package context.
  List<Opportunity> scan() {
    final opportunities = <Opportunity>[];
    for (final rule in rules) {
      if (rule.appliesTo(context)) {
        opportunities.addAll(rule.evaluate(context));
      }
    }
    return opportunities;
  }
}
