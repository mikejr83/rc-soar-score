import 'package:flutter/material.dart';

import 'docs_placeholder_page.dart';

/// Public contests and results help (`/docs/contests-and-scores`).
class ContestsAndScoresPage extends StatelessWidget {
  const ContestsAndScoresPage({super.key});

  static const String title = 'Finding Contests and Results';

  @override
  Widget build(BuildContext context) {
    return const DocsPlaceholderPage(
      title: title,
      sections: ['Searching for contests', 'Reading results'],
    );
  }
}
