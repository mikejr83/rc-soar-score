import 'package:flutter/material.dart';

/// A note under a setting: a warning, an error or an explanation.
class SettingNote {
  const SettingNote.info(this.icon, this.title, [this.text])
    : tone = SettingNoteTone.info;
  const SettingNote.warning(this.icon, this.title, [this.text])
    : tone = SettingNoteTone.warning;
  const SettingNote.error(this.icon, this.title, [this.text])
    : tone = SettingNoteTone.error;

  final SettingNoteTone tone;
  final IconData icon;
  final String title;
  final String? text;
}

enum SettingNoteTone { info, warning, error }

/// One setting in a wizard card: its label and description, whether it is
/// the discipline default (with Reset when changed), its control, and any
/// notes.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    required this.description,
    required this.control,
    this.defaultLabel,
    this.changedFrom,
    this.onReset,
    this.hint,
    this.below,
    this.notes = const [],
    this.enabled = true,
  });

  final String label;
  final String description;

  /// The control, on the trailing side (or below on narrow cards).
  final Widget control;

  /// `F5J default`, shown while the value is the default.
  final String? defaultLabel;

  /// `Changed from Normalized`, shown (with Reset) once changed.
  final String? changedFrom;
  final VoidCallback? onReset;

  /// A short line under the control (for example a live example).
  final String? hint;

  /// A full-width control under the label (radio lists).
  final Widget? below;

  final List<SettingNote> notes;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final disabled = scheme.onSurface.withValues(alpha: 0.38);
    final small = theme.textTheme.bodySmall?.copyWith(color: muted);
    final changed = changedFrom != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: enabled ? null : disabled,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: enabled ? muted : disabled,
                      ),
                    ),
                    if (defaultLabel != null || changed)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 32),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Icon(
                              changed ? Icons.edit_outlined : Icons.verified,
                              size: 16,
                              color: muted,
                            ),
                            Text(
                              changed ? changedFrom! : defaultLabel!,
                              style: small,
                            ),
                            if (changed && onReset != null)
                              TextButton(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  textStyle: theme.textTheme.labelMedium,
                                ),
                                onPressed: onReset,
                                child: const Text('Reset to default'),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  control,
                  if (hint != null) ...[
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        hint!,
                        textAlign: TextAlign.end,
                        style: small,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (below != null) ...[const SizedBox(height: 4), below!],
          for (final note in notes) ...[
            const SizedBox(height: 12),
            _Note(note: note),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.note});

  final SettingNote note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (note.tone) {
      SettingNoteTone.info => (scheme.surfaceContainer, scheme.onSurface),
      SettingNoteTone.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      SettingNoteTone.error => (scheme.errorContainer, scheme.onErrorContainer),
    };
    final style = theme.textTheme.bodyMedium?.copyWith(color: foreground);
    return Semantics(
      container: true,
      liveRegion: note.tone == SettingNoteTone.error,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(note.icon, size: 20, color: foreground, fill: 1),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: style?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (note.text != null) Text(note.text!, style: style),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
