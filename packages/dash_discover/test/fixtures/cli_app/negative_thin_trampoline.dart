import 'package:dash_discover/dash_discover.dart';

Future<void> main(List<String> args) async {
  // Thin entrypoint: delegates execution to lib/
  final engine = DiscoveryEngine('.');
  final report = engine.run();
  print(report.toMarkdown());
}
