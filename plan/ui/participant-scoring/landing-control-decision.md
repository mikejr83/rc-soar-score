# Landing control: choose by table size

Status: decided in design review, 2026-10-22. Applies to the self-scoring app's score entry form (participant scoring).

## Decision

- Landing tables are defined per contest. They are arbitrary, so the discipline does not decide the landing control. The table size does.
- Threshold: 20 results. This is the size of the F3J landing table.
  - 20 results or fewer: a bottom sheet listing each result with its label and points. Pilots choose by tapping a row.
  - More than 20 results: an autocomplete combobox. The pilot types part of a label or a number, a short list of matches appears, and picking one selects that single result.
- Each landing result is one object from the contest's table (id, label, points). The form stores the selected object's id, and the read-only view shows its label and points.
- Autocomplete matches on the label, and on the value when the label is numeric. A typed value with no match shows "not on the landing table". Nothing is selected.
- Example: Thermal Duration landing is scored in 1" steps up to 100" from the landing spot, so its table has one result per inch and goes to autocomplete.
- Late landing and Out of bounds clear the selected result and disable the landing control, with the reason shown in text. This applies to both controls.

## Open questions

- Is the threshold a single global value (20), or can a contest's table change it?
- For the sheet at 20 rows, does the sheet need a full-height view with scrolling? (About 1,100px at 56px per row.)
- Does a Thermal Duration result need its inch value shown as the label, or only as the points?
