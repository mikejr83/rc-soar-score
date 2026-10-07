import 'package:flutter/material.dart';

/// A line in a [showWizardConfirmDialog] list.
class WizardConfirmItem {
  const WizardConfirmItem(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// A Material 3 confirmation for a destructive wizard action (changing the
/// discipline, turning teams off, leaving with unsaved changes). Returns
/// whether the user confirmed.
Future<bool> showWizardConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String cancelLabel,
  required String confirmLabel,
  String? body,
  List<WizardConfirmItem> items = const [],
  String? footnote,
  String? warning,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final muted = theme.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      );
      return AlertDialog(
        icon: Icon(icon),
        title: Text(title),
        content: SizedBox(
          width: 392,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (body != null) Text(body, style: muted),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, size: 20, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.text,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              if (footnote != null) ...[
                const SizedBox(height: 16),
                Text(footnote, style: muted),
              ],
              if (warning != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 20,
                        color: scheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
