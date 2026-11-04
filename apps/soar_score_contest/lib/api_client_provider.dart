import 'package:flutter/widgets.dart';
import 'package:soar_score_api/soar_score_api.dart';

/// Exposes the app's `ApiClient` (and, transitively, its target server) to
/// the widget tree.
///
/// The client is created once during the platform bootstrap before the first
/// frame and handed in by `SoarScoreContestApp`; widgets reach it through
/// [contextWatch]. This is the seam that lets the UI call through
/// `soar_score_api` (per the architecture's front-end parity rule) without
/// any further state-management machinery.
class ApiClientInherited extends InheritedWidget {
  const ApiClientInherited({
    super.key,
    required this.client,
    required super.child,
  });

  final ApiClient client;

  @override
  bool updateShouldNotify(ApiClientInherited oldWidget) =>
      client != oldWidget.client;
}

/// The app-wide `ApiClient`, or `null` when no bootstrap client is provided
/// (e.g. tests that pump the app without one).
ApiClient? apiClientOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<ApiClientInherited>()?.client;

/// Exposes the `ApiClient` that publishes contests to the widget tree.
///
/// Publishing needs the hosted server: the embedded server of the native
/// build never publishes. So on native this is the remote client (which sends
/// the sign-in token); on web it is the one client the app has.
class PublicationClientInherited extends InheritedWidget {
  const PublicationClientInherited({
    super.key,
    required this.client,
    required super.child,
  });

  final ApiClient client;

  @override
  bool updateShouldNotify(PublicationClientInherited oldWidget) =>
      client != oldWidget.client;
}

/// The client for publication calls: the one the app provides for them, else
/// the app-wide client (tests that pump the app with a single client), or
/// `null` when there is none.
ApiClient? publicationClientOf(BuildContext context) =>
    context
        .dependOnInheritedWidgetOfExactType<PublicationClientInherited>()
        ?.client ??
    apiClientOf(context);
