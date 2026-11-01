import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

class _FakeProfiles implements ParticipantProfileRepository {
  final Map<Id, ParticipantProfile> stored = {};
  final List<String> mutationIds = [];
  Id? failOn;

  @override
  Future<ParticipantProfile?> findById(Id id) async => stored[id];

  @override
  Future<List<ParticipantProfile>> listForOwner(Id accountId) async => [
    for (final p in stored.values)
      if (p.ownerAccountId == accountId) p,
  ];

  @override
  Future<ParticipantProfile> save(
    ParticipantProfile profile, {
    required MutationMetadata metadata,
  }) async {
    final current = stored[profile.id];
    if (profile.id == failOn) {
      throw StateError('boom');
    }
    if (current != null && current.revision != profile.revision) {
      throw StaleRevisionError(
        entityType: 'ParticipantProfile',
        entityId: profile.id,
        expectedRevision: profile.revision,
        storedRevision: current.revision,
      );
    }
    mutationIds.add(metadata.clientMutationId);
    return stored[profile.id] = ParticipantProfile.fromJson({
      ...profile.toJson(),
      'revision': current == null ? 0 : current.revision + 1,
    });
  }

  @override
  Future<List<ParticipantProfile>> saveAll(
    List<ParticipantProfile> profiles, {
    required MutationMetadata metadata,
  }) async {
    final before = Map<Id, ParticipantProfile>.of(stored);
    final idsBefore = mutationIds.length;
    try {
      return [
        for (final p in profiles)
          await save(p, metadata: metadata.forPart(p.id.value)),
      ];
    } on Object {
      stored
        ..clear()
        ..addAll(before);
      mutationIds.removeRange(idsBefore, mutationIds.length);
      rethrow;
    }
  }

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async =>
      stored.remove(id) != null;
}

final _owner = Id.create();
final _clock = DateTime.utc(2026, 11, 1, 12);
final _earlier = DateTime.utc(2026, 10, 1);

MutationMetadata _metadata([String id = 'op-1']) => MutationMetadata(
  clientMutationId: id,
  authority: Authority.director,
  clientTime: _clock,
  actorId: _owner,
);

ParticipantProfile _profile({
  String first = 'Alex',
  String last = 'Ashdown',
  String? email,
  String? club,
  String? state,
  String? fai,
}) => ParticipantProfile(
  id: Id.create(),
  ownerAccountId: _owner,
  firstName: first,
  lastName: last,
  email: email,
  club: club,
  state: state,
  faiNumber: fai,
  createdAt: _earlier,
  updatedAt: _earlier,
);

PilotDraft _draft({
  int no = 1,
  String first = 'Alex',
  String last = 'Ashdown',
  String? email,
  String? club,
  String? state,
  String? fai,
}) => PilotDraft(
  sourcePilotNo: no,
  firstName: first,
  lastName: last,
  email: email,
  club: club,
  state: state,
  faiNumber: fai,
);

void main() {
  const matcher = PilotImportMatcher();
  late _FakeProfiles repo;
  late PilotImportService service;

  setUp(() {
    repo = _FakeProfiles();
    service = PilotImportService(repo, clock: () => _clock);
  });

  Future<PilotImportOutcome> run(
    List<PilotDraft> drafts, {
    String op = 'op-1',
  }) async {
    final matches = matcher.match(drafts, repo.stored.values.toList());
    return service.apply(_owner, [
      for (final m in matches) PilotImportSelection.defaultFor(m),
    ], metadata: _metadata(op));
  }

  test('adds new pilots as profiles of the owner, email lower-cased', () async {
    final outcome = await run([
      _draft(email: 'New@X.test', club: 'Club', state: 'FL'),
      _draft(no: 2, first: 'Bea', last: 'Birch'),
    ]);
    expect(outcome.added, hasLength(2));
    final first = outcome.added.first;
    expect(first.ownerAccountId, _owner);
    expect(first.email, 'new@x.test');
    expect(first.club, 'Club');
    expect(first.createdAt, _clock);
    expect(first.revision, 0);
    expect(repo.stored, hasLength(2));
  });

  test('each profile is a mutation of the same operation', () async {
    await run([_draft(), _draft(no: 2, first: 'Bea', last: 'Birch')]);
    expect(repo.mutationIds, hasLength(2));
    expect(repo.mutationIds.every((m) => m.startsWith('op-1/')), isTrue);
  });

  test('an exact match is updated; blanks and names are kept', () async {
    final existing = _profile(first: 'Mike', last: 'G', email: 'm@x.test');
    repo.stored[existing.id] = existing;
    final outcome = await run([
      _draft(
        first: 'Michael',
        last: 'Gardner',
        email: 'M@x.test',
        club: 'Club',
      ),
    ]);
    expect(outcome.updated, hasLength(1));
    final updated = outcome.updated.single;
    expect(updated.id, existing.id);
    expect(updated.firstName, 'Mike');
    expect(updated.lastName, 'G');
    expect(updated.club, 'Club');
    expect(updated.revision, 1);
    expect(updated.createdAt, _earlier);
    expect(updated.updatedAt, _clock);
  });

  test('a blank value never clears an existing one', () async {
    final existing = _profile(email: 'a@x.test', state: 'FL', club: 'Keep');
    repo.stored[existing.id] = existing;
    final outcome = await run([_draft(email: 'a@x.test', state: 'CA')]);
    final updated = outcome.updated.single;
    expect(updated.club, 'Keep');
    expect(updated.state, 'CA');
  });

  test('importing the same file again changes nothing', () async {
    final drafts = [
      _draft(email: 'a@x.test', club: 'C'),
      _draft(no: 2, first: 'Bea', last: 'Birch', email: 'b@x.test'),
    ];
    await run(drafts);
    final snapshot = Map<Id, ParticipantProfile>.of(repo.stored);
    final again = await run(drafts, op: 'op-2');
    expect(again.added, isEmpty);
    expect(again.updated, isEmpty);
    expect(again.unchanged, 2);
    expect(repo.stored, snapshot);
  });

  test(
    'a likely match is skipped until chosen, then follows the choice',
    () async {
      final existing = _profile();
      repo.stored[existing.id] = existing;
      final match = matcher.match([_draft(club: 'Club')], [existing]).single;
      expect(match.kind, PilotMatchKind.likely);

      final skipped = await service.apply(_owner, [
        PilotImportSelection.defaultFor(match),
      ], metadata: _metadata());
      expect(skipped.skipped, 1);
      expect(repo.stored, hasLength(1));

      final asNew = await service.apply(_owner, [
        PilotImportSelection(match: match, choice: PilotImportChoice.add),
      ], metadata: _metadata('op-2'));
      expect(asNew.added, hasLength(1));
      expect(repo.stored, hasLength(2));

      final asUpdate = await service.apply(_owner, [
        PilotImportSelection(match: match, choice: PilotImportChoice.update),
      ], metadata: _metadata('op-3'));
      expect(asUpdate.updated.single.club, 'Club');
    },
  );

  test('an update that cannot name its profile is refused', () async {
    final a = _profile(email: 'e@x.test', first: 'A', last: 'A');
    final b = _profile(email: 'e@x.test', first: 'B', last: 'B');
    repo.stored
      ..[a.id] = a
      ..[b.id] = b;
    final match = matcher.match([_draft(email: 'e@x.test')], [a, b]).single;
    expect(
      () => service.apply(_owner, [
        PilotImportSelection(match: match, choice: PilotImportChoice.update),
      ], metadata: _metadata()),
      throwsArgumentError,
    );
  });

  test("another director's profile is not found", () async {
    final other = ParticipantProfile(
      id: Id.create(),
      ownerAccountId: Id.create(),
      firstName: 'X',
      lastName: 'Y',
      createdAt: _earlier,
      updatedAt: _earlier,
    );
    repo.stored[other.id] = other;
    final match = matcher.match([_draft()], const []).single;
    expect(
      () => service.apply(_owner, [
        PilotImportSelection(
          match: match,
          choice: PilotImportChoice.update,
          targetProfileId: other.id,
        ),
      ], metadata: _metadata()),
      throwsA(isA<EntityNotFoundError>()),
    );
  });

  test('a retry with the same new ids does not write twice', () async {
    final match = matcher.match([_draft()], const []).single;
    final selection = PilotImportSelection(
      match: match,
      choice: PilotImportChoice.add,
      newProfileId: Id.create(),
    );
    await service.apply(_owner, [selection], metadata: _metadata());
    final retry = await service.apply(_owner, [
      selection,
    ], metadata: _metadata());
    expect(retry.added, isEmpty);
    expect(repo.stored, hasLength(1));
    expect(repo.mutationIds, hasLength(1));
  });

  test('a failure part-way stores nothing', () async {
    final bad = Id.create();
    repo.failOn = bad;
    final matches = matcher.match([
      _draft(),
      _draft(no: 2, first: 'Bea', last: 'Birch'),
    ], const []);
    await expectLater(
      service.apply(_owner, [
        PilotImportSelection(match: matches[0], choice: PilotImportChoice.add),
        PilotImportSelection(
          match: matches[1],
          choice: PilotImportChoice.add,
          newProfileId: bad,
        ),
      ], metadata: _metadata()),
      throwsStateError,
    );
    expect(repo.stored, isEmpty);
  });

  test('two selections for one profile are applied in order', () async {
    final existing = _profile(email: 'a@x.test');
    repo.stored[existing.id] = existing;
    final matches = matcher.match(
      [
        _draft(email: 'a@x.test', club: 'First'),
        _draft(no: 2, email: 'a@x.test', state: 'CA'),
      ],
      [existing],
    );
    final outcome = await service.apply(_owner, [
      for (final m in matches)
        PilotImportSelection(
          match: m,
          choice: PilotImportChoice.update,
          targetProfileId: existing.id,
        ),
    ], metadata: _metadata());
    final updated = outcome.updated.single;
    expect(updated.club, 'First');
    expect(updated.state, 'CA');
    expect(updated.revision, 1);
  });

  test('retrying the default selections does not add twice', () async {
    final matches = matcher.match([
      _draft(),
      _draft(no: 2, first: 'Bea', last: 'Birch'),
    ], const []);
    final selections = [
      for (final m in matches) PilotImportSelection.defaultFor(m),
    ];
    await service.apply(_owner, selections, metadata: _metadata());
    final retry = await service.apply(
      _owner,
      selections,
      metadata: _metadata(),
    );
    expect(retry.added, isEmpty);
    expect(repo.stored, hasLength(2));
  });

  test('two new profiles with the same id in one batch are refused', () async {
    final matches = matcher.match([
      _draft(),
      _draft(no: 2, first: 'Bea', last: 'Birch'),
    ], const []);
    final id = Id.create();
    await expectLater(
      service.apply(_owner, [
        for (final m in matches)
          PilotImportSelection(
            match: m,
            choice: PilotImportChoice.add,
            newProfileId: id,
          ),
      ], metadata: _metadata()),
      throwsArgumentError,
    );
    expect(repo.stored, isEmpty);
  });

  test(
    'an update is refused when the profile changed after the review',
    () async {
      final existing = _profile(email: 'a@x.test');
      repo.stored[existing.id] = existing;
      final selections = [
        for (final m in matcher.match(
          [_draft(email: 'a@x.test', club: 'Imported')],
          [existing],
        ))
          PilotImportSelection.defaultFor(m),
      ];

      // The director edits the profile while the review is open.
      repo.stored[existing.id] = ParticipantProfile.fromJson({
        ...existing.toJson(),
        'club': 'Typed by hand',
        'revision': 1,
      });

      await expectLater(
        service.apply(_owner, selections, metadata: _metadata()),
        throwsA(isA<StaleRevisionError>()),
      );
      expect(repo.stored[existing.id]!.club, 'Typed by hand');
    },
  );

  test(
    'a conflicting match is not updated unless the director picks',
    () async {
      final a = _profile(first: 'A', last: 'A', email: 'e@x.test');
      final b = _profile(first: 'B', last: 'B', fai: 'F1');
      repo.stored
        ..[a.id] = a
        ..[b.id] = b;
      final match = matcher
          .match(
            [_draft(first: 'C', last: 'C', email: 'e@x.test', fai: 'F1')],
            [a, b],
          )
          .single;
      final outcome = await service.apply(_owner, [
        PilotImportSelection.defaultFor(match),
      ], metadata: _metadata());
      expect(outcome.skipped, 1);
      expect(repo.stored[a.id], a);
      expect(repo.stored[b.id], b);
    },
  );
}
