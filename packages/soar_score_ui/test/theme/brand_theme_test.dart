import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

void main() {
  group('BrandTheme', () {
    test('light uses the kit palette and the bundled fonts', () {
      final theme = BrandTheme.light;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, BrandColors.deepOrange);
      expect(theme.colorScheme.surface, BrandColors.paper);
      expect(theme.colorScheme.onSurface, BrandColors.ink);
      // Fonts shipped by a package resolve only through the prefixed name.
      expect(
        theme.textTheme.bodyLarge!.fontFamily,
        'packages/soar_score_ui/Archivo',
      );
      expect(
        theme.textTheme.headlineLarge!.fontFamily,
        'packages/soar_score_ui/League Spartan',
      );
      expect(theme.textTheme.labelSmall!.fontFamily, BrandFonts.body);
      // Merged, not replaced: the slots keep Material's onSurface colour.
      expect(theme.textTheme.headlineLarge!.color, isNotNull);
      expect(theme.textTheme.displayLarge!.fontSize, 48);
    });

    test('dark is darker than light and keeps the night ground', () {
      final theme = BrandTheme.dark;

      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, BrandColors.nightGround);
      expect(
        theme.colorScheme.surface.computeLuminance(),
        lessThan(BrandTheme.light.colorScheme.surface.computeLuminance()),
      );
    });

    test('the three app themes are the brand theme', () {
      expect(
        ContestAppTheme.lightTheme.colorScheme,
        BrandTheme.light.colorScheme,
      );
      expect(PublicAppTheme.darkTheme.colorScheme, BrandTheme.dark.colorScheme);
      expect(
        SelfScoreAppTheme.lightTheme.colorScheme,
        BrandTheme.light.colorScheme,
      );
    });
  });

  group('BrandLogo', () {
    testWidgets('picks the file by size and ground', (tester) async {
      const tiny = BrandLogo(height: 24);
      const small = BrandLogo(height: 40);
      const full = BrandLogo(height: 96);
      const forcedDark = BrandLogo(
        variant: BrandLogoVariant.lockup,
        onDark: true,
      );

      expect(tiny.assetFor(dark: false), BrandLogos.markTinyPng);
      expect(small.assetFor(dark: true), BrandLogos.markSmallPng);
      expect(full.assetFor(dark: false), BrandLogos.markPng);
      expect(forcedDark.assetFor(dark: false), BrandLogos.lockupDarkPng);

      await tester.pumpWidget(const MaterialApp(home: full));
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).package, 'soar_score_ui');
    });

    testWidgets('the lockup follows the theme brightness', (tester) async {
      const lockup = BrandLogo(variant: BrandLogoVariant.lockup);
      String drawn() =>
          (tester.widget<Image>(find.byType(Image)).image as AssetImage)
              .assetName;

      await tester.pumpWidget(
        MaterialApp(theme: BrandTheme.light, home: lockup),
      );
      expect(drawn(), BrandLogos.lockupLightPng);

      await tester.pumpWidget(
        MaterialApp(theme: BrandTheme.dark, home: lockup),
      );
      // MaterialApp animates theme changes; let it land on the dark theme.
      await tester.pumpAndSettle();
      expect(drawn(), BrandLogos.lockupDarkPng);
    });

    test('tonal containers are the kit neutrals, not orange', () {
      expect(
        BrandTheme.light.colorScheme.secondaryContainer,
        BrandColors.tableHead,
      );
      expect(
        BrandTheme.dark.colorScheme.secondaryContainer,
        BrandColors.bezelCharcoal,
      );
    });
  });
}
