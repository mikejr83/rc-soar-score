import 'dart:convert';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'contest_draft.dart';
import 'draft_validation.dart';
import 'draw_settings.dart';
import '../participants/participant_option.dart';
import '../participants/participant_row.dart';
import 'participant_rules.dart';
import 'time_zones.dart';

/// The ids one creation uses, kept for retries so a repeated attempt
/// returns what an earlier one already stored instead of duplicating it.
class CreationIds {
  CreationIds(this.signature);

  /// What the draft described when these ids were first used, from
  /// [ContestCreator.signature]. A changed draft needs new ids.
  final String signature;

  final Id contest = Id.create();
  final Map<String, Id> _participations = {};
  final Map<String, Id> _teams = {};
  final Map<String, Id> _memberships = {};
  final Map<String, Id> _profileModels = {};

  Id participation(Id profileId) =>
      _participations.putIfAbsent(profileId.value, Id.create);

  Id team(String name) => _teams.putIfAbsent(name.toLowerCase(), Id.create);

  /// The id of the profile model made for the draft model [entryId].
  Id profileModel(Id entryId) =>
      _profileModels.putIfAbsent(entryId.value, Id.create);

  Id membership(Id profileId) =>
      _memberships.putIfAbsent(profileId.value, Id.create);
}

/// Creates the contest a valid draft describes, through the API.
///
/// The contest is created (unpublished and private), then its first
/// configuration is saved, which moves it to `Configuring`. Then the
/// participants are added and the teams are created. No matrix and no
/// score is created. Each request uses ids from [CreationIds], and steps
/// that already happened are skipped, so retrying after a failure is safe.
///
/// A model typed in the wizard is added to the person's profile (so a later
/// contest can pick it) and entered for the pilot. Remote profiles can't be added until remote search exists.
class ContestCreator {
  ContestCreator(this.client);

  final ApiClient client;

  Future<Contest> create(ContestDraft draft, CreationIds ids) async {
    final contest = await client.createContest(_contestRequest(draft, ids));
    await _saveConfiguration(contest, draft);
    final participations = await _addParticipants(contest, draft, ids);
    if (draft.has(ParticipantOption.teams)) {
      await _addTeams(contest, draft, ids, participations);
    }
    if (draft.has(ParticipantOption.models)) {
      await _addModels(contest, draft, ids, participations);
    }
    return client.contest(contest.id);
  }

  /// A fingerprint of everything [create] sends for [draft]. Retries reuse
  /// ids only while the fingerprint is unchanged: the same contest id with
  /// different content is refused by the server, and a configuration saved
  /// by an earlier attempt would silently ignore the new values.
  static String signature(ContestDraft draft) => jsonEncode([
    draft.name.trim(),
    draft.startDate.trim(),
    draft.endDate.trim(),
    TimeZones.effective(draft.timeZone, draft.country),
    draft.venue.trim(),
    draft.city.trim(),
    draft.region.trim(),
    draft.country.trim(),
    draft.discipline?.profileId?.value,
    coreOptionsOf(draft),
    disciplineDefaultsOf(draft),
    [
      for (final p in draft.participants)
        [
          p.profileId.value,
          p.source.name,
          p.roleId.value,
          p.classification,
          p.team,
          [
            for (final m in p.models)
              [
                m.id.value,
                m.catalogId?.value,
                m.name,
                m.manufacturer,
                m.modelId,
                m.contestIdentifier,
              ],
          ],
        ],
    ],
  ]);

  static String? _optional(String text) =>
      text.trim().isEmpty ? null : text.trim();

  /// Dates are stored at noon UTC so the calendar day shows the same in any
  /// time zone within ±12 hours.
  static DateTime _day(String text) {
    final date = DraftValidation.parseDate(text)!;
    return DateTime.utc(date.year, date.month, date.day, 12);
  }

  CreateContestRequest _contestRequest(ContestDraft draft, CreationIds ids) =>
      CreateContestRequest(
        id: ids.contest,
        name: draft.name.trim(),
        startDateTime: _day(draft.startDate),
        endDateTime: _day(draft.endDate),
        timezone: TimeZones.effective(draft.timeZone, draft.country),
        host: _optional(draft.venue),
        city: _optional(draft.city),
        state: _optional(draft.region),
        country: _optional(draft.country),
      );

  Future<void> _saveConfiguration(Contest contest, ContestDraft draft) async {
    try {
      await client.configuration(contest.id);
      return; // Saved by an earlier attempt.
    } on ApiHttpError catch (error) {
      if (error.statusCode != 404) {
        rethrow;
      }
    }
    final discipline = draft.discipline!;
    await client.saveConfiguration(
      contest.id,
      SaveConfigurationRequest(
        baseRevisionNumber: 0,
        disciplineProfileId: discipline.profileId!,
        config: ContestConfig(
          core: coreOptionsOf(draft),
          discipline: disciplineDefaultsOf(draft),
        ),
      ),
    );
  }

  /// The full `core` settings for [draft].
  static Map<String, Object?> coreOptionsOf(ContestDraft draft) {
    final scoring = draft.scoringSettings;
    final draw = draft.drawSettings;
    final teams = draft.has(ParticipantOption.teams);
    return {
      'teams_enabled': teams,
      'team_pilot_count': teams ? int.parse(draft.teamPilotCount.trim()) : null,
      'team_protection': teams && draw.teamProtection,
      'allow_back_to_back': draw.allowBackToBack,
      'roles_enabled': draft.has(ParticipantOption.roles),
      'draw_mode': draw.drawMode.json,
      'preliminary_rounds': draw.seeded
          ? int.parse(draw.seededRounds.trim())
          : null,
      'lane_mode': draw.laneMode.json,
      'group_score_mode': scoring.groupScoreMode.json,
      'rounding_mode': scoring.roundingMode.json,
      'decimal_places': scoring.decimalPlaces,
      'drop_after_rounds': scoring.dropAfterRounds,
      'tiebreaker_enabled': false,
      'classes_enabled': draft.has(ParticipantOption.classes),
      'models_enabled': draft.has(ParticipantOption.models),
      'participant_numbers_enabled': draft.has(ParticipantOption.pilotNumbers),
      'review_requests_enabled': scoring.reviewRequests,
      'public_update_mode': scoring.publicUpdateMode.json,
      'intended_total_rounds': draw.seeded
          ? int.tryParse(draft.roundsText.trim())
          : null,
    }..removeWhere((key, value) => value == null);
  }

  /// The discipline's own settings at their defaults (overrides are made on
  /// the configuration page after creation).
  static Map<String, Object?> disciplineDefaultsOf(ContestDraft draft) {
    final profile = SystemDisciplineProfiles.all.firstWhere(
      (p) => p.profile.id == draft.discipline!.profileId,
    );
    return {
      for (final field in profile.configFields)
        if (field.fieldType != ConfigFieldType.landing &&
            field.defaultValue != null)
          field.fieldKey: field.defaultValue,
    };
  }

  Future<Map<String, Id>> _addParticipants(
    Contest contest,
    ContestDraft draft,
    CreationIds ids,
  ) async {
    final existing = {
      for (final p in await client.participations(contest.id))
        p.participantProfileId.value: p.id,
    };
    final roles = draft.has(ParticipantOption.roles);
    final classes = draft.has(ParticipantOption.classes);
    final added = <String, Id>{...existing};
    for (final participant in draft.participants) {
      if (participant.source == ParticipantSource.remote ||
          existing.containsKey(participant.profileId.value)) {
        continue;
      }
      final pilot = draft.isScoring(participant);
      final participation = await client.addParticipation(
        contest.id,
        AddParticipationRequest(
          id: ids.participation(participant.profileId),
          participantProfileId: participant.profileId,
          roleId: roles ? participant.roleId : null,
          classification: pilot && classes
              ? titleCase(participant.classification)
              : null,
        ),
      );
      added[participant.profileId.value] = participation.id;
    }
    return added;
  }

  Future<void> _addModels(
    Contest contest,
    ContestDraft draft,
    CreationIds ids,
    Map<String, Id> participations,
  ) async {
    final entered = {
      for (final link in await client.modelLinks(contest.id)) link.id.value,
    };
    for (final participant in draft.participants) {
      final participation = participations[participant.profileId.value];
      if (participation == null ||
          participant.source == ParticipantSource.remote ||
          !draft.isScoring(participant) ||
          participant.models.isEmpty) {
        continue;
      }
      List<ModelCatalog>? profileModels;
      for (final model in participant.models) {
        if (entered.contains(model.id.value)) continue;
        var catalogId = model.catalogId;
        if (catalogId == null) {
          profileModels ??= [
            ...await client.profileModels(participant.profileId),
          ];
          final known = profileModels.where(
            (m) => ModelsService.sameProfileModel(
              m,
              name: model.name,
              manufacturer: model.manufacturer,
            ),
          );
          if (known.isNotEmpty) {
            catalogId = known.first.id;
          } else {
            final created = await client.addProfileModel(
              participant.profileId,
              AddProfileModelRequest(
                id: ids.profileModel(model.id),
                name: model.name,
                manufacturer: model.manufacturer,
                modelId: model.modelId,
              ),
            );
            profileModels.add(created);
            catalogId = created.id;
          }
        }
        await client.addModelLink(
          contest.id,
          participation,
          AddModelLinkRequest(
            id: model.id,
            modelCatalogId: catalogId,
            modelName: model.name,
            manufacturer: model.manufacturer,
            modelId: model.modelId,
            contestSpecificIdentifier: model.contestIdentifier,
          ),
        );
      }
    }
  }

  Future<void> _addTeams(
    Contest contest,
    ContestDraft draft,
    CreationIds ids,
    Map<String, Id> participations,
  ) async {
    final teams = {
      for (final team in await client.teams(contest.id))
        team.name.toLowerCase(): team.id,
    };
    for (final summary in draft.teams) {
      final key = summary.name.toLowerCase();
      if (!teams.containsKey(key)) {
        final team = await client.createTeam(
          contest.id,
          CreateTeamRequest(id: ids.team(summary.name), name: summary.name),
        );
        teams[key] = team.id;
      }
    }
    final members = {
      for (final membership in await client.teamMemberships(contest.id))
        membership.contestParticipationId.value,
    };
    for (final participant in draft.participants) {
      final team = participant.team.trim().toLowerCase();
      final participation = participations[participant.profileId.value];
      if (team.isEmpty ||
          participation == null ||
          members.contains(participation.value)) {
        continue;
      }
      await client.addTeamMember(
        contest.id,
        AddTeamMemberRequest(
          id: ids.membership(participant.profileId),
          teamId: teams[team]!,
          contestParticipationId: participation,
        ),
      );
    }
  }
}
