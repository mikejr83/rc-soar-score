import 'package:soar_score_core/soar_score_core.dart';

/// Makes [email] free for an account whose provider has verified it.
///
/// Returns true when nobody else holds [email] afterwards. A registered
/// account that holds it without having verified it gives it up (its
/// verification stays off), so someone who signed up with an address they do
/// not own cannot keep its owner from using it. A holder with a verified
/// address, or an account that is not a registered one, keeps it.
///
/// Call it only for an address the provider reports as verified.
Future<bool> freeEmailForVerifiedClaimant(
  AccountRepository accounts,
  String email, {
  required Id? claimant,
  required DateTime now,
}) async {
  final holder = await accounts.findByEmail(email);
  if (holder == null || holder.id == claimant) return true;
  if (holder.kind != AccountKind.registered || holder.emailVerified) {
    return false;
  }
  // One conditional write: it applies only while the holder still has this
  // address unverified, so a refresh that verified or replaced it meanwhile
  // is not undone, and no other column is rewritten from a stale read.
  await accounts.releaseUnverifiedEmail(holder.id, email, now: now);
  // Whether or not this call released it, free means nobody holds it now.
  final after = await accounts.findByEmail(email);
  return after == null || after.id == claimant;
}
