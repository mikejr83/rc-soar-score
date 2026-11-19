import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/scoring/retire_impact.dart';
import '../api_error_text.dart';

/// Asks before a pilot is retired from a round on, or taken back, and names
/// what changes in the round counts. [apply] makes the change; an error it
/// throws is shown in the dialog, which stays open.
Future<bool> confirmRetirement(
  BuildContext context, {
  required RetireImpact impact,
  required Future<void> Function() apply,
}) async {
  final done = await showDialog<bool>(
    context: context,
    builder: (context) => _RetireDialog(impact: impact, apply: apply),
  );
  return done ?? false;
}

class _RetireDialog extends StatefulWidget {
  const _RetireDialog({required this.impact, required this.apply});

  final RetireImpact impact;
  final Future<void> Function() apply;

  @override
  State<_RetireDialog> createState() => _RetireDialogState();
}

class _RetireDialogState extends State<_RetireDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.apply();
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = apiErrorText(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final impact = widget.impact;
    final reinstating = impact.reinstating;
    final lines = impact.changeLines;
    return AlertDialog(
      key: const ValueKey('retire-dialog'),
      title: Text(
        reinstating
            ? words.scoreReinstateTitle(impact.pilot)
            : words.scoreRetireTitle(impact.pilot),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reinstating
                  ? words.scoreReinstateBody(impact.pilot, impact.fromRound)
                  : words.scoreRetireBody(impact.pilot, impact.fromRound),
            ),
            const SizedBox(height: 12),
            if (lines.isEmpty)
              Text(words.scoreRetireNoChanges)
            else
              for (final line in lines) Text(line),
            if (impact.keptScores > 0) ...[
              const SizedBox(height: 8),
              Text(
                words.scoreRetireKeptScores(impact.keptScores, impact.fromRound),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('retire-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('retire-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context).cancelButton),
        ),
        FilledButton(
          key: const ValueKey('retire-confirm'),
          onPressed: _busy ? null : _confirm,
          child: Text(
            reinstating
                ? words.scoreReinstateButton
                : words.scoreRetireButton,
          ),
        ),
      ],
    );
  }
}
