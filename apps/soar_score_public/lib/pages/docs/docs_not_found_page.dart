import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'docs_nav_links.dart';

/// Shown for any unknown route under `/docs` (`/docs/not-found`).
class DocsNotFoundPage extends StatelessWidget {
  const DocsNotFoundPage({super.key});

  static const String route = '/docs/not-found';
  static const String title = 'Page Not Found';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: text.headlineSmall),
        const SizedBox(height: 16),
        const Text('The documentation page you asked for does not exist.'),
        Text('Are you having trouble?', style: text.headlineMedium),
        const Text(
          'If you have questions on functionality, are seeing errors, or '
          'have feature requests please go to our support page.',
        ),
        TextButton(
          onPressed: () => context.go('/support'),
          child: const Text('Go to the support page'),
        ),
        Text('Documentation', style: text.titleLarge),
        const DocsNavLinks(),
      ],
    );
  }
}
