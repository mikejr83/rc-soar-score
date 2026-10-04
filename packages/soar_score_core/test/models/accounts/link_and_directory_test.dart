import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

ParticipantAccountLink link({
  ParticipantLinkStatus status = ParticipantLinkStatus.candidate,
  ParticipantLinkOrigin origin = ParticipantLinkOrigin.emailMatch,
  DateTime? confirmed,
  DateTime? ended,
}) => ParticipantAccountLink(
  id: exampleId(1),
  participantProfileId: exampleId(2),
  accountId: exampleId(3),
  status: status,
  origin: origin,
  createdAt: t0,
  confirmedAt: confirmed,
  endedAt: ended,
);

ParticipantDirectoryEntry entry({String first = 'Sam', bool listed = false}) =>
    ParticipantDirectoryEntry(
      id: exampleId(4),
      accountId: exampleId(3),
      firstName: first,
      lastName: 'Ortega',
      isListed: listed,
      createdAt: t0,
      updatedAt: t0,
    );

void main() {
  group('ParticipantAccountLink', () {
    test('round trips with documented enum text', () {
      final l = link();
      final json = l.toJson();
      expect(json['status'], 'Candidate');
      expect(json['origin'], 'EmailMatch');
      expect(l.revision, 0);
      expect(ParticipantAccountLink.fromJson(json), l);
      expect(l, isA<BackendOnly>());
    });

    test('a candidate is unconfirmed; a confirmed link says when', () {
      expect(() => link(confirmed: t0), throwsArgumentError);
      expect(
        () => link(status: ParticipantLinkStatus.confirmed),
        throwsArgumentError,
      );
      final ok = link(status: ParticipantLinkStatus.confirmed, confirmed: t0);
      expect(ok.isConfirmed, isTrue);
    });

    test('an ended link says when, and only then', () {
      expect(
        () => link(status: ParticipantLinkStatus.ended),
        throwsArgumentError,
      );
      expect(() => link(ended: t0), throwsArgumentError);
      expect(
        link(
          status: ParticipantLinkStatus.ended,
          confirmed: t0,
          ended: t0,
        ).isConfirmed,
        isFalse,
      );
    });

    test('a directory pull is confirmed on creation', () {
      expect(
        () => link(origin: ParticipantLinkOrigin.directoryPull),
        throwsArgumentError,
      );
      expect(
        link(
          origin: ParticipantLinkOrigin.directoryPull,
          status: ParticipantLinkStatus.confirmed,
          confirmed: t0,
        ).origin.name,
        'directoryPull',
      );
    });
  });

  group('ParticipantDirectoryEntry', () {
    test('round trips and defaults to unlisted', () {
      final e = entry();
      expect(e.isListed, isFalse);
      expect(e.emailVisibleToDirectors, isFalse);
      expect(ParticipantDirectoryEntry.fromJson(e.toJson()), e);
      expect(e, isA<BackendOnly>());
    });

    test('needs a first name', () {
      expect(() => entry(first: ' '), throwsArgumentError);
    });

    test('has no email field', () {
      expect(entry().toJson().containsKey('email'), isFalse);
    });
  });
}
