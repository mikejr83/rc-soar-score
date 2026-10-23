import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/entry_context.dart';
import '../../models/landing_result.dart';
import '../../router.dart';
import '../../services/flight_time_input.dart';
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

class _ScoreEntryFormState extends State<ScoreEntryForm> {
  final _time = TextEditingController();
  final _height = TextEditingController();
  final _penalty = TextEditingController(text: '0');

  LandingResult? _landing;
  bool _lateLanding = false;
  bool _motorRestart = false;
  bool _outOfBounds = false;
  bool _noAltitude = false;
  bool _submitted = false;

  @override
  void dispose() {
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
    if (_submitted || _penaltyValue == null || _penaltyError != null) {
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
    setState(() {
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

  void _submit() {
    if (!_canSubmit) return;
    setState(() => _submitted = true);
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
    final editable = !_submitted;
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
        EntryNumberField(
          label: 'Time flown',
          controller: _time,
          enabled: editable && !_zeroed,
          allowDecimal: true,
          onChanged: (_) => setState(() {}),
          errorText: timeError,
          hint: timeSeconds == null
              ? 'Type 630 for 6:30. Type 630.4 for 6:30.4.'
              : 'Reads as ${FlightTimeInput.format(timeSeconds)}.',
        ),
        const SizedBox(height: 18),
        EntryNumberField(
          label: 'Launch height (m)',
          controller: _height,
          enabled: editable && !_zeroed,
          onChanged: (_) => setState(() {}),
          errorText: _heightError,
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
          disabledReason: !editable ? 'Submitted.' : _landingReason,
          onChanged: (value) => setState(() => _landing = value),
        ),
        const SizedBox(height: 18),
        EntryToggleRow(
          label: 'Late landing',
          value: _lateLanding,
          onChanged: editable && !_zeroed
              ? (value) => setState(() {
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
          onChanged: (_) => setState(() {}),
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
                Text(
                  _summary,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
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
            child: const Text('Submit score'),
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
