import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/startup/startup_mode.dart';

/// The app shown while it starts, before the data layer is ready: the name,
/// a progress bar and one status line for the kind of start it is.
class StartupSplashApp extends StatelessWidget {
  const StartupSplashApp({super.key, required this.mode});

  final StartupMode mode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soar Score',
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: StartupSplashPage(mode: mode),
    );
  }
}

class StartupSplashPage extends StatelessWidget {
  const StartupSplashPage({super.key, required this.mode});

  final StartupMode mode;

  static String message(AppLocalizations l10n, StartupMode mode) =>
      switch (mode) {
        StartupMode.initializing => l10n.startupInitializing,
        StartupMode.starting => l10n.startupStarting,
        StartupMode.updating => l10n.startupUpdating,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('startup-splash'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Soar Score',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message(l10n, mode),
                  key: const ValueKey('startup-splash-message'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
