import 'package:flutter/material.dart';

class ContestParticipantsPage extends StatefulWidget {
  const ContestParticipantsPage({super.key, required this.contestId});

  final String contestId;

  @override
  State<ContestParticipantsPage> createState() =>
      _ContestParticipantsPageState();
}

class _ContestParticipantsPageState extends State<ContestParticipantsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: Center(child: Text('Contest ID: ${widget.contestId}')),
    );
  }
}
