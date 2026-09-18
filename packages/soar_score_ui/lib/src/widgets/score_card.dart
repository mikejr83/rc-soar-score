import 'package:flutter/material.dart';

/// Displays score information for a flight.
class ScoreCard extends StatelessWidget {
  final double points;
  final int rank;

  const ScoreCard({super.key, required this.points, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Points: $points'),
            Text('Rank: $rank'),
          ],
        ),
      ),
    );
  }
}