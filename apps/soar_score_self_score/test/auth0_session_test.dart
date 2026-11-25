import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/auth/auth0_client.dart';
import 'package:soar_score_self_score/auth/auth0_session.dart';
import 'package:soar_score_self_score/auth/auth_session.dart';

/// An [Auth0Client] the test steers: when the SDK "arrives", who the callback
/// signs in, and how logout ends.
class _FakeClient implements Auth0Client {
  bool ready = true;
  Completer<bool>? readyGate;

  /// Answers the long "late SDK" wait (the one given a timeout).
  Completer<bool>? lateGate;
  AuthIdentity? identity;
  Future<void> Function()? onLogout;
  final calls = <String>[];

  @override
  Future<bool> waitUntilReady({Duration? timeout}) async {
    if (timeout != null) {
      // The late watch: only a test that gates it sees the SDK arrive.
      if (lateGate == null) return false;
      calls.add('late-wait');
      return lateGate!.future;
    }
    calls.add('ready:$ready');
    if (readyGate != null) return readyGate!.future;
    return ready;
  }

  @override
  Future<AuthIdentity?> onLoad() async {
    calls.add('onLoad');
    return identity;
  }

  @override
  Future<void> loginWithRedirect({required bool createAccount}) async =>
      calls.add(createAccount ? 'sign-up' : 'sign-in');

  @override
  Future<void> logout() async {
    calls.add('logout');
    await onLogout?.call();
  }

  @override
  Future<String> accessToken() async => 'token';
}

void main() {
  test('restore signs in a pilot returning from Auth0', () async {
    final client = _FakeClient()..identity = const AuthIdentity(name: 'Pat');
    final session = Auth0Session(client);
    await session.restore();
    expect(session.isSignedIn, isTrue);
    expect(session.displayName, 'Pat');
  });

  test(
    'a late SDK: the pending callback is processed on the next try',
    () async {
      final client = _FakeClient()
        ..ready = false
        ..identity = const AuthIdentity(email: 'pat@example.com');
      final session = Auth0Session(client);
      await session.restore();
      // The SDK never loaded: nothing was processed, nobody is signed in.
      expect(session.isSignedIn, isFalse);
      expect(client.calls, ['ready:false']);

      // Sign in is refused while the SDK is still missing, and starts no
      // redirect (which would lose the unprocessed callback).
      await expectLater(session.signIn(), throwsA(isA<AuthException>()));
      expect(client.calls, isNot(contains('sign-in')));

      // The SDK arrives: the callback is processed once, with no new redirect.
      client.ready = true;
      await session.signIn();
      expect(session.isSignedIn, isTrue);
      expect(session.displayName, 'pat@example.com');
      expect(client.calls.where((c) => c == 'onLoad'), hasLength(1));
      expect(client.calls, isNot(contains('sign-in')));
    },
  );

  test(
    'overlapping sign-ins share one restore and start no redirect',
    () async {
      final client = _FakeClient()
        ..readyGate = Completer<bool>()
        ..identity = const AuthIdentity(name: 'Pat');
      final session = Auth0Session(client);
      expect(session.isInitializing, isTrue);

      // Two taps (and the startup restore itself) while the SDK is pending.
      final startup = session.restore();
      final first = session.signIn();
      final second = session.signIn(createAccount: true);
      client.readyGate!.complete(true);
      await Future.wait([startup, first, second]);

      expect(session.isInitializing, isFalse);
      expect(session.isSignedIn, isTrue);
      expect(client.calls.where((c) => c == 'onLoad'), hasLength(1));
      expect(client.calls.where((c) => c.startsWith('ready')), hasLength(1));
      expect(client.calls, isNot(contains('sign-in')));
      expect(client.calls, isNot(contains('sign-up')));
    },
  );

  test('an SDK that arrives late completes the callback once', () async {
    final client = _FakeClient()
      ..ready = false
      ..lateGate = Completer<bool>()
      ..identity = const AuthIdentity(name: 'Pat');
    final session = Auth0Session(client);
    await session.restore();
    expect(session.isSignedIn, isFalse);
    expect(client.calls, contains('late-wait'));

    client.ready = true;
    client.lateGate!.complete(true);
    await pumpEventQueue();

    expect(session.isSignedIn, isTrue);
    expect(client.calls.where((c) => c == 'onLoad'), hasLength(1));
    expect(client.calls.where((c) => c == 'late-wait'), hasLength(1));
  });

  test('a failed start leaves the controls to try again', () async {
    final client = _FakeClient()..ready = false;
    final session = Auth0Session(client);
    await session.restore();
    expect(session.isInitializing, isFalse);
    expect(session.isSignedIn, isFalse);
  });

  test('once restored, sign in and sign up start the redirect', () async {
    final client = _FakeClient();
    final session = Auth0Session(client);
    await session.restore();
    await session.signIn();
    await session.signIn(createAccount: true);
    expect(client.calls, containsAllInOrder(['sign-in', 'sign-up']));
    expect(client.calls.where((c) => c == 'onLoad'), hasLength(1));
  });

  test('a failed restore is not retried by sign in', () async {
    final client = _FakeClient();
    final session = Auth0Session(_ThrowingOnLoad(client));
    await session.restore();
    expect(session.isSignedIn, isFalse);
    await session.signIn();
    expect(client.calls, contains('sign-in'));
  });

  test('a failed logout leaves the pilot signed in', () async {
    final client = _FakeClient()..identity = const AuthIdentity(name: 'Pat');
    final session = Auth0Session(client);
    await session.restore();
    final logout = Completer<void>();
    client.onLogout = () => logout.future;

    var notified = 0;
    session.addListener(() => notified++);
    final result = session.signOut();
    await Future<void>.delayed(Duration.zero);
    // Still signed in while the request is out, and nobody was told otherwise.
    expect(session.isSignedIn, isTrue);
    expect(notified, 0);

    logout.completeError(StateError('network'));
    await expectLater(result, throwsA(isA<AuthException>()));
    expect(session.isSignedIn, isTrue);
    expect(notified, 0);

    // The retry works.
    client.onLogout = null;
    await session.signOut();
    expect(session.isSignedIn, isFalse);
    expect(notified, 1);
  });
}

class _ThrowingOnLoad extends _FakeClient {
  _ThrowingOnLoad(this._inner);

  final _FakeClient _inner;

  @override
  Future<bool> waitUntilReady({Duration? timeout}) => _inner.waitUntilReady();

  @override
  Future<AuthIdentity?> onLoad() async => throw StateError('expired callback');

  @override
  Future<void> loginWithRedirect({required bool createAccount}) =>
      _inner.loginWithRedirect(createAccount: createAccount);
}
