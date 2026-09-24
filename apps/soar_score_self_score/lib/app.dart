import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class SelfScoreApp extends StatelessWidget {
  const SelfScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Self Score',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
