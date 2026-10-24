import styles from "./results.module.css";

/** Loading placeholder shaped like the content, so nothing jumps. */
export function Skeleton({ rows = 6, header = false }: { rows?: number; header?: boolean }) {
  return (
    <div className={styles.skeleton} aria-busy="true" aria-label="Loading">
      {header && (
        <div className={`card ${styles.header}`}>
          <div className={styles.bone} style={{ height: 36, width: "60%" }} />
          <div className={styles.bone} style={{ height: 18, width: "40%" }} />
        </div>
      )}
      <div className={`card ${styles.skeleton}`} style={{ padding: 16 }}>
        {Array.from({ length: rows }, (_, i) => (
          <div key={i} className={styles.bone} style={{ height: 22, width: `${92 - (i % 3) * 8}%` }} />
        ))}
      </div>
    </div>
  );
}
