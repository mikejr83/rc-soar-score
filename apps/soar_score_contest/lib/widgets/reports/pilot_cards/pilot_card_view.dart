import 'package:flutter/material.dart';

import '../../../services/reports/pilot_cards/card_columns.dart';
import '../../../services/reports/pilot_cards/card_geometry.dart';
import '../../../services/reports/pilot_cards/card_sizing.dart';
import '../../../services/reports/pilot_cards/pilot_cards_data.dart';
import '../../../services/reports/report_pilot.dart';
import '../viewer/paper_style.dart';
import 'qr_code_view.dart';

/// One pilot's scoring card at its printed size: the contest line, the pilot's
/// name and details, an optional QR code, the table to write in and a footer
/// that dates the card. Black on white; every mark survives a black-and-white
/// inkjet.
class PilotCardView extends StatelessWidget {
  const PilotCardView({
    super.key,
    required this.geometry,
    required this.insets,
    required this.pilot,
    required this.rows,
    required this.columns,
    required this.contestLine,
    required this.fit,
    required this.footer,
    required this.printed,
    this.qrLink,
    this.prefill = false,
    this.zoom = 1,
  });

  final CardGeometry geometry;
  final CardInsets insets;
  final ReportPilot pilot;
  final List<CardRow> rows;
  final List<CardColumn> columns;
  final String contestLine;
  final CardFit fit;
  final String footer;
  final String printed;

  /// The link the QR code carries; `null` prints the card without a code.
  final String? qrLink;
  final bool prefill;

  /// Enlarges the card for reading on screen; the printout is never enlarged.
  final double zoom;

  static const _mono = [
    'Noto Sans Mono',
    'Consolas',
    'Menlo',
    'Courier New',
    'monospace',
  ];
  static final _rule = BorderSide(width: ptToPx(.5), color: PaperStyle.ink);

  @override
  Widget build(BuildContext context) {
    final card = Semantics(
      container: true,
      label: 'Scoring card, ${pilot.givenSurname}',
      child: Container(
        width: mmToPx(geometry.cardWidth),
        height: mmToPx(geometry.cardHeight),
        padding: EdgeInsets.fromLTRB(
          mmToPx(insets.left),
          mmToPx(insets.top),
          mmToPx(insets.right),
          mmToPx(insets.bottom),
        ),
        color: PaperStyle.paper,
        child: DefaultTextStyle(
          style: PaperStyle.body.copyWith(height: 1.15),
          // The sizing rules leave room for everything; the clip only keeps a
          // font that sets taller than measured from drawing over the footer.
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_top(), _table()],
                    ),
                  ),
                ),
              ),
              Positioned(left: 0, right: 0, bottom: 0, child: _footer()),
            ],
          ),
        ),
      ),
    );
    if (zoom == 1) {
      return card;
    }
    return SizedBox(
      width: mmToPx(geometry.cardWidth) * zoom,
      height: mmToPx(geometry.cardHeight) * zoom,
      child: FittedBox(fit: BoxFit.fill, child: card),
    );
  }

  Widget _top() {
    final identity = fit.identity;
    final qr = qrLink != null;
    return SizedBox(
      height: mmToPx(fit.topHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contestLine,
                      style: TextStyle(fontSize: ptToPx(7), height: 3.1 / 2.47),
                    ),
                    SizedBox(height: mmToPx(.5)),
                    Semantics(
                      header: true,
                      child: Text(
                        pilot.givenSurname,
                        style: TextStyle(
                          fontSize: ptToPx(identity.nameSizePt),
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    SizedBox(height: mmToPx(.6)),
                    for (final line in identity.details)
                      Text(
                        line,
                        style: TextStyle(
                          fontSize: ptToPx(7),
                          height: 2.8 / 2.47,
                          fontWeight: line.startsWith('Retired')
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (qr) ...[
            SizedBox(
              width: mmToPx(CardSpec.captionWidth - 1.5),
              height: mmToPx(fit.qrSize),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Scan to enter scores',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: ptToPx(7),
                    height: 3 / 2.47,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: mmToPx(1.5)),
            QrCodeView(data: qrLink!, size: mmToPx(fit.qrSize)),
            SizedBox(width: mmToPx(fit.quietZone)),
          ],
        ],
      ),
    );
  }

  Widget _table() {
    final rowHeight = mmToPx(fit.rowHeight);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: ptToPx(1), color: PaperStyle.ink),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < columns.length; i++)
                _heading(columns[i], first: i == 0),
            ],
          ),
          for (final row in rows)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < columns.length; i++)
                  _cell(columns[i], row, rowHeight, first: i == 0),
              ],
            ),
        ],
      ),
    );
  }

  Widget _heading(CardColumn column, {required bool first}) => Container(
    width: mmToPx(column.widthMm),
    height: mmToPx(CardSpec.headingHeight),
    padding: EdgeInsets.symmetric(horizontal: mmToPx(.4)),
    alignment: Alignment.bottomCenter,
    decoration: BoxDecoration(
      border: Border(
        left: first ? BorderSide.none : _rule,
        bottom: BorderSide(width: ptToPx(1), color: PaperStyle.ink),
      ),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            column.title,
            maxLines: 1,
            style: TextStyle(
              fontSize: ptToPx(6.5),
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          if (column.unit.isNotEmpty)
            Text(
              column.unit,
              style: TextStyle(fontSize: ptToPx(6.5), height: 1.1),
            ),
        ],
      ),
    ),
  );

  Widget _cell(
    CardColumn column,
    CardRow row,
    double height, {
    required bool first,
  }) {
    final score = prefill ? row.score : null;
    final occupied =
        score != null &&
        (column.kind == CardColumnKind.time ||
            column.kind == CardColumnKind.number ||
            column.kind == CardColumnKind.tick);
    final border = Border(left: first ? BorderSide.none : _rule, top: _rule);
    Widget? child;
    switch (column.kind) {
      case CardColumnKind.lead:
        final text = switch (column.field) {
          CardField.round => '${row.round}',
          CardField.group => row.group,
          _ => row.lane == null ? '' : '${row.lane}',
        };
        child = Text(
          text,
          style: TextStyle(
            fontSize: ptToPx(10),
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      case CardColumnKind.initials:
        child = null;
      case CardColumnKind.tick:
        child = occupied
            ? _tickValue(score, column.field)
            : _box(checked: false);
      case CardColumnKind.time:
      case CardColumnKind.number:
        if (occupied) {
          child = _value(score.text[column.field] ?? '–', score.official);
        } else if (column.kind == CardColumnKind.time) {
          child = ExcludeSemantics(
            child: Text(
              ':',
              style: TextStyle(
                fontSize: ptToPx(10.5),
                color: const Color(0xFF9E9E9E),
              ),
            ),
          );
        }
    }
    return Container(
      width: mmToPx(column.widthMm),
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: border,
        color: occupied ? PaperStyle.shade : null,
      ),
      child: child,
    );
  }

  Widget _value(String text, bool official) => Text(
    '$text${official ? '' : '*'}',
    maxLines: 1,
    style: TextStyle(
      fontFamilyFallback: _mono,
      fontSize: ptToPx(8),
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );

  Widget _tickValue(CardScore score, CardField field) {
    final yes = score.ticks[field] ?? false;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        yes
            ? _box(checked: true)
            : Text(
                '–',
                style: TextStyle(
                  fontFamilyFallback: _mono,
                  fontSize: ptToPx(8),
                  fontWeight: FontWeight.w700,
                ),
              ),
        if (!score.official)
          Text(
            '*',
            style: TextStyle(
              fontFamilyFallback: _mono,
              fontSize: ptToPx(8),
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _box({required bool checked}) => Container(
    width: mmToPx(3.5),
    height: mmToPx(3.5),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(width: ptToPx(.75), color: PaperStyle.ink),
    ),
    child: checked
        ? const Icon(Icons.check, size: 10, color: PaperStyle.ink)
        : null,
  );

  Widget _footer() => Container(
    padding: EdgeInsets.only(top: mmToPx(.8)),
    decoration: BoxDecoration(border: Border(top: _rule)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            footer,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(fontSize: ptToPx(6), height: 2.6 / 2.12),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          printed,
          maxLines: 1,
          style: TextStyle(fontSize: ptToPx(6), height: 2.6 / 2.12),
        ),
      ],
    ),
  );
}
