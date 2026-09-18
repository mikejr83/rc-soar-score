import 'package:flutter/material.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/pages/landing_page.dart';
import 'package:soar_score_contest/pages/score_page_selector.dart';

import 'theme/soar_score_theme.dart';

void main() {
  runApp(const ScoreSoarContest());
}

class ScoreSoarContest extends StatelessWidget {
  const ScoreSoarContest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score Soar - Contest Management',

      // Use your custom light and dark themes here
      theme: SoarScoreTheme.lightTheme,
      darkTheme: SoarScoreTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically matches system light/dark mode

      home: const LandingPage(),
      routes: <String, WidgetBuilder>{
        // The landing page route for the contest administration app.
        '/contest-administration': (context) => const LandingPage(),
        // The contest-selection and system-management page, reached after
        // signing in or choosing offline mode.
        '/contest-administration/home': (context) => const HomePage(),
        // Development testing pages, reachable via the "Testing" nav item.
        '/testing': (context) => const ScorePageSelector(),
      },
    );
  }
}
