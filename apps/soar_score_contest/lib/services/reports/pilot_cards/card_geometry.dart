import '../viewer/page_setup.dart';

/// Millimetres to logical pixels (96 to the inch), so a card is drawn at its
/// printed size.
const double pxPerMm = 96 / 25.4;

double mmToPx(double mm) => mm * pxPerMm;

/// Points to logical pixels.
double ptToPx(double pt) => pt * 4 / 3;

/// The sizes that decide how a card is laid out, in millimetres.
abstract final class CardSpec {
  /// The inset a card keeps at a cut line.
  static const double inset = 3.5;

  /// The QR square: this size when there is room, never below [qrMin].
  static const double qr = 25;
  static const double qrMin = 18;

  /// The QR code is version 3: 29 modules a side, with a quiet zone of four.
  static const int qrModules = 29;
  static const int quietModules = 4;

  /// Writable rows: at least [rowMin], growing to [rowMax] when there is room.
  static const double rowMin = 8;
  static const double rowMax = 10;

  /// The table's outline is 1 pt (0.3528 mm) on each side.
  static const double tableOutline = 0.3528;

  static const double headingHeight = 6.5;
  static const double footerHeight = 3.4;

  /// The caption beside the QR code.
  static const double captionWidth = 14;

  /// The page margins of the shared sheet layout (16, 24 and 14 px).
  static const double marginX = 16 / pxPerMm;
  static const double marginTop = 24 / pxPerMm;
  static const double marginBottom = 14 / pxPerMm;
}

/// How many cards a page holds.
enum CardsPerPage {
  four(4),
  two(2);

  const CardsPerPage(this.count);

  final int count;
}

/// The size of a page and of a card on it, in millimetres. Cards are always
/// landscape.
class CardGeometry {
  const CardGeometry._({
    required this.pageWidth,
    required this.pageHeight,
    required this.perPage,
  });

  factory CardGeometry.of(PaperSize paper, CardsPerPage perPage) {
    final (short, long) = switch (paper) {
      PaperSize.letter => (215.9, 279.4),
      PaperSize.a4 => (210.0, 297.0),
    };
    return CardGeometry._(pageWidth: long, pageHeight: short, perPage: perPage);
  }

  final double pageWidth;
  final double pageHeight;
  final CardsPerPage perPage;

  double get cardWidth => (pageWidth - 2 * CardSpec.marginX) / 2;

  double get _areaHeight =>
      pageHeight - CardSpec.marginTop - CardSpec.marginBottom;

  double get cardHeight =>
      perPage == CardsPerPage.four ? _areaHeight / 2 : _areaHeight;

  /// The content width of a card, less the inset at its cut line.
  double get contentWidth => cardWidth - CardSpec.inset;

  /// The vertical room the inset takes: top or bottom in four-up.
  double get insetVertical => perPage == CardsPerPage.four ? CardSpec.inset : 0;

  /// The insets of card [index] on its page: only where it meets a cut.
  CardInsets insetsOf(int index) {
    final column = index % 2;
    final row = (index ~/ 2) % 2;
    final four = perPage == CardsPerPage.four;
    return CardInsets(
      top: four && row == 1 ? CardSpec.inset : 0,
      bottom: four && row == 0 ? CardSpec.inset : 0,
      left: column == 1 ? CardSpec.inset : 0,
      right: column == 0 ? CardSpec.inset : 0,
    );
  }
}

class CardInsets {
  const CardInsets({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  final double top;
  final double bottom;
  final double left;
  final double right;
}
