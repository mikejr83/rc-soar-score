import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/soar_logo.dart';

/// The contest administration landing page.
///
/// Route: `/contest-administration`
///
/// The online and desktop applications share this landing page structure.
/// It provides `Sign in`, `Create account`, links to help and the public
/// contest site, and (desktop only) `Continue offline`. The web app does not
/// show `Continue offline`.
///
/// `Sign in` and `Create account` are placeholders: they would navigate to
/// the configured identity provider, which is not yet wired up. Tapping them
/// shows a dialog explaining that.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  /// Shown when `Sign in` or `Create account` is tapped before the identity
  /// provider integration is complete.
  void _showNotWiredUpDialog(BuildContext context, String action) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('$action is not available yet'),
        content: const Text(
          'Authentication through the identity provider has not been '
          'wired up yet. Please check back soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Opens an external URL in a new tab. External navigation is visibly
  /// identified so it does not silently discard local work: the user
  /// confirms the navigation in a dialog before leaving.
  Future<void> _openExternalLink(
    BuildContext context,
    String url,
    String label,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Opening external site'),
        content: Text(
          'You are about to leave Soar Score and open "$label" in a new '
          'browser tab. Any unsaved local work is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Open'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final uri = Uri.parse(url);
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open "$label".')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Soar - Contest Administration'),
        actions: const [
          // Development navigation item hiding the scoring/matrix test pages.
          _TestingNavItem(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SoarLogo(size: 72),
                const SizedBox(height: 16),
                Text(
                  'RC Soar Score',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage and score RC sailplane soaring contests.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => _showNotWiredUpDialog(context, 'Sign in'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showNotWiredUpDialog(context, 'Create account'),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Create account'),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openExternalLink(
                        context,
                        'https://example.com/help',
                        'Help',
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Help'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _openExternalLink(
                        context,
                        'https://example.com/public',
                        'Public contest site',
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Public contest site'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Development navigation item that links to the scoring and matrix test
/// pages. Hidden from end users until the real application pages exist.
class _TestingNavItem extends StatelessWidget {
  const _TestingNavItem();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Development testing pages',
      icon: const Icon(Icons.science_outlined),
      onPressed: () => Navigator.of(context).pushNamed('/testing'),
    );
  }
}