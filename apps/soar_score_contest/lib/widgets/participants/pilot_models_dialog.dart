import 'package:flutter/material.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/contest_participants/participants_controller.dart'
    show apiErrorTextOf;
import '../../services/participants/model_entry.dart';
import '../../services/participants/pilot_models_backend.dart';

/// Opens the window where a pilot's models are added, edited and removed.
///
/// Each change goes to [backend] as it is made. Completes with the models as
/// they stand when the window closes.
Future<List<ModelEntry>> showPilotModelsDialog(
  BuildContext context, {
  required String pilotName,
  required List<ModelEntry> models,
  required PilotModelsBackend backend,
}) async =>
    await showDialog<List<ModelEntry>>(
      context: context,
      builder: (context) => PilotModelsDialog(
        pilotName: pilotName,
        models: models,
        backend: backend,
      ),
    ) ??
    models;

/// A pilot's models: the list, and a form to add or edit one. A pilot with no
/// models is fine; nothing here is required.
class PilotModelsDialog extends StatefulWidget {
  const PilotModelsDialog({
    super.key,
    required this.pilotName,
    required this.models,
    required this.backend,
  });

  final String pilotName;
  final List<ModelEntry> models;
  final PilotModelsBackend backend;

  @override
  State<PilotModelsDialog> createState() => _PilotModelsDialogState();
}

class _PilotModelsDialogState extends State<PilotModelsDialog> {
  late List<ModelEntry> _models = widget.models;
  List<ModelCatalog> _profileModels = const [];

  /// The form is shown while adding ([_editing] null) or editing one.
  bool _formOpen = false;
  ModelEntry? _editing;
  Id? _pickedCatalogId;

  final _name = TextEditingController();
  final _manufacturer = TextEditingController();
  final _modelId = TextEditingController();
  final _contestId = TextEditingController();

  bool _busy = false;
  bool _nameMissing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.backend.profileModels().then((models) {
      if (mounted) setState(() => _profileModels = models);
    });
    for (final field in [_name, _manufacturer, _modelId]) {
      field.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _manufacturer.dispose();
    _modelId.dispose();
    _contestId.dispose();
    super.dispose();
  }

  void _openForm([ModelEntry? entry]) => setState(() {
    _formOpen = true;
    _editing = entry;
    _pickedCatalogId = entry?.catalogId;
    _name.text = entry?.name ?? '';
    _manufacturer.text = entry?.manufacturer ?? '';
    _modelId.text = entry?.modelId ?? '';
    _contestId.text = entry?.contestIdentifier ?? '';
    _nameMissing = false;
    _error = null;
  });

  void _closeForm() => setState(() {
    _formOpen = false;
    _editing = null;
    _error = null;
  });

  void _pick(ModelCatalog model) => setState(() {
    _pickedCatalogId = model.id;
    _name.text = model.name;
    _manufacturer.text = model.manufacturer ?? '';
    _modelId.text = model.modelId ?? '';
    _nameMissing = false;
  });

  /// What the form holds, as an entry (a new one gets its id here, so a
  /// retried creation repeats the same request).
  ModelEntry _formEntry() =>
      (_editing ??
              ModelEntry(
                id: Id.create(),
                catalogId: _pickedCatalogId,
                name: _name.text,
              ))
          .edited(
            name: _name.text,
            manufacturer: _manufacturer.text,
            modelId: _modelId.text,
            contestIdentifier: _contestId.text,
          );

  bool get _duplicate {
    if (_name.text.trim().isEmpty) return false;
    final entry = _formEntry();
    return _models.any((m) => m.id != entry.id && m.sameModelAs(entry));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final l10n = AppLocalizations.of(context);
    try {
      await action();
    } on Object catch (error) {
      if (!mounted) return;
      final stale =
          error is ApiHttpError && error.error?.code == 'stale_revision';
      setState(() {
        _error = stale
            ? l10n.modelsStale
            : l10n.modelsSaveFailed(apiErrorTextOf(error));
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    final entry = _formEntry();
    await _run(() async {
      final editing = _editing;
      final stored = editing == null
          ? await widget.backend.add(entry)
          : await widget.backend.update(entry);
      setState(() {
        _models = [
          for (final m in _models)
            if (m.id == stored.id) stored else m,
          if (editing == null) stored,
        ];
        _formOpen = false;
        _editing = null;
      });
    });
  }

  Future<void> _remove(ModelEntry entry) => _run(() async {
    await widget.backend.remove(entry);
    setState(
      () => _models = [
        for (final m in _models)
          if (m.id != entry.id) m,
      ],
    );
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pickable = _profileModels;
    return AlertDialog(
      key: const ValueKey('pilot-models-dialog'),
      icon: const Icon(Icons.flight),
      title: Text(l10n.modelsDialogTitle(widget.pilotName)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_models.isEmpty && !_formOpen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.modelsDialogEmpty,
                    key: const ValueKey('models-dialog-empty'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final model in _models)
                ListTile(
                  key: ValueKey('model-${model.id.value}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(model.label),
                  subtitle: _details(l10n, model) == null
                      ? null
                      : Text(_details(l10n, model)!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: ValueKey('edit-model-${model.id.value}'),
                        tooltip: l10n.modelsEditEntry(model.name),
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _busy ? null : () => _openForm(model),
                      ),
                      IconButton(
                        key: ValueKey('remove-model-${model.id.value}'),
                        tooltip: l10n.modelsRemoveEntry(model.name),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _busy ? null : () => _remove(model),
                      ),
                    ],
                  ),
                ),
              if (_formOpen) ...[
                const Divider(),
                if (_editing == null && pickable.isNotEmpty) ...[
                  DropdownMenu<ModelCatalog>(
                    key: const ValueKey('model-pick'),
                    width: 392,
                    label: Text(l10n.modelsPickLabel),
                    helperText: l10n.modelsPickHint,
                    enabled: !_busy,
                    dropdownMenuEntries: [
                      for (final model in pickable)
                        DropdownMenuEntry(
                          value: model,
                          label: _catalogLabel(model),
                        ),
                    ],
                    onSelected: (model) {
                      if (model != null) _pick(model);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  key: const ValueKey('model-name'),
                  controller: _name,
                  enabled: !_busy,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.modelsFieldName,
                    errorText: _nameMissing && _name.text.trim().isEmpty
                        ? l10n.modelsNameRequired
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('model-manufacturer'),
                  controller: _manufacturer,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: l10n.modelsFieldManufacturer,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('model-model-id'),
                  controller: _modelId,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: l10n.modelsFieldModelId,
                    helperText: l10n.modelsFieldModelIdHelper,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('model-contest-id'),
                  controller: _contestId,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: l10n.modelsFieldContestId,
                    helperText: l10n.modelsFieldContestIdHelper,
                  ),
                ),
                if (_duplicate)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.modelsDuplicate,
                      key: const ValueKey('model-duplicate'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.tertiary,
                      ),
                    ),
                  ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      key: const ValueKey('models-error'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (_formOpen) ...[
          TextButton(
            key: const ValueKey('model-cancel'),
            onPressed: _busy ? null : _closeForm,
            child: Text(l10n.modelsFormCancel),
          ),
          FilledButton(
            key: const ValueKey('model-save'),
            onPressed: _busy ? null : _save,
            child: Text(
              _editing == null ? l10n.modelsSaveAdd : l10n.modelsSaveEdit,
            ),
          ),
        ] else ...[
          TextButton.icon(
            key: const ValueKey('model-add'),
            onPressed: _busy ? null : _openForm,
            icon: const Icon(Icons.add),
            label: Text(l10n.modelsAddButton),
          ),
          FilledButton(
            key: const ValueKey('models-done'),
            onPressed: _busy ? null : () => Navigator.of(context).pop(_models),
            child: Text(l10n.modelsDone),
          ),
        ],
      ],
    );
  }

  static String _catalogLabel(ModelCatalog model) {
    final maker = model.manufacturer;
    return maker == null || maker.isEmpty
        ? model.name
        : '${model.name} · $maker';
  }

  /// `ID S-1 · Contest S7`, or null when there is neither.
  static String? _details(AppLocalizations l10n, ModelEntry model) {
    final parts = [
      if (model.modelId != null) l10n.modelsDetailModelId(model.modelId!),
      if (model.contestIdentifier != null)
        l10n.modelsDetailContestId(model.contestIdentifier!),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
