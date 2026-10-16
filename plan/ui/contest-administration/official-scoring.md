# RC Soar Score User Interface - Official Scoring

Official scoring is optimized for a tablet or larger screen and displays one complete group for one round at a time. Phone support is a stretch goal: the page uses the standard Material 3 window size classes, and compact widths show a stacked card per pilot instead of the grid. See [ADR 0002](../../../docs/adr/0002-score-entry-layout.md). The route identifies the contest, matrix revision, round, and group.

The scoring is performed at `/contest-administration/contests/:id/scoring`, with the round and group in the query: `?round=3&group=2` (group 1 is group A). Without them the page opens at the first group that is not completely scored.

## Navigation and grid

The page provides round navigation to first, previous, current, next, and last available rounds. Group navigation provides first, previous, next, and last groups within the selected round. The current round and group remain in the URL or route state so refresh and browser navigation restore them.

The grid includes configured pilot or lane number, team, pilot name, discipline-specific raw inputs, raw points, group points, penalty, participant-submission indicator, review-request indicator, and official status. Non-flying participants are not score rows.

Time inputs accept compact locale-aware values: `630` means 6:30 and `630.4` means 6:30.4. The field displays the parsed time and rejects impossible values without losing the original input until corrected. Time and whole-number fields request a numeric keypad.

## Score actions

The director or local operator can enter or correct raw components only when lifecycle, administration lock, score lock, and assignment rules permit it. Save creates an auditable official revision; it does not overwrite the original participant submission. Derived scores recalculate from the stored raw values.

`Score check` reports missing entries and configurable out-of-range values without changing data. The user can mark individual rows official and lock a group, round, or contest. Lock scope and current lock reason are visible in the grid. A locked score requires the authorized correction workflow.

Participant submissions that lose to an official decision remain visible in history or the director's review details. A review request shows the proposed values, message, base revision, and approve/reject actions. Approval creates a new official revision.

The page includes loading, unsaved-edit, validation, save-failed, stale-revision, and conflict states. A failed save preserves field values and identifies whether refresh, retry, or explicit conflict resolution is required.
