import 'package:logging/logging.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'principal.dart';
import 'token_verifier.dart';
import 'user_profile.dart';

final _logger = Logger('AccountPrincipalResolver');

/// Turns a verified token into the [Principal] of a registered account.
///
/// A returning identity maps to its account. A new identity gets a registered
/// account on its first request, filled in from the identity provider's
/// profile ([profiles]). Contest ownership then hangs off the account, never
/// off the issuer and subject.
class AccountPrincipalResolver {
  AccountPrincipalResolver({
    required this.accounts,
    required this.identities,
    required this.profiles,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AccountRepository accounts;
  final AccountIdentityRepository identities;
  final UserProfileSource profiles;
  final DateTime Function() _now;

  /// The principal for [token], which [accessToken] was verified into.
  ///
  /// Throws a [ForbiddenError] when the account cannot sign in (archived),
  /// and a [UserProfileUnavailableException] when a new account needs the
  /// profile and the provider does not answer.
  Future<Principal> resolve(VerifiedToken token, String accessToken) async {
    var identity = await identities.findBySubject(
      issuer: token.issuer,
      subject: token.subject,
    );
    identity ??= await _register(token, accessToken);

    final account = await accounts.findById(identity.accountId);
    if (account == null || !account.canSignIn) {
      throw ForbiddenError(
        'account_not_active',
        'This account cannot sign in.',
      );
    }
    return Principal(accountId: account.id);
  }

  Future<AccountIdentity> _register(
    VerifiedToken token,
    String accessToken,
  ) async {
    final profile = await profiles.fetch(accessToken);
    final now = _now().toUtc();

    // An email another account already uses is not copied: the same email at
    // a second login is only a candidate link, which a person confirms.
    var email = profile.email?.trim().toLowerCase();
    if (email != null &&
        (email.isEmpty || await accounts.findByEmail(email) != null)) {
      email = null;
    }
    final names = _names(profile, email);
    final account = Account(
      id: Id.create(),
      firstName: names.$1,
      lastName: names.$2,
      email: email,
      emailVerified: email != null && profile.emailVerified,
      kind: AccountKind.registered,
      createdAt: now,
      updatedAt: now,
    );
    final identity = AccountIdentity(
      id: Id.create(),
      accountId: account.id,
      issuer: token.issuer,
      subject: token.subject,
      createdAt: now,
    );

    try {
      await accounts.save(account);
      final saved = await identities.save(identity);
      _logger.info('Registered an account for a new sign-in.');
      return saved;
    } catch (_) {
      // Two first requests can race; the loser finds the winner's identity.
      final existing = await identities.findBySubject(
        issuer: token.issuer,
        subject: token.subject,
      );
      if (existing != null) return existing;
      rethrow;
    }
  }

  /// First and last name for a new account, which need both to be non-blank.
  (String, String) _names(UserProfile profile, String? email) {
    String? clean(String? value) {
      final trimmed = value?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    final given = clean(profile.givenName);
    final family = clean(profile.familyName);
    if (given != null && family != null) return (given, family);

    final full = clean(profile.name);
    if (full != null && full != email) {
      final parts = full.split(RegExp(r'\s+'));
      if (parts.length > 1) {
        return (given ?? parts.first, family ?? parts.skip(1).join(' '));
      }
      return (given ?? full, family ?? 'Unknown');
    }
    final local = email?.split('@').first;
    return (given ?? clean(local) ?? 'New user', family ?? 'Unknown');
  }
}
