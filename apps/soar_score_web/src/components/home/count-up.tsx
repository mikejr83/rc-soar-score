"use client";

import { useEffect, useRef } from "react";

/**
 * Counts from 0 to `value` the first time it scrolls into view, like an
 * altimeter settling. The final value is rendered on the server and left
 * alone under prefers-reduced-motion or without IntersectionObserver; the
 * animation only rewrites the element's text, never React state.
 */
export function CountUp({
  value,
  decimals = 0,
  duration = 1400,
  className,
}: {
  value: number;
  decimals?: number;
  duration?: number;
  className?: string;
}) {
  const ref = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element || !("IntersectionObserver" in window)) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    let frame = 0;
    element.textContent = (0).toFixed(decimals);
    const observer = new IntersectionObserver((entries) => {
      if (!entries.some((e) => e.isIntersecting)) return;
      observer.disconnect();
      const start = performance.now();
      const tick = (now: number) => {
        const t = Math.min(1, (now - start) / duration);
        const eased = 1 - Math.pow(1 - t, 3);
        element.textContent = (value * eased).toFixed(decimals);
        if (t < 1) frame = requestAnimationFrame(tick);
      };
      frame = requestAnimationFrame(tick);
    });
    observer.observe(element);
    return () => {
      observer.disconnect();
      cancelAnimationFrame(frame);
    };
  }, [value, decimals, duration]);

  return (
    <span ref={ref} className={className} aria-label={value.toFixed(decimals)}>
      {value.toFixed(decimals)}
    </span>
  );
}
