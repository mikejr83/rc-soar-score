// Exposes `openExternalUrl(String url)`, which sends the browser to an
// external URL in the same tab. The public site is web-only; on other
// platforms (the VM running tests) the stub is a no-op.
export 'external_url_stub.dart'
    if (dart.library.js_interop) 'external_url_web.dart';
