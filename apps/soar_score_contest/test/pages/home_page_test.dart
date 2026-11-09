import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/services/competition_import/competition_import.dart';
import 'package:soar_score_contest/services/ui_account/ui_account.dart';
import 'package:soar_score_contest/ui_account_provider.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/competition_import_fakes.dart';

Contest _contest(String name, {int day = 17}) => Contest(
  id: Id.parse('019c0000-0000-7000-8000-0000000000$day'),
  name: name,
  startDateTime: DateTime.utc(2026, 10, day, 14),
  endDateTime: DateTime.utc(2026, 10, day + 1, 14),
  timezone: 'America/Denver',
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

Widget _app(ApiClient? client) {
  final page = MaterialApp(
    home: const Scaffold(body: HomePage()),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
  return client == null
      ? page
      : ApiClientInherited(client: client, child: page);
}

/// The page wrapped in a [UiAccountInherited], so the page sees an acting
/// account the way the native build does.
Widget _appWithAccount(ApiClient client, UiAccount account) {
  final page = MaterialApp(
    home: const Scaffold(body: HomePage()),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
  return UiAccountInherited(
    account: account,
    child: ApiClientInherited(client: client, child: page),
  );
}

/// A [UiAccount] whose id can be flipped, standing in for the native build's
/// acting account, which moves from the Local account to the signed-in one
/// when the claim completes.
class _MutableUiAccount extends ChangeNotifier implements UiAccount {
  _MutableUiAccount(this._id);

  String _id;

  @override
  String get id => _id;

  void changeTo(String id) {
    _id = id;
    notifyListeners();
  }
}

ApiClient _client(Future<http.Response> Function(http.Request) respond) =>
    ApiClient(
      baseUrl: Uri.parse('http://localhost'),
      httpClient: MockClient(respond),
    );

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final l10n = AppLocalizationsEn();

void main() {
  testWidgets('lists the contests the API returns', (tester) async {
    final client = _client(
      (_) async => _json({
        'contests': [
          _contest('Front Range ALES Open').toJson(),
          _contest('Second Open', day: 24).toJson(),
        ],
      }),
    );

    await tester.pumpWidget(_app(client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    // The latest start is listed first and shown in the detail pane.
    expect(find.text('Second Open'), findsNWidgets(2));
    expect(find.text('Front Range ALES Open'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Second Open').first).dy,
      lessThan(tester.getTopLeft(find.text('Front Range ALES Open')).dy),
    );
    expect(find.text(l10n.lifecycleCreated), findsNWidgets(4));
    expect(find.text('Oct 24, 2026 to Oct 25, 2026'), findsNWidgets(2));
  });

  testWidgets('selecting a contest shows its detail', (tester) async {
    final client = _client(
      (_) async => _json({
        'contests': [
          _contest('Front Range ALES Open').toJson(),
          _contest('Second Open', day: 24).toJson(),
        ],
      }),
    );

    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Front Range ALES Open'));
    await tester.pumpAndSettle();

    expect(find.text('Front Range ALES Open'), findsNWidgets(2));
    expect(find.text('Oct 17, 2026 to Oct 18, 2026'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('open-contest')), findsOneWidget);
  });

  testWidgets('a narrow window shows the list, then the detail with a back '
      'button', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = _client(
      (_) async => _json({
        'contests': [_contest('Front Range ALES Open').toJson()],
      }),
    );

    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-contest')), findsNothing);

    await tester.tap(find.text('Front Range ALES Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-contest')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('contest-detail-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-contest')), findsNothing);
    expect(find.text('Front Range ALES Open'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no contests', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_client((_) async => _json({'contests': <Object>[]}))),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.contestsEmpty), findsOneWidget);
  });

  testWidgets('shows the error and retries', (tester) async {
    var calls = 0;
    final client = _client((_) async {
      calls++;
      if (calls == 1) {
        return http.Response('boom', 500);
      }
      return _json({
        'contests': [_contest('Recovered Open').toJson()],
      });
    });

    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contestsLoadFailed), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered Open'), findsNWidgets(2));
    expect(find.text(l10n.contestsLoadFailed), findsNothing);
  });

  testWidgets('shows the error when no API client is provided', (tester) async {
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();

    expect(find.text(l10n.contestsLoadFailed), findsOneWidget);
  });

  testWidgets('shows a loading state while the contests load', (tester) async {
    await tester.pumpWidget(
      _app(_client((_) async => _json({'contests': <Object>[]}))),
    );

    expect(find.text(l10n.contestsLoading), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(l10n.contestsLoading), findsNothing);
  });

  testWidgets('a 401 says to sign in again instead of blaming the server', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_client((_) async => http.Response('', 401))));
    await tester.pumpAndSettle();

    expect(find.text(l10n.contestsLoadFailed), findsOneWidget);
    expect(find.textContaining('not signed in'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byKey(const ValueKey('page-state-retry')), findsNothing);
  });

  testWidgets('a 403 explains it and does not offer Retry', (tester) async {
    await tester.pumpWidget(_app(_client((_) async => http.Response('', 403))));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.textContaining('not allowed'), findsOneWidget);
    expect(find.byKey(const ValueKey('page-state-retry')), findsNothing);
  });

  testWidgets('a rejected request shows the server message without Retry', (
    tester,
  ) async {
    final client = _client(
      (_) async => http.Response(
        jsonEncode({
          'error': {'code': 'invalid_request', 'message': 'Bad filter.'},
        }),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    expect(find.text('Bad filter.'), findsOneWidget);
    expect(find.byKey(const ValueKey('page-state-retry')), findsNothing);
  });

  testWidgets('an unreachable server is shown as unavailable with Retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_client((_) async => throw http.ClientException('down'))),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text('The server could not be reached.'), findsOneWidget);
    expect(find.byKey(const ValueKey('page-state-retry')), findsOneWidget);
  });

  testWidgets('the empty state keeps its Create contest action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_client((_) async => _json({'contests': <Object>[]}))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('empty-create-contest')), findsOneWidget);
  });

  group('the imported chip', () {
    late FakeCompetitionImportStore store;
    setUp(() {
      store = FakeCompetitionImportStore(const []);
      CompetitionImportStore.current = store;
    });
    tearDown(() => CompetitionImportStore.current = null);

    ApiClient twoContests() => _client(
      (_) async => _json({
        'contests': [
          _contest('Imported Open').toJson(),
          _contest('Home Made Open', day: 24).toJson(),
        ],
      }),
    );

    testWidgets('shows on an imported contest and not on another', (
      tester,
    ) async {
      store.notes[_contest('Imported Open').id] = ImportedContestNote(
        importedAt: DateTime.utc(2026, 11, 4),
        lanesKept: true,
      );
      await tester.pumpWidget(_app(twoContests()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Imported Open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('imported-label')), findsOneWidget);

      await tester.tap(find.text('Home Made Open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('imported-label')), findsNothing);
    });

    testWidgets('a store that cannot answer leaves the chip out', (
      tester,
    ) async {
      CompetitionImportStore.current = null;
      await tester.pumpWidget(_app(twoContests()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Imported Open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('imported-label')), findsNothing);
    });
  });

  group('when the acting account changes', () {
    testWidgets('a first load that races the sign-in reloads when the '
        'acting account is claimed', (tester) async {
      // First the embedded server acts as the Local account (no contests),
      // then the claim re-points it at the signed-in account (with them).
      var signedIn = false;
      final client = _client(
        (_) async => _json({
          'contests': signedIn
              ? [_contest('Signed In Open').toJson()]
              : <Object>[],
        }),
      );
      final account = _MutableUiAccount('local-account');
      account.addListener(() {
        if (account.id == 'signed-in-account') signedIn = true;
      });

      await tester.pumpWidget(_appWithAccount(client, account));
      await tester.pumpAndSettle();

      // The first load answered while acting as the Local account: empty.
      expect(find.text(l10n.contestsEmpty), findsOneWidget);

      // The claim completes: the embedded server now acts as the signed-in
      // account. The page must reload and show the account's contests.
      account.changeTo('signed-in-account');
      await tester.pumpAndSettle();

      expect(find.text('Signed In Open'), findsNWidgets(2));
      expect(find.text(l10n.contestsEmpty), findsNothing);
    });

    testWidgets('changing to the same account does not reload', (tester) async {
      var calls = 0;
      final client = _client((_) async {
        calls++;
        return _json({
          'contests': [_contest('Same Account Open').toJson()],
        });
      });
      final account = _MutableUiAccount('local-account');

      await tester.pumpWidget(_appWithAccount(client, account));
      await tester.pumpAndSettle();
      expect(calls, 1);

      // A change to the account the list already belongs to must not ask
      // again.
      account.changeTo('local-account');
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Same Account Open'), findsNWidgets(2));
    });
  });
}
