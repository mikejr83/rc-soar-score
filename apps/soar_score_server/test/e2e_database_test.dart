import 'dart:convert';

import 'package:drift/native.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../tool/e2e_database.dart';

void main() {
  test(
    'native demo database can read and publish when publishing is on',
    () async {
      final database = E2eDatabase(
        NativeDatabase.memory(),
        profile: DatabaseProfile.native,
        publishingEnabled: true,
      );
      addTearDown(database.close);
      final director = await seedE2eDatabase(database, serverProfile: false);
      final repository = Repository(database);
      final contests = await repository.contestRepository.getAll();
      final contest = contests.firstWhere(
        (contest) => contest.lifecycleState == core.LifecycleState.completed,
      );
      final handler = buildApiHandler(
        name: 'e2e-test',
        displayName: 'E2E test',
        version: '0.0.0',
        repository: repository,
        publishingEnabled: true,
        authMiddleware: fixedPrincipal(Principal(accountId: director)),
      );
      final path = '/api/v1/contests/${contest.id.value}/publication';
      final before = await handler(
        Request('GET', Uri.parse('http://test$path')),
      );
      expect(before.statusCode, 404, reason: await before.readAsString());

      final published = await handler(
        Request(
          'POST',
          Uri.parse('http://test$path'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'client_mutation_id': 'e2e-publish-1',
            'source_contest_revision': contest.revision,
          }),
        ),
      );
      final body = await published.readAsString();
      expect(published.statusCode, 201, reason: body);
      final publication = jsonDecode(body) as Map<String, dynamic>;
      expect(publication['visibility'], 'Unlisted');
      final publicCopy = await handler(
        Request(
          'GET',
          Uri.parse(
            'http://test/public/publications/${publication['publication_id']}',
          ),
        ),
      );
      final copyBody = await publicCopy.readAsString();
      expect(publicCopy.statusCode, 200, reason: copyBody);
      final copy = jsonDecode(copyBody) as Map<String, dynamic>;
      expect(copy['projection_revision'], 1);
      expect(copy['participants'], isNotEmpty);
      expect(copy['scores'], isNotEmpty);
    },
  );

  for (final profile in DatabaseProfile.values) {
    test(
      '${profile.name} without publishing keeps its original schema',
      () async {
        final database = E2eDatabase(
          NativeDatabase.memory(),
          profile: profile,
          publishingEnabled: false,
        );
        addTearDown(database.close);
        final rows = await database
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get();
        final names = rows.map((row) => row.read<String>('name'));
        expect(names, contains('contests'));
        expect(
          names.contains('publication_identities'),
          profile == DatabaseProfile.server,
        );
        expect(
          names.contains('local_account'),
          profile == DatabaseProfile.native,
        );
      },
    );
  }
}
