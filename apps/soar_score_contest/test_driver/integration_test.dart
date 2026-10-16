import 'package:integration_test/integration_test_driver.dart';

/// Driver for `flutter drive` runs of `integration_test/` on the web
/// (`scripts/e2e.sh -d web`); the Windows runs use `flutter test`.
Future<void> main() => integrationDriver();
