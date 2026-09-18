import 'package:flutter/material.dart';

void main() {
  runApp(const ScoreSoarPublic());
}

class ScoreSoarPublic extends StatelessWidget {
  const ScoreSoarPublic({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RC Soar Score',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('RC Soar Score', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('View soaring contests and results'),
              SizedBox(height: 32),
              Text('Browse current and past contests here'),
            ],
          ),
        ),
      ),
    );
  }
}
