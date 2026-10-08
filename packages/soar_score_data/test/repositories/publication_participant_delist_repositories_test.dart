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

  final participants = [
    for (final row in exampleRows('publication_participant'))
      core.PublicationParticipant.fromJson(row),
  ];
  final delists = [
    for (final row in exampleRows('delist_request'))
      core.DelistRequest.fromJson(row),
  ];
  final publicationId = participants.first.publicationId;

  group('PublicationParticipantRepository', () {
    late core.PublicationParticipantRepository repo;
    setUp(() => repo = repository.publicationParticipantRepository);

    test('reads back the example participants unchanged', () async {
      for (final participant in participants) {
        expect(await repo.findById(participant.id), participant);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists a publication and finds a pilot by key', () async {
      expect(
        await repo.listForPublication(publicationId),
        unorderedEquals(participants),
      );
      expect(await repo.listForPublication(core.Id.create()), isEmpty);
      expect(
        await repo.findByPilotKey(publicationId, 'p_Bd4Wm9'),
        participants[1],
      );
      expect(await repo.findByPilotKey(publicationId, 'p_nobody'), isNull);
    });

    test('save replaces a participant and records no mutation', () async {
      final before = await inst.count('mutation_records');
      final redacted = core.PublicationParticipant.fromJson({
        ...participants.first.toJson(),
        'details': null,
        'redacted_at': '2026-10-20T09:00:00Z',
        'updated_at': '2026-10-20T09:00:00Z',
      });

      expect(await repo.save(redacted), redacted);

      expect(await repo.findById(redacted.id), redacted);
      expect(await repo.listForPublication(publicationId), hasLength(5));
      expect(await inst.count('mutation_records'), before);
    });

    test('a second participant with the same pilot key is refused', () async {
      final twin = core.PublicationParticipant.fromJson({
        ...participants.first.toJson(),
        'id': core.Id.create().value,
      });

      await expectLater(repo.save(twin), throwsA(anything));
      expect(await repo.listForPublication(publicationId), hasLength(5));
    });
  });

  group('DelistRequestRepository', () {
    late core.DelistRequestRepository repo;
    setUp(() => repo = repository.delistRequestRepository);

    core.DelistRequest pending({core.Id? id}) => core.DelistRequest.fromJson({
      'id': (id ?? core.Id.create()).value,
      'publication_id': publicationId.value,
      'requested_by': delists.first.requestedBy.value,
      'trigger': 'owner_request',
      'reason': 'Wrong contest name',
      'requested_at': '2026-10-21T10:00:00Z',
      'state': 'pending',
      'decided_by': null,
      'decided_at': null,
      'decision_note': null,
    });

    test('reads back the example request unchanged', () async {
      expect(await repo.findById(delists.single.id), delists.single);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists by publication and by state', () async {
      expect(await repo.listForPublication(publicationId), delists);
      expect(await repo.listForPublication(core.Id.create()), isEmpty);
      expect(await repo.listByState(core.DelistState.approved), delists);
      expect(await repo.listByState(core.DelistState.pending), isEmpty);
    });

    test('finds the pending request of a publication', () async {
      expect(await repo.findPendingForPublication(publicationId), isNull);
      final request = pending();
      await repo.save(request);

      expect(await repo.findPendingForPublication(publicationId), request);
      expect(await repo.listByState(core.DelistState.pending), [request]);
    });

    test('a decision is a save of the decided copy', () async {
      final before = await inst.count('mutation_records');
      final request = await repo.save(pending());
      final decided = core.DelistRequest.fromJson({
        ...request.toJson(),
        'state': 'denied',
        'decided_by': delists.single.decidedBy!.value,
        'decided_at': '2026-10-21T12:00:00Z',
        'decision_note': 'Name is correct',
      });

      await repo.save(decided);

      expect(await repo.findById(request.id), decided);
      expect(await repo.findPendingForPublication(publicationId), isNull);
      expect(await inst.count('mutation_records'), before);
    });

    test('a second pending request for a publication is refused', () async {
      await repo.save(pending());

      await expectLater(repo.save(pending()), throwsA(anything));
      expect(await repo.listByState(core.DelistState.pending), hasLength(1));
    });
  });
}
