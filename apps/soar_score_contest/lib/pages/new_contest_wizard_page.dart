import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../connectivity_provider.dart';
import '../contest_draft_provider.dart';
import '../services/new_contest/contest_draft.dart';
import '../services/new_contest/contest_draft_store.dart';
import '../services/new_contest/draft_validation.dart';
import '../services/new_contest/participant_option.dart';
import '../services/new_contest/wizard_discipline.dart';
import '../widgets/new_contest/contest_details_section.dart';
import '../widgets/new_contest/copy_source_section.dart';
import '../widgets/new_contest/discipline_step.dart';
import '../widgets/new_contest/participant_options_step.dart';
import '../widgets/new_contest/wizard_banner.dart';
import '../widgets/new_contest/wizard_confirm_dialog.dart';
import '../widgets/new_contest/wizard_dot_stepper.dart';
import '../widgets/new_contest/wizard_footer.dart';
import '../widgets/new_contest/wizard_step_list.dart';
import '../widgets/new_contest/wizard_step_status.dart';
import '../widgets/unsaved_changes_guard.dart';

/// The New Contest wizard (`/contest-administration/contests/new`).
///
/// It replaces the shell's content area; the rail, header and status bar
/// stay, because connectivity changes what the copy source can do. Wide
/// windows show a vertical step list, narrow ones a row of step markers.
/// Every change is saved to the user's single draft, so going back, jumping
/// to a visited step or leaving loses nothing; leaving only warns when
/// something is actually unsaved.
///
/// Steps 1 to 3 are built. Steps 4 to 7 are listed and reachable but not
/// built yet, so the wizard cannot go past step 4.
class NewContestWizardPage extends StatefulWidget {
  const NewContestWizardPage({super.key, this.guard});

  /// Lets the route's `onExit` ask before leaving with unsaved changes.
  final UnsavedChangesGuard? guard;

  /// The window width from which the step list sits beside the content.
  static const double wideWidth = 1100;

  static const List<String> stepTitles = [
    'Details & copy source',
    'Discipline',
    'Participant options',
    'Participants',
    'Scoring & publication',
    'Draw options',
    'Summary & create',
  ];

  static const List<String> stepIntros = [
    'Name the contest and say where it’s held. You can also start from an '
        'earlier contest.',
    'Choose one discipline. It sets the default task, landing bonus and '
        'scoring rules.',
    'Turn on only what this contest needs. Each option adds columns to the '
        'Participants step.',
    'Add pilots and helpers. Every scoring pilot needs the columns marked '
        'with *.',
    'Review the defaults for this discipline and change anything this '
        'contest does differently.',
    'Set how pilots are grouped. You draw the matrix after the contest is '
        'created.',
    'Check each section, then create the contest.',
  ];

  /// The steps built so far; later steps show a placeholder.
  static const int builtSteps = 3;

  static const String leftMessage =
      'Left the wizard. Your draft is kept until you close the app.';

  @override
  State<NewContestWizardPage> createState() => _NewContestWizardPageState();
}

class _NewContestWizardPageState extends State<NewContestWizardPage> {
  ContestDraftStore? _ownStore;
  late ContestDraftStore _store;
  late int _step;
  bool _initialized = false;
  final Set<int> _tried = {};
  final Map<DetailsField, FocusNode> _detailsFocus = {
    for (final field in DetailsField.values) field: FocusNode(),
  };
  final FocusNode _teamCountFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.guard?.attach(_confirmLeave);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final shared = contestDraftStoreOf(context);
    _store = shared ?? (_ownStore = ContestDraftStore());
    // Resume where the user got to, up to the first step not built yet.
    _step = _store.draft.visitedThrough.clamp(
      1,
      NewContestWizardPage.builtSteps + 1,
    );
    if (_store.savedAt == null) {
      // Start the draft once the first frame is built; saving notifies the
      // header, which is building now.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _store.savedAt == null) {
          unawaited(_store.update(_store.draft));
        }
      });
    }
  }

  @override
  void dispose() {
    widget.guard?.detach(_confirmLeave);
    _ownStore?.dispose();
    for (final node in _detailsFocus.values) {
      node.dispose();
    }
    _teamCountFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ContestDraft get _draft => _store.draft;

  void _update(ContestDraft draft) => unawaited(_store.update(draft));

  void _message(String text) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  bool get _offline =>
      appConnectivityOf(context)?.internetStatus ==
      ConnectivityStatus.unavailable;

  // --- Validation ---------------------------------------------------------

  /// Whether step [step] is valid, or `null` for steps not built yet.
  bool? _valid(int step) => switch (step) {
    1 => DraftValidation.details(_draft).isEmpty,
    2 => DraftValidation.discipline(_draft) == null,
    3 => DraftValidation.teamPilotCount(_draft) == null,
    _ => null,
  };

  /// Whether step [step] shows its errors (after trying to continue, or as
  /// soon as a typed team count is invalid).
  bool _showErrors(int step) =>
      _tried.contains(step) ||
      (step == 3 && _draft.teamPilotCount.trim().isNotEmpty);

  List<WizardStepEntry> get _entries => [
    for (var n = 1; n <= NewContestWizardPage.stepTitles.length; n++)
      WizardStepEntry(
        number: n,
        title: NewContestWizardPage.stepTitles[n - 1],
        status: _status(n),
      ),
  ];

  WizardStepStatus _status(int n) {
    final current = n == _step;
    final visited = n <= _draft.visitedThrough;
    final valid = _valid(n);
    final error = visited && valid == false && (!current || _showErrors(n));
    if (error) {
      return current
          ? WizardStepStatus.currentNeedsAttention
          : WizardStepStatus.needsAttention;
    }
    if (current) {
      return WizardStepStatus.current;
    }
    if (visited && valid == true) {
      return WizardStepStatus.complete;
    }
    return visited ? WizardStepStatus.visited : WizardStepStatus.notStarted;
  }

  // --- Navigation ---------------------------------------------------------

  void _go(int step) {
    setState(() => _step = step);
    if (step > _draft.visitedThrough) {
      _update(_draft.copyWith(visitedThrough: step));
    }
    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
    final view = View.of(context);
    unawaited(
      SemanticsService.sendAnnouncement(
        view,
        'Step $step of ${NewContestWizardPage.stepTitles.length}, '
        '${NewContestWizardPage.stepTitles[step - 1]}.',
        Directionality.of(context),
      ),
    );
  }

  void _next() {
    if (_valid(_step) == false) {
      setState(() => _tried.add(_step));
      return;
    }
    _go(_step + 1);
  }

  bool get _unsaved =>
      _store.saveFailed || (_showErrors(_step) && _valid(_step) == false);

  Future<bool> _confirmLeave() async {
    if (!mounted) {
      return true;
    }
    if (_unsaved) {
      final leave = await showWizardConfirmDialog(
        context,
        icon: Icons.logout,
        title: 'Leave new contest?',
        body:
            'Your draft is kept until you close the app. You can finish it '
            'later from Contests.',
        warning: _store.saveFailed
            ? 'Your latest changes couldn’t be saved and will be lost.'
            : 'Fields with errors on this step need fixing before the '
                  'contest can be created.',
        cancelLabel: 'Keep editing',
        confirmLabel: 'Leave',
      );
      if (!leave) {
        return false;
      }
    }
    if (mounted) {
      _message(NewContestWizardPage.leftMessage);
    }
    return true;
  }

  // --- Step actions -------------------------------------------------------

  Future<void> _selectDiscipline(WizardDiscipline discipline) async {
    final current = _draft.discipline;
    if (current == null) {
      _update(_draft.copyWith(discipline: discipline));
      return;
    }
    final change = await showWizardConfirmDialog(
      context,
      icon: Icons.swap_horiz,
      title: 'Change discipline to ${discipline.name}?',
      body:
          'Some values set for ${current.name} don’t apply to '
          '${discipline.name} and will be cleared:',
      items: [
        WizardConfirmItem(
          Icons.remove_circle_outline,
          '${current.name} landing-bonus table',
        ),
        WizardConfirmItem(
          Icons.remove_circle_outline,
          '${current.name}-specific rules (${current.rules.first})',
        ),
        const WizardConfirmItem(
          Icons.remove_circle_outline,
          'Group-score mode and precision, reset to the new defaults',
        ),
      ],
      footnote: 'Details, participants and draw options stay as they are.',
      cancelLabel: 'Keep ${current.name}',
      confirmLabel: 'Change and clear',
    );
    if (change && mounted) {
      _update(_draft.copyWith(discipline: discipline));
      _message(
        'Discipline changed to ${discipline.name}. Incompatible values were '
        'cleared.',
      );
    }
  }

  Future<void> _toggleOption(ParticipantOption option, bool value) async {
    final options = {..._draft.options};
    if (value) {
      options.add(option);
      _update(_draft.copyWith(options: options));
      return;
    }
    options.remove(option);
    if (option != ParticipantOption.teams) {
      _update(_draft.copyWith(options: options));
      return;
    }
    final participants = _draft.participants;
    if (participants.isNotEmpty) {
      final assigned = participants.where((p) => p.team.trim().isNotEmpty);
      final teams = {for (final p in assigned) p.team.trim().toLowerCase()}
          .length;
      final nonPilots = participants.where((p) => !p.isPilot).length;
      final turnOff = await showWizardConfirmDialog(
        context,
        icon: Icons.group_off,
        title: 'Turn off teams?',
        items: [
          WizardConfirmItem(
            Icons.group_off,
            'Team assignments are removed from ${assigned.length} '
            'participant${assigned.length == 1 ? '' : 's'} '
            '($teams team${teams == 1 ? '' : 's'}).',
          ),
          WizardConfirmItem(
            Icons.person_remove,
            nonPilots == 1
                ? '1 participant who isn’t a pilot is removed from the '
                      'contest.'
                : '$nonPilots participants who aren’t pilots are removed '
                      'from the contest.',
          ),
          const WizardConfirmItem(
            Icons.grid_view,
            'Check the group size in Draw options. Team protection no longer '
            'sets a minimum.',
          ),
        ],
        cancelLabel: 'Keep teams',
        confirmLabel: 'Turn off and remove',
      );
      if (!turnOff || !mounted) {
        return;
      }
      _message(
        'Teams turned off. Team assignments and non-pilots were removed.',
      );
    }
    _update(
      _draft.copyWith(
        options: options,
        teamPilotCount: '',
        participants: [
          for (final p in participants)
            if (p.isPilot) p.copyWith(team: ''),
        ],
      ),
    );
  }

  // --- Building -----------------------------------------------------------

  List<Widget> _banners() {
    final banners = <Widget>[];
    if (_store.saveFailed) {
      banners.add(
        WizardBanner(
          key: const ValueKey('banner-save-failed'),
          tone: WizardBannerTone.error,
          icon: Icons.sync_problem,
          title: 'Draft not saved',
          body:
              'Your last changes weren’t saved. Everything you entered is '
              'still on screen.',
          actions: [
            WizardBannerAction(
              key: const ValueKey('draft-retry'),
              label: 'Retry save',
              onPressed: () async {
                await _store.retry();
                if (mounted && !_store.saveFailed) {
                  _message('Draft saved.');
                }
              },
            ),
            WizardBannerAction(
              label: 'Cancel',
              onPressed: _store.dismissFailure,
            ),
          ],
        ),
      );
    }
    if (!_showErrors(_step)) {
      return banners;
    }
    final links = <WizardBannerLink>[];
    switch (_step) {
      case 1:
        for (final MapEntry(key: field, value: error)
            in DraftValidation.details(_draft).entries) {
          links.add(
            WizardBannerLink(
              text: '${field.label}: $error',
              onTap: () => _detailsFocus[field]!.requestFocus(),
            ),
          );
        }
      case 2:
        final error = DraftValidation.discipline(_draft);
        if (error != null) {
          links.add(WizardBannerLink(text: error, onTap: () {}));
        }
      case 3:
        if (DraftValidation.teamPilotCount(_draft) != null) {
          links.add(
            WizardBannerLink(
              text:
                  'Pilots counted for team score: enter a whole number above '
                  '0.',
              onTap: _teamCountFocus.requestFocus,
            ),
          );
        }
    }
    if (links.isNotEmpty) {
      final n = links.length;
      banners.add(
        WizardBanner(
          key: const ValueKey('banner-validation'),
          tone: WizardBannerTone.error,
          icon: Icons.error,
          title:
              '$n field${n == 1 ? ' needs' : 's need'} attention before you '
              'continue',
          links: links,
        ),
      );
    }
    return banners;
  }

  Widget _stepContent(bool narrow) => switch (_step) {
    1 => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContestDetailsSection(
          draft: _draft,
          onChanged: _update,
          focusNodes: _detailsFocus,
          showErrors: _showErrors(1),
          narrow: narrow,
        ),
        const SizedBox(height: 20),
        CopySourceSection(
          draft: _draft,
          onChanged: _update,
          offline: _offline,
          onMessage: _message,
        ),
      ],
    ),
    2 => DisciplineStep(
      selected: _draft.discipline,
      onSelect: (discipline) => unawaited(_selectDiscipline(discipline)),
    ),
    3 => ParticipantOptionsStep(
      draft: _draft,
      onToggle: (option, value) => unawaited(_toggleOption(option, value)),
      onTeamPilotCount: (value) =>
          _update(_draft.copyWith(teamPilotCount: value)),
      teamPilotCountFocus: _teamCountFocus,
      showErrors: _showErrors(3),
    ),
    _ => const _NotBuiltYet(),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final wide =
          MediaQuery.sizeOf(context).width >= NewContestWizardPage.wideWidth;
      final entries = _entries;
      final titles = NewContestWizardPage.stepTitles;
      final last = _step == titles.length;
      final built = _step <= NewContestWizardPage.builtSteps;

      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'STEP $_step OF ${titles.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Semantics(
                            header: true,
                            child: Text(
                              titles[_step - 1],
                              key: const ValueKey('wizard-step-title'),
                              style: theme.textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Text(
                              NewContestWizardPage.stepIntros[_step - 1],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          for (final banner in _banners()) ...[
                            const SizedBox(height: 20),
                            banner,
                          ],
                          const SizedBox(height: 20),
                          _stepContent(!wide),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          WizardFooter(
            onBack: _step > 1 ? () => _go(_step - 1) : null,
            primaryLabel: last ? 'Create contest' : 'Next: ${titles[_step]}',
            showArrow: !last,
            onPrimary: _next,
            blocked: built
                ? null
                : const WizardBlockedReason(text: 'This step isn’t built yet.'),
          ),
        ],
      );

      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WizardStepList(steps: entries, onSelect: _go),
            Expanded(child: content),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WizardDotStepper(steps: entries, onSelect: _go),
          Expanded(child: content),
        ],
      );
    },
  );
}

/// The placeholder for steps 4 to 7 until they are built.
class _NotBuiltYet extends StatelessWidget {
  const _NotBuiltYet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('wizard-step-not-built'),
      margin: EdgeInsets.zero,
      elevation: 1,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.construction, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This step isn’t built yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Participants, scoring, draw options and the summary come '
                    'in a later update. Your draft keeps everything you '
                    'entered in the earlier steps.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
