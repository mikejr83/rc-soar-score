import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../router.dart';
import '../services/configuration/config_impact.dart';
import '../services/configuration/configuration_data.dart';
import '../services/configuration/configuration_draft.dart';
import '../services/configuration/draw_readiness.dart';
import '../widgets/api_error_text.dart';
import '../widgets/configuration/configuration_action_bar.dart';
import '../widgets/configuration/configuration_groups.dart';
import '../widgets/message_view.dart';

/// The configuration of one contest (`plan/ui/contest-administration/
/// contest-workspace.md`): its options in groups, `Save configuration` and
/// `Draw matrix`. Saving never draws a matrix.
class ContestConfigurationPage extends StatefulWidget {
  const ContestConfigurationPage({super.key, required this.contestId});

  final String contestId;

  @override
  State<ContestConfigurationPage> createState() =>
      _ContestConfigurationPageState();
}

class _ContestConfigurationPageState extends State<ContestConfigurationPage> {
  Future<ConfigurationData>? _loading;
  ConfigurationData? _data;
  ConfigurationDraft? _draft;
  bool _saving = false;
  String? _saveError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= _load();
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

  void _show(ConfigurationData data) {
    _data = data;
    final config = data.configuration?.config;
    _draft = config == null ? null : ConfigurationDraft(config);
  }

  void _retry() {
    final loading = _load();
    setState(() {
      _loading = loading;
      _saveError = null;
    });
  }

  bool _warnsBeforeSaving(ConfigurationData data, ConfigurationDraft draft) =>
      (draft.impact == ConfigImpact.matrix && data.matrix != null) ||
      (draft.impact == ConfigImpact.scores &&
          (data.contest.lifecycleState == LifecycleState.running ||
              data.contest.lifecycleState == LifecycleState.completed));

  Future<void> _save() async {
    final data = _data!;
    final draft = _draft!;
    final revision = data.configuration!;
    final client = apiClientOf(context);
    if (_warnsBeforeSaving(data, draft) && !await _confirmSave(draft)) {
      return;
    }
    if (client == null || !mounted) {
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final saved = await client.saveConfiguration(
        data.contest.id,
        SaveConfigurationRequest(
          baseRevisionNumber: revision.revisionNumber,
          disciplineProfileId: revision.disciplineProfileId,
          landingTableId: revision.landingTableId,
          config: draft.build(),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _show(data.withSaved(saved));
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _saveError = apiErrorText(error);
      });
    }
  }

  Future<bool> _confirmSave(ConfigurationDraft draft) async {
    final matrix = draft.impact == ConfigImpact.matrix;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save these changes?'),
        content: Text(
          matrix
              ? 'This changes how the matrix is drawn. The matrix that is '
                    'already drawn no longer matches and has to be redrawn.'
              : 'This changes how scores are calculated. Scores and '
                    'standings are recalculated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-save'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save configuration'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

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
      final draft = _draft;
      final readiness = DrawReadiness.evaluate(
        contest: data.contest,
        configurationProblem: draft == null
            ? 'No configuration is saved yet, so the matrix can’t be drawn.'
            : draft.problem == null
            ? null
            : 'The configuration is not valid yet, so the matrix can’t be '
                  'drawn.',
        scoringPilots: data.scoringPilots,
        matrixDrawn: data.matrix != null,
      );
      final editable =
          data.contest.adminLock == AdminLock.unlocked &&
          data.contest.lifecycleState != LifecycleState.completed;
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          Text(
            'Configuration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(data.contest.name),
          const SizedBox(height: 24),
          ConfigurationGroups(
            data: data,
            draft: draft,
            editable: editable,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 24),
          ConfigurationActionBar(
            canSave:
                editable &&
                draft != null &&
                draft.changed &&
                draft.problem == null,
            saving: _saving,
            onSave: _save,
            problem: _saveError ?? draft?.problem,
            drawReadiness: readiness,
            onDraw: () => context.go(contestMatrixPath(widget.contestId)),
          ),
        ],
      );
    },
  );
}
