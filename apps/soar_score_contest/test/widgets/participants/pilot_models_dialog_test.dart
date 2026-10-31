import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/services/participants/model_entry.dart';
import 'package:soar_score_contest/services/participants/pilot_models_backend.dart';
import 'package:soar_score_contest/widgets/participants/pilot_models_dialog.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Keeps the models in memory and can be told to refuse a change.
class _Backend implements PilotModelsBackend {
  _Backend({this.catalog = const [], this.failWith});

  final List<ModelCatalog> catalog;
  Object? failWith;
  final List<String> calls = [];

  @override
  Future<List<ModelCatalog>> profileModels() async => catalog;

  Future<T> _do<T>(String call, T Function() result) async {
    calls.add(call);
    if (failWith != null) throw failWith!;
    return result();
  }

  @override
  Future<ModelEntry> add(ModelEntry entry) =>
      _do('add ${entry.name}', () => entry);

  @override
  Future<ModelEntry> update(ModelEntry entry) =>
      _do('update ${entry.name}', () => entry);

  @override
  Future<void> remove(ModelEntry entry) => _do('remove ${entry.name}', () {});
}

Future<void> _open(
  WidgetTester tester, {
  required List<ModelEntry> models,
  required _Backend backend,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showPilotModelsDialog(
              context,
              pilotName: 'Ada Lovelace',
              models: models,
              backend: backend,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  final owner = Id.create();
  final profile = Id.create();
  ModelCatalog catalogModel(String name) => ModelCatalog(
    id: Id.create(),
    ownerAccountId: owner,
    participantProfileId: profile,
    name: name,
    manufacturer: 'Vladimir',
    modelId: 'S-1',
  );

  testWidgets('a pilot with no models is fine: the window says so and can '
      'be closed', (tester) async {
    await _open(tester, models: const [], backend: _Backend());

    expect(find.text('Models for Ada Lovelace'), findsOneWidget);
    expect(find.byKey(const ValueKey('models-dialog-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('models-done')));
    await tester.pumpAndSettle();
    expect(find.byType(PilotModelsDialog), findsNothing);
  });

  testWidgets('adds a typed model; the name is required', (tester) async {
    final backend = _Backend();
    await _open(tester, models: const [], backend: backend);

    await tester.tap(find.byKey(const ValueKey('model-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('model-save')));
    await tester.pump();
    expect(find.text('Enter a model name.'), findsOneWidget);
    expect(backend.calls, isEmpty);

    await tester.enterText(find.byKey(const ValueKey('model-name')), 'Supra');
    await tester.enterText(
      find.byKey(const ValueKey('model-contest-id')),
      'A7',
    );
    await tester.tap(find.byKey(const ValueKey('model-save')));
    await tester.pumpAndSettle();

    expect(backend.calls, ['add Supra']);
    expect(find.text('Supra'), findsOneWidget);
    expect(find.text('Contest A7'), findsOneWidget);
  });

  testWidgets('picking a profile model fills the form', (tester) async {
    final backend = _Backend(catalog: [catalogModel('Supra')]);
    await _open(tester, models: const [], backend: backend);

    await tester.tap(find.byKey(const ValueKey('model-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('model-pick')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supra · Vladimir').last);
    await tester.pumpAndSettle();

    final name = tester.widget<TextField>(
      find.byKey(const ValueKey('model-name')),
    );
    expect(name.controller!.text, 'Supra');
    await tester.tap(find.byKey(const ValueKey('model-save')));
    await tester.pumpAndSettle();
    expect(backend.calls, ['add Supra']);
  });

  testWidgets('edits and removes a model', (tester) async {
    final model = ModelEntry(id: Id.create(), name: 'Supra');
    final backend = _Backend();
    await _open(tester, models: [model], backend: backend);

    await tester.tap(find.byKey(ValueKey('edit-model-${model.id.value}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('model-name')), 'Supra 2');
    await tester.tap(find.byKey(const ValueKey('model-save')));
    await tester.pumpAndSettle();
    expect(find.text('Supra 2'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('remove-model-${model.id.value}')));
    await tester.pumpAndSettle();
    expect(backend.calls, ['update Supra 2', 'remove Supra 2']);
    expect(find.byKey(const ValueKey('models-dialog-empty')), findsOneWidget);
  });

  testWidgets('a stale revision shows the refresh message and keeps the '
      'model', (tester) async {
    final model = ModelEntry(id: Id.create(), name: 'Supra');
    final backend = _Backend(
      failWith: ApiHttpError(
        'conflict',
        statusCode: 409,
        body: '{"error":{"code":"stale_revision","message":"changed"}}',
        requestUri: Uri.parse('http://localhost/x'),
      ),
    );
    await _open(tester, models: [model], backend: backend);

    await tester.tap(find.byKey(ValueKey('remove-model-${model.id.value}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('models-error')), findsOneWidget);
    expect(find.textContaining('changed elsewhere'), findsOneWidget);
    expect(find.text('Supra'), findsOneWidget);
  });

  testWidgets('warns about a duplicate but still allows it', (tester) async {
    final model = ModelEntry(id: Id.create(), name: 'Supra');
    await _open(tester, models: [model], backend: _Backend());

    await tester.tap(find.byKey(const ValueKey('model-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('model-name')), 'supra');
    await tester.pump();

    expect(find.byKey(const ValueKey('model-duplicate')), findsOneWidget);
  });
}
