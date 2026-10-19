import 'package:flutter/foundation.dart';

/// E2E-only mode that starts signed out and scripts provider recovery.
const bool e2eSignedOutMode =
    bool.fromEnvironment('SOAR_SCORE_E2E_SIGNED_OUT') && !kReleaseMode;
