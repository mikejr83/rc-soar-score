import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/report_viewer_page.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';
import 'package:soar_score_contest/services/reports/report_kind.dart';
import 'package:soar_score_contest/services/reports/viewer/report_print_result.dart';
import 'package:soar_score_contest/services/reports/viewer/report_view_params.dart';
import 'package:soar_score_contest/widgets/reports/pilot_cards/pilot_card_view.dart';
import 'package:soar_score_contest/widgets/reports/pilot_cards/qr_code_view.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_connectivity.dart';
import '../support/matrix_test_support.dart';
import '../support/next_step_widget_support.dart';
import '../support/stand_in_report.dart';
import '../support/workspace_facts_support.dart';

/// Invitations for the pilots in [invited] (by participation id); sending adds
/// the rest.
class _FakeInvitations implements PilotInvitationSource {
  _FakeInvitations({
    Set<String>? invited,
    this.fail = false,
    this.failRead = false,
    this.failReadAlways = false,
  }) : _invited = {...?invited};

  final Set<String> _invited;
  bool fail;

  /// Reading fails after the send worked.
  bool failRead;

  /// Reading always fails.
  bool failReadAlways;
  int sends = 0;
  ApiClient? readWith;
  ApiClient? sentWith;
  List<Id> lastSent = const [];

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async {
    readWith = client;
    if (failReadAlways || (failRead && sends > 0)) {
      throw StateError('read failed');
    }
    return PilotInvitations(
      links: {for (final id in _invited) id: 'https://soar.example/i/$id'},
    );
  }

  @override
  Future<void> send(
    ApiClient client,
    Id contestId,
    List<Id> participations,
  ) async {
    sends++;
    sentWith = client;
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
  ApiClient? publicationClient,
  Map<int, int> retired = const {},
  FakeAppConnectivity? connectivity,
}) async {
  final matrix = drawnMatrix(lanes: lanes);
  final server = WorkspaceServer(
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: scores?.call(matrix) ?? scoresFor(matrix, const {}),
  );
  server.inner.retirements.addAll(retired);
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
      child: _withConnectivity(
        connectivity,
        _withPublicationClient(
          publicationClient,
          MaterialApp(
            locale: const Locale('en', 'US'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ReportViewerPage(
              printer: printer,
              contestId: matrixContestId,
              report: ReportKind.cards,
              params: params,
              pollInterval: null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _withConnectivity(FakeAppConnectivity? monitor, Widget child) =>
    monitor == null
    ? child
    : AppConnectivityInherited(monitor: monitor, child: child);

Widget _withPublicationClient(ApiClient? client, Widget child) => client == null
    ? child
    : PublicationClientInherited(client: client, child: child);

String marginChoice(WidgetTester tester) => tester
    .widget<RadioGroup<String>>(
      find.ancestor(
        of: find.byKey(const ValueKey('cards-margin-std')),
        matching: find.byType(RadioGroup<String>),
      ),
    )
    .groupValue!;

Finder get _cards => find.byType(PilotCardView);

void main() {
  setUp(() {
    PilotInvitationSources.current = const UnavailablePilotInvitationSource();
  });

  tearDown(() {
    PilotInvitationSources.current = const ApiPilotInvitationSource();
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
    // Issuing sends no email, so the dialog and the result must not say so.
    expect(find.textContaining('Nobody is emailed'), findsOneWidget);
    expect(find.textContaining('also emailed'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(source.sends, 1);
    expect(source.lastSent, hasLength(4));
    expect(find.byType(QrCodeView), findsNWidgets(4));
    expect(
      find.textContaining('QR codes created.', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('No QR code.', findRichText: true),
      findsNothing,
    );
  });

  testWidgets(
    'a connection lost while confirming sends nothing from the cards',
    (tester) async {
      final source = _FakeInvitations();
      PilotInvitationSources.current = source;
      final connectivity = FakeAppConnectivity();
      await _pump(tester, connectivity: connectivity);

      await tester.tap(find.byKey(const ValueKey('cards-banner-send')));
      await tester.pumpAndSettle();
      connectivity
        ..internetStatus = ConnectivityStatus.unavailable
        ..notifyListeners();
      await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
      await tester.pumpAndSettle();

      expect(source.sends, 0);
      expect(
        find.text('You’re offline, so invitations can’t be sent now.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a retired pilot’s card prints but is never sent an invitation', (
    tester,
  ) async {
    final source = _FakeInvitations();
    PilotInvitationSources.current = source;
    await _pump(
      tester,
      retired: {4: 2},
      params: const ReportViewParams(filters: {'ret': '1'}),
    );

    // Four cards (the retired pilot's included), three that can have a code.
    expect(find.byType(PilotCardView), findsNWidgets(4));
    expect(
      find.textContaining('Some cards have no QR code. Send invitations'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('cards-banner-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 QR codes'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(source.lastSent, hasLength(3));
    expect(find.byType(QrCodeView), findsNWidgets(3));
  });

  testWidgets(
    'a send that worked but could not be read back is not a failure',
    (tester) async {
      final source = _FakeInvitations(failRead: true);
      PilotInvitationSources.current = source;
      await _pump(tester);

      await tester.tap(find.byKey(const ValueKey('cards-banner-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
      await tester.pumpAndSettle();

      expect(source.sends, 1);
      expect(
        find.textContaining('QR codes were created.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('could not be created', findRichText: true),
        findsNothing,
      );
      // Nothing offers to send again; the director can load the codes.
      expect(find.byKey(const ValueKey('cards-banner-send')), findsNothing);
      expect(find.byType(QrCodeView), findsNothing);

      source.failRead = false;
      await tester.tap(find.byKey(const ValueKey('cards-banner-reload')));
      await tester.pumpAndSettle();

      expect(source.sends, 1, reason: 'loading the codes sends nothing');
      expect(find.byType(QrCodeView), findsNWidgets(4));
    },
  );

  testWidgets('cards still print when the invitations cannot be read', (
    tester,
  ) async {
    final source = _FakeInvitations(failReadAlways: true);
    PilotInvitationSources.current = source;
    final printer = FakeReportPrinter(ReportPrintResult.sent);
    await _pump(tester, printer: printer);

    expect(find.byType(QrCodeView), findsNothing);
    expect(
      find.byKey(const ValueKey('cards-banner-load-failed')),
      findsOneWidget,
    );
    expect(find.text('Scan to enter scores'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('viewer-print')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cards-reminder-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cards-reminder-without')));
    await tester.pumpAndSettle();
    expect(printer.printed, isNotEmpty);

    source.failReadAlways = false;
    await tester.tap(find.byKey(const ValueKey('cards-banner-load-retry')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('cards-banner-load-failed')),
      findsNothing,
    );
    // Read now, nobody has an invitation yet: the usual banner.
    expect(find.byKey(const ValueKey('cards-banner-missing')), findsOneWidget);
  });

  testWidgets('printing waits for the codes after a send that was not read', (
    tester,
  ) async {
    final source = _FakeInvitations(failRead: true);
    PilotInvitationSources.current = source;
    final printer = FakeReportPrinter(ReportPrintResult.sent);
    await _pump(tester, printer: printer);
    await tester.tap(find.byKey(const ValueKey('cards-banner-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('viewer-print')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cards-reminder-dialog')), findsNothing);
    expect(printer.printed, isEmpty);
    expect(source.sends, 1);
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
      find.textContaining('QR codes could not be created.', findRichText: true),
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

  testWidgets(
    'invitations are read and issued through the publication client',
    (tester) async {
      final hosted = ApiClient(
        baseUrl: Uri.parse('http://hosted.example'),
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      );
      final source = _FakeInvitations();
      PilotInvitationSources.current = source;
      await _pump(tester, publicationClient: hosted);

      expect(source.readWith, same(hosted));
      await tester.tap(find.byKey(const ValueKey('cards-banner-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
      await tester.pumpAndSettle();
      expect(source.sentWith, same(hosted));
    },
  );

  testWidgets('each card carries its own pilot\u2019s link, never the site', (
    tester,
  ) async {
    final all = workspaceData(matrix: drawnMatrix()).participations
        .map((p) => p.id.value)
        .toSet();
    PilotInvitationSources.current = _FakeInvitations(invited: all);
    await _pump(tester);

    expect(find.byType(QrCodeView), findsNWidgets(4));
    final links = [
      for (final view in tester.widgetList<QrCodeView>(find.byType(QrCodeView)))
        view.data,
    ];
    expect(links.toSet(), hasLength(4));
    expect(links, everyElement(isNot('https://score.rcsoarscore.com')));
    expect(
      find.textContaining('No QR code.', findRichText: true),
      findsNothing,
    );
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

    testWidgets('only the typed pages are sent to the printer', (tester) async {
      PilotInvitationSources.current = _FakeInvitations(
        invited: workspaceData(matrix: drawnMatrix()).participations
            .map((p) => p.id.value)
            .toSet(),
      );
      final printer = FakeReportPrinter(ReportPrintResult.sent);
      await _pump(
        tester,
        printer: printer,
        params: const ReportViewParams(filters: {'up': 'two'}),
      );
      expect(find.text('Letter · Landscape · 2 pages'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('viewer-print-pages')),
        '1',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 of 2 pages will print.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();

      expect(printer.printed, hasLength(1));
      expect(printer.printed.single.pages, hasLength(1));
    });

    testWidgets('a page that does not exist turns printing off', (
      tester,
    ) async {
      final printer = FakeReportPrinter(ReportPrintResult.sent);
      await _pump(
        tester,
        printer: printer,
        params: const ReportViewParams(filters: {'up': 'two'}),
      );

      await tester.enterText(
        find.byKey(const ValueKey('viewer-print-pages')),
        '5',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Use page numbers from 1 to 2'), findsOne);
      final print = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('viewer-print')),
      );
      expect(print.onPressed, isNull);
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
          'QR codes could not be created.',
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

  testWidgets('the print margin is chosen in the panel and kept in the URL', (
    tester,
  ) async {
    await _pump(tester);
    expect(marginChoice(tester), 'std');

    // The panel is a long list: bring the margin choice into view.
    // Dragging at the panel's padding scrolls it, not the pilot list inside.
    await tester.dragFrom(const Offset(6, 600), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-margin-wide')));
    await tester.pumpAndSettle();

    expect(marginChoice(tester), 'wide');
    expect(_cards, findsNWidgets(4));
  });
}
