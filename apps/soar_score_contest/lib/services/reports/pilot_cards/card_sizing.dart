import 'dart:math' as math;

import '../report_pilot.dart';
import 'card_geometry.dart';

/// The text above the table: the contest line, the pilot's name and the lines
/// of detail under it, with the room they take.
class CardIdentity {
  const CardIdentity({
    required this.nameSizePt,
    required this.nameLines,
    required this.details,
    required this.footerHeightMm,
    required this.heightMm,
  });

  /// The name's size in points: 18, shrinking in half-point steps to 14, then
  /// wrapping. A name is never cut short.
  final double nameSizePt;
  final int nameLines;

  /// The lines under the name: club, then IDs, class and team.
  final List<String> details;

  /// The room the footer text takes at the bottom of the block.
  final double footerHeightMm;

  /// The whole block: contest line, name, details and footer text.
  final double heightMm;
}

/// How a card sizes itself. Pure functions of millimetres, so the rules in the
/// plan can be tested without drawing anything.
abstract final class CardSizing {
  static const double _contestLineSizePt = 7;
  static const double _detailSizePt = 7;
  static const double _footerSizePt = 6;
  static const double _detailLineMm = 2.8;
  static const double _contestLineMm = 3.1;

  /// Lines needed to set [text] at [pt] in [widthMm]; [width] is the average
  /// character width as a fraction of the type size.
  static int lines(String text, double pt, double widthMm, double width) {
    final charMm = pt * 0.3528 * width;
    var n = 1;
    var current = 0.0;
    for (final word in text.split(RegExp(r'(?<=[\s-])'))) {
      final length = word.length * charMm;
      if (current > 0 && current + length > widthMm) {
        n++;
        current = length;
      } else {
        current += length;
      }
      while (current > widthMm) {
        n++;
        current -= widthMm;
      }
    }
    return n;
  }

  /// The detail lines of [pilot]: club, then IDs, class, team and "Retired".
  static List<String> details(ReportPilot pilot) {
    final second = [
      if (pilot.isRetired) 'Retired',
      if (pilot.faiId != null) 'FAI ID ${pilot.faiId}',
      if (pilot.nationalId != null) 'National ID ${pilot.nationalId}',
      if (pilot.className != null) 'Class ${pilot.className}',
      if (pilot.team != null) 'Team ${pilot.team}',
    ].join(' · ');
    return [?pilot.club, if (second.isNotEmpty) second];
  }

  static CardIdentity identity(
    ReportPilot pilot,
    String contestLine,
    double widthMm,
    String footer,
  ) {
    final name = pilot.givenSurname;
    var size = 18.0;
    while (size > 14 && lines(name, size, widthMm, .62) > 1) {
      size -= .5;
    }
    final nameLines = lines(name, size, widthMm, .62);
    final details = CardSizing.details(pilot);
    final detailLines = details.fold(
      0,
      (sum, line) => sum + lines(line, _detailSizePt, widthMm, .56),
    );
    final contestLines = lines(contestLine, _contestLineSizePt, widthMm, .56);
    final footerMm = footer.isEmpty
        ? 0.0
        : lines(footer, _footerSizePt, widthMm, .56) *
                  CardSpec.footerLineHeight +
              .6;
    final height =
        contestLines * _contestLineMm +
        .5 +
        nameLines * size * .3528 * 1.1 +
        .6 +
        detailLines * _detailLineMm +
        footerMm;
    return CardIdentity(
      nameSizePt: size,
      nameLines: nameLines,
      details: details,
      footerHeightMm: footerMm,
      heightMm: height,
    );
  }

  /// How a card fits its geometry.
  static CardFit fit({
    required CardGeometry geometry,
    required ReportPilot pilot,
    required String contestLine,
    required String footer,
    required bool qr,
    required int rounds,
  }) {
    final width = geometry.contentWidth;
    final room =
        geometry.cardHeight -
        geometry.insetVertical -
        CardSpec.headingHeight -
        2 * CardSpec.tableOutline -
        .3;
    final table = room - rounds * CardSpec.rowMin;
    // The code and the quiet zone below it (four modules) share the block; the
    // card's inset and the page edge supply the quiet zone on the other sides.
    final qrFit =
        table *
        CardSpec.qrModules /
        (CardSpec.qrModules + CardSpec.quietModules);
    final size = qr
        ? math.max(CardSpec.qrMin, math.min(CardSpec.qr, qrFit))
        : 0.0;
    final quiet = size * CardSpec.quietModules / CardSpec.qrModules;
    final identity = CardSizing.identity(
      pilot,
      contestLine,
      width - (qr ? size + quiet + CardSpec.captionWidth : 0),
      footer,
    );
    final top = math.max(identity.heightMm + 1, qr ? size + quiet : 0.0);
    final ok = (!qr || qrFit >= CardSpec.qrMin - 1e-6) && top <= table + 1e-6;
    return CardFit(
      identity: identity,
      qrSize: size,
      quietZone: quiet,
      topHeight: top,
      ok: ok,
      rowHeight: math.min(CardSpec.rowMax, (room - top) / math.max(rounds, 1)),
    );
  }

  /// The most rounds a card of [geometry] holds at the minimum row height for
  /// the tallest of [pilots].
  static int maxRounds({
    required CardGeometry geometry,
    required List<ReportPilot> pilots,
    required String contestLine,
    required String footer,
    required bool qr,
  }) {
    var n = 0;
    while (n < 60 &&
        _allFit(geometry, pilots, contestLine, footer, qr, n + 1)) {
      n++;
    }
    return n;
  }

  static bool _allFit(
    CardGeometry geometry,
    List<ReportPilot> pilots,
    String contestLine,
    String footer,
    bool qr,
    int rounds,
  ) => pilots.every(
    (pilot) => fit(
      geometry: geometry,
      pilot: pilot,
      contestLine: contestLine,
      footer: footer,
      qr: qr,
      rounds: rounds,
    ).ok,
  );

  /// Whether every pilot's card fits [rounds] rows in [geometry]. The sheet is
  /// sized as if every card had a QR code, so sending invitations later never
  /// changes the page count.
  static bool fitsAll({
    required CardGeometry geometry,
    required List<ReportPilot> pilots,
    required String contestLine,
    required String footer,
    required int rounds,
  }) => _allFit(geometry, pilots, contestLine, footer, true, rounds);
}

/// The result of fitting one card.
class CardFit {
  const CardFit({
    required this.identity,
    required this.qrSize,
    required this.quietZone,
    required this.topHeight,
    required this.ok,
    required this.rowHeight,
  });

  final CardIdentity identity;

  /// The QR square in millimetres; 0 without a QR code.
  final double qrSize;
  final double quietZone;
  final double topHeight;

  /// The card holds its rounds at the minimum row height.
  final bool ok;

  /// The row height in millimetres, between the minimum and the maximum.
  final double rowHeight;
}
