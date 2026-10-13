import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'account_alias.g.dart';

/// A Local account id that was claimed into a registered account.
///
/// The [id] is the id the installation generated for its Local account. After
/// the claim it still appears as owner or actor on late mutations, queued
/// mutations and imported copies, and the alias tells the backend which
/// registered account those references mean.
///
/// Backend only, never exposed to clients. See
/// `plan/data-model/entities/account_alias.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class AccountAlias extends Equatable implements BackendOnly {
  AccountAlias({
    required this.id,
    required this.accountId,
    required DateTime claimedAt,
  }) : claimedAt = claimedAt.toUtc() {
    if (id == accountId) {
      throw ArgumentError('an account is not an alias of itself');
    }
  }

  factory AccountAlias.fromJson(Map<String, Object?> json) =>
      _$AccountAliasFromJson(json);

  /// The claimed Local account id.
  final Id id;

  /// The registered account the Local account was claimed into.
  final Id accountId;

  final DateTime claimedAt;

  Map<String, Object?> toJson() => _$AccountAliasToJson(this);

  @override
  List<Object?> get props => [id, accountId, claimedAt];
}
