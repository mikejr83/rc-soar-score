import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/account_kind.dart';
import '../../enums/account_status.dart';
import '../id.dart';
import 'account_preferences.dart';
import '../shared/shared.dart';

part 'account.g.dart';

/// A person's identity within the backend.
///
/// Backend only. Clients never receive account rows, except an
/// installation's own local account. See `plan/data-model/entities/account.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class Account extends Equatable implements BackendOnly {
  Account({
    required this.id,
    required String firstName,
    required String lastName,
    String? email,
    this.emailVerified = false,
    required this.kind,
    this.status = AccountStatus.active,
    DateTime? archivedAt,
    this.isSystemAdmin = false,
    String? preferredTimeZone,
    String? preferredLocale,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : firstName = requireNotBlank(firstName, 'firstName'),
       lastName = requireNotBlank(lastName, 'lastName'),
       email = email?.trim().toLowerCase(),
       archivedAt = archivedAt?.toUtc(),
       preferredTimeZone = AccountPreferences(
         preferredTimeZone: preferredTimeZone,
       ).preferredTimeZone,
       preferredLocale = AccountPreferences(preferredLocale: preferredLocale)
           .preferredLocale,
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc() {
    if ((status == AccountStatus.archived) != (archivedAt != null)) {
      throw ArgumentError('archived_at is set exactly when archived');
    }
    if (this.email != null && this.email!.isEmpty) {
      throw ArgumentError.value(email, 'email', 'must not be blank');
    }
    if (emailVerified && kind == AccountKind.guest) {
      throw ArgumentError('a guest account never has a verified email');
    }
    if ((kind == AccountKind.local || kind == AccountKind.deleted) &&
        this.email != null) {
      throw ArgumentError('local and deleted accounts have no email');
    }
    if (kind == AccountKind.deleted && status == AccountStatus.archived) {
      throw ArgumentError('the deleted-user account cannot be archived');
    }
    if (isSystemAdmin && kind != AccountKind.registered) {
      throw ArgumentError('only a registered account can be a system admin');
    }
  }

  factory Account.fromJson(Map<String, Object?> json) =>
      _$AccountFromJson(json);

  final Id id;
  final String firstName;
  final String lastName;

  /// Stored lowercase; null for local and deleted accounts.
  final String? email;

  /// Snapshot of the identity provider's verified-email claim.
  final bool emailVerified;

  final AccountKind kind;
  final AccountStatus status;
  final DateTime? archivedAt;

  /// Set out of band by the backend, never through a client request.
  final bool isSystemAdmin;

  /// The person's preferred IANA time zone; null until chosen.
  final String? preferredTimeZone;

  /// The person's preferred locale; null until chosen.
  final String? preferredLocale;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// The preferences stored on the account.
  AccountPreferences get preferences => AccountPreferences(
    preferredTimeZone: preferredTimeZone,
    preferredLocale: preferredLocale,
  );

  /// This account with [preferences] stored, last modified at [now].
  Account withPreferences(AccountPreferences preferences, DateTime now) =>
      Account(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        emailVerified: emailVerified,
        kind: kind,
        status: status,
        archivedAt: archivedAt,
        isSystemAdmin: isSystemAdmin,
        preferredTimeZone: preferences.preferredTimeZone,
        preferredLocale: preferences.preferredLocale,
        createdAt: createdAt,
        updatedAt: now,
      );

  /// Whether the account can sign in at all.
  bool get canSignIn =>
      kind == AccountKind.registered && status == AccountStatus.active;

  Map<String, Object?> toJson() => _$AccountToJson(this);

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    emailVerified,
    kind,
    status,
    archivedAt,
    isSystemAdmin,
    preferredTimeZone,
    preferredLocale,
    createdAt,
    updatedAt,
  ];
}
