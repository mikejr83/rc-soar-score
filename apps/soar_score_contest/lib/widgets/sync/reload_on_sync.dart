import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../app_sync_provider.dart';
import '../../services/sync/app_sync.dart';

/// Calls [onSynced] when a sync has changed [scope]'s data since this widget
/// was built: it pulled changes in or the service accepted ours. A sync that
/// changed nothing is not news.
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
    required SyncScopeKey this.scope,
    required this.onSynced,
    required this.child,
  }) : anyContest = false;

  /// Watches the signed-in account's own data scope (contest list,
  /// participants, roles, landing tables). Nothing fires while nobody is
  /// signed in.
  const ReloadOnSync.account({
    super.key,
    required this.onSynced,
    required this.child,
  }) : scope = null,
       anyContest = false;

  /// Watches the account's contest list: the account's own scope and every
  /// contest scope. A contest the account owns arrives, is renamed or changes
  /// state through its own contest scope, not through the account's.
  const ReloadOnSync.contests({
    super.key,
    required this.onSynced,
    required this.child,
  }) : scope = null,
       anyContest = true;

  /// Watches the contest with the route id [contestId]. An id that does not
  /// parse leaves [child] as it is: the page shows its own not-found state.
  static Widget contest({
    Key? key,
    required String contestId,
    required VoidCallback onSynced,
    required Widget child,
  }) {
    final Id id;
    try {
      id = Id.parse(contestId);
    } on ArgumentError {
      return child;
    }
    return ReloadOnSync(
      key: key,
      scope: ContestScopeKey(id),
      onSynced: onSynced,
      child: child,
    );
  }

  /// The contest scope to watch for the contest's own pages; [account] for
  /// the pages of the signed-in account.
  final SyncScopeKey? scope;

  /// Whether every contest scope counts too, besides [scope] or the account's.
  final bool anyContest;

  final VoidCallback onSynced;

  final Widget child;

  @override
  State<ReloadOnSync> createState() => _ReloadOnSyncState();
}

class _ReloadOnSyncState extends State<ReloadOnSync> {
  AppSync? _sync;
  StreamSubscription<Object?>? _subscription;
  int _seen = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sync = appSyncOf(context);
    if (identical(sync, _sync)) return;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _sync = sync;
    if (!sync.available) return;
    _seen = _revision(sync);
    _subscription = sync.states.listen((_) => _check());
  }

  @override
  void didUpdateWidget(ReloadOnSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope ||
        oldWidget.anyContest != widget.anyContest) {
      // A different contest: what it last synced is not news.
      final sync = _sync;
      _seen = sync == null ? 0 : _revision(sync);
    }
  }

  int _revision(AppSync sync) {
    final scope = widget.scope ?? sync.accountScope;
    var total = scope == null ? 0 : sync.state.of(scope)?.dataRevision ?? 0;
    if (widget.anyContest) {
      for (final entry in sync.state.scopes.entries) {
        if (entry.key is ContestScopeKey) total += entry.value.dataRevision;
      }
    }
    return total;
  }

  void _check() {
    if (!mounted) return;
    final sync = _sync;
    final revision = sync == null ? 0 : _revision(sync);
    if (revision == _seen) return;
    _seen = revision;
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
