import 'package:soar_score_api_handlers/soar_score_api_handlers.dart'
    show Principal;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../server/embedded_server.dart';
import '../services/pilot_import/pilot_import.dart';

/// Reads and saves the participants of the embedded server's database for a
/// GliderScore pilot import.
class NativePilotImportStore implements PilotImportStore {
  NativePilotImportStore(this._server, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final EmbeddedServer _server;

  /// The time of a change.
  final DateTime Function() clock;

  @override
  Future<List<core.ParticipantProfile>> existing() async {
    _server.assertProfileUsable();
    return _server.repository.participantProfileRepository.listForOwner(
      _server.actingAccountId,
    );
  }

  @override
  Future<core.PilotImportOutcome> apply(
    List<core.PilotImportSelection> selections, {
    required Map<core.Id, int> reviewedRevisions,
  }) {
    _server.assertProfileUsable();
    final acting = _server.actingAccountId;
    return core.PilotImportService(
      _server.repository.participantProfileRepository,
      clock: clock,
    ).apply(
      acting,
      selections,
      reviewedRevisions: reviewedRevisions,
      metadata: Principal(accountId: acting).mutationMetadata(
        clientMutationId: 'gliderscore-pilots-${core.Id.create().value}',
        clientTime: clock().toUtc(),
      ),
    );
  }
}
