import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../contest_draft_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../services/configuration/configuration_problem.dart';
import '../../services/configuration/draw_readiness.dart';
import '../../services/matrix/draw_form_check.dart';
import '../../services/matrix/draw_form_controller.dart';
import '../../services/matrix/matrix_page_data.dart';
import '../../widgets/api_error_text.dart';
import '../../widgets/matrix/draw_confirm_dialog.dart';
import '../../widgets/matrix/draw_form_panel.dart';
import '../../widgets/matrix/matrix_drawn_view.dart';
import '../../widgets/page_states/page_states.dart';

/// The matrix of one contest (`plan/ui/contest-administration/matrix.md`):
/// the first-draw form until a matrix exists, then the grid with its
/// fairness summary. A failed draw never changes the page or loses the form
/// values.
class MatrixPage extends StatefulWidget {
  const MatrixPage({super.key, required this.contestId});

  final String contestId;

  @override
  State<MatrixPage> createState() => _MatrixPageState();
}

class _MatrixPageState extends State<MatrixPage> {
  Future<MatrixPageData>? _loading;
  MatrixPageData? _data;
  DrawFormController? _form;
  bool _busy = false;
  String? _rejection;
  bool _networkFailure = false;
  bool _conflict = false;

  /// The id of the draw request being sent. Repeating a request with the same
  /// id and numbers returns the matrix it drew, so a retry cannot draw twice.
  Id? _requestId;
  String? _requestKey;

  /// What the server says about the draw being sent, polled while [_busy].
  DrawStatusDto? _progress;
  Timer? _poll;
  Future<void> Function()? _tickNow;
  bool _polling = false;

  /// Whether Cancel was pressed for the draw being sent.
  bool _cancelRequested = false;

  static const Duration _pollEvery = Duration(milliseconds: 400);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _form?.dispose();
    super.dispose();
  }

  Future<MatrixPageData> _load() async {
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
    final data = await MatrixPageData.load(client, id);
    _show(data);
    return data;
  }

  /// Makes [data] the shown data. The form is rebuilt only when it is
  /// needed, so a reload with no matrix keeps what was typed.
  void _show(MatrixPageData data) {
    _data = data;
    if (data.matrix.isEmpty && _form == null) {
      final options = data.options;
      final seeded = options?.drawMode == DrawMode.seededManOnMan;
      // A contest created in the wizard this session carries the draw values
      // the director chose there; after a restart they are gone and the form
      // asks.
      final suggestion = contestDraftStoreOf(context)
          ?.drawSuggestions[data.contest.id];
      final fromConfiguration = seeded ? options?.preliminaryRounds : null;
      _form = DrawFormController(
        configuredRounds:
            fromConfiguration ?? int.tryParse(suggestion?.rounds?.trim() ?? ''),
        roundsSource: fromConfiguration != null
            ? 'contest configuration'
            : 'the New Contest wizard',
        configuredGroups: int.tryParse(suggestion?.groups?.trim() ?? ''),
      )..addListener(_onForm);
    }
  }

  void _onForm() {
    if (mounted) {
      setState(() {});
    }
  }

  void _retry() {
    final loading = _load();
    setState(() {
      _loading = loading;
      _conflict = false;
    });
  }

  Future<void> _reload() async {
    try {
      final data = await _load();
      if (mounted) {
        setState(() {
          _conflict = false;
          _show(data);
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _rejection = apiErrorText(error));
      }
    }
  }

  void _openConfiguration() =>
      context.go(contestConfigurationPath(widget.contestId));

  void _fix(BlockerFix fix) => context.go(switch (fix) {
    BlockerFix.configuration => contestConfigurationPath(widget.contestId),
    BlockerFix.workspace => contestWorkspacePath(widget.contestId),
    BlockerFix.participants => participantsPath,
  });

  String? _configurationProblem(MatrixPageData data) => ConfigurationProblem.of(
    configuration: data.configuration,
    options: data.options,
  );

  DrawBlocker? _blocker(MatrixPageData data) => DrawReadiness.evaluate(
    contest: data.contest,
    configurationProblem: _configurationProblem(data),
    scoringPilots: data.scoringPilots,
    matrixDrawn: false,
  ).first;

  Future<void> _draw() async {
    final data = _data!;
    final form = _form!;
    if (_busy) {
      return;
    }
    form.submitted = true;
    final options = data.options;
    final check = DrawFormCheck.evaluate(
      roundsText: form.rounds.text,
      groupsText: form.groups.text,
      pilots: data.scoringPilots,
      minimumGroups: options?.teamProtection ?? false ? data.largestTeam : 0,
      submitted: true,
    );
    setState(() {
      _rejection = null;
      _networkFailure = false;
    });
    if (!check.valid) {
      return;
    }
    final confirmed = await confirmDraw(
      context,
      data: data,
      rounds: check.rounds!,
      sizes: check.sizes,
      seeded: options?.drawMode == DrawMode.seededManOnMan,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await _send(data, check);
  }

  Future<void> _send(MatrixPageData data, DrawFormCheck check) async {
    final client = apiClientOf(context);
    if (client == null) {
      return;
    }
    final form = _form!;
    final request = DrawMatrixRequest(
      id: _idFor(
        '${check.rounds}/${check.groups}/${form.seed.text}/'
        '${form.attempts.text}/${form.seedCount.text}',
      ),
      rounds: check.rounds!,
      groupsPerRound: check.groups!,
      randomSeed: DrawFormController.optionalNumber(form.seed),
      attemptsPerRound: DrawFormController.optionalNumber(form.attempts),
      seedCount: DrawFormController.optionalNumber(form.seedCount),
    );
    setState(() => _busy = true);
    _watch(client, data.contest.id, request.id);
    try {
      final drawn = await client.drawMatrix(data.contest.id, request);
      if (!mounted) {
        return;
      }
      _unwatch();
      // The draw assigns pilot numbers, so reload to show them.
      MatrixPageData fresh;
      try {
        fresh = await MatrixPageData.load(client, data.contest.id);
      } on Object {
        fresh = data.withMatrix(drawn);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _data = fresh.matrix.isEmpty ? fresh.withMatrix(drawn) : fresh;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Matrix drawn.')));
    } on ApiNetworkError {
      _unwatch();
      if (mounted) {
        setState(() {
          _busy = false;
          _networkFailure = true;
        });
      }
    } on ApiHttpError catch (error) {
      _unwatch();
      if (mounted) {
        final cancelled = error.error?.code == 'draw_cancelled';
        if (cancelled) {
          // The next draw is a new request.
          _requestId = null;
          _requestKey = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).drawCancelled)),
          );
        }
        setState(() {
          _busy = false;
          if (cancelled) {
            // Nothing to show: the form and the page are as they were.
          } else if (error.statusCode == 409) {
            _conflict = true;
          } else {
            _rejection = apiErrorText(error);
          }
        });
      }
    } on Object catch (error) {
      _unwatch();
      if (mounted) {
        setState(() {
          _busy = false;
          _rejection = apiErrorText(error);
        });
      }
    }
  }

  /// Starts asking the server how far the draw [drawId] has come.
  void _watch(ApiClient client, Id contestId, Id drawId) {
    _poll?.cancel();
    _progress = null;
    _cancelRequested = false;
    _tickNow = () => _tick(client, contestId, drawId);
    _poll = Timer.periodic(_pollEvery, (_) => _tickNow!());
  }

  void _unwatch() {
    _poll?.cancel();
    _poll = null;
    _tickNow = null;
    _progress = null;
    _cancelRequested = false;
  }

  /// One poll. After Cancel it asks again to cancel instead, until the server
  /// knows the draw: the draw request may not have reached the draw engine
  /// when Cancel was pressed.
  Future<void> _tick(ApiClient client, Id contestId, Id drawId) async {
    if (_polling) {
      return;
    }
    _polling = true;
    try {
      final status = _cancelRequested
          ? await client.cancelDraw(contestId, drawId)
          : await client.drawStatus(contestId, drawId);
      if (mounted && _busy && status != null) {
        setState(() => _progress = status);
      }
    } on Object {
      // A missed report is not a failure; the draw request has the outcome.
    } finally {
      _polling = false;
    }
  }

  void _cancel() {
    if (!_busy || _cancelRequested) {
      return;
    }
    setState(() => _cancelRequested = true);
    _tickNow?.call();
  }

  Id _idFor(String key) {
    if (_requestKey != key || _requestId == null) {
      _requestKey = key;
      _requestId = Id.create();
    }
    return _requestId!;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MatrixPageData>(
    future: _loading,
    builder: (context, snapshot) {
      final error = snapshot.error;
      if (error != null && _data == null) {
        return _Unavailable(error: error, onRetry: _retry);
      }
      final data = _data;
      if (data == null) {
        return const _Loading();
      }
      if (!data.matrix.isEmpty) {
        return MatrixDrawnView(
          data: data,
          onOpenConfiguration: _openConfiguration,
        );
      }
      final form = _form!;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: DrawFormPanel(
              data: data,
              controller: form,
              busy: _busy,
              progress: _progress,
              cancelling: _cancelRequested,
              onCancel: _cancel,
              blocker: _blocker(data),
              rejection: _rejection,
              networkFailure: _networkFailure,
              conflict: _conflict,
              onDraw: _draw,
              onOpenConfiguration: _openConfiguration,
              onFix: _fix,
              onReload: _reload,
            ),
          ),
        ),
      );
    },
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading matrix',
    child: const Column(
      children: [
        LinearProgressIndicator(),
        Expanded(child: Center(child: Text('Loading matrix…'))),
      ],
    ),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error is! ApiNetworkError) {
      return loadFailedView(
        error,
        title: 'The matrix could not be loaded.',
        onRetry: onRetry,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: scheme.surfaceContainerHigh,
                child: Icon(
                  Icons.cloud_off,
                  size: 32,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Matrix unavailable',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Soar Score can’t reach the server, so the matrix can’t be '
                'shown. Nothing on this contest has changed.',
                textAlign: TextAlign.center,
              ),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
