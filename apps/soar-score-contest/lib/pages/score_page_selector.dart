import 'package:flutter/material.dart';
import 'f5j_scoring_test_page.dart';
import 'matrix_page.dart';

class ScorePageSelector extends StatelessWidget {
  const ScorePageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoring Tests'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.calculate),
                title: const Text('F5J Score Testing'),
                subtitle: const Text('Test the scoring engine'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const F5JScoringTestScreen()),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Matrix Creation'),
                subtitle: const Text('Test matrix draw functionality'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MatrixCreationPage()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}