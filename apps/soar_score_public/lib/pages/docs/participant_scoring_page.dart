import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'docs_placeholder_page.dart';

/// Participant scoring help (`/docs/participant-scoring`).
class ParticipantScoringPage extends StatelessWidget {
  const ParticipantScoringPage({super.key});

  static const String title = 'Help Me Enter My Score';

  @override
  Widget build(BuildContext context) {
    return DocsPlaceholderPage(
      title: title,
      sections: const [
        'Goals of participant scoring',
        'Entering a score',
        'Requesting a score review',
        'Disciplines',
      ],
      children: [
        ListTile(
          title: const Text('F5J'),
          onTap: () => context.go('/docs/participant-scoring/disciplines/f5j'),
        ),
      ],
    );
  }
}
