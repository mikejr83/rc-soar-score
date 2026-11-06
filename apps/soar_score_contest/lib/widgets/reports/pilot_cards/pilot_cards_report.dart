import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/reports/pilot_cards/card_columns.dart';
import '../../../services/reports/pilot_cards/card_geometry.dart';
import '../../../services/reports/pilot_cards/card_sheet_decision.dart';
import '../../../services/reports/pilot_cards/card_sizing.dart';
import '../../../services/reports/pilot_cards/pilot_cards_data.dart';
import '../../../services/reports/pilot_cards/pilot_cards_options.dart';
import '../../../services/reports/pilot_cards/pilot_cards_text.dart';
import '../../../services/reports/pilot_cards/pilot_invitations.dart';
import '../../../services/reports/report_kind.dart';
import '../../../services/reports/report_pilot.dart';
import '../../../services/reports/reports_facts.dart';
import '../../../services/reports/viewer/page_setup.dart';
import '../../../services/reports/viewer/report_spec.dart';
import '../../../services/scoring/scoring_page_data.dart';
import '../viewer/report_definition.dart';
import 'pilot_card_view.dart';
import 'pilot_cards_controls.dart';
import 'pilot_cards_dialogs.dart';
import 'pilot_cards_page_body.dart';

/// The Pilot Scoring Cards document
/// (`plan/ui/contest-administration/reports/pilot-scoring-cards.md`): a
/// printable card per pilot to record their own scores, cut apart after
/// printing, with a QR code to their online scoring page when they have an
/// invitation.
///
/// The matrix, scores and invitations are read once; the round range, pilots
/// and options are applied to them, so changing them redraws at once. The
/// cards print landscape only and draw their own header and footer, so the
/// frame's running header and footer are left off.
class PilotCardsReport extends DataReportDefinition<PilotCardsData> {
  const PilotCardsReport({this.source});

  /// Where invitations come from; the app-wide one when `null`.
  final PilotInvitationSource? source;

  @override
  ReportKind get kind => ReportKind.cards;

  @override
  PageOrientation get defaultOrientation => PageOrientation.landscape;

  @override
  bool get fixedOrientation => true;

  @override
  bool get hasRunningFrame => false;

  /// The print margin on every side, so no printer cuts a card off.
  @override
  EdgeInsets barePageMargins(Map<String, String> filters, ReportsFacts facts) =>
      EdgeInsets.all(mmToPx(PilotCardsOptions.of(filters, facts).margin.mm));

  @override
  Map<String, String> defaultFilters(ReportsFacts facts) =>
      PilotCardsOptions.defaults(facts);

  /// The range and the pilot choice, then whether the rounds fit a half page
  /// at all. Paper is not known here, so the shorter landscape sheet (A4)
  /// decides: a contest it can hold, Letter can hold too.
  @override
  ReportCheck check(Map<String, String> filters, ReportsFacts facts) {
    final options = PilotCardsOptions.of(filters, facts);
    final base = options.check();
    if (!identical(base, ReportCheck.ok)) {
      return base;
    }
    final decision = _decision(options, facts, PaperSize.a4);
    if (decision.tooMany) {
      return ReportEmpty(
        title: 'This contest has too many rounds for a scoring card',
        body:
            'A half-page card holds up to ${decision.maxTwo} rounds at the '
            'minimum 8 mm row height. Narrow the round range to print cards '
            'for part of the contest.',
      );
    }
    return ReportCheck.ok;
  }

  @override
  String filterSummary(Map<String, String> filters, ReportsFacts facts) =>
      PilotCardsOptions.of(filters, facts).summary;

  CardSheetDecision _decision(
    PilotCardsOptions options,
    ReportsFacts facts,
    PaperSize paper,
  ) => CardSheetDecision.of(
    paper: paper,
    pilots: options.selected,
    contestLine: PilotCardsText.contestLine(facts.contest),
    footer: _sizingFooter(options, facts),
    rounds: options.rounds.length,
    choice: options.perPage,
    margin: options.margin.mm,
  );

  /// The longest footer the choices could produce, so the page layout is
  /// decided before the scores are read and never changes with them: the date
  /// is as wide as a date gets, and Pre-fill adds its note and legend.
  String _sizingFooter(PilotCardsOptions options, ReportsFacts facts) {
    final rounds = options.rounds;
    return PilotCardsText.footer(
      matrixRevision: facts.matrixRevision,
      rounds: rounds,
      drawn: options.range.drawn,
      planned: options.range.planned,
      scoredThrough: options.prefill && rounds.isNotEmpty ? rounds.last : null,
      anyUnofficial: options.prefill,
      printed: 'Printed 28 Sep 2026, 00:00',
    );
  }

  /// One read serves every range and option. A redraw or a score changes the
  /// key.
  @override
  String? dataKey(Map<String, String> filters, ReportsFacts facts) =>
      'cards=${facts.matrixRevision}:${facts.scoresSignature}';

  @override
  Future<ReportLoad<PilotCardsData>> loadData(ReportDataRequest request) async {
    final page = await ScoringPageData.load(request.client, request.contestId);
    final invitationSource = source ?? PilotInvitationSources.current;
    // A failed read must not stop the cards from printing: they print without
    // QR codes, with a banner to retry.
    PilotInvitations invitations;
    try {
      invitations = await invitationSource.read(
        request.publicationClient,
        request.contestId,
      );
    } on Object {
      invitations = const PilotInvitations(loadFailed: true);
    }
    return ReportLoaded(
      PilotCardsData.of(
        page: page.base,
        scores: page.scores,
        landings: page.landings,
        settings: page.settings,
        invitations: PilotInvitationSession(
          source: invitationSource,
          client: request.publicationClient,
          contestId: request.contestId,
          initial: invitations,
        ),
      ),
    );
  }

  @override
  Listenable? changesOf(Object? data) =>
      data is PilotCardsData ? data.invitations : null;

  @override
  List<ReportControlGroup> controls(ReportControlsContext context) {
    final options = PilotCardsOptions.of(context.filters, context.facts);
    return pilotCardsControls(
      context,
      options,
      _decision(options, context.facts, context.setup.paper),
    );
  }

  @override
  ReportDocument buildWithout(ReportPageContext context) => ReportDocument(
    title: 'Pilot Scoring Cards - ${context.facts.contest.name}',
    subtitle: 'No cards to show',
    pages: const [SizedBox.shrink()],
  );

  @override
  ReportDocument buildWith(ReportPageContext context, PilotCardsData data) {
    final facts = context.facts;
    final options = PilotCardsOptions.of(context.filters, facts);
    final selected = options.selected;
    final rounds = options.rounds;
    final contestLine = PilotCardsText.contestLine(facts.contest);
    final decision = _decision(options, facts, context.setup.paper);
    final perPage = decision.perPage ?? CardsPerPage.two;
    final geometry = CardGeometry.of(
      context.setup.paper,
      perPage,
      margin: options.margin.mm,
    );
    final columns = CardColumns.fitted(
      CardColumns.forContest(
        discipline: facts.disciplineLabel,
        lanes: data.hasLanes,
        motorRestart: data.motorRestart,
      ),
      geometry.contentWidth - 2 * CardSpec.tableOutline,
    );
    final session = data.invitations;
    final invitations = session.invitations;
    bool hasQr(ReportPilot pilot) =>
        invitations.synchronized && invitations.has(pilot.participationId);
    final missing = [
      for (final pilot in selected)
        if (!hasQr(pilot)) pilot,
    ];

    // Which rows exist and how far the scores go, for the footer.
    final prefill = options.prefill;
    int? through;
    var anyUnofficial = false;
    if (prefill) {
      for (final pilot in selected) {
        for (final row in data.rowsOf(pilot.participationId)) {
          final score = row.score;
          if (score != null && rounds.contains(row.round)) {
            through = through == null || row.round > through
                ? row.round
                : through;
            anyUnofficial = anyUnofficial || !score.official;
          }
        }
      }
    }
    final range = options.range;
    final footer = PilotCardsText.footer(
      matrixRevision: facts.matrixRevision,
      rounds: rounds,
      drawn: range.drawn,
      planned: range.planned,
      scoredThrough: through,
      anyUnofficial: anyUnofficial,
      printed: 'Printed ${DateFormat('d MMM y, HH:mm').format(DateTime.now())}',
    );

    final cards = <Widget>[
      for (var n = 0; n < selected.length; n++)
        _enlargeable(
          context,
          selected[n],
          (zoom, index) => PilotCardView(
            geometry: geometry,
            insets: geometry.insetsOf(index),
            pilot: selected[n],
            rows: [
              for (final row in data.rowsOf(selected[n].participationId))
                if (rounds.contains(row.round)) row,
            ],
            columns: columns,
            contestLine: contestLine,
            fit: CardSizing.fit(
              geometry: geometry,
              pilot: selected[n],
              contestLine: contestLine,
              footer: footer,
              qr: hasQr(selected[n]),
              rounds: rounds.length,
            ),
            footer: footer,
            qrLink: hasQr(selected[n])
                ? invitations.linkOf(selected[n].participationId)
                : null,
            prefill: prefill,
            zoom: zoom,
          ),
          index: n % perPage.count,
        ),
    ];
    final pages = <Widget>[
      for (var i = 0; i * perPage.count < cards.length; i++)
        PilotCardsPageBody(
          geometry: geometry,
          cards: cards.sublist(
            i * perPage.count,
            (i + 1) * perPage.count > cards.length
                ? cards.length
                : (i + 1) * perPage.count,
          ),
          size: context.bodySize,
          number: i + 1,
        ),
    ];
    return ReportDocument(
      title: 'Pilot Scoring Cards - ${facts.contest.name}',
      subtitle: contestLine,
      pages: pages.isEmpty ? const [SizedBox.shrink()] : pages,
      banners: invitationBanners(
        session: session,
        selected: selected,
        missing: missing,
        online: context.online,
      ),
      beforePrint: (buildContext) async {
        // Sent but not loaded back: the cards lack codes the invitations
        // already have. Printing now would offer to send them again.
        if (session.sending || session.phase == InvitationPhase.sentNotLoaded) {
          return false;
        }
        if (missing.isEmpty || selected.isEmpty) {
          return true;
        }
        return remindAboutMissingQr(
          context: buildContext,
          session: session,
          selected: selected,
          missing: missing,
          online: context.online,
        );
      },
    );
  }

  /// Wraps a card so a click enlarges it on screen. Print preview, the
  /// printout and the PDF leave the wrapper's behaviour out: it adds nothing
  /// that draws.
  Widget _enlargeable(
    ReportPageContext context,
    ReportPilot pilot,
    Widget Function(double zoom, int index) card, {
    required int index,
  }) => _Enlargeable(
    enabled: !context.preview,
    label: pilot.givenSurname,
    card: card,
    index: index,
  );
}

/// A card that opens at 150% in a dialog when clicked. Screen only.
class _Enlargeable extends StatelessWidget {
  const _Enlargeable({
    required this.enabled,
    required this.label,
    required this.card,
    required this.index,
  });

  final bool enabled;
  final String label;
  final Widget Function(double zoom, int index) card;
  final int index;

  @override
  Widget build(BuildContext context) {
    final child = card(1, index);
    if (!enabled) {
      return child;
    }
    return Semantics(
      button: true,
      onTapHint: 'Enlarge the card of $label',
      child: MouseRegion(
        cursor: SystemMouseCursors.zoomIn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(label),
                    subtitle: const Text(
                      'Screen only. Enlarged 150% for reading; prints at '
                      'actual size.',
                    ),
                    trailing: IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: card(1.5, 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
