import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying legacy type cascades and statements that can
/// be modernized with Dart 3 pattern matching, switch expressions, and
/// destructuring.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/bf984f3ef223dd85e92036f934bbcb6bf301e4ce/skills/dart-use-pattern-matching
final class PatternMatchingRule extends FileDiscoveryRule {
  const PatternMatchingRule();

  @override
  String get id => 'pattern-matching';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'dart-lang',
    repo: 'skills',
    path: 'skills/dart-use-pattern-matching',
    commitSha: 'bf984f3ef223dd85e92036f934bbcb6bf301e4ce',
  );

  @override
  RuleCategory get category => RuleCategory.language;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.migration;

  @override
  RuleTrigger get trigger => RuleTrigger.alternative;

  @override
  String get description =>
      'Detects legacy else if (... is ...) type cascades and returning '
      'switch statements.';

  @override
  Confidence get defaultConfidence => Confidence.high;

  @override
  String get diagnosisTemplate =>
      '{count} file(s) use legacy `else if (... is ...)` type cascades or '
      'returning switch statements.';

  @override
  String get prescription =>
      'Refactor into concise Dart 3 switch expressions, sealed class '
      'exhaustiveness, and pattern destructuring.';

  @override
  String? checkFile(File file, String content, PackageContext context) {
    final unit = context.facts.unitForFile(file, content);
    final visitor = _PatternMatchingVisitor();
    unit.accept(visitor);
    return visitor.reason;
  }
}

class _PatternMatchingVisitor extends RecursiveAstVisitor<void> {
  String? reason;

  @override
  void visitIfStatement(IfStatement node) {
    if (reason != null) return;
    final parent = node.parent;
    if (parent is! IfStatement || parent.elseStatement != node) {
      if (_countTypeCheckBranches(node) >= 2) {
        reason = 'Legacy type cascade found';
        return;
      }
    }
    super.visitIfStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (reason != null) return;
    if (_isExpressionConvertibleSwitch(node)) {
      reason = 'Legacy returning switch statement found';
      return;
    }
    super.visitSwitchStatement(node);
  }
}

int _countTypeCheckBranches(IfStatement root) {
  var count = 0;
  Statement? current = root;
  while (current is IfStatement) {
    if (current.caseClause == null && _containsPositiveIs(current.expression)) {
      count++;
    }
    current = current.elseStatement;
  }
  return count;
}

bool _containsPositiveIs(Expression expression) {
  final expr = expression.unParenthesized;
  if (expr is IsExpression) return expr.notOperator == null;
  if (expr is BinaryExpression) {
    return _containsPositiveIs(expr.leftOperand) ||
        _containsPositiveIs(expr.rightOperand);
  }
  return false;
}

bool _isExpressionConvertibleSwitch(SwitchStatement node) {
  final nonEmptyMembers = node.members
      .where((m) => m.statements.isNotEmpty)
      .toList();
  if (nonEmptyMembers.length < 2) return false;
  return nonEmptyMembers.every(_isSingleValueExitMember);
}

bool _isSingleValueExitMember(SwitchMember member) {
  if (member.statements.length != 1) return false;
  final stmt = member.statements.single;
  if (stmt is ReturnStatement) return stmt.expression != null;
  return stmt is ExpressionStatement && stmt.expression is ThrowExpression;
}
