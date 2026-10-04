import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../support/example_files.dart';

/// Keeps private data out of the publication models.
///
/// Dart has no reflection here, so the fields of each public model are a
/// hand-kept list: adding a field to one fails this test until the list, and
/// so a reviewer, accepts it.
const _projectionFields = {
  'id',
  'publication_id',
  'projection_revision',
  'contest_revision',
  'config_revision',
  'matrix_revision',
  'discipline_type',
  'discipline_rules_version',
  'calculation_version',
  'contest_identity',
  'participants',
  'teams',
  'matrix_info',
  'scores',
  'standings',
  'calculation_metadata',
  'published_at',
  'published_by',
  'client_mutation_id',
};

const _participantFields = {
  'id',
  'publication_id',
  'pilot_key',
  'source_participation_id',
  'details',
  'public_profile_id',
  'redacted_at',
  'created_at',
  'updated_at',
};

/// Field names that carry private data wherever they appear.
const _privateFieldNames = {
  'email',
  'verification_email',
  'protected_credential',
  'issuer',
  'subject',
  'first_name',
  'last_name',
  'owner_account_id',
  'account_id',
  'invitation_id',
  'actor_id',
  'raw_components',
  'proposed_components',
  'participant_message',
  'delivery_outcomes',
};

void main() {
  final files = ExampleFiles.locate();
  final catalog = files.catalog();

  Map<String, Object?> firstRow(String entity) =>
      files.rows(catalog.singleWhere((e) => e.entity == entity)).first.json;

  test('the publication models declare exactly the reviewed fields', () {
    final projection = PublicationProjection.fromJson(
      firstRow('PublicationProjection'),
    );
    final participant = PublicationParticipant.fromJson(
      firstRow('PublicationParticipant'),
    );
    expect(projection.toJson().keys.toSet(), _projectionFields);
    expect(participant.toJson().keys.toSet(), _participantFields);
  });

  test('no reviewed publication field is a private field name', () {
    expect(_projectionFields.intersection(_privateFieldNames), isEmpty);
    expect(_participantFields.intersection(_privateFieldNames), isEmpty);
  });

  test('the publication models are not private data', () {
    expect(
      PublicationProjection.fromJson(firstRow('PublicationProjection')),
      isNot(isA<PrivateData>()),
    );
    expect(
      PublicationParticipant.fromJson(firstRow('PublicationParticipant')),
      isNot(isA<PrivateData>()),
    );
  });

  test('the entities that hold private data are marked', () {
    expect(
      ParticipantProfile.fromJson(firstRow('ParticipantProfile')),
      isA<PrivateData>(),
    );
    expect(
      AccountIdentity.fromJson(firstRow('AccountIdentity')),
      isA<PrivateData>(),
    );
    expect(Invitation.fromJson(firstRow('Invitation')), isA<PrivateData>());
    expect(AuditEvent.fromJson(firstRow('AuditEvent')), isA<PrivateData>());
  });

  test('projection content names pilots only by key', () {
    final projection = PublicationProjection.fromJson(
      firstRow('PublicationProjection'),
    );
    final content = [
      projection.participants,
      projection.teams,
      projection.matrixInfo,
      projection.scores,
      projection.standings,
    ].toString();
    final details = PublicationParticipant.fromJson(
      firstRow('PublicationParticipant'),
    ).details!;
    for (final value in details.values) {
      expect(content, isNot(contains('$value')));
    }
    expect(content, isNot(contains('email')));
    expect(content, isNot(contains('@')));
  });

  test('a redacted participant leaves no details behind', () {
    final row = PublicationParticipant.fromJson(
      firstRow('PublicationParticipant'),
    );
    final redacted = PublicationParticipant(
      id: row.id,
      publicationId: row.publicationId,
      pilotKey: row.pilotKey,
      redactedAt: DateTime.utc(2026, 10, 20),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
    expect(redacted.toJson().toString(), isNot(contains('Ortega')));
    expect(redacted.details, isNull);
    expect(redacted.publicProfileId, isNull);
  });

  test('the credential stays out of plain JSON and text output', () {
    final invitation = Invitation.fromJson(firstRow('Invitation'));
    expect(invitation.toJson().containsKey('protected_credential'), isFalse);
    expect(invitation.toJson().toString(), isNot(contains('pbkdf2')));
    expect(
      invitation.protectedCredential.toString(),
      isNot(contains('pbkdf2')),
    );
  });
}
