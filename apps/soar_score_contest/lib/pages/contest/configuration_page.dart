import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../router.dart';
import '../../services/configuration/config_phase.dart';
import '../../services/configuration/configuration_data.dart';
import '../../services/configuration/configuration_draft.dart';
import '../../services/configuration/configuration_values.dart';
import '../../services/configuration/draw_readiness.dart';
import '../../services/configuration/readiness_summary.dart';
import '../../services/configuration/section_id.dart';
import '../../services/configuration/section_status.dart';
import '../../services/configuration/setting_catalog.dart';
import '../../widgets/api_error_text.dart';
import '../../widgets/configuration/config_banner.dart';
import '../../widgets/configuration/config_save_bar.dart';
import '../../widgets/configuration/configuration_sections.dart';
import '../../widgets/configuration/field_registry.dart';
import '../../widgets/configuration/matrix_readiness_panel.dart';
import '../../widgets/configuration/save_confirm_dialog.dart';
import '../../widgets/configuration/section_nav.dart';
import '../../widgets/message_view.dart';
import '../../widgets/unsaved_changes_guard.dart';

/// The configuration of one contest (`plan/ui/contest-administration/
/// contest-workspace.md`): the contest details and every option in sections
/// on one scrolling page, with a save bar that appears while there are
/// unsaved changes. Saving never draws a matrix.
class ContestConfigurationPage extends StatefulWidget {
  const ContestConfigurationPage({
    super.key,
    required this.contestId,
    this.guard,
  });

  final String contestId;

  /// Lets the router ask this page before it is left with unsaved changes.
  final UnsavedChangesGuard? guard;

  @override
  State<ContestConfigurationPage> createState() =>
      _ContestConfigurationPageState();
}

class _ContestConfigurationPageState extends State<ContestConfigurationPage> {
  /// The width from which the section list sits beside the page.
  static const _wideFrom = 900.0;

  /// How far below the top a section starts when it counts as the current one.
  static const _currentThreshold = 140.0;

  Future<ConfigurationData>? _loading;
  ConfigurationData? _data;
  ConfigurationDraft? _draft;
  bool _jumping = false;
  bool _saving = false;
  String? _saveError;

  final _registry = FieldRegistry();
  final _scrollKey = GlobalKey();
  final _scroll = ScrollController();
  final Map<SectionId, GlobalKey> _sectionKeys = {
    for (final id in SectionId.values) id: GlobalKey(),
  };
  SectionId _current = SectionId.details;

  @override
  void initState() {
    super.initState();
    widget.guard?.attach(_confirmLeave);
    _scroll.addListener(_followScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= _load();
  }

  @override
  void dispose() {
    widget.guard?.detach(_confirmLeave);
    _scroll.dispose();
    _registry.dispose();
    super.dispose();
  }

  Future<ConfigurationData> _load() async {
    final client = apiClientOf(context);
    if (client == null) {
      throw StateError('No API client is available.');
    }
    final Id id;
    try {
      id = Id.parse(widget.contestId);
    } on ArgumentError {
      throw StateError('"${widget.contestId}" is not an id.');
    }
    final data = await ConfigurationData.load(client, id);
    _show(data);
    return data;
  }

  /// Shows [data], with a fresh draft; [keep] are values to put back on it.
  void _show(ConfigurationData data, {Map<String, Object?> keep = const {}}) {
    _data = data;
    final revision = data.configuration;
    if (revision == null) {
      _draft = null;
      return;
    }
    final draft = ConfigurationDraft.fromSaved(
      contest: data.contest,
      revision: revision,
      catalog: SettingCatalog.forProfile(data.profile),
      phase: data.phase,
      lastDrawnRound: data.matrix?.lastRound,
    );
    _draft = draft..setAll(keep);
  }

  void _retry() {
    final loading = _load();
    setState(() {
      _loading = loading;
      _saveError = null;
    });
  }

  Future<bool> _confirmLeave() async {
    final draft = _draft;
    if (draft == null || !draft.dirty || _data?.readOnly == true) {
      return true;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.edit_note),
        title: const Text('Leave without saving?'),
        content: Text(
          'You have ${draft.changes.length} unsaved '
          'change${draft.changes.length == 1 ? '' : 's'} in '
          '${ReadinessSummary.lowerList(_changedSections(draft))}. Leaving '
          'discards them.',
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard and leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  List<String> _changedSections(ConfigurationDraft draft) => [
    for (final id in SectionId.values)
      if (draft.changes.any((c) => c.def.section == id)) id.title,
  ];

  void _changed() => setState(() => _saveError = null);

  void _discard() {
    setState(() {
      _draft!.discard();
      _saveError = null;
    });
    _message('Changes discarded.');
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save() async {
    final data = _data!;
    final draft = _draft!;
    final client = apiClientOf(context);
    if (client == null || _saving || draft.errors.isNotEmpty || !draft.dirty) {
      return;
    }
    if ((draft.matrixChanges.isNotEmpty || draft.recalcChanges.isNotEmpty) &&
        !await _confirmSave(draft, data)) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    var current = data;
    final mine = {for (final c in draft.changes) c.def.key: draft[c.def.key]};
    try {
      if (draft.detailsChanged) {
        final contest = await client.updateContest(
          data.contest.id,
          ConfigurationValues.toUpdate(draft, data.contest),
        );
        current = current.withContest(contest);
      }
      if (draft.configurationChanged) {
        final revision = data.configuration!;
        final toSave = ConfigurationValues.toSave(draft, revision);
        final saved = await client.saveConfiguration(
          data.contest.id,
          SaveConfigurationRequest(
            baseRevisionNumber: revision.revisionNumber,
            disciplineProfileId: revision.disciplineProfileId,
            landingTableId: toSave.landingTableId,
            config: toSave.config,
          ),
        );
        current = current.withSaved(saved);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _show(current);
      });
      _message(
        draft.configurationChanged
            ? 'Configuration saved as revision '
                  '${current.configuration!.revisionNumber}.'
            : 'Contest details saved.',
      );
    } on ApiHttpError catch (error) {
      if (!mounted) {
        return;
      }
      if (error.statusCode == 409) {
        await _reloadAfterConflict(client, mine);
      } else {
        setState(() {
          _saving = false;
          _saveError = apiErrorText(error);
          _show(current, keep: mine);
        });
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _saveError = apiErrorText(error);
        _show(current, keep: mine);
      });
    }
  }

  Future<bool> _confirmSave(ConfigurationDraft draft, ConfigurationData data) =>
      showDialog<bool>(
        context: context,
        builder: (context) => SaveConfirmDialog(
          draft: draft,
          matrixRevision: data.matrix?.revisionNumber,
        ),
      ).then((confirmed) => confirmed ?? false);

  /// Another device saved first: show the latest version, keep the director's
  /// own edits on top of it and say so.
  Future<void> _reloadAfterConflict(
    ApiClient client,
    Map<String, Object?> mine,
  ) async {
    try {
      final fresh = await ConfigurationData.load(client, _data!.contest.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _show(fresh, keep: mine);
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.sync),
          title: const Text('Configuration updated'),
          content: Text(
            fresh.configuration == null
                ? 'This contest was changed from another device. This page '
                      'now shows the latest version. Your unsaved changes are '
                      'kept.'
                : 'Revision ${fresh.configuration!.revisionNumber} was saved '
                      'from another device. This page now shows the latest '
                      'version. Your unsaved changes are kept; check them '
                      'before saving again.',
          ),
          actions: [
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = apiErrorText(error);
        });
      }
    }
  }

  void _jump(SectionId id) {
    final context = _sectionKeys[id]?.currentContext;
    if (context == null) {
      return;
    }
    setState(() => _current = id);
    _jumping = true;
    Scrollable.ensureVisible(
      context,
      alignment: 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    ).whenComplete(() {
      _jumping = false;
      _followScroll();
    });
  }

  /// Marks the section whose top has passed the top of the page as current.
  void _followScroll() {
    if (_jumping) {
      return;
    }

    final viewport = _scrollKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize || !_scroll.hasClients) {
      return;
    }
    final top = viewport.localToGlobal(Offset.zero).dy;
    var current = SectionId.values.first;
    for (final id in SectionId.values) {
      final box = _sectionKeys[id]?.currentContext?.findRenderObject();
      if (box is RenderBox &&
          box.attached &&
          box.localToGlobal(Offset.zero).dy - top <= _currentThreshold) {
        current = id;
      }
    }
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 4) {
      current = SectionId.values.last;
    }
    if (current != _current) {
      setState(() => _current = current);
    }
  }

  void _fix(BlockerFix fix) => context.go(switch (fix) {
    BlockerFix.configuration => contestConfigurationPath(widget.contestId),
    BlockerFix.workspace => contestWorkspacePath(widget.contestId),
    BlockerFix.participants => participantsPath,
  });

  void _goToMatrix() => context.go(contestMatrixPath(widget.contestId));

  @override
  Widget build(BuildContext context) => FutureBuilder<ConfigurationData>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MessageView(
          text: 'The configuration could not be loaded.',
          detail: apiErrorText(snapshot.error!),
          onRetry: _retry,
        );
      }
      final data = _data;
      if (data == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return _page(context, data, _draft);
    },
  );

  Widget _page(
    BuildContext context,
    ConfigurationData data,
    ConfigurationDraft? draft,
  ) {
    final editable = !data.readOnly && !_saving;
    final showBar = draft != null && !data.readOnly && (draft.dirty || _saving);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (showBar) _save();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          if (showBar) _save();
        },
      },
      child: Focus(
        autofocus: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= _wideFrom;
                  return wide
                      ? _wideBody(context, data, draft, editable)
                      : _narrowBody(context, data, draft, editable);
                },
              ),
            ),
            if (showBar)
              ConfigSaveBar(
                draft: draft,
                saving: _saving,
                saveError: _saveError,
                onSave: _save,
                onDiscard: _discard,
                onShowError: _registry.reveal,
              ),
          ],
        ),
      ),
    );
  }

  Map<SectionId, SectionStatus> _statuses(
    ConfigurationData data,
    ConfigurationDraft draft,
  ) {
    final completed = data.phase == ConfigPhase.completed;
    return {
      for (final id in SectionId.values)
        id: SectionStatus.of(
          id,
          draft,
          // The Participants section is marked read-only only when the contest
          // is completed, not while it is merely admin-locked.
          readOnly: switch (id) {
            SectionId.participants => completed,
            SectionId.scoringAccess || SectionId.adminLock => false,
            _ => data.readOnly,
          },
        ),
    };
  }

  Widget _wideBody(
    BuildContext context,
    ConfigurationData data,
    ConfigurationDraft? draft,
    bool editable,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 256,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 8, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (draft != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: SectionNav(
                      layout: SectionNavLayout.list,
                      sections: SectionId.values,
                      statuses: _statuses(data, draft),
                      current: _current,
                      onSelect: _jump,
                    ),
                  ),
                ),
              MatrixReadinessPanel(
                summary: ReadinessSummary.of(data, draft),
                onFix: _fix,
                onGoToMatrix: _goToMatrix,
              ),
            ],
          ),
        ),
      ),
      Expanded(child: _content(context, data, draft, editable, inline: false)),
    ],
  );

  Widget _narrowBody(
    BuildContext context,
    ConfigurationData data,
    ConfigurationDraft? draft,
    bool editable,
  ) => Column(
    children: [
      if (draft != null)
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: SectionNav(
            layout: SectionNavLayout.chips,
            sections: SectionId.values,
            statuses: _statuses(data, draft),
            current: _current,
            onSelect: _jump,
          ),
        ),
      Expanded(child: _content(context, data, draft, editable, inline: true)),
    ],
  );

  Widget _content(
    BuildContext context,
    ConfigurationData data,
    ConfigurationDraft? draft,
    bool editable, {
    required bool inline,
  }) {
    final theme = Theme.of(context);
    final revision = data.configuration;
    final saved = revision == null
        ? 'No configuration saved yet'
        : 'Configuration revision ${revision.revisionNumber}';
    return SingleChildScrollView(
      key: _scrollKey,
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    saved,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              for (final banner in _banners(data)) ...[
                const SizedBox(height: 20),
                banner,
              ],
              const SizedBox(height: 20),
              if (draft != null)
                Opacity(
                  opacity: _saving ? 0.6 : 1,
                  child: IgnorePointer(
                    ignoring: _saving,
                    child: ConfigurationSections(
                      data: data,
                      draft: draft,
                      registry: _registry,
                      sectionKeys: _sectionKeys,
                      editable: editable,
                      inlineReadiness: inline,
                      onChanged: _changed,
                      onFix: _fix,
                      onOpenLandings: () => context.go(landingsPath),
                      onOpenParticipants: () => context.go(participantsPath),
                      onGoToMatrix: _goToMatrix,
                      onOpenWorkspace: () =>
                          context.go(contestWorkspacePath(widget.contestId)),
                    ),
                  ),
                )
              else if (inline)
                MatrixReadinessPanel(
                  summary: ReadinessSummary.of(data, null),
                  onFix: _fix,
                  onGoToMatrix: _goToMatrix,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _banners(ConfigurationData data) {
    final contest = data.contest;
    return [
      if (contest.adminLock == AdminLock.locked)
        ConfigBanner(
          icon: Icons.lock_outline,
          title: 'Administration is locked',
          body:
              'The configuration is read-only while administration is locked. '
              'Unlock it from the Workspace.',
          actionLabel: 'Go to Workspace',
          onAction: () => context.go(contestWorkspacePath(widget.contestId)),
        )
      else if (data.phase == ConfigPhase.completed)
        const ConfigBanner(
          icon: Icons.flag_outlined,
          title: 'Contest completed',
          body:
              'The configuration is read-only. Only score corrections remain, '
              'and those are made on the Scoring page.',
        ),
      if (data.configuration == null)
        const ConfigBanner(
          icon: Icons.info_outline,
          info: true,
          title: 'Configuration not saved yet',
          body:
              'This contest has no saved configuration, and its discipline '
              'can’t be chosen on this page. Create the contest again with '
              'the New contest wizard to set one.',
        ),
      if (data.phase.isRunning && !data.readOnly)
        const ConfigBanner(
          icon: Icons.play_circle_outline,
          title: 'Scoring has started',
          body:
              'Structural settings, discipline options and the landing table '
              'are fixed. Scoring settings can still change; saving them '
              'recalculates all results.',
        ),
    ];
  }
}
