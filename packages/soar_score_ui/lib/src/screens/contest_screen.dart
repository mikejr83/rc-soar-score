import 'package:flutter/material.dart';

/// Main contest screen showing active contest info.
class ContestScreen extends StatelessWidget {
  const ContestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contest')),
      body: Center(child: Text('Contest Screen')),
    );
  }
}