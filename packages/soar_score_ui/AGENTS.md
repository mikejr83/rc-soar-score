# UI Package Agent Guide

Shared Flutter UI components and theme tokens used by both Flutter apps.

## Structure

- `lib/widgets/` — shared widgets that are both apps' shared UI components
- `lib/theme/` — theme tokens, font sizes, spacing
- `lib/navigation/` — routing constructs shared by both apps
- `lib/constants/` — shared UI constants

## Boundaries

- **Reusable components only; no state management, no data access.** Do not import `soar_score_core`, `soar_score_api`, `soar_score_data`, or state management packages. Widgets must be stateless where possible; if state is needed, use `ChangeNotifier` or state parameters, not a state management framework.
- Must work with either app theme (light and dark).
- `theme/app_theme.dart` holds `BrandTheme` (light and dark Material 3 themes built from the brand kit) and the three app themes (`ContestAppTheme`, `PublicAppTheme`, `SelfScoreAppTheme`), which are `BrandTheme` today; per-app differentiation belongs there, not in the apps. `AppColors` (high-viz amber, the tertiary role) and `AppStatusColors` (success and warning) stay as they are.
- The brand kit (artifact "RC Soar Score Brand Kit", October 2026) lives in `theme/brand_colors.dart` (`BrandColors`), `theme/brand_typography.dart` (`BrandFonts`, `BrandTypography`) and `theme/brand_logos.dart` (`BrandLogos`, `BrandLogo`). Fonts and logos are bundled under `assets/` and declared in this package's `pubspec.yaml`, so every dependent app gets them with no pubspec change. A font shipped by a package resolves only through the `packages/soar_score_ui/<family>` name; always use `BrandFonts.*`, never a bare family name. The brand orange (`#E8420C`) is for graphics and 24px+ headings only; small text on orange uses the deep orange (`#B83300`, the `primary` role). The wordmark is drawn lettering: use the logo files, never retype it.

## Testing

- Widget tests for all exported widgets (package: flutter_test).
- Run: `flutter test`
