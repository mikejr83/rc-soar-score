import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String title = 'Dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Home placeholder'),
            ElevatedButton(
              onPressed: () => context.go('/contests'),
              child: const Text('Go to Contests'),
            ),
          ],
        ),
      ),
    );
  }
}
