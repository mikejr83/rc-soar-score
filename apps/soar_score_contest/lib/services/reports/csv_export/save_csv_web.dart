import 'dart:js_interop';
import 'dart:convert';

import 'package:web/web.dart' as web;

/// The browser downloads the CSV as a blob. Returns the file name, or `null`
/// (the browser cannot report a cancel for a download).
Future<String?> saveCsvFile(String fileName, String csv) async {
  final bytes = utf8.encode(csv);
  final parts = JSArray<web.BlobPart>();
  parts.add(bytes.toJS as web.BlobPart);
  final blob = web.Blob(
    parts,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  // Revoke after a short delay: revoking right after the click can cancel the
  // download in Safari and older Firefox.
  await _delaySeconds(1);
  web.URL.revokeObjectURL(url);
  return fileName;
}

Future<void> _delaySeconds(double seconds) =>
    Future<void>.delayed(Duration(milliseconds: (seconds * 1000).round()));
