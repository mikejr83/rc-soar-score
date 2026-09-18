import 'package:flutter/material.dart';

/// Screen displaying pilot information.
class PilotScreen extends StatelessWidget {
  const PilotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pilot')),
      body: Center(child: Text('Pilot Screen')),
    );
  }
}