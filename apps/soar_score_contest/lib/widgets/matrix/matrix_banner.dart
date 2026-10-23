import 'package:flutter/material.dart';

import '../page_states/page_banner.dart';

/// Which colours a [MatrixBanner] uses.
enum MatrixBannerKind { error, warning }

/// A non-blocking notice with an icon, a title, a sentence and optional
/// actions. Errors are announced as alerts.
class MatrixBanner extends StatelessWidget {
  const MatrixBanner({
    super.key,
    required this.kind,
    required this.icon,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final MatrixBannerKind kind;
  final IconData icon;
  final String title;
  final String body;
  final List<PageBannerAction> actions;

  @override
  Widget build(BuildContext context) => PageBanner(
    kind: switch (kind) {
      MatrixBannerKind.error => PageBannerKind.alert,
      MatrixBannerKind.warning => PageBannerKind.status,
    },
    shape: PageBannerShape.card,
    icon: icon,
    title: title,
    text: body,
    actions: actions,
  );
}
