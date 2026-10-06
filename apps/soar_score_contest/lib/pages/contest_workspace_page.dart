import 'package:flutter/material.dart';

/// The contest workspace for one contest (`plan/ui/contest-administration/
/// contest-workspace.md`).
///
/// A placeholder until the workspace ticket lands: it gives the shell a
/// contest-scoped route so the contest navigation can be reached.
class ContestWorkspacePage extends StatelessWidget {
  const ContestWorkspacePage({super.key, required this.contestId});

  /// The selected contest's id, taken from the route.
  final String contestId;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'The contest workspace is not available yet.',
      style: Theme.of(context).textTheme.bodyLarge,
    ),
  );
}
