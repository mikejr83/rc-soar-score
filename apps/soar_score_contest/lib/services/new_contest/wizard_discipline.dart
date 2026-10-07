import 'package:soar_score_core/soar_score_core.dart';

/// A discipline card in step 2 of the New Contest wizard.
///
/// The text summarizes `plan/business-requirements/disciplines/`. Only the
/// disciplines the system ships a profile for can be selected; the others are
/// listed as not supported yet.
enum WizardDiscipline {
  ales(
    name: 'ALES',
    task:
        'Altitude-limited electric soaring. Fly a set target time, then land '
        'on the spot.',
    time: 'Target time (MM:ss or seconds) · 1 pt per second · 0 decimals',
    landing: 'ALES system table: 50 to 0 pts in steps of 5',
    rules: [
      'Flying past the target loses 1 pt per second over',
      'Motor restart or over-flight of more than 1 min scores 0',
      'Out of bounds: more than 75 m from the landing marker',
    ],
  ),
  f3j(
    name: 'F3J',
    task: 'Thermal duration. Fly as long as possible within the working time.',
    time: 'Working time · 1 pt per second · 1 decimal',
    landing: 'Official F3J table, up to 100 pts (by points or by distance)',
    rules: [
      'Late landing: no landing bonus and a 30 pt penalty',
      'Time can’t exceed the working time',
      'Out of bounds: more than 75 m from the landing marker',
    ],
  ),
  f5j(
    name: 'F5J',
    task:
        'Electric-launch thermal duration within the working time, with a '
        'launch height penalty.',
    time: 'Working time 10:00 · 1 pt per second',
    landing: 'F5J system table: 50 to 0 pts in steps of 5',
    rules: [
      'Height penalty 0.5 pt/m, 3 pt/m above the reference height',
      'Motor restart: Allowed, Non-droppable 0 or Not allowed',
      'Late landing forfeits the landing bonus',
    ],
  ),
  thermalDuration(
    name: 'Thermal Duration',
    task: 'Fly a set target time, then land on the spot.',
    time: 'Target time (MM:ss or seconds) · 1 pt per second · 0 decimals',
    landing: '100 inch landing tape: 1 pt per inch, 100 to 0',
    rules: [
      'Flying past the target loses 1 pt per second over',
      'Over-flight of more than 1 min scores 0',
      'Out of bounds: more than 75 m from the landing marker',
    ],
  ),
  f3b(name: 'F3B', task: 'Multi-task: duration, distance and speed'),
  f3k(name: 'F3K', task: 'Hand launch, a different task each round'),
  f3l(name: 'F3L', task: 'Rules not defined yet');

  const WizardDiscipline({
    required this.name,
    required this.task,
    this.time,
    this.landing,
    this.rules = const [],
  });

  final String name;
  final String task;

  /// The default target or working time; `null` when not supported.
  final String? time;

  /// The landing-bonus summary; `null` when not supported.
  final String? landing;

  final List<String> rules;

  static const String unsupportedLabel = 'Not supported yet';

  /// Whether the system ships a profile for this discipline.
  bool get supported => profileId != null;

  /// The system discipline profile behind this card.
  Id? get profileId => switch (this) {
    ales => SystemDisciplineProfiles.alesId,
    f3j => SystemDisciplineProfiles.f3jId,
    f5j => SystemDisciplineProfiles.f5jId,
    thermalDuration => SystemDisciplineProfiles.thermalId,
    f3b || f3k || f3l => null,
  };

  /// The card for the system profile [id], if it is one of the supported
  /// disciplines.
  static WizardDiscipline? forProfile(Id id) {
    for (final discipline in values) {
      if (discipline.profileId == id) {
        return discipline;
      }
    }
    return null;
  }
}
