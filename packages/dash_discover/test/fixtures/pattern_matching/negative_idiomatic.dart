enum Status { active, pending, inactive }

class IdiomaticDemo {
  String handleCascade(Object value) => switch (value) {
    int i => 'integer: $i',
    String s => 'string: $s',
    bool b => 'boolean: $b',
    _ => 'unknown',
  };

  String describeStatus(Status status) => switch (status) {
    Status.active => 'Active account',
    Status.pending => 'Pending review',
    Status.inactive => 'Inactive account',
  };

  void handlePattern(Map<String, dynamic> json) {
    if (json case {'id': int id, 'name': String name}) {
      print('User $id: $name');
    }
  }
}
