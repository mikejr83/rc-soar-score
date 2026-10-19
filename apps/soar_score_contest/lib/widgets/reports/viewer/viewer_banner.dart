import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

/// Which colours a [ViewerBanner] takes from the theme. Each kind also has its
/// own icon and a bold lead word, so none relies on colour.
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
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (background, foreground) = switch (kind) {
      ViewerBannerKind.official => (
        AppStatusColors.getSuccessContainer(dark),
        AppStatusColors.getOnSuccessContainer(dark),
      ),
      ViewerBannerKind.preliminary => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      ViewerBannerKind.info => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      ViewerBannerKind.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      ViewerBannerKind.neutral => (scheme.surfaceContainer, scheme.onSurface),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      child: ColoredBox(
        color: background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foreground),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(icon, color: foreground),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 200,
                    maxWidth: 760,
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: lead,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(text: ' $text'),
                      ],
                    ),
                  ),
                ),
                for (final action in actions)
                  Theme(
                    data: Theme.of(context).copyWith(
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: foreground,
                        ),
                      ),
                      outlinedButtonTheme: OutlinedButtonThemeData(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: foreground,
                          side: BorderSide(color: foreground),
                        ),
                      ),
                    ),
                    child: action,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
