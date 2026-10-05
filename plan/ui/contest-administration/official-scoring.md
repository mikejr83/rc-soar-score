# RC Soar Score User Interface - Official Scoring

Official scoring is optimized for a tablet or larger screen and displays one complete group for one round at a time. The route identifies the contest, matrix revision, round, and group.

The scoring is performed with the following route scheme: `/contest-administration/contests/:id/scoring/rounds/:round/groups/:group`.

## Navigation and grid

The page provides round navigation to first, previous, current, next, and last available rounds. Group navigation provides first, previous, next, and last groups within the selected round. The current round and group remain in the URL or route state so refresh and browser navigation restore them.

The grid includes configured pilot or lane number, team, pilot name, discipline-specific raw inputs, raw points, group points, flight penalty, cumulative penalty, participant-submission indicator, review-request indicator, and official status. Non-flying participants are not score rows.

The penalty is split into two columns:

- **Flight penalty:** entered with the score by whoever enters it (the pilot, a helper, or the director). It is part of the round score.
- **Cumulative penalty:** applied by the director only, on the official score of the flight where it was given. The column shows none, an amount, or "zeroed out" when a penalty was removed.

Time inputs accept compact locale-aware values: `630` means 6:30 and `630.4` means 6:30.4. The field displays the parsed time and rejects impossible values without losing the original input until corrected.

## Score actions

The director or local operator can enter or correct raw components only when lifecycle, administration lock, score lock, and assignment rules permit it. Save creates an auditable official revision; it does not overwrite the original participant submission. Derived scores recalculate from the stored raw values.

`Score check` reports missing entries and configurable out-of-range values without changing data. The user can mark individual rows official and lock a score, group, round, or contest. A score is locked if any of the four applies. Lock scope and current lock reason are visible in the grid. A locked score requires the authorized correction workflow, and overriding a lock requires a recorded reason. Applying a lock first lists any outstanding review requests in its scope for the director to resolve or dismiss.

A participant submission that lost to the director's value is kept as a silent record in the score's history and in the director's review details. It does not appear in the list of conflicts that need action. A review request shows the proposed values, including any proposed flight penalty, the message, the base revision, and approve/reject actions. Approval creates a new official revision.

The page includes loading, unsaved-edit, validation, save-failed, stale-revision, and conflict states. A failed save preserves field values and identifies whether refresh, retry, or explicit conflict resolution is required.
