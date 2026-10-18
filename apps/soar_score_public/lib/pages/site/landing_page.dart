import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../services/external_url/external_url.dart';

/// Homepage: logo, description and the three navigation elements from
/// `plan/ui/public-site/homepage.md`.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const String title = SoarScorePublicApp.title;

  // TODO(#127): decide whether the public site signs users in at all; until
  // then the login element is a plain link to the identity provider.
  static const String loginUrl = 'https://auth.rc-soar-score.com/';

  static const Key loginLink = Key('home_login');
  static const Key docsLink = Key('home_docs');
  static const Key contestsLink = Key('home_contests');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Placeholder until a logo asset exists.
              const Icon(
                Icons.flight_takeoff,
                size: 96,
                semanticLabel: 'RC Soar Score logo',
              ),
              const SizedBox(height: 16),
              Text(title, style: textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                'Scoring and management for RC sailplane soaring contests: '
                'run a contest, enter and check scores, and publish results '
                'for pilots and spectators.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    key: loginLink,
                    onPressed: () => openExternalUrl(loginUrl),
                    icon: const Icon(Icons.login),
                    label: const Text('Login / Registration'),
                  ),
                  FilledButton.tonalIcon(
                    key: docsLink,
                    onPressed: () => context.go('/docs'),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Documentation / Help'),
                  ),
                  FilledButton.tonalIcon(
                    key: contestsLink,
                    onPressed: () => context.go('/results/contests'),
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('Contests'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
