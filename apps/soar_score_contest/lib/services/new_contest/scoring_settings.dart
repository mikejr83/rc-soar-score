import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import 'wizard_discipline.dart';

/// How many rounds are dropped from each pilot's total.
enum DropPolicy {
  disabled,
  one,
  two;

  /// The user-visible label for this policy.
  String label(AppLocalizations l10n) => switch (this) {
    disabled => l10n.wizardDropDisabled,
    one => l10n.wizardDropOne,
    two => l10n.wizardDropTwo,
  };
}

/// The scoring and publication values of step 5.
///
/// The drop rounds are kept as typed so an invalid entry stays on screen.
class ScoringSettings {
  const ScoringSettings({
    required this.groupScoreMode,
    required this.roundingMode,
    required this.decimalPlaces,
    required this.dropPolicy,
    required this.firstDrop,
    required this.secondDrop,
    required this.reviewRequests,
    required this.publicUpdateMode,
    required this.scoresBecomeOfficial,
  });

  /// The defaults for [discipline]: the platform defaults, then the
  /// profile's `default_options`, then the dropped-round defaults agreed for
  /// the wizard (F3J and F5J drop one round after round 6).
  factory ScoringSettings.defaultsFor(WizardDiscipline? discipline) {
    final platform = CoreOptions();
    final profile = switch (discipline) {
      WizardDiscipline.ales => SystemDisciplineProfiles.ales,
      WizardDiscipline.f3j => SystemDisciplineProfiles.f3j,
      WizardDiscipline.f5j => SystemDisciplineProfiles.f5j,
      WizardDiscipline.thermalDuration => SystemDisciplineProfiles.thermal,
      _ => null,
    };
    final resolved = CoreOptions.fromMap({...?profile?.profile.defaultOptions});
    final dropsOne =
        discipline == WizardDiscipline.f3j ||
        discipline == WizardDiscipline.f5j;
    return ScoringSettings(
      groupScoreMode: resolved.groupScoreMode,
      roundingMode: resolved.roundingMode,
      decimalPlaces: resolved.decimalPlaces,
      dropPolicy: dropsOne ? DropPolicy.one : DropPolicy.disabled,
      firstDrop: '6',
      secondDrop: '12',
      reviewRequests: platform.reviewRequestsEnabled,
      publicUpdateMode: platform.publicUpdateMode,
      // A new contest accepts submitted scores at the end of each round; a
      // stored contest without the setting reads Manually instead.
      scoresBecomeOfficial: CoreOptions.freshContestScoresBecomeOfficial,
    );
  }

  /// The values of a copied configuration.
  factory ScoringSettings.fromOptions(CoreOptions options) {
    final drops = options.dropAfterRounds;
    return ScoringSettings(
      groupScoreMode: options.groupScoreMode,
      roundingMode: options.roundingMode,
      decimalPlaces: options.decimalPlaces,
      dropPolicy: switch (drops.length) {
        0 => DropPolicy.disabled,
        1 => DropPolicy.one,
        _ => DropPolicy.two,
      },
      firstDrop: drops.isNotEmpty ? '${drops[0]}' : '6',
      secondDrop: drops.length > 1 ? '${drops[1]}' : '12',
      reviewRequests: options.reviewRequestsEnabled,
      publicUpdateMode: options.publicUpdateMode,
      scoresBecomeOfficial: options.scoresBecomeOfficial,
    );
  }

  final GroupScoreMode groupScoreMode;
  final RoundingMode roundingMode;

  /// 0 to 3.
  final int decimalPlaces;

  final DropPolicy dropPolicy;
  final String firstDrop;
  final String secondDrop;
  final bool reviewRequests;
  final PublicUpdateMode publicUpdateMode;

  /// When submitted scores become official on their own.
  final OfficializationMode scoresBecomeOfficial;

  /// The rounds after which a round is dropped, when valid.
  List<int>? get dropAfterRounds {
    final first = int.tryParse(firstDrop.trim());
    final second = int.tryParse(secondDrop.trim());
    return switch (dropPolicy) {
      DropPolicy.disabled => const [],
      DropPolicy.one => first != null && first > 0 ? [first] : null,
      DropPolicy.two =>
        first != null && first > 0 && second != null && second > first
            ? [first, second]
            : null,
    };
  }

  ScoringSettings copyWith({
    GroupScoreMode? groupScoreMode,
    RoundingMode? roundingMode,
    int? decimalPlaces,
    DropPolicy? dropPolicy,
    String? firstDrop,
    String? secondDrop,
    bool? reviewRequests,
    PublicUpdateMode? publicUpdateMode,
    OfficializationMode? scoresBecomeOfficial,
  }) => ScoringSettings(
    groupScoreMode: groupScoreMode ?? this.groupScoreMode,
    roundingMode: roundingMode ?? this.roundingMode,
    decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    dropPolicy: dropPolicy ?? this.dropPolicy,
    firstDrop: firstDrop ?? this.firstDrop,
    secondDrop: secondDrop ?? this.secondDrop,
    reviewRequests: reviewRequests ?? this.reviewRequests,
    publicUpdateMode: publicUpdateMode ?? this.publicUpdateMode,
    scoresBecomeOfficial: scoresBecomeOfficial ?? this.scoresBecomeOfficial,
  );
}
