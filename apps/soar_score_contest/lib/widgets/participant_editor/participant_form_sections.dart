import 'package:flutter/material.dart';

import '../../services/participants/participant_editor_controller.dart';
import '../../services/participants/participant_field.dart';
import 'country_field.dart';
import 'editor_message.dart';
import 'editor_section_card.dart';
import 'editor_text_field.dart';
import 'participant_field_spec.dart';

/// The three section cards with every field, wired to the editor
/// [controller] through the page's text controllers and focus nodes.
class ParticipantFormSections extends StatelessWidget {
  const ParticipantFormSections({
    required this.controller,
    required this.texts,
    required this.focus,
    required this.stacked,
    required this.onSubmit,
    super.key,
  });

  final ParticipantEditorController controller;
  final Map<ParticipantField, TextEditingController> texts;
  final Map<ParticipantField, FocusNode> focus;

  /// One field per row and no cards (phones, large text).
  final bool stacked;

  /// Enter pressed in the last field.
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final section in ParticipantSection.values) ...[
        EditorSectionCard(
          title: section.title,
          optional: section != ParticipantSection.contact,
          plain: stacked,
          child: _fields(context, section),
        ),
        const SizedBox(height: 20),
      ],
    ],
  );

  Widget _fields(BuildContext context, ParticipantSection section) {
    final rows = [
      for (final row in participantFieldRows)
        if (section.fields.contains(row.first)) row,
    ];
    return Column(
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: 16),
          if (stacked || row.length == 1)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (j, field) in row.indexed) ...[
                  if (j > 0) const SizedBox(height: 16),
                  _field(context, field),
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (j, field) in row.indexed) ...[
                  if (j > 0) const SizedBox(width: 16),
                  Expanded(child: _field(context, field)),
                ],
              ],
            ),
        ],
      ],
    );
  }

  ParticipantField get _last => ParticipantField.values.lastWhere(
    (f) => !controller.managedFields.contains(f),
  );

  Widget _field(BuildContext context, ParticipantField field) {
    final spec = ParticipantFieldSpec.of(field);
    final readOnly = controller.managedFields.contains(field);
    final error = controller.visibleError(field);
    final messages = _messages(context, field, spec, error, readOnly);
    final isLast = field == _last;
    void submitted(String _) {
      if (isLast) {
        onSubmit();
        return;
      }
      final editable = ParticipantField.values
          .where((f) => !controller.managedFields.contains(f))
          .toList();
      focus[editable[editable.indexOf(field) + 1]]?.requestFocus();
    }

    if (field == ParticipantField.country) {
      return CountryField(
        controller: texts[field]!,
        focusNode: focus[field]!,
        fieldKey: ValueKey(spec.key),
        readOnly: readOnly,
        messages: messages,
        onSubmitted: submitted,
      );
    }
    return EditorTextField(
      label: field.label,
      controller: texts[field]!,
      focusNode: focus[field]!,
      fieldKey: ValueKey(spec.key),
      messages: messages,
      hasError: error != null,
      required: field.required,
      readOnly: readOnly,
      keyboardType: spec.keyboard,
      textCapitalization: spec.capitalization,
      autofillHints: spec.autofill == null ? null : [spec.autofill!],
      autocorrect: spec.autocorrect,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onSubmitted: submitted,
    );
  }

  List<EditorMessage> _messages(
    BuildContext context,
    ParticipantField field,
    ParticipantFieldSpec spec,
    String? error,
    bool readOnly,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final warning = dark ? const Color(0xFFFFB870) : const Color(0xFF8A5100);
    final isEmail = field == ParticipantField.email;
    return [
      if (error != null)
        EditorMessage(Icons.error, error, color: scheme.error, bold: true),
      if (readOnly)
        const EditorMessage(
          Icons.lock_outline,
          'Managed by the participant. Only they can change it from their '
          'account.',
        ),
      if (isEmail)
        const EditorMessage(
          Icons.lock_outline,
          'Private. Only used to match this person to an existing record.',
        )
      else if (spec.help != null)
        EditorMessage(Icons.info_outline, spec.help!),
      if (isEmail && controller.missingEmail && error == null)
        EditorMessage(
          Icons.mail_outline,
          'No email on file. Add an email to save.',
          color: warning,
          bold: true,
        ),
      if (isEmail && controller.creating && error == null)
        ..._emailCheck(scheme),
    ];
  }

  List<EditorMessage> _emailCheck(ColorScheme scheme) =>
      switch (controller.emailCheck) {
        EmailCheck.none => const [],
        EmailCheck.checking => const [
          EditorMessage(
            Icons.manage_search,
            'Checking for an existing participant…',
          ),
        ],
        EmailCheck.found => [
          EditorMessage(
            Icons.person_search,
            'A participant with this email already exists. Use that '
            'participant or enter a different email.',
            color: scheme.onSecondaryContainer,
            bold: true,
          ),
        ],
        EmailCheck.clear => [
          EditorMessage(
            Icons.check_circle_outline,
            'No existing participant uses this email.',
            color: scheme.secondary,
          ),
        ],
        EmailCheck.localOnly => const [
          EditorMessage(
            Icons.cloud_off_outlined,
            'Couldn’t check for matches online. Checked this device only.',
          ),
        ],
      };
}
