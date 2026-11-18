import 'dart:async';
import 'dart:js_interop';
import 'dart:convert';

import 'package:web/web.dart' as web;

/// The browser downloads the file as a blob. Returns the file name, or `null`
/// (the browser cannot report a cancel for a download).
Future<String?> saveCsvFile(
  String fileName,
  String csv, {
  String extension = 'csv',
}) async {
  final bytes = utf8.encode(csv);
  final parts = JSArray<web.BlobPart>();
  parts.add(bytes.toJS as web.BlobPart);
  final blob = web.Blob(
    parts,
    web.BlobPropertyBag(type: 'text/$extension;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  // Attach the anchor to the document before clicking: older Firefox may
  // ignore a click on a detached element.
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  // Revoke after a short delay: revoking right after the click can cancel the
  // download in Safari and older Firefox. The delay is a fire-and-forget timer
  // so the "saved" feedback is not held up.
  Timer(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
  return fileName;
}
