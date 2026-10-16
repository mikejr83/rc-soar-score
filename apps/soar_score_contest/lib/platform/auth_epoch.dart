import 'dart:async';

import 'package:soar_score_api/soar_score_api.dart';

import '../auth/auth_session.dart';

/// A request was not sent, or its answer not used, because the sign-in it
/// was made under ended first. Looks like a lost connection to its callers,
/// which leave their work in place and try again under the new sign-in.
class SessionChangedError extends ApiNetworkError {
  SessionChangedError(String what)
    : super(
        'The sign-in changed; $what was not sent',
        requestUri: Uri(path: what),
      );
}

/// Numbers the sign-ins of an [AuthSession] and binds requests to one.
///
/// The number moves, synchronously with the notification, whenever the
/// director signs in or out (and for good on [close]). An operation takes the
/// number it was authorised under and runs through [runBound]; the token
/// provider from [boundToken] then checks that number before and after it
/// looks up the access token. A request therefore carries the token of the
/// sign-in that authorised it or is not sent at all, however the awaits
/// between the authorisation and the request interleave with a sign-out or a
/// sign-in as someone else.
class AuthEpoch {
  AuthEpoch(this._auth) : _signedIn = _auth.isSignedIn {
    _auth.addListener(_changed);
  }

  final AuthSession _auth;
  final Object _zoneKey = Object();
  bool _signedIn;
  bool _closed = false;
  int _value = 0;

  /// The current sign-in's number.
  int get value => _value;

  /// Whether [epoch] is still the current sign-in, with someone signed in.
  bool isCurrent(int epoch) => !_closed && epoch == _value && _signedIn;

  void _changed() {
    if (_auth.isSignedIn == _signedIn) return;
    _signedIn = _auth.isSignedIn;
    _value++;
  }

  /// Ends every operation still bound to an earlier number, for good.
  void close() {
    _closed = true;
    _auth.removeListener(_changed);
    _value++;
  }

  /// Runs [body] so that every request it makes is bound to [epoch].
  Future<T> runBound<T>(int epoch, Future<T> Function() body) =>
      Zone.current.fork(zoneValues: {_zoneKey: epoch}).run(body);

  /// A token provider for the remote `ApiClient`: bound requests get the
  /// token of their sign-in or fail with [SessionChangedError]; others get
  /// whatever [live] returns.
  TokenProvider boundToken(TokenProvider live) => () async {
    final bound = Zone.current[_zoneKey] as int?;
    if (bound == null) return live();
    _require(bound);
    final token = await live();
    _require(bound);
    return token;
  };

  void _require(int epoch) {
    if (!isCurrent(epoch)) throw SessionChangedError('request');
  }
}
