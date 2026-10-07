import 'package:flutter/material.dart';

/// Why the primary action can't run yet, with a way to fix it.
class WizardBlockedReason {
  const WizardBlockedReason({required this.text, this.fixLabel, this.onFix});

  final String text;
  final String? fixLabel;
  final VoidCallback? onFix;
}

/// The bar under the wizard content: Back, and the step's one primary
/// action.
///
/// A blocked primary action stays focusable so keyboard and screen-reader
/// users reach it; it reads as disabled and its [WizardBlockedReason] is
/// shown beside it and linked as its hint.
class WizardFooter extends StatelessWidget {
  const WizardFooter({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.blocked,
    this.showArrow = true,
    this.busy = false,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;

  /// `null` hides Back (the first step).
  final VoidCallback? onBack;

  /// Set while the primary action is unavailable.
  final WizardBlockedReason? blocked;

  final bool showArrow;

  /// While the primary action runs: a spinner, and neither button reacts
  /// (a second press can't submit twice).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final blocked = this.blocked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          if (onBack != null)
            TextButton.icon(
              key: const ValueKey('wizard-back'),
              onPressed: busy ? null : onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (blocked != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, size: 20, color: scheme.error),
                    const SizedBox(width: 6),
                    Text(
                      blocked.text,
                      key: const ValueKey('wizard-blocked-reason'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (blocked.fixLabel != null && blocked.onFix != null)
                  TextButton(
                    onPressed: blocked.onFix,
                    child: Text(blocked.fixLabel!),
                  ),
              ],
              Semantics(
                enabled: blocked == null && !busy,
                hint: blocked?.text,
                liveRegion: busy,
                child: FilledButton(
                  key: const ValueKey('wizard-primary'),
                  style: blocked == null
                      ? null
                      : FilledButton.styleFrom(
                          backgroundColor: scheme.onSurface.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: scheme.onSurface.withValues(
                            alpha: 0.38,
                          ),
                          overlayColor: Colors.transparent,
                          enabledMouseCursor: SystemMouseCursors.forbidden,
                        ),
                  onPressed: blocked == null && !busy ? onPrimary : () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (busy) ...[
                        SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(primaryLabel),
                      if (showArrow) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
