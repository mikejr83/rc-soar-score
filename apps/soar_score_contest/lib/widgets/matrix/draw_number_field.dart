import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'matrix_colors.dart';

/// A whole-number field of the draw form with its source note, an "Edited"
/// marker, a reset to the configured value and a link to Configuration.
/// Errors and warnings use an icon and text, never colour alone.
class DrawNumberField extends StatelessWidget {
  const DrawNumberField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.note,
    this.error,
    this.warning,
    this.edited = false,
    this.resetLabel,
    this.onReset,
    this.onOpenConfiguration,
    this.hint,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;

  /// The source line shown when there is no error or warning.
  final String note;
  final String? error;
  final String? warning;
  final bool edited;
  final String? resetLabel;
  final VoidCallback? onReset;
  final VoidCallback? onOpenConfiguration;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = MatrixColors.of(context);
    final message = error ?? warning ?? note;
    final (icon, color) = error != null
        ? (Icons.error_outline, scheme.error)
        : warning != null
        ? (Icons.warning_amber, colors.warn)
        : (
            edited ? Icons.edit_note : Icons.settings_outlined,
            scheme.onSurfaceVariant,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            enabledBorder: _border(
              error != null,
              warning != null,
              scheme,
              colors,
            ),
            focusedBorder: _border(
              error != null,
              warning != null,
              scheme,
              colors,
              2,
            ),
            suffixIcon: edited
                ? const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Chip(
                      avatar: Icon(Icons.edit, size: 14),
                      label: Text('Edited'),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  message,
                  key: ValueKey('${(fieldKey as ValueKey).value}-message'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: error != null
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          children: [
            TextButton.icon(
              onPressed: onOpenConfiguration,
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Open Configuration'),
            ),
            if (edited && onReset != null)
              TextButton.icon(
                key: ValueKey('${(fieldKey as ValueKey).value}-reset'),
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt, size: 16),
                label: Text(resetLabel ?? 'Reset'),
              ),
          ],
        ),
      ],
    );
  }

  InputBorder _border(
    bool hasError,
    bool hasWarning,
    ColorScheme scheme,
    MatrixColors colors, [
    double width = 1,
  ]) {
    if (hasError) {
      return OutlineInputBorder(
        borderSide: BorderSide(color: scheme.error, width: 2),
      );
    }
    if (hasWarning) {
      return OutlineInputBorder(
        borderSide: BorderSide(color: colors.warn, width: 2),
      );
    }
    return OutlineInputBorder(
      borderSide: BorderSide(color: scheme.outline, width: width),
    );
  }
}
