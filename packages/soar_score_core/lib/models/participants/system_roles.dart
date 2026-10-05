import '../../enums/role_type.dart';
import '../id.dart';
import 'role.dart';

/// The roles the system ships, with fixed ids.
///
/// The ids match `plan/data-model/examples/entities/role.json`. A shipped
/// role has no owner and is never edited.
abstract final class SystemRoles {
  /// The one role that flies and receives scores; the default for everyone.
  static final pilotId = Id.parse('019c0000-0000-7000-8000-000000000030');

  static final helperId = Id.parse('019c0000-0000-7000-8000-000000000032');

  static final teamManagerId = Id.parse('019c0000-0000-7000-8000-000000000033');

  static final pilot = Role(
    id: pilotId,
    displayName: 'Pilot',
    type: RoleType.pilot,
    revision: 1,
  );

  static final helper = Role(
    id: helperId,
    displayName: 'Helper',
    type: RoleType.nonFlier,
    revision: 1,
  );

  static final teamManager = Role(
    id: teamManagerId,
    displayName: 'Team Manager',
    type: RoleType.nonFlier,
    revision: 1,
  );

  /// Every role the system ships, for the seeder.
  static List<Role> get all => [pilot, helper, teamManager];
}
