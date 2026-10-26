/// What a column of the card's table holds.
enum CardColumnKind {
  /// Printed from the draw: round, group, lane.
  lead,

  /// Time flown, written as mm:ss.
  time,

  /// A number the pilot writes: landing points, height, penalty.
  number,

  /// A real tick box: Over 75 m, motor restart.
  tick,

  /// Blank space for initials or a short name: Timer, Validated.
  initials,
}

/// The score component a column shows when Pre-fill is on.
enum CardField {
  round,
  group,
  lane,
  time,
  landing,
  height,
  over75,
  restart,
  penalty,
  timer,
  validated,
}

/// One column of the card's table: its heading, unit hint, kind and minimum
/// width in millimetres. Spare width is shared among the writable columns by
/// [weight].
class CardColumn {
  const CardColumn(
    this.field,
    this.title,
    this.unit,
    this.widthMm,
    this.kind, {
    this.weight = 0,
  });

  final CardField field;
  final String title;
  final String unit;
  final double widthMm;
  final CardColumnKind kind;
  final double weight;

  CardColumn withWidth(double width) =>
      CardColumn(field, title, unit, width, kind, weight: weight);
}

/// The columns of a card, from the contest's discipline
/// (`plan/ui/contest-administration/reports/pilot-scoring-cards.md`).
abstract final class CardColumns {
  /// The disciplines whose score has a height.
  static const _withHeight = {'F5J'};

  /// The disciplines that allow a motor restart.
  static const _withRestart = {'F5J', 'ALES'};

  /// The columns for [discipline] (`F5J`, `F3J`, ...; an unknown one counts as
  /// a duration task without height or restart), with lane and motor restart
  /// only when the contest uses them.
  static List<CardColumn> forContest({
    required String? discipline,
    required bool lanes,
    required bool motorRestart,
  }) {
    final label = discipline?.toUpperCase();
    return [
      const CardColumn(CardField.round, 'Round', '', 10, CardColumnKind.lead),
      const CardColumn(CardField.group, 'Group', '', 10, CardColumnKind.lead),
      if (lanes)
        const CardColumn(CardField.lane, 'Lane', '', 7.5, CardColumnKind.lead),
      const CardColumn(
        CardField.time,
        'Time',
        'mm:ss',
        10,
        CardColumnKind.time,
        weight: 1,
      ),
      const CardColumn(
        CardField.landing,
        'Landing',
        'pts',
        11,
        CardColumnKind.number,
        weight: 1,
      ),
      if (_withHeight.contains(label))
        const CardColumn(
          CardField.height,
          'Height',
          'm',
          10,
          CardColumnKind.number,
          weight: 1,
        ),
      const CardColumn(
        CardField.over75,
        'Over 75 m',
        '',
        12,
        CardColumnKind.tick,
      ),
      if (motorRestart && _withRestart.contains(label))
        const CardColumn(
          CardField.restart,
          'Motor restart',
          '',
          12,
          CardColumnKind.tick,
        ),
      const CardColumn(
        CardField.penalty,
        'Penalty',
        'pts',
        12,
        CardColumnKind.number,
      ),
      const CardColumn(
        CardField.timer,
        'Timer',
        '',
        15,
        CardColumnKind.initials,
      ),
      const CardColumn(
        CardField.validated,
        'Validated',
        '',
        17,
        CardColumnKind.initials,
      ),
    ];
  }

  /// [columns] stretched to [widthMm]: the spare width goes to the Time,
  /// Landing and Height columns by weight. Penalty (about three digits), Timer
  /// and Validated (initials) keep a fixed width.
  static List<CardColumn> fitted(List<CardColumn> columns, double widthMm) {
    final used = columns.fold(0.0, (sum, c) => sum + c.widthMm);
    final weights = columns.fold(0.0, (sum, c) => sum + c.weight);
    final spare = widthMm - used;
    if (spare <= 0 || weights == 0) {
      return columns;
    }
    return [
      for (final c in columns)
        c.withWidth(c.widthMm + spare * c.weight / weights),
    ];
  }
}
