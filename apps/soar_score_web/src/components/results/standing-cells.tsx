import Link from "next/link";

import { formatPercent, formatScore } from "@/lib/results/format";
import { contestFlightGroupsPath } from "@/lib/results/paths";
import { pilotName, type PilotStandingRow } from "@/lib/results/published-contest";

import styles from "./results.module.css";

const placeWidth = 64;
const num = `${styles.numCol} num`;

/** A place with the tie indicator, spoken as "Place 2, tied". */
export function PlaceCell({ place, tied, sticky = true }: { place: number; tied: boolean; sticky?: boolean }) {
  return (
    <td
      className={sticky ? styles.sticky : undefined}
      style={sticky ? { left: 0, width: placeWidth, minWidth: placeWidth } : undefined}
      title={tied ? "Tied" : undefined}
    >
      <span className={styles.place} aria-hidden="true">
        {place}
        {tied && <span className={styles.tie}>=</span>}
      </span>
      <span className="visually-hidden">{tied ? `Place ${place}, tied` : `Place ${place}`}</span>
    </td>
  );
}

/** The pilot columns the overall and team tables share. */
export function PilotHeaderCells({
  contestId,
  round,
  stickyName,
}: {
  contestId: string;
  round: number;
  stickyName?: boolean;
}) {
  return (
    <>
      <th
        scope="col"
        className={stickyName ? `${styles.sticky} ${styles.stickyEdge}` : undefined}
        style={stickyName ? { left: placeWidth } : undefined}
      >
        Name
      </th>
      <th scope="col">Country</th>
      <th scope="col" className={styles.numCol}>
        Score
      </th>
      <th scope="col" className={styles.numCol}>
        Percentage
      </th>
      <th scope="col" className={styles.numCol}>
        Raw Score
      </th>
      {Array.from({ length: round }, (_, i) => i + 1).map((r) => (
        <th key={r} scope="col" className={styles.numCol}>
          <Link href={contestFlightGroupsPath(contestId, r)} className={styles.scoreLink}>
            Round {r}
          </Link>
        </th>
      ))}
      <th scope="col" className={styles.numCol}>
        Penalty
      </th>
    </>
  );
}

export function PilotCells({
  row,
  contestId,
  round,
  stickyName,
}: {
  row: PilotStandingRow;
  contestId: string;
  round: number;
  stickyName?: boolean;
}) {
  return (
    <>
      <td
        className={stickyName ? `${styles.sticky} ${styles.stickyEdge}` : undefined}
        style={stickyName ? { left: placeWidth, fontWeight: 600 } : { fontWeight: 600 }}
      >
        {pilotName(row)}
      </td>
      <td>{row.country}</td>
      <td className={num}>{formatScore(row.overallScore)}</td>
      <td className={num}>{formatPercent(row.percentOfWinner)}</td>
      <td className={num}>{formatScore(row.rawTotal)}</td>
      {Array.from({ length: round }, (_, i) => i + 1).map((r) => {
        const score = row.roundScores.get(r);
        const dropped = row.droppedRounds.has(r);
        return (
          <td key={r} className={num} title={dropped ? "Dropped" : undefined}>
            {score === undefined ? (
              "-"
            ) : (
              <Link
                href={contestFlightGroupsPath(contestId, r, row.pilotKey)}
                className={`${styles.scoreLink} ${dropped ? styles.struck : ""}`}
              >
                {formatScore(score)}
                {dropped && <span className="visually-hidden"> (dropped)</span>}
              </Link>
            )}
          </td>
        );
      })}
      <td className={num}>{row.penaltyTotal === 0 ? "-" : formatScore(row.penaltyTotal)}</td>
    </>
  );
}
