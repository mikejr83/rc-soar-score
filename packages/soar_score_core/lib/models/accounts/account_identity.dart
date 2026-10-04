import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'account_identity.g.dart';

/// A login at an identity provider, kept apart from the account itself.
///
/// Backend only, never exposed to clients. See
/// `plan/data-model/entities/account_identity.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class AccountIdentity extends Equatable implements BackendOnly, PrivateData {
  AccountIdentity({
    required this.id,
    required this.accountId,
    required String issuer,
    required String subject,
    required DateTime createdAt,
  }) : issuer = requireNotBlank(issuer, 'issuer'),
       subject = requireNotBlank(subject, 'subject'),
       createdAt = createdAt.toUtc();

  factory AccountIdentity.fromJson(Map<String, Object?> json) =>
      _$AccountIdentityFromJson(json);

  final Id id;
  final Id accountId;

  /// The identity provider that issued the subject.
  final String issuer;

  /// The provider's stable subject identifier; meaningful only with [issuer].
  final String subject;

  final DateTime createdAt;

  Map<String, Object?> toJson() => _$AccountIdentityToJson(this);

  @override
  List<Object?> get props => [id, accountId, issuer, subject, createdAt];
}
