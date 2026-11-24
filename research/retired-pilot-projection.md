# Retired Pilot Publication Projection

This document examines how a retired pilot is represented in the publication projection and public results UI, identifying the current representation and the fields needed for a proper "Retired" row.

## Current Projection for a Retired Pilot

The projection builder (`packages/soar_score_core/lib/services/publication/publication_projection_builder.dart`) already carries retirement information. For a retired pilot, the participant entry includes `retired_at_round`:

```dart
// publication_projection_builder.dart, line 532-539
Map<String, Object?> entry(String? teamKey) => {
  'pilot_key': key,
  'classification': participation.classification,
  'number': participation.participantNumber,
  'retired_at_round': participation.retiredAtRound,
  'team_key': teamKey,
};
```

**Example JSON for a retired pilot participant entry:**

```json
{
  "pilot_key": "f5b8c2e4a1d7",
  "classification": null,
  "number": 14,
  "retired_at_round": 2,
  "team_key": "hawks",
  "details": {
    "first_name": "Chuck",
    "last_name": "Waters",
    "club": null,
    "city": null,
    "state": null,
    "country": "USA"
  }
}
```

**Current limitations:**

- The projection includes `retired_at_round` for each pilot, but the web UI (`apps/soar_score_web`) does not currently read or display it.
- A retired pilot still appears in the standings with their last computed standing as of their last flown round.
- The pilot's scores after retirement (if any re-flights occurred) still appear in `dto.scores`.
- The pilot is not visually distinguished as retired in the Overall Individual Results table.

## Flown Score Linking to Flight Groups

The flight score links back to the flight group through the URL and `?pilot=` query parameter.

**URL Pattern:**

```
/results/contests/{contestId}/rounds/{round}/flight-groups?pilot={pilotKey}
```

**Implementation:** `apps/soar_score_web/src/lib/results/paths.ts`, line 17-19:

```typescript
export const contestFlightGroupsPath = (
  contestId: string,
  round: number,
  pilotKey?: string,
) =>
  `${resultsPath}/${contestId}/rounds/${round}/flight-groups` +
  (pilotKey ? `?pilot=${encodeURIComponent(pilotKey)}` : '');
```

**Highlighting mechanism:** `apps/soar_score_web/src/components/results/flight-group-table.tsx`, line 98-105:

```tsx
{group.flights.map((f) => {
  const highlighted = f.pilotKey === highlightPilotKey;
  return (
    <tr
      key={`${f.pilotKey}-${f.isSelected}`}
      id={f.isSelected && highlighted ? flightRowId(group, f.pilotKey) : undefined}
      className={highlighted ? styles.highlight : undefined}
      aria-current={highlighted ? "true" : undefined}
    >
```

The row gets an `id` attribute (`flight-{round}-{group}-{reflight}-{pilotKey}`) and `className={styles.highlight}` when its `pilotKey` matches the `?pilot=` value.

## Dropped Round Pattern

Dropped rounds are indicated through a combination of data, styling, and a legend key.

**Data source:** `dropped_rounds` array from the standing:

```json
{
  "pilot_key": "waters",
  "place": 3,
  "tied": false,
  "raw_total": 2030,
  "dropped_rounds": [1],
  "penalty_total": 50,
  "overall_score": 1980,
  "preliminary": false
}
```

**Web UI handling:** `apps/soar_score_web/src/components/results/standing-cells.tsx`, lines 95-123:

```tsx
{
  Array.from({ length: round }, (_, i) => i + 1).map((r) => {
    const score = row.roundScores.get(r);
    const dropped = row.droppedRounds.has(r);
    return (
      <td
        key={r}
        className={dropped ? `${num} ${styles.droppedCell}` : num}
        title={dropped ? 'Dropped round' : undefined}
      >
        {score === undefined ? (
          '-'
        ) : (
          <Link
            href={contestFlightGroupsPath(contestId, r, row.pilotKey)}
            className={`${styles.scoreLink} ${dropped ? styles.struck : ''}`}
          >
            {formatScore(score)}
            {dropped && (
              <>
                <span aria-hidden="true" className={styles.droppedMark}>
                  *
                </span>
                <span className="visually-hidden"> (dropped round)</span>
              </>
            )}
          </Link>
        )}
      </td>
    );
  });
}
```

**Legend:** `apps/soar_score_web/src/components/results/overall-results-table.tsx`, lines 44-51:

```tsx
{
  anyDropped && (
    <p className={styles.tableKey}>
      <span aria-hidden="true" className={styles.droppedMark}>
        *
      </span>{' '}
      Dropped round: shaded to indicate not counted in the score.
    </p>
  );
}
```

**Pattern to copy for "Retired":**

1. Add a boolean or numeric field to the participant entry indicating retirement
2. Parse it in `published-contest.ts` into the `PilotStandingRow` interface
3. In `standing-cells.tsx`, conditionally render a retirement indicator (e.g., "Retired" pill)
4. In `overall-results-table.tsx`, add a legend entry if any pilot is retired

## Missing Fields for a "Retired" Row

Currently, a "Retired" row is **not** rendered. To display it properly, the following fields are missing from the web UI model:

### 1. `PilotStandingRow` interface needs a retirement field

**File:** `apps/soar_score_web/src/lib/results/published-contest.ts`, line 46-62

```typescript
export interface PilotStandingRow {
  pilotKey: string;
  place: number;
  isTied: boolean;
  firstName: string;
  lastName: string;
  country: string;
  overallScore: number;
  percentOfWinner: number;
  rawTotal: number;
  roundScores: Map<number, number>;
  droppedRounds: Set<number>;
  penaltyTotal: number;
  // MISSING: retiredAtRound?: number;
}
```

### 2. `row()` method needs to parse `retired_at_round`

**File:** `apps/soar_score_web/src/lib/results/published-contest.ts`, lines 233-256
The `row()` method reads the participant entry but currently ignores `retired_at_round`.

### 3. `standing-cells.tsx` needs a retirement indicator

**File:** `apps/soar_score_web/src/components/results/standing-cells.tsx`
Currently renders pilot name, country, scores, and round cells. No retirement indicator.

### 4. `overall-results-table.tsx` needs a retirement legend

**File:** `apps/soar_score_web/src/components/results/overall-results-table.tsx`
Currently shows a dropped-rounds legend only when `anyDropped` is true.

## Summary of Current vs. Needed

| Aspect                                 | Current                                        | Needed for "Retired" Row              |
| -------------------------------------- | ---------------------------------------------- | ------------------------------------- |
| Projection carries `retired_at_round`  | ✓                                              | Already present                       |
| Web UI parses `retired_at_round`       | ✗                                              | Add to `PilotStandingRow` and parse   |
| Retired pilot shows distinct styling   | ✗                                              | Add "Retired" pill or indicator       |
| Retired pilot legend                   | ✗                                              | Add legend entry in table footer      |
| Retired pilot remains in the standings | ✓ (zero for rounds after the retirement round) | Keep; mark the row as retired instead |
| Retired pilot scores shown as flown    | ✓                                              | Keep existing behavior                |
