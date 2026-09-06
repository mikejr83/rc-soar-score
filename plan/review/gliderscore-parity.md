# GliderScore Feature-Parity Analysis

Companion to `gap-analysis.md`. That doc found gaps *internal* to the plan; this one finds gaps
**relative to GliderScore**, which the plan is evidently rebuilding.

**Sources** (all verifiable, no decompilation needed):
- `GliderScoreData.mdb` — the shipped Access database, 28 tables. This is GliderScore's actual data
  model, extracted with `access-parser`. Cited below as `Table.Column`.
- gliderscore.com feature pages: `Setup`, `DrawRounds`, `Scoring`, `Reports`, `Audio`,
  `OnLineScores`, `FAQ`.
- `ReadMe.txt` and UTF-16 string tables from `GliderScore.exe` (VB.NET / .NET 4.8).

The installer is an IZArc self-extracting zip — plain `7z x`. The app is VB.NET over a single Access
file at `C:\GliderScore6`, ~74 pilots and 14 sample competitions with 2,702 score rows shipped.

---

## 0. Five scoping decisions before any parity list means anything

**S1. Which disciplines are the parity target?** GliderScore supports 16: F3B, F3F, F3G, F3J, F3K,
F3L, F3Q, F5B, F5J, F5K, F5L, Thermal, Electric, ALES (+ multi-task variants). The plan targets five
(ALES, F3J, F5J, F3L, Thermal). **This analysis assumes the plan's five** and deliberately excludes
lap counting, watt-minutes, speed tasks, and multi-task rounds. If parity means all 16, the scope
roughly triples and the data model changes shape (see `Scores.Laps`, `Scores.TaskNo`,
`F5B.WattMinSpecs`, `Scores.Flight1..4`).
→ **Q for owner:** parity across the plan's five, or all of GliderScore's classes?

**S2. Is the audio/timer/display subsystem in scope?** This is a large, self-contained product:
`AudioSettings` (233 rows), `TimerSettings` (787 rows), `TimerNames` (18 timer profiles), 211 shipped
WAV files, a separate `GliderScoreDigitalTimer.exe`, text-to-speech pilot-name generation, playlist
building, playlist *merging* across simultaneous competitions, and serial output to external LED
displays in six protocols (mmss, Aerobtec, Embedded-Ability, Extended, Extended+Pandora,
Extended+RGB). It runs the contest clock and calls the working time over a PA.
For many CDs this is *why they use GliderScore* — it isn't a side feature. The plan does not mention
it at all.
→ **Q:** in scope, out of scope, or a separate later application? A browser app has real constraints
here (serial ports, reliable offline audio, sleep prevention).

**S3. Frequency management — keep, make optional, or drop?** GliderScore treats radio frequency as a
first-class draw constraint: `CompPilots.DrawFreq`, `Comps.Enforce20KHz`, and the minimum-groups
calculation is driven by the most-used frequency. In 2026 nearly everyone is on 2.4GHz (GS makes you
literally type "2.4"). This is a legitimate simplification, not an oversight — but it is a *decision*.
→ **Q:** drop it, or keep it for clubs still flying 35/72MHz?

**S4. Contest series / aggregate scoring — parity or later?** `CompSeries` (`SeriesNo`, `SeriesDate`,
`ScoresToCount`, `Decimals`, `SeriesType`, `SeriesName`) plus `Comps.CompSeriesNo` — GliderScore
aggregates a season/league across contests, counting the best N. Absent from the plan entirely.

**S5. Can we get the source?** If yes, the highest-value uses are narrow: the exact **normalisation
edge cases** (all-zero group, single-pilot group), the **tie-break rule**, the **draw algorithm** and
its Mean Absolute Deviation fairness metric, and the **drop-score + penalty interaction order**. These
are the things neither the schema nor the docs answer. Decompiling 10MB of VB.NET to find them is not
worth it; asking is.

---

## 1. `business-requirements/contest-configuration.md`

| GliderScore feature | Source | Plan status |
|---|---|---|
| Up to **5 drop scores**, each with its own round threshold; `99` = never drop | `Comps.Drop1AtRound`…`Drop5AtRound`, `Comps.DropScoreOption` | **Partial** — plan has a single drop. Resolves the "one drop or one per N?" question in gap C3. |
| **Target time varies per round**, set from the scoring screen; all scores for that round recompute | `DurTargetTimeByRound`, ReadMe.txt, FAQ Q2 | **Absent** — plan has one contest-level target time. This is called out in their own ReadMe as a headline capability. |
| `OmitFromTeamScore` (OTS) per pilot — counts in the draw and team protection but not the team score | `CompPilots.OmitFromTeamScore`; FAQ Q4 (defending champion flying with their national team) | **Absent** |
| **Assign Helpers** — helper allocated per pilot per group during the draw, rotating across rounds | `Comps.AssignHelpers`, `Scores.Helper` | **Absent**. Constraints: single-task comps only; not available with team protection, one group per round, or multi-class. |
| **1 or 2 timekeepers**; two independent recorded times per flight | `Dur.durNumberOfTimekeepers`, `Scores.Time1Mins/Secs`, `Time2Mins/Secs` | **Absent**. eScoring requires single-timekeeper. |
| Min **and** max pilots per group as explicit config | `Dur.durPilotsMin` / `durPilotsMax` | **Partial** — plan derives min/max for display only. |
| Roles ship as combined types: CD, CD/Plt, TM, TM/Plt, Hlp, Plt | `Roles` table (6 rows) | **Conflict** — `managing-system.md` says there can be only one "pilot" type and the CD isn't a participant. GS has three pilot-capable roles including the CD. |
| Group Score = None / Points / Time | `Comps.GroupScoreOption` | **Present** — maps to plan's Raw / Normalized / Time. Not a gap, just confirm naming. |
| Round-vs-truncate + 0–3 decimals; changing them triggers full recalculation | `Comps.RoundOrTruncate`, `GroupScoreDecimals` | **Present** |
| F5J height penalty (ref height, minor/major per metre) and motor-restart modes | `Dur.durRefHeight`, `durPenaltyUpToRefHeight`, `durPenaltyOverRefHeight`, `F5JMotorRestartOption` | **Present** — plan matches well. |
| **`FlightScoreDeduction` is a separate field from `Penalty`** | `Scores.FlightScoreDeduction` vs `Scores.Penalty`; Setup page "Deduction From Flight Score" | **Answers gap C3** — F3J's late-landing deduction and a CD's general penalty are two different mechanisms, applied at different points. The plan needs both. |
| Per-discipline "Deduction" selector: None / Late Landing / Height Penalty / Motor Run / Penalty F3Q | Setup page, per class | **Absent** as a concept — the plan hardcodes deductions per discipline instead of modelling them. |

**Landing tables are distance→points lookups, not key/value.** `LndgPoints` has 1,607 rows across 9
named tables (`LndgNames`): FAI 15 Metre Tape, F3J/F3L/F5L Enter Dist, …Enter Points, …Enter Pts to 2m,
F5J Enter Distance, ALES Landing, F3J Enter Cms, F5B Enter Distance. Columns are
`LndgNo, Distance, Points`. Note the variants encode *what the scorer types* — distance in metres,
distance in centimetres, or points directly. `managing-system.md` describes these as generic key/value
pairs where "the value is always known as Points"; that's close but misses that the key is a measured
distance with table-specific units and granularity.

---

## 2. `business-requirements/contest-draw.md`

| GliderScore feature | Source | Plan status |
|---|---|---|
| **Back-to-back constraint** — prevent a pilot in the last group of round N also being in the first group of round N+1. Requires ≥3 groups/round. GS documents the tradeoff: "No" reduces draw fairness, though the effect is small at ≥5 groups. | `Dur.durAllowBackToBack` | **Absent** |
| **Fairness = Mean Absolute Deviation**, shown on a "Check Draw" screen with a bar graph of pilot-meeting distribution over a selectable round range | DrawRounds page | **Partial** — plan says "should be evaluated for fairness… a summary presented" without saying what the metric is. MAD is a concrete, cheap answer. |
| **Run the draw repeatedly and keep the best** — "no two draws will be the same"; system keeps the better of the two unless you force replacement | DrawRounds page | **Absent** — plan implies a single deterministic draw. This is the actual UX. |
| **Lane modes: None / Random / Team / Closest** (+ total lanes count), plus a post-draw **Swap Lanes** screen with team filtering | `Dur.durNbrOfLanes`, Setup page | **Partial** — plan has None/Random only. |
| **Switch Pilots** — replace one entrant with another across *all* rounds after the draw, even with scores entered | Setup page | **Absent** — plan only covers adding a late pilot randomly. This is the more useful operation (fixes entry errors without a redraw). |
| Minimum groups per round auto-calculated from largest team (if team protection) and most-used frequency | FAQ Q6 | **Partial** — plan has the team half, not the frequency half (see S3). |
| **Seeded MOM restrictions**: requires ≥2 groups/round, single-task comps only, no frequency clashes; a dedicated button draws the *next* round after the previous completes; retired pilots excluded | DrawRounds page | **Answers gap C1** — this is how seeded MOM coexists with a matrix: rounds are drawn incrementally *during* the running state, one at a time. The plan's state model needs to allow that. |
| Retire / **Un-retire** a pilot, with re-draw optimisation | `CompPilots.Retired`, Scoring page | **Partial** — plan has retirement but no un-retire. |

---

## 3. `business-requirements/contest-official-scoring.md` (currently a stub) and `mvp-application.md` §Scoring

| GliderScore feature | Source | Plan status |
|---|---|---|
| **Reflights — three modes**: *Move Pilot to Another Group* (blocks frequency/team clashes), *Re-Fly this Group* (same pilots, incremented reflight number), *Create a New Group* (hand-picked). Pilot takes their **best score across all flights** for the round; a reflight scored in a later round still credits the **original** round. | `Scores.ReFlightNo`, `Scores.OriginalRoundNo`, Scoring page | **Absent entirely.** Confirms gap C3. This touches the data model (composite key includes ReFlightNo), the state model, and the matrix. Any FAI CD will expect it. |
| **Score Check with configurable upper/lower limits**, colour-coded: red below limit, blue above, grey OK. Limits settable for times, landing scores, laps, speeds. Filter to one pilot or one round. | `Scores.ScoresChecked`, Scoring page | **Partial** — plan's Score Check only reports *missing* scores. GS's version catches typos, which is the more common failure. |
| **Best Flights** panel — live ranked list of top flights with components (time, landing, height), top 50 with expand | Scoring page | **Absent** |
| **Running Results** from inside the scoring screen — through current round / current round only / current group | Scoring page | **Absent** |
| Delete Round / Delete Group | Scoring page | **Absent** |
| Keyboard nav: Ctrl+←/→ prev/next, Ctrl+Home/End first/last | Scoring page | **Present in spirit** — plan specifies the same navigation as buttons. Add the shortcuts. |
| Time shorthand: `630` → 6:30, `630.3` → 6:30.3, comma decimals by locale | Scoring page | **Present** — plan matches exactly. |
| **Lock Data** per competition; manually entered/amended scores resist being overwritten by a download | `Comps.ScoresLocked`, Scoring page | **Present**, and the second half is worth stealing — "manual edits win over synced data" is a clean, simple answer to the conflict rule missing from `offline-synchronization.md` (gap B1). |
| `Scores.Updated` timestamp, `Scores.SeqNo` (flight order within group), `Scores.ModelID` | schema | **Partial** — plan's `data.md` has none of these. |
| `Scores.LandingOver75m` | schema | **Present** |
| Multi-class in one competition via a documented workaround (duplicate pilot entries suffixed `+ALES`, two-person teams to force separate groups) | FAQ Q1 | **Absent** — worth noting this is a *hack* in GS, and a genuine improvement opportunity: model multi-class properly. |

---

## 4. `architecture-requirements/data.md`

Entities present in GliderScore and missing from the plan's data model — this substantially extends
gap C2:

- `CompSeries` — season/league aggregation (see S4).
- `Comps.PrelimCompNo` — links a fly-off to its preliminary competition; `Comps.MergedComps` merges
  competitions. The plan mentions "fly-off" once, unspecified. There's a dedicated
  **FlyOff and Prelim Results** report.
- `DurTargetTimeByRound`, `F3KTaskByRound`, `F5KTaskandRefHeightByRound` — the per-round override
  pattern. Generalise it.
- `LndgNames` / `LndgPoints` — landing tables (above).
- `Roles` — role code + display name.
- `CountryCodes` (206 rows) — reference data.
- `ModelNames`, `DeviceNames`, `CompPilots.ModelData` — model *and* altimeter device registry, with
  serial numbers. Plan tracks model name + id only; F5J altimeter devices are a real audit need.
- `CustomReportsData` — per-competition report branding: two logos with dimensions, six header lines,
  two footer lines, matrix-badge header and logo.
- `QRCodeSpecs` — configurable QR payload (see §6).
- `Comps.BadgeSpecs` — identification badges.
- `AudioSettings`, `TimerNames`, `TimerSettings` — the audio subsystem (see S2).
- `DBParams` — decimal/list separator and locale, stored per install. The plan's "user's UI locale
  dictates decimal separator" is the modern equivalent; note that CSV import/export needs the same
  treatment (GS ships two CSV templates, comma and semicolon).

Also on `Pilots`, GliderScore stores more than the plan: `Street, Town, State, PostCode,
PrivatePhone, WorkPhone, Club, OtherRegistration, FAI_ID, UsualClass, UsualModel, Filter`. The plan
has a narrower set. `UsualClass`/`UsualModel` are the "remember last used" behaviour the plan
describes for classes — GS stores it on the pilot.

Notably **absent from GliderScore**: any review-request or score-audit table. See §7.

---

## 5. Reports — fills gap C5 completely

The plan specifies zero reports while making Reports a navigation target and justifying pilot classes
solely as a reporting feature. GliderScore's list is the parity baseline:

**Standard:** Overall Results (with drops and penalties, optionally per-flight detail) · Position
Report (ranking as at the end of each round) · Team Results (configurable member count) · Flight
Scores (by group or pilot; filter by round range/group/pilot) · Flight Scores Ranked by Task ·
Task Results by Task · Landing Results · Height Penalty (with averages) · Round by Round Scores
(printable progressively as the contest runs).

**Draw:** large/small draw, tabular, team-based, scoring sheets, pre-filled score cards, QR-coded
score cards, identification badges, and **Matrix Badges** (a pilot's round+group assignments for up
to 24 rounds on one badge).

**Custom:** Custom Overall Results, Custom Team Results, Custom Team Results Summary, FlyOff and
Prelim Results — all with configurable logos, six header lines, two footer lines, and toggles for
start numbers, class, team, percentages, raw scores.

**Distribution:** preview / print / PDF / CSV / publish online, plus **email distribution** with SMTP
config (ISP/Gmail/Hotmail, encrypted password, 2FA), auto-populated pilot addresses, attachments, and
per-pilot / per-team / all-pilot eScoring links.

**Preferences:** scope filter (All / Country / Club / Class), round-range selection, show-hide toggles.

*(One caveat: an automated summary of the Reports page claimed there is no badge/QR/scorecard
generation. That's wrong — the DrawRounds page describes them and `QRCodeSpecs` / `Comps.BadgeSpecs`
exist in the schema.)*

---

## 6. eScoring — fills gap B2 (`self-scoring-invites.md`, currently empty)

Recovered from string constants in `GliderScore.exe` and the `QRCodeSpecs` table:

```
http://gliderscore.com/escoring.aspx?ID=<CompID>&P=<PilotNo>
```

`CompID` is a 12-hex-character opaque per-competition token (`Comps.CompID`, e.g. `316042b1e1d9`).
The QR payload is assembled from `QRCodeSpecs` rows — configurable, ordered by `Seq`, each with an
identifier prefix and terminator. Available fields: `ID` (CompID), `P` (PilotNo), `R` (RoundNo),
`G` (GroupNo), `F` (ReFlightNo), `T` (TaskNo), `S` (StartNo), `N` (PilotName), `C` (CompNo), plus a
QR error-correction level. Default shipped config includes URL + CompID + PilotNo only.

Supporting endpoints, also from the binary: `scoringdataupload.aspx`, `scoringdatadownload.aspx`,
`scoringdatamanage.aspx`, `onlinescores.aspx?ID=`.

**The security model is: opaque contest token + sequential pilot number.** Anyone with one pilot's QR
code can score for every pilot in that contest by editing `P=`. No per-pilot secret, no expiry, no
revocation.

→ This is exactly what the plan should **not** copy. `data.md`'s per-participant **Scoring UUID** is
strictly better. Write `self-scoring-invites.md` around that, and answer the questions GliderScore
never had to: delivery, revocation, expiry, and how a helper's link resolves to their team's pilots.

**Sync behaviour worth copying:** upload is blocked while undownloaded server scores exist, to prevent
data loss; manual edits resist being overwritten on download; a competition toggles Public/Private at
any time from the upload screen; publishing does **not** require eScoring; viewers refresh to see the
in-progress round with provisional rankings. Note the last point contradicts the plan's default of
"require validation before score calculation" (gap A6) — GliderScore shows provisional live results.

---

## 7. Where the plan already goes beyond GliderScore

Worth stating explicitly so these don't get cut as scope creep during a parity pass:

1. **Score review request workflow.** GliderScore has no equivalent — no review table, no approval
   flow, no audit trail. A pilot who mis-enters simply tells the CD. The plan's
   `score-review-requests.md` + audit trail is a genuine improvement.
2. **Offline/online as a designed architecture.** GS's story is "copy `C:\GliderScore6` to a USB
   stick," and its own FAQ warns that export/import breaks eScoring because CompIDs and pilot numbers
   diverge. The plan's sync design is the improvement — but see B1, it's the unfinished doc.
3. **Immutable original score + tracked official score.** GS overwrites in place.
4. **Web-native and cross-platform.** GS is Windows/.NET on a single-user Access file, with a
   documented "copy folders to a backup computer" disaster plan and no concurrent multi-user access.
5. **Proper multi-class support**, versus GS's documented `LastName+ClassName` duplicate-entry hack.
6. **Public site as a designed product** rather than an upload target.

---

## 8. Free test fixtures

`GliderScoreData.mdb` ships 14 real competitions and 2,702 score rows across the disciplines. Once the
scoring engine exists, these are ready-made regression fixtures for validating normalisation, drops,
penalties, and height penalties against known-correct output.

---

## 9. Questions to take to the owner

1. **Parity scope: which disciplines?** Default assumption here is the plan's five. All 16 changes
   the data model shape.
2. **Is the audio/timer/display subsystem in scope?** It's arguably GliderScore's differentiator and
   is a separate application's worth of work — with real browser constraints.
3. **Frequency management: keep, optional, or drop?**
4. **Contest series aggregation: parity or later?**
5. **Can we get the source?** If so, the specific asks are: normalisation edge cases (all-zero group,
   single-pilot group), tie-break rule, the draw algorithm + MAD calculation, and the exact order of
   drop-score / penalty / team-score application.
6. **Reflights, per-round target times, and multi-drop-scores** are the three biggest absences and
   all three affect the data model. Are they in the MVP or explicitly deferred? (Deferring is fine —
   but the schema should leave room, since retrofitting `ReFlightNo` into a score's identity later is
   painful.)
