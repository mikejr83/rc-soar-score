import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/participants/directory_pilot_source.dart';

import 'package:soar_score_api/soar_score_api.dart';

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
    this.lookup,
    this.onQueryChanged,
  });

  /// The director's own profiles, or `null` while they load.
  final List<ParticipantProfile>? profiles;

  /// Profile ids already in the contest.
  final Set<String> selected;

  final ValueChanged<ParticipantCandidate> onAdd;
  final bool offline;
  final RemoteParticipantSearch? remote;

  /// Looks the typed text up in the directory on purpose, for an ID the typing
  /// rules skip. Shown as a button while the app is online.
  final RemoteParticipantSearch? lookup;

  /// Called as the text changes, so the page can filter its list with it.
  final ValueChanged<String>? onQueryChanged;

  @override
  State<ParticipantSearchField> createState() => _ParticipantSearchFieldState();
}

class _ParticipantSearchFieldState extends State<ParticipantSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _looking = false;

  /// Counts every edit or clear of the text, so an explicit lookup that
  /// comes back after one is ignored.
  int _edits = 0;
  String? _lookedUp;
  List<ParticipantCandidate>? _found;
  bool _lookupFailed = false;

  /// The server refused a lookup because this account asked too often.
  bool _rateLimited = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _searchesRemote => widget.remote != null && !widget.offline;

  String _sourceText(AppLocalizations l10n) {
    if (_searchesRemote) {
      return l10n.searchOnline;
    }
    if (widget.remote != null) {
      return l10n.searchOffline;
    }
    return l10n.searchProfiles;
  }

  /// Counts typed searches and explicit lookups, so a typed search that is
  /// overtaken (more typing, a clear, or a lookup on purpose) cannot show its
  /// rate-limit warning afterwards.
  int _searches = 0;

  Future<Iterable<ParticipantCandidate>> _search(String query) async {
    final mine = ++_searches;
    final local = searchLocalProfiles(widget.profiles ?? const [], query);
    if (!_searchesRemote) return local;
    if (query.trim().isEmpty) {
      // Clearing the text still ends a lookup waiting on an earlier one.
      unawaited(widget.remote!(query).then((_) {}, onError: (Object _) {}));
      return local;
    }
    try {
      final remote = await widget.remote!(query);
      return _arrange(remote, local);
    } on DirectoryRateLimited {
      if (mounted && mine == _searches) setState(() => _rateLimited = true);
      return local;
    } on Object {
      return local;
    }
  }

  /// The directory [remote] results before the director's own [local] ones,
  /// each pilot once.
  List<ParticipantCandidate> _arrange(
    List<ParticipantCandidate> remote,
    List<ParticipantCandidate> local,
  ) {
    final localIds = {for (final c in local) c.profileId};
    final own = widget.profiles ?? const <ParticipantProfile>[];
    // A pilot the director already holds is offered as that profile, whichever
    // identifier matched, even when the typed text is not on the profile (a
    // private email, or a field only the directory has).
    final copies = <ParticipantCandidate>[];
    final shown = {...localIds};
    final fresh = <ParticipantCandidate>[];
    for (final c in remote) {
      final held = c.copiesIn(own);
      if (held.isEmpty) {
        if (!localIds.contains(c.profileId)) fresh.add(c);
        continue;
      }
      for (final p in held) {
        if (shown.add(p.id)) copies.add(ParticipantCandidate.local(p));
      }
    }
    return [...fresh, ...copies, ...local];
  }

  Future<void> _lookUp(String text) async {
    _searches++;
    final asked = _edits;
    setState(() {
      _looking = true;
      _lookupFailed = false;
      _rateLimited = false;
    });
    try {
      final remote = await widget.lookup!(text);
      final local = searchLocalProfiles(widget.profiles ?? const [], text);
      if (!mounted || asked != _edits) return;
      setState(() {
        _lookedUp = text.trim();
        _found = _arrange(remote, local);
        _looking = false;
      });
    } on Object catch (e) {
      if (!mounted || asked != _edits) return;
      final limited = e is DirectoryRateLimited;
      setState(() {
        _lookedUp = text.trim();
        _found = null;
        _lookupFailed = !limited;
        _rateLimited = limited;
        _looking = false;
      });
    }
  }

  void _forgetLookup() {
    _edits++;
    _looking = false;
    _rateLimited = false;
    if (_lookedUp == null && !_lookupFailed) return;
    _lookedUp = null;
    _found = null;
    _lookupFailed = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            // A lookup still waiting must not bring results back under the
            // cleared text. Clearing in a selection does not reach the
            // typed search, so it is overtaken here.
            _searches++;
            setState(_forgetLookup);
            _controller.clear();
            widget.onQueryChanged?.call('');
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
              SearchBar(
                key: const ValueKey('participant-search'),
                controller: controller,
                focusNode: focusNode,
                hintText: l10n.searchHint,
                leading: const Icon(Icons.person_search),
                trailing: [
                  if (widget.lookup != null)
                    ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, value, _) => IconButton(
                        key: const ValueKey('directory-lookup'),
                        tooltip: widget.offline
                            ? l10n.searchDirectoryOffline
                            : l10n.searchDirectoryLookup,
                        icon: const Icon(Icons.manage_search),
                        // The directory is on the server: nothing to ask
                        // while offline.
                        onPressed:
                            widget.offline ||
                                _looking ||
                                value.text.trim().isEmpty
                            ? null
                            : () => unawaited(_lookUp(value.text)),
                      ),
                    ),
                  ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            tooltip: l10n.searchClear,
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(_forgetLookup);
                              controller.clear();
                              widget.onQueryChanged?.call('');
                            },
                          ),
                  ),
                ],
                onChanged: (value) {
                  setState(_forgetLookup);
                  widget.onQueryChanged?.call(value);
                },
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
                ? l10n.searchHeaderRemote
                : l10n.searchHeaderProfiles,
            onSelected: onSelected,
          ),
        ),
        if (_looking) const LinearProgressIndicator(),
        if (_rateLimited)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.searchDirectoryRateLimited,
              key: const ValueKey('directory-lookup-rate-limited'),
            ),
          )
        else if (_lookupFailed)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.searchDirectoryFailed,
              key: const ValueKey('directory-lookup-failed'),
            ),
          )
        else if (_lookedUp != null && (_found?.isEmpty ?? false))
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.searchDirectoryNone(_lookedUp!),
              key: const ValueKey('directory-lookup-none'),
            ),
          )
        else if (_found != null && _found!.isNotEmpty)
          _ResultsMenu(
            options: _found!,
            selected: widget.selected,
            header: l10n.searchDirectoryResults(_lookedUp!),
            onSelected: (candidate) {
              if (widget.selected.contains(candidate.profileId.value)) return;
              widget.onAdd(candidate);
              _searches++;
              setState(() {
                _forgetLookup();
                _controller.clear();
              });
              widget.onQueryChanged?.call('');
            },
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
                  widget.profiles == null
                      ? l10n.searchLoading
                      : _sourceText(l10n),
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final already = selected.contains(candidate.profileId.value);
    final remote = candidate.source == ParticipantSource.remote;
    // Pilots in the directory can share an ID (different countries), so the
    // director tells them apart by what else the entry says.
    final entry = candidate.directory;
    final subtitle = [
      candidate.club ?? l10n.searchNoClub,
      ?_place(entry),
      ?_id(l10n, entry),
      if (candidate.sharedId case final id?) l10n.searchDirectorySharedId(id),
      l10n.searchEmailPrefix(candidate.emailStatus.label(l10n)),
    ].join(' · ');
    final (icon, label) = already
        ? (Icons.check, l10n.searchAlready)
        : remote
        ? (Icons.cloud_outlined, l10n.searchRemote)
        : (Icons.person_outline, l10n.searchYourProfiles);
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

  static String? _place(DirectoryMatchDto? entry) {
    final parts = [
      for (final part in [entry?.city, entry?.state, entry?.country])
        if (part != null && part.trim().isNotEmpty) part.trim(),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _id(AppLocalizations l10n, DirectoryMatchDto? entry) {
    final id = entry?.faiNumber ?? entry?.nationalOrgId;
    return id == null || id.trim().isEmpty ? null : l10n.searchDirectoryId(id);
  }
}
