# Teams, Roles, and Models

## Roles

Roles are director-owned or system-default records with a stable identifier, display name, and type. There is exactly one `Pilot` role type; additional roles are `NonFlier`. A non-flier may be a helper or team manager and receives no score.

Role assignment is stored on the contest participation link. The display name may change in system configuration, but historical contest data retains the role identifier and contest snapshot.

## Teams and membership

A team belongs to a contest and has a unique contest-scoped name. Team membership joins participation links to teams. Pilot membership is fixed for a matrix revision and changes require a new draw or explicit matrix revision. Non-flier membership may change without redrawing and controls which pilots the helper may score for.

The number of pilot totals used for the team result is a contest option, the same for every team. Team totals are derived from eligible pilot contest totals, ordered according to the contest's configured rules; they are never entered as source data.

## Models

A model belongs to a participant profile, so the same model can be used in several contests, and a profile can have any number of models. When a contest has models enabled, the director can add one or more models to each pilot in the contest; non-fliers have none. Each model a pilot enters in a contest is a contest model link, a snapshot of the model name, manufacturer and the contestant-applied model identifier, plus an identifier the contest director applied for that contest (for example a serial number or sticker showing that the model was certified before the contest). Later edits to the profile's model do not rewrite the contest's records.

Model data is optional. A model-enabled contest in which a pilot has no model shows a notice. It never blocks creating the contest, drawing the matrix, adding a participant, opening scoring, entering scores or publishing, and no first-release scoring or draw rule reads it.

Some disciplines need to know which model flew a round. In F3B a pilot flies Speed, Distance and Duration as separate flights in one round and must use the same model for all three, so the director can record which model started the round (ContestRoundModel). F3B is not part of the first release; the data model reserves the record so the discipline can be added without reworking models. The serial number check is a low-use feature for regional and world events.
