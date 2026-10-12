import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import 'contest_scope.dart';

/// Loads the selected contest through the app's API client and hands it to
/// [builder], so the shell header, status panel and window title share one
/// load.
///
/// The contest is `null` when none is selected ([contestId] is `null`),
/// while loading, when no client is available, or when the contest cannot
/// be loaded; the routed page reports those errors. A [ContestScope] below
/// this widget lets a page ask for a reload.
class ContestNameLoader extends StatefulWidget {
  const ContestNameLoader({
    super.key,
    required this.contestId,
    required this.builder,
  });

  final String? contestId;
  final Widget Function(BuildContext context, Contest? contest) builder;

  @override
  State<ContestNameLoader> createState() => _ContestNameLoaderState();
}

class _ContestNameLoaderState extends State<ContestNameLoader> {
  Future<Contest>? _contest;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _contest = _load();
    }
  }

  @override
  void didUpdateWidget(ContestNameLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contestId != widget.contestId) {
      _contest = _load();
    }
  }

  Future<bool> _reload() async {
    final contest = _load();
    setState(() {
      _contest = contest;
    });
    if (contest == null) {
      return false;
    }
    try {
      await contest;
      return true;
    } on Object {
      return false;
    }
  }

  Future<Contest>? _load() {
    final contestId = widget.contestId;
    final client = apiClientOf(context);
    if (contestId == null || client == null) {
      return null;
    }
    final Id id;
    try {
      id = Id.parse(contestId);
    } on ArgumentError {
      return null;
    }
    final contest = client.contest(id);
    // The builder subscribes on the next frame; a failure that arrives
    // sooner would otherwise be reported as unhandled.
    contest.ignore();
    return contest;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Contest>(
    future: _contest,
    builder: (context, snapshot) {
      final contest = widget.contestId == null ? null : snapshot.data;
      return ContestScope(
        contest: contest,
        error: widget.contestId == null ? null : snapshot.error,
        reload: _reload,
        child: Builder(builder: (context) => widget.builder(context, contest)),
      );
    },
  );
}
