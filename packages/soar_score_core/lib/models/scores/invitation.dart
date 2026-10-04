import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/invitation_audience.dart';
import '../../enums/invitation_state.dart';
import '../../enums/invitation_type.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'invitation.g.dart';

/// Participant access to a contest through a magic link or QR token.
///
/// Issued and replaced by the service. The protected credential is left out
/// of [toJson]; use [toSyncJson] on the sync and API path. See
/// `plan/data-model/entities/invitation.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
@ProtectedCredentialConverter()
class Invitation extends Equatable implements SyncScoped, PrivateData {
  Invitation({
    required this.id,
    required this.contestId,
    required this.contestParticipationId,
    this.type = InvitationType.magicUrl,
    required this.protectedCredential,
    this.invitationRevision = 1,
    this.state = InvitationState.active,
    this.audience = InvitationAudience.pilot,
    required this.issuedBy,
    required DateTime issuedAt,
    DateTime? expiresAt,
    DateTime? firstUsedAt,
    DateTime? lastUsedAt,
    DateTime? revokedAt,
    this.replacesInvitationId,
    this.redeemedByAccountId,
    List<Map<String, Object?>> deliveryOutcomes = const [],
    required String clientMutationId,
  }) : issuedAt = issuedAt.toUtc(),
       expiresAt = expiresAt?.toUtc(),
       firstUsedAt = firstUsedAt?.toUtc(),
       lastUsedAt = lastUsedAt?.toUtc(),
       revokedAt = revokedAt?.toUtc(),
       deliveryOutcomes = List.unmodifiable(
         deliveryOutcomes.map(Map<String, Object?>.unmodifiable),
       ),
       clientMutationId = requireNotBlank(
         clientMutationId,
         'clientMutationId',
       ) {
    requirePositive(invitationRevision, 'invitationRevision');
    if (replacesInvitationId == id) {
      throw ArgumentError('an invitation cannot replace itself');
    }
    if (this.expiresAt != null && this.expiresAt!.isBefore(this.issuedAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'must not precede issuedAt',
      );
    }
    if (this.lastUsedAt != null && this.firstUsedAt == null) {
      throw ArgumentError('last_used_at needs first_used_at');
    }
    if (state == InvitationState.revoked && this.revokedAt == null) {
      throw ArgumentError('a Revoked invitation records when it was revoked');
    }
  }

  factory Invitation.fromJson(Map<String, Object?> json) =>
      _$InvitationFromJson(json);

  final Id id;
  final Id contestId;
  final Id contestParticipationId;
  final InvitationType type;

  /// Protected form of the credential; the raw credential is never stored.
  final ProtectedCredential protectedCredential;

  /// Increases per participation; only the latest non-revoked one grants
  /// access.
  final int invitationRevision;

  final InvitationState state;
  final InvitationAudience audience;
  final Id issuedBy;
  final DateTime issuedAt;

  /// Null for field QR tokens, which last the whole contest.
  final DateTime? expiresAt;

  final DateTime? firstUsedAt;
  final DateTime? lastUsedAt;
  final DateTime? revokedAt;
  final Id? replacesInvitationId;

  /// The account that first redeemed the invitation.
  final Id? redeemedByAccountId;

  /// Delivery requests and results; delivery is not proof of receipt.
  final List<Map<String, Object?>> deliveryOutcomes;

  /// Idempotency key, unique within the contest.
  final String clientMutationId;

  bool get isActive => state == InvitationState.active;

  @override
  SyncScope get syncScope => SyncScope.issued;

  /// JSON without the protected credential, safe for logs and public use.
  Map<String, Object?> toJson() =>
      _$InvitationToJson(this)..remove('protected_credential');

  /// JSON with the protected credential, for the sync and API path only.
  Map<String, Object?> toSyncJson() => _$InvitationToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    contestParticipationId,
    type,
    protectedCredential,
    invitationRevision,
    state,
    audience,
    issuedBy,
    issuedAt,
    expiresAt,
    firstUsedAt,
    lastUsedAt,
    revokedAt,
    replacesInvitationId,
    redeemedByAccountId,
    deliveryOutcomes,
    clientMutationId,
  ];
}
