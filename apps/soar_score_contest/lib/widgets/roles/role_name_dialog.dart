import 'package:flutter/material.dart';

import '../api_error_text.dart';

/// Asks for a role name and hands it to [onSubmit] (adding or renaming).
///
/// The dialog closes with `true` once [onSubmit] completes. When it throws,
/// the dialog stays open and shows the server's reason, such as a name that
/// is already taken.
Future<bool?> showRoleNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required Future<void> Function(String name) onSubmit,
  String initialName = '',
}) => showDialog<bool>(
  context: context,
  builder: (context) => _RoleNameDialog(
    title: title,
    confirmLabel: confirmLabel,
    initialName: initialName,
    onSubmit: onSubmit,
  ),
);

class _RoleNameDialog extends StatefulWidget {
  const _RoleNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
    required this.onSubmit,
  });

  final String title;
  final String confirmLabel;
  final String initialName;
  final Future<void> Function(String name) onSubmit;

  @override
  State<_RoleNameDialog> createState() => _RoleNameDialogState();
}

class _RoleNameDialogState extends State<_RoleNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name for the role.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(name);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = apiErrorText(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const ValueKey('role-name-field'),
      controller: _controller,
      autofocus: true,
      enabled: !_saving,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(labelText: 'Role name', errorText: _error),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('role-name-confirm'),
        onPressed: _saving ? null : _submit,
        child: Text(widget.confirmLabel),
      ),
    ],
  );
}
