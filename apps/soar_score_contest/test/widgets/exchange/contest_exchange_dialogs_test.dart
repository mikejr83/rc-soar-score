import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/exchange/contest_exchange.dart';
import 'package:soar_score_contest/widgets/exchange/contest_exchange_dialogs.dart';
import 'package:soar_score_core/soar_score_core.dart';

class _FakeExchange implements ContestExchange {
  _FakeExchange(this.next);

  ExchangePreview next;
  final exports = <bool>[];
  final imports = <ExchangeImportMode>[];

  @override
  Future<ExchangeExport> export(Id contestId, {required bool redact}) async {
    exports.add(redact);
    return ExchangeExport(fileName: 'Meet.rcsoar', bytes: Uint8List(3));
  }

  @override
  Future<ExchangePreview> preview(Uint8List bytes) async => next;

  @override
  Future<ExchangeImported> import(
    Uint8List bytes,
    ExchangeImportMode mode, {
    String? fileName,
  }) async {
    imports.add(mode);
    return ExchangeImported(contestId: Id.create(), mode: mode, differences: 0);
  }

  @override
  Future<Set<Id>> inspectionContests() async => {};
}

ExchangePreview _preview({
  List<String> refusals = const [],
  List<ExchangeImportMode> available = ExchangeImportMode.values,
  Map<ExchangeImportMode, String> unavailable = const {},
}) => ExchangePreview(
  contestName: 'Autumn Meet',
  sourceLabel: 'Director Dana',
  exportedAt: DateTime.utc(2026, 10, 22, 12),
  redacted: true,
  counts: const {'participants': 12, 'rounds': 4, 'scores': 40},
  refusals: refusals,
  available: available,
  unavailable: unavailable,
);

void main() {
  final l10n = AppLocalizationsEn();

  ExchangeFiles failingWith(Exception error, {bool onSave = true}) =>
      ExchangeFiles(
        choose: () async => onSave
            ? ChosenExchangeFile(name: 'a.rcsoar', bytes: Uint8List(1))
            : throw error,
        save: (_, _) async => throw error,
      );

  final contest = Contest(
    id: Id.create(),
    name: 'Autumn Meet',
    startDateTime: DateTime.utc(2026, 10, 17),
    endDateTime: DateTime.utc(2026, 10, 18),
    timezone: 'America/Denver',
    createdAt: DateTime.utc(2026, 10),
    updatedAt: DateTime.utc(2026, 10),
  );
  late _FakeExchange exchange;
  late List<String> saved;
  ExchangeImported? imported;

  setUp(() {
    exchange = _FakeExchange(_preview());
    saved = [];
    imported = null;
    ContestExchange.current = exchange;
    ExchangeFiles.current = ExchangeFiles(
      choose: () async =>
          ChosenExchangeFile(name: 'Autumn.rcsoar', bytes: Uint8List(1)),
      save: (name, bytes) async {
        saved.add(name);
        return name;
      },
    );
  });
  tearDown(() => ContestExchange.current = null);

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                key: const ValueKey('go-export'),
                onPressed: () => exportContest(context, contest),
                child: const Text('export'),
              ),
              TextButton(
                key: const ValueKey('go-import'),
                onPressed: () async => imported = await importContest(context),
                child: const Text('import'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets('export removes email addresses by default and warns', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-export')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.exportNotice), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const ValueKey('export-redact')))
          .value,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('export-save')));
    await tester.pumpAndSettle();

    expect(exchange.exports, [true]);
    expect(saved, ['Meet.rcsoar']);
    expect(find.text(l10n.exportSaved('Meet.rcsoar')), findsOneWidget);
  });

  testWidgets('export can keep email addresses for a full backup', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-export')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-redact')));
    await tester.tap(find.byKey(const ValueKey('export-save')));
    await tester.pumpAndSettle();

    expect(exchange.exports, [false]);
  });

  testWidgets('cancelling the export saves nothing', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-export')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancelButton));
    await tester.pumpAndSettle();

    expect(exchange.exports, isEmpty);
    expect(saved, isEmpty);
  });

  testWidgets('import defaults to the local copy and says it is not synced', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-import')));
    await tester.pumpAndSettle();

    expect(find.textContaining('12 participants'), findsOneWidget);
    expect(find.text(l10n.importModeInspectionNotice), findsOneWidget);
    expect(find.text(l10n.importModeEditableNotice), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('import-confirm')));
    await tester.pumpAndSettle();

    expect(exchange.imports, [ExchangeImportMode.inspection]);
    expect(imported?.mode, ExchangeImportMode.inspection);
  });

  testWidgets('the editable copy can be chosen', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-import')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-mode-editable')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-confirm')));
    await tester.pumpAndSettle();

    expect(exchange.imports, [ExchangeImportMode.editable]);
  });

  testWidgets('a mode that is not offered says why and cannot be picked', (
    tester,
  ) async {
    exchange.next = _preview(
      available: [ExchangeImportMode.inspection],
      unavailable: {
        ExchangeImportMode.editable: 'It belongs to another account.',
      },
    );
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-import')));
    await tester.pumpAndSettle();

    expect(find.text('It belongs to another account.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('import-mode-editable')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-confirm')));
    await tester.pumpAndSettle();
    expect(exchange.imports, [ExchangeImportMode.inspection]);
  });

  testWidgets('a refused file shows why and cannot be imported', (
    tester,
  ) async {
    exchange.next = _preview(
      refusals: ['This contest is already in this database as "Autumn Meet".'],
      available: const [],
    );
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-import')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('import-refusal')), findsOneWidget);
    expect(find.byKey(const ValueKey('import-mode-inspection')), findsNothing);
    final confirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('import-confirm')),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('a file that is not a contest is explained', (tester) async {
    ExchangeFiles.current = ExchangeFiles(
      choose: () async =>
          ChosenExchangeFile(name: 'notes.rcsoar', bytes: Uint8List(1)),
      save: (_, _) async => null,
    );
    ContestExchange.current = _Unreadable();
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-import')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        l10n.importFileRefused('notes.rcsoar', 'It is not a contest file.'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('import-dialog')), findsNothing);
  });

  testWidgets('a failed save is reported', (tester) async {
    ExchangeFiles.current = failingWith(
      const FileSystemException('Cannot create file', '/x'),
    );
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-export')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-save')));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.exportFileSaveFailed('Cannot create file')),
      findsOneWidget,
    );
  });

  testWidgets('a file dialog that fails is reported on export', (tester) async {
    ExchangeFiles.current = failingWith(
      PlatformException(code: 'x', message: 'The dialog is not available.'),
    );
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-export')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('The dialog is not available.'), findsOneWidget);
  });

  testWidgets('a file that cannot be read is reported on import', (
    tester,
  ) async {
    ExchangeFiles.current = failingWith(
      const FileSystemException('Cannot open file', '/x'),
      onSave: false,
    );
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-import')));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.importOpenFailed('Cannot open file')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('import-dialog')), findsNothing);
  });

  testWidgets('an export that fails is not reported as a save failure', (
    tester,
  ) async {
    ContestExchange.current = _ExportBreaks();
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('go-export')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-save')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.exportFailed), findsOneWidget);
    expect(find.textContaining(l10n.exportFileSaveFailed('')), findsNothing);
    expect(saved, isEmpty);
  });
}

class _Unreadable extends _FakeExchange {
  _Unreadable() : super(_preview());

  @override
  Future<ExchangePreview> preview(Uint8List bytes) =>
      throw const ExchangeFailure('It is not a contest file.');
}

class _ExportBreaks extends _FakeExchange {
  _ExportBreaks() : super(_preview());

  @override
  Future<ExchangeExport> export(Id contestId, {required bool redact}) =>
      throw Exception('database is closed');
}
