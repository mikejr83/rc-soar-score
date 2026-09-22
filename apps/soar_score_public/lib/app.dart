import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class SoarScorePublicApp extends StatelessWidget {
  const SoarScorePublicApp({super.key});

  static const String title = 'RC Soar Score';

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: buildAppRouter(),
    );
  }
}
