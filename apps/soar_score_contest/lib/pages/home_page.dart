import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../contest_draft_provider.dart';
import '../router.dart';
import '../services/contest_open_action.dart';
import '../widgets/contest_detail_pane.dart';
import '../widgets/contest_list.dart';
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
    return client.contests();
  }

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
      if (snapshot.hasError) {
        return loadFailedView(
          snapshot.error!,
          title: 'Contests could not be loaded.',
          onRetry: _retry,
        );
      }
      final contests = snapshot.data;
      if (contests == null) {
        return const PageStateView.loading(label: 'Loading contests');
      }
      if (contests.isEmpty) {
        final store = contestDraftStoreOf(context);
        return PageStateView.empty(
          title: 'No contests yet.',
          action: ListenableBuilder(
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
        );
      }
      final selected = contests.firstWhere(
        (contest) => contest.id == _selectedId,
        orElse: () => contests.first,
      );
      return MasterDetail(
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
        ),
      );
    },
  );
}
