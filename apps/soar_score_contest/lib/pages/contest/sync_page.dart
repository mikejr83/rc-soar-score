import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/sync/app_sync.dart';
import '../../services/sync/refused_change.dart';
import '../../widgets/contest_scope.dart';
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
    final contest = ContestScope.maybeOf(context)?.contest;
    final zoneId = contest?.timezone ?? 'UTC';
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
                zoneId: zoneId,
                onSyncNow: syncing || (summary?.localOnly ?? true)
                    ? null
                    : () => unawaited(sync.syncNow(scope)),
              ),
              const SizedBox(height: 16),
              _Refused(
                sync: sync,
                scope: scope,
                zoneId: zoneId,
                // A new count means the list changed.
                version: summary?.rejectedChanges ?? 0,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Loads the refused changes and reloads them when [version] changes.
class _Refused extends StatefulWidget {
  const _Refused({
    required this.sync,
    required this.scope,
    required this.zoneId,
    required this.version,
  });

  final AppSync sync;
  final SyncScopeKey scope;
  final String zoneId;
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
  Widget build(BuildContext context) =>
      RefusedChangesCard(changes: _changes, zoneId: widget.zoneId);
}
