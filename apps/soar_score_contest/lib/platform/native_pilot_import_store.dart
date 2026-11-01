import 'package:soar_score_api_handlers/soar_score_api_handlers.dart'
    show Principal;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../server/embedded_server.dart';
import '../services/pilot_import/pilot_import.dart';

/// Reads and saves the participants of the embedded server's database for a
/// GliderScore pilot import.
class NativePilotImportStore implements PilotImportStore {
  NativePilotImportStore(this._server, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final EmbeddedServer _server;
  final DateTime Function() _clock;

  @override
  Future<List<core.ParticipantProfile>> existing() => _server
      .repository
      .participantProfileRepository
      .listForOwner(_server.actingAccountId);

  @override
  Future<core.PilotImportOutcome> apply(
    List<core.PilotImportSelection> selections,
  ) {
    final acting = _server.actingAccountId;
    return core.PilotImportService(
      _server.repository.participantProfileRepository,
      clock: _clock,
    ).apply(
      acting,
      selections,
      metadata: Principal(accountId: acting).mutationMetadata(
        clientMutationId: 'gliderscore-pilots-${core.Id.create().value}',
        clientTime: _clock().toUtc(),
      ),
    );
  }
}
