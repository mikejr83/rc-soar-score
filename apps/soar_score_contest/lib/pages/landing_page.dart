import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/app_mode_provider.dart';
import 'package:soar_score_contest/auth/auth_session.dart';
import 'package:soar_score_contest/auth/auth_session_inherited.dart';
import 'package:soar_score_contest/auth/auth_config.dart';
import 'package:soar_score_contest/auth/e2e_mode.dart';
import 'package:soar_score_contest/auth/identity_provider_check.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/services/connectivity/app_connectivity.dart';
import 'package:soar_score_contest/widgets/connectivity_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_window_title.dart';
import '../widgets/glider_score_import_button.dart';
import '../widgets/not_wired_up_dialog.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key, this.isWeb = kIsWeb, this.identityCheck});

  final bool isWeb;

  /// The identity-provider reachability check behind the loading and
  /// unavailable states. When `null` (the app's router) the page makes one
  /// for the platform's Auth0 tenant when a session is present. Provided in
  /// tests only.
  final IdentityProviderCheck? identityCheck;

  static const String title = 'RC Soar Score';

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  /// The page's identity-provider check, present only while a session is
  /// inherited (bare tests pump the page without one and render exactly as
  /// before the states existed).
  IdentityProviderCheck? _check;

  bool _ownsCheck = false;

  AppConnectivity? _monitor;

  /// The monitor's last seen internet status, so only a transition to
  /// `available` re-probes (no flicker on flapping connections).
  ConnectivityStatus? _lastInternetStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = authSessionOf(context);
    final monitor = appConnectivityOf(context);
    final previousMonitor = _monitor;
    _monitor = monitor;
    _lastInternetStatus = monitor?.internetStatus;
    if (previousMonitor != null && previousMonitor != monitor) {
      previousMonitor.removeListener(_onConnectivityChanged);
    }
    if (monitor != null && monitor != previousMonitor) {
      monitor.addListener(_onConnectivityChanged);
    }
    if (session == null) {
      _disposeCheck();
      return;
    }
    if (_check == null) {
      final injected = widget.identityCheck;
      _check =
          injected ??
          IdentityProviderCheck(
            tenantDomain: widget.isWeb
                ? Auth0Config.web().domain
                : Auth0Config.windows().domain,
            scriptedE2e: e2eSignedOutMode,
          );
      _ownsCheck = injected == null;
      _check?.check();
    }
  }

  void _onConnectivityChanged() {
    final monitor = _monitor;
    if (monitor == null) {
      return;
    }
    if (monitor.internetStatus == ConnectivityStatus.available &&
        _lastInternetStatus != ConnectivityStatus.available) {
      _lastInternetStatus = monitor.internetStatus;
      _check?.check();
    }
    _lastInternetStatus = monitor.internetStatus;
  }

  void _disposeCheck() {
    if (_ownsCheck) {
      _check?.dispose();
    }
    _check = null;
    _ownsCheck = false;
  }

  @override
  void dispose() {
    _monitor?.removeListener(_onConnectivityChanged);
    _disposeCheck();
    super.dispose();
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
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open "$label".')));
    }
  }

  /// Starts sign-in (or sign-up), showing the reason when it fails.
  Future<void> _signIn(
    BuildContext context,
    AuthSession session, {
    bool createAccount = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await session.signIn(createAccount: createAccount);
    } on AuthException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Widget _authenticationArea(
    BuildContext context,
    AppConnectivity? monitor,
    AuthSession? session,
    IdentityProviderCheck? check,
  ) {
    if (session != null && session.isSignedIn) {
      return _signedInArea(session);
    }

    Widget buttons(bool internetAvailable, bool apiAvailable) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session?.endedReason != null) ...[
          Text(
            session!.endedReason!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: internetAvailable && apiAvailable
              ? () => session == null
                    ? showNotWiredUpDialog(context, 'Sign in')
                    : _signIn(context, session)
              : null,
          icon: const Icon(Icons.login),
          label: const Text('Sign in'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: internetAvailable
              ? () => session == null
                    ? showNotWiredUpDialog(context, 'Create account')
                    : _signIn(context, session, createAccount: true)
              : null,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Create account'),
        ),
      ],
    );

    final Widget normal = monitor == null
        ? buttons(false, false)
        : ListenableBuilder(
            listenable: monitor,
            builder: (context, _) => buttons(
              monitor.internetStatus == ConnectivityStatus.available,
              monitor.apiStatus == ConnectivityStatus.available,
            ),
          );

    if (check == null) {
      return normal;
    }

    return ListenableBuilder(
      listenable: check,
      builder: (context, _) {
        final status = check.status;
        if (status == IdentityProviderStatus.checking) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Checking sign-in…'),
            ],
          );
        }
        if (status == IdentityProviderStatus.unavailable) {
          final lastError = check.lastError;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40),
              const SizedBox(height: 8),
              Text(
                'Sign-in unavailable',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'The identity provider is currently unreachable: '
                '${lastError ?? 'unknown error'}.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => check.check(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          );
        }
        return normal;
      },
    );
  }

  Widget _signedInArea(AuthSession session) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session.displayName != null) ...[
          Text(
            'Signed in as ${session.displayName}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: () => context.pushNamed('home'),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continue'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: session.signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionWidgets = List<Widget>.empty(growable: true);
    final monitor = _monitor;
    final session = authSessionOf(context);

    if (!kIsWeb && monitor != null) {
      // Indicators exist only when a bootstrap created the monitor (D5).
      // Internet first; hidden when the host cannot report connectivity at
      // all (decision D8).
      if (monitor.supportsConnectivity) {
        actionWidgets.add(ConnectivityIndicator.internet(monitor));
      }
      actionWidgets.add(ConnectivityIndicator.api(monitor));
    }

    return AppWindowTitle(
      title: windowTitleFor(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: actionWidgets,
        ),
        // Scrolls instead of overflowing on short or narrow windows and with
        // larger text; the content stays centered when it fits.
        body: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
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
                        _authenticationArea(context, monitor, session, _check),
                        const SizedBox(height: 32),
                        if (!widget.isWeb) ...[
                          Text(
                            'Offline contests stay on this device unless you '
                            'publish them or sign in to enable '
                            'synchronization.',
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
                            if (!widget.isWeb) ...[
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
                              const SizedBox(height: 32),
                              const GliderScoreImportButton(),
                            ],
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
            ),
          ),
        ),
      ),
    );
  }
}
