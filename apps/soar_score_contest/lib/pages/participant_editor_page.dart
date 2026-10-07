import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../router.dart';
import '../widgets/api_error_text.dart';
import '../widgets/message_view.dart';
import '../widgets/unsaved_changes_guard.dart';

/// Creates or edits one reusable participant profile
/// (`plan/ui/contest-administration/participant-data.md`).
///
/// With a null [participantId] the editor creates a profile. Validation is
/// inline and entered values survive a failed save; a possible duplicate by
/// email is shown before a new profile is created, and leaving with unsaved
/// changes asks for confirmation.
///
/// Opened from another flow (the New Contest wizard), [onDone] receives the
/// saved or chosen profile and [onCancel] is called instead of returning to
/// the participant list.
class ParticipantEditorPage extends StatefulWidget {
  const ParticipantEditorPage({
    super.key,
    this.participantId,
    this.guard,
    this.onDone,
    this.onCancel,
  });

  final String? participantId;

  /// Asked by the router before any navigation away from this page.
  final UnsavedChangesGuard? guard;

  /// Called with the saved profile (or the existing one the user chose)
  /// instead of returning to the participant list.
  final ValueChanged<ParticipantProfile>? onDone;

  /// Called instead of returning to the participant list when the user
  /// cancels.
  final VoidCallback? onCancel;

  @override
  State<ParticipantEditorPage> createState() => _ParticipantEditorPageState();
}

class _ParticipantEditorPageState extends State<ParticipantEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _club = TextEditingController();
  final _faiNumber = TextEditingController();
  final _nationalOrgId = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController();

  late final List<TextEditingController> _controllers = [
    _firstName,
    _lastName,
    _email,
    _club,
    _faiNumber,
    _nationalOrgId,
    _city,
    _state,
    _country,
  ];

  /// The profile being edited, or the existing profile whose email matched a
  /// new one (see [_match]).
  ParticipantProfile? _loaded;
  ParticipantProfile? _match;
  Future<void>? _loading;
  bool _dirty = false;
  bool _saving = false;
  bool _separateConfirmed = false;
  String? _saveError;

  bool get _creating => widget.participantId == null;

  @override
  void initState() {
    super.initState();
    widget.guard?.attach(_confirmDiscard);
    for (final controller in _controllers) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= _load();
  }

  @override
  void dispose() {
    widget.guard?.detach(_confirmDiscard);
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  Future<void> _load() async {
    final client = apiClientOf(context);
    if (client == null) {
      throw StateError('No API client is available.');
    }
    if (_creating) {
      return;
    }
    final profile = await client.participant(Id.parse(widget.participantId!));
    _loaded = profile;
    _firstName.text = profile.firstName;
    _lastName.text = profile.lastName;
    _email.text = profile.email ?? '';
    _club.text = profile.club ?? '';
    _faiNumber.text = profile.faiNumber ?? '';
    _nationalOrgId.text = profile.nationalOrgId ?? '';
    _city.text = profile.city ?? '';
    _state.text = profile.state ?? '';
    _country.text = profile.country ?? '';
    _dirty = false;
  }

  String? _optional(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<ParticipantProfile?> _findByEmail(ApiClient client) async {
    final email = _email.text.trim().toLowerCase();
    final profiles = await client.participants();
    for (final profile in profiles) {
      if (profile.email?.toLowerCase() == email) {
        return profile;
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final client = apiClientOf(context)!;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final ParticipantProfile saved;
    try {
      if (_creating) {
        if (!_separateConfirmed) {
          final match = await _findByEmail(client);
          if (match != null) {
            setState(() {
              _match = match;
              _saving = false;
            });
            return;
          }
        }
        saved = await client.createParticipant(
          CreateParticipantRequest(
            id: Id.create(),
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            club: _optional(_club),
            faiNumber: _optional(_faiNumber),
            nationalOrgId: _optional(_nationalOrgId),
            city: _optional(_city),
            state: _optional(_state),
            country: _optional(_country),
          ),
        );
      } else {
        saved = await client.updateParticipant(
          _loaded!.id,
          UpdateParticipantRequest(
            baseRevision: _loaded!.revision,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            club: _optional(_club),
            faiNumber: _optional(_faiNumber),
            nationalOrgId: _optional(_nationalOrgId),
            city: _optional(_city),
            state: _optional(_state),
            country: _optional(_country),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = apiErrorText(error);
        });
      }
      return;
    }
    if (mounted) {
      _dirty = false;
      _leave(saved);
    }
  }

  /// Returns to where the editor was opened from, with [profile] when one
  /// was saved or chosen.
  void _leave([ParticipantProfile? profile]) {
    final onDone = widget.onDone;
    final onCancel = widget.onCancel;
    if (profile != null && onDone != null) {
      onDone(profile);
    } else if (profile == null && onCancel != null) {
      onCancel();
    } else {
      context.go(participantsPath);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) {
      return true;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _cancel() async {
    if (await _confirmDiscard() && mounted) {
      _dirty = false;
      _leave();
    }
  }

  static String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  static String? _emailRule(String? value) {
    final required = _required(value, 'Email');
    if (required != null) {
      return required;
    }
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
        ? null
        : 'Enter a valid email address.';
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Key? key,
  }) => TextFormField(
    key: key,
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MessageView(
          text: 'The participant could not be loaded.',
          detail: apiErrorText(snapshot.error!),
          onRetry: () => setState(() => _loading = _load()),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      return PopScope(
        canPop: !_dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) {
            return;
          }
          if (await _confirmDiscard() && context.mounted) {
            _dirty = false;
            _leave();
          }
        },
        child: _form(context),
      );
    },
  );

  Widget _form(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _creating ? 'Add participant' : 'Edit participant',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (_saveError != null) ...[
                Text(
                  _saveError!,
                  key: const ValueKey('save-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              if (_match != null) ...[
                _matchNotice(context),
                const SizedBox(height: 12),
              ],
              _field(
                'First name',
                _firstName,
                key: const ValueKey('first-name'),
                validator: (v) => _required(v, 'First name'),
              ),
              _field(
                'Last name',
                _lastName,
                key: const ValueKey('last-name'),
                validator: (v) => _required(v, 'Last name'),
              ),
              _field(
                'Email (private, used for matching only)',
                _email,
                key: const ValueKey('email'),
                keyboardType: TextInputType.emailAddress,
                validator: _emailRule,
              ),
              _field('Club', _club),
              _field('FAI number', _faiNumber),
              _field('National organization ID', _nationalOrgId),
              _field('City', _city),
              _field('State/province', _state),
              _field('Country', _country),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton(
                    key: const ValueKey('save-participant'),
                    onPressed: _saving ? null : _save,
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    key: const ValueKey('cancel-participant'),
                    onPressed: _saving ? null : _cancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _matchNotice(BuildContext context) {
    final match = _match!;
    return Card(
      key: const ValueKey('duplicate-notice'),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${match.firstName} ${match.lastName} already uses this email '
              'address.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: const ValueKey('use-existing'),
                  onPressed: () {
                    _dirty = false;
                    if (widget.onDone != null) {
                      widget.onDone!(match);
                    } else {
                      context.go(participantPath(match.id.value));
                    }
                  },
                  child: const Text('Use existing participant'),
                ),
                OutlinedButton(
                  key: const ValueKey('create-separate'),
                  onPressed: () {
                    setState(() {
                      _separateConfirmed = true;
                      _match = null;
                    });
                    _save();
                  },
                  child: const Text('Create a separate participant'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
