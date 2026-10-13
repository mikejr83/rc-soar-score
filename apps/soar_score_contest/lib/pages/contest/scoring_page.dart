import 'package:flutter/material.dart';

class ContestScoringPage extends StatefulWidget {
  const ContestScoringPage({
    super.key,
    required this.contestId,
    this.round,
    this.group,
  });

  final String contestId;

  /// The round the page was opened at (`?round=3`), if any. The page is a
  /// placeholder until #123, which opens its round and group.
  final int? round;
  final int? group;

  @override
  State<ContestScoringPage> createState() => _ContestScoringPageState();
}

class _ContestScoringPageState extends State<ContestScoringPage> {
  @override
  Widget build(BuildContext context) {
    final round = widget.round;
    final group = widget.group;
    return Scaffold(
      appBar: AppBar(title: const Text('Scoring')),
      body: Center(
        child: Text(
          'This page isn\'t implemented yet. Just a placeholder. '
          'Contest ID: ${widget.contestId}'
          '${round == null ? '' : '. Opened at round $round'}'
          '${group == null ? '' : ', group $group'}',
        ),
      ),
    );
  }
}
