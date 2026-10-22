import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// How urgent a banner is, which sets how assistive technology announces it:
/// by role on the web and as a live region elsewhere.
enum PageBannerKind {
  /// Something is wrong and needs the director's attention (role alert).
  alert(SemanticsRole.alert),

  /// Something the director should know (role status).
  status(SemanticsRole.status);

  const PageBannerKind(this.role);

  final SemanticsRole role;

  /// The semantics to give a banner of this kind. Flutter supports roles only
  /// on the web and does not allow a status or alert role on a live region, so
  /// the web gets the role and every other platform gets a live region.
  @visibleForTesting
  ({SemanticsRole? role, bool liveRegion}) semantics({required bool web}) =>
      web ? (role: role, liveRegion: false) : (role: null, liveRegion: true);
}

/// A banner above a page's content. It adds to the page and never replaces
/// it (use a `PageStateView` for that). An icon and text carry the meaning,
/// not colour alone.
class PageBanner extends StatelessWidget {
  const PageBanner({
    super.key,
    required this.kind,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final PageBannerKind kind;
  final IconData icon;
  final String text;

  /// The label of the banner's one action; no action when `null`.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAlert = kind == PageBannerKind.alert;
    final background = isAlert
        ? scheme.errorContainer
        : scheme.tertiaryContainer;
    final foreground = isAlert
        ? scheme.onErrorContainer
        : scheme.onTertiaryContainer;
    final label = actionLabel;
    final semantics = kind.semantics(web: kIsWeb);
    return Semantics(
      container: true,
      role: semantics.role,
      liveRegion: semantics.liveRegion,
      child: Material(
        color: background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  children: [
                    Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                    if (label != null)
                      TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: foreground,
                        ),
                        child: Text(label),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
