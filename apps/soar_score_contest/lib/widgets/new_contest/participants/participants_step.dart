import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../api_client_provider.dart';
import '../../../pages/participant_editor_page.dart';
import '../../../services/new_contest/contest_draft.dart';
import '../../../services/new_contest/draft_candidate.dart';
import '../../../services/new_contest/draft_list_rules.dart';
import '../../../services/new_contest/draft_participant.dart';
import '../../../services/new_contest/draft_validation.dart';
import '../../../services/new_contest/participant_rules.dart';
import '../../../services/participants/participant_candidate.dart';
import '../../../services/participants/pilot_models_backend.dart';
import '../../../services/participants/participant_option.dart';
import '../../../services/participants/participant_row.dart';
import '../../participants/bulk_edit_bar.dart';
import '../../participants/cell_focus_registry.dart';
import '../../participants/participant_card.dart';
import '../../participants/participant_editing.dart';
import '../../participants/pilot_models_dialog.dart';
import '../../participants/participant_search_field.dart';
import '../../participants/participants_table.dart';
import '../wizard_banner.dart';

/// Step 4: the people in the contest.
///
/// Search adds people as Pilots; `Add participant` opens the participant
/// editor over the wizard and appends the new person to the list. Rows edit inline
/// (stacked cards on narrow windows), several rows can be edited at once,
/// and a `Needs fixing` filter and the summary links lead to the rows that
/// block continuing.
class ParticipantsStep extends StatefulWidget {
  const ParticipantsStep({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.showErrors,
    required this.offline,
    required this.narrow,
    this.onMessage,
    this.remote,
  });

  final ContestDraft draft;
  final ValueChanged<ContestDraft> onChanged;

  /// Whether the user has tried to continue.
  final bool showErrors;

  final bool offline;
  final bool narrow;
  final ValueChanged<String>? onMessage;
  final RemoteParticipantSearch? remote;

  @override
  State<ParticipantsStep> createState() => _ParticipantsStepState();
}

class _ParticipantsStepState extends State<ParticipantsStep> {
  final CellFocusRegistry _focus = CellFocusRegistry();
  final Set<String> _selected = {};
  bool _onlyFix = false;
  String _query = '';
  List<ParticipantProfile>? _profiles;
  List<Role> _roles = [SystemRoles.pilot];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final client = apiClientOf(context);
    if (client == null) {
      setState(() => _profiles = const []);
      return;
    }
    try {
      final profiles = await client.participants();
      if (mounted) {
        setState(() => _profiles = profiles);
      }
    } on Object {
      if (mounted) {
        setState(() => _profiles = const []);
      }
    }
    try {
      final roles =
          (await client.roles())
              .where((role) => role.archivedAt == null)
              .toList()
            ..sort((a, b) {
              if (a.type == b.type) {
                return a.displayName.compareTo(b.displayName);
              }
              return a.type == RoleType.pilot ? -1 : 1;
            });
      if (mounted && roles.isNotEmpty) {
        setState(() => _roles = roles);
      }
    } on Object {
      // Without the role list every new participant is a Pilot.
    }
  }

  ContestDraft get _draft => widget.draft;

  void _setParticipants(List<DraftParticipant> participants) =>
      widget.onChanged(_draft.copyWith(participants: participants));

  void _update(DraftParticipant updated) => _setParticipants([
    for (final p in _draft.participants)
      p.profileId == updated.profileId ? updated : p,
  ]);

  /// Opens the models window for [row]; the models stay in the draft and are
  /// sent when the contest is created.
  Future<void> _editModels(ParticipantRow row) async {
    final participant = row as DraftParticipant;
    final client = apiClientOf(context);
    final models = await showPilotModelsDialog(
      context,
      pilotName: participant.name,
      models: participant.models,
      backend: DraftPilotModelsBackend(
        loadProfileModels: () async =>
            client == null || participant.source == ParticipantSource.remote
            ? const []
            : client.profileModels(participant.profileId),
      ),
    );
    if (!mounted) return;
    final current = _draft.participants.where(
      (p) => p.profileId == participant.profileId,
    );
    if (current.isNotEmpty) _update(current.first.copyWith(models: models));
  }

  void _updateSelected(DraftParticipant Function(DraftParticipant) change) {
    _setParticipants([
      for (final p in _draft.participants)
        _selected.contains(p.profileId.value) ? change(p) : p,
    ]);
  }

  void _add(DraftParticipant participant) => _addAll([participant]);

  /// Adds [participants] in one change. The draft is only refreshed when the
  /// step rebuilds, so each one is checked against the list built so far.
  void _addAll(List<DraftParticipant> participants) {
    final next = [..._draft.participants];
    for (final participant in participants) {
      if (next.any((p) => p.profileId == participant.profileId)) {
        widget.onMessage?.call(
          '${participant.name} is already in the contest.',
        );
        continue;
      }
      next.add(participant);
    }
    if (next.length != _draft.participants.length) _setParticipants(next);
  }

  Future<void> _addNew() async {
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
    final saved = [...others, ?profile];
    if (saved.isEmpty) return;
    final participants = [
      for (final profile in saved) DraftParticipant.fromProfile(profile),
    ];
    _addAll(participants);
    setState(() => _profiles = [...?_profiles, ...saved]);
    for (final participant in participants) {
      widget.onMessage?.call('${participant.name} is added as Pilot.');
    }
  }

  void _removeSelected() {
    final count = _selected.length;
    _setParticipants([
      for (final p in _draft.participants)
        if (!_selected.contains(p.profileId.value)) p,
    ]);
    setState(_selected.clear);
    widget.onMessage?.call(
      '$count participant${count == 1 ? '' : 's'} removed from this contest.',
    );
  }

  void _toggle(DraftParticipant participant) => setState(() {
    final id = participant.profileId.value;
    if (!_selected.remove(id)) {
      _selected.add(id);
    }
  });

  void _toggleAll(List<DraftParticipant> rows) => setState(() {
    final ids = rows.map((p) => p.profileId.value);
    if (ids.every(_selected.contains)) {
      _selected.removeAll(ids);
    } else {
      _selected.addAll(ids);
    }
  });

  void _focusIssue(DraftParticipant participant, ParticipantIssue issue) {
    final column = switch (issue) {
      ParticipantIssue.classification => ParticipantColumn.classification,
    };
    _focus.node(participant.profileId.value, column).requestFocus();
  }

  /// Whether [participant] matches the text in the search field (name,
  /// email, team, class or role), so the same field filters the list. An
  /// email the person hides is never matched.
  bool _matchesQuery(DraftParticipant participant) {
    final query = _query.trim().toLowerCase();
    return query.isEmpty ||
        [
          participant.name,
          if (participant.emailVisible) ?participant.email,
          participant.team,
          participant.classification,
          participant.roleName,
        ].any((value) => value.toLowerCase().contains(query));
  }

  List<Widget> _banners() {
    final draft = _draft;
    final banners = <Widget>[];
    final needing = draft.participantsNeedingFixes;
    if (needing.isNotEmpty) {
      final n = needing.length;
      banners.add(
        WizardBanner(
          key: const ValueKey('banner-participants'),
          tone: WizardBannerTone.error,
          icon: Icons.error,
          title:
              '$n participant${n == 1 ? ' needs' : 's need'} fixing before '
              'you continue',
          links: [
            for (final participant in needing.take(5))
              () {
                final issue = draft.issuesOf(participant).first;
                return WizardBannerLink(
                  text: '${participant.name}: ${issue.fix}',
                  onTap: () => _focusIssue(participant, issue),
                );
              }(),
          ],
        ),
      );
    }
    final scoring = draft.scoringCount;
    if (scoring < DraftValidation.minScoringPilots &&
        (widget.showErrors || draft.participants.isNotEmpty)) {
      banners.add(
        const WizardBanner(
          key: ValueKey('banner-min-pilots'),
          tone: WizardBannerTone.error,
          icon: Icons.error,
          title: 'Add at least 2 scoring pilots',
          body:
              'A contest needs 2 or more scoring pilots. Non-flying roles '
              'don’t count.',
        ),
      );
    } else if (scoring == DraftValidation.minScoringPilots) {
      banners.add(
        WizardBanner(
          key: const ValueKey('banner-few-pilots'),
          tone: WizardBannerTone.warning,
          icon: Icons.lightbulb,
          title: 'Only $scoring scoring pilots',
          body:
              'You can continue. With fewer than 3 pilots, use 1 group per '
              'round.',
        ),
      );
    }
    return banners;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final draft = _draft;
    final participants = draft.participants;
    final ids = {for (final p in participants) p.profileId.value};
    _selected.retainAll(ids);
    _focus.retain(ids);
    final needing = draft.participantsNeedingFixes;
    final onlyFix = _onlyFix && needing.isNotEmpty;
    final fixRows = onlyFix ? needing : participants;
    final rows = fixRows.where(_matchesQuery).toList();
    _focus.rowOrder = [for (final p in rows) p.profileId.value];
    final editing = ParticipantEditing(
      rules: DraftListRules(draft),
      roles: _roles,
      focus: _focus,
      selected: _selected,
      onToggleSelected: (row) => _toggle(row as DraftParticipant),
      onUpdate: (row) => _update(row as DraftParticipant),
      editModels: _editModels,
    );
    final scoring = draft.scoringCount;

    Widget chip(IconData icon, String label) => Container(
      height: 32,
      padding: const EdgeInsetsDirectional.only(start: 8, end: 12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final banner in _banners()) ...[
          banner,
          const SizedBox(height: 20),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final search = ParticipantSearchField(
              profiles: _profiles,
              selected: ids,
              offline: widget.offline,
              remote: widget.remote,
              onQueryChanged: (value) => setState(() => _query = value),
              onAdd: (candidate) {
                _add(candidate.toParticipant());
                widget.onMessage?.call('${candidate.name} added as Pilot.');
              },
            );
            final add = SizedBox(
              height: 56,
              child: FilledButton.icon(
                key: const ValueKey('add-participant-new'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsetsDirectional.only(start: 16, end: 24),
                ),
                onPressed: () => unawaited(_addNew()),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add participant'),
              ),
            );
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [search, const SizedBox(height: 12), add],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                add,
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (participants.isEmpty)
          _EmptyState(key: const ValueKey('participants-empty'))
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_draft.has(ParticipantOption.roles)) ...[
                chip(Icons.groups, '${participants.length} people'),
                chip(Icons.flight_takeoff, '$scoring scoring pilots'),
                chip(
                  Icons.badge_outlined,
                  '${participants.length - scoring} non-flying',
                ),
              ] else
                chip(Icons.flight_takeoff, '$scoring pilots'),
              if (needing.isNotEmpty)
                FilterChip(
                  key: const ValueKey('needs-fixing-filter'),
                  selected: onlyFix,
                  avatar: onlyFix ? null : const Icon(Icons.filter_list),
                  label: Text('Needs fixing (${needing.length})'),
                  onSelected: (value) => setState(() => _onlyFix = value),
                ),
            ],
          ),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 12),
            BulkEditBar(
              count: _selected.length,
              onClear: () => setState(_selected.clear),
              onRemove: _removeSelected,
              teams: draft.has(ParticipantOption.teams) ? draft.teams : null,
              classes: draft.has(ParticipantOption.classes)
                  ? draft.classes
                  : null,
              roles: draft.has(ParticipantOption.roles) ? _roles : null,
              onTeam: (team) {
                _updateSelected((p) => p.copyWith(team: team));
                widget.onMessage?.call(
                  'Team set for ${_selected.length} participants.',
                );
              },
              onClass: (value) {
                _updateSelected(
                  (p) => draft.isScoring(p)
                      ? p.copyWith(classification: value)
                      : p,
                );
                widget.onMessage?.call(
                  'Class set to $value for ${_selected.length} '
                  'participants.',
                );
              },
              onRole: (role) {
                _updateSelected((p) => p.copyWith(role: role));
                widget.onMessage?.call(
                  'Role set to ${role.displayName} for ${_selected.length} '
                  'participants.',
                );
              },
            ),
          ],
          if (_query.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Showing ${rows.length} of ${fixRows.length} matching '
              '“${_query.trim()}”',
              key: const ValueKey('participants-filter-note'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No one in this contest matches “${_query.trim()}”.',
                key: const ValueKey('participants-filter-empty'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else if (widget.narrow)
            Semantics(
              container: true,
              label: 'Contest participants',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final participant in rows) ...[
                    ParticipantCard(editing: editing, participant: participant),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            )
          else
            ParticipantsTable(
              editing: editing,
              rows: rows,
              onToggleAll: () => _toggleAll(rows),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.keyboard, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tab moves between cells · Enter confirms and moves down · '
                  'Space selects a row · Esc closes a menu',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              'Find people by name or email above, or add someone new. The '
              'contest needs at least 2 scoring pilots.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
