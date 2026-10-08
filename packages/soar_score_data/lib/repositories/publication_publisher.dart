import 'package:soar_score_core/soar_score_core.dart' as core;

import 'audit_event_repository.dart';
import 'drift_repository.dart';
import 'publication_identity_repository.dart';
import 'publication_participant_repository.dart';
import 'publication_projection_repository.dart';

/// Writes one publish in a single database transaction.
class PublicationPublisher extends DriftRepository
    implements core.PublicationPublisher {
  PublicationPublisher(super.db, {super.stores});

  late final _identities = PublicationIdentityRepository(db, stores: stores);
  late final _participants = PublicationParticipantRepository(
    db,
    stores: stores,
  );
  late final _projections = PublicationProjectionRepository(db, stores: stores);
  late final _audits = AuditEventRepository(db, stores: stores);

  @override
  Future<core.PublicationIdentity> publish({
    required core.PublicationIdentity identity,
    required Iterable<core.PublicationParticipant> participants,
    required core.PublicationProjection projection,
    required core.AuditEvent attempt,
  }) => db.transaction(() async {
    final stored = await _identities.save(identity);
    for (final row in participants) {
      await _participants.save(row);
    }
    await _projections.append(projection);
    await _audits.append(attempt);
    return stored;
  });
}
