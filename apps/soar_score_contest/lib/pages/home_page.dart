import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../router.dart';
import '../widgets/contest_detail_pane.dart';
import '../widgets/contest_list.dart';
import '../widgets/master_detail.dart';
import '../widgets/message_view.dart';

/// The main page ("Contests"): the contests the app's API holds, as a list
/// beside the selected contest's detail (one pane at a time when narrow).
///
/// Loading, empty and error states, selection and opening a contest. The
/// empty state offers `Create contest`, which opens the New Contest wizard
/// (the rail's FAB does the same at any time).
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

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Contest>>(
    future: _contests,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MessageView(
          text: 'Contests could not be loaded.',
          detail: '${snapshot.error}',
          onRetry: _retry,
        );
      }
      final contests = snapshot.data;
      if (contests == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (contests.isEmpty) {
        return MessageView(
          text: 'No contests yet.',
          action: FilledButton.icon(
            key: const ValueKey('empty-create-contest'),
            onPressed: () => context.go(newContestPath),
            icon: const Icon(Icons.add),
            label: const Text('Create contest'),
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
        ),
        detail: (context, wide) => ContestDetailPane(
          contest: selected,
          onBack: wide ? null : () => setState(() => _showDetail = false),
          onOpen: () => context.go(contestWorkspacePath(selected.id.value)),
        ),
      );
    },
  );
}
