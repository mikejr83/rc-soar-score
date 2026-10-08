import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/new_contest/time_zone_picker.dart';

void main() {
  testWidgets('searching by city picks a zone with a readable label', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TimeZonePicker(
              zone: 'America/Los_Angeles',
              at: DateTime.utc(2026, 7, 1),
              onChanged: (value) => picked = value,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Pacific Time (US & Canada) · Los Angeles · UTC-07:00',
    );

    await tester.enterText(find.byType(TextField), 'rome');
    await tester.pumpAndSettle();
    final entry = find.text('Central European Time · Rome · UTC+02:00');
    expect(entry, findsWidgets);
    expect(find.textContaining('_'), findsNothing);

    await tester.tap(entry.last);
    await tester.pumpAndSettle();
    expect(picked, 'Europe/Rome');
  });
}
