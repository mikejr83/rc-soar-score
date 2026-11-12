import 'package:soar_score_api_handlers/soar_score_api_handlers.dart'
    show Principal;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../server/embedded_server.dart';
import '../services/pilot_import/pilot_import.dart';

/// Reads and saves the participants of the embedded server's database for a
/// GliderScore pilot import.
class NativePilotImportStore implements PilotImportStore, PilotImportLinkStore {
  NativePilotImportStore(this._server, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final EmbeddedServer _server;
  Map<core.Id, int>? _reviewedLinks;

  /// The time of a change.
  final DateTime Function() clock;

  @override
  Future<List<core.ParticipantProfile>> existing() =>
      _server.runProfileOperation(
        () => _server.repository.participantProfileRepository.listForOwner(
          _server.actingAccountId,
        ),
      );

  @override
  Future<List<core.PilotImportLink>> existingLinks() =>
      _server.runProfileOperation(() async {
        final links = await _server.repository.pilotImportLinkRepository
            .listForOwner(_server.actingAccountId);
        _reviewedLinks = {for (final link in links) link.id: link.revision};
        return links;
      });

  @override
  Future<Set<int>> pilotsUnderReview() => _server.runProfileOperation(
    () => _server.repository.pilotImportLinkRepository.pilotsUnderReview(
      _server.actingAccountId,
    ),
  );

  @override
  Future<bool> linksManagedElsewhere() => _server.runProfileOperation(
    () => _server.repository.pilotImportLinkRepository.managedElsewhere(
      _server.actingAccountId,
    ),
  );

  @override
  Future<core.PilotImportOutcome> apply(
    List<core.PilotImportSelection> selections, {
    required Map<core.Id, int> reviewedRevisions,
    bool rememberLinks = true,
  }) => _server.runProfileOperation(() async {
    // The owner is read once, inside the operation: a change of owner while
    // it runs stops its writes instead of splitting them between two.
    final acting = _server.actingAccountId;
    final seen = _reviewedLinks;
    return core.PilotImportService(
      _server.repository.participantProfileRepository,
      clock: clock,
      links: rememberLinks
          ? _server.repository.pilotImportLinkRepository
          : null,
      reviewedLinks: rememberLinks ? seen : null,
    ).apply(
      acting,
      selections,
      reviewedRevisions: reviewedRevisions,
      metadata: Principal(accountId: acting).mutationMetadata(
        clientMutationId: 'gliderscore-pilots-${core.Id.create().value}',
        clientTime: clock().toUtc(),
      ),
    );
  });
}
