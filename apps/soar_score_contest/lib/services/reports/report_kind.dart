/// The two groups the reports page sorts its cards into.
enum ReportGroup {
  results('Results', 'Calculated from the scores entered so far.'),
  documents(
    'Documents to print',
    'Built from the drawn matrix. Usually printed before the contest.',
  );

  const ReportGroup(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

/// A report or document a director can produce for a contest
/// (`plan/ui/contest-administration/reports.md`).
enum ReportKind {
  standings(
    key: 'standings',
    title: 'Overall Standings',
    brief: 'Every pilot’s placing, total, and score for each round.',
    group: ReportGroup.results,
    needsScores: true,
  ),
  matrix(
    key: 'matrix',
    title: 'Draw Matrix',
    brief: 'Which pilots fly in each round and group.',
    group: ReportGroup.documents,
    needsScores: false,
  ),
  sheet(
    key: 'sheet',
    title: 'Scoring Sheet',
    brief: 'Blank grids for officials to write scores by hand.',
    group: ReportGroup.documents,
    needsScores: false,
  ),
  cards(
    key: 'cards',
    title: 'Pilot Scoring Cards',
    brief:
        'A printable card per pilot to record their own scores, with a QR '
        'code to their online scoring page.',
    group: ReportGroup.documents,
    needsScores: false,
  );

  const ReportKind({
    required this.key,
    required this.title,
    required this.brief,
    required this.group,
    required this.needsScores,
  });

  /// A stable id for widget keys and, later, the viewer's route.
  final String key;
  final String title;

  /// One plain sentence on what the report provides.
  final String brief;
  final ReportGroup group;

  /// Whether the report is built from scores. Every report needs a matrix.
  final bool needsScores;

  /// The reports of [group], in display order.
  static List<ReportKind> of(ReportGroup group) => [
    for (final kind in values)
      if (kind.group == group) kind,
  ];
}
