import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown by the router for any unknown route.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.location});

  final String location;

  static const String title = 'Page not found';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('There is no page at $location.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
