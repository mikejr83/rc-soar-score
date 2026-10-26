import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/card_columns.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/card_geometry.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/card_sheet_decision.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/card_sizing.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_cards_options.dart';
import 'package:soar_score_contest/services/reports/report_pilot.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _id = Id.parse('019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01');

ReportPilot _pilot({
  String first = 'Elena',
  String last = 'Vargas',
  String? club,
  String? fai,
  String? national,
  String? team,
  String? className,
  int? retiredAtRound,
}) => ReportPilot(
  participationId: _id,
  firstName: first,
  lastName: last,
  club: club,
  faiId: fai,
  nationalId: national,
  team: team,
  className: className,
  retiredAtRound: retiredAtRound,
);

const _line = 'Gator Cup F5J · Lake Wales, Florida · 17–18 Oct 2026';

void main() {
  group('how many rounds fit', () {
    test('8 rounds fit four to a page on Letter, 14 need two', () {
      final four = CardGeometry.of(PaperSize.letter, CardsPerPage.four);
      final two = CardGeometry.of(PaperSize.letter, CardsPerPage.two);
      final pilots = [_pilot(club: 'Gator Soaring Club')];
      bool fits(CardGeometry g, int rounds) => CardSizing.fitsAll(
        geometry: g,
        pilots: pilots,
        contestLine: _line,
        rounds: rounds,
      );
      expect(fits(four, 8), isTrue);
      expect(fits(four, 14), isFalse);
      expect(fits(two, 14), isTrue);
    });

    test('8 rounds also fit four to a page on A4', () {
      final pilots = [_pilot(club: 'Gator Soaring Club')];
      expect(
        CardSizing.fitsAll(
          geometry: CardGeometry.of(PaperSize.a4, CardsPerPage.four),
          pilots: pilots,
          contestLine: _line,
          rounds: 8,
        ),
        isTrue,
      );
    });

    test('A4 landscape holds no more rounds than Letter', () {
      int most(PaperSize paper) => CardSizing.maxRounds(
        geometry: CardGeometry.of(paper, CardsPerPage.four),
        pilots: [_pilot()],
        contestLine: _line,
        qr: true,
      );
      expect(most(PaperSize.a4), lessThanOrEqualTo(most(PaperSize.letter)));
    });

    test('the tallest header block decides for the sheet', () {
      final tall = _pilot(
        first: 'Maximilian-Alexander',
        last: 'Featherstonehaugh-Cholmondeley-Marjoribanks',
        club:
            'The Very Long Named Radio Controlled Soaring Society of Lake '
            'Wales and Surrounding Counties',
        fai: 'FAI-123456',
        national: 'AMA 104233',
        className: 'Open',
        team: 'Team Thermal',
      );
      final geometry = CardGeometry.of(PaperSize.letter, CardsPerPage.four);
      final plain = CardSizing.maxRounds(
        geometry: geometry,
        pilots: [_pilot()],
        contestLine: _line,
        qr: true,
      );
      final withTall = CardSizing.maxRounds(
        geometry: geometry,
        pilots: [_pilot(), tall],
        contestLine: _line,
        qr: true,
      );
      expect(withTall, lessThanOrEqualTo(plain));
    });
  });

  group('QR size', () {
    test('is 25 mm when there is room and never below 18 mm', () {
      final geometry = CardGeometry.of(PaperSize.letter, CardsPerPage.four);
      final roomy = CardSizing.fit(
        geometry: geometry,
        pilot: _pilot(),
        contestLine: _line,
        qr: true,
        rounds: 4,
      );
      final full = CardSizing.fit(
        geometry: geometry,
        pilot: _pilot(),
        contestLine: _line,
        qr: true,
        rounds: 8,
      );
      expect(roomy.qrSize, CardSpec.qr);
      expect(full.qrSize, inInclusiveRange(CardSpec.qrMin, CardSpec.qr));
      expect(full.ok, isTrue);
      expect(full.quietZone, closeTo(full.qrSize * 4 / 29, 1e-9));
    });

    test('a card without a QR code gives the room to the rows', () {
      final geometry = CardGeometry.of(PaperSize.letter, CardsPerPage.four);
      CardFit fit(bool qr) => CardSizing.fit(
        geometry: geometry,
        pilot: _pilot(),
        contestLine: _line,
        qr: qr,
        rounds: 8,
      );
      expect(fit(false).qrSize, 0);
      expect(fit(false).rowHeight, greaterThanOrEqualTo(fit(true).rowHeight));
    });
  });

  group('names', () {
    test('shrink to a floor of 14 pt, then wrap, and are never cut', () {
      final short = CardSizing.identity(_pilot(), _line, 80);
      expect(short.nameSizePt, 18);
      expect(short.nameLines, 1);
      final long = CardSizing.identity(
        _pilot(
          first: 'Maximilian-Alexander',
          last: 'Featherstonehaugh-Cholmondeley-Marjoribanks',
        ),
        _line,
        80,
      );
      expect(long.nameSizePt, 14);
      expect(long.nameLines, greaterThan(1));
    });

    test('a pilot with only a name has no detail lines', () {
      expect(CardSizing.details(_pilot()), isEmpty);
    });

    test('detail lines carry club, IDs, class and team', () {
      final lines = CardSizing.details(
        _pilot(
          club: 'Gator Soaring',
          fai: 'USA-4100',
          national: 'AMA 104233',
          className: 'Open',
          team: 'Thermal',
          retiredAtRound: 3,
        ),
      );
      expect(lines.first, 'Gator Soaring');
      expect(
        lines.last,
        'Retired · FAI ID USA-4100 · National ID AMA 104233 · Class Open · '
        'Team Thermal',
      );
    });
  });

  group('columns', () {
    List<String> titles({
      String? discipline = 'F5J',
      bool lanes = true,
      bool restart = true,
    }) => [
      for (final c in CardColumns.forContest(
        discipline: discipline,
        lanes: lanes,
        motorRestart: restart,
      ))
        c.title,
    ];

    test('F5J has every component, lane and motor restart', () {
      expect(titles(), [
        'Round',
        'Group',
        'Lane',
        'Time',
        'Landing',
        'Height',
        'Over 75 m',
        'Motor restart',
        'Penalty',
        'Timer',
        'Validated',
      ]);
    });

    test('F3J has Over 75 m but no height or motor restart', () {
      expect(titles(discipline: 'F3J'), [
        'Round',
        'Group',
        'Lane',
        'Time',
        'Landing',
        'Over 75 m',
        'Penalty',
        'Timer',
        'Validated',
      ]);
    });

    test('lanes and motor restart appear only when the contest uses them', () {
      final t = titles(lanes: false, restart: false);
      expect(t, isNot(contains('Lane')));
      expect(t, isNot(contains('Motor restart')));
      expect(titles(discipline: 'ALES'), contains('Motor restart'));
    });

    test('spare width goes to the writable columns, none is lost', () {
      final base = CardColumns.forContest(
        discipline: 'F5J',
        lanes: true,
        motorRestart: true,
      );
      final fitted = CardColumns.fitted(base, 130);
      expect(fitted.fold(0.0, (sum, c) => sum + c.widthMm), closeTo(130, 1e-9));
      expect(
        fitted.first.widthMm,
        base.first.widthMm,
        reason: 'printed draw columns keep their width',
      );
    });

    test('Timer and Validated are wide enough for initials', () {
      final timer = CardColumns.forContest(
        discipline: 'F5J',
        lanes: false,
        motorRestart: false,
      ).firstWhere((c) => c.field == CardField.timer);
      expect(timer.widthMm, greaterThanOrEqualTo(9));
      expect(timer.kind, CardColumnKind.initials);
    });
  });

  group('the sheet decision', () {
    CardSheetDecision decide(int rounds, CardsPerPageChoice choice) =>
        CardSheetDecision.of(
          paper: PaperSize.letter,
          pilots: [_pilot()],
          contestLine: _line,
          rounds: rounds,
          choice: choice,
        );

    test('automatic uses four for 8 rounds and two for 14', () {
      expect(
        decide(8, CardsPerPageChoice.automatic).perPage,
        CardsPerPage.four,
      );
      final fourteen = decide(14, CardsPerPageChoice.automatic);
      expect(fourteen.perPage, CardsPerPage.two);
      expect(fourteen.message, contains('14 rounds don’t fit four to a page'));
    });

    test('two per page can be chosen when four would fit', () {
      final d = decide(8, CardsPerPageChoice.two);
      expect(d.perPage, CardsPerPage.two);
      expect(d.message, startsWith('8 rounds on half-page cards.'));
    });

    test('too many rounds for a half page has no layout and says why', () {
      final d = decide(60, CardsPerPageChoice.automatic);
      expect(d.tooMany, isTrue);
      expect(d.perPage, isNull);
      expect(d.message, contains('too many rounds for a scoring card'));
    });

    test('no rounds in range', () {
      expect(
        decide(0, CardsPerPageChoice.automatic).message,
        'No rounds in range.',
      );
    });
  });

  group('geometry', () {
    test('cards meet at the cut: an inset only where they touch', () {
      final four = CardGeometry.of(PaperSize.letter, CardsPerPage.four);
      final tl = four.insetsOf(0);
      expect(
        (tl.top, tl.left, tl.right, tl.bottom),
        (0.0, 0.0, CardSpec.inset, CardSpec.inset),
      );
      final br = four.insetsOf(3);
      expect(
        (br.top, br.left, br.right, br.bottom),
        (CardSpec.inset, CardSpec.inset, 0.0, 0.0),
      );
    });

    test('four-up cards are a quarter of the page area', () {
      final four = CardGeometry.of(PaperSize.a4, CardsPerPage.four);
      final two = CardGeometry.of(PaperSize.a4, CardsPerPage.two);
      expect(four.cardWidth, two.cardWidth);
      expect(four.cardHeight * 2, closeTo(two.cardHeight, 1e-9));
    });
  });
}
