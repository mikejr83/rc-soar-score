import 'copy_mode.dart';
import 'copy_source.dart';
import 'draft_participant.dart';
import 'participant_option.dart';
import 'wizard_discipline.dart';

/// The values entered in the New Contest wizard so far.
///
/// A draft is not a contest: it is not listed with contests and does not
/// affect scoring or publication. Text fields keep what was typed, valid or
/// not, so nothing the user entered is lost.
class ContestDraft {
  const ContestDraft({
    this.name = '',
    this.venue = '',
    this.startDate = '',
    this.endDate = '',
    this.city = '',
    this.region = '',
    this.country = '',
    this.timeZone,
    this.copyMode = CopyMode.none,
    this.source,
    this.selectedPilots = const {},
    this.discipline,
    this.options = const {},
    this.optionsFromSource = const {},
    this.teamPilotCount = '',
    this.participants = const [],
    this.visitedThrough = 1,
  });

  final String name;
  final String venue;

  /// The start date as typed (`MMM d, yyyy`).
  final String startDate;

  /// The end date as typed (`MMM d, yyyy`).
  final String endDate;

  final String city;
  final String region;
  final String country;

  /// The chosen time zone; `null` means this device's.
  final String? timeZone;

  final CopyMode copyMode;
  final CopySource? source;

  /// The source pilots chosen for [CopyMode.selectedPilots], by profile id.
  final Set<String> selectedPilots;

  final WizardDiscipline? discipline;
  final Set<ParticipantOption> options;

  /// The options that were turned on by the copy source.
  final Set<ParticipantOption> optionsFromSource;

  /// The pilots counted for the team score, as typed.
  final String teamPilotCount;

  final List<DraftParticipant> participants;

  /// The furthest step the user has reached (1-based).
  final int visitedThrough;

  bool has(ParticipantOption option) => options.contains(option);

  static const Object _keep = Object();

  ContestDraft copyWith({
    String? name,
    String? venue,
    String? startDate,
    String? endDate,
    String? city,
    String? region,
    String? country,
    Object? timeZone = _keep,
    CopyMode? copyMode,
    Object? source = _keep,
    Set<String>? selectedPilots,
    Object? discipline = _keep,
    Set<ParticipantOption>? options,
    Set<ParticipantOption>? optionsFromSource,
    String? teamPilotCount,
    List<DraftParticipant>? participants,
    int? visitedThrough,
  }) => ContestDraft(
    name: name ?? this.name,
    venue: venue ?? this.venue,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    city: city ?? this.city,
    region: region ?? this.region,
    country: country ?? this.country,
    timeZone: identical(timeZone, _keep) ? this.timeZone : timeZone as String?,
    copyMode: copyMode ?? this.copyMode,
    source: identical(source, _keep) ? this.source : source as CopySource?,
    selectedPilots: selectedPilots ?? this.selectedPilots,
    discipline: identical(discipline, _keep)
        ? this.discipline
        : discipline as WizardDiscipline?,
    options: options ?? this.options,
    optionsFromSource: optionsFromSource ?? this.optionsFromSource,
    teamPilotCount: teamPilotCount ?? this.teamPilotCount,
    participants: participants ?? this.participants,
    visitedThrough: visitedThrough ?? this.visitedThrough,
  );
}
