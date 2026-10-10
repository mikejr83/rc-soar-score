import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import 'router.dart';

class SelfScoreApp extends StatelessWidget {
  const SelfScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Self Score',
      debugShowCheckedModeBanner: false,
      theme: SelfScoreAppTheme.lightTheme,
      darkTheme: SelfScoreAppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
