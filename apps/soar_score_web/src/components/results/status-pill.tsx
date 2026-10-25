/** In progress / Completed, as text plus an icon (never colour alone). */
export function StatusPill({ completed }: { completed: boolean }) {
  return completed ? (
    <span className="pill pill--done">
      <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
        <path d="M3 8.5 6.5 12 13 4.5" />
      </svg>
      Completed
    </span>
  ) : (
    <span className="pill pill--live">
      <svg viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">
        <path d="M4 2.5v11l9-5.5z" />
      </svg>
      In progress
    </span>
  );
}
