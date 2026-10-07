import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';
import 'package:soar_score_contest/services/new_contest/draft_participant.dart';
import 'package:soar_score_contest/services/new_contest/participant_option.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_test_support.dart';

/// The director's profiles the search finds.
final List<ParticipantProfile> stepProfiles = [
  profile('Mike', 'Gardner', n: 31, club: 'Flying Gators'),
  profile('Gary', 'Novak', n: 32, club: 'Flying Gators'),
  profile('Sarah', 'Albright', n: 33, club: 'Tidewater Thermals'),
];

/// Answers profiles, roles and participant creation (the new profile is
/// Jordan Lee).
Future<http.Response> stepApi(http.Request request) async {
  final path = request.url.path;
  if (path.endsWith('/roles')) {
    return json({
      'roles': [SystemRoles.pilot.toJson(), SystemRoles.helper.toJson()],
    });
  }
  if (path.endsWith('/participants') && request.method == 'POST') {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    return json(
      profile(
        body['first_name'] as String,
        body['last_name'] as String,
        n: 39,
      ).toJson(),
    );
  }
  if (path.endsWith('/participants')) {
    return json({
      'participants': [for (final p in stepProfiles) p.toJson()],
    });
  }
  return json({'contests': []});
}

/// A participant row for profile [n] of [stepProfiles].
DraftParticipant row(
  int index, {
  String classification = '',
  String team = '',
}) =>
    DraftParticipant.fromProfile(stepProfiles[index])
        .copyWith(classification: classification, team: team);

/// A draft that has reached step 4 with [options] on.
Future<ContestDraftStore> storeAtStep4({
  Set<ParticipantOption> options = const {
    ParticipantOption.classes,
    ParticipantOption.teams,
    ParticipantOption.roles,
  },
  List<DraftParticipant> participants = const [],
  WizardDiscipline discipline = WizardDiscipline.f5j,
  int visitedThrough = 4,
}) async {
  final store = ContestDraftStore();
  await store.update(
    ContestDraft(
      name: 'Gator Cup',
      venue: 'Hague Field',
      startDate: 'Nov 14, 2026',
      endDate: 'Nov 15, 2026',
      discipline: discipline,
      options: options,
      teamPilotCount: options.contains(ParticipantOption.teams) ? '2' : '',
      participants: participants,
      visitedThrough: visitedThrough,
    ),
  );
  return store;
}

/// Types [text] into the search box and picks [name] from the results.
Future<void> searchAndPick(
  WidgetTester tester,
  String text,
  String name,
) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey('participant-search')),
      matching: find.byType(TextField),
    ),
    text,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, name));
  await tester.pumpAndSettle();
}
