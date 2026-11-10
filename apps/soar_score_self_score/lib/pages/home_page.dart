import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../widgets/legal_footer.dart';

/// The landing page: brand lockup, what the app is for and the two ways in.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: BrandLogo(
                            variant: BrandLogoVariant.lockup,
                            height: 120,
                            semanticLabel:
                                'RC Soar Score, glider contest scoring',
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Score your flights at the field',
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This is the self-scoring app for RC Soar Score. Open '
                          'the link your contest director sent you to start '
                          'scoring.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Accounts come in a future release; until then the
                        // only way in is the director's link. The hint tells a
                        // screen reader why the buttons are off.
                        Semantics(
                          hint:
                              'Sign in and sign up are not available yet. '
                              'Use the link your contest director sent you.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: null,
                                child: const Text('Sign in'),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  side: BorderSide(
                                    color: scheme.onSurface,
                                    width: 1.5,
                                  ),
                                ),
                                onPressed: null,
                                child: const Text('Sign up'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in and sign up are coming in a future '
                                'release, when pilots can create accounts '
                                'that track their results over time.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.mail_outline,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Lost your link? Ask your contest director to send '
                                'your link again.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const LegalFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
