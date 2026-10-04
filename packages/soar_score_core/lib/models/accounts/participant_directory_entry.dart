import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'participant_directory_entry.g.dart';

/// The basic details a person offers about themselves as a participant.
///
/// Backend only. A director can find a listed entry and copy it into their
/// own profile; the account's email is not stored here. See
/// `plan/data-model/entities/participant_directory_entry.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ParticipantDirectoryEntry extends Equatable implements BackendOnly {
  ParticipantDirectoryEntry({
    required this.id,
    required this.accountId,
    required String firstName,
    required String lastName,
    this.club,
    this.faiNumber,
    this.nationalOrgId,
    this.city,
    this.state,
    this.country,
    this.isListed = false,
    this.emailVisibleToDirectors = false,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : firstName = requireNotBlank(firstName, 'firstName'),
       lastName = requireNotBlank(lastName, 'lastName'),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc();

  factory ParticipantDirectoryEntry.fromJson(Map<String, Object?> json) =>
      _$ParticipantDirectoryEntryFromJson(json);

  final Id id;

  /// At most one entry per account.
  final Id accountId;

  final String firstName;
  final String lastName;
  final String? club;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? city;
  final String? state;
  final String? country;

  /// The participant's opt-in: only listed entries can be found.
  final bool isListed;

  /// Whether a director can see the account's email.
  final bool emailVisibleToDirectors;

  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$ParticipantDirectoryEntryToJson(this);

  @override
  List<Object?> get props => [
    id,
    accountId,
    firstName,
    lastName,
    club,
    faiNumber,
    nationalOrgId,
    city,
    state,
    country,
    isListed,
    emailVisibleToDirectors,
    createdAt,
    updatedAt,
  ];
}
