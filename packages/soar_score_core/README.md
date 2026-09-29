# soar_score_core

Core domain models, business logic, and the scoring engine for the Soar Score RC sailplane soaring contest scoring suite. Pure Dart with no Flutter dependencies, testable and reusable from all apps and packages in the monorepo.

## Packages

- `models/` — domain model types (`Contest`, `ContestStatus`, pilots, flights, scores, etc.)
- `scoring/` — discipline profiles and the scoring engine (ALES, F3J, F5J, Thermal)
- `disciplines/` — per-discipline rule logic
- `errors/` — domain error types
- `repositories/` — repository interfaces for the data layer

## Key types

- `Contest` — complete contest model with matrix, configuration, and participation
- `ContestStatus` — derived contest state (scheduled, ongoing, scored, etc.) computed from independent control states
- `Pilot` — pilot entity (registration, class)
- `Flight` — flight entity (takeoff/landing, duration, speed)
- `FlightScore` — flight-specific score components
- `Score` — pilot's aggregate contest score
- `ScoreStatus` — score state (provisional, official, discarded)
- `ContestMatrix` — matrix of pilot/flight rows and scoring columns
- `ContestConfiguration` — configuration and scoring parameters
- `ContestParticipation` — participation state (registered, entered, retired, DNS, DNF)
- Repository interfaces (in `repositories/`) — abstract contracts for each entity's data layer
- Error types (in `errors/`) — domain errors (validation, not found, duplicate, etc.)

## Tests

```sh
cd packages/soar_score_core
dart test
```

All tests are pure Dart unit tests — no network, no file I/O, no external services.
