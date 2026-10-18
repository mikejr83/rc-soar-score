import 'package:flutter/material.dart';

import 'docs_placeholder_page.dart';

/// Competition help for contest directors (`/docs/competitions`).
class CompetitionsPage extends StatelessWidget {
  const CompetitionsPage({super.key});

  static const String title = 'Contest Director Getting Started';

  @override
  Widget build(BuildContext context) {
    return const DocsPlaceholderPage(
      title: title,
      sections: [
        'Running a contest on the web site',
        'The offline application',
      ],
    );
  }
}
