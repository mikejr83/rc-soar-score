import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../services/new_contest/contest_draft.dart';
import '../../services/new_contest/copy_mode.dart';
import '../../services/new_contest/copy_source.dart';
import '../../services/new_contest/copy_source_loader.dart';
import '../../services/new_contest/date_range_text.dart';
import '../../services/new_contest/draft_copy.dart';
import 'choose_pilots_dialog.dart';
import 'copy_mode_picker.dart';
import 'copy_summary.dart';
import 'source_contest_tile.dart';
import 'wizard_section_card.dart';

/// Where the copy source picker looks.
enum _SourceTab { local, public }

/// Step 1's optional copy source: the copy mode, the source contest (with
/// loading and failed states), the pilots for a fly-off, and a summary.
///
/// Local contests are always available. Public contests can be searched
/// only when online, which the picker says when offline.
class CopySourceSection extends StatefulWidget {
  const CopySourceSection({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.offline,
    this.onMessage,
  });

  final ContestDraft draft;
  final ValueChanged<ContestDraft> onChanged;
  final bool offline;

  /// Shows a short confirmation (a snackbar).
  final ValueChanged<String>? onMessage;

  /// Where this app's own contests live: the device on native builds, the
  /// account on the web (which stores no contest data locally).
  static const String localLabel = kIsWeb ? 'Your contests' : 'On this device';

  @override
  State<CopySourceSection> createState() => _CopySourceSectionState();
}

class _CopySourceSectionState extends State<CopySourceSection> {
  _SourceTab _tab = _SourceTab.local;
  Future<List<Contest>>? _contests;
  Contest? _loading;
  Contest? _failed;
  int _attempt = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contests ??= _loadContests();
  }

  Future<List<Contest>> _loadContests() {
    final client = apiClientOf(context);
    if (client == null) {
      return Future.error(StateError('No API client is available.'));
    }
    return client.contests();
  }

  Future<void> _use(Contest contest) async {
    final client = apiClientOf(context);
    final attempt = ++_attempt;
    setState(() {
      _loading = contest;
      _failed = null;
    });
    try {
      if (client == null) {
        throw StateError('No API client is available.');
      }
      final source = await loadCopySource(client, contest);
      if (!mounted || attempt != _attempt) {
        return;
      }
      setState(() => _loading = null);
      widget.onChanged(widget.draft.withSource(source));
    } on Object {
      if (!mounted || attempt != _attempt) {
        return;
      }
      setState(() {
        _loading = null;
        _failed = contest;
      });
    }
  }

  void _remove() {
    _attempt++;
    setState(() {
      _loading = null;
      _failed = null;
    });
    if (widget.draft.source != null) {
      widget.onChanged(widget.draft.withoutSource());
    }
    widget.onMessage?.call('Source removed. You can continue without copying.');
  }

  void _setMode(CopyMode mode) {
    final draft = widget.draft.copyWith(copyMode: mode);
    if (!mode.usesSource) {
      _attempt++;
      setState(() {
        _loading = null;
        _failed = null;
      });
      widget.onChanged(draft.source == null ? draft : draft.withoutSource());
      return;
    }
    widget.onChanged(draft.withCopiedPilots());
  }

  Future<void> _choosePilots(CopySource source) async {
    final chosen = await showChoosePilotsDialog(
      context,
      pilots: source.pilots,
      selected: widget.draft.selectedPilots,
    );
    if (chosen != null && mounted) {
      widget.onChanged(
        widget.draft.copyWith(selectedPilots: chosen).withCopiedPilots(),
      );
    }
  }

  String _contestLine(Contest contest, {int? pilots, String? discipline}) => [
    dateRangeText(contest.startDateTime, contest.endDateTime),
    ?discipline,
    if (pilots != null) '$pilots pilot${pilots == 1 ? '' : 's'}',
    CopySourceSection.localLabel,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final draft = widget.draft;
    final mode = draft.copyMode;
    final source = draft.source;

    return WizardSectionCard(
      title: 'Copy from an existing contest',
      trailing: 'Optional',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CopyModePicker(value: mode, onChanged: _setMode),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.block, size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Copying never brings scores, the flight matrix, '
                    'publication history, invitations or audit history.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          if (mode.usesSource) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              'Source contest',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (source != null)
              _chosenSource(source)
            else if (_loading != null)
              _loadingSource(_loading!)
            else if (_failed != null)
              _failedSource(_failed!)
            else
              _picker(),
            if (source != null && mode == CopyMode.selectedPilots) ...[
              const SizedBox(height: 16),
              _pilotSubset(source),
            ],
            if (source != null) ...[
              const SizedBox(height: 16),
              CopySummary(draft: draft),
            ],
          ],
        ],
      ),
    );
  }

  Widget _chosenSource(CopySource source) => SourceContestTile(
    key: const ValueKey('copy-source-chosen'),
    icon: Icons.event,
    name: source.contest.name,
    subtitle: _contestLine(
      source.contest,
      pilots: source.pilots.length,
      discipline: source.discipline?.name,
    ),
    outlined: true,
    trailing: OutlinedButton.icon(
      key: const ValueKey('copy-source-remove'),
      onPressed: _remove,
      icon: const Icon(Icons.close, size: 18),
      label: const Text('Remove source'),
    ),
  );

  Widget _loadingSource(Contest contest) => Semantics(
    liveRegion: true,
    child: SourceContestTile(
      key: const ValueKey('copy-source-loading'),
      icon: Icons.event,
      name: contest.name,
      subtitle: 'Loading configuration and pilot list…',
      outlined: true,
      trailing: TextButton(onPressed: _remove, child: const Text('Cancel')),
      footer: const LinearProgressIndicator(),
    ),
  );

  Widget _failedSource(Contest contest) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onErrorContainer,
    );
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('copy-source-failed'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off, color: scheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Couldn’t load “${contest.name}”',
                          style: style?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'The contest didn’t load. Retry, or remove the '
                          'source and continue without copying.',
                          style: style,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: const ValueKey('copy-source-retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: () => _use(contest),
                  child: const Text('Retry'),
                ),
                OutlinedButton(
                  key: const ValueKey('copy-source-remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onErrorContainer,
                    side: BorderSide(color: scheme.onErrorContainer),
                  ),
                  onPressed: _remove,
                  child: const Text('Remove source'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _picker() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final offline = widget.offline;
    Widget tab(_SourceTab value, String label, IconData icon) {
      final selected = _tab == value;
      final color = selected ? scheme.primary : scheme.onSurfaceVariant;
      return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          key: ValueKey('copy-source-tab-${value.name}'),
          onTap: () => setState(() => _tab = value),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Wrap(
            children: [
              tab(
                _SourceTab.local,
                CopySourceSection.localLabel,
                kIsWeb ? Icons.event : Icons.devices,
              ),
              tab(
                _SourceTab.public,
                offline ? 'Public (needs connection)' : 'Public',
                offline ? Icons.cloud_off : Icons.public,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_tab == _SourceTab.local)
          _localContests()
        else if (offline)
          _note(
            Icons.cloud_off,
            'You’re offline. Public contests can be searched when you’re back '
            'online. ${CopySourceSection.localLabel} are still available.',
            key: const ValueKey('copy-source-public-offline'),
          )
        else
          _note(
            Icons.public,
            'Searching public contests isn’t available yet. Copy from '
            '${CopySourceSection.localLabel.toLowerCase()} for now.',
            key: const ValueKey('copy-source-public-unavailable'),
          ),
      ],
    );
  }

  Widget _note(IconData icon, String text, {Key? key}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }

  Widget _localContests() => FutureBuilder<List<Contest>>(
    future: _contests,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Row(
          children: [
            Expanded(
              child: _note(
                Icons.error_outline,
                'Contests could not be loaded.',
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _contests = _loadContests()),
              child: const Text('Retry'),
            ),
          ],
        );
      }
      final contests = snapshot.data;
      if (contests == null) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (contests.isEmpty) {
        return _note(Icons.event_busy, 'There are no contests to copy yet.');
      }
      final primary = Theme.of(context).colorScheme.primary;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final contest in contests)
            SourceContestTile(
              key: ValueKey('copy-source-${contest.id.value}'),
              icon: Icons.event,
              name: contest.name,
              subtitle: _contestLine(contest),
              onTap: () => unawaited(_use(contest)),
              trailing: Text(
                'Use',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: primary),
              ),
            ),
        ],
      );
    },
  );

  Widget _pilotSubset(CopySource source) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chosen = widget.draft.participants;
    final names = chosen.take(3).map((pilot) => pilot.name).join(', ');
    final more = chosen.length > 3 ? ' and ${chosen.length - 3} more' : '';
    return Container(
      key: const ValueKey('copy-source-subset'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${chosen.length} of ${source.pilots.length} pilots '
                        'selected',
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        chosen.isEmpty ? 'No pilots chosen yet' : '$names$more',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            key: const ValueKey('copy-source-choose-pilots'),
            onPressed: source.pilots.isEmpty
                ? null
                : () => unawaited(_choosePilots(source)),
            child: const Text('Choose pilots'),
          ),
        ],
      ),
    );
  }
}
