# Teams, Roles, and Models

## Roles

Roles are director-owned or system-default records with a stable identifier, display name, and type. There is exactly one `Pilot` role type; additional roles are `NonFlier`. A non-flier may be a helper or team manager and receives no score.

Role assignment is stored on the contest participation link. The display name may change in system configuration, but historical contest data retains the role identifier and contest snapshot.

## Teams and membership

A team belongs to a contest and has a unique contest-scoped name. Team membership joins participation links to teams. Pilot membership is fixed for a matrix revision and changes require a new draw or explicit matrix revision. Non-flier membership may change without redrawing and controls which pilots the helper may score for.

The team configuration stores the number of pilot totals used for the team result. Team totals are derived from eligible pilot contest totals, ordered according to the contest's configured rules; they are never entered as source data.

## Models

A reusable model catalog record may be owned by a director or shared according to future policy. A contest model link snapshots the model name, manufacturer, model identifier, and contest-specific identifier for a pilot participation link. Historical scores reference the contest snapshot so later catalog edits do not rewrite contest history.
