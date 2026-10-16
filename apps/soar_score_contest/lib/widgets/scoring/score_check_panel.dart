import 'package:flutter/material.dart';

import '../../services/scoring/score_check.dart';
import '../matrix/matrix_colors.dart';

/// The result of a Score check: findings grouped by pilot, each jumping to
/// its field, or a clean result.
class ScoreCheckPanel extends StatelessWidget {
  const ScoreCheckPanel({
    super.key,
    required this.result,
    required this.onJump,
    required this.onClose,
  });

  final ScoreCheckResult result;
  final void Function(ScoreFinding finding) onJump;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = MatrixColors.of(context);
    final clean = result.isClean;
    final byPilot = <String, List<ScoreFinding>>{};
    for (final finding in result.findings) {
      byPilot.putIfAbsent(finding.pilot, () => []).add(finding);
    }
    return Container(
      key: const ValueKey('score-check-panel'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: clean ? colors.success : colors.warn,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                clean ? Icons.check_circle : Icons.fact_check_outlined,
                color: clean ? colors.success : colors.warn,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  clean
                      ? 'All ${result.checked} pilots entered, nothing out '
                            'of range.'
                      : '${result.findings.length} to look at for '
                            '${byPilot.length} of ${result.checked} pilots.',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton(onPressed: onClose, child: const Text('Close')),
            ],
          ),
          for (final entry in byPilot.entries) ...[
            const SizedBox(height: 8),
            Text(entry.key, style: theme.textTheme.labelLarge),
            for (final finding in entry.value)
              ListTile(
                key: ValueKey('finding-${finding.rowKey}-${finding.field}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.arrow_forward),
                title: Text(finding.message),
                onTap: () => onJump(finding),
              ),
          ],
        ],
      ),
    );
  }
}
