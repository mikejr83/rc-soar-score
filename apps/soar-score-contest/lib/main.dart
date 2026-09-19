import 'package:flutter/material.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/pages/landing_page.dart';
import 'package:soar_score_contest/pages/score_page_selector.dart';
import 'package:soar_score_contest/state/connectivity_state.dart';

import 'theme/soar_score_theme.dart';

void main() {
  final connectivity = ConnectivityState();
  connectivity.startMonitoring();

  runApp(
    ScoreSoarContest(connectivity: connectivity),
  );
}

/// Provides [ConnectivityState] to the widget tree so that any page can
/// read connectivity status via [ConnectivityStateWidget.of].
class ScoreSoarContest extends StatefulWidget {
  const ScoreSoarContest({super.key, required this.connectivity});

  final ConnectivityState connectivity;

  @override
  State<ScoreSoarContest> createState() => _ScoreSoarContestState();
}

class _ScoreSoarContestState extends State<ScoreSoarContest> {
  @override
  void dispose() {
    widget.connectivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityStateWidget(
      connectivity: widget.connectivity,
      child: MaterialApp(
        title: 'Score Soar - Contest Management',
        theme: SoarScoreTheme.lightTheme,
        darkTheme: SoarScoreTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const LandingPage(),
        routes: <String, WidgetBuilder>{
          '/contest-administration': (context) => const LandingPage(),
          '/contest-administration/home': (context) => const HomePage(),
          '/testing': (context) => const ScorePageSelector(),
        },
      ),
    );
  }
}

/// An [InheritedWidget] that exposes [ConnectivityState] to descendant widgets.
///
/// Use [ConnectivityStateWidget.of] from any descendant to get the
/// [ConnectivityState] instance.
class ConnectivityStateWidget extends InheritedWidget {
  const ConnectivityStateWidget({
    super.key,
    required this.connectivity,
    required super.child,
  });

  final ConnectivityState connectivity;

  /// Returns the nearest [ConnectivityState] from the widget tree, or null
  /// if no [ConnectivityStateWidget] is an ancestor.
  ///
  /// Use [ofRequired] when the presence of a [ConnectivityState] is guaranteed.
  static ConnectivityState? of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<ConnectivityStateWidget>();
    return widget?.connectivity;
  }

  /// Returns the nearest [ConnectivityState] from the widget tree.
  ///
  /// Throws an assertion error if no [ConnectivityStateWidget] is an ancestor.
  static ConnectivityState ofRequired(BuildContext context) {
    final connectivity = of(context);
    assert(
      connectivity != null,
      'No ConnectivityStateWidget found in widget tree.',
    );
    return connectivity!;
  }

  @override
  bool updateShouldNotify(covariant ConnectivityStateWidget oldWidget) =>
      connectivity != oldWidget.connectivity;
}
