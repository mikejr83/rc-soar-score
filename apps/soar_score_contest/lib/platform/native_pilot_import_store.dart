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
  Future<core.PilotImportOutcome> apply(
    List<core.PilotImportSelection> selections, {
    required Map<core.Id, int> reviewedRevisions,
  }) => _server.runProfileOperation(() async {
    // The owner is read once, inside the operation: a change of owner while
    // it runs stops its writes instead of splitting them between two.
    final acting = _server.actingAccountId;
    final seen = _reviewedLinks;
    if (seen != null) {
      final current = await _server.repository.pilotImportLinkRepository
          .listForOwner(acting);
      final revisions = {for (final link in current) link.id: link.revision};
      final changed = <core.Id>{
        for (final entry in revisions.entries)
          if (seen[entry.key] != entry.value) entry.key,
        for (final id in seen.keys)
          if (!revisions.containsKey(id)) id,
      };
      if (changed.isNotEmpty) {
        throw core.PilotImportReviewChangedError(changed.toList());
      }
    }
    return core.PilotImportService(
      _server.repository.participantProfileRepository,
      clock: clock,
      saveImport: (profiles, selections, metadata) async {
        final existing = await _server.repository.pilotImportLinkRepository
            .listForOwner(acting);
        final now = clock().toUtc();
        final links = <core.PilotImportLink>[];
        for (final selection in selections) {
          final no = selection.match.draft.sourcePilotNo;
          if (no == null || selection.choice == core.PilotImportChoice.skip) {
            continue;
          }
          final id = selection.choice == core.PilotImportChoice.add
              ? selection.newProfileId
              : selection.targetProfileId ??
                    selection.match.candidateIds.single;
          final previous = existing
              .where(
                (l) =>
                    l.sourceSystem == 'gliderscore6' && l.sourcePilotNo == no,
              )
              .toList();
          final old = previous.isEmpty ? null : previous.single;
          links.add(
            core.PilotImportLink(
              id: old?.id ?? core.Id.create(),
              ownerAccountId: acting,
              sourcePilotNo: no,
              participantProfileId: id,
              sourceValues: core.PilotImportMatcher.sourceValues(
                selection.match.draft,
              ),
              createdAt: old?.createdAt ?? now,
              updatedAt: now,
              revision: old?.revision ?? 0,
            ),
          );
        }
        return _server.repository.pilotImportLinkRepository.saveImport(
          profiles,
          links,
          metadata: metadata,
          reviewedOwner: acting,
          reviewedLinks: seen,
        );
      },
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
