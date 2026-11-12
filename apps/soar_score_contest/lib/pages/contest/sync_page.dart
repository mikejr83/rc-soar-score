import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/sync/app_sync.dart';
import '../../services/sync/conflict_answer.dart';
import '../../services/sync/open_conflict.dart';
import '../../services/sync/refused_change.dart';
import '../../widgets/app_version_label.dart';
import '../../widgets/sync/conflict_resolve_dialog.dart';
import '../../widgets/sync/conflicts_card.dart';
import '../../widgets/sync/refused_changes_card.dart';
import '../../widgets/sync/sync_details_card.dart';
import '../../widgets/sync/sync_summary_builder.dart';

/// The sync details of one contest: what is waiting, what was refused, why a
/// sync failed, and a button to sync now.
class ContestSyncPage extends StatelessWidget {
  const ContestSyncPage({super.key, required this.contestId});

  final String contestId;

  @override
  Widget build(BuildContext context) {
    final scope = ContestScopeKey(Id.parse(contestId));
    return Scaffold(
      body: SyncSummaryBuilder(
        scope: scope,
        builder: (context, sync, summary, syncing) {
          if (!sync.available) {
            return const Center(
              child: Text('Syncing is only used in the Windows app.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SyncDetailsCard(
                summary: summary,
                syncing: syncing,
                onSyncNow: syncing || (summary?.localOnly ?? true)
                    ? null
                    : () => unawaited(sync.syncNow(scope)),
              ),
              const SizedBox(height: 16),
              _Conflicts(
                sync: sync,
                scope: scope,
                version: summary?.conflicts ?? 0,
              ),
              const SizedBox(height: 16),
              _Refused(
                sync: sync,
                scope: scope,
                // A new count means the list changed.
                version: summary?.rejectedChanges ?? 0,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: AppVersionLabel(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The account's own sync conflicts, including remembered pilot links.
class DirectorSyncPage extends StatelessWidget {
  const DirectorSyncPage({super.key, required this.scope});

  final SyncScopeKey scope;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account sync')),
    body: SyncSummaryBuilder(
      scope: scope,
      builder: (context, sync, summary, syncing) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SyncDetailsCard(
            summary: summary,
            syncing: syncing,
            onSyncNow: syncing || (summary?.localOnly ?? true)
                ? null
                : () => unawaited(sync.syncNow(scope)),
          ),
          const SizedBox(height: 16),
          _Conflicts(
            sync: sync,
            scope: scope,
            version: summary?.conflicts ?? 0,
          ),
          const SizedBox(height: 16),
          _Refused(
            sync: sync,
            scope: scope,
            version: summary?.rejectedChanges ?? 0,
          ),
        ],
      ),
    ),
  );
}

/// Loads the refused changes and reloads them when [version] changes.
class _Refused extends StatefulWidget {
  const _Refused({
    required this.sync,
    required this.scope,
    required this.version,
  });

  final AppSync sync;
  final SyncScopeKey scope;
  final int version;

  @override
  State<_Refused> createState() => _RefusedState();
}

class _RefusedState extends State<_Refused> {
  List<RefusedChange>? _changes;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_Refused oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version != widget.version) unawaited(_load());
  }

  Future<void> _load() async {
    final changes = await widget.sync.refusedChanges(widget.scope);
    if (mounted) setState(() => _changes = changes);
  }

  @override
  Widget build(BuildContext context) => RefusedChangesCard(changes: _changes);
}

/// Loads the open conflicts, reloads them when [version] changes and opens the
/// dialog that decides one.
class _Conflicts extends StatefulWidget {
  const _Conflicts({
    required this.sync,
    required this.scope,
    required this.version,
  });

  final AppSync sync;
  final SyncScopeKey scope;
  final int version;

  @override
  State<_Conflicts> createState() => _ConflictsState();
}

class _ConflictsState extends State<_Conflicts> {
  List<OpenConflict>? _conflicts;

  // Conflicts the service accepted a decision for. The local record stays
  // pending until a sync stores the answer, so they are hidden meanwhile and
  // cannot be decided twice.
  final _decided = <Id>{};
  bool _reviewing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_Conflicts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version != widget.version) unawaited(_load());
  }

  Future<void> _load() async {
    final conflicts = await widget.sync.openConflicts(widget.scope);
    if (mounted) {
      setState(() {
        _conflicts = [
          for (final conflict in conflicts)
            if (!_decided.contains(conflict.id)) conflict,
        ];
      });
    }
  }

  Future<void> _review(OpenConflict conflict) async {
    if (_reviewing) return;
    _reviewing = true;
    final answer = await showDialog<ConflictAnswer>(
      context: context,
      builder: (_) => ConflictResolveDialog(
        conflict: conflict,
        onResolve: (choice, payload) => widget.sync.resolveConflict(
          widget.scope,
          conflict,
          choice,
          payload: payload,
        ),
      ),
    );
    _reviewing = false;
    if (!mounted) return;
    if (answer != null && answer.resolved) {
      _decided.add(conflict.id);
      final problem = answer.refreshProblem;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            problem == null
                ? 'Decision saved.'
                : 'Decision sent. The sync that follows failed '
                      '(${problem.label.toLowerCase()}), so this screen '
                      'updates after the next successful sync.',
          ),
        ),
      );
    }
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) => ConflictsCard(
    conflicts: _conflicts,
    onReview: (conflict) => unawaited(_review(conflict)),
  );
}
