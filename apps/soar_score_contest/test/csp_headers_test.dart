import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('CSP headers regression test', () {
    final requiredOrigins = [
      'https://lh3.googleusercontent.com',
      'https://lh4.googleusercontent.com',
      'https://graph.facebook.com',
      'https://scontent-*.fbcdn.net',
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
      // Find the workspace root by walking up from test directory
      var path = Directory.current.path;
      while (!path.endsWith('soar-score') && !path.endsWith('abrupt-soap')) {
        final parent = Directory(path).parent.path;
        if (parent == path) break;
        path = parent;
      }
      return '$path/$appDir/web/_headers';
    }

    Future<String> readHeadersFile(String appDir) async {
      final headersPath = resolvePath(appDir);
      final headersFile = File(headersPath);
      expect(headersFile.existsSync(), true,
          reason: 'web/_headers file should exist at $headersPath');
      return headersFile.readAsStringSync();
    }

    Future<String> extractImgSrc(String headers) async {
      // Find the img-src directive in the CSP
      final imgSrcMatch = RegExp(r"img-src\s([^;]+);").firstMatch(headers);
      expect(imgSrcMatch, isNotNull,
          reason: 'img-src directive should be present in CSP');
      return imgSrcMatch!.group(1)!.trim();
    }

    void expectOriginsPresent(String imgSrc, List<String> origins) {
      for (final origin in origins) {
        expect(imgSrc.contains(origin), true,
            reason: 'img-src should allow $origin');
      }
    }

    test('contest app img-src allows social provider profile images', () async {
      final headers = await readHeadersFile('apps/soar_score_contest');
      final imgSrc = await extractImgSrc(headers);
      expectOriginsPresent(imgSrc, requiredOrigins);
    });

    test('self-score app img-src allows social provider profile images',
        () async {
      final headers = await readHeadersFile('apps/soar_score_self_score');
      final imgSrc = await extractImgSrc(headers);
      expectOriginsPresent(imgSrc, requiredOrigins);
    });
  });
}