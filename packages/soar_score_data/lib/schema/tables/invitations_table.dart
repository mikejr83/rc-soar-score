import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'contest_participations_table.dart';

/// `Invitation`: the table of invitations, one column per model field.
@DataClassName('InvitationData')
class Invitations extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get contestParticipationId =>
      text().references(ContestParticipations, #id)();
  TextColumn get type => text().check(type.isIn(invitationTypeValues))();
  TextColumn get protectedCredential => text()();
  IntColumn get invitationRevision => integer()();
  TextColumn get state => text().check(state.isIn(invitationStateValues))();
  TextColumn get audience =>
      text().check(audience.isIn(invitationAudienceValues))();
  TextColumn get issuedBy => text()();
  TextColumn get issuedAt => text()();
  TextColumn get expiresAt => text().nullable()();
  TextColumn get firstUsedAt => text().nullable()();
  TextColumn get lastUsedAt => text().nullable()();
  TextColumn get revokedAt => text().nullable()();
  TextColumn get replacesInvitationId =>
      text().nullable().references(Invitations, #id)();
  TextColumn get redeemedByAccountId => text().nullable()();
  TextColumn get deliveryOutcomes => text()();
  TextColumn get clientMutationId => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {contestParticipationId, invitationRevision},
    {contestId, clientMutationId},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (state <> 'Revoked' OR revoked_at IS NOT NULL)",
  ];
}

/// Columns of `invitations` that hold JSON as text.
const invitationsJsonColumns = <String>{'delivery_outcomes'};
