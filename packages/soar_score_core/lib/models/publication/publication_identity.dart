import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/claim_status.dart';
import '../../enums/publication_visibility.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'publication_identity.g.dart';

/// The persistent identity of a published contest: owner, claim status and
/// visibility, independent of the private contest.
///
/// Backend only. See `plan/data-model/entities/publication_identity.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class PublicationIdentity extends Equatable implements BackendOnly {
  PublicationIdentity({
    required this.id,
    this.contestId,
    this.ownerPublicProfileId,
    this.claimStatus = ClaimStatus.unclaimed,
    this.verificationEmail,
    this.visibility = PublicationVisibility.unlisted,
    DateTime? publishedAt,
    this.currentProjectionId,
    this.resultsHiddenThroughRound,
    DateTime? resultsHiddenAt,
    this.revision = 0,
  }) : publishedAt = publishedAt?.toUtc(),
       resultsHiddenAt = resultsHiddenAt?.toUtc() {
    if ((claimStatus == ClaimStatus.claimed) !=
        (ownerPublicProfileId != null)) {
      throw ArgumentError(
        'owner_public_profile_id is set exactly when the publication is Claimed',
      );
    }
    if (claimStatus == ClaimStatus.unclaimed && verificationEmail == null) {
      throw ArgumentError('an unclaimed publication is found by its email');
    }
    if ((resultsHiddenThroughRound == null) != (resultsHiddenAt == null)) {
      throw ArgumentError(
        'results_hidden_through_round and results_hidden_at are set together',
      );
    }
    if (resultsHiddenThroughRound != null) {
      requirePositive(resultsHiddenThroughRound!, 'resultsHiddenThroughRound');
    }
    requireNonNegative(revision, 'revision');
  }

  factory PublicationIdentity.fromJson(Map<String, Object?> json) =>
      _$PublicationIdentityFromJson(json);

  final Id id;

  /// Null once the source contest has been deleted.
  final Id? contestId;

  /// Required when claimed; null for an unclaimed anonymous publication.
  final Id? ownerPublicProfileId;

  final ClaimStatus claimStatus;

  /// Verified private email of an anonymous publisher.
  final String? verificationEmail;

  final PublicationVisibility visibility;
  final DateTime? publishedAt;
  final Id? currentProjectionId;

  /// Copy of the contest's results-hiding setting.
  final int? resultsHiddenThroughRound;
  final DateTime? resultsHiddenAt;

  final int revision;

  bool get isDelisted => visibility == PublicationVisibility.delisted;

  Map<String, Object?> toJson() => _$PublicationIdentityToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    ownerPublicProfileId,
    claimStatus,
    verificationEmail,
    visibility,
    publishedAt,
    currentProjectionId,
    resultsHiddenThroughRound,
    resultsHiddenAt,
    revision,
  ];
}
