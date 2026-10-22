import 'package:flutter/material.dart';

import 'editor_message.dart';

/// A text field with its label above it (so long labels wrap at large text
/// sizes) and icon-and-sentence messages below.
///
/// [fieldKey] goes on the underlying [TextField], so tests and journeys can
/// enter text by key.
class EditorTextField extends StatelessWidget {
  const EditorTextField({
    required this.label,
    required this.controller,
    required this.focusNode,
    this.fieldKey,
    this.messages = const [],
    this.hasError = false,
    this.required = false,
    this.readOnly = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.autocorrect = true,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Key? fieldKey;
  final List<EditorMessage> messages;
  final bool hasError;
  final bool required;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final edge = hasError ? scheme.error : scheme.outline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text.rich(
            TextSpan(
              text: label,
              children: [if (required) const TextSpan(text: ' *')],
            ),
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: hasError ? scheme.error : scheme.onSurface),
          ),
        ),
        Semantics(
          label: required ? '$label, required' : label,
          child: TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            readOnly: readOnly,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            autofillHints: autofillHints,
            autocorrect: autocorrect,
            enableSuggestions: autocorrect,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              filled: readOnly,
              fillColor: readOnly ? scheme.surfaceContainerHigh : null,
              suffixIcon: readOnly ? const Icon(Icons.lock_outline) : null,
              border: _border(scheme.outline, 1),
              enabledBorder: _border(edge, hasError ? 2 : 1),
              focusedBorder: _border(
                hasError ? scheme.error : scheme.primary,
                2,
              ),
            ),
          ),
        ),
        for (final message in messages) EditorMessageLine(message),
      ],
    );
  }

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color, width: width),
      );
}
