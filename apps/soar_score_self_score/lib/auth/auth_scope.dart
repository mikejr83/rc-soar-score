import 'package:flutter/widgets.dart';

import 'auth_session.dart';

/// Provides the [AuthSession] to the pages and rebuilds them when the pilot
/// signs in or out.
class AuthScope extends InheritedNotifier<AuthSession> {
  const AuthScope({
    required AuthSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);
}

final _unavailable = UnavailableAuthSession();

extension AuthSessionContext on BuildContext {
  /// The session pages read the sign-in state from. With no scope above, a
  /// session with no sign-in, so a page tested alone shows no accounts.
  AuthSession get auth =>
      dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier ?? _unavailable;
}
