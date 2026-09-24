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
