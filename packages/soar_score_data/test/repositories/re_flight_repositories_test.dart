import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  final reFlights = [
    for (final row in exampleRows('re_flight')) core.ReFlight.fromJson(row),
  ];
  final participants = [
    for (final row in exampleRows('re_flight_participant'))
      core.ReFlightParticipant.fromJson(row),
  ];

  group('ReFlightRepository', () {
    late core.ReFlightRepository repo;
    setUp(() => repo = repository.reFlightRepository);

    test('reads back the example re-flights unchanged', () async {
      for (final reFlight in reFlights) {
        expect(await repo.findById(reFlight.id), reFlight);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists by contest, source group and scheduled round', () async {
      final first = reFlights.first;

      expect(
        await repo.listForContest(first.contestId),
        unorderedEquals(reFlights.where((r) => r.contestId == first.contestId)),
      );
      final sourced = await repo.listForSourceGroup(
        first.sourceRoundId,
        first.sourceGroup,
      );
      expect(
        sourced,
        unorderedEquals(
          reFlights.where(
            (r) =>
                r.sourceRoundId == first.sourceRoundId &&
                r.sourceGroup == first.sourceGroup,
          ),
        ),
      );
      expect(
        sourced.map((r) => r.sequence).toList(),
        orderedEquals([...sourced.map((r) => r.sequence)]..sort()),
      );
      expect(
        await repo.listForScheduledRound(first.scheduledRoundId),
        unorderedEquals(
          reFlights.where((r) => r.scheduledRoundId == first.scheduledRoundId),
        ),
      );
      expect(await repo.listForSourceGroup(first.sourceRoundId, 999), isEmpty);
    });

    test('save bumps the revision and refuses a stale copy', () async {
      final first = reFlights.first;
      final changed = core.ReFlight.fromJson({
        ...first.toJson(),
        'reason': 'Changed reason',
      });

      final saved = await repo.save(changed, metadata: metadata());

      expect(saved.revision, first.revision + 1);
      expect(saved.reason, 'Changed reason');
      expect(
        repo.save(changed, metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
    });

    test('delete refuses a re-flight that has participants', () async {
      final parent = participants.first.reFlightId;

      await expectLater(
        repo.delete(parent, metadata: metadata()),
        throwsA(anything),
      );
      expect(await repo.findById(parent), isNotNull);
    });
  });

  group('ReFlightParticipantRepository', () {
    late core.ReFlightParticipantRepository repo;
    setUp(() => repo = repository.reFlightParticipantRepository);

    test('reads back the example participants unchanged', () async {
      for (final participant in participants) {
        expect(await repo.findById(participant.id), participant);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists by re-flight and by participation', () async {
      final first = participants.first;

      expect(
        await repo.listForReFlight(first.reFlightId),
        unorderedEquals(
          participants.where((p) => p.reFlightId == first.reFlightId),
        ),
      );
      expect(
        await repo.listForParticipation(first.contestParticipationId),
        unorderedEquals(
          participants.where(
            (p) => p.contestParticipationId == first.contestParticipationId,
          ),
        ),
      );
    });

    test('save bumps the revision and refuses a stale copy', () async {
      final first = participants.first;
      final changed = core.ReFlightParticipant.fromJson({
        ...first.toJson(),
        'draw_position': 7,
      });

      final saved = await repo.save(changed, metadata: metadata());

      expect(saved.revision, first.revision + 1);
      expect(saved.drawPosition, 7);
      expect(
        repo.save(changed, metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
    });

    test('delete removes a participant', () async {
      final first = participants.first;

      expect(await repo.delete(first.id, metadata: metadata()), isTrue);

      expect(await repo.findById(first.id), isNull);
      expect(await repo.delete(first.id, metadata: metadata()), isFalse);
    });
  });
}
