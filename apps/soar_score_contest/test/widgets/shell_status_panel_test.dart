import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/shell_status_panel.dart';
import 'package:soar_score_core/soar_score_core.dart';

Contest _contest({ScoringAccess access = ScoringAccess.closed}) => Contest(
  id: Id.parse('019c0000-0000-7000-8000-000000000017'),
  name: 'Front Range ALES Open',
  startDateTime: DateTime.utc(2026, 10, 17, 14),
  endDateTime: DateTime.utc(2026, 10, 18, 14),
  timezone: 'America/Denver',
  host: 'Front Range Soaring',
  lifecycleState: LifecycleState.running,
  scoringAccess: access,
  adminLock: AdminLock.locked,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

void main() {
  testWidgets('shows status, participant scoring and administration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShellStatusPanel(contest: _contest(access: ScoringAccess.open)),
        ),
      ),
    );

    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Lifecycle'), findsNothing);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Participant scoring'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Administration'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
  });
}
