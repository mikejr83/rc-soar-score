import 'package:flutter/foundation.dart';

import 'auth0_web_session.dart';
import 'auth_config.dart';
import 'auth_session.dart';
import 'e2e_signed_in_session.dart';

/// Whether the build is for the web end-to-end tests:
/// `--dart-define=SOAR_SCORE_E2E=true`, never in a release build.
const bool e2eMode = bool.fromEnvironment('SOAR_SCORE_E2E') && !kReleaseMode;

/// The Auth0 session for this platform (web), or the always-signed-in
/// [E2eSignedInSession] in an end-to-end test build.
AuthSession createAuthSession() =>
    e2eMode ? E2eSignedInSession() : Auth0WebSession(Auth0Config.web());
