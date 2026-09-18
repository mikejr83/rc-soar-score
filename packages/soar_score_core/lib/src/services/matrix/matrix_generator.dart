import 'dart:math';

import '../../models/matrix/round_assignment.dart';

/// Generates an initial random assignment of pilots to groups and lanes.
class MatrixGenerator {
  final Random random;

  MatrixGenerator({int? seed}) : random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  List<MatrixPilotAssignment> generateInitialAssignment({
    required List<String> pilotIds,
    required int groupsPerRound,
    required int baseGroupSize,
    required int remainder,
  }) {
    final shuffled = List<String>.from(pilotIds)..shuffle(random);
    final assignments = <MatrixPilotAssignment>[];
    var index = 0;

    for (int group = 1; group <= groupsPerRound; group++) {
      final groupSize = group <= remainder ? baseGroupSize + 1 : baseGroupSize;
      for (int lane = 1; lane <= groupSize; lane++) {
        if (index >= shuffled.length) break;
        assignments.add(MatrixPilotAssignment(
          pilotId: shuffled[index],
          groupNumber: group,
          laneNumber: lane,
        ));
        index++;
      }
    }

    return assignments;
  }
}