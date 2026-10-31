import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final contestId = Id.parse('019c0000-0000-7000-8000-000000000020');
  final profileId = Id.parse('019c0000-0000-7000-8000-000000000101');
  final participationId = Id.parse('019c0000-0000-7000-8000-000000000201');
  final modelId = Id.parse('019c0000-0000-7000-8000-000000000301');
  final linkId = Id.parse('019c0000-0000-7000-8000-000000000401');
  final owner = Id.parse('019c0000-0000-7000-8000-000000000001');
  final model = ModelCatalog(
    id: modelId,
    ownerAccountId: owner,
    participantProfileId: profileId,
    name: 'Supra',
  );
  final link = ContestModelLink(
    id: linkId,
    contestId: contestId,
    contestParticipationId: participationId,
    modelName: 'Supra',
  );

  late http.Request seen;

  ApiClient clientFor(http.Response Function(http.Request) respond) {
    final client = ApiClient(
      baseUrl: Uri.parse('http://localhost:8085'),
      httpClient: MockClient((request) async {
        seen = request;
        return respond(request);
      }),
    );
    addTearDown(client.close);
    return client;
  }

  http.Response body(Object json, [int status = 200]) => http.Response(
    jsonEncode(json),
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );

  group('profile models', () {
    test('lists, adds, updates and removes', () async {
      var client = clientFor(
        (_) => body({
          'models': [model.toJson()],
        }),
      );
      expect(await client.profileModels(profileId), [model]);
      expect(seen.url.path, '/api/v1/participants/${profileId.value}/models');

      client = clientFor((_) => body(model.toJson(), 201));
      expect(
        await client.addProfileModel(
          profileId,
          AddProfileModelRequest(id: modelId, name: 'Supra'),
        ),
        model,
      );
      expect(seen.method, 'POST');
      expect(jsonDecode(seen.body), {
        'id': modelId.value,
        'name': 'Supra',
        'manufacturer': null,
        'model_id': null,
      });

      client = clientFor((_) => body(model.toJson()));
      await client.updateProfileModel(
        profileId,
        modelId,
        const UpdateProfileModelRequest(baseRevision: 0, name: 'Supra'),
      );
      expect(seen.method, 'PUT');
      expect(
        seen.url.path,
        '/api/v1/participants/${profileId.value}/models/${modelId.value}',
      );

      client = clientFor((_) => http.Response('', 204));
      await client.removeProfileModel(profileId, modelId);
      expect(seen.method, 'DELETE');
    });
  });

  group('contest model links', () {
    test('lists, adds, updates and removes', () async {
      var client = clientFor(
        (_) => body({
          'model_links': [link.toJson()],
        }),
      );
      expect(await client.modelLinks(contestId), [link]);
      expect(seen.url.path, '/api/v1/contests/${contestId.value}/model-links');

      client = clientFor((_) => body(link.toJson(), 201));
      expect(
        await client.addModelLink(
          contestId,
          participationId,
          AddModelLinkRequest(id: linkId, modelName: 'Supra'),
        ),
        link,
      );
      expect(seen.method, 'POST');
      expect(
        seen.url.path,
        '/api/v1/contests/${contestId.value}/participations/'
        '${participationId.value}/model-links',
      );

      client = clientFor((_) => body(link.toJson()));
      await client.updateModelLink(
        contestId,
        linkId,
        const UpdateModelLinkRequest(baseRevision: 0, modelName: 'Supra'),
      );
      expect(seen.method, 'PUT');
      expect(
        seen.url.path,
        '/api/v1/contests/${contestId.value}/model-links/${linkId.value}',
      );

      client = clientFor((_) => http.Response('', 204));
      await client.removeModelLink(contestId, linkId);
      expect(seen.method, 'DELETE');
    });
  });
}
