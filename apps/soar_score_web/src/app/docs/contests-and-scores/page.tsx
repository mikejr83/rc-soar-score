import type { Metadata } from "next";
import Link from "next/link";

import { Callout, DraftNote } from "@/components/docs/bits";

export const metadata: Metadata = { title: "Finding Contests and Results" };

/** Public contests help (`/docs/contests-and-scores`). Sources:
 *  plan/ui/public-site/contest-search.md, view-contest.md,
 *  plan/business-requirements/flight-group-management/reflights.md. */
export default function ContestsAndScoresPage() {
  return (
    <>
      <p className="eyebrow">
        <b>Everyone</b> · Guide
      </p>
      <h1>Finding Contests and Results</h1>
      <p className="lede">
        Where to look, what the columns mean, and why a contest might not be
        there yet.
      </p>
      <DraftNote />

      <h2>Finding a contest</h2>
      <p>
        <Link href="/results/contests">Contests</Link> lists the ten most recent
        contests that are in progress or completed, newest start date first,
        with a count of how many ran in the last 30 days. Filter by name, venue
        or start date to see every match; a start date filter also sets the time
        frame of the count; the filters live in the address, so a
        filtered list can be bookmarked or shared. Refresh reloads the list
        without leaving the page, handy while you wait for a contest to go
        live.
      </p>
      <p>
        Future contests appear only through the coming weekend. Private,
        unpublished and delisted contests never appear.
      </p>

      <h2>Reading a contest</h2>
      <p>
        Every contest page starts with the name, dates, venue and whether it is{" "}
        <strong>In progress</strong> or <strong>Completed</strong>, then a
        round selector. The round you pick applies to all three views and is
        kept in the address, so a link always opens on the same round.
      </p>

      <h3>Overall individual results</h3>
      <p>
        One row per pilot as of the selected round: place, name, country,
        score, percentage of the winner&apos;s score, raw score, one column per
        round, and the cumulative penalty. Round headers and round scores open
        that round&apos;s flight groups.
      </p>
      <dl>
        <dt>2=</dt>
        <dd>
          A tie the discipline&apos;s tie-break could not settle. Tied pilots
          share the place and are listed alphabetically by last name.
        </dd>
        <dt>Struck-through round score</dt>
        <dd>
          A dropped round: the contest&apos;s drop rule removed it from the
          total at this point in the contest.
        </dd>
        <dt>Penalty</dt>
        <dd>
          Points the director deducted from the total, never dropped. A dash
          means none.
        </dd>
        <dt>Pilot withheld</dt>
        <dd>The pilot asked for their details to be kept private.</dd>
      </dl>

      <h3>Team scores</h3>
      <p>
        Shown only for contests with teams. Each team is a block: team place,
        name, team score and percentage, then its pilots with their own
        columns. Standings are as of the selected round, like everything else.
      </p>

      <h3>Flight group scores</h3>
      <p>
        One table per group of the selected round, highest group score first:
        name, country, time, landing (for disciplines that have one), the
        discipline&apos;s own details, raw points, normalised score and
        penalty. A group headed <strong>re-flight</strong> flew again; the
        replaced flight is struck through and the official score is the one the
        rules choose, which for a pilot added to a re-flight group is the better
        of the two.
      </p>

      <h2>Why a contest is not shown</h2>
      <Callout label="Not shown yet">
        <p>
          This contest has pending results or has been marked private. It is
          not shown at this time. The contest will be shown after the final
          placing is announced and the contest director makes the results
          public or 48hrs after the last score entered.
        </p>
      </Callout>
      <p>
        That page re-checks every 15 minutes on its own. A contest that never
        existed, a mistyped address or a delisted contest shows &quot;Contest
        not found&quot; instead.
      </p>

      <h2>How current is it?</h2>
      <p>
        The director chooses when scores reach this site: as they are entered,
        when each round completes (the default), or only after confirming
        them. Scores are preliminary until the director marks them official. If
        the director hides overall results before the last rounds, placings
        freeze at that round while group scores keep updating; hiding ends when
        it is turned off, the contest completes or 24 hours pass.
      </p>
      <p>
        Spotted a wrong score? The director corrects it; this site cannot edit
        results. Published results are public record and are removed only by a
        system administrator on request.
      </p>
    </>
  );
}
