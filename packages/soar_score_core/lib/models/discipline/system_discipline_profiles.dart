import '../id.dart';
import 'discipline_profile_with_rules.dart';
import 'system/system_ales_profile.dart';
import 'system/system_f3j_profile.dart';
import 'system/system_f5j_profile.dart';
import 'system/system_thermal_profile.dart';

/// The discipline profiles the system ships, with fixed ids.
///
/// The ids and rows match the documents in
/// `plan/data-model/examples/disciplines/`. A shipped profile is never
/// edited: a change is a new version with new ids.
abstract final class SystemDisciplineProfiles {
  static final f5jId = Id.parse('019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01');
  static final f3jId = Id.parse('019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01');
  static final alesId = Id.parse('019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01');
  static final thermalId = Id.parse('019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01');

  static final f5j = systemF5jProfile;
  static final f3j = systemF3jProfile;
  static final ales = systemAlesProfile;
  static final thermal = systemThermalProfile;

  /// Every profile the system ships, for the seeder.
  static List<DisciplineProfileWithRules> get all => [f5j, f3j, ales, thermal];
}
