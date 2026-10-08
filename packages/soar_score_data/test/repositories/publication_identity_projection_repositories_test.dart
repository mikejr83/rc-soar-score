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

  final identities = [
    for (final row in exampleRows('publication_identity'))
      core.PublicationIdentity.fromJson(row),
  ];
  final projections = [
    for (final row in exampleRows('publication_projection'))
      core.PublicationProjection.fromJson(row),
  ];
  final identity = identities.single;

  core.PublicationProjection nextProjection({
    int revision = 3,
    String mutation = 'publish-3',
    core.Id? id,
    core.Id? publicationId,
  }) => core.PublicationProjection.fromJson({
    ...projections.first.toJson(),
    'id': (id ?? core.Id.create()).value,
    'publication_id': (publicationId ?? identity.id).value,
    'projection_revision': revision,
    'client_mutation_id': mutation,
  });

  group('PublicationIdentityRepository', () {
    late core.PublicationIdentityRepository repo;
    setUp(() => repo = repository.publicationIdentityRepository);

    test('reads back the example identity unchanged', () async {
      expect(await repo.findById(identity.id), identity);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('finds by contest and lists by owner', () async {
      expect(await repo.findForContest(identity.contestId!), identity);
      expect(await repo.findForContest(core.Id.create()), isNull);
      expect(await repo.listForOwner(identity.ownerPublicProfileId!), [
        identity,
      ]);
      expect(await repo.listForOwner(core.Id.create()), isEmpty);
    });

    test('save bumps the revision and records no mutation', () async {
      final before = await inst.count('mutation_records');

      final saved = await repo.save(
        core.PublicationIdentity.fromJson({
          ...identity.toJson(),
          'visibility': 'Unlisted',
        }),
      );

      expect(saved.revision, identity.revision + 1);
      expect(saved.visibility, core.PublicationVisibility.unlisted);
      expect(await repo.findById(identity.id), saved);
      expect(await inst.count('mutation_records'), before);
    });

    test('save of a new identity keeps the revision it carries', () async {
      final fresh = core.PublicationIdentity(
        id: core.Id.create(),
        verificationEmail: 'pilot@example.com',
      );

      final saved = await repo.save(fresh);

      expect(saved, fresh);
      expect(await repo.findById(fresh.id), fresh);
    });

    test('save of an identity read at an older revision is stale', () async {
      await repo.save(identity);

      await expectLater(
        repo.save(identity),
        throwsA(
          isA<core.StaleRevisionError>()
              .having((e) => e.expectedRevision, 'expected', 4)
              .having((e) => e.storedRevision, 'stored', 5),
        ),
      );
      expect((await repo.findById(identity.id))!.revision, 5);
    });

    test('the database refuses a hiding round without its time', () async {
      final broken = {
        ...identity.toJson(),
        'results_hidden_through_round': 2,
        'results_hidden_at': null,
      };

      await expectLater(
        inst.stores.of('PublicationIdentity').upsertJson(broken),
        throwsA(anything),
      );
    });
  });

  group('PublicationProjectionRepository', () {
    late core.PublicationProjectionRepository repo;
    setUp(() => repo = repository.publicationProjectionRepository);

    test('reads back the example projection unchanged', () async {
      for (final projection in projections) {
        expect(await repo.findById(projection.id), projection);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists a publication oldest revision first', () async {
      final next = nextProjection();
      await repo.append(next);

      final listed = await repo.listForPublication(identity.id);

      expect(listed.map((p) => p.projectionRevision), [2, 3]);
      expect(await repo.latestForPublication(identity.id), next);
      expect(await repo.latestForPublication(core.Id.create()), isNull);
    });

    test('finds a projection by its client mutation id', () async {
      final next = nextProjection(mutation: 'retry-me');
      await repo.append(next);

      expect(await repo.findByClientMutationId(identity.id, 'retry-me'), next);
      expect(await repo.findByClientMutationId(identity.id, 'other'), isNull);
      expect(
        await repo.findByClientMutationId(core.Id.create(), 'retry-me'),
        isNull,
      );
    });

    test('append stores a new projection with no mutation', () async {
      final before = await inst.count('mutation_records');
      final next = nextProjection();

      expect(await repo.append(next), next);

      expect(await repo.findById(next.id), next);
      expect(await inst.count('mutation_records'), before);
    });

    test('append of a stored id is refused and changes nothing', () async {
      await expectLater(
        repo.append(projections.first),
        throwsA(isA<core.AlreadyStoredError>()),
      );
      expect(await repo.listForPublication(identity.id), projections);
    });

    test('a second projection with the same revision is refused', () async {
      await expectLater(
        repo.append(nextProjection(revision: 2, mutation: 'other')),
        throwsA(anything),
      );
      expect(await repo.listForPublication(identity.id), projections);
    });

    test('a second projection with the same mutation id is refused', () async {
      await repo.append(nextProjection(mutation: 'same'));

      await expectLater(
        repo.append(nextProjection(revision: 4, mutation: 'same')),
        throwsA(anything),
      );
      expect(await repo.listForPublication(identity.id), hasLength(2));
    });
  });
}
