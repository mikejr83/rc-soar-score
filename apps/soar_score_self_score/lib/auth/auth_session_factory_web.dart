import 'package:flutter/foundation.dart';

import 'auth0_session.dart';
import 'auth0_web_client.dart';
import 'auth_config.dart';
import 'auth_session.dart';
import 'e2e_auth_session.dart';

/// Whether the build is for the web end-to-end tests:
/// `--dart-define=SOAR_SCORE_E2E=true`, never in a release build.
const bool e2eMode = bool.fromEnvironment('SOAR_SCORE_E2E') && !kReleaseMode;

/// The Auth0 session of the browser build, or [E2eAuthSession] in an
/// end-to-end test build.
AuthSession createAuthSession() => e2eMode
    ? E2eAuthSession()
    : Auth0Session(Auth0WebClient(Auth0Config.fromEnvironment()));
