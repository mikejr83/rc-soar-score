import 'package:flutter/material.dart';

import 'docs_placeholder_page.dart';

/// F5J score entry quick reference
/// (`/docs/participant-scoring/disciplines/f5j`).
class F5jScoringPage extends StatelessWidget {
  const F5jScoringPage({super.key});

  static const String title = 'F5J Score Entry';

  @override
  Widget build(BuildContext context) {
    return const DocsPlaceholderPage(
      title: title,
      sections: ['Score entry screen', 'Fields'],
    );
  }
}
