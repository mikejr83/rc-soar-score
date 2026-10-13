import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/checklist/checklist_item.dart';
import 'package:soar_score_contest/services/workspace/checklist/setup_checklist.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_contest/widgets/workspace/checklist/setup_checklist_card.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/configuration_fixtures.dart';
import '../../../support/matrix_test_support.dart';
import '../../../support/workspace_checklist_support.dart';

SetupChecklist _checklist({
  CurrentMatrix? matrix,
  List<ContestParticipation>? participations,
  PublicationFacts publication = PublicationFacts.notPublished,
}) => SetupChecklist.resolve(
  WorkspaceFacts.derive(
    data: f5jWorkspaceData(matrix: matrix, participations: participations),
    landingTables: [landingTableView(f5jLandingTableId, 'F5J default')],
    publication: publication,
  ),
  formatSavedAt: (_) => 'Oct 12, 14:05',
);

Future<List<ChecklistTarget>> _pump(
  WidgetTester tester,
  SetupChecklist checklist, {
  double width = 640,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  final opened = <ChecklistTarget>[];
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SetupChecklistCard(checklist: checklist, onOpen: opened.add),
        ),
      ),
    ),
  );
  return opened;
}

void main() {
  testWidgets('mixed: done, check and to do rows with their summary', (
    tester,
  ) async {
    await _pump(
      tester,
      _checklist(matrix: drawnMatrix(config: const {'team_protection': true})),
    );
    expect(find.text('Setup checklist'), findsOneWidget);
    expect(find.text('3 of 4 required items done'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('checklist-status-matrix')))
          .data,
      'Check',
    );
    expect(find.text('Matrix doesn’t match the configuration'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    expect(find.text('Not published'), findsOneWidget);
  });

  testWidgets('missing pilots show Missing, with an icon as well', (
    tester,
  ) async {
    await _pump(
      tester,
      _checklist(participations: [matrixParticipations().first]),
    );
    expect(find.text('1 scoring pilot'), findsOneWidget);
    expect(find.text('Missing'), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('2 of 4 required items done'), findsOneWidget);
  });

  testWidgets('all required done', (tester) async {
    await _pump(tester, _checklist(matrix: drawnMatrix()));
    expect(find.text('4 of 4 required items done'), findsOneWidget);
    expect(find.text('Done'), findsNWidgets(4));
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
  });

  testWidgets('each row opens its target', (tester) async {
    final opened = await _pump(tester, _checklist());
    for (final id in [
      'configuration',
      'discipline',
      'pilots',
      'matrix',
      'publication',
      'scoringAccess',
    ]) {
      await tester.tap(find.byKey(ValueKey('checklist-row-$id')));
    }
    expect(opened, [
      ChecklistTarget.configuration,
      ChecklistTarget.configuration,
      ChecklistTarget.participants,
      ChecklistTarget.matrix,
      ChecklistTarget.publicationControl,
      ChecklistTarget.scoringControl,
    ]);
  });

  testWidgets('a row reads as one button with its status spoken', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _checklist());
    expect(
      find.bySemanticsLabel('4 scoring pilots. Done. Teams off · classes off'),
      findsOneWidget,
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel('4 scoring pilots. Done. Teams off · classes off'),
    );
    expect(node.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('fits a narrow window at large text scale', (tester) async {
    await _pump(
      tester,
      _checklist(matrix: drawnMatrix(config: const {'team_protection': true})),
      width: 360,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in the dark theme', (tester) async {
    await _pump(
      tester,
      _checklist(matrix: drawnMatrix()),
      brightness: Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('4 of 4 required items done'), findsOneWidget);
  });
}
