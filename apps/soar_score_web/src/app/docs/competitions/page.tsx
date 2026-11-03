import type { Metadata } from "next";

import { Callout, DraftNote, FigurePlaceholder } from "@/components/docs/bits";
import { contestAppUrl, downloadUrl } from "@/lib/site";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("Contest Director Getting Started");

/** Competition help (`/docs/competitions`). Sources: plan/business-requirements
 *  contest-phases.md, contest-configuration.md, contest-draw.md,
 *  contest-official-scoring.md; plan/architecture-requirements
 *  offline-usage.md, contest-publishing.md; docs/install-alpha.md. */
export default function CompetitionsPage() {
  return (
    <>
      <p className="eyebrow">
        <b>Director</b> · Guide
      </p>
      <h1>Contest Director Getting Started</h1>
      <p className="lede">
        Everything a first F5J contest needs, in the order the day happens:
        create, configure, add pilots, draw the matrix, score, publish.
      </p>
      <DraftNote />

      <h2>Running a contest on the web</h2>
      <p>
        Sign in to the <a href={contestAppUrl}>contest administration app</a>.
        A contest moves through five stages, and the app shows the next step on
        the contest&apos;s workspace page at every one of them.
      </p>

      <h3>1. Create</h3>
      <p>
        <strong>Create contest</strong> on the rail opens a short wizard: the
        name, dates, host club and venue. A created contest cannot be drawn or
        scored yet; it is a placeholder you come back to.
      </p>

      <h3>2. Configure</h3>
      <p>
        The configuration page sets the discipline first, because the discipline
        chooses the scoring form and the defaults. For F5J the defaults are a
        600 second working time, one point per second, normalised group scores
        rounded to one decimal, and the launch-height penalty (0.5 points per
        metre up to the reference height, 3 points per metre above it). Pick
        the landing bonus table, decide how motor restarts are treated, and set
        when the lowest round is dropped.
      </p>
      <p>
        Three options change what pilots see on their phones: whether
        participants may enter their own scores, whether they may request a
        score review, and when the public site updates (as scores arrive, at
        round completion, or only when you confirm). The default is at round
        completion.
      </p>

      <h3>3. Participants and teams</h3>
      <p>
        Add pilots from your own participant list or create them. A pilot is
        always a pilot; a person who both flies and helps needs a second
        participant record with a different email. When teams are on, assign
        each helper to a team so they can enter scores for their team&apos;s
        pilots.
      </p>

      <h3>4. Draw the matrix</h3>
      <p>
        Choose the number of rounds and draw. The draw puts every pilot into a
        group in each round; that grid is the flight matrix, and it can be
        printed from the Reports page. Once a matrix exists, scores can be
        entered. If you draw more rounds than you expect to fly, that is fine:
        the contest completes when you mark it so.
      </p>

      <h3>5. Score</h3>
      <p>
        Rounds and groups fly in order. Scores arrive two ways: pilots and
        helpers enter them from their invitation links, or an official enters
        them on the Scoring page, one group at a time, each pilot&apos;s row
        saved on its own. Score check highlights a group that does not add up.
        If a pilot stops flying, retire them from the round in view; later
        rounds count as zero and nobody is prompted for the missing scores.
      </p>
      <FigurePlaceholder caption="Scoring page, one group of round 1" wide />

      <h3>6. Publish</h3>
      <p>
        Publishing copies a snapshot of the contest to this site. It is
        separate from saving your data online. The first publish is Unlisted
        (reachable by link); switch it to Public to appear in the contest
        search. Publish as often as you like during the weekend and once more
        at the end. You can hide overall standings before the last rounds; the
        round scores keep showing and the standings reappear when you unhide,
        when the contest completes, or after 24 hours.
      </p>
      <Callout label="Good to know">
        <p>
          A published contest is public record. You can hide results or ask a
          system administrator to delist the contest, but you cannot delete the
          published record yourself.
        </p>
      </Callout>

      <h2>The offline application</h2>
      <p>
        Many flying fields have no usable signal. The Windows application is the
        same contest app running on your laptop with its own copy of the data,
        so every step above works with no connection at all.
      </p>

      <h3>Install</h3>
      <ol>
        <li>
          Download the latest zip from the <a href={downloadUrl}>releases page</a>.
          It is a zip, not an installer, and it is not signed yet.
        </li>
        <li>Unzip it anywhere except Program Files and run the application.</li>
        <li>
          If Windows SmartScreen warns you, choose <strong>More info</strong>,
          then <strong>Run anyway</strong>.
        </li>
        <li>
          Choose <strong>Continue offline</strong> on the first screen, or sign
          in if you have an account and a connection.
        </li>
      </ol>
      <p>
        Contests live in your Windows user profile, not next to the program, so
        replacing the unzipped folder with a newer build keeps them. Back up by
        copying that folder while the app is closed.
      </p>

      <h3>What is different offline</h3>
      <ul>
        <li>
          <strong>Local first.</strong> Every change is saved on the laptop
          immediately. With a connection the app synchronises to your account
          for backup; without one it queues the changes and sends them next
          time it connects.
        </li>
        <li>
          <strong>Pilot self-scoring needs the internet.</strong> Pilots enter
          scores through the online service, so a fully offline contest is
          scored by the director or an official on the Scoring page.
        </li>
        <li>
          <strong>Publishing needs a connection,</strong> but not an account. A
          director without an account confirms an email address with a code and
          can then publish. Publish from the field when you get a bar of signal,
          or from home afterwards.
        </li>
        <li>
          <strong>Sync page.</strong> A contest&apos;s Sync page lists pending
          changes and any conflicts to decide, and shows the app version.
        </li>
      </ul>
      <Callout label="Coming">
        <p>
          External timer integration (driving the field timer from the app) is
          planned but not built.
        </p>
      </Callout>
    </>
  );
}
