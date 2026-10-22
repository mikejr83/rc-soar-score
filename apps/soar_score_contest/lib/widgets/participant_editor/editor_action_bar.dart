import 'package:flutter/material.dart';

/// The line of status text in the action bar ("Unsaved changes").
class EditorBarStatus {
  const EditorBarStatus(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// The bar pinned to the bottom of the editor: status on the left, Cancel,
/// Save and add another, and Save on the right. On a phone the status takes
/// its own line and the buttons share the width.
class EditorActionBar extends StatelessWidget {
  const EditorActionBar({
    required this.saveLabel,
    required this.saving,
    required this.saveEnabled,
    required this.onSave,
    required this.onCancel,
    this.status,
    this.compact = false,
    this.anotherEnabled = true,
    this.onSaveAnother,
    super.key,
  });

  final String saveLabel;
  final bool saving;
  final bool saveEnabled;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final EditorBarStatus? status;
  final bool compact;

  /// Whether "Save and add another" can be used now.
  final bool anotherEnabled;

  /// Null hides "Save and add another" (edit mode).
  final VoidCallback? onSaveAnother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusLine = status == null
        ? null
        : Semantics(
            liveRegion: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(status!.icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    status!.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
    final cancel = TextButton(
      key: const ValueKey('cancel-participant'),
      onPressed: saving ? null : onCancel,
      child: const Text('Cancel'),
    );
    final another = onSaveAnother == null
        ? null
        : OutlinedButton(
            key: const ValueKey('save-add-another'),
            onPressed: saving || !anotherEnabled ? null : onSaveAnother,
            child: const Text('Save and add another'),
          );
    final save = FilledButton(
      key: const ValueKey('save-participant'),
      onPressed: saveEnabled && !saving ? onSave : null,
      child: saving
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(saveLabel),
              ],
            )
          : Text(saveLabel),
    );
    return Material(
      color: scheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 32,
            vertical: 12,
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?statusLine,
                    if (statusLine != null) const SizedBox(height: 8),
                    Row(
                      children: [
                        cancel,
                        const SizedBox(width: 8),
                        if (another != null) ...[
                          Expanded(child: another),
                          const SizedBox(width: 8),
                        ],
                        Expanded(child: save),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: statusLine ?? const SizedBox.shrink(),
                      ),
                    ),
                    cancel,
                    if (another != null) ...[const SizedBox(width: 8), another],
                    const SizedBox(width: 8),
                    save,
                  ],
                ),
        ),
      ),
    );
  }
}
