import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../connectivity_provider.dart';
import '../../router.dart';
import '../../services/reports/report_availability.dart';
import '../../services/reports/report_kind.dart';
import '../../services/reports/reports_facts.dart';
import '../../services/reports/reports_facts_loader.dart';
import '../../widgets/reports/reports_context_strip.dart';
import '../../widgets/reports/reports_list.dart';
import '../../widgets/reports/reports_states.dart';
import '../../widgets/workspace/states/workspace_not_found_view.dart';

/// Opens [kind]'s report. The viewer is not built yet, so the default says so;
/// the viewer replaces it with a new tab or window.
typedef ReportOpener = void Function(BuildContext context, ReportKind kind);

void _viewerNotBuilt(BuildContext context, ReportKind kind) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('The ${kind.title} viewer isn’t built yet.')),
    );

/// The reports of one contest (`plan/ui/contest-administration/reports.md`):
/// a strip saying what reports are built from, then a card for each report
/// that can be produced, grouped as results and documents to print.
class ContestReportsPage extends StatefulWidget {
  const ContestReportsPage({
    super.key,
    required this.contestId,
    this.onOpen = _viewerNotBuilt,
  });

  final String contestId;

  /// What Open does for an available report.
  final ReportOpener onOpen;

  @override
  State<ContestReportsPage> createState() => _ContestReportsPageState();
}

class _ContestReportsPageState extends State<ContestReportsPage> {
  Future<ReportsFacts>? _loading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= _load();
  }

  @override
  void didUpdateWidget(ContestReportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contestId != widget.contestId) {
      _loading = _load();
    }
  }

  Future<ReportsFacts> _load() {
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
    return ReportsFactsLoader.load(client, id);
  }

  void _retry() {
    final loading = _load();
    setState(() {
      _loading = loading;
    });
  }

  void _go(ReportAction action) {
    final id = widget.contestId;
    context.go(switch (action.destination) {
      ReportDestination.scoring => contestScoringPath(id, round: action.round),
      ReportDestination.matrix => contestMatrixPath(id),
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ReportsFacts>(
    future: _loading,
    builder: (context, snapshot) {
      final error = snapshot.error;
      if (error is _NotFound ||
          (error is ApiHttpError && error.statusCode == 404)) {
        return WorkspaceNotFoundView(onBack: () => context.go(homePath));
      }
      if (error != null) {
        return ReportsUnavailable(onRetry: _retry);
      }
      final width = MediaQuery.sizeOf(context).width;
      final twoColumns = width >= 840;
      final compact = width < 600;
      final facts = snapshot.data;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 24,
          20,
          compact ? 16 : 24,
          40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: facts == null
                ? ReportsLoading(twoColumns: twoColumns)
                : _Ready(
                    facts: facts,
                    twoColumns: twoColumns,
                    compact: compact,
                    onOpen: (kind) => widget.onOpen(context, kind),
                    onAction: _go,
                    onOpenSync: () =>
                        context.go(contestSyncPath(widget.contestId)),
                  ),
          ),
        ),
      );
    },
  );
}

/// The id in the route is not an id.
class _NotFound {
  const _NotFound();
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.facts,
    required this.twoColumns,
    required this.compact,
    required this.onOpen,
    required this.onAction,
    required this.onOpenSync,
  });

  final ReportsFacts facts;
  final bool twoColumns;
  final bool compact;
  final ValueChanged<ReportKind> onOpen;
  final ValueChanged<ReportAction> onAction;
  final VoidCallback onOpenSync;

  @override
  Widget build(BuildContext context) {
    final monitor = appConnectivityOf(context);
    return ListenableBuilder(
      listenable: monitor ?? Listenable.merge(const []),
      builder: (context, _) {
        final offline =
            monitor?.internetStatus == ConnectivityStatus.unavailable;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 28,
          children: [
            ReportsContextStrip(
              facts: facts,
              offline: offline,
              onOpenSync: onOpenSync,
            ),
            ReportsList(
              facts: facts,
              twoColumns: twoColumns,
              compact: compact,
              onOpen: onOpen,
              onAction: onAction,
            ),
          ],
        );
      },
    );
  }
}
