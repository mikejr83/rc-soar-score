import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Contest selection')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Contest selection is not wired up yet.'),
      ),
    ),
  );
}
