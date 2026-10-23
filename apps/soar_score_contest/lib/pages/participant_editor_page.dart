import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../widgets/contest_scope.dart';
import '../api_client_provider.dart';
import '../app_sync_provider.dart';
import '../router.dart';
import '../services/participants/participant_editor_controller.dart';
import '../services/participants/participant_field.dart';
import '../services/participants/participant_storage.dart';
import '../services/sync/app_sync_state.dart';
import '../widgets/page_states/page_states.dart';
import '../widgets/participant_editor/duplicate_decision_panel.dart';
import '../widgets/participant_editor/editor_action_bar.dart';
import '../widgets/participant_editor/editor_banner.dart';
import '../widgets/participant_editor/editor_header.dart';
import '../widgets/participant_editor/editor_skeleton.dart';
import '../widgets/participant_editor/participant_form_sections.dart';
import '../widgets/participant_editor/review_differences_panel.dart';
import '../widgets/participant_editor/validation_summary.dart';
import '../widgets/unsaved_changes_guard.dart';

/// Creates or edits one reusable participant profile
/// (`plan/ui/contest-administration/participant-data.md`).
///
/// With a null [participantId] the editor creates a profile. Validation is
/// inline after a field is left and summarised after a failed save; entered
/// values survive a failed save; a possible duplicate by email is a decision
/// shown before a second profile is created; a stale revision can be
/// reviewed field by field; and leaving with unsaved changes asks first.
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
    this.remoteMatchingUnavailable = false,
    this.managedFields = const {},
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

  /// Show that matching against online records failed, so the email check
  /// covered this device only (#247; no remote source yet).
  final bool remoteMatchingUnavailable;

  /// Fields owned by the participant's own account, shown read-only
  /// (#247; no owned profiles yet).
  final Set<ParticipantField> managedFields;

  @override
  State<ParticipantEditorPage> createState() => _ParticipantEditorPageState();
}

class _ParticipantEditorPageState extends State<ParticipantEditorPage> {
  static const double _narrowWidth = 600;

  final Map<ParticipantField, TextEditingController> _texts = {
    for (final field in ParticipantField.values) field: TextEditingController(),
  };
  final Map<ParticipantField, FocusNode> _focus = {
    for (final field in ParticipantField.values) field: FocusNode(),
  };
  final FocusNode _decisionFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  ParticipantEditorController? _controller;

  ParticipantEditorController get _c => _controller!;

  bool get _fromWizard => widget.onDone != null;

  @override
  void initState() {
    super.initState();
    widget.guard?.attach(_confirmDiscard);
    for (final field in ParticipantField.values) {
      _texts[field]!.addListener(() => _typed(field));
      _focus[field]!.addListener(() {
        if (!_focus[field]!.hasFocus) {
          _controller?.leave(field);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) {
      return;
    }
    final client = apiClientOf(context);
    if (client == null) {
      throw StateError('No API client is available.');
    }
    final id = widget.participantId;
    _controller = ParticipantEditorController(
      client: client,
      participantId: id == null ? null : Id.parse(id),
      remoteMatchingUnavailable: widget.remoteMatchingUnavailable,
      managedFields: widget.managedFields,
      forContest: ContestScope.maybeOf(context)?.contest?.id,
    )..addListener(_syncTexts);
    _c.load();
  }

  @override
  void dispose() {
    widget.guard?.detach(_confirmDiscard);
    _controller?.dispose();
    for (final text in _texts.values) {
      text.dispose();
    }
    for (final node in _focus.values) {
      node.dispose();
    }
    _decisionFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _typed(ParticipantField field) =>
      _controller?.setValue(field, _texts[field]!.text);

  /// Copies values the controller replaced (a loaded profile, kept values,
  /// a reviewed version) into the text fields.
  void _syncTexts() {
    for (final field in ParticipantField.values) {
      final text = _texts[field]!;
      if (text.text != _c.values[field]) {
        text.text = _c.values[field];
      }
    }
  }

  Future<void> _save({bool another = false}) async {
    final outcome = await _c.save(another: another);
    await _react(outcome);
  }

  Future<void> _react(SaveOutcome outcome) async {
    if (!mounted) {
      return;
    }
    switch (outcome) {
      case SaveOutcome.invalid:
        final first = _c.firstInvalid;
        if (first != null) {
          _focus[first]!.requestFocus();
        }
      case SaveOutcome.needsDecision:
        _decisionFocus.requestFocus();
      case SaveOutcome.saved:
        _leave(_c.saved);
      case SaveOutcome.savedAnother:
        final saved = _c.saved!;
        _snack('${saved.firstName} ${saved.lastName} added');
        if (_scroll.hasClients) {
          _scroll.jumpTo(0);
        }
        _focus[ParticipantField.firstName]!.requestFocus();
      case SaveOutcome.failed ||
          SaveOutcome.conflict ||
          SaveOutcome.blocked ||
          SaveOutcome.unchanged:
        break;
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(text)));

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
    if (_controller == null || !_c.dirty) {
      return true;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            autofocus: true,
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
    if (_c.phase == EditorPhase.saving) {
      return;
    }
    if (await _confirmDiscard() && mounted) {
      _c.values = _c.baseline;
      _leave();
    }
  }

  void _useExisting() {
    final match = _c.useExisting();
    if (match == null) {
      return;
    }
    _c.values = _c.baseline;
    if (widget.onDone != null) {
      widget.onDone!(match);
    } else {
      context.go(participantPath(match.id.value));
    }
  }

  ParticipantStorage? _storage(AppSyncState sync) {
    final owner = _c.loaded?.ownerAccountId;
    if (owner == null) {
      return null;
    }
    return ParticipantStorage.of(sync.of(DirectorScopeKey(owner)));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      switch (_c.phase) {
        case EditorPhase.loading:
          return const EditorSkeleton();
        case EditorPhase.loadFailed:
          return loadFailedView(
            _c.loadError ?? StateError(_c.error ?? 'Unknown error'),
            title: 'Couldn’t load this participant',
            onRetry: _c.load,
            secondary: PageStateAction(
              label: _fromWizard
                  ? 'Back to contest setup'
                  : 'Back to participants',
              onPressed: _leave,
            ),
          );
        default:
          return _form(context);
      }
    },
  );

  Widget _form(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_c.phase == EditorPhase.duplicate) {
            _c.backToEdit();
            _focus[ParticipantField.email]!.requestFocus();
          } else {
            _cancel();
          }
        },
      },
      child: PopScope(
        canPop: !_c.dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) {
            return;
          }
          if (await _confirmDiscard() && mounted) {
            _c.values = _c.baseline;
            _leave();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final phone = constraints.maxWidth < _narrowWidth;
            final stacked = phone || scale > 1.3;
            return Column(
              children: [
                Expanded(child: _content(context, phone, stacked)),
                _bar(stacked),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, bool phone, bool stacked) {
    final c = _c;
    final edit = !c.creating;
    final loaded = c.loaded;
    final attention = c.attention;
    return SingleChildScrollView(
      controller: _scroll,
      padding: phone
          ? const EdgeInsets.fromLTRB(16, 16, 16, 24)
          : const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: phone ? double.infinity : 704),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<AppSyncState>(
                stream: appSyncOf(context).states,
                initialData: appSyncOf(context).state,
                builder: (context, snapshot) => EditorHeader(
                  title: edit && loaded != null
                      ? '${loaded.firstName} ${loaded.lastName}'
                      : 'Add participant',
                  subtitle: edit
                      ? (loaded?.club ?? 'No club')
                      : 'Details are reused in every contest you add them to.',
                  initials: edit && loaded != null
                      ? '${loaded.firstName[0]}${loaded.lastName[0]}'
                            .toUpperCase()
                      : null,
                  storage: edit && snapshot.data != null
                      ? _storage(snapshot.data!)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              if (attention.isNotEmpty) ...[
                ValidationSummary(
                  problems: attention,
                  onGoTo: (field) => _focus[field]!.requestFocus(),
                ),
                const SizedBox(height: 20),
              ],
              if (c.phase == EditorPhase.saveFailed) ...[
                EditorBanner(
                  key: const ValueKey('save-error'),
                  icon: Icons.error,
                  title: 'Couldn’t save',
                  body: c.error,
                  kind: PageBannerKind.alert,
                  actions: [
                    EditorBannerAction(
                      'Try again',
                      () async => _react(await _c.retrySave()),
                      icon: Icons.refresh,
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Nothing was saved and your entries are kept, so it’s '
                      'safe to try again.',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (c.phase == EditorPhase.stale) ...[
                _staleBanner(),
                const SizedBox(height: 20),
              ],
              if (c.phase == EditorPhase.review && c.review != null) ...[
                ReviewDifferencesPanel(
                  review: c.review!,
                  onChoose: c.chooseInReview,
                  onReloadTheirs: c.reloadLatest,
                  onApply: () async => _react(await _c.applyReview()),
                ),
                const SizedBox(height: 20),
              ],
              if (c.phase == EditorPhase.duplicate && c.match != null) ...[
                DuplicateDecisionPanel(
                  key: const ValueKey('duplicate-notice'),
                  existing: c.match!,
                  entered: c.values,
                  addsToContest: _fromWizard,
                  focusNode: _decisionFocus,
                  onUseExisting: _useExisting,
                  onBackToEdit: () {
                    c.backToEdit();
                    _focus[ParticipantField.email]!.requestFocus();
                  },
                ),
                const SizedBox(height: 20),
              ],
              if (c.keptFrom != null) ...[
                _keptNotice(),
                const SizedBox(height: 20),
              ],
              ParticipantFormSections(
                controller: c,
                texts: _texts,
                focus: _focus,
                stacked: stacked,
                onSubmit: _save,
              ),
              if (c.creating)
                CheckboxListTile(
                  key: const ValueKey('keep-club-location'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: c.keepClubAndLocation,
                  onChanged: (keep) => c.toggleKeep(keep: keep ?? false),
                  title: const Text(
                    'Keep club and location for the next participant',
                  ),
                  subtitle: const Text(
                    'Used by Save and add another, so a row of pilots from '
                    'one club needs them once.',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staleBanner() {
    final names = _c.staleFields.map((f) => f.label).toList();
    final changed = switch (names.length) {
      0 => null,
      1 => names.single,
      _ => '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}',
    };
    return EditorBanner(
      key: const ValueKey('stale-revision'),
      icon: Icons.sync_problem,
      title: 'This participant was changed elsewhere since you opened it.',
      body: changed == null
          ? _c.error
          : '$changed ${names.length == 1 ? 'was' : 'were'} changed '
                'elsewhere. Nothing was saved, and your edits are kept.',
      kind: PageBannerKind.status,
      actions: [
        EditorBannerAction(
          'Reload their version',
          _c.reloadLatest,
          key: const ValueKey('reload-latest'),
        ),
        if (_c.latest != null)
          EditorBannerAction(
            'Review differences',
            _c.startReview,
            key: const ValueKey('review-start'),
          ),
      ],
    );
  }

  Widget _keptNotice() => EditorBanner(
    key: const ValueKey('kept-values'),
    icon: Icons.content_copy,
    title: 'Club and location kept from ${_c.keptFrom}.',
    kind: PageBannerKind.success,
    actions: [EditorBannerAction('Clear them', _c.clearKept)],
  );

  Widget _bar(bool stacked) {
    final c = _c;
    final edit = !c.creating;
    final saving = c.phase == EditorPhase.saving;
    // An unchanged stored profile has nothing to save or cancel, so the bar
    // waits for the first change (or any state that needs an answer).
    if (edit && !c.dirty && c.phase == EditorPhase.idle) {
      return const SizedBox.shrink();
    }
    final EditorBarStatus? status = switch (c.phase) {
      EditorPhase.saving => const EditorBarStatus(Icons.sync, 'Saving…'),
      EditorPhase.duplicate => const EditorBarStatus(
        Icons.person_search,
        'Choose an option above to continue.',
      ),
      EditorPhase.stale || EditorPhase.review => const EditorBarStatus(
        Icons.sync_problem,
        'Resolve the conflict above to save.',
      ),
      _ when edit && c.dirty => const EditorBarStatus(
        Icons.edit,
        'Unsaved changes',
      ),
      _ => null,
    };
    return EditorActionBar(
      compact: stacked,
      status: status,
      saving: saving,
      saveLabel: edit
          ? 'Save changes'
          : _fromWizard
          ? 'Add to contest'
          : 'Add participant',
      saveEnabled: !c.blocked && c.dirty,
      onSave: _save,
      onCancel: _cancel,
      anotherEnabled: !c.blocked && c.dirty,
      onSaveAnother: edit ? null : () => _save(another: true),
    );
  }
}
