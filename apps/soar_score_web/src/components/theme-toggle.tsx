"use client";

import styles from "./theme-toggle.module.css";

/**
 * Light or dark, the other of whatever is showing. The choice is stored as
 * `theme` and applied before paint by the inline script in layout.tsx; picking
 * the scheme the OS already prefers clears the override so the site follows
 * the OS again. The icon is chosen by CSS from the same state, so there is no
 * React state to hydrate. Hidden without JavaScript, where it could do nothing.
 */
export function ThemeToggle() {
  const toggle = () => {
    const root = document.documentElement;
    const system = matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    const current = root.dataset.theme ?? system;
    const next = current === "dark" ? "light" : "dark";
    root.dataset.theme = next;
    try {
      if (next === system) localStorage.removeItem("theme");
      else localStorage.setItem("theme", next);
    } catch {
      // Private mode or blocked storage: the choice lasts for this page only.
    }
  };
  return (
    <button type="button" className={styles.toggle} onClick={toggle} aria-label="Switch between light and dark theme">
      <svg className={styles.sun} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
        <circle cx="12" cy="12" r="4" />
        <path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
      </svg>
      <svg className={styles.moon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" aria-hidden="true">
        <path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z" />
      </svg>
    </button>
  );
}
