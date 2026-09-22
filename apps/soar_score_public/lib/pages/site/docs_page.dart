import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocsPage extends StatelessWidget {
  const DocsPage({super.key});

  static const String title = 'Docs';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Docs placeholder'),
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
