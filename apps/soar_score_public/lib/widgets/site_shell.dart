import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../app.dart';

/// Header (logo, app name, navigation), page body and footer shared by every
/// route of the public site.
class SiteShell extends StatelessWidget {
  const SiteShell({super.key, required this.child});

  final Widget child;

  static const Key homeLink = Key('site_shell_home');
  static const Key docsLink = Key('site_shell_docs');
  static const Key helpLink = Key('site_shell_help');
  static const Key contestsLink = Key('site_shell_contests');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: BrandLogo(height: 36),
        ),
        title: const Text(SoarScorePublicApp.title),
        actions: [
          TextButton(
            key: homeLink,
            onPressed: () => context.go('/'),
            child: const Text('Home'),
          ),
          TextButton(
            key: docsLink,
            onPressed: () => context.go('/docs'),
            child: const Text('Docs'),
          ),
          TextButton(
            key: helpLink,
            onPressed: () => context.go('/help'),
            child: const Text('Help'),
          ),
          TextButton(
            key: contestsLink,
            onPressed: () => context.go('/results/contests'),
            child: const Text('Contests'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '${SoarScorePublicApp.title} - RC sailplane contest scoring',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
