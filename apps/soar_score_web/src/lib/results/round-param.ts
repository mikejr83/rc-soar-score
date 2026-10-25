/** The `:roundNumber` path segment as a round, or undefined when it is not a number. */
export function parseRound(raw: string): number | undefined {
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) && String(n) === raw ? n : undefined;
}
