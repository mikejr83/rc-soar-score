import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Edits a reusable participant (pilot) profile.
///
/// Presented as a bottom sheet from the participants page (or the
/// new-contest wizard). It supports both adding a new participant (when
/// [pilot] is null) and editing an existing one.
///
/// Per the participant editor requirements:
/// * Required fields are first name, last name, and email; the rest are
///   optional (club, FAI number, national organization ID, city,
///   state/province, country).
/// * Email is always marked private and is never shown in public views.
/// * Validation is inline and entered values are preserved after a failed
///   save.
/// * Unsaved changes require confirmation before leaving.
class ParticipantEditor extends StatefulWidget {
  const ParticipantEditor({
    super.key,
    required this.pilot,
    required this.onSave,
  });

  /// The participant being edited, or `null` when adding a new one.
  final Pilot? pilot;

  /// Called with the resulting [Pilot] after a successful save.
  final Future<void> Function(Pilot pilot) onSave;

  @override
  State<ParticipantEditor> createState() => _ParticipantEditorState();
}

class _ParticipantEditorState extends State<ParticipantEditor> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _listController = ScrollController();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _club;
  late final TextEditingController _faiNumber;
  late final TextEditingController _nationalOrgId;
  late final TextEditingController _city;
  late final TextEditingController _stateProvince;
  late final TextEditingController _country;

  final Set<String> _errors = <String>{};
  bool _saving = false;

  /// Whether the current field values differ from the values the editor was
  /// opened with.
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final pilot = widget.pilot;
    _firstName = TextEditingController(text: pilot?.firstName ?? '');
    _lastName = TextEditingController(text: pilot?.lastName ?? '');
    _email = TextEditingController(text: pilot?.email ?? '');
    _club = TextEditingController(text: pilot?.club ?? '');
    _faiNumber = TextEditingController(text: pilot?.faiNumber ?? '');
    _nationalOrgId = TextEditingController(text: pilot?.nationalOrgId ?? '');
    _city = TextEditingController(text: pilot?.city ?? '');
    _stateProvince = TextEditingController(text: pilot?.stateProvince ?? '');
    _country = TextEditingController(text: pilot?.country ?? '');
    final controllers = <TextEditingController>[
      _firstName,
      _lastName,
      _email,
      _club,
      _faiNumber,
      _nationalOrgId,
      _city,
      _stateProvince,
      _country,
    ];
    for (final c in controllers) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() {
    if (mounted) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _listController.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _club.dispose();
    _faiNumber.dispose();
    _nationalOrgId.dispose();
    _city.dispose();
    _stateProvince.dispose();
    _country.dispose();
    super.dispose();
  }

  String get _title => widget.pilot == null ? 'Add participant' : 'Edit participant';

  bool _validate() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return false;
    }
    _errors
      ..clear()
      ..addAll(_collectErrors());
    if (mounted) setState(() {});
    return _errors.isEmpty;
  }

  /// Collects any cross-field validation problems (e.g. duplicate email).
  Set<String> _collectErrors() => <String>{};

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);

    final pilot = Pilot(
      id: widget.pilot?.id ?? _generateId(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      club: _optional(_club),
      faiNumber: _optional(_faiNumber),
      nationalOrgId: _optional(_nationalOrgId),
      city: _optional(_city),
      stateProvince: _optional(_stateProvince),
      country: _optional(_country),
    );

    try {
      await widget.onSave(pilot);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Asks the user to confirm discarding unsaved changes before popping.
  Future<void> _confirmDiscard() async {
    if (!_isDirty || _saving) {
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. If you leave now they will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  static String? _optional(TextEditingController c) {
    final value = c.text.trim();
    return value.isEmpty ? null : value;
  }

  static String _generateId() =>
      'pilot-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The sheet is sized to a fixed height derived from the route so that
    // the internal scroll region is well defined and the form fields never
    // overflow the container.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SizedBox(
      height: maxHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Drag handle.
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: _confirmDiscard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: _listController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    children: [
                      _field(
                        controller: _firstName,
                        label: 'First name',
                        required: true,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      _field(
                        controller: _lastName,
                        label: 'Last name',
                        required: true,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      _field(
                        controller: _email,
                        label: 'Email (private)',
                        required: true,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Required';
                          final ok =
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                          return ok ? null : 'Enter a valid email address';
                        },
                      ),
                      const SizedBox(height: 4),
                      // Cross-field validation message (e.g. duplicate email).
                      if (_errors.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber,
                                  size: 18, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errors.join(' '),
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                    _field(controller: _club, label: 'Club', required: false),
                    _field(
                        controller: _faiNumber,
                        label: 'FAI number',
                        required: false),
                    _field(
                        controller: _nationalOrgId,
                        label: 'National org ID',
                        required: false),
                    _field(controller: _city, label: 'City', required: false),
                    _field(
                        controller: _stateProvince,
                        label: 'State / province',
                        required: false),
                    _field(controller: _country, label: 'Country', required: false),
                  ],
                ),
              ),
            ),
            const Divider(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _confirmDiscard,
                        child: const Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool required,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}