import 'dart:math';

import '../../models/matrix/round_assignment.dart';
import 'matchup_tracker.dart';

/// Optimizes a flight matrix using simulated annealing to minimize duplicate matchups.
class MatrixOptimizer {
  final Random random;

  MatrixOptimizer({int? seed}) : random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  List<MatrixPilotAssignment> optimize({
    required List<MatrixPilotAssignment> initialAssignment,
    required MatchupTracker tracker,
    required int lanes,
    required int totalPilots,
    required int groupsPerRound,
    required int round,
    double temperature = 1000,
    double coolingRate = 0.9995,
    int maxIterations = 100000,
  }) {
    var current = initialAssignment;
    double currentCost = _calculateCost(current, tracker, lanes, totalPilots, groupsPerRound, round);
    var best = current;
    var bestCost = currentCost;

    double temp = temperature;
    int iterations = 0;

    while (iterations < maxIterations && temp > 1.0) {
      iterations++;

      final neighbor = _swapTwoPilots(current);
      final neighborCost = _calculateCost(neighbor, tracker, lanes, totalPilots, groupsPerRound, round);

      final delta = neighborCost - currentCost;
      if (delta < 0 || random.nextDouble() < exp(-delta / temp)) {
        current = neighbor;
        currentCost = neighborCost;
      }

      if (neighborCost < bestCost) {
        best = neighbor;
        bestCost = neighborCost;
      }

      temp *= coolingRate;
    }

    return best;
  }

  List<MatrixPilotAssignment> _swapTwoPilots(List<MatrixPilotAssignment> assignments) {
    final shuffled = List<MatrixPilotAssignment>.from(assignments);
    final len = shuffled.length;
    final i = random.nextInt(len);
    final j = random.nextInt(len);
    if (i == j) return shuffled;

    final temp = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = temp;
    return shuffled;
  }

  double _calculateCost(
    List<MatrixPilotAssignment> assignments,
    MatchupTracker tracker,
    int lanes,
    int totalPilots,
    int groupsPerRound,
    int round,
  ) {
    final groups = _groupByAssignment(assignments);

    // Count matchups in this proposed assignment
    final roundMatchups = <String, int>{};
    for (final groupPilots in groups.values) {
      for (int i = 0; i < groupPilots.length; i++) {
        for (int j = i + 1; j < groupPilots.length; j++) {
          final key = _pairKey(groupPilots[i], groupPilots[j]);
          roundMatchups[key] = (roundMatchups[key] ?? 0) + 1;
        }
      }
    }

    // Cost = sum of squared cumulative matchup counts
    double cost = 0;
    for (final key in roundMatchups.keys) {
      final historical = tracker.getPairCount(
        key.split('-')[0],
        key.split('-')[1],
      );
      final total = historical + roundMatchups[key]!;
      cost += total * total;
    }

    // Penalize pairs that flew together before but not this round
    for (final key in tracker.pairCounts.keys) {
      if (!roundMatchups.containsKey(key)) {
        cost += (tracker.getPairCount(
          key.split('-')[0],
          key.split('-')[1],
        )) * (tracker.getPairCount(
          key.split('-')[0],
          key.split('-')[1],
        ));
      }
    }

    return cost;
  }

  Map<int, List<String>> _groupByAssignment(List<MatrixPilotAssignment> assignments) {
    final groups = <int, List<String>>{};
    for (final a in assignments) {
      if (!groups.containsKey(a.groupNumber)) {
        groups[a.groupNumber] = [];
      }
      groups[a.groupNumber]!.add(a.pilotId);
    }
    return groups;
  }

  String _pairKey(String a, String b) {
    if (a.compareTo(b) < 0) return '$a-$b';
    return '$b-$a';
  }
}