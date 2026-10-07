import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../widgets/contest_list.dart';
import '../widgets/message_view.dart';

/// The main page ("Contests"): lists the contests the app's API holds.
///
/// Loading, empty and error states only; selection and actions come later.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Contest>>? _contests;

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text('Contests', style: Theme.of(context).textTheme.titleLarge),
      ),
      Expanded(
        child: FutureBuilder<List<Contest>>(
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
              return const MessageView(text: 'No contests yet.');
            }
            return ContestList(contests: contests);
          },
        ),
      ),
    ],
  );
}
