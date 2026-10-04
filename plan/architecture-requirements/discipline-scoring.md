# RC Soar Score Architecture - Discipline Scoring

## Purpose and boundaries

Discipline scoring converts accepted raw score components into a pilot's raw flight score, group score, contest total, and any team result that depends on those scores. The calculation service is the authority for validation and derived values. Clients may present the scoring schema and calculate previews, but a client-calculated value is never accepted as authoritative input.

The initial implementation supports the shared duration-scoring model for ALES, Thermal Duration, F3J, and F5J. F3K, F3L, and disciplines with multiple task types must be representable by the same extension boundary but are not implemented by these requirements until their business rules are defined.

## Discipline profile contract

1. Each discipline must be registered by a stable identifier and must resolve to a versioned scoring profile. A profile contains its default contest options, configuration schema, score-entry schema, validation rules, zero-score reasons, raw-score calculation, group-score behavior, and calculation metadata.
2. The service must select the profile from the contest's stored discipline identifier and rules version. It must not infer the profile from labels, client route names, or arbitrary fields in a score submission.
3. A profile must expose machine-readable field definitions, including field identifier, display label, type, unit, precision, valid range, required status, allowed values, dependencies, and whether the field is an input, a status flag, or a derived value.
4. Profile field identifiers and meanings are immutable within a rules version. A changed rule or field interpretation requires a new rules version and must not reinterpret historical scores.
5. Contest-specific overrides must be stored as data against the contest configuration and identified as overrides of the official profile. They must not mutate the shared system profile or create an untracked custom discipline.
6. The profile contract must support a multi-task discipline and multiple component scores without requiring changes to contest, round, group, review, synchronization, or publishing workflows. The initial duration profiles may expose one task with several components.

## Stored scoring data

1. A group-score record must retain the immutable submitted raw components, the actor and authority that submitted them, the source device, client mutation identifier, score revision, contest configuration revision, matrix revision, discipline rules version, calculation version, and server acceptance time.
2. A score's component set may carry two contest-level penalty components, distinct from each other and from the discipline-specific penalties the profile computes, such as the late-landing and launch-height penalties. The `Flight Penalty` is a nullable non-negative integer entered with the score by the pilot, a helper, or the director. The `Cumulative Penalty` is a nullable non-negative integer applied only by the contest director (see scores-and-results.md).
3. The record must retain the current official component set separately from the original participant submission and every accepted review proposal. Recalculation must never overwrite the original raw submission or erase superseded values.
4. A raw component must be stored in its canonical unit and precision. Display values such as `MM:ss`, landing distance, or a landing-table label must not be the source of calculation.
5. A landing selection must be stored as the identifier of the selected landing-table entry. Landing tables are immutable, so the entry identifies the selected key, the resolved point value, and the table the calculation used, and a later table choice cannot alter a historical calculation. A contest's landing table cannot be changed once a landing score has been entered.
6. Derived values must identify the exact input revision and calculation metadata that produced them. At minimum, the system must be able to reproduce the discipline raw score, group score, contest total, dropped-round decision, and team total.

## Calculation pipeline

The service must calculate scores in the following logical order. Each stage must preserve sufficient intermediate precision for the next stage.

1. Resolve the contest configuration, applicable overrides, matrix assignment, discipline profile, and rules/calculation versions.
2. Validate and canonicalize the raw components using the profile. Reject invalid combinations rather than silently repairing them, except where the profile explicitly defines a forced zero representation.
3. Apply profile-specific status rules and compute the discipline raw score. A zero condition must produce a zero raw score and retain its reason flags for reporting. Deduct any `Flight Penalty` from the discipline raw score, which never goes below zero, before the group score is computed. A dropped round therefore drops its flight penalty.
4. Compute the group score using the contest's `Raw Score`, `Normalized`, or `Time` option. Normalization is based only on the eligible pilots and the appropriate profile-defined source score.
5. Apply the configured final group-score rounding or truncation once, after normalization and other group-score arithmetic. No intermediate raw, penalty, or normalization value may be rounded or truncated.
6. Apply cumulative penalties at the contest total stage, after dropped rounds are selected. A cumulative penalty is not droppable: it continues to affect the pilot's contest total even when its round's score is dropped, and even when the flight was re-flown. An absent penalty counts as zero.
7. Select dropped rounds only after the applicable round scores and penalty metadata are available. A profile may mark a zero as non-droppable, as F5J does for a motor restart under the `Non-Droppable 0` option.
8. Calculate team totals from the resulting pilot contest totals according to the contest's configured number of pilots, ordering eligible pilot totals from highest to lowest.
9. Store or return the resulting values with their input revisions and calculation version. Recalculation from the same inputs and versions must produce the same values on every supported client and service instance.

10. For re-flight attempts, the profile must define the eligible normalization population, how the attempt contributes to each affected pilot's official round score, and how non-awarded pilots compare original and re-flight group results. The calculation must retain the attempt identifier and selection rule used.

## Shared duration-scoring behavior

1. Duration profiles must support target time or working time, points per second, optional fractional-second precision from 0 through 3 decimal places, a landing-bonus table, and an out-of-bounds landing status.
2. Time values must be non-negative and must use the profile's configured canonical precision. The service must enforce the profile's maximum time rules even if a client bypasses its form constraints.
3. An out-of-bounds landing must record the profile-defined reason and produce zero flight and landing values. The initial profiles use more than 75 meters from the pilot's landing marker as the out-of-bounds condition.
4. A zero condition must not be represented only by a numeric zero. The system must retain one or more profile-defined reason flags so reports can distinguish an ordinary zero, an out-of-bounds landing, an over-flight, a motor restart, missing altitude, and retirement where applicable.
5. If every pilot in a group has a zero raw score, the normalized group score must be zero and must not divide by zero or produce an undefined value.
6. A profile must define whether a late landing preserves flight-time points, removes the landing bonus, applies a discipline penalty, or produces a zero. The calculation engine must not infer these behaviors from a shared field name.

## Initial discipline profiles

### ALES

1. The default group-score mode is `Time`; selecting another mode is a contest override.
2. The target-time score is `points per second * time` up to the target, and `points per second * target time - points per second * over-flight time` after the target. The result cannot be negative.
3. An over-flight greater than one minute, motor restart, or out-of-bounds landing produces zero flight and landing values. These are mutually exclusive reason flags in the initial profile.
4. A landing bonus is added according to the selected group-score mode. In `Time` mode, flight time is normalized first and the landing bonus is added afterward.

### Thermal Duration

1. The default group-score mode is `Normalized`; selecting another mode is a contest override.
2. The target-time score follows the shared ALES target-time formula and cannot be negative.
3. An over-flight greater than one minute or out-of-bounds landing produces zero flight and landing values. These are mutually exclusive reason flags in the initial profile.
4. The landing bonus is included according to the selected group-score mode.

### F3J

1. The default group-score mode is `Normalized`, and the default final total precision is truncation to one decimal place.
2. The working-time score is `points per second * time flown`. The submitted time must not exceed the working time.
3. An out-of-bounds landing produces zero. A late landing removes the landing bonus and applies the fixed 30-point discipline penalty to the round; the penalty remains associated with the round.
4. Landing points are added according to the selected group-score mode. Fractional-second precision is applied to the stored time input without intermediate rounding.

### F5J

1. The default group-score mode is `Normalized`, and the default final total precision is rounding to one decimal place.
2. The raw score is flight-time points plus any eligible landing bonus minus the launch-height penalty. The result cannot be negative.
3. For altitude at or below the reference height, the height penalty is `altitude * minor penalty per meter`. Above the reference height, it is `reference height * minor penalty per meter + (altitude - reference height) * major penalty per meter`.
4. A motor restart, missing altitude, or out-of-bounds landing produces zero flight and landing values. A motor restart may be marked non-droppable when configured; missing altitude and out-of-bounds remain reportable reason flags.
5. A late landing preserves flight-time points, removes the landing bonus, and records the late-landing status. Flight time is capped by the working time and uses the configured time precision.
6. The `Not Allowed` motor-restart option controls the entry schema and must not be treated as automatic enforcement of the physical contest rule. The `Allowed` and `Non-Droppable 0` options must remain distinguishable in calculation metadata.

## Validation and authority

1. The service must validate field types, ranges, precision, required fields, mutually exclusive statuses, dependent fields, contest configuration, and profile-specific formulas before accepting a score.
2. Forced-zero selections must clear or ignore the associated numeric components only according to the profile contract, and the canonical stored result must make the zero and its reason explicit.
3. A participant or offline client may submit a schema version, but the service must resolve the authoritative schema and reject stale or incompatible submissions. The client must not add, omit, rename, or reinterpret fields.
4. A score calculation must be atomic with acceptance of an official component set. A failed validation or calculation must not create a partial official score, alter contest lifecycle, or trigger a public projection update.
5. An accepted score must be idempotent by client mutation identifier and must return the resulting score state, derived values, validation messages, and calculation metadata.

## Recalculation and change management

1. Any change to a calculation-affecting contest option, discipline override, landing table, matrix assignment, or rules/calculation version marks the affected stored results stale until they are recomputed from the immutable raw data. Stored results carry the revisions they were computed under so staleness can be detected.
2. Recalculation must preserve score state, review history, source metadata, and audit records. Superseded computed values are not kept; the published projections are the record of what was shown.
3. Changes to the discipline and to the values of its scoring rules are prohibited once the contest reaches `Running`, except for changes already permitted by contest-state requirements. Derived-score options, such as the group-score mode, rounding, decimal places, dropped rounds, the tie-breaker, and the team pilot count, may change until the contest is completed. Such a change must trigger a complete affected-scope recalculation.
4. Public projections, participant results, rankings, and team totals use only results computed from the current official component sets under the current configuration, matrix, and calculation version. A stale or incomplete result, such as one with missing scores or open reviews, must be marked preliminary and must not be presented as official.

## Verification requirements

1. Each profile must have executable examples covering normal scores, ties, zero-only groups, out-of-bounds landings, boundary times, precision limits, landing bonuses, invalid combinations, and final rounding or truncation.
2. F5J tests must cover both sides of the reference altitude, motor-restart droppable and non-droppable behavior, missing altitude, late landing, and a height penalty that would otherwise make the raw score negative.
3. ALES and Thermal tests must cover target-time over-flight, the one-minute over-flight boundary, `Time` versus `Normalized` group scoring, and landing-bonus ordering.
4. F3J tests must cover working-time limits, fractional seconds, late landing without a landing bonus, and the fixed late-landing penalty.
5. Golden calculation fixtures must record raw inputs, profile and configuration versions, intermediate values where needed for audit, and final values. The service and any offline calculation library must pass the same fixtures.
6. Property-based or equivalent invariant tests should verify that scores never become negative where the profile forbids it, normalization never divides by zero, rejected inputs do not mutate official data, and recalculation is deterministic.
