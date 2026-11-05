import 'dart:convert';
import 'dart:io';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:test/test.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('fixtures/self_scoring/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// Decodes a fixture, re-encodes it and expects the same JSON back.
void _roundTrips<T>(String name, T Function(Map<String, dynamic>) decode) {
  test('$name fixture decodes and round-trips', () {
    final json = _fixture(name);
    final dto = decode(json);
    expect(jsonDecode(jsonEncode(dto)), json);
  });
}

void main() {
  _roundTrips('resolve_invitation_request', ResolveInvitationRequest.fromJson);
  _roundTrips(
    'resolve_invitation_response',
    ResolveInvitationResponse.fromJson,
  );
  _roundTrips('participant_overview', ParticipantOverviewDto.fromJson);
  _roundTrips('entry_context', ParticipantEntryContextDto.fromJson);
  _roundTrips('submit_request', SubmitParticipantScoreRequest.fromJson);
  _roundTrips('submit_response', SubmitParticipantScoreResponse.fromJson);
  _roundTrips('error_score_already_submitted', ParticipantErrorDto.fromJson);
  _roundTrips('error_validation_failed', ParticipantErrorDto.fromJson);
  _roundTrips('error_invalid_invitation', ParticipantErrorDto.fromJson);
  _roundTrips('group_results', ParticipantGroupResultsDto.fromJson);
  _roundTrips('overall_results', ParticipantOverallResultsDto.fromJson);

  test('overview marks exactly one round as next to score', () {
    final overview = ParticipantOverviewDto.fromJson(
      _fixture('participant_overview'),
    );
    expect(overview.rounds.where((r) => r.isNextToScore).single.round, 2);
    expect(overview.rounds.first.state, ParticipantScoreState.submitted);
    expect(overview.rounds[1].state, ParticipantScoreState.notEntered);
  });

  test('score_already_submitted carries the accepted score', () {
    final error = ParticipantErrorDto.fromJson(
      _fixture('error_score_already_submitted'),
    );
    expect(error.code, ParticipantErrorCodes.scoreAlreadySubmitted);
    expect(error.acceptedScore?.revision, 1);
  });

  test('an invalid invitation reveals nothing about the contest', () {
    final text = File('fixtures/self_scoring/error_invalid_invitation.json')
        .readAsStringSync();
    expect(text, isNot(contains('Summer Heater')));
    expect(
      ParticipantErrorDto.fromJson(jsonDecode(text) as Map<String, dynamic>)
          .code,
      ParticipantErrorCodes.invalidInvitation,
    );
  });

  test('the entry context never offers a cumulative penalty', () {
    final context = ParticipantEntryContextDto.fromJson(
      _fixture('entry_context'),
    );
    expect(
      context.fields.map((f) => f.key),
      isNot(contains('cumulative_penalty')),
    );
  });

  test('a missing credential fails to decode', () {
    expect(() => ResolveInvitationRequest.fromJson({}), throwsA(anything));
  });
}
