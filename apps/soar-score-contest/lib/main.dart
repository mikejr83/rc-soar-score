import 'package:flutter/material.dart';
import 'package:soar_score_contest/pages/score_page_selector.dart';

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
      home: const ScorePageSelector(),
    );
  }
}
