import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying unidiomatic `expect()` assertions in tests
/// (such as checking `.length`, `.isEmpty`, `.isNotEmpty`, or `.contains()`)
/// that should be migrated to first-class matchers.
///
/// **Target Skill**:
/// - GitHub: https://github.com/kevmoo/dash_skills/tree/main/skills/dart-matcher-best-practices
final class MatcherBestPracticesRule extends FileDiscoveryRule {
  const MatcherBestPracticesRule();

  @override
  String get id => 'matcher-best-practices';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'kevmoo',
    repo: 'dash_skills',
    path: 'skills/dart-matcher-best-practices',
  );

  @override
  RuleCategory get category => RuleCategory.testing;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.hygiene;

  @override
  RuleTrigger get trigger => RuleTrigger.alternative;

  @override
  String get description =>
      'Detects unidiomatic expect() assertions (e.g. expect(x.length, ...) '
      'or expect(x.isEmpty, true)).';

  @override
  Confidence get defaultConfidence => Confidence.high;

  @override
  bool appliesTo(PackageContext context) =>
      (context.hasDependency('test') ||
          context.hasDependency('flutter_test')) &&
      context.testFiles.isNotEmpty;

  @override
  List<File> selectFiles(PackageContext context) => context.testFiles;

  @override
  String get diagnosisTemplate =>
      '{count} test file(s) use suboptimal expect() assertions instead of '
      'dedicated matchers.';

  @override
  String get prescription =>
      'Migrate to first-class matchers (hasLength, isEmpty, isNotEmpty, '
      'contains) for clearer assertion failure messages.';

  @override
  String? checkFile(File file, String content, PackageContext context) {
    final unit = context.facts.unitForFile(file, content);
    final visitor = _SuboptimalMatcherVisitor();
    unit.accept(visitor);
    return visitor.found ? 'Suboptimal expect() assertion found' : null;
  }
}

class _SuboptimalMatcherVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (found) return;
    if (_isSuboptimalExpectCall(node)) {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    if (found) return;
    if (node.catchClauses.isNotEmpty && _blockContainsFailCall(node.body)) {
      found = true;
      return;
    }
    super.visitTryStatement(node);
  }
}

bool _isSuboptimalExpectCall(MethodInvocation node) {
  if (node.target != null ||
      node.isCascaded ||
      node.methodName.name != 'expect') {
    return false;
  }
  final args = node.argumentList.arguments;
  if (args.length < 2 ||
      args[0] is NamedExpression ||
      args[1] is NamedExpression) {
    return false;
  }

  final actual = args[0].unParenthesized;
  final expected = args[1].unParenthesized;

  final prop = _accessedPropertyName(actual);
  if (prop == 'isEmpty' || prop == 'isNotEmpty') return true;
  if (prop == 'length') return !_isFloatingPointMatcher(expected);

  if (actual is MethodInvocation &&
      actual.target != null &&
      actual.methodName.name == 'contains' &&
      actual.argumentList.arguments.length == 1) {
    return true;
  }

  return actual is IndexExpression &&
      actual.target != null &&
      actual.index.unParenthesized is StringLiteral;
}

String? _accessedPropertyName(Expression expr) => switch (expr) {
  PrefixedIdentifier(:final identifier) => identifier.name,
  PropertyAccess(:final propertyName) => propertyName.name,
  _ => null,
};

bool _isFloatingPointMatcher(Expression expr) {
  if (expr is DoubleLiteral) return true;
  if (expr is PrefixExpression) {
    return expr.operand.unParenthesized is DoubleLiteral;
  }
  if (expr is MethodInvocation) {
    final name = expr.methodName.name;
    if (name == 'closeTo') return true;
    if (name == 'equals' && expr.argumentList.arguments.length == 1) {
      return _isFloatingPointMatcher(
        expr.argumentList.arguments.first.unParenthesized,
      );
    }
  }
  return false;
}

bool _blockContainsFailCall(Block block) {
  final finder = _FailCallFinder();
  block.accept(finder);
  return finder.found;
}

class _FailCallFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Do not cross into nested closures that may not run synchronously inside
    // the try block.
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (found) return;
    if (node.target == null &&
        !node.isCascaded &&
        node.methodName.name == 'fail') {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}
