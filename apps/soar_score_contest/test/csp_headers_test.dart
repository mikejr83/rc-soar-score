import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('CSP headers regression test', () {
    final requiredOrigins = [
      'https://lh3.googleusercontent.com',
      'https://lh4.googleusercontent.com',
      'https://graph.facebook.com',
      'https://*.fbcdn.net',
      'https://avatars.githubusercontent.com',
      'https://pbs.twimg.com',
      'https://abs.twimg.com',
      'https://is1-ssl.mzstatic.com',
      'https://media.licdn.com',
      'https://static.licdn.com',
      'https://s.yimg.com',
      'https://s.gravatar.com',
      'https://secure.gravatar.com',
      'https://www.gravatar.com',
    ];

    String resolvePath(String appDir) {
      // Find the workspace root by walking up from the test file's directory
      // and looking for the .kilo directory (workspace root marker).
      var path = Directory.current.path;
      while (true) {
        if (Directory('$path/.kilo').existsSync()) {
          break;
        }
        final parent = Directory(path).parent.path;
        if (parent == path) break;
        path = parent;
      }
      return '$path/$appDir/web/_headers';
    }

    Future<String> readHeadersFile(String appDir) async {
      final headersPath = resolvePath(appDir);
      final headersFile = File(headersPath);
      expect(
        headersFile.existsSync(),
        true,
        reason: 'web/_headers file should exist at $headersPath',
      );
      return headersFile.readAsStringSync();
    }

    Future<String> extractDirective(String headers, String directive) async {
      // Find a CSP directive in the headers
      final regex = RegExp(directive + r'\s([^;]+);');
      final match = regex.firstMatch(headers);
      expect(
        match,
        isNotNull,
        reason: '$directive directive should be present in CSP',
      );
      return match!.group(1)!.trim();
    }

    void expectOriginsPresent(
      String directive,
      String value,
      List<String> origins,
    ) {
      for (final origin in origins) {
        expect(
          value.contains(origin),
          true,
          reason: '$directive should allow $origin',
        );
      }
    }

    test('contest app img-src allows social provider profile images', () async {
      final headers = await readHeadersFile('apps/soar_score_contest');
      final imgSrc = await extractDirective(headers, 'img-src');
      expectOriginsPresent('img-src', imgSrc, requiredOrigins);
    });

    test(
      'self-score app img-src allows social provider profile images',
      () async {
        final headers = await readHeadersFile('apps/soar_score_self_score');
        final imgSrc = await extractDirective(headers, 'img-src');
        expectOriginsPresent('img-src', imgSrc, requiredOrigins);
      },
    );

    // Flutter web's Image.network uses XMLHttpRequest which is governed by
    // connect-src, not img-src. The connect-src must also allow avatar origins.
    test('contest app connect-src allows avatar image origins', () async {
      final headers = await readHeadersFile('apps/soar_score_contest');
      final connectSrc = await extractDirective(headers, 'connect-src');
      expectOriginsPresent('connect-src', connectSrc, requiredOrigins);
    });

    test('self-score app connect-src allows avatar image origins', () async {
      final headers = await readHeadersFile('apps/soar_score_self_score');
      final connectSrc = await extractDirective(headers, 'connect-src');
      expectOriginsPresent('connect-src', connectSrc, requiredOrigins);
    });
  });
}
