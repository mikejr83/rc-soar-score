import 'package:flutter/widgets.dart';

import 'auth_session.dart';

/// Exposes the app's [AuthSession] to the widget tree and rebuilds dependents
/// when the signed-in state changes.
class AuthSessionInherited extends InheritedNotifier<AuthSession> {
  const AuthSessionInherited({
    super.key,
    required AuthSession session,
    required super.child,
  }) : super(notifier: session);
}

/// The app-wide [AuthSession], or `null` when none is provided (tests that
/// pump the app without a bootstrap).
AuthSession? authSessionOf(BuildContext context) => context
    .dependOnInheritedWidgetOfExactType<AuthSessionInherited>()
    ?.notifier;
