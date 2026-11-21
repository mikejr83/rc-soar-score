import 'dart:async';

import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
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
    expect(lines.first, startsWith('Sync started: scope=contest/'));
    expect(lines.any((l) => l.startsWith('Checked service versions')), isTrue);
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

  test(
    'an exchange over the slow threshold is a warning marked slow',
    () async {
      final rig = Rig(slowExchange: Duration.zero);

      await rig.engine.syncScope(scope);

      final slow = records.where((r) => r.message.contains('(slow)'));
      expect(slow, isNotEmpty);
      expect(slow.every((r) => r.level == Level.WARNING), isTrue);
    },
  );

  test('a refusal logs its reason but not the mutation id', () async {
    final rig = Rig();
    const profileId = '019c0000-0000-7000-8000-00000000abcd';
    rig.store.mutations.add(mutation(1, clientId: 'profile:$profileId:name'));
    rig.gateway.onExchange = (request) async => FakeGateway.response(
      results: [
        for (final m in request.mutations)
          SyncMutationResult(
            clientMutationId: m.clientMutationId,
            outcome: MutationOutcome.rejected,
            reasonCode: 'unauthorized',
          ),
      ],
    );

    await rig.engine.syncScope(scope);

    final refusal = messages().firstWhere(
      (l) => l.startsWith('Change not accepted'),
    );
    expect(refusal, contains('reason=unauthorized'));
    expect(refusal, contains('entityType=official_score'));
    expect(messages().any((l) => l.contains(profileId)), isFalse);
  });

  test('a throw while finishing locally is logged and rethrown', () async {
    final rig = Rig();
    rig.store.cursorWriteError = StateError('session changed');

    await expectLater(rig.engine.syncScope(scope), throwsStateError);

    final lines = messages();
    expect(lines.last, startsWith('Sync failed: scope=contest/'));
    expect(lines.last, contains('error=StateError'));
    expect(lines.last, isNot(contains('session changed')));
    expect(rig.engine.state.syncing, isFalse);
  });
}
