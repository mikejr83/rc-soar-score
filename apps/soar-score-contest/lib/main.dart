import 'package:flutter/material.dart';

void main() {
  runApp(const ScoreSoarContest());
}

class ScoreSoarContest extends StatelessWidget {
  const ScoreSoarContest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score Soar - Contest Management',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Score Soar', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Text('Contest Management', style: TextStyle(fontSize: 18)),
              SizedBox(height: 32),
              Text('Manage soaring contests, pilots, and scoring'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: null,
                child: Text('Create Contest (coming soon)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
