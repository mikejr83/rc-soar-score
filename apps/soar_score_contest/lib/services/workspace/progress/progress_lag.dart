import 'package:equatable/equatable.dart';

/// The note shown while the current group is still being entered: late
/// entries right after a group lands are normal, not missing.
class ProgressLag extends Equatable {
  const ProgressLag({
    required this.roundOrdinal,
    required this.groupNumber,
    required this.scored,
    required this.total,
  });

  final int roundOrdinal;
  final int groupNumber;
  final int scored;
  final int total;

  /// Pilots of the group who have no score yet.
  int get pending => total - scored;

  @override
  List<Object?> get props => [roundOrdinal, groupNumber, scored, total];
}
