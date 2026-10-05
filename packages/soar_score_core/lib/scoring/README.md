# scoring

Pure-Dart scoring engine. It depends on no data layer.

- `profile/` holds the profile framework: field definitions, validation, the
  profile registry and contest option overrides.
- `duration/` holds the time-to-points rules shared by duration disciplines.
- `group/` holds the group score modes (`Raw`, `Normalized`, `Time`) and the
  single final rounding or truncation step.
- `f5j/` holds the official F5J profile: field definitions, option parsing, the
  height penalty, zero reasons and the flight calculation.
- `thermal/` holds the official Thermal Duration profile: field definitions,
  option parsing, zero reasons and the flight calculation on top of the shared
  target-time rules in `duration/`.
- `f3j/` holds the official F3J profile: field definitions, option parsing, zero
  reasons and the flight calculation with the fixed late landing penalty.
- `totals/` holds the contest total: dropped rounds (never a non-droppable
  zero), cumulative penalties applied after drops, and the preliminary flag.
- `standings/` holds the pilot places (shared places, optional tie-breaker) and
  the team totals with the team fallback tie-breakers.
