import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A titled docs page with placeholder sections; content comes with #165.
class DocsPlaceholderPage extends StatelessWidget {
  const DocsPlaceholderPage({
    super.key,
    required this.title,
    required this.sections,
    this.children = const [],
  });

  final String title;
  final List<String> sections;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: text.headlineSmall),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          Text(section, style: text.titleLarge),
          const Text('This section is not written yet.'),
        ],
        ...children,
        TextButton(
          onPressed: () => context.go('/docs'),
          child: const Text('Back to documentation'),
        ),
      ],
    );
  }
}
