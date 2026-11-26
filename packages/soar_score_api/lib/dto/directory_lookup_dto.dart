import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'directory_lookup_dto.g.dart';

/// What a director searches the pilot directory by, matched exactly.
@JsonEnum(fieldRename: FieldRename.snake)
enum DirectoryLookupKeyDto { email, faiNumber, nationalOrgId }

/// Body of `POST /api/v1/directory/lookups`: one [key] and its [value].
///
/// POST so an email never appears in a URL or an access log. A blank value
/// is 400.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class DirectoryLookupRequest {
  const DirectoryLookupRequest({required this.key, required this.value});

  factory DirectoryLookupRequest.fromJson(Map<String, dynamic> json) =>
      _$DirectoryLookupRequestFromJson(json);

  final DirectoryLookupKeyDto key;
  final String value;

  Map<String, dynamic> toJson() => _$DirectoryLookupRequestToJson(this);
}

/// A listed pilot as a director sees them.
///
/// [email] is set only when the pilot made it visible to directors;
/// [emailAvailable] says an email exists that the pilot keeps private.
/// [entryId] is what a copy or refresh names; it is not an account id.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class DirectoryMatchDto {
  const DirectoryMatchDto({
    required this.entryId,
    required this.firstName,
    required this.lastName,
    this.club,
    this.faiNumber,
    this.nationalOrgId,
    this.city,
    this.state,
    this.country,
    this.email,
    required this.emailAvailable,
  });

  factory DirectoryMatchDto.fromJson(Map<String, dynamic> json) =>
      _$DirectoryMatchDtoFromJson(json);

  final Id entryId;
  final String firstName;
  final String lastName;
  final String? club;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? city;
  final String? state;
  final String? country;
  final String? email;
  final bool emailAvailable;

  Map<String, dynamic> toJson() => _$DirectoryMatchDtoToJson(this);
}

/// Answer of `POST /api/v1/directory/lookups`: the listed pilots matching
/// the key (empty when none; an unlisted pilot is indistinguishable from
/// none).
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
  explicitToJson: true,
)
class DirectoryLookupResponse {
  const DirectoryLookupResponse({required this.results});

  factory DirectoryLookupResponse.fromJson(Map<String, dynamic> json) =>
      _$DirectoryLookupResponseFromJson(json);

  final List<DirectoryMatchDto> results;

  Map<String, dynamic> toJson() => _$DirectoryLookupResponseToJson(this);
}

/// Body of `POST /api/v1/directory/copies` and `/directory/refreshes`: the
/// directory entry and the director's own participant profile it is (or
/// becomes) a copy of. The profile id is chosen by the director's app and
/// the profile may not have synced yet.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class DirectoryCopyRequest {
  const DirectoryCopyRequest({required this.entryId, required this.profileId});

  factory DirectoryCopyRequest.fromJson(Map<String, dynamic> json) =>
      _$DirectoryCopyRequestFromJson(json);

  final Id entryId;
  final Id profileId;

  Map<String, dynamic> toJson() => _$DirectoryCopyRequestToJson(this);
}
