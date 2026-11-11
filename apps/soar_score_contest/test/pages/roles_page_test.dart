import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_contest/widgets/roles/role_detail_pane.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_sync.dart';
import '../support/roles_test_support.dart';

/// The list row for [name]; the detail pane repeats the selected name.
Finder _row(String name) => find.widgetWithText(ListTile, name);

IconButton _deleteButton(WidgetTester tester) =>
    tester.widget<IconButton>(find.byKey(const ValueKey('delete-role')));

void main() {
  testWidgets('lists the system roles first, then the director\'s own', (
    tester,
  ) async {
    final api = FakeRolesApi()
      ..roles.addAll([ownRole('Timer'), ownRole('Boss', n: 51)]);

    await tester.pumpWidget(rolesApp(api.client));
    await tester.pumpAndSettle();

    final names = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data)
        .toList();
    expect(names, ['Helper', 'Pilot', 'Team Manager', 'Boss', 'Timer']);
    expect(find.text('System role'), findsNWidgets(3));
    expect(find.text('Your role'), findsNWidgets(2));
  });

  testWidgets('a sync of the account lists the roles it pulled', (
    tester,
  ) async {
    final api = FakeRolesApi();
    final scope = DirectorScopeKey(Id.create());
    final sync = FakeAppSync()..accountScope = scope;
    await tester.pumpWidget(
      AppSyncInherited(sync: sync, child: rolesApp(api.client)),
    );
    await tester.pumpAndSettle();
    expect(_row('Timer'), findsNothing);

    api.roles.add(ownRole('Timer'));
    sync.state = AppSyncState(
      scopes: {scope: SyncScopeSummary(dataRevision: 1)},
    );
    await tester.pumpAndSettle();

    expect(_row('Timer'), findsOneWidget);
  });

  group('system roles', () {
    testWidgets('Pilot has no Rename or Delete and says why', (tester) async {
      final api = FakeRolesApi();
      await tester.pumpWidget(rolesApp(api.client));
      await tester.pumpAndSettle();

      await tester.tap(_row('Pilot'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('rename-role')), findsNothing);
      expect(find.byKey(const ValueKey('delete-role')), findsNothing);
      expect(find.text(RoleDetailPane.pilotExplanation), findsOneWidget);
      expect(find.text('Pilot'), findsNWidgets(3)); // row, heading, type
    });

    testWidgets('another system role is protected with its own reason', (
      tester,
    ) async {
      final api = FakeRolesApi();
      await tester.pumpWidget(rolesApp(api.client));
      await tester.pumpAndSettle();

      await tester.tap(_row('Team Manager'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('rename-role')), findsNothing);
      expect(find.byKey(const ValueKey('delete-role')), findsNothing);
      expect(find.text(RoleDetailPane.systemExplanation), findsOneWidget);
      expect(find.text(RoleDetailPane.pilotExplanation), findsNothing);
    });
  });

  group('creating', () {
    testWidgets('New role opens the dialog; Create adds a non-flier role', (
      tester,
    ) async {
      final api = FakeRolesApi();
      await tester.pumpWidget(rolesApp(api.client, initial: newRolePath));
      await tester.pumpAndSettle();

      expect(find.text('New role'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('role-name-field')),
        '  Scorer ',
      );
      await tester.tap(find.byKey(const ValueKey('role-name-confirm')));
      await tester.pumpAndSettle();

      final post = api.requests.singleWhere((r) => r.method == 'POST');
      expect(post.body, contains('"display_name":"Scorer"'));
      // The new role is listed and selected.
      expect(_row('Scorer'), findsOneWidget);
      expect(find.byKey(const ValueKey('rename-role')), findsOneWidget);
      expect(find.byKey(const ValueKey('role-name-field')), findsNothing);
    });

    testWidgets('a blank name is refused before any request', (tester) async {
      final api = FakeRolesApi();
      await tester.pumpWidget(rolesApp(api.client, initial: newRolePath));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('role-name-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name for the role.'), findsOneWidget);
      expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('a name that is taken keeps the dialog open with the reason', (
      tester,
    ) async {
      final api = FakeRolesApi()
        ..failures['POST /roles'] = (
          status: 409,
          code: 'duplicate_role_name',
          message: 'a role named "Helper" already exists',
        );
      await tester.pumpWidget(rolesApp(api.client, initial: newRolePath));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('role-name-field')),
        'Helper',
      );
      await tester.tap(find.byKey(const ValueKey('role-name-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('a role named "Helper" already exists'), findsOneWidget);
      expect(find.byKey(const ValueKey('role-name-field')), findsOneWidget);
    });

    testWidgets('Cancel adds nothing', (tester) async {
      final api = FakeRolesApi();
      await tester.pumpWidget(rolesApp(api.client, initial: newRolePath));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('role-name-field')), findsNothing);
      expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    });
  });

  group('renaming', () {
    testWidgets('Rename sends the new name with the revision read', (
      tester,
    ) async {
      final api = FakeRolesApi()..roles.add(ownRole('Timer', revision: 3));
      await tester.pumpWidget(rolesApp(api.client));
      await tester.pumpAndSettle();

      await tester.tap(_row('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rename-role')));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('role-name-field')),
      );
      expect(field.controller!.text, 'Timer');
      await tester.enterText(
        find.byKey(const ValueKey('role-name-field')),
        'Timekeeper',
      );
      await tester.tap(find.byKey(const ValueKey('role-name-confirm')));
      await tester.pumpAndSettle();

      final put = api.requests.singleWhere((r) => r.method == 'PUT');
      expect(put.body, contains('"base_revision":3'));
      expect(put.body, contains('"display_name":"Timekeeper"'));
      expect(_row('Timekeeper'), findsOneWidget);
      expect(_row('Timer'), findsNothing);
    });

    testWidgets('a role in use can still be renamed', (tester) async {
      final role = ownRole('Timer');
      final api = FakeRolesApi(
        roles: [...SystemRoles.all, role],
        usage: {
          role.id: [usedIn('Spring Open', 2)],
        },
      );
      await tester.pumpWidget(rolesApp(api.client));
      await tester.pumpAndSettle();

      await tester.tap(_row('Timer'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('rename-role')), findsOneWidget);
    });
  });

  group('deleting', () {
    testWidgets('an unused role is deleted after confirmation', (tester) async {
      final api = FakeRolesApi()..roles.add(ownRole('Timer'));
      await tester.pumpWidget(rolesApp(api.client));
      await tester.pumpAndSettle();

      await tester.tap(_row('Timer'));
      await tester.pumpAndSettle();
      expect(find.text('No contest uses this role yet.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('delete-role')));
      await tester.pumpAndSettle();
      expect(find.text('Delete role?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(api.requests.where((r) => r.method == 'DELETE'), hasLength(1));
      expect(_row('Timer'), findsNothing);
    });

    testWidgets('Cancel keeps the role', (tester) async {
      final api = FakeRolesApi()..roles.add(ownRole('Timer'));
      await tester.pumpWidget(rolesApp(api.client));
      await tester.pumpAndSettle();

      await tester.tap(_row('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-role')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(api.requests.where((r) => r.method == 'DELETE'), isEmpty);
      expect(_row('Timer'), findsOneWidget);
    });

    testWidgets('a role in use is locked and shows where it is used', (
      tester,
    ) async {
      final role = ownRole('Timer');
      final api = FakeRolesApi(
        roles: [...SystemRoles.all, role],
        usage: {
          role.id: [usedIn('Fall Classic', 1), usedIn('Spring Open', 4, n: 2)],
        },
      );
      await tester.pumpWidget(rolesApp(api.client));
      await tester.pumpAndSettle();

      await tester.tap(_row('Timer'));
      await tester.pumpAndSettle();

      expect(find.text('Fall Classic: 1 participant'), findsOneWidget);
      expect(find.text('Spring Open: 4 participants'), findsOneWidget);
      expect(find.text(RoleDetailPane.inUseExplanation), findsOneWidget);
      expect(_deleteButton(tester).onPressed, isNull);
    });

    testWidgets('a refusal from the server is shown', (tester) async {
      final api = FakeRolesApi()
        ..roles.add(ownRole('Timer'))
        ..failures['DELETE /roles/${ownRole('Timer').id.value}'] = (
          status: 409,
          code: 'role_in_use',
          message: 'the role is used in 1 contest(s)',
        );
      await tester.pumpWidget(rolesApp(api.client));
      await tester.pumpAndSettle();

      await tester.tap(_row('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-role')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('the role is used in 1 contest(s)'), findsOneWidget);
      expect(_row('Timer'), findsOneWidget);
    });
  });

  testWidgets('a failed load shows the reason and Retry loads again', (
    tester,
  ) async {
    final api = FakeRolesApi()
      ..failures['GET /roles'] = (
        status: 500,
        code: 'internal',
        message: 'database offline',
      );
    await tester.pumpWidget(rolesApp(api.client));
    await tester.pumpAndSettle();

    expect(find.text('Roles could not be loaded.'), findsOneWidget);
    expect(find.text('database offline'), findsOneWidget);

    api.failures.clear();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(_row('Pilot'), findsOneWidget);
  });

  testWidgets('a narrow window shows the list, then the detail with a way '
      'back', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeRolesApi();
    await tester.pumpWidget(rolesApp(api.client));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('role-detail-back')), findsNothing);
    await tester.tap(_row('Pilot'));
    await tester.pumpAndSettle();
    expect(find.text(RoleDetailPane.pilotExplanation), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('role-detail-back')));
    await tester.pumpAndSettle();
    expect(_row('Helper'), findsOneWidget);
  });
}
