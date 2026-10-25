"use client";

import { useEffect, useState } from "react";

/**
 * True at desktop widths (840px and up, the layout breakpoint). A closed
 * <details> hides its children whatever CSS says, so menus that are a
 * collapsed sheet on a phone and an open panel on a desktop hold themselves
 * open with this. False on the server and before hydration.
 */
export function useWide(): boolean {
  const [wide, setWide] = useState(false);
  useEffect(() => {
    const query = window.matchMedia("(min-width: 840px)");
    const sync = () => setWide(query.matches);
    sync();
    query.addEventListener("change", sync);
    return () => query.removeEventListener("change", sync);
  }, []);
  return wide;
}
