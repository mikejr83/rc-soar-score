import type { PilotStandingRow } from "@/lib/results/published-contest";

import styles from "./results.module.css";
import { PilotCells, PilotHeaderCells, PlaceCell } from "./standing-cells";

/**
 * Overall Individual Results as of `round`: one column per round up to it, a
 * tie indicator on shared places and dropped rounds shaded, struck through
 * and starred, with a key under the table. Round
 * headers and scores link to that round's flight groups.
 */
export function OverallResultsTable({
  rows,
  round,
  contestId,
}: {
  rows: PilotStandingRow[];
  round: number;
  contestId: string;
}) {
  const anyDropped = rows.some((row) => row.droppedRounds.size > 0);
  return (
    <>
      <div className={styles.scroller}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th scope="col" className={styles.sticky} style={{ left: 0 }}>
                Place
              </th>
              <PilotHeaderCells contestId={contestId} round={round} stickyName />
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.pilotKey}>
                <PlaceCell place={row.place} tied={row.isTied} />
                <PilotCells row={row} contestId={contestId} round={round} stickyName />
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {anyDropped && (
        <p className={styles.tableKey}>
          <span aria-hidden="true" className={styles.droppedMark}>
            *
          </span>{" "}
          Dropped round: shaded and struck through, not counted in the score.
        </p>
      )}
    </>
  );
}
