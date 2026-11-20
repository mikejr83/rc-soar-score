import 'package:material_ui/material_ui.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import 'l10n/app_localization_delegates.dart';
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
      localizationsDelegates: appLocalizationDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
