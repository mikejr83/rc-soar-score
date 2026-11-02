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
    this.contestName,
    DateTime? contestStartsAt,
    DateTime? contestEndsAt,
    this.venue,
    this.revision = 0,
  }) : publishedAt = publishedAt?.toUtc(),
       resultsHiddenAt = resultsHiddenAt?.toUtc(),
       contestStartsAt = contestStartsAt?.toUtc(),
       contestEndsAt = contestEndsAt?.toUtc() {
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

  /// Copies of the current projection's contest identity, kept so the public
  /// listing can filter and order in the database. Null before the first
  /// publish of a record written by an older version.
  final String? contestName;
  final DateTime? contestStartsAt;
  final DateTime? contestEndsAt;

  /// Host, city, state and country, whichever are set, joined with ", ".
  final String? venue;

  final int revision;

  /// This identity with [visibility] changed and everything else kept.
  PublicationIdentity withVisibility(PublicationVisibility visibility) =>
      PublicationIdentity(
        id: id,
        contestId: contestId,
        ownerPublicProfileId: ownerPublicProfileId,
        claimStatus: claimStatus,
        verificationEmail: verificationEmail,
        visibility: visibility,
        publishedAt: publishedAt,
        currentProjectionId: currentProjectionId,
        resultsHiddenThroughRound: resultsHiddenThroughRound,
        resultsHiddenAt: resultsHiddenAt,
        contestName: contestName,
        contestStartsAt: contestStartsAt,
        contestEndsAt: contestEndsAt,
        venue: venue,
        revision: revision,
      );

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
    contestName,
    contestStartsAt,
    contestEndsAt,
    venue,
    revision,
  ];
}
