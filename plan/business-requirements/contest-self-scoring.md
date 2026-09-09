# RC Soar Score Business Requirements - Self Scoring

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. Participants in the contest will need to enter data as the contest progresses.

This document is intended to explain how scores are entered by participants other than the contest director. A contest director is not considered a participant for this aspect of contest except in an administrative capacity.

Participants can be of two main types, pilots and non-fliers. The general case for entering scores is that of an individual pilot in the contest entering their own scores. However, when teams are enabled the pilot or a non-flier role participant on the same team can enter scores. The pilot will always only be able to only self-enter. The non-flier participants for the team can enter scores for their team's pilots.

In the case of a non-flier entering scores for their team, the participant will select the team member and then follow the same steps to enter the score for the pilot as if the pilot were doing this operation.

The main mode of use for this portion of the application will be on mobile devices. As mentioned, this is not the only way scores can be entered for pilots. It is intended to provide an interface to help pilots see when and where they're supposed to fly as well as scores to be entered on the individual basis. It should be presented as a neat and tidy interface suitable for mobile devices.

Participants are directed to an overview screen that summarizes their participation in the contest. The invitation link used to reach the scores must remain usable for the participant to return to this overview after closing or leaving the application. Only the most recently issued invitation link for the participant may open the score interface; an older link must direct the participant to obtain the latest invitation link from the contest director. The screen shows their name and if enabled their pilot number. It will have a table with a row for each round in the contest. The rows display the following:

* The round number.
* The group in which they fly in that round.
* If lanes are assigned, the lane number.
* If the contest type is F3K, the task type to be flown.

A selection button may be visible on the table row.

The button will be visible and titled "Enter" when that round has not had a score entered. The "Enter" button is only shown for the first round which has no score for the pilot. As an example, the pilot has not entered their score for round one. The "Enter" button will appear on that row only. The table will then show the "Enter" button on round two after they have entered their score for the first round. Subsequent rounds will not show the button to enter scores.

The table will have a button labeled "View" for rounds in which the pilot has a score entered. When the pilot selects this button they will be presented with the detailed information which was entered for that flight.

The participant must have a way to retain or copy the current invitation link so they can navigate back to their score overview after closing the application. Returning through the most recent invitation link must show their existing scores and current next-entry round without requiring account creation.

## Score Entry and Viewing

When a user selects the button to enter or view a round's score they are taken to this view. It enables the pilot to enter or view the scoring details for a single flight.

A form with inputs for each of the scoring parameters is presented to the user when they are entering a score or request a score to be reviewed. The details of the score are shown if the user is viewing previously submitted data.

The contest discipline dictates what inputs or scoring parameters are shown on the form or view. These are outlined in each document for that soaring discipline.

One input is required for every discipline. An input must take an integer value for "Cumulative Penalty". This is input is to store a penalty incurred by the pilot during their flight that must be deducted from their total score at the end of the contest.

The form will have submission, navigation, and optional operations. These are enabled under different conditions.

### Navigation

The view will have buttons that let the user navigate to previous and next rounds if they're available. A button to go back to the overview page will also be present.

### Score Entry Mode

A form with inputs for each of the scoring parameters is presented to the user when they are entering a score.

When the user is entering scoring parameters the view will show a button to submit the scoring details. Any scoring that results in the pilot receiving a zero score will alert the user before allowing them to continue. Once the scoring details have been submitted the form becomes the read only view and the submission button is no longer available.

### Review Request

A button labeled "Request Review" will be available if the contest configuration has it enabled and the contest director has not disabled it for the round. It is not shown otherwise. This button is only available after a score has been submitted and while no other review for the pilot is open for the round in which the current score is linked.

Clicking on this button will enable the form to be presented to the user with the current score details as the defaults in the inputs. The "Submit" button is also presented. It is enabled only if the user makes a change to any of the form fields. The user may change any of the values in the form. An additional text field is presented so the user may enter a short message on why they are requesting a review.

The user clicks the "Submit" button. The form is then presented as a readonly view again. The view shows the values as they were entered by the user. The values which were altered will have an indicator next to their label. The page will also indicate that the pilots score for the round is under a requested review.

## Round and Contest Placement Viewing

Additional scores are shown when the user is viewing the page after the round's score has been entered.

A section will appear under the pilots scoring details shows all pilots that participated in the same group as the pilot. This table will show columns for pilot name, each of the scoring details, the raw score, and the round score. These values will update as participants enter the data. They update as submissions are entered regardless of the settings used for updating the scores on the public site. This is presented as preliminary results to participants.

An indicator will be shown for the row if that pilot has a pending review request. The scores for the pilot will be those that were initially entered and will only updated once the review request process ends.

A section will appear under the group's scores that shows the pilot's current placement in the contest. This will be the 3 pilots currently ahead and behind them in the overall ranking as of the round that is currently being viewed. For rounds that do not have all scores entered, the scores should be extrapolated for those pilots without a score. Those pilots should be indicated as having no score entered for the current round and as such the score placing them ahead or behind the current pilot have been estimated. Additionally, if a pilot has a pending review request for the currently viewed round or any previous round it should be indicated in the table.

## Retirement

A pilot may need to stop participating in the contest for any number of reasons. It is good etiquette for the pilot to indicate that they are no longer entering scores. By indicating this they will not be prompted for missing scores. This also indicates to the contest director that their scores are not missing.

The score overview page will have a button for a pilot to self-report that they are retiring. Upon indicating that they are retiring the application will inform them that once confirmed that all future rounds or rounds without scores will be counted as a 0 for their round score and that all score entry will be locked.

After confirming the participant may still view the scores and the rounds but all editing and review requests are no longer available.
