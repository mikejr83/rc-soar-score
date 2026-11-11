import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../connectivity_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../services/publication/publication_page_data.dart';
import '../../widgets/publication/publication_actions_row.dart';
import '../../widgets/publication/publication_text.dart';
import '../../widgets/workspace/states/workspace_not_found_view.dart';
import '../../widgets/sync/reload_on_sync.dart';

/// The publication of one contest: its state, the public update policy, the
/// latest published copy and the publish and visibility actions.
///
/// A director can also request delisting (and withdraw the request while it
/// waits for a system administrator) and sees every published copy.
class ContestPublicationPage extends StatefulWidget {
  const ContestPublicationPage({super.key, required this.contestId});

  final String contestId;

  @override
  State<ContestPublicationPage> createState() => _ContestPublicationPageState();
}

class _ContestPublicationPageState extends State<ContestPublicationPage> {
  Future<PublicationPageData>? _loading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= _load();
  }

  @override
  void didUpdateWidget(ContestPublicationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contestId != widget.contestId) {
      _loading = _load();
    }
  }

  Future<PublicationPageData> _load() {
    final client = apiClientOf(context);
    if (client == null) {
      return Future.error(StateError('No API client is available.'));
    }
    final Id id;
    try {
      id = Id.parse(widget.contestId);
    } on ArgumentError {
      return Future.error(const _NotFound());
    }
    return PublicationPageData.load(
      client,
      id,
      publicationClient: publicationClientOf(context),
    );
  }

  void _reload() {
    final loading = _load();
    setState(() {
      _loading = loading;
    });
  }

  @override
  Widget build(BuildContext context) => ReloadOnSync.contest(
    contestId: widget.contestId,
    onSynced: _reload,
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monitor = appConnectivityOf(context);
    final offline = monitor?.internetStatus == ConnectivityStatus.unavailable;
    return FutureBuilder<PublicationPageData>(
      future: _loading,
      builder: (context, snapshot) {
        final error = snapshot.error;
        if (error is _NotFound ||
            (error is ApiHttpError && error.statusCode == 404)) {
          return WorkspaceNotFoundView(onBack: () => context.go(homePath));
        }
        final data = snapshot.data;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Card(
                key: const ValueKey('publication-page-card'),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: error != null
                        ? _Failed(onRetry: _reload)
                        : data == null
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _Ready(
                            data: data,
                            isOffline: offline,
                            onChanged: _reload,
                            l10n: l10n,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotFound {
  const _NotFound();
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(
          l10n.publicationPageLoadFailed,
          key: const ValueKey('publication-page-failed'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('publication-page-retry'),
          onPressed: onRetry,
          child: Text(l10n.publicationActionRetry),
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.data,
    required this.isOffline,
    required this.onChanged,
    required this.l10n,
  });

  final PublicationPageData data;
  final bool isOffline;
  final VoidCallback onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final publication = data.publication;
    final projection = publication.projection;
    final policyText = data.policyReadFailed
        ? l10n.publicationPolicyUnreadable
        : l10n.updatePolicy(data.policy);
    final reason = PublicationActionsRow.disabledReason(
      l10n,
      publication,
      isOffline: isOffline,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.publicationCardTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text.rich(
          key: const ValueKey('publication-page-state'),
          TextSpan(
            children: [
              TextSpan(
                text: l10n.publicationState(publication),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          publication.isPublished
              ? policyText
              : l10n.publicationScopeUnpublished,
          key: const ValueKey('publication-page-policy'),
        ),
        if (publication.pendingDelist case final request?) ...[
          const SizedBox(height: 4),
          Text(
            l10n.publicationPageDelistPending(
              l10n.publicationTime(request.requestedAt),
            ),
            key: const ValueKey('publication-page-delist-pending'),
          ),
        ],
        if (data.contest.lifecycleState != LifecycleState.completed) ...[
          const SizedBox(height: 8),
          Text(
            l10n.publicationNotCompletedHint,
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        PublicationActionsRow(
          contest: data.contest,
          publication: publication,
          policyText: policyText,
          isOffline: isOffline,
          onChanged: onChanged,
        ),
        if (reason != null) ...[
          const SizedBox(height: 8),
          Text(
            reason,
            key: const ValueKey('publication-page-reason'),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        Text(
          l10n.publicationPageLatestCopy,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (projection == null)
          Text(
            l10n.publicationPageNoCopy,
            key: const ValueKey('publication-page-no-copy'),
          )
        else
          Column(
            key: const ValueKey('publication-page-copy'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.publicationPageCopyNumber(
                  '${projection.projectionRevision}',
                ),
              ),
              Text(
                l10n.publicationPageFromRevision(
                  '${projection.contestRevision}',
                ),
              ),
              if (projection.publishedAt != null)
                Text(
                  l10n.publicationPagePublishedAt(
                    l10n.publicationTime(projection.publishedAt!),
                  ),
                ),
            ],
          ),
        if (publication.isPublished) ...[
          const SizedBox(height: 24),
          Text(
            l10n.publicationPageHistoryTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (data.historyReadFailed)
            Text(
              l10n.publicationPageHistoryFailed,
              key: const ValueKey('publication-page-history-failed'),
            )
          else
            Column(
              key: const ValueKey('publication-page-history'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in data.history)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      key: ValueKey(
                        'publication-history-${entry.projectionRevision}',
                      ),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.publicationPageHistoryEntry(
                            '${entry.projectionRevision}',
                            '${entry.contestRevision}',
                            l10n.publicationTime(entry.publishedAt),
                          ),
                        ),
                        Text(
                          entry.isBySystem
                              ? l10n.publicationPageHistoryAutomatic
                              : l10n.publicationPageHistoryByYou,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}
