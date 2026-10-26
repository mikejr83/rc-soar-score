import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_cards_options.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_cards_text.dart';
import 'package:soar_score_contest/services/reports/viewer/report_spec.dart';
import 'package:soar_score_contest/widgets/reports/pilot_cards/pilot_cards_report.dart';

import '../../../support/draw_matrix_support.dart';

void main() {
  final facts = factsOfPage(drawnPage());

  PilotCardsOptions options([Map<String, String> filters = const {}]) =>
      PilotCardsOptions.of({
        ...PilotCardsOptions.defaults(facts),
        ...filters,
      }, facts);

  test('every pilot and every drawn round are chosen by default', () {
    final o = options();
    expect(o.selected, hasLength(facts.pilots.length));
    expect(o.rounds, facts.roundOrdinals);
    expect(o.prefill, isFalse);
    expect(o.perPage, CardsPerPageChoice.automatic);
    expect(o.check(), same(ReportCheck.ok));
  });

  test('pilots come by last name, then given name', () {
    final names = [for (final p in options().selected) p.listName];
    expect(names, [...names]..sort((a, b) => a.compareTo(b)));
  });

  test('a pilots filter picks those pilots; none and all are spelled out', () {
    final first = facts.pilots.first.participationId.value;
    expect(options({'pilots': first}).selected, hasLength(1));
    expect(options({'pilots': 'none'}).selected, isEmpty);
    expect(options({'pilots': 'all'}).selected, hasLength(facts.pilots.length));
  });

  test('choosing every pilot is stored as all, none as none', () {
    final o = options();
    final all = {for (final p in o.eligible) p.participationId.value};
    expect(o.pilotsValue(all), isNull);
    expect(o.pilotsValue({}), 'none');
    expect(o.pilotsValue({all.first}), all.first);
  });

  test('no pilots selected is an empty result, not an error', () {
    final check = options({'pilots': 'none'}).check();
    expect(check, isA<ReportEmpty>());
    expect((check as ReportEmpty).title, 'No pilots selected');
  });

  test('a range with a lower bound above the upper one is invalid', () {
    expect(options({'from': '2', 'to': '1'}).check(), isA<ReportInvalid>());
  });

  test('a range with no drawn round is empty', () {
    expect(options({'from': '9', 'to': '9'}).check(), isA<ReportEmpty>());
  });

  test('pre-fill needs a score: the choice is kept but not applied', () {
    final o = options({'pre': '1'});
    expect(o.prefillChosen, isTrue);
    expect(o.prefillAvailable, facts.hasScores);
    expect(o.prefill, facts.hasScores);
  });

  test('the summary names the range and a pilot subset', () {
    expect(options().summary, 'All rounds');
    final first = facts.pilots.first.participationId.value;
    expect(
      options({'pilots': first}).summary,
      'All rounds · 1 of ${facts.pilots.length} pilots',
    );
  });

  test('the contest line carries name and dates', () {
    final line = PilotCardsText.contestLine(facts.contest);
    expect(line, startsWith(facts.contest.name));
    expect(line, contains(' · '));
  });

  group('the card footer', () {
    test('dates the card by matrix revision and rounds covered', () {
      expect(
        PilotCardsText.footer(
          matrixRevision: 3,
          rounds: [1, 2, 3, 4],
          drawn: 4,
          planned: 4,
          scoredThrough: null,
          anyUnofficial: false,
          printed: 'Printed 1 Jan 2026, 09:00',
        ),
        'Matrix rev 3 · Rounds 1 to 4 · Printed 1 Jan 2026, 09:00',
      );
    });

    test(
      'notes rounds not drawn yet so a reprint after the next draw shows',
      () {
        expect(
          PilotCardsText.footer(
            matrixRevision: 2,
            rounds: [1, 2, 3, 4],
            drawn: 4,
            planned: 8,
            scoredThrough: null,
            anyUnofficial: false,
            printed: 'Printed 1 Jan 2026, 09:00',
          ),
          'Matrix rev 2 · Rounds 1 to 4 (4 of 8 drawn) · Printed 1 Jan 2026, 09:00',
        );
      },
    );

    test('pre-fill adds how far the scores go and the unofficial legend', () {
      expect(
        PilotCardsText.footer(
          matrixRevision: 2,
          rounds: [3],
          drawn: 8,
          planned: 8,
          scoredThrough: 3,
          anyUnofficial: true,
          printed: 'Printed 1 Jan 2026, 09:00',
        ),
        'Matrix rev 2 · Round 3 · Includes scores through round 3 · '
        '* not official · Printed 1 Jan 2026, 09:00',
      );
    });
  });

  group('the report', () {
    const report = PilotCardsReport();

    test('prints landscape only and draws its own header and footer', () {
      expect(report.fixedOrientation, isTrue);
      expect(report.hasRunningFrame, isFalse);
    });

    test('reads again when the matrix or a score changes', () {
      final key = report.dataKey(const {}, facts);
      expect(key, startsWith('cards='));
      expect(key, contains('${facts.scoresSignature}'));
    });

    test('check passes for a small contest', () {
      expect(report.check(const {'from': '1'}, facts), same(ReportCheck.ok));
    });
  });
}
