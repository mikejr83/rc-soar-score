import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../platform/inspection_owner_guard.dart';

final _logger = Logger('OwnerScopedPrincipal');

/// The auth layer of the embedded server: every request acts as the account
/// the app acts as, except that data imported for inspection is reachable.
///
/// - Inside a contest (`/contests/{id}/...`, or a `contest_id` query
///   parameter) whose owner is an inspection owner, the request acts as that
///   owner, so the contest's participants, roles and landing tables can be
///   browsed and edited as in any contest, and new rows belong to it.
/// - On a single participant, role or landing table whose owner is an
///   inspection owner, the request acts as that owner.
/// - The lists of those three also show the rows of every inspection owner
///   (the principal's `alsoVisibleOwners`).
///
/// A read error of the markers leaves the request acting as the account: it
/// never acts as an owner it cannot show to be an inspection owner.
Handler Function(Handler) ownerScopedPrincipal({
  required core.Id Function() acting,
  required SoarScoreDatabase database,
  required InspectionOwnerGuard guard,
}) {
  final stores = EntityStores.forDatabase(database);
  final contests = ContestRepository(database);

  Future<core.Id?> ownerOfRow(String entityType, String id) async {
    final parsed = _tryParse(id);
    if (parsed == null) return null;
    final row = await stores.of(entityType).findJson(parsed);
    final owner = row?['owner_account_id'];
    return owner is String ? _tryParse(owner) : null;
  }

  Future<core.Id?> contestOwner(String id) async {
    final parsed = _tryParse(id);
    return parsed == null
        ? null
        : (await contests.findById(parsed))?.ownerAccountId;
  }

  Future<core.Id?> scopeOwner(Request request) async {
    var segments = request.url.pathSegments;
    if (segments.length > 2 && segments[0] == 'api' && segments[1] == 'v1') {
      segments = segments.sublist(2);
    }
    if (segments.length >= 2 && segments[0] == 'contests') {
      return contestOwner(segments[1]);
    }
    if (segments.length >= 2) {
      final type = switch (segments[0]) {
        'participants' => 'ParticipantProfile',
        'roles' => 'Role',
        'landing-tables' => 'LandingTable',
        _ => null,
      };
      if (type != null) return ownerOfRow(type, segments[1]);
    }
    if (request.url.queryParameters['contest_id'] case final String id) {
      return contestOwner(id);
    }
    return null;
  }

  Future<Principal> principalFor(Request request) async {
    final account = acting();
    try {
      final owner = await scopeOwner(request);
      if (owner != null &&
          owner != account &&
          await guard.isInspection(owner)) {
        return Principal(accountId: owner);
      }
      return Principal(
        accountId: account,
        alsoVisibleOwners: await guard.owners(),
      );
    } on Object catch (error, stack) {
      _logger.warning('Could not read the inspection owners', error, stack);
      return Principal(accountId: account);
    }
  }

  return (inner) =>
      (request) async => inner(
        request.change(
          context: {principalContextKey: await principalFor(request)},
        ),
      );
}

core.Id? _tryParse(String text) {
  try {
    return core.Id.parse(text);
  } on ArgumentError {
    return null;
  }
}
