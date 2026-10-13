import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The lowest and highest participant number a contest has handed out.
class ParticipantNumberRange extends Equatable {
  const ParticipantNumberRange({required this.lowest, required this.highest});

  /// The range of the numbers [participations] hold, or `null` when none has a
  /// number yet. Every participation counts, whatever its role.
  static ParticipantNumberRange? of(
    Iterable<ContestParticipation> participations,
  ) {
    int? lowest;
    int? highest;
    for (final participation in participations) {
      final number = participation.participantNumber;
      if (number == null) {
        continue;
      }
      lowest = lowest == null || number < lowest ? number : lowest;
      highest = highest == null || number > highest ? number : highest;
    }
    return lowest == null || highest == null
        ? null
        : ParticipantNumberRange(lowest: lowest, highest: highest);
  }

  final int lowest;
  final int highest;

  @override
  List<Object?> get props => [lowest, highest];
}
