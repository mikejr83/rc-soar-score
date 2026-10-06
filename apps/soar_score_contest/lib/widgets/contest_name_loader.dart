import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';

/// Loads the selected contest's name through the app's API client and hands
/// it to [builder], so the shell header and the window title share one load.
///
/// The name is `null` when no contest is selected ([contestId] is `null`),
/// while loading, when no client is available, or when the contest cannot
/// be loaded; the routed page reports those errors.
class ContestNameLoader extends StatefulWidget {
  const ContestNameLoader({
    super.key,
    required this.contestId,
    required this.builder,
  });

  final String? contestId;
  final Widget Function(BuildContext context, String? contestName) builder;

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
    return client.contest(id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Contest>(
    future: _contest,
    builder: (context, snapshot) => widget.builder(
      context,
      widget.contestId == null ? null : snapshot.data?.name,
    ),
  );
}
