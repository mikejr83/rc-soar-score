/// Calculates fairness metrics for a flight matrix.
class FairnessCalculator {
  /// Compute max duplicate matchups.
  int computeMaxDuplicates(Map<String, int> pairCounts) {
    if (pairCounts.isEmpty) return 0;
    return pairCounts.values.reduce((a, b) => a > b ? a : b);
  }

  /// Compute matchup distribution histogram: [0 times, 1 time, 2 times, 3+ times].
  List<int> computeMatchupHistogram(Map<String, int> pairCounts, int totalPilots) {
    final histogram = <int>[0, 0, 0, 0];
    final totalPairs = (totalPilots * (totalPilots - 1)) ~/ 2;

    int trackedPairs = pairCounts.length;
    histogram[0] = totalPairs - trackedPairs;

    for (final count in pairCounts.values) {
      if (count <= 3) {
        histogram[count]++;
      } else {
        histogram[3]++;
      }
    }

    return histogram;
  }

  /// Compute ideal matchup target for given contest parameters.
  double computeIdealMatchupTarget({
    required int rounds,
    required int pilots,
    required int groups,
  }) {
    final avgGroupSize = pilots / groups;
    return (rounds * (avgGroupSize - 1)) / (pilots - 1);
  }
}