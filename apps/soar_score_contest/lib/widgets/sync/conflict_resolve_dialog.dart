import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/sync/conflict_answer.dart';
import '../../services/sync/open_conflict.dart';
import 'payload_comparison.dart';

/// Sends the director's decision: one of the two versions, or an edited one.
typedef ResolveConflict = Future<ConflictAnswer> Function(
  ConflictResolutionChoice choice,
  Map<String, Object?>? payload,
);

/// Shows both versions of a conflict and asks which to keep. The dialog closes
/// with true once the service accepted the decision. Otherwise it stays open
/// and says why.
class ConflictResolveDialog extends StatefulWidget {
  const ConflictResolveDialog({
    super.key,
    required this.conflict,
    required this.onResolve,
  });

  final OpenConflict conflict;
  final ResolveConflict onResolve;

  @override
  State<ConflictResolveDialog> createState() => _ConflictResolveDialogState();
}

class _ConflictResolveDialogState extends State<ConflictResolveDialog> {
  late final TextEditingController _edit;
  bool _editing = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final start =
        widget.conflict.acceptedPayload ??
        widget.conflict.competingPayload ??
        const <String, Object?>{};
    _edit = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(start),
    );
  }

  @override
  void dispose() {
    _edit.dispose();
    super.dispose();
  }

  Future<void> _send(
    ConflictResolutionChoice choice, {
    Map<String, Object?>? payload,
  }) async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final answer = await widget.onResolve(choice, payload);
    if (!mounted) return;
    if (answer.resolved) {
      Navigator.of(context).pop(true);
      return;
    }
    final problem = answer.problem;
    setState(() {
      _sending = false;
      _error = problem == null
          ? answer.refusal
          : '${problem.label}. ${problem.explanation}';
    });
  }

  void _sendEdited() {
    final Object? decoded;
    try {
      decoded = jsonDecode(_edit.text);
    } on FormatException catch (e) {
      setState(
        () => _error = 'The edited value is not valid JSON: ${e.message}',
      );
      return;
    }
    if (decoded is! Map<String, Object?>) {
      setState(() => _error = 'The edited value must be a JSON object.');
      return;
    }
    _send(ConflictResolutionChoice.merged, payload: decoded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conflict = widget.conflict;
    return AlertDialog(
      key: const ValueKey('conflict-dialog'),
      title: Text('Resolve ${conflict.entityType} conflict'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conflict.explanation),
              const SizedBox(height: 12),
              if (_editing) ...[
                Text(
                  'Edit the value to keep. It replaces both versions.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('conflict-edit-field'),
                  controller: _edit,
                  maxLines: 12,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else
                PayloadComparison(
                  acceptedLabel: 'Accepted by the service',
                  competingLabel: 'Competing change',
                  accepted: conflict.acceptedPayload,
                  competing: conflict.competingPayload,
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const ValueKey('conflict-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('conflict-close'),
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Decide later'),
        ),
        if (_editing) ...[
          TextButton(
            key: const ValueKey('conflict-edit-cancel'),
            onPressed: _sending ? null : () => setState(() => _editing = false),
            child: const Text('Back'),
          ),
          FilledButton(
            key: const ValueKey('conflict-edit-save'),
            onPressed: _sending ? null : _sendEdited,
            child: const Text('Keep edited value'),
          ),
        ] else ...[
          OutlinedButton(
            key: const ValueKey('conflict-edit'),
            onPressed: _sending ? null : () => setState(() => _editing = true),
            child: const Text('Edit'),
          ),
          OutlinedButton(
            key: const ValueKey('conflict-take-competing'),
            onPressed: _sending
                ? null
                : () => _send(ConflictResolutionChoice.tookCompeting),
            child: const Text('Use competing change'),
          ),
          FilledButton(
            key: const ValueKey('conflict-keep-accepted'),
            onPressed: _sending
                ? null
                : () => _send(ConflictResolutionChoice.keptAccepted),
            child: const Text('Keep accepted value'),
          ),
        ],
      ],
    );
  }
}
