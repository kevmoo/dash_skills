enum Status { active, pending, inactive }

class PositiveDemo {
  String handleCascade(Object value) {
    // Suboptimal: multi-branch type cascade
    if (value is int) {
      return 'integer: $value';
    } else if (value is String) {
      return 'string: $value';
    } else if (value is bool) {
      return 'boolean: $value';
    } else {
      return 'unknown';
    }
  }

  String describeStatus(Status status) {
    // Suboptimal: legacy switch statement returning values across cases
    switch (status) {
      case Status.active:
        return 'Active account';
      case Status.pending:
        return 'Pending review';
      case Status.inactive:
        return 'Inactive account';
    }
  }
}
