import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:soar_score_contest/auth/identity_provider_check.dart';

/// Hand-rolled [IdentityProviderCheck] stand-in: tests drive the state
/// transitions directly and count probes.
class FakeIdentityProviderCheck extends ChangeNotifier
    implements IdentityProviderCheck {
  FakeIdentityProviderCheck({
    this.status = IdentityProviderStatus.checking,
    this.lastError,
  });

  @override
  IdentityProviderStatus status;

  @override
  String? lastError;

  int probeCalls = 0;

  @override
  Future<void> probe() {
    probeCalls++;
    return Future.value();
  }

  @override
  void check() {
    unawaited(probe());
  }
}
