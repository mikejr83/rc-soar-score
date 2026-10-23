import 'package:flutter/material.dart';

import '../page_states/page_banner.dart';

/// A button in an [EditorBanner].
class EditorBannerAction {
  const EditorBannerAction(this.label, this.onPressed, {this.icon, this.key});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Key? key;
}

/// A notice in the participant editor: an icon, a title, a sentence and
/// optional actions on a [PageBanner]. The last action is the filled one.
///
/// The kind says what sort of notice it is (error, conflict, note) but the
/// icon and the words carry the meaning too.
class EditorBanner extends StatelessWidget {
  const EditorBanner({
    required this.kind,
    required this.icon,
    required this.title,
    this.body,
    this.actions = const [],
    this.child,
    super.key,
  });

  final PageBannerKind kind;
  final IconData icon;
  final String title;
  final String? body;
  final List<EditorBannerAction> actions;
  final Widget? child;

  @override
  Widget build(BuildContext context) => PageBanner(
    kind: kind,
    shape: PageBannerShape.card,
    icon: icon,
    title: title,
    text: body ?? '',
    actions: [
      for (final (i, action) in actions.indexed)
        PageBannerAction(
          action.label,
          action.onPressed,
          icon: action.icon,
          key: action.key,
          emphasis: i == actions.length - 1
              ? PageBannerEmphasis.filled
              : PageBannerEmphasis.outlined,
        ),
    ],
    child: child,
  );
}
