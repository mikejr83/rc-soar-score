import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'account_public_profile.g.dart';

/// The public stand-in for an account, used in publications.
///
/// Backend only. It holds only what the account chose to make public. See
/// `plan/data-model/entities/account_public_profile.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class AccountPublicProfile extends Equatable implements BackendOnly {
  AccountPublicProfile({
    required this.id,
    this.accountId,
    required String displayName,
    required DateTime createdAt,
  }) : displayName = requireNotBlank(displayName, 'displayName'),
       createdAt = createdAt.toUtc();

  factory AccountPublicProfile.fromJson(Map<String, Object?> json) =>
      _$AccountPublicProfileFromJson(json);

  /// Used in publications.
  final Id id;

  /// Null once the profile has been unlinked from its account.
  final Id? accountId;

  final String displayName;
  final DateTime createdAt;

  bool get isUnlinked => accountId == null;

  Map<String, Object?> toJson() => _$AccountPublicProfileToJson(this);

  @override
  List<Object?> get props => [id, accountId, displayName, createdAt];
}
