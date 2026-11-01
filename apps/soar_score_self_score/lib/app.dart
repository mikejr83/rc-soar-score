import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import 'l10n/app_localizations.dart';
import 'router.dart';

class SelfScoreApp extends StatelessWidget {
  const SelfScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RC Soar Score Self-Scoring',
      debugShowCheckedModeBanner: false,
      theme: SelfScoreAppTheme.lightTheme,
      darkTheme: SelfScoreAppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
