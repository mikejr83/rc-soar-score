# RC Soar Score User Interface - Participant Scoring

Participant scoring is mobile-first and is opened through the participant's invitation link. The invitation identifies the participant and, for a helper, the permitted team scope, without requiring account creation. An invalid, expired, or replaced link shows how to obtain a link from the contest director and does not reveal contest data.

The initial release is a hosted web app designed mainly for mobile browsers. The UI must be able to move into Android and iOS apps later, so routes must work as app links and the sign-in flow must follow the identity provider SDK's standard redirect pattern.

The examples in these documents use the host `scoring.rcsoarscore.com`. The host is not decided yet and the name is only an example.

Business behaviour is defined in [contest-self-scoring.md](../../business-requirements/contest-self-scoring.md). Architecture is defined in [self-scoring-invites.md](../../architecture-requirements/self-scoring-invites.md), [participant-score-entry.md](../../architecture-requirements/participant-score-entry.md), and [participant-team-overview.md](../../architecture-requirements/participant-team-overview.md).

## Branding and theme

The self-scoring app uses the theming provided by the shared UI package.

## Routes

Routes have no host and no leading context beyond what is shown. A pilot and a helper use the same route family; the pilot routes carry a pilot identifier so a helper can act for several pilots.

| Page                   | Route                                                        | Who sees it        |
| ---------------------- | ------------------------------------------------------------ | ------------------ |
| Landing page           | `/`                                                          | Anyone             |
| Invitation handler     | `/invitations/{credential}`                                  | Anyone with a link |
| Contests               | `/contests`                                                  | Signed-in accounts |
| Contest entry          | `/contests/{contest_id}`                                     | Participants       |
| Team overview          | `/contests/{contest_id}/team`                                | Helpers            |
| Pilot overview         | `/contests/{contest_id}/pilots/{pilot_id}`                   | Pilots and helpers |
| Score entry and review | `/contests/{contest_id}/pilots/{pilot_id}/rounds/{round_id}` | Pilots and helpers |
| Results                | `/contests/{contest_id}/results`                             | Participants       |

The contest entry route sends a pilot to their own pilot overview and a helper to the team overview. The credential is removed from the address once the invitation handler has accepted it, so it is not left in browser history or shared by accident.

A page reached directly for a round the participant may not enter yet, for example a later round than the next one, opens in a read-only state that says why.

## Landing page

The root of the site. A person who goes to the root sees a short page that says this is the self-scoring application for RC Soar Score. The logo is plainly visible. There is text for someone who has lost their link: ask the contest director to send the invitation again.

Two buttons are offered, Sign in and Sign up. Both go to the identity provider and return to the handler the SDK requires before continuing to any deep link. A person who signs in or signs up from here goes to the Contests page.

## Invitation handler page

Route: `/invitations/{credential}`.

An emailed link and a QR code lead here. The person does not need an account. The page validates the credential. An unknown, expired, or replaced link all produce the same message, which does not reveal whether the contest or participant exists, and tells the person to ask the contest director for their link.

When the link is valid the page offers three choices:

- **Continue as a guest.** The API issues a guest session for the participant link before the person is sent on. The session identifies the participant link and contest, so later requests do not need the credential.
- **Sign in.** The person signs in, then confirms "Continue as Jane Smith (pilot 12)". The confirmation links the account to the participant and attaches earlier guest entries.
- **Create an account.** The same as sign in, after creating the account.

The page names the participant and contest so the person can see the link is theirs. After any choice the person is sent to the contest entry route. A person who has already linked their account is not asked to confirm again.

## Contests page

Route: `/contests`.

This page lists the contests the signed-in account is taking part in or has been invited to. In almost every case there is one. A contest director who has linked the account to a participant record makes the invitation appear here as soon as it is sent, without the participant opening the link.

Each row shows the contest name, its state (Invited, In progress, Completed), and the participant's next round when there is one. Selecting a row opens the contest entry route. Completed contests stay readable and link to the public results when the contest is public.

When the list is empty the page says to open the link the contest director sent, and does not imply an error. When the account's verified email matches a participant record that has an active invitation but is not linked, the page shows "Is this you?" with the participant and contest, and links the record after the person confirms.

## Team overview

Route: `/contests/{contest_id}/team`. Available to helpers when teams are enabled.

The page shows:

- The team name.
- Every pilot on the helper's team, as a list. Each row shows the pilot's name and number, the round, group, and lane of the pilot's next flight, and one of these indicators when it applies: **Up now**, **Up next**, or **Just flown** (with a prompt to enter the score). Retired pilots are marked and carry no indicator.
- A standings table of every team, with the helper's own team highlighted.
- A line that explains that the indicators are based on entered scores.

Selecting a pilot opens that pilot's overview. A message says when no further flight is drawn for the team.

Indicators use text or an icon as well as colour.

## Pilot overview

Route: `/contests/{contest_id}/pilots/{pilot_id}`.

The overview shows contest name, participant name, pilot number when enabled, scoring-access state, and one row per round. Each row shows round, group, lane when assigned, and task type when applicable.

Only the first round without a submitted score shows `Enter`. A round with a submission shows `View`. A participant may navigate to prior completed views but cannot skip ahead to later entry. Retired participants retain read-only access and see that future rounds are locked and counted according to the retirement policy.

A helper sees a **Back to pilots** link to the team overview. Otherwise the page works the same as for the pilot.

The page also has:

- A way to copy or share the participant's invitation link.
- A **Retire** button. It asks for confirmation. The confirmation explains that future and unscored rounds count as zero and that score entry will be locked. When a helper retires a pilot the confirmation names the pilot.
- A link to the current results.

## Entry and review

Route: `/contests/{contest_id}/pilots/{pilot_id}/rounds/{round_id}`.

The entry form renders the fields that make up the pilot's score. These are the discipline-specific fields plus the flight penalty. It has `Submit`, `Back`, and available previous and next navigation. A cumulative penalty is shown read-only once the contest director has applied it; the participant cannot enter one. Before submission, a result that would produce zero shows a confirmation explaining the consequence. After accepted submission, the form becomes read-only and displays who entered the score (the pilot or the helper by name), the submission time, and the status.

If the pilot or a helper submits first, the other person's form switches to the read-only view and shows the accepted score with the option to request a review.

When review requests are enabled and no review is open for the flight assignment, `Request review` is available to the pilot and to a helper, only for a preliminary (`Submitted`) score that is not locked. It opens an editable form prepopulated with the submitted values and an optional explanation field. Submit is disabled until at least one value changes. After submission, the form displays the pending review state and highlights the modified fields. If a review is already pending, the form is not offered and the pending state is shown. If the score has been marked `Official` by the contest director or is locked (at the score, group, round, or contest level), review request actions are hidden.

After a score is submitted, show preliminary group results with pilot name, discipline values, raw score, and round score. Participant submissions update this view as received, independent of the public update policy. Pending reviews are indicated, and the displayed official values remain unchanged until the director resolves the review. A helper sees exactly the view the pilot would see.

Show the participant's current placement with up to three pilots above and below. Estimated placements for missing scores are labeled as estimates. Pending reviews affecting the placement are indicated. While the director is hiding overall results, the placement is shown as of the recorded round.

## Results

Route: `/contests/{contest_id}/results`.

The page shows the most up-to-date results for the contest. They are almost always preliminary, since they are mostly viewed by pilots during the contest. It is designed for a phone and shows only the group score for each pilot.

When teams are enabled the page also shows the team standings, to every participant. While the director is hiding overall results both the individual and the team standings are shown as of the recorded round.

When the results are public, a link opens the contest on the public site for the complete results and flight details.

## General information

All participant views support loading, unavailable-network, invalid-link, closed-scoring, rejected-submission, and retry states. A submission must remain visible locally until its server acknowledgement or a clear rejection reason is received, and a submission that is only queued locally must look different from one the server has accepted.
