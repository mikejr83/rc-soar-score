import 'package:flutter/material.dart';

class ContestScoringPage extends StatefulWidget {
  const ContestScoringPage({super.key, required this.contestId});

  final String contestId;

  @override
  State<ContestScoringPage> createState() => _ContestScoringPageState();
}

class _ContestScoringPageState extends State<ContestScoringPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scoring')),
      body: Center(
        child: Text(
          'This page isn\'t implemented yet. Just a placeholder. Contest ID: ${widget.contestId}',
        ),
      ),
    );
  }
}
