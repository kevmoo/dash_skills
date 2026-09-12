import 'package:args/args.dart';

void main(List<String> args) {
  final parser = ArgParser()..addFlag('verbose', abbr: 'v');
  final results = parser.parse(args);
  if (results['verbose'] as bool) {
    print('Verbose mode');
  }
}
