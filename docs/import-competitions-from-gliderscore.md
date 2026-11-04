# Import competitions from GliderScore

The Windows contest app can turn competitions in a GliderScore database into
contests, complete with their draw and scores. It reads the file on your
computer; nothing is sent anywhere. The file is not changed, and GliderScore
does not need to be running.

An import is a **restore**: the contest is what GliderScore held when the file
was made. Each competition you choose becomes one contest with its settings,
participants, draw, scores, re-flights, retirements and, if you want, its
final state. A competition is imported whole or not at all; there is no
half-imported contest.

## How to use it

1. On the **Contests** page, choose **Import from GliderScore…**.
2. Choose the GliderScore database (`.mdb`). The app shows **Reading…** while
   it reads and maps the file, and you can cancel it.
3. Tick the competitions to import. None are ticked to begin with. A competition
   that cannot be imported has no checkbox and says why. Each row says how
   many participants and scored flights the competition has and warns about
   anything adjusted (see _What the warnings mean_).
4. For each ticked competition with scores, decide **Mark the contest
   Completed**. It starts ticked when the file shows a finished competition
   (every flown round fully scored) and unticked otherwise.
5. Review the pilots of the competitions you chose. This is the same review as
   [importing pilots](import-pilots-from-gliderscore.md): new pilots are added,
   pilots you already have are updated, and a pilot who might be someone you
   already have waits for your choice.
6. Check the summary and choose **Import**.
7. The last step shows what happened to each competition. **Open** goes
   straight to the contest.

## What is imported

- The name, the venue and the date. GliderScore stores no time zone, so the
  contest uses the time zone of this computer; the end date is the start date.
- The scoring settings that Soar Score has a place for, such as the target
  time, drops and team scoring. A setting that is out of range is replaced by a
  safe value, and the list of competitions says so.
- Every participant, with their role (pilot, helper, team manager or
  competition director), start number and team. GliderScore has no team
  names, so teams are named Team 1, Team 2 and so on. Rename them afterwards.
- The draw: rounds, groups and every pilot's place as GliderScore drew it. The
  draw is a copy; it cannot be reproduced from a seed.
- Every scored flight: time, launch height, landing, penalty and motor restart.
  Each becomes an official score, with a record that says it was restored from
  GliderScore.
- Re-flights of whole groups. Soar Score shows each as an extra group after the
  regular groups of its round, so the group number differs from GliderScore's.
- Retirements. A pilot marked retired in GliderScore retires from the round
  after their last scored flight (round 1 when they have none); the list says
  which were worked out this way.
- The landing table the competition used. A table Soar Score ships is used
  as it is; a table of your own is brought in as a landing table of the same
  name.
- The pilots themselves, as participants in your list.

## The final state

- **Completed ticked:** the contest is Completed and locked. Rounds after the
  last scored round (rounds nobody flew) are cancelled, all other rounds are
  locked, and scoring is closed.
- **Completed not ticked:** the contest is Running, so you can carry on
  scoring in Soar Score. A competition with no scored flights becomes Ready,
  with the draw and nothing scored.

## The check against GliderScore

Before the import is kept, Soar Score recalculates every flight and compares
it with the score GliderScore recorded. If any score differs, **nothing of that
competition is kept** and the last step names the first few flights (round,
group and pilot) so you can look at them. Other competitions in the same run are
not affected.

## What the warnings mean

- _Teams are named Team 1, Team 2…_: GliderScore has no team names.
- _N pilots are marked retired_: the retirement round was worked out from the
  last score.
- _N re-flights are imported as extra groups_: see above.
- _N flights have a motor restart GliderScore did not count_: the competition
  does not allow restarts (or the file predates the setting), so the score is
  kept as GliderScore recorded it. A competition that does allow restarts
  scores such a flight as zero, as GliderScore did.
- _N rounds have flights without a score_: a round was only partly flown.
- _N flights have no time, landing or penalty_: they are imported as zeros.
- _N landing values are not in the landing table_: they are left out, and the
  check against GliderScore decides whether the scores still agree.

## What is not imported

- The history of how a score came about (who entered it, when, and any review).
  Every restored score has one record, made at the time of the import.
- Subset re-flights, flights credited to another round, and competitions whose
  tasks overlap. Such a competition cannot be imported, and the list says so.
- Publication settings, audio profiles, score locks, and a preliminary
  competition linked to another one.
- Street, post code, phone numbers, usual class and usual model of a pilot.
- GliderScore's own test pilots (last name starting with `ZZ`).
- The lane count setting. Soar Score has none; the draw uses it once.

## Which competitions can be imported

- **F5J** competitions can be imported.
- **F3J**, **DurGeneral** and **DurALES** are planned but not imported yet.
- **F3B**, **F3K**, **F3L**, **F5B**, **F5L**, speed and electric classes are
  not supported by Soar Score.
- A competition is also blocked when its settings or date are missing from the
  file, its settings are not valid, nobody in it can be imported, or its scores
  are missing from the file.

The mapping was checked against GliderScore database version **6.78**. A file of
another version still imports, but the list warns that it was not tested.

## Importing the same competition again

Importing a competition again **replaces** the contest it made earlier, which
keeps its place in your list.

- A competition is recognised by its `CompID` (files from 2019 on). An older
  file has none, so the app uses the competition number with its name and date
  and, if the number matches an earlier import with another name or date, asks
  whether it is the same competition.
- If the file holds the same content as the last import, nothing is written and
  the last step says the contest is **already up to date**.
- If you changed the contest in Soar Score after the import (entered scores,
  moved pilots, changed settings), the summary says so and you must tick that
  you understand those changes are replaced before the import can run.
- A contest whose results are published, or that has been sent to the server,
  cannot be replaced yet, and the list says so. (Soar Score has no way to delete
  a contest yet.)

If one competition fails, the others are still imported, and the failed one
leaves nothing behind. Pilots saved in step 5 stay in your participants list.

## If something goes wrong

- _Importing from GliderScore is not available on this computer_: the reader
  that ships with the app could not be started. Reinstall the alpha zip and try
  again.
- _Soar Score could not reproduce GliderScore's scores for N flights_: nothing
  of that competition was kept. Send the file and the message so it can be
  looked at, after checking the file holds nothing you cannot share. Mention
  the GliderScore version. A developer can run
  `dart run packages/soar_score_core/tool/gs_compare.dart <snapshot.json>` on a
  snapshot of the file to see every flight that differs.
- _The import failed_ or a competition says why it was not imported: send the
  file and the message, as above.
- _A participant you chose is no longer in your list_: you changed your list
  while the import ran. Import again.
