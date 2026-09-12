import 'dart:io';

void main(List<String> args) {
  // Suboptimal: manual argument checks without package:args, destructive exit, stdout usage
  if (args.isEmpty || args.contains('--help')) {
    print('Usage: my_tool <input>');
    exit(1);
  }
  final input = args[0];
  print('Processing $input');
}
