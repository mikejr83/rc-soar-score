import Link from "next/link";

import { formatDay } from "@/lib/results/contest-filters";
import type { ContestSummary } from "@/lib/results/contest-summary";
import { contestResultsPath } from "@/lib/results/paths";

import styles from "./results.module.css";
import { StatusPill } from "./status-pill";

/** One contest in the search list: start date, name, discipline, venue and status. */
export function ContestRow({ contest }: { contest: ContestSummary }) {
  return (
    <Link href={contestResultsPath(contest.publicationId)} className={styles.row}>
      <time className={styles.rowDate} dateTime={formatDay(contest.start)}>
        {formatDay(contest.start)}
      </time>
      <span className={styles.rowName}>{contest.name}</span>
      {contest.discipline && <span className={styles.rowDiscipline}>{contest.discipline}</span>}
      <span className={styles.rowVenue}>{contest.venue}</span>
      <span className={styles.rowStatus}>
        <StatusPill status={contest.status} />
      </span>
    </Link>
  );
}
