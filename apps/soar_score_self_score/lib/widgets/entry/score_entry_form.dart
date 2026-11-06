import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/self_score_repository.dart';
import '../../data/self_score_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../models/entry_context.dart';
import '../../models/landing_result.dart';
import '../../models/score_submission.dart';
import '../../router.dart';
import '../../services/flight_time_input.dart';
import '../../services/score_components.dart';
import '../../session/guest_session_scope.dart';
import '../../session/score_draft_store.dart';
import '../landing_control.dart';
import '../status_chip.dart';
import 'entry_number_field.dart';
import 'entry_toggle_row.dart';

/// The F5J score entry form for one flight. Submit is final: the form then
/// becomes read-only and the button goes away.
class ScoreEntryForm extends StatefulWidget {
  const ScoreEntryForm({
    required this.contestId,
    required this.pilotId,
    required this.data,
    super.key,
  });

  final String contestId;
  final String pilotId;
  final EntryContext data;

  @override
  State<ScoreEntryForm> createState() => _ScoreEntryFormState();
}

/// Where the flight's score is in its way to the server.
enum _Phase {
  /// The pilot is typing.
  editing,

  /// Sent, no answer yet.
  sending,

  /// The server could not be reached. The score is kept and sent again.
  queued,

  /// The server has the score; the form is read-only.
  accepted,
}

class _ScoreEntryFormState extends State<ScoreEntryForm> {
  final _time = TextEditingController();
  final _height = TextEditingController();
  final _penalty = TextEditingController(text: '0');

  LandingResult? _landing;
  bool _lateLanding = false;
  bool _motorRestart = false;
  bool _outOfBounds = false;
  bool _noAltitude = false;
  _Phase _phase = _Phase.editing;
  PendingSubmission? _pending;

  /// The server's own calculation, once it accepted the score.
  String? _flightScore;
  bool _alreadyThere = false;
  ScoreDetails? _details;

  /// Why the server refused the last send, in words for the pilot.
  String? _rejection;
  Set<String> _rejectedFields = const {};
  Timer? _retryTimer;
  bool _restored = false;

  bool get _submitted => _phase == _Phase.accepted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    if (widget.data.alreadySubmitted) {
      _phase = _Phase.accepted;
      return;
    }
    final draft = context.scoreDrafts.read(
      widget.contestId,
      widget.pilotId,
      widget.data.round,
    );
    if (draft == null) return;
    _time.text = draft.time;
    _height.text = draft.height;
    _penalty.text = draft.penalty;
    _lateLanding = draft.lateLanding;
    _motorRestart = draft.motorRestart && widget.data.allowsMotorRestart;
    _outOfBounds = draft.outOfBounds;
    _noAltitude = draft.noAltitude;
    _landing = [
      for (final option in widget.data.landingTable)
        if (option.id == draft.landingId) option,
    ].firstOrNull;
    _pending = draft.pending;
    if (_pending != null) {
      // The last send never got an answer: send it again with the same id.
      _phase = _Phase.sending;
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }
  }

  /// [setState] that also keeps the draft on this phone.
  void _update(VoidCallback change) {
    setState(change);
    _saveDraft();
  }

  void _saveDraft() {
    if (_submitted) return;
    context.scoreDrafts.write(
      widget.contestId,
      widget.pilotId,
      widget.data.round,
      ScoreDraft(
        time: _time.text,
        height: _height.text,
        penalty: _penalty.text,
        landingId: _landing?.id,
        lateLanding: _lateLanding,
        motorRestart: _motorRestart,
        outOfBounds: _outOfBounds,
        noAltitude: _noAltitude,
        pending: _pending,
      ),
    );
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _time.dispose();
    _height.dispose();
    _penalty.dispose();
    super.dispose();
  }

  /// Out of bounds, motor restart and no altitude recorded each score the
  /// flight as zero, so time, height and landing are cleared and disabled.
  bool get _zeroed => _outOfBounds || _motorRestart || _noAltitude;

  FlightTimeInput get _timeInput => FlightTimeInput.parse(_time.text);
  int? get _heightValue => int.tryParse(_height.text.trim());
  int? get _penaltyValue => int.tryParse(_penalty.text.trim());

  String? get _heightError {
    if (_zeroed || _height.text.trim().isEmpty) return null;
    final value = _heightValue;
    return value == null || value <= 0
        ? 'Enter whole metres above zero.'
        : null;
  }

  String? get _penaltyError =>
      _penalty.text.trim().isNotEmpty && (_penaltyValue ?? -1) < 0
      ? 'Enter whole points, zero or more.'
      : null;

  bool get _canSubmit {
    if (_phase != _Phase.editing ||
        _penaltyValue == null ||
        _penaltyError != null) {
      return false;
    }
    if (_zeroed) return true;
    if (!_timeInput.isValid) return false;
    if ((_heightValue ?? 0) <= 0) return false;
    return _lateLanding || _landing != null;
  }

  String get _summary {
    // Penalty is rare, so it is named only when one is entered.
    final penalty = (_penaltyValue ?? 0) > 0 ? 'Penalty entered' : null;
    if (_zeroed) {
      return ['Zero for the flight: $_zeroReason', ?penalty].join(' · ');
    }
    final parts = <String>[
      if (_timeInput.seconds case final seconds?)
        FlightTimeInput.format(seconds),
      if (_heightValue != null) '$_heightValue m',
      if (_lateLanding)
        'late landing'
      else if (_landing != null)
        'landing ${_landing!.points}',
      ?penalty,
    ];
    return parts.join(' · ');
  }

  String get _zeroReason => [
    if (_outOfBounds) 'out of bounds',
    if (_motorRestart) 'motor restart',
    if (_noAltitude) 'no altitude recorded',
  ].join(', ');

  void _setZeroing({bool? outOfBounds, bool? motorRestart, bool? noAltitude}) {
    _update(() {
      _outOfBounds = outOfBounds ?? _outOfBounds;
      _motorRestart = motorRestart ?? _motorRestart;
      _noAltitude = noAltitude ?? _noAltitude;
      if (_zeroed) {
        _time.clear();
        _height.clear();
        _landing = null;
      }
    });
  }

  static final _random = Random();

  String _newMutationId() =>
      'entry-${widget.pilotId}-${widget.data.round}-'
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

  void _submit() {
    if (!_canSubmit) return;
    // One id per attempt; a retry reuses it so the server never stores the
    // score twice.
    _pending = PendingSubmission(
      mutationId: _newMutationId(),
      matrixRevision: widget.data.matrixRevision,
    );
    _rejection = null;
    _rejectedFields = const {};
    _update(() => _phase = _Phase.sending);
    _send();
  }

  Map<String, Object?> get _components => buildF5jComponents(
    seconds: _timeInput.seconds,
    height: _heightValue,
    landingId: _landing?.id,
    lateLanding: _lateLanding,
    motorRestart: _motorRestart,
    outOfBounds: _outOfBounds,
    noAltitude: _noAltitude,
    penalty: _penaltyValue,
  );

  Future<void> _send() async {
    final pending = _pending;
    if (pending == null) return;
    _retryTimer?.cancel();
    final repository = context.repository;
    final drafts = context.scoreDrafts;
    final sessions = context.guestSessions;
    final components = _components;
    try {
      final result = await repository.submitScore(
        ScoreSubmission(
          contestId: widget.contestId,
          pilotId: widget.pilotId,
          round: widget.data.round,
          matrixRevision: pending.matrixRevision,
          clientMutationId: pending.mutationId,
          components: components,
        ),
      );
      if (!mounted) return;
      switch (result) {
        case ScoreAccepted(:final flightScore, :final details):
          _accept(flightScore, details, alreadyThere: false);
        case ScoreAlreadySubmitted(:final flightScore, :final details):
          _accept(flightScore, details, alreadyThere: true);
        case ScoreRejected(:final code):
          // The server ended the session: drop it so nothing routes from it.
          if (code == 'session_invalid') sessions.clear();
          // Nothing was stored. The next try is a new attempt with a new id.
          setState(() {
            _pending = null;
            _phase = _Phase.editing;
            _rejection = _rejectionText(result);
            _rejectedFields = result.fields.toSet();
          });
          _saveDraft();
      }
      if (_submitted) {
        drafts.clear(widget.contestId, widget.pilotId, widget.data.round);
      }
    } on SelfScoreOfflineException {
      if (!mounted) return;
      setState(() => _phase = _Phase.queued);
      _retryTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _phase == _Phase.queued) {
          setState(() => _phase = _Phase.sending);
          _send();
        }
      });
    } on SelfScoreLoadException catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _phase = _Phase.editing;
        _rejection = error.message;
      });
      _saveDraft();
    }
  }

  void _accept(
    String? flightScore,
    ScoreDetails? details, {
    required bool alreadyThere,
  }) {
    setState(() {
      _phase = _Phase.accepted;
      _pending = null;
      _flightScore = flightScore;
      _details = details;
      _alreadyThere = alreadyThere;
      _rejection = null;
    });
  }

  /// What the server made of the score, in its own numbers.
  String _acceptedLine(AppLocalizations l10n) {
    final score = _flightScore;
    if (_alreadyThere) {
      return score == null
          ? l10n.scoreAlreadyThere
          : l10n.scoreAlreadyThereWith(score);
    }
    if (score == null) return l10n.scoreAcceptedNoValue;
    // Only an official score is called official; until then it is the
    // server's calculation and can still change.
    return _details?.official ?? false
        ? l10n.scoreAcceptedLine(score)
        : l10n.scoreCalculatedLine(score);
  }

  /// The numbers the server kept with the score, one per line.
  List<String> _detailLines(AppLocalizations l10n) {
    final details = _details;
    if (details == null) return const [];
    return [
      if (details.rawScore case final value?) l10n.scoreRawLine(value),
      if (details.roundScore case final value?) l10n.scoreRoundLine(value),
      if (details.cumulativePenalty case final value?)
        l10n.scorePenaltyLine(value),
      if (details.enteredBy case final name?) l10n.scoreEnteredByLine(name),
    ];
  }

  String _rejectionText(ScoreRejected rejected) {
    final l10n = AppLocalizations.of(context);
    return switch (rejected.code) {
      'validation_failed' => l10n.scoreRejectedValidation,
      'scoring_closed' => l10n.scoreRejectedClosed,
      'out_of_order' => l10n.scoreRejectedOutOfOrder,
      'stale_matrix' => l10n.scoreRejectedStaleDraw,
      'session_invalid' => l10n.scoreRejectedSession,
      _ => l10n.scoreRejectedOther,
    };
  }

  String? get _landingReason {
    if (_zeroed) {
      return 'The flight scores zero ($_zeroReason), so landing is not '
          'scored.';
    }
    if (_lateLanding) return 'Late landing is on, so landing is cleared.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timeError = _timeInput.error;
    final timeSeconds = _timeInput.seconds;
    final l10n = AppLocalizations.of(context);
    final editable = _phase == _Phase.editing;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            alignment: Alignment.centerLeft,
            foregroundColor: scheme.primary,
          ),
          onPressed: () =>
              context.go(pilotPath(widget.contestId, widget.pilotId)),
          icon: const Icon(Icons.format_list_bulleted, size: 20),
          label: Text('All rounds for ${widget.data.pilotName}'),
        ),
        Text(
          'Rounds you have scored show View. Submitted scores are '
          'read-only. Review requests are made from View.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_submitted) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(
              label: 'Submitted',
              icon: Icons.check_circle_outline,
              style: StatusChipStyle.tonal,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_rejection case final message?) ...[
          Semantics(
            liveRegion: true,
            child: Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: scheme.onErrorContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_phase == _Phase.queued) ...[
          Semantics(
            liveRegion: true,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scoreQueuedTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.scoreQueuedBody,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () {
                        _update(() => _phase = _Phase.sending);
                        _send();
                      },
                      child: Text(l10n.scoreRetryNow),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        EntryNumberField(
          label: 'Time flown',
          controller: _time,
          enabled: editable && !_zeroed,
          allowDecimal: true,
          onChanged: (_) => _update(() {}),
          errorText:
              timeError ??
              (_rejectedFields.contains('time_flown') ? ' ' : null),
          hint: timeSeconds == null
              ? 'Type 630 for 6:30. Type 630.4 for 6:30.4.'
              : 'Reads as ${FlightTimeInput.format(timeSeconds)}.',
        ),
        const SizedBox(height: 18),
        EntryNumberField(
          label: 'Launch height (m)',
          controller: _height,
          enabled: editable && !_zeroed,
          onChanged: (_) => _update(() {}),
          errorText:
              _heightError ??
              (_rejectedFields.contains('launch_height') ? ' ' : null),
          hint: _zeroed
              ? 'The flight scores zero, so no height is needed.'
              : 'Whole metres. Zero is not valid.',
        ),
        const SizedBox(height: 18),
        Text(
          'Landing',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        LandingControl(
          table: widget.data.landingTable,
          selected: _landing,
          disabledReason: !editable
              ? (_submitted ? 'Submitted.' : 'Waiting to send.')
              : _landingReason,
          onChanged: (value) => _update(() => _landing = value),
        ),
        const SizedBox(height: 18),
        EntryToggleRow(
          label: 'Late landing',
          value: _lateLanding,
          onChanged: editable && !_zeroed
              ? (value) => _update(() {
                  _lateLanding = value;
                  if (value) _landing = null;
                })
              : null,
        ),
        if (widget.data.allowsMotorRestart)
          EntryToggleRow(
            label: 'Motor restart',
            hint: 'Time, height and landing are zeroed.',
            value: _motorRestart,
            onChanged: editable
                ? (value) => _setZeroing(motorRestart: value)
                : null,
          ),
        EntryToggleRow(
          label: 'Out of bounds',
          hint: 'Landed more than 75 m from the marker.',
          value: _outOfBounds,
          onChanged: editable
              ? (value) => _setZeroing(outOfBounds: value)
              : null,
        ),
        EntryToggleRow(
          label: 'No altitude recorded',
          hint: 'Time, height and landing are zeroed.',
          value: _noAltitude,
          onChanged: editable
              ? (value) => _setZeroing(noAltitude: value)
              : null,
        ),
        const SizedBox(height: 18),
        EntryNumberField(
          label: 'Flight penalty (points)',
          controller: _penalty,
          enabled: editable,
          onChanged: (_) => _update(() {}),
          errorText: _penaltyError,
          hint:
              'For an infraction on this flight, such as flying outside '
              'your group. Dropped if this round is dropped.',
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _submitted ? 'Submitted score' : 'Check before you submit',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.data.alreadySubmitted)
                  Text(
                    l10n.scoreExistingReadOnly,
                    style: theme.textTheme.titleMedium,
                  )
                else ...[
                  Text(
                    _summary,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (_submitted) ...[
                    const SizedBox(height: 8),
                    Text(
                      _acceptedLine(l10n),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    for (final line in _detailLines(l10n))
                      Text(line, style: theme.textTheme.bodyMedium),
                  ],
                ],
                const SizedBox(height: 8),
                Text(
                  _submitted
                      ? 'This flight is read-only.'
                      : 'Submit is final. After you submit, this flight '
                            'is read-only.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_submitted) ...[
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: _canSubmit ? _submit : null,
            child: Text(
              _phase == _Phase.editing ? 'Submit score' : l10n.scoreSending,
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => context.go(
              groupResultsPath(
                widget.contestId,
                widget.pilotId,
                '${widget.data.round}',
              ),
            ),
            child: const Text('See group results'),
          ),
        ],
      ],
    );
  }
}
