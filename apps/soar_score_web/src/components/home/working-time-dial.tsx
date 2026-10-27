import styles from "./working-time-dial.module.css";

/**
 * The hero instrument: a working-time clock in the mark's idiom (charcoal
 * bezel, black face, paper ticks, one orange elapsed-time sweep). It is an
 * illustration drawn from the palette, not the logo, so it may animate: the
 * sweep runs on load and the whole instrument drifts with the scroll.
 *
 * Pure SVG and CSS; decorative, so hidden from assistive technology.
 */
export function WorkingTimeDial() {
  const ticks = Array.from({ length: 60 }, (_, i) => i);
  return (
    <div className={styles.frame} aria-hidden="true">
      <svg viewBox="0 0 320 320" className={styles.svg}>
        <defs>
          <radialGradient id="face" cx="50%" cy="42%" r="70%">
            <stop offset="0%" stopColor="#1a1817" />
            <stop offset="100%" stopColor="#0c0b0b" />
          </radialGradient>
        </defs>
        <rect x="8" y="8" width="304" height="304" rx="22" fill="#4a4643" />
        <rect x="8" y="8" width="304" height="304" rx="22" fill="none" stroke="#5c5753" strokeWidth="1" />
        {[32, 288].flatMap((x) =>
          [32, 288].map((y) => <circle key={`${x}-${y}`} cx={x} cy={y} r="7" fill="#0c0b0b" />),
        )}
        <circle cx="160" cy="160" r="124" fill="url(#face)" />
        <circle cx="160" cy="160" r="124" fill="none" stroke="#2a2725" strokeWidth="2" />

        {/* The elapsed-time sweep: a thick stroke whose dash offset animates. */}
        <circle
          className={styles.sweep}
          cx="160"
          cy="160"
          r="34"
          fill="none"
          stroke="#e8420c"
          strokeWidth="68"
          pathLength="100"
          transform="rotate(-90 160 160)"
        />

        <g fill="#f3f2f2">
          {ticks.map((i) => {
            const major = i % 5 === 0;
            return (
              <rect
                key={i}
                x="158"
                y={major ? 44 : 48}
                width={major ? 4 : 2}
                height={major ? 16 : 8}
                rx="1"
                transform={`rotate(${i * 6} 160 160)`}
                opacity={major ? 1 : 0.55}
              />
            );
          })}
        </g>

        <text x="160" y="82" textAnchor="middle" className={styles.label}>
          WORKING TIME
        </text>
        <text x="160" y="258" textAnchor="middle" className={styles.readout}>
          3:48
        </text>

        {/* The glider hand. */}
        <g className={styles.hand}>
          <g transform="translate(160 160) scale(0.78)">
            <path d="M0,-96 L4,-78 L36,-66 L36,-60 L4,-64 L2,-40 L10,-36 L10,-32 L0,-34 L-10,-32 L-10,-36 L-2,-40 L-4,-64 L-36,-60 L-36,-66 L-4,-78 Z" fill="#f3f2f2" />
            <circle r="7" fill="#f3f2f2" />
            <circle r="3" fill="#0c0b0b" />
          </g>
        </g>
      </svg>
      <div className={styles.plate}>
        <span className="eyebrow">
          <b>F5J</b> · Round 4 · Group 2
        </span>
      </div>
    </div>
  );
}
