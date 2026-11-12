import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../connectivity_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../services/workspace/activity/activity_entry.dart';
import '../../services/workspace/activity/activity_log_reader.dart';
import '../../ui_account_provider.dart';
import '../../widgets/page_states/load_failed_view.dart';
import '../../widgets/page_states/page_banner.dart';
import '../../widgets/page_states/page_state_view.dart';
import '../../widgets/sync/reload_on_sync.dart';
import '../../widgets/workspace/activity/activity_entry_tile.dart';

/// The full activity list of one contest: the audit events the Recent
/// activity card shows a few of, newest first and paged, with who and when
/// (in the contest's time zone) and a filter by kind of event.
class ContestActivityPage extends StatefulWidget {
  const ContestActivityPage({super.key, required this.contestId});

  final String contestId;

  @override
  State<ContestActivityPage> createState() => _ContestActivityPageState();
}

class _ContestActivityPageState extends State<ContestActivityPage> {
  Contest? _contest;
  List<ActivityEntry> _entries = const [];
  ActivityLogReader? _reader;
  bool _hasMore = false;
  ActivityFilter _filter = ActivityFilter.all;

  /// Set while the first page of the current filter loads or after it failed.
  bool _loading = true;
  Object? _error;

  /// The contest could not be read (so there is no time zone to show).
  Object? _contestError;

  /// Whether publications are missing because the publishing server did not
  /// answer.
  bool _incomplete = false;

  /// Set while a further page loads or after it failed.
  bool _loadingMore = false;
  bool _moreFailed = false;

  /// Counts reads started, so a slow answer to an older filter is dropped.
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_generation == 0) {
      unawaited(_loadFirst());
    }
  }

  @override
  void didUpdateWidget(ContestActivityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contestId != widget.contestId) {
      _contest = null;
      unawaited(_loadFirst());
    }
  }

  Future<void> _loadFirst() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _contestError = null;
      _moreFailed = false;
      _loadingMore = false;
    });
    final client = apiClientOf(context);
    final publicationClient = publicationClientOf(context);
    final accountId = auditActorIdOf(context);

    Contest? contest = _contest;
    Object? contestError;
    Object? feedError;
    ActivityLogPage? page;
    ActivityLogReader? reader;
    final Id id;
    try {
      if (client == null) {
        throw StateError('No API client is available.');
      }
      id = Id.parse(widget.contestId);
    } on Object catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _contestError = error is ArgumentError ? const _NotFound() : error;
          _loading = false;
        });
      }
      return;
    }
    // The contest (its time zone) and the feed are read on their own: a feed
    // that fails still leaves the page, its filters and the offline notice.
    reader = ActivityLogReader(
      client,
      id,
      filter: _filter,
      publicationClient: publicationClient,
      actingAccountId: accountId,
    );
    await Future.wait<void>([
      if (contest == null)
        client
            .contest(id)
            .then<void>(
              (loaded) => contest = loaded,
              onError: (Object error) => contestError = error,
            ),
      reader.next().then<void>(
        (loaded) => page = loaded,
        onError: (Object error) => feedError = error,
      ),
    ]);
    if (!mounted || generation != _generation) {
      return;
    }
    final read = page;
    setState(() {
      _contest = contest;
      _contestError = contestError;
      _error = feedError;
      _reader = read == null ? null : reader;
      _entries = read?.entries ?? const [];
      _hasMore = read?.hasMore ?? false;
      _incomplete = read?.incomplete ?? false;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    final reader = _reader;
    if (reader == null || _loadingMore) {
      return;
    }
    final generation = _generation;
    setState(() {
      _loadingMore = true;
      _moreFailed = false;
    });
    try {
      final page = await reader.next();
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        // An event logged since the last read moves the older ones down, so a
        // line can come twice; keep the first.
        final seen = {for (final entry in _entries) entry.id};
        _entries = [
          ..._entries,
          for (final entry in page.entries)
            if (seen.add(entry.id)) entry,
        ];
        _hasMore = page.hasMore;
        _incomplete = page.incomplete;
        _loadingMore = false;
      });
    } on Object {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _loadingMore = false;
        _moreFailed = true;
      });
    }
  }

  void _choose(ActivityFilter filter) {
    if (filter == _filter) {
      return;
    }
    _filter = filter;
    unawaited(_loadFirst());
  }

  @override
  Widget build(BuildContext context) => ReloadOnSync.contest(
    contestId: widget.contestId,
    onSynced: () => unawaited(_loadFirst()),
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contest = _contest;
    final error = _contestError ?? _error;
    if (error is _NotFound ||
        (error is ApiHttpError && error.statusCode == 404)) {
      return PageStateView.notFound(
        title: l10n.activityPageNotFound,
        primary: PageStateAction(
          key: const ValueKey('activity-page-back'),
          label: l10n.shellNavContests,
          onPressed: () => context.go(homePath),
        ),
      );
    }
    if (contest == null) {
      // The contest, and with it the time zone, is not known yet.
      return _contestError != null
          ? KeyedSubtree(
              key: const ValueKey('activity-page-failed'),
              child: loadFailedView(
                _contestError!,
                title: l10n.activityPageFailed,
                onRetry: () => unawaited(_loadFirst()),
              ),
            )
          : PageStateView.loading(
              key: const ValueKey('activity-page-loading'),
              label: l10n.activityPageLoading,
            );
    }
    final offline =
        appConnectivityOf(context)?.internetStatus ==
        ConnectivityStatus.unavailable;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          key: const ValueKey('activity-page'),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.shellNavActivity,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.activityPageIntro),
            const SizedBox(height: 16),
            if (offline) ...[
              PageBanner(
                key: const ValueKey('activity-page-offline'),
                kind: PageBannerKind.info,
                icon: Icons.cloud_off_outlined,
                shape: PageBannerShape.card,
                text: l10n.activityPageOffline,
              ),
              const SizedBox(height: 16),
            ],
            _FilterBar(selected: _filter, onSelected: _choose),
            const SizedBox(height: 8),
            if (_incomplete && !_loading) ...[
              PageBanner(
                key: const ValueKey('activity-page-incomplete'),
                kind: PageBannerKind.status,
                icon: Icons.warning_amber_outlined,
                shape: PageBannerShape.card,
                text: l10n.activityPageIncomplete,
                actionLabel: l10n.activityRetry,
                onAction: () => unawaited(_loadFirst()),
              ),
              const SizedBox(height: 8),
            ],
            ..._body(context, contest, l10n),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    Contest contest,
    AppLocalizations l10n,
  ) {
    final error = _error;
    if (_loading) {
      return [
        SizedBox(
          height: 240,
          child: PageStateView.loading(
            key: const ValueKey('activity-list-loading'),
            label: l10n.activityPageLoading,
          ),
        ),
      ];
    }
    if (error != null) {
      return [
        SizedBox(
          height: 320,
          child: KeyedSubtree(
            key: const ValueKey('activity-list-failed'),
            child: loadFailedView(
              error,
              title: l10n.activityPageFailed,
              onRetry: () => unawaited(_loadFirst()),
            ),
          ),
        ),
      ];
    }
    if (_entries.isEmpty && !_hasMore) {
      final filtered = _filter != ActivityFilter.all;
      return [
        SizedBox(
          height: 320,
          child: PageStateView.empty(
            key: const ValueKey('activity-list-empty'),
            title: filtered
                ? l10n.activityPageEmptyFiltered
                : l10n.activityPageEmpty,
            body: filtered ? l10n.activityPageEmptyFilteredBody : null,
            primary: filtered
                ? PageStateAction(
                    key: const ValueKey('activity-clear-filter'),
                    label: l10n.activityPageShowEverything,
                    onPressed: () => _choose(ActivityFilter.all),
                  )
                : null,
          ),
        ),
      ];
    }
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return [
      Card(
        key: const ValueKey('activity-list'),
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            for (final entry in _entries)
              ActivityEntryTile(
                contest: contest,
                entry: entry,
                showActor: true,
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (_loadingMore)
        const Center(child: CircularProgressIndicator())
      else if (_moreFailed)
        Wrap(
          key: const ValueKey('activity-more-failed'),
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(l10n.activityPageMoreFailed, style: muted),
            TextButton(
              key: const ValueKey('activity-more-retry'),
              onPressed: () => unawaited(_loadMore()),
              child: Text(l10n.activityRetry),
            ),
          ],
        )
      else if (_hasMore)
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const ValueKey('activity-load-more'),
            onPressed: () => unawaited(_loadMore()),
            child: Text(l10n.activityPageLoadMore),
          ),
        )
      else
        Text(
          l10n.activityPageEnd,
          key: const ValueKey('activity-end'),
          style: muted,
        ),
    ];
  }
}

class _NotFound {
  const _NotFound();
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final ActivityFilter selected;
  final ValueChanged<ActivityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String label(ActivityFilter filter) => switch (filter) {
      ActivityFilter.all => l10n.activityFilterAll,
      ActivityFilter.contest => l10n.activityFilterContest,
      ActivityFilter.scores => l10n.activityFilterScores,
      ActivityFilter.configuration => l10n.activityFilterConfiguration,
      ActivityFilter.matrix => l10n.activityFilterMatrix,
      ActivityFilter.publication => l10n.activityFilterPublication,
    };
    return Semantics(
      container: true,
      label: l10n.activityFilterLabel,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in ActivityFilter.values)
            ChoiceChip(
              key: ValueKey('activity-filter-${filter.name}'),
              label: Text(label(filter)),
              selected: filter == selected,
              onSelected: (_) => onSelected(filter),
            ),
        ],
      ),
    );
  }
}
