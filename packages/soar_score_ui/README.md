# soar_score_ui

Shared Flutter UI package for the Soar Score RC sailplane scoring suite. Provides reusable widgets, composite components, and shared theme tokens used by the `soar_score_contest` and `soar_score_self_score` Flutter apps. The public site (`apps/soar_score_web`, Next.js) copies the fonts and logos from this package's `assets/`.

This package contains presentational-only widgets with no state or data access logic. It depends on `soar_score_core` for domain types used in widget parameters.

## Packages

- `widgets/` — reusable leaf widgets (e.g., `ScoreCard`)
- `components/` — larger composite components (cards, tables, forms — to be added)
- `theme/` — shared theme configurations and tokens

## Key widgets

- `ScoreCard` — presentational display card with title, subtitle, optional trailing widget, and optional tap behavior

## Shared theme

The package exports shared theme tokens matching both app baselines (contest and public). Both apps can consume `SoarScoreThemeTokens` to maintain consistent colors, typography, and spacing across the suite.

## Tests

```bash
cd packages/soar_score_ui
flutter test
```
