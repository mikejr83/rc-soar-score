# RC Soar Score User Interface - New Contest Wizard

The wizard is a guided way to create a contest. It is not the only configuration surface. A step may be revisited before creation, and the contest configuration page remains the authority for later changes.

The wizard saves a local draft between steps. A draft is not a contest, does not appear in contest lists, and does not affect scoring or publication. Required fields are validated before advancing. Validation errors are shown next to the field and summarized at the top of the step. The user can navigate back without losing valid values.

This wizard page is located at the route `/contest-administration/contests/new`.

## Step 1: Contest details and copy source

Required fields:

- Contest name.
- Start date and end date.
- Venue or host.

Optional fields:

- City, state/province, and country.
- Time zone, defaulting to the device or browser time zone with an explicit selection available.

The user may choose not to copy an existing contest, copy configuration only, copy configuration and all pilots, or copy configuration and select a subset of pilots for a fly-off. Local contests are available without connectivity; public contests are searchable only when the service is available and are copied as input data, not as a new public projection. The source contest, selected copy mode, and any selected pilots are shown in the summary.

Copying never copies scores, matrix assignments, publication history, invitations, deletion state, or audit history. Copied values remain editable in later steps. If the source cannot be loaded, the user can remove the source and continue with a new contest.

## Step 2: Discipline

The user selects one supported discipline. The selection card shows the discipline name, task type, default target or working time, landing-bonus summary, and discipline-specific rules. The initial supported choices are ALES, F3J, F5J, and Thermal Duration. Unsupported or placeholder disciplines are not selectable.

Changing discipline clears incompatible discipline-specific values and requires confirmation. The selected discipline supplies defaults; contest-specific overrides are configured after creation.

## Step 3: Participant options

The user selects the options that define contest-specific participant data:

- Teams.
- Contest pilot numbers.
- Classes.
- Contest roles.
- Pilot models.

All options default to disabled unless copied from a source contest. If teams are enabled, the number of pilots counted for the team score is required and must be a positive integer. Team protection is available only when teams are enabled. If models are enabled, the later participant step requests model name and model ID for pilots.

The step also displays whether the option changes participant selection requirements. Disabling an option removes only its new-contest draft values; it does not modify a source contest.

## Step 4: Participants

The participant list shows selected pilots and non-flying participants. Each row may show name, email status, role, class, team, pilot number, and model according to the options selected earlier. A participant must be selected only once.

An autocomplete field searches by name or email. Search order is:

- Offline without connectivity: local participant data.
- Offline with connectivity: remote participant data first, then local participant data.
- Online: remote participant data.

The UI identifies whether a result is local, remote, or already selected. It must not expose participant email to users who are not permitted to see it.

`Add participant` opens the participant editor in creation mode and returns to this step after a successful save. The new participant is selected automatically. Cancel returns without changing the list.

### Participant row rules

When teams are enabled, each pilot must have a team. Team names are case-insensitive for matching and are normalized for comparison. A missing name receives the next numeric team identifier. A team control offers existing teams and a free-text value. The display may use a short avatar, but the full name must remain available as text or an accessible label.

When classes are enabled, each pilot must have a class. Class names are compared case-insensitively and displayed in title case. Previously entered classes are offered as suggestions.

When roles are enabled, new participants default to the immutable `Pilot` role. The role selector lists the configured roles. Non-flying roles do not receive score rows, but may be associated with a team and may enter team scores later when authorized.

Pilot numbers are assigned at the first draw, not in this wizard. The wizard may preview the expected numbering but must label it as provisional.

The contest requires at least two scoring pilots. Fewer than three pilots shows a warning that groups per round should normally be set to one; it does not by itself block continuation. The step blocks continuation when required class, team, role, model, or other configured participant data is missing.

## Step 5: Scoring and publication defaults

The wizard displays discipline defaults for review and permits values that are explicitly allowed during initial configuration:

- Group-score mode: raw, normalized, or time where supported.
- Rounding or truncation and decimal precision from 0 through 3.
- Dropped-round policy.
- Participant score-review requests enabled or disabled.
- Public update policy: automatic, round completion, or manual.

The contest is created unpublished with private visibility. Publication and visibility changes are performed on the contest configuration page. This step does not send data to the public site.

## Step 6: Draw options

The step collects:

- Draw mode: `Man on Man` or `Seeded Man on Man`.
- Groups per round.
- Preliminary number of rounds.
- Lane mode: none or random.
- Team protection when teams are enabled. It is not available together with `Seeded Man on Man`; selecting one disables the other and explains why.
- Back-to-back constraint (no pilot flies the last group of one round and the first of the next). It is off by default, so back-to-back flights are allowed. Turning it on shows a notice that the fairness of the draw will decrease, and the wizard warns when the contest is too small for it.
- Preliminary seeded rounds when seeded mode is selected.

Groups per round is a positive integer. The control displays the calculated minimum and maximum pilots per group and updates them as the value changes. It must prevent a configuration with fewer than two scoring pilots in a group. Team protection may increase the minimum groups per round and the UI must show that constraint.

The preliminary number of rounds is a planning value. In seeded mode, the preliminary seeded-round count defaults to one and cannot be less than one. The wizard labels values that may be changed or extended after the contest starts.

The wizard does not draw a matrix. Matrix creation is an explicit action on contest configuration after the contest exists and all configuration is valid.

## Step 7: Summary and creation

The summary shows contest details, copy source, discipline, participant count, enabled participant options, teams and classes when enabled, scoring defaults, draw options, and the preliminary round/group calculations. Each section has an edit action that returns to its step.

The primary action is `Create contest`. It is disabled while required validation fails. Creation produces a contest in `Configuring` with unpublished/private visibility, closed participant scoring, and an unlocked administration state. No matrix or score is created.

After successful creation, navigate to contest configuration and show a confirmation that the contest exists, the matrix has not been drawn, and discipline overrides and remaining configuration can now be reviewed. If creation fails, retain the wizard values and show a retry action. A duplicate submission must not create duplicate contests.
