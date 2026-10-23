import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../connectivity_provider.dart';
import '../ui_account_provider.dart';
import '../services/workspace/shell_round_item.dart';
import '../services/workspace/workspace_facts_loader.dart';

final Logger _logger = Logger('ShellRoundLoader');

/// Loads the round being scored for the shell status panel and hands it to
/// [builder] (`null` until known, and when it cannot be read).
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
  final Widget Function(BuildContext context, ShellRoundItem? item) builder;

  @override
  State<ShellRoundLoader> createState() => _ShellRoundLoaderState();
}

class _ShellRoundLoaderState extends State<ShellRoundLoader> {
  ShellRoundItem? _item;
  Object? _loadedFor;

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
    final client = apiClientOf(context);
    if (client == null) {
      _item = null;
      return;
    }
    final offline =
        appConnectivityOf(context)?.internetStatus ==
        ConnectivityStatus.unavailable;
    WorkspaceFactsLoader.load(
      client,
      widget.contest,
      isOffline: offline,
      actingAccountId: uiAccountIdOf(context),
    ).then(
      (facts) {
        if (mounted && _loadedFor == key) {
          setState(() => _item = ShellRoundItem.of(facts));
        }
      },
      onError: (Object error) {
        _logger.warning('Could not read the round of ${widget.contest.id}');
        if (mounted && _loadedFor == key) {
          setState(() => _item = null);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _item);
}
