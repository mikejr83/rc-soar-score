import 'package:equatable/equatable.dart';

/// A finished round and how many scores it lacks.
class MissingRound extends Equatable {
  const MissingRound({required this.ordinal, required this.missing});

  final int ordinal;
  final int missing;

  @override
  List<Object?> get props => [ordinal, missing];
}
