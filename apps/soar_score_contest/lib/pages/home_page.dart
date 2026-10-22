import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../contest_draft_provider.dart';
import '../router.dart';
import '../services/api_failure.dart';
import '../services/contest_open_action.dart';
import '../services/exchange/contest_exchange.dart';
import '../widgets/contest_detail_pane.dart';
import '../widgets/contest_list.dart';
import '../widgets/exchange/contest_exchange_dialogs.dart';
import '../widgets/master_detail.dart';
import '../widgets/new_contest/create_contest_entry.dart';
import '../widgets/page_states/page_states.dart';

/// The main page ("Contests"): the contests the app's API holds, as a list
/// beside the selected contest's detail (one pane at a time when narrow).
///
/// Loading, empty and error states, selection and opening a contest. The
/// empty state offers `Create contest` (`Continue configuration` while a
/// draft is underway), which opens the New Contest wizard (the rail's FAB
/// does the same at any time).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Contest>>? _contests;
  Id? _selectedId;
  bool _showDetail = false;

  /// The contests imported for inspection.
  Set<Id> _inspection = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contests ??= _load();
  }

  Future<List<Contest>> _load() {
    final client = apiClientOf(context);
    if (client == null) {
      return Future.error(StateError('No API client is available.'));
    }
    return _withInspection(client);
  }

  Future<List<Contest>> _withInspection(ApiClient client) async {
    final contests = await client.contests();
    final exchange = ContestExchange.current;
    _inspection = exchange == null
        ? const {}
        : await exchange.inspectionContests();
    return contests;
  }

  /// Imports a file and shows the imported contest, selected.
  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);
    final imported = await importContest(context);
    if (imported == null || !mounted) return;
    final contests = _load();
    setState(() {
      _contests = contests;
      _selectedId = imported.contestId;
      _showDetail = true;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          imported.mode == ExchangeImportMode.inspection
              ? 'Imported as a local copy. It is not synced.'
              : 'Imported as an editable copy.',
        ),
      ),
    );
  }

  Widget _importButton() => TextButton.icon(
    key: const ValueKey('import-contest'),
    onPressed: _import,
    icon: const Icon(Icons.file_upload_outlined, size: 18),
    label: const Text('Import contest…'),
  );

  void _retry() {
    final contests = _load();
    setState(() {
      _contests = contests;
    });
  }

  void _open(Contest contest) => context.go(contestOpenPath(contest));

  /// The load failure, sorted by kind: signing in again does not fix an
  /// unreachable server and retrying does not fix a missing sign-in.
  Widget _failed(Object error) {
    final failure = ApiFailure.of(error);
    // Only an unreachable or failing server can recover on its own, so only
    // that failure offers Retry; retrying a 403 or a rejected request loops.
    final retry = failure.retryable
        ? PageStateAction(
            key: const ValueKey('page-state-retry'),
            label: 'Retry',
            onPressed: _retry,
          )
        : null;
    return switch (failure.kind) {
      ApiFailureKind.unauthorized ||
      ApiFailureKind.forbidden => PageStateView.authorization(
        title: 'Contests could not be loaded.',
        body: failure.kind == ApiFailureKind.unauthorized
            ? 'You are not signed in. Sign in again to see them.'
            : 'Your account is not allowed to see these contests. ${failure.message}',
        primary: retry,
      ),
      _ => PageStateView.unavailable(
        title: 'Contests could not be loaded.',
        body: failure.message,
        primary: retry,
      ),
    };
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Contest>>(
    future: _contests,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _failed(snapshot.error!);
      }
      final contests = snapshot.data;
      if (contests == null) {
        return const PageStateView.loading(label: 'Loading contests');
      }
      if (contests.isEmpty) {
        final store = contestDraftStoreOf(context);
        return PageStateView.empty(
          title: 'No contests yet.',
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListenableBuilder(
                listenable: store ?? Listenable.merge(const []),
                builder: (context, _) {
                  final hasDraft = store?.hasDraft ?? false;
                  return FilledButton.icon(
                    key: const ValueKey('empty-create-contest'),
                    onPressed: () => context.go(newContestPath),
                    icon: Icon(CreateContestEntry.icon(hasDraft)),
                    label: Text(CreateContestEntry.label(hasDraft)),
                  );
                },
              ),
              if (ContestExchange.current != null) _importButton(),
            ],
          ),
        );
      }
      final selected = contests.firstWhere(
        (contest) => contest.id == _selectedId,
        orElse: () => contests.first,
      );
      final exchange = ContestExchange.current;
      final master = MasterDetail(
        showDetail: _showDetail,
        list: (context, wide) => ContestList(
          contests: contests,
          selectedId: selected.id,
          highlight: wide,
          onSelect: (contest) => setState(() {
            _selectedId = contest.id;
            _showDetail = true;
          }),
          onOpen: _open,
        ),
        detail: (context, wide) => ContestDetailPane(
          contest: selected,
          onBack: wide ? null : () => setState(() => _showDetail = false),
          onOpen: () => _open(selected),
          inspection: _inspection.contains(selected.id),
          onExport: exchange == null
              ? null
              : () => exportContest(context, selected),
        ),
      );
      if (exchange == null) return master;
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _importButton(),
            ),
          ),
          Expanded(child: master),
        ],
      );
    },
  );
}
