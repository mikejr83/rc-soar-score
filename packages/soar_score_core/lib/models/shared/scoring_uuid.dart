import 'dart:math';

import 'package:equatable/equatable.dart';

/// The random UUIDv4 `ContestParticipation.scoring_uuid`.
///
/// It must not be sequential, so unlike `Id` it is not a UUIDv7.
class ScoringUuid extends Equatable {
  ScoringUuid._(this.value);

  static final RegExp _pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  /// A fresh random UUIDv4.
  factory ScoringUuid.create() {
    final random = Random.secure();
    String hex(int value, int width) =>
        value.toRadixString(16).padLeft(width, '0');
    final group4 = (8 + random.nextInt(4)).toRadixString(16);
    return ScoringUuid._(
      '${hex(random.nextInt(1 << 32), 8)}-'
      '${hex(random.nextInt(1 << 16), 4)}-'
      '4${hex(random.nextInt(1 << 12), 3)}-'
      '$group4${hex(random.nextInt(1 << 12), 3)}-'
      '${hex(random.nextInt(1 << 24), 6)}${hex(random.nextInt(1 << 24), 6)}',
    );
  }

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
