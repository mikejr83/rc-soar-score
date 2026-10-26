import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/card_columns.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/card_geometry.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/card_sizing.dart';
import 'package:soar_score_contest/services/reports/report_pilot.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_contest/widgets/reports/pilot_cards/pilot_card_view.dart';
import 'package:soar_score_contest/widgets/reports/pilot_cards/qr_code_view.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _pilot = ReportPilot(
  participationId: Id.parse('019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01'),
  firstName: 'Elena',
  lastName: 'Vargas',
  club: 'Gator Soaring Club',
);

const _line = 'Gator Cup F5J · Lake Wales, Florida · 17–18 Oct 2026';
const _footer = 'Matrix rev 3 · Rounds 1 to 8 · Printed 28 Sep 2026, 00:00';
const _link =
    'https://scoring.rcsoarscore.com/invitations/'
    '019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01';

Future<(Rect card, Rect qr, Rect caption, CardFit fit)> _pump(
  WidgetTester tester,
  int index,
) async {
  final geometry = CardGeometry.of(PaperSize.a4, CardsPerPage.four);
  final fit = CardSizing.fit(
    geometry: geometry,
    pilot: _pilot,
    contestLine: _line,
    footer: _footer,
    qr: true,
    rounds: 8,
  );
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: PilotCardView(
          geometry: geometry,
          insets: geometry.insetsOf(index),
          pilot: _pilot,
          rows: const [],
          columns: CardColumns.fitted(
            CardColumns.forContest(
              discipline: 'F5J',
              lanes: true,
              motorRestart: true,
            ),
            geometry.contentWidth - 2 * CardSpec.tableOutline,
          ),
          contestLine: _line,
          fit: fit,
          footer: _footer,
          qrLink: _link,
        ),
      ),
    ),
  );
  return (
    tester.getRect(find.byType(PilotCardView)),
    tester.getRect(find.byType(QrCodeView)),
    tester.getRect(find.text('Scan to enter scores')),
    fit,
  );
}

void main() {
  testWidgets('four modules of white sit between the caption and the code', (
    tester,
  ) async {
    final (_, qr, caption, fit) = await _pump(tester, 0);
    final gap = qr.left - caption.right;
    expect(gap, greaterThanOrEqualTo(mmToPx(fit.quietZone) - .5));
    expect(fit.quietZone, closeTo(fit.qrSize * 4 / 37, 1e-9));
  });

  testWidgets('the code keeps its quiet zone from a cut line at the right', (
    tester,
  ) async {
    // Card 0 is top left: its right edge is a cut line, 2 mm of inset beyond
    // the content, so the content must leave the rest of the quiet zone.
    final (card, qr, _, fit) = await _pump(tester, 0);
    final white = card.right - qr.right;
    expect(white, greaterThanOrEqualTo(mmToPx(fit.quietZone) - .5));
  });

  testWidgets('a lower-row card keeps the quiet zone under its cut line', (
    tester,
  ) async {
    // Card 2 is bottom left: a cut line runs above it, 2 mm of inset.
    final (card, qr, _, fit) = await _pump(tester, 2);
    final white = qr.top - card.top;
    expect(white, greaterThanOrEqualTo(mmToPx(fit.quietZone) - .5));
  });

  testWidgets('a top-row card needs no extra: the page margin is the white', (
    tester,
  ) async {
    final (card, qr, _, _) = await _pump(tester, 0);
    expect(qr.top - card.top, closeTo(0, .5));
  });
}
