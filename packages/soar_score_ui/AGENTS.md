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

## Testing

- Widget tests for all exported widgets (package: flutter_test).
- Run: `flutter test`
