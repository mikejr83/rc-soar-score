import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../app_sync_provider.dart';
import '../../services/sync/app_sync.dart';
import '../../services/sync/sync_scope_summary.dart';

/// Builds from the sync summary of [scope], reading it once from the local
/// store when it first appears and again whenever the engine reports.
///
/// Builds with a null summary until the first read finishes, and always when
/// the build does not synchronize ([AppSync.available] is false).
class SyncSummaryBuilder extends StatefulWidget {
  const SyncSummaryBuilder({
    super.key,
    required this.scope,
    required this.builder,
  });

  final SyncScopeKey scope;

  final Widget Function(
    BuildContext context,
    AppSync sync,
    SyncScopeSummary? summary,
    bool syncing,
  )
  builder;

  @override
  State<SyncSummaryBuilder> createState() => _SyncSummaryBuilderState();
}

class _SyncSummaryBuilderState extends State<SyncSummaryBuilder> {
  AppSync? _sync;
  StreamSubscription<Object?>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sync = appSyncOf(context);
    if (identical(sync, _sync)) return;
    unawaited(_subscription?.cancel());
    _sync = sync;
    if (!sync.available) return;
    _subscription = sync.states.listen((_) {
      if (mounted) setState(() {});
    });
    unawaited(sync.refresh(widget.scope));
  }

  @override
  void didUpdateWidget(SyncSummaryBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sync = _sync;
    if (sync != null && sync.available && oldWidget.scope != widget.scope) {
      unawaited(sync.refresh(widget.scope));
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = _sync ?? appSyncOf(context);
    final state = sync.state;
    return widget.builder(context, sync, state.of(widget.scope), state.syncing);
  }
}
