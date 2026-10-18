import 'dart:async';

import 'package:flutter/material.dart';

/// A contest that exists but is pending or private (view-contest.md,
/// "Contest Not Visible"). Calls [onRecheck] every [recheckInterval].
class ContestNotVisiblePage extends StatefulWidget {
  const ContestNotVisiblePage({
    super.key,
    required this.onRecheck,
    this.recheckInterval = const Duration(minutes: 15),
  });

  final VoidCallback onRecheck;
  final Duration recheckInterval;

  static const String title = 'Contest not shown';
  static const String message =
      'This contest has pending results or has been marked private. It is '
      'not shown at this time. The contest will be shown after the final '
      'placing is announced and the contest director makes the results '
      'public or 48hrs after the last score entered.';

  @override
  State<ContestNotVisiblePage> createState() => _ContestNotVisiblePageState();
}

class _ContestNotVisiblePageState extends State<ContestNotVisiblePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.recheckInterval, (_) => widget.onRecheck());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.recheckInterval.inMinutes;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ContestNotVisiblePage.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(ContestNotVisiblePage.message),
              const SizedBox(height: 12),
              Text(
                'Please check back later. This page checks again every '
                '$minutes minutes to see whether the contest has become '
                'public.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
