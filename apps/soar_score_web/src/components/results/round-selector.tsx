"use client";

import styles from "./results.module.css";

const Icon = ({ d }: { d: string }) => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
    <path d={d} />
  </svg>
);

/**
 * First, previous, select, next, last over `rounds`. Presentational: the
 * owner changes the route in `onChange`. Shared by every contest view.
 */
export function RoundSelector({
  rounds,
  selected,
  onChange,
}: {
  rounds: number[];
  selected?: number;
  onChange: (round: number) => void;
}) {
  const index = selected === undefined ? -1 : rounds.indexOf(selected);
  const hasPrevious = index > 0;
  const hasNext = index >= 0 && index < rounds.length - 1;
  // A round outside the list (a stale link) can still jump to a real one.
  const hasFirst = hasPrevious || (index < 0 && rounds.length > 0);
  const hasLast = hasNext || (index < 0 && rounds.length > 0);
  return (
    <div className={styles.selector} role="group" aria-label="Round">
      <button type="button" aria-label="First round" disabled={!hasFirst} onClick={() => onChange(rounds[0])}>
        <Icon d="M18 6l-6 6 6 6M9 6v12" />
      </button>
      <button
        type="button"
        aria-label="Previous round"
        disabled={!hasPrevious}
        onClick={() => onChange(rounds[index - 1])}
      >
        <Icon d="M15 6l-6 6 6 6" />
      </button>
      <select
        aria-label="Round"
        value={index >= 0 ? selected : ""}
        disabled={rounds.length === 0}
        onChange={(e) => onChange(Number(e.target.value))}
      >
        {index < 0 && <option value="">Round</option>}
        {rounds.map((r) => (
          <option key={r} value={r}>
            Round {r}
          </option>
        ))}
      </select>
      <button type="button" aria-label="Next round" disabled={!hasNext} onClick={() => onChange(rounds[index + 1])}>
        <Icon d="M9 6l6 6-6 6" />
      </button>
      <button type="button" aria-label="Last round" disabled={!hasLast} onClick={() => onChange(rounds.at(-1)!)}>
        <Icon d="M6 6l6 6-6 6M15 6v12" />
      </button>
    </div>
  );
}
