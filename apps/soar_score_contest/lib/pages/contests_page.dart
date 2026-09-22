import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ContestsPage extends StatelessWidget {
  const ContestsPage({super.key});

  static const String title = 'Contests';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Contests placeholder'),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
