import '../models/contest/contest_config.dart';
import '../models/id.dart';

/// What a director supplies when saving the next configuration revision of a
/// contest.
class ConfigurationInput {
  const ConfigurationInput({
    required this.baseRevisionNumber,
    required this.disciplineProfileId,
    required this.config,
    this.landingTableId,
    this.notes,
  });

  /// The revision number the caller read: the latest one, or 0 when the
  /// contest has no configuration yet.
  final int baseRevisionNumber;

  /// The discipline profile the settings are for. It is chosen with the
  /// first revision and the same for every later one.
  final Id disciplineProfileId;

  final ContestConfig config;

  /// The landing table to use. When null, the profile's default is used for
  /// a discipline that scores landings.
  final Id? landingTableId;

  final String? notes;
}
