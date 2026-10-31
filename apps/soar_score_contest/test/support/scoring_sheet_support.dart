import 'package:flutter/painting.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/card_columns.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_cards_data.dart';
import 'package:soar_score_contest/services/reports/report_pilot.dart';
import 'package:soar_score_contest/services/reports/scoring_sheet/scoring_sheet_data.dart';
import 'package:soar_score_contest/services/reports/scoring_sheet/scoring_sheet_options.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'draw_matrix_support.dart';

/// The body of a Letter landscape page between the running header and footer.
const letterLandscapeBody = Size(1024, 666);

/// The body of a Letter portrait page.
const letterPortraitBody = Size(784, 906);

final _facts = factsOfPage(drawnPage());

/// The sheet's options for [filters] on the fixture contest.
ScoringSheetOptions sheetOptions([Map<String, String> filters = const {}]) =>
    ScoringSheetOptions.of({
      ...ScoringSheetOptions.defaults(_facts),
      ...filters,
    }, _facts);

/// A pilot named "Pilot NN, Given N"; [retiredAtRound] is the first round they
/// no longer fly.
ReportPilot reportPilot(int n, {int? retiredAtRound}) => ReportPilot(
  participationId: Id.create(),
  firstName: 'Given $n',
  lastName: 'Pilot ${n.toString().padLeft(2, '0')}',
  number: 100 + n,
  retiredAtRound: retiredAtRound,
);

/// A synthetic draw: [rounds] rounds of [groupSizes] with the same pilots in
/// every round (numbered from 1), lanes by position when [lanes].
/// [retiredAt] gives the first round a pilot number no longer flies; [scores]
/// is keyed by round and pilot number.
ScoringSheetData syntheticSheet({
  int rounds = 2,
  List<int> groupSizes = const [7, 7],
  bool lanes = true,
  String? discipline = 'F5J',
  bool motorRestart = true,
  Map<int, int> retiredAt = const {},
  Map<(int, int), CardScore> scores = const {},
}) {
  final total = groupSizes.fold(0, (a, b) => a + b);
  final pilots = [
    for (var n = 1; n <= total; n++)
      reportPilot(n, retiredAtRound: retiredAt[n]),
  ];
  return ScoringSheetData(
    hasLanes: lanes,
    motorRestart: motorRestart,
    workingTime: '10:00',
    discipline: discipline,
    rounds: [
      for (var r = 1; r <= rounds; r++)
        ScoringSheetRound(
          ordinal: r,
          groups: [
            for (var g = 0; g < groupSizes.length; g++)
              ScoringSheetGroup(
                label: String.fromCharCode(0x41 + g),
                pilots: [
                  for (var k = 0; k < groupSizes[g]; k++)
                    ScoringSheetPilot(
                      pilot:
                          pilots[groupSizes.take(g).fold(0, (a, b) => a + b) +
                              k],
                      lane: lanes ? k + 1 : null,
                      score:
                          scores[(
                            r,
                            groupSizes.take(g).fold(0, (a, b) => a + b) + k + 1,
                          )],
                    ),
                ],
              ),
          ],
        ),
    ],
  );
}

/// An entered score as the sheet prints it.
CardScore enteredScore({bool official = true}) => CardScore(
  text: {
    CardField.time: '9:57',
    CardField.landing: '50',
    CardField.height: '119',
    CardField.penalty: '–',
  },
  ticks: {CardField.over75: true, CardField.restart: false},
  official: official,
);
