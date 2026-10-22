import 'package:flutter/material.dart';

/// One line of text under a field: an icon and a sentence, so no state
/// relies on color alone.
class EditorMessage {
  const EditorMessage(
    this.icon,
    this.text, {
    this.color,
    this.bold = false,
    this.key,
  });

  final IconData icon;
  final String text;

  /// Null uses the muted text color.
  final Color? color;
  final bool bold;
  final Key? key;
}

/// Renders an [EditorMessage].
class EditorMessageLine extends StatelessWidget {
  const EditorMessageLine(this.message, {super.key});

  final EditorMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = message.color ?? theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(message.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message.text,
              key: message.key,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: message.bold ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
