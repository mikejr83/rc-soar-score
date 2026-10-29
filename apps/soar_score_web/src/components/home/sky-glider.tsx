"use client";

import { useEffect, useRef } from "react";

/** A sailplane seen from above, nose up; wingspan 240 units. */
export const sailplanePath =
  "M0,-60 L3,-30 L120,-26 L120,-21 L3,-12 L2,40 L18,44 L18,48 L0,46 L-18,48 L-18,44 L-2,40 L-3,-12 L-120,-21 L-120,-26 L-3,-30 Z";

/**
 * A hairline sailplane in the panel seams that soars toward the pointer:
 * it banks to face the cursor and follows with a lag, like a model answering
 * the sticks. Static (parked at rest) under reduced motion, on touch, and
 * before JavaScript runs. Decorative; hidden from assistive tech.
 */
export function SkyGlider({
  size = 260,
  lag = 0.06,
  className,
}: {
  size?: number;
  lag?: number;
  className?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    const host = el?.parentElement;
    if (!el || !host) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    if (!window.matchMedia("(hover: hover)").matches) return;

    let frame = 0;
    const rest = () => ({ x: host.clientWidth * 0.72, y: host.clientHeight * 0.42 });
    let target = rest();
    let pos = { ...target };
    let angle = 0;

    const tick = () => {
      const dx = target.x - pos.x;
      const dy = target.y - pos.y;
      pos = { x: pos.x + dx * lag, y: pos.y + dy * lag };
      if (Math.hypot(dx, dy) > 2) {
        // Nose toward the target; the shape points up, so add a quarter turn.
        const wanted = (Math.atan2(dy, dx) * 180) / Math.PI + 90;
        const delta = ((wanted - angle + 540) % 360) - 180;
        angle += delta * 0.08;
      }
      el.style.transform = `translate(${pos.x}px, ${pos.y}px) rotate(${angle}deg)`;
      // Settled: stop; the next pointer move wakes the loop again.
      if (Math.hypot(dx, dy) > 0.5) frame = requestAnimationFrame(tick);
      else frame = 0;
    };
    const wake = () => {
      if (!frame) frame = requestAnimationFrame(tick);
    };
    const onMove = (e: PointerEvent) => {
      const r = host.getBoundingClientRect();
      target = { x: e.clientX - r.left, y: e.clientY - r.top };
      wake();
    };
    const onLeave = () => {
      target = rest();
      wake();
    };
    el.style.transform = `translate(${pos.x}px, ${pos.y}px) rotate(0deg)`;
    host.addEventListener("pointermove", onMove);
    host.addEventListener("pointerleave", onLeave);
    return () => {
      host.removeEventListener("pointermove", onMove);
      host.removeEventListener("pointerleave", onLeave);
      cancelAnimationFrame(frame);
    };
  }, [lag]);

  return (
    <div ref={ref} className={className} aria-hidden="true" style={{ width: size, height: size }}>
      <svg viewBox="-130 -70 260 130" width={size} height={size / 2} fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round">
        <path d={sailplanePath} />
      </svg>
    </div>
  );
}
