import 'package:flutter/material.dart';

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
/// Errors are announced as alerts (live region); the tone is also carried by
/// the icon and the title text, not color alone.
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
    final scheme = theme.colorScheme;
    final (Color background, Color foreground) = switch (tone) {
      WizardBannerTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      WizardBannerTone.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      WizardBannerTone.info => (scheme.surfaceContainer, scheme.onSurface),
      WizardBannerTone.success => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
    };
    final textStyle = theme.textTheme.bodyMedium?.copyWith(color: foreground);
    return Semantics(
      container: true,
      liveRegion: tone == WizardBannerTone.error,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: foreground, fill: 1),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: textStyle?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (body != null) ...[
                          const SizedBox(height: 4),
                          Text(body!, style: textStyle),
                        ],
                        for (final link in links)
                          _BannerLink(
                            link: link,
                            style: textStyle,
                            color: foreground,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (actions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (index, action) in actions.indexed)
                    if (index == 0)
                      FilledButton(
                        key: action.key,
                        style: tone == WizardBannerTone.error
                            ? FilledButton.styleFrom(
                                backgroundColor: scheme.error,
                                foregroundColor: scheme.onError,
                              )
                            : null,
                        onPressed: action.onPressed,
                        child: Text(action.label),
                      )
                    else
                      OutlinedButton(
                        key: action.key,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: foreground,
                          side: BorderSide(color: foreground),
                        ),
                        onPressed: action.onPressed,
                        child: Text(action.label),
                      ),
                ],
              ),
          ],
        ),
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
