import '../id.dart';

/// Throws [ArgumentError] unless exactly one of [contestId] and
/// [ownerAccountId] is set, the rule on every record that can belong to
/// either a contest or a director's own data.
void requireExactlyOneScope({Id? contestId, Id? ownerAccountId}) {
  if ((contestId == null) == (ownerAccountId == null)) {
    throw ArgumentError(
      'exactly one of contest_id and owner_account_id must be set',
    );
  }
}

/// Throws [ArgumentError] when [value] is blank after trimming.
String requireNotBlank(String value, String name) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return trimmed;
}

/// Throws [ArgumentError] when [value] is negative.
int requireNonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must not be negative');
  }
  return value;
}
