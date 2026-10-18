import 'dart:js_interop';

@JS('window.location')
external _Location get _location;

extension type _Location(JSObject _) implements JSObject {
  external void assign(JSString url);
}

void openExternalUrl(String url) => _location.assign(url.toJS);
