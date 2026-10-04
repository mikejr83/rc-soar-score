import '../../enums/authority.dart';

/// Throws [ArgumentError] when the penalty entries of a score component map
/// break the rules in `plan/data-model/entities/score_attempt.md`.
///
/// `flight_penalty` and `cumulative_penalty`, when present and not null, are
/// non-negative integers. `cumulative_penalty` is set only under director
/// authority, so pass [authority] for attempts; pass `null` to skip that check.
void requireValidPenalties(
  Map<String, Object?> components, {
  Authority? authority,
}) {
  for (final key in const ['flight_penalty', 'cumulative_penalty']) {
    final value = components[key];
    if (value == null) continue;
    if (value is! int || value < 0) {
      throw ArgumentError.value(
        value,
        key,
        'must be a non-negative integer or null',
      );
    }
  }
  if (authority != null &&
      authority != Authority.director &&
      components['cumulative_penalty'] != null) {
    throw ArgumentError(
      'cumulative_penalty is set only under director authority',
    );
  }
}
