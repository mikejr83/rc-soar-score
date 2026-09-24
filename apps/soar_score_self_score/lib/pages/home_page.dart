import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Self Score')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pilots enter flight scores here.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/scores'),
              child: const Text('Enter Score'),
            ),
          ],
        ),
      ),
    );
  }
}
