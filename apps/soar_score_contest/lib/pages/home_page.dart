import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../contest_draft_provider.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../services/competition_import/competition_import.dart';
import '../services/contest_open_action.dart';
import '../services/exchange/contest_exchange.dart';
import '../widgets/competition_import/competition_import_dialog.dart';
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

  // When each selected contest was imported from GliderScore, kept so a
  // rebuild does not ask again. Cleared when the list loads.
  final Map<Id, Future<DateTime?>> _imported = {};

  /// When [id] was imported, or `null` (also in a build without a store).
  Future<DateTime?> _importedAt(Id id) => _imported.putIfAbsent(id, () async {
    final store = CompetitionImportStore.current;
    if (store == null) return null;
    try {
      return (await store.noteFor(id))?.importedAt;
    } catch (_) {
      return null; // The chip is a courtesy.
    }
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contests ??= _load();
  }

  Future<List<Contest>> _load() {
    _imported.clear();
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
    return ContestList.newestFirst(contests);
  }

  /// Imports a file and shows the imported contest, selected.
  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
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
              ? l10n.importDoneInspection
              : l10n.importDoneEditable,
        ),
      ),
    );
  }

  Widget _importButton() => TextButton.icon(
    key: const ValueKey('import-contest'),
    onPressed: _import,
    icon: const Icon(Icons.file_upload_outlined, size: 18),
    label: Text(AppLocalizations.of(context).importButton),
  );

  /// Imports competitions of a GliderScore file as contests; opens one when
  /// the director asks, else shows the first imported, selected.
  Future<void> _importCompetitions() async {
    final outcome = await importCompetitions(context);
    if (outcome == null || !mounted) return;
    final future = _load();
    setState(() {
      _contests = future;
      _selectedId = outcome.open ?? outcome.imported.first;
      _showDetail = true;
    });
    final open = outcome.open;
    if (open == null) return;
    final contests = await future;
    if (!mounted) return;
    for (final contest in contests) {
      if (contest.id == open) {
        _open(contest);
        return;
      }
    }
  }

  Widget _importCompetitionsButton() => TextButton.icon(
    key: const ValueKey('import-competitions'),
    onPressed: _importCompetitions,
    icon: const Icon(Icons.library_add_outlined, size: 18),
    label: Text(AppLocalizations.of(context).competitionImportButton),
  );

  /// The import buttons of this build: files of contests, GliderScore files.
  List<Widget> _importButtons() => [
    if (ContestExchange.current != null) _importButton(),
    if (CompetitionImportStore.current != null) _importCompetitionsButton(),
  ];

  void _retry() {
    final contests = _load();
    setState(() {
      _contests = contests;
    });
  }

  void _open(Contest contest) => context.go(contestOpenPath(contest));

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Contest>>(
    future: _contests,
    builder: (context, snapshot) {
      final l10n = AppLocalizations.of(context);
      if (snapshot.hasError) {
        return loadFailedView(
          snapshot.error!,
          title: l10n.contestsLoadFailed,
          onRetry: _retry,
        );
      }
      final contests = snapshot.data;
      if (contests == null) {
        return PageStateView.loading(label: l10n.contestsLoading);
      }
      if (contests.isEmpty) {
        final store = contestDraftStoreOf(context);
        return PageStateView.empty(
          title: l10n.contestsEmpty,
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
                    label: Text(CreateContestEntry.label(l10n, hasDraft)),
                  );
                },
              ),
              ..._importButtons(),
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
        detail: (context, wide) => FutureBuilder<DateTime?>(
          future: _importedAt(selected.id),
          builder: (context, imported) => ContestDetailPane(
            contest: selected,
            onBack: wide ? null : () => setState(() => _showDetail = false),
            onOpen: () => _open(selected),
            inspection: _inspection.contains(selected.id),
            importedAt: imported.data,
            onExport: exchange == null
                ? null
                : () => exportContest(context, selected),
          ),
        ),
      );
      if (_importButtons().isEmpty) return master;
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Wrap(spacing: 8, children: _importButtons()),
            ),
          ),
          Expanded(child: master),
        ],
      );
    },
  );
}
