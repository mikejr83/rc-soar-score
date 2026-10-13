import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/workspace_fact_source.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';

import '../../support/configuration_fixtures.dart';
import '../../support/workspace_checklist_support.dart';
import '../../support/workspace_facts_support.dart';

void main() {
  final table = landingTableView(f5jLandingTableId, 'F5J default');

  test('name the discipline and the landing table', () {
    final facts = WorkspaceFacts.derive(
      data: f5jWorkspaceData(),
      landingTables: [
        landingTableView(clubLandingTableId, 'Club table'),
        table,
      ],
    );
    expect(facts.disciplineLabel, 'F5J');
    expect(facts.landingTableName, 'F5J default');
    expect(facts.houseRuleCount, 0);
  });

  test('count house rules', () {
    final facts = WorkspaceFacts.derive(
      data: f5jWorkspaceData(discipline: {'working_time': 480}),
    );
    expect(facts.houseRuleCount, 1);
  });

  test('are empty without a configuration', () {
    final facts = WorkspaceFacts.derive(
      data: f5jWorkspaceData(withConfiguration: false),
      landingTables: [table],
    );
    expect(facts.disciplineLabel, isNull);
    expect(facts.landingTableName, isNull);
    expect(facts.houseRuleCount, 0);
  });

  test('leave the table name empty when the tables were not read', () {
    final facts = WorkspaceFacts.derive(
      data: f5jWorkspaceData(),
      unavailable: {WorkspaceFactSource.landingTables},
    );
    expect(facts.landingTableName, isNull);
    expect(facts.disciplineLabel, 'F5J');
  });

  test('leave the table name empty for a table that is not listed', () {
    final facts = WorkspaceFacts.derive(
      data: f5jWorkspaceData(),
      landingTables: [landingTableView(clubLandingTableId, 'Club table')],
    );
    expect(facts.landingTableName, isNull);
  });

  test('give no discipline name for a profile that is not a system one', () {
    final facts = WorkspaceFacts.derive(data: workspaceData());
    expect(facts.disciplineLabel, isNull);
    expect(facts.houseRuleCount, 0);
  });

  test('report the numbers handed out', () {
    expect(
      WorkspaceFacts.derive(data: f5jWorkspaceData()).participantNumbers,
      isNull,
    );
    final numbered = WorkspaceFacts.derive(
      data: f5jWorkspaceData(numbered: true),
    ).participantNumbers;
    expect(numbered?.lowest, 1);
    expect(numbered?.highest, 4);
  });

  test('survive an offline change', () {
    final facts = WorkspaceFacts.derive(
      data: f5jWorkspaceData(numbered: true),
      landingTables: [table],
    );
    final offline = facts.withOffline(true);
    expect(offline.landingTableName, 'F5J default');
    expect(offline.disciplineLabel, 'F5J');
    expect(offline.participantNumbers, facts.participantNumbers);
  });

  test('a landing-table failure does not make the next step unavailable', () {
    final facts = WorkspaceFacts.derive(
      data: f5jWorkspaceData(),
      unavailable: {WorkspaceFactSource.landingTables},
    );
    expect(facts.unavailable, isNotEmpty);
    expect(facts.nextStepFactsUnavailable, isFalse);
    expect(
      WorkspaceFacts.derive(
        data: f5jWorkspaceData(),
        unavailable: {WorkspaceFactSource.scores},
      ).nextStepFactsUnavailable,
      isTrue,
    );
    expect(
      WorkspaceFacts.derive(
        data: f5jWorkspaceData(),
        unavailable: {WorkspaceFactSource.publication},
      ).nextStepFactsUnavailable,
      isTrue,
    );
  });
}
