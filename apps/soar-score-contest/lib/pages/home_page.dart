import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/connectivity_status_indicator.dart';

/// The contest-selection and system-management page.
///
/// Route: `/contest-administration/home`
///
/// The user reaches this page after signing in or choosing offline mode. It
/// lists the director's most recently active contests and provides
/// create/open/delete actions plus navigation to participant, role, and
/// landing-bonus management.
///
/// The contest data source and the create-contest wizard are not yet wired
/// up. Selecting an action therefore shows a dialog explaining that, matching
/// how the landing page handles features that are not yet integrated.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Shown when an action that depends on not-yet-integrated functionality
  /// is selected.
  void _showNotWiredUpDialog(BuildContext context, String action) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('$action is not available yet'),
        content: const Text(
          'This feature has not been wired up yet. Please check back soon.',
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

  /// Builds a navigation button that opens a not-wired-up dialog.
  TextButton _navigationButton(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    return TextButton.icon(
      onPressed: () => _showNotWiredUpDialog(context, label),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soar Score - Contests'),
        actions: [
          _ConnectivityIndicators(),
          IconButton(
            tooltip: 'Back to landing page',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Contest list surface.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  children: const [
                    // Empty state: no contests yet.
                    _EmptyContestListState(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Action bar: create, primary open action, and management
          // navigation.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _showNotWiredUpDialog(context, 'Create contest'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create contest'),
                  ),
                  // Primary open action for the selected contest. Disabled
                  // until a contest exists and is selected; the label changes
                  // to Open, Continue, or View based on the contest state.
                  OutlinedButton(
                    onPressed: null,
                    child: const Text('Open'),
                  ),
                  // The participant manager edits the director's reusable
                  // local participant (pilot) records.
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(
                          '/contest-administration/participants',
                        ),
                    icon: const Icon(Icons.people, size: 16),
                    label: const Text('Participants'),
                  ),
                  _navigationButton(context, 'Roles', Icons.assignment),
                  _navigationButton(context, 'Landing bonuses', Icons.local_florist),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state shown when there are no contests to display.
class _EmptyContestListState extends StatelessWidget {
  const _EmptyContestListState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note, size: 48),
          SizedBox(height: 16),
          Text('No contests yet.'),
          SizedBox(height: 8),
          Text('Create a contest to get started.'),
        ],
      ),
    );
  }
}

/// Displays the internet and API connectivity indicators in the app bar.
class _ConnectivityIndicators extends StatelessWidget {
  const _ConnectivityIndicators();

  @override
  Widget build(BuildContext context) {
    final connectivity = ConnectivityStateWidget.of(context);
    if (connectivity == null) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: connectivity,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConnectivityStatusIndicator(
            state: connectivity.internet,
            label: 'Internet',
            icon: Icons.wifi,
            connectivity: connectivity,
          ),
          ConnectivityStatusIndicator(
            state: connectivity.api,
            label: 'API',
            icon: Icons.cloud,
            connectivity: connectivity,
          ),
        ],
      ),
    );
  }
}
