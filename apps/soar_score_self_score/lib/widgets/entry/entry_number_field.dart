import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

/// A labelled numeric entry: large right-aligned tabular figures, with a hint
/// that turns into the error text when the value is rejected.
class EntryNumberField extends StatelessWidget {
  const EntryNumberField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    this.allowDecimal = false,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final bool enabled;
  final bool allowDecimal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          textAlign: TextAlign.right,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          style: BrandTypography.numbers.copyWith(fontSize: 24, height: 1.3),
          decoration: InputDecoration(
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BrandTheme.buttonRadius),
            ),
            semanticCounterText: label,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorText != null) ...[
              Icon(
                Icons.error_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                errorText ?? hint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: errorText != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
