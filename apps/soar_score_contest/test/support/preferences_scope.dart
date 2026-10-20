import 'package:flutter/widgets.dart';
import 'package:soar_score_contest/preferences_controller_provider.dart';
import 'package:soar_score_contest/services/preferences/preferences_controller.dart';

/// Gives [child] a preferred time zone so director-facing times do not depend
/// on the zone of the machine running the test.
Widget withPreferredZone(Widget child, {String zone = 'UTC'}) =>
    PreferencesControllerInherited(
      controller: PreferencesController()..setTimeZone(zone),
      child: child,
    );
