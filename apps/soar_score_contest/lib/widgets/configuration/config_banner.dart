import 'package:flutter/material.dart';

import '../page_states/page_banner.dart';

/// A notice at the top of the page about the whole contest: administration
/// locked, contest completed, scoring started, no configuration saved yet.
class ConfigBanner extends StatelessWidget {
  const ConfigBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.info = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Uses the primary container instead of the neutral one.
  final bool info;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => PageBanner(
    kind: info ? PageBannerKind.info : PageBannerKind.neutral,
    shape: PageBannerShape.card,
    icon: icon,
    title: title,
    text: body,
    actions: [
      if (actionLabel != null)
        PageBannerAction(
          actionLabel!,
          onAction,
          emphasis: PageBannerEmphasis.outlined,
        ),
    ],
  );
}
