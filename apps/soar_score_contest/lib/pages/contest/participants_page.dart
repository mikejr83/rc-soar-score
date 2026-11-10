import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../connectivity_provider.dart';
import '../../services/connectivity/app_connectivity.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../services/reports/pilot_cards/pilot_invitations.dart';
import '../../widgets/invitations/send_invitations_flow.dart';
import '../../services/contest_participants/participants_controller.dart';
import '../../services/contest_participants/participants_row_styles.dart';
import '../../services/contest_participants/stored_participant.dart';
import '../../services/matrix/matrix_rounds_plan.dart';
import '../../services/participants/participant_option.dart';
import '../../services/participants/participant_row.dart';
import '../../services/participants/pilot_models_backend.dart';
import '../../widgets/contest_participants/participants_banners.dart';
import '../../widgets/contest_participants/participants_dialogs.dart';
import '../../widgets/contest_participants/participants_header.dart';
import '../../widgets/contest_participants/participants_save_bar.dart';
import '../../widgets/contest_participants/participants_toolbar.dart';
import '../../widgets/contest_participants/participant_actions.dart';
import '../../widgets/discard_changes_dialog.dart';
import '../../widgets/page_states/page_states.dart';
import '../../widgets/participants/bulk_edit_bar.dart';
import '../../widgets/participants/cell_focus_registry.dart';
import '../../widgets/participants/participant_card.dart';
import '../../widgets/participants/participant_editing.dart';
import '../../widgets/participants/pilot_models_dialog.dart';
import '../../widgets/participants/participants_table.dart';
import '../../widgets/unsaved_changes_guard.dart';
import '../participant_editor_page.dart';

/// Who takes part in an existing contest, and their contest-specific data
/// (role, class, team), at `/contest-administration/contests/{id}/participants`
/// (`plan/ui/contest-administration/briefs/participants.md`).
///
/// The list is the wizard's step 4 list working on stored data. Edits wait
/// behind the Save bar and save row by row; adding and removing people act
/// at once. The page serves every stage: before and after the draw, locked,
/// and completed (read-only).
class ContestParticipantsPage extends StatefulWidget {
  const ContestParticipantsPage({
    super.key,
    required this.contestId,
    this.guard,
  });

  final String contestId;

  /// Lets the route's `onExit` ask before leaving with unsaved edits.
  final UnsavedChangesGuard? guard;

  @override
  State<ContestParticipantsPage> createState() =>
      _ContestParticipantsPageState();
}

class _ContestParticipantsPageState extends State<ContestParticipantsPage> {
  ParticipantsController? _controller;
  final CellFocusRegistry _focus = CellFocusRegistry();
  final ScrollController _scroll = ScrollController();
  String? _shownMessage;
  PilotInvitationSession? _invitations;
  AppConnectivity? _monitor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The Invitations menu follows connectivity, so it goes off when the
    // network is lost instead of failing a request.
    final monitor = appConnectivityOf(context);
    if (!identical(monitor, _monitor)) {
      _monitor?.removeListener(_changed);
      _monitor = monitor?..addListener(_changed);
    }
    if (_controller != null) return;
    final client = apiClientOf(context);
    if (client == null) return;
    final Id id;
    try {
      id = Id.parse(widget.contestId);
    } on ArgumentError {
      return;
    }
    _controller = ParticipantsController(client: client, contestId: id)
      ..addListener(_changed);
    widget.guard?.attach(
      _confirmLeave,
      hasChanges: () => _controller?.hasUnsaved ?? false,
    );
    _controller!.load();
    _openInvitations(id);
  }

  /// Reads the contest's invitations in the background: the Invitations menu
  /// stays off until they are known.
  Future<void> _openInvitations(Id id) async {
    final publication = publicationClientOf(context);
    if (publication == null) return;
    final session = await PilotInvitationSession.open(
      source: PilotInvitationSources.current,
      client: publication,
      contestId: id,
    );
    if (!mounted) {
      session.dispose();
      return;
    }
    setState(() => _invitations = session..addListener(_changed));
  }

  Future<void> _sendInvitations(List<Id> missing) async {
    final session = _invitations;
    if (session == null) return;
    await sendInvitationsGuarded(context, session, missing);
  }

  /// What the Invitations menu offers for the selection now.
  ({VoidCallback? send, VoidCallback? copy, String? reason}) _invitationMenu(
    ParticipantsController c,
    Set<String> rowIds,
  ) {
    final l10n = AppLocalizations.of(context);
    final session = _invitations;
    if (session == null || session.phase == InvitationPhase.loadFailed) {
      return (send: null, copy: null, reason: l10n.invitationsNotReady);
    }
    final pilots = [
      for (final row in c.rows)
        if (rowIds.contains(row.rowId) && canHaveInvitation(row.participation))
          row.participation.id,
    ];
    final missing = [
      for (final id in pilots)
        if (!session.has(id)) id,
    ];
    final unavailable = invitationsUnavailableText(
      l10n,
      session.invitations,
      unreachable: invitationsUnreachableText(context, l10n),
    );
    final sendReason =
        unavailable ??
        (rowIds.isEmpty
            ? l10n.invitationsSelectPilots
            : pilots.isEmpty
            ? l10n.invitationsOnlyPilots
            : missing.isEmpty
            ? l10n.invitationsAllHaveLinks
            : null);
    // Copy needs exactly one selected row, and it must be a pilot.
    final oneRow = rowIds.length == 1 && pilots.length == 1;
    final link = oneRow ? session.invitations.linkOf(pilots.single) : null;
    final copyReason = !oneRow
        ? l10n.invitationsSelectOne
        : link == null
        ? l10n.invitationsNoLinkYet
        : null;
    final canSend = sendReason == null && !session.sending && !c.saving;
    final reasons = [?sendReason, if (rowIds.length == 1) ?copyReason];
    return (
      send: canSend ? () => _sendInvitations(missing) : null,
      copy: link == null ? null : () => _copyLink(link),
      reason: reasons.isEmpty ? null : reasons.join(' '),
    );
  }

  Future<void> _copyLink(String link) async {
    var copied = true;
    try {
      await Clipboard.setData(ClipboardData(text: link))
          .timeout(const Duration(seconds: 3));
    } on Object {
      // A browser can refuse clipboard access, or never answer.
      copied = false;
    }
    // The page may have been left while the clipboard answered.
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const ValueKey('invitations-snackbar'),
          content: Text(
            copied ? l10n.invitationsLinkCopied : l10n.invitationsCopyFailed,
          ),
        ),
      );
  }

  @override
  void dispose() {
    _monitor?.removeListener(_changed);
    _invitations
      ?..removeListener(_changed)
      ..dispose();
    widget.guard?.detach(_confirmLeave);
    _controller?.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    final message = _controller?.message;
    if (message != null && message != _shownMessage) {
      _shownMessage = message;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const ValueKey('participants-snackbar'),
            content: Text(message),
          ),
        );
      _controller!.clearMessage();
      _shownMessage = null;
    }
    final highlight = _controller?.highlightId;
    if (highlight != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focus.node(highlight, ParticipantColumn.team).requestFocus();
        }
      });
    }
  }

  Future<bool> _confirmLeave() async {
    final c = _controller;
    if (c == null || !mounted || !c.hasUnsaved) return true;
    final count = c.changedIds.length;
    final closing = UnsavedChangesGuard.closingApp;
    final discard = await confirmDiscard(
      context,
      title: closing
          ? UnsavedChangesGuard.closeTitle
          : 'Leave with unsaved changes?',
      body:
          'You have unsaved changes to $count participant'
          '${count == 1 ? '' : 's'}. '
          '${closing ? 'Closing the app' : 'Leaving'} discards them.',
      keepLabel: 'Stay',
      discardLabel: 'Discard and leave',
    );
    if (discard) c.discardAll();
    return discard;
  }

  // Actions.

  /// Opens the models window for [row]. Each change is saved as it is made;
  /// the list is read again when the window closes, so a model changed
  /// elsewhere shows up.
  Future<void> _editModels(ParticipantRow row) async {
    final c = _controller!;
    final client = apiClientOf(context);
    final participant = row as StoredParticipant;
    if (client == null) return;
    await showPilotModelsDialog(
      context,
      pilotName: participant.name,
      models: participant.models,
      backend: ApiPilotModelsBackend(
        client: client,
        contestId: c.contestId,
        participationId: participant.id,
        profileId: participant.profile.id,
      ),
    );
    await c.reload();
  }

  /// A cell edit. Making a pilot non-flying clears their class, so that
  /// asks first; cancelling puts the row back.
  Future<void> _onEdit(ParticipantRow row) async {
    final c = _controller!;
    final updated = row as StoredParticipant;
    final before = c.rows.where((r) => r.rowId == updated.rowId).firstOrNull;
    c.edit(updated);
    final inDraw = before != null && c.inDraw(before);
    if (before != null &&
        before.isPilot &&
        !updated.isPilot &&
        (before.classification.trim().isNotEmpty || inDraw)) {
      final ok = await confirmNonFlying(
        context,
        name: updated.name,
        roleName: updated.roleName,
        classification: before.classification,
        inDraw: inDraw,
      );
      if (!ok) c.edit(before);
    }
  }

  /// The bulk role change. Making pilots non-flying clears their class and,
  /// for those in the draw, takes them out of it, so that asks first, like a
  /// single edit.
  Future<void> _setRoleForSelected(Role role) async {
    final c = _controller!;
    if (role.type != RoleType.pilot) {
      final affected = [
        for (final row in c.rows)
          if (c.selection.contains(row.rowId) &&
              row.isPilot &&
              !c.hasFlights(row) &&
              (row.classification.trim().isNotEmpty || c.inDraw(row)))
            row,
      ];
      if (affected.isNotEmpty) {
        final ok = await confirmNonFlying(
          context,
          name: ParticipantsController.andList([
            for (final row in affected) row.name,
          ]),
          roleName: role.displayName,
          classification: affected
              .map((row) => row.classification.trim())
              .firstWhere((c) => c.isNotEmpty, orElse: () => ''),
          clearsClass: affected.any((r) => r.classification.trim().isNotEmpty),
          inDraw: affected.any(c.inDraw),
          plural: affected.length > 1,
        );
        if (!ok || !mounted) return;
      }
    }
    c.setRoleForSelected(role);
  }

  Future<void> _addProfile(
    ParticipantProfile profile, {
    Role? retryRole,
  }) async {
    final c = _controller!;
    if (!c.canEdit) return;
    final name = '${profile.firstName} ${profile.lastName}';
    final rolesOn = c.options.contains(ParticipantOption.roles);
    Role? role = retryRole;
    if (retryRole == null && (rolesOn || c.drawn)) {
      final choice = await askAddParticipant(
        context,
        name: name,
        roles: rolesOn ? c.roles : null,
        drawn: c.drawn,
      );
      if (choice == null || !mounted) return;
      role = choice.role;
    }
    if (await c.add(profile, role: role)) await _placeNewPilots();
  }

  /// Saves the changed rows, then puts anyone who became a pilot in the
  /// rounds.
  Future<void> _save() async {
    final c = _controller!;
    await c.save();
    if (mounted) await _placeNewPilots();
  }

  /// A pilot who joined a drawn contest is put in the last group of every
  /// round. With no scores yet the director may redraw the matrix with them
  /// instead; declining keeps the matrix and places them anyway.
  Future<void> _placeNewPilots() async {
    final c = _controller!;
    for (final row in c.takePendingPlacements()) {
      if (!mounted) return;
      if (!c.hasScores) {
        final redraw = await askRedrawWith(context, name: row.name);
        if (!mounted) return;
        if (redraw) {
          context.go(
            contestMatrixPath(widget.contestId, intent: MatrixIntent.redraw),
          );
          return;
        }
      }
      await c.placeInRounds(row);
    }
  }

  /// Puts the pilots who are in the contest but in no group into every round,
  /// for a page that was reloaded or a placement that failed.
  Future<void> _placeUnplaced() async {
    final c = _controller!;
    for (final row in [...c.unplaced]) {
      if (!mounted) return;
      await c.placeInRounds(row);
    }
  }

  Future<void> _addNew() async {
    final c = _controller!;
    if (!c.canEdit) return;
    // Profiles saved with "Save and add another" before the dialog closes.
    final others = <ParticipantProfile>[];
    final profile = await showDialog<ParticipantProfile>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Cancel',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Add participant'),
          ),
          body: ParticipantEditorPage(
            onDone: (profile) => Navigator.of(context).pop(profile),
            onCancel: () => Navigator.of(context).pop(),
            onSavedAnother: others.add,
          ),
        ),
      ),
    );
    if (!mounted) return;
    final added = [...others, ?profile];
    if (added.isEmpty) return;
    await c.reload();
    for (final saved in added) {
      if (!mounted) return;
      await _addProfile(saved);
    }
  }

  Future<void> _removeSelected() =>
      _removeParticipants(Set.of(_controller!.selection));

  Future<void> _removeParticipants(Set<String> rowIds) async {
    final c = _controller!;
    if (!c.canEdit ||
        c.saving ||
        c.rows.any((row) => rowIds.contains(row.rowId) && c.hasFlights(row))) {
      return;
    }
    final names = [
      for (final row in c.rows)
        if (rowIds.contains(row.rowId)) row.name,
    ];
    if (names.isEmpty) return;
    final ok = await confirmRemove(
      context,
      names: names,
      contestName: c.contest?.name ?? 'this contest',
      inDraw: [
        for (final row in c.rows)
          if (rowIds.contains(row.rowId) && c.inDraw(row)) row.name,
      ],
    );
    if (ok && mounted) await c.removeParticipants(rowIds);
  }

  void _showRow(StoredParticipant row, ParticipantColumn column) {
    _focus.node(row.rowId, column).requestFocus();
  }

  // Building.

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      body: c == null
          ? const PageStateView.unavailable(
              title: 'No API client is available.',
            )
          : _body(c),
    );
  }

  Widget _body(ParticipantsController c) {
    if (c.data == null) {
      if (c.loadError != null) {
        return loadFailedView(
          c.loadError!,
          title: 'The participants could not be loaded.',
          onRetry: c.load,
        );
      }
      return const PageStateView.loading(
        key: ValueKey('participants-loading'),
        label: 'Loading the participants',
      );
    }
    final ids = {for (final row in c.rows) row.rowId};
    _focus.retain(ids);
    final visible = c.visibleRows;
    _focus.rowOrder = [for (final row in visible) row.rowId];
    final editing = ParticipantEditing(
      rules: c.rules,
      roles: c.roles,
      focus: _focus,
      selected: c.selection,
      onToggleSelected: (row) => c.toggleSelected(row.rowId),
      onUpdate: _onEdit,
      editModels: _editModels,
      styleOf: c.styleOf,
    );
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 800;
              return SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ParticipantsHeader(
                      key: const ValueKey('participants-header'),
                      controller: c,
                      onOpenConfiguration: () => context.go(
                        contestConfigurationPath(widget.contestId),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // One keyed child, so a banner coming or going never moves
                    // the toolbar and list to another position, which would
                    // rebuild them and lose typed text and focus.
                    Column(
                      key: const ValueKey('participant-banners'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final banner in participantBanners(
                          controller: c,
                          onAdd: _addNew,
                          onRetryAdd: () {
                            final profile = c.failedAdd;
                            if (profile != null) {
                              _addProfile(profile, retryRole: c.failedAddRole);
                            }
                          },
                          onUnlock: () => context.go(
                            contestWorkspacePath(widget.contestId),
                          ),
                          onOpenMatrix: () =>
                              _goTo(contestMatrixPath(widget.contestId)),
                          onOpenScoring: () =>
                              _goTo(contestScoringPath(widget.contestId)),
                          onRedoDraw: () => _goTo(
                            contestMatrixPath(
                              widget.contestId,
                              intent: MatrixIntent.redraw,
                            ),
                          ),
                          onPlaceUnplaced: _placeUnplaced,
                          onShowClass: (row) =>
                              _showRow(row, ParticipantColumn.classification),
                        )) ...[banner, const SizedBox(height: 12)],
                      ],
                    ),
                    ParticipantsToolbar(
                      key: const ValueKey('participants-toolbar'),
                      controller: c,
                      narrow: narrow,
                      onAddNew: _addNew,
                      onAddProfile: _addProfile,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      key: const ValueKey('participants-list'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _list(c, editing, visible, narrow),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (!c.readOnly)
          ParticipantsSaveBar(
            controller: c,
            onSave: _save,
            onShowRow: (row) => _showRow(
              row,
              c.rules.issuesOf(row).isNotEmpty
                  ? ParticipantColumn.classification
                  : ParticipantColumn.team,
            ),
          ),
      ],
    );
  }

  void _goTo(String path) {
    final c = _controller;
    if (c != null && c.hasUnsaved) {
      // The route's guard asks before leaving.
    }
    context.go(path);
  }

  Widget _actions(
    ParticipantsController c,
    Set<String> rowIds, {
    StoredParticipant? row,
  }) {
    final invitation = _invitationMenu(c, rowIds);
    return ParticipantActions(
      rowId: row?.rowId,
      count: rowIds.length,
      onSend: invitation.send,
      onCopy: invitation.copy,
      reason: invitation.reason,
      onRemove: row != null && c.canEdit && !c.saving && !c.hasFlights(row)
          ? () => _removeParticipants(rowIds)
          : null,
    );
  }

  List<Widget> _list(
    ParticipantsController c,
    ParticipantEditing editing,
    List<StoredParticipant> visible,
    bool narrow,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (c.rows.isEmpty) {
      return [
        Container(
          key: const ValueKey('participants-empty'),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.group_add, size: 48, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('No participants yet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Add people you’ve saved before, or create a new one.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      if (c.selection.isNotEmpty) ...[
        BulkEditBar(
          key: const ValueKey('participants-bulk-bar'),
          count: c.selection.length,
          onClear: c.clearSelection,
          showRemove: !c.readOnly,
          actions: [_actions(c, Set.of(c.selection))],
          onRemove: c.canEdit && !c.saving && !c.selectionHasFlights
              ? _removeSelected
              : null,
          removeReason: c.selectionHasFlights
              ? 'The selection contains a pilot with flights.'
              : null,
          teams: c.options.contains(ParticipantOption.teams) && c.canEdit
              ? c.rules.teams
              : null,
          classes: c.options.contains(ParticipantOption.classes) && c.canEdit
              ? c.rules.classes
              : null,
          roles: c.options.contains(ParticipantOption.roles) && c.canEdit
              ? c.roles
              : null,
          onTeam: c.setTeamForSelected,
          onClass: c.setClassForSelected,
          onRole: _setRoleForSelected,
        ),
        const SizedBox(height: 12),
      ],
      if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No one in this contest matches “${c.query.trim()}”.',
            key: const ValueKey('participants-filter-empty'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        )
      else if (narrow)
        Semantics(
          key: const ValueKey('participants-cards'),
          container: true,
          label: 'Contest participants',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final row in visible) ...[
                ParticipantCard(
                  editing: editing,
                  participant: row,
                  selectable: true,
                  actions: _actions(c, {row.rowId}, row: row),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        )
      else
        ParticipantsTable(
          key: const ValueKey('participants-table'),
          editing: editing,
          rows: visible,
          selectable: true,
          onToggleAll: () => c.toggleAll(visible.map((r) => r.rowId)),
          actionsOf: (row) =>
              _actions(c, {row.rowId}, row: row as StoredParticipant),
        ),
    ];
  }
}
