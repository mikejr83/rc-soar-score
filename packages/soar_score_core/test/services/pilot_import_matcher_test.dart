import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

final _owner = Id.create();
final _now = DateTime.utc(2026, 11, 1);

ParticipantProfile _profile({
  String first = 'Alex',
  String last = 'Ashdown',
  String? email,
  String? fai,
  String? org,
  String? club,
  String? city,
  String? state,
  String? country,
}) => ParticipantProfile(
  id: Id.create(),
  ownerAccountId: _owner,
  firstName: first,
  lastName: last,
  email: email,
  faiNumber: fai,
  nationalOrgId: org,
  club: club,
  city: city,
  state: state,
  country: country,
  createdAt: _now,
  updatedAt: _now,
);

PilotDraft _draft({
  int no = 1,
  String first = 'Alex',
  String last = 'Ashdown',
  String? email,
  String? fai,
  String? org,
  String? club,
  String? city,
  String? state,
  String? country,
}) => PilotDraft(
  sourcePilotNo: no,
  firstName: first,
  lastName: last,
  email: email,
  faiNumber: fai,
  nationalOrgId: org,
  club: club,
  city: city,
  state: state,
  country: country,
);

void main() {
  const matcher = PilotImportMatcher();

  PilotMatch one(PilotDraft d, List<ParticipantProfile> existing) =>
      matcher.match([d], existing).single;

  group('remembered links', () {
    late ParticipantProfile profile;
    late PilotImportLink link;
    setUp(() {
      profile = _profile();
      link = PilotImportLink(
        id: Id.create(),
        ownerAccountId: _owner,
        sourcePilotNo: 1,
        participantProfileId: profile.id,
        sourceValues: PilotImportMatcher.sourceValues(_draft()),
        createdAt: _now,
        updatedAt: _now,
      );
    });
    test('previous name-only decision is selected automatically', () {
      final m = matcher.match([_draft()], [profile], links: [link]).single;
      expect(m.remembered, isTrue);
      expect(m.candidateIds, [profile.id]);
      expect(m.defaultAction, PilotImportAction.update);
    });
    test('changed source data needs approval', () {
      final m = matcher
          .match([_draft(club: 'New Club')], [profile], links: [link])
          .single;
      expect(m.sourceChanged, isTrue);
      expect(m.defaultAction, PilotImportAction.ask);
      expect(PilotImportSelection.defaultFor(m).targetProfileId, profile.id);
    });
    test('format-only source differences do not require approval', () {
      final m = matcher
          .match(
            [_draft(first: ' ALEX ', last: 'ashdown')],
            [profile],
            links: [link],
          )
          .single;
      expect(m.sourceChanged, isFalse);
      expect(m.defaultAction, PilotImportAction.update);
    });
    test('extra or absent empty snapshot fields do not invent a change', () {
      final incomplete = PilotImportLink(
        id: link.id,
        ownerAccountId: link.ownerAccountId,
        sourcePilotNo: link.sourcePilotNo,
        participantProfileId: link.participantProfileId,
        sourceValues: const {
          'firstName': 'alex',
          'lastName': 'ashdown',
          'futureField': 'retained',
        },
        createdAt: link.createdAt,
        updatedAt: link.updatedAt,
      );
      final match = matcher
          .match([_draft()], [profile], links: [incomplete])
          .single;
      expect(match.sourceChanged, isFalse);
      expect(match.sourceChanges, isEmpty);
    });
    test('deleted participant cannot be resolved', () {
      final m = matcher.match([_draft()], [], links: [link]).single;
      expect(m.remembered, isFalse);
      expect(m.kind, PilotMatchKind.newPilot);
    });
    test('conflicting identifier is not selected automatically', () {
      final other = _profile(email: 'other@example.com');
      final m = matcher
          .match(
            [_draft(email: 'other@example.com')],
            [profile, other],
            links: [link],
          )
          .single;
      expect(m.conflict, isTrue);
      expect(m.defaultAction, PilotImportAction.ask);
    });
  });

  group('kinds', () {
    test('nobody in the list means new, added by default', () {
      final m = one(_draft(), const []);
      expect(m.kind, PilotMatchKind.newPilot);
      expect(m.defaultAction, PilotImportAction.add);
      expect(m.candidateIds, isEmpty);
    });

    test('same email is exact, ignoring case and padding', () {
      final p = _profile(first: 'Other', last: 'Name', email: 'a@x.test');
      final m = one(_draft(email: '  A@X.TEST '), [p]);
      expect(m.kind, PilotMatchKind.exact);
      expect(m.rule, PilotMatchRule.email);
      expect(m.candidateIds, [p.id]);
      expect(m.defaultAction, PilotImportAction.update);
    });

    test('FAI number and national org id match without case or spaces', () {
      final byFai = one(_draft(first: 'X', last: 'Y', fai: 'fai 123'), [
        _profile(first: 'P', last: 'Q', fai: 'FAI123'),
      ]);
      expect(byFai.rule, PilotMatchRule.faiNumber);
      expect(byFai.kind, PilotMatchKind.exact);

      final byOrg = one(_draft(first: 'X', last: 'Y', org: 'nat-1'), [
        _profile(first: 'P', last: 'Q', org: 'NAT-1'),
      ]);
      expect(byOrg.rule, PilotMatchRule.nationalOrgId);
    });

    test('identifiers that point at different profiles are a conflict', () {
      final byEmail = _profile(first: 'A', last: 'A', email: 'e@x.test');
      final byFai = _profile(first: 'B', last: 'B', fai: 'F1');
      final m = one(
        _draft(first: 'C', last: 'C', email: 'e@x.test', fai: 'F1'),
        [byFai, byEmail],
      );
      expect(m.kind, PilotMatchKind.likely);
      expect(m.conflict, isTrue);
      expect(m.rule, PilotMatchRule.email);
      expect(m.candidateIds, unorderedEquals([byEmail.id, byFai.id]));
      expect(m.defaultAction, PilotImportAction.ask);
      expect(m.changes, isEmpty);
    });

    test('an incoming FAI number owned by another profile is a conflict', () {
      final owner = _profile(first: 'A', last: 'A', email: 'e@x.test');
      final other = _profile(first: 'B', last: 'B', fai: 'F9');
      final m = one(
        _draft(first: 'A', last: 'A', email: 'e@x.test', fai: 'F9'),
        [owner, other],
      );
      expect(m.conflict, isTrue);
      expect(m.kind, PilotMatchKind.likely);
    });

    test('identifiers that agree on one profile stay exact', () {
      final p = _profile(first: 'A', last: 'A', email: 'e@x.test', fai: 'F1');
      final m = one(_draft(email: 'e@x.test', fai: 'f1'), [p]);
      expect(m.kind, PilotMatchKind.exact);
      expect(m.conflict, isFalse);
      expect(m.candidateIds, [p.id]);
    });

    test('an identifier only one profile holds still matches', () {
      final p = _profile(first: 'A', last: 'A', email: 'e@x.test');
      final m = one(_draft(email: 'e@x.test', fai: 'NEW1'), [p]);
      expect(m.kind, PilotMatchKind.exact);
      expect(m.changes.single.field, 'faiNumber');
    });

    test('the matcher records the revision of each candidate', () {
      final p = _profile(email: 'e@x.test');
      final m = one(_draft(email: 'e@x.test'), [p]);
      expect(m.candidateRevisions, {p.id: p.revision});
    });

    test('name alone is only a likely match, with no default', () {
      final p = _profile(first: 'Zoë', last: 'Åkerman');
      final m = one(_draft(first: 'zoe', last: ' akerman '), [p]);
      expect(m.kind, PilotMatchKind.likely);
      expect(m.rule, PilotMatchRule.name);
      expect(m.defaultAction, PilotImportAction.ask);
      expect(m.changes, isEmpty);
    });

    test('several profiles on one key need a decision', () {
      final a = _profile(first: 'A', last: 'A', email: 'e@x.test');
      final b = _profile(first: 'B', last: 'B', email: 'e@x.test');
      final m = one(_draft(email: 'e@x.test'), [a, b]);
      expect(m.kind, PilotMatchKind.likely);
      expect(m.rule, PilotMatchRule.email);
      expect(m.candidateIds, unorderedEquals([a.id, b.id]));
    });

    test('a different person with the same blank keys is new', () {
      final m = one(_draft(first: 'New', last: 'Person'), [
        _profile(first: 'Old', last: 'Person'),
      ]);
      expect(m.kind, PilotMatchKind.newPilot);
    });
  });

  group('upsert', () {
    test('non-blank values replace, blanks never clear', () {
      final p = _profile(
        email: 'a@x.test',
        club: 'Old club',
        city: 'Oldtown',
        state: 'FL',
        country: 'Canada',
      );
      final m = one(
        _draft(
          email: 'a@x.test',
          club: 'New club',
          city: null,
          state: 'CA',
          country: 'United States',
        ),
        [p],
      );
      expect(m.kind, PilotMatchKind.exact);
      expect(
        {for (final c in m.changes) c.field: c.to},
        {'club': 'New club', 'state': 'CA', 'country': 'United States'},
      );
      expect(m.changes.firstWhere((c) => c.field == 'club').from, 'Old club');
    });

    test('fills a field the profile was missing', () {
      final p = _profile(fai: 'F1');
      final m = one(_draft(fai: 'F1', email: 'new@x.test'), [p]);
      final change = m.changes.single;
      expect(change.field, 'email');
      expect(change.from, isNull);
      expect(change.to, 'new@x.test');
    });

    test('never changes names or the field the match was made on', () {
      final p = _profile(first: 'Mike', last: 'G', email: 'm@x.test');
      final m = one(
        _draft(first: 'Michael', last: 'Gardner', email: 'M@X.TEST'),
        [p],
      );
      expect(m.changes, isEmpty);
      expect(m.isUnchanged, isTrue);
    });

    test('values equal after normalising are not changes', () {
      final p = _profile(email: 'a@x.test', fai: 'FAI 1', org: 'n-1');
      final m = one(_draft(email: 'a@x.test', fai: 'fai1', org: 'N-1'), [p]);
      expect(m.isUnchanged, isTrue);
    });
  });

  group('duplicates in the file', () {
    test('a second draft of the same person is flagged and asks', () {
      final matches = matcher.match([
        _draft(no: 1, first: 'Sam', last: 'Twin'),
        _draft(no: 2, first: 'Sam', last: 'Twin'),
      ], const []);
      expect(matches[0].isDuplicateInFile, isFalse);
      expect(matches[0].defaultAction, PilotImportAction.add);
      expect(matches[1].duplicateOfSourcePilotNo, 1);
      expect(matches[1].defaultAction, PilotImportAction.ask);
    });

    test('a shared email flags the second even with different names', () {
      final matches = matcher.match([
        _draft(no: 1, first: 'A', last: 'One', email: 's@x.test'),
        _draft(no: 2, first: 'B', last: 'Two', email: ' S@x.test'),
      ], const []);
      expect(matches[1].duplicateOfSourcePilotNo, 1);
    });
  });

  group('name normalisation', () {
    test('ignores case, accents, ligatures and repeated spaces', () {
      String n(String f, String l) => PilotImportMatcher.normalizeName(f, l);
      expect(n('Zoë', 'Åkerman'), n('zoe', ' akerman'));
      expect(n('Jörg', 'Straße'), n('JORG', 'Strasse'));
      expect(n('Æsa', 'Ørsted'), n('aesa', 'orsted'));
      expect(n('Anne  Marie', 'X'), n('anne marie', 'x'));
    });

    test('keeps names that differ apart', () {
      String n(String f, String l) => PilotImportMatcher.normalizeName(f, l);
      expect(n('Jon', 'Smith'), isNot(n('John', 'Smith')));
    });

    test('email and number normalisation', () {
      expect(PilotImportMatcher.normalizeEmail('  A@B.C '), 'a@b.c');
      expect(PilotImportMatcher.normalizeEmail('   '), isNull);
      expect(PilotImportMatcher.normalizeNumber(' fai 12 '), 'FAI12');
      expect(PilotImportMatcher.normalizeNumber(''), isNull);
    });
  });

  group('re-importing', () {
    test(
      'importing a file whose pilots are all in the list changes nothing',
      () {
        final drafts = [
          _draft(no: 1, first: 'A', last: 'One', email: 'a@x.test', club: 'C'),
          _draft(no: 2, first: 'B', last: 'Two', email: 'b@x.test'),
        ];
        final existing = [
          _profile(first: 'A', last: 'One', email: 'a@x.test', club: 'C'),
          _profile(first: 'B', last: 'Two', email: 'b@x.test'),
        ];
        final matches = matcher.match(drafts, existing);
        expect(matches.every((m) => m.kind == PilotMatchKind.exact), isTrue);
        expect(matches.every((m) => m.isUnchanged), isTrue);
      },
    );
  });

  group('edge cases from the import fixture', () {
    test('finds the same-name and shared-email duplicates', () {
      // Same name pair (1001/1002) and shared email pair (1003/1004).
      final drafts = [
        _draft(no: 1001, first: 'Sam', last: 'Twin'),
        _draft(no: 1002, first: 'Sam', last: 'Twin'),
        _draft(
          no: 1003,
          first: 'Ellis',
          last: 'Shared',
          email: 'shared@x.test',
        ),
        _draft(
          no: 1004,
          first: 'Ellis',
          last: 'Sharedname',
          email: '  Shared@X.TEST ',
        ),
      ];
      final flagged = [
        for (final m in matcher.match(drafts, const []))
          if (m.isDuplicateInFile) m.draft.sourcePilotNo,
      ];
      expect(flagged, [1002, 1004]);
    });
  });

  group('a pilot whose link is under review', () {
    PilotImportLink linkFor(ParticipantProfile profile, int no) =>
        PilotImportLink(
          id: Id.create(),
          ownerAccountId: _owner,
          sourcePilotNo: no,
          participantProfileId: profile.id,
          sourceValues: PilotImportMatcher.sourceValues(
            _draft(no: no, first: profile.firstName, last: profile.lastName),
          ),
          createdAt: _now,
          updatedAt: _now,
        );

    test('is held back: no link and no guess from the file is used', () {
      final ada = _profile(first: 'Ada', last: 'Lovelace', email: 'a@x.test');
      final held = matcher
          .match(
            [_draft(no: 7, first: 'Ada', last: 'Lovelace', email: 'a@x.test')],
            [ada],
            links: [linkFor(ada, 7)],
            pilotsUnderReview: {7},
          )
          .single;

      expect(held.linkReview, isTrue);
      expect(held.remembered, isFalse);
      expect(held.candidateIds, isEmpty);
      expect(held.defaultAction, PilotImportAction.ask);
      final selection = PilotImportSelection.defaultFor(held);
      expect(selection.choice, PilotImportChoice.skip);
      expect(selection.targetProfileId, isNull);
    });

    test('leaves the other pilots of the file alone', () {
      final ada = _profile(first: 'Ada', last: 'Lovelace');
      final grace = _profile(first: 'Grace', last: 'Hopper');
      final matches = matcher.match(
        [
          _draft(no: 7, first: 'Ada', last: 'Lovelace'),
          _draft(no: 8, first: 'Grace', last: 'Hopper'),
        ],
        [ada, grace],
        links: [linkFor(ada, 7), linkFor(grace, 8)],
        pilotsUnderReview: {7},
      );

      expect(matches[0].linkReview, isTrue);
      expect(matches[1].linkReview, isFalse);
      expect(matches[1].remembered, isTrue);
      expect(matches[1].candidateIds, [grace.id]);
      expect(matches[1].defaultAction, PilotImportAction.update);
    });
  });
}
