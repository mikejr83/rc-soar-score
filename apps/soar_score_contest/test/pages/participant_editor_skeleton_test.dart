import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localization_delegates.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/widgets/participant_editor/editor_skeleton.dart';

void main() {
  testWidgets('the loading skeleton does not overflow a short window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final l10n = AppLocalizationsEn();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationDelegates,
        home: const Scaffold(body: EditorSkeleton()),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(l10n.participantEditorLoadingText), findsOneWidget);
  });
}
