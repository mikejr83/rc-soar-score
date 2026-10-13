import 'package:soar_score_core/soar_score_core.dart';

/// Puts [pending] in dependency order: a mutation comes after the one it
/// depends on, so a matrix revision is sent before the scores that use it.
///
/// The store returns the outbox oldest first; that order is kept wherever no
/// dependency says otherwise. A dependency that is not in [pending] (already
/// acknowledged) puts no constraint on its dependent.
List<MutationRecord> inDependencyOrder(List<MutationRecord> pending) {
  final byId = {for (final m in pending) m.id: m};
  final ordered = <MutationRecord>[];
  final placed = <Id>{};
  final visiting = <Id>{};

  void place(MutationRecord mutation) {
    if (placed.contains(mutation.id)) return;
    // A cycle cannot be ordered; keep the stored order rather than loop.
    if (!visiting.add(mutation.id)) return;
    final parent = byId[mutation.dependsOnMutationId];
    if (parent != null) place(parent);
    visiting.remove(mutation.id);
    if (placed.add(mutation.id)) ordered.add(mutation);
  }

  pending.forEach(place);
  return ordered;
}
