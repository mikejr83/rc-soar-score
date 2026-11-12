import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../router.dart';
import '../../../services/workspace/activity/activity_facts.dart';
import '../workspace_scope.dart';
import 'recent_activity_card.dart';

/// The recent-activity section of the workspace: reads the facts the page
/// loaded. A retry reloads all the workspace facts, not only the audit read,
/// and a failed facts load shows the same failed state as a failed audit read.
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key, required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final scope = WorkspaceScope.of(context);
    final facts = scope.facts;
    final ActivityFacts? activity = facts == null
        ? (scope.factsFailed ? ActivityFacts.unavailable : null)
        : facts.activity;
    return RecentActivityCard(
      contest: contest,
      activity: activity,
      onRetry: scope.reloadFacts,
      onViewAll: () => context.go(contestActivityPath(contest.id.value)),
    );
  }
}
