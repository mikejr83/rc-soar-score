import 'package:logging/logging.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'email_takeover.dart';
import 'profile_names.dart';
import 'user_profile.dart';

final _logger = Logger('AccountProfileRefresher');

/// Keeps a registered account's name, email and verified flag in step with
/// the identity provider.
///
/// A new account copies the profile once. Without a refresh, a person who
/// verifies the email afterwards, or changes it, stays as first recorded.
/// The refresh asks the provider with the caller's own access token, so no
/// management credential is needed.
///
/// It never fails a request: a provider that is down, slow or answers with
/// junk leaves the stored values as they are. Log lines carry counts and
/// reasons, never an email address.
class AccountProfileRefresher {
  AccountProfileRefresher({
    required this.accounts,
    required this.profiles,
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 3),
  }) : _now = now ?? DateTime.now;

  /// A verified account is asked again after this long.
  static const staleAfter = Duration(hours: 24);

  /// No account is asked more often than this, verified or not.
  static const minInterval = Duration(minutes: 10);

  final AccountRepository accounts;
  final UserProfileSource profiles;
  final Duration timeout;
  final DateTime Function() _now;

  /// Whether [account] is due for a refresh at [now].
  ///
  /// An archived account cannot sign in, so the resolver never gets here for
  /// one.
  bool isDue(Account account, DateTime now) {
    if (account.kind != AccountKind.registered) return false;
    final last = account.profileRefreshedAt;
    if (last == null) return true;
    final age = now.difference(last);
    if (age < minInterval) return false;
    return !account.emailVerified || age >= staleAfter;
  }

  /// Refreshes [account] from the provider when it is due; never throws.
  Future<void> refresh(Account account, String accessToken) async {
    try {
      await _refresh(account, accessToken);
    } on Object catch (e) {
      _logger.warning('Profile refresh failed (${e.runtimeType}).');
    }
  }

  Future<void> _refresh(Account account, String accessToken) async {
    final now = _now().toUtc();
    if (!isDue(account, now)) return;

    // One request wins the right to ask; concurrent ones carry on without.
    final claimed = await accounts.claimProfileRefresh(
      account.id,
      expected: account.profileRefreshedAt,
      at: now,
    );
    if (!claimed) return;

    final UserProfile profile;
    try {
      profile = await profiles.fetch(accessToken).timeout(timeout);
    } on Object catch (e) {
      _logger.info(
        'Profile refresh skipped: provider unavailable '
        '(${e.runtimeType}).',
      );
      // The claim must not shut the account out for a whole day: a verified
      // account is due again after [minInterval] (an unverified one already
      // is).
      if (account.emailVerified) {
        await accounts.claimProfileRefresh(
          account.id,
          expected: now,
          at: now.subtract(staleAfter - minInterval),
        );
      }
      return;
    }

    var email = account.email;
    var verified = account.emailVerified;
    final fresh = profile.email?.trim().toLowerCase();
    final providerEmailDiffers =
        fresh != null && fresh.isNotEmpty && fresh != account.email;
    if (fresh != null && fresh.isNotEmpty) {
      if (fresh == email) {
        verified = profile.emailVerified;
      } else {
        final holder = await accounts.findByEmail(fresh);
        if (holder == null || holder.id == account.id) {
          email = fresh;
          verified = profile.emailVerified;
        } else if (profile.emailVerified &&
            await freeEmailForVerifiedClaimant(
              accounts,
              fresh,
              claimant: account.id,
              now: now,
            )) {
          // The holder had not verified it: the provider says it is ours.
          email = fresh;
          verified = true;
        } else {
          // The provider no longer reports the stored address, so it is not
          // verified for this account any more, whatever it was before.
          verified = false;
          _logger.warning(
            'Profile refresh kept the stored email unverified: the new one '
            'belongs to another account.',
          );
        }
      }
    }

    // The name follows the provider until a person edits it (AM-3 will stop
    // the refresh for an edited name).
    final names = profileNameParts(profile, fresh);
    final firstName = names.first ?? account.firstName;
    final lastName = names.last ?? account.lastName;

    if (email == account.email &&
        verified == account.emailVerified &&
        firstName == account.firstName &&
        lastName == account.lastName) {
      return;
    }
    try {
      await accounts.applyProfile(
        account.id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        emailVerified: verified,
        now: now,
      );
    } on Object catch (_) {
      // The usual cause is another account taking the email between the check
      // and the write (the database refuses a duplicate). The contract does
      // not tell that apart from other write failures, so any failure retries
      // once with the stored email; a second failure is caught by [refresh].
      _logger.warning('Profile refresh retried with the stored email.');
      await accounts.applyProfile(
        account.id,
        firstName: firstName,
        lastName: lastName,
        email: account.email,
        // A stored address the provider does not report is not verified.
        emailVerified: providerEmailDiffers ? false : account.emailVerified,
        now: now,
      );
    }
    _logger.info('Refreshed an account profile from the provider.');
  }
}
