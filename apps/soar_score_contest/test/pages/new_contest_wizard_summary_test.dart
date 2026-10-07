import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/new_contest_test_support.dart';
import '../support/participant_test_support.dart';
import '../support/participants_step_support.dart';

/// A fake API for creating a contest without teams. [failCreates] makes
/// that many contest creations fail first.
class _FakeApi {
  _FakeApi({this.failCreates = 0, this.delay = Duration.zero});

  int failCreates;

  /// How long creating the contest takes.
  final Duration delay;
  int contestPosts = 0;
  Contest? contest;
  bool configured = false;
  final List<Map<String, dynamic>> participations = [];

  Future<http.Response> call(http.Request request) async {
    final path = request.url.path;
    final post = request.method == 'POST';
    if (post && path == '/api/v1/contests') {
      contestPosts++;
      await Future<void>.delayed(delay);
      if (failCreates > 0) {
        failCreates--;
        return errorResponse(503, 'unavailable', 'The server is busy.');
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      contest = Contest(
        id: Id.parse(body['id'] as String),
        name: body['name'] as String,
        startDateTime: DateTime.parse(body['start_date_time'] as String),
        endDateTime: DateTime.parse(body['end_date_time'] as String),
        timezone: body['timezone'] as String,
        createdAt: DateTime.utc(2026, 10),
        updatedAt: DateTime.utc(2026, 10),
      );
      return json(contest!.toJson());
    }
    if (path.endsWith('/configuration')) {
      if (!post) {
        return configured
            ? json(sourceConfiguration(contest!).toJson())
            : errorResponse(404, 'not_found', 'No configuration.');
      }
      configured = true;
      contest = contest!.copyWithState(
        lifecycleState: LifecycleState.configuring,
        updatedAt: DateTime.utc(2026, 10, 2),
      );
      return json({
        'configuration': sourceConfiguration(contest!).toJson(),
        'contest': contest!.toJson(),
      });
    }
    if (path.endsWith('/participations')) {
      if (post) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final participation = ContestParticipation(
          id: Id.parse(body['id'] as String),
          contestId: contest!.id,
          participantProfileId: Id.parse(
            body['participant_profile_id'] as String,
          ),
          roleId: SystemRoles.pilotId,
          roleName: 'Pilot',
          scoringUuid: ScoringUuid.create(),
        ).toJson();
        participations.add(participation);
        return json(participation);
      }
      return json({'participations': participations});
    }
    if (contest != null && path == '/api/v1/contests/${contest!.id.value}') {
      return json(contest!.toJson());
    }
    return stepApi(request);
  }
}

Future<ContestDraftStore> _ready() => storeAtStep4(
  options: const {},
  participants: [row(0), row(1)],
  visitedThrough: 7,
);

void main() {
  testWidgets('the summary lists each section and Edit returns to its step', (
    tester,
  ) async {
    final store = await _ready();
    await pumpWizard(tester, respond: _FakeApi().call, store: store);

    expect(stepTitle(tester), 'Summary & create');
    for (final title in [
      'Details',
      'Copy source',
      'Discipline',
      'Participants',
      'Enabled options',
      'Teams and classes',
      'Scoring and publication',
      'Draw options',
      'Rounds and groups',
    ]) {
      expect(find.byKey(ValueKey('summary-$title')), findsOneWidget);
    }
    expect(find.text('Gator Cup'), findsOneWidget);
    expect(find.text('Unpublished and private'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('edit-Discipline')));
    await tester.tap(find.byKey(const ValueKey('edit-Discipline')));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'Discipline');
  });

  testWidgets('the cards in a row of the summary share one height', (
    tester,
  ) async {
    final store = await _ready();
    await pumpWizard(tester, respond: _FakeApi().call, store: store);

    Rect rect(String title) =>
        tester.getRect(find.byKey(ValueKey('summary-$title')));
    final details = rect('Details');
    final copy = rect('Copy source');
    expect(details.top, copy.top);
    expect(details.height, copy.height);
  });

  testWidgets('the summary words roles-off participants, lanes and what '
      'happens after creating', (tester) async {
    final store = await _ready();
    await pumpWizard(tester, respond: _FakeApi().call, store: store);

    // Roles are off: one pilot count instead of people / non-flying.
    expect(find.text('Pilots'), findsOneWidget);
    expect(find.text('Non-flying'), findsNothing);
    expect(find.text('No lane assignment'), findsOneWidget);
    expect(find.text('The contest configuration page is opened.'), findsOne);
    expect(
      find.text(
        'A flight matrix hasn’t been drawn. The draw can be created from '
        'the next screen.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Configuration in process is kept until the app is closed or the '
        'contest is created.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Create is disabled with its reason while a step is invalid', (
    tester,
  ) async {
    final store = await storeAtStep4(
      options: const {},
      participants: [row(0)],
      visitedThrough: 7,
    );
    final api = _FakeApi();
    await pumpWizard(tester, respond: api.call, store: store);

    expect(
      find.text('Can’t create yet: add at least 2 scoring pilots.'),
      findsOneWidget,
    );
    expect(find.text('Needs at least 2 scoring pilots'), findsOneWidget);
    await next(tester);
    expect(api.contestPosts, 0);

    await tester.tap(find.text('Go to Participants'));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'Participants');
  });

  testWidgets('a failed creation keeps the values and Retry creates the '
      'contest once', (tester) async {
    final store = await _ready();
    final api = _FakeApi(failCreates: 1);
    await pumpWizard(tester, respond: api.call, store: store);

    await next(tester);
    expect(find.byKey(const ValueKey('banner-create-failed')), findsOneWidget);
    expect(find.text('The contest wasn’t created'), findsOneWidget);
    expect(store.draft.name, 'Gator Cup');

    await tester.tap(find.byKey(const ValueKey('create-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('contest-created')), findsOneWidget);
    expect(find.text('Contest created'), findsOneWidget);
    expect(find.text('Configuring'), findsOneWidget);
    expect(api.contestPosts, 2);
    expect(api.participations, hasLength(2));
    // The draft is gone; the draw values wait for the draw.
    expect(store.draft.name, isEmpty);
    expect(store.drawSuggestions, hasLength(1));
    expect(find.byKey(const ValueKey('draft-status')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('back-to-contests')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('pressing Create twice submits once', (tester) async {
    final store = await _ready();
    final api = _FakeApi(delay: const Duration(seconds: 1));
    await pumpWizard(tester, respond: api.call, store: store);

    await tester.tap(find.byKey(const ValueKey('wizard-primary')));
    await tester.tap(find.byKey(const ValueKey('wizard-primary')));
    await tester.pump();
    expect(find.text('Creating contest…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(api.contestPosts, 1);
    expect(find.byKey(const ValueKey('contest-created')), findsOneWidget);
  });
}
