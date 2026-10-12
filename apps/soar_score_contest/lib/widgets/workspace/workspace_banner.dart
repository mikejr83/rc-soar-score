import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// How urgent a banner is, which sets its role for assistive technology.
enum WorkspaceBannerKind {
  /// Something is wrong and needs the director's attention (role alert).
  alert(SemanticsRole.alert),

  /// Something the director should know (role status).
  status(SemanticsRole.status);

  const WorkspaceBannerKind(this.role);

  final SemanticsRole role;
}

/// A banner above the workspace sections. It adds to the page and never
/// replaces it. An icon and text carry the meaning, not colour alone.
class WorkspaceBanner extends StatelessWidget {
  const WorkspaceBanner({
    super.key,
    required this.kind,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final WorkspaceBannerKind kind;
  final IconData icon;
  final String text;

  /// The label of the banner's one action; no action when `null`.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAlert = kind == WorkspaceBannerKind.alert;
    final background = isAlert
        ? scheme.errorContainer
        : scheme.tertiaryContainer;
    final foreground = isAlert
        ? scheme.onErrorContainer
        : scheme.onTertiaryContainer;
    final label = actionLabel;
    return Semantics(
      container: true,
      role: kind.role,
      // The alert and status roles are live regions already, and cannot be
      // combined with the flag.
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
