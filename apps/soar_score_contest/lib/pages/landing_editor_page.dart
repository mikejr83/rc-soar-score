import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../router.dart';
import '../widgets/api_error_text.dart';
import '../widgets/landings/landing_entry_fields.dart';
import '../widgets/landings/landing_unit_text.dart';
import '../widgets/unsaved_changes_guard.dart';

/// Creates one landing table: a name, what the keys mean, and the entries a
/// scorer can pick, each with its points (`main-page.md`).
///
/// A table never changes, so this form only creates. With a [source] it
/// starts as a copy of that table, which is how a locked table is changed.
/// Validation is inline, entered values survive a failed save, and leaving
/// with unsaved changes asks for confirmation.
class LandingEditorPage extends StatefulWidget {
  const LandingEditorPage({super.key, this.source, this.guard});

  /// The table to start from, or `null` for an empty form.
  final LandingTableView? source;

  /// Asked by the router before any navigation away from this page.
  final UnsavedChangesGuard? guard;

  @override
  State<LandingEditorPage> createState() => _LandingEditorPageState();
}

class _LandingEditorPageState extends State<LandingEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final List<LandingEntryFields> _rows;
  LandingInputUnit _unit = LandingInputUnit.points;
  bool _dirty = false;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final source = widget.source;
    if (source == null) {
      _rows = [LandingEntryFields()];
    } else {
      _name.text = 'Copy of ${source.table.name}';
      _unit = source.table.inputUnit;
      _rows = [
        for (final entry in source.results)
          LandingEntryFields(
            key: entry.entryKey,
            label: entry.displayValue,
            points: '${entry.pointValue}',
          ),
      ];
    }
    widget.guard?.attach(_confirmDiscard);
    _name.addListener(_markDirty);
    for (final row in _rows) {
      _watch(row);
    }
  }

  @override
  void dispose() {
    widget.guard?.detach(_confirmDiscard);
    _name.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _watch(LandingEntryFields row) {
    row.key.addListener(_markDirty);
    row.label.addListener(_markDirty);
    row.points.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  void _addRow() => setState(() {
    final row = LandingEntryFields();
    _watch(row);
    _rows.add(row);
    _dirty = true;
  });

  void _removeRow(int index) => setState(() {
    _rows.removeAt(index).dispose();
    _dirty = true;
  });

  static String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  /// Fails a key that an earlier row already uses.
  String? _keyRule(int index, String? value) {
    final required = _required(value, 'Key');
    if (required != null) {
      return required;
    }
    final key = value!.trim();
    for (var i = 0; i < index; i++) {
      if (_rows[i].key.text.trim() == key) {
        return 'Key is already used in this table.';
      }
    }
    return null;
  }

  static String? _pointsRule(String? value) {
    final required = _required(value, 'Points');
    if (required != null) {
      return required;
    }
    final points = int.tryParse(value!.trim());
    if (points == null) {
      return 'Enter a whole number.';
    }
    return points < 0 ? 'Points cannot be negative.' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final client = apiClientOf(context)!;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await client.createLandingTable(
        CreateLandingTableRequest(
          id: Id.create(),
          name: _name.text.trim(),
          inputUnit: _unit,
          entries: [
            for (final row in _rows)
              LandingEntryInput(
                entryKey: row.key.text.trim(),
                displayValue: row.label.text.trim(),
                pointValue: int.parse(row.points.text.trim()),
              ),
          ],
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = apiErrorText(error);
        });
      }
      return;
    }
    if (mounted) {
      _dirty = false;
      context.go(landingsPath);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) {
      return true;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _cancel() async {
    if (await _confirmDiscard() && mounted) {
      _dirty = false;
      context.go(landingsPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        if (await _confirmDiscard() && context.mounted) {
          _dirty = false;
          context.go(landingsPath);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.source == null
                        ? 'New landing table'
                        : 'New landing table from a copy',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A landing table never changes once it is created. To '
                    'change one later, create a copy.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_saveError != null) ...[
                    Text(
                      _saveError!,
                      key: const ValueKey('save-error'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    key: const ValueKey('landing-name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => _required(v, 'Name'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<LandingInputUnit>(
                    key: const ValueKey('landing-unit'),
                    initialValue: _unit,
                    decoration: const InputDecoration(
                      labelText: 'What the keys mean',
                    ),
                    items: [
                      for (final unit in LandingInputUnit.values)
                        DropdownMenuItem(
                          value: unit,
                          child: Text(landingUnitLabel(unit)),
                        ),
                    ],
                    onChanged: (unit) => setState(() {
                      _unit = unit!;
                      _dirty = true;
                    }),
                  ),
                  const SizedBox(height: 24),
                  Text('Entries', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _rows.length; i++) _row(i),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('add-landing-entry'),
                      onPressed: _addRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add entry'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton(
                        key: const ValueKey('save-landing'),
                        onPressed: _saving ? null : _save,
                        child: const Text('Save'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        key: const ValueKey('cancel-landing'),
                        onPressed: _saving ? null : _cancel,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(int index) {
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('entry-key-$index'),
              controller: row.key,
              decoration: const InputDecoration(labelText: 'Key'),
              validator: (v) => _keyRule(index, v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('entry-label-$index'),
              controller: row.label,
              decoration: const InputDecoration(labelText: 'Label (optional)'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('entry-points-$index'),
              controller: row.points,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Points'),
              validator: _pointsRule,
            ),
          ),
          IconButton(
            key: ValueKey('remove-entry-$index'),
            tooltip: 'Remove entry ${index + 1}',
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: _rows.length > 1 ? () => _removeRow(index) : null,
          ),
        ],
      ),
    );
  }
}
