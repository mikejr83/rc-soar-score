import 'user_profile.dart';

String? _clean(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// The first and last name [profile] gives, or null when it gives no real
/// name (nothing, or only the email repeated as the name).
///
/// A single word fills the first name and the last becomes `Unknown`, since
/// an account needs both.
(String, String)? profileNames(UserProfile profile, String? email) {
  final given = _clean(profile.givenName);
  final family = _clean(profile.familyName);
  if (given != null && family != null) return (given, family);

  final full = _clean(profile.name);
  if (full != null && full != email) {
    final parts = full.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (given ?? parts.first, family ?? parts.skip(1).join(' '));
    }
    return (given ?? full, family ?? 'Unknown');
  }
  if (given != null || family != null) {
    return (given ?? 'New user', family ?? 'Unknown');
  }
  return null;
}

/// The parts of the name [profile] really gives, null for a part it does not
/// give. A refresh keeps the stored value of a null part, so a provider that
/// only knows a given name does not turn the stored last name into `Unknown`.
({String? first, String? last}) profileNameParts(
  UserProfile profile,
  String? email,
) {
  final given = _clean(profile.givenName);
  final family = _clean(profile.familyName);
  if (given != null && family != null) return (first: given, last: family);

  final full = _clean(profile.name);
  if (full != null && full != email) {
    final parts = full.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (
        first: given ?? parts.first,
        last: family ?? parts.skip(1).join(' '),
      );
    }
    return (first: given ?? full, last: family);
  }
  return (first: given, last: family);
}

/// The names for a new account: [profileNames], else the email's local part.
(String, String) newAccountNames(UserProfile profile, String? email) {
  final names = profileNames(profile, email);
  if (names != null) return names;
  final local = _clean(email?.split('@').first);
  return (local ?? 'New user', 'Unknown');
}
