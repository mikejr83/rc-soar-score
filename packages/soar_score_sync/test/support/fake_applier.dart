import 'package:soar_score_core/soar_score_core.dart';

/// Records the changes it is given; can be made to fail on one sequence.
class FakeApplier implements ReplicatedChangeApplier {
  FakeApplier(this.log);

  final List<String> log;
  final applied = <ReplicatedChange>[];
  int? failOnSequence;
  int? unsupportedOnSequence;
  int? invalidOnSequence;

  final _stored = <int>{};

  @override
  Future<bool> apply(ReplicatedChange change) async {
    if (change.sequence == failOnSequence) {
      throw StateError('disk full');
    }
    if (change.sequence == invalidOnSequence) {
      throw ArgumentError('bad payload');
    }
    if (change.sequence == unsupportedOnSequence) {
      throw UnsupportedEntityTypeError(change.entityType, 'has no store');
    }
    log.add('apply:${change.sequence}');
    applied.add(change);
    // Like the real store, a change it already holds is a no-op.
    return _stored.add(change.sequence);
  }
}
