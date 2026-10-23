/// The sizes of the Draw Matrix sheet, in logical pixels (96 to the inch), the
/// same on screen and on paper. Default rows are 11 pt; compact rows are 9 pt,
/// the smallest type used on any report.
class DrawMatrixStyle {
  const DrawMatrixStyle({
    required this.fontSize,
    required this.lineHeight,
    required this.padY,
    required this.padX,
    required this.laneWidth,
    required this.numberWidth,
    required this.classWidth,
    required this.teamMax,
    required this.clubMax,
    required this.roundFont,
    required this.roundLine,
    required this.roundPadY,
    required this.roundGap,
    required this.roundRule,
    required this.groupFont,
    required this.groupLine,
    required this.groupPadY,
    required this.headFont,
    required this.headLine,
    required this.headPadY,
    this.teamFixed,
  });

  static const DrawMatrixStyle normal = DrawMatrixStyle(
    fontSize: 14.67,
    lineHeight: 18,
    padY: 2,
    padX: 6,
    laneWidth: 46,
    numberWidth: 50,
    classWidth: 84,
    teamMax: 170,
    clubMax: 230,
    roundFont: 17.33,
    roundLine: 22,
    roundPadY: 4,
    roundGap: 10,
    roundRule: 4,
    groupFont: 14.67,
    groupLine: 18,
    groupPadY: 4,
    headFont: 12,
    headLine: 16,
    headPadY: 4,
  );

  static const DrawMatrixStyle compact = DrawMatrixStyle(
    fontSize: 12,
    lineHeight: 14,
    padY: 1,
    padX: 4,
    laneWidth: 28,
    numberWidth: 32,
    classWidth: 56,
    teamMax: 120,
    clubMax: 120,
    teamFixed: 110,
    roundFont: 13.33,
    roundLine: 17,
    roundPadY: 2,
    roundGap: 6,
    roundRule: 3,
    groupFont: 12,
    groupLine: 14,
    groupPadY: 2,
    headFont: 12,
    headLine: 14,
    headPadY: 2,
  );

  /// The width between the two tables of a compact page, rule included.
  static const double gutter = 28;

  final double fontSize;
  final double lineHeight;
  final double padY;
  final double padX;
  final double laneWidth;
  final double numberWidth;
  final double classWidth;
  final double teamMax;
  final double clubMax;

  /// A team column of fixed width instead of a share of the room.
  final double? teamFixed;

  /// Round header: size, line, padding, space above and the rule above.
  final double roundFont;
  final double roundLine;
  final double roundPadY;
  final double roundGap;
  final double roundRule;

  final double groupFont;
  final double groupLine;
  final double groupPadY;

  /// Column headings.
  final double headFont;
  final double headLine;
  final double headPadY;

  /// The height of the column headings, rule included.
  double get headHeight => headLine + 2 * headPadY + 2;

  /// The height of a group header, its two rules included.
  double get groupHeight => groupLine + 2 * groupPadY + 2;

  /// The height of a round header, with the space above it when [gap].
  double roundHeight({required bool gap}) =>
      roundLine + 2 * roundPadY + roundRule + (gap ? roundGap : 0);

  /// The height of a pilot row of [lines] lines.
  double rowHeight(int lines) => lines * lineHeight + 2 * padY + 1;
}
