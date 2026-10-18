import 'package:flutter/material.dart';

import 'docs_nav_links.dart';

/// Documentation and help landing page (`/docs`).
class DocsLandingPage extends StatelessWidget {
  const DocsLandingPage({super.key});

  static const String route = '/docs';
  static const String title = 'Documentation and Help';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: text.headlineSmall),
        const SizedBox(height: 16),
        Text('Getting started', style: text.titleLarge),
        const Text(
          'Tips on getting started will appear here. Pick the guide that '
          'matches what you want to do.',
        ),
        const DocsNavLinks(),
        // Reserved for a future FAQ section.
        Text('FAQ', style: text.titleLarge),
        const Text('Frequently asked questions will appear here.'),
      ],
    );
  }
}
