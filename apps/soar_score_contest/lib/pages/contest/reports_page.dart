import 'package:flutter/material.dart';

class ContestReportsPage extends StatefulWidget {
  const ContestReportsPage({super.key, required this.contestId});

  final String contestId;

  @override
  State<ContestReportsPage> createState() => _ContestReportsPageState();
}

class _ContestReportsPageState extends State<ContestReportsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Center(
        child: Text(
          'This page isn\'t implemented yet. Just a placeholder. Contest ID: ${widget.contestId}',
        ),
      ),
    );
  }
}
