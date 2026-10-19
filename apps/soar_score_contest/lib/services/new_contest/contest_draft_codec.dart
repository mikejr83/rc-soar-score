import 'package:soar_score_core/soar_score_core.dart';

import 'contest_draft.dart';
import 'copy_mode.dart';
import 'copy_source.dart';
import 'draft_participant.dart';
import 'draw_settings.dart';
import 'participant_option.dart';
import 'scoring_settings.dart';
import 'wizard_discipline.dart';

/// Turns a [ContestDraft] into JSON-encodable data and back, for the stored
/// draft.
///
/// [version] is the shape of the data: raise it when a field changes in a way
/// older data cannot be read. [decode] throws [FormatException] for anything
/// it cannot read, so a damaged or outdated draft is never loaded blindly.
///
/// The source contest keeps its contest, discipline and pilots; its options
/// were already applied to the draft when it was chosen, so they are not kept.
class ContestDraftCodec {
  const ContestDraftCodec._();

  static const int version = 1;

  static Map<String, Object?> encode(ContestDraft draft) => {
    'name': draft.name,
    'venue': draft.venue,
    'start_date': draft.startDate,
    'end_date': draft.endDate,
    'city': draft.city,
    'region': draft.region,
    'country': draft.country,
    'time_zone': draft.timeZone,
    'copy_mode': draft.copyMode.name,
    'source': draft.source == null ? null : _encodeSource(draft.source!),
    'selected_pilots': draft.selectedPilots.toList()..sort(),
    'discipline': _disciplineName(draft.discipline),
    'options': _names(draft.options),
    'options_from_source': _names(draft.optionsFromSource),
    'team_pilot_count': draft.teamPilotCount,
    'participants': [for (final p in draft.participants) _encodeParticipant(p)],
    'scoring': draft.scoring == null ? null : _encodeScoring(draft.scoring!),
    'draw': _encodeDraw(draft.draw),
    'visited_through': draft.visitedThrough,
  };

  static ContestDraft decode(Object? data) {
    try {
      final map = _map(data);
      final source = map['source'];
      final scoring = map['scoring'];
      final discipline = map['discipline'];
      return ContestDraft(
        name: map['name']! as String,
        venue: map['venue']! as String,
        startDate: map['start_date']! as String,
        endDate: map['end_date']! as String,
        city: map['city']! as String,
        region: map['region']! as String,
        country: map['country']! as String,
        timeZone: map['time_zone'] as String?,
        copyMode: CopyMode.values.byName(map['copy_mode']! as String),
        source: source == null ? null : _decodeSource(_map(source)),
        selectedPilots: {
          for (final id in map['selected_pilots']! as List) id as String,
        },
        discipline: discipline == null
            ? null
            : WizardDiscipline.values.byName(discipline as String),
        options: _options(map['options']),
        optionsFromSource: _options(map['options_from_source']),
        teamPilotCount: map['team_pilot_count']! as String,
        participants: [
          for (final p in map['participants']! as List)
            _decodeParticipant(_map(p)),
        ],
        scoring: scoring == null ? null : _decodeScoring(_map(scoring)),
        draw: _decodeDraw(_map(map['draw'])),
        visitedThrough: map['visited_through']! as int,
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Unreadable draft: $error');
    }
  }

  /// The enum's identifier; [WizardDiscipline.name] is its display name.
  static String? _disciplineName(WizardDiscipline? discipline) =>
      (discipline as Enum?)?.name;

  static Map<String, Object?> _map(Object? data) =>
      Map<String, Object?>.from(data! as Map);

  static List<String> _names(Set<ParticipantOption> options) =>
      [for (final o in options) o.name]..sort();

  static Set<ParticipantOption> _options(Object? data) => {
    for (final name in data! as List)
      ParticipantOption.values.byName(name as String),
  };

  static Map<String, Object?> _encodeSource(CopySource source) => {
    'contest': source.contest.toJson(),
    'discipline': _disciplineName(source.discipline),
    'pilots': [
      for (final p in source.pilots)
        {
          'profile_id': p.profileId.value,
          'name': p.name,
          'email': p.email,
          'classification': p.classification,
        },
    ],
  };

  static CopySource _decodeSource(Map<String, Object?> map) {
    final discipline = map['discipline'];
    return CopySource(
      contest: Contest.fromJson(_map(map['contest'])),
      discipline: discipline == null
          ? null
          : WizardDiscipline.values.byName(discipline as String),
      pilots: [
        for (final p in map['pilots']! as List)
          SourcePilot(
            profileId: Id.parse(_map(p)['profile_id']! as String),
            name: _map(p)['name']! as String,
            email: _map(p)['email'] as String?,
            classification: _map(p)['classification'] as String?,
          ),
      ],
    );
  }

  static Map<String, Object?> _encodeParticipant(DraftParticipant p) => {
    'profile_id': p.profileId.value,
    'name': p.name,
    'email': p.email,
    'email_visible': p.emailVisible,
    'source': p.source.name,
    'role_id': p.roleId.value,
    'role_name': p.roleName,
    'is_pilot': p.isPilot,
    'classification': p.classification,
    'team': p.team,
    'model': p.model,
    'model_id': p.modelId,
  };

  static DraftParticipant _decodeParticipant(Map<String, Object?> map) =>
      DraftParticipant(
        profileId: Id.parse(map['profile_id']! as String),
        name: map['name']! as String,
        email: map['email'] as String?,
        emailVisible: map['email_visible']! as bool,
        source: ParticipantSource.values.byName(map['source']! as String),
        roleId: Id.parse(map['role_id']! as String),
        roleName: map['role_name']! as String,
        isPilot: map['is_pilot']! as bool,
        classification: map['classification']! as String,
        team: map['team']! as String,
        model: map['model']! as String,
        modelId: map['model_id']! as String,
      );

  static Map<String, Object?> _encodeScoring(ScoringSettings s) => {
    'group_score_mode': s.groupScoreMode.name,
    'rounding_mode': s.roundingMode.name,
    'decimal_places': s.decimalPlaces,
    'drop_policy': s.dropPolicy.name,
    'first_drop': s.firstDrop,
    'second_drop': s.secondDrop,
    'review_requests': s.reviewRequests,
    'public_update_mode': s.publicUpdateMode.name,
  };

  static ScoringSettings _decodeScoring(Map<String, Object?> map) =>
      ScoringSettings(
        groupScoreMode: GroupScoreMode.values.byName(
          map['group_score_mode']! as String,
        ),
        roundingMode: RoundingMode.values.byName(
          map['rounding_mode']! as String,
        ),
        decimalPlaces: map['decimal_places']! as int,
        dropPolicy: DropPolicy.values.byName(map['drop_policy']! as String),
        firstDrop: map['first_drop']! as String,
        secondDrop: map['second_drop']! as String,
        reviewRequests: map['review_requests']! as bool,
        publicUpdateMode: PublicUpdateMode.values.byName(
          map['public_update_mode']! as String,
        ),
      );

  static Map<String, Object?> _encodeDraw(DrawSettings d) => {
    'draw_mode': d.drawMode.name,
    'groups': d.groups,
    'rounds': d.rounds,
    'lane_mode': d.laneMode.name,
    'team_protection': d.teamProtection,
    'allow_back_to_back': d.allowBackToBack,
    'seeded_rounds': d.seededRounds,
  };

  static DrawSettings _decodeDraw(Map<String, Object?> map) => DrawSettings(
    drawMode: DrawMode.values.byName(map['draw_mode']! as String),
    groups: map['groups'] as String?,
    rounds: map['rounds'] as String?,
    laneMode: LaneMode.values.byName(map['lane_mode']! as String),
    teamProtection: map['team_protection']! as bool,
    allowBackToBack: map['allow_back_to_back']! as bool,
    seededRounds: map['seeded_rounds']! as String,
  );
}
