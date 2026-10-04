import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'participant_profile.g.dart';

/// A director's own record of a person, kept apart from any contest.
///
/// Private to the owning director. See
/// `plan/data-model/entities/participant_profile.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ParticipantProfile extends Equatable
    implements Synchronizable, PrivateData {
  ParticipantProfile({
    required this.id,
    required this.ownerAccountId,
    required String firstName,
    required String lastName,
    this.club,
    this.faiNumber,
    this.nationalOrgId,
    this.city,
    this.state,
    this.country,
    this.email,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.revision = 0,
  }) : firstName = requireNotBlank(firstName, 'firstName'),
       lastName = requireNotBlank(lastName, 'lastName'),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc() {
    requireNonNegative(revision, 'revision');
  }

  factory ParticipantProfile.fromJson(Map<String, Object?> json) =>
      _$ParticipantProfileFromJson(json);

  @override
  final Id id;

  /// The director who owns and maintains this profile.
  final Id ownerAccountId;

  final String firstName;
  final String lastName;
  final String? club;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? city;
  final String? state;
  final String? country;

  /// Always private; never appears in a public projection.
  final String? email;

  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  final int revision;

  @override
  String get entityType => 'ParticipantProfile';

  @override
  SyncScope get syncScope => SyncScope.director;

  Map<String, Object?> toJson() => _$ParticipantProfileToJson(this);

  @override
  List<Object?> get props => [
    id,
    ownerAccountId,
    firstName,
    lastName,
    club,
    faiNumber,
    nationalOrgId,
    city,
    state,
    country,
    email,
    createdAt,
    updatedAt,
    revision,
  ];
}
