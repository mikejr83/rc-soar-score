import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../widgets/contest_list.dart';

/// Contest selection: lists the contests the app's API holds.
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Contest selection')),
    body: FutureBuilder<List<Contest>>(
      future: _contests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Message(
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
          return const _Message(text: 'No contests yet.');
        }
        return ContestList(contests: contests);
      },
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.detail, this.onRetry});

  final String text;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    ),
  );
}
