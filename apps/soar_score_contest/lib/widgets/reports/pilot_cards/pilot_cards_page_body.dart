import 'package:flutter/material.dart';

import '../../../services/reports/pilot_cards/card_geometry.dart';
import '../viewer/paper_style.dart';

/// The body of one printed page of cards: two columns, one row in two-up and
/// two in four-up, with dashed cut lines between the cards that are there.
///
/// Cards meet edge to edge, so a four-up sheet needs one vertical and one
/// horizontal cut and a two-up sheet one vertical cut. The page margin stays
/// on the outer cards as a narrow strip, so nothing needs trimming. On a last
/// page with fewer cards the lines only surround the cards that exist.
class PilotCardsPageBody extends StatelessWidget {
  const PilotCardsPageBody({
    super.key,
    required this.geometry,
    required this.cards,
    required this.size,
    required this.number,
  });

  final CardGeometry geometry;

  /// The cards of the page, at most [CardsPerPage.count], in reading order.
  final List<Widget> cards;
  final Size size;
  final int number;

  @override
  Widget build(BuildContext context) {
    final cardW = mmToPx(geometry.cardWidth);
    final cardH = mmToPx(geometry.cardHeight);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Semantics(
        container: true,
        label:
            'Page $number, ${cards.length} '
            '${cards.length == 1 ? 'card' : 'cards'}',
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (var i = 0; i < cards.length; i++)
              Positioned(
                left: (i % 2) * cardW,
                top: (i ~/ 2) * cardH,
                width: cardW,
                height: cardH,
                child: cards[i],
              ),
            Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _CutLines(
                    cards: cards.length,
                    cardWidth: cardW,
                    cardHeight: cardH,
                    pageWidth: size.width,
                    pageHeight: size.height,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashed black lines on every edge two cards share, or an existing card shares
/// with the empty space beside it, except the edges of the page itself.
class _CutLines extends CustomPainter {
  _CutLines({
    required this.cards,
    required this.cardWidth,
    required this.cardHeight,
    required this.pageWidth,
    required this.pageHeight,
  });

  final int cards;
  final double cardWidth;
  final double cardHeight;
  final double pageWidth;
  final double pageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final segments = <(Offset, Offset)>{};
    for (var i = 0; i < cards; i++) {
      final x0 = (i % 2) * cardWidth;
      final y0 = (i ~/ 2) * cardHeight;
      final x1 = x0 + cardWidth;
      final y1 = y0 + cardHeight;
      segments
        ..add((Offset(x0, y0), Offset(x1, y0)))
        ..add((Offset(x0, y1), Offset(x1, y1)))
        ..add((Offset(x0, y0), Offset(x0, y1)))
        ..add((Offset(x1, y0), Offset(x1, y1)));
    }
    final paint = Paint()
      ..color = PaperStyle.ink
      ..strokeWidth = ptToPx(.75)
      ..style = PaintingStyle.stroke;
    for (final (a, b) in segments) {
      final vertical = a.dx == b.dx;
      final onPageEdge = vertical
          ? a.dx <= 0.5 || a.dx >= pageWidth - 0.5
          : a.dy <= 0.5 || a.dy >= pageHeight - 0.5;
      if (onPageEdge) {
        continue;
      }
      _dashed(canvas, a, b, paint);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.67;
    const gap = 3.78;
    final length = (b - a).distance;
    final direction = (b - a) / length;
    for (var at = 0.0; at < length; at += dash + gap) {
      final end = (at + dash).clamp(0, length).toDouble();
      canvas.drawLine(a + direction * at, a + direction * end, paint);
    }
  }

  @override
  bool shouldRepaint(_CutLines old) =>
      old.cards != cards ||
      old.cardWidth != cardWidth ||
      old.cardHeight != cardHeight;
}
