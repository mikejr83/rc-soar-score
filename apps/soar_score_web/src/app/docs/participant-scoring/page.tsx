import type { Metadata } from "next";
import Link from "next/link";

import { Callout, DraftNote, FigurePlaceholder } from "@/components/docs/bits";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("Help Me Enter My Score");

/** Participant scoring help (`/docs/participant-scoring`). Sources:
 *  plan/business-requirements/contest-self-scoring.md,
 *  score-review-requests.md, contest-configuration.md. */
export default function ParticipantScoringPage() {
  return (
    <>
      <p className="eyebrow">
        <b>Pilot</b> · Guide
      </p>
      <h1>Help Me Enter My Score</h1>
      <p className="lede">
        Land, fold the wings, enter the flight. The scoring page is built for a
        phone, one hand and bright sun, and it takes about as long as a walk
        back from the landing spot.
      </p>
      <DraftNote />

      <h2>What self-scoring is for</h2>
      <p>
        Instead of carrying cards to the scoring table, each pilot enters their
        own flight from the invitation link the contest director sent. The page
        shows which group and lane you fly in each round, the scores of your
        group as they come in, and roughly where you stand. When teams are on,
        a helper on your team can enter scores for the team&apos;s pilots, and
        the team page tells them who is up now and up next.
      </p>

      <h2>Getting in</h2>
      <ol>
        <li>
          Open the <strong>invitation link</strong> from your email or scan the
          QR code at the field. The link is yours alone and keeps working, so
          save it. No account is needed.
        </li>
        <li>
          You can sign in or create an account from that link if you want your
          contests in one list. The app asks you to confirm the named pilot is
          you before linking.
        </li>
        <li>
          Lost the link? Ask the director to send it again. If a link was shared
          by mistake the director can issue a new one; the old one then stops
          working.
        </li>
      </ol>

      <h2>What the director&apos;s settings change</h2>
      <dl>
        <dt>Self-scoring off</dt>
        <dd>You will not get a link; an official enters every score.</dd>
        <dt>Review requests</dt>
        <dd>
          When on, a <strong>Request Review</strong> button lets you correct a
          flight you entered wrongly; see below.
        </dd>
        <dt>Scoring locked</dt>
        <dd>The director has stopped entry, usually at the end of the day.</dd>
        <dt>Public updates</dt>
        <dd>
          Decides when scores reach this site: as entered, at round completion
          (the default) or only when the director confirms. Your own group page
          always updates as entries arrive, whatever the setting.
        </dd>
        <dt>Hidden overall results</dt>
        <dd>
          Your placing freezes at the round the director hid results; group
          scores keep showing.
        </dd>
      </dl>

      <h2>Entering a flight, step by step</h2>
      <p>
        The example is an F5J contest with the default settings: a 600 second
        working time and one point per second.
      </p>
      <ol>
        <li>
          <strong>Open your overview.</strong> It lists every round with your
          group and lane. The first round without a score shows{" "}
          <strong>Enter</strong>; rounds you have scored show{" "}
          <strong>View</strong>.
          <FigurePlaceholder caption="Pilot overview with round 2 ready to enter" />
        </li>
        <li>
          <strong>Enter the time flown</strong> as minutes and seconds, for
          example 9:42. The form will not accept a time at or over the working
          time; if you landed after the horn, enter your time and tick{" "}
          <strong>Late landing</strong> instead.
        </li>
        <li>
          <strong>Enter the launch height</strong> in whole metres from your
          altimeter. The form asks you to double-check anything over 300 m.
          Tick <strong>No altitude recorded</strong> only if the device failed;
          that flight scores zero.
        </li>
        <li>
          <strong>Pick the landing.</strong> The list is the contest&apos;s own
          landing table, so you choose the distance or the points exactly as the
          director set them up. A late landing has no landing bonus and the
          field is disabled.
          <FigurePlaceholder caption="F5J score entry with the landing sheet open" />
        </li>
        <li>
          <strong>Zero-score cases.</strong> <strong>Motor restart</strong> and{" "}
          <strong>Out of bounds</strong> (more than 75 m from your spot) clear
          the other fields and score zero; the form tells you before you submit,
          and says whether that zero can be dropped. A{" "}
          <strong>Flight penalty</strong> in points can be added for an
          infraction such as flying in the wrong group.
        </li>
        <li>
          <strong>Submit.</strong> The form becomes read-only and shows who
          entered the score and when. Below it your group&apos;s scores appear
          as other pilots enter theirs, marked preliminary until the director
          makes them official, followed by the three pilots ahead of and behind
          you overall.
          <FigurePlaceholder caption="Submitted flight with the group table below" />
        </li>
      </ol>
      <p>
        Only the first accepted entry for a flight counts. If a helper and the
        pilot both enter the same flight with different numbers, the second
        person sees the accepted score and can request a review.
      </p>
      <p>
        For what each F5J field means and how the score is worked out, see the{" "}
        <Link href="/docs/participant-scoring/disciplines/f5j">F5J quick reference</Link>.
      </p>

      <h2>Requesting a score review</h2>
      <p>
        Typed 8:42 instead of 9:42? If the director has enabled review requests
        and the score is still preliminary and unlocked, open the flight and
        choose <strong>Request Review</strong>.
      </p>
      <ol>
        <li>The form reopens filled with what you entered.</li>
        <li>Change the values that were wrong; Submit enables once something differs.</li>
        <li>Add a short note explaining why, then submit.</li>
        <li>
          The flight shows the values you asked for, a marker beside each
          changed field, and an &quot;under review&quot; note. Your group table
          keeps the original score until the director decides.
        </li>
        <li>
          The director approves (your new values become the official score and
          the results recalculate) or rejects (the original stands). Only one
          request can be open per flight.
        </li>
      </ol>
      <Callout label="Coming">
        <p>
          Review requests are specified but the participant API that carries
          them is still being built, so the button is not live in the current
          release. Until then, tell your director and they will correct the
          score on the Scoring page.
        </p>
      </Callout>

      <h2>Retiring from the contest</h2>
      <p>
        If you have to leave early, use <strong>Retire</strong> on your
        overview. Your remaining rounds count as zero, nobody chases you for
        missing scores, and the director sees that your scores are not simply
        late. You can still read your results. The director can reinstate you if
        plans change.
      </p>
    </>
  );
}
