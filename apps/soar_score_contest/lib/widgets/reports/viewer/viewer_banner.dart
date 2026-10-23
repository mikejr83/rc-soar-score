import 'package:flutter/material.dart';

import '../../page_states/page_banner.dart';

/// How a [ViewerBanner] reads. Each kind also has its own icon and a bold lead
/// word, so none relies on colour.
enum ViewerBannerKind { official, preliminary, info, error, neutral }

/// One status line above the sheet: an icon, a bold lead, one sentence and up
/// to two actions. Screen only; it never prints.
class ViewerBanner extends StatelessWidget {
  const ViewerBanner({
    super.key,
    required this.kind,
    required this.icon,
    required this.lead,
    required this.text,
    this.actions = const [],
  });

  final ViewerBannerKind kind;
  final IconData icon;
  final String lead;
  final String text;

  /// Buttons, last one primary.
  final List<PageBannerAction> actions;

  @override
  Widget build(BuildContext context) => PageBanner(
    kind: switch (kind) {
      ViewerBannerKind.official => PageBannerKind.positive,
      ViewerBannerKind.preliminary => PageBannerKind.status,
      ViewerBannerKind.info => PageBannerKind.info,
      ViewerBannerKind.error => PageBannerKind.alert,
      ViewerBannerKind.neutral => PageBannerKind.neutral,
    },
    icon: icon,
    lead: lead,
    text: text,
    actions: actions,
  );
}
