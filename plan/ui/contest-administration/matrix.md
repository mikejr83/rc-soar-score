# RC Soar Score User Interface - Matrix

The matrix and draw page is located at the route: `/contest-administration/contests/:id/matrix`.

The matrix view shows one contest matrix revision with round and group navigation. Each assignment displays pilot number when assigned, pilot name, team, role, lane when enabled, and assignment status. Non-flying participants are not assigned score slots.

The director can inspect the fairness summary, add future rounds, redraw permitted unscored rounds, and move or replace pilots only where the matrix and lifecycle rules allow it. Any action that affects a scored assignment is blocked or routed to the explicit correction/re-flight workflow; the UI must not silently reinterpret existing scores.

For seeded man-on-man, the view shows preliminary rounds, whether scores are complete and validated, and whether the next seeded round can be drawn. A draw operation shows the target rounds, configuration revision, matrix revision, and warning before confirmation. The result displays success, rejected constraints, or a recoverable failure without losing the prior matrix.
