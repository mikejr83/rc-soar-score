import '../../enums/discipline_type.dart';
import '../../errors/unknown_scoring_profile_error.dart';
import 'scoring_profile.dart';

/// Resolves scoring profiles by discipline and rules version.
///
/// A profile is selected only from a contest's stored discipline and rules
/// version, never from labels or fields in a score submission.
class ScoringProfileRegistry {
  ScoringProfileRegistry([Iterable<ScoringProfile> profiles = const []]) {
    profiles.forEach(register);
  }

  final Map<(DisciplineType, int), ScoringProfile> _profiles = {};

  /// Registers [profile]; a discipline and version can be registered once.
  void register(ScoringProfile profile) {
    final key = (profile.discipline, profile.rulesVersion);
    if (_profiles.containsKey(key)) {
      throw StateError(
        'A profile for ${profile.discipline.name} rules version '
        '${profile.rulesVersion} is already registered.',
      );
    }
    _profiles[key] = profile;
  }

  /// Throws [UnknownScoringProfileError] when nothing is registered.
  ScoringProfile resolve(DisciplineType discipline, int rulesVersion) =>
      _profiles[(discipline, rulesVersion)] ??
      (throw UnknownScoringProfileError(discipline, rulesVersion));

  /// All registered profiles.
  Iterable<ScoringProfile> get profiles => _profiles.values;
}
