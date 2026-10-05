import 'package:equatable/equatable.dart';

/// A team and the pilots on it.
class TeamEntry extends Equatable {
  TeamEntry({required this.teamId, required List<String> pilotIds})
    : pilotIds = List.unmodifiable(pilotIds);

  final String teamId;
  final List<String> pilotIds;

  @override
  List<Object?> get props => [teamId, pilotIds];
}
