import 'package:flutter/material.dart';

import '../page_states/page_banner.dart';

/// How a [WizardBanner] reads: errors block, warnings advise, info explains.
enum WizardBannerTone { error, warning, info, success }

/// A link in a [WizardBanner] that moves focus to the field it names.
class WizardBannerLink {
  const WizardBannerLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;
}

/// An action button in a [WizardBanner]; the first one is the filled one.
class WizardBannerAction {
  const WizardBannerAction({
    required this.label,
    required this.onPressed,
    this.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Key? key;
}

/// A banner at the top of a wizard step: the validation summary (with links
/// to each field), a failed save, or a step-wide note.
///
/// Errors are announced as alerts; the tone is also carried by the icon and
/// the title text, not color alone.
class WizardBanner extends StatelessWidget {
  const WizardBanner({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    this.body,
    this.links = const [],
    this.actions = const [],
  });

  final WizardBannerTone tone;
  final IconData icon;
  final String title;
  final String? body;
  final List<WizardBannerLink> links;
  final List<WizardBannerAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = switch (tone) {
      WizardBannerTone.error => theme.colorScheme.onErrorContainer,
      WizardBannerTone.warning => theme.colorScheme.onTertiaryContainer,
      WizardBannerTone.info => theme.colorScheme.onSurface,
      WizardBannerTone.success => theme.colorScheme.onSecondaryContainer,
    };
    final textStyle = theme.textTheme.bodyMedium?.copyWith(color: foreground);
    return PageBanner(
      kind: switch (tone) {
        WizardBannerTone.error => PageBannerKind.alert,
        WizardBannerTone.warning => PageBannerKind.status,
        WizardBannerTone.info => PageBannerKind.neutral,
        WizardBannerTone.success => PageBannerKind.success,
      },
      shape: PageBannerShape.card,
      icon: icon,
      title: title,
      text: body ?? '',
      actions: [
        for (final (index, action) in actions.indexed)
          PageBannerAction(
            action.label,
            action.onPressed,
            key: action.key,
            emphasis: index == 0
                ? PageBannerEmphasis.filled
                : PageBannerEmphasis.outlined,
          ),
      ],
      child: links.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final link in links)
                  _BannerLink(link: link, style: textStyle, color: foreground),
              ],
            ),
    );
  }
}

class _BannerLink extends StatelessWidget {
  const _BannerLink({
    required this.link,
    required this.style,
    required this.color,
  });

  final WizardBannerLink link;
  final TextStyle? style;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: InkWell(
      onTap: link.onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_right_alt, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                link.text,
                style: style?.copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
