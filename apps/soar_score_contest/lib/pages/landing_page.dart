import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/app_mode_provider.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/services/connectivity/app_connectivity.dart';
import 'package:soar_score_contest/widgets/connectivity_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/not_wired_up_dialog.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key, this.isWeb = kIsWeb});

  final bool isWeb;

  static const String title = 'RC Soar Score';

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
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open "$label".')));
    }
  }

  Widget _authenticationButtons(
    BuildContext context,
    AppConnectivity? monitor,
  ) {
    Widget buildButtons(bool internetAvailable, bool apiAvailable) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: internetAvailable && apiAvailable
              ? () => showNotWiredUpDialog(context, 'Sign in')
              : null,
          icon: const Icon(Icons.login),
          label: const Text('Sign in'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: internetAvailable
              ? () => showNotWiredUpDialog(context, 'Create account')
              : null,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Create account'),
        ),
      ],
    );

    if (monitor == null) {
      return buildButtons(false, false);
    }

    return ListenableBuilder(
      listenable: monitor,
      builder: (context, _) => buildButtons(
        monitor.internetStatus == ConnectivityStatus.available,
        monitor.apiStatus == ConnectivityStatus.available,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionWidgets = List<Widget>.empty(growable: true);
    final monitor = appConnectivityOf(context);

    if (!kIsWeb && monitor != null) {
      // Indicators exist only when a bootstrap created the monitor (D5).
      // Internet first; hidden when the host cannot report connectivity at
      // all (decision D8).
      if (monitor.supportsConnectivity) {
        actionWidgets.add(ConnectivityIndicator.internet(monitor));
      }
      actionWidgets.add(ConnectivityIndicator.api(monitor));
    }

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, actions: actionWidgets),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // const SoarLogo(size: 72),
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
                _authenticationButtons(context, monitor),
                const SizedBox(height: 32),
                if (!isWeb) ...[
                  Text(
                    'Offline contests stay on this device unless you publish '
                    'them or sign in to enable synchronization.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    // `Continue offline` is available only in the offline
                    // (desktop) version of the app. The web build does not
                    // show it.
                    if (!isWeb)
                      TextButton.icon(
                        onPressed: () {
                          if (!kIsWeb) {
                            appModeOf(context)?.enterOfflineMode();
                          }
                          context.pushNamed('home');
                        },
                        icon: const Icon(Icons.wifi_off, size: 16),
                        label: const Text('Continue offline'),
                      ),
                    TextButton.icon(
                      onPressed: () => _openExternalLink(
                        context,
                        'https://example.com/help',
                        'Help',
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Help'),
                    ),
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
