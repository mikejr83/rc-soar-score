import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_self_score/api_client_provider.dart';

void main() {
  group('ApiClientInherited', () {
    testWidgets('provides client to descendants', (tester) async {
      final client = ApiClient(baseUrl: Uri.parse('http://localhost:8080'));

      await tester.pumpWidget(
        ApiClientInherited(
          client: client,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(context.apiClient, same(client));
                return const Text('ok');
              },
            ),
          ),
        ),
      );
    });
  });
}
