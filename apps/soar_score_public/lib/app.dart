import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import 'router.dart';

class SoarScorePublicApp extends StatelessWidget {
  const SoarScorePublicApp({super.key});

  static const String title = 'RC Soar Score';

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: PublicAppTheme.lightTheme,
      darkTheme: PublicAppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: buildAppRouter(),
    );
  }
}
