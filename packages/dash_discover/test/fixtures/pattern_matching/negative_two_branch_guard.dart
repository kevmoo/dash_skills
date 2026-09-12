class Headers {
  final Map<String, List<String>> entries;
  Headers._(this.entries);

  static Headers from(Object? values) {
    // Skill abstention guardrail: prefer simple `is` promotion for single promotable variables
    // instead of replacing a 2-branch null/empty guard with a switch expression.
    if (values == null) {
      return Headers._({});
    } else if (values is Headers) {
      return values;
    } else {
      return Headers._({});
    }
  }
}
