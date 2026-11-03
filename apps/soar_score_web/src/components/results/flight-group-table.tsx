import { formatScore, formatTime } from "@/lib/results/format";
import {
  detailKeys,
  groupTitle,
  hasRawComponents,
  type ScoreFields,
  timeKey,
  type FlightGroup,
} from "@/lib/results/published-contest";

import styles from "./results.module.css";

/** The element id of a pilot's flight, for `?pilot=` scrolling. */
export const flightRowId = (group: FlightGroup, pilotKey: string) =>
  `flight-${group.round}-${group.group}-${group.reflight ?? 0}-${pilotKey}`;

/**
 * A discipline detail. A yes/no flag (motor restart, late landing, no
 * altitude recorded) shows a check mark when it happened and a dash when not,
 * never the word "true" (#722).
 */
function DetailValue({ label, text, value }: { label: string; text: string; value: unknown }) {
  if (typeof value !== "boolean") return <>{text}</>;
  if (!value) return <>-</>;
  return (
    <>
      <span aria-hidden="true" className={styles.flagMark} title={label}>
        ✓
      </span>
      <span className="visually-hidden">{label}: yes</span>
    </>
  );
}

/**
 * One flight group headed by its number and re-flight label. Time and the
 * discipline details show only when the flights carry raw components
 * (#456), labelled from the projection's score fields; the landing column only when `hasLanding`.
 */
export function FlightGroupTable({
  group,
  hasLanding,
  fields,
  highlightPilotKey,
}: {
  group: FlightGroup;
  hasLanding: boolean;
  fields: ScoreFields;
  highlightPilotKey?: string;
}) {
  const raw = hasRawComponents(group);
  const details = detailKeys(group);
  const num = `${styles.numCol} num`;
  return (
    <section className={styles.group} aria-label={groupTitle(group)}>
      <div className={styles.groupHead}>
        <span className="eyebrow">Round {group.round}</span>
        <h2>
          Group <span className="stencil">{group.group}</span>
        </h2>
        {group.reflight !== undefined && <span className="pill">Re-flight {group.reflight}</span>}
      </div>
      <div className={styles.scroller}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th scope="col" className={`${styles.sticky} ${styles.stickyEdge}`} style={{ left: 0 }}>
                Name
              </th>
              <th scope="col">Country</th>
              {raw && (
                <th scope="col" className={styles.numCol}>
                  Time
                </th>
              )}
              {hasLanding && (
                <th scope="col" className={styles.numCol}>
                  Landing
                </th>
              )}
              {details.map((key) => (
                <th key={key} scope="col" className={styles.numCol}>
                  {fields.label(key)}
                </th>
              ))}
              <th scope="col" className={styles.numCol}>
                Points
              </th>
              <th scope="col" className={styles.numCol}>
                Score
              </th>
              <th scope="col" className={styles.numCol}>
                Penalty
              </th>
            </tr>
          </thead>
          <tbody>
            {group.flights.map((f) => {
              const highlighted = f.pilotKey === highlightPilotKey;
              return (
                <tr
                  key={`${f.pilotKey}-${f.isSelected}`}
                  id={f.isSelected && highlighted ? flightRowId(group, f.pilotKey) : undefined}
                  className={highlighted ? styles.highlight : undefined}
                  aria-current={highlighted ? "true" : undefined}
                >
                  <td className={`${styles.sticky} ${styles.stickyEdge}`} style={{ left: 0, fontWeight: 600 }}>
                    {f.name}
                  </td>
                  <td>{f.country}</td>
                  {raw && <td className={num}>{formatTime(f.rawComponents[timeKey])}</td>}
                  {hasLanding && <td className={num}>{formatScore(f.landingPoints)}</td>}
                  {details.map((key) => (
                    <td key={key} className={num}>
                      <DetailValue
                        label={fields.label(key)}
                        text={fields.format(key, f.rawComponents[key])}
                        value={f.rawComponents[key]}
                      />
                    </td>
                  ))}
                  <td className={num}>{formatScore(f.rawPoints)}</td>
                  <td className={num} title={f.isSelected ? undefined : "Replaced by a re-flight"}>
                    <span className={f.isSelected ? undefined : styles.struck}>{formatScore(f.groupScore)}</span>
                    {!f.isSelected && <span className="visually-hidden"> (replaced by a re-flight)</span>}
                  </td>
                  <td className={num}>{f.penaltyPoints === 0 ? "-" : formatScore(f.penaltyPoints)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </section>
  );
}
