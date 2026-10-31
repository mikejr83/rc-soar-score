import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
final _other = Id.parse('019c0000-0000-7000-8000-000000000002');
const _contestId = '019c0000-0000-7000-8000-000000000020';
const _profileId = '019c0000-0000-7000-8000-000000000101';
const _participationId = '019c0000-0000-7000-8000-000000000201';
const _modelId = '019c0000-0000-7000-8000-000000000301';
const _linkId = '019c0000-0000-7000-8000-000000000401';

void main() {
  late HandlerHarness api;

  setUp(() async {
    api = HandlerHarness(_owner);
    await api.send(
      'POST',
      '/contests',
      body: {
        'id': _contestId,
        'name': 'Spring Open',
        'start_date_time': '2026-10-17T14:00:00.000Z',
        'end_date_time': '2026-10-18T22:00:00.000Z',
        'timezone': 'America/Denver',
      },
    );
    await api.send(
      'POST',
      '/participants',
      body: {'id': _profileId, 'first_name': 'Ada', 'last_name': 'Lovelace'},
    );
  });

  Future<void> addParticipation({String? roleId}) async {
    final response = await api.send(
      'POST',
      '/contests/$_contestId/participations',
      body: {
        'id': _participationId,
        'participant_profile_id': _profileId,
        'role_id': roleId,
      },
    );
    expect(response.statusCode, 201);
  }

  Future<Map<String, Object?>> addModel([Map<String, Object?>? body]) async {
    final response = await api.send(
      'POST',
      '/participants/$_profileId/models',
      body:
          body ??
          {
            'id': _modelId,
            'name': 'Supra',
            'manufacturer': 'Vladimir',
            'model_id': 'S-1',
          },
    );
    final json = await api.json(response);
    expect(response.statusCode, 201, reason: '$json');
    return json;
  }

  String linksPath() =>
      '/contests/$_contestId/participations/$_participationId/model-links';

  Future<Map<String, Object?>> addLink([Map<String, Object?>? body]) async {
    final response = await api.send(
      'POST',
      linksPath(),
      body: body ?? {'id': _linkId, 'model_name': 'Home-built'},
    );
    final json = await api.json(response);
    expect(response.statusCode, 201, reason: '$json');
    return json;
  }

  group('profile models', () {
    test('adds, lists, updates and removes', () async {
      final model = await addModel();
      expect(model['participant_profile_id'], _profileId);
      expect(model['model_id'], 'S-1');
      expect(model['revision'], 0);

      final listed = await api.json(
        await api.send('GET', '/participants/$_profileId/models'),
      );
      expect(listed['models'], [model]);

      final updated = await api.json(
        await api.send(
          'PUT',
          '/participants/$_profileId/models/$_modelId',
          body: {'base_revision': 0, 'name': 'Supra 2'},
        ),
      );
      expect(updated['name'], 'Supra 2');
      expect(updated['manufacturer'], isNull);
      expect(updated['revision'], 1);

      final removed = await api.send(
        'DELETE',
        '/participants/$_profileId/models/$_modelId',
      );
      expect(removed.statusCode, 204);
      expect(api.repository.modelCatalogs.models, isEmpty);
    });

    test('repeating an add returns the same model', () async {
      final first = await addModel();
      expect(await addModel(), first);
      expect(api.repository.modelCatalogs.models, hasLength(1));
    });

    test('the same id with other content is a 409', () async {
      await addModel();

      final response = await api.send(
        'POST',
        '/participants/$_profileId/models',
        body: {'id': _modelId, 'name': 'Other'},
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'already_stored');
    });

    test('another model with the same name and maker is a 409', () async {
      await addModel();

      final response = await api.send(
        'POST',
        '/participants/$_profileId/models',
        body: {
          'id': '019c0000-0000-7000-8000-000000000302',
          'name': 'Supra',
          'manufacturer': 'Vladimir',
        },
      );

      expect(response.statusCode, 409);
    });

    test('a blank name is a 400', () async {
      final response = await api.send(
        'POST',
        '/participants/$_profileId/models',
        body: {'id': _modelId, 'name': ' '},
      );

      expect(response.statusCode, 400);
    });

    test('a stale base revision is a 409', () async {
      await addModel();

      final response = await api.send(
        'PUT',
        '/participants/$_profileId/models/$_modelId',
        body: {'base_revision': 3, 'name': 'Supra'},
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'stale_revision');
    });

    test('another director\'s profile is a 404', () async {
      final stranger = HandlerHarness(_other);
      stranger.repository.participantProfiles.profiles.addAll(
        api.repository.participantProfiles.profiles,
      );

      final response = await stranger.send(
        'GET',
        '/participants/$_profileId/models',
      );

      expect(response.statusCode, 404);
    });

    test('deleting a profile removes its models', () async {
      await addModel();

      final response = await api.send('DELETE', '/participants/$_profileId');

      expect(response.statusCode, 204);
      expect(api.repository.modelCatalogs.models, isEmpty);
    });
  });

  group('contest model links', () {
    setUp(addParticipation);

    test('a pilot can have several, or none', () async {
      expect(
        (await api.json(
          await api.send('GET', '/contests/$_contestId/model-links'),
        ))['model_links'],
        isEmpty,
      );

      final first = await addLink();
      await addLink({
        'id': '019c0000-0000-7000-8000-000000000402',
        'model_name': 'Spare',
        'contest_specific_identifier': 'A1',
      });

      expect(first['contest_participation_id'], _participationId);
      expect(first['model_id'], isNull);
      final listed = await api.json(
        await api.send('GET', '/contests/$_contestId/model-links'),
      );
      expect(listed['model_links'], hasLength(2));
    });

    test('a link to a profile model copies it, with overrides', () async {
      await addModel();

      final link = await addLink({
        'id': _linkId,
        'model_catalog_id': _modelId,
        'model_id': 'S-9',
      });

      expect(link['model_catalog_id'], _modelId);
      expect(link['model_name'], 'Supra');
      expect(link['manufacturer'], 'Vladimir');
      expect(link['model_id'], 'S-9');
    });

    test('without a name or profile model it is a 400', () async {
      final response = await api.send(
        'POST',
        linksPath(),
        body: {'id': _linkId},
      );

      expect(response.statusCode, 400);
    });

    test('a model of another profile is a 404', () async {
      await api.send(
        'POST',
        '/participants',
        body: {
          'id': '019c0000-0000-7000-8000-000000000102',
          'first_name': 'Grace',
          'last_name': 'Hopper',
        },
      );
      await api.send(
        'POST',
        '/participants/019c0000-0000-7000-8000-000000000102/models',
        body: {'id': _modelId, 'name': 'Other'},
      );

      final response = await api.send(
        'POST',
        linksPath(),
        body: {'id': _linkId, 'model_catalog_id': _modelId},
      );

      expect(response.statusCode, 404);
    });

    test('repeating an add returns the same link', () async {
      final first = await addLink();
      expect(await addLink(), first);
      expect(api.repository.modelLinks.links, hasLength(1));
    });

    test('updates and removes; a stale revision is a 409', () async {
      await addLink();
      final path = '/contests/$_contestId/model-links/$_linkId';

      final stale = await api.send(
        'PUT',
        path,
        body: {'base_revision': 5, 'model_name': 'X'},
      );
      expect(stale.statusCode, 409);
      expect((await api.errorOf(stale))['code'], 'stale_revision');

      final updated = await api.json(
        await api.send(
          'PUT',
          path,
          body: {
            'base_revision': 0,
            'model_name': 'Renamed',
            'contest_specific_identifier': 'S7',
          },
        ),
      );
      expect(updated['model_name'], 'Renamed');
      expect(updated['contest_specific_identifier'], 'S7');
      expect(updated['revision'], 1);

      expect((await api.send('DELETE', path)).statusCode, 204);
      expect(api.repository.modelLinks.links, isEmpty);
    });

    test('editing the profile model leaves the link alone', () async {
      await addModel();
      await addLink({'id': _linkId, 'model_catalog_id': _modelId});

      await api.send(
        'PUT',
        '/participants/$_profileId/models/$_modelId',
        body: {'base_revision': 0, 'name': 'Renamed'},
      );

      expect(api.repository.modelLinks.links.values.first.modelName, 'Supra');
    });

    test('removing the participation removes its links', () async {
      await addLink();

      await api.send(
        'DELETE',
        '/contests/$_contestId/participations/$_participationId',
      );

      expect(api.repository.modelLinks.links, isEmpty);
    });
  });

  test('a non-flier cannot have models', () async {
    await addParticipation(roleId: SystemRoles.helperId.value);

    final response = await api.send(
      'POST',
      linksPath(),
      body: {'id': _linkId, 'model_name': 'Nope'},
    );

    expect(response.statusCode, 400);
    expect(api.repository.modelLinks.links, isEmpty);
  });

  test('a pilot who becomes a non-flier loses the models', () async {
    await addParticipation();
    await addLink();

    final response = await api.send(
      'PUT',
      '/contests/$_contestId/participations/$_participationId',
      body: {'base_revision': 0, 'role_id': SystemRoles.helperId.value},
    );

    expect(response.statusCode, 200);
    expect(api.repository.modelLinks.links, isEmpty);
  });
}
