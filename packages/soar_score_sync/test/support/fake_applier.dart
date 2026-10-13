import 'package:soar_score_core/soar_score_core.dart';

/// Records the changes it is given; can be made to fail on one sequence.
class FakeApplier implements ReplicatedChangeApplier {
  FakeApplier(this.log);

  final List<String> log;
  final applied = <ReplicatedChange>[];
  int? failOnSequence;
  int? unsupportedOnSequence;

  @override
  Future<void> apply(ReplicatedChange change) async {
    if (change.sequence == failOnSequence) {
      throw StateError('disk full');
    }
    if (change.sequence == unsupportedOnSequence) {
      throw ArgumentError('No store for ${change.entityType}');
    }
    log.add('apply:${change.sequence}');
    applied.add(change);
  }
}
