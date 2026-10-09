import 'package:soar_score_core/soar_score_core.dart';

/// How a discipline is named in the words of the page, for example in
/// `F5J default`.
abstract final class DisciplineLabel {
  static String of(DisciplineType type) => switch (type) {
    DisciplineType.ales => 'ALES',
    DisciplineType.thermalDuration => 'Thermal duration',
    DisciplineType.f3j => 'F3J',
    DisciplineType.f5j => 'F5J',
    DisciplineType.f3l => 'F3L',
    DisciplineType.f3k => 'F3K',
  };

  /// `F5J default`.
  static String defaultOf(DisciplineType type) => '${of(type)} default';
}
