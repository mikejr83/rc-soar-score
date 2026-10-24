import { formatDates } from "@/lib/results/format";
import type { ContestHeader as Header } from "@/lib/results/published-contest";

import styles from "./results.module.css";
import { StatusPill } from "./status-pill";

/** Name, dates, venue, discipline and status of a contest. */
export function ContestHeader({ header }: { header: Header }) {
  return (
    <header className={`card ${styles.header}`}>
      <div className={styles.headerTop}>
        <h1>{header.name}</h1>
        <StatusPill completed={header.isCompleted} />
      </div>
      <div className={styles.headerMeta}>
        <span>
          <b>{formatDates(header.start, header.end)}</b>
        </span>
        {header.venue && <span>{header.venue}</span>}
        {header.discipline && <span>{header.discipline}</span>}
      </div>
    </header>
  );
}
