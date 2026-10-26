import '../report_pilot.dart';
import '../viewer/page_setup.dart';
import 'card_geometry.dart';
import 'card_sizing.dart';
import 'pilot_cards_options.dart';

/// Whether the cards go four or two to a page, and why. The rounds decide, not
/// a fixed count: four-up when every round row fits a quadrant at the minimum
/// writable height with the identity block, QR code and header; two-up
/// otherwise; and a plain notice when even a half page cannot hold them.
class CardSheetDecision {
  const CardSheetDecision._({
    required this.rounds,
    required this.perPage,
    required this.fitsFour,
    required this.fitsTwo,
    required this.maxFour,
    required this.maxTwo,
    required this.choice,
  });

  factory CardSheetDecision.of({
    required PaperSize paper,
    required List<ReportPilot> pilots,
    required String contestLine,
    required String footer,
    required int rounds,
    required CardsPerPageChoice choice,
  }) {
    final four = CardGeometry.of(paper, CardsPerPage.four);
    final two = CardGeometry.of(paper, CardsPerPage.two);
    bool fits(CardGeometry g) => CardSizing.fitsAll(
      geometry: g,
      pilots: pilots,
      contestLine: contestLine,
      footer: footer,
      rounds: rounds,
    );
    int most(CardGeometry g) => CardSizing.maxRounds(
      geometry: g,
      pilots: pilots,
      contestLine: contestLine,
      footer: footer,
      qr: true,
    );
    final fitsFour = fits(four);
    final fitsTwo = fits(two);
    final CardsPerPage? picked;
    if (!fitsTwo) {
      picked = null;
    } else if (choice == CardsPerPageChoice.two || !fitsFour) {
      picked = CardsPerPage.two;
    } else {
      picked = CardsPerPage.four;
    }
    return CardSheetDecision._(
      rounds: rounds,
      perPage: picked,
      fitsFour: fitsFour,
      fitsTwo: fitsTwo,
      maxFour: most(four),
      maxTwo: most(two),
      choice: choice,
    );
  }

  final int rounds;

  /// The layout used; `null` when the rounds do not fit even a half page.
  final CardsPerPage? perPage;
  final bool fitsFour;
  final bool fitsTwo;
  final int maxFour;
  final int maxTwo;
  final CardsPerPageChoice choice;

  bool get tooMany => !fitsTwo;

  /// The line under the Cards per page choice.
  String get message {
    if (rounds == 0) {
      return 'No rounds in range.';
    }
    if (tooMany) {
      return 'This contest has too many rounds for a scoring card. A '
          'half-page card holds up to $maxTwo rounds at the minimum 8 mm row '
          'height.';
    }
    if (perPage == CardsPerPage.two && choice == CardsPerPageChoice.two) {
      return '$rounds rounds on half-page cards. Up to $maxTwo fit.';
    }
    if (perPage == CardsPerPage.four) {
      return '$rounds rounds fit four to a page (up to $maxFour at 8 mm '
          'rows).';
    }
    return '$rounds rounds don’t fit four to a page; using two. Four holds '
        'up to $maxFour.';
  }
}
