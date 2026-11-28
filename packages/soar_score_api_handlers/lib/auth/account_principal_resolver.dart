import 'package:logging/logging.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'account_profile_refresher.dart';
import 'principal.dart';
import 'email_takeover.dart';
import 'profile_names.dart';
import 'token_verifier.dart';
import 'user_profile.dart';

final _logger = Logger('AccountPrincipalResolver');

/// Turns a verified token into the [Principal] of a registered account.
///
/// A returning identity maps to its account. A new identity gets a registered
/// account on its first request, filled in from the identity provider's
/// profile ([profiles]). Contest ownership then hangs off the account, never
/// off the issuer and subject. A returning account's name, email and verified
/// flag are refreshed from the same profile when due
/// ([AccountProfileRefresher]).
class AccountPrincipalResolver {
  AccountPrincipalResolver({
    required this.accounts,
    required this.identities,
    required this.profiles,
    DateTime Function()? now,
    AccountProfileRefresher? refresher,
  }) : _now = now ?? DateTime.now,
       _refresher =
           refresher ??
           AccountProfileRefresher(
             accounts: accounts,
             profiles: profiles,
             now: now,
           );

  final AccountRepository accounts;
  final AccountIdentityRepository identities;
  final UserProfileSource profiles;
  final DateTime Function() _now;
  final AccountProfileRefresher _refresher;

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
    // After the first request the profile is refreshed when due; a refresh
    // never fails the request.
    await _refresher.refresh(account, accessToken);
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
    if (email != null) {
      if (email.isEmpty) {
        email = null;
      } else if (await accounts.findByEmail(email) != null) {
        // Only an address the provider verified can take it from an account
        // that never verified it.
        final freed =
            profile.emailVerified &&
            await freeEmailForVerifiedClaimant(
              accounts,
              email,
              claimant: null,
              now: now,
            );
        if (!freed) email = null;
      }
    }
    final names = newAccountNames(profile, email);
    final account = Account(
      id: Id.create(),
      firstName: names.$1,
      lastName: names.$2,
      email: email,
      emailVerified: email != null && profile.emailVerified,
      profileRefreshedAt: now,
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
}
