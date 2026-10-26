import 'package:soar_score_core/soar_score_core.dart';

/// One scoring pilot as a report names them. A report shows only the facts
/// the contest uses: the number, team and class are `null` when it has none.
class ReportPilot {
  const ReportPilot({
    required this.participationId,
    required this.firstName,
    required this.lastName,
    this.number,
    this.team,
    this.className,
    this.retiredAtRound,
    this.club,
    this.faiId,
    this.nationalId,
  });

  final Id participationId;
  final String firstName;
  final String lastName;
  final int? number;
  final String? team;
  final String? className;

  /// The first round the pilot no longer flies, or null.
  final int? retiredAtRound;

  /// The pilot's club and identification numbers, when recorded.
  final String? club;
  final String? faiId;
  final String? nationalId;

  bool get isRetired => retiredAtRound != null;

  /// "Elena Vargas"; a single name stands as it is.
  String get givenSurname => [
    firstName.trim(),
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  /// "Vargas, Elena"; a single name stands as it is.
  String get listName {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty || last.isEmpty) {
      return '$first$last';
    }
    return '$last, $first';
  }
}
