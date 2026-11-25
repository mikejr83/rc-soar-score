import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'directory_entry_dto.g.dart';

/// Body of `PUT /api/v1/account/directory-entry`: the details the signed-in
/// account offers contest directors (#652). Names are required; a blank
/// optional detail is stored as none.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class PutDirectoryEntryRequest {
  const PutDirectoryEntryRequest({
    required this.firstName,
    required this.lastName,
    this.club,
    this.faiNumber,
    this.nationalOrgId,
    this.city,
    this.state,
    this.country,
    required this.isListed,
    required this.emailVisibleToDirectors,
  });

  factory PutDirectoryEntryRequest.fromJson(Map<String, dynamic> json) =>
      _$PutDirectoryEntryRequestFromJson(json);

  final String firstName;
  final String lastName;
  final String? club;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? city;
  final String? state;
  final String? country;

  /// "Let contest directors find me".
  final bool isListed;

  /// Whether a director may see the account's email; off means private.
  final bool emailVisibleToDirectors;

  Map<String, dynamic> toJson() => _$PutDirectoryEntryRequestToJson(this);
}

/// The caller's own directory entry: `GET`/`PUT /api/v1/account/directory-entry`.
///
/// [entry] is null until the account has made one; the suggested names are
/// the account's own, to start from. [emailAvailable] says the account has a
/// verified email directors could be given; the address is never part of the
/// entry or of this answer.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
  explicitToJson: true,
)
class DirectoryEntryStateDto {
  const DirectoryEntryStateDto({
    required this.entry,
    required this.suggestedFirstName,
    required this.suggestedLastName,
    required this.emailAvailable,
  });

  factory DirectoryEntryStateDto.fromJson(Map<String, dynamic> json) =>
      _$DirectoryEntryStateDtoFromJson(json);

  final DirectoryEntryDto? entry;
  final String suggestedFirstName;
  final String suggestedLastName;
  final bool emailAvailable;

  Map<String, dynamic> toJson() => _$DirectoryEntryStateDtoToJson(this);
}

/// The details of an account's directory entry.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
@UtcTimestampConverter()
class DirectoryEntryDto {
  const DirectoryEntryDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.club,
    this.faiNumber,
    this.nationalOrgId,
    this.city,
    this.state,
    this.country,
    required this.isListed,
    required this.emailVisibleToDirectors,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DirectoryEntryDto.fromJson(Map<String, dynamic> json) =>
      _$DirectoryEntryDtoFromJson(json);

  final Id id;
  final String firstName;
  final String lastName;
  final String? club;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? city;
  final String? state;
  final String? country;
  final bool isListed;
  final bool emailVisibleToDirectors;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$DirectoryEntryDtoToJson(this);
}
