import 'dart:async';

import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:test/test.dart';

import '../support/fake_gateway.dart';
import '../support/fixtures.dart';

void main() {
  late List<LogRecord> records;
  late StreamSubscription<LogRecord> subscription;

  setUp(() {
    records = [];
    Logger.root.level = Level.ALL;
    subscription = Logger('SyncEngine').onRecord.listen(records.add);
  });
  tearDown(() => subscription.cancel());

  List<String> messages() => [for (final r in records) r.message];

  test('a sync logs its start, each exchange and its end', () async {
    final rig = Rig();
    rig.store.mutations.add(mutation(1));
    var sequence = 0;
    rig.gateway.onExchange = (request) async => FakeGateway.response(
      results: [
        for (final m in request.mutations)
          accepted(m.clientMutationId, ++sequence),
      ],
      serverSequence: sequence,
    );

    await rig.engine.syncScope(scope);

    final lines = messages();
    expect(lines.first, startsWith('Checked service versions'));
    expect(
      lines.any((l) => l.startsWith('Sync started: scope=contest/')),
      isTrue,
    );
    expect(lines.any((l) => l.contains('Exchange (pull)')), isTrue);
    expect(
      lines.any(
        (l) => l.contains('Exchange (push 1/1)') && l.contains('sent=1'),
      ),
      isTrue,
    );
    expect(lines.last, startsWith('Sync finished: scope=contest/'));
  });

  test(
    'a failed sync logs a warning with the failure and no message',
    () async {
      final rig = Rig();
      rig.gateway.onExchange = (request) async => throw ApiNetworkError(
        'secret-host-detail',
        requestUri: Uri.parse('https://api.example/x'),
      );

      await rig.engine.syncScope(scope);

      final warnings = [
        for (final r in records)
          if (r.level >= Level.WARNING) r.message,
      ];
      expect(
        warnings.any((l) => l.contains('Sync failed') && l.contains('offline')),
        isTrue,
      );
      expect(warnings.any((l) => l.contains('ApiNetworkError')), isTrue);
      expect(messages().any((l) => l.contains('secret-host-detail')), isFalse);
    },
  );

  test('the start is logged before a failing preparation', () async {
    final rig = Rig();
    rig.gateway.infoError = ApiNetworkError(
      'down',
      requestUri: Uri.parse('https://api.example/x'),
    );

    await rig.engine.syncScope(scope);

    final lines = messages();
    final started = lines.indexWhere((l) => l.startsWith('Sync started'));
    final failed = lines.indexWhere((l) => l.startsWith('Sync failed'));
    expect(started, greaterThanOrEqualTo(0));
    expect(failed, greaterThan(started));
  });
}
