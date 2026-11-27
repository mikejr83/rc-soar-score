import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_scope.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import 'self_score_app_bar.dart';

/// The centred spinner a page shows while it waits, announced as "Loading".
class PageLoading extends StatelessWidget {
  const PageLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: AppLocalizations.of(context).loading,
        liveRegion: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

/// A page only a signed-in pilot can use. While the sign-in is being
/// restored (the SDK is loading, or a redirect is being completed) it shows a
/// loading state, so a pilot who is about to be signed in never sees a blank
/// page or a sign-in prompt. Signed in it shows [builder]. Signed out, once
/// the restore has finished, it shows [signedOut], or sends the pilot to the
/// landing page when there is none.
class SignedInGate extends StatelessWidget {
  const SignedInGate({
    required this.title,
    required this.builder,
    this.signedOut,
    super.key,
  });

  /// The page title the app bar shows while waiting or leaving.
  final String title;
  final WidgetBuilder builder;

  /// What a signed-out pilot sees; null sends them to the landing page.
  final WidgetBuilder? signedOut;

  @override
  Widget build(BuildContext context) {
    final auth = context.auth;
    if (auth.isSignedIn) return builder(context);
    if (!auth.isInitializing && signedOut != null) return signedOut!(context);
    if (!auth.isInitializing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(homePath);
      });
    }
    return Scaffold(
      appBar: SelfScoreAppBar(title: title, showAccount: false),
      body: const SafeArea(child: PageLoading()),
    );
  }
}
