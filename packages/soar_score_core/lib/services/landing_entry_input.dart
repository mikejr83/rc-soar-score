import 'package:equatable/equatable.dart';

/// One entry of a new landing table, as the director typed it. Its position
/// in the list is its ordinal.
///
/// The key is internal: leave it blank and the service derives one from the
/// label.
class LandingEntryInput extends Equatable {
  const LandingEntryInput({
    this.entryKey = '',
    required this.displayValue,
    required this.pointValue,
  });

  factory LandingEntryInput.fromJson(Map<String, Object?> json) =>
      LandingEntryInput(
        entryKey: json['entry_key'] as String? ?? '',
        displayValue: json['display_value'] as String? ?? '',
        pointValue: (json['point_value']! as num).toInt(),
      );

  /// Blank to derive the key from [displayValue].
  final String entryKey;

  /// The label shown to the scorer; blank means "use the key".
  final String displayValue;
  final int pointValue;

  Map<String, Object?> toJson() => {
    'entry_key': entryKey,
    'display_value': displayValue,
    'point_value': pointValue,
  };

  @override
  List<Object?> get props => [entryKey, displayValue, pointValue];
}
