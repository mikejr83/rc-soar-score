import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest/report_viewer_page.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';
import 'package:soar_score_contest/services/reports/report_kind.dart';
import 'package:soar_score_contest/services/reports/viewer/report_print_result.dart';
import 'package:soar_score_contest/services/reports/viewer/report_view_params.dart';
import 'package:soar_score_contest/widgets/reports/pilot_cards/pilot_card_view.dart';
import 'package:soar_score_contest/widgets/reports/pilot_cards/qr_code_view.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';
import '../support/next_step_widget_support.dart';
import '../support/stand_in_report.dart';
import '../support/workspace_facts_support.dart';

/// Invitations for the pilots in [invited] (by participation id); sending adds
/// the rest.
class _FakeInvitations implements PilotInvitationSource {
  _FakeInvitations({Set<String>? invited, this.fail = false})
    : _invited = {...?invited};

  final Set<String> _invited;
  bool fail;
  int sends = 0;
  List<Id> lastSent = const [];

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async =>
      PilotInvitations(
        links: {for (final id in _invited) id: 'https://soar.example/i/$id'},
      );

  @override
  Future<void> send(
    ApiClient client,
    Id contestId,
    List<Id> participations,
  ) async {
    sends++;
    lastSent = participations;
    if (fail) {
      throw StateError('no network');
    }
    _invited.addAll(participations.map((id) => id.value));
  }
}

Future<void> _pump(
  WidgetTester tester, {
  bool lanes = true,
  ReportViewParams params = const ReportViewParams(),
  Size size = const Size(1280, 1000),
  ContestScores Function(CurrentMatrix matrix)? scores,
  ReportPrinter printer = const NotWiredReportPrinter(),
}) async {
  final matrix = drawnMatrix(lanes: lanes);
  final server = WorkspaceServer(
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: scores?.call(matrix) ?? scoresFor(matrix, const {}),
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(
          (request) async => request.url.path.endsWith('/landing-tables')
              ? http.Response(
                  '{"landing_tables": []}',
                  200,
                  headers: {'content-type': 'application/json'},
                )
              : server.handle(request),
        ),
      ),
      child: MaterialApp(
        locale: const Locale('en', 'US'),
        home: ReportViewerPage(
          printer: printer,
          contestId: matrixContestId,
          report: ReportKind.cards,
          params: params,
          pollInterval: null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _cards => find.byType(PilotCardView);

void main() {
  tearDown(() {
    PilotInvitationSources.current = const UnavailablePilotInvitationSource();
  });

  testWidgets('prints a card per pilot, by last name, with the draw rows', (
    tester,
  ) async {
    await _pump(tester);

    expect(_cards, findsNWidgets(4));
    expect(find.text('4 cards · 1 page'), findsOneWidget);
    // Alphabetical by last name, then given name.
    final names = [
      for (final card in tester.widgetList<PilotCardView>(_cards))
        card.pilot.listName,
    ];
    expect(names, [...names]..sort());
    // The table's columns follow the discipline and the contest's lanes.
    for (final heading in ['Round', 'Group', 'Lane', 'Time', 'Landing']) {
      expect(find.text(heading), findsWidgets, reason: heading);
    }
    expect(find.text('Timer'), findsWidgets);
    expect(find.text('Validated'), findsWidgets);
  });

  testWidgets('a contest without lanes has no Lane column', (tester) async {
    await _pump(tester, lanes: false);
    expect(find.text('Lane'), findsNothing);
  });

  testWidgets('cards are landscape only: the page group has no orientation', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Orientation'), findsNothing);
    expect(find.text('Paper'), findsOneWidget);
  });

  testWidgets('the round range limits every card', (tester) async {
    await _pump(
      tester,
      params: const ReportViewParams(filters: {'from': '2', 'to': '2'}),
    );
    expect(find.textContaining('· Round 2'), findsWidgets);
    expect(find.textContaining('Rounds 1 to 2'), findsNothing);
  });

  testWidgets('choosing no pilots says so and leaves nothing to print', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('cards-select-none')));
    await tester.pumpAndSettle();

    expect(find.text('No pilots selected'), findsOneWidget);
    expect(_cards, findsNothing);
    expect(find.text('0 of 4 selected'), findsOneWidget);
  });

  testWidgets('searching narrows the list and Select acts on the matches', (
    tester,
  ) async {
    await _pump(
      tester,
      params: const ReportViewParams(filters: {'pilots': 'none'}),
    );
    await tester.enterText(
      find.byKey(const ValueKey('cards-pilot-search')),
      'Ray',
    );
    await tester.pumpAndSettle();
    expect(find.text('Select 1 shown'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cards-select-all')));
    await tester.pumpAndSettle();

    expect(find.text('1 of 4 selected'), findsOneWidget);
    expect(_cards, findsOneWidget);
  });

  testWidgets('pre-fill is off and says why when no score exists', (
    tester,
  ) async {
    await _pump(tester, params: const ReportViewParams(filters: {'pre': '1'}));
    final pre = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Pre-fill'),
    );
    expect(pre.onChanged, isNull);
    expect(pre.value, isFalse);
    expect(find.text('No scores have been entered yet.'), findsOneWidget);
  });

  testWidgets('without invitations the cards have no QR and say how to add', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(QrCodeView), findsNothing);
    expect(
      find.textContaining('No QR code.', findRichText: true),
      findsOneWidget,
    );
    // The stand-in source cannot send: the reason is in text and the button
    // is off.
    expect(
      find.textContaining('Sending invitations isn’t available'),
      findsOneWidget,
    );
    final send = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Send invitations'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('a pilot with an invitation gets a QR code, others do not', (
    tester,
  ) async {
    final lee = workspaceData(matrix: drawnMatrix()).participations.first;
    PilotInvitationSources.current = _FakeInvitations(invited: {lee.id.value});
    await _pump(tester);

    expect(find.byType(QrCodeView), findsOneWidget);
    expect(find.text('Scan to enter scores'), findsOneWidget);
    expect(
      find.textContaining('No QR code.', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('3 cards have no QR code. Send invitations'),
      findsOneWidget,
    );
  });

  testWidgets('sending invitations confirms, then adds the QR codes', (
    tester,
  ) async {
    final source = _FakeInvitations();
    PilotInvitationSources.current = source;
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('cards-banner-send')));
    await tester.pumpAndSettle();
    expect(find.text('Send invitations?'), findsOneWidget);
    expect(find.textContaining('4 QR codes'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(source.sends, 1);
    expect(source.lastSent, hasLength(4));
    expect(find.byType(QrCodeView), findsNWidgets(4));
    expect(
      find.textContaining('Invitations sent.', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('No QR code.', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('a failed send adds nothing and offers a retry', (tester) async {
    final source = _FakeInvitations(fail: true);
    PilotInvitationSources.current = source;
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('cards-banner-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Invitations could not be sent.', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(QrCodeView), findsNothing);

    source.fail = false;
    await tester.tap(find.byKey(const ValueKey('cards-banner-retry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(QrCodeView), findsNWidgets(4));
  });

  testWidgets('a QR code encodes the invitation link and stays pure black', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: QrCodeView(data: 'https://soar.example/i/x', size: 94.5),
        ),
      ),
    );
    expect(find.byType(QrCodeView), findsOneWidget);
    expect(tester.getSize(find.byType(QrCodeView)).width, 94.5);
  });

  group('pre-fill', () {
    /// Round 1: the first pilot has an official 9:57 with a 119 m launch and
    /// a 100 point penalty; the second has one pending submission.
    ContestScores scored(CurrentMatrix matrix) {
      final first = matrix.assignments.where((a) {
        final round = matrix.rounds.firstWhere(
          (r) => r.id == a.scheduledRoundId,
        );
        return round.ordinal == 1;
      }).toList();
      ScoreSlot slot(
        MatrixAssignment a,
        ScorePlaceholderState state,
        Map<String, Object?> components,
      ) {
        final placeholder = ScorePlaceholder(
          id: Id.create(),
          contestId: a.contestId,
          contestParticipationId: a.contestParticipationId,
          assignmentId: a.id,
          state: state,
          scoreRevision: 1,
        );
        return ScoreSlot(
          placeholder: placeholder,
          officialScore: OfficialScore(
            id: Id.create(),
            contestId: a.contestId,
            scorePlaceholderId: placeholder.id,
            scoreAttemptId: Id.create(),
            scoreRevision: 1,
            components: components,
            setAt: DateTime.utc(2026, 10, 17, 15),
            setBy: Id.create(),
            reason: 'Entered by the director',
          ),
        );
      }

      return ContestScores(
        rounds: [
          for (final round in matrix.rounds)
            RoundProgress(
              roundId: round.id,
              ordinal: round.ordinal,
              scored: round.ordinal == 1 ? 2 : 0,
              total: 4,
            ),
        ],
        slots: [
          slot(first[0], ScorePlaceholderState.official, const {
            'time_flown': 597,
            'launch_height': 119,
            'flight_penalty': 100,
            'out_of_bounds': true,
          }),
          slot(first[1], ScorePlaceholderState.submitted, const {
            'time_flown': 540,
            'launch_height': 80,
          }),
          for (final a in matrix.assignments.skip(2)) scoreSlot(a),
        ],
      );
    }

    testWidgets('prints the scores entered, marks the unofficial', (
      tester,
    ) async {
      await _pump(
        tester,
        scores: scored,
        params: const ReportViewParams(filters: {'pre': '1'}),
      );

      final pre = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Pre-fill'),
      );
      expect(pre.onChanged, isNotNull);
      expect(pre.value, isTrue);
      expect(find.text('9:57'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      // The submission is not official: its values carry an asterisk, and the
      // footer dates the card and explains it.
      expect(find.text('9:00*'), findsOneWidget);
      expect(find.text('–*'), findsWidgets);
      expect(
        find.textContaining('Includes scores through round 1 · * not official'),
        findsWidgets,
      );
    });

    testWidgets('is off by default and prints nothing extra', (tester) async {
      await _pump(tester, scores: scored);

      final pre = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Pre-fill'),
      );
      expect(pre.onChanged, isNotNull);
      expect(pre.value, isFalse);
      expect(find.text('9:57'), findsNothing);
      expect(find.textContaining('Includes scores'), findsNothing);
    });
  });

  group('printing', () {
    Future<FakeReportPrinter> pumpPrinting(
      WidgetTester tester, {
      PilotInvitationSource? source,
    }) async {
      PilotInvitationSources.current = source ?? _FakeInvitations();
      final printer = FakeReportPrinter(ReportPrintResult.sent);
      await _pump(tester, printer: printer);
      return printer;
    }

    testWidgets('reminds about cards without a QR code before printing', (
      tester,
    ) async {
      final printer = await pumpPrinting(tester);

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();

      expect(
        find.text('Some cards will print without QR codes.'),
        findsOneWidget,
      );
      expect(find.textContaining('None of these 4 cards'), findsOneWidget);
      expect(printer.printed, isEmpty, reason: 'nothing prints yet');

      await tester.tap(find.byKey(const ValueKey('cards-reminder-without')));
      await tester.pumpAndSettle();
      expect(printer.printed, hasLength(1));
      expect(find.byType(QrCodeView), findsNothing);
    });

    testWidgets('Cancel in the reminder prints nothing', (tester) async {
      final printer = await pumpPrinting(tester);

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cards-reminder-cancel')));
      await tester.pumpAndSettle();

      expect(printer.printed, isEmpty);
    });

    testWidgets('Send invitations and print confirms, sends, then prints', (
      tester,
    ) async {
      final source = _FakeInvitations();
      final printer = await pumpPrinting(tester, source: source);

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cards-reminder-send')));
      await tester.pumpAndSettle();
      expect(find.text('Send invitations?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
      await tester.pumpAndSettle();

      expect(source.sends, 1);
      expect(printer.printed, hasLength(1));
      expect(find.byType(QrCodeView), findsNWidgets(4));
    });

    testWidgets('a failed send in the reminder prints nothing', (tester) async {
      final printer = await pumpPrinting(
        tester,
        source: _FakeInvitations(fail: true),
      );

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cards-reminder-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
      await tester.pumpAndSettle();

      expect(printer.printed, isEmpty);
      expect(
        find.textContaining(
          'Invitations could not be sent.',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('the stand-in source cannot send: the reminder says why', (
      tester,
    ) async {
      final printer = await pumpPrinting(
        tester,
        source: const UnavailablePilotInvitationSource(),
      );

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cards-reminder-send')), findsNothing);
      expect(
        find.textContaining('Sending invitations isn’t available'),
        findsWidgets,
      );
      await tester.tap(find.byKey(const ValueKey('cards-reminder-without')));
      await tester.pumpAndSettle();
      expect(printer.printed, hasLength(1));
    });

    testWidgets('prints without a reminder when every card has a QR code', (
      tester,
    ) async {
      final ids = [
        for (final p in workspaceData(matrix: drawnMatrix()).participations)
          p.id.value,
      ];
      final printer = await pumpPrinting(
        tester,
        source: _FakeInvitations(invited: ids.toSet()),
      );
      expect(find.byType(QrCodeView), findsNWidgets(4));
      expect(
        find.textContaining('No QR code.', findRichText: true),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cards-reminder-dialog')), findsNothing);
      expect(printer.printed, hasLength(1));
    });
  });
}
