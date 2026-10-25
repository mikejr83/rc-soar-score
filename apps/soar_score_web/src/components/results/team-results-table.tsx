import { formatPercent, formatScore } from "@/lib/results/format";
import type { TeamStandingRow } from "@/lib/results/published-contest";

import styles from "./results.module.css";
import { PilotCells, PilotHeaderCells, PlaceCell } from "./standing-cells";

/**
 * Team Scores as of `round`: a section per team whose first row carries the
 * team's place, name, score and percentage, followed by its pilots.
 */
export function TeamResultsTable({
  teams,
  round,
  contestId,
}: {
  teams: TeamStandingRow[];
  round: number;
  contestId: string;
}) {
  const num = `${styles.numCol} num`;
  return (
    <div className={styles.scroller}>
      <table className={styles.table}>
        <thead>
          <tr>
            <th scope="col" className={styles.sticky} style={{ left: 0 }}>
              Place
            </th>
            <th scope="col" className={`${styles.sticky} ${styles.stickyEdge}`} style={{ left: 64 }}>
              Team
            </th>
            <th scope="col" className={styles.numCol}>
              Team Score
            </th>
            <th scope="col" className={styles.numCol}>
              Percentage
            </th>
            <PilotHeaderCells contestId={contestId} round={round} />
          </tr>
        </thead>
        <tbody>
          {teams.map((team) =>
            team.pilots.map((pilot, i) => (
              <tr key={`${team.teamKey}_${pilot.pilotKey}`} className={i === 0 ? styles.teamRow : undefined}>
                {i === 0 ? (
                  <>
                    <PlaceCell place={team.place} tied={team.isTied} />
                    <td className={`${styles.sticky} ${styles.stickyEdge} ${styles.teamName}`} style={{ left: 64 }}>
                      {team.name}
                    </td>
                    <td className={num}>{formatScore(team.teamScore)}</td>
                    <td className={num}>{formatPercent(team.percentOfWinner)}</td>
                  </>
                ) : (
                  <>
                    <td className={styles.sticky} style={{ left: 0 }} />
                    <td className={`${styles.sticky} ${styles.stickyEdge}`} style={{ left: 64 }} />
                    <td />
                    <td />
                  </>
                )}
                <PilotCells row={pilot} contestId={contestId} round={round} />
              </tr>
            )),
          )}
        </tbody>
      </table>
    </div>
  );
}
