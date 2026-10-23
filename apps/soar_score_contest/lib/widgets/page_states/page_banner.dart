import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

/// How urgent a banner is, which sets how assistive technology announces it:
/// by role on the web and as a live region elsewhere.
enum PageBannerKind {
  /// Something is wrong and needs the director's attention (role alert).
  alert(SemanticsRole.alert),

  /// Something the director should know (role status).
  status(SemanticsRole.status),

  /// Explains what the page is doing or why (role status).
  info(SemanticsRole.status),

  /// A quiet note that is not about anything wrong (role status).
  neutral(SemanticsRole.status),

  /// Something went through (role status).
  success(SemanticsRole.status),

  /// Something is settled and good, in the status colours (role status).
  positive(SemanticsRole.status);

  const PageBannerKind(this.role);

  final SemanticsRole role;

  /// The semantics to give a banner of this kind. Flutter supports roles only
  /// on the web and does not allow a status or alert role on a live region, so
  /// the web gets the role and every other platform gets a live region.
  @visibleForTesting
  ({SemanticsRole? role, bool liveRegion}) semantics({required bool web}) =>
      web ? (role: role, liveRegion: false) : (role: null, liveRegion: true);
}

/// Whether a banner is a full-width band above a page or a rounded card
/// inside its content.
enum PageBannerShape { band, card }

/// How strongly a [PageBannerAction] is drawn.
enum PageBannerEmphasis { text, outlined, filled }

/// A button in a [PageBanner].
class PageBannerAction {
  const PageBannerAction(
    this.label,
    this.onPressed, {
    this.emphasis = PageBannerEmphasis.text,
    this.key,
    this.icon,
    this.focusOrder,
  });

  final String label;
  final VoidCallback? onPressed;
  final PageBannerEmphasis emphasis;
  final Key? key;

  /// An icon before the label.
  final IconData? icon;

  /// Where the button sits in the Tab order of the enclosing group, when it
  /// must not follow the layout order.
  final double? focusOrder;
}

/// A banner above a page's content. It adds to the page and never replaces
/// it (use a `PageStateView` for that). An icon and text carry the meaning,
/// not colour alone.
///
/// This is the one banner layout of the contest app: an icon, an optional
/// bold [title], the [text], an optional [child] (such as links) and any
/// number of buttons. Page-specific banners wrap it with their own copy and
/// keys rather than drawing their own.
class PageBanner extends StatelessWidget {
  const PageBanner({
    super.key,
    required this.kind,
    required this.icon,
    required this.text,
    this.title,
    this.lead,
    this.shape = PageBannerShape.band,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.actions = const [],
    this.child,
    this.textKey,
  });

  final PageBannerKind kind;
  final IconData icon;
  final String text;

  /// A bold line above [text]; none when `null`.
  final String? title;

  /// A bold word or phrase that starts [text] on the same line.
  final String? lead;
  final PageBannerShape shape;

  /// The label of the banner's one action; no action when `null`.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A second, quieter action (such as `Dismiss`); none when `null`.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// More buttons, after the two above, for the pages that need them.
  final List<PageBannerAction> actions;

  /// Content under the text, such as links to fields.
  final Widget? child;

  /// Key of the banner's text, for tests that read the message.
  final Key? textKey;

  (Color, Color) _colors(
    ColorScheme scheme, {
    required bool dark,
  }) => switch (kind) {
    PageBannerKind.alert => (scheme.errorContainer, scheme.onErrorContainer),
    PageBannerKind.status => (
      scheme.tertiaryContainer,
      scheme.onTertiaryContainer,
    ),
    PageBannerKind.info => (scheme.primaryContainer, scheme.onPrimaryContainer),
    PageBannerKind.neutral => (scheme.surfaceContainer, scheme.onSurface),
    PageBannerKind.success => (
      scheme.secondaryContainer,
      scheme.onSecondaryContainer,
    ),
    PageBannerKind.positive => (
      AppStatusColors.getSuccessContainer(dark),
      AppStatusColors.getOnSuccessContainer(dark),
    ),
  };

  Widget _button(
    PageBannerAction action,
    ColorScheme scheme,
    Color foreground,
  ) {
    final label = Text(action.label);
    final icon = action.icon == null ? null : Icon(action.icon, size: 18);
    final button = switch (action.emphasis) {
      PageBannerEmphasis.text =>
        icon == null
            ? TextButton(
                key: action.key,
                onPressed: action.onPressed,
                style: TextButton.styleFrom(foregroundColor: foreground),
                child: label,
              )
            : TextButton.icon(
                key: action.key,
                onPressed: action.onPressed,
                style: TextButton.styleFrom(foregroundColor: foreground),
                icon: icon,
                label: label,
              ),
      PageBannerEmphasis.outlined =>
        icon == null
            ? OutlinedButton(
                key: action.key,
                onPressed: action.onPressed,
                style: _outlined(foreground),
                child: label,
              )
            : OutlinedButton.icon(
                key: action.key,
                onPressed: action.onPressed,
                style: _outlined(foreground),
                icon: icon,
                label: label,
              ),
      PageBannerEmphasis.filled =>
        icon == null
            ? FilledButton(
                key: action.key,
                onPressed: action.onPressed,
                style: _filled(scheme),
                child: label,
              )
            : FilledButton.icon(
                key: action.key,
                onPressed: action.onPressed,
                style: _filled(scheme),
                icon: icon,
                label: label,
              ),
    };
    final order = action.focusOrder;
    return order == null
        ? button
        : FocusTraversalOrder(order: NumericFocusOrder(order), child: button);
  }

  ButtonStyle _outlined(Color foreground) => OutlinedButton.styleFrom(
    foregroundColor: foreground,
    side: BorderSide(color: foreground),
  );

  ButtonStyle? _filled(ColorScheme scheme) => kind == PageBannerKind.alert
      ? FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
        )
      : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = _colors(
      scheme,
      dark: theme.brightness == Brightness.dark,
    );
    final textStyle = theme.textTheme.bodyMedium?.copyWith(color: foreground);
    final label = actionLabel;
    final secondary = secondaryLabel;
    final semantics = kind.semantics(web: kIsWeb);
    final card = shape == PageBannerShape.card;
    final buttons = [
      if (label != null) PageBannerAction(label, onAction),
      if (secondary != null) PageBannerAction(secondary, onSecondary),
      ...actions,
    ];
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: card ? 14 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: textStyle?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    if (lead != null)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: lead,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(text: ' $text'),
                          ],
                        ),
                        key: textKey,
                        style: textStyle,
                      )
                    else if (text.isNotEmpty)
                      Text(text, key: textKey, style: textStyle),
                    ?child,
                  ],
                ),
                for (final action in buttons)
                  _button(action, scheme, foreground),
              ],
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      role: semantics.role,
      liveRegion: semantics.liveRegion,
      child: Material(
        color: background,
        shape: card
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            : null,
        child: content,
      ),
    );
  }
}
