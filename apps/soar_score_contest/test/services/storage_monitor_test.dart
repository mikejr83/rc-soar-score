import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/storage/storage_monitor.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  test('is available once the probe answers, and keeps when', () async {
    final monitor = StorageMonitor(probe: () async {}, pollInterval: null);
    addTearDown(monitor.dispose);
    expect(monitor.status, ConnectivityStatus.checking);

    await monitor.retry();

    expect(monitor.status, ConnectivityStatus.available);
    expect(monitor.lastObservedAt, isNotNull);
    expect(monitor.lastError, isNull);
  });

  test('is unavailable with the reason when the probe throws, and recovers '
      'on retry', () async {
    var broken = true;
    final monitor = StorageMonitor(
      pollInterval: null,
      probe: () async {
        if (broken) throw StateError('disk is gone');
      },
    );
    addTearDown(monitor.dispose);
    await monitor.retry();
    expect(monitor.status, ConnectivityStatus.unavailable);
    expect(monitor.lastError, contains('disk is gone'));

    broken = false;
    await monitor.retry();

    expect(monitor.status, ConnectivityStatus.available);
    expect(monitor.lastError, isNull);
  });
}
