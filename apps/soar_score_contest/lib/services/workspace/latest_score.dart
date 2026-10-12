import 'package:equatable/equatable.dart';

/// The most recently entered official score and where it sits in the matrix.
class LatestScore extends Equatable {
  const LatestScore({
    required this.roundOrdinal,
    required this.groupNumber,
    required this.setAt,
  });

  final int roundOrdinal;
  final int groupNumber;
  final DateTime setAt;

  @override
  List<Object?> get props => [roundOrdinal, groupNumber, setAt];
}
