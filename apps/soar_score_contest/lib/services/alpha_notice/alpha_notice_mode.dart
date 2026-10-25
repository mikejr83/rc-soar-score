import 'package:flutter/foundation.dart';

/// Whether the alpha release warning is shown when the app opens.
///
/// It is shown in every build except the demo-database and E2E builds
/// (`--dart-define=SOAR_SCORE_DEMO=true` or `SOAR_SCORE_E2E=true`, never in a
/// release build), so the end-to-end journeys start on the page they expect.
const bool showAlphaNotice =
    kReleaseMode ||
    !(bool.fromEnvironment('SOAR_SCORE_DEMO') ||
        bool.fromEnvironment('SOAR_SCORE_E2E'));
