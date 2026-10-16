import 'dart:convert';

const _escape = HtmlEscape();

/// The page shown in the browser after Auth0 sent it back successfully.
/// [appUrl] is the custom-scheme URL that returns the callback to the app.
String authCallbackDonePage({required String heading, required Uri appUrl}) =>
    _page(
      heading: heading,
      message:
          'You can now close this browser window and return to RC Soar Score.',
      appUrl: appUrl,
    );

/// The page shown when Auth0 reported a problem. The callback is still handed
/// to the app, so it can end the pending sign-in and say what went wrong.
String authCallbackErrorPage({required String detail, required Uri appUrl}) =>
    _page(
      heading: 'Sign-in was not completed',
      message:
          'You can close this browser window and try again in RC Soar Score.',
      detail: detail,
      appUrl: appUrl,
    );

/// The page shown for a request that is not an Auth0 callback.
String authCallbackRejectedPage() => _page(
  heading: 'This page is not used for sign-in',
  message: 'You can close this browser window.',
);

String _page({
  required String heading,
  required String message,
  String? detail,
  Uri? appUrl,
}) {
  final forward = appUrl == null
      ? ''
      : '''
<p class="hint">If RC Soar Score did not come to the front,
<a href="${_escape.convert(appUrl.toString())}">open it</a>.</p>
<script>window.location.href = ${_jsString(appUrl.toString())};</script>''';
  return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>RC Soar Score</title>
<style>
body { font-family: system-ui, sans-serif; margin: 0; min-height: 100vh;
  display: flex; align-items: center; justify-content: center;
  background: #f5f7fa; color: #1b2733; }
main { max-width: 28rem; padding: 2rem; text-align: center; }
h1 { font-size: 1.4rem; margin: 0 0 1rem; }
p { line-height: 1.5; margin: 0.5rem 0; }
.detail { color: #8a1c1c; }
.hint { color: #5b6b7a; font-size: 0.9rem; margin-top: 1.5rem; }
@media (prefers-color-scheme: dark) {
  body { background: #11181f; color: #e6edf3; }
  .detail { color: #ff9b9b; }
  .hint { color: #9aa8b5; }
  a { color: #8ab4f8; }
}
</style>
</head>
<body>
<main>
<h1>${_escape.convert(heading)}</h1>
<p>${_escape.convert(message)}</p>
${detail == null ? '' : '<p class="detail">${_escape.convert(detail)}</p>'}
$forward
</main>
</body>
</html>
''';
}

/// A JavaScript string literal for [value] that is safe inside a `<script>`.
String _jsString(String value) =>
    jsonEncode(value)
        .replaceAll('<', r'\u003c')
        .replaceAll('>', r'\u003e')
        .replaceAll('&', r'\u0026');
