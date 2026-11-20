import 'package:flutter_test/flutter_test.dart';

import 'journey.dart';

/// The web build has no export (see `export_step_native.dart`); the step is
/// declared native-only and never runs here.
Future<void> exportContestToFile(
  WidgetTester tester,
  JourneyContext data,
) async {}

/// Likewise native-only: the web build has no export for support either.
Future<void> exportContestForSupport(
  WidgetTester tester,
  JourneyContext data,
) async {}
