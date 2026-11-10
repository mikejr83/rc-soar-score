import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../app_sync_provider.dart';
import '../../services/sync/app_sync.dart';

/// Calls [onSynced] when [scope] has synced since this widget was built.
///
/// A page that loads data once goes stale when a sync pulls changes into the
/// local store: nothing else announces a pulled change (the database's own
/// change stream skips them on purpose). Wrap the part of the page that shows
/// synced data in this and reload there. The old content stays on screen, so
/// [onSynced] should reload quietly rather than show a loading state.
///
/// Builds without sync ([AppSync.available] false, as on web) never call back.
class ReloadOnSync extends StatefulWidget {
  const ReloadOnSync({
    super.key,
    required this.scope,
    required this.onSynced,
    required this.child,
  });

  final SyncScopeKey scope;

  final VoidCallback onSynced;

  final Widget child;

  @override
  State<ReloadOnSync> createState() => _ReloadOnSyncState();
}

class _ReloadOnSyncState extends State<ReloadOnSync> {
  AppSync? _sync;
  StreamSubscription<Object?>? _subscription;
  DateTime? _seen;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sync = appSyncOf(context);
    if (identical(sync, _sync)) return;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _sync = sync;
    if (!sync.available) return;
    _seen = sync.state.of(widget.scope)?.lastSyncedAt;
    _subscription = sync.states.listen((_) => _check());
  }

  @override
  void didUpdateWidget(ReloadOnSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) {
      // A different contest: what it last synced is not news.
      _seen = _sync?.state.of(widget.scope)?.lastSyncedAt;
    }
  }

  void _check() {
    if (!mounted) return;
    final synced = _sync?.state.of(widget.scope)?.lastSyncedAt;
    if (synced == null || synced == _seen) return;
    _seen = synced;
    widget.onSynced();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
