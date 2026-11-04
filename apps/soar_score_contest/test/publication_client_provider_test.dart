import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';

void main() {
  final local = ApiClient(baseUrl: Uri.parse('http://127.0.0.1:1'));
  final remote = ApiClient(baseUrl: Uri.parse('http://127.0.0.1:2'));

  testWidgets('publishing uses the publication client when one is provided', (
    tester,
  ) async {
    ApiClient? seenPublication;
    ApiClient? seenApp;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ApiClientInherited(
          client: local,
          child: PublicationClientInherited(
            client: remote,
            child: Builder(
              builder: (context) {
                seenPublication = publicationClientOf(context);
                seenApp = apiClientOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    expect(seenPublication, same(remote));
    expect(seenApp, same(local));
  });

  testWidgets('without a publication client it falls back to the app client', (
    tester,
  ) async {
    ApiClient? seen;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ApiClientInherited(
          client: local,
          child: Builder(
            builder: (context) {
              seen = publicationClientOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(seen, same(local));
  });
}
