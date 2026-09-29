import 'dart:math';

/// A stable, opaque identifier for a domain entity.
///
/// Identifiers are UUIDv7 strings: 128-bit, time-ordered, and generatable
/// offline. The canonical form is lower-case; [value] always holds it.
class Id {
  Id._(this.value);

  static final RegExp _pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  /// The lower-case canonical string form of the identifier.
  final String value;

  /// Parses and validates a previously assigned identifier.
  ///
  /// [raw] is trimmed and lower-cased before validation; an
  /// [ArgumentError] is thrown when it is not a UUIDv7 string.
  factory Id.parse(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (!_pattern.hasMatch(normalized)) {
      throw ArgumentError.value(raw, 'raw', 'is not a valid UUIDv7 identifier');
    }
    return Id._(normalized);
  }

  /// Generates a fresh, never-reused, offline-safe UUIDv7 identifier.
  factory Id.create() => Id._(_generate());

  static String _generate() {
    final random = Random.secure();
    String hex(int value, int width) =>
        value.toRadixString(16).padLeft(width, '0');

    final timestamp = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFFFFFF;
    final group1 = hex(timestamp >> 16, 8);
    final group2 = hex(timestamp & 0xFFFF, 4);
    final group3 = '7${hex(random.nextInt(0x1000), 3)}';
    final group4 =
        '${(8 + random.nextInt(4)).toRadixString(16)}${hex(random.nextInt(0x1000), 3)}';
    final group5 =
        '${hex(random.nextInt(0x10000), 4)}'
        '${hex(random.nextInt(0x10000), 4)}'
        '${hex(random.nextInt(0x10000), 4)}';
    return '$group1-$group2-$group3-$group4-$group5';
  }

  @override
  bool operator ==(Object other) => other is Id && other.value == value;

  @override
  int get hashCode => value.hashCode;

  int compareTo(Id other) => value.compareTo(other.value);

  @override
  String toString() => value;
}
