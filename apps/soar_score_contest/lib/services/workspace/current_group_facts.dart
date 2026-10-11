import 'package:equatable/equatable.dart';

/// The group of the latest score: how far it is scored and which group flies
/// next (the next group of the same round, otherwise group 1 of the next
/// round, otherwise none).
class CurrentGroupFacts extends Equatable {
  const CurrentGroupFacts({
    required this.roundOrdinal,
    required this.groupNumber,
    required this.scored,
    required this.total,
    this.nextRoundOrdinal,
    this.nextGroupNumber,
  });

  final int roundOrdinal;
  final int groupNumber;
  final int scored;
  final int total;
  final int? nextRoundOrdinal;
  final int? nextGroupNumber;

  bool get isComplete => total > 0 && scored >= total;

  @override
  List<Object?> get props => [
    roundOrdinal,
    groupNumber,
    scored,
    total,
    nextRoundOrdinal,
    nextGroupNumber,
  ];
}
