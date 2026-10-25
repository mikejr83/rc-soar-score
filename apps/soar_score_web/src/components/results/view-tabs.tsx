import Link from "next/link";

import {
  contestFlightGroupsPath,
  contestResultsPath,
  contestTeamResultsPath,
} from "@/lib/results/paths";

import styles from "./results.module.css";

export type ContestView = "overall" | "teams" | "flightGroups";

export const viewTitle: Record<ContestView, string> = {
  overall: "Overall Individual Results",
  teams: "Team Scores",
  flightGroups: "Flight Group Scores",
};

/** Links between the three views, keeping the selected round. */
export function ViewTabs({
  contestId,
  view,
  round,
  hasTeams,
}: {
  contestId: string;
  view: ContestView;
  /** The round in the URL; undefined keeps "latest" in the overall and team links. */
  round?: number;
  hasTeams: boolean;
}) {
  const current = (v: ContestView) => (v === view ? "page" : undefined);
  return (
    <ul className={styles.tabs}>
      <li>
        <Link href={contestResultsPath(contestId, round)} aria-current={current("overall")}>
          Overall
        </Link>
      </li>
      {hasTeams && (
        <li>
          <Link href={contestTeamResultsPath(contestId, round)} aria-current={current("teams")}>
            Team results
          </Link>
        </li>
      )}
      {round !== undefined && (
        <li>
          <Link href={contestFlightGroupsPath(contestId, round)} aria-current={current("flightGroups")}>
            Flight groups
          </Link>
        </li>
      )}
    </ul>
  );
}
