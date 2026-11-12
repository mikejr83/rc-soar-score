import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../connectivity_provider.dart';
import '../ui_account_provider.dart';
import '../services/workspace/shell_round_item.dart';
import '../services/workspace/workspace_facts_loader.dart';
import 'sync/reload_on_sync.dart';

final Logger _logger = Logger('ShellRoundLoader');

/// Loads the round being scored for the shell status panel and hands it to
/// [builder] (`null` until known, and when it cannot be read). While a newer
/// read is under way `refreshing` is true and the last value is stale, so the
/// builder must not offer it as a link.
///
/// It loads again when the contest or the shown page [path] changes, so
/// leaving the scoring page after a save brings the value up to date.
class ShellRoundLoader extends StatefulWidget {
  const ShellRoundLoader({
    super.key,
    required this.contest,
    required this.path,
    required this.builder,
  });

  final Contest contest;
  final String path;
  final Widget Function(
    BuildContext context,
    ShellRoundItem? item,
    bool refreshing,
  )
  builder;

  @override
  State<ShellRoundLoader> createState() => _ShellRoundLoaderState();
}

class _ShellRoundLoaderState extends State<ShellRoundLoader> {
  ShellRoundItem? _item;
  Object? _loadedFor;
  bool _refreshing = false;

  // Counts the loads started: a sync reload has the same (contest, path) key
  // as the load it replaces, so only the newest load may apply its answer.
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensure();
  }

  @override
  void didUpdateWidget(ShellRoundLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensure();
  }

  void _ensure() {
    final key = (widget.contest, widget.path);
    if (_loadedFor == key) {
      return;
    }
    if (_loadedFor is (Contest, String) &&
        (_loadedFor! as (Contest, String)).$1.id != widget.contest.id) {
      _item = null;
    }
    _loadedFor = key;
    final generation = ++_generation;
    final client = apiClientOf(context);
    if (client == null) {
      _item = null;
      _refreshing = false;
      return;
    }
    _refreshing = true;
    final offline =
        appConnectivityOf(context)?.internetStatus ==
        ConnectivityStatus.unavailable;
    WorkspaceFactsLoader.load(
      client,
      widget.contest,
      publicationClient: publicationClientOf(context),
      isOffline: offline,
      actingAccountId: auditActorIdOf(context),
    ).then(
      (facts) {
        if (mounted && _loadedFor == key && _generation == generation) {
          setState(() {
            _item = ShellRoundItem.of(facts);
            _refreshing = false;
          });
        }
      },
      onError: (Object error) {
        _logger.warning('Could not read the round of ${widget.contest.id}');
        if (mounted && _loadedFor == key && _generation == generation) {
          setState(() {
            _item = null;
            _refreshing = false;
          });
        }
      },
    );
  }

  // A sync can move the round on (a score arrived), so the entry reads the
  // facts again. The old entry stays until the new one is ready.
  void _onSynced() {
    _loadedFor = null;
    setState(_ensure);
  }

  @override
  Widget build(BuildContext context) => ReloadOnSync(
    scope: ContestScopeKey(widget.contest.id),
    onSynced: _onSynced,
    child: widget.builder(context, _item, _refreshing),
  );
}
