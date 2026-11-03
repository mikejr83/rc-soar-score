import type { Metadata } from "next";
import Link from "next/link";

import { Callout, DraftNote, FigurePlaceholder } from "@/components/docs/bits";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("F5J score entry quick reference");

/** F5J quick reference (`/docs/participant-scoring/disciplines/f5j`).
 *  Source: plan/business-requirements/disciplines/f5j.md. */
export default function F5jScoringPage() {
  return (
    <>
      <p className="eyebrow">
        <b>F5J</b> · Quick reference
      </p>
      <h1>F5J score entry</h1>
      <p className="lede">
        The fields on the F5J form with the default configuration, and how
        they turn into points.
      </p>
      <DraftNote />
      <FigurePlaceholder caption="F5J score entry, default configuration" />

      <h2>The fields</h2>
      <table>
        <thead>
          <tr>
            <th scope="col">Field</th>
            <th scope="col">What to enter</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Time flown</td>
            <td>
              From launch to landing, truncated to the second, for example
              9:42. Must be under the working time (600 s by default).
            </td>
          </tr>
          <tr>
            <td>Launch height</td>
            <td>
              The altimeter reading at motor cut, in whole metres. Zero is not
              possible; over 300 m asks for confirmation.
            </td>
          </tr>
          <tr>
            <td>Landing</td>
            <td>
              Pick from the contest&apos;s landing table. Depending on the
              director it reads as distance from the spot or as points.
            </td>
          </tr>
          <tr>
            <td>Late landing</td>
            <td>
              You landed after the working time ended but within the one-minute
              overfly. You keep the time; the landing bonus is forfeited and
              greyed out.
            </td>
          </tr>
          <tr>
            <td>Motor restart</td>
            <td>
              The motor ran again after launch. Scores zero. Shown only when the
              contest allows restarts to be recorded.
            </td>
          </tr>
          <tr>
            <td>Out of bounds</td>
            <td>Landed more than 75 m from your marker. Scores zero.</td>
          </tr>
          <tr>
            <td>No altitude recorded</td>
            <td>
              The altimeter failed. Scores zero and disables the other flags; it
              only records why.
            </td>
          </tr>
          <tr>
            <td>Flight penalty</td>
            <td>
              Whole points for an infraction on this flight. Deducted before the
              group score and dropped with the round if the round is dropped.
            </td>
          </tr>
        </tbody>
      </table>
      <p>
        Submitting an empty form is how an overflight past one minute is
        recorded: the form warns that it is a zero and keeps it if you agree.
      </p>

      <h2>How the score is worked out</h2>
      <ol>
        <li>
          <strong>Flight points</strong> = seconds flown × points per second
          (1 by default).
        </li>
        <li>
          <strong>Height penalty</strong> = 0.5 points per metre up to the
          reference height, then 3 points per metre above it (defaults; the
          director can change them).
        </li>
        <li>
          <strong>Raw score</strong> = flight points − height penalty + landing
          bonus (none on a late landing), never below zero.
        </li>
        <li>
          <strong>Group score</strong>: the best raw score in the group becomes
          1000 and the others scale to it, rounded to one decimal.
        </li>
      </ol>
      <Callout label="Worked example">
        <p>
          Reference height 200 m. A pilot flies 9:30 (570 s), launched to 13 m
          and lands for 45: 570 − 6.5 + 45 = 608.5 raw. A group-mate flies
          9:55 to 46 m with a 50 landing: 595 − 23 + 50 = 622, the best in the
          group, so 1000 points; the first pilot scores 608.5 ÷ 622 × 1000 =
          978.3.
        </p>
      </Callout>
      <p>
        Re-flights, drop rules and ties are the director&apos;s side of the
        rules; results pages show them as described in{" "}
        <Link href="/docs/contests-and-scores">Finding Contests and Results</Link>.
      </p>
    </>
  );
}
