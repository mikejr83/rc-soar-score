import 'dart:math';

import '../../models/matrix/draw_result.dart';
import '../../models/matrix/round_assignment.dart';
import 'fairness_calculator.dart';
import 'lane_tracker.dart';
import 'matchup_tracker.dart';
import 'matrix_generator.dart';
import 'matrix_optimizer.dart';
import 'team_validator.dart';

/// Main service for generating flight matrices.
class MatrixDrawService {
  final Random random;
  final MatrixGenerator generator;
  final MatrixOptimizer optimizer;
  final MatchupTracker tracker;
  final FairnessCalculator fairness;
  final LaneTracker laneTracker;
  final TeamValidator teamValidator;

  MatrixDrawService({int? seed})
      : random = Random(seed ?? DateTime.now().millisecondsSinceEpoch),
        generator = MatrixGenerator(seed: seed),
        optimizer = MatrixOptimizer(seed: seed),
        tracker = MatchupTracker(),
        fairness = FairnessCalculator(),
        laneTracker = LaneTracker(),
        teamValidator = TeamValidator();

  DrawResult generate({
    required List<String> pilotIds,
    required Map<String, int> pilotTeams,
    required int groupsPerRound,
    required int roundsRequested,
    double temperature = 1000,
    double coolingRate = 0.9995,
    int maxIterations = 100000,
  }) {
    // Validate team protection constraint
    if (!teamValidator.validateGroupCount(
      pilotTeams: pilotTeams,
      groupsPerRound: groupsPerRound,
    )) {
      final maxTeam = teamValidator.getMaxTeamSize(pilotTeams);
      throw StateError(
        'groupsPerRound ($groupsPerRound) must be >= max team size ($maxTeam)',
      );
    }

    final totalPilots = pilotIds.length;
    final baseGroupSize = totalPilots ~/ groupsPerRound;
    final remainder = totalPilots % groupsPerRound;
    final lanes = baseGroupSize;

    laneTracker.initializeForPilots(pilotIds);
    final rounds = <RoundAssignment>[];
    int totalIterations = 0;

    for (int round = 1; round <= roundsRequested; round++) {
      // Generate initial random assignment
      final initial = generator.generateInitialAssignment(
        pilotIds: pilotIds,
        groupsPerRound: groupsPerRound,
        baseGroupSize: baseGroupSize,
        remainder: remainder,
      );

      // Optimize using simulated annealing
      final optimized = optimizer.optimize(
        initialAssignment: initial,
        tracker: tracker,
        lanes: lanes,
        totalPilots: totalPilots,
        groupsPerRound: groupsPerRound,
        round: round,
        temperature: temperature,
        coolingRate: coolingRate,
        maxIterations: maxIterations,
      );

      // Build round result
      final roundAssignment = RoundAssignment(
        roundNumber: round,
        groups: _buildGroups(optimized),
      );
      rounds.add(roundAssignment);

      // Record for next rounds
      tracker.recordMatchups(optimized);
      laneTracker.recordAssignments(optimized);
      totalIterations += maxIterations;
    }

    // Compute fairness metrics
    final maxDuplicates = fairness.computeMaxDuplicates(tracker.pairCounts);
    final histogram = fairness.computeMatchupHistogram(tracker.pairCounts, pilotIds.length);

    return DrawResult(
      rounds: rounds,
      pilotTeamIds: pilotTeams,
      groupsPerRound: groupsPerRound,
      roundsRequested: roundsRequested,
      matchupCounts: tracker.pairCounts,
      maxDuplicateMatchups: maxDuplicates,
      matchupHistogram: histogram,
      laneAssignments: laneTracker.laneCounts,
      totalIterations: totalIterations,
    );
  }

  List<List<MatrixPilotAssignment>> _buildGroups(
      List<MatrixPilotAssignment> assignments) {
    final groups = <int, List<MatrixPilotAssignment>>{};
    for (final a in assignments) {
      if (!groups.containsKey(a.groupNumber)) {
        groups[a.groupNumber] = [];
      }
      groups[a.groupNumber]!.add(a);
    }

    final result = <List<MatrixPilotAssignment>>[];
    for (int g = 1; g <= groups.length; g++) {
      if (groups.containsKey(g)) {
        final group = groups[g]!;
        group.sort((a, b) => a.laneNumber.compareTo(b.laneNumber));
        result.add(group);
      }
    }
    return result;
  }
}