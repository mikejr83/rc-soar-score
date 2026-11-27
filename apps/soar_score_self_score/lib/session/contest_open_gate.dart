import 'package:flutter/widgets.dart';

/// Coordinates opening a contest from the list with signing out.
///
/// An open answer sets the API's HttpOnly cookie before the app can look at
/// it, so a sign-out that clears the cookie while an open is still in flight
/// can be undone by the late answer. Sign-out therefore [closeAndSettle]s the
/// gate first (no new opens, wait for those sent), clears the cookie, and
/// only then signs out.
class ContestOpenGate {
  bool _closed = false;
  final _inFlight = <Future<void>>{};

  /// Whether new opens are refused (a sign-out is under way).
  bool get isClosed => _closed;

  /// Runs [open], or returns null without calling it while the gate is
  /// closed. The call is tracked until it settles, whatever it answers.
  Future<T?> run<T>(Future<T> Function() open) async {
    if (_closed) return null;
    final call = open();
    late final Future<void> tracked;
    tracked = call.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
      _inFlight.remove(tracked);
    });
    _inFlight.add(tracked);
    return call;
  }

  /// Refuses new opens and completes once every open already sent has
  /// settled, so no late answer can set a cookie after this returns.
  Future<void> closeAndSettle() async {
    _closed = true;
    while (_inFlight.isNotEmpty) {
      await Future.wait(_inFlight.toList());
    }
  }

  /// Accepts opens again, after a sign-out that did not happen or finished.
  void reopen() => _closed = false;

  Future<void>? _signOut;

  /// Whether a sign-out is under way.
  bool get isSigningOut => _signOut != null;

  /// Runs the one sign-out of the app: closes the gate, waits for the opens
  /// already sent, runs [teardown], and reopens the gate only when that has
  /// finished or failed. A call made while one is under way (the pilot left
  /// Home and came back) joins it and gets its outcome, so two teardowns never
  /// overlap and the gate never reopens under a running one.
  Future<void> signOut(Future<void> Function() teardown) {
    return _signOut ??= () async {
      try {
        await closeAndSettle();
        await teardown();
      } finally {
        reopen();
        _signOut = null;
      }
    }();
  }
}

/// Provides the [ContestOpenGate] to the pages.
class ContestOpenScope extends InheritedWidget {
  const ContestOpenScope({required this.gate, required super.child, super.key});

  final ContestOpenGate gate;

  @override
  bool updateShouldNotify(ContestOpenScope oldWidget) => gate != oldWidget.gate;
}

final _fallbackGate = ContestOpenGate();

extension ContestOpenGateContext on BuildContext {
  /// The gate the pages share. With no scope above, one that lasts as long as
  /// the app.
  ContestOpenGate get contestOpenGate =>
      getInheritedWidgetOfExactType<ContestOpenScope>()?.gate ?? _fallbackGate;
}
