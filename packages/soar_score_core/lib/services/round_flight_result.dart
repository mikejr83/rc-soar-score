import 'package:equatable/equatable.dart';

import '../models/id.dart';
import '../models/results/flight_result.dart';

/// One flight of a round: its result and the group it flew in.
class RoundFlightResult extends Equatable {
  const RoundFlightResult({required this.group, required this.result});

  factory RoundFlightResult.fromJson(Map<String, Object?> json) =>
      RoundFlightResult(
        group: json['group']! as int,
        result: FlightResult.fromJson(json['result']! as Map<String, Object?>),
      );

  final int group;
  final FlightResult result;

  Id get participationId => result.contestParticipationId;

  Map<String, Object?> toJson() => {'group': group, 'result': result.toJson()};

  @override
  List<Object?> get props => [group, result];
}
