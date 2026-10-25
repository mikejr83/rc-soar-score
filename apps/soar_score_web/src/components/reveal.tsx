"use client";

import { useEffect, useRef, type ReactNode } from "react";

/**
 * Marks its element with `data-inview` the first time it scrolls into view;
 * globals.css fades and lifts it in. Purely presentational: without
 * JavaScript, or under prefers-reduced-motion, the content is simply shown.
 *
 * `delay` staggers siblings (milliseconds). `as` picks the element.
 */
export function Reveal({
  children,
  as: Tag = "div",
  className,
  delay = 0,
  ...rest
}: {
  children: ReactNode;
  as?: keyof React.JSX.IntrinsicElements;
  className?: string;
  delay?: number;
} & Record<string, unknown>) {
  const ref = useRef<HTMLElement>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;
    if (!("IntersectionObserver" in window)) {
      element.setAttribute("data-inview", "");
      return;
    }
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            element.setAttribute("data-inview", "");
            observer.disconnect();
          }
        }
      },
      { rootMargin: "0px 0px -10% 0px", threshold: 0.1 },
    );
    observer.observe(element);
    return () => observer.disconnect();
  }, []);

  const Component = Tag as React.ElementType;
  return (
    <Component
      ref={ref}
      data-reveal=""
      className={className}
      style={delay ? { "--reveal-delay": `${delay}ms` } : undefined}
      {...rest}
    >
      {children}
    </Component>
  );
}
