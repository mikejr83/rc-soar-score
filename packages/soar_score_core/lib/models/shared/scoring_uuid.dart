import 'package:equatable/equatable.dart';

/// The random UUIDv4 `ContestParticipation.scoring_uuid`.
///
/// It must not be sequential, so unlike `Id` it is not a UUIDv7.
class ScoringUuid extends Equatable {
  ScoringUuid._(this.value);

  static final RegExp _pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  /// The lower-case canonical string form.
  final String value;

  /// Parses and validates a UUIDv4 string, trimmed and lower-cased first.
  factory ScoringUuid.parse(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (!_pattern.hasMatch(normalized)) {
      throw ArgumentError.value(raw, 'raw', 'is not a valid UUIDv4');
    }
    return ScoringUuid._(normalized);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
