import '../draw_matrix/draw_matrix_options.dart';
import '../report_pilot.dart';
import '../reports_facts.dart';
import '../viewer/report_spec.dart';
import 'card_geometry.dart';

/// The cards-per-page setting.
enum CardsPerPageChoice {
  automatic('auto', 'Automatic'),
  four('four', 'Four per page'),
  two('two', 'Two per page');

  const CardsPerPageChoice(this.key, this.label);

  final String key;
  final String label;

  static const Set<String> keys = {'auto', 'four', 'two'};

  static CardsPerPageChoice of(String? key) =>
      values.firstWhere((choice) => choice.key == key, orElse: () => automatic);
}

/// How far the cards stay from the paper's edge. Printers cannot reach the
/// edge: [standard] is a quarter inch, which the printers tried so far and
/// common inkjets reach; [wide] is 10 mm, for a printer that still cuts the
/// edges off.
enum PrintMargin {
  standard('std', 'Standard', '6.35 mm (¼ in) from the paper’s edge.', 6.35),
  wide(
    'wide',
    'Wide',
    '10 mm from the paper’s edge, for a printer that cuts the cards off.',
    10,
  );

  const PrintMargin(this.key, this.label, this.help, this.mm);

  final String key;
  final String label;
  final String help;
  final double mm;

  static const Set<String> keys = {'std', 'wide'};

  static PrintMargin of(String? key) =>
      values.firstWhere((m) => m.key == key, orElse: () => standard);
}

/// The filters and options of the Pilot Scoring Cards, read from the viewer's
/// filter map (and so from the URL) with the contest's facts.
///
/// Filter keys: `from` and `to` (an inclusive round range, as in the Draw
/// Matrix), `ret` (include retired pilots), `pilots` (the participation ids
/// that get a card, comma separated, `none`, or `all`; all when absent), `pre`
/// (Pre-fill), `up` (`auto`, `four` or `two`) and `mg` (the print margin,
/// `std` or `wide`).
class PilotCardsOptions {
  PilotCardsOptions._({
    required this.range,
    required this.includeRetired,
    required this.chosen,
    required this.prefillChosen,
    required this.perPage,
    required this.margin,
    required this.eligible,
    required this.hasScores,
  });

  factory PilotCardsOptions.of(
    Map<String, String> filters,
    ReportsFacts facts,
  ) {
    final range = DrawMatrixOptions.of(filters, facts);
    final includeRetired = filters['ret'] == '1';
    final eligible = [
      for (final pilot in facts.pilots)
        if (includeRetired || !pilot.isRetired) pilot,
    ]..sort(_byName);
    final raw = filters['pilots'];
    final Set<String>? chosen = raw == null || raw == 'all' || raw.isEmpty
        ? null
        : raw == 'none'
        ? const {}
        : raw.split(',').toSet();
    return PilotCardsOptions._(
      range: range,
      includeRetired: includeRetired,
      chosen: chosen,
      prefillChosen: filters['pre'] == '1',
      perPage: CardsPerPageChoice.of(filters['up']),
      margin: PrintMargin.of(filters['mg']),
      eligible: eligible,
      hasScores: facts.hasScores,
    );
  }

  static int _byName(ReportPilot a, ReportPilot b) {
    final last = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
    if (last != 0) {
      return last;
    }
    return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
  }

  /// No filter is set: the defaults apply.
  static Map<String, String> defaults(ReportsFacts facts) => const {
    'from': '1',
  };

  /// The round range, with the Draw Matrix's rules.
  final DrawMatrixOptions range;

  final bool includeRetired;

  /// The participation ids chosen; `null` means every eligible pilot.
  final Set<String>? chosen;
  final bool prefillChosen;
  final CardsPerPageChoice perPage;
  final PrintMargin margin;

  /// The pilots the picker lists, by last name then given name.
  final List<ReportPilot> eligible;
  final bool hasScores;

  /// Pre-fill needs a score to print; the choice is kept while there is none.
  bool get prefillAvailable => hasScores;
  bool get prefill => prefillChosen && prefillAvailable;

  /// The pilots that get a card, in card order.
  List<ReportPilot> get selected => [
    for (final pilot in eligible)
      if (isSelected(pilot)) pilot,
  ];

  bool isSelected(ReportPilot pilot) =>
      chosen == null || chosen!.contains(pilot.participationId.value);

  /// The `pilots` filter value for [ids], or `null` for everyone.
  String? pilotsValue(Set<String> ids) {
    if (ids.length == eligible.length &&
        eligible.every((p) => ids.contains(p.participationId.value))) {
      return null;
    }
    return ids.isEmpty ? 'none' : (ids.toList()..sort()).join(',');
  }

  /// The rounds shown.
  List<int> get rounds => range.rounds;

  /// Judges the range and the pilot choice.
  ReportCheck check() {
    final rangeCheck = range.check();
    if (!identical(rangeCheck, ReportCheck.ok)) {
      return rangeCheck;
    }
    if (selected.isEmpty) {
      return const ReportEmpty(
        title: 'No pilots selected',
        body:
            'Choose at least one pilot to print a card for, or select all '
            'pilots.',
      );
    }
    return ReportCheck.ok;
  }

  /// The filters in a few words: "Rounds 1–6 · 12 of 30 pilots".
  String get summary {
    final pilots = chosen == null
        ? ''
        : ' · ${selected.length} of ${eligible.length} pilots';
    return '${range.summary}$pilots';
  }

  /// The geometry choice [perPage] asks for, when it is not automatic.
  CardsPerPage? get forced => switch (perPage) {
    CardsPerPageChoice.automatic => null,
    CardsPerPageChoice.four => CardsPerPage.four,
    CardsPerPageChoice.two => CardsPerPage.two,
  };
}
