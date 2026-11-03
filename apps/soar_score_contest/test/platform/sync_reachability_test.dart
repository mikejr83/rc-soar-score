import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/platform/native_sync.dart';
import 'package:soar_score_sync/soar_score_sync.dart';

void main() {
  group('NativeSync.reachedService', () {
    test('a completed sync or an answer from the service means reachable', () {
      expect(NativeSync.reachedService(null), isTrue);
      expect(NativeSync.reachedService(SyncFailureKind.tokenExpired), isTrue);
      expect(NativeSync.reachedService(SyncFailureKind.updateRequired), isTrue);
      expect(
        NativeSync.reachedService(SyncFailureKind.inactiveInstallation),
        isTrue,
      );
    });

    test('no connection means unreachable', () {
      expect(NativeSync.reachedService(SyncFailureKind.offline), isFalse);
    });

    test('a server error says nothing either way', () {
      expect(NativeSync.reachedService(SyncFailureKind.serverError), isNull);
    });
  });
}
