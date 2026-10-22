# RC Soar Score Business Requirements - Self Scoring

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. Participants in the contest will need to enter data as the contest progresses.

This document is intended to explain how scores are entered by participants other than the contest director. A contest director is not considered a participant for this aspect of contest except in an administrative capacity.

Participants can be of two main types, pilots and non-fliers. A pilot is only ever a pilot. A person who both flies and helps is not supported in the first release; the contest director can create a second participant with a different email for the helper role.

The general case for entering scores is that of an individual pilot in the contest entering their own scores. A pilot can only self-enter. When teams are enabled, a non-flier on a team is a **helper**: a helper can enter scores for the pilots on their team. Helper self-scoring exists only when teams are enabled. Every helper is assigned to a team, and the contest director assigns them.

In the case of a helper entering scores for their team, the helper first selects the team member and then follows the same steps to enter the score for the pilot as if the pilot were doing this operation. A pilot and a helper can both submit scores for the same pilot; the first accepted submission wins (see Pilot and helper entering the same score).

The main mode of use for this portion of the application will be on mobile devices. As mentioned, this is not the only way scores can be entered for pilots. It is intended to provide an interface to help pilots see when and where they're supposed to fly as well as scores to be entered on the individual basis. It should be presented as a neat and tidy interface suitable for mobile devices.

## Getting in

A participant can reach the self-scoring application in three ways. None of them requires the participant to create an account.

- **The invitation link.** The contest director sends each participant an invitation link, by email or as a QR code at the field. The link contains a random, unguessable code, so no other participant can guess one and enter scores for someone else. Email and QR links behave the same way. The link is not used up when it is opened: the participant can use it again to return to their overview after closing or leaving the application. The application must give the participant a way to copy or share the link so they can find their way back. The contest director sends the same link again when a participant loses it. The contest director may generate a new link for a participant (for example, if a link was shared by mistake); the earlier link then stops working.
- **A guest session.** Opening the link without signing in gives the participant a guest identity so their entries can be attributed to them. See `accounts.md`.
- **An account.** A participant who has an account can sign in. When the contest director has linked the participant to their account, the contest appears in the participant's list of contests as soon as the invitation is sent, without opening the link.

A participant who opens an invitation link can also create an account or sign in at that point. The application asks them to confirm that the participant named on the invitation is them before it links the account to that participant. Entries already made as a guest are then attached to the account.

A participant who has an account and has been linked to a contest director's participant record before is linked again automatically when the director adds them to a new contest. The first link needs the participant's confirmation once. After that it is not asked for again.

A participant who has an account sees a list of the contests they are taking part in or have been invited to. In almost every case it is one contest at a time. Selecting a contest takes them to the contest's overview. If the contest director has not linked the participant and the participant's verified email matches a participant record, the list offers "Is this you?" and links the account once the participant confirms it.

## Overview

Participants are directed to an overview screen that summarizes their participation in the contest. For a pilot this is the pilot's own overview. For a helper it is the team overview described below, from which the helper selects a pilot. Once a helper has selected a pilot, the pilot's overview functions exactly as if the pilot were using it, with a link to go back to the team's pilots.

The pilot's overview shows their name and, if enabled, their pilot number. It has a table with a row for each round in the contest. The rows display the following:

- The round number.
- The group in which they fly in that round.
- If lanes are assigned, the lane number.
- If the contest type is F3K, the task type to be flown.

A selection button may be visible on the table row.

The button will be visible and titled "Enter" when that round has not had a score entered. The "Enter" button is only shown for the first round which has no score for the pilot. As an example, the pilot has not entered their score for round one. The "Enter" button will appear on that row only. The table will then show the "Enter" button on round two after they have entered their score for the first round. Subsequent rounds will not show the button to enter scores.

The table will have a button labeled "View" for rounds in which the pilot has a score entered. When the pilot selects this button they will be presented with the detailed information which was entered for that flight.

The overview also has a way to copy or share the current invitation link, the retirement button, and a link to the current results.

## Team overview

When teams are enabled, a helper's overview is the team overview. It shows:

- Every pilot on the helper's team, with the round, group, and lane (if assigned) of the pilot's next flight, as defined by the next entry rule above.
- The overall standing of every team in the contest, with the helper's own team highlighted.
- Two indicators that tell the helper which of their pilots flies next: **Up now** and **Up next**.

Selecting a pilot opens that pilot's overview.

### Up now and Up next

The indicators are worked out from the scores entered so far, so they trail what is happening on the field and are labeled as based on entered scores.

1. The latest group with an accepted score is the group that has most recently flown. Its round is the latest round, by round number, that has accepted scores. A correction to an earlier round does not move it.
2. Starting with the group after that one, in the order of the matrix (continuing into the next round when that round is drawn), the first group that contains a pilot from the team is the team's next group.
3. The team's pilots in that group are **Up now** if the group is the one directly after the latest group with a score. Otherwise they are **Up next**.
4. When pilots are Up now, the pilots in the next later group that contains a team pilot are **Up next**.
5. Retired pilots are skipped.

For example, group 3 has scores because one pilot has entered theirs. Rob flew in group 3 but has not entered his score yet; he is not up, and the application shows him as having just flown so that he is reminded to enter his score. Joe is in group 4, which has no scores, so he is Up now. Amy is not in group 5. She is in the first group of the next round, so she is Up next.

If no later group has a team pilot, for example because the next round has not been drawn yet, the page says so.

Participants who are not helpers do not see the team overview. The team standings are also shown with the overall results for everyone, as described below.

## Score Entry and Viewing

When a user selects the button to enter or view a round's score they are taken to this view. It enables the pilot to enter or view the scoring details for a single flight.

A form with inputs for each of the scoring parameters is presented to the user when they are entering a score or request a score to be reviewed. The details of the score are shown if the user is viewing previously submitted data.

The contest discipline dictates what inputs or scoring parameters are shown on the form or view. These are outlined in each document for that soaring discipline.

Every discipline has a generic numeric "Flight Penalty" input. A participant, helper, or the contest director may enter a whole number of points for an infraction on that flight, for example flying outside the assigned group. It is part of the round score: it is deducted from the flight's raw score before the group score is calculated, and it is dropped with the round if the round is dropped. It is separate from the penalties a discipline applies on its own, such as the F3J late-landing penalty. The contest director alone may also apply a "Cumulative Penalty" to a flight, which is never dropped (see `contest-official-scoring.md`). The participant sees the cumulative penalty read-only once it has been applied.

The form will have submission, navigation, and optional operations. These are enabled under different conditions.

### Navigation

The view will have buttons that let the user navigate to previous and next rounds if they're available. A button to go back to the overview page will also be present.

### Score Entry Mode

A form with inputs for each of the scoring parameters is presented to the user when they are entering a score.

When the user is entering scoring parameters the view will show a button to submit the scoring details. Any scoring that results in the pilot receiving a zero score will alert the user before allowing them to continue. Once the scoring details have been submitted the form becomes the read only view and the submission button is no longer available.

A submitted score shows who entered it, the pilot or a helper by name, and when.

### Pilot and helper entering the same score

The first valid submission the server accepts is the pilot's score. Neither the pilot nor a helper can overwrite it. A second, different submission is turned away, and the person is shown the score that was accepted together with the option to request a review.

### Review Request

A button labeled "Request Review" is available if review requests are enabled in the contest configuration, the score is in the preliminary `Submitted` state, and the score is not locked (at the score, group, round, or contest level). If the contest director has already marked the score as `Official` or if the score is locked, the "Request Review" button is hidden.

Both a pilot and a helper can request a review of a pilot's score. Only one review request can be open for a flight at a time, so when one is pending the other person sees the pending state instead of the form.

Clicking on this button presents the form pre-populated with the participant's submitted score details. The "Submit" button is enabled only after at least one value changes. The participant may change any scoring values and enter an optional message explaining the reason for the review.

The user clicks the "Submit" button. The form is then presented as a readonly view again. The view shows the values as they were entered by the user. The values which were altered will have an indicator next to their label. The page will also indicate that the pilots score for the round is under a requested review.

## Round and Contest Placement Viewing

Additional scores are shown when the user is viewing the page after the round's score has been entered. A helper sees exactly what the selected pilot would see.

A section will appear under the pilots scoring details shows all pilots that participated in the same group as the pilot. This table will show columns for pilot name, each of the scoring details, the raw score, and the round score. These values will update as participants enter the data. They update as submissions are entered regardless of the settings used for updating the scores on the public site. This is presented as preliminary results to participants.

An indicator will be shown for the row if that pilot has a pending review request. The scores for the pilot will be those that were initially entered and will only updated once the review request process ends.

A section will appear under the group's scores that shows the pilot's current placement in the contest. While the contest director is hiding overall results (see `contest-configuration.md`), this section shows the placement as of the round at which results were hidden, and it does not change until hiding ends. This will be the 3 pilots currently ahead and behind them in the overall ranking as of the round that is currently being viewed. For rounds that do not have all scores entered, the scores should be extrapolated for those pilots without a score. Those pilots should be indicated as having no score entered for the current round and as such the score placing them ahead or behind the current pilot have been estimated. Additionally, if a pilot has a pending review request for the currently viewed round or any previous round it should be indicated in the table.

## Results

The results page shows the most up to date results for the contest. They are almost always preliminary, since participants mostly view them during the contest. It shows the individual overall results, using only the group score for each pilot so the page stays easy to read on a phone.

When teams are enabled the page also shows the team standings, for everyone, so pilots whose team has no helper are not at a disadvantage. Hiding overall results applies to the team standings in the same way as to the individual standings.

Once the contest results are public, the page links to the contest on the public site for the complete results and flight details.

## Retirement

A pilot may need to stop participating in the contest for any number of reasons. It is good etiquette for the pilot to indicate that they are no longer entering scores. By indicating this they will not be prompted for missing scores. This also indicates to the contest director that their scores are not missing.

The score overview page will have a button for a pilot to self-report that they are retiring. A helper can retire a pilot on their team from that pilot's overview. Upon indicating that they are retiring the application will inform them that once confirmed that all future rounds or rounds without scores will be counted as a 0 for their round score and that all score entry will be locked. When a helper retires a pilot, the confirmation names the pilot, and the record shows who retired them. The contest director can reinstate a retired pilot.

After confirming the participant may still view the scores and the rounds but all editing and review requests are no longer available.
