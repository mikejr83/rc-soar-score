import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

import '../../../services/reports/pilot_cards/card_geometry.dart';

/// A QR code of [data], square modules in pure black on white, with no logo
/// and no styling, so a household inkjet in document quality prints it and a
/// phone reads it at arm's length.
///
/// The code is version 5 (37 modules a side) at error correction M while the
/// data fits (84 bytes, room for the invitation link); a longer link takes the
/// smallest version that holds it. A shorter link is set in version 5 too, so
/// the quiet zone the card reserves is always four modules. The quiet zone around the code is
/// drawn by the caller.
class QrCodeView extends StatelessWidget {
  const QrCodeView({
    super.key,
    required this.data,
    required this.size,
    this.label = 'QR code, scan to enter scores',
  });

  final String data;

  /// The side of the square in logical pixels.
  final double size;
  final String label;

  static QrImage encode(String data) {
    try {
      return QrImage(
        QrCode(CardSpec.qrVersion, QrErrorCorrectLevel.M)..addData(data),
      );
    } on Exception {
      // The data does not fit version 5: take the smallest version that does.
      return QrImage(
        QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _QrPainter(encode(data))),
      ),
    ),
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    final count = image.moduleCount;
    final module = size.width / count;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final ink = Paint()
      ..color = const Color(0xFF000000)
      ..isAntiAlias = false;
    for (var y = 0; y < count; y++) {
      for (var x = 0; x < count; x++) {
        if (image.isDark(y, x)) {
          // A hair of overlap closes the seams between neighbours.
          canvas.drawRect(
            Rect.fromLTWH(x * module, y * module, module + .3, module + .3),
            ink,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.image != image;
}
