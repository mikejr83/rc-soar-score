import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/participants/directory_pilot_source.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _entryA = Id.parse('019c0000-0000-7000-8000-0000000000a1');
final _entryB = Id.parse('019c0000-0000-7000-8000-0000000000b1');

Map<String, Object?> _match(Id id, String first, {String? email}) => {
  'entry_id': id.value,
  'first_name': first,
  'last_name': 'Pilot',
  'club': 'Soar Club',
  'fai_number': 'F1',
  'national_org_id': null,
  'city': null,
  'state': null,
  'country': null,
  'email': email,
  'email_available': true,
};

/// A director's search of the pilot directory and the copy into their list
/// (#653), against a canned server.
void main() {
  late List<http.Request> hostedRequests;
  late List<http.Request> localRequests;
  late Map<String, List<Map<String, Object?>>> byKey;

  DirectoryPilotSource source() => DirectoryPilotSource(
    pause: const Duration(milliseconds: 5),
    hosted: ApiClient(
      baseUrl: Uri.parse('http://hosted.invalid'),
      tokenProvider: () async => 'token',
      httpClient: MockClient((request) async {
        hostedRequests.add(request);
        final path = request.url.path;
        if (path.endsWith('/directory/lookups')) {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          return http.Response(
            jsonEncode({'results': byKey[body['key']] ?? const []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        final body = jsonDecode(request.body) as Map<String, Object?>;
        final entry = body['entry_id'] == _entryA.value
            ? _match(_entryA, 'Pat', email: 'pat@example.com')
            : _match(_entryB, 'Bea');
        return http.Response(
          jsonEncode(entry),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    ),
    local: ApiClient(
      baseUrl: Uri.parse('http://local.invalid'),
      httpClient: MockClient((request) async {
        localRequests.add(request);
        final body = jsonDecode(request.body) as Map<String, Object?>;
        return http.Response(
          jsonEncode({
            ...body,
            'owner_account_id': Id.create().value,
            'created_at': '2026-11-26T12:00:00Z',
            'updated_at': '2026-11-26T12:00:00Z',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    ),
  );

  setUp(() {
    hostedRequests = [];
    localRequests = [];
    byKey = {};
  });

  test('text that cannot be a key makes no request', () async {
    final s = source();

    for (final text in ['', 'ab', 'pat@', 'two words 123', 'a@b', 'Zephyr']) {
      expect(await s.search(text), isEmpty, reason: text);
    }

    expect(hostedRequests, isEmpty);
  });

  test('an email is looked up as an email only', () async {
    byKey['email'] = [_match(_entryA, 'Pat')];
    final s = source();

    final found = await s.search(' pat@example.com ');

    expect(found.map((c) => c.name), ['Pat Pilot']);
    expect(hostedRequests, hasLength(1));
    final sent = jsonDecode(hostedRequests.single.body) as Map<String, Object?>;
    expect(sent, {'key': 'email', 'value': 'pat@example.com'});
  });

  test(
    'an id is tried as FAI number and national ID, once per pilot',
    () async {
      byKey['fai_number'] = [_match(_entryA, 'Pat')];
      byKey['national_org_id'] = [
        _match(_entryA, 'Pat'),
        _match(_entryB, 'Bea'),
      ];
      final s = source();

      final found = await s.search('F1234');

      expect(found.map((c) => c.name), ['Pat Pilot', 'Bea Pilot']);
      expect(hostedRequests, hasLength(2));
    },
  );

  test('a newer query during the pause drops the older one', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    final s = source();

    final first = s.search('F123');
    final second = s.search('F1234');

    expect(await first, isEmpty);
    expect(await second, isNotEmpty);
    expect(hostedRequests, hasLength(2)); // two keys, one query
  });

  test('an answered query is not asked again', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    final s = source();

    await s.search('F1234');
    await s.search('f1234');

    expect(hostedRequests, hasLength(2));
  });

  test('the same pilot always gets the same profile id', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    final s = source();

    final a = (await s.search('F1234')).single;
    final b = (await s.search('F5678')).single;

    expect(b.profileId, a.profileId);
  });

  test(
    'copy links first, then creates the profile with what was shared',
    () async {
      byKey['fai_number'] = [_match(_entryA, 'Pat')];
      final s = source();
      final candidate = (await s.search('F1234')).single;
      hostedRequests.clear();

      final profile = await s.copy(candidate);

      expect(hostedRequests.single.url.path, endsWith('/directory/copies'));
      final link =
          jsonDecode(hostedRequests.single.body) as Map<String, Object?>;
      expect(link, {
        'entry_id': _entryA.value,
        'profile_id': candidate.profileId.value,
      });
      expect(profile.id, candidate.profileId);
      final created =
          jsonDecode(localRequests.single.body) as Map<String, Object?>;
      expect(created['id'], candidate.profileId.value);
      expect(created['first_name'], 'Pat');
      expect(created['email'], 'pat@example.com');
    },
  );

  test('a pilot who keeps their email private is copied without one', () async {
    byKey['fai_number'] = [_match(_entryB, 'Bea')];
    final s = source();
    final candidate = (await s.search('F1234')).single;

    await s.copy(candidate);

    final created =
        jsonDecode(localRequests.single.body) as Map<String, Object?>;
    expect(created['email'], isNull);
    expect(candidate.emailVisible, isFalse);
  });

  test('a profile that already holds the pilot is not offered again', () async {
    byKey['fai_number'] = [_match(_entryB, 'Bea')];
    final s = source();
    final candidate = (await s.search('F1234')).single;
    final own = ParticipantProfile(
      id: Id.create(),
      ownerAccountId: Id.create(),
      firstName: 'Bea',
      lastName: 'Pilot',
      faiNumber: ' f1 ',
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );

    expect(candidate.isCopiedIn([own]), isTrue);
    expect(candidate.isCopiedIn(const []), isFalse);
  });
}
