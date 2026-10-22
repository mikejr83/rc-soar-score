import 'package:flutter/material.dart';

import '../../services/participants/participant_countries.dart';
import 'editor_message.dart';
import 'editor_text_field.dart';

/// The Country field: type-ahead over [participantCountries] that still
/// accepts any text.
class CountryField extends StatelessWidget {
  const CountryField({
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    required this.readOnly,
    this.messages = const [],
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Key fieldKey;
  final bool readOnly;
  final List<EditorMessage> messages;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => RawAutocomplete<String>(
    textEditingController: controller,
    focusNode: focusNode,
    optionsBuilder: (value) {
      final typed = value.text.trim().toLowerCase();
      if (readOnly || typed.isEmpty) {
        return const Iterable<String>.empty();
      }
      return participantCountries.where(
        (country) => country.toLowerCase().contains(typed),
      );
    },
    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
        EditorTextField(
          label: 'Country',
          controller: controller,
          focusNode: focusNode,
          fieldKey: fieldKey,
          readOnly: readOnly,
          messages: messages,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.countryName],
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            onFieldSubmitted();
            onSubmitted?.call(value);
          },
        ),
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              for (final option in options)
                ListTile(
                  dense: true,
                  title: Text(option),
                  onTap: () => onSelected(option),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
