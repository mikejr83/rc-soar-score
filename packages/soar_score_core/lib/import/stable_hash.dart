/// A small, deterministic, web-safe hash for change detection.
///
/// Two 32-bit FNV-1a lanes with different offsets, joined into 16 hex
/// characters. It is not cryptographic: it only answers "is this the same
/// content as last time", where a collision is as unlikely as a typo in the
/// file. Every step stays below 2^53, so the Dart VM and dart2js agree.
String stableHash(String text) {
  var a = 0x811c9dc5;
  var b = 0x9747b28c;
  for (final unit in text.codeUnits) {
    a = _step(a, unit);
    b = _step(b, unit ^ 0x5a);
  }
  return _hex(a) + _hex(b);
}

/// `(h ^ unit) * 16777619 mod 2^32` without ever exceeding 2^53.
int _step(int hash, int unit) {
  final h = (hash ^ (unit & 0xffff)) & 0xffffffff;
  // 16777619 = 2^24 + 403.
  return (h * 403 + (h & 0xff) * 16777216) & 0xffffffff;
}

String _hex(int value) => value.toRadixString(16).padLeft(8, '0');
