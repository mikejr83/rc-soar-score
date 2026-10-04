import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'publication_participant.g.dart';

/// The identifying details of a pilot shown in a publication, kept apart from
/// the published results.
///
/// Backend only. Redaction deletes the details and cannot be undone. See
/// `plan/data-model/entities/publication_participant.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class PublicationParticipant extends Equatable implements BackendOnly {
  PublicationParticipant({
    required this.id,
    required this.publicationId,
    required String pilotKey,
    this.sourceParticipationId,
    Map<String, Object?>? details,
    this.publicProfileId,
    DateTime? redactedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : pilotKey = requireNotBlank(pilotKey, 'pilotKey'),
       details = details == null ? null : Map.unmodifiable(details),
       redactedAt = redactedAt?.toUtc(),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc() {
    if (redactedAt != null && (details != null || publicProfileId != null)) {
      throw ArgumentError(
        'a redacted row has no details and no public profile',
      );
    }
  }

  factory PublicationParticipant.fromJson(Map<String, Object?> json) =>
      _$PublicationParticipantFromJson(json);

  final Id id;
  final Id publicationId;

  /// Opaque key that identifies the pilot inside projection content.
  final String pilotKey;

  /// A plain reference, cleared when the contest's working data is deleted.
  final Id? sourceParticipationId;

  /// Identifying fields the results show; null once redacted.
  final Map<String, Object?>? details;

  /// Set only through a verified link between the pilot and an account.
  final Id? publicProfileId;

  /// When the details were redacted; write-once.
  final DateTime? redactedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRedacted => redactedAt != null;

  Map<String, Object?> toJson() => _$PublicationParticipantToJson(this);

  @override
  List<Object?> get props => [
    id,
    publicationId,
    pilotKey,
    sourceParticipationId,
    details,
    publicProfileId,
    redactedAt,
    createdAt,
    updatedAt,
  ];
}
