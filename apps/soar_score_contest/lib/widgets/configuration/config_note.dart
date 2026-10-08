import 'package:flutter/material.dart';

/// How a [ConfigNote] looks.
enum ConfigNoteTone {
  /// Plain explanation text.
  info,

  /// A reason in a neutral container: why a setting is fixed or blocked, an
  /// example or a readiness line.
  block,

  /// A validation error.
  error,

  /// Something that happens on save, such as making the matrix out of date.
  warning,
}

/// A line under a setting: a validation error, why a setting is fixed or
/// blocked, the saved value with Undo, an example. It can carry one action.
class ConfigNote extends StatelessWidget {
  const ConfigNote({
    super.key,
    required this.icon,
    required this.text,
    this.tone = ConfigNoteTone.info,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.noteId,
  });

  final IconData icon;
  final String text;
  final ConfigNoteTone tone;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// Set on error notes so a test or a screen reader can find them.
  final Key? noteId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warn = theme.brightness == Brightness.dark
        ? const Color(0xFFFFB870)
        : const Color(0xFF8A5100);
    final (foreground, iconColor) = switch (tone) {
      ConfigNoteTone.error => (scheme.error, scheme.error),
      ConfigNoteTone.warning => (warn, warn),
      ConfigNoteTone.block => (scheme.onSurface, scheme.onSurfaceVariant),
      ConfigNoteTone.info => (scheme.onSurfaceVariant, scheme.onSurfaceVariant),
    };
    final boxed = tone == ConfigNoteTone.block;
    return Semantics(
      container: true,
      liveRegion: tone == ConfigNoteTone.error,
      child: Container(
        key: noteId,
        padding: boxed
            ? const EdgeInsets.fromLTRB(10, 6, 8, 6)
            : EdgeInsets.zero,
        decoration: boxed
            ? BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Icon(icon, size: 20, color: iconColor),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ),
            if (actionLabel != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: theme.textTheme.labelLarge,
                ),
                onPressed: onAction,
                icon: actionIcon == null
                    ? const SizedBox.shrink()
                    : Icon(actionIcon, size: 16),
                label: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
