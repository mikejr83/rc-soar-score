import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/participants/participant_candidate.dart';
import '../../services/participants/participant_row.dart';
import 'participant_email_text.dart';

/// Finds people by name or email to add to the contest.
///
/// Results say where they came from (remote or your profiles) and which are
/// already selected; selected people can't be added twice. Remote results
/// (when a directory search exists and the app is online) come first.
class ParticipantSearchField extends StatefulWidget {
  const ParticipantSearchField({
    super.key,
    required this.profiles,
    required this.selected,
    required this.onAdd,
    required this.offline,
    this.remote,
    this.onQueryChanged,
  });

  /// The director's own profiles, or `null` while they load.
  final List<ParticipantProfile>? profiles;

  /// Profile ids already in the contest.
  final Set<String> selected;

  final ValueChanged<ParticipantCandidate> onAdd;
  final bool offline;
  final RemoteParticipantSearch? remote;

  /// Called as the text changes, so the page can filter its list with it.
  final ValueChanged<String>? onQueryChanged;

  static const String localLabel = 'Your profiles';

  @override
  State<ParticipantSearchField> createState() => _ParticipantSearchFieldState();
}

class _ParticipantSearchFieldState extends State<ParticipantSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _searchesRemote => widget.remote != null && !widget.offline;

  String get _sourceText {
    if (_searchesRemote) {
      return 'Online: searching remote first, then your profiles';
    }
    if (widget.remote != null) {
      return 'Offline: searching your profiles only';
    }
    return 'Searching your participant profiles';
  }

  Future<Iterable<ParticipantCandidate>> _search(String query) async {
    final local = searchLocalProfiles(widget.profiles ?? const [], query);
    if (!_searchesRemote || query.trim().isEmpty) {
      return local;
    }
    try {
      final remote = await widget.remote!(query);
      final localIds = {for (final c in local) c.profileId};
      return [
        ...remote.where((c) => !localIds.contains(c.profileId)),
        ...local,
      ];
    } on Object {
      return local;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RawAutocomplete<ParticipantCandidate>(
          textEditingController: _controller,
          focusNode: _focus,
          displayStringForOption: (candidate) => candidate.name,
          optionsBuilder: (value) => _search(value.text),
          onSelected: (candidate) {
            if (widget.selected.contains(candidate.profileId.value)) {
              return;
            }
            widget.onAdd(candidate);
            _controller.clear();
            widget.onQueryChanged?.call('');
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
              SearchBar(
                key: const ValueKey('participant-search'),
                controller: controller,
                focusNode: focusNode,
                hintText: 'Enter a name or email to search or filter',
                leading: const Icon(Icons.person_search),
                trailing: [
                  ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              controller.clear();
                              widget.onQueryChanged?.call('');
                            },
                          ),
                  ),
                ],
                onChanged: (value) => widget.onQueryChanged?.call(value),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  scheme.surfaceContainerHighest,
                ),
                constraints: const BoxConstraints(minHeight: 56),
                onSubmitted: (_) => onSubmit(),
              ),
          optionsViewBuilder: (context, onSelected, options) => _ResultsMenu(
            options: options.toList(),
            selected: widget.selected,
            header: _searchesRemote
                ? 'Add from remote and your profiles'
                : 'Add from saved profiles',
            onSelected: onSelected,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                widget.offline ? Icons.cloud_off : Icons.travel_explore,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.profiles == null ? 'Loading people…' : _sourceText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultsMenu extends StatelessWidget {
  const _ResultsMenu({
    required this.options,
    required this.selected,
    required this.header,
    required this.onSelected,
  });

  final List<ParticipantCandidate> options;
  final Set<String> selected;
  final String header;
  final AutocompleteOnSelected<ParticipantCandidate> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Material(
        elevation: 3,
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 360),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Text(
                  header,
                  style: muted?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              for (final candidate in options)
                _result(context, candidate, muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _result(
    BuildContext context,
    ParticipantCandidate candidate,
    TextStyle? muted,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final already = selected.contains(candidate.profileId.value);
    final remote = candidate.source == ParticipantSource.remote;
    final subtitle = [
      candidate.club ?? 'No club',
      'Email: ${candidate.emailStatus.label(AppLocalizations.of(context))}',
    ].join(' · ');
    final (icon, label) = already
        ? (Icons.check, 'Already in this contest')
        : remote
        ? (Icons.cloud_outlined, 'Remote')
        : (Icons.person_outline, ParticipantSearchField.localLabel);
    return Opacity(
      opacity: already ? 0.6 : 1,
      child: ListTile(
        key: ValueKey('search-result-${candidate.profileId.value}'),
        enabled: !already,
        minVerticalPadding: 8,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(initials(candidate.name)),
        ),
        title: Text(candidate.name),
        subtitle: Text(subtitle),
        trailing: Chip(
          avatar: Icon(icon, size: 16),
          label: Text(label),
          visualDensity: VisualDensity.compact,
        ),
        onTap: already ? null : () => onSelected(candidate),
      ),
    );
  }
}
