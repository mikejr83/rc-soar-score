import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

void main() {
  test('SelfScoreAppTheme provides Material 3 light and dark themes', () {
    final light = SelfScoreAppTheme.lightTheme;
    final dark = SelfScoreAppTheme.darkTheme;

    expect(light.useMaterial3, true);
    expect(dark.useMaterial3, true);
    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
  });
}
